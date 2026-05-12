# ============================================================
# URM Platform — 환경변수
# (이 파일은 .gitignore에 포함됨. Git에 커밋 금지)
# ============================================================

# ── Anthropic ────────────────────────────────────────────────
# https://console.anthropic.com → API Keys 에서 발급
# 없으면 일단 더미값 (앱은 실행되지만 AI 호출 시 실패)
ANTHROPIC_API_KEY=sk-ant-DUMMY-PLACEHOLDER-XXXXXXXXXXXXXXXXXXXX

# 모델명은 절대 변경 금지 (env.ts에서 정확히 이 값만 허용)
ANTHROPIC_MODEL_OPUS=claude-opus-4-7
ANTHROPIC_MODEL_HAIKU=claude-haiku-4-5-20251001
ANTHROPIC_MODEL_SONNET=claude-sonnet-4-6

# ── OpenAI (임베딩 전용) ─────────────────────────────────────
# 없으면 더미값 — 임베딩 기능만 비활성
OPENAI_API_KEY=sk-DUMMY-PLACEHOLDER-XXXXXXXXXXXXXXXXXXXX
OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# ── Supabase ─────────────────────────────────────────────────
# Project Settings → API → Project URL
NEXT_PUBLIC_SUPABASE_URL=https://ogenmrgxwhpbfepeldqx.supabase.co

# Legacy anon, service_role API keys 탭의 값들
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9nZW5tcmd4d2hwYmZlcGVsZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MTYzNjQsImV4cCI6MjA5Mzk5MjM2NH0.CGRjD8m3fO_qiiE3F2-SCj7jRfR_lYcwWCOsEgN4p30
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9nZW5tcmd4d2hwYmZlcGVsZHF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODQxNjM2NCwiZXhwIjoyMDkzOTkyMzY0fQ.b0VfwHbKETzgQBOXSjl20Sm3U36woAqS9jX5PUCHixc

# DB URL — Supabase Dashboard → Project Settings → Database → Connection string → URI
# 예: postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres
SUPABASE_DB_URL=postgresql://postgres.ogenmrgxwhpbfepeldqx:!wsxedc12Q@aws-1-us-east-1.pooler.supabase.com:6543/postgres

SUPABASE_STORAGE_BUCKET_ATTACHMENTS=communications-attachments

# ── TABS Mailer 4 (이메일 발송 SMTP) ─────────────────────────
# 실제 SMTP가 없으면 mock 모드 사용 (USE_MOCK=true)
TABS_MAILER_HOST=localhost
TABS_MAILER_PORT=587
TABS_MAILER_AUTH_METHOD=plain
TABS_MAILER_USERNAME=dummy
TABS_MAILER_PASSWORD=dummy
TABS_MAILER_USE_TLS=false
TABS_MAILER_FROM_DOMAIN=mbg-project.local
TABS_MAILER_USE_MOCK=true

# ── MailCarrier 7 (이메일 수신 IMAP) ─────────────────────────
# 실제 IMAP이 없으면 더미값 (수신 워커 비활성)
MAILCARRIER_HOST=imap.gmail.com
MAILCARRIER_PORT=993
MAILCARRIER_USERNAME=dummy@example.com
MAILCARRIER_PASSWORD=dummy-password
MAILCARRIER_USE_IDLE=true
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30

# ── 비즈니스 정책 ────────────────────────────────────────────
AI_AUTO_SEND_ENABLED=false
SCRAPING_ENABLED=false
MAX_DAILY_AI_COST_USD=50
MAX_MONTHLY_AI_COST_USD=1500
DRAFT_EXPIRY_DAYS=7
LOG_LEVEL=info
WORKER_RUNTIME=node

# ── STEP 4 프론트엔드 ────────────────────────────────────────
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_DEFAULT_LOCALE=ko

# ── Node ─────────────────────────────────────────────────────
NODE_ENV=development
