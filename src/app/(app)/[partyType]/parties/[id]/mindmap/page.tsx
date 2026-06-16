/**
 * Per-party Mindmap page: /<partyType>/parties/<id>/mindmap
 * Reuses fetchPartyDetail for the core data and adds two relationship branches
 * fetched here:
 *   - Supply links  (app.party_supply_links)  — filler <-> paper mill
 *   - Partners/Co-investors (app.deals + app.deal_parties) — parties that share
 *     a deal/round, with each side's role (lead / participant / ...).
 * Every relationship/contact node links out; relationship links carry ?from=...
 * so the destination shows a "back" chip to return here.
 */
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft, CornerUpLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { PartyMindmap, type MindmapData, type MindLeaf } from '@/components/parties/party-mindmap';

interface PageProps {
  params: Promise<{ partyType: string; id: string }>;
  searchParams: Promise<{ from?: string; fromType?: string; fromName?: string }>;
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
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency || 'USD', maximumFractionDigits: 0 }).format(amount);
  } catch { return `${amount}`; }
}
const ROLE_RANK: Record<string, number> = { lead: 4, primary: 3, co_investor: 2, participant: 1, advisor: 0 };
const ROLE_LABEL: Record<string, string> = {
  lead: 'Lead', primary: 'Primary', co_investor: 'Co-investor', participant: 'Participant', advisor: 'Advisor',
};

/** link to another party's mindmap, carrying a back-reference to this party */
function mindmapHref(code: string, id: string, from: { id: string; type: string; name: string }) {
  const qs = `from=${from.id}&fromType=${from.type}&fromName=${encodeURIComponent(from.name)}`;
  return `/${code}/parties/${id}/mindmap?${qs}`;
}

