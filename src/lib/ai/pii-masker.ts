/**
 * lib/ai/pii-masker.ts
 *
 * Just before an AI call, replaces PII in the inboundMessage with tokens, and
 * restores those same tokens to the original text in the AI response.
 *
 * This regex-based masking is best-effort:
 *   - Korean resident/passport/business-registration/phone numbers
 *   - international phone numbers (E.164-like form)
 *   - email addresses
 *   - credit card numbers (16 digits)
 * Some variant notations and foreign formats are missed. Consider adding an NER model later.
 *
 * Usage:
 *   const { masked, tokens, categories } = maskPii(rawText);
 *   const aiOutput = await claude.complete({ inboundMessage: masked });
 *   const restored = restorePii(aiOutput.content, tokens);
 */

/* ============================================================
 * 1. Type definitions
 * ============================================================ */

export type PiiTokenMap = Map<string, string>;

export interface MaskResult {
  /** Text with PII replaced by tokens. */
  masked: string;
  /** Token -> original-text mapping. Kept in memory per call and discarded right after the response. */
  tokens: PiiTokenMap;
  /** List of detected PII categories (deduplicated). Stored in ai.runs.pii_categories_detected. */
  categories: string[];
  /** Total number of masked tokens. */
  tokenCount: number;
}

export type PiiCategory =
  | 'national_id_kr'
  | 'business_id_kr'
  | 'passport_kr'
  | 'phone_kr'
  | 'phone_intl'
  | 'phone_jp'
  | 'phone_us'
  | 'email'
  | 'credit_card'
  | 'bank_account_kr'
  | 'iban';

/* ============================================================
 * 2. Regex patterns
 * ----------------------------------------------------------
 * Order matters: more specific patterns must match first.
 * e.g. credit cards (16 digits) before the generic number pattern.
 *
 * All regexes use the 'g' flag for multiple matches + automatic lastIndex advance.
 * ============================================================ */
interface PiiPattern {
  name: PiiCategory;
  regex: RegExp;
  /**
   * Optional extra function that validates a matched string.
   * e.g. Luhn checksum for credit cards, last-digit check for resident numbers.
   */
  validate?: (match: string) => boolean;
}

