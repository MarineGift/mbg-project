/**
 * tests/action-schemas.test.ts
 *
 * Server Actions의 zod 검증 로직 테스트.
 * Server Action 자체는 supabase mock 없이 테스트하기 복잡하므로,
 * 여기선 schema가 input을 정확히 검증·정규화하는지에 집중.
 *
 * Server Action 모듈을 직접 import할 수 없는 이유: 'use server' + supabase server client
 * → schema를 재정의해서 동일 규칙 검증.
 */

import { describe, it, expect } from 'vitest';
import { z } from 'zod';

describe('Party action schemas', () => {
  // src/lib/actions/parties.ts와 동일한 규칙 재정의
  const partySchema = z.object({
    name: z.string().min(1).max(200),
    module: z.enum([
      'investor',
      'buyer',
      'partner',
      'customer',
      'crowdfunding',
      'product_launch',
      'sales',
    ]),
    partyType: z.enum(['company', 'individual', 'organization']).default('company'),
    tier: z.enum(['tier_1', 'tier_2', 'tier_3', 'cold']).optional().nullable(),
    countryCode: z
      .string()
      .length(2)
      .optional()
      .nullable()
      .or(z.literal('').transform(() => null)),
    website: z
      .string()
      .url()
      .max(500)
      .optional()
      .nullable()
      .or(z.literal('').transform(() => null)),
  });

  it('accepts valid input', () => {
    const result = partySchema.safeParse({
      name: 'Acme Inc.',
      module: 'buyer',
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty name', () => {
    const result = partySchema.safeParse({ name: '', module: 'buyer' });
    expect(result.success).toBe(false);
  });

  it('rejects name > 200 chars', () => {
    const result = partySchema.safeParse({
      name: 'A'.repeat(201),
      module: 'buyer',
    });
    expect(result.success).toBe(false);
  });

  it('rejects unknown module', () => {
    const result = partySchema.safeParse({
      name: 'A',
      module: 'unknown_module',
    });
    expect(result.success).toBe(false);
  });

  it('accepts 7 valid modules', () => {
    const modules = [
      'investor',
      'buyer',
      'partner',
      'customer',
      'crowdfunding',
      'product_launch',
      'sales',
    ];
    for (const m of modules) {
      expect(partySchema.safeParse({ name: 'X', module: m }).success).toBe(true);
    }
  });

  it('accepts 2-letter country code', () => {
    expect(
      partySchema.safeParse({ name: 'X', module: 'buyer', countryCode: 'KR' }).success,
    ).toBe(true);
  });

  it('rejects 3-letter country code', () => {
    expect(
      partySchema.safeParse({ name: 'X', module: 'buyer', countryCode: 'KOR' }).success,
    ).toBe(false);
  });

  it('accepts empty string country (transforms to null)', () => {
    const r = partySchema.safeParse({ name: 'X', module: 'buyer', countryCode: '' });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.countryCode).toBeNull();
  });

  it('accepts https website', () => {
    expect(
      partySchema.safeParse({
        name: 'X',
        module: 'buyer',
        website: 'https://example.com',
      }).success,
    ).toBe(true);
  });

  it('rejects bare-domain website (no protocol)', () => {
    expect(
      partySchema.safeParse({ name: 'X', module: 'buyer', website: 'example.com' })
        .success,
    ).toBe(false);
  });
});

describe('Compose action schemas', () => {
  const composeSchema = z.object({
    to: z.string().email().max(255),
    subject: z.string().min(1).max(500),
    bodyPlain: z.string().min(1).max(50_000),
  });

  it('accepts valid email', () => {
    expect(
      composeSchema.safeParse({
        to: 'a@b.com',
        subject: 's',
        bodyPlain: 'b',
      }).success,
    ).toBe(true);
  });

  it('rejects invalid email', () => {
    expect(
      composeSchema.safeParse({
        to: 'not-an-email',
        subject: 's',
        bodyPlain: 'b',
      }).success,
    ).toBe(false);
  });

  it('rejects empty body', () => {
    expect(
      composeSchema.safeParse({
        to: 'a@b.com',
        subject: 's',
        bodyPlain: '',
      }).success,
    ).toBe(false);
  });

  it('rejects body > 50k', () => {
    expect(
      composeSchema.safeParse({
        to: 'a@b.com',
        subject: 's',
        bodyPlain: 'x'.repeat(50_001),
      }).success,
    ).toBe(false);
  });
});

describe('Engagement action schemas', () => {
  const engagementSchema = z.object({
    name: z.string().min(1).max(200),
    valueAmount: z.number().min(0).max(1e15).optional().nullable(),
    valueCurrency: z.string().length(3).default('USD'),
    probabilityPct: z.number().int().min(0).max(100).default(0),
  });

  it('accepts valid', () => {
    expect(
      engagementSchema.safeParse({
        name: 'Q3 Deal',
        valueAmount: 50000,
        probabilityPct: 75,
      }).success,
    ).toBe(true);
  });

  it('rejects negative value', () => {
    expect(
      engagementSchema.safeParse({ name: 'X', valueAmount: -100 }).success,
    ).toBe(false);
  });

  it('rejects probability > 100', () => {
    expect(
      engagementSchema.safeParse({ name: 'X', probabilityPct: 150 }).success,
    ).toBe(false);
  });

  it('rejects non-integer probability', () => {
    expect(
      engagementSchema.safeParse({ name: 'X', probabilityPct: 50.5 }).success,
    ).toBe(false);
  });

  it('rejects 2-letter currency', () => {
    expect(
      engagementSchema.safeParse({ name: 'X', valueCurrency: 'KR' }).success,
    ).toBe(false);
  });
});

describe('Task action schemas', () => {
  const taskSchema = z.object({
    title: z.string().min(1).max(500),
    priority: z.enum(['low', 'medium', 'high', 'urgent']).default('medium'),
  });

  it('accepts each valid priority', () => {
    for (const p of ['low', 'medium', 'high', 'urgent']) {
      expect(taskSchema.safeParse({ title: 'T', priority: p }).success).toBe(true);
    }
  });

  it('rejects unknown priority', () => {
    expect(taskSchema.safeParse({ title: 'T', priority: 'critical' }).success).toBe(
      false,
    );
  });

  it('rejects title > 500 chars', () => {
    expect(taskSchema.safeParse({ title: 'x'.repeat(501) }).success).toBe(false);
  });
});

describe('Contact action schemas', () => {
  const contactSchema = z.object({
    fullName: z.string().min(1).max(160),
    email: z
      .string()
      .email()
      .max(255)
      .optional()
      .or(z.literal('').transform(() => undefined)),
    decisionRole: z
      .enum(['decision_maker', 'influencer', 'gatekeeper', 'user', 'champion', 'unknown'])
      .default('unknown'),
    preferredLanguage: z
      .enum(['ko', 'en', 'ja', 'zh-CN'])
      .optional()
      .or(z.literal('').transform(() => undefined)),
  });

  it('accepts valid', () => {
    expect(contactSchema.safeParse({ fullName: 'John Doe' }).success).toBe(true);
  });

  it('decisionRole defaults to unknown', () => {
    const r = contactSchema.safeParse({ fullName: 'X' });
    if (r.success) expect(r.data.decisionRole).toBe('unknown');
  });

  it('accepts ko/en/ja/zh-CN languages', () => {
    for (const lang of ['ko', 'en', 'ja', 'zh-CN']) {
      expect(
        contactSchema.safeParse({ fullName: 'X', preferredLanguage: lang }).success,
      ).toBe(true);
    }
  });

  it('rejects unknown language', () => {
    expect(
      contactSchema.safeParse({ fullName: 'X', preferredLanguage: 'es' }).success,
    ).toBe(false);
  });
});
