# 01 — 마스터 시스템 프롬프트 (최종판 v2.0)

> **이 문서는 모든 작업의 컨텍스트입니다. 모든 task 프롬프트(02~06) 실행 전에 이 문서가 시스템 컨텍스트에 로드되어 있어야 합니다.**

---

## 1. 프로젝트 정체성

### 1.1 프로젝트명
**Universal Relationship Management Platform (URM Platform)**

### 1.2 핵심 철학
**"코어는 공유, 도메인은 분리"**

7개의 비즈니스 도메인(investor, buyer, partner, customer, crowdfunding, product_launch, sales)을 단일 데이터 모델 위에서 운영하되, 각 모듈의 도메인 특성을 잃지 않도록 설계.

### 1.3 핵심 가치
- **사람이 운전대를 잡고, AI가 보조** — AI는 자율 시스템이 아닌 보조 도구
- **모듈 추가 시 코어 변경 최소화** — `module_data` JSONB와 도메인 테이블로 확장
- **추적성과 감사** — 모든 데이터 변경, AI 호출, 메일 발송이 기록됨

---

## 2. 기술 스택 (변경 금지)

### 2.1 프론트엔드
- **Next.js 14+** (App Router)
- **TypeScript strict 모드**
- **Tailwind CSS + shadcn/ui**
- **TanStack Query/Table**
- **Zustand** (상태 관리)
- **Liquid 템플릿 엔진** (LiquidJS)
- **React Hook Form + Zod**

### 2.2 백엔드·데이터
- **Supabase** (PostgreSQL 15+, Auth, Storage, RLS)
- **pgvector** (RAG 임베딩, HNSW 인덱스)
- **Next.js Route Handlers / Server Actions**
- **BullMQ + Redis** (비동기 작업)

### 2.3 이메일 인프라 (자체 보유, 변경 불가)
- **TABS Mailer 4** — 발송 전용 (DKIM·트래킹·시간당 10만 통, MS SQL Server 통계 DB)
- **MailCarrier 7** — 수신 전용 (IMAP 폴링)

### 2.4 AI 모델 (정확한 ID 사용 필수)

| 용도 | 모델 ID | 단가 (USD per 1M tokens) |
|------|---------|--------------------------|
| 메인 작성·전략 | `claude-opus-4-7` | $15 input / $75 output |
| 분류·요약·라이트 | `claude-haiku-4-5-20251001` | $0.8 input / $4 output |
| 균형 (옵션) | `claude-sonnet-4-6` | $3 input / $15 output |
| 임베딩 | OpenAI `text-embedding-3-large` (1536차원) | $0.13 per 1M tokens |

❌ **다음 모델명은 사용 금지 (존재하지 않거나 구버전)**:
`claude-3-opus`, `claude-3-haiku`, `claude-opus-4-5`, `claude-haiku-4-5` (suffix 없음), `Claude-Opus-4`, `claude-3.5-sonnet`

### 2.5 호스팅
- **Vercel** (Next.js)
- **Railway 또는 Fly.io** (워커, IMAP 폴러, 스크래퍼)
- **Supabase Cloud** (DB, Auth, Storage)

---

## 3. 데이터 모델 (절대 명세)

### 3.1 7개 모듈 ENUM (변경 금지)

```sql
CREATE TYPE app.module_type AS ENUM (
    'investor',         -- 투자사
    'buyer',            -- 글로벌 바이어
    'partner',          -- 협력사
    'customer',         -- 고객
    'crowdfunding',     -- 크라우드펀딩
    'product_launch',   -- 신제품 출시
    'sales'             -- 판매
);
```

### 3.2 코어 테이블 (모든 모듈 공유)

| 테이블 | 역할 |
|--------|------|
| `app.organizations` | 멀티테넌트 루트 |
| `app.users` | Supabase auth.users 확장 |
| `app.parties` | **외부 엔티티 통합 마스터** (모든 모듈) |
| `app.contacts` | 거래처 담당자 |
| `app.engagements` | **관계 진행 트래킹 핵심** |
| `app.pipeline_definitions` | 파이프라인 정의 |
| `app.pipeline_stages` | 파이프라인 단계 |
| `app.communications` | 이메일·LinkedIn·전화 통합 |
| `app.meetings` | 미팅 기록 |
| `app.tasks` | To-do 통합 |
| `app.attachments` | 범용 파일 첨부 |

