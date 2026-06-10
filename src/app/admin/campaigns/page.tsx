import { webAdminClient, getSiteId } from '../web-admin-client';

export const dynamic = 'force-dynamic';

interface Campaign {
  id: string; title: string; goal_amount: number | null;
  raised_amount: number | null; backer_count: number | null; status: string;
}

async function loadCampaigns(): Promise<Campaign[]> {
  const sb = webAdminClient();
  const siteId = await getSiteId();
  if (!siteId) return [];
  const { data } = await sb
    .schema('web').from('campaigns' as never)
    .select('id, title, goal_amount, raised_amount, backer_count, status')
    .eq('site_id', siteId);
  return (data ?? []) as Campaign[];
}

export default async function AdminCampaigns() {
  const campaigns = await loadCampaigns();
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Campaigns</h1>
      <div className="grid gap-4">
        {campaigns.map((c) => {
          const goal = Number(c.goal_amount ?? 0);
          const raised = Number(c.raised_amount ?? 0);
          const pct = goal > 0 ? Math.min(100, Math.round((raised / goal) * 100)) : 0;
          return (
            <div key={c.id} className="rounded-xl border border-slate-200 bg-white p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-semibold text-slate-900">{c.title}</h2>
                <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">{c.status}</span>
              </div>
              <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-emerald-500" style={{ width: `${pct}%` }} />
              </div>
              <div className="flex justify-between text-sm text-slate-500 mt-2">
                <span>${raised.toLocaleString()} / ${goal.toLocaleString()}</span>
                <span>{c.backer_count ?? 0} backers</span>
                <span>{pct}%</span>
              </div>
            </div>
          );
        })}
        {!campaigns.length && <div className="rounded-lg border border-slate-200 bg-white p-8 text-center text-slate-400">No campaigns yet</div>}
      </div>
    </div>
  );
}