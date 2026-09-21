/**
 * lib/email/investor-intro.ts
 *
 * 2026-09-21 - rule-based (no AI) detection of investor mail that arrives
 * through Greentown Labs.
 *
 * Why: the 2026 warm-intro outreach to Greentown's investor list was sent
 * through Greentown Labs' own mail system (not URM), so URM holds no outbound
 * for those threads. Replies land either
 *   - with no party at all (sender is not a URM contact yet), or
 *   - on the wrong party (e.g. the person is also one of the 118 Greentown
 *     mentors, so contact-email matching picks the mentor party).
 * Both must show as Investors.
 *
 * A mail is an investor intro when it is NOT automated (newsletter / luma /
 * no-reply) and any of:
 *   1. the sender is a Greentown intro sender (will@greentownlabs.org)
 *   2. the subject is the Greentown warm-intro template
 *      ("... Exploring a potential fit with <Firm>")
 *   3. the subject or the NEW part of the body (quoted history excluded -
 *      our own signature carries the Greentown Labs address) mentions
 *      Greentown together with an intro / investment word, and the sender is
 *      not Greentown staff.
 *
 * Output is stored in communications.external_data.inferred_party_type and
 * used by the inbox list badge. If a firm name can be read from the subject,
 * the ingest step also re-links the message to that investor party.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { detectAutomated, extractNewText } from './rule-classifier';

/** Greentown people who send investor intros. Lower-case. */
export const GREENTOWN_INTRO_SENDERS: readonly string[] = [
  'will@greentownlabs.org',
  'will@greentownlabs.com',
];

const GREENTOWN_DOMAINS = ['greentownlabs.org', 'greentownlabs.com'];

const INTRO_SUBJECT = /exploring (a )?potential fit with\s+(.+?)\s*$/i;

const GREENTOWN_MENTION = /green\s*town(\s*labs?)?/i;

const INTRO_WORDS =
  /\b(connect(ed|ing)?|introduc(e|ed|ing|tion)|intro|deck|pitch|invest(or|ors|ment|ing)?|fund(ing|raise|raising)?|portfolio|venture|capital|round|seed|diligence|call|meet(ing)?)\b/i;

export interface InvestorIntroInput {
  fromAddress?: string | null;
  subject?: string | null;
  bodyPlain?: string | null;
  headers?: Record<string, string>;
}

export interface InvestorIntroResult {
  isInvestorIntro: boolean;
  reason?: 'greentown_sender' | 'intro_subject' | 'greentown_mention';
  /** firm name read from the intro subject, e.g. "Strategic Ventures" */
  firmHint?: string;
}

export function extractIntroFirm(subject: string | null | undefined): string | undefined {
  const s = (subject ?? '').trim();
  const m = INTRO_SUBJECT.exec(s);
  if (!m || !m[2]) return undefined;
  const firm = m[2].replace(/[\s.!?]+$/, '').trim();
  return firm.length >= 2 && firm.length <= 120 ? firm : undefined;
}

export function detectInvestorIntro(input: InvestorIntroInput): InvestorIntroResult {
  const from = (input.fromAddress ?? '').trim().toLowerCase();
  const subject = input.subject ?? '';
  const body = (input.bodyPlain ?? '').slice(0, 20000);

  const firmHint = extractIntroFirm(subject);

  // Greentown intro senders win even when the mail went out through a bulk
  // platform (List-Unsubscribe etc.) - those intros are the whole point.
  if (GREENTOWN_INTRO_SENDERS.includes(from)) {
    return { isInvestorIntro: true, reason: 'greentown_sender', firmHint };
  }

  if (
    detectAutomated({
      subject,
      bodyPlain: body,
      fromAddress: from,
      headers: input.headers,
    })
  ) {
    return { isInvestorIntro: false };
  }

  if (firmHint) {
    return { isInvestorIntro: true, reason: 'intro_subject', firmHint };
  }

  const domain = from.slice(from.lastIndexOf('@') + 1);
  const fromGreentownStaff = GREENTOWN_DOMAINS.some(
    (d) => domain === d || domain.endsWith(`.${d}`),
  );
  // new text only: our own signature (Greentown Labs Houston address) is
  // quoted in every reply, so quoted history must not count.
  const text = `${subject}\n${extractNewText(body)}`;
  if (!fromGreentownStaff && GREENTOWN_MENTION.test(text) && INTRO_WORDS.test(text)) {
    return { isInvestorIntro: true, reason: 'greentown_mention' };
  }

  return { isInvestorIntro: false };
}

