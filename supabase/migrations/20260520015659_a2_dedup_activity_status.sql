-- =====================================================================
-- migration_A2_dedup_2026Q2.sql
-- =====================================================================
-- A2 (Phase 4 확장) — activity_status + phone + 통합 dedup 인프라
-- 작성: 2026-05-19  (URM_MASTER_ARCHITECTURE §6 Phase 4)
-- 상태: ✅ 적용 완료 (이 세션. 참고용 보관)
-- 재실행: idempotent — CREATE OR REPLACE / IF NOT EXISTS / DO $$ guard
-- =====================================================================
--
-- 적용 후 산출물:
--   - app.activity_status enum (5 값: active, on_leave, retired, deceased, unknown)
--   - app.parties.activity_status  app.activity_status (nullable)
--   - app.parties.phone_e164       text
--   - app.parties.phone_normalized text
--   - GIN trgm index on (name_normalized) + (phone_normalized)
--   - B-tree partial index on (phone_normalized)
--   - app.normalize_phone(text)                       → text  (IMMUTABLE)
--   - app.find_similar_parties(...)                   → table (STABLE, 7 args)
--   - app.find_similar_persons(...)                   → table (STABLE, 6 args, wrapper)
--   - app.v_party_dedup_candidates                    view (recursive root, 3 dedup filter)
--   - app.v_person_dedup_candidates                   view (wrapper, party_type=individual)
--
-- 의존성:
--   - pg_trgm extension (확인됨: v1.6)
--   - app.parties 의 name_normalized 컬럼 (기존)
--   - parent_party_id self-FK (기존)
--   - Phase 1 (filler) cleanup 완료 상태 (235 filler active rows)
--
-- 의사결정 메모:
--   1. activity_status 는 nullable — individual 위주이나 firm 도 미래에 활용 여지 (회사 폐업 등)
--   2. CHECK 강제 안 함 (party_type='individual' AND activity_status NOT NULL) — 너무 빡빡
--   3. phone_e164 (표시용) vs phone_normalized (비교용) 분리
--   4. threshold 0.5 view 안의 hard floor — caller 가 추가 filter 가능
--   5. recursive CTE depth 5 — 무한 루프 방지 (현재 3-tier 만 사용)
--   6. siblings (same parent) + 직접 hierarchy + same-root 자동 제외
-- =====================================================================

BEGIN;

-- =====================================================================
-- 1. app.activity_status enum
-- =====================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'activity_status' AND n.nspname = 'app'
  ) THEN
    CREATE TYPE app.activity_status AS ENUM (
      'active',     -- 현재 일하는 중 (의도된 default)
      'on_leave',   -- 휴직 / 출산휴가 / 장기 부재
      'retired',    -- 은퇴
      'deceased',   -- 사망
      'unknown'     -- 시간 흘러 확인 불가
    );
  END IF;
END $$;

-- =====================================================================
-- 2. parties 컬럼 3개 추가 (idempotent)
-- =====================================================================
ALTER TABLE app.parties 
  ADD COLUMN IF NOT EXISTS activity_status  app.activity_status,
  ADD COLUMN IF NOT EXISTS phone_e164       text,
  ADD COLUMN IF NOT EXISTS phone_normalized text;

COMMENT ON COLUMN app.parties.activity_status IS
  'Person activity status (휴직/은퇴 등). entity_status (active/inactive/archived/blocked) 와 직교. firm 에는 보통 NULL.';
COMMENT ON COLUMN app.parties.phone_e164 IS
  'E.164 형식 전화번호. 표시용. 정규화 비교는 phone_normalized 사용.';
COMMENT ON COLUMN app.parties.phone_normalized IS
  'normalize_phone() 산출 — digits only. dedup 비교 키.';

-- =====================================================================
-- 3. Indexes (trigram + phone B-tree)
-- =====================================================================
-- name_normalized 에는 기존 idx_parties_name_normalized (no WHERE) 있음.
-- 신규는 partial (deleted 제외) — 더 작고 효율적.
CREATE INDEX IF NOT EXISTS idx_parties_name_normalized_trgm 
  ON app.parties USING gin (name_normalized gin_trgm_ops)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_parties_phone_normalized_trgm
  ON app.parties USING gin (phone_normalized gin_trgm_ops)
  WHERE deleted_at IS NULL AND phone_normalized IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_parties_phone_normalized_btree
  ON app.parties (phone_normalized)
  WHERE deleted_at IS NULL AND phone_normalized IS NOT NULL;

