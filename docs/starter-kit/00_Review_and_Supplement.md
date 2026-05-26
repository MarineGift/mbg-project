# URM Platform — 검토 보고서·코드 가이드 (STEP 3 핵심 참조)

> **이 문서의 위치**: STEP 3(이메일 통합·AI 인프라 코드)의 직접 참조 가이드.
> STEP 4-7도 본 문서를 부분 참조. 작업 명세서(`04_task_email_integration.md`)는 "무엇을 만들지", 본 문서는 "어떻게 만들지"를 다룬다.

> **분량**: 약 1,300줄. 11개 섹션. 모든 결정·패턴·코드 예시는 STEP 1·2의 데이터베이스 스키마(`sql_completion/`, 7,385줄)를 전제로 한다.

---

## 1. 개요

### 1.1 본 문서의 위치

URM Platform 개발은 7개 STEP으로 구성된다:

| STEP | 작업 | 본 문서 활용도 |
|------|------|----------------|
| STEP 0 | 환경 설정 (Supabase·Anthropic·TABS·MailCarrier 계정) | 낮음 |
| STEP 1 | DB 스키마 13 SQL | 낮음 (완료) |
| STEP 2 | AI 에이전트 시드·few_shot 보강 | 낮음 (완료) |
| **STEP 3** | **이메일 통합·AI 인프라 코드 (TypeScript)** | **★★★ 직접 참조** |
| STEP 4 | 프론트엔드 Phase 1 (대시보드·인게이지먼트 보드) | 중간 (타입·환경 재사용) |
| STEP 5 | 메일 통합 UI (인박스·작성·AI 초안 검토) | ★★★ 직접 참조 |
| STEP 6 | AI 초안 승인·자동발송 게이트 UI | ★★ |
| STEP 7 | 첫 운영 시작 | ★★ (관측·운영 부분) |

### 1.2 STEP 3 코드의 역할

데이터베이스(STEP 1·2)와 사용자 인터페이스(STEP 4-6) 사이의 **백엔드 인프라**.

- **read 측**: MailCarrier 7 IMAP에서 메일 수신 → 스키마(communications, attachments)에 저장
- **process 측**: Anthropic API로 분류·회신 초안 생성 → ai.runs·ai.drafts 기록
- **write 측**: TABS Mailer 4 SMTP로 발송 (사람 승인 후 또는 자동발송 게이트 통과 시)
- **automation 측**: pg_notify·크론으로 백그라운드 처리 (consultation 전략·draft 만료·메일머지)

### 1.3 적용 범위와 제외 범위

**범위 내**:
- Anthropic SDK 래퍼 (재시도·비용·PII)
- TABS Mailer 4 / MailCarrier 7 어댑터
- 메일 처리 파이프라인 (분류 → 스레드 매칭 → 회신 초안)
- 자동발송 게이트 평가
- 백그라운드 워커 3종

**범위 외 (다른 STEP)**:
- UI 컴포넌트, 폼, 인박스 화면 (STEP 4-6)
- Supabase 인증·권한 정책 (STEP 1·2 + STEP 4)
- 스크래핑 시스템 (STEP 8, 별도)
- 모니터링 인프라(Datadog·Sentry 등) 통합 (STEP 7)
- TABS Mailer 4의 MS SQL 통계 DB 직접 접근 (어댑터의 메서드만 정의, 실 구현은 외부 정보 수령 후)

### 1.4 핵심 결정 요약

| 결정 항목 | 선택 | 근거 |
|----------|------|------|
| Anthropic SDK 버전 | `@anthropic-ai/sdk` ^0.40 | 2026-05 시점 안정판, opus-4-7 지원 |
| HTTP 클라이언트 | SDK 내장 fetch | extra 의존성 회피 |
| IMAP 라이브러리 | `imapflow` ^1.0 | IDLE 지원, RFC 5322 파싱 안정 |
| SMTP 라이브러리 | `nodemailer` ^6.9 | 산업 표준, 헤더 커스터마이징 자유 |
| 메일 파싱 | `mailparser` ^3.7 | imapflow와 자연스럽게 결합 |
| 환경변수 검증 | `zod` ^3.23 | 런타임 검증 + 타입 추론 |
| 테스트 러너 | `vitest` ^2.0 | 빠른 실행, ESM 친화 |
| 외부 API 모킹 | `msw` ^2.4 | HTTP 레벨 모킹, 표준화 |
| 워커 런타임 | env 분기 (Vercel Cron / Render Worker / Supabase Edge) | 단일 코드, 다중 런타임 |
| 로깅 | `pino` ^9 또는 console wrapping | JSON 구조화 로그 |

---

## 2. 시스템 아키텍처

### 2.1 컴포넌트 토폴로지

```
                                    ┌─────────────────────────┐
                                    │   Anthropic API         │
                                    │  (Claude Opus·Haiku)    │
                                    └────────────┬────────────┘
                                                 │
                                                 ▼
┌──────────────┐    SMTP      ┌─────────────────────────────────────┐
│ TABS Mailer 4│◄─────────────│  STEP 3 INFRASTRUCTURE              │   IMAP    ┌──────────────┐
│              │              │                                     │◄──────────│ MailCarrier 7│
│ (외부 발송)  │              │  ┌────────────────────────────────┐ │           │              │
└──────────────┘              │  │ lib/ai/                        │ │           │ (외부 수신)  │
                              │  │  claude-client · pii-masker    │ │           └──────────────┘
                              │  │  prompt-renderer · cost-tracker│ │
                              │  └────────────────────────────────┘ │
                              │                                     │
                              │  ┌────────────────────────────────┐ │
                              │  │ lib/email/                     │ │
                              │  │  tabs-mailer · mailcarrier     │ │
                              │  │  header-parser · processor     │ │
                              │  │  auto-send-gate                │ │
                              │  └────────────────────────────────┘ │
                              │                                     │
                              │  ┌────────────────────────────────┐ │
                              │  │ workers/                       │ │
                              │  │  consultation·draft-expiry·    │ │
                              │  │  mail-merge                    │ │
                              │  └────────────────────────────────┘ │
                              └─────────────────┬───────────────────┘
                                                │
                                                ▼ pg / Supabase client
                              ┌─────────────────────────────────────┐
                              │  Supabase / PostgreSQL              │
                              │  app · audit · ai 스키마             │
                              │  (sql_completion/ 7,385줄 적용 후)   │
                              └─────────────────────────────────────┘
                                                ▲
                                                │ Server Actions / RPC
                              ┌─────────────────────────────────────┐
                              │  STEP 4-6 Frontend (Next.js)        │
                              └─────────────────────────────────────┘
```

### 2.2 데이터 흐름 — 메일 수신 → AI 분류 → 회신 초안 → 검토 → 발송

다음은 1건의 inbound 이메일이 처리되는 전체 흐름이다.

```
[1] MailCarrier 7 IMAP IDLE
    │
    │ 새 메일 도착 알림
    ▼
[2] mailcarrier.ts onMessage 콜백
    │ - mailparser로 raw → ParsedMail
    │ - PII 사전 마스킹 (저장 직전)
    │ - 첨부 → Supabase Storage 업로드
    ▼
[3] header-parser.ts findThreadId()
    │ - X-URM-Communication-Id (1순위)
    │ - In-Reply-To
    │ - References (역순)
    │ - 없으면 새 thread UUID
    ▼
[4] app.communications INSERT
    │ - direction='inbound', channel='email'
    │ - message_id (UNIQUE)
    │ - thread_id, in_reply_to
    │ - external_data (X-URM-* 등)
    │ - ai_processing_status='pending'
    ▼
[5] processor.ts processInbound(commId) — 큐로 분리 가능
    │
    ├─[5-1] PII 사전 마스킹 (이미 했으면 skip)
    │
    ├─[5-2] ClaudeClient.complete({ agentRole: 'classifier' })
    │       │
    │       ├─ DB에서 ai.agents (role=classifier, language=detected) 조회
    │       ├─ Haiku 호출 (claude-haiku-4-5-20251001)
    │       ├─ 출력 JSON 파싱 → ClassificationOutput
    │       ├─ category ∈ STANDARD_CATEGORIES 검증 (위반 시 throw)
    │       └─ ai.runs INSERT (성공·실패 모두)
    │
    ├─[5-3] Thread context 보강 (recent communications 5)
    │
    ├─[5-4] ClaudeClient.complete({ agentRole: 'reply_drafter' })
    │       │
    │       ├─ ai.agents (role=reply_drafter, module=detected, language=detected)
    │       ├─ Opus 호출 (claude-opus-4-7)
    │       │   fallback claude-sonnet-4-6 (1회 재시도)
    │       ├─ prompt-renderer로 컨텍스트 합성:
    │       │   - brand_voice (모듈·언어 매칭)
    │       │   - knowledge_chunks (cosine top_k=8)
    │       │   - thread_history (최근 5)
    │       └─ 출력 JSON: { subject, body_plain, rationale, risk_flags, requires_human_approval }
    │
    ├─[5-5] auto-send-gate.evaluate()
    │       │
    │       ├─ AI_AUTO_SEND_ENABLED 체크
    │       ├─ ai.auto_send_rules (org + category + module)
    │       ├─ confidence·blocked_keywords·daily_limit·hourly_limit·per_party_daily_limit
    │       ├─ requires_calendar_data·requires_human (강제)
    │       └─ GateResult { allowed, reasons[], blockedRules[] }
    │
    └─[5-6] ai.drafts INSERT
            ├─ expires_at = NOW() + 7 days
            ├─ requires_human_approval = !gateResult.allowed
            ├─ ai_generated = true
            └─ communications.ai_draft_id FK 갱신

[6] STEP 5-6 UI에서 사람 검토 또는 (게이트 통과 시) 자동발송
    │
    ▼
[7] 발송 결정
    │
    ├─[자동] tabs_mailer.sendOne() — gate.allowed=true 시
    │
    └─[수동] 사람이 UI에서 승인 → ai.drafts.status='approved'
            → mail-merge-worker 또는 즉시 sendOne()

[8] tabs_mailer.sendOne() — 공통
    │ - X-URM-Engagement-Id, X-URM-Communication-Id, X-URM-Auto-Send 헤더 부착
    │ - quiet_hours 체크
    │ - 발송 성공 시 communications INSERT (direction='outbound')
    │ - communications.sent_at 기록
    ▼
[9] (선택) TABS Mailer 4 캠페인 통계 동기화
    │ - getCampaignStats → mail_merge_jobs.progress 갱신
    │ - opened_at, clicked_at 등 전파 (외부 시스템 정보 정합)
```

### 2.3 컨트롤 플레인 vs 데이터 플레인

본 인프라는 두 개의 평면으로 구성된다.

**컨트롤 플레인 (느림·정합 중요)**:
- DB 트랜잭션 (Supabase)
- pg_notify 트리거
- ai.agents·brand_voice 시드 데이터
- mail_merge_jobs 큐

**데이터 플레인 (빠름·throughput 중요)**:
- Anthropic API 호출
- IMAP IDLE 수신
- SMTP 발송
- Supabase Storage 첨부 업로드

각 평면의 실패는 다르게 처리한다:
- 컨트롤 플레인 실패 → 즉시 throw·알람
- 데이터 플레인 실패 → 재시도·dead letter

### 2.4 외부 의존성

| 외부 시스템 | 인터페이스 | 미확정 정보 (운영 전 수령 필요) | 미확정 시 대응 |
|-------------|-----------|------------------------------|--------------|
| Anthropic API | HTTPS · `@anthropic-ai/sdk` | 없음 (계정·키 보유 가정) | — |
| Supabase | HTTPS·pg connection pooler | 없음 | — |
| TABS Mailer 4 | SMTP submit (587/465) | SASL 방식 (PLAIN/LOGIN/IP whitelist), 사용자 정의 헤더 통과 여부, 캠페인 통계 DB 스키마 | Mock 어댑터 + env 분기로 모든 방식 코드 포함 |
| MailCarrier 7 | IMAP4 | IDLE 지원 여부 | IDLE 우선·30초 폴링 폴백 자동 |
| OpenAI (임베딩만) | HTTPS · text-embedding-3-large | 없음 (계정·키 보유 가정) | — |
| Supabase Storage | S3 호환 | 없음 | — |