/**
 * Firm named in a meeting-style subject: "Intro Meeting | MarineBio Group <>
 * Strategic Ventures @ Thu Oct 1 ..." or "Strategic Ventures <> MBG".
 * Only a candidate - it counts only when an investor party has that name.
 */
export function extractPairFirm(subject: string | null | undefined): string | undefined {
  const s = (subject ?? '').replace(/^(invitation|updated invitation|accepted|declined|re|fw|fwd)\s*:\s*/i, '');
  const us = '(?:marine\\s*bio(?:\\s*group)?(?:,?\\s*inc\\.?)?|mbg)';
  const clean = (x: string | undefined) => {
    const f = (x ?? '').replace(/\s+@.*$/, '').replace(/[\s.!?|,]+$/, '').trim();
    return f.length >= 2 && f.length <= 120 ? f : undefined;
  };
  const a = new RegExp(`${us}\\s*(?:<>|<->|x|&|\\/)\\s*([^|\\n@()]+)`, 'i').exec(s);
  if (a) return clean(a[1]);
  const b = new RegExp(`([^|\\n@()]+?)\\s*(?:<>|<->)\\s*${us}\\b`, 'i').exec(s);
  if (b) return clean(b[1]);
  return undefined;
}

/* ============================================================
 * Ingest helper (DB)
 * ============================================================ */

/** party types an investor classification is allowed to override */
const OVERRIDABLE_TYPES = new Set(['mentor', 'investor']);

export type InvestorReason =
  | NonNullable<InvestorIntroResult['reason']>
  | 'subject_firm'
  | 'sender_domain'
  | 'prior_intro_sender';

export interface InvestorIntroResolution {
  /** set when the message should be re-linked to an investor party */
  relinkPartyId?: string;
  /** value for external_data.inferred_party_type ('investor') or undefined */
  inferredPartyType?: 'investor';
  reason?: InvestorReason;
  firmHint?: string;
  detection: InvestorIntroResult;
}

function escapeLike(s: string): string {
  return s.replace(/[\\%_]/g, (c) => `\\${c}`);
}

type Sb = SupabaseClient;

async function partyTypeOf(supabase: Sb, partyId: string | null): Promise<string | null> {
  if (!partyId) return null;
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, party_types(code)')
    .eq('id', partyId)
    .maybeSingle();
  const pt = (data as { party_types?: { code?: string } | Array<{ code?: string }> } | null)
    ?.party_types;
  return (Array.isArray(pt) ? pt[0]?.code : pt?.code) ?? null;
}

/** exactly one investor party with this name (case-insensitive) */
async function uniqueInvestorByName(
  supabase: Sb,
  organizationId: string,
  name: string,
): Promise<string | undefined> {
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, party_types!inner(code)')
    .eq('organization_id', organizationId)
    .eq('party_types.code', 'investor')
    .is('deleted_at', null)
    .ilike('party_name', escapeLike(name))
    .limit(2);
  const rows = (data ?? []) as Array<{ id: string }>;
  return rows.length === 1 && rows[0] ? rows[0].id : undefined;
}

/* webmail / shared domains never identify a firm */
const GENERIC_DOMAINS = new Set([
  'gmail.com', 'googlemail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
  'live.com', 'msn.com', 'aol.com', 'icloud.com', 'me.com', 'proton.me',
  'protonmail.com', 'naver.com', 'daum.net', 'kakao.com', 'qq.com', '163.com',
]);

/**
 * Platform / big-corporate hosts. An investor party whose website is a
 * LinkedIn profile or a parent company (microsoft.com, samsung.com) must never
 * pull platform mail (LinkedIn notifications, Azure promos) onto itself.
 * 2026-09-21: the first sender-domain backfill did exactly that.
 */
const PLATFORM_HOSTS = new Set([
  'linkedin.com', 'facebook.com', 'twitter.com', 'x.com', 'instagram.com',
  'youtube.com', 'medium.com', 'substack.com', 'github.com', 'crunchbase.com',
  'angel.co', 'wellfound.com', 'pitchbook.com', 'google.com', 'microsoft.com',
  'apple.com', 'amazon.com', 'samsung.com', 'notion.site', 'wix.com',
  'squarespace.com', 'linktr.ee', 'bit.ly', 'mailchimp.com', 'hubspot.com',
]);

