-- =====================================================================
-- stage24_baseline_check.sql
-- =====================================================================
-- Session 7 시작 시 Supabase SQL Editor 에서 실행.
-- Session 6 의 DB 사실 재확인 + Stage 24 작업에 필요한 추가 정보.
-- 결과를 Claude 에게 붙여넣고 작업 plan 받기.
-- =====================================================================

-- ─────────────────────────────────────────────
-- §1. Session 6 의 DB 사실 재확인 (모두 true 여야 함)
-- ─────────────────────────────────────────────
SELECT
  '§1. DB 사실 재확인' AS section,
  EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema='app' AND table_name='meetings') AS s_meetings_exists,
  EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema='app' AND table_name='meeting_attendees') AS s_attendees_table_exists,
  EXISTS (SELECT 1 FROM information_schema.columns
          WHERE table_schema='app' AND table_name='meetings' AND column_name='duration_min') AS s_duration_min_exists,
  NOT EXISTS (SELECT 1 FROM information_schema.columns
              WHERE column_name='meeting_mode') AS s_no_meeting_mode_anywhere,
  NOT EXISTS (SELECT 1 FROM information_schema.tables
              WHERE table_schema='app' AND table_name='lead_scores') AS s_no_lead_scores_table,
  EXISTS (SELECT 1 FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE n.nspname='public' AND p.proname='get_lead_scores_many') AS s_rpc_get_lead_scores_many,
  EXISTS (SELECT 1 FROM information_schema.columns
          WHERE table_schema='app' AND table_name='users' AND column_name='organization_id') AS s_app_users_orgid;


-- ─────────────────────────────────────────────
-- §2. app.meetings 전체 컬럼 (Stage 24 의 새 type 정의 근거)
-- ─────────────────────────────────────────────
SELECT
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name   = 'meetings'
ORDER BY ordinal_position;


-- ─────────────────────────────────────────────
-- §3. channel enum 값 (방향 Y 의 통합 대상)
-- ─────────────────────────────────────────────
SELECT
  n.nspname    AS schema_name,
  t.typname    AS enum_name,
  array_agg(e.enumlabel ORDER BY e.enumsortorder) AS values
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_enum e      ON e.enumtypid = t.oid
WHERE t.typname IN (
    SELECT udt_name FROM information_schema.columns
    WHERE table_schema='app' AND table_name='meetings' AND column_name='channel'
)
GROUP BY n.nspname, t.typname;


-- ─────────────────────────────────────────────
-- §4. meeting_attendees 테이블 schema + row 수
--     (Stage 24 의 attendees jsonb vs table 결정 근거)
-- ─────────────────────────────────────────────
SELECT
  '§4a. meeting_attendees schema' AS section,
  column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'app' AND table_name = 'meeting_attendees'
ORDER BY ordinal_position;

SELECT
  '§4b. 데이터 양 (폐기 결정용)' AS section,
  (SELECT COUNT(*) FROM app.meetings)            AS meetings_row_count,
  (SELECT COUNT(*) FROM app.meeting_attendees)   AS meeting_attendees_row_count,
  (SELECT COUNT(*) FROM app.meetings WHERE attendees IS NOT NULL AND jsonb_array_length(attendees) > 0)
                                                  AS meetings_with_jsonb_attendees;


-- ─────────────────────────────────────────────
-- §5. app.meetings.status enum 값
-- ─────────────────────────────────────────────
SELECT
  n.nspname    AS schema_name,
  t.typname    AS enum_name,
  array_agg(e.enumlabel ORDER BY e.enumsortorder) AS values
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_enum e      ON e.enumtypid = t.oid
WHERE t.typname IN (
    SELECT udt_name FROM information_schema.columns
    WHERE table_schema='app' AND table_name='meetings' AND column_name='status'
)
GROUP BY n.nspname, t.typname;


-- ─────────────────────────────────────────────
-- §6. meetings 관련 RPC 함수 목록 (현존 vs 추가 필요)
-- ─────────────────────────────────────────────
SELECT
  n.nspname           AS schema_name,
  p.proname           AS function_name,
  pg_get_function_arguments(p.oid) AS args,
  pg_get_function_result(p.oid)    AS returns
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('public', 'app')
  AND (p.proname ILIKE '%meeting%' OR p.proname ILIKE '%attendee%')
ORDER BY n.nspname, p.proname;


-- ─────────────────────────────────────────────
-- §7. log_change 함수 존재 여부 (Stage 24 #4 작업 범위)
-- ─────────────────────────────────────────────
SELECT
  '§7. log_change 함수' AS section,
  EXISTS (SELECT 1 FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE n.nspname IN ('public', 'app') AND p.proname = 'log_change') AS log_change_exists;
