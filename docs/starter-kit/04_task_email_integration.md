# 04 — 작업 프롬프트: 이메일 통합·AI 인프라 코드 (STEP 3)

## 사전 조건 (필수)

다음 문서가 시스템 컨텍스트로 로드되어 있어야 합니다:
1. `00_anti_evasion_requirements.md` — 회피 방지 요구사항 (필수 준수)
2. `01_master_system_prompt.md` — 마스터 시스템 프롬프트 (절대 변경 금지)
3. `00_Review_and_Supplement.md` — 1,302줄 코드 가이드 (본 작업의 직접 참조)
4. `004_communications_and_activities.sql` — 인프라 코드가 read/write할 핵심 스키마

추가 권장:
5. `007_ai_system.sql` — ai.agents·ai.runs·ai.drafts·ai.brand_voice 스키마
6. STEP 1·2가 완료되어 13 SQL 패키지가 적용된 데이터베이스

응답 시작 부분에 안티-회피 약속 5개를 명시하지 않으면 작업이 거부됩니다.

---

## 작업 목적

Next.js 14 / TypeScript 5.5+ 기반의 백엔드 인프라 코드를 작성한다. STEP 1·2의 데이터베이스 스키마 위에서 동작하며, STEP 4-6 프론트엔드의 토대가 된다.

핵심 책임:
- Anthropic API 호출의 단일 진입점 (재시도·비용 추적·PII 마스킹·구조화 출력)
- TABS Mailer 4 (발송) / MailCarrier 7 (수신) 어댑터
- 메일 수신 → 분류 → 스레드 매칭 → AI 회신 초안 생성 파이프라인
- 자동발송 게이트 (10 카테고리 정책 평가)
- 백그라운드 워커 (consultation 처리·draft 만료·메일머지 잡 처리)

본 작업은 코드 가이드 `00_Review_and_Supplement.md` (1,302줄)의 패턴·결정 사항을 그대로 따른다. 가이드에서 다루지 않은 부분만 본 작업 명세에 따라 자체 결정한다.

---

## 절대 산출물 목록 (모두 작성, 누락 불가)

```
src/
├── lib/
│   ├── env.ts                              [필수] zod 환경변수 스키마
│   ├── ai/
│   │   ├── claude-client.ts                [필수] Anthropic API 래퍼
│   │   ├── pii-masker.ts                   [필수] PII 탐지·마스킹·복원
│   │   ├── prompt-renderer.ts              [필수] brand_voice·knowledge_chunks 합성
│   │   └── cost-tracker.ts                 [필수] 비용·토큰 → ai.runs
│   └── email/
│       ├── tabs-mailer.ts                  [필수] TABS Mailer 4 SMTP 어댑터
│       ├── mailcarrier.ts                  [필수] MailCarrier 7 IMAP 어댑터
│       ├── header-parser.ts                [필수] RFC 5322·thread 매칭
│       ├── processor.ts                    [필수] 수신→분류→draft 파이프라인
│       └── auto-send-gate.ts               [필수] 자동발송 정책 평가
├── workers/
│   ├── consultation-worker.ts              [필수] LISTEN consultation_created
│   ├── draft-expiry-worker.ts              [필수] ai.expire_stale_drafts() 크론
│   └── mail-merge-worker.ts                [필수] mail_merge_jobs 큐 처리
├── types/
│   ├── ai.ts                               [필수] AI 도메인 타입
│   ├── email.ts                            [필수] 메일 도메인 타입
│   └── classification.ts                   [필수] 10 카테고리 enum + risk_flags
└── __tests__/
    ├── ai/claude-client.test.ts            [필수]
    ├── email/header-parser.test.ts         [필수]
    ├── email/processor.test.ts             [필수]
    ├── email/auto-send-gate.test.ts        [필수]
    └── workers/consultation-worker.test.ts [필수]
```

추가 설정 파일:
- `package.json`, `tsconfig.json`, `.eslintrc.json`, `vitest.config.ts`

**산출물 개수: 18개 TS 파일 + 4개 설정 파일 = 22개. 18개 미만이면 거부.**

---