/** hosts that belong to a platform (or any subdomain of one) */
export function isPlatformHost(host: string): boolean {
  for (const p of PLATFORM_HOSTS) if (host === p || host.endsWith(`.${p}`)) return true;
  return false;
}

/**
 * Local parts that are machines or shared inboxes, anywhere in the name
 * (messages-noreply@, account-security-noreply@, health.info@, invitations@).
 */
const ROLE_LOCAL =
  /(^|[-_.+])(no-?reply|do-?not-?reply|notifications?|notify|alerts?|news(letter)?s?|marketing|promo|mailer|bounces?|digest|updates|info|hello|contact|support|team|admin|billing|security|account|invitations?|jobs|editors|messages|messaging|groups|hit-reply|events?|community|membership|sales|press|careers|office)([-_.+]|$)/i;

export function isRoleSender(address: string): boolean {
  const local = address.toLowerCase().split('@')[0] ?? '';
  return ROLE_LOCAL.test(local);
}

const US_MENTION = /\b(marine\s*bio(\s*group)?|mbg|marinebiogroup|fcc|hfcc)\b/i;

/**
 * The mail is a conversation with us, not a broadcast: it is a reply
 * (In-Reply-To present) or names MarineBio / MBG in the subject or new text.
 * Addresses and URLs are stripped first - account mail quotes our address.
 */
export function mentionsUs(input: InvestorIntroInput): boolean {
  const h = input.headers ?? {};
  if ((h['in-reply-to'] ?? '').trim()) return true;
  const text = `${input.subject ?? ''}\n${extractNewText(input.bodyPlain ?? '')}`
    .replace(/\S+@\S+/g, ' ')
    .replace(/https?:\/\/\S+/g, ' ');
  return US_MENTION.test(text);
}

