/**
 * 가벼운 CSV 파서. RFC 4180 핵심 규칙을 따른다:
 *   - 쉼표(,)와 따옴표(")를 escape하기 위해 필드를 큰따옴표로 감쌈
 *   - 큰따옴표를 필드 안에 포함하려면 ""로 표기
 *   - CRLF / LF 모두 지원
 *
 * 외부 의존성 없이 동작 (papaparse 등 추가 안 함). 클라이언트/서버 양쪽에서 사용 가능.
 */

export interface ParseCsvResult {
  columns: string[];
  rows: Array<Record<string, string>>;
  errors: string[];
}

export function parseCsv(text: string): ParseCsvResult {
  const errors: string[] = [];
  const rawRows = tokenizeCsv(text);

  if (rawRows.length === 0) {
    return { columns: [], rows: [], errors: ['CSV 파일이 비어 있습니다'] };
  }

  const headerRow = rawRows[0];
  if (!headerRow || headerRow.length === 0) {
    return { columns: [], rows: [], errors: ['헤더 행이 없습니다'] };
  }

  const columns = headerRow.map((col, i) => {
    const trimmed = col.trim();
    if (trimmed === '') return `column_${i + 1}`;
    return trimmed;
  });

  // 중복 컬럼 검출
  const seen = new Set<string>();
  for (const col of columns) {
    if (seen.has(col)) {
      errors.push(`중복된 컬럼명: '${col}' — 두 번째 이후의 데이터가 손실될 수 있음`);
    }
    seen.add(col);
  }

  const rows: Array<Record<string, string>> = [];
  for (let i = 1; i < rawRows.length; i++) {
    const raw = rawRows[i];
    if (!raw || raw.length === 0) continue;
    if (raw.length === 1 && raw[0] === '') continue;

    const obj: Record<string, string> = {};
    for (let j = 0; j < columns.length; j++) {
      const colName = columns[j];
      if (!colName) continue;
      obj[colName] = (raw[j] ?? '').trim();
    }
    rows.push(obj);
  }

  return { columns, rows, errors };
}

/**
 * Tokenize CSV — 쉼표/줄바꿈/따옴표를 RFC 4180 규칙에 따라 처리.
 */
function tokenizeCsv(text: string): string[][] {
  const rows: string[][] = [];
  let currentRow: string[] = [];
  let currentField = '';
  let inQuotes = false;
  let i = 0;
  const len = text.length;

  while (i < len) {
    const ch = text[i];
    const next = text[i + 1];

    if (inQuotes) {
      if (ch === '"') {
        if (next === '"') {
          // escaped quote
          currentField += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      currentField += ch;
      i += 1;
      continue;
    }

    // not in quotes
    if (ch === '"') {
      // 필드 시작/중간의 따옴표
      if (currentField.length === 0) {
        inQuotes = true;
        i += 1;
        continue;
      }
      // 비표준이지만 데이터 안의 단독 따옴표는 그냥 포함
      currentField += ch;
      i += 1;
      continue;
    }
    if (ch === ',') {
      currentRow.push(currentField);
      currentField = '';
      i += 1;
      continue;
    }
    if (ch === '\r' && next === '\n') {
      currentRow.push(currentField);
      rows.push(currentRow);
      currentRow = [];
      currentField = '';
      i += 2;
      continue;
    }
    if (ch === '\n' || ch === '\r') {
      currentRow.push(currentField);
      rows.push(currentRow);
      currentRow = [];
      currentField = '';
      i += 1;
      continue;
    }
    currentField += ch;
    i += 1;
  }

  // 마지막 필드/행 flush
  if (currentField.length > 0 || currentRow.length > 0) {
    currentRow.push(currentField);
    rows.push(currentRow);
  }

  return rows;
}

/**
 * 이메일 형식 검증 — 캠페인 발송 전에 수신자 컬럼의 모든 값이 유효한지 확인.
 */
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

export function isValidEmail(value: string): boolean {
  return EMAIL_REGEX.test(value.trim());
}

/**
 * 컬럼 이름들 중 'email'에 가장 적합한 것을 자동 선택 (첫 매칭).
 * 정확히 'email' / 'e-mail' / 'mail' / '이메일' / 'email_address' 등.
 */
export function detectEmailColumn(columns: string[], firstRow?: Record<string, string>): string | null {
  const lowered = columns.map((c) => c.toLowerCase());

  // 정확히 매칭
  for (const target of ['email', 'e-mail', 'mail', 'email_address', 'emailaddress']) {
    const idx = lowered.indexOf(target);
    if (idx >= 0) return columns[idx] ?? null;
  }
  // 한국어
  for (const target of ['이메일', '메일', '이메일주소']) {
    const idx = columns.indexOf(target);
    if (idx >= 0) return columns[idx] ?? null;
  }
  // 부분 매칭
  for (let i = 0; i < lowered.length; i++) {
    const c = lowered[i];
    if (c && c.includes('email')) return columns[i] ?? null;
  }
  // 데이터 검증: 첫 행의 어떤 컬럼이 이메일 형식인지
  if (firstRow) {
    for (const col of columns) {
      const v = firstRow[col];
      if (v && isValidEmail(v)) return col;
    }
  }
  return null;
}

/**
 * 템플릿에서 사용된 변수 이름 추출. {{name}}, {{ company }} 등.
 * Returns 정렬된 unique 배열.
 */
export function extractTemplateVariables(template: string): string[] {
  const matches = template.matchAll(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g);
  const set = new Set<string>();
  for (const m of matches) {
    if (m[1]) set.add(m[1]);
  }
  return Array.from(set).sort();
}

/**
 * Liquid-style 변수 치환. prompt-renderer.ts의 applyLiquidVariables와 동일한 로직.
 * 클라이언트 컴포넌트에서 라이브 프리뷰용으로 재구현 (server-only import 우회).
 */
export function applyVariables(
  template: string,
  values: Readonly<Record<string, string | number | undefined | null>>,
): string {
  return template.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (_, key: string) => {
    const v = values[key];
    if (v === undefined || v === null) return '';
    return String(v);
  });
}
