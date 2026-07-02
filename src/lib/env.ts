/**
 * lib/env.ts
 *
 * Single entry point for environment variables. Validates at runtime with a zod schema, then exports a frozen object.
 *
 * All infrastructure code uses only `import { env } from '@/lib/env'`.
 * Direct `process.env.X` access is forbidden (bypasses validation + loses types).
 */

import { z } from 'zod';

/* ============================================================
 * 1. Schema definitions
 * ----------------------------------------------------------
 * Based on the variable catalog in master system prompt §11 and guide §3.1.
 * ============================================================ */
const envSchema = z
  .object({
    // ── Anthropic ────────────────────────────────────────
    ANTHROPIC_API_KEY: z.string().min(20),
    ANTHROPIC_MODEL_OPUS: z.literal('claude-opus-4-7'),
    ANTHROPIC_MODEL_HAIKU: z.literal('claude-haiku-4-5-20251001'),
    ANTHROPIC_MODEL_SONNET: z.literal('claude-sonnet-4-6'),

    // ── OpenAI (embeddings only) ──
    OPENAI_API_KEY: z.string().min(20),
    OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-large'),

    // ── Supabase ─────────────────────────────────────────
    NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
    NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(20),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),

    // -- Slack (URM <-> Slack integration) --
    SLACK_SIGNING_SECRET: z.string().min(1).optional(),
    SUPABASE_DB_URL: z.string().url(),
    SUPABASE_STORAGE_BUCKET_ATTACHMENTS: z
      .string()
      .default('communications-attachments'),

    // ── TABS Mailer 4 (sending) ──
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
    TABS_MAILER_TLS_REJECT_UNAUTHORIZED: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .optional(),

    MAIL_PERSONAL_USERNAME: z.string().email().optional(),
    MAIL_PERSONAL_PASSWORD: z.string().min(1).optional(),
    MAIL_ROLE_USERNAME: z.string().email().optional(),
    MAIL_ROLE_PASSWORD: z.string().min(1).optional(),
    MAIL_SHARED_USERNAME: z.string().email().optional(),
    MAIL_SHARED_PASSWORD: z.string().min(1).optional(),
    MAIL_PERSONAL_DISPLAY_NAME: z.string().default('YunYoung Heo'),
    MAIL_ROLE_DISPLAY_NAME: z.string().default('CEO'),
    MAIL_SHARED_DISPLAY_NAME: z.string().default('Marinebio Group'),

    // ── MailCarrier 7 (receiving) ──
    // NOTE: these are WORKER-ONLY (the web app never opens IMAP).
    // They are optional here so the web build/runtime does not require them.
    // The worker enforces them at startup via requireMailcarrierEnv() below.
    MAILCARRIER_HOST: z.string().min(1).optional(),
    MAILCARRIER_PORT: z.coerce.number().int().min(1).max(65535).default(993),
    MAILCARRIER_USERNAME: z.string().min(1).optional(),
    MAILCARRIER_PASSWORD: z.string().min(1).optional(),
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
    MAILCARRIER_TLS_REJECT_UNAUTHORIZED: z
      .union([z.boolean(), z.enum(['true', 'false'])])
      .transform((v) => (typeof v === 'boolean' ? v : v === 'true'))
      .optional(),

    // ── MailCarrier polling target kinds (Phase 2) ──
    // Decides which sending-account inboxes to poll.
    // If empty or unset, uses the single MAILCARRIER_USERNAME (Phase 1 backward compat).
    // e.g. MAILCARRIER_POLL_KINDS=personal,role,shared
    MAILCARRIER_POLL_KINDS: z
      .string()
      .default('')
      .transform((v) =>
        v
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .filter((s): s is 'personal' | 'role' | 'shared' =>
            s === 'personal' || s === 'role' || s === 'shared',
          ),
      ),  

    // ── Business ──
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

    // ── Tracking / operations (optional) ──
    MAIL_DOMAIN: z.string().min(1).optional(),
    TRACKING_BASE_URL: z.string().url().optional(),
    SLACK_WEBHOOK_URL: z.string().url().optional(),
    SENTRY_DSN: z.string().url().optional(),
    REDIS_URL: z.string().url().optional(),

    // ── STEP 4 frontend ──
    NEXT_PUBLIC_APP_URL: z
      .string()
      .url()
      .default('http://localhost:3000'),
    NEXT_PUBLIC_DEFAULT_LOCALE: z
      .enum(['ko', 'en', 'ja'])
      .default('ko'),

    // ── Node standard ──
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development'),
  })
  .superRefine((data, ctx) => {
    // conditionally required: username/password needed unless ip_whitelist
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
    // the daily limit must not exceed the monthly limit
    if (data.MAX_DAILY_AI_COST_USD > data.MAX_MONTHLY_AI_COST_USD) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['MAX_DAILY_AI_COST_USD'],
        message: 'Daily limit cannot exceed monthly limit',
      });
    }
  });

/* ============================================================
 * 2. Run validation
 * ----------------------------------------------------------
 * Throw immediately on validation failure - surface problems at boot time.
 * In the test environment, to allow partial omissions when NODE_ENV='test',
 * use .env.test or a vitest global setup.
 * ============================================================ */
const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // print details to stderr so the server fails fast on startup in production
  // never print secret values - only the path and message
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
 * 3. Export the frozen env object
 * ============================================================ */
export const env = Object.freeze(parsed.data);
export type Env = typeof env;

/**
 * Quickly check whether the current environment is production.
 */
export const isProduction = (): boolean => env.NODE_ENV === 'production';

/**
 * Whether the mock TABS Mailer is used.
 * true when env.TABS_MAILER_USE_MOCK or host==='mock'.
 */
export const isUsingMockMailer = (): boolean =>
  env.TABS_MAILER_USE_MOCK || env.TABS_MAILER_HOST === 'mock';

/**
 * Worker-only guard for the MailCarrier (IMAP receiving) worker.
 *
 * MAILCARRIER_HOST / USERNAME / PASSWORD are optional in the base schema so the
 * web app does not need them. The worker, however, cannot run without them, so
 * call this at the top of the worker entrypoint (mailcarrier-worker.ts) to fail
 * fast with a clear message instead of an opaque IMAP connection error.
 *
 * Returns the three values narrowed to non-optional `string`.
 */
export function requireMailcarrierEnv(): {
  host: string;
  username: string;
  password: string;
} {
  const missing: string[] = [];
  if (!env.MAILCARRIER_HOST) missing.push('MAILCARRIER_HOST');
  if (!env.MAILCARRIER_USERNAME) missing.push('MAILCARRIER_USERNAME');
  if (!env.MAILCARRIER_PASSWORD) missing.push('MAILCARRIER_PASSWORD');

  if (missing.length > 0) {
    throw new Error(
      `[env] MailCarrier worker requires the following variable(s): ${missing.join(', ')}`,
    );
  }

  return {
    host: env.MAILCARRIER_HOST as string,
    username: env.MAILCARRIER_USERNAME as string,
    password: env.MAILCARRIER_PASSWORD as string,
  };
}
