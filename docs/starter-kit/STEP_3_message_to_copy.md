안녕하세요. URM Platform의 STEP 3 — 핵심 인프라 코드(TypeScript)를 의뢰합니다.

## 컨텍스트

이전 세션에서 다음을 모두 완료했습니다:
- STEP 1: 데이터베이스 스키마 13 SQL 패키지 (sql_completion/, 7,385줄, production-ready)
- STEP 2: investor/buyer × ko/en/ja Reply Drafter 6개 + brand_voice few_shot_examples 30 페어
- 표준 프롬프트 v2.0 (안티-회피 요구사항 포함)
- partner/customer/crowdfunding/product_launch/sales 모듈 Reply Drafter 15개 (ai_prompts_supplement/)
- 코드 가이드 (urm_supplement/00_Review_and_Supplement.md, 1,302줄)

이번 세션에서는 STEP 3 — Next.js 14 / TypeScript 5 기반 백엔드 인프라 코드를 작성합니다.
프론트엔드(Phase 1~3)는 STEP 4-6에서 별도 진행.

## 사전 조건

첨부된 5개 문서를 시스템 컨텍스트로 사용해주세요:
1. 00_anti_evasion_requirements.md — 회피 방지 요구사항 (필수 준수)
2. 01_master_system_prompt.md — 시스템 명세 (절대 변경 금지)
3. 04_task_email_integration.md — 본 작업의 상세 요구사항
4. 00_Review_and_Supplement.md — 1,302줄 코드 가이드 (STEP 3 직접 참조)
5. 004_communications_and_activities.sql — 인프라 코드가 read/write할 communications/meetings/tasks 스키마

## 응답 시작 시 필수 약속

응답 첫 줄에 다음 5개 약속을 정확히 그대로 명시해주세요. 약속 없이 작업을 시작하면 산출물 전체를 거부합니다:

"본 작업의 안티-회피 요구사항(00)을 정독했고, 다음을 약속합니다:
1. 요청된 모든 항목을 실제 코드로 작성하며, '동일 패턴' 회피를 사용하지 않습니다.
2. 모델명은 claude-opus-4-7 / claude-haiku-4-5-20251001 만 사용합니다.
3. 카테고리는 마스터 프롬프트 표준 10개만 사용합니다.
4. 산출물 끝에 완성도 카운트 표를 첨부합니다.
5. 길이가 길면 'Part X/N' 형식으로 분할하여 모두 출력합니다."

## 작성 의뢰 — 5개 모듈 + 타입·테스트

전체 디렉터리 구조 (`src/` 기준):

src/
├── lib/
│   ├── ai/
│   │   ├── claude-client.ts          (A) Anthropic API 래퍼
│   │   ├── pii-masker.ts             (A) PII 탐지·마스킹·복원
│   │   ├── prompt-renderer.ts        (A) brand_voice·knowledge_chunks 합성
│   │   └── cost-tracker.ts           (A) 비용·토큰 집계 → ai.runs 기록
│   ├── email/
│   │   ├── tabs-mailer.ts            (B) TABS Mailer 4 SMTP 어댑터
│   │   ├── mailcarrier.ts            (C) MailCarrier 7 IMAP 어댑터
│   │   ├── header-parser.ts          (C) RFC 5322 / message-id / in_reply_to / thread 매칭
│   │   ├── processor.ts              (D) 수신 → 분류 → 스레드 매칭 → draft 생성 파이프라인
│   │   └── auto-send-gate.ts         (D) ai.auto_send_rules 평가 (10 카테고리)
│   └── db/
│       └── (Supabase 클라이언트는 기존 패턴 따름, 본 의뢰에서는 제외)
├── workers/
│   ├── consultation-worker.ts        (E) pg_notify('consultation_created') 수신 → strategy_advisor 호출
│   ├── draft-expiry-worker.ts        (E) 매시간 ai.expire_stale_drafts() 실행
│   └── mail-merge-worker.ts          (E) mail_merge_jobs 큐 처리
├── types/
│   ├── ai.ts                          ai.agents·ai.runs·ai.drafts·ai.brand_voice 타입
│   ├── email.ts                       inbound·outbound·thread·attachment 타입
│   └── classification.ts              표준 10 카테고리 enum + risk_flags
└── __tests__/
    ├── ai/claude-client.test.ts
    ├── email/header-parser.test.ts
    ├── email/processor.test.ts
    ├── email/auto-send-gate.test.ts
    └── workers/consultation-worker.test.ts

### 모듈 A — Claude Client (lib/ai/)

