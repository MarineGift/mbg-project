-- ============================================================================
-- Stage 29-c · 05 · verify_urm_schema.sql
-- ============================================================================
-- 목적: Stage 29-b 종결 시점의 urm.* 스키마 구조가 caller cutover 기대치와
--       일치하는지 확인. handoff §3 / §6 / §8 의 모든 carry-forward 컬럼명을
--       information_schema 로 검증.
--
-- 실행 환경: Supabase SQL Editor (single statement, no BEGIN/COMMIT)
--
-- 출력: 1개 SELECT 결과셋. 각 row 는 (check_id, check_name, status, detail).
--       status 'OK' / 'FAIL' / 'WARN' / 'INFO'
--
-- ⚠️  caller cutover 진입 전 반드시 실행. FAIL 1건이라도 있으면 stop.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Block 1: urm schema 존재
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S01'::text AS check_id,
  'urm schema 존재'::text AS check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'urm'
  ) THEN 'OK' ELSE 'FAIL' END AS status,
  'expected: urm schema 정의됨'::text AS detail

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 2: 19개 urm 핵심 테이블 존재 검증
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S02-' || lpad(rn::text, 2, '0'))::text,
  ('urm.' || tname || ' 존재')::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'urm' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 V2 schema'::text
FROM (
  VALUES
    (1, 'parties'),
    (2, 'contacts'),
    (3, 'contacts_history'),
    (4, 'party_types'),
    (5, 'party_supply_links'),
    (6, 'plant_supply_links'),
    (7, 'investor_profile'),
    (8, 'paper_mill_profile'),
    (9, 'filler_supplier_profile'),
    (10, 'investor_portfolio_companies'),
    (11, 'pipelines'),
    (12, 'stages'),
    (13, 'deals'),
    (14, 'deal_stage_history'),
    (15, 'deal_checklists'),
    (16, 'tasks'),
    (17, 'engagements'),
    (18, 'engagement_attendees'),
    (19, 'engagement_documents')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 3: 핵심 컬럼명 검증 (handoff §3 rename 표)
-- ────────────────────────────────────────────────────────────────────────

-- S03-01: urm.parties.party_type_id 존재 (FK, NOT party_type column)
SELECT
  'S03-01'::text,
  'urm.parties.party_type_id 존재 (FK)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'caller code 가 party_type 직접 컬럼 참조하면 fail. JOIN to urm.party_types 필요'::text

UNION ALL

-- S03-02: urm.parties.party_type 직접 컬럼 부재 (반대 검증)
SELECT
  'S03-02'::text,
  'urm.parties.party_type 직접 컬럼 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: party_type 컬럼 없음 (FK lookup 으로 대체)'::text

UNION ALL

-- S03-03: urm.stages.sort_order (NOT stage_position)
SELECT
  'S03-03'::text,
  'urm.stages.sort_order 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'sort_order'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §3 rename: stage_position → sort_order'::text

UNION ALL

-- S03-04: urm.stages.stage_position 부재
SELECT
  'S03-04'::text,
  'urm.stages.stage_position 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'stage_position'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 이전 컬럼명 부재'::text

UNION ALL

-- S03-05: urm.contacts.firm_party_id NOT NULL
SELECT
  'S03-05'::text,
  'urm.contacts.firm_party_id NOT NULL'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts'
      AND column_name = 'firm_party_id'
      AND is_nullable = 'NO'
  ) THEN 'OK' ELSE 'FAIL' END,
  'R3 결정: NOT NULL 유지 (handoff §5 ε)'::text

UNION ALL

-- S03-06: urm.contacts_history (1:1 from app.person_firm_history)
SELECT
  'S03-06'::text,
  'urm.contacts_history.contact_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'contact_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: person_party_id → contact_id'::text

UNION ALL

-- S03-07: urm.contacts_history.started_at (date, NOT joined_at timestamptz)
SELECT
  'S03-07'::text,
  'urm.contacts_history.started_at (date)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'started_at'
      AND data_type = 'date'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: joined_at::date → started_at'::text

UNION ALL

-- S03-08: urm.party_supply_links.link_type (NOT supply_type)
SELECT
  'S03-08'::text,
  'urm.party_supply_links.link_type 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'link_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: supply_type → link_type (text)'::text

UNION ALL

-- S03-09: urm.party_supply_links.volume_estimate (text, NOT volume_tpy)
SELECT
  'S03-09'::text,
  'urm.party_supply_links.volume_estimate (text)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'volume_estimate'
      AND data_type = 'text'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: volume_tpy::text || tpy → volume_estimate'::text

UNION ALL

-- S03-10: urm.tasks.checklist_id (handoff §6 신설 컬럼)
SELECT
  'S03-10'::text,
  'urm.tasks.checklist_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'tasks'
      AND column_name = 'checklist_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §6 신설: FK to deal_checklists ON DELETE SET NULL'::text

