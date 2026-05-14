-- ============================================================================
-- 024_plant_supply_links.sql
-- Phase 7-a — paper mill plant ↔ filler plant 매칭 테이블
--
-- 비즈니스 의미:
--   - paper mill plant 단위와 filler company plant 단위 간 실제 공급 관계
--   - filler_plant_id NULL 허용 = "Paper Mill 미팅했지만 충전제 미정" 상태 정식 표현
--   - 영업 진행에 따라 점진적 업데이트:
--       inquiry → qualification → qualified → active → (dormant | terminated)
--
-- 두 가지 영업 진입 채널:
--   - mill_first  : YunYoung이 Paper Mill에 정보 송부 → Mill이 Filler에 spec 요청
--   - filler_first: YunYoung이 Filler Company와 직접 계약 → Filler가 Paper Mill 영업
--   - industry_master: V11.4 마스터 DB에서 가져온 기존 데이터
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. 테이블 생성
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.plant_supply_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,

  -- 양측 plant FK
  paper_mill_plant_id uuid NOT NULL REFERENCES app.parties(id),
  filler_plant_id     uuid          REFERENCES app.parties(id),  -- NULL 허용

  filler_type text,  -- 'GCC' | 'PCC' | 'Kaolin' | 'Talc' | ...

  supply_status text CHECK (supply_status IN (
    'inquiry',        -- 영업 초기, 충전제 미정
    'qualification',  -- 시험 진행 중
    'qualified',      -- 검증 완료, 공급 시작 전
    'active',         -- 정식 공급 중
    'dormant',        -- 휴면
    'terminated'      -- 종료
  )),

  source_channel text CHECK (source_channel IN (
    'mill_first',       -- 경로 ① YunYoung → Paper Mill → Filler
    'filler_first',     -- 경로 ② YunYoung → Filler → Paper Mill
    'industry_master'   -- V11.4 기존 데이터에서 import
  )),

  notes text,

  -- 영업 추적 timestamps
  first_contact_at timestamptz,
  contracted_at    timestamptz,

  -- A/B/C 신뢰도 (V11.4 confidence_grade와 동일 척도)
  confidence_grade char(1) CHECK (confidence_grade IN ('A', 'B', 'C')),

  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

COMMENT ON TABLE app.plant_supply_links IS
  'paper mill plant ↔ filler plant 매칭. 영업 핵심 데이터. filler_plant_id NULL = 미정';

COMMENT ON COLUMN app.plant_supply_links.filler_plant_id IS
  'NULL 허용 — Paper Mill 미팅 시점에 Filler가 미정인 상태를 명시적으로 표현';


-- ---------------------------------------------------------------------------
-- 2. 인덱스
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_psl_paper_mill 
  ON app.plant_supply_links(paper_mill_plant_id);

CREATE INDEX IF NOT EXISTS idx_psl_filler 
  ON app.plant_supply_links(filler_plant_id);

-- 활성 단계만 빠르게 — 영업 KPI 조회 빈번
CREATE INDEX IF NOT EXISTS idx_psl_status 
  ON app.plant_supply_links(supply_status) 
  WHERE supply_status IN ('inquiry', 'qualification', 'active');

CREATE INDEX IF NOT EXISTS idx_psl_org 
  ON app.plant_supply_links(organization_id);


-- ---------------------------------------------------------------------------
-- 3. RLS — 조직 격리
-- ---------------------------------------------------------------------------

ALTER TABLE app.plant_supply_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS plant_supply_links_org_isolation ON app.plant_supply_links;

CREATE POLICY plant_supply_links_org_isolation ON app.plant_supply_links
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid);


-- ---------------------------------------------------------------------------
-- 4. 검증
-- ---------------------------------------------------------------------------

-- 테이블 + 인덱스 + 정책 확인
SELECT 
  c.relname AS table_name,
  COUNT(DISTINCT i.indexname) AS index_count,
  COUNT(DISTINCT p.policyname) AS policy_count
FROM pg_class c
LEFT JOIN pg_indexes i ON i.tablename = c.relname AND i.schemaname = 'app'
LEFT JOIN pg_policies p ON p.tablename = c.relname AND p.schemaname = 'app'
WHERE c.relname = 'plant_supply_links'
GROUP BY c.relname;
-- 기대: index_count >= 4, policy_count = 1
