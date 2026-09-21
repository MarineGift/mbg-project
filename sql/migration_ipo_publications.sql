-- ============================================================
-- migration_ipo_publications.sql
-- Peer-reviewed publications backing the FCC technology (S-1 "Business —
-- Technology" section, IR technical validation, and licensee diligence).
-- Public information: safe to commit. Rows are entered by paste file.
-- ============================================================
BEGIN;

CREATE TABLE IF NOT EXISTS app.ipo_publications (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  uuid NOT NULL REFERENCES app.organizations(id) ON DELETE CASCADE,
  program_id       uuid REFERENCES app.ipo_programs(id) ON DELETE SET NULL,
  family_code      text,                      -- links to patents.family_code (e.g. FCC-NFC, FCC-CHITIN)
  pub_type         text NOT NULL DEFAULT 'journal'
                     CHECK (pub_type IN ('journal','conference','thesis','report','other')),
  title            text NOT NULL,
  authors          text NOT NULL,
  venue            text NOT NULL,             -- journal / conference
  year             int  NOT NULL,
  volume_pages     text,
  doi              text,
  published_on     date,
  affiliation      text,
  key_finding      text,                      -- one-paragraph takeaway usable in IR / S-1
  ir_use           text,                      -- how it is cited: validation, third-party, licensee diligence
  peer_reviewed    boolean NOT NULL DEFAULT true,
  created_by       uuid REFERENCES app.users(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, doi)
);

DROP TRIGGER IF EXISTS ipo_publications_touch ON app.ipo_publications;
CREATE TRIGGER ipo_publications_touch BEFORE UPDATE ON app.ipo_publications
  FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();

ALTER TABLE app.ipo_publications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ipo_publications_org_isolation ON app.ipo_publications;
CREATE POLICY ipo_publications_org_isolation ON app.ipo_publications FOR ALL
  USING      (organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid)
  WITH CHECK (organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid);

COMMIT;

-- Verify
-- SELECT count(*) FROM app.ipo_publications;   -- 0 until the paste file runs
