'use client';

// src/app/(app)/mailing/bulk-mail-client.tsx
// Audience -> message/options -> preview -> send. Recipients & dedup are
// resolved server-side; the client may only narrow the recipient set (uncheck
// rows) and choose recipient mode, recency guard, and whitelist bypass.

import { useEffect, useMemo, useState, useTransition } from 'react';
import { Mail, Search, X, Send, AlertTriangle, CheckCircle2 } from 'lucide-react';
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
import { previewBulkMail, sendBulkMail, type BulkMailSendSummary } from '@/lib/actions/bulk-mail';
import type { BulkMailPreview, BulkMailSource, RecipientMode } from '@/lib/queries/bulk-mail';
import { searchPartiesForCampaign } from '@/lib/actions/campaigns';

type Pipeline = { id: string; code: string; name: string };
type Stage = { id: string; pipelineId: string; name: string };
type Template = { id: string; name: string; subject: string; category: string | null; module: string | null };
type Account = { id: string; address: string; displayName: string | null; isDefault: boolean };
type PartyHit = { id: string; party_name: string; country_code: string | null; party_type_id: number | null };

const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';
const RECENCY_OPTIONS = [
  { value: '0', label: 'Off' },
  { value: '7', label: '7 days' },
  { value: '14', label: '14 days' },
  { value: '30', label: '30 days' },
  { value: '90', label: '90 days' },
];

