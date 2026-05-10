/**
 * 표준 10개 분류 카테고리. 마스터 시스템 프롬프트 §4.2에 의해 명명·개수 변경 금지.
 *
 * 분류기 출력, ai.auto_send_rules.classification_category, Reply Drafter의
 * risk 분기 처리에서 모두 동일한 명명을 사용해야 한다.
 */
export const STANDARD_CATEGORIES = [
  'information_request',
  'meeting_scheduling',
  'simple_acknowledgment',
  'price_negotiation',
  'contract_terms',
  'rejection',
  'complaint',
  'introduction',
  'follow_up',
  'other',
] as const;

export type StandardCategory = (typeof STANDARD_CATEGORIES)[number];

/**
 * STANDARD_CATEGORIES 중에서 자동발송이 정책상 허용 가능한 화이트리스트.
 * 마스터 §4.1에 의해 'price_negotiation', 'contract_terms', 'rejection',
 * 'complaint', 'introduction', 'follow_up', 'other'는 항상 차단.
 *
 * 실제 자동발송 여부는 ai.auto_send_rules + auto-send-gate.ts에서 최종 결정되며,
 * 본 상수는 코드 레벨의 추가 안전망 역할을 한다.
 */
export const AUTO_SEND_CANDIDATE_CATEGORIES: ReadonlySet<StandardCategory> = new Set([
  'information_request',
  'meeting_scheduling',
  'simple_acknowledgment',
]);

/**
 * 분류기·답장 드래프터가 출력할 수 있는 위험 신호 플래그.
 * 운영 시 새로운 플래그가 필요하면 본 배열에만 추가하고 DB 시드와 동기화한다.
 */
export const RISK_FLAGS = [
  'price_commitment_required',
  'legal_terms_present',
  'contract_amendment_requested',
  'urgent_response_required',
  'sensitive_personal_info',
  'regulated_industry_topic',
  'competitor_mentioned',
  'negative_sentiment_high',
  'escalation_requested',
  'meeting_change_required',
  'attachment_review_required',
  'compliance_flag',
  'unknown_party',
  'jurisdiction_uncertainty',
  'language_mismatch',
] as const;

export type RiskFlag = (typeof RISK_FLAGS)[number];

/**
 * Haiku 분류기의 정형 출력. processor.ts에서 표준 카테고리·risk_flag 검증.
 */
export interface ClassificationOutput {
  category: StandardCategory;
  urgency: 'low' | 'medium' | 'high' | 'urgent';
  sentiment: 'positive' | 'neutral' | 'negative' | 'mixed';
  /** 사람 검토 필수 여부 (분류기가 self-flag 가능) */
  requiresHuman: boolean;
  /** 0.0 ~ 1.0 */
  confidence: number;
  /** 분류 근거 (한 문장) */
  rationale: string;
  riskFlags: RiskFlag[];
  detectedLanguage: 'ko' | 'en' | 'ja' | 'zh' | 'other';
}

export function isStandardCategory(value: unknown): value is StandardCategory {
  return typeof value === 'string'
    && (STANDARD_CATEGORIES as readonly string[]).includes(value);
}

export function isRiskFlag(value: unknown): value is RiskFlag {
  return typeof value === 'string'
    && (RISK_FLAGS as readonly string[]).includes(value);
}

/**
 * 분류기 raw 출력에서 비표준 risk_flag를 제거해 안전한 RiskFlag[]로 정규화한다.
 * 비표준 플래그는 console.warn으로만 기록 (하드 throw 하지 않음 — 분류 자체는 살리고
 * 게이트에서 'unknown_risk_flag' 사유로 차단하는 정책).
 */
export function sanitizeRiskFlags(raw: unknown): RiskFlag[] {
  if (!Array.isArray(raw)) return [];
  const result: RiskFlag[] = [];
  for (const candidate of raw) {
    if (isRiskFlag(candidate)) {
      result.push(candidate);
    } else if (typeof candidate === 'string') {
      // eslint-disable-next-line no-console
      console.warn(`[classification] dropping unknown risk_flag: ${candidate}`);
    }
  }
  return result;
}

/**
 * 분류기 raw 출력을 ClassificationOutput으로 정규화. 카테고리 위반 시
 * 'other'로 강제 + requires_human=true. 본 함수는 처음 JSON 파싱 직후 호출.
 */
export function normalizeClassification(raw: unknown): ClassificationOutput {
  if (typeof raw !== 'object' || raw === null) {
    return makeFallbackClassification('non_object_response');
  }
  const r = raw as Record<string, unknown>;

  let category: StandardCategory = 'other';
  let requiresHuman = true;
  let confidence = 0.5;

  if (isStandardCategory(r.category)) {
    category = r.category;
  } else {
    // eslint-disable-next-line no-console
    console.warn(
      `[classification] non-standard category from classifier: ${String(r.category)} → forcing 'other'`,
    );
  }

  if (typeof r.requiresHuman === 'boolean') {
    requiresHuman = r.requiresHuman;
  } else if (typeof r.requires_human === 'boolean') {
    requiresHuman = r.requires_human;
  }

  if (typeof r.confidence === 'number'
      && Number.isFinite(r.confidence)
      && r.confidence >= 0
      && r.confidence <= 1) {
    confidence = r.confidence;
  }
  if (category === 'other') {
    confidence = Math.min(confidence, 0.5);
    requiresHuman = true;
  }

  const urgency = pickEnum(r.urgency, ['low', 'medium', 'high', 'urgent'] as const, 'medium');
  const sentiment = pickEnum(
    r.sentiment,
    ['positive', 'neutral', 'negative', 'mixed'] as const,
    'neutral',
  );
  const detectedLanguage = pickEnum(
    r.detectedLanguage ?? r.detected_language,
    ['ko', 'en', 'ja', 'zh', 'other'] as const,
    'other',
  );

  return {
    category,
    urgency,
    sentiment,
    requiresHuman,
    confidence,
    rationale: typeof r.rationale === 'string' ? r.rationale : '',
    riskFlags: sanitizeRiskFlags(r.riskFlags ?? r.risk_flags),
    detectedLanguage,
  };
}

function pickEnum<T extends string>(
  value: unknown,
  allowed: readonly T[],
  fallback: T,
): T {
  return typeof value === 'string' && (allowed as readonly string[]).includes(value)
    ? (value as T)
    : fallback;
}

function makeFallbackClassification(reason: string): ClassificationOutput {
  return {
    category: 'other',
    urgency: 'medium',
    sentiment: 'neutral',
    requiresHuman: true,
    confidence: 0.0,
    rationale: `Fallback classification (reason=${reason})`,
    riskFlags: [],
    detectedLanguage: 'other',
  };
}