## 파일별 상세 요구사항

### lib/env.ts

zod 스키마로 모든 환경변수 검증. 미설정 시 모듈 import 시점에 throw.

필수 변수:
- `ANTHROPIC_API_KEY` (string, min 20)
- `ANTHROPIC_MODEL_OPUS` (literal 'claude-opus-4-7')
- `ANTHROPIC_MODEL_HAIKU` (literal 'claude-haiku-4-5-20251001')
- `ANTHROPIC_MODEL_SONNET` (literal 'claude-sonnet-4-6')
- `OPENAI_API_KEY` (string)
- `OPENAI_EMBEDDING_MODEL` (default 'text-embedding-3-large')
- `NEXT_PUBLIC_SUPABASE_URL` (url)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (string)
- `SUPABASE_SERVICE_ROLE_KEY` (string)
- `TABS_MAILER_HOST`, `TABS_MAILER_PORT`, `TABS_MAILER_AUTH_METHOD` (enum: plain/login/ip_whitelist), `TABS_MAILER_USERNAME`, `TABS_MAILER_PASSWORD`
- `MAILCARRIER_HOST`, `MAILCARRIER_PORT`, `MAILCARRIER_USERNAME`, `MAILCARRIER_PASSWORD`, `MAILCARRIER_USE_IDLE` (boolean)
- `AI_AUTO_SEND_ENABLED` (default false)
- `SCRAPING_ENABLED` (default true)
- `MAX_DAILY_AI_COST_USD` (number, default 50)
- `LOG_LEVEL` (enum: debug/info/warn/error)

`export const env = envSchema.parse(process.env)` 형태로 한 번 검증 → 어디서든 `env.X` 사용. 직접 `process.env.X` 접근은 절대 금지.

**검증 포인트**:
- ✅ 모든 변수 zod 검증
- ✅ 모듈 import 시점에 즉시 throw (lazy 평가 금지)
- ✅ 모델 ID는 정확한 리터럴 타입

### lib/ai/claude-client.ts

`class ClaudeClient`:
- 생성자: `(supabase: SupabaseClient, organizationId: string)`
- 메서드:
  - `complete(input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput>`
- `ClaudeCompleteInput`:
  - `agentRole: AgentRole` (classifier/reply_drafter/strategy_advisor/summarizer)
  - `partyId?: string`, `engagementId?: string`, `inboundMessage: string`
  - `maskPii?: boolean` (default true)
  - `outputFormat: 'text' | 'json'`
- `ClaudeCompleteOutput`:
  - `content: string`, `parsedJson?: object`, `runId: string`
  - `model: string`, `latencyMs: number`, `tokensIn: number`, `tokensOut: number`, `costUsd: number`

내부 흐름:
1. DB에서 `ai.agents` 행 조회 (organization_id + role + applicable_languages 매칭)
2. PII 마스킹 (maskPii=true 시)
3. prompt-renderer로 컨텍스트 번들 합성
4. Anthropic API 호출 — `agent.model` 우선, 실패 시 `agent.fallback_model`로 1회 재시도
5. 재시도 정책: 429·5xx에 exponential backoff (1s, 2s, 4s, 최대 3회)
6. 60초 hard timeout (AbortController)
7. PII 복원
8. `ai.runs` INSERT (성공·실패 모두 기록)
9. 비용 한도 체크 (cost-tracker 호출, 일일 한도 초과 시 throw)

에러 클래스:
- `class ClaudeApiError extends Error` — status, retryAfter 등 메타 포함
- `class ClaudeBudgetExceededError extends Error`
- `class ClaudeInvalidModelError extends Error`

**검증 포인트**:
- ✅ 모든 호출 경로(성공·재시도·실패)에 ai.runs INSERT
- ✅ 모델 ID는 claude-opus-4-7 / claude-haiku-4-5-20251001 / claude-sonnet-4-6 외 throw
- ✅ AbortController로 타임아웃 명확히

### lib/ai/pii-masker.ts

`function maskPii(text: string): { masked: string; tokens: PiiTokenMap; categories: string[] }`
`function restorePii(text: string, tokens: PiiTokenMap): string`

