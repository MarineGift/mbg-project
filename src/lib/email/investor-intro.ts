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
