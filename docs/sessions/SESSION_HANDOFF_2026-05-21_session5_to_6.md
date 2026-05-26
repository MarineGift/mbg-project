# SESSION HANDOFF — Session 5 → Session 6

**Date:** 2026-05-21 (Session 5 종료)
**Project:** mbg-project — B2B CRM/sales intelligence (Next.js 14 + Supabase + Anthropic SDK)
**Owner:** YunYoung
**Business verticals:** paper filler (calcium carbonate) / chitin & chitosan / cosmetics

---

## §1. Session 5 요약 — Stage 20 / 21 v4 / 22 완성

Session 4 handoff 의 미적용 Stage 20 부터 시작, email_sequence URM 완성 (Stage 21),
frontend 동기화 (Stage 22) 까지 마무리. **DB layer URM 100% 일치 완성**.

### 완료된 Stages

| Stage | 작업 | 결과 | 비고 |
|:--:|---|:--:|---|
| **20** | Investor 측 보강 (RLS + 5 FK + 4 triggers) | ✅ | 1,026 rows 보존, audit trigger skip (log_change 부재) |
| **21 v4** | email_sequence URM β+δ (Session 4 handoff §4 의 17b+17c+17d) | ✅ | v1→v4 까지 4번 재시도 (의존성 4종 단계적 식별) |
| **22** | Frontend code 정정 (Stage 21 동기화) | ✅ | mbg-project 의 RPC 인자명 + interface URM 일치 |

---

## §2. Stage 21 v4 세부 — URM β+δ 완전 적용

### DB 변경 내역

**Column rename (2 테이블):**
- `email_sequences.org_id` → `organization_id`
- `email_sequence_enrollments.org_id` → `organization_id`

**Status text → enum cast (3 컬럼):**
- `email_sequences.status` → `app.email_sequence_status` (draft/active/paused/archived)
- `email_sequence_enrollments.status` → `app.enrollment_status` (active/paused/completed/cancelled/failed)
- `email_sequence_sends.status` → `app.send_status` (pending/sent/skipped/bounced/failed)

**Function 재정의 (15 functions, β+δ 전면):**
- 9 함수: `p_org_id` → `p_organization_id` (β)
- 4 함수: RETURNS column 의 status text → enum (δ)
- `advance_enrollment`: `p_status` arg type → app.send_status
- `get_due_enrollments`: RETURNS `org_id` → `organization_id`
- `get_sequence_with_steps`: jsonb key `'org_id'` → `'organization_id'`
- archive_sequence + cancel_enrollment: explicit enum cast 추가 (LANGUAGE sql)

**기타 재생성:**
- 8 RLS policies (es + ese 의 org_id 참조 정정)
- 2 triggers + 2 trigger functions (organization_id 컬럼명 반영)
- 2 partial indexes (idx_seq_enrollments_due, idx_unique_active_enrollment, enum literal 사용)

**CHECK constraint 3개 DROP** — enum 으로 더 강력한 제약 대체.

### Stage 21 의존성 단계 식별 (v1→v4 의 학습)

| v | 발견 의존성 | 처리 |
|:--:|---|---|
| v1 | (초기) | 기본 작업 — fail |
| v2 | LANGUAGE sql 함수 (archive_sequence, cancel_enrollment) | eager 재컴파일 회피 → DROP+recreate |
| v3 | CHECK constraint 3개 (normal dep) | ALTER 전 DROP, enum 으로 대체 |
| v4 | partial index 2개 (auto dep, WHERE 절 text literal) | DROP+recreate with enum literal |

격리 테스트 (Test A/B/C) 로 정확한 위치 (`email_sequence_enrollments`) 좁힌 후 마지막 의존성 식별.

---

## §3. Stage 22 세부 — Frontend 동기화

### Patch 적용 (mbg-project, 7 파일)