---

## 3. 환경·설정 관리

### 3.1 환경 변수 카탈로그

모든 환경변수는 `lib/env.ts`에서 zod 스키마로 검증된다. 변수 자체 또는 검증된 값에만 코드에서 접근.

#### 3.1.1 Anthropic·OpenAI

| 변수 | 타입 | 기본값 | 검증 |
|------|------|--------|------|
| `ANTHROPIC_API_KEY` | string | — (필수) | min length 20, prefix `sk-ant-` 권장 |
| `ANTHROPIC_MODEL_OPUS` | literal | `claude-opus-4-7` | 정확한 리터럴만 |
| `ANTHROPIC_MODEL_HAIKU` | literal | `claude-haiku-4-5-20251001` | 정확한 리터럴만 |
| `ANTHROPIC_MODEL_SONNET` | literal | `claude-sonnet-4-6` | fallback용 |
| `OPENAI_API_KEY` | string | — (필수) | min length 20 |
| `OPENAI_EMBEDDING_MODEL` | string | `text-embedding-3-large` | enum 또는 string |

#### 3.1.2 Supabase

| 변수 | 타입 | 기본값 | 검증 |
|------|------|--------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | url | — | https URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | string | — | JWT 형식 |
| `SUPABASE_SERVICE_ROLE_KEY` | string | — | JWT 형식 |
| `SUPABASE_DB_URL` | url | — | 직접 pg 연결용 (워커) |
| `SUPABASE_STORAGE_BUCKET_ATTACHMENTS` | string | `communications-attachments` | DNS-safe |

#### 3.1.3 TABS Mailer 4

| 변수 | 타입 | 기본값 | 검증 |
|------|------|--------|------|
| `TABS_MAILER_HOST` | string | — | hostname |
| `TABS_MAILER_PORT` | number | 587 | 1~65535 |
| `TABS_MAILER_AUTH_METHOD` | enum | — | `plain` / `login` / `ip_whitelist` |
| `TABS_MAILER_USERNAME` | string? | — | auth_method != ip_whitelist 일 때만 필수 |
| `TABS_MAILER_PASSWORD` | string? | — | 동일 |
| `TABS_MAILER_USE_TLS` | boolean | true | — |
| `TABS_MAILER_FROM_DOMAIN` | string | — | SPF/DKIM/DMARC 인증 도메인 |

#### 3.1.4 MailCarrier 7

| 변수 | 타입 | 기본값 | 검증 |
|------|------|--------|------|
| `MAILCARRIER_HOST` | string | — | hostname |
| `MAILCARRIER_PORT` | number | 993 | 1~65535 |
| `MAILCARRIER_USERNAME` | string | — | — |
| `MAILCARRIER_PASSWORD` | string | — | — |
| `MAILCARRIER_USE_IDLE` | boolean | true | — |
| `MAILCARRIER_INBOX_FOLDER` | string | `INBOX` | — |
| `MAILCARRIER_POLL_INTERVAL_SECONDS` | number | 30 | IDLE 미사용 시만 |

#### 3.1.5 비즈니스 설정

| 변수 | 타입 | 기본값 | 검증 |
|------|------|--------|------|
| `AI_AUTO_SEND_ENABLED` | boolean | false | **운영 초기 항상 false** |
| `SCRAPING_ENABLED` | boolean | true | — |
| `MAX_DAILY_AI_COST_USD` | number | 50 | min 0 |
| `MAX_MONTHLY_AI_COST_USD` | number | 1500 | min 0 |
| `DRAFT_EXPIRY_DAYS` | number | 7 | 1~30 |
| `LOG_LEVEL` | enum | `info` | debug/info/warn/error |
| `WORKER_RUNTIME` | enum | `node` | node/edge/cron |

### 3.2 zod 스키마 정의 패턴

`lib/env.ts`의 권장 패턴:

```typescript
import { z } from 'zod';

const envSchema = z.object({
  // Anthropic
  ANTHROPIC_API_KEY: z.string().min(20),
  ANTHROPIC_MODEL_OPUS: z.literal('claude-opus-4-7'),
  ANTHROPIC_MODEL_HAIKU: z.literal('claude-haiku-4-5-20251001'),
  ANTHROPIC_MODEL_SONNET: z.literal('claude-sonnet-4-6'),

  // Supabase
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(20),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
  SUPABASE_DB_URL: z.string().url(),
  SUPABASE_STORAGE_BUCKET_ATTACHMENTS: z.string().default('communications-attachments'),

  // OpenAI
  OPENAI_API_KEY: z.string().min(20),
  OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-large'),

  // TABS Mailer 4
  TABS_MAILER_HOST: z.string().min(1),
  TABS_MAILER_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  TABS_MAILER_AUTH_METHOD: z.enum(['plain', 'login', 'ip_whitelist']),
  TABS_MAILER_USERNAME: z.string().optional(),
  TABS_MAILER_PASSWORD: z.string().optional(),
  TABS_MAILER_USE_TLS: z.coerce.boolean().default(true),
  TABS_MAILER_FROM_DOMAIN: z.string().min(1),

  // MailCarrier 7
  MAILCARRIER_HOST: z.string().min(1),
  MAILCARRIER_PORT: z.coerce.number().int().min(1).max(65535).default(993),
  MAILCARRIER_USERNAME: z.string().min(1),
  MAILCARRIER_PASSWORD: z.string().min(1),
  MAILCARRIER_USE_IDLE: z.coerce.boolean().default(true),
  MAILCARRIER_INBOX_FOLDER: z.string().default('INBOX'),
  MAILCARRIER_POLL_INTERVAL_SECONDS: z.coerce.number().int().min(5).default(30),

  // Business
  AI_AUTO_SEND_ENABLED: z.coerce.boolean().default(false),
  SCRAPING_ENABLED: z.coerce.boolean().default(true),
  MAX_DAILY_AI_COST_USD: z.coerce.number().nonnegative().default(50),
  MAX_MONTHLY_AI_COST_USD: z.coerce.number().nonnegative().default(1500),
  DRAFT_EXPIRY_DAYS: z.coerce.number().int().min(1).max(30).default(7),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  WORKER_RUNTIME: z.enum(['node', 'edge', 'cron']).default('node'),
}).superRefine((data, ctx) => {
  // 조건부 필수: auth_method가 ip_whitelist가 아닐 때 username/password 필수
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
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Environment validation failed:');
  console.error(parsed.error.format());
  throw new Error('Invalid environment configuration');
}

export const env = parsed.data;
export type Env = typeof env;
```

### 3.3 시크릿 관리

- `.env.local` 파일은 git에 커밋하지 않음 (.gitignore)
- 운영 환경: Vercel / Render / Supabase의 환경변수 UI 사용
- 시크릿 회전 주기:
  - `ANTHROPIC_API_KEY`: 90일
  - `OPENAI_API_KEY`: 90일
  - `SUPABASE_SERVICE_ROLE_KEY`: 회전 어려우므로 노출 차단 우선
  - `TABS_MAILER_PASSWORD`, `MAILCARRIER_PASSWORD`: 60일
- 모든 시크릿은 로그에 절대 출력 금지 (`logger.ts`에서 자동 마스킹 패턴)

### 3.4 환경별 설정 분기

| 환경 | `NODE_ENV` | `AI_AUTO_SEND_ENABLED` | `LOG_LEVEL` | `WORKER_RUNTIME` |
|------|-----------|----------------------|-------------|------------------|
| dev (로컬) | development | false | debug | node |
| preview (PR) | production | false | info | node |
| staging | production | false | info | node |
| production | production | **운영자가 의도적으로 토글** | info | cron |

운영 시작 시점에는 `AI_AUTO_SEND_ENABLED=false`를 유지하고, 충분한 사람 검토 데이터(2~4주)가 쌓인 뒤에야 카테고리별로 점진 활성화한다.

---

## 4. 모듈 A — Claude Client (lib/ai/)

본 모듈은 Anthropic API의 단일 진입점이다. 모든 AI 호출은 이 모듈을 거쳐야 ai.runs에 기록되고 PII 마스킹·비용 추적이 일관되게 적용된다.

### 4.1 책임과 비책임

**책임**:
- Anthropic API 호출 (텍스트 완성)
- 모델 ID 검증 (claude-opus-4-7 / claude-haiku-4-5-20251001 / claude-sonnet-4-6 만 허용)
- 재시도 (429·5xx에 exponential backoff)
- 타임아웃 (60초 hard timeout)
- PII 마스킹·복원
- 비용·토큰 계산 → ai.runs INSERT
- prompt-renderer 호출 (컨텍스트 번들 합성)
- 일일·월간 예산 한도 강제

**비책임**:
- UI에서 사용자에게 결과 표시 (호출자가 처리)
- knowledge_chunks의 임베딩 생성 (별도 인덱싱 작업)
- ai.drafts 행 생성 (processor.ts의 책임)

### 4.2 ClaudeClient 인터페이스

