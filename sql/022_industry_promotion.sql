-- ============================================================================
-- 022_industry_promotion.sql
-- Bulk promote industry.* master DB into app.parties:
--   1. UPDATE existing parties to link to industry (name match)
--   2. INSERT paper_companies as module='buyer' parties
--   3. INSERT filler_suppliers as module='filler' parties
-- Idempotent — re-runnable. UPSERT semantics via industry FK.
--
-- 사전 조건: 021_industry_app_link.sql 적용 완료 + 'filler' enum 존재
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. 사전 검증
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  -- 'filler' enum 존재 확인
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'module_type' AND e.enumlabel = 'filler'
  ) THEN
    RAISE EXCEPTION '021_industry_app_link.sql을 먼저 실행하세요 (filler enum 없음)';
  END IF;

  -- FK 컬럼 존재 확인
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'parties'
      AND column_name = 'industry_paper_company_id'
  ) THEN
    RAISE EXCEPTION '021_industry_app_link.sql을 먼저 실행하세요 (FK 컬럼 없음)';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. 기존 14개 parties → industry 링크 (이름 매칭)
-- ---------------------------------------------------------------------------

-- 기존 buyer parties 중 industry.paper_companies와 이름 일치하는 것 자동 연결
UPDATE app.parties p
SET industry_paper_company_id = ipc.id,
    updated_at = NOW()
FROM industry.paper_companies ipc
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.module = 'buyer'
  AND p.industry_paper_company_id IS NULL
  AND p.industry_filler_supplier_id IS NULL
  AND LOWER(TRIM(p.name)) = LOWER(TRIM(ipc.name));

