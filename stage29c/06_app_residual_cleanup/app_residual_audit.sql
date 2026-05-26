-- ============================================================================
-- Stage 29-c · 06 · app_residual_audit.sql
-- ============================================================================
-- 목적: Stage 29-d (app.* drop) 진입 전 사전 분석.
--       1) 모든 app.* 테이블 목록 + row count
--       2) 분류: PRESERVE / DROP_AFTER_CUTOVER / RESIDUAL_AUTODROP / ALREADY_EMPTY
--       3) FK 의존성 그래프 (in/out)
--
-- 실행 환경: Supabase SQL Editor (single SELECT)
--
-- 출력: (action, table_name, row_count, fk_in, fk_out, note)
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Section A: 전체 app.* 테이블 목록 + row count + 분류
-- ────────────────────────────────────────────────────────────────────────
-- 동적 row count 가 필요하므로 DO block + temp 결과는 불가 (Supabase SQL Editor).
-- 대신 LATERAL JOIN 으로 information_schema 와 동적 카운트 결합.
-- 단 동적 카운트는 PL/pgSQL 함수 또는 사전 정의된 view 필요.
-- → 여기서는 known 테이블 리스트를 명시적으로 지정. (Stage 29-b 종결 시점 기준)

SELECT
  CASE tname
    -- DROP_AFTER_CUTOVER: caller cutover 완료 후 drop. urm 에 완전 이전됨.
    WHEN 'parties' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'contacts' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'party_supply_links' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'plant_supply_links' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'investor_profile' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'paper_mill_profile' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'filler_supplier_profile' THEN 'DROP_AFTER_CUTOVER'
    -- RESIDUAL_AUTODROP: ε 잔재. handoff §7 의 명시 — Stage 29-d 자동 drop
    WHEN 'investor_partner_profile' THEN 'RESIDUAL_AUTODROP'
    WHEN 'person_firm_history' THEN 'RESIDUAL_AUTODROP'
    WHEN 'investor_portfolio_companies' THEN 'RESIDUAL_AUTODROP'
    -- ALREADY_EMPTY: α+β TRUNCATE 후 0 row. cutover 후 drop 안전
    WHEN 'pipelines' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'pipeline_stages' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'tasks' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'engagements' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'engagement_stage_history' THEN 'ALREADY_EMPTY_DROP'
    -- PRESERVE: V2 에서도 운영 carry. column rename 만 필요.
    WHEN 'email_whitelist' THEN 'PRESERVE_RENAME'
    WHEN 'communications' THEN 'PRESERVE_RENAME'
    -- PRESERVE: 운영 carry, 변경 없음
    WHEN 'invoices' THEN 'PRESERVE'
    WHEN 'payments' THEN 'PRESERVE'
    WHEN 'sales_orders' THEN 'PRESERVE'
    WHEN 'organizations' THEN 'PRESERVE'
    WHEN 'users' THEN 'PRESERVE'
    WHEN 'memberships' THEN 'PRESERVE'
    WHEN 'roles' THEN 'PRESERVE'
    WHEN 'permissions' THEN 'PRESERVE'
    WHEN 'role_permissions' THEN 'PRESERVE'
    WHEN 'sessions' THEN 'PRESERVE'
    WHEN 'api_keys' THEN 'PRESERVE'
    WHEN 'audit_log' THEN 'PRESERVE'
    WHEN 'feature_flags' THEN 'PRESERVE'
    WHEN 'scraping_jobs' THEN 'PRESERVE'
    WHEN 'scraping_results' THEN 'PRESERVE'
    ELSE 'UNKNOWN'
  END::text AS action,
  tname AS table_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = tname
  ) THEN 'EXISTS' ELSE 'MISSING' END AS table_status,
  ''::text AS placeholder_count,
  CASE tname
    -- urm 이전 완료 + caller cutover 후 drop
    WHEN 'parties' THEN 'urm.parties 로 이전 (id 보존). caller cutover 후 DROP CASCADE'
    WHEN 'contacts' THEN 'urm.contacts 로 이전 (id 보존, R3 결정 hard-delete 19)'
    WHEN 'party_supply_links' THEN 'urm.party_supply_links 로 이전 117 row'
    WHEN 'plant_supply_links' THEN '0 row, urm 동일'
    WHEN 'investor_profile' THEN 'urm.investor_profile 101 row (-5 fund)'
    WHEN 'paper_mill_profile' THEN 'urm.paper_mill_profile 1074 row'
    WHEN 'filler_supplier_profile' THEN 'urm.filler_supplier_profile 232 row (3 HQ 보존)'
    -- ε 잔재
    WHEN 'investor_partner_profile' THEN 'ε 잔재 108 (117-9). urm.contacts_history 로 대체 완료'
    WHEN 'person_firm_history' THEN 'ε 잔재 109 (118-9). urm.contacts_history 로 대체 완료'
    WHEN 'investor_portfolio_companies' THEN 'ε 잔재 422. urm.investor_portfolio_companies (δ Port-1)'
    -- TRUNCATE 결과
    WHEN 'pipelines' THEN 'α+β TRUNCATE (sample 폐기). urm.pipelines 로 신규 시작'
    WHEN 'pipeline_stages' THEN 'α+β TRUNCATE. urm.stages 로 이전 (이름 변경 sort_order)'
    WHEN 'tasks' THEN 'α+β TRUNCATE. urm.tasks 로 신규 시작'
    WHEN 'engagements' THEN 'α+β TRUNCATE (원래 0 row). urm.engagements'
    WHEN 'engagement_stage_history' THEN 'α+β TRUNCATE (원래 0 row)'
    -- PRESERVE
    WHEN 'email_whitelist' THEN '운영 carry. RENAME: org_id→organization_id, value→pattern'
    WHEN 'communications' THEN '운영 carry. RENAME: org_id→organization_id, body_text→body_plain'
    WHEN 'invoices' THEN 'finance carry. RESTRICT FK to app.parties 안전 (0 row 확인됨)'
    WHEN 'payments' THEN 'finance carry'
    WHEN 'sales_orders' THEN 'finance carry'
    WHEN 'organizations' THEN 'multi-tenant root. urm 은 single-tenant'
    WHEN 'users' THEN 'auth carry'
    WHEN 'memberships' THEN 'RBAC carry'
    WHEN 'roles' THEN 'RBAC carry'
    WHEN 'permissions' THEN 'RBAC carry'
    WHEN 'role_permissions' THEN 'RBAC carry'
    WHEN 'sessions' THEN 'auth carry'
    WHEN 'api_keys' THEN 'auth carry'
    WHEN 'audit_log' THEN 'audit carry (audit schema 와 별도)'
    WHEN 'feature_flags' THEN 'ops carry'
    WHEN 'scraping_jobs' THEN 'data acquisition carry'
    WHEN 'scraping_results' THEN 'data acquisition carry'
    ELSE '확인 필요 — known 리스트에 없음'
  END::text AS note