탐지 대상 (정규식 패턴):
- 한국 주민등록번호 (`\d{6}-?[1-4]\d{6}`)
- 한국 전화번호 (`01[0-9]-?\d{3,4}-?\d{4}`)
- 국제 전화번호 (E.164)
- 이메일 (RFC 5322 간략판)
- 신용카드 번호 (Luhn 미검증, 패턴만 — 16자리)
- 한국 사업자등록번호 (`\d{3}-?\d{2}-?\d{5}`)
- 여권번호 (alphanum 9자리)
- 주소·계좌번호는 best-effort

마스킹 토큰 형식: `{{PII_001}}`, `{{PII_002}}` 순차.
`tokens` Map은 호출자(claude-client)가 메모리에 보관 → AI 응답 받은 뒤 `restorePii`로 복원.

`categories`는 `['phone', 'email', 'national_id']` 형식 → ai.runs.pii_categories_detected에 기록.

### lib/ai/prompt-renderer.ts

`async function renderPrompt(input: RenderInput): Promise<RenderedPrompt>`

`RenderInput`:
- `agent: AgentRow`
- `partyId?: string`, `engagementId?: string`, `inboundMessage: string`
- `language?: 'ko' | 'en' | 'ja'`

처리:
1. `ai.brand_voice` 조회 (organization_id + agent.applicable_modules[0] + language 매칭, 없으면 default)
2. `ai.search_knowledge(org_id, query_embedding, limit=8)` 호출 (cosine 유사도)
   - query_embedding은 OpenAI text-embedding-3-large 호출
3. `app.communications` 최근 thread 5개 조회 (party_id 기준)
4. 시스템 프롬프트 = `agent.system_prompt` 그대로
5. user 메시지 = JSON 컨텍스트 번들:
   ```json
   {
     "inbound_message": "...",
     "party_context": { ... },
     "brand_voice": { ... },
     "knowledge_chunks": [ ... ],
     "thread_history": [ ... ]
   }
   ```
6. Liquid 변수 치환 (email-templates 본문 렌더링 시 재사용 가능한 함수 export)

`RenderedPrompt`:
- `system: string`
- `messages: Anthropic.MessageParam[]`
- `metadata: { brandVoiceId, knowledgeChunkIds[], threadIds[] }`

### lib/ai/cost-tracker.ts

상수 테이블 (2026년 5월 기준 USD per 1M tokens):
```typescript
export const MODEL_PRICING = {
  'claude-opus-4-7':           { input: 15.00, output: 75.00 },
  'claude-sonnet-4-6':         { input:  3.00, output: 15.00 },
  'claude-haiku-4-5-20251001': { input:  0.80, output:  4.00 },
};
```

함수:
- `calculateCost(model, tokensIn, tokensOut): number`
- `recordRun(supabase, organizationId, runData): Promise<string>` (runId 반환)
- `checkDailyBudget(supabase, organizationId): Promise<{ used: number; limit: number; allowed: boolean }>`
- `checkMonthlyBudget(...)`

비용 한도 초과 시 `ClaudeBudgetExceededError` throw — claude-client가 호출 차단.

### lib/email/tabs-mailer.ts

`class TabsMailerClient`:
- 생성자: `(config: TabsMailerConfig)`
- 인증 분기:
  - `auth_method === 'plain'` 또는 `'login'`: nodemailer + SASL
  - `auth_method === 'ip_whitelist'`: 인증 헤더 없이 host에 직접 SMTP
- 메서드:
  - `createCampaign(params): Promise<{ tabsCampaignId: string }>`
  - `sendOne(params): Promise<{ messageId: string; tabsTrackingId?: string }>`
  - `getCampaignStats(tabsCampaignId): Promise<TabsCampaignStats>`
  - `syncCampaignToMergeJob(supabase, jobId): Promise<void>` (mail_merge_jobs.progress 갱신)

사용자 정의 헤더 부착 (`headers` 파라미터):
- `X-URM-Engagement-Id`
- `X-URM-Communication-Id`
- `X-URM-Auto-Send: true|false`
- `X-URM-Brand-Voice-Id`