UNION ALL

-- S03-11: urm.investor_portfolio_companies.portfolio_company_name_normalized
SELECT
  'S03-11'::text,
  'urm.ipc.portfolio_company_name_normalized 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'investor_portfolio_companies'
      AND column_name = 'portfolio_company_name_normalized'
  ) THEN 'OK' ELSE 'FAIL' END,
  'δ Port-1: portfolio_companies 의 name_normalized 보존 컬럼'::text

UNION ALL

-- S03-12: urm.parties 의 organization_id 컬럼 부재 (single-tenant 검증)
SELECT
  'S03-12'::text,
  'urm.parties.organization_id 부재 (single-tenant)'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'organization_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: urm = single-tenant'::text

UNION ALL

-- S03-13: urm.parties.module_data jsonb 존재 (legacy 보존)
SELECT
  'S03-13'::text,
  'urm.parties.module_data (jsonb) 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'module_data'
      AND data_type = 'jsonb'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8: _app_* legacy 필드 jsonb 보존소'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 4: party_types lookup 7개 코드 확인
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S04-01'::text,
  'urm.party_types 7개 코드 존재'::text,
  CASE WHEN (
    SELECT COUNT(*) FROM urm.party_types
    WHERE code IN (
      'investor','paper_mill','filler_supplier',
      'buyer','customer','partner','government_grant'
    )
  ) = 7 THEN 'OK' ELSE 'FAIL' END,
  ('handoff §5 ε: 7개 코드 (' ||
   (SELECT string_agg(code, ',' ORDER BY id) FROM urm.party_types)
   || ')')::text

UNION ALL

SELECT
  'S04-02'::text,
  'urm.party_types 에 fund 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'fund'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: fund V2 미지원'::text

UNION ALL

SELECT
  'S04-03'::text,
  'urm.party_types 에 organization 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'organization'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: organization V2 미지원'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 5: FK 무결성 (party_type_id FK 가 urm.party_types.id 참조)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S05-01'::text,
  'urm.parties.party_type_id FK → urm.party_types.id'::text,
  CASE WHEN EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'urm'
      AND tc.table_name = 'parties'
      AND kcu.column_name = 'party_type_id'
      AND ccu.table_schema = 'urm'
      AND ccu.table_name = 'party_types'
      AND ccu.column_name = 'id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'FK 강제: party_type_id 무효값 차단'::text

UNION ALL

-- S05-02: orphan party_type_id 검증
SELECT
  'S05-02'::text,
  'urm.parties.party_type_id orphan row 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.parties p
    WHERE p.party_type_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.party_types pt WHERE pt.id = p.party_type_id
      )
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 0 orphan (FK constraint 으로 보장)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 6: urm.parties.name 컬럼 확인 (handoff §13 의 ε ERROR 자취)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S06-01'::text,
  ('urm.parties name 컬럼 = ' ||
    COALESCE(
      (SELECT string_agg(column_name, ', ')
       FROM information_schema.columns
       WHERE table_schema = 'urm' AND table_name = 'parties'
         AND column_name IN ('name','display_name','party_name','legal_name')
      ), 'NONE'
    ))::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name IN ('name','display_name','party_name','legal_name')
  ) THEN 'INFO' ELSE 'WARN' END,
  'handoff §13: 실제 컬럼명 확인 필요. caller code 의 이름 참조 일관성 검증'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 7: 9개 deprecation profile 부재 확인 (Stage 29-b δ 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S07-' || lpad(rn::text, 2, '0'))::text,
  ('app.' || tname || ' DROP 확인')::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ: 9 deprecation profile DROP 완료'::text
FROM (
  VALUES
    (1, 'buyer_profile'),
    (2, 'buyer_partner_profile'),
    (3, 'customer_profile'),
    (4, 'govt_grant_profile'),
    (5, 'govt_grant_contact_profile'),
    (6, 'partner_profile'),
    (7, 'partner_audits'),
    (8, 'partner_capabilities'),
    (9, 'filler_supplier_contact_profile')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 8: app.portfolio_companies DROP 확인 (δ Port-1 cleanup)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S08-01'::text,
  'app.portfolio_companies DROP 확인'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = 'portfolio_companies'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ Port-1: 342 row → ipc.portfolio_company_name_normalized 보존 후 DROP'::text

) results
ORDER BY check_id;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 에 통째로 붙여넣기 → Run
-- 2. 모든 row 의 status = 'OK' 또는 'INFO' 인지 확인
-- 3. FAIL 1건이라도 있으면 → caller cutover STOP, handoff 재점검
-- 4. WARN 은 정보성. detail 컬럼 읽고 caller cutover 시 주의
-- ============================================================================
