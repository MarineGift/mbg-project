# URM Platform

**솔로 파운더용 통합 CRM/Workflow Automation**
Investor·Buyer·Partner·Customer 4 모듈 (Phase 1) + AI 회신 초안 + Kanban·Inbox·Task·Settings.

---

## Stack

- **Frontend**: Next.js 14 App Router · TypeScript strict · TailwindCSS · shadcn/ui · TanStack Query · React Hook Form + zod · @dnd-kit · next-intl · sonner · Zustand
- **Backend**: Next.js Server Components / Server Actions · Supabase (Postgres 16 + RLS + Realtime + Auth)
- **AI**: Claude API — `claude-opus-4-7` (drafter/strategy), `claude-haiku-4-5-20251001` (classifier/summary), `claude-sonnet-4-6` (fallback)
- **Email**: TABS SMTP relay (테스트는 Mailcarrier mock)
- **i18n**: 한국어 · 영어 · 일본어 (451 키 동기화)

---

## 디렉토리 구조

```
src/
├── app/(app)/                     # 인증 필수 라우트 그룹
│   ├── layout.tsx                 # AppShell + RealtimeProvider mount
│   ├── inbox/                     # 통합 communications (search/filter)
│   ├── drafts/                    # AI 초안 검토 큐 (Part 3, 4)
│   ├── [module]/                  # 동적 module segment (investor/buyer/partner/customer)
│   │   ├── parties/
│   │   ├── parties/new/
│   │   ├── parties/[id]/
│   │   ├── parties/[id]/edit/
│   │   ├── engagements/           # Kanban 보드
│   │   └── engagements/new/
│   ├── engagements/[id]/          # 단일 인게이지먼트 상세 (모듈 segment 없음)
│   ├── tasks/
│   ├── compose/                   # 새 outbound 메일 작성
│   └── settings/                  # profile/language/notifications/organization
├── components/
│   ├── ui/                        # shadcn primitives
│   ├── common/                    # ModuleBadge, StatusBadge, ConfidenceBar, ...
│   ├── layout/                    # AppShell, Sidebar (badge with realtime count), TopBar, UserMenu
│   ├── providers/                 # QueryProvider, IntlProvider, ToastProvider, RealtimeProvider
│   ├── drafts/                    # 큐 리스트, 필터, bulk actions, 상세, diff viewer
│   ├── inbox/                     # 통합 목록, 검색 (디바운스 350ms), 채널/방향 아이콘
│   ├── parties/                   # 헤더, 폼, 통계, 활동 타임라인, 컨택트 dialog
│   ├── engagements/               # Kanban (드래그앤드롭), 상세, 폼, stage history
│   ├── tasks/                     # 테이블, 필터, dialog 폼
│   ├── settings/                  # nav, profile/language/notification 폼
│   └── compose/                   # 새 메일 작성 폼
├── lib/
│   ├── ai/                        # Claude API 클라이언트, cost tracker, PII masker, prompt renderer
│   ├── email/                     # TabsMailer + mock, quiet hours, mailcarrier, processor
│   ├── workers/                   # consultation/draft-expiry/mail-merge background workers
│   ├── auth.ts / supabase/        # Supabase 클라이언트 (server/client/admin/middleware)
│   ├── queries/                   # Server-side data fetching (inbox, drafts, engagements, parties, ...)
│   ├── actions/                   # Server Actions (parties/engagements/contacts/tasks/communications/drafts/profile)
│   ├── stores/                    # Zustand UI store (sidebar, queue selection, realtime count)
│   └── utils.ts, env.ts, ...
├── i18n/                          # next-intl: routing + messages/{ko,en,ja}.json
├── types/                         # AI, email, classification, database, party-detail, engagement, task, inbox, ...
└── __tests__/                     # vitest 159 tests
sql/
└── 013_step3_step4_compat_patch.sql   # STEP 3+4 호환 패치 (custom_access_token_hook, drafts cols 등)
```

---

## 실행 (개발)

### 사전 요구사항

1. Node.js 18+
2. Supabase 프로젝트 (Postgres 16 권장)
3. Anthropic API 키
4. SMTP relay (TABS 또는 Mailcarrier)

### 환경 변수

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

# Anthropic
ANTHROPIC_API_KEY=<key>

# TABS Mailer (SMTP)
TABS_SMTP_HOST=<host>
TABS_SMTP_PORT=587
TABS_SMTP_USER=<user>
TABS_SMTP_PASSWORD=<password>
TABS_SMTP_FROM=<default-from>

# 옵션
URM_QUIET_HOURS_TZ=Asia/Seoul
URM_AUTO_SEND_GLOBAL_DISABLE=false
```

### 마이그레이션 순서 (Supabase SQL editor)

```bash
# STEP 1 — 인프라
000_extensions.sql
001_core_infrastructure.sql       # enum, users, organizations
002_audit_log.sql

# STEP 2 — 비즈니스 도메인
003_core_business.sql              # parties, contacts, ...
004_communications_and_activities.sql
005_engagements.sql                # pipeline_definitions, pipeline_stages, engagements
006_strategy_system.sql
007_modules_seed_data.sql
008_ai_schema.sql                  # ai.drafts, ai.runs
009_fk_constraints.sql

# STEP 3 — AI 시스템
010_step3_ai_drafts_extension.sql
011_step3_ai_runs_metadata.sql
012_step3_rls.sql

