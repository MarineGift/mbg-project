-- ============================================================
-- migration_026_submission_method.sql
-- Adds submission routing to application_forms and Playwright
-- selector metadata to application_form_fields, then extends
-- v_application_field_status with the new columns.
--
-- Depends on: migration_025_application_forms.sql
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables
--   * constraints are DROP IF EXISTS then ADD (idempotent rerun)
--   * CREATE OR REPLACE VIEW only APPENDS columns at the end
--     (postgres forbids reordering or dropping view columns here)
--
-- SaaS rules:
--   * application_form_fields is a child-detail table
--     -> NO created_by added (rule confirmed)
--   * RLS policies from 025 already cover both tables. New columns
--     are covered automatically (RLS is row level, not column level)
-- ============================================================


-- ------------------------------------------------------------
-- 1. application_forms: how this program accepts submissions
-- ------------------------------------------------------------
ALTER TABLE app.application_forms
  ADD COLUMN IF NOT EXISTS submission_method text NOT NULL DEFAULT 'web_form';

ALTER TABLE app.application_forms
  ADD COLUMN IF NOT EXISTS submit_email text;

ALTER TABLE app.application_forms
  ADD COLUMN IF NOT EXISTS attachments text[] NOT NULL DEFAULT '{}';

ALTER TABLE app.application_forms
  ADD COLUMN IF NOT EXISTS login_required boolean NOT NULL DEFAULT false;

ALTER TABLE app.application_forms
  DROP CONSTRAINT IF EXISTS application_forms_submission_method_chk;

ALTER TABLE app.application_forms
  ADD CONSTRAINT application_forms_submission_method_chk
  CHECK (submission_method IN ('email','web_form','portal','email_then_form'));

-- submit_email is required when the method is email based
ALTER TABLE app.application_forms
  DROP CONSTRAINT IF EXISTS application_forms_submit_email_chk;

ALTER TABLE app.application_forms
  ADD CONSTRAINT application_forms_submit_email_chk
  CHECK (
    submission_method NOT IN ('email','email_then_form')
    OR submit_email IS NOT NULL
  );


-- ------------------------------------------------------------
-- 2. application_form_fields: Playwright selector metadata
--    (child-detail table: no created_by, per SaaS rules)
-- ------------------------------------------------------------
ALTER TABLE app.application_form_fields
  ADD COLUMN IF NOT EXISTS selector text;

ALTER TABLE app.application_form_fields
  ADD COLUMN IF NOT EXISTS selector_type text NOT NULL DEFAULT 'css';

ALTER TABLE app.application_form_fields
  ADD COLUMN IF NOT EXISTS input_kind text NOT NULL DEFAULT 'fill';

ALTER TABLE app.application_form_fields
  DROP CONSTRAINT IF EXISTS application_form_fields_selector_type_chk;

ALTER TABLE app.application_form_fields
  ADD CONSTRAINT application_form_fields_selector_type_chk
  CHECK (selector_type IN ('css','xpath','label','placeholder'));

ALTER TABLE app.application_form_fields
  DROP CONSTRAINT IF EXISTS application_form_fields_input_kind_chk;

ALTER TABLE app.application_form_fields
  ADD CONSTRAINT application_form_fields_input_kind_chk
  CHECK (input_kind IN ('fill','check','select_option','upload'));


-- ------------------------------------------------------------
-- 3. Extend the status view.
--    IMPORTANT: existing columns keep their exact order.
--    New columns are appended AFTER field_state only.
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
  ff.input_kind
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
-- 4. Data fix: CTAN application actually lives on the Dealum
--    portal, not on ctan.com. Verified 2026-07-09 on the CTAN
--    Entrepreneurs page (Apply for Funding button).
--    Portal implies an account, so login_required = true.
-- ------------------------------------------------------------
UPDATE app.application_forms
SET
  form_url          = 'https://app.dealum.com/#/company/application/new/72264/cmwl94en1rop0rvg8k9x44vzlcw2hgrf',
  submission_method = 'portal',
  login_required    = true,
  updated_at        = now()
WHERE form_url LIKE '%ctan.com%';


-- ------------------------------------------------------------
-- 5. Verify
-- ------------------------------------------------------------
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name = 'application_forms'
  AND column_name IN ('submission_method','submit_email','attachments','login_required')
ORDER BY column_name;

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'app'
  AND table_name = 'application_form_fields'
  AND column_name IN ('selector','selector_type','input_kind')
ORDER BY column_name;

SELECT form_id, party_name, submission_method, login_required, form_url
FROM app.v_application_field_status
GROUP BY form_id, party_name, submission_method, login_required, form_url;
