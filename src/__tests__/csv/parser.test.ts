import { describe, it, expect } from 'vitest';
import {
  parseCsv,
  detectEmailColumn,
  isValidEmail,
  applyVariables,
  extractTemplateVariables,
} from '@/lib/csv/parser';

describe('parseCsv', () => {
  it('parses a simple CSV with headers', () => {
    const csv = 'name,email\nAlice,alice@example.com\nBob,bob@example.com';
    const r = parseCsv(csv);
    expect(r.errors).toEqual([]);
    expect(r.columns).toEqual(['name', 'email']);
    expect(r.rows).toEqual([
      { name: 'Alice', email: 'alice@example.com' },
      { name: 'Bob', email: 'bob@example.com' },
    ]);
  });

  it('handles quoted fields with commas', () => {
    const csv = 'name,company\n"Smith, John","Acme, Inc."';
    const r = parseCsv(csv);
    expect(r.rows[0]).toEqual({ name: 'Smith, John', company: 'Acme, Inc.' });
  });

  it('handles escaped quotes (double quote)', () => {
    const csv = 'name,note\n"Alice","She said ""hi"""';
    const r = parseCsv(csv);
    expect(r.rows[0]?.note).toBe('She said "hi"');
  });

  it('handles CRLF line endings', () => {
    const csv = 'a,b\r\n1,2\r\n3,4';
    const r = parseCsv(csv);
    expect(r.rows).toEqual([
      { a: '1', b: '2' },
      { a: '3', b: '4' },
    ]);
  });

  it('skips empty rows', () => {
    const csv = 'a,b\n1,2\n\n3,4\n';
    const r = parseCsv(csv);
    expect(r.rows).toHaveLength(2);
  });

  it('detects duplicate column names with warning', () => {
    const csv = 'email,name,email\na@b.com,Alice,a2@b.com';
    const r = parseCsv(csv);
    expect(r.errors.length).toBeGreaterThan(0);
    expect(r.errors[0]).toContain('email');
  });

  it('returns error for empty CSV', () => {
    const r = parseCsv('');
    expect(r.rows).toEqual([]);
    expect(r.errors).toContain('CSV 파일이 비어 있습니다');
  });

  it('handles quoted fields with newlines inside', () => {
    const csv = 'a,b\n"line1\nline2","x"';
    const r = parseCsv(csv);
    expect(r.rows[0]?.a).toBe('line1\nline2');
  });

  it('trims whitespace from cells', () => {
    const csv = 'name,age\n  Alice  ,  30  ';
    const r = parseCsv(csv);
    expect(r.rows[0]).toEqual({ name: 'Alice', age: '30' });
  });
});

describe('isValidEmail', () => {
  it.each([
    ['alice@example.com', true],
    ['user+tag@sub.example.co.kr', true],
    ['no-at-sign.com', false],
    ['@no-local.com', false],
    ['no-domain@', false],
    ['  spaced@example.com  ', true],     // trim
    ['', false],
    ['user@example', false],               // no TLD
  ])('isValidEmail(%s) → %s', (input, expected) => {
    expect(isValidEmail(input)).toBe(expected);
  });
});

describe('detectEmailColumn', () => {
  it('matches exact "email" column', () => {
    expect(detectEmailColumn(['name', 'email', 'phone'])).toBe('email');
  });

  it('matches case-insensitively', () => {
    expect(detectEmailColumn(['Name', 'EMAIL', 'Phone'])).toBe('EMAIL');
  });

  it('matches Korean column 이메일', () => {
    expect(detectEmailColumn(['이름', '이메일', '전화'])).toBe('이메일');
  });

  it('matches partial "email_address"', () => {
    expect(detectEmailColumn(['name', 'email_address'])).toBe('email_address');
  });

  it('falls back to data-based detection if no column name matches', () => {
    const result = detectEmailColumn(['col_a', 'col_b'], { col_a: 'foo', col_b: 'user@example.com' });
    expect(result).toBe('col_b');
  });

  it('returns null if no match anywhere', () => {
    const result = detectEmailColumn(['a', 'b'], { a: 'x', b: 'y' });
    expect(result).toBeNull();
  });
});

describe('extractTemplateVariables', () => {
  it('extracts {{name}} style variables', () => {
    const tpl = 'Hello {{name}}, welcome to {{company}}!';
    expect(extractTemplateVariables(tpl)).toEqual(['company', 'name']);
  });

  it('handles whitespace inside braces', () => {
    const tpl = '{{ name }} and {{  company  }}';
    expect(extractTemplateVariables(tpl)).toEqual(['company', 'name']);
  });

  it('returns unique variables only', () => {
    const tpl = '{{name}} again {{name}}';
    expect(extractTemplateVariables(tpl)).toEqual(['name']);
  });

  it('returns empty array for no variables', () => {
    expect(extractTemplateVariables('plain text')).toEqual([]);
  });
});

describe('applyVariables', () => {
  it('substitutes {{var}} with values', () => {
    const tpl = 'Hello {{name}}, you have {{count}} messages';
    const result = applyVariables(tpl, { name: 'Alice', count: 3 });
    expect(result).toBe('Hello Alice, you have 3 messages');
  });

  it('replaces undefined variables with empty string', () => {
    const tpl = 'Hi {{name}} from {{company}}';
    const result = applyVariables(tpl, { name: 'Bob' });
    expect(result).toBe('Hi Bob from ');
  });

  it('handles whitespace in variable braces', () => {
    const tpl = '{{ name }}';
    expect(applyVariables(tpl, { name: 'Alice' })).toBe('Alice');
  });

  it('replaces null with empty string', () => {
    const result = applyVariables('{{x}}', { x: null });
    expect(result).toBe('');
  });
});
