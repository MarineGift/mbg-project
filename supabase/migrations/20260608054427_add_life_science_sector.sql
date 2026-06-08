-- Migration: add 'life_science' to the app.sectors controlled vocabulary.
-- Distinct from 'healthcare' (Healthcare & Bio): life_science is for
-- therapeutics / drug discovery / biotech-platform investors, so they can be
-- filtered separately from broader health/medtech investors.
-- Idempotent: ON CONFLICT keeps the row in sync on re-run.

BEGIN;

INSERT INTO app.sectors (id, code, label_en, label_ko, sort_order) VALUES
  (16, 'life_science', 'Life Science', '생명과학', 95)
ON CONFLICT (id) DO UPDATE
  SET code       = EXCLUDED.code,
      label_en   = EXCLUDED.label_en,
      label_ko   = EXCLUDED.label_ko,
      sort_order = EXCLUDED.sort_order;

COMMIT;

NOTIFY pgrst, 'reload schema';