FROM (
  VALUES
    -- DROP_AFTER_CUTOVER
    ('parties'),('contacts'),('party_supply_links'),('plant_supply_links'),
    ('investor_profile'),('paper_mill_profile'),('filler_supplier_profile'),
    -- RESIDUAL_AUTODROP
    ('investor_partner_profile'),('person_firm_history'),('investor_portfolio_companies'),
    -- ALREADY_EMPTY_DROP
    ('pipelines'),('pipeline_stages'),('tasks'),('engagements'),('engagement_stage_history'),
    -- PRESERVE_RENAME
    ('email_whitelist'),('communications'),
    -- PRESERVE
    ('invoices'),('payments'),('sales_orders'),
    ('organizations'),('users'),('memberships'),
    ('roles'),('permissions'),('role_permissions'),
    ('sessions'),('api_keys'),('audit_log'),
    ('feature_flags'),('scraping_jobs'),('scraping_results')
) AS t(tname)

) classified
ORDER BY action, table_name;

-- ============================================================================
-- 부록 query 1: 실제 app.* 모든 테이블 (위의 known list 와 비교)
-- ============================================================================
-- 실행: 별도 query 로 (single statement 정책)

-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'app'
-- ORDER BY table_name;

-- ============================================================================
-- 부록 query 2: app.* row count (테이블별 카운트가 필요할 때)
-- ============================================================================
-- 1개 SELECT 로 모두 합칠 수 없으니 (table 이름이 dynamic),
-- 아래 DO block 사용. ⚠️ Supabase SQL Editor 에서 RAISE NOTICE 출력 안 보임.
-- 대안: pg_stat_user_tables.n_live_tup 사용 (근사값)