```typescript
// lib/ai/claude-client.ts

import Anthropic from '@anthropic-ai/sdk';
import { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import type {
  AgentRole, AgentRow, ClaudeModel,
  ClaudeCompleteInput, ClaudeCompleteOutput,
  ClassificationOutput, ReplyDrafterOutput,
} from '@/types/ai';
import { maskPii, restorePii, type PiiTokenMap } from './pii-masker';
import { renderPrompt } from './prompt-renderer';
import { calculateCost, recordRun, checkDailyBudget } from './cost-tracker';

export class ClaudeApiError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
    public readonly retryAfter?: number,
    public readonly cause?: unknown,
  ) {
    super(message);
    this.name = 'ClaudeApiError';
  }
}

export class ClaudeBudgetExceededError extends Error {
  constructor(
    public readonly used: number,
    public readonly limit: number,
    public readonly period: 'daily' | 'monthly',
  ) {
    super(`Budget exceeded for ${period}: ${used.toFixed(2)} / ${limit.toFixed(2)} USD`);
    this.name = 'ClaudeBudgetExceededError';
  }
}

export class ClaudeInvalidModelError extends Error {
  constructor(public readonly model: string) {
    super(`Unsupported Claude model: ${model}`);
    this.name = 'ClaudeInvalidModelError';
  }
}

const SUPPORTED_MODELS: ReadonlySet<ClaudeModel> = new Set([
  'claude-opus-4-7',
  'claude-sonnet-4-6',
  'claude-haiku-4-5-20251001',
]);

export class ClaudeClient {
  private readonly anthropic: Anthropic;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
  ) {
    this.anthropic = new Anthropic({
      apiKey: env.ANTHROPIC_API_KEY,
      maxRetries: 0, // SDK 재시도 비활성화 — 본 모듈에서 직접 제어
      timeout: 60_000,
    });
  }

  async complete(input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> {
    // 1. 일일 예산 체크
    const budget = await checkDailyBudget(this.supabase, this.organizationId);
    if (!budget.allowed) {
      throw new ClaudeBudgetExceededError(budget.used, budget.limit, 'daily');
    }

    // 2. agent 조회
    const agent = await this.loadAgent(input.agentRole, input.language);
    if (!SUPPORTED_MODELS.has(agent.model as ClaudeModel)) {
      throw new ClaudeInvalidModelError(agent.model);
    }

    // 3. PII 마스킹
    const maskPiiEnabled = input.maskPii ?? agent.requirePiiMasking ?? true;
    const { masked: maskedInbound, tokens, categories } = maskPiiEnabled
      ? maskPii(input.inboundMessage)
      : { masked: input.inboundMessage, tokens: new Map() as PiiTokenMap, categories: [] };

    // 4. 프롬프트 렌더
    const rendered = await renderPrompt({
      supabase: this.supabase,
      organizationId: this.organizationId,
      agent,
      partyId: input.partyId,
      engagementId: input.engagementId,
      inboundMessage: maskedInbound,
      language: input.language,
    });

    // 5. API 호출 (재시도 포함)
    const startedAt = Date.now();
    let attempt = 0;
    let modelUsed: ClaudeModel = agent.model as ClaudeModel;
    let lastError: unknown;
    let response: Anthropic.Messages.Message | null = null;

    while (attempt < 3 && response === null) {
      try {
        response = await this.anthropic.messages.create({
          model: modelUsed,
          max_tokens: agent.maxTokens ?? 4096,
          temperature: agent.temperature ?? 0.30,
          system: rendered.system,
          messages: rendered.messages,
        });
      } catch (err) {
        lastError = err;
        const apiError = this.normalizeError(err);

        // 재시도 가능 여부 판단
        const isRetryable = apiError.status !== undefined
          && (apiError.status === 429 || apiError.status >= 500);

        if (!isRetryable) {
          break;
        }

        // 마지막 시도에서 fallback 모델 사용 (1회)
        if (attempt === 1 && agent.fallbackModel
            && SUPPORTED_MODELS.has(agent.fallbackModel as ClaudeModel)) {
          modelUsed = agent.fallbackModel as ClaudeModel;
        }

        const backoffMs = (apiError.retryAfter ?? Math.pow(2, attempt)) * 1000;
        await new Promise((r) => setTimeout(r, backoffMs));
        attempt += 1;
      }
    }

    const latencyMs = Date.now() - startedAt;

    // 6. 실패 처리
    if (response === null) {
      const apiError = this.normalizeError(lastError);
      await recordRun(this.supabase, this.organizationId, {
        agentId: agent.id,
        status: 'failed',
        model: modelUsed,
        tokensIn: 0,
        tokensOut: 0,
        costUsd: 0,
        latencyMs,
        piiMasked: maskPiiEnabled,
        piiCategories: categories,
        errorMessage: apiError.message,
        errorStatus: apiError.status,
        retryCount: attempt,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw apiError;
    }

    // 7. 응답 추출 + PII 복원
    const rawContent = response.content
      .filter((block): block is Anthropic.TextBlock => block.type === 'text')
      .map((block) => block.text)
      .join('\n');
    const content = maskPiiEnabled ? restorePii(rawContent, tokens) : rawContent;

    // 8. JSON 파싱 (output_format='structured' 또는 'json')
    let parsedJson: object | undefined;
    if (input.outputFormat === 'json' || agent.outputFormat === 'structured') {
      try {
        // ```json fence 제거
        const cleaned = content.replace(/```json\s*|\s*```/g, '').trim();
        parsedJson = JSON.parse(cleaned);
      } catch {
        // JSON 파싱 실패는 호출자가 처리 (raw content 반환)
      }
    }

    // 9. 비용·토큰 계산 + ai.runs INSERT
    const tokensIn = response.usage.input_tokens;
    const tokensOut = response.usage.output_tokens;
    const costUsd = calculateCost(modelUsed, tokensIn, tokensOut);

    const runId = await recordRun(this.supabase, this.organizationId, {
      agentId: agent.id,
      status: 'success',
      model: modelUsed,
      tokensIn,
      tokensOut,
      costUsd,
      latencyMs,
      piiMasked: maskPiiEnabled,
      piiCategories: categories,
      retryCount: attempt,
      partyId: input.partyId,
      engagementId: input.engagementId,
      brandVoiceId: rendered.metadata.brandVoiceId,
      knowledgeChunkIds: rendered.metadata.knowledgeChunkIds,
    });

    return {
      content,
      parsedJson,
      runId,
      model: modelUsed,
      latencyMs,
      tokensIn,
      tokensOut,
      costUsd,
    };
  }

  private async loadAgent(role: AgentRole, language?: string): Promise<AgentRow> {
    const { data, error } = await this.supabase
      .from('agents')
      .select('*')
      .eq('organization_id', this.organizationId)
      .eq('role', role)
      .eq('is_active', true)
      .order('version', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error || !data) {
      throw new ClaudeApiError(
        `Agent not found: role=${role} organization=${this.organizationId}`,
      );
    }
    return data as unknown as AgentRow;
  }

  private normalizeError(err: unknown): ClaudeApiError {
    if (err instanceof ClaudeApiError) return err;
    if (err instanceof Anthropic.APIError) {
      return new ClaudeApiError(
        err.message,
        err.status,
        Number(err.headers?.['retry-after']) || undefined,
        err,
      );
    }
    if (err instanceof Error) {
      return new ClaudeApiError(err.message, undefined, undefined, err);
    }
    return new ClaudeApiError(String(err));
  }
}
```

### 4.3 재시도·타임아웃·서킷 브레이커

#### 4.3.1 재시도 정책

| 상태 코드 | 처리 |
|-----------|------|
| 200 | 성공, 즉시 반환 |
| 400 (Bad Request) | 즉시 throw — 재시도 불가 |
| 401 (Unauthorized) | 즉시 throw — API 키 점검 필요 |
| 429 (Rate Limit) | `Retry-After` 헤더 우선, 없으면 exponential backoff (1s, 2s, 4s) |
| 500/502/503/504 | exponential backoff (1s, 2s, 4s) |
| 기타 5xx | exponential backoff |

최대 재시도 3회. 2회차에 fallback 모델로 전환 (예: opus → sonnet).

#### 4.3.2 타임아웃

- 단건 호출: 60초 (AbortController, SDK 옵션)
- 전체 complete() 메서드 (재시도 포함): 약 80초 한계 (60s + 백오프 누적)
- 60초 초과 시 `ClaudeApiError` with status undefined·`cause: TimeoutError`

#### 4.3.3 서킷 브레이커 (선택, 운영 후 추가 권장)

본 STEP 3 범위에서는 미구현. STEP 7 운영 시작 후 다음 패턴 추가:
- 최근 1분간 5xx 비율 > 50% 시 회로 OPEN (모든 호출 즉시 throw)
- 30초 후 HALF_OPEN (1건만 허용)
- 성공 시 CLOSED 복귀

라이브러리: `opossum` 또는 자체 구현.

### 4.4 비용·토큰 추적 → ai.runs

#### 4.4.1 단가 테이블

```typescript
// lib/ai/cost-tracker.ts

import type { ClaudeModel } from '@/types/ai';

export const MODEL_PRICING: Readonly<Record<ClaudeModel, { input: number; output: number }>> = {
  'claude-opus-4-7':           { input: 15.00, output: 75.00 },
  'claude-sonnet-4-6':         { input:  3.00, output: 15.00 },
  'claude-haiku-4-5-20251001': { input:  0.80, output:  4.00 },
};

export function calculateCost(
  model: ClaudeModel,
  tokensIn: number,
  tokensOut: number,
): number {
  const pricing = MODEL_PRICING[model];
  if (!pricing) {
    throw new Error(`No pricing defined for model: ${model}`);
  }
  // 단가는 per 1M tokens
  return (tokensIn * pricing.input + tokensOut * pricing.output) / 1_000_000;
}
```

#### 4.4.2 ai.runs 기록 패턴

성공·재시도·실패 모든 경로에서 record:

```typescript
export interface RecordRunInput {
  agentId: string;
  status: 'success' | 'failed' | 'timeout' | 'budget_exceeded';
  model: string;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
  latencyMs: number;
  piiMasked: boolean;
  piiCategories: string[];
  retryCount: number;
  partyId?: string;
  engagementId?: string;
  brandVoiceId?: string;
  knowledgeChunkIds?: string[];
  errorMessage?: string;
  errorStatus?: number;
}

export async function recordRun(
  supabase: SupabaseClient,
  organizationId: string,
  input: RecordRunInput,
): Promise<string> {
  const { data, error } = await supabase
    .from('runs')
    .insert({
      organization_id: organizationId,
      agent_id: input.agentId,
      status: input.status,
      model: input.model,
      tokens_in: input.tokensIn,
      tokens_out: input.tokensOut,
      cost_usd: input.costUsd,
      latency_ms: input.latencyMs,
      pii_masked: input.piiMasked,
      pii_categories_detected: input.piiCategories,
      retry_count: input.retryCount,
      party_id: input.partyId ?? null,
      engagement_id: input.engagementId ?? null,
      brand_voice_id: input.brandVoiceId ?? null,
      knowledge_chunk_ids: input.knowledgeChunkIds ?? [],
      error_message: input.errorMessage ?? null,
      error_status: input.errorStatus ?? null,
    })
    .select('id')
    .single();

  if (error || !data) {
    // ai.runs INSERT 실패는 절대 실리지 않게 — fallback 로깅만
    console.error('[recordRun] failed to insert ai.runs:', error);
    return '';
  }
  return data.id;
}
```

#### 4.4.3 일일·월간 예산 체크

```typescript
export async function checkDailyBudget(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<{ used: number; limit: number; allowed: boolean }> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const { data, error } = await supabase
    .from('runs')
    .select('cost_usd')
    .eq('organization_id', organizationId)
    .gte('created_at', today.toISOString());

  if (error) {
    // 조회 실패 시 안전하게 차단 vs 통과 — 운영 정책에 따라 결정
    // 본 가이드는 "차단" 권장 (예산 보호 우선)
    return { used: 0, limit: env.MAX_DAILY_AI_COST_USD, allowed: false };
  }

  const used = (data ?? []).reduce((sum, row) => sum + Number(row.cost_usd ?? 0), 0);
  const limit = env.MAX_DAILY_AI_COST_USD;

  return { used, limit, allowed: used < limit };
}
```

### 4.5 PII 마스킹·복원 워크플로

#### 4.5.1 마스킹 시점

- **AI 호출 직전**: claude-client가 inboundMessage에 대해 maskPii() 호출
- **DB 저장 직전 (선택)**: mailcarrier 수신 시 communications.body에 사전 마스킹
- **로깅 직전**: logger가 자동 마스킹 (구현은 별도)

#### 4.5.2 토큰 형식

`{{PII_001}}`, `{{PII_002}}` 순차. 토큰 맵은 호출 단위로 메모리에 유지하고 응답 직후 폐기.

```typescript
// lib/ai/pii-masker.ts

export type PiiTokenMap = Map<string, string>;

export interface MaskResult {
  masked: string;
  tokens: PiiTokenMap;
  categories: string[];
}

const PATTERNS: Array<{ name: string; regex: RegExp }> = [
  { name: 'national_id_kr', regex: /\b\d{6}-?[1-4]\d{6}\b/g },
  { name: 'phone_kr',       regex: /\b01[0-9]-?\d{3,4}-?\d{4}\b/g },
  { name: 'phone_intl',     regex: /\+\d{1,3}[\s-]?\d{2,4}[\s-]?\d{2,4}[\s-]?\d{2,4}/g },
  { name: 'email',          regex: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g },
  { name: 'credit_card',    regex: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g },
  { name: 'business_id_kr', regex: /\b\d{3}-?\d{2}-?\d{5}\b/g },
  { name: 'passport',       regex: /\b[A-Z]\d{8}\b/g },
];

export function maskPii(text: string): MaskResult {
  const tokens: PiiTokenMap = new Map();
  const categories = new Set<string>();
  let counter = 0;
  let masked = text;

  for (const { name, regex } of PATTERNS) {
    masked = masked.replace(regex, (match) => {
      counter += 1;
      const token = `{{PII_${String(counter).padStart(3, '0')}}}`;
      tokens.set(token, match);
      categories.add(name);
      return token;
    });
  }

  return {
    masked,
    tokens,
    categories: Array.from(categories),
  };
}

export function restorePii(text: string, tokens: PiiTokenMap): string {
  let restored = text;
  for (const [token, original] of tokens) {
    restored = restored.replaceAll(token, original);
  }
  return restored;
}
```

#### 4.5.3 한계와 보완

본 정규식 기반 마스킹은 best-effort:
- 변형 표기 (010 1234 5678, 010.1234.5678 등) 일부 누락
- 외국 형식 주소·계좌번호 미포함
- 향후 NER 모델·Microsoft Presidio 도입 검토

### 4.6 prompt-renderer (brand_voice·knowledge_chunks 합성)

`lib/ai/prompt-renderer.ts`는 ClaudeClient의 입력을 구조화 컨텍스트 번들로 변환한다. STEP 1·2의 `ai.brand_voice` (모듈·언어별)와 `ai.knowledge_chunks` (vector 검색)를 활용.

```typescript
import type Anthropic from '@anthropic-ai/sdk';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { AgentRow } from '@/types/ai';

