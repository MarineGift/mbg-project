-- ============================================================
-- migration_027_contact_method_variants.sql
-- Generalizes the application-form machinery from investor-only
-- to any party that communicates via a web form (mills included),
-- and adds the canonical-question / length-variant system.
--
--   1. app.parties: preferred_contact_method + contact_form_url
--      (common attribute of any party -> lives on parties itself,
--       NOT on investor_profile / paper_mill_profile)
--   2. app.application_forms: form_type gains 'contact_inquiry'
--      (mill contact forms reuse the whole 025/026 machinery:
--       fields, answer binding, char counts, nda_blocked guard)
--   3. app.answer_library: variant + target_length
--      one answer_key can now carry short / medium / long bodies,
--      picked automatically against the field's max_length
--   4. app.application_form_fields: canonical_key
--      maps each form question onto the standard question catalog
--      so hundreds of forms share one answer library
--   5. v_application_field_status: appends canonical_key + variant
--
-- Depends on: migration_026_submission_method.sql
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables
--   * constraints are DROP IF EXISTS then ADD (idempotent rerun)
--   * CREATE OR REPLACE VIEW only APPENDS columns at the end
--
-- SaaS rules:
--   * only existing tables altered; RLS from 013/025 already covers
--     every row (RLS is row level, new columns need no new policy)
--   * application_form_fields stays a child-detail table: no created_by
-- ============================================================


-- ------------------------------------------------------------
-- 1. parties: how this party prefers to be contacted
--    Nullable: unknown for most of the 1000+ existing rows.
--    Badge logic reads ONLY these two columns (no extra joins).
-- ------------------------------------------------------------
ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS preferred_contact_method text;

ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS contact_form_url text;

ALTER TABLE app.parties
  DROP CONSTRAINT IF EXISTS parties_preferred_contact_method_chk;

ALTER TABLE app.parties
  ADD CONSTRAINT parties_preferred_contact_method_chk
  CHECK (
    preferred_contact_method IS NULL
    OR preferred_contact_method IN ('email','web_form','portal','phone','other')
  );

-- form-based parties should carry the URL of that form
ALTER TABLE app.parties
  DROP CONSTRAINT IF EXISTS parties_contact_form_url_chk;

ALTER TABLE app.parties
  ADD CONSTRAINT parties_contact_form_url_chk
  CHECK (
    preferred_contact_method IS NULL
    OR preferred_contact_method NOT IN ('web_form','portal')
    OR contact_form_url IS NOT NULL
  );

-- partial index: badge filter (show me every form-based party) stays fast
CREATE INDEX IF NOT EXISTS idx_parties_contact_method
  ON app.parties (preferred_contact_method)
  WHERE preferred_contact_method IN ('web_form','portal');


-- ------------------------------------------------------------
-- 2. application_forms: mill contact inquiries are a form_type,
--    not a new table. Everything from 025/026 is reused as-is.
-- ------------------------------------------------------------
ALTER TABLE app.application_forms
  DROP CONSTRAINT IF EXISTS application_forms_form_type_chk;

ALTER TABLE app.application_forms
  ADD CONSTRAINT application_forms_form_type_chk
  CHECK (form_type IN ('application','grant','accelerator','pitch_event','contact_inquiry','other'));


-- ------------------------------------------------------------
-- 3. answer_library: length variants per canonical answer.
--    Existing 13 seed rows become variant=medium automatically
--    via the column default. The old UNIQUE (org, answer_key)
--    widens to (org, answer_key, variant).
-- ------------------------------------------------------------
ALTER TABLE app.answer_library
  ADD COLUMN IF NOT EXISTS variant text NOT NULL DEFAULT 'medium';

ALTER TABLE app.answer_library
  ADD COLUMN IF NOT EXISTS target_length integer;

ALTER TABLE app.answer_library
  DROP CONSTRAINT IF EXISTS answer_library_variant_chk;

