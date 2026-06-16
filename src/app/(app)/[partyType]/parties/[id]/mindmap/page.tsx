/**
 * Per-party Mindmap page: /<partyType>/parties/<id>/mindmap
 * Core data via fetchPartyDetail + relationship branches fetched here:
 *   - Contacts enriched with email + LinkedIn (app.contacts.linkedin_url)
 *   - Deals deep-linked to /pipelines/<code>/deals/<id>
 *   - Supply links (app.party_supply_links) — filler <-> paper mill
 *   - Partners / Co-investors (app.deals + app.deal_parties.role)
 * Navigation keeps a breadcrumb "trail" (?trail=...) so you can hop party ->
 * party and step back through every hop.
 */
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { PartyMindmap, type MindmapData, type MindLeaf } from '@/components/parties/party-mindmap';

interface PageProps {
  params: Promise<{ partyType: string; id: string }>;
  searchParams: Promise<{ trail?: string }>;
}
interface Crumb { i: string; t: string; n: string }

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

function parseTrail(raw?: string): Crumb[] {
  if (!raw) return [];
  try {
    const arr = JSON.parse(decodeURIComponent(raw));
    if (!Array.isArray(arr)) return [];
    return arr
      .filter((x) => x && typeof x.i === 'string' && typeof x.t === 'string')
      .map((x) => ({ i: String(x.i), t: String(x.t), n: String(x.n ?? 'party') }))
      .slice(-8);
  } catch { return []; }
}
const encTrail = (arr: Crumb[]) => encodeURIComponent(JSON.stringify(arr));
function shortUrl(u: string) {
  return u.replace(/^https?:\/\//i, '').replace(/^www\./i, '').replace(/\/$/, '');
}

export default async function PartyMindmapPage({ params, searchParams }: PageProps) {
  const { partyType: urlModule, id } = await params;
  const sp = await searchParams;
  const inTrail = parseTrail(sp.trail);

  const full = await fetchPartyDetail(id);
  if (!full) notFound();
  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}/mindmap`);
  }
  const p = full.party;

  // outgoing trail = incoming + this party (capped). Used for every out-link.
  const outTrail: Crumb[] = [...inTrail, { i: p.id, t: p.partyType, n: p.name }].slice(-8);
  const linkTo = (code: string, pid: string) => `/${code}/parties/${pid}/mindmap?trail=${encTrail(outTrail)}`;

  const supabase = await createSupabaseServerClient();

  const { data: ptRows } = await supabase.schema('app').from('party_types' as never).select('id, code');
  const codeById = new Map<number, string>(((ptRows ?? []) as any[]).map((r) => [r.id, r.code]));

  // ---- contacts: enrich with email + linkedin (not in fetchPartyDetail) ----
  const { data: cRows } = await supabase.schema('app')
    .from('contacts' as never)
    .select('id, email, phone_e164, linkedin_url')
    .eq('party_id' as never, p.id)
    .is('deleted_at' as never, null);
  const extraById = new Map<string, { email: string | null; phone: string | null; linkedin: string | null }>(
    ((cRows ?? []) as any[]).map((r) => [r.id, { email: r.email ?? null, phone: r.phone_e164 ?? null, linkedin: r.linkedin_url ?? null }]),
  );
  const contacts: MindLeaf[] = full.contacts.slice(0, 10).map((c) => {
    const ex = extraById.get(c.id);
    const email = c.email ?? ex?.email ?? null;
    const linkedin = ex?.linkedin ?? null;
    const phone = c.phone ?? ex?.phone ?? null;
    const children: MindLeaf[] = [];
    if (email) children.push({ label: email, sub: 'email', href: `mailto:${email}` });
    if (linkedin) children.push({ label: 'LinkedIn', sub: shortUrl(linkedin), href: linkedin });
    if (phone) children.push({ label: phone, sub: 'phone', href: `tel:${phone.replace(/[^+0-9]/g, '')}` });
    if (c.profile?.coverageRegion) children.push({ label: c.profile.coverageRegion, sub: 'coverage' });
    if (c.profile?.mbgFitRating) children.push({ label: c.profile.mbgFitRating, sub: 'mbg fit' });
    return {
      label: (c.fullName || c.email || 'Contact') + (c.isPrimary ? ' \u2605' : ''),
      sub: c.jobTitle ?? null,
      children: children.length ? children : undefined,
    };
  });

  // ---- deals: deep-link to pipeline deal detail ----
  const engIds = full.engagements.map((e) => e.id);
  const dealPipe = new Map<string, string>();
  if (engIds.length) {
    const { data: dRows } = await supabase.schema('app').from('deals' as never)
      .select('id, pipeline_id').in('id' as never, engIds);
    for (const r of ((dRows ?? []) as any[])) if (r.pipeline_id) dealPipe.set(r.id, r.pipeline_id);
  }
  const { data: pipeRows } = await supabase.schema('app').from('pipelines' as never).select('id, code');
  const pipeCode = new Map<string, string>(((pipeRows ?? []) as any[]).map((r) => [r.id, r.code]));
  const engagements: MindLeaf[] = full.engagements.slice(0, 8).map((e) => {
    const code = pipeCode.get(dealPipe.get(e.id) ?? '');
    return {
      label: e.name,
      sub: money(e.valueAmount, e.valueCurrency) ?? e.stage ?? e.status ?? null,
      href: code ? `/pipelines/${code}/deals/${e.id}` : null,
    };
  });

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

  // ---- supply links ----
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
        href: linked?.id ? linkTo(code, linked.id) : null,
        children: children.length ? children : undefined,
      };
    }).filter((l) => l.label !== 'Unknown');
  }

  // ---- partners / co-investors (shared deals) ----
  const partners: MindLeaf[] = await (async () => {
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
        href: linkTo(code, pid),
        children: agg.deals.slice(0, 5).map((d) => ({
          label: d.name,
          sub: `you: ${ROLE_LABEL[d.myRole] ?? d.myRole} / them: ${ROLE_LABEL[d.theirRole] ?? d.theirRole}`,
        })),
      });
    }
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

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-2 border-b px-6 py-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8 shrink-0">
          <Link href={`/${p.partyType}/parties/${p.id}`} aria-label="Back to party">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        {/* breadcrumb trail (multi-step back) */}
        <nav className="flex items-center gap-1 text-xs text-muted-foreground min-w-0 overflow-x-auto">
          {inTrail.map((c, idx) => (
            <span key={`${c.i}-${idx}`} className="flex items-center gap-1 shrink-0">
              <Link
                href={`/${c.t}/parties/${c.i}/mindmap?trail=${encTrail(inTrail.slice(0, idx))}`}
                className="hover:underline hover:text-foreground max-w-[140px] truncate"
              >
                {c.n}
              </Link>
              <ChevronRight className="h-3 w-3 opacity-60" />
            </span>
          ))}
          <span className="font-semibold text-foreground shrink-0 max-w-[200px] truncate">{p.name}</span>
        </nav>
        <span className="ml-auto text-xs text-muted-foreground shrink-0">Mindmap</span>
      </div>
      <div className="flex-1 overflow-auto p-6">
        <PartyMindmap data={data} />
      </div>
    </div>
  );
}
