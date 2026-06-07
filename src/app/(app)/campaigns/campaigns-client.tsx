'use client';

import { useEffect, useMemo, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Plus, Trash2, Search, Pencil, X } from 'lucide-react';
import {
  Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import {
  createCampaign, updateCampaign, deleteCampaign, searchPartiesForCampaign,
} from '@/lib/actions/campaigns';

type Row = {
  id: string; name: string; campaign_type: string | null; description: string | null;
  status: string; start_date: string | null; end_date: string | null; color: string | null;
  deal_count: number; total_value: number; weighted_forecast: number;
};
type PipelineOpt = { code: string; name: string };
type PartyHit = { id: string; party_name: string; country_code: string | null; party_type_id: number | null };

const COLORS = ['#2563eb', '#16a34a', '#f59e0b', '#8b5cf6', '#dc2626', '#0ea5e9', '#94a3b8'];
const fmt = (n: number) => (n ?? 0).toLocaleString();
const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';

export function CampaignsClient({
  initialCampaigns,
  pipelines,
  partyTypeMap,
}: {
  initialCampaigns: Row[];
  pipelines: PipelineOpt[];
  partyTypeMap: Record<string, string>;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [query, setQuery] = useState('');

  // ---- create dialog state ----
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [type, setType] = useState('');
  const [status, setStatus] = useState<'active' | 'closed' | 'archived'>('active');
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [color, setColor] = useState(COLORS[0]);
  const [pipelineCode, setPipelineCode] = useState(pipelines[0]?.code ?? '');

  // company picker
  const [companyQuery, setCompanyQuery] = useState('');
  const [results, setResults] = useState<PartyHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<Map<string, PartyHit>>(new Map());

  const reset = () => {
    setName(''); setType(''); setStatus('active'); setStart(''); setEnd('');
    setColor(COLORS[0]); setPipelineCode(pipelines[0]?.code ?? '');
    setCompanyQuery(''); setResults([]); setSelected(new Map()); setError(null);
  };

  // debounced company search
  useEffect(() => {
    if (!open) return;
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
  }, [companyQuery, open]);

  const addParty = (p: PartyHit) => {
    setSelected((prev) => {
      const next = new Map(prev);
      next.set(p.id, p);
      return next;
    });
  };
  const removeParty = (id: string) => {
    setSelected((prev) => {
      const next = new Map(prev);
      next.delete(id);
      return next;
    });
  };

  const submit = () => {
    if (!name.trim()) { setError('Enter a name'); return; }
    if (selected.size > 0 && !pipelineCode) {
      setError('Pick a pipeline to place the selected companies'); return;
    }
    startTransition(async () => {
      const res = await createCampaign({
        name, campaignType: type || null, status,
        startDate: start || null, endDate: end || null, color,
        pipelineCode: selected.size > 0 ? pipelineCode : null,
        partyIds: Array.from(selected.keys()),
      });
      if (!res.ok) { setError(res.errorMessage ?? 'Failed to save'); return; }
      if (res.errorMessage) { setError(`Campaign saved, but deals failed: ${res.errorMessage}`); }
      reset(); setOpen(false); router.refresh();
    });
  };

  // ---- edit dialog state ----
  const [editing, setEditing] = useState<Row | null>(null);
  const [eName, setEName] = useState('');
  const [eType, setEType] = useState('');
  const [eStatus, setEStatus] = useState<'active' | 'closed' | 'archived'>('active');
  const [eStart, setEStart] = useState('');
  const [eEnd, setEEnd] = useState('');
  const [eColor, setEColor] = useState(COLORS[0]);
  const [eError, setEError] = useState<string | null>(null);

  const openEdit = (e: React.MouseEvent, c: Row) => {
    e.preventDefault(); e.stopPropagation();
    setEditing(c);
    setEName(c.name); setEType(c.campaign_type ?? '');
    setEStatus((c.status as 'active' | 'closed' | 'archived') ?? 'active');
    setEStart(c.start_date ?? ''); setEEnd(c.end_date ?? '');
    setEColor(c.color ?? COLORS[0]); setEError(null);
  };

  const submitEdit = () => {
    if (!editing) return;
    if (!eName.trim()) { setEError('Enter a name'); return; }
    startTransition(async () => {
      const res = await updateCampaign({
        campaignId: editing.id, name: eName, campaignType: eType || null,
        status: eStatus, startDate: eStart || null, endDate: eEnd || null, color: eColor,
      });
      if (!res.ok) { setEError(res.errorMessage ?? 'Failed to save'); return; }
      setEditing(null); router.refresh();
    });
  };

  const remove = (e: React.MouseEvent, id: string) => {
    e.preventDefault(); e.stopPropagation();
    if (!confirm('Delete this campaign? (Deals are not deleted; they are just unlinked.)')) return;
    startTransition(async () => { await deleteCampaign({ campaignId: id }); router.refresh(); });
  };

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return initialCampaigns;
    return initialCampaigns.filter(
      (c) => c.name.toLowerCase().includes(q) || (c.campaign_type ?? '').toLowerCase().includes(q),
    );
  }, [initialCampaigns, query]);

  const selectedArr = Array.from(selected.values());

  return (
    <div className="p-6">
      <div className="mb-4 flex items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold">Campaigns</h1>
          <p className="text-sm text-muted-foreground">Group deals into sales, fundraising, or outreach campaigns</p>
        </div>
        <Dialog open={open} onOpenChange={(o) => { setOpen(o); if (!o) reset(); }}>
          <DialogTrigger asChild>
            <Button size="sm"><Plus className="mr-1 h-4 w-4" />New campaign</Button>
          </DialogTrigger>
          <DialogContent className="max-w-lg">
            <DialogHeader><DialogTitle>New campaign</DialogTitle></DialogHeader>
            <div className="space-y-3 max-h-[70vh] overflow-y-auto pr-1">
              <input className={inputCls} placeholder="Name *" value={name} onChange={(e) => setName(e.target.value)} />
              <input className={inputCls} placeholder="Type (e.g. fundraising, filler_sales)" value={type} onChange={(e) => setType(e.target.value)} />
              <div className="flex gap-2">
                <input type="date" className={inputCls} value={start} onChange={(e) => setStart(e.target.value)} />
                <input type="date" className={inputCls} value={end} onChange={(e) => setEnd(e.target.value)} />
              </div>
              <select className={inputCls} value={status} onChange={(e) => setStatus(e.target.value as typeof status)}>
                <option value="active">active</option>
                <option value="closed">closed</option>
                <option value="archived">archived</option>
              </select>
              <div className="flex items-center gap-2">
                {COLORS.map((c) => (
                  <button key={c} type="button" onClick={() => setColor(c)}
                    className={'h-6 w-6 rounded-full border-2 ' + (color === c ? 'border-foreground' : 'border-transparent')}
                    style={{ backgroundColor: c }} aria-label={c} />
                ))}
              </div>

              {/* Companies -> deals at the pipeline's first stage */}
              <div className="rounded-md border p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium">Companies (added as deals at stage 1)</label>
                  <span className="text-xs text-muted-foreground">{selected.size} selected</span>
                </div>
                <select className={inputCls} value={pipelineCode} onChange={(e) => setPipelineCode(e.target.value)}>
                  {pipelines.length === 0 && <option value="">No pipelines</option>}
                  {pipelines.map((p) => (
                    <option key={p.code} value={p.code}>Place in: {p.name}</option>
                  ))}
                </select>
                <div className="flex items-center gap-2 rounded-md border bg-background px-2 py-1.5">
                  <Search className="h-4 w-4 text-muted-foreground" />
                  <input
                    value={companyQuery}
                    onChange={(e) => setCompanyQuery(e.target.value)}
                    placeholder="Search companies by name..."
                    className="w-full bg-transparent text-sm focus:outline-none"
                  />
                </div>
                {/* results */}
                {(searching || results.length > 0) && (
                  <div className="max-h-40 overflow-y-auto rounded-md border divide-y">
                    {searching && <div className="px-3 py-2 text-xs text-muted-foreground">Searching...</div>}
                    {!searching && results.map((r) => {
                      const picked = selected.has(r.id);
                      const typeCode = r.party_type_id != null ? (partyTypeMap[String(r.party_type_id)] ?? '') : '';
                      return (
                        <button key={r.id} type="button" onClick={() => addParty(r)} disabled={picked}
                          className={'flex w-full items-center justify-between px-3 py-1.5 text-left text-sm hover:bg-muted/40 ' + (picked ? 'opacity-40' : '')}>
                          <span className="truncate">{r.party_name}</span>
                          <span className="ml-2 shrink-0 text-xs text-muted-foreground">
                            {typeCode}{r.country_code ? ` · ${r.country_code}` : ''}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                )}
                {/* selected chips */}
                {selectedArr.length > 0 && (
                  <div className="flex flex-wrap gap-1 pt-1">
                    {selectedArr.map((p) => (
                      <span key={p.id} className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs">
                        {p.party_name}
                        <button type="button" onClick={() => removeParty(p.id)} className="text-muted-foreground hover:text-red-600">
                          <X className="h-3 w-3" />
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {error && <p className="text-sm text-red-600">{error}</p>}
            </div>
            <DialogFooter>
              <Button variant="ghost" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={submit} disabled={pending}>{pending ? 'Saving...' : 'Save'}</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Search */}
      <div className="mb-3 flex items-center gap-2 rounded-md border bg-background px-3 py-2">
        <Search className="h-4 w-4 text-muted-foreground" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search campaigns by name or type..."
          className="w-full bg-transparent text-sm focus:outline-none"
        />
      </div>

      <div className="overflow-x-auto rounded-md border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left text-muted-foreground">
            <tr>
              <th className="px-3 py-2 font-medium">Campaign</th>
              <th className="px-3 py-2 font-medium">Type</th>
              <th className="px-3 py-2 font-medium">Status</th>
              <th className="px-3 py-2 font-medium">Period</th>
              <th className="px-3 py-2 text-right font-medium">Deals</th>
              <th className="px-3 py-2 text-right font-medium">Total</th>
              <th className="px-3 py-2 text-right font-medium">Weighted</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={8} className="px-3 py-8 text-center text-muted-foreground">
                {query ? 'No campaigns match your search.' : 'No campaigns yet.'}
              </td></tr>
            )}
            {filtered.map((c) => (
              <tr key={c.id} className="border-t hover:bg-muted/30">
                <td className="px-3 py-2">
                  <Link href={'/campaigns/' + c.id} className="inline-flex items-center gap-2 font-medium hover:underline">
                    <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: c.color ?? '#94a3b8' }} />
                    {c.name}
                  </Link>
                </td>
                <td className="px-3 py-2 text-muted-foreground">{c.campaign_type ?? '-'}</td>
                <td className="px-3 py-2">{c.status}</td>
                <td className="px-3 py-2 text-muted-foreground">{c.start_date ?? '?'} ~ {c.end_date ?? '?'}</td>
                <td className="px-3 py-2 text-right tabular-nums">{c.deal_count}</td>
                <td className="px-3 py-2 text-right tabular-nums">{fmt(c.total_value)}</td>
                <td className="px-3 py-2 text-right tabular-nums">{fmt(c.weighted_forecast)}</td>
                <td className="px-3 py-2 text-right">
                  <div className="inline-flex items-center gap-2">
                    <button onClick={(e) => openEdit(e, c)} className="text-muted-foreground hover:text-foreground" aria-label="Edit">
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button onClick={(e) => remove(e, c.id)} className="text-muted-foreground hover:text-red-600" aria-label="Delete">
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Edit dialog */}
      <Dialog open={!!editing} onOpenChange={(o) => { if (!o) setEditing(null); }}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit campaign</DialogTitle></DialogHeader>
          <div className="space-y-3">
            <input className={inputCls} placeholder="Name *" value={eName} onChange={(e) => setEName(e.target.value)} />
            <input className={inputCls} placeholder="Type" value={eType} onChange={(e) => setEType(e.target.value)} />
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
            <Button variant="ghost" onClick={() => setEditing(null)}>Cancel</Button>
            <Button onClick={submitEdit} disabled={pending}>{pending ? 'Saving...' : 'Save'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