export function BulkMailClient({
  pipelines,
  stages,
  templates,
  accounts,
}: {
  pipelines: Pipeline[];
  stages: Stage[];
  templates: Template[];
  accounts: Account[];
}) {
  const [pending, startTransition] = useTransition();

  // ---- audience ----
  const [mode, setMode] = useState<'pipeline_stage' | 'parties'>('pipeline_stage');
  const [pipelineId, setPipelineId] = useState('');
  const [stageId, setStageId] = useState('');
  const stageOptions = useMemo(
    () => stages.filter((s) => s.pipelineId === pipelineId),
    [stages, pipelineId],
  );

  // parties mode
  const [partyQuery, setPartyQuery] = useState('');
  const [results, setResults] = useState<PartyHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedParties, setSelectedParties] = useState<Map<string, PartyHit>>(new Map());

  // ---- message / options ----
  const [templateId, setTemplateId] = useState('');
  const [accountId, setAccountId] = useState(
    accounts.find((a) => a.isDefault)?.id ?? accounts[0]?.id ?? '',
  );
  const [recipientMode, setRecipientMode] = useState<RecipientMode>('primary');
  const [recentDays, setRecentDays] = useState(0);
  const [bypassWhitelist, setBypassWhitelist] = useState(false);

  // ---- preview / send ----
  const [preview, setPreview] = useState<BulkMailPreview | null>(null);
  const [checked, setChecked] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [summary, setSummary] = useState<BulkMailSendSummary | null>(null);

  const selectedTemplate = templates.find((t) => t.id === templateId) ?? null;
  const selectedAccount = accounts.find((a) => a.id === accountId) ?? null;

  const resetPreview = () => { setPreview(null); setSummary(null); };

  // debounced party search (parties mode)
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
    if (mode === 'pipeline_stage') {
      return stageId ? { mode: 'pipeline_stage', stageId } : null;
    }
    const ids = Array.from(selectedParties.keys());
    return ids.length > 0 ? { mode: 'parties', partyIds: ids } : null;
  };

  const audienceReady = mode === 'pipeline_stage' ? !!stageId : selectedParties.size > 0;
  const canPreview = !!templateId && audienceReady;

  const runPreview = () => {
    setError(null);
    setSummary(null);
    const source = buildSource();
    if (!source || !templateId) { setError('Pick an audience and a template first.'); return; }
    startTransition(async () => {
      const res = await previewBulkMail({
        templateId,
        source,
        recipientMode,
        recentDays: recentDays || undefined,
      });
      if (!res.ok || !res.preview) {
        setError(res.errorMessage ?? 'Preview failed.');
        setPreview(null);
        return;
      }
      setPreview(res.preview);
      setChecked(new Set(res.preview.toSend.map((c) => c.key)));
    });
  };

  const toggleRow = (key: string) => {
    setChecked((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const checkedNotWhitelisted = useMemo(() => {
    if (!preview) return 0;
    return preview.toSend.filter((c) => checked.has(c.key) && !c.whitelisted).length;
  }, [preview, checked]);

  const runSend = () => {
    setError(null);
    const source = buildSource();
    if (!source || !templateId || !accountId) {
      setError('Missing template, audience, or sending account.');
      return;
    }
    const onlyKeys = Array.from(checked);
    if (onlyKeys.length === 0) { setError('No recipients selected.'); return; }
    startTransition(async () => {
      const res = await sendBulkMail({
        templateId,
        source,
        mailAccountId: accountId,
        recipientMode,
        recentDays: recentDays || undefined,
        bypassWhitelist,
        onlyKeys,
      });
      setConfirmOpen(false);
      if (!res.ok || !res.summary) { setError(res.errorMessage ?? 'Send failed.'); return; }
      setSummary(res.summary);
      runPreview(); // sent rows now carry template_id -> re-preview drops them
    });
  };

  const checkedCount = checked.size;

  return (
    <div className="mx-auto max-w-5xl p-4 sm:p-6 space-y-6">
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
              onClick={() => { setMode('pipeline_stage'); resetPreview(); }}>
              Pipeline stage
            </Button>
            <Button type="button" variant={mode === 'parties' ? 'default' : 'outline'} size="sm"
              onClick={() => { setMode('parties'); resetPreview(); }}>
              Pick parties
            </Button>
          </div>

          {mode === 'pipeline_stage' ? (
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Pipeline</Label>
                <Select value={pipelineId} onValueChange={(v) => { setPipelineId(v); setStageId(''); resetPreview(); }}>
                  <SelectTrigger><SelectValue placeholder="Select pipeline" /></SelectTrigger>
                  <SelectContent>
                    {pipelines.map((p) => (<SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Stage</Label>
                <Select value={stageId} onValueChange={(v) => { setStageId(v); resetPreview(); }} disabled={!pipelineId}>
                  <SelectTrigger><SelectValue placeholder="Select stage" /></SelectTrigger>
                  <SelectContent>
                    {stageOptions.map((s) => (<SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>))}
                  </SelectContent>
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
                  {searching ? (
                    <div className="p-3 text-sm text-muted-foreground">Searching&hellip;</div>
                  ) : results.length === 0 ? (
                    <div className="p-3 text-sm text-muted-foreground">No parties found.</div>
                  ) : (
                    results.map((p) => (
                      <button key={p.id} type="button"
                        className="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-muted"
                        onClick={() => { setSelectedParties((prev) => { const n = new Map(prev); n.set(p.id, p); return n; }); resetPreview(); }}>
                        <span>{p.party_name}</span>
                        {selectedParties.has(p.id) && <CheckCircle2 className="h-4 w-4 text-emerald-600" />}
                      </button>
                    ))
                  )}
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
                <SelectContent>
                  {templates.map((t) => (
                    <SelectItem key={t.id} value={t.id}>{t.name}{t.module ? ` (${t.module})` : ''}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {selectedTemplate && (
                <p className="text-xs text-muted-foreground truncate">Subject: {selectedTemplate.subject || '(none)'}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label>From</Label>
              {accounts.length === 0 ? (
                <p className="text-sm text-amber-600">No active sending account. Configure one in Settings &rsaquo; Mail.</p>
              ) : (
                <Select value={accountId} onValueChange={setAccountId}>
                  <SelectTrigger><SelectValue placeholder="Select account" /></SelectTrigger>
                  <SelectContent>
                    {accounts.map((a) => (
                      <SelectItem key={a.id} value={a.id}>
                        {a.displayName ? `${a.displayName} <${a.address}>` : a.address}{a.isDefault ? ' - default' : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
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
                <SelectContent>
                  {RECENCY_OPTIONS.map((o) => (<SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center justify-between rounded-md border p-3">
            <div className="space-y-0.5">
              <Label htmlFor="bypass">Bypass whitelist</Label>
              <p className="text-xs text-muted-foreground">
                Off (default): non-whitelisted recipients are blocked. On: send to everyone selected.
              </p>
            </div>
            <Switch id="bypass" checked={bypassWhitelist} onCheckedChange={setBypassWhitelist} />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <Button type="button" onClick={runPreview} disabled={!canPreview || pending} variant="outline">
              {pending && !confirmOpen ? 'Working\u2026' : 'Preview recipients'}
            </Button>
            <Button type="button" onClick={() => setConfirmOpen(true)}
              disabled={!preview || checkedCount === 0 || !accountId || pending}>
              <Send className="mr-1.5 h-4 w-4" />
              Send to {checkedCount}
            </Button>
          </div>

          {error && <p className="text-sm text-red-600">{error}</p>}
        </CardContent>
      </Card>

      {/* ---- Send summary ---- */}
      {summary && (
        <Card>
          <CardHeader><CardTitle className="text-base">Last run</CardTitle></CardHeader>
          <CardContent className="space-y-2 text-sm">
            <div className="flex flex-wrap gap-2">
              <Badge variant="secondary">Attempted {summary.attempted}</Badge>
              <Badge className="bg-emerald-600">Sent {summary.sent}</Badge>
              {summary.blocked > 0 && <Badge className="bg-amber-600">Blocked {summary.blocked}</Badge>}
              {summary.failed > 0 && <Badge variant="destructive">Failed {summary.failed}</Badge>}
              {summary.capped && <Badge variant="outline">Capped (run again for the rest)</Badge>}
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
              {preview.counts.notWhitelisted > 0 && <Badge className="bg-amber-600">Not whitelisted {preview.counts.notWhitelisted}</Badge>}
            </div>

            {preview.counts.notWhitelisted > 0 && !bypassWhitelist && (
              <div className="flex items-start gap-2 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>
                  {preview.counts.notWhitelisted} eligible recipient(s) are not whitelisted and will be
                  blocked. Turn on &ldquo;Bypass whitelist&rdquo; to send to them, or add them to the whitelist.
                </span>
              </div>
            )}

            {preview.toSend.length > 0 && (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-10"></TableHead>
                      <TableHead>Party</TableHead>
                      <TableHead>Recipient</TableHead>
                      <TableHead className="w-28">Whitelist</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {preview.toSend.map((c) => (
                      <TableRow key={c.key}>
                        <TableCell><Checkbox checked={checked.has(c.key)} onCheckedChange={() => toggleRow(c.key)} /></TableCell>
                        <TableCell className="font-medium">{c.partyName || '(unnamed)'}</TableCell>
                        <TableCell className="text-muted-foreground">{c.email}</TableCell>
                        <TableCell>
                          {c.whitelisted ? <Badge variant="secondary">Whitelisted</Badge> : <Badge className="bg-amber-600">Not listed</Badge>}
                        </TableCell>
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
                    <li key={c.key}>
                      {c.partyName || '(unnamed)'} &mdash;{' '}
                      {c.excludeReason === 'already_sent'
                        ? 'already received this template'
                        : c.excludeReason === 'recently_contacted'
                          ? 'contacted recently'
                          : 'no contact email'}
                    </li>
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
          <DialogHeader><DialogTitle>Send this mailing?</DialogTitle></DialogHeader>
          <div className="space-y-2 text-sm">
            <p>
              Sending <span className="font-medium">{selectedTemplate?.name ?? 'template'}</span> to{' '}
              <span className="font-medium">{checkedCount}</span> recipient(s) from{' '}
              <span className="font-medium">{selectedAccount?.address ?? '(no account)'}</span>.
            </p>
            {checkedNotWhitelisted > 0 && (
              <p className={bypassWhitelist ? 'text-amber-700' : 'text-red-600'}>
                {checkedNotWhitelisted} selected recipient(s) are not whitelisted
                {bypassWhitelist ? ' \u2014 they will be sent (bypass on).' : ' \u2014 they will be blocked.'}
              </p>
            )}
            <Separator />
            <p className="text-xs text-muted-foreground">
              This goes out over live mail. Recipients are re-checked on the server before sending.
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmOpen(false)} disabled={pending}>Cancel</Button>
            <Button onClick={runSend} disabled={pending}>{pending ? 'Sending\u2026' : `Send to ${checkedCount}`}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