1. `src/lib/actions/email-sequences.ts`:
   - RPC arg 정정: create_sequence, enroll_in_sequence, bulk_enroll_filtered, create_campaign_from_template (4 hits)
   - getSequenceForEdit 명시적 return type 추가 (TS narrowing 정정)
   - EmailSequenceWithSteps import 추가
   - 회귀 복원: list_active_templates, preview_campaign_filter 의 `p_org_id` 유지 (Stage 21 무관)
2. `src/lib/queries/email-history.ts`: 2 hits
3. `src/lib/queries/email-sequences.ts`: 1 hits
4. `src/lib/utils/sequence-processor.ts`: e.org_id → e.organization_id (RETURNS 컬럼 변경 반영)
5. `src/types/phase21.ts`: EmailTracking.org_id → organization_id (1 hit)
6. `src/types/phase21b.ts`: EmailSequence.org_id, DueEnrollmentRow.org_id → organization_id (2 hits)
7. TS types 재생성: `npx supabase gen types typescript --project-id ogenmrgxwhpbfepeldqx > src/types/database.types.ts`

### TS types regeneration 한계 (preexisting, Session 6 이슈)

`database.types.ts` 의 RPC 시그니처가 일부 함수에서 `Args: undefined` 또는 `Returns: never` 로
추론되는 longstanding 이슈. 이는 Supabase types CLI 의 SECURITY DEFINER 함수 + 복잡 RETURNS
시그니처 인식 한계. Session 6 에서 분리 정리.

---

## §4. 누적 핵심 학습 — Gotchas (Session 1-5)

### Session 1-4 기존 (16개)
- #1 ~ #18: handoff_session4_to_5.md §7 참조

### Session 5 신규 (#19 ~ #22)

**#19. LANGUAGE sql 함수의 eager 재컴파일**
- PostgreSQL 의 LANGUAGE sql 함수는 ALTER COLUMN TYPE 시 본문을 즉시 재컴파일
- LANGUAGE plpgsql 함수는 lazy (실행 시점 컴파일) 이라 영향 없음
- 대응: ALTER 전 SQL function 들을 DROP, ALTER 후 explicit cast 로 recreate

**#20. CHECK constraint 의 normal dependency**
- `status = ANY(ARRAY[...]::text[])` 패턴 CHECK 는 column type 변경을 막는 normal dep
- ALTER 전 DROP 필수. enum 이 자체 제약을 더 강력하게 보장하므로 재생성 불필요

**#21. ALTER TYPE ADD VALUE 의 transaction 제약**
- enum 에 ADD VALUE 후 같은 transaction 안에서 그 value 사용 불가
- 대응: 별도 transaction 으로 사전 commit 후 메인 작업 진입

**#22. Partial index 의 WHERE 절 type dependency**
- `WHERE column = 'literal'::text` 형태의 partial index 는 auto dep 이지만
  ALTER COLUMN TYPE 시 WHERE 표현식이 enum 컬럼과 type mismatch
- 대응: ALTER 전 DROP, 후 enum literal 로 재생성

### 진단 도구 — pg_depend
ALTER COLUMN TYPE 의존성 추적은 다음 4개 catalog 모두 검사:
- `pg_depend` (가장 권위 — normal/auto dependency)
- `pg_constraint` (CHECK / FK)
- `pg_views`, `pg_matviews` (view)
- `pg_proc` 의 prolang 별 검사 (sql 함수 = eager)

---

## §5. 현재 DB 상태 (Session 5 종료 시점)

### Schema 통계
- app schema base tables: ~82
- Stage 20/21 신규 / 변경:
  - 신규 enum: `app.email_sequence_status` (4 values), `app.enrollment_status` (5 values 포함 paused), `app.send_status` (5 values)
  - 변경 컬럼: `email_sequences.organization_id`, `email_sequence_enrollments.organization_id`
  - 변경 status type: 3 컬럼 (위)
  - Stage 20 신규 trigger: trg_ipp_updated_at, trg_pc_updated_at + audit triggers skipped (log_change 부재)

