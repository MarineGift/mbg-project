-- ============================================================
-- 999_rollback_houston.sql
-- 014 / 015 / 016 이 만든 것을 전부 되돌린다.
--
-- 모든 작업을 동적 SQL 로 감쌌다. 대상이 하나도 없어도
-- 오류 없이 통과한다. 여러 번 실행해도 안전하다.
--
-- ⚠ 데이터가 지워진다. app.drive_links 와 app.introductions 에
--    실제로 입력한 내용이 있다면 먼저 백업하십시오.
--
--    SELECT * FROM app.drive_links;
--    SELECT * FROM app.introductions;
--
-- ⚠ enum 타입에 추가한 값(nda, patent 등)은 되돌리지 않는다.
--    PostgreSQL 은 ALTER TYPE ... DROP VALUE 를 지원하지 않는다.
--    타입 자체를 지우므로 실제로는 함께 사라진다.
-- ============================================================

DO $$
DECLARE
  v_dropped text[] := '{}';
  v_sql     text;
BEGIN

  -- ---- 1. 뷰 ----
  FOREACH v_sql IN ARRAY ARRAY[
    'app.v_party_documents',
    'app.v_pending_introductions'
  ]
  LOOP
    IF to_regclass(v_sql) IS NOT NULL THEN
      EXECUTE format('DROP VIEW IF EXISTS %s CASCADE', v_sql);
      v_dropped := v_dropped || ('view ' || v_sql);
    END IF;
  END LOOP;

  -- ---- 2. 016 이 만든 테이블 ----
  IF to_regclass('app.introductions') IS NOT NULL THEN
    EXECUTE 'DROP TABLE app.introductions CASCADE';
    v_dropped := v_dropped || 'table app.introductions';
  END IF;

  -- ---- 3. 014 가 만든 테이블 ----
  IF to_regclass('app.drive_links') IS NOT NULL THEN
    EXECUTE 'DROP TABLE app.drive_links CASCADE';
    v_dropped := v_dropped || 'table app.drive_links';
  END IF;

  -- ---- 4. 014 가 만든 enum ----
  IF EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
              WHERE n.nspname='app' AND t.typname='drive_link_kind') THEN
    EXECUTE 'DROP TYPE app.drive_link_kind CASCADE';
    v_dropped := v_dropped || 'type app.drive_link_kind';
  END IF;

  -- ---- 5. 함수 ----
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='app' AND p.proname='touch_drive_links_updated_at') THEN
    EXECUTE 'DROP FUNCTION app.touch_drive_links_updated_at() CASCADE';
    v_dropped := v_dropped || 'function app.touch_drive_links_updated_at';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='app' AND p.proname='touch_updated_at') THEN
    EXECUTE 'DROP FUNCTION app.touch_updated_at() CASCADE';
    v_dropped := v_dropped || 'function app.touch_updated_at';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='app' AND p.proname='check_introduction_contact_party') THEN
    EXECUTE 'DROP FUNCTION app.check_introduction_contact_party() CASCADE';
    v_dropped := v_dropped || 'function app.check_introduction_contact_party';
  END IF;

  -- ---- 6. app.parties 에 추가한 컬럼 ----
  IF to_regclass('app.parties') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE app.parties
               DROP COLUMN IF EXISTS drive_folder_id,
               DROP COLUMN IF EXISTS drive_folder_synced_at';
    v_dropped := v_dropped || 'columns app.parties.drive_*';
  END IF;

  -- ---- 7. app.organizations 에 추가한 컬럼 ----
  IF to_regclass('app.organizations') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE app.organizations
               DROP COLUMN IF EXISTS drive_root_folder_id,
               DROP COLUMN IF EXISTS drive_investor_folder_id,
               DROP COLUMN IF EXISTS drive_partner_folder_id,
               DROP COLUMN IF EXISTS drive_buyer_folder_id,
               DROP COLUMN IF EXISTS drive_customer_folder_id';
    v_dropped := v_dropped || 'columns app.organizations.drive_*';
  END IF;

  -- ---- 8. app.engagements 에 추가한 컬럼 ----
  IF to_regclass('app.engagements') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE app.engagements
               DROP CONSTRAINT IF EXISTS engagements_value_basis_paired,
               DROP CONSTRAINT IF EXISTS engagements_value_basis_required';
    EXECUTE 'ALTER TABLE app.engagements
               DROP COLUMN IF EXISTS potential_value_usd,
               DROP COLUMN IF EXISTS value_basis,
               DROP COLUMN IF EXISTS probability_pct,
               DROP COLUMN IF EXISTS champion_contact_id,
               DROP COLUMN IF EXISTS decision_maker_contact_id,
               DROP COLUMN IF EXISTS royalty_basis';
    v_dropped := v_dropped || 'columns app.engagements.*';
  END IF;

  -- ---- 9. app.pipeline_stages 에 추가한 컬럼 ----
  IF to_regclass('app.pipeline_stages') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE app.pipeline_stages
               DROP CONSTRAINT IF EXISTS pipeline_stages_stage_kind_check,
               DROP CONSTRAINT IF EXISTS pipeline_stages_terminal_consistent';
    EXECUTE 'DROP INDEX IF EXISTS app.pipeline_stages_kind_idx';
    EXECUTE 'ALTER TABLE app.pipeline_stages
               DROP COLUMN IF EXISTS stage_kind,
               DROP COLUMN IF EXISTS is_terminal';
    v_dropped := v_dropped || 'columns app.pipeline_stages.stage_kind,is_terminal';
  END IF;

  -- ---- 10. 015 가 만든 인덱스 ----
  IF to_regclass('app.pipeline_definitions') IS NOT NULL THEN
    EXECUTE 'DROP INDEX IF EXISTS app.pipeline_definitions_default_uniq';
    v_dropped := v_dropped || 'index pipeline_definitions_default_uniq';
  END IF;

  -- ---- 11. app.contacts 에 추가한 제약 (부록 A) ----
  IF to_regclass('app.contacts') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE app.contacts
               DROP CONSTRAINT IF EXISTS contacts_id_party_uniq';
  END IF;

  IF array_length(v_dropped, 1) IS NULL THEN
    RAISE NOTICE '되돌릴 대상이 없습니다. 깨끗한 상태입니다.';
  ELSE
    RAISE NOTICE '되돌림: %', array_to_string(v_dropped, E'\n  ');
  END IF;