-- SELECT
--   schemaname || '.' || relname AS table_fqdn,
--   n_live_tup AS approx_row_count,
--   n_dead_tup AS approx_dead_count,
--   last_vacuum,
--   last_analyze
-- FROM pg_stat_user_tables
-- WHERE schemaname = 'app'
-- ORDER BY n_live_tup DESC;

-- ============================================================================
-- 부록 query 3: app.* 의 FK 의존성 (in-bound + out-bound)
-- ============================================================================
-- DROP 순서 결정용. RESTRICT FK 가 가리키는 테이블 먼저 정리.

-- SELECT
--   tc.table_schema || '.' || tc.table_name AS from_table,
--   kcu.column_name AS from_column,
--   ccu.table_schema || '.' || ccu.table_name AS to_table,
--   ccu.column_name AS to_column,
--   rc.delete_rule
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu
--   ON tc.constraint_name = kcu.constraint_name
--   AND tc.table_schema = kcu.table_schema
-- JOIN information_schema.constraint_column_usage ccu
--   ON ccu.constraint_name = tc.constraint_name
--   AND ccu.constraint_schema = tc.constraint_schema
-- JOIN information_schema.referential_constraints rc
--   ON rc.constraint_name = tc.constraint_name
--   AND rc.constraint_schema = tc.constraint_schema
-- WHERE tc.constraint_type = 'FOREIGN KEY'
--   AND (tc.table_schema = 'app' OR ccu.table_schema = 'app')
-- ORDER BY from_table, from_column;

-- ============================================================================
-- 부록 query 4: 실제 row count (수동 verification)
-- ============================================================================
-- Stage 29-d 진입 전 마지막 확인. 모두 0 row 인지 확인.

-- SELECT 'app.pipelines' AS t, COUNT(*) FROM app.pipelines
-- UNION ALL SELECT 'app.pipeline_stages', COUNT(*) FROM app.pipeline_stages
-- UNION ALL SELECT 'app.tasks', COUNT(*) FROM app.tasks
-- UNION ALL SELECT 'app.engagements', COUNT(*) FROM app.engagements
-- UNION ALL SELECT 'app.engagement_stage_history', COUNT(*) FROM app.engagement_stage_history
-- UNION ALL SELECT 'app.plant_supply_links', COUNT(*) FROM app.plant_supply_links;
-- → 모두 0 면 ALREADY_EMPTY_DROP 즉시 가능

-- ============================================================================
-- 사용:
-- 1. 메인 SELECT 통째 실행 → 전체 분류 결과
-- 2. UNKNOWN 행 있으면 → app schema 에 known 외 테이블 존재. 부록 query 1 로 확인
-- 3. 부록 query 2 (pg_stat) 로 근사 row count 확보
-- 4. 부록 query 4 로 ALREADY_EMPTY_DROP 카테고리 0 row 재확인
-- 5. 부록 query 3 으로 FK 의존성 그래프 그려 DROP 순서 결정
--
-- ⚠️  Stage 29-d 의 DROP 순서:
--    Step 1: ALREADY_EMPTY_DROP (의존성 없음 → 안전)
--    Step 2: RESIDUAL_AUTODROP (FK 가 DROP_AFTER_CUTOVER 가리킬 수 있음 — 순서 주의)
--    Step 3: DROP_AFTER_CUTOVER (의존성 끊긴 뒤)
--    Step 4: PRESERVE_RENAME 의 컬럼 rename 만 (테이블 자체는 유지)
-- ============================================================================
