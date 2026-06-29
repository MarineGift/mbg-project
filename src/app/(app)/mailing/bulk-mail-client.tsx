'use client';

// src/app/(app)/mailing/bulk-mail-client.tsx
// Audience -> message/options -> preview -> send now OR queue in background.
// "Send now" runs the synchronous action (small batches). "Queue" enqueues a
// mail_run drained by the mailrun-worker (no cap/timeout, rate-limited,
// progress-tracked). Recipients & dedup are resolved server-side.

import { useCallback, useEffect, useMemo, useState, useTransition } from 'react';
import { Mail, Search, X, Send, AlertTriangle, CheckCircle2, Clock } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select';
import {
  Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import {
  previewBulkMail, sendBulkMail, enqueueBulkMail, listRecentMailRuns,
  type BulkMailSendSummary, type MailRunStatus,
} from '@/lib/actions/bulk-mail';
import type { BulkMailPreview, BulkMailSource, RecipientMode } from '@/lib/queries/bulk-mail';
import { searchPartiesForCampaign } from '@/lib/actions/campaigns';

type Pipeline = { id: string; code: string; name: string };
type Stage = { id: string; pipelineId: string; code: string | null; name: string };
type Template = { id: string; name: string; subject: string; category: string | null; module: string | null; stageCode: string | null };
type Account = { id: string; address: string; displayName: string | null; isDefault: boolean };
type PartyHit = { id: string; party_name: string; country_code: string | null; party_type_id: number | null };

const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';
const RECENCY_OPTIONS = [
  { value: '0', label: 'Off' }, { value: '7', label: '7 days' }, { value: '14', label: '14 days' },
  { value: '30', label: '30 days' }, { value: '90', label: '90 days' },
];
const RATE_OPTIONS = [
  { value: '15', label: '15 / min' }, { value: '30', label: '30 / min' },
  { value: '60', label: '60 / min' }, { value: '120', label: '120 / min' },
];
const TERMINAL = ['completed', 'failed', 'canceled'];

export function BulkMailClient({
  pipelines, stages, templates, accounts,
}: {
  pipelines: Pipeline[]; stages: Stage[]; templates: Template[]; accounts: Account[];
}) {
  const [pending, startTransition] = useTransition();

  // ---- audience ----
  const [mode, setMode] = useState<'pipeline_stage' | 'parties'>('pipeline_stage');
  const [pipelineId, setPipelineId] = useState('');
  const [stageId, setStageId] = useState('');
  const stageOptions = useMemo(() => stages.filter((s) => s.pipelineId === pipelineId), [stages, pipelineId]);

  const [partyQuery, setPartyQuery] = useState('');
  const [results, setResults] = useState<PartyHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedParties, setSelectedParties] = useState<Map<string, PartyHit>>(new Map());

  // ---- message / options ----
  const [templateId, setTemplateId] = useState('');
  const [accountId, setAccountId] = useState(accounts.find((a) => a.isDefault)?.id ?? accounts[0]?.id ?? '');
  const [recipientMode, setRecipientMode] = useState<RecipientMode>('primary');
  const [recentDays, setRecentDays] = useState(0);
  const [bypassWhitelist, setBypassWhitelist] = useState(false);
  const [sendMode, setSendMode] = useState<'now' | 'queue'>('now');
  const [ratePerMinute, setRatePerMinute] = useState(30);
  // scheduled send (mail_runs.scheduled_at); '' = send asap
  const [scheduledAt, setScheduledAt] = useState<string>('');
  const toLocalInput = (d: Date): string => {
    const p = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
  };
  const nextGoodSendLocal = (): string => {
    const base = new Date();
    base.setHours(9, 0, 0, 0);
    for (let i = 0; i < 14; i++) {
      const cand = new Date(base);
      cand.setDate(base.getDate() + i);
      const wd = cand.getDay();
      if ((wd === 2 || wd === 3 || wd === 4) && cand.getTime() > Date.now()) return toLocalInput(cand);
    }
    return toLocalInput(base);
  };

  // ---- preview / send ----
  const [preview, setPreview] = useState<BulkMailPreview | null>(null);
  const [checked, setChecked] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [summary, setSummary] = useState<BulkMailSendSummary | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  // ---- background runs ----
  const [runs, setRuns] = useState<MailRunStatus[]>([]);

  // Map plural pipeline codes (investors, filler_suppliers) to the singular
  // template module/party_type tags (investor, filler_supplier).
  const pipelineModule = useMemo(() => {
    const code = pipelines.find((p) => p.id === pipelineId)?.code ?? '';
    if (code === 'investors') return 'investor';
    if (code === 'filler_suppliers') return 'filler_supplier';
    return code;
  }, [pipelines, pipelineId]);
  const selectedStageCode = useMemo(
    () => stages.find((s) => s.id === stageId)?.code ?? '',
    [stages, stageId],
  );
  // Templates offered in the picker: narrow to the audience pipeline's module,
  // then to the selected stage when stage-specific templates exist (otherwise
  // keep the module list so the dropdown is never empty).
  const templateOptions = useMemo(() => {
    if (mode !== 'pipeline_stage' || !pipelineId) return templates;
    const byModule = pipelineModule ? templates.filter((t) => t.module === pipelineModule) : templates;
    const base = byModule.length > 0 ? byModule : templates;
    if (selectedStageCode) {
      const byStage = base.filter((t) => t.stageCode === selectedStageCode);
      if (byStage.length > 0) return byStage;
    }
    return base;
  }, [templates, mode, pipelineId, pipelineModule, selectedStageCode]);
  // Clear the chosen template if an audience change removes it from the list.
  useEffect(() => {
    if (templateId && !templateOptions.some((t) => t.id === templateId)) setTemplateId('');
  }, [templateId, templateOptions]);
  const selectedTemplate = templates.find((t) => t.id === templateId) ?? null;
  const selectedAccount = accounts.find((a) => a.id === accountId) ?? null;

  const resetPreview = () => { setPreview(null); setSummary(null); };

  const loadRuns = useCallback(async () => {
    const res = await listRecentMailRuns(8);
    if (res.ok && res.runs) setRuns(res.runs);
  }, []);

  useEffect(() => { void loadRuns(); }, [loadRuns]);

  // poll while any run is still queued/running
  useEffect(() => {
    const active = runs.some((r) => !TERMINAL.includes(r.status));
    if (!active) return;
    const t = setInterval(() => { void loadRuns(); }, 4000);
    return () => clearInterval(t);
  }, [runs, loadRuns]);

  // debounced party search
  useEffect(() => {
    if (mode !== 'parties') return;
    const q = partyQuery.trim();
    if (q.length < 2) { setResults([]); return; }
    let active = true;
    setSearching(true);
    const t = setTimeout(async () => {
      const res = await searchPartiesForCampaign({ query: q, limit: 30 });
      if (!active) return;
      setResults(res.ok ? res.parties : []);
      setSearching(false);
    }, 250);
    return () => { active = false; clearTimeout(t); };
  }, [partyQuery, mode]);

  const buildSource = (): BulkMailSource | null => {
    if (mode === 'pipeline_stage') return stageId ? { mode: 'pipeline_stage', stageId } : null;
    const ids = Array.from(selectedParties.keys());
    return ids.length > 0 ? { mode: 'parties', partyIds: ids } : null;
  };

  const audienceReady = mode === 'pipeline_stage' ? !!stageId : selectedParties.size > 0;
  const canPreview = !!templateId && audienceReady;

  const runPreview = () => {
    setError(null); setSummary(null); setNotice(null);
    const source = buildSource();
    if (!source || !templateId) { setError('Pick an audience and a template first.'); return; }
    startTransition(async () => {
      const res = await previewBulkMail({ templateId, source, recipientMode, recentDays: recentDays || undefined });
      if (!res.ok || !res.preview) { setError(res.errorMessage ?? 'Preview failed.'); setPreview(null); return; }
      setPreview(res.preview);
      setChecked(new Set(res.preview.toSend.map((c) => c.key)));
    });
  };

  const toggleRow = (key: string) => {
    setChecked((prev) => { const n = new Set(prev); if (n.has(key)) n.delete(key); else n.add(key); return n; });
  };

  const checkedNotWhitelisted = useMemo(
    () => (preview ? preview.toSend.filter((c) => checked.has(c.key) && !c.whitelisted).length : 0),
    [preview, checked],
  );

  const runNow = () => {
    setError(null);
    const source = buildSource();
    if (!source || !templateId || !accountId) { setError('Missing template, audience, or sending account.'); return; }
    const onlyKeys = Array.from(checked);
    if (onlyKeys.length === 0) { setError('No recipients selected.'); return; }
    startTransition(async () => {
      const res = await sendBulkMail({ templateId, source, mailAccountId: accountId, recipientMode, recentDays: recentDays || undefined, bypassWhitelist, onlyKeys });
      setConfirmOpen(false);
      if (!res.ok || !res.summary) { setError(res.errorMessage ?? 'Send failed.'); return; }
      setSummary(res.summary);
      runPreview();
    });
  };

  const runQueue = () => {
    setError(null);
    const source = buildSource();
    if (!source || !templateId || !accountId) { setError('Missing template, audience, or sending account.'); return; }
    const onlyKeys = Array.from(checked);
    if (onlyKeys.length === 0) { setError('No recipients selected.'); return; }
    startTransition(async () => {
      const res = await enqueueBulkMail({ templateId, source, mailAccountId: accountId, recipientMode, recentDays: recentDays || undefined, bypassWhitelist, onlyKeys, ratePerMinute, scheduledAt: scheduledAt ? new Date(scheduledAt).toISOString() : undefined });
      setConfirmOpen(false);
      if (!res.ok) { setError(res.errorMessage ?? 'Queue failed.'); return; }
      setNotice(`Queued ${res.total ?? onlyKeys.length} recipient(s). The worker will send them in the background.`);
      resetPreview();
      void loadRuns();
    });
  };

  const checkedCount = checked.size;
  const actionLabel = sendMode === 'now' ? `Send to ${checkedCount}` : `Queue ${checkedCount}`;

  return (
    <div className="p-4 sm:p-6 space-y-6">
      <div className="flex items-center gap-2">
        <Mail className="h-5 w-5" />
        <h1 className="text-xl font-semibold">Mailing</h1>
      </div>
      <p className="text-sm text-muted-foreground">
        Send a template to a pipeline stage&rsquo;s parties or a chosen set of parties. Anyone who
        already received this template is left out automatically.
      </p>

      {/* ---- Audience ---- */}
      <Card>
        <CardHeader><CardTitle className="text-base">Audience</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Button type="button" variant={mode === 'pipeline_stage' ? 'default' : 'outline'} size="sm"
              onClick={() => { setMode('pipeline_stage'); resetPreview(); }}>Pipeline stage</Button>
            <Button type="button" variant={mode === 'parties' ? 'default' : 'outline'} size="sm"
              onClick={() => { setMode('parties'); resetPreview(); }}>Pick parties</Button>
          </div>

          {mode === 'pipeline_stage' ? (
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Pipeline</Label>
                <Select value={pipelineId} onValueChange={(v) => { setPipelineId(v); setStageId(''); resetPreview(); }}>
                  <SelectTrigger><SelectValue placeholder="Select pipeline" /></SelectTrigger>
                  <SelectContent>{pipelines.map((p) => (<SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>))}</SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Stage</Label>
                <Select value={stageId} onValueChange={(v) => { setStageId(v); resetPreview(); }} disabled={!pipelineId}>
                  <SelectTrigger><SelectValue placeholder="Select stage" /></SelectTrigger>
                  <SelectContent>{stageOptions.map((s) => (<SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>))}</SelectContent>
                </Select>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="relative">
                <Search className="pointer-events-none absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <input className={inputCls + ' pl-8'} placeholder="Search parties by name (min 2 chars)"
                  value={partyQuery} onChange={(e) => setPartyQuery(e.target.value)} />
              </div>
              {selectedParties.size > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {Array.from(selectedParties.values()).map((p) => (
                    <Badge key={p.id} variant="secondary" className="gap-1">
                      {p.party_name}
                      <button type="button" aria-label={`Remove ${p.party_name}`}
                        onClick={() => { setSelectedParties((prev) => { const n = new Map(prev); n.delete(p.id); return n; }); resetPreview(); }}>
                        <X className="h-3 w-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}
              {partyQuery.trim().length >= 2 && (
                <div className="max-h-48 overflow-y-auto rounded-md border">
                  {searching ? (<div className="p-3 text-sm text-muted-foreground">Searching&hellip;</div>)
                    : results.length === 0 ? (<div className="p-3 text-sm text-muted-foreground">No parties found.</div>)
                    : (results.map((p) => (
                        <button key={p.id} type="button"
                          className="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-muted"
                          onClick={() => { setSelectedParties((prev) => { const n = new Map(prev); n.set(p.id, p); return n; }); resetPreview(); }}>
                          <span>{p.party_name}</span>
                          {selectedParties.has(p.id) && <CheckCircle2 className="h-4 w-4 text-emerald-600" />}
                        </button>)))}
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* ---- Message / options ---- */}
      <Card>
        <CardHeader><CardTitle className="text-base">Message</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Template</Label>
              <Select value={templateId} onValueChange={(v) => { setTemplateId(v); resetPreview(); }}>
                <SelectTrigger><SelectValue placeholder="Select template" /></SelectTrigger>
                <SelectContent>{templateOptions.map((t) => (<SelectItem key={t.id} value={t.id}>{t.name}{t.module ? ` (${t.module})` : ''}</SelectItem>))}</SelectContent>
              </Select>
              {selectedTemplate && (<p className="text-xs text-muted-foreground truncate">Subject: {selectedTemplate.subject || '(none)'}</p>)}
            </div>
            <div className="space-y-1.5">
              <Label>From</Label>
              {accounts.length === 0 ? (
                <p className="text-sm text-amber-600">No active sending account. Configure one in Settings &rsaquo; Mail.</p>
              ) : (
                <Select value={accountId} onValueChange={setAccountId}>
                  <SelectTrigger><SelectValue placeholder="Select account" /></SelectTrigger>
                  <SelectContent>{accounts.map((a) => (<SelectItem key={a.id} value={a.id}>{a.displayName ? `${a.displayName} <${a.address}>` : a.address}{a.isDefault ? ' - default' : ''}</SelectItem>))}</SelectContent>
                </Select>
              )}
            </div>
            <div className="space-y-1.5">
              <Label>Recipients per party</Label>
              <Select value={recipientMode} onValueChange={(v) => { setRecipientMode(v as RecipientMode); resetPreview(); }}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="primary">Primary contact</SelectItem>
                  <SelectItem value="all_contacts">All contacts with email</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Skip recently contacted</Label>
              <Select value={String(recentDays)} onValueChange={(v) => { setRecentDays(Number(v)); resetPreview(); }}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>{RECENCY_OPTIONS.map((o) => (<SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>))}</SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center justify-between rounded-md border p-3">
            <div className="space-y-0.5">
              <Label htmlFor="bypass">Bypass whitelist</Label>
              <p className="text-xs text-muted-foreground">Off (default): non-whitelisted recipients are blocked. On: send to everyone selected.</p>
            </div>
            <Switch id="bypass" checked={bypassWhitelist} onCheckedChange={setBypassWhitelist} />
          </div>

          {/* send mode */}
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Delivery</Label>
              <div className="flex gap-2">
                <Button type="button" size="sm" variant={sendMode === 'now' ? 'default' : 'outline'} onClick={() => setSendMode('now')}>Send now</Button>
                <Button type="button" size="sm" variant={sendMode === 'queue' ? 'default' : 'outline'} onClick={() => setSendMode('queue')}>Queue (background)</Button>
              </div>
              <p className="text-xs text-muted-foreground">
                {sendMode === 'now'
                  ? 'Sends immediately (best for small batches; capped at 100).'
                  : 'Hands off to the background worker - no cap, rate-limited, progress below.'}
              </p>
            </div>
            {sendMode === 'queue' && (
              <>
                <div className="space-y-1.5">
                  <Label>Send time</Label>
                  <div className="flex flex-wrap items-center gap-2">
                    <input
                      type="datetime-local"
                      value={scheduledAt}
                      min={toLocalInput(new Date())}
                      onChange={(e) => setScheduledAt(e.target.value)}
                      className="h-9 rounded-md border border-input bg-background px-2 text-sm"
                    />
                    <Button type="button" size="sm" variant="outline" onClick={() => setScheduledAt(nextGoodSendLocal())}>
                      <Clock className="mr-1 h-3.5 w-3.5" />Best time
                    </Button>
                    {scheduledAt && (
                      <Button type="button" size="sm" variant="ghost" onClick={() => setScheduledAt('')}>Send asap</Button>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {scheduledAt
                      ? `Held until ${new Date(scheduledAt).toLocaleString()} (your local time).`
                      : 'Empty = send as soon as the worker picks it up. Tip: Tue\u2013Thu ~9am beats Friday afternoon.'}
                  </p>
                </div>
                <div className="space-y-1.5">
                  <Label>Rate</Label>
                  <Select value={String(ratePerMinute)} onValueChange={(v) => setRatePerMinute(Number(v))}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>{RATE_OPTIONS.map((o) => (<SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>))}</SelectContent>
                  </Select>
                </div>
              </>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <Button type="button" onClick={runPreview} disabled={!canPreview || pending} variant="outline">
              {pending && !confirmOpen ? 'Working\u2026' : 'Preview recipients'}
            </Button>
            <Button type="button" onClick={() => setConfirmOpen(true)} disabled={!preview || checkedCount === 0 || !accountId || pending}>
              <Send className="mr-1.5 h-4 w-4" />{actionLabel}
            </Button>
          </div>

          {error && <p className="text-sm text-red-600">{error}</p>}
          {notice && <p className="text-sm text-emerald-700">{notice}</p>}
        </CardContent>
      </Card>

      {/* ---- Background runs ---- */}
      {runs.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-base">Background runs</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {runs.map((r) => {
              const done = r.sent + r.failed + r.blocked;
              const pct = r.total > 0 ? Math.round((done / r.total) * 100) : 0;
              const active = !TERMINAL.includes(r.status);
              return (
                <div key={r.id} className="space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="flex items-center gap-2">
                      {active ? <Clock className="h-3.5 w-3.5 animate-pulse text-blue-600" /> : <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />}
                      <span className="font-medium capitalize">{r.status}</span>
                      <span className="text-muted-foreground">{done}/{r.total}</span>
                    </span>
                    <span className="flex gap-1.5">
                      <Badge className="bg-emerald-600">Sent {r.sent}</Badge>
                      {r.blocked > 0 && <Badge className="bg-amber-600">Blocked {r.blocked}</Badge>}
                      {r.failed > 0 && <Badge variant="destructive">Failed {r.failed}</Badge>}
                    </span>
                  </div>
                  <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                    <div className="h-full bg-emerald-600 transition-all" style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}

      {/* ---- Send-now summary ---- */}
      {summary && (
        <Card>
          <CardHeader><CardTitle className="text-base">Last run</CardTitle></CardHeader>
          <CardContent className="space-y-2 text-sm">
            <div className="flex flex-wrap gap-2">
              <Badge variant="secondary">Attempted {summary.attempted}</Badge>
              <Badge className="bg-emerald-600">Sent {summary.sent}</Badge>
              {summary.blocked > 0 && <Badge className="bg-amber-600">Blocked {summary.blocked}</Badge>}
              {summary.failed > 0 && <Badge variant="destructive">Failed {summary.failed}</Badge>}
              {summary.capped && <Badge variant="outline">Capped - queue the rest for the worker</Badge>}
            </div>
            {(summary.blocked > 0 || summary.failed > 0) && (
              <ul className="mt-2 space-y-1 text-xs text-muted-foreground">
                {summary.results.filter((r) => r.status !== 'sent').slice(0, 25).map((r) => (
                  <li key={r.key}><span className="font-medium">{r.email}</span> &mdash; {r.status}{r.error ? `: ${r.error}` : ''}</li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      )}

      {/* ---- Preview ---- */}
      {preview && (
        <Card>
          <CardHeader><CardTitle className="text-base">Recipients</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-wrap gap-2 text-sm">
              <Badge variant="secondary">Parties {preview.counts.parties}</Badge>
              <Badge variant="secondary">Eligible {preview.counts.toSend}</Badge>
              {preview.counts.alreadySent > 0 && <Badge variant="outline">Already received {preview.counts.alreadySent}</Badge>}
              {preview.counts.recentlyContacted > 0 && <Badge variant="outline">Recently contacted {preview.counts.recentlyContacted}</Badge>}
              {preview.counts.noEmail > 0 && <Badge variant="outline">No email {preview.counts.noEmail}</Badge>}
              {preview.counts.bounced > 0 && <Badge className="bg-red-600">Bounced/invalid {preview.counts.bounced}</Badge>}
              {preview.counts.blocklisted > 0 && <Badge className="bg-red-700">Do-not-send {preview.counts.blocklisted}</Badge>}
              {preview.counts.notWhitelisted > 0 && <Badge className="bg-amber-600">Not whitelisted {preview.counts.notWhitelisted}</Badge>}
            </div>

            {preview.counts.notWhitelisted > 0 && !bypassWhitelist && (
              <div className="flex items-start gap-2 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>{preview.counts.notWhitelisted} eligible recipient(s) are not whitelisted and will be blocked. Turn on &ldquo;Bypass whitelist&rdquo; to send to them, or add them to the whitelist.</span>
              </div>
            )}

            {preview.toSend.length > 0 && (
              <div className="rounded-md border">
                <Table>
                  <TableHeader><TableRow>
                    <TableHead className="w-10"></TableHead><TableHead>Party</TableHead>
                    <TableHead>Recipient</TableHead><TableHead className="w-28">Whitelist</TableHead>
                  </TableRow></TableHeader>
                  <TableBody>
                    {preview.toSend.map((c) => (
                      <TableRow key={c.key}>
                        <TableCell><Checkbox checked={checked.has(c.key)} onCheckedChange={() => toggleRow(c.key)} /></TableCell>
                        <TableCell className="font-medium">{c.partyName || '(unnamed)'}</TableCell>
                        <TableCell className="text-muted-foreground">{c.email}</TableCell>
                        <TableCell>{c.whitelisted ? <Badge variant="secondary">Whitelisted</Badge> : <Badge className="bg-amber-600">Not listed</Badge>}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}

            {preview.excluded.length > 0 && (
              <details className="text-sm">
                <summary className="cursor-pointer text-muted-foreground">Excluded ({preview.excluded.length})</summary>
                <ul className="mt-2 space-y-1 text-xs text-muted-foreground">
                  {preview.excluded.map((c) => (
                    <li key={c.key}>{c.partyName || '(unnamed)'}{c.email ? ` <${c.email}>` : ''} &mdash;{' '}
                      {c.excludeReason === 'already_sent' ? 'already received this template'
                        : c.excludeReason === 'recently_contacted' ? 'contacted recently'
                        : c.excludeReason === 'bounced' ? 'previously bounced / invalid recipient'
                        : c.excludeReason === 'blocklisted' ? 'on do-not-send list'
                        : 'no contact email'}</li>
                  ))}
                </ul>
              </details>
            )}
          </CardContent>
        </Card>
      )}

      {/* ---- Confirm dialog ---- */}
      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{sendMode === 'now' ? 'Send this mailing?' : 'Queue this mailing?'}</DialogTitle></DialogHeader>
          <div className="space-y-2 text-sm">
            <p>
              {sendMode === 'now' ? 'Sending ' : 'Queuing '}
              <span className="font-medium">{selectedTemplate?.name ?? 'template'}</span> to{' '}
              <span className="font-medium">{checkedCount}</span> recipient(s) from{' '}
              <span className="font-medium">{selectedAccount?.address ?? '(no account)'}</span>
              {sendMode === 'queue' ? ` at ${ratePerMinute}/min${scheduledAt ? `, starting ${new Date(scheduledAt).toLocaleString()}` : ''}.` : '.'}
            </p>
            {checkedNotWhitelisted > 0 && (
              <p className={bypassWhitelist ? 'text-amber-700' : 'text-red-600'}>
                {checkedNotWhitelisted} selected recipient(s) are not whitelisted
                {bypassWhitelist ? ' \u2014 they will be sent (bypass on).' : ' \u2014 they will be blocked.'}
              </p>
            )}
            <Separator />
            <p className="text-xs text-muted-foreground">This goes out over live mail. Recipients are re-checked on the server before sending.</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmOpen(false)} disabled={pending}>Cancel</Button>
            <Button onClick={sendMode === 'now' ? runNow : runQueue} disabled={pending}>
              {pending ? (sendMode === 'now' ? 'Sending\u2026' : 'Queuing\u2026') : actionLabel}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