const PATTERNS: PiiPattern[] = [
  // Korean resident registration number: 6 digits-1 digit(1-4)+6 digits, or 13 consecutive digits
  // 1/2/3/4 = 1900s male/female, 2000s male/female
  {
    name: 'national_id_kr',
    regex: /\b\d{6}-?[1-4]\d{6}\b/g,
  },
  // Korean business registration number: 3-2-5
  {
    name: 'business_id_kr',
    regex: /\b\d{3}-\d{2}-\d{5}\b/g,
  },
  // Korean passport number: M+8 digits or S+8 digits (old) / 1 letter+8 digits (new)
  {
    name: 'passport_kr',
    regex: /\b[A-Z]\d{8}\b/g,
  },
  // Credit card: 16 digits (spaces/hyphens allowed). The Luhn check reduces false positives.
  {
    name: 'credit_card',
    regex: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g,
    validate: (match: string): boolean => luhnCheck(match.replace(/[\s-]/g, '')),
  },
  // Korean mobile phone: 010-1234-5678 / 010 1234 5678 / 01012345678
  {
    name: 'phone_kr',
    regex: /\b01[0-9][\s.-]?\d{3,4}[\s.-]?\d{4}\b/g,
  },
  // Korean landline: area code such as 02 / 031-064 + 3-4 digits + 4 digits
  {
    name: 'phone_kr',
    regex: /\b0(?:2|[3-6][1-5])[\s.-]?\d{3,4}[\s.-]?\d{4}\b/g,
  },
  // Japanese mobile: 080 / 090 / 070 + 4 digits + 4 digits
  {
    name: 'phone_jp',
    regex: /\b0[789]0[\s.-]?\d{4}[\s.-]?\d{4}\b/g,
  },
  // US phone: (555) 123-4567 / 555-123-4567 / +1 555 123 4567
  {
    name: 'phone_us',
    regex: /\b(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b/g,
  },
  // International phone: + 1-3 digit country code + 7-14 digits
  {
    name: 'phone_intl',
    regex: /\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{2,4}[\s.-]?\d{2,4}/g,
  },
  // email address
  {
    name: 'email',
    regex: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g,
  },
  // Korean bank account: 3-6 digits + hyphen + 2-4 digits + hyphen + 6 digits (typical form)
  {
    name: 'bank_account_kr',
    regex: /\b\d{3,6}-\d{2,4}-\d{6,7}\b/g,
  },
  // IBAN: 2-digit country code + 2-digit check + up to 30 digits
  {
    name: 'iban',
    regex: /\b[A-Z]{2}\d{2}[A-Z0-9]{4,30}\b/g,
  },
];

/* ============================================================
 * 3. Luhn checksum (credit-card validation)
 * ============================================================ */
function luhnCheck(num: string): boolean {
  if (!/^\d{13,19}$/.test(num)) return false;
  let sum = 0;
  let alt = false;
  for (let i = num.length - 1; i >= 0; i -= 1) {
    let n = parseInt(num.charAt(i), 10);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 === 0;
}

/* ============================================================
 * 4. Masking
 * ============================================================ */

/**
 * Replace PII in the input text with tokens of the form `{{PII_001}}`, `{{PII_002}}`.
 *
 * - reuse the same token even if the same text appears multiple times (preserves context).
 * - regex priority: the order of the PATTERNS array.
 * - a position once matched is not matched again by another pattern (the substituted token itself can't match).
 */
export function maskPii(text: string): MaskResult {
  if (!text) {
    return { masked: text, tokens: new Map(), categories: [], tokenCount: 0 };
  }

  const tokens: PiiTokenMap = new Map();
  const reverseLookup: Map<string, string> = new Map(); // original -> token
  const categories = new Set<string>();
  let counter = 0;
  let masked = text;

  for (const pattern of PATTERNS) {
    masked = masked.replace(pattern.regex, (match) => {
      // if a validate function exists and returns false, do not mask
      if (pattern.validate && !pattern.validate(match)) {
        return match;
      }
      // if the same text is already tokenized, reuse it
      const existing = reverseLookup.get(match);
      if (existing) {
        return existing;
      }
      counter += 1;
      const token = `{{PII_${String(counter).padStart(3, '0')}}}`;
      tokens.set(token, match);
      reverseLookup.set(match, token);
      categories.add(pattern.name);
      return token;
    });
  }

  return {
    masked,
    tokens,
    categories: Array.from(categories),
    tokenCount: counter,
  };
}

/* ============================================================
 * 5. Restoration
 * ============================================================ */

/**
 * Revert tokens back to the original text in the AI response.
 *
 * - text other than the `{{PII_NNN}}` token format is left unchanged.
 * - if the AI outputs a corrupted token (e.g. `{{ PII_001 }}`), it is not restored.
 *   In that case the caller can validate via the fact that a temporary token remains in the output.
 */
export function restorePii(text: string, tokens: PiiTokenMap): string {
  if (!text || tokens.size === 0) return text;

  let restored = text;
  for (const [token, original] of tokens) {
    // String.replaceAll is ES2021. The tsconfig target must be ES2021+.
    restored = restored.split(token).join(original);
  }
  return restored;
}

/* ============================================================
 * 6. Validation helpers
 * ============================================================ */

/**
 * Check whether any unrestored PII tokens remain in the text.
 * Used by processor.ts when validating reply-drafter output.
 */
export function hasUnrestoredTokens(text: string): boolean {
  return /\{\{PII_\d{3}\}\}/.test(text);
}

/**
 * Extract unrestored tokens from the text.
 */
export function findUnrestoredTokens(text: string): string[] {
  const matches = text.match(/\{\{PII_\d{3}\}\}/g);
  return matches ?? [];
}