-- ---------------------------------------------------------------------------
-- 2. Helper: market_code → ISO 2-letter country_code 매핑 함수
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION industry.market_to_iso(market_code text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE market_code
    WHEN 'algeria'          THEN 'DZ'
    WHEN 'argentina'        THEN 'AR'
    WHEN 'australia'        THEN 'AU'
    WHEN 'austria'          THEN 'AT'
    WHEN 'bangladesh'       THEN 'BD'
    WHEN 'brazil'           THEN 'BR'
    WHEN 'canada'           THEN 'CA'
    WHEN 'chile'            THEN 'CL'
    WHEN 'china'            THEN 'CN'
    WHEN 'colombia'         THEN 'CO'
    WHEN 'egypt'            THEN 'EG'
    WHEN 'europe_composite' THEN NULL  -- 멀티-국가; region에만 표기
    WHEN 'finland'          THEN 'FI'
    WHEN 'france'           THEN 'FR'
    WHEN 'germany'          THEN 'DE'
    WHEN 'india'            THEN 'IN'
    WHEN 'indonesia'        THEN 'ID'
    WHEN 'iran'             THEN 'IR'
    WHEN 'italy'            THEN 'IT'
    WHEN 'japan'            THEN 'JP'
    WHEN 'korea'            THEN 'KR'
    WHEN 'malaysia'         THEN 'MY'
    WHEN 'mexico'           THEN 'MX'
    WHEN 'morocco'          THEN 'MA'
    WHEN 'nigeria'          THEN 'NG'
    WHEN 'norway'           THEN 'NO'
    WHEN 'pakistan'         THEN 'PK'
    WHEN 'philippines'      THEN 'PH'
    WHEN 'poland'           THEN 'PL'
    WHEN 'portugal'         THEN 'PT'
    WHEN 'russia'           THEN 'RU'
    WHEN 'saudi_arabia'     THEN 'SA'
    WHEN 'slovakia'         THEN 'SK'
    WHEN 'south_africa'     THEN 'ZA'
    WHEN 'spain'            THEN 'ES'
    WHEN 'sri_lanka'        THEN 'LK'
    WHEN 'sweden'           THEN 'SE'
    WHEN 'switzerland'      THEN 'CH'
    WHEN 'thailand'         THEN 'TH'
    WHEN 'tunisia'          THEN 'TN'
    WHEN 'turkey'           THEN 'TR'
    WHEN 'usa'              THEN 'US'
    WHEN 'united_kingdom'   THEN 'GB'
    WHEN 'uruguay'          THEN 'UY'
    WHEN 'vietnam'          THEN 'VN'
    ELSE NULL
  END
$$;

-- evidence_level (A/B/C) → tier_level 매핑
CREATE OR REPLACE FUNCTION industry.evidence_to_tier(ev char(1))
RETURNS app.tier_level LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE ev
    WHEN 'A' THEN 'tier_1'::app.tier_level
    WHEN 'B' THEN 'tier_2'::app.tier_level
    WHEN 'C' THEN 'tier_3'::app.tier_level
    ELSE 'tier_3'::app.tier_level
  END
$$;

-- 도메인 정규화 (URL → 도메인만 추출, 이메일 매칭용)
CREATE OR REPLACE FUNCTION industry.url_to_domain(url text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT LOWER(REGEXP_REPLACE(
    REGEXP_REPLACE(COALESCE(url, ''), '^https?://(www\.)?', '', 'i'),
    '/.*$', ''
  ))
$$;

-- ---------------------------------------------------------------------------
-- 3. INSERT paper_companies → app.parties (module='buyer')
-- ---------------------------------------------------------------------------

INSERT INTO app.parties (
  organization_id,
  name,
  name_normalized,
  party_type,
  module,
  country_code,
  region,
  website,
  domain_normalized,
  industry_tags,
  tier,
  notes,
  module_data,
  industry_paper_company_id,
  source
)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  ipc.name,
  LOWER(REGEXP_REPLACE(ipc.name, '[^a-zA-Z0-9가-힣]+', '_', 'g')),
  'company'::app.party_type,
  'buyer'::app.module_type,
  industry.market_to_iso(ipc.market_code),
  CASE WHEN ipc.market_code = 'europe_composite' THEN 'Europe' ELSE NULL END,
  ipc.source_url,
  NULLIF(industry.url_to_domain(ipc.source_url), ''),
  ARRAY['paper-manufacturer'] 
    || COALESCE(
         (SELECT ARRAY_AGG(LOWER(REPLACE(t, ' ', '-'))) 
          FROM UNNEST(ipc.known_filler_types) AS t),
         ARRAY[]::text[]
       ),
  industry.evidence_to_tier(ipc.evidence_level),
  ipc.notes,
  jsonb_build_object(
    'industry_source', 'v11.4',
    'evidence_level', ipc.evidence_level,
    'filler_use_intensity', ipc.filler_use_intensity,
    'main_product_category', ipc.main_product_category,
    'main_products', ipc.main_products,
    'headquarters', ipc.headquarters,
    'europe_mills_footprint', ipc.europe_mills_footprint,
    'auto_promoted_at', NOW()
  ),
  ipc.id,
  'industry.v11_4.paper_company'
FROM industry.paper_companies ipc
WHERE NOT EXISTS (
  -- 이미 promoted된 row (FK 채워진 거) 스킵
  SELECT 1 FROM app.parties p WHERE p.industry_paper_company_id = ipc.id
);

-- ---------------------------------------------------------------------------
-- 4. INSERT filler_suppliers → app.parties (module='filler')
-- ---------------------------------------------------------------------------

INSERT INTO app.parties (
  organization_id,
  name,
  name_normalized,
  party_type,
  module,
  country_code,
  region,
  website,
  domain_normalized,
  industry_tags,
  tier,
  notes,
  module_data,
  industry_filler_supplier_id,
  source
)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  ifs.name,
  LOWER(REGEXP_REPLACE(ifs.name, '[^a-zA-Z0-9가-힣]+', '_', 'g')),
  'company'::app.party_type,
  'filler'::app.module_type,
  industry.market_to_iso(ifs.market_code),
  CASE WHEN ifs.market_code = 'europe_composite' THEN 'Europe' ELSE NULL END,
  ifs.source_url,
  NULLIF(industry.url_to_domain(ifs.source_url), ''),
  ARRAY['filler-supplier']
    || COALESCE(
         (SELECT ARRAY_AGG(LOWER(REPLACE(t, ' ', '-'))) 
          FROM UNNEST(ifs.relevant_filler_types) AS t),
         ARRAY[]::text[]
       ),
  industry.evidence_to_tier(ifs.evidence_level),
  ifs.notes,
  jsonb_build_object(
    'industry_source', 'v11.4',
    'evidence_level', ifs.evidence_level,
    'supplier_type', ifs.supplier_type,
    'market_role', ifs.market_role,
    'supply_model', ifs.supply_model,
    'onsite_pcc_evidence', ifs.onsite_pcc_evidence,
    'auto_promoted_at', NOW()
  ),
  ifs.id,
  'industry.v11_4.filler_supplier'
FROM industry.filler_suppliers ifs
WHERE NOT EXISTS (
  SELECT 1 FROM app.parties p WHERE p.industry_filler_supplier_id = ifs.id
);

-- ---------------------------------------------------------------------------
-- 5. 검증 — 결과 통계
-- ---------------------------------------------------------------------------

SELECT 
  module,
  COUNT(*) AS total,
  COUNT(industry_paper_company_id) AS linked_paper,
  COUNT(industry_filler_supplier_id) AS linked_filler,
  COUNT(*) - COUNT(industry_paper_company_id) - COUNT(industry_filler_supplier_id) AS manual
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY module
ORDER BY module;

-- 기대 결과:
--   buyer    | ~423 | ~423 | 0    | 0~14 (기존 매뉴얼 buyer)
--   filler   | ~281 | 0    | ~281 | 0
--   기타     | (기존 그대로)