**핵심 원칙**: `parties`, `engagements` 등은 모든 모듈이 공유. `module` ENUM 컬럼으로 구분, `module_data` JSONB 컬럼으로 모듈별 확장 속성.

### 3.3 모듈별 도메인 테이블 (강한 타입이 필요한 데이터)

| 모듈 | 테이블 |
|------|--------|
| investor | `investor_profile`, `investor_portfolio_companies` |
| buyer | `buyer_profile`, `buyer_inquiries`, `quotations` |
| partner | `partner_profile`, `partner_audits`, `partner_capabilities` |
| customer | `customer_profile`, `customer_segments`, `customer_purchases` |
| crowdfunding | `crowdfunding_campaigns`, `campaign_rewards`, `campaign_backers`, `campaign_updates` |
| product_launch | `product_launches`, `launch_milestones`, `launch_tasks`, `launch_risks` |
| sales | `products`, `sales_orders`, `sales_order_items`, `shipments`, `invoices`, `payments` |

### 3.4 AI 시스템 테이블 (`ai` 스키마)

| 테이블 | 역할 |
|--------|------|
| `ai.agents` | AI 에이전트 정의 (역할별 모델·프롬프트·파라미터) |
| `ai.runs` | **모든 AI 호출 감사 로그** (필수, 90일+ 보관) |
| `ai.drafts` | AI 생성 메일 초안 (사람 검토 대기) |
| `ai.knowledge_chunks` | RAG 지식베이스 (`vector(1536)` + HNSW) |
| `ai.auto_send_rules` | 자동발송 정책 |
| `ai.brand_voice` | 모듈·언어별 브랜드 보이스 |

### 3.5 표준 컬럼 규칙 (모든 비즈니스 테이블 필수)

```sql
CREATE TABLE app.example (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL REFERENCES app.organizations (id) ON DELETE RESTRICT,
    -- ... 비즈니스 컬럼 ...
    module_data     jsonb       NOT NULL DEFAULT '{}',     -- 모듈별 확장
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),
    created_by      uuid        REFERENCES app.users (id) ON DELETE SET NULL,
    updated_by      uuid        REFERENCES app.users (id) ON DELETE SET NULL,
    deleted_at      timestamptz                            -- 소프트 삭제
);
```

### 3.6 명명 규칙 (절대 준수)

- 테이블명: `snake_case`, 복수형
- FK 제약: `fk_{테이블}_{컬럼}` (예: `fk_engagements_party_id`)
- 인덱스: `idx_{테이블}_{컬럼}` (예: `idx_communications_engagement_id`)
- CHECK 제약: `chk_{테이블}_{설명}` (예: `chk_engagements_probability_pct`)
- UNIQUE 제약: `uq_{테이블}_{컬럼들}`
- 트리거: `trg_{테이블}_{목적}` (예: `trg_parties_updated_at`)

---

## 4. AI 안전·품질 원칙 (절대 준수)

### 4.1 Human-in-the-Loop이 기본값

**모든 AI 생성 콘텐츠는 사람의 검토·승인 후에만 외부로 나갑니다.**

- 자동 발송이 허용되는 경우: 매우 제한적 (정책으로 명시된 카테고리만)
- 자동 발송 차단 카테고리: `price_negotiation`, `contract_terms`, `rejection`, `complaint`, `introduction`, `follow_up`, `other`

### 4.2 표준 분류 카테고리 (10개, 변경 금지)

```
information_request, meeting_scheduling, simple_acknowledgment,
price_negotiation, contract_terms, rejection, complaint,
introduction, follow_up, other
```

분류기 출력, `auto_send_rules.classification_category`, Reply Drafter의 risk 분기 처리에서 **모두 동일한 명명을 사용**해야 합니다.

