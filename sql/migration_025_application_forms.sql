-- ============================================================
-- migration_025_application_forms.sql
-- Investor / accelerator web-form application tracker
--
-- Problem: most angel groups, accelerators and grant programs
-- accept applications only through a web form on their own site.
-- We cannot auto-submit those. What we CAN do is:
--   1. store the form URL and its questions
--   2. keep a reusable answer library (EN + KO)
--   3. bind an answer to each field, with a live character count
--   4. mark disclosure level so NDA-only text never gets pasted out
--   5. track status and deadline per program
--
-- SaaS rules applied:
--   * every tenant table carries organization_id + RLS
--   * created_by ONLY on entity tables (application_forms, answer_library)
--   * NO created_by on child-detail / link tables
--     (application_form_fields, application_field_answers)
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables, no BEGIN/END function bodies
--   * no semicolons or apostrophes inside string literals
--   * updated_at maintained by the app layer, not a trigger
--
-- RUN ORDER: this file, then seed_answer_library.sql
-- ============================================================


-- ------------------------------------------------------------
-- 1. application_forms   (ENTITY -> has created_by)
--    One row per program we apply to. party_id points at the
--    investor or partner already in app.parties.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.application_forms (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL,
  party_id          uuid NOT NULL REFERENCES app.parties(id) ON DELETE CASCADE,

  form_url          text NOT NULL,
  form_type         text NOT NULL DEFAULT 'application',
  cycle_label       text,

  opens_at          date,
  deadline          date,

  status            text NOT NULL DEFAULT 'not_started',
  submitted_at      timestamptz,
  decision_at       timestamptz,
  outcome           text,

  notes             text,

  created_by        uuid NOT NULL DEFAULT auth.uid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT application_forms_form_type_chk
    CHECK (form_type IN ('application','grant','accelerator','pitch_event','other')),
  CONSTRAINT application_forms_status_chk
    CHECK (status IN ('not_started','drafting','ready','submitted','decided')),
  CONSTRAINT application_forms_outcome_chk
    CHECK (outcome IS NULL OR outcome IN ('accepted','rejected','waitlisted','withdrawn'))
);

CREATE INDEX IF NOT EXISTS idx_application_forms_org       ON app.application_forms (organization_id);
CREATE INDEX IF NOT EXISTS idx_application_forms_party     ON app.application_forms (party_id);
CREATE INDEX IF NOT EXISTS idx_application_forms_deadline  ON app.application_forms (deadline) WHERE status <> 'decided';


-- ------------------------------------------------------------
-- 2. application_form_fields   (CHILD DETAIL -> no created_by)
--    The questions on that form, in display order.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.application_form_fields (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL,
  form_id           uuid NOT NULL REFERENCES app.application_forms(id) ON DELETE CASCADE,

  seq               integer NOT NULL DEFAULT 0,
  label             text NOT NULL,
  field_type        text NOT NULL DEFAULT 'textarea',
  max_length        integer,
  is_required       boolean NOT NULL DEFAULT false,
  help_text         text,

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT application_form_fields_type_chk
    CHECK (field_type IN ('text','textarea','dropdown','url','number','file','date'))
);

CREATE INDEX IF NOT EXISTS idx_form_fields_form ON app.application_form_fields (form_id, seq);
CREATE INDEX IF NOT EXISTS idx_form_fields_org  ON app.application_form_fields (organization_id);


-- ------------------------------------------------------------
-- 3. answer_library   (ENTITY -> has created_by)
--    Reusable answers. disclosure_level is the NDA guard:
--    'public'   -> safe to paste into a third-party web form
--    'nda_only' -> in-person or under-NDA use only, never pasted
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.answer_library (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL,

  answer_key        text NOT NULL,
  title             text NOT NULL,
  body_en           text,
  body_ko           text,

  disclosure_level  text NOT NULL DEFAULT 'public',
  tags              text[] NOT NULL DEFAULT '{}',

  created_by        uuid NOT NULL DEFAULT auth.uid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT answer_library_disclosure_chk
    CHECK (disclosure_level IN ('public','nda_only')),
  CONSTRAINT answer_library_key_uq
    UNIQUE (organization_id, answer_key)
);

CREATE INDEX IF NOT EXISTS idx_answer_library_org  ON app.answer_library (organization_id);
CREATE INDEX IF NOT EXISTS idx_answer_library_tags ON app.answer_library USING gin (tags);


-- ------------------------------------------------------------
-- 4. application_field_answers   (LINK -> no created_by)
--    Binds one library answer to one form field, plus the exact
--    text actually submitted. char_count is derived.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.application_field_answers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL,

  field_id          uuid NOT NULL REFERENCES app.application_form_fields(id) ON DELETE CASCADE,
  answer_id         uuid REFERENCES app.answer_library(id) ON DELETE SET NULL,

  final_text        text,
  char_count        integer GENERATED ALWAYS AS (coalesce(length(final_text), 0)) STORED,
  is_copied         boolean NOT NULL DEFAULT false,

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT application_field_answers_field_uq UNIQUE (field_id)
);

CREATE INDEX IF NOT EXISTS idx_field_answers_answer ON app.application_field_answers (answer_id);
CREATE INDEX IF NOT EXISTS idx_field_answers_org    ON app.application_field_answers (organization_id);


-- ------------------------------------------------------------
-- 5. Row Level Security
--    VERIFY: the USING expression below must match the pattern
--    already used by app.parties. Run the discovery query in the
--    handoff first, then adjust these four policies if needed.
-- ------------------------------------------------------------
ALTER TABLE app.application_forms         ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.application_form_fields   ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.answer_library            ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.application_field_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS application_forms_org_isolation ON app.application_forms;
CREATE POLICY application_forms_org_isolation ON app.application_forms
  FOR ALL
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid)
  WITH CHECK (organization_id = (auth.jwt() ->> 'organization_id')::uuid);

DROP POLICY IF EXISTS application_form_fields_org_isolation ON app.application_form_fields;
CREATE POLICY application_form_fields_org_isolation ON app.application_form_fields
  FOR ALL
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid)
  WITH CHECK (organization_id = (auth.jwt() ->> 'organization_id')::uuid);

DROP POLICY IF EXISTS answer_library_org_isolation ON app.answer_library;
CREATE POLICY answer_library_org_isolation ON app.answer_library
  FOR ALL
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid)
  WITH CHECK (organization_id = (auth.jwt() ->> 'organization_id')::uuid);

DROP POLICY IF EXISTS application_field_answers_org_isolation ON app.application_field_answers;
CREATE POLICY application_field_answers_org_isolation ON app.application_field_answers
  FOR ALL
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid)
  WITH CHECK (organization_id = (auth.jwt() ->> 'organization_id')::uuid);


-- ------------------------------------------------------------
-- 6. Convenience view: one row per field, ready for the UI
--    Shows the bound answer, the live char count and whether the
--    text overflows the form limit.
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
  END AS field_state
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
-- 7. Verify
-- ------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'app'
  AND table_name IN (
    'application_forms',
    'application_form_fields',
    'answer_library',
    'application_field_answers'
  )
ORDER BY table_name;
