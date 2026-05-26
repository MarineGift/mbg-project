-- ============================================================================
-- Stage 29-c · 05 · verify_carry_forward_counts.sql
-- ============================================================================
-- 목적: handoff §7 의 "Stage 29-b 종결 시점 데이터 snapshot" 과 실제 DB 의
--       row count 일치 여부 검증.
--
-- 실행 환경: Supabase SQL Editor (single SELECT, no BEGIN/COMMIT)
--
-- 출력: (group, table_fqdn, expected, actual, delta, status)
--       status: OK / MISMATCH / TABLE_MISSING
--
-- ⚠️  delta ≠ 0 인 row 발견 시 → handoff §7 와 실제 DB drift. 원인 조사.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Group A: urm.* 핵심 master (handoff §7)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'A'::text AS grp,
  'urm.parties (active)'::text AS table_fqdn,
  1532::int AS expected,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) AS actual,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) - 1532 AS delta,
  CASE WHEN (SELECT COUNT(*) FROM urm.parties WHERE deleted_at IS NULL) = 1532
       THEN 'OK' ELSE 'MISMATCH' END AS status

UNION ALL

SELECT 'A', 'urm.parties (total inc. soft-deleted)', NULL,
  (SELECT COUNT(*)::int FROM urm.parties),
  NULL, 'INFO'

UNION ALL

SELECT 'A', 'urm.contacts (active)', 217,
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL) - 217,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts WHERE deleted_at IS NULL) = 217
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.contacts_history', 109,
  (SELECT COUNT(*)::int FROM urm.contacts_history),
  (SELECT COUNT(*)::int FROM urm.contacts_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.party_supply_links', 117,
  (SELECT COUNT(*)::int FROM urm.party_supply_links),
  (SELECT COUNT(*)::int FROM urm.party_supply_links) - 117,
  CASE WHEN (SELECT COUNT(*) FROM urm.party_supply_links) = 117
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.plant_supply_links', 0,
  (SELECT COUNT(*)::int FROM urm.plant_supply_links),
  (SELECT COUNT(*)::int FROM urm.plant_supply_links) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.plant_supply_links) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group B: urm.* profile tables
-- ────────────────────────────────────────────────────────────────────────
SELECT 'B', 'urm.investor_profile', 101,
  (SELECT COUNT(*)::int FROM urm.investor_profile),
  (SELECT COUNT(*)::int FROM urm.investor_profile) - 101,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_profile) = 101
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.paper_mill_profile', 1074,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile),
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile) - 1074,
  CASE WHEN (SELECT COUNT(*) FROM urm.paper_mill_profile) = 1074
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.filler_supplier_profile', 232,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile),
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile) - 232,
  CASE WHEN (SELECT COUNT(*) FROM urm.filler_supplier_profile) = 232
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.investor_portfolio_companies', 422,
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group C: urm.* pipeline/deal/task/engagement (모두 0 — α+β TRUNCATE)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'C', 'urm.pipelines', 0,
  (SELECT COUNT(*)::int FROM urm.pipelines),
  (SELECT COUNT(*)::int FROM urm.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.stages', 0,
  (SELECT COUNT(*)::int FROM urm.stages),
  (SELECT COUNT(*)::int FROM urm.stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deals', 0,
  (SELECT COUNT(*)::int FROM urm.deals),
  (SELECT COUNT(*)::int FROM urm.deals) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deals) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_stage_history', 0,
  (SELECT COUNT(*)::int FROM urm.deal_stage_history),
  (SELECT COUNT(*)::int FROM urm.deal_stage_history) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_stage_history) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_checklists', 0,
  (SELECT COUNT(*)::int FROM urm.deal_checklists),
  (SELECT COUNT(*)::int FROM urm.deal_checklists) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_checklists) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.tasks', 0,
  (SELECT COUNT(*)::int FROM urm.tasks),
  (SELECT COUNT(*)::int FROM urm.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagements', 0,
  (SELECT COUNT(*)::int FROM urm.engagements),
  (SELECT COUNT(*)::int FROM urm.engagements) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagements) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_attendees', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_attendees),
  (SELECT COUNT(*)::int FROM urm.engagement_attendees) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_attendees) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_documents', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_documents),
  (SELECT COUNT(*)::int FROM urm.engagement_documents) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_documents) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group D: app.* 잔존 (handoff §7 carry — Stage 29-d 까지 보존)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'D', 'app.parties (active)', 1738,
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL) - 1738,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE deleted_at IS NULL) = 1738
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=company (active)', 1413,
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company'),
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company') - 1413,
  CASE WHEN (SELECT COUNT(*) FROM app.parties
             WHERE deleted_at IS NULL AND party_type::text = 'company') = 1413
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=fund (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=organization (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group E: ε 잔재 (Stage 29-d 자동 drop)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'E', 'app.investor_partner_profile (ε 잔재)', 108,
  (SELECT COUNT(*)::int FROM app.investor_partner_profile),
  (SELECT COUNT(*)::int FROM app.investor_partner_profile) - 108,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_partner_profile) = 108
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.person_firm_history (ε 잔재)', 109,
  (SELECT COUNT(*)::int FROM app.person_firm_history),
  (SELECT COUNT(*)::int FROM app.person_firm_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM app.person_firm_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.investor_portfolio_companies (ε 잔재)', 422,
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group F: app.* TRUNCATE 확인 (handoff §5 α+β)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'F', 'app.pipelines (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipelines),
  (SELECT COUNT(*)::int FROM app.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.pipeline_stages (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipeline_stages),
  (SELECT COUNT(*)::int FROM app.pipeline_stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipeline_stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.tasks (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.tasks),
  (SELECT COUNT(*)::int FROM app.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

) results
ORDER BY grp, table_fqdn;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. status = OK 모두 → handoff §7 snapshot 과 일치, Stage 29-c 진입 안전
-- 3. MISMATCH 1건이라도 → STOP. delta 컬럼으로 drift 방향 파악
--    - delta > 0 : Stage 29-b 종결 후 신규 row 추가됨 (불법 writer 의심)
--    - delta < 0 : 누군가 row 삭제함 (사고? 정상?)
-- 4. TABLE_MISSING → 테이블 자체 부재 (verify_urm_schema.sql 우선 실행)
--
-- ⚠️  운영 traffic 진행 중이면 작은 drift 발생 가능. ±5 row 이내는 WARN.
--     단 fund/organization 카운트는 절대 0 여야 함 (D group).
-- ============================================================================