### 4.3 모든 AI 호출은 `ClaudeClient` 래퍼 통과 (필수)

직접 `anthropic.messages.create()` 호출 금지. 다음을 자동으로 수행하는 래퍼 사용:

1. **호출 시작을 `ai.runs`에 기록** (status='running')
2. **PII 마스킹** — 주민번호·여권·계좌·카드번호를 입력에서 제거
3. **실제 API 호출** — Zero Data Retention 헤더 포함
4. **출력 검증** — JSON 응답 형식 강제 시 파싱·스키마 검증
5. **비용 계산 + `ai.runs` 업데이트** (status='completed' 또는 'failed')

### 4.4 자동발송 정책 enforcement (코드로 강제)

`auto_send_rules` 테이블의 정책은 데이터일 뿐. **실제 enforcement는 코드로**:

- Kill switch (`system_flags.ai_auto_send_kill_switch`) 우선 확인
- 카테고리별 `min_confidence` 임계값
- 카테고리별 `daily_limit`
- 거래처별 24시간 자동발송 횟수 제한
- 본문 키워드 차단 (`blocked_keywords_in_body`)

### 4.5 AI 비용 가시화·통제

- 월 $500 도달 → Slack 알림
- 월 $1,000 도달 → Opus 호출을 Sonnet으로 자동 다운그레이드
- 월 $2,000 도달 → 자동발송 전면 중단

### 4.6 AI 답장 품질 점진적 개선

운영 시 단계별로:

1. **첫 1~2개월**: 모든 답장 사람 검토 의무
2. **분기별 추적**: 카테고리별 승인률·수정률
3. **점진적 자동화**: 승인률 95% + 수정률 10% 이하 카테고리만 자동발송 점진 허용
4. **학습 루프**: 사람이 수정한 답장은 자동으로 few-shot 후보로 등록

---

## 5. 표준 API 패턴

### 5.1 라우팅 규칙

```
/api/{module}/parties              # 거래처 CRUD
/api/{module}/engagements          # 인게이지먼트 CRUD
/api/{module}/engagements/{id}/move-stage   # 단계 이동
/api/communications/send           # 메일 발송 (모든 모듈 공통)
/api/ai-drafts/{id}/approve        # AI 초안 승인
/api/ai-drafts/{id}/reject         # AI 초안 거부
/api/scraping/jobs                 # 스크래핑 잡
```

### 5.2 응답 형식

```typescript
// 성공
{ data: T, meta?: { total, page, limit } }

// 실패
{ error: { code: string, message: string, details?: unknown } }
```

### 5.3 Server Action 패턴

모든 mutation은 다음 단계 거침:

1. Zod 스키마 검증
2. 권한 확인 (`requirePermission(resource, action)`)
3. 트랜잭션 내 DB 작업
4. 외부 호출 (메일 발송 등)은 트랜잭션 외부
5. 캐시 무효화
6. 감사 로그 기록 (자동, 트리거로 처리)

---

## 6. 이메일 워크플로 (정확한 명세)

### 6.1 발송 (TABS Mailer 4)

```
사용자가 메일 작성/AI 초안 승인
  → 템플릿 렌더링 (Liquid)
  → HTML 살균 (DOMPurify)
  → 트래킹 픽셀·클릭 래핑 삽입
  → communications 테이블 INSERT (status='sending')
  → TABS Mailer 4 SMTP 발송 (Message-ID, X-TABS-Campaign, X-Engagement-Id 헤더)
  → communications UPDATE (sent_at, status='sent')
```

### 6.2 수신 (MailCarrier 7)

```
IMAP 폴링 또는 IDLE
  → 새 메일 헤더 파싱 (Message-ID, In-Reply-To, References)
  → 멱등성 검사 (Message-ID UNIQUE)
  → 스레드 매칭 (In-Reply-To → 우리 DB의 message_id)
  → 매칭 실패 시 발신자 이메일로 contact 매칭
  → 본문 추출 (HTML/Plain 모두 저장)
  → 첨부 → Supabase Storage
  → communications INSERT (direction='inbound')
  → AI 분류·초안 생성 큐에 추가
```

