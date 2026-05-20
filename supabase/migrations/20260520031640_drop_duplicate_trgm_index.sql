-- ============================================================================
-- Migration: 중복 trigram index 정리 (보너스 (3))
-- Date:      2026-05-19
-- Context:   A2.1 적용 시 partial `_trgm` 신규 인덱스가 추가됐는데 기존 full
--            GIN `idx_parties_name_normalized` 가 잔존 → DROP 으로 정리.
-- Effect:    기능 영향 없음. storage 절약 + 단순화.
-- Keeps:     idx_parties_name_normalized_trgm
--              USING gin (name_normalized gin_trgm_ops)
--              WHERE deleted_at IS NULL  -- partial
-- Idempotent: yes (IF EXISTS guard)
-- ============================================================================

BEGIN;

-- 1) 현재 상태 검증 (이 SELECT 는 NOTICE 만 출력, 실제 DDL 영향 없음)
DO $$
DECLARE
  v_old_exists boolean;
  v_new_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'app'
       AND indexname  = 'idx_parties_name_normalized'
  ) INTO v_old_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'app'
       AND indexname  = 'idx_parties_name_normalized_trgm'
  ) INTO v_new_exists;

  RAISE NOTICE 'idx_parties_name_normalized (구, full GIN): %', v_old_exists;
  RAISE NOTICE 'idx_parties_name_normalized_trgm (신, partial): %', v_new_exists;

  IF NOT v_new_exists THEN
    RAISE EXCEPTION 'Partial trgm index (_trgm) missing - A2 migration not applied yet. Abort.';
  END IF;
END $$;

-- 2) 구 인덱스 DROP
DROP INDEX IF EXISTS app.idx_parties_name_normalized;

-- 3) 사후 검증
DO $$
DECLARE
  v_remaining int;
BEGIN
  SELECT COUNT(*)
    INTO v_remaining
    FROM pg_indexes
   WHERE schemaname = 'app'
     AND tablename  = 'parties'
     AND indexdef ILIKE '%gin_trgm_ops%';

  RAISE NOTICE 'parties 의 GIN trgm index 잔여 개수: % (기대: 1 = name_normalized_trgm + phone_normalized 등)',
               v_remaining;
END $$;

COMMIT;

-- ============================================================================
-- 검증 SQL (재실행 가능)
-- ============================================================================
-- SELECT indexname, indexdef
--   FROM pg_indexes
--  WHERE schemaname = 'app'
--    AND tablename  = 'parties'
--    AND indexdef ILIKE '%gin_trgm_ops%';
-- 기대:
--   idx_parties_name_normalized_trgm    | ... WHERE (deleted_at IS NULL)
--   idx_parties_phone_normalized_trgm   | ... WHERE (deleted_at IS NULL)   (A2 산출물)