Quiet hours 체크:
- `mail_merge_jobs.quiet_hours` 기준 (`{timezone, start, end, weekends_blocked}`)
- 발송 시점 검증, 차단 시 `next_send_at`을 다음 가능 시간으로 재스케줄

에러 클래스:
- `class TabsMailerError extends Error` (cause 포함)
- `class TabsMailerAuthError extends TabsMailerError`
- `class TabsMailerQuietHoursError extends TabsMailerError`

### lib/email/mailcarrier.ts

`class MailCarrierClient`:
- 생성자: `(config: MailCarrierConfig)`
- IMAPFlow 라이브러리 사용
- 메서드:
  - `connect(): Promise<void>`
  - `startListening(onMessage: (msg: InboundMessage) => Promise<void>): Promise<void>`
  - `stop(): Promise<void>` (graceful shutdown)
- IDLE 분기:
  - `MAILCARRIER_USE_IDLE=true` 시 IDLE 대기 (~29분 후 자동 재연결)
  - `false` 시 30초 폴링
- 수신 메시지 → `header-parser.parse()` → `app.communications` INSERT
- 첨부:
  - 내용 추출 → SHA-256 hash
  - Supabase Storage 업로드 (`bucket: communications-attachments`, path: `{org_id}/{comm_id}/{filename}`)
  - `app.attachments` 행 생성 (entity_type='communication')
- 수신 시점 PII 사전 마스킹 (`processor.ts`로 넘기기 전)

에러 처리:
- IMAP 연결 끊김 시 exponential backoff 재연결 (최대 5회)
- 파싱 실패 시 raw payload는 보존하고 `processed=false`로 INSERT (수동 검토)

### lib/email/header-parser.ts

순수 함수 모듈 (테스트 용이).

`function parseInboundMessage(raw: ParsedMail): ParsedHeaders`

`ParsedHeaders`:
- `messageId: string` (RFC 5322, `<...@...>` 그대로)
- `inReplyTo?: string`
- `references: string[]` (배열)
- `from: { name?: string; address: string }`
- `to: Array<{ name?: string; address: string }>`
- `cc?: ...`
- `subject: string`
- `date: Date`
- `urmHeaders`: `{ engagementId?, communicationId?, autoSend?, brandVoiceId? }` (X-URM-* 파싱)

`async function findThreadId(supabase, organizationId, parsedHeaders): Promise<string | null>`
- 우선순위:
  1. `urmHeaders.communicationId` 부모로 thread_id 조회
  2. `inReplyTo`로 communications.message_id 매칭
  3. `references` 배열을 역순으로 시도
  4. 없으면 null (신규 thread, 호출자가 새 UUID 부여)

### lib/email/processor.ts

`async function processInbound(supabase, communicationId): Promise<ProcessResult>`

처리 단계:
1. `app.communications` 행 조회 (lock for update)
2. PII 사전 마스킹 (이미 mailcarrier에서 했으면 skip)
3. ClaudeClient.complete({ agentRole: 'classifier' }) — Haiku 호출
4. 분류 결과 검증:
   - `classification.category` ∈ 표준 10 카테고리 (위반 시 throw → `requires_human_approval=true`로 강제)
   - `risk_flags` 추출
5. ClaudeClient.complete({ agentRole: 'reply_drafter' }) — Opus 호출 (모듈·언어 매칭 자동)
6. `auto-send-gate.evaluate()` 호출 → 자동발송 가능 여부 판단
7. `ai.drafts` INSERT:
   - `expires_at = NOW() + 7 days`
   - `requires_human_approval = !gateResult.allowed`
   - `ai_generated = true`
8. communications.ai_draft_id FK 갱신
9. `ProcessResult` 반환:
   - `draftId, classification, autoSendAllowed, blockedReasons[]`

에러 처리:
- 모든 단계 실패는 `ai.runs.status='failed'` + `communications.ai_processing_status='failed'` 기록
- Critical 실패 시 admin alert 이벤트 발행 (lib/alerts.ts 별도 모듈, 본 작업 범위 외)