**claude-client.ts**:
- `class ClaudeClient` (Anthropic SDK 래핑)
- 메서드: `complete(agentRole, contextBundle, options)` — 시그니처 명확
- 모델 선택: `agent.model` 우선, 실패 시 `agent.fallback_model`로 1회 재시도
- 재시도 정책: 429·5xx에 대해 exponential backoff (1s, 2s, 4s, 최대 3회)
- 타임아웃: 60초 hard timeout
- 출력: `{ content, raw, runId, latencyMs, tokensIn, tokensOut, costUsd }`
- 모든 호출은 `ai.runs`에 기록 (성공·실패 모두)
- 모델 ID 검증: claude-opus-4-7 / claude-haiku-4-5-20251001 / claude-sonnet-4-6 외에는 throw

**pii-masker.ts**:
- 주민등록번호·여권번호·신용카드·전화·이메일 패턴 탐지
- 마스킹 토큰 발급 (`{{PII_001}}` 등 → 원문 매핑은 메모리 또는 짧은 TTL 캐시)
- 복원: AI 출력에서 토큰을 원문으로 되돌림
- 마스킹 대상은 `ai.runs.pii_masked = true`, 카테고리는 `pii_categories_detected`에 기록

**prompt-renderer.ts**:
- 입력: agent_id + party_id + engagement_id + inbound_message
- DB 조회: `brand_voice` (모듈+언어 매칭) + `knowledge_chunks` 검색 (cosine top_k=8) + 최근 thread 5개
- 시스템 프롬프트는 `agent.system_prompt` 그대로, 사용자 메시지에 컨텍스트 번들을 구조화 JSON으로 주입
- Liquid 변수 치환은 본 모듈에서 수행 (email-templates 본문 렌더링 시 재사용)

**cost-tracker.ts**:
- 모델별 단가 테이블 상수 (2026년 5월 기준)
- 호출당 비용 계산 → `ai.runs.cost_usd` 갱신
- 일별·월별 조직 한도 체크 (한도 초과 시 throw)

### 모듈 B — TABS Mailer 4 어댑터 (lib/email/tabs-mailer.ts)

- `class TabsMailerClient`
- 인증 방식은 환경변수로 분기 (SASL PLAIN / LOGIN / IP 화이트리스트) — STEP 7 시작 전 탭스랩 확정 필요
- 메서드:
  - `createCampaign(params)` → `tabs_campaign_id` 반환
  - `sendOne(params)` → 단건 발송, message_id 반환
  - `getCampaignStats(tabsCampaignId)` → progress jsonb 형식으로 정규화
  - `syncCampaignToMergeJob(jobId)` → mail_merge_jobs.progress 갱신
- 사용자 정의 헤더 추가: `X-URM-Engagement-Id`, `X-URM-Communication-Id`, `X-URM-Auto-Send` (true/false) — 헤더 통과 여부 미확인 시 mock에서 항상 통과하는 설정 사용
- Quiet hours 체크: mail_merge_jobs.quiet_hours 기준으로 발송 전 차단·재스케줄

### 모듈 C — MailCarrier 7 어댑터 (lib/email/mailcarrier.ts)

- `class MailCarrierClient` (IMAP IDLE 사용, 미지원 시 폴링 30초로 폴백)
- 수신 메시지를 `app.communications`에 INSERT (direction='inbound', channel='email')
- 헤더 파싱:
  - `Message-ID` → `communications.message_id` (UNIQUE)
  - `In-Reply-To`, `References` → 기존 thread_id 매칭
  - 신규 thread는 새 UUID 부여
- 첨부 처리: `attachments` 테이블 + Supabase Storage 업로드
- `header-parser.ts`로 분리: 순수 함수 (테스트 용이)

### 모듈 D — 메일 처리 파이프라인 (lib/email/processor.ts + auto-send-gate.ts)

**processor.ts**:
- 진입점: `processInbound(communicationId)`
- 단계: ① PII 마스킹 → ② 분류기 (Haiku) 호출 → ③ 스레드 매칭 보강 → ④ 회신가 (Opus) 호출 → ⑤ ai.drafts 생성 (expires_at = NOW() + 7일)
- 분류기 출력은 표준 10 카테고리만 허용 (위반 시 throw → drafts.requires_human_approval = true 강제)
- 비동기 큐로 분리 가능하게 함수 단위 작성 (CPU 작업과 I/O 작업 분리)

**auto-send-gate.ts**:
- 입력: classification + organization_id + party_id + draft
- 평가 순서:
  1. ai.auto_send_rules (조직별 카테고리 정책) — is_blocked 체크
  2. min_confidence 비교 (예: 0.92 미만이면 차단)
  3. blocked_keywords_in_body 정규식 매칭
  4. daily_limit / hourly_limit / per_party_daily_limit 체크
  5. requires_calendar_data 시 미팅 가용성 검증
  6. requires_human_approval=true 시 무조건 차단
- 출력: `{ allowed, reasons[], blockedRules[] }` — 차단 시 명확한 사유 배열

