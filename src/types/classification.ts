/**
 * types/classification.ts
 *
 * 분류기(Classifier) 에이전트의 표준 출력 타입.
 * 마스터 시스템 프롬프트 §4.2의 표준 10개 카테고리만 허용한다.
 *
 * 본 파일에 정의된 STANDARD_CATEGORIES 외의 값은 processor.ts가
 * 자동으로 `other`로 강제 변환하고 requiresHuman=true로 마킹한다.
 */

/* ============================================================
 * 1. 표준 10 카테고리 (마스터 프롬프트 §4.2)
 * ----------------------------------------------------------
 * 변경 금지. ai.auto_send_rules.classification_category와
 * 정확히 일치해야 한다.
 * ============================================================ */
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

/* ============================================================
 * 2. 위험 플래그 (분류기가 발견한 민감 토픽)
 * ----------------------------------------------------------
 * 1개라도 존재하면 자동발송 게이트가 차단한다.
 * (auto-send-gate.ts §[7] 참조)
 * ============================================================ */
export const RISK_FLAGS = [
  // investor 모듈
  'valuation_topic',
  'term_sheet_topic',
  'legal_topic',
  'financial_projection',
  'competitor_disclosure',
  // buyer 모듈
  'price_commitment',
  'moq_commitment',
  'lead_time_commitment',
  'exclusivity_request',
  'payment_terms',
  'quality_certification',
  // customer 모듈
  'pricing_dispute',
  'delivery_issue',
  'quality_complaint',
  // partner 모듈
  'capacity_commitment',
  'audit_finding_topic',
  // 공통
  'pii_in_request',
  'regulatory_topic',
  'litigation_topic',
] as const;

export type RiskFlag = (typeof RISK_FLAGS)[number];

/* ============================================================
 * 3. 보조 enum
 * ============================================================ */
export type Urgency = 'low' | 'medium' | 'high' | 'urgent';
export type Sentiment = 'positive' | 'neutral' | 'negative' | 'mixed';
export type DetectedLanguage = 'ko' | 'en' | 'ja' | 'zh' | 'other';

/* ============================================================
 * 4. ClassificationOutput
 * ----------------------------------------------------------
 * Classifier 에이전트의 system_prompt가 강제하는 JSON 스키마.
 * (ai_prompts/classifier_*.json과 동일 구조)
 * ============================================================ */
export interface ClassificationOutput {
  /** 표준 10 카테고리 중 하나. */
  category: StandardCategory;
  /** 시간 민감도. */
  urgency: Urgency;
  /** 감정 톤. */
  sentiment: Sentiment;
  /** true면 자동발송 차단, 사람 검토 필수. */
  requiresHuman: boolean;
  /** 0.0 ~ 1.0. min_confidence 비교에 사용. */
  confidence: number;
  /** 분류 근거(짧은 자연어). */
  rationale: string;
  /** 발견된 위험 플래그 목록. */
  riskFlags: RiskFlag[];
  /** 감지된 언어. */
  detectedLanguage: DetectedLanguage;
  /** 핵심 토픽 키워드(선택, knowledge_chunks 검색 보강용). */
  topics?: string[];
  /** 추출된 엔티티(선택, 회사명·금액·날짜 등). */
  entities?: Record<string, unknown>;
}

/* ============================================================
 * 5. 검증 헬퍼
 * ============================================================ */

/**
 * 임의의 문자열이 표준 카테고리인지 확인하는 type guard.
 * processor.ts에서 분류기 응답을 검증할 때 사용한다.
 */
export function isStandardCategory(value: unknown): value is StandardCategory {
  return (
    typeof value === 'string' &&
    (STANDARD_CATEGORIES as readonly string[]).includes(value)
  );
}

/**
 * 임의의 문자열이 정의된 risk flag인지 확인.
 */
export function isRiskFlag(value: unknown): value is RiskFlag {
  return (
    typeof value === 'string' &&
    (RISK_FLAGS as readonly string[]).includes(value)
  );
}

/**
 * 분류기가 반환한 임의 객체가 ClassificationOutput 형식을 만족하는지 검증.
 * 위반 시 [false, 사유 배열] 반환.
 *
 * processor.ts는 false 시 category='other', requiresHuman=true,
 * confidence=min(0.5, 원래값)로 강제한다.
 */
export function validateClassificationOutput(
  obj: unknown,
): { ok: true; value: ClassificationOutput } | { ok: false; reasons: string[] } {
  const reasons: string[] = [];

  if (!obj || typeof obj !== 'object') {
    return { ok: false, reasons: ['not_an_object'] };
  }
  const o = obj as Record<string, unknown>;

  if (!isStandardCategory(o.category)) {
    reasons.push(`invalid_category:${String(o.category)}`);
  }
  if (typeof o.confidence !== 'number' || o.confidence < 0 || o.confidence > 1) {
    reasons.push('confidence_out_of_range');
  }
  if (!['low', 'medium', 'high', 'urgent'].includes(String(o.urgency))) {
    reasons.push(`invalid_urgency:${String(o.urgency)}`);
  }
  if (!['positive', 'neutral', 'negative', 'mixed'].includes(String(o.sentiment))) {
    reasons.push(`invalid_sentiment:${String(o.sentiment)}`);
  }
  if (typeof o.requiresHuman !== 'boolean') {
    reasons.push('requires_human_not_boolean');
  }
  if (typeof o.rationale !== 'string') {
    reasons.push('rationale_not_string');
  }
  if (!Array.isArray(o.riskFlags)) {
    reasons.push('risk_flags_not_array');
  }
  if (!['ko', 'en', 'ja', 'zh', 'other'].includes(String(o.detectedLanguage))) {
    reasons.push(`invalid_detected_language:${String(o.detectedLanguage)}`);
  }

  if (reasons.length > 0) {
    return { ok: false, reasons };
  }

  // 알 수 없는 risk_flag는 silently 제거 (이후 시드 추가 시 호환을 위해)
  const sanitizedFlags = (o.riskFlags as unknown[]).filter(isRiskFlag);

  return {
    ok: true,
    value: {
      category: o.category as StandardCategory,
      urgency: o.urgency as Urgency,
      sentiment: o.sentiment as Sentiment,
      requiresHuman: o.requiresHuman as boolean,
      confidence: o.confidence as number,
      rationale: o.rationale as string,
      riskFlags: sanitizedFlags,
      detectedLanguage: o.detectedLanguage as DetectedLanguage,
      topics: Array.isArray(o.topics)
        ? (o.topics as unknown[]).filter((t): t is string => typeof t === 'string')
        : undefined,
      entities:
        o.entities && typeof o.entities === 'object'
          ? (o.entities as Record<string, unknown>)
          : undefined,
    },
  };
}
