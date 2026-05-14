-- ============================================================================
-- 021_industry_app_link.sql
-- Link app.* CRM tables to industry.* master DB:
--   1. Add 'filler' to app.module_type enum
--   2. Add FK columns to app.parties (industry_paper_company_id, industry_filler_supplier_id)
--   3. Add mill_id to app.engagements (FK to industry.paper_mills)
-- Idempotent — safe to re-run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Extend module_type enum with 'filler'
-- ---------------------------------------------------------------------------

-- ALTER TYPE ADD VALUE는 PG 12+에서 transaction 내부 가능하나, 
-- 같은 transaction에서 즉시 사용은 불가. Supabase SQL Editor는
-- 각 ';' 단위로 auto-commit하므로 다음 statement에서 사용 가능.
ALTER TYPE app.module_type ADD VALUE IF NOT EXISTS 'filler';

-- ---------------------------------------------------------------------------
-- 2. Add industry FK columns to app.parties
-- ---------------------------------------------------------------------------

ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS industry_paper_company_id bigint
    REFERENCES industry.paper_companies(id) ON DELETE SET NULL;

ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS industry_filler_supplier_id bigint
    REFERENCES industry.filler_suppliers(id) ON DELETE SET NULL;

-- 한 party는 두 industry 테이블 중 하나로만 매핑 (또는 둘 다 NULL — manual party)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_parties_industry_exclusive'
      AND conrelid = 'app.parties'::regclass
  ) THEN
    ALTER TABLE app.parties ADD CONSTRAINT chk_parties_industry_exclusive
      CHECK (
        industry_paper_company_id IS NULL
        OR industry_filler_supplier_id IS NULL
      );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Add mill_id to app.engagements
-- ---------------------------------------------------------------------------

ALTER TABLE app.engagements
  ADD COLUMN IF NOT EXISTS mill_id bigint
    REFERENCES industry.paper_mills(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- 4. Indexes for FK lookups
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_parties_industry_paper
  ON app.parties (industry_paper_company_id)
  WHERE industry_paper_company_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_parties_industry_filler
  ON app.parties (industry_filler_supplier_id)
  WHERE industry_filler_supplier_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_engagements_mill
  ON app.engagements (mill_id)
  WHERE mill_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Documentation
-- ---------------------------------------------------------------------------

COMMENT ON COLUMN app.parties.industry_paper_company_id IS
  'Link to industry.paper_companies (V11.4 master DB). For module=buyer parties promoted from paper company master.';

COMMENT ON COLUMN app.parties.industry_filler_supplier_id IS
  'Link to industry.filler_suppliers. For module=filler parties.';

COMMENT ON COLUMN app.engagements.mill_id IS
  'Optional link to industry.paper_mills. Used when engagement is mill-specific (e.g. supplier-X-to-Sappi-Belgium-mill contract).';

-- ---------------------------------------------------------------------------
-- 6. 검증 쿼리 (실행 후 직접 돌려보기용 — 주석 처리됨)
-- ---------------------------------------------------------------------------

-- 'filler' enum 추가 확인
-- SELECT e.enumlabel FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid
-- WHERE t.typname = 'module_type' ORDER BY e.enumsortorder;

-- 새 컬럼 확인
-- SELECT column_name FROM information_schema.columns
-- WHERE table_schema = 'app' AND table_name IN ('parties','engagements')
--   AND column_name LIKE 'industry_%' OR column_name = 'mill_id';
