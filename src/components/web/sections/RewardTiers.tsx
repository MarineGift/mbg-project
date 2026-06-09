'use client';
// src/components/web/sections/RewardTiers.tsx
// Crowdfunding reward tiers. Reads campaign.tiers (loaded by template).
// "Select" reveals an inline pledge form that records a pledge + mirrors it
// into the unified admin inbox via createPledge.

import { useState, useTransition } from 'react';
import type { SectionProps } from '../SectionRenderer';
import type { RewardTier } from '@/lib/web/types';
import { createPledge } from '@/lib/web/commerce-actions';

interface Cfg { title?: string }

export function RewardTiers({ section, campaign, site }: SectionProps) {
  const cfg = section.config as Cfg;
  if (!campaign || !campaign.tiers || !campaign.tiers.length) return null;
  const tiers = campaign.tiers;
  const currency = campaign.currency;
  const campaignId = campaign.id;
  const siteId = site.id;

  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      {cfg.title && (
        <h2 className="mb-10 text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>
      )}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {tiers.map((t) => (
          <TierCard key={t.id} tier={t} campaignId={campaignId} siteId={siteId} currency={currency} />
        ))}
      </div>
    </section>
  );
}

function TierCard({
  tier, campaignId, siteId, currency,
}: { tier: RewardTier; campaignId: string; siteId: string; currency: string }) {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [done, setDone] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const cur = (n: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency, maximumFractionDigits: 0 }).format(n);
  const remaining = tier.limited_qty != null ? tier.limited_qty - tier.claimed_qty : null;

  const submit = () => {
    setErr(null);
    start(async () => {
      const r = await createPledge({
        campaign_id: campaignId, site_id: siteId, tier_id: tier.id,
        name, email, amount: tier.price,
      });
      if (r.ok) setDone(true);
      else setErr(r.error ?? 'error');
    });
  };

  return (
    <div className={`relative flex flex-col rounded-2xl border bg-white p-6 shadow-sm ${tier.is_popular ? 'border-2' : 'border-slate-200'}`}
      style={tier.is_popular ? { borderColor: 'var(--site-accent)' } : undefined}>
      {tier.is_popular && (
        <span className="absolute -top-3 left-6 rounded-full px-3 py-0.5 text-xs font-semibold text-white" style={{ background: 'var(--site-accent)' }}>
          Most Popular
        </span>
      )}
      {remaining != null && (
        <span className="mb-1 text-xs font-medium text-amber-600">Limited: {remaining} left</span>
      )}
      <h3 className="text-lg font-bold text-slate-800">{tier.name}</h3>
      <div className="mt-1 flex items-baseline gap-2">
        <span className="text-2xl font-extrabold text-slate-900">{cur(tier.price)}</span>
        {tier.compare_at_price && (
          <span className="text-sm text-slate-400 line-through">{cur(tier.compare_at_price)}</span>
        )}
      </div>
      {tier.description && <p className="mt-2 text-sm text-slate-600">{tier.description}</p>}

      <ul className="mt-4 flex-1 space-y-1.5 text-sm text-slate-600">
        {tier.includes.map((inc, i) => (
          <li key={i} className="flex gap-2">
            <span style={{ color: 'var(--site-accent)' }}>+</span>{inc}
          </li>
        ))}
      </ul>

      <div className="mt-4 text-xs text-slate-400">
        {tier.est_delivery && <>Est. delivery: {tier.est_delivery} &middot; </>}
        Backers: {tier.backers_count}
      </div>

      {done ? (
        <p className="mt-5 rounded-lg bg-emerald-50 p-3 text-center text-sm text-emerald-700">
          Thank you for backing this tier.
        </p>
      ) : open ? (
        <div className="mt-5 space-y-2">
          <input placeholder="Name" value={name} onChange={(e) => setName(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" />
          <input placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" />
          {err && <p className="text-xs text-red-600">{err}</p>}
          <button onClick={submit} disabled={pending}
            className="w-full rounded-lg py-2.5 text-sm font-semibold text-white disabled:opacity-60"
            style={{ background: 'var(--site-primary)' }}>
            {pending ? 'Submitting...' : 'Confirm Pledge'}
          </button>
        </div>
      ) : (
        <button onClick={() => setOpen(true)}
          className="mt-5 w-full rounded-lg border-2 py-2.5 text-sm font-semibold"
          style={{ borderColor: 'var(--site-primary)', color: 'var(--site-primary)' }}>
          Select This Reward
        </button>
      )}
    </div>
  );
}
