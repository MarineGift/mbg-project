-- ════════════════════════════════════════════════════════════════════
-- RLS Verification Harness
-- ════════════════════════════════════════════════════════════════════
-- 본 스크립트는 STEP 1 SQL 적용 후 Supabase SQL Editor 또는 psql에서
-- 직접 실행하여 RLS 정책의 동작을 정적으로 검증합니다.
--
-- 검사 대상 테이블 (STEP 3 코드가 직접 접근하는 것):
--   app.communications
--   app.attachments
--   app.contacts
--   app.user_organizations
--   app.mail_merge_jobs
--   app.meetings
--   ai.agents
--   ai.brand_voice
--   ai.knowledge_chunks
--   ai.runs
--   ai.drafts
--   ai.auto_send_rules
--   ai.consultations
--   ai.response_strategies
--   ai.strategy_actions
--
-- 통과 기준: 모든 SELECT가 0건이거나 정책이 명시된 결과만 반환해야 함.
-- 실패 시: 누락 정책을 STEP 1 SQL에 추가하거나 별도 마이그레이션 파일로 보완.
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. 각 테이블의 RLS 활성 상태 ────────────────────────────────────
-- 기대값: 모든 행에서 rowsecurity=true
SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled,
  CASE WHEN rowsecurity THEN '✓' ELSE '✗ MISSING' END AS status
FROM pg_tables
WHERE schemaname IN ('app', 'ai', 'audit')
ORDER BY schemaname, tablename;

-- ─── 2. 각 테이블의 정책 수와 명령 ───────────────────────────────────
-- 기대값:
--   - 모든 테이블에 최소 1개 이상의 SELECT 정책
--   - 사용자가 INSERT/UPDATE/DELETE 가능한 테이블엔 해당 정책 존재
--   - service_role은 정책 우회 (별도 정책 불필요)
SELECT
  schemaname,
  tablename,
  COUNT(*) AS policy_count,
  string_agg(DISTINCT cmd, ', ' ORDER BY cmd) AS commands_covered
FROM pg_policies
WHERE schemaname IN ('app', 'ai', 'audit')
GROUP BY schemaname, tablename
ORDER BY schemaname, tablename;

-- ─── 3. 정책에 organization_id 검증이 포함됐는지 ─────────────────────
-- 기대값: 모든 정책의 qual 또는 with_check 식에 organization_id 또는
--        user_organizations join이 등장해야 함 (멀티테넌트 격리)
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  CASE
    WHEN qual ILIKE '%organization_id%' OR qual ILIKE '%user_organizations%' THEN '✓'
    WHEN with_check ILIKE '%organization_id%' OR with_check ILIKE '%user_organizations%' THEN '✓'
    ELSE '⚠ NO ORG SCOPING'
  END AS org_scoping,
  qual,
  with_check
FROM pg_policies
WHERE schemaname IN ('app', 'ai')
  AND tablename IN (
    'communications', 'attachments', 'contacts',
    'mail_merge_jobs', 'meetings',
    'agents', 'brand_voice', 'knowledge_chunks',
    'runs', 'drafts', 'auto_send_rules',
    'consultations', 'response_strategies', 'strategy_actions'
  )
ORDER BY schemaname, tablename, cmd;

-- ─── 4. anon 역할이 민감 테이블에 접근 불가한지 ──────────────────────
-- 기대값: anon 역할은 ai.runs, ai.drafts, app.communications 등에 0건만 보여야 함
-- (실제 검증은 anon 키로 별도 클라이언트에서 수행 — 본 SQL은 권한 그랜트만 확인)
SELECT
  table_schema,
  table_name,
  privilege_type,
  grantee
FROM information_schema.role_table_grants
WHERE grantee IN ('anon', 'authenticated')
  AND table_schema IN ('app', 'ai', 'audit')
ORDER BY table_schema, table_name, grantee;

-- ─── 5. 핵심 함수의 SECURITY 옵션 검사 ───────────────────────────────
-- expire_stale_drafts(), match_knowledge_chunks() 등은 SECURITY DEFINER로
-- 정의되어 호출자 권한과 무관하게 작동해야 함.
SELECT
  n.nspname AS schema,
  p.proname AS function_name,
  p.prosecdef AS is_security_definer,
  CASE WHEN p.prosecdef THEN '✓' ELSE '⚠ NOT DEFINER' END AS status
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('app', 'ai')
  AND p.proname IN (
    'expire_stale_drafts',
    'match_knowledge_chunks'
  )
ORDER BY n.nspname, p.proname;

-- ─── 6. 정책 부재 경고 (반드시 RLS 정책이 있어야 하는 테이블) ────────
WITH expected AS (
  SELECT * FROM (VALUES
    ('app','communications'),
    ('app','attachments'),
    ('app','contacts'),
    ('app','mail_merge_jobs'),
    ('app','meetings'),
    ('app','user_organizations'),
    ('ai','agents'),
    ('ai','brand_voice'),
    ('ai','knowledge_chunks'),
    ('ai','runs'),
    ('ai','drafts'),
    ('ai','auto_send_rules'),
    ('ai','consultations'),
    ('ai','response_strategies'),
    ('ai','strategy_actions')
  ) AS t(schemaname, tablename)
),
actual AS (
  SELECT DISTINCT schemaname, tablename FROM pg_policies
)
SELECT
  e.schemaname,
  e.tablename,
  CASE WHEN a.tablename IS NULL THEN '✗ NO POLICY DEFINED' ELSE '✓' END AS status
FROM expected e
LEFT JOIN actual a USING (schemaname, tablename)
ORDER BY status DESC, e.schemaname, e.tablename;

-- ════════════════════════════════════════════════════════════════════
-- 끝.
-- 결과 해석:
--   1. status='✗ MISSING' 행이 있으면 → ALTER TABLE ... ENABLE ROW LEVEL SECURITY
--   2. status='⚠ NO ORG SCOPING' 정책이 있으면 → 정책 식 재검토 (멀티테넌트 위험)
--   3. status='✗ NO POLICY DEFINED' 행이 있으면 → CREATE POLICY 추가 필요
--   4. is_security_definer=false인 RPC 함수가 있으면 → ALTER FUNCTION ... SECURITY DEFINER
-- ════════════════════════════════════════════════════════════════════
