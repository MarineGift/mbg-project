/**
 * types/classification.ts
 *
 * Standard output type of the Classifier agent.
 * Only the 10 standard categories from master system prompt §4.2 are allowed.
 *
 * Values outside the STANDARD_CATEGORIES defined here are
 * automatically coerced to `other` by processor.ts and marked requiresHuman=true.
 */

/* ============================================================
 * 1. The 10 standard categories (master prompt §4.2)
 * ----------------------------------------------------------
 * Do not change. Must exactly match
 * ai.auto_send_rules.classification_category.
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
 * 2. Risk flags (sensitive topics the classifier found)
 * ----------------------------------------------------------
 * If even one is present, the auto-send gate blocks.
 * (see auto-send-gate.ts §[7])
 * ============================================================ */
export const RISK_FLAGS = [
  // investor module
  'valuation_topic',
  'term_sheet_topic',
  'legal_topic',
  'financial_projection',
  'competitor_disclosure',
  // buyer module
  'price_commitment',
  'moq_commitment',
  'lead_time_commitment',
  'exclusivity_request',
  'payment_terms',
  'quality_certification',
  // customer module
  'pricing_dispute',
  'delivery_issue',
  'quality_complaint',
  // partner module
  'capacity_commitment',
  'audit_finding_topic',
  // common
  'pii_in_request',
  'regulatory_topic',
  'litigation_topic',
] as const;

export type RiskFlag = (typeof RISK_FLAGS)[number];

/* ============================================================
 * 3. Helper enums
 * ============================================================ */
export type Urgency = 'low' | 'medium' | 'high' | 'urgent';
export type Sentiment = 'positive' | 'neutral' | 'negative' | 'mixed';
export type DetectedLanguage = 'ko' | 'en' | 'ja' | 'zh' | 'other';

/* ============================================================
 * 4. ClassificationOutput
 * ----------------------------------------------------------
 * JSON schema enforced by the Classifier agent's system_prompt.
 * (same structure as ai_prompts/classifier_*.json)
 * ============================================================ */
export interface ClassificationOutput {
  /** One of the 10 standard categories. */
  category: StandardCategory;
  /** Time sensitivity. */
  urgency: Urgency;
  /** Emotional tone. */
  sentiment: Sentiment;
  /** If true, block auto-send; human review required. */
  requiresHuman: boolean;
  /** 0.0 - 1.0. Used for the min_confidence comparison. */
  confidence: number;
  /** Classification rationale (short natural language). */
  rationale: string;
  /** List of risk flags found. */
  riskFlags: RiskFlag[];
  /** Detected language. */
  detectedLanguage: DetectedLanguage;
  /** Key topic keywords (optional, to enrich knowledge_chunks search). */
  topics?: string[];
  /** Extracted entities (optional, e.g. company name, amount, date). */
  entities?: Record<string, unknown>;
}

/* ============================================================
 * 5. Validation helpers
 * ============================================================ */

/**
 * Type guard checking whether an arbitrary string is a standard category.
 * Used by processor.ts when validating the classifier response.
 */
export function isStandardCategory(value: unknown): value is StandardCategory {
  return (
    typeof value === 'string' &&
    (STANDARD_CATEGORIES as readonly string[]).includes(value)
  );
}

/**
 * Check whether an arbitrary string is a defined risk flag.
 */
export function isRiskFlag(value: unknown): value is RiskFlag {
  return (
    typeof value === 'string' &&
    (RISK_FLAGS as readonly string[]).includes(value)
  );
}

/**
 * Validate whether an arbitrary object returned by the classifier satisfies the ClassificationOutput shape.
 * On violation, returns [false, array of reasons].
 *
 * On false, processor.ts forces category='other', requiresHuman=true,
 * confidence=min(0.5, original value).
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

  // unknown risk_flags are silently dropped (for compatibility when seeds are added later)
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