-- =====================================================================
-- 4. app.normalize_phone(text) → text
--    모든 non-digit 제거. NULL-safe.
-- =====================================================================
CREATE OR REPLACE FUNCTION app.normalize_phone(p_phone text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT NULLIF(
    regexp_replace(COALESCE(p_phone, ''), '[^0-9]', '', 'g'),
    ''
  );
$$;

COMMENT ON FUNCTION app.normalize_phone(text) IS
  '전화번호 정규화 — non-digit 제거. NULL → NULL. dedup 비교 키.';

-- =====================================================================
-- 5. app.find_similar_parties() — generic dedup (firm + person 통합)
--    name trgm similarity + phone exact match
-- =====================================================================
CREATE OR REPLACE FUNCTION app.find_similar_parties(
  p_name        text,
  p_phone       text                  DEFAULT NULL,
  p_party_type  app.party_type        DEFAULT NULL,
  p_module      app.module_type       DEFAULT NULL,
  p_exclude_id  uuid                  DEFAULT NULL,
  p_threshold   real                  DEFAULT 0.3,
  p_limit       int                   DEFAULT 20
)
RETURNS TABLE (
  id                uuid,
  name              text,
  party_type        app.party_type,
  module            app.module_type,
  country_code      text,
  parent_party_id   uuid,
  similarity_score  real,
  match_kind        text          -- 'name_trgm' | 'phone_exact' | 'both'
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
DECLARE
  v_name_norm  text := lower(trim(COALESCE(p_name, '')));
  v_phone_norm text := app.normalize_phone(p_phone);
BEGIN
  RETURN QUERY
  WITH candidates AS (
    SELECT 
      p.id, p.name, p.party_type, p.module, p.country_code, p.parent_party_id,
      CASE 
        WHEN v_name_norm <> '' AND p.name_normalized IS NOT NULL
          THEN similarity(p.name_normalized, v_name_norm)
        ELSE 0::real
      END AS sim_name,
      CASE 
        WHEN v_phone_norm IS NOT NULL 
         AND p.phone_normalized = v_phone_norm
          THEN 1.0::real
        ELSE 0::real
      END AS sim_phone
    FROM app.parties p
    WHERE p.deleted_at IS NULL
      AND (p_exclude_id IS NULL OR p.id <> p_exclude_id)
      AND (p_party_type IS NULL OR p.party_type = p_party_type)
      AND (p_module     IS NULL OR p.module     = p_module)
      AND (
        (v_name_norm <> '' AND p.name_normalized % v_name_norm)
        OR (v_phone_norm IS NOT NULL AND p.phone_normalized = v_phone_norm)
      )
  )
  SELECT 
    c.id, c.name, c.party_type, c.module, c.country_code, c.parent_party_id,
    GREATEST(c.sim_name, c.sim_phone)::real,
    CASE 
      WHEN c.sim_name >= p_threshold AND c.sim_phone >= 1 THEN 'both'
      WHEN c.sim_name >= p_threshold                       THEN 'name_trgm'
      WHEN c.sim_phone >= 1                                THEN 'phone_exact'
      ELSE NULL
    END
  FROM candidates c
  WHERE (c.sim_name >= p_threshold) OR (c.sim_phone >= 1)
  ORDER BY GREATEST(c.sim_name, c.sim_phone) DESC, c.name
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION app.find_similar_parties(text, text, app.party_type, app.module_type, uuid, real, int) IS
  'Generic party dedup — name trgm similarity + phone exact match. firm/person 모두 cover. siblings 제외는 caller 책임 (view 측에서 처리).';

-- =====================================================================
-- 6. app.find_similar_persons() — wrapper, party_type='individual' 강제
-- =====================================================================
CREATE OR REPLACE FUNCTION app.find_similar_persons(
  p_name        text,
  p_phone       text                  DEFAULT NULL,
  p_module      app.module_type       DEFAULT NULL,
  p_exclude_id  uuid                  DEFAULT NULL,
  p_threshold   real                  DEFAULT 0.3,
  p_limit       int                   DEFAULT 20
)
RETURNS TABLE (
  id                uuid,
  name              text,
  party_type        app.party_type,
  module            app.module_type,
  country_code      text,
  parent_party_id   uuid,
  similarity_score  real,
  match_kind        text
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
  SELECT * FROM app.find_similar_parties(
    p_name        => p_name,
    p_phone       => p_phone,
    p_party_type  => 'individual'::app.party_type,
    p_module      => p_module,
    p_exclude_id  => p_exclude_id,
    p_threshold   => p_threshold,
    p_limit       => p_limit
  );
$$;

COMMENT ON FUNCTION app.find_similar_persons(text, text, app.module_type, uuid, real, int) IS
  'Person dedup wrapper — find_similar_parties 의 party_type=individual 강제. URM_MASTER §1 원칙 10.';

-- =====================================================================
-- 7. app.v_party_dedup_candidates — generic dedup pair list
--    recursive root + same-parent + parent-child 자동 제외
-- =====================================================================
CREATE OR REPLACE VIEW app.v_party_dedup_candidates AS
WITH RECURSIVE party_roots AS (
  -- Anchor: parent 없는 행 = 자기 자신이 root
  SELECT id, id AS root_id, 0 AS depth
    FROM app.parties
   WHERE deleted_at IS NULL
     AND parent_party_id IS NULL
  UNION ALL
  -- Recursive: 자식이 부모에서 root_id 상속
  SELECT p.id, pr.root_id, pr.depth + 1
    FROM app.parties p
    JOIN party_roots pr ON p.parent_party_id = pr.id
   WHERE p.deleted_at IS NULL
     AND pr.depth < 5  -- 무한 루프 방지 (현재 3-tier 만)
)
SELECT 
  LEAST(a.id, b.id)    AS party_a,
  GREATEST(a.id, b.id) AS party_b,
  CASE WHEN a.id < b.id THEN a.name         ELSE b.name         END AS name_a,
  CASE WHEN a.id < b.id THEN b.name         ELSE a.name         END AS name_b,
  CASE WHEN a.id < b.id THEN a.country_code ELSE b.country_code END AS country_a,
  CASE WHEN a.id < b.id THEN b.country_code ELSE a.country_code END AS country_b,
  a.party_type,
  a.module,
  GREATEST(
    CASE 
      WHEN a.name_normalized IS NOT NULL AND b.name_normalized IS NOT NULL
        THEN similarity(a.name_normalized, b.name_normalized)
      ELSE 0::real
    END,
    CASE 
      WHEN a.phone_normalized IS NOT NULL 
       AND a.phone_normalized = b.phone_normalized
        THEN 1.0::real
      ELSE 0::real
    END
  ) AS similarity_score,
  CASE 
    WHEN a.phone_normalized IS NOT NULL 
     AND a.phone_normalized = b.phone_normalized
     AND a.name_normalized IS NOT NULL 
     AND b.name_normalized IS NOT NULL
     AND similarity(a.name_normalized, b.name_normalized) >= 0.5
      THEN 'both'
    WHEN a.phone_normalized IS NOT NULL 
     AND a.phone_normalized = b.phone_normalized
      THEN 'phone_exact'
    ELSE 'name_trgm'
  END AS match_kind,
  a.parent_party_id AS a_parent_id,
  b.parent_party_id AS b_parent_id,
  ra.root_id AS a_root_id,
  rb.root_id AS b_root_id
FROM app.parties a
JOIN app.parties b
  ON a.id < b.id
 AND a.deleted_at IS NULL
 AND b.deleted_at IS NULL
 AND a.party_type = b.party_type
 AND a.module     = b.module
 AND (
   (a.name_normalized IS NOT NULL 
    AND b.name_normalized IS NOT NULL 
    AND a.name_normalized % b.name_normalized
    AND similarity(a.name_normalized, b.name_normalized) >= 0.5)
   OR
   (a.phone_normalized IS NOT NULL 
    AND a.phone_normalized = b.phone_normalized)
 )
LEFT JOIN party_roots ra ON ra.id = a.id
LEFT JOIN party_roots rb ON rb.id = b.id
WHERE 
  -- 1. same-parent siblings 제외
  NOT (a.parent_party_id IS NOT NULL 
       AND a.parent_party_id = b.parent_party_id)
  -- 2. 직접 hierarchy 제외 (parent-child)
  AND a.parent_party_id IS DISTINCT FROM b.id
  AND b.parent_party_id IS DISTINCT FROM a.id
  -- 3. 같은 root (group ancestor) 자동 제외 — Specialty/Omya 같은 group 의 모든 변형
  AND (ra.root_id IS NULL 
       OR rb.root_id IS NULL 
       OR ra.root_id <> rb.root_id);

COMMENT ON VIEW app.v_party_dedup_candidates IS
  'Generic dedup candidate pair list. name trgm sim >= 0.5 OR phone exact match. same-parent siblings + parent-child + same-root-ancestor (recursive) 모두 자동 제외. A2.3 v2 (2026-05-19).';

-- =====================================================================
-- 8. app.v_person_dedup_candidates — person-only wrapper
-- =====================================================================
CREATE OR REPLACE VIEW app.v_person_dedup_candidates AS
SELECT * 
  FROM app.v_party_dedup_candidates
 WHERE party_type = 'individual'::app.party_type;

COMMENT ON VIEW app.v_person_dedup_candidates IS
  'Person dedup wrapper - v_party_dedup_candidates filtered to party_type=individual. URM_MASTER section 1 principle 10. A2.3 (2026-05-19).';

-- =====================================================================
-- 9. 검증 — 적용 결과 확인
-- =====================================================================
SELECT 
  (SELECT array_agg(enumlabel ORDER BY enumsortorder)
     FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'activity_status')                       AS enum_values,
  (SELECT array_agg(column_name ORDER BY column_name)
     FROM information_schema.columns 
    WHERE table_schema = 'app' AND table_name = 'parties'
      AND column_name IN ('activity_status','phone_e164','phone_normalized')) AS new_columns,
  (SELECT array_agg(proname ORDER BY proname)
     FROM pg_proc 
    WHERE pronamespace = 'app'::regnamespace
      AND proname IN ('normalize_phone','find_similar_parties','find_similar_persons')) AS new_functions,
  (SELECT array_agg(viewname ORDER BY viewname)
     FROM pg_views 
    WHERE schemaname = 'app'
      AND viewname IN ('v_party_dedup_candidates','v_person_dedup_candidates')) AS new_views;

-- 기대 결과:
-- enum_values   : {active, on_leave, retired, deceased, unknown}
-- new_columns   : {activity_status, phone_e164, phone_normalized}
-- new_functions : {find_similar_parties, find_similar_persons, normalize_phone}
-- new_views     : {v_party_dedup_candidates, v_person_dedup_candidates}

COMMIT;

-- =====================================================================
-- Acceptance test snippets (참고용, 별도 실행 권장)
-- =====================================================================
-- Cat 4 acceptance test (3 쌍 모두 잡혀야)
-- SELECT name_a, name_b, similarity_score, match_kind
--   FROM app.v_party_dedup_candidates
--  WHERE module = 'filler'::app.module_type
--    AND (
--      (name_a ILIKE 'EGM%' AND name_b ILIKE 'EGM%')
--      OR (name_a ILIKE 'Quality Minerals%' AND name_b ILIKE 'Quality Minerals%')
--      OR (name_a ILIKE 'Mikron-S%' AND name_b ILIKE 'Mikron-S%')
--    );
-- 기대: 3 행 (EGM 1.0 / Q-min 0.88 / Mikron-S 0.79)

-- Same-root 자동 제외 검증
-- SELECT COUNT(*) FROM app.v_party_dedup_candidates
--  WHERE name_a ILIKE 'Specialty Minerals%' AND name_b ILIKE 'Specialty Minerals%';
-- 기대: 0

-- Person dedup 사용 예시
-- SELECT * FROM app.find_similar_persons('Lior Susan', p_threshold => 0.5);

-- View 직접 활용
-- SELECT name_a, name_b, similarity_score 
--   FROM app.v_person_dedup_candidates 
--  ORDER BY similarity_score DESC;