/** "https://www.APVentures.com/team" -> "apventures.com" */
export function hostOf(url: string | null | undefined): string | undefined {
  let s = (url ?? '').trim().toLowerCase();
  if (!s) return undefined;
  s = s.replace(/^[a-z]+:\/\//, '').replace(/^www\d*\./, '');
  s = s.split(/[/?#:\s]/)[0] ?? '';
  return /^[a-z0-9.-]+\.[a-z]{2,}$/.test(s) ? s : undefined;
}

/** sender domain belongs to host (equal, or a subdomain of it) */
export function domainMatches(senderDomain: string, host: string): boolean {
  return senderDomain === host || senderDomain.endsWith(`.${host}`);
}

/**
 * Rule F: exactly one investor party whose website (or email) domain is the
 * sender's domain, e.g. girven@apventures.com -> AP Ventures.
 */
async function uniqueInvestorByDomain(
  supabase: Sb,
  organizationId: string,
  sender: string,
): Promise<string | undefined> {
  const at = sender.lastIndexOf('@');
  if (at < 0) return undefined;
  const domain = sender.slice(at + 1);
  if (!domain || GENERIC_DOMAINS.has(domain) || isPlatformHost(domain)) return undefined;
  if (isRoleSender(sender)) return undefined;
  // registrable part for the coarse ilike ("mail.apventures.com" -> "apventures.com")
  const labels = domain.split('.');
  const base = labels.slice(-2).join('.');
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, website, email, party_types!inner(code)')
    .eq('organization_id', organizationId)
    .eq('party_types.code', 'investor')
    .is('deleted_at', null)
    .or(`website.ilike.*${base}*,email.ilike.*@*${base}`)
    .limit(25);
  const ids = new Set<string>();
  for (const r of (data ?? []) as Array<{ id: string; website: string | null; email: string | null }>) {
    const w = hostOf(r.website);
    const e = (r.email ?? '').toLowerCase().split('@')[1];
    if (w && !isPlatformHost(w) && domainMatches(domain, w)) ids.add(r.id);
    else if (e && !isPlatformHost(e) && domainMatches(domain, e)) ids.add(r.id);
  }
  return ids.size === 1 ? [...ids][0] : undefined;
}

/** latest earlier mail from this sender that was classified investor */
async function priorInvestorMail(
  supabase: Sb,
  organizationId: string,
  sender: string,
): Promise<{ partyId: string | null } | undefined> {
  if (!sender) return undefined;
  const { data } = await supabase
    .schema('app')
    .from('communications')
    .select('party_id')
    .eq('organization_id', organizationId)
    .eq('direction', 'inbound')
    .ilike('from_address', escapeLike(sender))
    .eq('external_data->>inferred_party_type', 'investor')
    .is('deleted_at', null)
    .order('occurred_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data) return undefined;
  return { partyId: ((data as { party_id?: string | null }).party_id ?? null) };
}

/**
 * Decide investor classification for one inbound message.
 * Never throws - a lookup failure must not block ingest.
 *
 * Rules, in order:
 *   A-C  detectInvestorIntro (Greentown sender / intro subject / Greentown mention)
 *   D    subject names an investor firm ("MarineBio Group <> Strategic Ventures")
 *        and exactly one investor party has that name
 *   F    the sender's company domain is the website/email domain of exactly
 *        one investor party (girven@apventures.com -> AP Ventures); personal
 *        senders only (no role/no-reply locals), platform hosts (linkedin.com,
 *        microsoft.com, samsung.com, ...) never match, and the mail must be a
 *        reply or name MarineBio / MBG
 *   E    the same sender already had mail classified investor (e.g. the
 *        warm-intro reply) - later mail from them (calendar invites, follow-ups)
 *        follows it to the same investor party
 *
 * Guard: a message already linked to a business party (paper mill, filler
 * supplier, partner, ...) is left alone, because our own signature mentions
 * Greentown Labs and replies quote it. Only unlinked / mentor / investor
 * messages are touched - except mail from a Greentown intro sender.
 */
export async function resolveInvestorIntro(
  supabase: SupabaseClient,
  organizationId: string,
  input: InvestorIntroInput,
  currentPartyId: string | null,
): Promise<InvestorIntroResolution> {
  const detection = detectInvestorIntro(input);
  const sender = (input.fromAddress ?? '').trim().toLowerCase();

  try {
    const currentType = await partyTypeOf(supabase, currentPartyId);
    const overridable = currentType === null || OVERRIDABLE_TYPES.has(currentType);

    if (detection.isInvestorIntro) {
      if (!(detection.reason === 'greentown_sender' || overridable)) {
        return { detection: { isInvestorIntro: false } };
      }
      const base = {
        detection,
        inferredPartyType: 'investor' as const,
        reason: detection.reason,
        firmHint: detection.firmHint,
      };
      if (currentType === 'investor') return base;
      if (detection.firmHint) {
        const id = await uniqueInvestorByName(supabase, organizationId, detection.firmHint);
        if (id) return { ...base, relinkPartyId: id };
      }
      // no firm in the subject - the sender's company domain may still name it
      const byDomain = await uniqueInvestorByDomain(supabase, organizationId, sender);
      if (byDomain) return { ...base, relinkPartyId: byDomain };
      return base;
    }

    if (!overridable || currentType === 'investor') return { detection };
    if (
      detectAutomated({
        subject: input.subject ?? '',
        bodyPlain: input.bodyPlain ?? '',
        fromAddress: sender,
        headers: input.headers,
      })
    ) {
      return { detection };
    }

    // D - firm named in the subject
    const pairFirm = extractPairFirm(input.subject);
    if (pairFirm) {
      const id = await uniqueInvestorByName(supabase, organizationId, pairFirm);
      if (id) {
        return {
          detection,
          inferredPartyType: 'investor',
          reason: 'subject_firm',
          firmHint: pairFirm,
          relinkPartyId: id,
        };
      }
    }

    // F - sender's company domain is an investor party's website/email domain,
    //     only for a personal sender writing to us (reply, or names MarineBio)
    const byDomain = mentionsUs(input)
      ? await uniqueInvestorByDomain(supabase, organizationId, sender)
      : undefined;
    if (byDomain) {
      return {
        detection,
        inferredPartyType: 'investor',
        reason: 'sender_domain',
        relinkPartyId: byDomain,
      };
    }

    // E - sender already known as an investor contact through an intro
    const prior = await priorInvestorMail(supabase, organizationId, sender);
    if (prior) {
      const priorType = await partyTypeOf(supabase, prior.partyId);
      return {
        detection,
        inferredPartyType: 'investor',
        reason: 'prior_intro_sender',
        ...(prior.partyId && priorType === 'investor' ? { relinkPartyId: prior.partyId } : {}),
      };
    }
    return { detection };
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[investor-intro] lookup failed:', e);
    return detection.isInvestorIntro
      ? { detection, inferredPartyType: 'investor', reason: detection.reason, firmHint: detection.firmHint }
      : { detection };
  }
}