END$$;


-- ============================================================
-- 015 가 만든 파이프라인 데이터 삭제 (별도 판단 필요)
--
-- 위 블록은 스키마만 되돌리고 데이터는 남긴다.
-- 015 의 시드 데이터까지 지우려면 아래를 별도로 실행하십시오.
-- engagement 가 물려 있으면 FK 로 막힌다. 그게 정상이다.
-- ============================================================
--
-- DO $$
-- DECLARE v_org uuid := '<ORGANIZATION_ID>';
-- BEGIN
--   IF to_regclass('app.pipeline_definitions') IS NULL THEN
--     RAISE NOTICE 'pipeline_definitions 없음';
--     RETURN;
--   END IF;
--
--   EXECUTE format($q$
--     DELETE FROM app.pipeline_stages
--      WHERE pipeline_definition_id IN (
--        SELECT id FROM app.pipeline_definitions
--         WHERE organization_id = %L
--           AND name IN ('HTX Fundraising','Technology Licensing',
--                        'HTX Ecosystem','Royalty Accounts'))
--   $q$, v_org);
--
--   EXECUTE format($q$
--     DELETE FROM app.pipeline_definitions
--      WHERE organization_id = %L
--        AND name IN ('HTX Fundraising','Technology Licensing',
--                     'HTX Ecosystem','Royalty Accounts')
--   $q$, v_org);
-- END$$;