export default async function PartyMindmapPage({ params, searchParams }: PageProps) {
  const { partyType: urlModule, id } = await params;
  const sp = await searchParams;

  const full = await fetchPartyDetail(id);
  if (!full) notFound();
  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}/mindmap`);
  }
  const p = full.party;
  const self = { id: p.id, type: p.partyType, name: p.name };

  const supabase = await createSupabaseServerClient();

  // party_type_id -> code (for building links to other parties' pages)
  const { data: ptRows } = await supabase.schema('app').from('party_types' as never).select('id, code');
  const codeById = new Map<number, string>(((ptRows ?? []) as any[]).map((r) => [r.id, r.code]));

  // ---- core leaves ----
  const contacts: MindLeaf[] = full.contacts.slice(0, 8).map((c) => {
    const children: MindLeaf[] = [];
    if (c.email) children.push({ label: c.email, sub: 'email', href: `mailto:${c.email}` });
    if (c.phone) children.push({ label: c.phone, sub: 'phone', href: `tel:${c.phone.replace(/[^+0-9]/g, '')}` });
    if (c.profile?.coverageRegion) children.push({ label: c.profile.coverageRegion, sub: 'coverage' });
    if (c.profile?.mbgFitRating) children.push({ label: c.profile.mbgFitRating, sub: 'mbg fit' });
    return {
      label: (c.fullName || c.email || 'Contact') + (c.isPrimary ? ' \u2605' : ''),
      sub: c.jobTitle ?? null,
      children: children.length ? children : undefined,
    };
  });

  const engagements: MindLeaf[] = full.engagements.slice(0, 8).map((e) => ({
    label: e.name, sub: money(e.valueAmount, e.valueCurrency) ?? e.stage ?? e.status ?? null,
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
      ? `${money(ip.ticketMinUsd, 'USD') ?? '?'} - ${money(ip.ticketMaxUsd, 'USD') ?? '?'}` : null;
    if (ticket) investorFocus.push({ label: 'Ticket', sub: ticket });
    if (ip.isLeadInvestor) investorFocus.push({ label: 'Lead investor' });
    if (ip.isStrategic) investorFocus.push({ label: 'Strategic' });
  }

  // ---- supply links (filler <-> paper mill) ----
  const isFiller = p.partyType === 'filler_supplier';
  const isMill = p.partyType === 'paper_mill';
  let supplyLinks: MindLeaf[] = [];
  let supplyLabel = 'Supply links';
  if (isFiller || isMill) {
    const selfCol = isFiller ? 'filler_party_id' : 'mill_party_id';
    supplyLabel = isFiller ? 'Paper mills supplied' : 'Filler suppliers';
    const { data: links } = await supabase.schema('app')
      .from('party_supply_links' as never)
      .select(`id, link_type, product_grade, volume_estimate,
        linked_filler:filler_party_id(id,party_name,party_type_id,country_code),
        linked_mill:mill_party_id(id,party_name,party_type_id,country_code)`)
      .eq(selfCol as never, p.id)
      .is('deleted_at' as never, null);
    supplyLinks = ((links ?? []) as any[]).map((row) => {
      const linked = isFiller ? row.linked_mill : row.linked_filler;
      const code = linked ? (codeById.get(linked.party_type_id) ?? 'paper_mill') : 'paper_mill';
      const children: MindLeaf[] = [];
      if (row.link_type) children.push({ label: row.link_type, sub: 'type' });
      if (row.product_grade) children.push({ label: row.product_grade, sub: 'grade' });
      if (row.volume_estimate) children.push({ label: String(row.volume_estimate), sub: 'volume' });
      if (linked?.country_code) children.push({ label: linked.country_code, sub: 'country' });
      return {
        label: linked?.party_name ?? 'Unknown',
        sub: row.product_grade ?? row.link_type ?? null,
        href: linked?.id ? mindmapHref(code, linked.id, self) : null,
        children: children.length ? children : undefined,
      };
    }).filter((l) => l.label !== 'Unknown');
  }

  // ---- partners / co-investors (shared deals) ----
  const partners: MindLeaf[] = await (async () => {
    // deals where this party participates (M:M) + legacy primary on deals.party_id
    const [{ data: myDP }, { data: myDeals }] = await Promise.all([
      supabase.schema('app').from('deal_parties' as never).select('deal_id, role').eq('party_id' as never, p.id),
      supabase.schema('app').from('deals' as never).select('id').eq('party_id' as never, p.id).is('deleted_at' as never, null),
    ]);
    const myRoleByDeal = new Map<string, string>();
    for (const r of ((myDP ?? []) as any[])) myRoleByDeal.set(r.deal_id, r.role ?? 'participant');
    const dealIds = new Set<string>([
      ...((myDP ?? []) as any[]).map((r) => r.deal_id),
      ...((myDeals ?? []) as any[]).map((r) => r.id),
    ]);
    for (const d of ((myDeals ?? []) as any[])) if (!myRoleByDeal.has(d.id)) myRoleByDeal.set(d.id, 'primary');
    if (dealIds.size === 0) return [];

    const ids = [...dealIds];
    const [{ data: allDP }, { data: deals }] = await Promise.all([
      supabase.schema('app').from('deal_parties' as never).select('deal_id, party_id, role').in('deal_id' as never, ids),
      supabase.schema('app').from('deals' as never).select('id, deal_name, party_id').in('id' as never, ids).is('deleted_at' as never, null),
    ]);
    const dealName = new Map<string, string>(((deals ?? []) as any[]).map((d) => [d.id, d.deal_name]));

    // other party -> { bestRole, deals:[{name, myRole, theirRole}] }
    type Agg = { bestRole: string; deals: { name: string; myRole: string; theirRole: string }[] };
    const byParty = new Map<string, Agg>();
    const consider = (otherId: string, dealId: string, theirRole: string) => {
      if (!otherId || otherId === p.id) return;
      const a = byParty.get(otherId) ?? { bestRole: 'participant', deals: [] };
      if ((ROLE_RANK[theirRole] ?? 0) > (ROLE_RANK[a.bestRole] ?? 0)) a.bestRole = theirRole;
      a.deals.push({ name: dealName.get(dealId) ?? 'Deal', myRole: myRoleByDeal.get(dealId) ?? 'participant', theirRole });
      byParty.set(otherId, a);
    };
    for (const r of ((allDP ?? []) as any[])) consider(r.party_id, r.deal_id, r.role ?? 'participant');
    for (const d of ((deals ?? []) as any[])) if (d.party_id) consider(d.party_id, d.id, 'primary');
    if (byParty.size === 0) return [];

    const { data: pts } = await supabase.schema('app').from('parties' as never)
      .select('id, party_name, party_type_id, country_code')
      .in('id' as never, [...byParty.keys()]).is('deleted_at' as never, null);
    const ptMap = new Map<string, any>(((pts ?? []) as any[]).map((r) => [r.id, r]));

    const out: MindLeaf[] = [];
    for (const [pid, agg] of byParty) {
      const meta = ptMap.get(pid);
      if (!meta) continue;
      const code = codeById.get(meta.party_type_id) ?? 'investor';
      out.push({
        label: meta.party_name,
        sub: ROLE_LABEL[agg.bestRole] ?? agg.bestRole,
        href: mindmapHref(code, pid, self),
        children: agg.deals.slice(0, 5).map((d) => ({
          label: d.name,
          sub: `you: ${ROLE_LABEL[d.myRole] ?? d.myRole} / them: ${ROLE_LABEL[d.theirRole] ?? d.theirRole}`,
        })),
      });
    }
    // sort by role strength then name
    out.sort((a, b) => (ROLE_RANK[b.sub as string] ?? 0) - (ROLE_RANK[a.sub as string] ?? 0) || a.label.localeCompare(b.label));
    return out.slice(0, 12);
  })();

  const data: MindmapData = {
    id: p.id, name: p.name, partyType: p.partyType, tier: p.tier, status: p.status,
    priority: full.investorProfile?.priority ?? null,
    country: p.countryCode, region: p.region, city: p.city, website: p.website, source: p.source,
    introKo: p.introKo, introEn: p.introEn, notes: p.notes,
    counts: full.party.counts,
    contacts, engagements, activity, investorFocus,
    partners, supplyLinks, supplyLabel,
  };

  const back = sp.from && sp.fromType
    ? { href: `/${sp.fromType}/parties/${sp.from}/mindmap`, name: sp.fromName ? decodeURIComponent(sp.fromName) : 'Back' }
    : null;

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-3 border-b px-6 py-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link href={`/${p.partyType}/parties/${p.id}`} aria-label="Back to party">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div className="min-w-0">
          <Link href={`/${p.partyType}/parties/${p.id}`} className="text-sm font-semibold leading-none hover:underline">
            {p.name}
          </Link>
          <div className="text-xs text-muted-foreground mt-0.5">Mindmap — connections &amp; status</div>
        </div>
        {back && (
          <Button asChild variant="outline" size="sm" className="ml-auto">
            <Link href={back.href}>
              <CornerUpLeft className="h-3.5 w-3.5" />
              <span className="max-w-[160px] truncate">Back to {back.name}</span>
            </Link>
          </Button>
        )}
      </div>
      <div className="flex-1 overflow-auto p-6">
        <PartyMindmap data={data} />
      </div>
    </div>
  );
}
