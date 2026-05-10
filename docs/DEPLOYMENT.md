# URM Platform — Vercel + Supabase 배포 가이드

> 본 문서는 STEP 1(DB 스키마) + STEP 2(시드) + STEP 3(TS 인프라) + STEP 4(Next.js 앱) 산출물을
> 실제 운영 환경에 처음부터 끝까지 배포하는 단계별 절차입니다.
>
> 작성일: 2026-05-10. 본 가이드의 명령은 macOS/Linux 기준입니다.

---

## 목차

- [0. 개요 — 무엇을 배포하는가](#0-개요--무엇을-배포하는가)
- [1. 사전 결정 항목](#1-사전-결정-항목)
- [2. 외부 계정 + 도메인 준비](#2-외부-계정--도메인-준비)
- [3. Supabase 설치](#3-supabase-설치)
- [4. 외부 API 키 발급](#4-외부-api-키-발급)
- [5. 메일 인프라 선택과 설치](#5-메일-인프라-선택과-설치)
- [6. Vercel 배포](#6-vercel-배포)
- [7. 첫 사용자와 조직 시드](#7-첫-사용자와-조직-시드)
- [8. 장기 가동 워커 (선택)](#8-장기-가동-워커-선택)
- [9. 스모크 테스트](#9-스모크-테스트)
- [10. 운영 — 비용, 감사, 알림](#10-운영--비용-감사-알림)
- [11. 트러블슈팅](#11-트러블슈팅)
- [부록 A. 환경변수 전체 표](#부록-a-환경변수-전체-표)
- [부록 B. SQL 검증 쿼리 모음](#부록-b-sql-검증-쿼리-모음)

---

## 0. 개요 — 무엇을 배포하는가

### 컴포넌트 지도

```
┌─────────────────────────────────────────────────────────────────────┐
│                       URM Platform Deployment                        │
└─────────────────────────────────────────────────────────────────────┘

   ┌───────────────────┐         ┌──────────────────────────┐
   │   사용자 브라우저  │ ───────►│   Vercel (Next.js 14)    │
   └───────────────────┘         │  - /login, /drafts, ...   │
                                 │  - /api/* 라우트 7개       │
                                 │  - Cron 3개 (vercel.json) │
                                 └────────┬─────────────────┘
                                          │
                                          ▼
   ┌──────────────────────────────────────────────────────────┐
   │                    Supabase                              │
   │  - Postgres (app, ai, audit 스키마, pgvector)            │
   │  - Auth (이메일/비번)                                     │
   │  - Storage (communications-attachments 버킷)              │
   │  - Realtime (옵션, 본 골격에서는 미사용)                   │
   └────────────────────────────────────────────────────────────┘
                                          ▲
                                          │
   ┌──────────────────────────────────────┴───────────────────┐
   │     Long-running workers (Vercel 외부 — 선택적)           │
   │  - consultation-worker (pg LISTEN)                       │
   │  - MailCarrier IMAP IDLE (자체 운영 시)                   │
   │  → Railway / Fly.io / AWS ECS                            │
   └────────────────────────────────────────────────────────────┘
                                          ▲
                                          │
   ┌──────────────────────────────────────┴───────────────────┐
   │        외부 메일 인프라 (옵션 A/B/C 중 선택)              │
   │  - Anthropic API (Claude 호출)                            │
   │  - OpenAI API (임베딩)                                    │
   │  - Postmark/Mailgun 또는 자체 TABS/MailCarrier            │
   └────────────────────────────────────────────────────────────┘
```

### 무엇을 직접 가져와야 하나

| 항목 | 출처 | 본 가이드 안에서 다루는가 |
|------|------|-------------------------|
| STEP 1 SQL 마이그레이션 (7,385줄) | 사용자 보관 | 적용 절차만 |
| STEP 2 시드 데이터 (agents, brand_voice 등) | 사용자 보관 | 적용 절차만 |
| STEP 3+4 코드 zip | `urm-step3-full.zip` | ✅ 전체 |
| 도메인 (DKIM/SPF 설정용) | 사용자 구매 | 권장 설정 |
| Anthropic / OpenAI 계정 | 사용자 발급 | 키 위치만 안내 |
| 메일 인프라 (TABS/MailCarrier 또는 대체) | 사용자 결정 | 옵션 3개 비교 |

---

## 1. 사전 결정 항목

배포 시작 전에 반드시 결정해야 하는 4개 항목입니다.

### 1.1 메일 인프라 (세 옵션 중 택 1)

| 옵션 | 상황 | 작업량 | 권장 |
|------|------|------|------|
| **A. Mock 모드** | 개발/staging — 메일 발송 없이 UI/DB만 검증 | 0 (env에 `TABS_MAILER_HOST=mock`) | 첫 배포 |
| **B. Postmark/Mailgun + 인바운드 웹훅** | 베타 운영 — 소량~중량 발송, SaaS 운영 | 中 — 계정 가입 + DKIM/SPF + 웹훅 라우팅 | **추천** |
| **C. 자체 TABS Mailer 4 + MailCarrier 7** | 본격 운영 — 대량 발송, 엄격한 IP 제어, MS SQL stats DB 연동 | 大 — 별도 호스트 + DB 구축 + 인증 정책 | 후기 전환 |

대다수 신규 사용자는 **A로 시작 → B로 전환 → 필요 시 C 도입**.

### 1.2 워커 호스팅

STEP 3의 3개 worker 중 어떻게 운영할지 결정:

| 워커 | Vercel Cron 가능? | 권장 |
|------|------------------|------|
| `draft-expiry-worker` | ✅ (1일 1회 RPC 호출) | Vercel Cron (이미 `vercel.json`에 설정됨) |
| `mail-merge-worker` | ⚠️ 2분 폴링으로 변환 가능 | Vercel Cron (충분) 또는 Railway |
| `consultation-worker` | ❌ pg LISTEN 영구 연결 | **Railway / Fly.io 필수** |
| `MailCarrierClient` (IMAP IDLE) | ❌ 영구 연결 | 옵션 C 선택 시 별도 호스트 필요 |

**결정**: 옵션 A/B로 시작하고 consultation-worker만 Railway에서 돌릴지, 아니면 consultations 기능 자체를 첫 단계에서 비활성화할지.

### 1.3 도메인

발송 도메인 (`mail.yourdomain.com` 같은 하위 도메인 권장)을 미리 결정. 다음을 추가해야 함:
- **MX** 레코드 (옵션 B/C 선택 시)
- **SPF** TXT 레코드 — 발송 IP 허용
- **DKIM** TXT 레코드 — 메일 서명
- **DMARC** TXT 레코드 — 정책 명시

DNS 변경은 전파에 24-48시간 소요 가능 → 다른 단계 진행 중에 미리 시작.

### 1.4 STEP 1 SQL 파일 정리

```bash
mkdir -p supabase/migrations
# STEP 1에서 만든 SQL 파일들을 여기에 복사
# 적용 순서대로 prefix 지정 (Supabase CLI 권장 형식: 14자리 timestamp)
mv 01_extensions.sql       supabase/migrations/20260101000001_extensions.sql
mv 02_app_schema.sql       supabase/migrations/20260101000002_app_schema.sql
mv 03_ai_schema.sql        supabase/migrations/20260101000003_ai_schema.sql
mv 04_communications.sql   supabase/migrations/20260101000004_communications.sql
# ... 나머지 파일들도 같은 패턴으로
```

`004_communications_and_activities.sql`이 반드시 포함되어 있는지 확인.

---

## 2. 외부 계정 + 도메인 준비

### 2.1 계정 생성 체크리스트

- [ ] **Anthropic Console** — https://console.anthropic.com → 결제 정보 등록 → API Key 발급
- [ ] **OpenAI Platform** — https://platform.openai.com → 결제 정보 등록 → API Key 발급
- [ ] **Supabase** — https://supabase.com → 조직 생성
- [ ] **Vercel** — https://vercel.com → GitHub 연동
- [ ] **GitHub** — 비공개 리포지토리 생성 (코드 푸시용)
- [ ] *(선택)* **Sentry** — https://sentry.io → 신규 프로젝트 (Next.js)
- [ ] *(선택)* **Slack Workspace** → Incoming Webhook 추가

### 2.2 도메인 DNS

도메인 등록처(Cloudflare, GoDaddy, Namecheap 등)의 DNS 관리 페이지에서:

```
# 발송 도메인 예: mail.yourcompany.com

# SPF (Postmark/Mailgun 사용 시 그쪽 안내 따라)
mail.yourcompany.com.   TXT   "v=spf1 include:spf.postmarkapp.com ~all"

# DKIM (Postmark가 발급한 키)
2025-pm._domainkey.mail.yourcompany.com.   TXT   "k=rsa; p=MIGfMA0GCS..."

# DMARC (점진적 적용 권장)
_dmarc.yourcompany.com.   TXT   "v=DMARC1; p=none; rua=mailto:dmarc@yourcompany.com"
```

옵션 A(mock)면 DKIM/SPF 불필요. 운영 진입 시 추가.

---

## 3. Supabase 설치

### 3.1 프로젝트 생성

1. Supabase Dashboard → **New project**
2. **Region** 선택 — 사용자/서버에 가장 가까운 곳:
   - 한국: `ap-northeast-2 Seoul`
   - 미국 동부: `us-east-1 N. Virginia`
   - 미국 서부: `us-west-1 N. California`
   - 유럽: `eu-west-1 Ireland`, `eu-central-1 Frankfurt`
3. **Database password** — 32자 이상 강력한 패스워드 생성. 1Password 등에 즉시 보관
4. **Pricing plan** — Free로 시작 가능. 운영 시 Pro 권장 (PITR, 일일 백업, 8 GB)

> 프로젝트 생성에 약 2분 소요. 완료되면 Project URL과 anon key가 발급됨.

### 3.2 Extensions 활성화

Dashboard → **Database → Extensions**에서 활성화하거나, SQL Editor에서:

```sql
-- 필수
CREATE EXTENSION IF NOT EXISTS pgcrypto;     -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS vector;       -- pgvector (knowledge_chunks RAG)
CREATE EXTENSION IF NOT EXISTS pg_trgm;      -- 텍스트 검색 인덱스
CREATE EXTENSION IF NOT EXISTS btree_gin;    -- 복합 인덱스 최적화

-- 선택 (DB 안에서 직접 cron 실행할 때만)
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

검증:

```sql
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('pgcrypto', 'vector', 'pg_trgm', 'btree_gin')
ORDER BY extname;
```

### 3.3 PostgREST에 스키마 노출

STEP 3 코드는 `app`, `ai`, `audit` 스키마를 사용합니다. PostgREST가 이들을 노출하도록 설정:

**Project Settings → API → Exposed schemas**에 추가:

```
public, app, ai, audit
```

저장 후 PostgREST가 자동 재시작 (~5초).

> ⚠️ `audit` 노출은 RLS로 admin only로 제한되어 있어야 함. STEP 1 SQL이 그렇게 작성됐는지 §3.5에서 검증.

### 3.4 STEP 1 마이그레이션 적용

세 가지 방법 중 택 1.

#### 방법 A. Supabase CLI (권장 — 재현 가능, 버전 관리)

```bash
# Supabase CLI 설치 (macOS 기준)
brew install supabase/tap/supabase

# 로컬 머신의 프로젝트 디렉터리에서
cd urm-platform
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>

# §1.4에서 정리한 supabase/migrations/ 디렉터리가 있으면
supabase db push

# 일부만 적용하려면
supabase db push --include-all
```

#### 방법 B. psql로 직접 실행

```bash
# Supabase Dashboard → Project Settings → Database → Connection string의
# "URI" 모드 (postgres://...)를 복사
export SUPABASE_DB_URL='postgres://postgres.xxx:<password>@aws-0-...pooler.supabase.com:6543/postgres'

# 순서대로 실행 — 에러 발생 시 즉시 멈추고 디버깅
for f in supabase/migrations/*.sql; do
  echo "=== Applying $f ==="
  psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$f" || { echo "FAILED at $f"; exit 1; }
done
```

#### 방법 C. Dashboard SQL Editor (소규모/초기 검증용)

각 SQL 파일을 순서대로 SQL Editor에 붙여넣고 Run. 큰 파일은 지원 안 됨.

### 3.5 RLS 검증 — 반드시 실행

마이그레이션 적용 후 `scripts/verify-rls.sql`을 실행:

```bash
psql "$SUPABASE_DB_URL" -f scripts/verify-rls.sql > rls-check.txt
grep -E "✗|⚠" rls-check.txt
```

위 grep이 0줄을 출력해야 합니다. 결과 해석은 `docs/RLS-VERIFICATION.md` 참조.

자주 발견되는 문제와 해결:

| 출력 | 의미 | 해결 |
|------|------|------|
| `✗ MISSING` (rls_enabled) | 테이블에 RLS 미활성 | `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` |
| `⚠ NO ORG SCOPING` | 정책에 organization_id 검증 누락 | 정책 식 수정 (멀티테넌트 위험) |
| `✗ NO POLICY DEFINED` | 정책 자체가 없음 | `CREATE POLICY ...` 추가 |
| `is_security_definer=false` | RPC 함수가 호출자 권한으로 작동 | `ALTER FUNCTION ... SECURITY DEFINER` |

### 3.6 Storage 버킷 생성

Dashboard → **Storage → New bucket**:

| 필드 | 값 |
|------|------|
| Name | `communications-attachments` |
| Public bucket | ❌ OFF |
| File size limit | 50 MB |
| Allowed MIME types | `application/pdf`, `image/*`, `application/vnd.openxmlformats-*`, `application/msword`, `text/plain` (운영 정책에 맞게) |

**Bucket policy**는 service_role만 INSERT/SELECT 가능하게 (CLI는 service_role 사용, 사용자는 signed URL로):

```sql
-- Storage RLS는 storage.objects 테이블에 적용
CREATE POLICY "service_role full access" ON storage.objects FOR ALL
  USING (bucket_id = 'communications-attachments' AND auth.role() = 'service_role');

CREATE POLICY "auth users read own org files" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'communications-attachments'
    AND (storage.foldername(name))[1] IN (
      SELECT organization_id::text FROM app.user_organizations
      WHERE user_id = auth.uid() AND is_active = true
    )
  );
```

`storage.foldername(name)[1]`은 storage path의 첫 번째 폴더 = `organization_id`. STEP 3의 `persistAttachment`가 `${organizationId}/${communicationId}/${filename}` 형식으로 업로드하므로 이 정책이 작동.

### 3.7 STEP 2 시드 데이터 적용

ai.agents (분류기, 답장 드래프터, strategy advisor 등), ai.brand_voice, ai.knowledge_chunks 시드 데이터를 SQL Editor 또는 psql로 적용:

```bash
psql "$SUPABASE_DB_URL" -f seeds/01_agents.sql
psql "$SUPABASE_DB_URL" -f seeds/02_brand_voice.sql
psql "$SUPABASE_DB_URL" -f seeds/03_auto_send_rules.sql
# (knowledge_chunks는 임베딩이 필요하므로 OpenAI 키 발급 후 별도 인제스트 스크립트로)
```

검증:

```sql
SELECT
  (SELECT COUNT(*) FROM ai.agents)              AS agents_count,
  (SELECT COUNT(*) FROM ai.brand_voice)         AS brand_voice_count,
  (SELECT COUNT(*) FROM ai.auto_send_rules)     AS auto_send_rules_count;
-- 기대값 (운영 정책에 따라 다름):
-- agents_count: 6+ (classifier, reply_drafter, strategy_advisor, ...)
-- brand_voice_count: 30+ (모듈×언어 조합)
-- auto_send_rules_count: 10 (표준 카테고리당 1개)
```

### 3.8 Auth 설정

Dashboard → **Authentication → URL Configuration**:

| 필드 | 값 (예시) |
|------|---------|
| Site URL | `https://app.yourcompany.com` (배포 도메인) |
| Redirect URLs | `https://app.yourcompany.com/auth/callback`<br>`http://localhost:3000/auth/callback` (개발용) |

Dashboard → **Authentication → Providers**:
- Email — 활성화 (이메일/비밀번호)
- Magic Link 사용 시 → Email Templates에서 confirm/reset 템플릿 검토
- Google/GitHub OAuth → 추가 시 redirect URL 동일

Dashboard → **Authentication → Email Templates**:
- "Confirm signup", "Magic Link" 등의 본문 한국어로 번역 (선택)

### 3.9 Supabase 키 발급

Dashboard → **Project Settings → API**에서 다음 4개를 복사:

| 변수명 | 위치 |
|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Project API keys → `anon public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Project API keys → `service_role` ⚠️ **절대 클라이언트에 노출 금지** |
| `SUPABASE_DB_URL` | Project Settings → Database → Connection string (URI 모드, **Pooler** 권장) |

> ⚠️ `service_role` key는 RLS를 우회합니다. Vercel env vars에만 저장하고 절대 git에 커밋하지 마세요.

---

## 4. 외부 API 키 발급

### 4.1 Anthropic

1. https://console.anthropic.com → Sign in
2. **Billing** → 결제 카드 등록 → 초기 충전 ($20+ 권장)
3. **API Keys** → **Create Key** → 이름: `urm-production` → 키 복사
4. `ANTHROPIC_API_KEY` 환경변수에 저장

키 형태: `sk-ant-api03-XXXXXXXXXXXX...`

### 4.2 OpenAI (임베딩 전용)

1. https://platform.openai.com → Sign in
2. **Settings → Billing** → Add payment method
3. **Settings → API keys** → **Create new secret key** → 이름: `urm-embeddings` → 키 복사
4. `OPENAI_API_KEY` 환경변수에 저장

> URM은 OpenAI를 **임베딩 전용**으로만 사용합니다 (text-embedding-3-large). 답장 생성은 Anthropic만 사용. OpenAI 비용은 매우 낮음 (1M 토큰당 $0.13).

### 4.3 Sentry / Slack (선택)

- **Sentry**: Project → Settings → Client Keys (DSN) → `SENTRY_DSN`에 저장
- **Slack**: Workspace → Apps → Incoming Webhooks → Webhook URL → `SLACK_WEBHOOK_URL`에 저장

---

## 5. 메일 인프라 선택과 설치

### 5.A 옵션 A — Mock 모드 (개발/staging)

가장 빠른 시작. 환경변수만 설정:

```bash
TABS_MAILER_HOST=mock
TABS_MAILER_PORT=587
TABS_MAILER_AUTH_METHOD=ip_whitelist
TABS_MAILER_FROM_DOMAIN=mail.example.com
TABS_MAILER_FROM_DEFAULT=noreply@mail.example.com

MAILCARRIER_HOST=mock
MAILCARRIER_USERNAME=mock@example.com
MAILCARRIER_PASSWORD=mock
```

`tabs-mailer.ts`의 `detectMockMode()`가 `host=mock`을 감지하면:
- `sendOne`은 SMTP 호출 없이 console.log + `{mocked: true}` 반환
- DB에는 정상적으로 outbound communication INSERT됨
- 인바운드는 `/api/webhooks/inbound`로 직접 POST해서 시뮬레이션 가능 (§9.2 참조)

### 5.B 옵션 B — Postmark (권장)

발송 + 인바운드 웹훅을 한 곳에서 처리하는 SaaS. 신뢰성 높고 도입 빠름.

#### 발송 측 (TABS Mailer 대체)

1. https://postmarkapp.com → Sign up
2. **Servers → Create Server** → 이름: `urm-prod`
3. **Sender Signatures** → 도메인 추가 → DKIM/SPF 레코드 DNS에 추가 → 검증 대기 (~5분)
4. **API Tokens** → Server API token 복사

환경변수:

```bash
TABS_MAILER_HOST=smtp.postmarkapp.com
TABS_MAILER_PORT=587
TABS_MAILER_AUTH_METHOD=login
TABS_MAILER_USERNAME=<Postmark Server API Token>   # username = password = token
TABS_MAILER_PASSWORD=<Postmark Server API Token>
TABS_MAILER_USE_TLS=true
TABS_MAILER_FROM_DOMAIN=mail.yourcompany.com
TABS_MAILER_FROM_DEFAULT=noreply@mail.yourcompany.com
TABS_MAILER_DB_CONN=                # 미사용 — getCampaignStats는 self-aggregation fallback 사용
```

#### 인바운드 측 (MailCarrier 대체)

Postmark는 **Inbound Email Webhook**을 지원해 IMAP 폴링 없이 메일이 오면 HTTP POST를 받을 수 있음.

1. Postmark Server → **Inbound** 탭 → 활성화
2. **Inbound Stream** → Server에서 발급된 이메일 주소(`<hash>@inbound.postmarkapp.com`)를 확인
3. DNS에서 `inbox@mail.yourcompany.com` → Postmark inbound로 포워딩 설정 (Postmark가 안내)
4. **Webhook URL** 설정: `https://app.yourcompany.com/api/webhooks/inbound`

⚠️ Postmark는 기본적으로 JSON 페이로드를 보내는데, STEP 4의 `/api/webhooks/inbound`는 `{raw_eml_base64, organization_id}` 형식을 기대합니다. **Postmark → URM 어댑터**가 필요합니다.

옵션 B-1: Postmark의 JSON을 그대로 받는 별도 라우트 작성:

```ts
// src/app/api/webhooks/inbound/postmark/route.ts (예시 — 직접 작성 필요)
import { NextResponse, type NextRequest } from 'next/server';
import { simpleParser } from 'mailparser';
import { getAdminSupabase } from '@/lib/supabase/admin';
import { persistInbound } from '@/lib/email/mailcarrier';

export async function POST(request: NextRequest) {
  // Postmark는 X-Postmark-Webhook-Token 헤더로 인증 권장
  const token = request.headers.get('x-postmark-webhook-token');
  if (token !== process.env.POSTMARK_WEBHOOK_TOKEN) {
    return NextResponse.json({ error: 'invalid_token' }, { status: 401 });
  }

  const body = await request.json();
  // Postmark JSON에서 RawEmail 필드(전체 RFC 822) 사용
  const rawEml = Buffer.from(body.RawEmail, 'utf-8');
  const parsed = await simpleParser(rawEml);

  // organization_id를 어떻게 결정할지 — 보통 To 주소 매핑:
  // inbox+org_<uuid>@mail.yourcompany.com → org_<uuid>
  const organizationId = extractOrgFromTo(body.ToFull) || env.DEFAULT_ORG_ID;

  const supa = getAdminSupabase();
  const result = await persistInbound(supa, organizationId, parsed);
  return NextResponse.json({ ok: true, ...result });
}
```

옵션 B-2: 이미 만든 generic `/api/webhooks/inbound`를 호출하는 Cloudflare Worker / Lambda 어댑터를 끼움.

### 5.C 옵션 C — 자체 TABS Mailer 4 + MailCarrier 7

조직 내부에 이미 TABS Mailer 4 (SMTP relay + MS SQL stats)와 MailCarrier 7 (IMAP)이 있는 경우.

#### 환경변수 (실제 호스트 입력):

```bash
TABS_MAILER_HOST=tabs-mailer-4.internal.yourcompany.com
TABS_MAILER_PORT=587
TABS_MAILER_AUTH_METHOD=plain                   # 또는 'ip_whitelist'
TABS_MAILER_USERNAME=urm-platform
TABS_MAILER_PASSWORD=<from-vault>
TABS_MAILER_USE_TLS=true
TABS_MAILER_FROM_DOMAIN=mail.yourcompany.com
TABS_MAILER_DB_CONN='Server=tabs-stats.internal,1433;Database=TabsStats;User Id=...;Password=...;Encrypt=true;'

MAILCARRIER_HOST=mailcarrier-7.internal.yourcompany.com
MAILCARRIER_PORT=993
MAILCARRIER_USERNAME=urm-inbox@mail.yourcompany.com
MAILCARRIER_PASSWORD=<from-vault>
MAILCARRIER_USE_IDLE=true
MAILCARRIER_INBOX_FOLDER=INBOX
```

#### 추가 작업 (Vercel에서는 IMAP 영구 연결 불가):

`MailCarrierClient`를 사용하려면 **Vercel 외부**에 배포해야 합니다 — §8 참조.

---

## 6. Vercel 배포

### 6.1 GitHub 리포지토리 준비

```bash
# 로컬에서
unzip urm-step3-full.zip -d urm-platform
cd urm-platform

# git 초기화
git init
git add .
git commit -m "Initial commit: URM Platform skeleton"

# .gitignore 검증 — node_modules, .next, .env*가 무시되는지 확인
cat .gitignore | grep -E "node_modules|\.next|\.env"

# GitHub에 비공개 repo 만든 후
git remote add origin git@github.com:<your-org>/urm-platform.git
git branch -M main
git push -u origin main
```

> 본 zip에는 `.gitignore`가 미포함 — 다음을 추가하세요:

```gitignore
# .gitignore
node_modules/
.next/
.env
.env.local
.env.*.local
*.tsbuildinfo
.vercel
.DS_Store
.cache/
coverage/
.next-cache/
```

### 6.2 Vercel 프로젝트 연결

1. https://vercel.com → **Add New → Project**
2. **Import Git Repository** → GitHub `<your-org>/urm-platform` 선택
3. **Framework Preset** — `Next.js` 자동 감지
4. **Root Directory** — `./` (기본값)
5. **Build Command** — `next build` (기본값)
6. **Install Command** — `npm install` (기본값)
7. **Output Directory** — `.next` (기본값)

먼저 **Deploy** 버튼 누르지 말고 환경변수부터 설정 → 그 다음 Deploy.

### 6.3 환경변수 설정

Vercel Dashboard → **Settings → Environment Variables**에 §부록 A의 전체 표를 추가. CLI로 일괄 등록도 가능:

```bash
# Vercel CLI 설치
npm i -g vercel
vercel login

# 프로젝트 디렉터리에서
vercel link

# .env.local을 Vercel env로 일괄 푸시
vercel env pull .env.local        # 현재 vercel env를 받아옴 (덮어쓰기 주의)

# 또는 개별 추가
vercel env add ANTHROPIC_API_KEY production
# (프롬프트에서 값 입력)
```

> ⚠️ **반드시 production 환경에서 `AI_AUTO_SEND_ENABLED=false`로 시작**하세요. 운영 안정화 후에 명시적으로 `true`로 변경.

각 환경(Development, Preview, Production)별로 같은 변수를 다르게 설정 가능:
- Development: 본인 로컬 개발용 (실제로는 .env.local로 관리)
- Preview: PR 미리보기 — staging Supabase 가리키기 권장
- Production: 운영용 production Supabase

### 6.4 Cron Secret 생성

Vercel Cron 인증용 비밀값:

```bash
# 32자 랜덤 시크릿 생성
openssl rand -hex 32

# Vercel env에 등록
vercel env add CRON_SECRET production
# (위에서 생성한 값 입력)

# 인바운드 웹훅 시크릿도 같은 방법으로
openssl rand -hex 32
vercel env add INBOUND_WEBHOOK_SECRET production
```

### 6.5 첫 배포

환경변수 등록 후:

```bash
git push origin main          # main에 푸시하면 자동 배포
# 또는 CLI로
vercel --prod
```

배포 로그를 모니터링하면서 빌드 단계의 에러 확인. 일반적인 실패 유형은 §11 참조.

배포 완료 시간: 평균 2-3분.

### 6.6 도메인 연결

1. Vercel Dashboard → **Settings → Domains**
2. **Add** → `app.yourcompany.com` 입력
3. Vercel이 안내하는 CNAME 레코드를 DNS에 추가
4. 검증 완료 후 자동 SSL 발급 (Let's Encrypt)

전파 후 Supabase Auth Site URL을 새 도메인으로 업데이트 (§3.8).

### 6.7 Cron Job 자동 등록 확인

`vercel.json`이 commit되어 있으면 Vercel이 자동으로 cron을 등록.

Vercel Dashboard → **Cron Jobs** 탭에서 확인:

```
✓ /api/cron/draft-expiry              0 3 * * *      (매일 03:00 UTC)
✓ /api/cron/process-pending-inbound   */2 * * * *    (2분 주기)
✓ /api/cron/mail-merge                */2 * * * *    (2분 주기)
```

> Vercel **Hobby plan**은 cron이 1일 1회로 제한됨. **Pro plan** 필요 (월 $20).

---

## 7. 첫 사용자와 조직 시드

배포 직후 DB는 비어 있어 로그인할 사용자가 없습니다. 다음 순서로 부트스트랩:

### 7.1 organization 행 INSERT

Supabase SQL Editor에서:

```sql
INSERT INTO app.organizations (id, name, slug, created_at)
VALUES (gen_random_uuid(), 'Your Company', 'your-company', NOW())
RETURNING id;
-- 반환된 organization_id를 메모
```

### 7.2 첫 사용자 생성 (Supabase Auth)

Dashboard → **Authentication → Users → Add user → Create new user**:
- Email: `admin@yourcompany.com`
- Password: 강력한 패스워드
- Auto Confirm User: ✅ 체크

또는 SQL로:

```sql
-- 비추천 — Dashboard 사용 권장 (해시 처리 자동)
```

생성된 사용자의 UUID는 Dashboard → Users 목록 또는:

```sql
SELECT id, email FROM auth.users WHERE email = 'admin@yourcompany.com';
```

### 7.3 user_organizations 연결

```sql
INSERT INTO app.user_organizations (user_id, organization_id, role, is_active, created_at)
VALUES (
  '<auth.users.id>',
  '<organization.id>',
  'owner',
  true,
  NOW()
);
```

### 7.4 ai.agents 등 시드와 organization_id 매핑

§3.7에서 시드한 ai.agents/brand_voice 등이 어떤 organization을 가리키는지 확인:

```sql
SELECT organization_id, COUNT(*) FROM ai.agents GROUP BY organization_id;
```

만약 시드가 다른 placeholder organization_id를 사용했다면 위 §7.1에서 만든 ID로 업데이트:

```sql
UPDATE ai.agents      SET organization_id = '<new-org-id>' WHERE organization_id = '<placeholder-id>';
UPDATE ai.brand_voice SET organization_id = '<new-org-id>' WHERE organization_id = '<placeholder-id>';
UPDATE ai.auto_send_rules SET organization_id = '<new-org-id>' WHERE organization_id = '<placeholder-id>';
```

### 7.5 로그인 시도

1. https://app.yourcompany.com/login
2. admin@yourcompany.com + 비밀번호 입력
3. 성공 시 `/drafts`로 자동 이동 (빈 목록 정상)

---

## 8. 장기 가동 워커 (선택)

§1.2 결정에서 consultation-worker 또는 자체 MailCarrier IMAP을 별도 호스트에서 돌리기로 한 경우.

### 8.1 Railway 배포 (권장)

**Railway** (https://railway.app)는 Vercel과 비슷한 UX의 컨테이너 호스팅. 영구 연결 지원.

```bash
# Railway CLI 설치
npm i -g @railway/cli
railway login

# 별도 디렉터리에서 (또는 같은 repo의 다른 서비스로)
mkdir urm-workers && cd urm-workers
cp -r ../urm-platform/src/workers .
cp -r ../urm-platform/src/lib .
cp -r ../urm-platform/src/types .
cp ../urm-platform/package.json .
cp ../urm-platform/tsconfig.json .

# Railway 프로젝트 생성
railway init
railway link

# 환경변수 등록 (Vercel에 등록한 것과 동일한 값)
railway variables set SUPABASE_DB_URL='...'
railway variables set NEXT_PUBLIC_SUPABASE_URL='...'
# ... 나머지

# 배포
railway up
```

`Procfile` 또는 `railway.json`으로 시작 명령 지정:

```json
// railway.json
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "tsx src/workers/consultation-worker.ts",
    "restartPolicyType": "ALWAYS"
  }
}
```

### 8.2 Fly.io 배포 (대안)

```bash
brew install flyctl
flyctl auth login

cd urm-workers
flyctl launch                  # 대화형 설정
flyctl secrets set SUPABASE_DB_URL='...'  # 환경변수
flyctl deploy
```

### 8.3 모니터링

worker 로그를 Railway Dashboard 또는 `railway logs --tail`로 확인. `pg LISTEN`이 끊기면 STEP 3의 자동 재연결 로직이 작동하지만, 영구 끊김 시 알림 필요 → Sentry/Slack에 연결.

---

## 9. 스모크 테스트

배포 후 시스템이 끝까지 작동하는지 확인하는 5단계.

### 9.1 헬스체크

```bash
curl https://app.yourcompany.com/api/health
```

기대 응답:

```json
{
  "status": "ok",
  "version": "0.2.0",
  "timestamp": "2026-05-10T...",
  "checks": { "database": "ok", "storage": "unknown" }
}
```

`status: "down"`이면 Supabase 키 또는 네트워크 점검.

### 9.2 인바운드 웹훅 테스트

```bash
# 테스트용 raw EML 생성
cat > test-mail.eml <<'EOF'
From: customer@example.com
To: inbox@mail.yourcompany.com
Subject: Test inbound message
Message-ID: <test-001@example.com>
Date: Thu, 10 May 2026 10:00:00 +0000
Content-Type: text/plain; charset=utf-8

Hello, this is a test inbound message.
EOF

# base64로 인코딩 후 webhook에 POST
RAW_B64=$(base64 -i test-mail.eml | tr -d '\n')

curl -X POST https://app.yourcompany.com/api/webhooks/inbound \
  -H "Content-Type: application/json" \
  -H "X-URM-Webhook-Secret: $INBOUND_WEBHOOK_SECRET" \
  -d "{\"raw_eml_base64\":\"$RAW_B64\",\"organization_id\":\"<your-org-id>\"}"
```

기대 응답:

```json
{ "ok": true, "communication_id": "...", "thread_id": "...", "duplicate": false }
```

DB에서 확인:

```sql
SELECT id, subject, from_address, ai_processing_status, status
FROM app.communications
WHERE message_id = '<test-001@example.com>';
-- ai_processing_status='pending' 인 행이 1건 있어야 함
```

### 9.3 AI 처리 트리거 (수동)

2분 cron을 기다리거나, 직접 호출:

```bash
curl -X GET https://app.yourcompany.com/api/cron/process-pending-inbound \
  -H "Authorization: Bearer $CRON_SECRET"
```

기대 응답:

```json
{
  "ok": true,
  "elapsed_ms": 3500,
  "picked": 1,
  "processed": 1,
  "failed": 0,
  "skipped": 0
}
```

DB에서 확인:

```sql
SELECT communication_id, classification_category, status, requires_human_approval
FROM ai.drafts
ORDER BY created_at DESC LIMIT 1;
-- pending 상태의 draft가 1건 생성되어 있어야 함

SELECT status, model, tokens_in, tokens_out, cost_usd
FROM ai.runs
ORDER BY created_at DESC LIMIT 5;
-- success 상태의 run이 최소 2건 (classifier Haiku + reply_drafter Opus)
```

### 9.4 대시보드 검토

브라우저에서 https://app.yourcompany.com/login → 로그인 → `/drafts` 이동 → 테스트 드래프트가 보이는지 확인 → 클릭 → 원본 메일 + AI 분류 + 답장 드래프트 본문이 보이는지 확인.

### 9.5 발송 테스트

대시보드에서 **승인하고 발송** 버튼 클릭. 옵션 A(mock)면 console.log만 발생, 옵션 B/C면 실제 메일 전송.

DB 확인:

```sql
SELECT id, direction, status, sent_at, message_id
FROM app.communications
WHERE direction = 'outbound'
ORDER BY created_at DESC LIMIT 1;
-- status='sent' + sent_at 있는 행

SELECT status, sent_at, sent_communication_id
FROM ai.drafts
ORDER BY created_at DESC LIMIT 1;
-- status='sent', sent_communication_id 있음
```

---

## 10. 운영 — 비용, 감사, 알림

### 10.1 비용 모니터링

실시간 추적:

```sql
-- 오늘 누적 비용
SELECT
  organization_id,
  COUNT(*) AS run_count,
  SUM(cost_usd) AS today_cost_usd,
  SUM(tokens_in) AS tokens_in,
  SUM(tokens_out) AS tokens_out
FROM ai.runs
WHERE created_at >= CURRENT_DATE
  AND status = 'success'
GROUP BY organization_id;

-- 모델별
SELECT model, COUNT(*) AS calls, SUM(cost_usd) AS cost_usd
FROM ai.runs
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND status = 'success'
GROUP BY model
ORDER BY cost_usd DESC;
```

`MAX_DAILY_AI_COST_USD` 초과 시 자동 차단되며 `ai.runs`에 `status='budget_exceeded'`로 기록됨.

### 10.2 자동발송 감사

```sql
-- 자동발송으로 나간 메일 (auto_send_eligible AND ai_generated)
SELECT
  c.id,
  c.subject,
  c.to_addresses,
  c.sent_at,
  c.external_data->>'auto_sent' AS auto_sent_flag,
  d.classification_category,
  d.confidence
FROM app.communications c
JOIN ai.drafts d ON d.id = c.ai_draft_id
WHERE c.direction = 'outbound'
  AND c.ai_generated = true
  AND (c.external_data->>'auto_sent')::boolean = true
ORDER BY c.sent_at DESC
LIMIT 100;

-- 차단된 자동발송 시도 (게이트 평가 결과 사유)
SELECT
  d.id,
  d.classification_category,
  d.auto_send_blocked_reasons,
  d.created_at
FROM ai.drafts d
WHERE d.auto_send_eligible = false
  AND array_length(d.auto_send_blocked_reasons, 1) > 0
ORDER BY d.created_at DESC
LIMIT 100;
```

### 10.3 Slack 알림 (선택)

핵심 이벤트(예산 초과, 시스템 다운)를 Slack으로 푸시. 별도 미들웨어/wrapper 작성 필요. 골격은 STEP 3에 포함 안 됨 — 운영 시 추가:

```ts
// src/lib/notify/slack.ts (직접 작성)
import { env } from '@/lib/env';

export async function notifySlack(message: string, level: 'info' | 'warn' | 'error' = 'info') {
  if (!env.SLACK_WEBHOOK_URL) return;
  const emoji = { info: '📘', warn: '⚠️', error: '🚨' }[level];
  await fetch(env.SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: `${emoji} URM: ${message}` }),
  });
}
```

호출 위치: `cost-tracker.ts`의 budget exceeded 분기, `claude-client.ts`의 fail 분기 등.

### 10.4 Sentry 알림

`SENTRY_DSN`만 설정하면 Next.js 에러는 자동 캡처. 추가 설정:

```bash
npm install @sentry/nextjs
npx @sentry/wizard@latest -i nextjs
```

Wizard가 `sentry.client.config.ts`, `sentry.server.config.ts` 자동 생성.

---

## 11. 트러블슈팅

### 11.1 빌드 실패 — "Cannot find module 'mssql'"

**증상**: `next build` 시 webpack이 mssql 못 찾음.
**원인**: `next.config.mjs`의 webpack external 설정 누락.
**해결**: `next.config.mjs`에 다음 포함됐는지 확인:

```js
webpack: (config, { isServer }) => {
  if (isServer) {
    config.externals = config.externals || [];
    if (Array.isArray(config.externals)) {
      config.externals.push({ mssql: 'commonjs mssql' });
    }
  }
  return config;
},
```

### 11.2 런타임 에러 — "Invalid environment configuration"

**증상**: Vercel 배포 후 모든 라우트가 500.
**원인**: `env.ts`의 zod 검증 실패 — 필수 환경변수 누락.
**해결**: Vercel logs에서 zod 에러 메시지 확인 → 누락된 변수 추가.

```bash
vercel logs https://app.yourcompany.com --prod
```

### 11.3 로그인 후 401 반복

**증상**: `/login`에서 성공하지만 `/drafts` 진입 시 401 또는 무한 리다이렉트.
**원인**: `user_organizations` 테이블에 해당 사용자 매핑 없음 → `getUserAndOrg()` throw.
**해결**: §7.3 참조하여 `user_organizations` INSERT.

### 11.4 분류기 실패 — "ClaudeAgentNotFoundError"

**증상**: `/api/cron/process-pending-inbound` 호출 시 `failed`로 떨어짐.
**원인**: `ai.agents`에 `role='classifier'` 행이 없거나 `is_active=false`.
**해결**: §3.7 시드 적용 + organization_id 매핑 확인.

```sql
SELECT role, name, model, is_active FROM ai.agents
WHERE organization_id = '<your-org-id>';
-- 최소 'classifier', 'reply_drafter'가 is_active=true로 있어야 함
```

### 11.5 임베딩 실패 — RAG 결과 빈약

**증상**: 답장 드래프트가 일반적인 톤만 사용, 사내 자료 미반영.
**원인**: `ai.knowledge_chunks`가 비어 있거나, 임베딩이 누락.
**해결**: 사내 문서를 OpenAI text-embedding-3-large로 임베딩 후 INSERT. 별도 인제스트 스크립트 필요 (별도 단계).

### 11.6 Storage 업로드 실패 — RLS 거절

**증상**: 인바운드 메일에 첨부파일 있으면 console에 `Storage upload failed: ...`.
**원인**: `storage.objects`에 service_role 정책이 누락.
**해결**: §3.6의 storage RLS 정책 적용.

### 11.7 메일 발송 실패 — TabsMailerError

**증상**: 드래프트 승인 시 `send_failed`.
**원인**: SMTP 인증 실패 / DNS 미전파 / 도메인 검증 미완료.
**해결**:
1. `vercel logs`로 정확한 에러 메시지 확인
2. Postmark 사용 시 → Sender Signatures의 도메인 상태가 "Verified"인지 확인
3. SPF/DKIM 전파 확인: `dig TXT mail.yourcompany.com +short`

### 11.8 Cron 미실행

**증상**: `/api/cron/process-pending-inbound`가 2분마다 호출되지 않음.
**원인**: Vercel Hobby plan 제한 (1일 1회) 또는 vercel.json 미커밋.
**해결**: Pro plan 업그레이드 + `git commit vercel.json && git push`.

### 11.9 DB connection pooler 한도 초과

**증상**: `too many connections` 에러.
**원인**: Supabase Free tier는 60 동시 연결. Vercel serverless가 cold start마다 새 연결 생성.
**해결**:
1. `SUPABASE_DB_URL`을 **Pooler URL** (`pooler.supabase.com:6543`)로 변경
2. Pro plan 업그레이드 → 200 connections

### 11.10 RLS verification에 ⚠ 표시

**해결**: `docs/RLS-VERIFICATION.md`의 "일반적인 문제와 해결" 섹션 참조.

---

## 부록 A. 환경변수 전체 표

`src/lib/env.ts`에 zod로 정의된 전체 변수 목록.

| Key | 필수 | 기본값 | 출처 |
|-----|------|------|------|
| `ANTHROPIC_API_KEY` | ✅ | — | https://console.anthropic.com → API Keys |
| `ANTHROPIC_MODEL_OPUS` | — | `claude-opus-4-7` | 변경 금지 (마스터 §2.4) |
| `ANTHROPIC_MODEL_HAIKU` | — | `claude-haiku-4-5-20251001` | 변경 금지 |
| `ANTHROPIC_MODEL_SONNET` | — | `claude-sonnet-4-6` | 변경 금지 |
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ | — | Supabase Project Settings → API |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✅ | — | 동일 |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | — | 동일 — ⚠️ 절대 클라이언트 노출 금지 |
| `SUPABASE_DB_URL` | ✅ | — | Project Settings → Database (Pooler URL 권장) |
| `SUPABASE_STORAGE_BUCKET_ATTACHMENTS` | — | `communications-attachments` | §3.6에서 생성 |
| `OPENAI_API_KEY` | ✅ | — | https://platform.openai.com → API Keys |
| `OPENAI_EMBEDDING_MODEL` | — | `text-embedding-3-large` | 임베딩 모델 |
| `TABS_MAILER_HOST` | ✅ | — | `mock` 또는 SMTP host |
| `TABS_MAILER_PORT` | — | 587 | |
| `TABS_MAILER_AUTH_METHOD` | ✅ | — | `plain` / `login` / `ip_whitelist` |
| `TABS_MAILER_USERNAME` | 조건부 | — | `ip_whitelist` 외에 필수 |
| `TABS_MAILER_PASSWORD` | 조건부 | — | 동일 |
| `TABS_MAILER_USE_TLS` | — | true | |
| `TABS_MAILER_FROM_DOMAIN` | ✅ | — | 발송 도메인 |
| `TABS_MAILER_FROM_DEFAULT` | — | — | 기본 발송자 (없으면 `noreply@<DOMAIN>`) |
| `TABS_MAILER_DB_CONN` | — | — | 옵션 C (TABS stats DB) 사용 시 |
| `MAILCARRIER_HOST` | ✅ | — | `mock` 또는 IMAP host |
| `MAILCARRIER_PORT` | — | 993 | |
| `MAILCARRIER_USERNAME` | ✅ | — | |
| `MAILCARRIER_PASSWORD` | ✅ | — | |
| `MAILCARRIER_USE_IDLE` | — | true | false 시 폴링 |
| `MAILCARRIER_INBOX_FOLDER` | — | INBOX | |
| `MAILCARRIER_POLL_INTERVAL_SECONDS` | — | 30 | |
| `MAIL_DOMAIN` | — | — | 트래킹용 (옵션) |
| `TRACKING_BASE_URL` | — | — | 트래킹용 (옵션) |
| `AI_AUTO_SEND_ENABLED` | — | false | **운영 첫 배포는 반드시 false** |
| `SCRAPING_ENABLED` | — | true | |
| `MAX_DAILY_AI_COST_USD` | — | 50 | 초과 시 차단 |
| `MAX_MONTHLY_AI_COST_USD` | — | 1500 | 동일 |
| `DRAFT_EXPIRY_DAYS` | — | 7 | ai.drafts.expires_at = NOW() + N |
| `CLAUDE_HARD_TIMEOUT_MS` | — | 60000 | Anthropic API timeout |
| `CLAUDE_MAX_RETRIES` | — | 3 | 429/5xx/timeout 재시도 |
| `REDIS_URL` | — | — | 미사용 |
| `NODE_ENV` | — | development | `production` 권장 |
| `LOG_LEVEL` | — | info | |
| `SENTRY_DSN` | — | — | https://sentry.io 프로젝트 DSN |
| `SLACK_WEBHOOK_URL` | — | — | Slack incoming webhook |
| `INBOUND_WEBHOOK_SECRET` | ⚠️ | — | `openssl rand -hex 32` |
| `CRON_SECRET` | ⚠️ | — | 동일 |

⚠️ = production에서는 반드시 설정.

---

## 부록 B. SQL 검증 쿼리 모음

운영 중 자주 쓰는 점검 쿼리.

```sql
-- 1. 미처리 inbound 메일 큐 길이
SELECT COUNT(*) FROM app.communications
WHERE direction='inbound' AND ai_processing_status='pending';

-- 2. 만료 임박 드래프트
SELECT id, subject, expires_at, status
FROM ai.drafts
WHERE status='pending' AND expires_at < NOW() + INTERVAL '24 hours'
ORDER BY expires_at;

-- 3. 최근 24시간 분류 분포
SELECT classification_category, COUNT(*) FROM ai.drafts
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY classification_category
ORDER BY 2 DESC;

-- 4. 최근 24시간 자동발송 차단 사유 빈도
SELECT unnest(auto_send_blocked_reasons) AS reason, COUNT(*) AS hits
FROM ai.drafts
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY reason
ORDER BY 2 DESC;

-- 5. 가장 비용 많이 쓴 organization
SELECT organization_id, SUM(cost_usd) AS month_cost_usd
FROM ai.runs
WHERE created_at >= date_trunc('month', NOW())
  AND status='success'
GROUP BY organization_id
ORDER BY 2 DESC
LIMIT 10;

-- 6. ai.runs 실패율 (지난 7일)
SELECT
  status,
  COUNT(*) AS count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM ai.runs
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY status
ORDER BY 2 DESC;

-- 7. 캠페인 진행률
SELECT
  id,
  name,
  status,
  progress->>'totalRecipients' AS recipients,
  progress->>'totalSent' AS sent,
  progress->>'totalDelivered' AS delivered,
  progress->>'totalFailed' AS failed
FROM app.mail_merge_jobs
WHERE created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;
```

---

## 마무리 — 배포 완료 체크리스트

배포가 끝났다고 선언하기 전에 다음 모두 ✅:

- [ ] `/api/health` 200 응답
- [ ] 인바운드 웹훅 테스트 메일 → DB INSERT 확인
- [ ] cron이 2분마다 실행됨 (`vercel logs --prod | grep cron`)
- [ ] 분류기 + 드래프터 호출 → ai.runs `status='success'` 행 생성
- [ ] 대시보드 로그인 → 드래프트 보임 → 승인 → outbound communication INSERT
- [ ] (옵션 B/C) 실제 메일 발송 테스트 → 수신함 확인
- [ ] `verify-rls.sql` 0개의 ✗ 또는 ⚠
- [ ] `MAX_DAILY_AI_COST_USD`, `MAX_MONTHLY_AI_COST_USD` 적정값 설정 확인
- [ ] `AI_AUTO_SEND_ENABLED` 의도된 값으로 설정 (첫 운영은 `false` 권장)
- [ ] DKIM/SPF/DMARC DNS 전파 완료 (`dig +short TXT _dmarc.yourdomain.com`)
- [ ] Sentry/Slack 알림 동작 검증
- [ ] DB 백업 활성화 확인 (Supabase Pro: Daily backups)

위 모두 ✅면 운영 시작 준비 완료.
