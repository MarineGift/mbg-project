-- ============================================================================
-- 020_industry_schema.sql
-- Industry master DB: paper companies, mills, filler suppliers, linkages
-- Source: Global_Paper_Filler_Master_Database_45_V11_4.xlsx (V11.4 — 45 markets)
-- Idempotent — safe to re-run
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Prerequisites
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS industry;

-- ---------------------------------------------------------------------------
-- 1. Markets (lookup, 45 rows)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.markets (
  code        text PRIMARY KEY,
  name        text NOT NULL,
  region      text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE industry.markets IS 'Country/region master. 45 markets matching V11.4 dataset.';

INSERT INTO industry.markets (code, name, region) VALUES
  ('algeria',          'Algeria',            'MEA'),
  ('argentina',        'Argentina',          'Americas'),
  ('australia',        'Australia',          'Oceania'),
  ('austria',          'Austria',            'Europe'),
  ('bangladesh',       'Bangladesh',         'Asia'),
  ('brazil',           'Brazil',             'Americas'),
  ('canada',           'Canada',             'Americas'),
  ('chile',            'Chile',              'Americas'),
  ('china',            'China',              'Asia'),
  ('colombia',         'Colombia',           'Americas'),
  ('egypt',            'Egypt',              'MEA'),
  ('europe_composite', 'Europe (composite)', 'Europe'),
  ('finland',          'Finland',            'Europe'),
  ('france',           'France',             'Europe'),
  ('germany',          'Germany',            'Europe'),
  ('india',            'India',              'Asia'),
  ('indonesia',        'Indonesia',          'Asia'),
  ('iran',             'Iran',               'MEA'),
  ('italy',            'Italy',              'Europe'),
  ('japan',            'Japan',              'Asia'),
  ('korea',            'Korea',              'Asia'),
  ('malaysia',         'Malaysia',           'Asia'),
  ('mexico',           'Mexico',             'Americas'),
  ('morocco',          'Morocco',            'MEA'),
  ('nigeria',          'Nigeria',            'MEA'),
  ('norway',           'Norway',             'Europe'),
  ('pakistan',         'Pakistan',           'Asia'),
  ('philippines',      'Philippines',        'Asia'),
  ('poland',           'Poland',             'Europe'),
  ('portugal',         'Portugal',           'Europe'),
  ('russia',           'Russia',             'Europe'),
  ('saudi_arabia',     'Saudi Arabia',       'MEA'),
  ('slovakia',         'Slovakia',           'Europe'),
  ('south_africa',     'South Africa',       'MEA'),
  ('spain',            'Spain',              'Europe'),
  ('sri_lanka',        'Sri Lanka',          'Asia'),
  ('sweden',           'Sweden',             'Europe'),
  ('switzerland',      'Switzerland',        'Europe'),
  ('thailand',         'Thailand',           'Asia'),
  ('tunisia',          'Tunisia',            'MEA'),
  ('turkey',           'Turkey',             'MEA'),
  ('usa',              'USA',                'Americas'),
  ('united_kingdom',   'United Kingdom',     'Europe'),
  ('uruguay',          'Uruguay',            'Americas'),
  ('vietnam',          'Vietnam',            'Asia')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Paper Companies (423 rows from V11.4)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.paper_companies (
  id                      bigserial PRIMARY KEY,
  market_code             text NOT NULL REFERENCES industry.markets(code),
  legacy_id               int,                          -- 엑셀의 원본 ID
  name                    text NOT NULL,
  headquarters            text,
  europe_mills_footprint  text,
  main_product_category   text,
  main_products           text,
  filler_use_intensity    text,                         -- 'High' | 'Medium' | 'Low'
  known_filler_types      text[],
  supply_structure_note   text,
  onsite_pcc_evidence     text,
  evidence_level          char(1),                      -- 'A' | 'B' | 'C'
  source_url              text,
  notes                   text,
  created_at              timestamptz NOT NULL DEFAULT NOW(),
  updated_at              timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE (market_code, legacy_id)
);

CREATE INDEX IF NOT EXISTS idx_paper_companies_name
  ON industry.paper_companies (name);
CREATE INDEX IF NOT EXISTS idx_paper_companies_market
  ON industry.paper_companies (market_code);

-- ---------------------------------------------------------------------------
-- 3. Paper Mills / Plants (552 rows) — ⭐ child of paper_companies
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.paper_mills (
  id                       bigserial PRIMARY KEY,
  paper_company_id         bigint REFERENCES industry.paper_companies(id) ON DELETE CASCADE,
  market_code              text NOT NULL REFERENCES industry.markets(code),
  legacy_id                int,
  company_name_raw         text,                        -- FK 매칭 실패 시 fallback
  mill_name                text NOT NULL,
  city                     text,
  region                   text,
  main_product_category    text,
  main_products            text,
  filler_probability       text,                        -- 'High' | 'Medium' | 'Low'
  basis_for_filler         text,
  likely_filler_types      text[],
  likely_supply_structure  text,
  likely_supplier_note     text,
  evidence_level           char(1),
  source_url               text,
  notes                    text,
  created_at               timestamptz NOT NULL DEFAULT NOW(),
  updated_at               timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE (market_code, legacy_id)
);

CREATE INDEX IF NOT EXISTS idx_paper_mills_company
  ON industry.paper_mills (paper_company_id);
CREATE INDEX IF NOT EXISTS idx_paper_mills_market
  ON industry.paper_mills (market_code);
CREATE INDEX IF NOT EXISTS idx_paper_mills_name
  ON industry.paper_mills (mill_name);

-- ---------------------------------------------------------------------------
-- 4. Filler Suppliers (281 rows)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.filler_suppliers (
  id                       bigserial PRIMARY KEY,
  market_code              text NOT NULL REFERENCES industry.markets(code),
  legacy_id                int,
  name                     text NOT NULL,
  supplier_type            text,
  market_role              text,
  relevant_filler_types    text[],
  supply_model             text,
  europe_paper_evidence    text,
  onsite_pcc_evidence      text,
  evidence_level           char(1),
  source_url               text,
  notes                    text,
  created_at               timestamptz NOT NULL DEFAULT NOW(),
  updated_at               timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE (market_code, legacy_id)
);

CREATE INDEX IF NOT EXISTS idx_filler_suppliers_name
  ON industry.filler_suppliers (name);

-- ---------------------------------------------------------------------------
-- 5. Supplier × Mill Linkages (817 rows) — ⭐ M:N relationship
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.supplier_mill_linkages (
  id                          bigserial PRIMARY KEY,
  market_code                 text NOT NULL REFERENCES industry.markets(code),
  legacy_id                   int,
  filler_supplier_id          bigint REFERENCES industry.filler_suppliers(id),
  paper_company_id            bigint REFERENCES industry.paper_companies(id),
  paper_mill_id               bigint REFERENCES industry.paper_mills(id),
  -- denormalized name fallbacks (for unmatched rows)
  supplier_name_raw           text,
  paper_company_name_raw      text,
  mill_site_raw               text,
  country_region              text,
  relationship_type           text,
  filler_type                 text,
  supply_structure            text,
  confirmation_status         text,
  confidence_grade            char(1),                  -- 'A' | 'B' | 'C'
  evidence_level              text,                     -- 'E1' | 'E2' | 'E3'
  supplier_evidence_url       text,
  transaction_evidence_url    text,
  customer_mill_evidence_url  text,
  current_status              text,
  assessment_scope            text,
  notes                       text,
  created_at                  timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE (market_code, legacy_id)
);

CREATE INDEX IF NOT EXISTS idx_linkages_supplier
  ON industry.supplier_mill_linkages (filler_supplier_id);
CREATE INDEX IF NOT EXISTS idx_linkages_mill
  ON industry.supplier_mill_linkages (paper_mill_id);
CREATE INDEX IF NOT EXISTS idx_linkages_company
  ON industry.supplier_mill_linkages (paper_company_id);
CREATE INDEX IF NOT EXISTS idx_linkages_confidence
  ON industry.supplier_mill_linkages (confidence_grade);

-- ---------------------------------------------------------------------------
-- 6. Market Findings (459 rows) — RAG-ready
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.market_findings (
  id                bigserial PRIMARY KEY,
  market_code       text REFERENCES industry.markets(code),
  finding_category  text,
  description       text NOT NULL,
  evidence_source   text,
  embedding         vector(3072),                       -- text-embedding-3-large
  created_at        timestamptz NOT NULL DEFAULT NOW(),
  embedded_at       timestamptz
);

CREATE INDEX IF NOT EXISTS idx_market_findings_market
  ON industry.market_findings (market_code);
CREATE INDEX IF NOT EXISTS idx_market_findings_category
  ON industry.market_findings (finding_category);
-- NOTE: pgvector ivfflat/hnsw indexes는 2000 dim 제한. 3072-dim은 index 없이 시퀀셜 스캔.
-- 459 rows 규모에서는 instant. 추후 row 폭발 시 halfvec 또는 Matryoshka 1536으로 축소 검토.

-- ---------------------------------------------------------------------------
-- 7. Verification Queue (340 rows)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry.verification_queue (
  id                          bigserial PRIMARY KEY,
  market_code                 text REFERENCES industry.markets(code),
  legacy_id                   int,
  filler_supplier_id          bigint REFERENCES industry.filler_suppliers(id),
  supplier_name_raw           text,
  supplier_type               text,
  country_market              text,
  potential_paper_company     text,
  potential_mill_site         text,
  state_region                text,
  city_district               text,
  hypothesized_relationship   text,
  filler_type                 text,
  likely_supply_structure     text,
  why_needs_verification      text,
  current_confidence          text,
  best_evidence_url           text,
  notes                       text,
  resolved_at                 timestamptz,
  resolved_linkage_id         bigint REFERENCES industry.supplier_mill_linkages(id),
  created_at                  timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE (market_code, legacy_id)
);

CREATE INDEX IF NOT EXISTS idx_verification_unresolved
  ON industry.verification_queue (created_at)
  WHERE resolved_at IS NULL;

-- ---------------------------------------------------------------------------
-- 8. Updated_at auto-trigger (간단 패턴)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION industry.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_paper_companies_touch') THEN
    CREATE TRIGGER trg_paper_companies_touch
      BEFORE UPDATE ON industry.paper_companies
      FOR EACH ROW EXECUTE FUNCTION industry.touch_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_paper_mills_touch') THEN
    CREATE TRIGGER trg_paper_mills_touch
      BEFORE UPDATE ON industry.paper_mills
      FOR EACH ROW EXECUTE FUNCTION industry.touch_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_filler_suppliers_touch') THEN
    CREATE TRIGGER trg_filler_suppliers_touch
      BEFORE UPDATE ON industry.filler_suppliers
      FOR EACH ROW EXECUTE FUNCTION industry.touch_updated_at();
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 9. Permissions
-- ---------------------------------------------------------------------------

GRANT USAGE ON SCHEMA industry TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA industry TO authenticated;
GRANT ALL    ON ALL TABLES IN SCHEMA industry TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA industry TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA industry
  GRANT SELECT ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA industry
  GRANT ALL    ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA industry
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 10. 검증 쿼리 — 실행 후 확인용
-- ---------------------------------------------------------------------------

-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'industry' ORDER BY table_name;
-- SELECT COUNT(*) AS markets FROM industry.markets;  -- 기대: 45
