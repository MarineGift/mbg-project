import { z } from 'zod';

/**
 * 모든 환경 변수의 단일 검증 진입점. 마스터 §11과 STEP 3 가이드 §3.1 기준.
 */
const envSchema = z
  .object({
    // ─── Anthropic ──────────────────────────────────────────────
    ANTHROPIC_API_KEY: z.string().min(20, 'ANTHROPIC_API_KEY too short'),
    ANTHROPIC_MODEL_OPUS: z.literal('claude-opus-4-7').default('claude-opus-4-7'),
    ANTHROPIC_MODEL_HAIKU: z
      .literal('claude-haiku-4-5-20251001')
      .default('claude-haiku-4-5-20251001'),
    ANTHROPIC_MODEL_SONNET: z.literal('claude-sonnet-4-6').default('claude-sonnet-4-6'),

    // ─── Supabase ───────────────────────────────────────────────
    NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
    NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(20),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
    SUPABASE_DB_URL: z.string().url(),
    SUPABASE_STORAGE_BUCKET_ATTACHMENTS: z.string().default('communications-attachments'),

    // ─── OpenAI ─────────────────────────────────────────────────
    OPENAI_API_KEY: z.string().min(20),
    OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-large'),

    // ─── TABS Mailer 4 ──────────────────────────────────────────
    TABS_MAILER_HOST: z.string().min(1),
    TABS_MAILER_PORT: z.coerce.number().int().min(1).max(65535).default(587),
    TABS_MAILER_AUTH_METHOD: z.enum(['plain', 'login', 'ip_whitelist']),
    TABS_MAILER_USERNAME: z.string().optional(),
    TABS_MAILER_PASSWORD: z.string().optional(),
    TABS_MAILER_USE_TLS: z.coerce.boolean().default(true),
    TABS_MAILER_FROM_DOMAIN: z.string().min(1),
    TABS_MAILER_FROM_DEFAULT: z.string().email().optional(),
    TABS_MAILER_DB_CONN: z.string().optional(),

    // ─── MailCarrier 7 ──────────────────────────────────────────
    MAILCARRIER_HOST: z.string().min(1),
    MAILCARRIER_PORT: z.coerce.number().int().min(1).max(65535).default(993),
    MAILCARRIER_USERNAME: z.string().min(1),
    MAILCARRIER_PASSWORD: z.string().min(1),
    MAILCARRIER_USE_IDLE: z.coerce.boolean().default(true),
    MAILCARRIER_INBOX_FOLDER: z.string().default('INBOX'),
    MAILCARRIER_POLL_INTERVAL_SECONDS: z.coerce.number().int().min(5).default(30),

    // ─── 트래킹 ─────────────────────────────────────────────────
    MAIL_DOMAIN: z.string().optional(),
    TRACKING_BASE_URL: z.string().url().optional(),

    // ─── 운영 정책 ──────────────────────────────────────────────
    AI_AUTO_SEND_ENABLED: z.coerce.boolean().default(false),
    SCRAPING_ENABLED: z.coerce.boolean().default(true),
    MAX_DAILY_AI_COST_USD: z.coerce.number().nonnegative().default(50),
    MAX_MONTHLY_AI_COST_USD: z.coerce.number().nonnegative().default(1500),
    DRAFT_EXPIRY_DAYS: z.coerce.number().int().min(1).max(60).default(7),
    CLAUDE_HARD_TIMEOUT_MS: z.coerce.number().int().min(5_000).default(60_000),
    CLAUDE_MAX_RETRIES: z.coerce.number().int().min(0).max(5).default(3),

    // ─── 인프라 ─────────────────────────────────────────────────
    REDIS_URL: z.string().optional(),
    NODE_ENV: z.enum(['development', 'test', 'preview', 'staging', 'production']).default('development'),
    LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
    SENTRY_DSN: z.string().optional(),
    SLACK_WEBHOOK_URL: z.string().optional(),

    // ─── Next.js HTTP 진입점 인증 ───────────────────────────────
    /** 인바운드 메일 웹훅(POST /api/webhooks/inbound)의 X-URM-Webhook-Secret 헤더 검증값. */
    INBOUND_WEBHOOK_SECRET: z.string().min(16).optional(),
    /** Vercel Cron의 Authorization: Bearer <secret> 검증값. */
    CRON_SECRET: z.string().min(16).optional(),
  })
  .superRefine((data, ctx) => {
    if (data.TABS_MAILER_AUTH_METHOD !== 'ip_whitelist') {
      if (!data.TABS_MAILER_USERNAME) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['TABS_MAILER_USERNAME'],
          message:
            'TABS_MAILER_USERNAME required when TABS_MAILER_AUTH_METHOD is plain or login',
        });
      }
      if (!data.TABS_MAILER_PASSWORD) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['TABS_MAILER_PASSWORD'],
          message:
            'TABS_MAILER_PASSWORD required when TABS_MAILER_AUTH_METHOD is plain or login',
        });
      }
    }
  });

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('❌ Environment validation failed:');
  // eslint-disable-next-line no-console
  console.error(JSON.stringify(parsed.error.format(), null, 2));
  throw new Error('Invalid environment configuration');
}

export const env = parsed.data;
export type Env = typeof env;

export const __envSchemaForTest = envSchema;
