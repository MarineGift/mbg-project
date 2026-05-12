/**
 * lib/ai/pii-masker.ts
 *
 * AI 호출 직전에 inboundMessage의 PII를 토큰으로 치환하고,
 * AI 응답에서 동일 토큰을 원문으로 복원한다.
 *
 * 본 정규식 기반 마스킹은 best-effort:
 *   - 한국 주민·여권·사업자·전화번호
 *   - 국제 전화번호(E.164 비슷한 형태)
 *   - 이메일 주소
 *   - 신용카드 번호 (16자리)
 * 변형 표기·외국 형식 일부는 누락. 향후 NER 모델 추가 검토.
 *
 * 사용:
 *   const { masked, tokens, categories } = maskPii(rawText);
 *   const aiOutput = await claude.complete({ inboundMessage: masked });
 *   const restored = restorePii(aiOutput.content, tokens);
 */

/* ============================================================
 * 1. 타입 정의
 * ============================================================ */

export type PiiTokenMap = Map<string, string>;

export interface MaskResult {
  /** PII가 토큰으로 치환된 텍스트. */
  masked: string;
  /** 토큰 → 원문 매핑. 호출 단위로 메모리에 유지하고 응답 직후 폐기. */
  tokens: PiiTokenMap;
  /** 발견된 PII 카테고리 목록(중복 제거). ai.runs.pii_categories_detected에 저장. */
  categories: string[];
  /** 마스킹된 토큰 총 개수. */
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
 * 2. 정규식 패턴
 * ----------------------------------------------------------
 * 순서가 중요: 더 구체적인 패턴이 먼저 매칭되어야 한다.
 * 예: 신용카드(16자리)는 일반 숫자 패턴보다 먼저.
 *
 * 모든 정규식은 'g' 플래그로 다중 매칭 + lastIndex 자동 진행.
 * ============================================================ */
interface PiiPattern {
  name: PiiCategory;
  regex: RegExp;
  /**
   * 매칭된 문자열을 검증하는 추가 함수(선택).
   * 예: 신용카드의 Luhn 체크섬, 주민번호의 마지막 자리 검증.
   */
  validate?: (match: string) => boolean;
}

const PATTERNS: PiiPattern[] = [
  // 한국 주민등록번호: 6자리-1자리(1~4)+6자리, 또는 13자리 연속
  // 1·2·3·4 = 1900년대 남/여, 2000년대 남/여
  {
    name: 'national_id_kr',
    regex: /\b\d{6}-?[1-4]\d{6}\b/g,
  },
  // 한국 사업자등록번호: 3-2-5
  {
    name: 'business_id_kr',
    regex: /\b\d{3}-\d{2}-\d{5}\b/g,
  },
  // 한국 여권번호: M+8자리 또는 S+8자리(구형) / 알파벳 1자+8자리(신형)
  {
    name: 'passport_kr',
    regex: /\b[A-Z]\d{8}\b/g,
  },
  // 신용카드: 16자리(공백·하이픈 허용). Luhn 체크로 false positive 줄임.
  {
    name: 'credit_card',
    regex: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g,
    validate: (match: string): boolean => luhnCheck(match.replace(/[\s-]/g, '')),
  },
  // 한국 휴대전화: 010-1234-5678 / 010 1234 5678 / 01012345678
  {
    name: 'phone_kr',
    regex: /\b01[0-9][\s.-]?\d{3,4}[\s.-]?\d{4}\b/g,
  },
  // 한국 일반전화: 02·031~064 등 지역번호 + 3-4자리 + 4자리
  {
    name: 'phone_kr',
    regex: /\b0(?:2|[3-6][1-5])[\s.-]?\d{3,4}[\s.-]?\d{4}\b/g,
  },
  // 일본 휴대전화: 080·090·070 + 4자리 + 4자리
  {
    name: 'phone_jp',
    regex: /\b0[789]0[\s.-]?\d{4}[\s.-]?\d{4}\b/g,
  },
  // 미국 전화: (555) 123-4567 / 555-123-4567 / +1 555 123 4567
  {
    name: 'phone_us',
    regex: /\b(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b/g,
  },
  // 국제 전화: + 1~3자리 국가코드 + 7~14자리
  {
    name: 'phone_intl',
    regex: /\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{2,4}[\s.-]?\d{2,4}/g,
  },
  // 이메일 주소
  {
    name: 'email',
    regex: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g,
  },
  // 한국 계좌번호: 3-6자리 + 하이픈 + 2-4자리 + 하이픈 + 6자리 (대표적 형태)
  {
    name: 'bank_account_kr',
    regex: /\b\d{3,6}-\d{2,4}-\d{6,7}\b/g,
  },
  // IBAN: 2자리 국가코드 + 2자리 체크 + 최대 30자리
  {
    name: 'iban',
    regex: /\b[A-Z]{2}\d{2}[A-Z0-9]{4,30}\b/g,
  },
];

/* ============================================================
 * 3. Luhn 체크섬 (신용카드 검증)
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
 * 4. 마스킹
 * ============================================================ */

/**
 * 입력 텍스트의 PII를 `{{PII_001}}`, `{{PII_002}}` 형태 토큰으로 치환.
 *
 * - 같은 원문이 여러 번 등장해도 동일 토큰 재사용(맥락 보존).
 * - 정규식 우선순위: PATTERNS 배열 순서.
 * - 한 번 매칭된 위치는 다른 패턴이 다시 매칭하지 않음(전치된 토큰 자체는 매칭 불가).
 */
export function maskPii(text: string): MaskResult {
  if (!text) {
    return { masked: text, tokens: new Map(), categories: [], tokenCount: 0 };
  }

  const tokens: PiiTokenMap = new Map();
  const reverseLookup: Map<string, string> = new Map(); // 원문 → 토큰
  const categories = new Set<string>();
  let counter = 0;
  let masked = text;

  for (const pattern of PATTERNS) {
    masked = masked.replace(pattern.regex, (match) => {
      // validate 함수가 있고 false면 마스킹하지 않음
      if (pattern.validate && !pattern.validate(match)) {
        return match;
      }
      // 동일 원문이 이미 토큰화되었으면 재사용
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
 * 5. 복원
 * ============================================================ */

/**
 * AI 응답에서 토큰을 원문으로 되돌린다.
 *
 * - 토큰 형식 `{{PII_NNN}}` 외의 텍스트는 변경하지 않음.
 * - AI가 토큰을 망가뜨려 출력한 경우(예: `{{ PII_001 }}`)는 복원되지 않음.
 *   이때 호출자는 임시 토큰이 출력에 남았다는 사실로 검증 가능.
 */
export function restorePii(text: string, tokens: PiiTokenMap): string {
  if (!text || tokens.size === 0) return text;

  let restored = text;
  for (const [token, original] of tokens) {
    // String.replaceAll은 ES2021. tsconfig target이 ES2021+여야 함.
    restored = restored.split(token).join(original);
  }
  return restored;
}

/* ============================================================
 * 6. 검증 헬퍼
 * ============================================================ */

/**
 * 텍스트에 미복원 PII 토큰이 남아있는지 확인.
 * processor.ts에서 회신가 출력 검증 시 사용.
 */
export function hasUnrestoredTokens(text: string): boolean {
  return /\{\{PII_\d{3}\}\}/.test(text);
}

/**
 * 텍스트에서 미복원 토큰을 추출.
 */
export function findUnrestoredTokens(text: string): string[] {
  const matches = text.match(/\{\{PII_\d{3}\}\}/g);
  return matches ?? [];
}
