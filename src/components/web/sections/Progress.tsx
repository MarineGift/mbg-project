'use client';
// src/components/web/sections/Progress.tsx
// Crowdfunding progress bar + stats. Reads the campaign loaded by the
// crowdfunding template. No config needed.

import type { SectionProps } from '../SectionRenderer';

export function Progress({ campaign }: SectionProps) {
  if (!campaign) return null;
  const pct = campaign.goal_amount > 0
    ? Math.min(100, Math.round((campaign.raised_amount / campaign.goal_amount) * 100))
    : 0;
  const cur = (n: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: campaign.currency, maximumFractionDigits: 0 }).format(n);

  const daysLeft = campaign.end_at
    ? Math.max(0, Math.ceil((new Date(campaign.end_at).getTime() - Date.now()) / 86400000))
    : null;

  return (
    <section className="mx-auto max-w-4xl px-6 py-12">
      {campaign.video_id && (
        <div className="mb-8 aspect-video w-full overflow-hidden rounded-2xl bg-black">
          <iframe
            title={campaign.title}
            className="h-full w-full"
            src={`https://www.youtube.com/embed/${campaign.video_id}?autoplay=1&mute=1&loop=1&playlist=${campaign.video_id}&controls=0&modestbranding=1`}
            allow="autoplay; encrypted-media"
          />
        </div>
      )}

      <h2 className="text-center text-3xl font-bold text-slate-800">{campaign.title}</h2>

      <div className="mt-8">
        <div className="h-3 w-full overflow-hidden rounded-full bg-slate-200">
          <div className="h-full rounded-full" style={{ width: `${pct}%`, background: 'var(--site-accent)' }} />
        </div>
        <p className="mt-2 text-right text-sm font-medium text-slate-500">{pct}% Funded</p>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Stat value={cur(campaign.raised_amount)} label="Raised" />
        <Stat value={campaign.backers_count.toLocaleString()} label="Backers" />
        <Stat value={daysLeft === null ? '-' : String(daysLeft)} label="Days to go" />
        <Stat value={cur(campaign.goal_amount)} label="Goal" />
      </div>
    </section>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="rounded-xl bg-slate-50 p-4 text-center">
      <div className="text-2xl font-bold text-slate-800">{value}</div>
      <div className="text-xs uppercase tracking-wide text-slate-500">{label}</div>
    </div>
  );
}
