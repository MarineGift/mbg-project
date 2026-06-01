/**
 * __tests__/setup/env-setup.ts
 *
 * Entry point registered in vitest setupFiles.
 * Since env.ts runs zod validation at module load time,
 * all env variables are injected here in advance.
 */

// Anthropic
process.env.ANTHROPIC_API_KEY ??= 'sk-ant-test-1234567890abcdefghij';
process.env.ANTHROPIC_MODEL_OPUS ??= 'claude-opus-4-7';
process.env.ANTHROPIC_MODEL_HAIKU ??= 'claude-haiku-4-5-20251001';
process.env.ANTHROPIC_MODEL_SONNET ??= 'claude-sonnet-4-6';

// OpenAI
process.env.OPENAI_API_KEY ??= 'sk-test-1234567890abcdefghij';
process.env.OPENAI_EMBEDDING_MODEL ??= 'text-embedding-3-large';

// Supabase
process.env.NEXT_PUBLIC_SUPABASE_URL ??= 'https://test.supabase.co';
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??= 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.role.signature';
process.env.SUPABASE_DB_URL ??= 'postgres://test:test@localhost:5432/test';
process.env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS ??= 'communications-attachments';

// TABS Mailer
process.env.TABS_MAILER_HOST ??= 'mock';
process.env.TABS_MAILER_PORT ??= '587';
process.env.TABS_MAILER_AUTH_METHOD ??= 'login';
process.env.TABS_MAILER_USERNAME ??= 'test-user';
process.env.TABS_MAILER_PASSWORD ??= 'test-pass';
process.env.TABS_MAILER_FROM_DOMAIN ??= 'test.example.com';
process.env.TABS_MAILER_USE_TLS ??= 'true';
process.env.TABS_MAILER_USE_MOCK ??= 'true';

// MailCarrier
process.env.MAILCARRIER_HOST ??= 'imap.test.example.com';
process.env.MAILCARRIER_PORT ??= '993';
process.env.MAILCARRIER_USERNAME ??= 'inbox@test.example.com';
process.env.MAILCARRIER_PASSWORD ??= 'imap-test-pass';
process.env.MAILCARRIER_USE_IDLE ??= 'false';
process.env.MAILCARRIER_INBOX_FOLDER ??= 'INBOX';
process.env.MAILCARRIER_POLL_INTERVAL_SECONDS ??= '30';

// Business
process.env.AI_AUTO_SEND_ENABLED ??= 'false';
process.env.SCRAPING_ENABLED ??= 'true';
process.env.MAX_DAILY_AI_COST_USD ??= '10';
process.env.MAX_MONTHLY_AI_COST_USD ??= '100';
process.env.DRAFT_EXPIRY_DAYS ??= '7';
process.env.LOG_LEVEL ??= 'error';
process.env.WORKER_RUNTIME ??= 'node';
// NODE_ENV is declared as a readonly literal union in @types/node - cast to work around it
(process.env as Record<string, string | undefined>).NODE_ENV ??= 'test';

// STEP 4 frontend
process.env.NEXT_PUBLIC_APP_URL ??= 'http://localhost:3000';
process.env.NEXT_PUBLIC_DEFAULT_LOCALE ??= 'ko';