### 6.3 트래킹

- 자체 트래킹 픽셀: `/track/open/{message_id}.gif`
- 클릭 래핑: `/track/click/{message_id}?url={original}`
- TABS Mailer 4 통계 DB와 5분 주기 동기화 (이중 트래킹)

---

## 7. 스크래핑 컴플라이언스

### 7.1 허용 소스
- 산업 협회 회원사 디렉토리 (CEPI, AF&PA, JPA, KPIA 등)
- 공시 시스템 (SEC EDGAR, DART)
- GLEIF LEI 데이터베이스
- 회사 공식 사이트 (About, Contact, IR 페이지)

### 7.2 금지 소스 (코드 + DB CHECK 제약 양쪽 차단)

**LinkedIn, PitchBook, CB Insights, Crunchbase**

```sql
-- DB 레벨 차단
CONSTRAINT chk_scraping_sources_no_blocked_domains
    CHECK (base_url !~* '(linkedin\.com|pitchbook\.com|cbinsights\.com|crunchbase\.com)')
```

### 7.3 운영 안전장치

- robots.txt 24시간 캐시·존중
- 도메인별 속도 제한 (초당 1회 기본)
- HTTP 403/429 → 자동 백오프, 24시간 후 재시도
- User-Agent 명시: `"{회사명}-Research-Bot/1.0 (contact: {이메일})"`
- 본문 통째 저장 금지 — 사실 데이터(회사명·주소·웹사이트)만

### 7.4 중복 처리

- 정규화 후 매칭 점수 계산
- 점수 95%+ → 자동 병합
- 점수 70~95% → `dedup_review_queue`에 등록 (사람 검토)
- 점수 <70% → 신규 INSERT

---

## 8. 다국어 지원 명세

### 8.1 지원 언어
한국어 (`ko`), 영어 (`en`), 일본어 (`ja`)

### 8.2 회신 언어 결정 우선순위

1. `contacts.preferred_language` (명시된 경우)
2. 수신 메일의 `language_detected` (분류기가 감지)
3. `parties.country` 기본 언어 매핑
4. 조직 기본 언어

### 8.3 다국어 자산
- Reply Drafter 프롬프트: 모듈 7 × 언어 3 = **21개 (모두 작성, 누락 불가)**
- Brand Voice: 모듈 7 × 언어 3 = **21개 (모두 작성, 누락 불가)**
- 메일 템플릿: 같은 템플릿의 언어별 버전 자동 선택

---

## 9. 컴플라이언스·보안

### 9.1 RLS (모든 비즈니스 테이블 필수)

```sql
ALTER TABLE app.{table} ENABLE ROW LEVEL SECURITY;

CREATE POLICY pol_{table}_org ON app.{table}
    FOR ALL USING (organization_id = app.current_organization_id());
```

`organization_id`에 인덱스 필수 (RLS 성능):
```sql
CREATE INDEX idx_{table}_organization_id ON app.{table} (organization_id) WHERE deleted_at IS NULL;
```

### 9.2 PII 보호

- AI 호출 입력에서 자동 마스킹: 주민번호, 여권, 계좌, 카드번호
- 마스킹 함수는 한국·일본·미국 형식 모두 처리
- 마스킹 여부를 `ai.runs.pii_masked`에 기록

### 9.3 감사 로그

- `audit.change_log` 테이블에 모든 INSERT/UPDATE/DELETE 자동 기록
- `audit.log_change()` 함수가 모든 비즈니스 테이블에 트리거로 부착
- 90일+ 보관, 조직 소유자만 조회 가능

### 9.4 백업

- Supabase PITR (Point-in-Time Recovery) 활성화
- `parties`, `communications`, `ai.drafts`는 주간 외부 dump (S3)

---

## 10. 코딩 관례

### 10.1 TypeScript

- strict 모드, `any` 금지
- Zod 스키마로 모든 외부 입력 검증
- Server Action 응답은 `{data}` 또는 `{error}` 형식

### 10.2 SQL

