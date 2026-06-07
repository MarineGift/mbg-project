'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { ChevronLeft, Pencil, Plus, Trash2, Search, X } from 'lucide-react';
import {
  Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import {
  updateCampaign, addCampaignDeals, removeCampaignDeal, setDealStage, searchPartiesForCampaign,
} from '@/lib/actions/campaigns';

type Campaign = {
  id: string; name: string; campaign_type: string | null; description: string | null;
  status: string; start_date: string | null; end_date: string | null; color: string | null;
};
type Forecast = { deal_count: number; total_value: number; weighted_forecast: number };
type Deal = {
  id: string; deal_name: string; value_amount: number | null; value_currency: string | null;
  status: string; current_stage_id: string | null; pipeline_id: string | null; companies: string[];
};
type PipelineOpt = { id: string; code: string; name: string };
type Stage = { id: string; name: string; pipeline_id: string; sort_order: number };
type PartyHit = { id: string; party_name: string; country_code: string | null; party_type_id: number | null };

const COLORS = ['#2563eb', '#16a34a', '#f59e0b', '#8b5cf6', '#dc2626', '#0ea5e9', '#94a3b8'];
const fmtMoney = (n: number | null, cur: string | null) => (cur ? cur + ' ' : '') + (n ?? 0).toLocaleString();
const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';

export function CampaignDetailClient({
  campaign, forecast, deals, pipelines, stages, partyTypeMap,
}: {
  campaign: Campaign;
  forecast: Forecast;
  deals: Deal[];
  pipelines: PipelineOpt[];
  stages: Stage[];
  partyTypeMap: Record<string, string>;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  const pipelineById = new Map(pipelines.map((p) => [p.id, p]));
  const stagesByPipeline = new Map<string, Stage[]>();
  for (const s of stages) {
    const arr = stagesByPipeline.get(s.pipeline_id) ?? [];
    arr.push(s);
    stagesByPipeline.set(s.pipeline_id, arr);
  }
  for (const arr of stagesByPipeline.values()) arr.sort((a, b) => a.sort_order - b.sort_order);

  // ---- edit campaign ----
  const [editOpen, setEditOpen] = useState(false);
  const [eName, setEName] = useState(campaign.name);
  const [eType, setEType] = useState(campaign.campaign_type ?? '');
  const [eStatus, setEStatus] = useState<'active' | 'closed' | 'archived'>((campaign.status as 'active' | 'closed' | 'archived') ?? 'active');
  const [eStart, setEStart] = useState(campaign.start_date ?? '');
  const [eEnd, setEEnd] = useState(campaign.end_date ?? '');
  const [eColor, setEColor] = useState(campaign.color ?? COLORS[0]);
  const [eDesc, setEDesc] = useState(campaign.description ?? '');
  const [eError, setEError] = useState<string | null>(null);

  const submitEdit = () => {
    if (!eName.trim()) { setEError('Enter a name'); return; }
    startTransition(async () => {
      const res = await updateCampaign({
        campaignId: campaign.id, name: eName, campaignType: eType || null,
        description: eDesc || null, status: eStatus,
        startDate: eStart || null, endDate: eEnd || null, color: eColor,
      });
      if (!res.ok) { setEError(res.errorMessage ?? 'Failed to save'); return; }
      setEditOpen(false); router.refresh();
    });
  };

  // ---- add companies ----
  const [addOpen, setAddOpen] = useState(false);
  const defaultPipeline = deals.find((d) => d.pipeline_id)?.pipeline_id;
  const defaultCode = (defaultPipeline && pipelineById.get(defaultPipeline)?.code) || pipelines[0]?.code || '';
  const [pipelineCode, setPipelineCode] = useState(defaultCode);
  const [companyQuery, setCompanyQuery] = useState('');
  const [results, setResults] = useState<PartyHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<Map<string, PartyHit>>(new Map());
  const [addError, setAddError] = useState<string | null>(null);

  useEffect(() => {
    if (!addOpen) return;
    const q = companyQuery.trim();
    let active = true;
    setSearching(true);
    const t = setTimeout(async () => {
      const res = await searchPartiesForCampaign({ query: q, limit: 30 });
      if (!active) return;
      setResults(res.ok ? res.parties : []);
      setSearching(false);
    }, 250);
    return () => { active = false; clearTimeout(t); };
  }, [companyQuery, addOpen]);

  const resetAdd = () => { setCompanyQuery(''); setResults([]); setSelected(new Map()); setAddError(null); setPipelineCode(defaultCode); };

  const submitAdd = () => {
    if (selected.size === 0) { setAddError('Pick at least one company'); return; }
    if (!pipelineCode) { setAddError('Pick a pipeline'); return; }
    startTransition(async () => {
      const res = await addCampaignDeals({
        campaignId: campaign.id, pipelineCode, partyIds: Array.from(selected.keys()),
      });
      if (!res.ok) { setAddError(res.errorMessage ?? 'Failed to add'); return; }
      resetAdd(); setAddOpen(false); router.refresh();
    });
  };

  // ---- per-deal stage change / remove ----
  const changeStage = (dealId: string, stageId: string) => {
    if (!stageId) return;
    startTransition(async () => { await setDealStage({ dealId, stageId }); router.refresh(); });
  };
  const removeDeal = (dealId: string) => {
    if (!confirm('Remove this company from the campaign? (The deal is deleted.)')) return;
    startTransition(async () => { await removeCampaignDeal({ dealId }); router.refresh(); });
  };

  const selectedArr = Array.from(selected.values());

  return (
    <div className="flex h-full flex-col">
      <div className="border-b bg-background px-6 py-4">
        <Link href="/campaigns" className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground">
          <ChevronLeft className="h-3 w-3" /> Campaigns
        </Link>
        <div className="mt-1 flex items-start justify-between gap-4">
          <div>
            <h1 className="flex items-center gap-2 text-xl font-semibold text-foreground">
              <span className="h-3 w-3 rounded-full" style={{ backgroundColor: campaign.color ?? '#94a3b8' }} />
              {campaign.name}
            </h1>
            <div className="mt-1 flex flex-wrap items-center gap-x-2 text-xs text-muted-foreground">
              <span>{campaign.campaign_type ?? 'campaign'}</span>
              <span className="opacity-40">·</span>
              <span>{campaign.status}</span>
              <span className="opacity-40">·</span>
              <span>{campaign.start_date ?? '?'} ~ {campaign.end_date ?? '?'}</span>
            </div>
            {campaign.description ? (
              <p className="mt-2 max-w-2xl text-sm text-muted-foreground">{campaign.description}</p>
            ) : null}
          </div>
          <Button size="sm" variant="outline" onClick={() => setEditOpen(true)}>
            <Pencil className="mr-1 h-4 w-4" /> Edit
          </Button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="mb-6 grid grid-cols-3 gap-3">
          <Stat label="Deals" value={String(forecast.deal_count)} />
          <Stat label="Total value" value={fmtMoney(forecast.total_value, null)} />
          <Stat label="Weighted forecast" value={fmtMoney(forecast.weighted_forecast, null)} />
        </div>

        <div className="rounded-lg border bg-card">
          <div className="flex items-center justify-between border-b px-4 py-2">
            <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">Deals in this campaign</span>
            <Button size="sm" onClick={() => { resetAdd(); setAddOpen(true); }}>
              <Plus className="mr-1 h-4 w-4" /> Add company
            </Button>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/30 text-xs text-muted-foreground">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Deal</th>
                <th className="px-4 py-2 text-left font-medium">Companies</th>
                <th className="px-4 py-2 text-left font-medium">Pipeline</th>
                <th className="px-4 py-2 text-left font-medium">Stage</th>
                <th className="px-4 py-2 text-right font-medium">Value</th>
                <th className="px-4 py-2"></th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {deals.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">No deals linked yet.</td></tr>
              )}
              {deals.map((d) => {
                const p = d.pipeline_id ? pipelineById.get(d.pipeline_id) : undefined;
                const pstages = d.pipeline_id ? (stagesByPipeline.get(d.pipeline_id) ?? []) : [];
                return (
                  <tr key={d.id} className="hover:bg-muted/30">
                    <td className="px-4 py-2 font-medium">
                      {p ? (
                        <Link href={'/pipelines/' + p.code + '/deals/' + d.id} className="hover:underline">{d.deal_name}</Link>
                      ) : d.deal_name}
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">
                      {d.companies.length === 0 ? '-' : d.companies.length === 1 ? d.companies[0] : `${d.companies[0]} +${d.companies.length - 1}`}
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">{p?.name ?? '-'}</td>
                    <td className="px-4 py-2">
                      {pstages.length > 0 ? (
                        <select
                          className="rounded border bg-background px-2 py-1 text-xs"
                          value={d.current_stage_id ?? ''}
                          disabled={pending}
                          onChange={(e) => changeStage(d.id, e.target.value)}
                        >
                          {pstages.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
                        </select>
                      ) : <span className="text-muted-foreground">-</span>}
                    </td>
                    <td className="px-4 py-2 text-right tabular-nums">{fmtMoney(d.value_amount, d.value_currency)}</td>
                    <td className="px-4 py-2 text-right">
                      <button onClick={() => removeDeal(d.id)} className="text-muted-foreground hover:text-red-600" aria-label="Remove">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit campaign dialog */}
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit campaign</DialogTitle></DialogHeader>
          <div className="space-y-3">
            <input className={inputCls} placeholder="Name *" value={eName} onChange={(e) => setEName(e.target.value)} />
            <input className={inputCls} placeholder="Type" value={eType} onChange={(e) => setEType(e.target.value)} />
            <textarea className={inputCls} placeholder="Description" rows={2} value={eDesc} onChange={(e) => setEDesc(e.target.value)} />
            <div className="flex gap-2">
              <input type="date" className={inputCls} value={eStart} onChange={(e) => setEStart(e.target.value)} />
              <input type="date" className={inputCls} value={eEnd} onChange={(e) => setEEnd(e.target.value)} />
            </div>
            <select className={inputCls} value={eStatus} onChange={(e) => setEStatus(e.target.value as typeof eStatus)}>
              <option value="active">active</option>
              <option value="closed">closed</option>
              <option value="archived">archived</option>
            </select>
            <div className="flex items-center gap-2">
              {COLORS.map((c) => (
                <button key={c} type="button" onClick={() => setEColor(c)}
                  className={'h-6 w-6 rounded-full border-2 ' + (eColor === c ? 'border-foreground' : 'border-transparent')}
                  style={{ backgroundColor: c }} aria-label={c} />
              ))}
            </div>
            {eError && <p className="text-sm text-red-600">{eError}</p>}
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={() => setEditOpen(false)}>Cancel</Button>
            <Button onClick={submitEdit} disabled={pending}>{pending ? 'Saving...' : 'Save'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add companies dialog */}
      <Dialog open={addOpen} onOpenChange={(o) => { setAddOpen(o); if (!o) resetAdd(); }}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>Add companies</DialogTitle></DialogHeader>
          <div className="space-y-3">
            <select className={inputCls} value={pipelineCode} onChange={(e) => setPipelineCode(e.target.value)}>
              {pipelines.length === 0 && <option value="">No pipelines</option>}
              {pipelines.map((p) => <option key={p.code} value={p.code}>Place in: {p.name} (stage 1)</option>)}
            </select>
            <div className="flex items-center gap-2 rounded-md border bg-background px-2 py-1.5">
              <Search className="h-4 w-4 text-muted-foreground" />
              <input value={companyQuery} onChange={(e) => setCompanyQuery(e.target.value)}
                placeholder="Search companies by name..." className="w-full bg-transparent text-sm focus:outline-none" />
            </div>
            {(searching || results.length > 0) && (
              <div className="max-h-48 overflow-y-auto rounded-md border divide-y">
                {searching && <div className="px-3 py-2 text-xs text-muted-foreground">Searching...</div>}
                {!searching && results.map((r) => {
                  const picked = selected.has(r.id);
                  const typeCode = r.party_type_id != null ? (partyTypeMap[String(r.party_type_id)] ?? '') : '';
                  return (
                    <button key={r.id} type="button" disabled={picked} onClick={() => setSelected((prev) => new Map(prev).set(r.id, r))}
                      className={'flex w-full items-center justify-between px-3 py-1.5 text-left text-sm hover:bg-muted/40 ' + (picked ? 'opacity-40' : '')}>
                      <span className="truncate">{r.party_name}</span>
                      <span className="ml-2 shrink-0 text-xs text-muted-foreground">{typeCode}{r.country_code ? ` · ${r.country_code}` : ''}</span>
                    </button>
                  );
                })}
              </div>
            )}
            {selectedArr.length > 0 && (
              <div className="flex flex-wrap gap-1">
                {selectedArr.map((p) => (
                  <span key={p.id} className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs">
                    {p.party_name}
                    <button type="button" onClick={() => setSelected((prev) => { const n = new Map(prev); n.delete(p.id); return n; })}
                      className="text-muted-foreground hover:text-red-600"><X className="h-3 w-3" /></button>
                  </span>
                ))}
              </div>
            )}
            {addError && <p className="text-sm text-red-600">{addError}</p>}
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={() => setAddOpen(false)}>Cancel</Button>
            <Button onClick={submitAdd} disabled={pending}>{pending ? 'Adding...' : `Add ${selected.size || ''}`.trim()}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="text-xs uppercase tracking-wider text-muted-foreground">{label}</div>
      <div className="mt-1 text-2xl font-semibold tabular-nums text-foreground">{value}</div>
    </div>
  );
}