### URM 100% 일치 모듈 (Session 5 추가)
- investor, paper_mill, buyer, sales (Session 4 기준)
- **email_sequence (Session 5 추가)**

### Module type enum 11 values (변경 없음, Session 4 와 동일)
- investor / paper_mill / partner / customer / crowdfunding(DEPRECATED) /
  product_launch(DEPRECATED) / sales / filler / filler_supplier / government_grant / buyer

---

## §6. Session 6 우선순위

### 권장 작업 순서

**1. Preexisting tsc errors 정리 (별도 stage, ~2시간)**

tsc --noEmit 결과 ~48 errors. 분류:
- paper_mill 관련: `industryPaperMillId` 등 (PartyDetail type 갱신 필요)
- calendar/meetings: createMeeting / MeetingType 누락 export
- Supabase auth helpers: createServerActionClient (옛 API) → @supabase/ssr 패턴 마이그레이션
- TS strict mode 의 possibly undefined
- RPC type generation 한계 (`'never'` 추론) — workaround: `as any` 또는 wrapper type
- `processSequences` typo → `processSequence`

**2. Buyer 측 UI 추가 (Session 4 handoff 잔재)**
- buyer dashboard (`v_buyer_with_partners` view 활용)
- "Promote to Sales Order" button → `app.promote_buyer_engagement_to_sales_order`

**3. Calendar Edge Function** (Stage 14 의 외부 API 호출 분리부)
- `supabase functions new calendar-sync`
- Google/MS Calendar API + DB 함수 (sync_calendar_pull/push_prep) 연동

**4. log_change 함수 도입** (Stage 20 의 audit trigger skipped 부분 보강)
- IPP, PC 의 audit trigger 활성
- 공통 audit log 시스템 설계

**5. Investor 측 활용** (Stage 20 후)
- `v_investor_outreach_list` view 활용 (CSV 38 확인)
- partner_seniority enum 활용 (CSV 61)

---

## §7. 환경 확인 single query (Session 6 시작 시 1번 실행)

```sql
SELECT
  -- Session 4 stages (이미 검증)
  EXISTS (SELECT 1 FROM app.engagement_type_registry LIMIT 1) AS s13a,
  (SELECT COUNT(*) FROM app.paper_mill_profile) AS s13f_profile_rows,
  EXISTS (SELECT 1 FROM app.calendar_sync_log LIMIT 0) AS s14_sync_log,
  EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema='app' AND table_name='buyer_partner_profile') AS s16b_bpp,
  -- Session 5 stages
  -- Stage 20: IPP + PC 보강
  EXISTS (SELECT 1 FROM information_schema.columns
          WHERE table_schema='app' AND table_name='investor_partner_profile'
            AND column_name='deleted_at') AS s20_ipp_deleted,
  EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_pc_organization'
          AND conrelid='app.portfolio_companies'::regclass) AS s20_pc_org_fk,
  -- Stage 21: email_sequence URM β+δ
  EXISTS (SELECT 1 FROM information_schema.columns
          WHERE table_schema='app' AND table_name='email_sequences'
            AND column_name='organization_id') AS s21_es_orgid,
  NOT EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema='app' AND table_name='email_sequences'
                AND column_name='org_id') AS s21_es_orgid_removed,
  (SELECT udt_name FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequences' AND column_name='status'
  ) AS s21_es_status_type,
  (SELECT udt_name FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequence_enrollments' AND column_name='status'
  ) AS s21_ese_status_type,
  (SELECT udt_name FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequence_sends' AND column_name='status'
  ) AS s21_esn_status_type,
  -- Stage 21 의 enum values 확인 (paused 포함)
  EXISTS (SELECT 1 FROM pg_enum e
          JOIN pg_type t ON t.oid=e.enumtypid
          JOIN pg_namespace n ON n.oid=t.typnamespace
          WHERE n.nspname='app' AND t.typname='enrollment_status' AND e.enumlabel='paused'
  ) AS s21_paused_in_enum,
  -- partial index 재생성 확인
  (SELECT COUNT(*) FROM pg_indexes
    WHERE schemaname='app' AND tablename='email_sequence_enrollments'
      AND indexname IN ('idx_seq_enrollments_due','idx_unique_active_enrollment')
  ) AS s21_partial_idx_count,
  -- 함수 overload count
  (SELECT COUNT(*) FROM pg_proc p
   JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public'
     AND p.proname IN (
       'advance_enrollment','bulk_enroll_filtered','count_email_history',
       'create_campaign_from_template','create_sequence','enroll_in_sequence',
       'get_due_enrollments','get_email_history','get_party_enrollments',
       'get_sequence_with_steps','list_sequences','archive_sequence','cancel_enrollment'
     )
  ) AS s21_func_overload_count;
```