export interface RenderInput {
  supabase: SupabaseClient;
  organizationId: string;
  agent: AgentRow;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: 'ko' | 'en' | 'ja';
}

export interface RenderedPrompt {
  system: string;
  messages: Anthropic.MessageParam[];
  metadata: {
    brandVoiceId?: string;
    knowledgeChunkIds: string[];
    threadIds: string[];
  };
}

export async function renderPrompt(input: RenderInput): Promise<RenderedPrompt> {
  const { supabase, organizationId, agent, partyId, inboundMessage, language } = input;

  // 1. brand_voice 조회 (agent.applicable_modules[0] 매칭)
  const moduleType = agent.applicableModules?.[0];
  let brandVoice = null;
  if (moduleType && language) {
    const { data } = await supabase
      .from('brand_voice')
      .select('id, tone_guidelines, do_say, dont_say, glossary, few_shot_examples')
      .eq('organization_id', organizationId)
      .eq('module', moduleType)
      .eq('language', language)
      .eq('is_active', true)
      .maybeSingle();
    brandVoice = data;
  }

  // 2. party 컨텍스트 (옵션)
  let party = null;
  if (partyId) {
    const { data } = await supabase
      .from('parties')
      .select('id, name, module, tier, country_code, industry_tags, module_data')
      .eq('id', partyId)
      .maybeSingle();
    party = data;
  }

  // 3. knowledge_chunks (cosine top_k=8)
  // 임베딩 생성은 별도 OpenAI 호출 또는 캐시
  const queryEmbedding = await embedQuery(inboundMessage); // 별도 함수
  const { data: chunks } = await supabase
    .rpc('search_knowledge', {
      p_organization_id: organizationId,
      p_query_embedding: queryEmbedding,
      p_collection: agent.knowledgeCollection ?? null,
      p_limit: 8,
      p_min_similarity: 0.65,
    });

  // 4. 최근 thread (party_id 기준 5개)
  let threadHistory: any[] = [];
  if (partyId) {
    const { data } = await supabase
      .from('communications')
      .select('id, direction, subject, body_text, sent_at, received_at, thread_id')
      .eq('party_id', partyId)
      .order('created_at', { ascending: false })
      .limit(5);
    threadHistory = data ?? [];
  }

  // 5. 컨텍스트 번들 합성
  const contextBundle = {
    inbound_message: inboundMessage,
    party_context: party,
    brand_voice: brandVoice,
    knowledge_chunks: (chunks ?? []).map((c: any) => ({
      id: c.id,
      content: c.content,
      similarity: c.similarity,
      source_type: c.source_type,
    })),
    thread_history: threadHistory.map((t) => ({
      direction: t.direction,
      subject: t.subject,
      excerpt: (t.body_text ?? '').slice(0, 500),
      sent_at: t.sent_at ?? t.received_at,
    })),
  };

  return {
    system: agent.systemPrompt,
    messages: [
      {
        role: 'user',
        content: JSON.stringify(contextBundle, null, 2),
      },
    ],
    metadata: {
      brandVoiceId: brandVoice?.id,
      knowledgeChunkIds: (chunks ?? []).map((c: any) => c.id),
      threadIds: threadHistory.map((t) => t.thread_id).filter(Boolean),
    },
  };
}

async function embedQuery(text: string): Promise<number[]> {
  // OpenAI embeddings 호출 — 별도 캐시 권장
  // 본 가이드 범위 외 (lib/ai/embeddings.ts에서 처리)
  throw new Error('embedQuery: implement separately in lib/ai/embeddings.ts');
}
```

### 4.7 에러 분류·다운스트림 처리

| 에러 클래스 | 발생 조건 | 호출자(processor.ts) 처리 |
|-------------|----------|---------------------------|
| `ClaudeApiError` (status 4xx) | 잘못된 요청, 인증 실패 | 즉시 ai.drafts에 `requires_human_approval=true` 강제 + admin alert |
| `ClaudeApiError` (status 5xx, 재시도 후) | API 장애 | communications.ai_processing_status='failed' + 1시간 후 재시도 큐 |
| `ClaudeApiError` (timeout) | 60초 초과 | 동일 |
| `ClaudeBudgetExceededError` | 예산 초과 | 즉시 admin alert + 작업 중단 (운영자 결정 대기) |
| `ClaudeInvalidModelError` | 모델 ID 검증 실패 | 즉시 throw + alert (시드 데이터 오염 의심) |

각 에러는 `console.error` 또는 `logger.error`로 구조화 로그 기록. `ai.runs.error_message`에도 사유 명시.

---

## 5. 모듈 B — TABS Mailer 4 어댑터

본 모듈은 외부 SMTP 발송 시스템(TABS Mailer 4)과의 단일 통합점이다. 발송 자체는 외부 시스템이 수행하고, 본 어댑터는 캠페인 등록·헤더 부착·통계 동기화를 담당한다.

### 5.1 책임과 비책임

**책임**:
- SMTP 인증 (PLAIN / LOGIN / IP whitelist 분기)
- 발송 (단건·캠페인)
- 사용자 정의 헤더 부착 (X-URM-*)
- Quiet hours·rate limit 클라이언트 측 검증
- 통계 동기화 → mail_merge_jobs.progress

**비책임**:
- TABS Mailer 4의 내부 큐·전송 정책
- bounces·complaints 처리 (운영 시점에 별도)
- 수신자 unsubscribe 관리 (별도 모듈)

### 5.2 TabsMailerClient 인터페이스

```typescript
// lib/email/tabs-mailer.ts

import nodemailer, { Transporter } from 'nodemailer';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

export class TabsMailerError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'TabsMailerError';
  }
}
export class TabsMailerAuthError extends TabsMailerError {}
export class TabsMailerQuietHoursError extends TabsMailerError {}

export interface SendOneInput {
  to: { name?: string; address: string };
  cc?: { name?: string; address: string }[];
  fromName: string;
  fromAddress: string;
  replyTo?: string;
  subject: string;
  bodyText: string;
  bodyHtml?: string;
  urmHeaders: {
    engagementId?: string;
    communicationId: string;
    autoSend: boolean;
    brandVoiceId?: string;
  };
  attachments?: Array<{ filename: string; content: Buffer; contentType?: string }>;
}

export interface SendOneOutput {
  messageId: string;
  acceptedRecipients: string[];
  rejectedRecipients: string[];
  rawResponse: string;
}

export interface CampaignParams {
  name: string;
  description?: string;
  templateId: string;
  scheduledAt?: Date;
  recipientCount: number;
}

export interface TabsCampaignStats {
  tabsCampaignId: string;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalBounced: number;
  totalUnsubscribed: number;
  lastUpdatedAt: Date;
}

export class TabsMailerClient {
  private transporter: Transporter;

  constructor() {
    const config: Parameters<typeof nodemailer.createTransport>[0] = {
      host: env.TABS_MAILER_HOST,
      port: env.TABS_MAILER_PORT,
      secure: env.TABS_MAILER_USE_TLS,
    };

    // 인증 분기
    if (env.TABS_MAILER_AUTH_METHOD === 'plain' || env.TABS_MAILER_AUTH_METHOD === 'login') {
      config.auth = {
        type: 'login',
        user: env.TABS_MAILER_USERNAME!,
        pass: env.TABS_MAILER_PASSWORD!,
      };
    }
    // ip_whitelist는 auth 미지정 — TABS 측에서 IP 검증

    this.transporter = nodemailer.createTransport(config);
  }

  async verify(): Promise<void> {
    try {
      await this.transporter.verify();
    } catch (err) {
      throw new TabsMailerAuthError(
        `TABS Mailer connection/auth failed: ${(err as Error).message}`,
        err,
      );
    }
  }

  async sendOne(input: SendOneInput): Promise<SendOneOutput> {
    const headers: Record<string, string> = {
      'X-URM-Communication-Id': input.urmHeaders.communicationId,
      'X-URM-Auto-Send': input.urmHeaders.autoSend ? 'true' : 'false',
    };
    if (input.urmHeaders.engagementId) {
      headers['X-URM-Engagement-Id'] = input.urmHeaders.engagementId;
    }
    if (input.urmHeaders.brandVoiceId) {
      headers['X-URM-Brand-Voice-Id'] = input.urmHeaders.brandVoiceId;
    }

    try {
      const info = await this.transporter.sendMail({
        from: { name: input.fromName, address: input.fromAddress },
        to: input.to,
        cc: input.cc,
        replyTo: input.replyTo,
        subject: input.subject,
        text: input.bodyText,
        html: input.bodyHtml,
        attachments: input.attachments,
        headers,
      });

      return {
        messageId: info.messageId,
        acceptedRecipients: info.accepted as string[],
        rejectedRecipients: info.rejected as string[],
        rawResponse: info.response,
      };
    } catch (err) {
      throw new TabsMailerError(`sendOne failed: ${(err as Error).message}`, err);
    }
  }

  async createCampaign(params: CampaignParams): Promise<{ tabsCampaignId: string }> {
    // TABS Mailer 4의 캠페인 등록 API — 외부 명세 수령 시 구현
    // 본 가이드는 인터페이스만 제시
    throw new TabsMailerError(
      'createCampaign: pending TABS Mailer 4 API specification from 탭스랩',
    );
  }

  async getCampaignStats(tabsCampaignId: string): Promise<TabsCampaignStats> {
    // TABS Mailer 4 통계 API 또는 MS SQL 직접 조회
    throw new TabsMailerError(
      'getCampaignStats: pending TABS Mailer 4 stats DB schema from 탭스랩',
    );
  }

  async syncCampaignToMergeJob(
    supabase: SupabaseClient,
    organizationId: string,
    jobId: string,
  ): Promise<void> {
    const { data: job, error } = await supabase
      .from('mail_merge_jobs')
      .select('id, tabs_campaign_id')
      .eq('id', jobId)
      .eq('organization_id', organizationId)
      .single();

    if (error || !job?.tabs_campaign_id) {
      throw new TabsMailerError(`Cannot sync: job ${jobId} has no tabs_campaign_id`);
    }

    const stats = await this.getCampaignStats(job.tabs_campaign_id);

    await supabase
      .from('mail_merge_jobs')
      .update({
        progress: {
          sent: stats.totalSent,
          delivered: stats.totalDelivered,
          opened: stats.totalOpened,
          clicked: stats.totalClicked,
          bounced: stats.totalBounced,
          unsubscribed: stats.totalUnsubscribed,
        },
        tabs_campaign_status: 'synced',
        tabs_campaign_synced_at: new Date().toISOString(),
      })
      .eq('id', jobId);
  }
}
```

### 5.3 캠페인 라이프사이클

mail_merge_jobs 행 1건 = TABS Mailer 4 캠페인 1건 매핑. 상태 전이:

```
draft → queued → running → completed
                 ↓
                 paused (운영자 수동) → running 재개
                 ↓
                 cancelled (운영자 수동, 환불 정책 별도)
                 ↓
                 failed (TABS 측 오류, retry_count·max_retries 따라 재시도)
