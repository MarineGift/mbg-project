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

/* ============================================================
 * Ingest helper (DB)
 * ============================================================ */

/** party types an investor intro is allowed to override */
const OVERRIDABLE_TYPES = new Set(['mentor', 'investor']);

export interface InvestorIntroResolution {
  /** set when the message should be re-linked to an investor party */
  relinkPartyId?: string;
  /** value for external_data.inferred_party_type ('investor') or undefined */
  inferredPartyType?: 'investor';
  detection: InvestorIntroResult;
}

function escapeLike(s: string): string {
  return s.replace(/[\\%_]/g, (c) => `\\${c}`);
}

/**
 * Decide investor classification for one inbound message.
 * Never throws - a lookup failure must not block ingest.
 *
 * Guard: a message already linked to a business party (paper mill, filler
 * supplier, partner, ...) is left alone, because our own signature mentions
 * Greentown Labs and replies quote it. Only unlinked / mentor / investor
 * messages are touched - except mail from a Greentown intro sender, which is
 * always an investor intro.
 */
export async function resolveInvestorIntro(
  supabase: SupabaseClient,
  organizationId: string,
  input: InvestorIntroInput,
  currentPartyId: string | null,
): Promise<InvestorIntroResolution> {
  const detection = detectInvestorIntro(input);
  if (!detection.isInvestorIntro) return { detection };

  try {
    let currentType: string | null = null;
    if (currentPartyId) {
      const { data } = await supabase
        .schema('app')
        .from('parties')
        .select('id, party_types(code)')
        .eq('id', currentPartyId)
        .maybeSingle();
      const pt = (data as { party_types?: { code?: string } | Array<{ code?: string }> } | null)
        ?.party_types;
      currentType = (Array.isArray(pt) ? pt[0]?.code : pt?.code) ?? null;
    }

    const allowed =
      detection.reason === 'greentown_sender' ||
      currentType === null ||
      OVERRIDABLE_TYPES.has(currentType);
    if (!allowed) return { detection: { isInvestorIntro: false } };
    if (currentType === 'investor') return { detection, inferredPartyType: 'investor' };

    // Try to re-link to the named investor firm (exact name, case-insensitive,
    // and only when exactly one investor party carries that name).
    if (detection.firmHint) {
      const { data: firms } = await supabase
        .schema('app')
        .from('parties')
        .select('id, party_types!inner(code)')
        .eq('organization_id', organizationId)
        .eq('party_types.code', 'investor')
        .is('deleted_at', null)
        .ilike('party_name', escapeLike(detection.firmHint))
        .limit(2);
      const rows = (firms ?? []) as Array<{ id: string }>;
      if (rows.length === 1 && rows[0]) {
        return { detection, relinkPartyId: rows[0].id, inferredPartyType: 'investor' };
      }
    }
    return { detection, inferredPartyType: 'investor' };
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[investor-intro] lookup failed:', e);
    return { detection, inferredPartyType: 'investor' };
  }
}
