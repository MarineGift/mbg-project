/**
 * lib/queries/marketing-segment.ts
 *
 * Directory-segment audience for marketing bulk mail (/marketing).
 * Resolves a party_type segment (e.g. every paper_mill) narrowed by country,
 * keyword (party name / paper_mill_profile products), linked filler supplier
 * and "already received template X at least N days ago" (follow-ups), then
 * hands back ONE batch of party ids. The batch is sent through the existing
 * bulk-mail path as { mode: 'parties', partyIds } so dedup, blocklist,
 * do-not-send, bounce suppression, whitelist and the mailrun-worker are all
 * reused unchanged (no DB migration).
 *
 * Batch selection skips parties that:
 *   - already received the chosen template (sending|sent|delivered),
 *   - are pending in a not-yet-finished mail_run of the same template
 *     (so "build next batch" right after queueing never duplicates),
 *   - are party-level do-not-send (replied / rejected / form submitted),
 *   - have no contact with an email.
 *
 * Batches are capped (MAX_BATCH) because bulk-mail resolves recipients with
 * PostgREST `in.(...)` filters, which travel in the URL.
 *
 * Conventions: flat selects + in-memory joins, explicit organization_id,
 * paginated reads (PostgREST returns max 1000 rows per request).
 */

import 'server-only';
import type { SbClient } from '@/lib/supabase/server';

export const MAX_BATCH = 150;
const PAGE = 1000;
const SENT_STATUSES = ['sending', 'sent', 'delivered'];
const TERMINAL_RUN = '(completed,failed,canceled)';

export interface SegmentFilter {
  partyTypeCode: string;
  /** template the batch will send (dedup + in-queue exclusion). */
  templateId: string;
  includeCountries?: string[];
  excludeCountries?: string[];
  keyword?: string;
  supplierQuery?: string;
  /** follow-up mode: only parties that already received this template. */
  receivedTemplateId?: string | null;
  /** follow-up mode: ...at least this many days ago. */
  receivedMinDays?: number;
  /**
   * Mills linked to MBG's licensees (Omya / Specialty Minerals) in
   * party_supply_links. 'exclude_all' (default for paper_mill) skips active,
   * filler_supply and potential links; 'exclude_active' skips only active and
   * filler_supply; 'include' keeps them. Historical links never exclude.
   */
  licenseeHosts?: 'exclude_all' | 'exclude_active' | 'include';
  batchSize: number;
}

export interface SegmentFacet { key: string; parties: number; withEmail: number }

export interface SegmentResult {
  totalInType: number;
  matched: number;
  withEmail: number;
  alreadySent: number;
  inQueue: number;
  doNotSend: number;
  /** mills dropped because a licensee supplies (or may supply) them. */
  licenseeExcluded: number;
  remaining: number;
  batchPartyIds: string[];
  countries: SegmentFacet[];
  categories: SegmentFacet[];
}

type Res = { data: unknown; error: { message: string } | null };

async function fetchAll<T>(build: (from: number, to: number) => PromiseLike<Res>): Promise<T[]> {
  const out: T[] = [];
  for (let from = 0; from < 100_000; from += PAGE) {
    const { data, error } = await build(from, from + PAGE - 1);
    if (error) throw new Error(error.message);
    const rows = (data ?? []) as T[];
    out.push(...rows);
    if (rows.length < PAGE) break;
  }
  return out;
}

function chunk<T>(arr: T[], n: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += n) out.push(arr.slice(i, i + n));
  return out;
}

const norm = (c: string | null | undefined) => (c ?? '').trim().toUpperCase();