```

### 5.4 사용자 정의 헤더 (X-URM-*)

부착되는 헤더 4종:
- `X-URM-Engagement-Id`: 인게이지먼트 UUID (스레드 추적·수신 메일 연결)
- `X-URM-Communication-Id`: 발신 communications 행 UUID
- `X-URM-Auto-Send`: `true`/`false` — 자동발송 게이트 통과 여부
- `X-URM-Brand-Voice-Id`: 사용된 brand_voice 행 UUID (학습 루프용)

**TABS Mailer 4가 헤더를 통과시키는지 미확인 시 대응**:
- Mock 환경에서는 항상 통과 가정
- 운영 시 첫 메일 수신 후 헤더 보존 여부 검증 (mailcarrier에서 raw headers 로깅 → 비교)
- 헤더 손실 시 fallback: Message-ID 기반 매칭 + 메일 본문 끝에 invisible footer (예: `<!-- urm:c=<comm_id> -->`)

### 5.5 Quiet hours·rate limit

#### 5.5.1 Quiet hours

`mail_merge_jobs.quiet_hours` jsonb 형식:
```json
{
  "timezone": "Asia/Seoul",
  "start": "22:00",
  "end": "08:00",
  "weekends_blocked": true
}
```

발송 시점에 `isWithinQuietHours(now, quietHours)` 검증:
- true → `mail-merge-worker`가 `next_send_at`을 다음 가능 시각으로 미루고 큐 재등록
- 즉시 발송 호출(sendOne 직접) 시 `TabsMailerQuietHoursError` throw

```typescript
function isWithinQuietHours(now: Date, qh: QuietHours): boolean {
  const localTime = toZonedTime(now, qh.timezone);
  const day = localTime.getDay(); // 0=Sunday, 6=Saturday
  if (qh.weekends_blocked && (day === 0 || day === 6)) return true;

  const hh = localTime.getHours();
  const mm = localTime.getMinutes();
  const totalMinutes = hh * 60 + mm;

  const [startH, startM] = qh.start.split(':').map(Number);
  const [endH, endM] = qh.end.split(':').map(Number);
  const startMin = startH * 60 + startM;
  const endMin = endH * 60 + endM;

  // 자정을 넘는 경우 (예: 22:00 → 08:00)
  if (startMin > endMin) {
    return totalMinutes >= startMin || totalMinutes < endMin;
  }
  return totalMinutes >= startMin && totalMinutes < endMin;
}
```

#### 5.5.2 Rate limit

`mail_merge_jobs.rate_limit_per_hour` 및 `rate_limit_per_minute` 준수:
- 워커가 발송 시점에 최근 1분·1시간 내 발송 카운트를 communications에서 집계
- 한도 도달 시 다음 분/시간으로 미루기

### 5.6 통계 동기화 → mail_merge_jobs.progress

TABS Mailer 4의 통계는 외부 시스템(MS SQL Server)에 보관됨. 주기 동기화:
- 운영 중 캠페인: 5분마다 동기화
- 완료된 캠페인: 24시간 후 1회 최종 동기화 후 종료

### 5.7 Mock 어댑터 (운영 정보 미수령 시)

`lib/email/tabs-mailer.mock.ts`:
- `sendOne()`: 콘솔 출력 + `messageId: 'mock-{uuid}@local'` 반환
- `createCampaign()`: 가짜 ID 생성
- `getCampaignStats()`: 임의 통계 (랜덤 또는 고정값)
- env 분기: `TABS_MAILER_HOST === 'mock'` 시 자동 주입

테스트 환경과 dev 환경에서 실 SMTP 호출 없이 파이프라인 검증 가능.

---

## 6. 모듈 C — MailCarrier 7 어댑터

본 모듈은 외부 IMAP 시스템(MailCarrier 7)에서 메일을 수신해 communications에 저장하고 processor.ts로 전달한다.

### 6.1 책임과 비책임

**책임**:
- IMAP 연결·인증 (TLS 우선)
- IDLE 또는 폴링 기반 신규 메일 감지
- mailparser로 raw → ParsedMail 변환
- header-parser로 thread 매칭
- 첨부 추출 → Supabase Storage 업로드
- communications + attachments INSERT
- processor.ts에 처리 위임 (큐 또는 직접 호출)

**비책임**:
- 메일 분류·회신 초안 생성 (processor.ts)
- 폴더 정리·아카이빙 (운영 정책)
- IMAP 서버 자체 모니터링

### 6.2 MailCarrierClient 인터페이스

```typescript
// lib/email/mailcarrier.ts

import { ImapFlow } from 'imapflow';
import { simpleParser, ParsedMail } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { parseInboundMessage, findThreadId } from './header-parser';
import { maskPii } from '../ai/pii-masker';

export class MailCarrierError extends Error {}

export interface InboundMessage {
  communicationId: string;
  threadId: string;
  messageId: string;
  organizationId: string;
}

export class MailCarrierClient {
  private client: ImapFlow;
  private isRunning = false;
  private reconnectAttempts = 0;
  private readonly MAX_RECONNECT = 5;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
  ) {
    this.client = new ImapFlow({
      host: env.MAILCARRIER_HOST,
      port: env.MAILCARRIER_PORT,
      secure: env.MAILCARRIER_PORT === 993,
      auth: {
        user: env.MAILCARRIER_USERNAME,
        pass: env.MAILCARRIER_PASSWORD,
      },
      logger: false, // env.LOG_LEVEL과 연동 시 별도 어댑터
    });
  }

  async connect(): Promise<void> {
    try {
      await this.client.connect();
      await this.client.mailboxOpen(env.MAILCARRIER_INBOX_FOLDER);
      this.reconnectAttempts = 0;
    } catch (err) {
      throw new MailCarrierError(
        `IMAP connection failed: ${(err as Error).message}`,
      );
    }
  }

  async startListening(
    onMessage: (msg: InboundMessage) => Promise<void>,
  ): Promise<void> {
    if (this.isRunning) {
      throw new MailCarrierError('Listener is already running');
    }
    this.isRunning = true;

    if (env.MAILCARRIER_USE_IDLE) {
      await this.runIdleLoop(onMessage);
    } else {
      await this.runPollingLoop(onMessage);
    }
  }

  async stop(): Promise<void> {
    this.isRunning = false;
    try {
      await this.client.logout();
    } catch {
      // 무시 — 강제 종료 후속 처리
    }
  }

  private async runIdleLoop(
    onMessage: (msg: InboundMessage) => Promise<void>,
  ): Promise<void> {
    while (this.isRunning) {
      try {
        // 신규 메시지 처리
        await this.fetchAndProcessNew(onMessage);

        // IDLE 대기 (29분 한계 — 일부 IMAP 서버는 30분 후 끊음)
        await this.client.idle();
      } catch (err) {
        if (!this.isRunning) break;
        await this.handleReconnect();
      }
    }
  }

  private async runPollingLoop(
    onMessage: (msg: InboundMessage) => Promise<void>,
  ): Promise<void> {
    while (this.isRunning) {
      try {
        await this.fetchAndProcessNew(onMessage);
      } catch (err) {
        await this.handleReconnect();
      }
      await new Promise((r) =>
        setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
      );
    }
  }

  private async fetchAndProcessNew(
    onMessage: (msg: InboundMessage) => Promise<void>,
  ): Promise<void> {
    // UNSEEN 메시지만 가져오기
    const lock = await this.client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);
    try {
      for await (const message of this.client.fetch(
        { seen: false },
        { source: true, envelope: true },
      )) {
        try {
          const parsed = await simpleParser(message.source);
          const inbound = await this.persistInbound(parsed);
          if (inbound) {
            await onMessage(inbound);
            await this.client.messageFlagsAdd(message.uid, ['\\Seen']);
          }
        } catch (err) {
          // 단건 실패는 다른 메일 처리에 영향 없음
          // raw payload 별도 보존 (실패 큐에 — 본 가이드 범위 외)
          console.error('[mailcarrier] message processing failed:', err);
        }
      }
    } finally {
      lock.release();
    }
  }

  private async persistInbound(parsed: ParsedMail): Promise<InboundMessage | null> {
    const headers = parseInboundMessage(parsed);

    // 중복 체크 (Message-ID UNIQUE)
    const { data: existing } = await this.supabase
      .from('communications')
      .select('id')
      .eq('message_id', headers.messageId)
      .maybeSingle();
    if (existing) return null;

    // thread 매칭
    const existingThreadId = await findThreadId(this.supabase, this.organizationId, headers);
    const threadId = existingThreadId ?? crypto.randomUUID();

    // PII 사전 마스킹 (저장 직전, body만)
    const bodyText = parsed.text ?? '';
    const { masked: maskedBody, categories } = maskPii(bodyText);

    // communications INSERT
    const { data: comm, error: commError } = await this.supabase
      .from('communications')
      .insert({
        organization_id: this.organizationId,
        message_id: headers.messageId,
        thread_id: threadId,
        in_reply_to: headers.inReplyTo ?? null,
        direction: 'inbound',
        channel: 'email',
        from_address: headers.from.address,
        from_name: headers.from.name ?? null,
        to_addresses: headers.to.map((t) => t.address),
        subject: headers.subject,
        body_text: maskedBody,
        body_html: parsed.html || null,
        received_at: headers.date.toISOString(),
        external_data: {
          urm_headers: headers.urmHeaders,
          references: headers.references,
        },
        ai_processing_status: 'pending',
        pii_categories_detected: categories,
        pii_masked: true,
      })
      .select('id')
      .single();

    if (commError || !comm) {
      throw new MailCarrierError(
        `communications INSERT failed: ${commError?.message}`,
      );
    }

    // 첨부 처리
    for (const att of parsed.attachments ?? []) {
      await this.persistAttachment(comm.id, att);
    }

    return {
      communicationId: comm.id,
      threadId,
      messageId: headers.messageId,
      organizationId: this.organizationId,
    };
  }

  private async persistAttachment(commId: string, att: any): Promise<void> {
    const filename = att.filename ?? `attachment-${Date.now()}`;
    const path = `${this.organizationId}/${commId}/${filename}`;

    const { error: uploadError } = await this.supabase.storage
      .from(env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS)
      .upload(path, att.content, {
        contentType: att.contentType,
        upsert: false,
      });
    if (uploadError) {
      console.error('[mailcarrier] attachment upload failed:', uploadError);
      return;
    }

    await this.supabase.from('attachments').insert({
      organization_id: this.organizationId,
      entity_type: 'communication',
      entity_id: commId,
      filename,
      content_type: att.contentType,
      size_bytes: att.size,
      storage_path: path,
    });
  }

  private async handleReconnect(): Promise<void> {
    if (this.reconnectAttempts >= this.MAX_RECONNECT) {
      this.isRunning = false;
      throw new MailCarrierError(
        `Reconnect failed after ${this.MAX_RECONNECT} attempts`,
      );
    }
    this.reconnectAttempts += 1;
    const backoffMs = Math.pow(2, this.reconnectAttempts) * 1000;
    await new Promise((r) => setTimeout(r, backoffMs));
    try {
      await this.client.logout();
    } catch {/* ignore */}
    this.client = new ImapFlow({
      host: env.MAILCARRIER_HOST,
      port: env.MAILCARRIER_PORT,
      secure: env.MAILCARRIER_PORT === 993,
      auth: {
        user: env.MAILCARRIER_USERNAME,
        pass: env.MAILCARRIER_PASSWORD,
      },
      logger: false,
    });
    await this.connect();
  }
}
```

### 6.3 IMAP IDLE vs 폴링 폴백

**IDLE 사용 시**:
- 신규 메일 도착 즉시 알림 (지연 ~수초)
- 약 29분마다 IDLE 재시작 (서버 timeout 회피)
- 일부 IMAP 서버 (구식 설정) 미지원 → 폴링 폴백

**폴링 사용 시**:
- 30초 간격 (env로 조정)
- IDLE 미지원 환경의 안전한 기본
- 비용·트래픽 약간 더 (그러나 30초 단위는 무시 가능 수준)

### 6.4 헤더 파싱 (Message-ID·In-Reply-To·References)

`lib/email/header-parser.ts`:

```typescript
import type { ParsedMail } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';

export interface ParsedHeaders {
  messageId: string;
  inReplyTo?: string;
  references: string[];
  from: { name?: string; address: string };
  to: { name?: string; address: string }[];
  cc?: { name?: string; address: string }[];
  subject: string;
  date: Date;
  urmHeaders: {
    engagementId?: string;
    communicationId?: string;
    autoSend?: boolean;
    brandVoiceId?: string;
  };
}