# STEP 4 — UI 호환 패치 (필수)
013_step3_step4_compat_patch.sql   # custom_access_token_hook, ai.drafts.auto_send_*, drafts_queue_sort 인덱스
```

### 개발 실행

```bash
npm install
npm run dev       # http://localhost:3000
```

### 테스트

```bash
npm test          # vitest 159 통과
npx tsc --noEmit  # 0 에러
```

### 빌드

```bash
npm run build
npm start
```

---

## 운영자 액션 체크리스트 (필수)

### 🔴 첫 배포 전 반드시 수행

1. **Custom Access Token Hook 활성화**
   - Supabase Dashboard → Authentication → Hooks → "Custom Access Token Hook" 클릭
   - Hook function: `public.custom_access_token_hook` 선택 (migration 013에서 생성됨)
   - 활성화 시 JWT에 `organization_id`, `is_owner`, `preferred_language` 주입됨

2. **모든 기존 사용자 세션 강제 재로그인**
   - JWT가 새 hook을 거치지 않은 사용자는 RLS 정책에 의해 차단됨
   - SQL editor에서: `SELECT auth.uid(), auth.jwt() -> 'app_metadata' -> 'organization_id'` 로 검증

3. **RLS 정책 활성화 확인**
   - SQL editor에서 `SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname IN ('app','ai') AND rowsecurity = false;`
   - 결과가 비어 있어야 함

4. **Realtime publication 등록**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE ai.drafts;
   ALTER PUBLICATION supabase_realtime ADD TABLE app.communications;
   ```

5. **각 조직에 default pipeline 생성**
   - 4개 priority 모듈(investor/buyer/partner/customer)별로 `pipeline_definitions` 1행 + `pipeline_stages` 4~6개
   - 미설정 모듈은 Kanban이 "파이프라인 미설정" 안내를 표시 (Part 6)

### 🟡 첫 사용자 경험을 위한 권장

6. **사용자 프로필 sending_email 설정**
   - 발신용 이메일 (예: `you@yourdomain.com`) — 미설정 시 로그인 이메일 사용
   - Settings → Profile 에서 가능

7. **Browser Notification 권한 안내**
   - 새 AI 초안 도착 시 데스크톱 알림 (Q9 결정: 기본 OFF)
   - Settings → Notifications에서 사용자가 직접 활성화

---

## 9-Part 빌드 요약

| Part | 영역 | 파일 | 라인 |
|------|------|------|------|
| 1 | 인프라 (config, supabase clients, i18n, providers) | 25 | 1,593 |
| 2 | App Shell + Auth (Sidebar, AppShell, login flow) | 36 | 2,133 |
| 3 | AI Draft Queue 목록 | 12 | 1,927 |
| 4 | AI Draft Queue 상세/편집/승인/거부 + Server Actions | 21 | 2,680 |
| 5 | Inbox + Party 상세 + 활동 타임라인 | 28 | 2,493 |
| 6 | Engagement Kanban + Stage 이동 + 상세 | 16 | 1,711 |
| 7 | Tasks + Settings + Realtime | 23 | 1,728 |
| 8 | Tier 2 — 모든 폼 (Party/Engagement/Contact/Task/Compose) | 13 | 2,103 |
| 9 | 통합 테스트 + i18n 검증 + 운영자 가이드 | 3 + README | 600+ |

**누적**: ~191 TS/TSX 파일, ~25,000 라인 (STEP 3 포함)
**테스트**: vitest 159 통과 (STEP 3의 106 + Part 9의 53 신규)
**i18n**: 3개 언어 451 키 100% 동기화

---

## 주요 결정 (STEP 4 Q1-Q16)

- **Q1**: Phase 1 모듈 = investor, buyer, partner, customer (4개)
- **Q2**: Tier 2 = 모든 6 영역 (Party/Engagement/Contact/Task/Communication/Org)
- **Q3**: 활동 타임라인 = communications + tasks 시간순 통합
- **Q4**: AI 출력 보존 = `body_plain` (원본) vs `final_body_plain` (편집본) 별도 컬럼
- **Q5**: 일괄 승인은 편집 중인 항목 자동 제외
- **Q6**: 검색 = ilike + pg_trgm (STEP 1의 GIN 인덱스 활용)
- **Q7**: Reject 사유 = 4 preset (Too informal / Incorrect facts / Off-tone / Other) + 기타 입력
- **Q8**: i18n = ko + en + ja 모두 100% 번역
- **Q9**: Realtime + Browser Notification opt-in (기본 OFF)
- **Q10**: i18n key 누락 0건 보장 (자동 테스트 추가)
- **Q11**: 조직 멤버 = 모든 권한 (소유자/멤버 구분 안 함)
- **Q12**: 다크 모드 = HSL 토큰만 (별도 dark CSS 없음)
- **Q13**: bulk approve는 동일 트랜잭션 단일 UPDATE (race condition 회피)
- **Q14**: stage 이동 = trigger가 자동 history 기록 + Server Action은 current_stage_id만 UPDATE
- **Q15**: 모든 list 페이지 = URL 기반 filter/sort/pagination (북마크 가능)
- **Q16**: 데스크톱 dnd-kit 사용, 모바일은 Select 대안 UI 제공

---

## 알려진 한계 (Phase 1)

- **Pipeline 편집 UI 미제공** — 운영자가 SQL로 stage 정의 (Phase 2에서 UI 제공 예정)
- **다중 조직 미지원** — 한 사용자 = 한 조직 (UI는 대비되어 있음)
- **첨부 파일 미처리** — communications.attachment_count는 카운트만 표시
- **이메일 본문 HTML 미렌더** — plain text만 표시 (XSS 회피)
- **모듈별 권한 차등 없음** — 조직 멤버는 모든 모듈 접근 가능

---

## 라이선스 및 운영

- STEP 1-4의 모든 코드는 단일 솔로 파운더용으로 작성됨
- 멀티 테넌시는 RLS로 격리되어 있으나 운영 전 검증 필요
- 클로드 API 호출은 cost-tracker로 daily/monthly 모니터링 가능
- TABS Mailer는 quiet hours (Asia/Seoul 22-06)에 발송 보류
