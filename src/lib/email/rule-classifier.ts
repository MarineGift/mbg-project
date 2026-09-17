/**
 * lib/email/rule-classifier.ts
 *
 * Classifies an inbound email WITHOUT calling any AI API (2026-09-17).
 * Output has the same shape as the AI classifier (ClassificationOutput), so
 * ai.drafts / communications.ai_classification / the UI badge keep working.
 *
 * How it works (deterministic, zero cost):
 *   1. automated-mail detection  (List-Unsubscribe, Precedence, Auto-Submitted,
 *      noreply-style senders, out-of-office subjects)
 *   2. keep only the NEW part of the body (quoted history is dropped so our
 *      own earlier outbound text does not trigger keywords)
 *   3. keyword rules (en / ko / ja) -> one of the 10 standard categories
 *   4. keyword rules -> risk flags, urgency, sentiment
 *   5. script detection -> language
 *
 * Rules are intentionally conservative: requiresHuman is always true
 * (auto-send stays blocked for rule-based results).
 */

import type {
  ClassificationOutput,
  DetectedLanguage,
  RiskFlag,
  Sentiment,
  StandardCategory,
  Urgency,
} from '../../types/classification';

export interface RuleClassifierInput {
  subject: string;
  bodyPlain: string;
  fromAddress?: string;
  /** lower-case header name -> value (communications.external_data.raw_selected_headers) */
  headers?: Record<string, string>;
}

export interface RuleClassifierResult {
  classification: ClassificationOutput;
  /** true for newsletters, notifications, auto-replies, bounces. */
  isAutomated: boolean;
  automatedReason?: string;
}

/* ============================================================
 * 1. Automated mail
 * ============================================================ */

const AUTOMATED_SENDER =
  /^(no[-_.]?reply|do[-_.]?not[-_.]?reply|mailer-daemon|postmaster|bounces?|notifications?|notify|alerts?|newsletters?|news|marketing|updates|digest|info-noreply)([-_.+][^@]*)?@/i;

const AUTO_REPLY_SUBJECT =
  /^(automatic reply|auto(matic)?[- ]?reply|autoreply|out of (the )?office|away from (the )?office|undeliverable|delivery status notification|mail delivery failed|returned mail|자동\s*회신|자동\s*응답|부재\s*중|자동返信|不在)/i;

export function detectAutomated(input: RuleClassifierInput): string | undefined {
  const h = input.headers ?? {};
  const get = (k: string) => (h[k] ?? h[k.toLowerCase()] ?? '').trim();

  if (get('list-unsubscribe')) return 'list-unsubscribe header';
  const precedence = get('precedence').toLowerCase();
  if (/^(bulk|list|junk|auto_reply)$/.test(precedence)) return `precedence: ${precedence}`;
  const autoSubmitted = get('auto-submitted').toLowerCase();
  if (autoSubmitted && autoSubmitted !== 'no') return `auto-submitted: ${autoSubmitted}`;
  if (get('x-autoreply') || get('x-autorespond')) return 'auto-reply header';

  const from = (input.fromAddress ?? '').trim();
  if (from && AUTOMATED_SENDER.test(from)) return `sender: ${from.split('@')[0]}`;

  const subject = (input.subject ?? '').trim().replace(/^(re|fw|fwd)\s*:\s*/i, '');
  if (AUTO_REPLY_SUBJECT.test(subject)) return 'auto-reply subject';

  return undefined;
}

/* ============================================================
 * 2. New-text extraction (drop quoted history)
 * ============================================================ */

const QUOTE_START = [
  /^On .{4,200}wrote:\s*$/i,
  /^-{2,}\s*Original Message\s*-{2,}/i,
  /^-{2,}\s*Forwarded message\s*-{2,}/i,
  /^_{10,}\s*$/,
  /^From:\s.+/i,
  /^(보낸\s*사람|보낸사람|발신자)\s*:/,
  /^20\d\d.{0,40}(작성|님이 작성)/,
  /^差出人\s*[:：]/,
];

export function extractNewText(body: string): string {
  const lines = (body ?? '').replace(/\r\n/g, '\n').split('\n');
  const out: string[] = [];
  for (const line of lines) {
    const t = line.trim();
    if (QUOTE_START.some((re) => re.test(t))) break;
    if (t.startsWith('>')) continue;
    out.push(line);
  }
  return out.join('\n').slice(0, 6000);
}