export function parseInboundMessage(parsed: ParsedMail): ParsedHeaders {
  const messageId = parsed.messageId ?? `unknown-${Date.now()}@local`;

  // References: 공백 분리 + <...> 형태
  const referencesRaw = parsed.references;
  const references: string[] = Array.isArray(referencesRaw)
    ? referencesRaw
    : typeof referencesRaw === 'string'
      ? referencesRaw.split(/\s+/).filter(Boolean)
      : [];

  // X-URM-* 추출
  const urmHeaders: ParsedHeaders['urmHeaders'] = {};
  const headers = parsed.headers;
  const eng = headers.get('x-urm-engagement-id');
  const comm = headers.get('x-urm-communication-id');
  const autoSend = headers.get('x-urm-auto-send');
  const brandVoice = headers.get('x-urm-brand-voice-id');
  if (typeof eng === 'string')        urmHeaders.engagementId = eng;
  if (typeof comm === 'string')       urmHeaders.communicationId = comm;
  if (typeof autoSend === 'string')   urmHeaders.autoSend = autoSend.toLowerCase() === 'true';
  if (typeof brandVoice === 'string') urmHeaders.brandVoiceId = brandVoice;

  return {
    messageId,
    inReplyTo: parsed.inReplyTo,
    references,
    from: {
      name: parsed.from?.value[0]?.name,
      address: parsed.from?.value[0]?.address ?? 'unknown@unknown',
    },
    to: (parsed.to?.value ?? []).map((v) => ({ name: v.name, address: v.address ?? '' })),
    cc: parsed.cc?.value?.map((v) => ({ name: v.name, address: v.address ?? '' })),
    subject: parsed.subject ?? '(no subject)',
    date: parsed.date ?? new Date(),
    urmHeaders,
  };
}
```

### 6.5 스레드 매칭 알고리즘

```typescript
export async function findThreadId(
  supabase: SupabaseClient,
  organizationId: string,
  headers: ParsedHeaders,
): Promise<string | null> {
  // 1순위: X-URM-Communication-Id (자체 헤더)
  if (headers.urmHeaders.communicationId) {
    const { data } = await supabase
      .from('communications')
      .select('thread_id')
      .eq('id', headers.urmHeaders.communicationId)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (data?.thread_id) return data.thread_id;
  }

  // 2순위: In-Reply-To
  if (headers.inReplyTo) {
    const { data } = await supabase
      .from('communications')
      .select('thread_id')
      .eq('message_id', headers.inReplyTo)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (data?.thread_id) return data.thread_id;
  }

  // 3순위: References 역순
  for (const ref of [...headers.references].reverse()) {
    const { data } = await supabase
      .from('communications')
      .select('thread_id')
      .eq('message_id', ref)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (data?.thread_id) return data.thread_id;
  }

  return null;
}
```

### 6.6 첨부 처리·Supabase Storage

- 버킷: `communications-attachments` (env로 변경 가능)
- 경로: `{organization_id}/{communication_id}/{filename}`
- 5MB 초과 시 별도 처리 권장 (chunked upload, 본 가이드 범위 외)
- 바이러스 스캔: 운영 시점에 외부 서비스 통합 (clamav-server 등)

### 6.7 PII 사전 마스킹 (저장 전)

수신 메일의 본문은 communications에 저장되기 전에 PII 마스킹된다:
- 메일 본문 그대로 저장하지 않음 (감사·로그 노출 위험)
- 마스킹된 텍스트만 body_text에 저장
- 원본은 mailcarrier 호출 직후 메모리에서 폐기 (Anthropic 호출은 마스킹된 버전)
- 첨부는 마스킹 없이 Storage에 보관 (이진 파일이므로) — Storage 접근 권한으로 보호

---

## 7. 모듈 D — 메일 처리 파이프라인

`lib/email/processor.ts`와 `lib/email/auto-send-gate.ts`는 mailcarrier가 저장한 inbound communications를 AI로 처리해 ai.drafts를 생성하고 자동발송 가능 여부를 평가한다.

### 7.1 처리 단계 (5단계)

```
processInbound(communicationId) {
  [Step 1] communications 행 lock + 조회
  [Step 2] PII 사전 마스킹 (필요 시)
  [Step 3] 분류기 호출 (Haiku) → ClassificationOutput
  [Step 4] 회신가 호출 (Opus) → ReplyDrafterOutput
  [Step 5] auto-send-gate 평가
  [Step 6] ai.drafts INSERT + communications.ai_draft_id FK
}
```

### 7.2 분류기 호출·표준 10 카테고리 강제

```typescript
import { STANDARD_CATEGORIES } from '@/types/classification';

const result = await claudeClient.complete({
  agentRole: 'classifier',
  inboundMessage: comm.body_text,
  outputFormat: 'json',
  partyId: comm.party_id,
  engagementId: comm.engagement_id,
  language: comm.language ?? 'ko',
});

const classification = result.parsedJson as ClassificationOutput | undefined;
if (!classification) {
  throw new ProcessorError('Classifier returned non-JSON response');
}

// 표준 10 카테고리 검증 — 위반 시 'other'로 강제 + requires_human=true
if (!STANDARD_CATEGORIES.includes(classification.category as any)) {
  console.warn(
    `[processor] non-standard category from classifier: ${classification.category} → forcing 'other'`,
  );
  classification.category = 'other';
  classification.requiresHuman = true;
  classification.confidence = Math.min(classification.confidence, 0.5);
}
```

### 7.3 자동발송 게이트 평가 순서

`lib/email/auto-send-gate.ts`:

```typescript
export interface GateInput {
  organizationId: string;
  partyId?: string;
  module: ModuleType;
  classification: ClassificationOutput;
  draftBody: string;
}

export interface GateResult {
  allowed: boolean;
  reasons: string[];
  blockedRules: string[];
  evaluationLog: Record<string, unknown>;
}

export async function evaluateAutoSend(
  supabase: SupabaseClient,
  input: GateInput,
): Promise<GateResult> {
  const reasons: string[] = [];
  const blockedRules: string[] = [];
  const log: Record<string, unknown> = {};

  // [1] 글로벌 플래그
  if (!env.AI_AUTO_SEND_ENABLED) {
    return {
      allowed: false,
      reasons: ['global_disabled'],
      blockedRules: [],
      evaluationLog: { step: 'global_flag', value: false },
    };
  }

  // [2] 룰 조회
  const { data: rule, error } = await supabase
    .from('auto_send_rules')
    .select('*')
    .eq('organization_id', input.organizationId)
    .eq('classification_category', input.classification.category)
    .maybeSingle();

  if (error || !rule) {
    return {
      allowed: false,
      reasons: ['no_rule_defined'],
      blockedRules: [],
      evaluationLog: { step: 'rule_lookup', error: error?.message ?? 'not_found' },
    };
  }

  // [3] is_blocked
  if (rule.is_blocked) {
    reasons.push('rule_blocked');
    blockedRules.push(rule.id);
    log.is_blocked = { reason: rule.block_reason };
  }

  // [4] applicable_modules 매칭 (빈 배열은 "전 모듈 차단")
  const allowedModules = (rule.allowed_modules ?? []) as string[];
  if (allowedModules.length === 0 || !allowedModules.includes(input.module)) {
    reasons.push('module_not_allowed');
    log.module_check = { allowedModules, requestedModule: input.module };
  }

  // [5] min_confidence
  if (input.classification.confidence < Number(rule.min_confidence ?? 0.95)) {
    reasons.push('confidence_below_threshold');
    log.confidence_check = {
      observed: input.classification.confidence,
      required: rule.min_confidence,
    };
  }

  // [6] requires_human_approval
  if (rule.requires_human_approval || input.classification.requiresHuman) {
    reasons.push('requires_human_approval');
    log.human_required = true;
  }

  // [7] risk_flags 존재
  if (input.classification.riskFlags.length > 0) {
    reasons.push('risk_flags_present');
    log.risk_flags = input.classification.riskFlags;
  }

  // [8] blocked_keywords_in_body 정규식 매칭
  const blockedKeywords = (rule.blocked_keywords_in_body ?? []) as string[];
  for (const kw of blockedKeywords) {
    try {
      const regex = new RegExp(kw, 'i');
      if (regex.test(input.draftBody)) {
        reasons.push(`blocked_keyword:${kw}`);
        break;
      }
    } catch {/* 잘못된 regex는 skip */}
  }

  // [9] daily_limit / hourly_limit / per_party_daily_limit
  // (구현은 communications 카운트 쿼리)
  if (rule.daily_limit > 0) {
    const dailyCount = await countOutboundToday(supabase, input.organizationId, input.module);
    if (dailyCount >= rule.daily_limit) {
      reasons.push('daily_limit_reached');
      log.daily_limit = { observed: dailyCount, limit: rule.daily_limit };
    }
  }

  // [10] 최종 판단
  const allowed = reasons.length === 0;
  return {
    allowed,
    reasons,
    blockedRules,
    evaluationLog: log,
  };
}

async function countOutboundToday(
  supabase: SupabaseClient,
  organizationId: string,
  module: string,
): Promise<number> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const { count } = await supabase
    .from('communications')
    .select('*', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('direction', 'outbound')
    .eq('channel', 'email')
    .gte('sent_at', today.toISOString());

  return count ?? 0;
}
```

### 7.4 ai.drafts 생성·만료 정책

```typescript
const expiresAt = new Date();
expiresAt.setDate(expiresAt.getDate() + env.DRAFT_EXPIRY_DAYS);

const { data: draft } = await supabase
  .from('drafts')
  .insert({
    organization_id: organizationId,
    communication_id: communicationId,
    party_id: partyId,
    engagement_id: engagementId,
    classification_category: classification.category,
    confidence_score: classification.confidence,
    risk_flags: classification.riskFlags,
    subject: replyOutput.subject,
    body_plain: replyOutput.bodyPlain,
    body_html: replyOutput.bodyHtml ?? null,
    rationale: replyOutput.rationale,
    requires_human_approval: !gateResult.allowed,
    auto_send_eligible: gateResult.allowed,
    auto_send_blocked_reasons: gateResult.reasons,
    expires_at: expiresAt.toISOString(),
    ai_generated: true,
    status: 'draft',
    classifier_run_id: classifierRunId,
    drafter_run_id: drafterRunId,
  })
  .select('id')
  .single();

await supabase
  .from('communications')
  .update({
    ai_draft_id: draft.id,
    ai_processing_status: 'completed',
    ai_processing_completed_at: new Date().toISOString(),
  })
  .eq('id', communicationId);
```

### 7.5 risk_flags·requires_human_approval 처리

다음 중 하나라도 true면 자동발송 차단 (게이트의 [6][7] 단계와 동일 효과):
- `classification.requiresHuman === true`
- `classification.riskFlags.length > 0`
- `replyOutput.requires_human_approval === true` (회신가 자체 판단)

이 경우 ai.drafts는 생성되지만 `requires_human_approval=true`로 표시되어 STEP 5-6 UI에서 사람 검토 큐에 들어간다.

---

## 8. 모듈 E — 백그라운드 워커

3개 워커는 모두 graceful shutdown·dead-letter·재시도 패턴을 공유한다. 각 워커는 단일 프로세스로 실행되며 환경에 따라 Vercel Cron / Render Worker / Supabase Edge Function 중 하나에서 호스팅된다.

### 8.1 워커 런타임 분기

```typescript
// workers/runtime.ts (공통 헬퍼)

import { env } from '@/lib/env';

export type WorkerRuntime = 'node' | 'edge' | 'cron';

export function getRuntime(): WorkerRuntime {
  return env.WORKER_RUNTIME;
}

export function shouldRunOnce(): boolean {
  // cron 런타임은 1회 실행 후 종료, node/edge는 무한 루프
  return getRuntime() === 'cron';
}
```

각 워커의 main 함수는 런타임에 따라 다음과 같이 분기:
- `node`: 무한 루프 + LISTEN/NOTIFY 또는 폴링
- `edge`: Supabase Edge Function — 트리거당 1회 실행
- `cron`: Vercel Cron 또는 GitHub Actions — 스케줄당 1회 실행

### 8.2 consultation-worker (LISTEN/NOTIFY)

```typescript
// workers/consultation-worker.ts

