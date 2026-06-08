-- Migration: sectors controlled vocabulary + investor_sector_focus junction
-- Phase 1 of investor sector normalization.
-- Mirrors the existing app.investment_stages / app.investor_stage_focus pattern
-- (lookup table + N:M junction with FKs), NOT a Postgres enum, so that:
--   * adding a sector is a single INSERT (no ALTER TYPE, no redeploy)
--   * labels / sort order / active flag are first-class columns (i18n-ready)
--   * the FK constraint prevents free-text tag drift
-- RLS policies are created up-front (the investor_stage_focus rollout missed
-- this and the join returned 0 rows to the authenticated role until fixed).

BEGIN;

-- 1) sectors: controlled vocabulary master ------------------------------------
CREATE TABLE IF NOT EXISTS app.sectors (
  id          smallint    PRIMARY KEY,
  code        text        NOT NULL UNIQUE,
  label_en    text        NOT NULL,
  label_ko    text,
  sort_order  smallint    NOT NULL DEFAULT 0,
  is_active   boolean     NOT NULL DEFAULT true
);

-- 2) controlled vocabulary seed (15 sectors) ----------------------------------
--    mbg-fit sectors (advanced_materials / industrial / deep_tech / climate)
--    intentionally get the lowest sort_order so they surface first.
INSERT INTO app.sectors (id, code, label_en, label_ko, sort_order) VALUES
  ( 1, 'advanced_materials', 'Advanced Materials',          '신소재',        10),
  ( 2, 'industrial',         'Industrial & Manufacturing',  '산업/제조',     20),
  ( 3, 'deep_tech',          'Deep Tech',                   '딥테크',        30),
  ( 4, 'climate',            'Climate & Sustainability',    '기후/지속가능', 40),
  ( 5, 'energy',             'Energy',                      '에너지',        50),
  ( 6, 'ai',                 'AI & Data',                   'AI/데이터',     60),
  ( 7, 'software',           'Software & SaaS',             '소프트웨어',    70),
  ( 8, 'fintech',            'Fintech',                     '핀테크',        80),
  ( 9, 'healthcare',         'Healthcare & Bio',            '헬스케어/바이오', 90),
  (10, 'consumer',           'Consumer & CPG',              '소비재',       100),
  (11, 'mobility',           'Mobility & Aerospace',        '모빌리티/항공우주', 110),
  (12, 'food_ag',            'Food & Agriculture',          '식품/농업',    120),
  (13, 'defense',            'Defense',                     '방위',         130),
  (14, 'enterprise',         'Enterprise',                  '엔터프라이즈', 140),
  (15, 'crypto',             'Crypto & Web3',               '크립토/웹3',   150)
ON CONFLICT (id) DO UPDATE
  SET code       = EXCLUDED.code,
      label_en   = EXCLUDED.label_en,
      label_ko   = EXCLUDED.label_ko,
      sort_order = EXCLUDED.sort_order;

-- 3) investor_sector_focus: investor <-> sector N:M junction -------------------
CREATE TABLE IF NOT EXISTS app.investor_sector_focus (
  investor_profile_id uuid        NOT NULL
    REFERENCES app.investor_profile(id) ON DELETE CASCADE,
  sector_id           smallint    NOT NULL
    REFERENCES app.sectors(id)          ON DELETE RESTRICT,
  organization_id     uuid        NOT NULL
    REFERENCES app.organizations(id)    ON DELETE RESTRICT,
  created_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (investor_profile_id, sector_id)
);

CREATE INDEX IF NOT EXISTS idx_isf_sector_id
  ON app.investor_sector_focus (sector_id);
CREATE INDEX IF NOT EXISTS idx_isf_org_id
  ON app.investor_sector_focus (organization_id);

-- 4) RLS ----------------------------------------------------------------------
--    sectors is a read-mostly reference table; the junction follows the same
--    permissive authenticated policy shape as investor_stage_focus.
ALTER TABLE app.sectors                ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.investor_sector_focus  ENABLE ROW LEVEL SECURITY;

-- sectors: readable by all app roles (reference data)
DROP POLICY IF EXISTS pol_sectors_select ON app.sectors;
CREATE POLICY pol_sectors_select ON app.sectors
  FOR SELECT TO authenticated, anon USING (true);

-- investor_sector_focus: full CRUD for authenticated
DROP POLICY IF EXISTS pol_isf_select ON app.investor_sector_focus;
CREATE POLICY pol_isf_select ON app.investor_sector_focus
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS pol_isf_insert ON app.investor_sector_focus;
CREATE POLICY pol_isf_insert ON app.investor_sector_focus
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS pol_isf_update ON app.investor_sector_focus;
CREATE POLICY pol_isf_update ON app.investor_sector_focus
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS pol_isf_delete ON app.investor_sector_focus;
CREATE POLICY pol_isf_delete ON app.investor_sector_focus
  FOR DELETE TO authenticated USING (true);

COMMIT;

-- 5) make PostgREST aware of the new tables
NOTIFY pgrst, 'reload schema';