### lib/email/auto-send-gate.ts

`async function evaluateAutoSend(supabase, input): Promise<GateResult>`

평가 순서:
1. 환경 플래그 `AI_AUTO_SEND_ENABLED=false` 시 즉시 `{ allowed: false, reasons: ['global_disabled'] }`
2. `ai.auto_send_rules` 조회 (organization_id + classification_category + module 매칭)
3. `is_blocked === true` → 차단
4. `min_confidence > classification.confidence` → 차단
5. `blocked_keywords_in_body` 정규식 매칭 → 차단
6. `daily_limit` / `hourly_limit` / `per_party_daily_limit` 계산:
   - `app.communications` 집계 (direction='outbound', sent_at >= NOW() - interval) 카운트
7. `requires_calendar_data===true` 시 미팅 가용성 미존재 차단
8. `classification.requires_human === true` 또는 `risk_flags` 비어있지 않음 → 차단
9. 모두 통과 시 `allowed: true`

`GateResult`:
- `allowed: boolean`
- `reasons: string[]`
- `blockedRules: AutoSendRuleRow[]`
- `evaluationLog: jsonb` (감사용)

### workers/consultation-worker.ts

LISTEN/NOTIFY 패턴:
- Postgres connection으로 `LISTEN consultation_created` 등록
- 알림 페이로드 파싱 (consultation_id, organization_id, module, priority)
- ClaudeClient.complete({ agentRole: 'strategy_advisor' }) 호출
- 결과를 `app.response_strategies` INSERT
- 액션 분해 → `app.strategy_actions` 다수 INSERT
- 각 strategy_action 중 `action_type='immediate'`는 `app.tasks` 행 자동 생성
- consultation.ai_processing_status='completed' 갱신

graceful shutdown:
- `SIGTERM` → 현재 처리 중인 작업 완료 후 종료
- 5초 grace period 내 미완료 시 force kill

### workers/draft-expiry-worker.ts

크론 스케줄: 매시간 (`0 * * * *`)
- `SELECT ai.expire_stale_drafts()` 호출
- 결과(만료 처리된 draft 수)를 메트릭으로 기록
- 실패 시 alert

본 워커는 Vercel Cron 또는 Render Worker 또는 Supabase Edge Function 어디서든 동작 가능 — 환경변수 `WORKER_RUNTIME`으로 분기.

### workers/mail-merge-worker.ts

폴링 패턴 (10초 간격):
- `app.mail_merge_jobs` WHERE `status IN ('queued')` AND `scheduled_at <= NOW()` LIMIT 5
- 각 잡:
  1. `tabs_campaign_id`가 없으면 `TabsMailerClient.createCampaign()`
  2. 수신자 명단 해석 (`recipient_filter` jsonb → SQL → party_ids)
  3. 각 수신자에 대해 Liquid 렌더 → `tabs_mailer.sendOne()` (rate limit 준수)
  4. 발송된 통신은 `app.communications` 행으로 기록
  5. 진행상황 `mail_merge_jobs.progress` 갱신
  6. 완료 시 `status='completed'`

에러 시 `status='failed'` + `error_message` 기록.

### types/ai.ts

```typescript
export type AgentRole = 'classifier' | 'reply_drafter' | 'strategy_advisor' | 'summarizer';
export type ClaudeModel = 'claude-opus-4-7' | 'claude-sonnet-4-6' | 'claude-haiku-4-5-20251001';
export type DraftStatus = 'draft' | 'in_review' | 'approved' | 'rejected' | 'sent' | 'expired' | 'cancelled';

export interface AgentRow { id: string; organizationId: string; role: AgentRole; ... }
export interface RunRow { id: string; agentId: string; status: 'success' | 'failed' | ...; tokensIn: number; ... }
export interface DraftRow { id: string; communicationId: string; expiresAt: Date; ... }
export interface BrandVoiceRow { ... }

export interface ClaudeCompleteInput { ... }
export interface ClaudeCompleteOutput { ... }
```

### types/email.ts