### 모듈 E — 백그라운드 워커 (workers/)

- consultation-worker.ts: `LISTEN consultation_created` → strategy_advisor 호출 → response_strategies + strategy_actions INSERT
- draft-expiry-worker.ts: 매시간 `SELECT ai.expire_stale_drafts()`
- mail-merge-worker.ts: `mail_merge_jobs` 큐 폴링 → tabs_mailer.createCampaign + 진행상태 갱신
- 모든 워커는 graceful shutdown 지원 (SIGTERM 처리)
- 에러 시 dead-letter (ai.runs.status = 'failed') + alert 이벤트 발행

## 코드 작성 표준

- TypeScript strict mode (`strict: true`, `noUncheckedIndexedAccess: true`)
- 모든 외부 API 호출은 try-catch + 명시적 에러 타입 (`ClaudeApiError`, `TabsMailerError` 등)
- 환경변수는 `lib/env.ts`에서 zod 스키마로 검증 (런타임 누락 시 즉시 throw)
- 모든 함수는 JSDoc 주석 (한국어 또는 영어, 일관성 있게)
- 단위 테스트는 vitest (또는 jest), 외부 API는 모킹 (msw 또는 nock)
- 통합 테스트는 별도 Supabase 인스턴스에서 실행 (sql_completion 적용된 상태 가정)

## 응답 분할 권장

산출물이 단일 응답에 들어가지 않을 가능성이 높습니다. 다음과 같이 분할:
- Part 1/5: 모듈 A (claude-client·pii-masker·prompt-renderer·cost-tracker) + types/ai.ts + types/classification.ts
- Part 2/5: 모듈 B (tabs-mailer) + types/email.ts
- Part 3/5: 모듈 C (mailcarrier·header-parser) + 테스트 (header-parser, mailcarrier)
- Part 4/5: 모듈 D (processor·auto-send-gate) + 테스트 (processor·auto-send-gate)
- Part 5/5: 모듈 E (3개 워커) + 테스트 (consultation-worker) + 자체 검증 표

각 Part 끝에 "다음 응답에서 Part X+1 계속. 사용자가 '계속'이라고 응답하면 진행" 명시.

## 절대 금지 사항

❌ "각 모듈은 동일 패턴이므로 A만 보여드립니다"
❌ "// TODO: 실제 구현"
❌ TypeScript 코드가 끝맺음 없이 잘리는 것
❌ 함수 시그니처만 있고 본문이 비어 있음
❌ "전체 코드는 zip으로 제공" 같은 회피
❌ 구버전 모델명 (claude-3-opus, claude-opus-4-5 등)
❌ 카테고리 명명을 material_request / meeting_request 등으로 (표준은 information_request / meeting_scheduling)
❌ ai.runs 기록 누락 (모든 AI 호출은 성공·실패 모두 기록)
❌ 환경변수 직접 process.env 접근 (반드시 env 검증 모듈 통과)

## 산출물 자체 검증 (응답 끝에 필수)

### 완성도 카운트 표

| 모듈 | 파일 | 작성 여부 | 줄 수 | 함수 수 | 테스트 케이스 수 |
|------|------|-----------|-------|---------|-----------------|
| A | lib/ai/claude-client.ts | ✅/❌ | N | N | N |
| A | lib/ai/pii-masker.ts | | | | |
| A | lib/ai/prompt-renderer.ts | | | | |
| A | lib/ai/cost-tracker.ts | | | | |
| B | lib/email/tabs-mailer.ts | | | | |
| C | lib/email/mailcarrier.ts | | | | |
| C | lib/email/header-parser.ts | | | | |
| D | lib/email/processor.ts | | | | |
| D | lib/email/auto-send-gate.ts | | | | |
| E | workers/consultation-worker.ts | | | | |
| E | workers/draft-expiry-worker.ts | | | | |
| E | workers/mail-merge-worker.ts | | | | |
| 타입 | types/ai.ts·email.ts·classification.ts | | | | |

### 검증 통과 보고

다음 정적 분석이 모두 통과해야 함:

1. `tsc --noEmit` 에러 0건
2. `eslint .` 에러 0건 (warning은 허용)
3. 사용된 모델명 grep 결과: claude-opus-4-7, claude-haiku-4-5-20251001, claude-sonnet-4-6 만
4. 카테고리 사용 grep 결과: 표준 10개 외 0건
5. `ai.runs` INSERT 호출이 모든 Claude API 호출 경로에 존재
6. 환경변수 직접 접근(`process.env.X`) 0건 — 모두 검증 모듈 경유
7. 테스트 커버리지 (단위 테스트 통과 개수 보고)

준비되시면 약속 5개부터 명시하고 Part 1/5로 작업을 시작해주세요.