export async function resolveMarketingSegment(
  supabase: SbClient,
  orgId: string,
  f: SegmentFilter,
): Promise<SegmentResult> {
  const db = supabase.schema('app');

  // -- party type id ---------------------------------------------------------
  const { data: ptRaw, error: ptErr } = await db
    .from('party_types' as never)
    .select('id, code')
    .eq('code', f.partyTypeCode)
    .maybeSingle();
  if (ptErr) throw new Error(ptErr.message);
  const partyTypeId = (ptRaw as { id: number } | null)?.id;
  if (partyTypeId == null) throw new Error(`Unknown party type: ${f.partyTypeCode}`);

  // -- base parties ----------------------------------------------------------
  const parties = await fetchAll<{ id: string; party_name: string | null; country_code: string | null; status: string | null; interest_tags: unknown }>(
    (a, b) =>
      db
        .from('parties' as never)
        .select('id, party_name, country_code, status, interest_tags')
        .eq('organization_id', orgId)
        .eq('party_type_id', partyTypeId)
        .is('deleted_at', null)
        .order('id', { ascending: true })
        .range(a, b) as unknown as PromiseLike<Res>,
  );
  const totalInType = parties.length;
  const byId = new Map(parties.map((p) => [p.id, p]));

  // -- paper_mill_profile (category facet + keyword) -------------------------
  const profileByParty = new Map<string, { cat: string; products: string }>();
  if (f.partyTypeCode === 'paper_mill') {
    const profs = await fetchAll<{ party_id: string; main_product_category: string | null; main_products: string | null }>(
      (a, b) =>
        db
          .from('paper_mill_profile' as never)
          .select('party_id, main_product_category, main_products')
          .eq('organization_id', orgId)
          .is('deleted_at', null)
          .order('party_id', { ascending: true })
          .range(a, b) as unknown as PromiseLike<Res>,
    );
    for (const p of profs) {
      profileByParty.set(p.party_id, { cat: (p.main_product_category ?? '').trim(), products: p.main_products ?? '' });
    }
  }

  // -- contacts with an email -------------------------------------------------
  const contactRows = await fetchAll<{ party_id: string }>((a, b) =>
    db
      .from('contacts' as never)
      .select('party_id')
      .eq('organization_id', orgId)
      .is('deleted_at', null)
      .not('email', 'is', null)
      .order('id', { ascending: true })
      .range(a, b) as unknown as PromiseLike<Res>,
  );
  const hasEmail = new Set<string>();
  for (const c of contactRows) if (byId.has(c.party_id)) hasEmail.add(c.party_id);

  // -- facets over the whole type (before filters) ---------------------------
  const facet = (keyOf: (id: string) => string): SegmentFacet[] => {
    const m = new Map<string, SegmentFacet>();
    for (const p of parties) {
      const k = keyOf(p.id) || '(none)';
      const row = m.get(k) ?? { key: k, parties: 0, withEmail: 0 };
      row.parties += 1;
      if (hasEmail.has(p.id)) row.withEmail += 1;
      m.set(k, row);
    }
    return Array.from(m.values()).sort((x, y) => y.withEmail - x.withEmail || y.parties - x.parties);
  };
  const countries = facet((id) => norm(byId.get(id)?.country_code));
  const categories = profileByParty.size > 0 ? facet((id) => profileByParty.get(id)?.cat ?? '') : [];

  // -- filters ---------------------------------------------------------------
  // Never mail archived parties, nor mills tagged 'MBG Pulp Only' (market-pulp
  // producers make no paper and use no filler - not FCC targets). The tag lives
  // in the legacy interest_tags jsonb array; the directory shows it as a chip.
  const isPulpOnly = (t: unknown) => Array.isArray(t) && t.some((x) => x === 'MBG Pulp Only');
  let ids = parties
    .filter((p) => (p.status ?? 'active') !== 'archived' && !isPulpOnly(p.interest_tags))
    .map((p) => p.id);

  const inc = new Set((f.includeCountries ?? []).map(norm).filter(Boolean));
  const exc = new Set((f.excludeCountries ?? []).map(norm).filter(Boolean));
  if (inc.size > 0) ids = ids.filter((id) => inc.has(norm(byId.get(id)?.country_code)));
  if (exc.size > 0) ids = ids.filter((id) => !exc.has(norm(byId.get(id)?.country_code)));

  const kw = (f.keyword ?? '').trim().toLowerCase();
  if (kw) {
    ids = ids.filter((id) => {
      const p = byId.get(id);
      const prof = profileByParty.get(id);
      const hay = `${p?.party_name ?? ''} ${prof?.cat ?? ''} ${prof?.products ?? ''}`.toLowerCase();
      return hay.includes(kw);
    });
  }

  const sq = (f.supplierQuery ?? '').trim();
  if (sq.length >= 2) {
    const { data: supRaw, error: supErr } = await db
      .from('parties' as never)
      .select('id')
      .eq('organization_id', orgId)
      .is('deleted_at', null)
      .ilike('party_name', `%${sq.replace(/[%_,()]/g, ' ')}%`)
      .limit(500);
    if (supErr) throw new Error(supErr.message);
    const supIds = ((supRaw ?? []) as Array<{ id: string }>).map((r) => r.id);
    const linked = new Set<string>();
    for (const part of chunk(supIds, 100)) {
      const links = await fetchAll<{ mill_party_id: string }>((a, b) =>
        db
          .from('party_supply_links' as never)
          .select('mill_party_id')
          .eq('organization_id', orgId)
          .is('deleted_at', null)
          .in('filler_party_id', part)
          .order('id', { ascending: true })
          .range(a, b) as unknown as PromiseLike<Res>,
      );
      for (const l of links) linked.add(l.mill_party_id);
    }
    ids = ids.filter((id) => linked.has(id));
  }

  // -- licensee host mills (Omya / Specialty Minerals) ------------------------
  // These mills are approached through the licensee headquarters talks, not by
  // MBG cold mail. Read live from party_supply_links, so adding or removing a
  // link changes the segment immediately (no tag to maintain).
  let licenseeExcluded = 0;
  const lh = f.licenseeHosts ?? (f.partyTypeCode === 'paper_mill' ? 'exclude_all' : 'include');
  if (lh !== 'include') {
    const licRows = await fetchAll<{ id: string }>((a, b) =>
      db
        .from('parties' as never)
        .select('id')
        .eq('organization_id', orgId)
        .is('deleted_at', null)
        .or('party_name.ilike.*omya*,party_name.ilike.*specialty*minerals*,party_name.ilike.minerals*technologies*')
        .order('id', { ascending: true })
        .range(a, b) as unknown as PromiseLike<Res>,
    );
    const blocking = lh === 'exclude_all' ? ['active', 'filler_supply', 'potential'] : ['active', 'filler_supply'];
    const hosts = new Set<string>();
    for (const part of chunk(licRows.map((r) => r.id), 100)) {
      const links = await fetchAll<{ mill_party_id: string; link_type: string | null }>((a, b) =>
        db
          .from('party_supply_links' as never)
          .select('mill_party_id, link_type')
          .eq('organization_id', orgId)
          .is('deleted_at', null)
          .in('filler_party_id', part)
          .order('id', { ascending: true })
          .range(a, b) as unknown as PromiseLike<Res>,
      );
      for (const l of links) if (blocking.includes(l.link_type ?? '')) hosts.add(l.mill_party_id);
    }
    const before = ids.length;
    ids = ids.filter((id) => !hosts.has(id));
    licenseeExcluded = before - ids.length;
  }

  if (f.receivedTemplateId) {
    const cutoff = new Date(Date.now() - Math.max(0, f.receivedMinDays ?? 0) * 86_400_000).toISOString();
    const rec = await fetchAll<{ party_id: string | null }>((a, b) =>
      db
        .from('communications' as never)
        .select('party_id')
        .eq('organization_id', orgId)
        .eq('channel', 'email')
        .eq('direction', 'outbound')
        .eq('template_id', f.receivedTemplateId as string)
        .in('status', SENT_STATUSES)
        .lte('sent_at', cutoff)
        .order('id', { ascending: true })
        .range(a, b) as unknown as PromiseLike<Res>,
    );
    const got = new Set(rec.map((r) => r.party_id).filter(Boolean) as string[]);
    ids = ids.filter((id) => got.has(id));
  }

  const matched = ids.length;
  ids = ids.filter((id) => hasEmail.has(id));
  const withEmail = ids.length;

  // -- exclusions: already sent / in queue / do-not-send ----------------------
  const sentRows = await fetchAll<{ party_id: string | null }>((a, b) =>
    db
      .from('communications' as never)
      .select('party_id')
      .eq('organization_id', orgId)
      .eq('channel', 'email')
      .eq('direction', 'outbound')
      .eq('template_id', f.templateId)
      .in('status', SENT_STATUSES)
      .order('id', { ascending: true })
      .range(a, b) as unknown as PromiseLike<Res>,
  );
  const sent = new Set(sentRows.map((r) => r.party_id).filter(Boolean) as string[]);

  const { data: runsRaw, error: runErr } = await db
    .from('mail_runs' as never)
    .select('id')
    .eq('organization_id', orgId)
    .eq('template_id', f.templateId)
    .not('status', 'in', TERMINAL_RUN);
  if (runErr) throw new Error(runErr.message);
  const runIds = ((runsRaw ?? []) as Array<{ id: string }>).map((r) => r.id);
  const queued = new Set<string>();
  for (const part of chunk(runIds, 50)) {
    const rr = await fetchAll<{ party_id: string | null }>((a, b) =>
      db
        .from('mail_run_recipients' as never)
        .select('party_id')
        .in('run_id', part)
        .in('status', ['pending', 'sending'])
        .order('id', { ascending: true })
        .range(a, b) as unknown as PromiseLike<Res>,
    );
    for (const r of rr) if (r.party_id) queued.add(r.party_id);
  }

  const { data: dnsRaw } = await db.from('v_email_do_not_send' as never).select('party_id');
  const dns = new Set(
    ((dnsRaw ?? []) as Array<{ party_id: string | null }>).map((r) => r.party_id).filter(Boolean) as string[],
  );

  let alreadySent = 0;
  let inQueue = 0;
  let doNotSend = 0;
  const eligible: string[] = [];
  for (const id of ids) {
    if (sent.has(id)) { alreadySent += 1; continue; }
    if (queued.has(id)) { inQueue += 1; continue; }
    if (dns.has(id)) { doNotSend += 1; continue; }
    eligible.push(id);
  }

  eligible.sort((x, y) => {
    const px = byId.get(x);
    const py = byId.get(y);
    const c = norm(px?.country_code).localeCompare(norm(py?.country_code));
    return c !== 0 ? c : (px?.party_name ?? '').localeCompare(py?.party_name ?? '');
  });

  const size = Math.min(Math.max(1, Math.floor(f.batchSize)), MAX_BATCH);

  return {
    totalInType,
    matched,
    withEmail,
    alreadySent,
    inQueue,
    doNotSend,
    licenseeExcluded,
    remaining: eligible.length,
    batchPartyIds: eligible.slice(0, size),
    countries,
    categories,
  };
}
