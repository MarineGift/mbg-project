'use client';

// src/app/(app)/marketing/marketing-client.tsx
// Segment -> template -> build batch (segment + bulk preview) -> queue.
// Each batch is queued through enqueueBulkMail as { mode: 'parties' } so all
// bulk-mail safety rails apply. "Build next batch" skips parties already sent
// or still pending in a queued run of the same template.

import { useCallback, useEffect, useMemo, useState, useTransition } from 'react';
import { Megaphone, Layers, Send, AlertTriangle, CheckCircle2, Clock, RefreshCw } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import {
  Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import { buildMarketingSegment } from '@/lib/actions/marketing-segment';
import {
  previewBulkMail, enqueueBulkMail, listRecentMailRuns, type MailRunStatus,
} from '@/lib/actions/bulk-mail';
import type { BulkMailPreview, RecipientMode } from '@/lib/queries/bulk-mail';
import type { SegmentResult } from '@/lib/queries/marketing-segment';
import { MailRunDetailDialog } from '@/components/mailing/mail-run-detail-dialog';

type PartyType = { code: string; name: string };
type Template = { id: string; name: string; subject: string; body: string; category: string | null; module: string | null };
type Account = { id: string; address: string; displayName: string | null; isDefault: boolean };

const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';
const TERMINAL = ['completed', 'failed', 'canceled'];
const DEFAULT_EXCLUDE = 'KR, DE, AT';

const splitCodes = (s: string) =>
  s.split(/[\s,;]+/).map((x) => x.trim().toUpperCase()).filter(Boolean);

function nextGoodSendLocal(): string {
  const p = (n: number) => String(n).padStart(2, '0');
  const base = new Date();
  base.setHours(9, 0, 0, 0);
  for (let i = 0; i < 14; i++) {
    const c = new Date(base);
    c.setDate(base.getDate() + i);
    const wd = c.getDay();
    if ((wd === 2 || wd === 3 || wd === 4) && c.getTime() > Date.now()) {
      return `${c.getFullYear()}-${p(c.getMonth() + 1)}-${p(c.getDate())}T09:00`;
    }
  }
  return '';
}

export function MarketingClient({
  partyTypes, templates, accounts,
}: { partyTypes: PartyType[]; templates: Template[]; accounts: Account[] }) {
  const [pending, startTransition] = useTransition();

  // ---- segment ----
  const [partyTypeCode, setPartyTypeCode] = useState(
    partyTypes.some((p) => p.code === 'paper_mill') ? 'paper_mill' : (partyTypes[0]?.code ?? ''),
  );
  const [includeCountries, setIncludeCountries] = useState('');
  const [excludeCountries, setExcludeCountries] = useState(DEFAULT_EXCLUDE);
  const [keyword, setKeyword] = useState('');
  const [supplierQuery, setSupplierQuery] = useState('');
  const [licenseeHosts, setLicenseeHosts] = useState<'exclude_all' | 'exclude_active' | 'include'>('exclude_all');
  const [batchSize, setBatchSize] = useState(100);

  // ---- message ----
  const moduleTemplates = useMemo(() => {
    const own = templates.filter((t) => t.module === partyTypeCode);
    return own.length > 0 ? own : templates;
  }, [templates, partyTypeCode]);
  const [templateId, setTemplateId] = useState('');
  useEffect(() => {
    if (templateId && !moduleTemplates.some((t) => t.id === templateId)) setTemplateId('');
  }, [moduleTemplates, templateId]);
  const tmpl = templates.find((t) => t.id === templateId) ?? null;

  const [followUp, setFollowUp] = useState(false);
  const [receivedTemplateId, setReceivedTemplateId] = useState('');
  const [receivedMinDays, setReceivedMinDays] = useState(7);

  const [accountId, setAccountId] = useState(accounts.find((a) => a.isDefault)?.id ?? accounts[0]?.id ?? '');
  const [recipientMode, setRecipientMode] = useState<RecipientMode>('primary');
  const [recentDays, setRecentDays] = useState(14);
  const [bypassWhitelist, setBypassWhitelist] = useState(true);
  const [ratePerMinute, setRatePerMinute] = useState(15);
  const [scheduledAt, setScheduledAt] = useState('');

  // ---- results ----
  const [segment, setSegment] = useState<SegmentResult | null>(null);
  const [preview, setPreview] = useState<BulkMailPreview | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [runs, setRuns] = useState<MailRunStatus[]>([]);
  const [detailRunId, setDetailRunId] = useState<string | null>(null);

  const loadRuns = useCallback(async () => {
    const r = await listRecentMailRuns(8);
    if (r.ok && r.runs) setRuns(r.runs);
  }, []);
  useEffect(() => { void loadRuns(); }, [loadRuns]);
  useEffect(() => {
    if (!runs.some((r) => !TERMINAL.includes(r.status))) return;
    const t = setInterval(() => { void loadRuns(); }, 5000);
    return () => clearInterval(t);
  }, [runs, loadRuns]);

  const reset = () => { setSegment(null); setPreview(null); setNotice(null); };

  const buildBatch = () => {
    setError(null); setNotice(null);
    if (!templateId) { setError('Pick the template to send first.'); return; }
    if (followUp && !receivedTemplateId) { setError('Pick the earlier template for the follow-up filter.'); return; }
    startTransition(async () => {
      const seg = await buildMarketingSegment({
        partyTypeCode,
        templateId,
        includeCountries: splitCodes(includeCountries),
        excludeCountries: splitCodes(excludeCountries),
        keyword: keyword.trim() || undefined,
        supplierQuery: supplierQuery.trim() || undefined,
        licenseeHosts,
        receivedTemplateId: followUp ? receivedTemplateId : null,
        receivedMinDays: followUp ? receivedMinDays : undefined,
        batchSize,
      });
      if (!seg.ok || !seg.result) { setError(seg.errorMessage ?? 'Segment failed.'); setSegment(null); setPreview(null); return; }
      setSegment(seg.result);
      if (seg.result.batchPartyIds.length === 0) { setPreview(null); setNotice('No remaining parties in this segment for this template.'); return; }
      const pv = await previewBulkMail({
        templateId,
        source: { mode: 'parties', partyIds: seg.result.batchPartyIds },
        recipientMode,
        recentDays: followUp ? undefined : (recentDays || undefined),
      });
      if (!pv.ok || !pv.preview) { setError(pv.errorMessage ?? 'Preview failed.'); setPreview(null); return; }
      setPreview(pv.preview);
    });
  };

  const queueBatch = () => {
    if (!preview || !segment) return;
    const onlyKeys = preview.toSend.map((c) => c.key);
    if (onlyKeys.length === 0) { setError('Nothing to send in this batch.'); return; }
    if (!accountId) { setError('Pick a sending account.'); return; }
    setError(null);
    startTransition(async () => {
      const res = await enqueueBulkMail({
        templateId,
        source: { mode: 'parties', partyIds: segment.batchPartyIds },
        mailAccountId: accountId,
        recipientMode,
        recentDays: followUp ? undefined : (recentDays || undefined),
        bypassWhitelist,
        onlyKeys,
        ratePerMinute,
        scheduledAt: scheduledAt ? new Date(scheduledAt).toISOString() : undefined,
      });
      setConfirmOpen(false);
      if (!res.ok) { setError(res.errorMessage ?? 'Queue failed.'); return; }
      setNotice(`Queued ${res.total ?? onlyKeys.length} recipient(s). Press "Build next batch" for the next group.`);
      setPreview(null);
      void loadRuns();
    });
  };

  const addInclude = (code: string) => {
    const cur = new Set(splitCodes(includeCountries));
    if (cur.has(code)) cur.delete(code); else cur.add(code);
    setIncludeCountries(Array.from(cur).join(', '));
    reset();
  };

  const toSend = preview?.toSend.length ?? 0;
  const notWl = preview?.counts.notWhitelisted ?? 0;
  const blockedByWl = !bypassWhitelist && notWl > 0;

  return (
    <div className="p-4 sm:p-6 space-y-6">
      <div className="flex items-center gap-2">
        <Megaphone className="h-5 w-5" />
        <h1 className="text-xl font-semibold">Marketing</h1>
      </div>
      <p className="text-sm text-muted-foreground">
        Send a template to a directory segment (e.g. all paper mills by country) in safe batches.
        Parties that already received the template, are queued, replied, unsubscribed or bounced are skipped.
      </p>

      {error && (
        <div className="flex items-start gap-2 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          <AlertTriangle className="mt-0.5 h-4 w-4" /> {error}
        </div>
      )}
      {notice && (
        <div className="flex items-start gap-2 rounded-md border border-green-200 bg-green-50 p-3 text-sm text-green-800">
          <CheckCircle2 className="mt-0.5 h-4 w-4" /> {notice}
        </div>
      )}

      {/* ---- 1. Segment ---- */}
      <Card>
        <CardHeader><CardTitle className="text-base">1. Segment</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label>Party type</Label>
            <select className={inputCls} value={partyTypeCode} onChange={(e) => { setPartyTypeCode(e.target.value); reset(); }}>
              {partyTypes.map((p) => (<option key={p.code} value={p.code}>{p.name}</option>))}
            </select>
          </div>
          <div className="space-y-1.5">
            <Label>Batch size (max 150)</Label>
            <select className={inputCls} value={batchSize} onChange={(e) => { setBatchSize(Number(e.target.value)); reset(); }}>
              {[25, 50, 100, 150].map((n) => (<option key={n} value={n}>{n} parties</option>))}
            </select>
          </div>
          <div className="space-y-1.5">
            <Label>Include countries (ISO-2, comma separated; empty = all)</Label>
            <input className={inputCls} value={includeCountries} placeholder="US, CN, BR, IN"
              onChange={(e) => { setIncludeCountries(e.target.value); reset(); }} />
          </div>
          <div className="space-y-1.5">
            <Label>Exclude countries</Label>
            <input className={inputCls} value={excludeCountries}
              onChange={(e) => { setExcludeCountries(e.target.value); reset(); }} />
            <p className="text-xs text-muted-foreground">Default KR, DE, AT: cold e-mail needs prior consent there. Contact those mills directly.</p>
          </div>
          <div className="space-y-1.5">
            <Label>Keyword (name / grade / products)</Label>
            <input className={inputCls} value={keyword} placeholder="e.g. printing, tissue, newsprint"
              onChange={(e) => { setKeyword(e.target.value); reset(); }} />
          </div>
          <div className="space-y-1.5">
            <Label>Supplied by (filler supplier name)</Label>
            <input className={inputCls} value={supplierQuery} placeholder="e.g. Omya, Minerals Technologies, Imerys"
              onChange={(e) => { setSupplierQuery(e.target.value); reset(); }} />
          </div>
          <div className="space-y-1.5">
            <Label>Licensee host mills (Omya / Specialty Minerals)</Label>
            <select className={inputCls} value={licenseeHosts}
              onChange={(e) => { setLicenseeHosts(e.target.value as 'exclude_all' | 'exclude_active' | 'include'); reset(); }}>
              <option value="exclude_all">Exclude: active + potential links</option>
              <option value="exclude_active">Exclude: active links only</option>
              <option value="include">Include (no licensee filter)</option>
            </select>
            <p className="text-xs text-muted-foreground">Read live from supply links. These mills are approached through the licensee HQ talks.</p>
          </div>
        </CardContent>
      </Card>

      {/* ---- 2. Message ---- */}
      <Card>
        <CardHeader><CardTitle className="text-base">2. Message &amp; sending</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Template to send</Label>
              <select className={inputCls} value={templateId} onChange={(e) => { setTemplateId(e.target.value); reset(); }}>
                <option value="">Select template</option>
                {moduleTemplates.map((t) => (<option key={t.id} value={t.id}>{t.name}</option>))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label>From</Label>
              <select className={inputCls} value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                {accounts.map((a) => (<option key={a.id} value={a.id}>{a.displayName ? `${a.displayName} <${a.address}>` : a.address}</option>))}
              </select>
            </div>
          </div>

          {tmpl && (
            <div className="rounded-md border bg-muted/30 p-3 text-sm">
              <div className="font-medium">Subject: {tmpl.subject}</div>
              <pre className="mt-2 max-h-56 overflow-auto whitespace-pre-wrap font-sans text-xs text-muted-foreground">{tmpl.body}</pre>
            </div>
          )}

          <div className="flex items-center gap-3">
            <Switch checked={followUp} onCheckedChange={(v) => { setFollowUp(v); reset(); }} />
            <span className="text-sm">Follow-up: only parties that received an earlier template (replies are excluded automatically)</span>
          </div>
          {followUp && (
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Earlier template</Label>
                <select className={inputCls} value={receivedTemplateId} onChange={(e) => { setReceivedTemplateId(e.target.value); reset(); }}>
                  <option value="">Select template</option>
                  {moduleTemplates.filter((t) => t.id !== templateId).map((t) => (<option key={t.id} value={t.id}>{t.name}</option>))}
                </select>
              </div>
              <div className="space-y-1.5">
                <Label>Sent at least N days ago</Label>
                <input type="number" min={0} max={365} className={inputCls} value={receivedMinDays}
                  onChange={(e) => { setReceivedMinDays(Number(e.target.value) || 0); reset(); }} />
              </div>
            </div>
          )}

          <div className="grid gap-4 sm:grid-cols-4">
            <div className="space-y-1.5">
              <Label>Recipients per party</Label>
              <select className={inputCls} value={recipientMode} onChange={(e) => { setRecipientMode(e.target.value as RecipientMode); reset(); }}>
                <option value="primary">Primary contact</option>
                <option value="all_contacts">All contacts</option>
              </select>
            </div>
            <div className="space-y-1.5">
              <Label>Skip if any mail in last</Label>
              <select className={inputCls} value={recentDays} disabled={followUp} onChange={(e) => { setRecentDays(Number(e.target.value)); reset(); }}>
                {[0, 7, 14, 30, 90].map((d) => (<option key={d} value={d}>{d === 0 ? 'Off' : `${d} days`}</option>))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label>Rate</Label>
              <select className={inputCls} value={ratePerMinute} onChange={(e) => setRatePerMinute(Number(e.target.value))}>
                {[5, 10, 15, 30].map((r) => (<option key={r} value={r}>{r} / min</option>))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label>Schedule (local)</Label>
              <div className="flex gap-1">
                <input type="datetime-local" className={inputCls} value={scheduledAt} onChange={(e) => setScheduledAt(e.target.value)} />
                <Button type="button" variant="outline" size="sm" onClick={() => setScheduledAt(nextGoodSendLocal())} title="Next Tue-Thu 09:00">
                  <Clock className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Switch checked={bypassWhitelist} onCheckedChange={setBypassWhitelist} />
            <span className="text-sm">Send to non-whitelisted addresses (required for new outreach)</span>
          </div>

          <div className="flex gap-2">
            <Button type="button" onClick={buildBatch} disabled={pending || !templateId}>
              {segment ? <RefreshCw className="mr-2 h-4 w-4" /> : <Layers className="mr-2 h-4 w-4" />}
              {segment ? 'Build next batch' : 'Build batch'}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* ---- 3. Segment summary ---- */}
      {segment && (
        <Card>
          <CardHeader><CardTitle className="text-base">3. Segment</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-wrap gap-2 text-sm">
              <Badge variant="outline">In type: {segment.totalInType}</Badge>
              <Badge variant="outline">Matched filters: {segment.matched}</Badge>
              <Badge variant="outline">With e-mail: {segment.withEmail}</Badge>
              <Badge variant="outline">Already sent: {segment.alreadySent}</Badge>
              <Badge variant="outline">In queue: {segment.inQueue}</Badge>
              <Badge variant="outline">Do-not-send: {segment.doNotSend}</Badge>
              <Badge variant="outline">Licensee hosts excluded: {segment.licenseeExcluded}</Badge>
              <Badge>Remaining: {segment.remaining}</Badge>
              <Badge variant="secondary">This batch: {segment.batchPartyIds.length}</Badge>
            </div>
            <div>
              <div className="mb-1 text-xs text-muted-foreground">Countries (whole type, with e-mail / total). Click to toggle include.</div>
              <div className="flex flex-wrap gap-1.5">
                {segment.countries.slice(0, 60).map((c) => {
                  const on = splitCodes(includeCountries).includes(c.key);
                  return (
                    <button key={c.key} type="button" onClick={() => addInclude(c.key)}
                      className={'rounded-full border px-2 py-0.5 text-xs ' + (on ? 'border-blue-600 bg-blue-50 text-blue-700' : 'hover:bg-muted')}>
                      {c.key} {c.withEmail}/{c.parties}
                    </button>
                  );
                })}
              </div>
            </div>
            {segment.categories.length > 0 && (
              <div>
                <div className="mb-1 text-xs text-muted-foreground">Product categories (click to use as keyword)</div>
                <div className="flex flex-wrap gap-1.5">
                  {segment.categories.slice(0, 30).map((c) => (
                    <button key={c.key} type="button" onClick={() => { setKeyword(c.key === '(none)' ? '' : c.key); reset(); }}
                      className="rounded-full border px-2 py-0.5 text-xs hover:bg-muted">
                      {c.key} {c.withEmail}/{c.parties}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* ---- 4. Batch preview ---- */}
      {preview && (
        <Card>
          <CardHeader><CardTitle className="text-base">4. Batch preview</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-wrap gap-2 text-sm">
              <Badge>To send: {toSend}</Badge>
              <Badge variant="outline">No e-mail: {preview.counts.noEmail}</Badge>
              <Badge variant="outline">Recently contacted: {preview.counts.recentlyContacted}</Badge>
              <Badge variant="outline">Bounced: {preview.counts.bounced}</Badge>
              <Badge variant="outline">Blocklisted: {preview.counts.blocklisted}</Badge>
              <Badge variant="outline">Do-not-send: {preview.counts.doNotSend}</Badge>
              <Badge variant="outline">Not whitelisted: {notWl}</Badge>
            </div>
            {blockedByWl && (
              <p className="text-sm text-amber-700">{notWl} recipient(s) are not whitelisted and will be blocked unless the switch above is on.</p>
            )}
            <div className="max-h-80 overflow-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow><TableHead>Company</TableHead><TableHead>E-mail</TableHead><TableHead>Status</TableHead></TableRow>
                </TableHeader>
                <TableBody>
                  {preview.candidates.map((c) => (
                    <TableRow key={c.key}>
                      <TableCell className="text-sm">{c.partyName}</TableCell>
                      <TableCell className="text-sm">{c.email ?? '-'}</TableCell>
                      <TableCell className="text-xs">{c.excludeReason ? <span className="text-muted-foreground">{c.excludeReason}</span> : 'send'}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
            <Button type="button" onClick={() => setConfirmOpen(true)} disabled={pending || toSend === 0}>
              <Send className="mr-2 h-4 w-4" /> Queue {toSend}
            </Button>
          </CardContent>
        </Card>
      )}

      {/* ---- Runs ---- */}
      {runs.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-base">Recent runs <span className="text-xs font-normal text-muted-foreground">(click a row for details)</span></CardTitle></CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow><TableHead>Created</TableHead><TableHead>Status</TableHead><TableHead>Sent</TableHead><TableHead>Failed</TableHead><TableHead>Blocked</TableHead><TableHead>Total</TableHead></TableRow>
              </TableHeader>
              <TableBody>
                {runs.map((r) => (
                  <TableRow key={r.id} onClick={() => setDetailRunId(r.id)} className="cursor-pointer hover:bg-muted/50" title="Show recipients">
                    <TableCell className="text-xs">{new Date(r.createdAt).toLocaleString()}</TableCell>
                    <TableCell className="text-xs">{r.status}</TableCell>
                    <TableCell className="text-xs">{r.sent}</TableCell>
                    <TableCell className="text-xs">{r.failed}</TableCell>
                    <TableCell className="text-xs">{r.blocked}</TableCell>
                    <TableCell className="text-xs">{r.total}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      <MailRunDetailDialog runId={detailRunId} onOpenChange={(o) => { if (!o) setDetailRunId(null); }} />

      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Queue this batch?</DialogTitle></DialogHeader>
          <div className="space-y-1 text-sm">
            <p>Template: <b>{tmpl?.name}</b></p>
            <p>Recipients: <b>{toSend}</b> at {ratePerMinute}/min</p>
            <p>{scheduledAt ? `Scheduled: ${new Date(scheduledAt).toLocaleString()}` : 'Starts as soon as the worker picks it up.'}</p>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setConfirmOpen(false)}>Cancel</Button>
            <Button type="button" onClick={queueBatch} disabled={pending}>Queue</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
