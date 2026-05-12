/**
 * lib/env.ts
 *
 * 환경변수 단일 진입점. zod 스키마로 런타임 검증 후 동결된 객체를 export.
 *
 * 모든 인프라 코드는 `import { env } from '@/lib/env'` 만 사용한다.
 * `process.env.X` 직접 접근은 금지(검증 우회 + 타입 손실).
 */

import { z } from 'zod';

/* ============================================================
 * 1. 스키마 정의
 * ----------------------------------------------------------
 * 마스터 시스템 프롬프트 §11과 가이드 §3.1의 변수 카탈로그 기준.
 * ============================================================ */
const envSchema = z
  .object({
    // ── Anthropic ────────────────────────────────────────
    ANTHROPIC_API_KEY: z.string().min(20),
    ANTHROPIC_MODEL_OPUS: z.literal('claude-opus-4-7'),
    ANTHROPIC_MODEL_HAIKU: z.literal('claude-haiku-4-5-20251001'),
    ANTHROPIC_MODEL_SONNET: z.literal('claude-sonnet-4-6'),

    // ── OpenAI (임베딩 전용) ─────────────────────────────
    OPENAI_API_KEY: z.string().min(20),
    OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-large'),

    // ── Supabase ─────────────────────────────────────────
    NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
    NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(20),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
    SUPABASE_DB_URL: z.string().url(),
    SUPABASE_STORAGE_BUCKET_ATTACHMENTS: z
      .string()
      .default('communications-attachments'),

    // ── TABS Mailer 4 (발송) ─────────────────────────────
    TABS_MAILER_HOST: z.string().min(1),
    TABS_MAILER_PORT: z.coerce.number().int().min(1).max(65535).default(587),
    TABS_MAILER_AUTH_METHOD: z.enum(['plain', 'login', 'ip_whitelist']),
    TABS_MAILER_USERNAME: z.string().optional(),
    TABS_MAILER_PASSWORD: z.string().optional(),
    TABS_MAILER_USE_TLS: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .default(true),
    TABS_MAILER_FROM_DOMAIN: z.string().min(1),
    TABS_MAILER_USE_MOCK: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .default(false),

    // ── MailCarrier 7 (수신) ─────────────────────────────
    MAILCARRIER_HOST: z.string().min(1),
    MAILCARRIER_PORT: z.coerce.number().int().min(1).max(65535).default(993),
    MAILCARRIER_USERNAME: z.string().min(1),
    MAILCARRIER_PASSWORD: z.string().min(1),
    MAILCARRIER_USE_IDLE: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .default(true),
    MAILCARRIER_INBOX_FOLDER: z.string().default('INBOX'),
    MAILCARRIER_POLL_INTERVAL_SECONDS: z.coerce
      .number()
      .int()
      .min(5)
      .default(30),

    // ── 비즈니스 ─────────────────────────────────────────
    AI_AUTO_SEND_ENABLED: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .default(false),
    SCRAPING_ENABLED: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .default(true),
    MAX_DAILY_AI_COST_USD: z.coerce.number().nonnegative().default(50),
    MAX_MONTHLY_AI_COST_USD: z.coerce.number().nonnegative().default(1500),
    DRAFT_EXPIRY_DAYS: z.coerce.number().int().min(1).max(30).default(7),
    LOG_LEVEL: z
      .enum(['debug', 'info', 'warn', 'error'])
      .default('info'),
    WORKER_RUNTIME: z.enum(['node', 'edge', 'cron']).default('node'),

    // ── 트래킹·운영 (선택) ───────────────────────────────
    MAIL_DOMAIN: z.string().min(1).optional(),
    TRACKING_BASE_URL: z.string().url().optional(),
    SLACK_WEBHOOK_URL: z.string().url().optional(),
    SENTRY_DSN: z.string().url().optional(),
    REDIS_URL: z.string().url().optional(),

    // ── STEP 4 프론트엔드 ────────────────────────────────
    NEXT_PUBLIC_APP_URL: z
      .string()
      .url()
      .default('http://localhost:3000'),
    NEXT_PUBLIC_DEFAULT_LOCALE: z
      .enum(['ko', 'en', 'ja'])
      .default('ko'),

    // ── Node 표준 ────────────────────────────────────────
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development'),
  })
  .superRefine((data, ctx) => {
    // 조건부 필수: ip_whitelist가 아니면 username/password 필요
    if (data.TABS_MAILER_AUTH_METHOD !== 'ip_whitelist') {
      if (!data.TABS_MAILER_USERNAME) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['TABS_MAILER_USERNAME'],
          message: 'Required when TABS_MAILER_AUTH_METHOD is plain or login',
        });
      }
      if (!data.TABS_MAILER_PASSWORD) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['TABS_MAILER_PASSWORD'],
          message: 'Required when TABS_MAILER_AUTH_METHOD is plain or login',
        });
      }
    }
    // 일일 한도가 월 한도보다 크면 안 됨
    if (data.MAX_DAILY_AI_COST_USD > data.MAX_MONTHLY_AI_COST_USD) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['MAX_DAILY_AI_COST_USD'],
        message: 'Daily limit cannot exceed monthly limit',
      });
    }
  });

/* ============================================================
 * 2. 검증 실행
 * ----------------------------------------------------------
 * 검증 실패 시 즉시 throw — 부팅 단계에서 문제를 노출시킨다.
 * 테스트 환경에서는 NODE_ENV='test'일 때 부분 누락을 허용하기 위해
 * .env.test 또는 vitest 글로벌 setup 사용을 권장.
 * ============================================================ */
const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // 운영 환경에서 서버 시작 시 즉시 실패하도록 stderr에 상세 출력
  // 시크릿 값은 절대 출력하지 않고 path와 message만 노출
  const formatted = parsed.error.issues.map((i) => ({
    path: i.path.join('.'),
    code: i.code,
    message: i.message,
  }));
  // eslint-disable-next-line no-console
  console.error(
    '[env] Environment validation failed:\n' +
      JSON.stringify(formatted, null, 2),
  );
  throw new Error(
    `Invalid environment configuration (${formatted.length} issue(s))`,
  );
}

/* ============================================================
 * 3. 동결된 환경 객체 export
 * ============================================================ */
export const env = Object.freeze(parsed.data);
export type Env = typeof env;

/**
 * 현재 환경이 production인지 빠르게 확인.
 */
export const isProduction = (): boolean => env.NODE_ENV === 'production';

/**
 * Mock TABS Mailer 사용 여부.
 * env.TABS_MAILER_USE_MOCK 또는 host==='mock' 시 true.
 */
export const isUsingMockMailer = (): boolean =>
  env.TABS_MAILER_USE_MOCK || env.TABS_MAILER_HOST === 'mock';
