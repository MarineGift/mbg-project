/**
 * 호출 단위로만 사용되는 토큰→원문 매핑.
 */
export type PiiTokenMap = Map<string, string>;

export interface MaskResult {
  masked: string;
  tokens: PiiTokenMap;
  categories: string[];
}

const PATTERNS: ReadonlyArray<{ name: string; regex: RegExp }> = [
  { name: 'national_id_kr', regex: /\b\d{6}-?[1-4]\d{6}\b/g },
  { name: 'business_id_kr', regex: /\b\d{3}-\d{2}-\d{5}\b/g },
  { name: 'passport', regex: /\b[A-Z]\d{8}\b/g },
  { name: 'credit_card', regex: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g },
  { name: 'phone_kr', regex: /\b01[0-9][\s.-]?\d{3,4}[\s.-]?\d{4}\b/g },
  { name: 'phone_jp', regex: /\b0[789]0[\s.-]?\d{4}[\s.-]?\d{4}\b/g },
  { name: 'phone_intl', regex: /\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{2,4}[\s.-]?\d{2,4}\b/g },
  { name: 'email', regex: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g },
  { name: 'bank_account_kr', regex: /\b\d{2,4}-\d{2,6}-\d{2,8}(?:-\d{1,4})?\b/g },
];

export function maskPii(text: string): MaskResult {
  if (!text) {
    return { masked: text ?? '', tokens: new Map(), categories: [] };
  }
  const tokens: PiiTokenMap = new Map();
  const categories = new Set<string>();
  let counter = 0;
  let masked = text;

  for (const { name, regex } of PATTERNS) {
    masked = masked.replace(regex, (match) => {
      counter += 1;
      const token = `{{PII_${String(counter).padStart(3, '0')}}}`;
      tokens.set(token, match);
      categories.add(name);
      return token;
    });
  }

  return {
    masked,
    tokens,
    categories: Array.from(categories),
  };
}

export function restorePii(text: string, tokens: PiiTokenMap): string {
  if (!text || tokens.size === 0) return text;
  let restored = text;
  for (const [token, original] of tokens) {
    restored = restored.split(token).join(original);
  }
  return restored;
}

export function detectPiiCategories(text: string): string[] {
  if (!text) return [];
  const found = new Set<string>();
  for (const { name, regex } of PATTERNS) {
    if (regex.test(text)) found.add(name);
    regex.lastIndex = 0;
  }
  return Array.from(found);
}