```typescript
export interface InboundMessage {
  messageId: string;
  threadId?: string;
  from: { name?: string; address: string };
  to: { name?: string; address: string }[];
  subject: string;
  bodyText: string;
  bodyHtml?: string;
  attachments: AttachmentMeta[];
  receivedAt: Date;
  urmHeaders: Record<string, string>;
}

export interface OutboundMessage { ... }
export interface ThreadContext { ... }
export interface AttachmentMeta { ... }
```

### types/classification.ts

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
] as const;

export interface ClassificationOutput {
  category: StandardCategory;
  urgency: 'low' | 'medium' | 'high' | 'urgent';
  sentiment: 'positive' | 'neutral' | 'negative' | 'mixed';
  requiresHuman: boolean;
  confidence: number;
  rationale: string;
  riskFlags: typeof RISK_FLAGS[number][];
  detectedLanguage: 'ko' | 'en' | 'ja' | 'zh' | 'other';
}
```

### __tests__ 모음 (5 파일)

각 테스트 파일은 vitest 사용. 외부 API는 msw로 모킹.

**ai/claude-client.test.ts**: 정상 호출·재시도·타임아웃·예산 초과·잘못된 모델 ID 5가지 시나리오 최소.

**email/header-parser.test.ts**: RFC 5322 표준 메일·X-URM-* 헤더 추출·In-Reply-To 매칭·References 배열 역순 매칭 4가지.

**email/processor.test.ts**: 정상 처리·분류기 비표준 카테고리 반환 시 강제 차단·draft 만료 시간 확인 3가지.

**email/auto-send-gate.test.ts**: AI_AUTO_SEND_ENABLED=false·is_blocked·min_confidence 미달·일일 한도 초과·risk_flags 존재 5가지.

**workers/consultation-worker.test.ts**: pg_notify 수신 → strategy_advisor 호출 → response_strategies+strategy_actions+tasks 생성까지 통합.

---

## 코드 작성 표준 (절대 준수)

1. **TypeScript strict 모드**: `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`
2. **모든 외부 API 호출 try-catch**: 명시적 에러 클래스 (ClaudeApiError, TabsMailerError 등)
3. **환경변수**: `lib/env.ts`의 zod 검증 통과한 값만 사용. `process.env.X` 직접 접근 0건
4. **비동기**: Promise 모두 await 명시. `void` 캐스팅 금지 (의도적 fire-and-forget은 명시적 주석)
5. **로깅**: `console.log` 대신 `lib/logger.ts` 또는 minimal `pino` 패턴 사용 (있으면 사용, 없으면 console.log를 logger로 wrapping해서 로그 레벨 분기)
6. **JSDoc**: 모든 export 함수·클래스·인터페이스에 한국어 또는 영어 주석. 일관성 있게.
7. **테스트**: 각 모듈에 단위 테스트 최소 1개. 외부 API는 모킹.
8. **이름 규칙**:
   - 파일: kebab-case (`claude-client.ts`)
   - 클래스: PascalCase (`ClaudeClient`)
   - 함수·변수: camelCase
   - 상수: UPPER_SNAKE_CASE
   - 타입·인터페이스: PascalCase
9. **불변성**: 입력 파라미터 변형 금지. 새 객체 반환.
10. **DB 접근**: 모든 쿼리는 organization_id 기반 RLS 컨텍스트 가정 (service_role 사용 시 명시)

---

## 응답 길이 처리

이 작업의 산출물은 단일 응답에 들어가지 않습니다. 다음과 같이 분할:

- **Part 1/5**: types/* (3 파일) + lib/env.ts + lib/ai/claude-client.ts + lib/ai/cost-tracker.ts
- **Part 2/5**: lib/ai/pii-masker.ts + lib/ai/prompt-renderer.ts + lib/email/tabs-mailer.ts
- **Part 3/5**: lib/email/mailcarrier.ts + lib/email/header-parser.ts + 테스트 (header-parser, mailcarrier)
- **Part 4/5**: lib/email/processor.ts + lib/email/auto-send-gate.ts + 테스트 (processor, auto-send-gate)
- **Part 5/5**: workers/* (3 파일) + workers 테스트 + package.json/tsconfig/eslint/vitest 설정 + 자체 검증 표

각 Part 끝에 "다음 응답에서 Part X+1 계속. 사용자가 '계속'이라고 응답하면 진행" 명시.

---

## 절대 금지

❌ "각 모듈은 동일한 패턴이므로 A만 보여드립니다"
❌ "// 이하 다른 모듈 동일"
❌ "// TODO: 실제 구현"
❌ TypeScript 코드가 끝맺음 없이 잘리는 것
❌ 함수 시그니처만 있고 본문이 비어 있음
❌ "전체 코드는 zip으로 제공" 같은 회피
❌ Mock 데이터에 placeholder UUID(`00000000-...`)만 사용
❌ 구버전 모델명 (claude-3-opus, claude-opus-4-5 등)
❌ 카테고리 명명을 material_request / meeting_request 등으로 (표준은 information_request / meeting_scheduling)
❌ ai.runs 기록 누락 (모든 AI 호출은 성공·실패 모두 기록)
❌ 환경변수 직접 process.env 접근 (반드시 lib/env.ts 통과)
❌ 테스트 파일 누락 (5개 모두 작성)

---

## 산출물 자체 검증 (필수)

응답 끝에 다음 정보를 포함:

### 1. 완성도 카운트 표

| 모듈 | 파일 | 작성 여부 | 줄 수 | export 함수·클래스 수 | 테스트 케이스 수 |
|------|------|-----------|-------|----------------------|-----------------|
| 타입 | types/ai.ts | ✅/❌ | N | N | — |
| 타입 | types/email.ts | | | | — |
| 타입 | types/classification.ts | | | | — |
| 환경 | lib/env.ts | | | | — |
| A | lib/ai/claude-client.ts | | | | N |
| A | lib/ai/pii-masker.ts | | | | — |
| A | lib/ai/prompt-renderer.ts | | | | — |
| A | lib/ai/cost-tracker.ts | | | | — |
| B | lib/email/tabs-mailer.ts | | | | — |
| C | lib/email/mailcarrier.ts | | | | — |
| C | lib/email/header-parser.ts | | | | N |
| D | lib/email/processor.ts | | | | N |
| D | lib/email/auto-send-gate.ts | | | | N |
| E | workers/consultation-worker.ts | | | | N |
| E | workers/draft-expiry-worker.ts | | | | — |
| E | workers/mail-merge-worker.ts | | | | — |
| 설정 | package.json·tsconfig·eslint·vitest | | | | — |

### 2. 정적 검증 통과 보고

다음 7개 정적 분석이 모두 통과해야 함:

```bash
# 1. TypeScript 컴파일 에러 0건
pnpm exec tsc --noEmit
# 기대: no output (0 errors)