/* ============================================================
 * 3. Keyword rules
 * ============================================================ */

type Rule = { category: StandardCategory; patterns: RegExp[] };

// Order = priority (first match wins).
const CATEGORY_RULES: Rule[] = [
  {
    category: 'rejection',
    patterns: [
      /\b(not (a|the) (good |right )?fit|not a match|(we|i) will (have to )?pass|decided (not|to pass)|unable to (move forward|proceed)|not (be )?moving forward|not interested|no longer interested|decline)\b/i,
      /(어렵겠습니다|어려울 것 같습니다|진행하지 않기로|정중히 거절|관심이 없|참여하지 않기로)/,
      /(見送|お断り|辞退)/,
    ],
  },
  {
    category: 'complaint',
    patterns: [
      /\b(complain(t|ing)?|disappointed|unacceptable|not satisfied|dissatisfied|poor quality|defect(ive)?)\b/i,
      /(불만|항의|실망|불량|하자)/,
      /(苦情|クレーム|不良品)/,
    ],
  },
  {
    category: 'contract_terms',
    patterns: [
      /\b(contract|agreement|nda|non-disclosure|term sheet|mou|loi|letter of intent|licen[cs]e agreement|royalt(y|ies)|redline|signature page|docusign)\b/i,
      /(계약|협약|비밀유지|양해각서|로열티|라이선스 계약|서명)/,
      /(契約|秘密保持|覚書|ロイヤリティ)/,
    ],
  },
  {
    category: 'price_negotiation',
    patterns: [
      /\b(price|pricing|quote|quotation|discount|cost per|per ton|usd\s?\d|\$\s?\d|budget|rate card)\b/i,
      /(가격|단가|견적|할인|비용|톤당)/,
      /(価格|見積|値引|単価)/,
    ],
  },
  {
    category: 'meeting_scheduling',
    patterns: [
      /\b(meet(ing)?|call|zoom|teams|google meet|calendly|schedule|reschedule|availability|available (on|at|for)|time slot|coffee chat|catch up)\b/i,
      /(미팅|회의|통화|일정|시간 (괜찮|되시)|만나|화상)/,
      /(打ち合わせ|ミーティング|ご都合|日程|面談)/,
    ],
  },
  {
    category: 'introduction',
    patterns: [
      /\b(introduc(e|ing|tion)|connect you (with|to)|e-?intro|looping in|allow me to present|nice to meet)\b/i,
      /(소개(해|드|합)|인사드립니다|처음 연락)/,
      /(ご紹介|はじめまして|初めまして)/,
    ],
  },
  {
    category: 'follow_up',
    patterns: [
      /\b(follow(ing)?[- ]up|checking in|circling back|just a reminder|gentle reminder|any update|touch base|bumping this)\b/i,
      /(후속|리마인드|진행 상황|확인 부탁|다시 연락)/,
      /(フォローアップ|リマインド|進捗)/,
    ],
  },
  {
    category: 'information_request',
    patterns: [
      /\b(could|can|would) you (please )?(send|share|provide|tell|explain)\b/i,
      /\b(please (send|share|provide)|more (info|information|details)|questions? (about|regarding|on)|wondering (if|whether))\b/i,
      /(문의|자료|알려 ?주|보내 ?주|궁금)/,
      /(教えて|資料|お問い合わせ|ご質問)/,
    ],
  },
  {
    category: 'simple_acknowledgment',
    patterns: [
      /^\s*(thanks?|thank you|many thanks|received|noted|got it|sounds good|great|perfect|will do|ok(ay)?)\b[\s\S]{0,160}$/i,
      /^\s*(감사합니다|잘 받았습니다|확인했습니다|알겠습니다|네)[\s\S]{0,120}$/,
      /^\s*(ありがとうございます|承知しました|受領しました)[\s\S]{0,120}$/,
    ],
  },
];

