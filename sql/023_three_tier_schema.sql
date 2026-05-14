-- ============================================================================
-- 023_three_tier_schema.sql
-- Phase 7-a — 3-tier 계층 구조 (group_hq / country_entity / plant)
--
-- 비즈니스 모델: 영업 액션 단위가 paper company HQ가 아닌 paper mill plant.
-- Omya Inc (group_hq) → Omya Korea (country_entity) → Omya Korea Plant #1 (plant)
-- Oji Holdings (group_hq) → Oji 일본 region (country_entity) → Tomakomai mill (plant)
--
-- 사전 조건: 021_industry_app_link.sql / 022_industry_promotion.sql 적용 완료
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. parent_party_id self-FK + party_level enum 컬럼
-- ---------------------------------------------------------------------------

ALTER TABLE app.parties 
  ADD COLUMN IF NOT EXISTS parent_party_id uuid 
  REFERENCES app.parties(id) ON DELETE SET NULL;

ALTER TABLE app.parties 
  ADD COLUMN IF NOT EXISTS party_level text 
  CHECK (party_level IN ('group_hq', 'country_entity', 'plant'));

COMMENT ON COLUMN app.parties.parent_party_id IS
  '3-tier 계층 self-FK. plant → country_entity → group_hq 체인';
COMMENT ON COLUMN app.parties.party_level IS
  '계층 레벨. group_hq=본사, country_entity=국가 자회사, plant=공장 단위';

-- 인덱스 — parent로 자식 조회 빈번
CREATE INDEX IF NOT EXISTS idx_parties_parent 
  ON app.parties(parent_party_id) 
  WHERE parent_party_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_parties_level 
  ON app.parties(party_level) 
  WHERE party_level IS NOT NULL;


-- ---------------------------------------------------------------------------
-- 2. V11.4 promotion 데이터 backfill — country_entity로 기본 분류
-- (정밀화는 Phase 7-d에서 group_hq 분리)
-- ---------------------------------------------------------------------------

UPDATE app.parties
SET party_level = 'country_entity'
WHERE party_level IS NULL
  AND module IN ('buyer', 'filler')  -- Phase 7-b에서 buyer → paper_mill rename 예정
  AND organization_id = 'b25de8f2-1020-482f-9012-183f63883169';


-- ---------------------------------------------------------------------------
-- 3. 검증
-- ---------------------------------------------------------------------------

-- 기대:
--   country_entity / buyer    / 1083
--   country_entity / filler   / 361
--   NULL           / investor / 32   (기존 매뉴얼 — Phase 7 외)
--   NULL           / partner  / 14
--   NULL           / customer / 14
SELECT party_level, module, COUNT(*) AS cnt
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY party_level, module
ORDER BY party_level NULLS LAST, module;
