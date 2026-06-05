'use client';

import { useMemo, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Plus, Trash2, Search } from 'lucide-react';
import {
  Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { createCampaign, deleteCampaign } from '@/lib/actions/campaigns';

type Row = {
  id: string; name: string; campaign_type: string | null; description: string | null;
  status: string; start_date: string | null; end_date: string | null; color: string | null;
  deal_count: number; total_value: number; weighted_forecast: number;
};

const COLORS = ['#2563eb', '#16a34a', '#f59e0b', '#8b5cf6', '#dc2626', '#0ea5e9', '#94a3b8'];
const fmt = (n: number) => (n ?? 0).toLocaleString();

export function CampaignsClient({ initialCampaigns }: { initialCampaigns: Row[] }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState('');

  const [name, setName] = useState('');
  const [type, setType] = useState('');
  const [status, setStatus] = useState<'active' | 'closed' | 'archived'>('active');
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [color, setColor] = useState(COLORS[0]);

  const reset = () => { setName(''); setType(''); setStatus('active'); setStart(''); setEnd(''); setColor(COLORS[0]); setError(null); };

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return initialCampaigns;
    return initialCampaigns.filter(
      (c) => c.name.toLowerCase().includes(q) || (c.campaign_type ?? '').toLowerCase().includes(q),
    );
  }, [initialCampaigns, query]);

  const submit = () => {
    if (!name.trim()) { setError('Enter a name'); return; }
    startTransition(async () => {
      const res = await createCampaign({
        name, campaignType: type || null, status,
        startDate: start || null, endDate: end || null, color,
      });
      if (!res.ok) { setError(res.errorMessage ?? 'Failed to save'); return; }
      reset(); setOpen(false); router.refresh();
    });
  };

  const remove = (e: React.MouseEvent, id: string) => {
    e.preventDefault(); e.stopPropagation();
    if (!confirm('Delete this campaign? (Deals are not deleted; they are just unlinked.)')) return;
    startTransition(async () => { await deleteCampaign({ campaignId: id }); router.refresh(); });
  };

  const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';

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
          <DialogContent>
            <DialogHeader><DialogTitle>New campaign</DialogTitle></DialogHeader>
            <div className="space-y-3">
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
                  <button onClick={(e) => remove(e, c.id)} className="text-muted-foreground hover:text-red-600" aria-label="Delete">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