const RISK_RULES: Array<{ flag: RiskFlag; pattern: RegExp }> = [
  { flag: 'valuation_topic', pattern: /\b(valuation|pre-money|post-money|cap table|safe note|convertible)\b|밸류에이션|기업가치/i },
  { flag: 'term_sheet_topic', pattern: /\bterm ?sheet\b|텀\s?시트/i },
  { flag: 'legal_topic', pattern: /\b(nda|attorney|lawyer|legal counsel|indemnif|liabilit)\w*|변호사|법무|법률/i },
  { flag: 'litigation_topic', pattern: /\b(lawsuit|litigation|infring\w*|opposition|invalidat\w*)\b|소송|침해|무효/i },
  { flag: 'financial_projection', pattern: /\b(projection|forecast|revenue model|financials)\b|매출 전망|재무 계획/i },
  { flag: 'competitor_disclosure', pattern: /\b(competitor|competing)\b|경쟁사/i },
  { flag: 'price_commitment', pattern: /\b(firm price|price commitment|binding (price|quote))\b|확정 가격/i },
  { flag: 'exclusivity_request', pattern: /\bexclusiv\w*|독점/i },
  { flag: 'payment_terms', pattern: /\b(payment terms?|invoice|wire transfer|net ?\d{2})\b|결제 조건|송금|인보이스/i },
  { flag: 'regulatory_topic', pattern: /\b(regulat\w*|compliance|fda|epa|reach|export control)\b|규제|인허가/i },
];

function firstMatch(haystack: string, newText: string): StandardCategory | undefined {
  for (const rule of CATEGORY_RULES) {
    // a short thank-you is judged on the new body text only (subject excluded)
    const text = rule.category === 'simple_acknowledgment' ? newText.trim() : haystack;
    if (rule.patterns.some((re) => re.test(text))) return rule.category;
  }
  return undefined;
}

/* ============================================================
 * 4. Language / urgency / sentiment
 * ============================================================ */

export function detectLanguage(text: string): DetectedLanguage {
  const sample = text.slice(0, 2000);
  const hangul = (sample.match(/[\uAC00-\uD7A3]/g) ?? []).length;
  const kana = (sample.match(/[\u3040-\u30FF]/g) ?? []).length;
  const han = (sample.match(/[\u4E00-\u9FFF]/g) ?? []).length;
  const latin = (sample.match(/[A-Za-z]/g) ?? []).length;
  if (hangul >= 5 && hangul * 3 >= latin * 0.5) return 'ko';
  if (kana >= 5) return 'ja';
  if (han >= 10 && hangul === 0 && kana === 0) return 'zh';
  if (latin >= 20) return 'en';
  if (hangul > 0) return 'ko';
  return 'other';
}

function detectUrgency(text: string): Urgency {
  if (/\b(urgent|asap|immediately|by (today|tomorrow|eod))\b|긴급|급히|오늘 중|至急|大至急/i.test(text)) {
    return 'high';
  }
  return 'medium';
}

function sentimentFor(category: StandardCategory | undefined, text: string): Sentiment {
  if (category === 'rejection' || category === 'complaint') return 'negative';
  if (/\b(excited|great news|congratulations|impressed|love to)\b|기쁘|축하|감사드립니다/i.test(text)) {
    return 'positive';
  }
  return 'neutral';
}

/* ============================================================
 * 5. Entry point
 * ============================================================ */

export function classifyByRules(input: RuleClassifierInput): RuleClassifierResult {
  const automatedReason = detectAutomated(input);
  const newText = extractNewText(input.bodyPlain);
  const subject = (input.subject ?? '').replace(/^((re|fw|fwd|답장|전달)\s*:\s*)+/i, '');
  const haystack = `${subject}\n${newText}`;

  let matched = automatedReason ? undefined : firstMatch(haystack, newText);
  // a plain question with no other signal is most likely a request for info
  if (!automatedReason && !matched && /[?？]/.test(newText)) matched = 'information_request';
  const category: StandardCategory = matched ?? 'other';

  const riskFlags = Array.from(
    new Set(RISK_RULES.filter((r) => r.pattern.test(haystack)).map((r) => r.flag)),
  );

  const classification: ClassificationOutput = {
    category,
    urgency: automatedReason ? 'low' : detectUrgency(haystack),
    sentiment: sentimentFor(matched, haystack),
    requiresHuman: true,
    confidence: automatedReason ? 0.9 : matched ? 0.6 : 0.3,
    rationale: automatedReason
      ? `rules: automated mail (${automatedReason})`
      : matched
        ? `rules: keyword match -> ${matched}`
        : 'rules: no keyword match',
    riskFlags,
    detectedLanguage: detectLanguage(`${input.subject ?? ''}\n${newText}`),
  };

  return { classification, isAutomated: Boolean(automatedReason), automatedReason };
}
