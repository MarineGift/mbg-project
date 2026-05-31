// src/app/(app)/contacts/[id]/page.tsx
// Contact detail page (V1 -- focused on backer pledge history).
//
// Header: name + title + decision-maker badge, email/phone/linkedin row, firm link.
// Body:   "Pledge history" -- every deal_backers row this contact has, joined to
//         the deal/pipeline/stage and (optional) reward tier. Includes lifetime
//         totals by currency and a campaign count.
//
// Future sections (tabs once there's more): Activity, Tasks, Associated deals.

import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  ChevronLeft,
  Mail,
  Phone,
  Building2,
  Linkedin,
  Star,
  ExternalLink,
} from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';

interface Props {
  params: { id: string };
}

function fmtMoney(amount: number | null | undefined, currency: string | null | undefined): string {
  if (amount == null) return '\u2014';
  const cur = currency || 'USD';
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: cur,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return amount.toLocaleString() + ' ' + cur;
  }
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '\u2014';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '\u2014';
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function contactName(c: any): string {
  if (!c) return 'Contact';
  if (c.full_name) return c.full_name;
  if (c.given_name && c.family_name) return c.given_name + ' ' + c.family_name;
  return c.given_name || c.family_name || 'Contact';
}

export default async function ContactDetailPage({ params }: Props) {
  const supabase = await createSupabaseServerClient();

  // 1) Contact + their firm (parties)
  const { data: contactRow } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select(
      'id, full_name, given_name, family_name, ' +
      'email, email_secondary, phone_e164, phone_mobile, ' +
      'linkedin_url, twitter_handle, ' +
      'title_text, department, role_category, seniority_level, ' +
      'is_decision_maker, is_primary, is_active, ' +
      'last_contacted_at, notes, ' +
      'firm:parties!party_id(id, party_name, country_code, website)'
    )
    .eq('id', params.id)
    .is('deleted_at', null)
    .maybeSingle();

  if (!contactRow) notFound();
  const c = contactRow as any;

  // 2) All pledges (deal_backers) by this contact, joined to deal/pipeline/stage/tier
  const { data: backerRows } = await supabase
    .schema('app')
    .from('deal_backers' as never)
    .select(
      'id, pledge_amount, pledge_currency, status, reward_status, ' +
      'pledged_at, collected_at, country_code, ' +
      'deal:deals(id, deal_name, value_amount, value_currency, ' +
      '  pipeline:pipelines(id, code, name), ' +
      '  stage:stages(id, code, name)), ' +
      'reward_tier:reward_tiers(id, name, tier_name, pledge_from, currency)'
    )
    .eq('contact_id', params.id)
    .order('pledged_at', { ascending: false });

  const pledges = (backerRows ?? []) as any[];

  // Totals by currency (lifetime)
  const totalsByCurrency: Record<string, number> = {};
  for (const p of pledges) {
    const cur = p.pledge_currency || p.deal?.value_currency || 'USD';
    totalsByCurrency[cur] = (totalsByCurrency[cur] ?? 0) + Number(p.pledge_amount ?? 0);
  }

  // Distinct campaigns
  const campaignIds = new Set<string>();
  for (const p of pledges) {
    if (p.deal?.id) campaignIds.add(p.deal.id);
  }

  return (
    <div className="flex h-full flex-col">
      {/* ===== Header ===== */}
      <div className="border-b bg-background px-6 py-4">
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-1 hover:text-foreground"
          >
            <ChevronLeft className="h-3 w-3" />
            Back
          </Link>
        </div>

        <div className="mt-1 flex items-center gap-3">
          <h1 className="text-xl font-semibold text-foreground">{contactName(c)}</h1>
          {c.is_decision_maker && (
            <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-medium text-amber-700 ring-1 ring-inset ring-amber-200">
              <Star className="h-2.5 w-2.5" />
              Decision maker
            </span>
          )}
          {c.is_primary && (
            <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-medium text-blue-700 ring-1 ring-inset ring-blue-200">
              Primary
            </span>
          )}
          {c.is_active === false && (
            <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-medium text-zinc-600">
              Inactive
            </span>
          )}
        </div>

        {/* Title + department line */}
        {(c.title_text || c.department) && (
          <div className="mt-1 text-xs text-muted-foreground">
            {c.title_text}
            {c.title_text && c.department && <span className="mx-1 opacity-40">{'\u00b7'}</span>}
            {c.department}
          </div>
        )}

        {/* Contact channels row */}
        <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs">
          {c.email && (
            <a href={'mailto:' + c.email} className="inline-flex items-center gap-1 text-muted-foreground hover:text-foreground">
              <Mail className="h-3 w-3" />
              {c.email}
            </a>
          )}
          {(c.phone_e164 || c.phone_mobile) && (
            <a
              href={'tel:' + (c.phone_e164 || c.phone_mobile)}
              className="inline-flex items-center gap-1 text-muted-foreground hover:text-foreground"
            >
              <Phone className="h-3 w-3" />
              {c.phone_e164 || c.phone_mobile}
              {c.phone_mobile && c.phone_e164 && c.phone_mobile !== c.phone_e164 && (
                <span className="opacity-60">/ {c.phone_mobile}</span>
              )}
            </a>
          )}
          {c.linkedin_url && (
            <a
              href={c.linkedin_url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-muted-foreground hover:text-foreground"
            >
              <Linkedin className="h-3 w-3" />
              LinkedIn
              <ExternalLink className="h-2.5 w-2.5 opacity-60" />
            </a>
          )}
        </div>

        {/* Firm line */}
        {c.firm && (
          <div className="mt-1 inline-flex items-center gap-1 text-xs text-muted-foreground">
            <Building2 className="h-3 w-3" />
            <span className="font-medium text-foreground">{c.firm.party_name}</span>
            {c.firm.country_code && <span className="opacity-60">{'\u00b7'} {c.firm.country_code}</span>}
          </div>
        )}

        {c.last_contacted_at && (
          <div className="mt-1 text-[11px] text-muted-foreground/80">
            Last contacted: {fmtDate(c.last_contacted_at)}
          </div>
        )}
      </div>

      {/* ===== Pledge history ===== */}
      <div className="flex-1 overflow-y-auto p-6">
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
              Pledge history ({pledges.length})
            </div>
            {pledges.length > 0 && (
              <div className="text-xs text-muted-foreground">
                <span className="mr-3">{campaignIds.size} campaign{campaignIds.size === 1 ? '' : 's'}</span>
                <span className="font-medium text-foreground tabular-nums">
                  Total:{' '}
                  {Object.entries(totalsByCurrency)
                    .map(([cur, sum]) => fmtMoney(sum, cur))
                    .join(' \u00b7 ')}
                </span>
              </div>
            )}
          </div>

          {pledges.length === 0 ? (
            <div className="rounded-lg border bg-card px-4 py-12 text-center text-sm text-muted-foreground">
              No pledges yet.
            </div>
          ) : (
            <div className="rounded-lg border bg-card overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/30 text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-2 text-left font-medium">Date</th>
                    <th className="px-4 py-2 text-left font-medium">Campaign</th>
                    <th className="px-4 py-2 text-left font-medium">Tier</th>
                    <th className="px-4 py-2 text-right font-medium">Amount</th>
                    <th className="px-4 py-2 text-left font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {pledges.map((p: any) => (
                    <tr key={p.id}>
                      <td className="px-4 py-2 text-xs text-muted-foreground tabular-nums whitespace-nowrap">
                        {fmtDate(p.pledged_at)}
                      </td>
                      <td className="px-4 py-2">
                        {p.deal && p.deal.pipeline ? (
                          <Link
                            href={'/pipelines/' + p.deal.pipeline.code + '/deals/' + p.deal.id}
                            className="font-medium text-foreground hover:underline"
                          >
                            {p.deal.deal_name}
                          </Link>
                        ) : (
                          <span className="italic text-muted-foreground">deleted deal</span>
                        )}
                        {p.deal?.pipeline && (
                          <div className="mt-0.5 text-[11px] text-muted-foreground">
                            {p.deal.pipeline.name}
                            {p.deal.stage && (
                              <>
                                <span className="mx-1 opacity-40">{'\u00b7'}</span>
                                {p.deal.stage.name}
                              </>
                            )}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-2 text-xs text-muted-foreground">
                        {p.reward_tier
                          ? p.reward_tier.tier_name || p.reward_tier.name || '\u2014'
                          : '\u2014'}
                      </td>
                      <td className="px-4 py-2 text-right tabular-nums">
                        {fmtMoney(p.pledge_amount, p.pledge_currency || p.deal?.value_currency)}
                      </td>
                      <td className="px-4 py-2">
                        <StatusBadge status={p.reward_status || p.status || 'pledged'} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        {/* Notes (if any) */}
        {c.notes && (
          <section className="mt-6 rounded-lg border bg-card p-4 text-sm">
            <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
              Notes
            </div>
            <div className="whitespace-pre-wrap text-foreground">{c.notes}</div>
          </section>
        )}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colorMap: Record<string, string> = {
    pledged: 'bg-blue-50 text-blue-700 ring-blue-200',
    collected: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
    refunded: 'bg-zinc-50 text-zinc-700 ring-zinc-200',
    cancelled: 'bg-zinc-50 text-zinc-700 ring-zinc-200',
    failed: 'bg-rose-50 text-rose-700 ring-rose-200',
  };
  const cls = colorMap[status] || 'bg-zinc-50 text-zinc-700 ring-zinc-200';
  return (
    <span
      className={
        'inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium capitalize ring-1 ring-inset ' +
        cls
      }
    >
      {status}
    </span>
  );
}
