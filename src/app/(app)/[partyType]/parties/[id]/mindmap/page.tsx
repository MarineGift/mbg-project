/**
 * Per-party Mindmap page: /<partyType>/parties/<id>/mindmap
 * Reuses fetchPartyDetail (party + contacts + engagements + tasks + timeline +
 * investorProfile + counts) and renders the interactive PartyMindmap. No new
 * queries are introduced — this is a different *view* of the existing detail data.
 */
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { PartyMindmap, type MindmapData, type MindLeaf } from '@/components/parties/party-mindmap';

interface PageProps {
  params: Promise<{ partyType: string; id: string }>;
}

function relDate(iso: string | null): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  const days = Math.floor((Date.now() - d.getTime()) / 86_400_000);
  if (days <= 0) return 'today';
  if (days === 1) return 'yesterday';
  if (days < 30) return `${days}d ago`;
  if (days < 365) return `${Math.floor(days / 30)}mo ago`;
  return `${Math.floor(days / 365)}y ago`;
}

function money(amount: number | null, currency: string | null): string | null {
  if (amount == null) return null;
  try {
    return new Intl.NumberFormat('en-US', {
      style: 'currency', currency: currency || 'USD', maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `${amount}`;
  }
}

export default async function PartyMindmapPage({ params }: PageProps) {
  const { partyType: urlModule, id } = await params;

  const full = await fetchPartyDetail(id);
  if (!full) notFound();
  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}/mindmap`);
  }

  const p = full.party;

  const contacts: MindLeaf[] = full.contacts.slice(0, 8).map((c) => ({
    label: (c.fullName || c.email || 'Contact') + (c.isPrimary ? ' \u2605' : ''),
    sub: c.jobTitle ?? null,
  }));

  const engagements: MindLeaf[] = full.engagements.slice(0, 8).map((e) => ({
    label: e.name,
    sub: money(e.valueAmount, e.valueCurrency) ?? e.stage ?? e.status ?? null,
  }));

  const activity: MindLeaf[] = full.timeline.slice(0, 5).map((it) =>
    it.kind === 'communication'
      ? { label: it.subject || `${it.channel} ${it.direction}`, sub: relDate(it.occurredAt) }
      : { label: it.title, sub: relDate(it.occurredAt) },
  );

  const investorFocus: MindLeaf[] = [];
  if (full.investorProfile) {
    const ip = full.investorProfile;
    if (ip.typeName || ip.investorCategory) investorFocus.push({ label: 'Type', sub: ip.typeName || ip.investorCategory });
    for (const s of (ip.sectorFocus ?? []).slice(0, 6)) investorFocus.push({ label: s });
    if ((ip.geographicFocus ?? []).length) investorFocus.push({ label: 'Geography', sub: ip.geographicFocus.join(', ') });
    const ticket = ip.ticketMinUsd != null || ip.ticketMaxUsd != null
      ? `${money(ip.ticketMinUsd, 'USD') ?? '?'} – ${money(ip.ticketMaxUsd, 'USD') ?? '?'}`
      : null;
    if (ticket) investorFocus.push({ label: 'Ticket', sub: ticket });
    if (ip.isLeadInvestor) investorFocus.push({ label: 'Lead investor' });
    if (ip.isStrategic) investorFocus.push({ label: 'Strategic' });
  }

  const data: MindmapData = {
    id: p.id,
    name: p.name,
    partyType: p.partyType,
    tier: p.tier,
    status: p.status,
    priority: full.investorProfile?.priority ?? null,
    country: p.countryCode,
    region: p.region,
    city: p.city,
    website: p.website,
    source: p.source,
    counts: full.party.counts,
    contacts,
    engagements,
    activity,
    investorFocus,
  };

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-3 border-b px-6 py-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link href={`/${p.partyType}/parties/${p.id}`} aria-label="Back to party">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <div className="text-sm font-semibold leading-none">{p.name}</div>
          <div className="text-xs text-muted-foreground mt-0.5">Mindmap — connections &amp; status</div>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-6">
        <PartyMindmap data={data} />
      </div>
    </div>
  );
}