**expected (Session 5 종료 시점):**
- 모든 boolean true
- s21_es_status_type = `email_sequence_status`
- s21_ese_status_type = `enrollment_status`
- s21_esn_status_type = `send_status`
- s21_partial_idx_count = 2
- s21_func_overload_count = 15

---

## §8. Frontend (mbg-project) 상태

### Stage 22 변경 파일 (7 파일)

```
src/lib/actions/email-sequences.ts     — 5 RPC arg 변경 + getSequenceForEdit type + import
src/lib/queries/email-history.ts        — 2 RPC arg 변경
src/lib/queries/email-sequences.ts      — 1 RPC arg 변경
src/lib/utils/sequence-processor.ts     — e.organization_id (RETURNS 컬럼 반영)
src/types/phase21.ts                    — EmailTracking.organization_id
src/types/phase21b.ts                   — EmailSequence + DueEnrollmentRow.organization_id
src/types/database.types.ts             — regen 완료 (단, RPC type 추론 한계 존재)
```

### 백업 파일 (`.bak`)

각 patch 적용 파일에 `.bak` 자동 생성. 회귀 시 복원 가능:
```powershell
Get-ChildItem -Path src -Recurse -Filter '*.bak'
```

### 남은 tsc errors

~48 errors 잔존 (Session 6 의 정리 stage 대상):
- Stage 21/22 회귀: **0건** ✅
- preexisting Supabase types generation 한계: ~25 errors
- preexisting business module type 정의 누락: ~15 errors
- TS strict mode possibly undefined: ~8 errors

---

## §9. 사용자 작업 스타일 (Session 5 추가 학습)

- Korean 으로 communication
- PowerShell on Windows + Supabase SQL Editor 직접 실행
- Self-contained SQL (placeholder 없이, 단일 파일)
- 효율적 진행 선호 (분석 + 권장 + 결정 받고 작성)
- 결정은 짧고 명확 (예: "A / A", "B")
- **Session 5 신규**: 격리 테스트 + pg_depend 직접 진단 으로 의존성 추적 → 매우 효과적
- **Session 5 신규**: PowerShell script 와 SQL Editor 구분 명확히 함 (#주석 vs SQL syntax)

---

## §10. 첨부 파일 (`/mnt/user-data/outputs/` — Session 5 산출물)

### Session 5 적용 완료 (참고용)
- `stage20_investor_polish.sql` — Session 4 작성, Session 5 실행
- `stage21_email_sequence_urm_v4.sql` — Stage 21 의 최종 버전 (v1~v3 은 학습 기록용)
- `stage22_patch.ps1` — Frontend patch script

### Session 6 시작 준비
- 본 handoff 문서 (`SESSION_HANDOFF_2026-05-21_session5_to_6.md`)
- 모든 결정 사항 + 환경 확인 query + 우선순위 명시

---

**Session 5 종료. Stage 20 + 21 v4 + 22 완료. DB URM 100% 일치 + Frontend 동기화 완성.**
**Session 6 첫 작업: preexisting tsc errors 정리 또는 다른 우선순위 선택.**