- 모든 시간은 `timestamptz`
- 모든 PK는 `uuid` (`gen_random_uuid()`)
- 명시적 제약·인덱스·트리거 이름
- `COMMENT ON TABLE`, `COMMENT ON COLUMN`으로 한글 설명

### 10.3 Python (스크래퍼)

- Python 3.11+
- type hints 필수
- 비동기 (asyncio + httpx + Playwright)
- 모든 raw 응답을 `scraping_raw`에 보존

---

## 11. 환경 변수 표준

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Anthropic
ANTHROPIC_API_KEY=
ANTHROPIC_MODEL_OPUS=claude-opus-4-7
ANTHROPIC_MODEL_HAIKU=claude-haiku-4-5-20251001

# OpenAI (임베딩만)
OPENAI_API_KEY=
OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# TABS Mailer 4
TABS_MAILER_HOST=
TABS_MAILER_PORT=587
TABS_MAILER_USER=
TABS_MAILER_PASSWORD=
TABS_MAILER_FROM_DEFAULT=
TABS_MAILER_DB_HOST=
TABS_MAILER_DB_USER=
TABS_MAILER_DB_PASSWORD=
TABS_MAILER_DB_NAME=

# MailCarrier 7
MAILCARRIER_HOST=
MAILCARRIER_PORT=993
MAILCARRIER_USER=
MAILCARRIER_PASSWORD=
MAILCARRIER_USE_TLS=true

# 트래킹
MAIL_DOMAIN=
TRACKING_BASE_URL=

# Redis
REDIS_URL=

# 모니터링
SENTRY_DSN=
SLACK_WEBHOOK_URL=

# 기능 플래그
AI_AUTO_SEND_ENABLED=false
SCRAPING_ENABLED=true
```

---

## 12. 사업 컨텍스트

### 12.1 현재 사업 영역
- **키틴/키토산 추출 사업**: 동남아(태국·미얀마) 새우 껍질 소싱 → 추출 공정 → 글로벌 판매
- **글로벌 제지 산업 리서치**: Printing & Writing, Packaging & Board, Specialty, Tissue & Hygiene 세그먼트
- **투자 유치**: Pre-seed ~ Series A 단계

### 12.2 우선 강화 모듈
1. **investor** — 진행 중인 투자 유치
2. **buyer** — 키토산 글로벌 영업
3. **partner** — 동남아 새우 껍질 공급사
4. **customer** — 기존 고객 관리

`crowdfunding`, `product_launch`, `sales` 모듈은 후순위로 구현.

### 12.3 다국어 메일 비중
- **한국어**: 국내 협력사·투자자
- **영어**: 글로벌 바이어·기관 투자자 (대다수)
- **일본어**: 일본 제지사 (오지 페이퍼 등), 일부 일본 투자자

---

## 13. 참조 문서

이 마스터 프롬프트와 함께 다음 문서가 작업의 기준이 됩니다:

- `00_anti_evasion_requirements.md` — 회피 방지 (모든 작업 필수)
- `02_task_database_schema.md` — DB 스키마 작성 작업
- `03_task_ai_agent_prompts.md` — AI 에이전트 프롬프트 작성
- `04_task_email_integration.md` — 이메일 통합 모듈
- `05_task_scraping_module.md` — 스크래핑 모듈
- `06_task_frontend_nextjs.md` — Next.js 프론트엔드
- `09_verification_checklists.md` — 산출물 검증 체크리스트

---

## 14. 절대 변경 금지 사항

다음은 작업 중 변경이 발견되면 즉시 작업을 중단하고 사용자에게 확인:

1. 7개 모듈 명명 (`investor`, `buyer`, `partner`, `customer`, `crowdfunding`, `product_launch`, `sales`)
2. 10개 분류 카테고리 명명
3. 코어 테이블 이름 (`parties`, `engagements`, `communications` 등)
4. 모델 ID (`claude-opus-4-7`, `claude-haiku-4-5-20251001`)
5. 이메일 인프라 (TABS Mailer 4 발송 전용, MailCarrier 7 수신 전용)
6. 스키마 분리 (`app`, `audit`, `ai`)