import pg from 'pg';
import { createClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { ClaudeClient } from '@/lib/ai/claude-client';

interface ConsultationNotification {
  consultation_id: string;
  organization_id: string;
  module: string;
  priority: string;
  urgency?: string;
}

async function processConsultation(
  supabase: ReturnType<typeof createClient>,
  notification: ConsultationNotification,
): Promise<void> {
  const { consultation_id, organization_id } = notification;

  // 1. consultation 조회
  const { data: consultation, error } = await supabase
    .from('consultations')
    .select('*')
    .eq('id', consultation_id)
    .single();
  if (error || !consultation) return;

  // 2. ai_processing_status='processing' 갱신
  await supabase
    .from('consultations')
    .update({
      ai_processing_status: 'processing',
      ai_processing_started_at: new Date().toISOString(),
    })
    .eq('id', consultation_id);

  try {
    // 3. Strategy Advisor 호출
    const claudeClient = new ClaudeClient(supabase, organization_id);
    const result = await claudeClient.complete({
      agentRole: 'strategy_advisor',
      inboundMessage: consultation.content_processed ?? consultation.content_raw,
      partyId: consultation.party_id,
      engagementId: consultation.engagement_id,
      language: consultation.language ?? 'ko',
      outputFormat: 'json',
    });

    const strategyData = result.parsedJson as any;
    if (!strategyData) throw new Error('Strategy advisor returned non-JSON');

    // 4. response_strategies INSERT
    const { data: strategy } = await supabase
      .from('response_strategies')
      .insert({
        organization_id,
        consultation_id,
        engagement_id: consultation.engagement_id,
        party_id: consultation.party_id,
        module: consultation.module,
        run_id: result.runId,
        ai_generated: true,
        situation_analysis: strategyData.situation_analysis,
        key_signals: strategyData.key_signals ?? [],
        recommended_approach: strategyData.recommended_approach,
        key_messages: strategyData.key_messages ?? [],
        risks_to_avoid: strategyData.risks_to_avoid ?? [],
        questions_to_ask_internally: strategyData.questions_to_ask_internally ?? [],
        confidence_score: strategyData.confidence_score,
        requires_human_review: strategyData.requires_human_review ?? true,
        requires_legal_review: strategyData.requires_legal_review ?? false,
        requires_finance_review: strategyData.requires_finance_review ?? false,
        raw_ai_output: strategyData,
        status: 'draft',
      })
      .select('id')
      .single();

    // 5. strategy_actions 다수 INSERT (immediate / short_term / long_term)
    const actions = strategyData.actions ?? [];
    for (const action of actions) {
      const { data: actionRow } = await supabase
        .from('strategy_actions')
        .insert({
          organization_id,
          strategy_id: strategy?.id,
          title: action.title,
          description: action.description,
          action_type: action.action_type,
          priority: action.priority ?? 'medium',
          suggested_due_in_hours: action.suggested_due_in_hours ?? null,
          suggested_due_in_days: action.suggested_due_in_days ?? null,
          rationale: action.rationale,
          sort_order: action.sort_order ?? 0,
        })
        .select('id')
        .single();

      // 6. immediate 액션은 tasks 자동 생성
      if (action.action_type === 'immediate' && actionRow) {
        const { data: task } = await supabase
          .from('tasks')
          .insert({
            organization_id,
            title: action.title,
            description: action.description,
            priority: action.priority ?? 'high',
            status: 'todo',
            due_at: action.suggested_due_in_hours
              ? new Date(Date.now() + action.suggested_due_in_hours * 3600_000).toISOString()
              : null,
            party_id: consultation.party_id,
            engagement_id: consultation.engagement_id,
            linked_strategy_action_id: actionRow.id,
          })
          .select('id')
          .single();

        if (task) {
          await supabase
            .from('strategy_actions')
            .update({ linked_task_id: task.id })
            .eq('id', actionRow.id);
        }
      }
    }

    // 7. consultation 갱신
    await supabase
      .from('consultations')
      .update({
        ai_processing_status: 'completed',
        ai_processing_completed_at: new Date().toISOString(),
      })
      .eq('id', consultation_id);
  } catch (err) {
    await supabase
      .from('consultations')
      .update({ ai_processing_status: 'failed' })
      .eq('id', consultation_id);
    console.error('[consultation-worker] failed:', err);
  }
}

async function main() {
  const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

  // pg 클라이언트로 LISTEN
  const pgClient = new pg.Client({ connectionString: env.SUPABASE_DB_URL });
  await pgClient.connect();
  await pgClient.query('LISTEN consultation_created');

  let isShuttingDown = false;
  const inflight = new Set<Promise<void>>();

  pgClient.on('notification', (msg) => {
    if (isShuttingDown || msg.channel !== 'consultation_created') return;
    if (!msg.payload) return;
    try {
      const notification = JSON.parse(msg.payload) as ConsultationNotification;
      const promise = processConsultation(supabase, notification)
        .catch((e) => console.error(e))
        .finally(() => inflight.delete(promise));
      inflight.add(promise);
    } catch (err) {
      console.error('[consultation-worker] payload parse failed:', err);
    }
  });

  // graceful shutdown
  const shutdown = async () => {
    isShuttingDown = true;
    console.log('[consultation-worker] shutting down, waiting for inflight tasks...');
    await Promise.allSettled([...inflight]);
    await pgClient.end();
    process.exit(0);
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

if (require.main === module) {
  main().catch((err) => {
    console.error('[consultation-worker] fatal:', err);
    process.exit(1);
  });
}
```

### 8.3 draft-expiry-worker (크론)

```typescript
// workers/draft-expiry-worker.ts

import { createClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

export async function expireStaleDrafts(): Promise<{ expired: number }> {
  const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

  // SQL 함수 호출
  const { data, error } = await supabase.rpc('expire_stale_drafts');
  if (error) {
    console.error('[draft-expiry-worker] rpc failed:', error);
    throw error;
  }

  const expired = (data as any)?.expired_count ?? 0;
  console.log(`[draft-expiry-worker] expired ${expired} drafts at ${new Date().toISOString()}`);
  return { expired };
}

if (require.main === module) {
  expireStaleDrafts()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
```

스케줄 등록 (Vercel Cron `vercel.json` 예시):
```json
{
  "crons": [
    { "path": "/api/cron/draft-expiry", "schedule": "0 * * * *" }
  ]
}
```

### 8.4 mail-merge-worker (큐 폴링)

```typescript
// workers/mail-merge-worker.ts

import { createClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { TabsMailerClient } from '@/lib/email/tabs-mailer';

const POLL_INTERVAL_MS = 10_000;
const BATCH_SIZE = 5;

async function pickAndProcess(): Promise<void> {
  const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
  const tabs = new TabsMailerClient();

  // 큐 조회
  const { data: jobs } = await supabase
    .from('mail_merge_jobs')
    .select('*')
    .eq('status', 'queued')
    .lte('scheduled_at', new Date().toISOString())
    .order('scheduled_at', { ascending: true })
    .limit(BATCH_SIZE);

  for (const job of jobs ?? []) {
    try {
      // 캠페인 등록 (없으면)
      if (!job.tabs_campaign_id) {
        const { tabsCampaignId } = await tabs.createCampaign({
          name: job.name,
          description: job.description,
          templateId: job.template_id,
          scheduledAt: job.scheduled_at ? new Date(job.scheduled_at) : undefined,
          recipientCount: job.estimated_recipient_count ?? 0,
        });
        await supabase
          .from('mail_merge_jobs')
          .update({
            tabs_campaign_id: tabsCampaignId,
            status: 'running',
            started_at: new Date().toISOString(),
          })
          .eq('id', job.id);
      }

      // 수신자 명단 해석 + 발송 (구현 생략 — recipient_filter jsonb → SQL)
      // ... rate limit·quiet hours 준수 ...

      // 완료 처리
      await supabase
        .from('mail_merge_jobs')
        .update({
          status: 'completed',
          completed_at: new Date().toISOString(),
        })
        .eq('id', job.id);
    } catch (err) {
      const newRetryCount = (job.retry_count ?? 0) + 1;
      const shouldFail = newRetryCount >= (job.max_retries ?? 3);

      await supabase
        .from('mail_merge_jobs')
        .update({
          status: shouldFail ? 'failed' : 'queued',
          retry_count: newRetryCount,
          last_error_message: (err as Error).message,
          last_error_at: new Date().toISOString(),
          scheduled_at: shouldFail
            ? job.scheduled_at
            : new Date(Date.now() + Math.pow(2, newRetryCount) * 60_000).toISOString(),
        })
        .eq('id', job.id);
    }
  }
}

async function main() {
  let isShuttingDown = false;
  const shutdown = () => { isShuttingDown = true; };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

  while (!isShuttingDown) {
    try {
      await pickAndProcess();
    } catch (err) {
      console.error('[mail-merge-worker] iteration failed:', err);
    }
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
  }
  process.exit(0);
}

if (require.main === module) {
  main();
}
```

### 8.5 graceful shutdown 패턴

모든 워커에 적용되는 공통 패턴:
1. SIGTERM·SIGINT 받으면 `isShuttingDown = true`
2. 새 작업 수락 중지
3. inflight 작업의 Promise를 추적해 `Promise.allSettled` 대기
4. 5초 grace period 내 미완료 시 force exit
5. 정리 후 `process.exit(0)`

### 8.6 dead-letter·재시도

각 워커는 다음 정책을 공유:
- 실패 시 `status='failed'` + `error_message`·`error_at` 기록
- 재시도 가능 작업은 `retry_count` 증가 + exponential backoff (60s × 2^n)
- `max_retries` 초과 시 `status='failed'` 확정 + admin alert
- 별도 dead_letter 테이블 권장 (운영 시점에 추가)

---

## 9. 타입·인터페이스 가이드

### 9.1 types/ai.ts

```typescript
export type AgentRole = 'classifier' | 'reply_drafter' | 'strategy_advisor' | 'summarizer';

export type ClaudeModel =
  | 'claude-opus-4-7'
  | 'claude-sonnet-4-6'
  | 'claude-haiku-4-5-20251001';

export type DraftStatus =
  | 'draft' | 'in_review' | 'approved' | 'rejected' | 'sent' | 'expired' | 'cancelled';

export type RunStatus = 'success' | 'failed' | 'timeout' | 'budget_exceeded';

export interface AgentRow {
  id: string;
  organizationId: string;
  role: AgentRole;
  name: string;
  model: ClaudeModel;
  fallbackModel?: ClaudeModel;
  temperature: number;
  maxTokens: number;
  outputFormat: 'text' | 'structured';
  systemPrompt: string;
  applicableModules?: string[];
  applicableLanguages?: string[];
  requirePiiMasking?: boolean;
  knowledgeCollection?: string;
  isActive: boolean;
  version: number;
}

export interface ClaudeCompleteInput {
  agentRole: AgentRole;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: 'ko' | 'en' | 'ja';
  maskPii?: boolean;
  outputFormat?: 'text' | 'json';
}

export interface ClaudeCompleteOutput {
  content: string;
  parsedJson?: object;
  runId: string;
  model: ClaudeModel;
  latencyMs: number;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
}

export interface ReplyDrafterOutput {
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale: string;
  riskFlags: string[];
  requiresHumanApproval: boolean;
  language: 'ko' | 'en' | 'ja';
}
```

### 9.2 types/email.ts

```typescript
export type Direction = 'inbound' | 'outbound';
export type Channel = 'email' | 'phone' | 'meeting' | 'note' | 'chat' | 'social';

export interface CommunicationRow {
  id: string;
  organizationId: string;
  partyId?: string;
  contactId?: string;
  engagementId?: string;
  threadId: string;
  messageId: string;
  inReplyTo?: string;
  direction: Direction;
  channel: Channel;
  fromAddress: string;
  fromName?: string;
  toAddresses: string[];
  ccAddresses?: string[];
  subject: string;
  bodyText: string;
  bodyHtml?: string;
  sentAt?: string;
  receivedAt?: string;
  openedAt?: string;
  clickedAt?: string;
  repliedAt?: string;
  bouncedAt?: string;
  templateId?: string;
  aiDraftId?: string;
  externalData: Record<string, unknown>;
  aiProcessingStatus: 'pending' | 'processing' | 'completed' | 'failed' | 'skipped';
}

export interface AttachmentMeta {
  filename: string;
  contentType: string;
  sizeBytes: number;
  storagePath: string;
}
```

### 9.3 types/classification.ts (10 카테고리 enum)

```typescript
export const STANDARD_CATEGORIES = [
  'information_request',
  'meeting_scheduling',
  'simple_acknowledgment',
  'price_negotiation',
  'contract_terms',
  'rejection',
  'complaint',
  'introduction',
  'follow_up',
  'other',
] as const;

export type StandardCategory = typeof STANDARD_CATEGORIES[number];

export const RISK_FLAGS = [
  'valuation_topic', 'term_sheet_topic', 'legal_topic',
  'financial_projection', 'competitor_disclosure',
  'price_commitment', 'moq_commitment', 'lead_time_commitment',
  'exclusivity_request', 'payment_terms', 'quality_certification',
  'pricing_dispute', 'delivery_issue', 'quality_complaint',
] as const;

export type RiskFlag = typeof RISK_FLAGS[number];

export interface ClassificationOutput {
  category: StandardCategory;
  urgency: 'low' | 'medium' | 'high' | 'urgent';
  sentiment: 'positive' | 'neutral' | 'negative' | 'mixed';
  requiresHuman: boolean;
  confidence: number;
  rationale: string;
  riskFlags: RiskFlag[];
  detectedLanguage: 'ko' | 'en' | 'ja' | 'zh' | 'other';
}

export function isStandardCategory(value: string): value is StandardCategory {
  return STANDARD_CATEGORIES.includes(value as StandardCategory);
}
```

### 9.4 DB row → 도메인 객체 변환

snake_case (DB) → camelCase (TS) 변환은 명시적 매퍼 함수 사용:

```typescript
// lib/db/mappers.ts

export function toAgentRow(dbRow: any): AgentRow {
  return {
    id: dbRow.id,
    organizationId: dbRow.organization_id,
    role: dbRow.role,
    name: dbRow.name,
    model: dbRow.model,
    fallbackModel: dbRow.fallback_model ?? undefined,
    temperature: Number(dbRow.temperature),
    maxTokens: Number(dbRow.max_tokens),
    outputFormat: dbRow.output_format,
    systemPrompt: dbRow.system_prompt,
    applicableModules: dbRow.applicable_modules ?? undefined,
    applicableLanguages: dbRow.applicable_languages ?? undefined,
    requirePiiMasking: dbRow.require_pii_masking,
    knowledgeCollection: dbRow.knowledge_collection ?? undefined,
    isActive: dbRow.is_active,
    version: dbRow.version,
  };
}
```

자동 변환 라이브러리(camelcase-keys 등) 사용 가능하지만 명시적 매퍼가 타입 안전성·리팩토링 친화.

---

## 10. 테스트 전략

### 10.1 단위 테스트 (vitest)

각 모듈에 대해 최소 1 테스트 파일. 외부 의존성은 모두 mock.

```typescript
// __tests__/ai/claude-client.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ClaudeClient, ClaudeApiError, ClaudeBudgetExceededError } from '@/lib/ai/claude-client';

describe('ClaudeClient', () => {
  let supabase: any;
  let client: ClaudeClient;

  beforeEach(() => {
    supabase = {
      from: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      maybeSingle: vi.fn(),
      insert: vi.fn().mockReturnThis(),
      single: vi.fn(),
      gte: vi.fn().mockReturnThis(),
      rpc: vi.fn(),
    };
    client = new ClaudeClient(supabase, 'org-test');
  });

  it('should throw ClaudeBudgetExceededError when daily budget exceeded', async () => {
    supabase.maybeSingle.mockResolvedValueOnce({
      data: { id: 'agent-1', model: 'claude-haiku-4-5-20251001' },
    });
    supabase.gte = vi.fn().mockReturnThis();
    supabase.from('runs').select = vi.fn().mockReturnValue(
      Promise.resolve({ data: [{ cost_usd: 100 }] }),
    );

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'test',
        outputFormat: 'json',
      }),
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);
  });

  it('should reject unsupported model IDs', async () => {
    supabase.maybeSingle.mockResolvedValueOnce({
      data: { id: 'agent-1', model: 'claude-3-opus' }, // 구버전
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'test',
        outputFormat: 'json',
      }),
    ).rejects.toThrow(/Unsupported Claude model/);
  });

  it('should record ai.runs on both success and failure paths', async () => {
    // 성공 경로 검증
    // 실패 경로 검증 (재시도 후 throw)
    // 두 경로 모두에서 supabase.from('runs').insert가 호출되었는지
  });

  it('should retry on 429 with Retry-After header', async () => {
    // 첫 호출 429 → 재시도 → 200
    // recordRun이 success로 1번만 호출되는지
  });

  it('should fallback to sonnet on second retry attempt', async () => {
    // 첫 시도 5xx, 두 번째 시도에서 model이 sonnet으로 변경
  });
});
```

### 10.2 통합 테스트 (Supabase 인스턴스)

별도 Supabase 인스턴스 (sql_completion 적용된 상태):
- `pnpm test:integration` 명령
- 테스트 시작 전 시드 적용: `psql $TEST_DB_URL -f sql/...`
- 각 테스트 후 트랜잭션 롤백 또는 truncate

테스트 시나리오:
- 메일 수신 → communications INSERT → processor 호출 → ai.drafts 생성 (E2E)
- consultation INSERT → pg_notify → consultation-worker 처리 → response_strategies + tasks 생성
- mail_merge_jobs 큐 추가 → mail-merge-worker → tabs.sendOne 호출 (mock)

### 10.3 외부 API 모킹 (msw)

```typescript
// __tests__/setup/msw-handlers.ts

import { http, HttpResponse } from 'msw';

export const handlers = [
  // Anthropic API
  http.post('https://api.anthropic.com/v1/messages', () => {
    return HttpResponse.json({
      id: 'msg_test',
      type: 'message',
      role: 'assistant',
      content: [{ type: 'text', text: '{"category":"information_request","confidence":0.95}' }],
      model: 'claude-haiku-4-5-20251001',
      stop_reason: 'end_turn',
      usage: { input_tokens: 100, output_tokens: 50 },
    });
  }),

  // OpenAI Embeddings
  http.post('https://api.openai.com/v1/embeddings', () => {
    return HttpResponse.json({
      data: [{ embedding: new Array(1536).fill(0.01) }],
      model: 'text-embedding-3-large',
      usage: { prompt_tokens: 10, total_tokens: 10 },
    });
  }),
];
```

### 10.4 테스트 데이터 픽스처

`__tests__/fixtures/`:
- `inbound-investor-ko.json` — 한국어 투자자 첫 회신 메일
- `inbound-buyer-en.json` — 영문 RFQ 메일
- `classification-output-meeting.json` — 분류기 정상 출력
- `classification-output-malformed.json` — 비표준 카테고리 출력
- `mail-merge-job.json` — 큐에 들어가는 잡

### 10.5 커버리지 목표

| 영역 | 목표 |
|------|------|
| `lib/ai/claude-client.ts` | 90% |
| `lib/email/auto-send-gate.ts` | 90% (분기 많음) |
| `lib/email/header-parser.ts` | 95% (순수 함수) |
| `lib/email/processor.ts` | 80% |
| `workers/*` | 70% (런타임 의존성 많음) |
| 전체 | 80% |

---

## 11. 운영·관측·보안

### 11.1 로깅 표준

JSON 구조화 로그 (pino 권장):

```typescript
// lib/logger.ts

import pino from 'pino';
import { env } from './env';

export const logger = pino({
  level: env.LOG_LEVEL,
  redact: {
    paths: [
      '*.api_key',
      '*.password',
      '*.token',
      '*.email',  // 자동 마스킹
      'req.headers.authorization',
      'req.headers["x-api-key"]',
    ],
    censor: '***REDACTED***',
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
```

로그 메시지 형식:
- 항상 `{ event, organization_id, ... }` 객체로
- 사용자 식별 정보(이메일·이름)는 직접 로깅 금지 — ID로만

### 11.2 메트릭 (지연·실패율·비용)

추적해야 할 핵심 메트릭:

| 메트릭 | 단위 | 출처 | 알림 임계 |
|--------|------|------|----------|
| Claude API p95 latency | ms | ai.runs.latency_ms | > 30,000 |
| Claude API 실패율 | % | ai.runs.status='failed' / total | > 5% (5분) |
| 일일 AI 비용 | USD | ai.runs.cost_usd 합계 | > MAX_DAILY_AI_COST_USD × 0.8 |
| 메일 처리 큐 깊이 | rows | communications.ai_processing_status='pending' count | > 100 (10분) |
| 자동발송 차단율 | % | drafts.auto_send_eligible=false / total | (정상 모니터링) |
| Inbound 도착률 | rows/min | communications direction='inbound' | 급격 변동 시 알람 |

수집 도구: PostHog / Datadog / Grafana Cloud / Supabase Logs (선택).

### 11.3 알람·온콜

운영 시작 (STEP 7) 후 다음 알람 설정:
- **Critical** (즉시 호출): Anthropic API 30분 이상 실패율 > 50%, 예산 초과, MailCarrier 연결 끊김 1시간 이상
- **High** (영업 시간 내): 큐 깊이 > 500, 일일 비용 80% 도달
- **Info**: Quiet hours 차단 카운트, fallback 모델 사용률

### 11.4 PII 처리 정책

- **수집**: 메일 본문에서 정규식 기반 best-effort 마스킹
- **저장**: `communications.body_text`는 마스킹된 버전만 저장. 원본은 즉시 폐기.
- **AI 호출**: 마스킹된 텍스트로만 호출. 응답 받은 뒤 복원해서 사용자에게 표시.
- **로그**: 자동 redact 적용. 디버깅 시에도 PII 출력 금지.
- **백업·내보내기**: PII 포함 데이터는 별도 보안 정책 (운영 시점 결정)
- **삭제 요청 (GDPR/개인정보보호법)**: party 단위 cascade delete (audit.change_log은 PII 마스킹 후 보존)

### 11.5 비밀 관리·키 회전

- 운영 키: Vercel/Render Secrets, Supabase Vault
- 개발 키: 1Password / 팀 공용 패스워드 매니저
- 회전 자동화: 90일마다 알람 → 운영자 수동 회전 → 신키로 환경변수 갱신 → 구키 폐기 (이중 키 30일 유지)

### 11.6 RLS 컨텍스트 (service_role vs anon)

| 컴포넌트 | 클라이언트 | RLS 적용 | 이유 |
|----------|-----------|----------|------|
| Next.js Server Action (사용자 컨텍스트) | anon + JWT | ✅ 적용 | 사용자별 권한 |
| 워커 (백그라운드) | service_role | ❌ 우회 | 시스템 레벨 작업 |
| processor (메일 처리) | service_role | ❌ 우회 | 트리거 레벨 작업 |
| 통합 테스트 | service_role | 컨텍스트 시뮬레이션 | RLS 정책도 검증 |

service_role 사용 시 코드에 명시적 주석:
```typescript
// NOTE: using service_role to bypass RLS for system-level operation
const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
```

### 11.7 마무리 체크리스트

STEP 3 완료·운영 시작 전 확인:

- [ ] `tsc --noEmit` 0 에러
- [ ] `eslint` 0 에러
- [ ] 모든 테스트 통과
- [ ] 모델명: claude-opus-4-7 / claude-haiku-4-5-20251001 / claude-sonnet-4-6 만 사용
- [ ] 표준 10 카테고리 외 사용 0건
- [ ] `process.env.X` 직접 접근 0건
- [ ] ai.runs INSERT가 모든 Claude 호출 경로에 존재
- [ ] PII 마스킹 단위 테스트 통과
- [ ] graceful shutdown 모든 워커에 적용
- [ ] 환경 변수 카탈로그(§3.1) 모두 정의
- [ ] AI_AUTO_SEND_ENABLED=false 운영 시작 (점진 활성화)
- [ ] TABS Mailer / MailCarrier 외부 정보 수령 또는 mock 어댑터 명확히 표시

---

> **본 문서 끝**.
> 작업 명세서(`04_task_email_integration.md`)와 함께 STEP 3 새 채팅 세션에 첨부하면, AI가 본 가이드의 패턴·결정·코드 예시를 그대로 따라 production-ready 인프라 코드를 작성한다.