# 2. ESLint 에러 0건
pnpm exec eslint src/ workers/
# 기대: 0 errors (warning 허용)

# 3. 모델명 정확성
grep -hoE "claude-[a-z0-9-]+" src/ workers/ -r | sort -u
# 기대: claude-haiku-4-5-20251001, claude-opus-4-7, claude-sonnet-4-6 만

# 4. 비표준 카테고리 0건
grep -rE "(material_request|meeting_request|simple_reply|contract_discussion)" src/ workers/
# 기대: 결과 없음

# 5. 환경변수 직접 접근 0건
grep -rE "process\.env\.[A-Z]" src/ workers/ | grep -v "lib/env.ts"
# 기대: 결과 없음

# 6. ai.runs INSERT 호출 존재
grep -rE "from\(['\"]runs|insert.*runs|ai\.runs" src/lib/ai/
# 기대: claude-client.ts에서 최소 2건 (성공·실패 경로)

# 7. TODO 주석 0건
grep -rE "TODO|FIXME|XXX" src/ workers/
# 기대: 결과 없음
```

### 3. 테스트 통과 보고

```bash
pnpm test
# 기대: 모든 테스트 통과 (각 파일 최소 1 케이스)
# 5개 테스트 파일 × 평균 4 케이스 = 약 20 케이스
```

자체 검증 수행 후 결과를 응답 끝에 표로 첨부.