ALTER TABLE app.answer_library
  ADD CONSTRAINT answer_library_variant_chk
  CHECK (variant IN ('short','medium','long'));

ALTER TABLE app.answer_library
  DROP CONSTRAINT IF EXISTS answer_library_key_uq;

ALTER TABLE app.answer_library
  ADD CONSTRAINT answer_library_key_uq
  UNIQUE (organization_id, answer_key, variant);


-- ------------------------------------------------------------
-- 4. application_form_fields: canonical question mapping.
--    Registering a new form = mapping each question to a key,
--    not writing new answers. Free text on purpose: the catalog
--    is defined by the keys present in answer_library.
--    (child-detail table: still no created_by)
-- ------------------------------------------------------------
ALTER TABLE app.application_form_fields
  ADD COLUMN IF NOT EXISTS canonical_key text;

CREATE INDEX IF NOT EXISTS idx_form_fields_canonical
  ON app.application_form_fields (canonical_key)
  WHERE canonical_key IS NOT NULL;


-- ------------------------------------------------------------
-- 5. Extend the status view.
--    IMPORTANT: existing columns keep their exact order
--    (025 block, then the 026 appendix). New columns are
--    appended AFTER input_kind only.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_application_field_status AS
SELECT
  f.id                AS form_id,
  f.organization_id,
  f.party_id,
  p.party_name,
  f.form_url,
  f.status            AS form_status,
  f.deadline,
  ff.id               AS field_id,
  ff.seq,
  ff.label,
  ff.field_type,
  ff.max_length,
  ff.is_required,
  fa.answer_id,
  al.answer_key,
  al.disclosure_level,
  fa.final_text,
  fa.char_count,
  fa.is_copied,
  CASE
    WHEN fa.final_text IS NULL OR length(btrim(fa.final_text)) = 0 THEN 'empty'
    WHEN ff.max_length IS NOT NULL AND fa.char_count > ff.max_length THEN 'over_limit'
    WHEN al.disclosure_level = 'nda_only' THEN 'nda_blocked'
    ELSE 'ok'
  END AS field_state,
  f.submission_method,
  f.submit_email,
  f.login_required,
  f.attachments,
  ff.selector,
  ff.selector_type,
  ff.input_kind,
  f.form_type,
  ff.canonical_key,
  al.variant          AS answer_variant
FROM app.application_forms f
JOIN app.parties p
  ON p.id = f.party_id
LEFT JOIN app.application_form_fields ff
  ON ff.form_id = f.id
LEFT JOIN app.application_field_answers fa
  ON fa.field_id = ff.id
LEFT JOIN app.answer_library al
  ON al.id = fa.answer_id;


-- ------------------------------------------------------------
-- 6. Data alignment: parties that already have a registered
--    web_form / portal application form get their contact
--    method backfilled from it (no manual re-entry).
-- ------------------------------------------------------------
UPDATE app.parties p
SET
  preferred_contact_method = sub.submission_method,
  contact_form_url         = sub.form_url,
  updated_at               = now()
FROM (
  SELECT DISTINCT ON (party_id)
    party_id, submission_method, form_url
  FROM app.application_forms
  WHERE submission_method IN ('web_form','portal')
  ORDER BY party_id, created_at DESC
) sub
WHERE p.id = sub.party_id
  AND p.preferred_contact_method IS NULL;


-- ------------------------------------------------------------
-- 7. Verify
-- ------------------------------------------------------------
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name = 'parties'
  AND column_name IN ('preferred_contact_method','contact_form_url')
ORDER BY column_name;

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name = 'answer_library'
  AND column_name IN ('variant','target_length')
ORDER BY column_name;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name = 'application_form_fields'
  AND column_name = 'canonical_key';

SELECT answer_key, variant, disclosure_level
FROM app.answer_library
ORDER BY answer_key, variant;

SELECT party_name, preferred_contact_method, contact_form_url
FROM app.parties
WHERE preferred_contact_method IS NOT NULL
ORDER BY party_name;
