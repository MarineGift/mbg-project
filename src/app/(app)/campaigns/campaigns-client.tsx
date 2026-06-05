'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Plus, Trash2 } from 'lucide-react';
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

  const [name, setName] = useState('');
  const [type, setType] = useState('');
  const [status, setStatus] = useState<'active' | 'closed' | 'archived'>('active');
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [color, setColor] = useState(COLORS[0]);

  const reset = () => { setName(''); setType(''); setStatus('active'); setStart(''); setEnd(''); setColor(COLORS[0]); setError(null); };

  const submit = () => {
    if (!name.trim()) { setError('이름을 입력하세요'); return; }
    startTransition(async () => {
      const res = await createCampaign({
        name, campaignType: type || null, status,
        startDate: start || null, endDate: end || null, color,
      });
      if (!res.ok) { setError(res.errorMessage ?? '저장 실패'); return; }
      reset(); setOpen(false); router.refresh();
    });
  };

  const remove = (id: string) => {
    if (!confirm('이 캠페인을 삭제할까요? (딜은 삭제되지 않고 연결만 해제됩니다)')) return;
    startTransition(async () => {
      await deleteCampaign({ campaignId: id });
      router.refresh();
    });
  };

  const inputCls = 'w-full rounded-md border px-3 py-2 text-sm bg-background';

  return (
    <div className="p-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Campaigns</h1>
          <p className="text-sm text-muted-foreground">딜을 묶는 캠페인 — 영업·투자유치·제휴 등</p>
        </div>
        <Dialog open={open} onOpenChange={(o) => { setOpen(o); if (!o) reset(); }}>
          <DialogTrigger asChild>
            <Button size="sm"><Plus className="mr-1 h-4 w-4" />새 캠페인</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader><DialogTitle>새 캠페인</DialogTitle></DialogHeader>
            <div className="space-y-3">
              <input className={inputCls} placeholder="이름 *" value={name} onChange={(e) => setName(e.target.value)} />
              <input className={inputCls} placeholder="유형 (예: fundraising, filler_sales)" value={type} onChange={(e) => setType(e.target.value)} />
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
                    className={`h-6 w-6 rounded-full border-2 ${color === c ? 'border-foreground' : 'border-transparent'}`}
                    style={{ backgroundColor: c }} aria-label={c} />
                ))}
              </div>
              {error && <p className="text-sm text-red-600">{error}</p>}
            </div>
            <DialogFooter>
              <Button variant="ghost" onClick={() => setOpen(false)}>취소</Button>
              <Button onClick={submit} disabled={pending}>{pending ? '저장 중...' : '저장'}</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <div className="overflow-x-auto rounded-md border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left text-muted-foreground">
            <tr>
              <th className="px-3 py-2 font-medium">캠페인</th>
              <th className="px-3 py-2 font-medium">유형</th>
              <th className="px-3 py-2 font-medium">상태</th>
              <th className="px-3 py-2 font-medium">기간</th>
              <th className="px-3 py-2 text-right font-medium">딜</th>
              <th className="px-3 py-2 text-right font-medium">합계</th>
              <th className="px-3 py-2 text-right font-medium">가중예측</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {initialCampaigns.length === 0 && (
              <tr><td colSpan={8} className="px-3 py-8 text-center text-muted-foreground">아직 캠페인이 없습니다.</td></tr>
            )}
            {initialCampaigns.map((c) => (
              <tr key={c.id} className="border-t">
                <td className="px-3 py-2">
                  <span className="inline-flex items-center gap-2">
                    <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: c.color ?? '#94a3b8' }} />
                    {c.name}
                  </span>
                </td>
                <td className="px-3 py-2 text-muted-foreground">{c.campaign_type ?? '-'}</td>
                <td className="px-3 py-2">{c.status}</td>
                <td className="px-3 py-2 text-muted-foreground">{c.start_date ?? '?'} ~ {c.end_date ?? '?'}</td>
                <td className="px-3 py-2 text-right tabular-nums">{c.deal_count}</td>
                <td className="px-3 py-2 text-right tabular-nums">{fmt(c.total_value)}</td>
                <td className="px-3 py-2 text-right tabular-nums">{fmt(c.weighted_forecast)}</td>
                <td className="px-3 py-2 text-right">
                  <button onClick={() => remove(c.id)} className="text-muted-foreground hover:text-red-600" aria-label="삭제">
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
