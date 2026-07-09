-- ============================================================
-- seed_ctan_team_fields.sql
-- CTAN application on Dealum, step 2 of N: Team
-- Source: real form content pasted 2026-07-09
--
-- seq block: Team = 201..213 (Overview was 101..119)
-- Note: the applicant name is prefilled by the Dealum account,
-- so it is not seeded as a fillable field. The team member list
-- (seq 205) is an interactive invite widget done inside the
-- portal, seeded here only so preparation can be tracked.
--
-- Supabase SQL Editor safe:
--   * one self-contained INSERT (inline VALUES + NOT EXISTS)
--   * no semicolons or apostrophes inside string literals
--   * no standalone SQL keywords inside string literals
--
-- Child-detail table: no created_by (SaaS rule).
-- Rerun safe: NOT EXISTS on (form_id, label).
-- ============================================================

INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id,
  f.id,
  v.seq,
  v.label,
  v.field_type,
  v.max_length,
  v.is_required,
  v.help_text,
  v.canonical_key,
  v.input_kind,
  'css'
FROM app.application_forms f
JOIN (
  VALUES
    (201, 'Phone', 'text', NULL::integer, true,
     'With country code, e.g. +1 512 ...',
     'founder_phone', 'fill'),
    (202, 'LinkedIn', 'url', NULL, false,
     'Founder LinkedIn profile URL',
     'founder_linkedin', 'fill'),
    (203, 'Role in team', 'text', NULL, true,
     'Founder and CEO',
     'founder_role', 'fill'),
    (204, 'Relevant experience', 'textarea', NULL, true,
     'Founder background relevant to the venture - paper industry, filler markets, prior ventures. CAUTION: no NDA partner names',
     'founder_experience', 'fill'),
    (205, 'Team members', 'text', NULL, false,
     'Interactive invite widget inside the portal, up to 5 listed. Dealum note: strongest profiles feature at least five members and a second admin as backup contact',
     'team_member_invites', 'fill'),
    (206, 'Number of team members', 'number', NULL, true,
     'Total people working at the company, or on the project if not yet registered',
     'team_headcount', 'fill'),
    (207, 'Number of employees', 'number', NULL, true,
     NULL,
     'employee_count', 'fill'),
    (208, 'Please describe makeup of the company management team', 'textarea', NULL, true,
     NULL,
     'team_management', 'fill'),
    (209, 'Are there any family relationships among the founders, board members and or managers', 'textarea', NULL, true,
     'Yes or no, describe if yes',
     'team_family_relationships', 'fill'),
    (210, 'Please describe makeup of the company advisory board', 'textarea', NULL, true,
     'CAUTION: describe advisor roles generically - no NDA partner names',
     'advisory_board', 'fill'),
    (211, 'Advisory board breakdown by role type', 'textarea', NULL, true,
     'Counts of technical experts, sales connectors, acquisition connectors, IP regulatory legal business experts, investors with sector experience, family or friends, vacancies',
     'advisory_board_breakdown', 'fill'),
    (212, 'Number of years your CEO has experience as a start-up entrepreneur', 'number', NULL, true,
     NULL,
     'ceo_startup_years', 'fill'),
    (213, 'Do any key team members have other business or educational commitments that may limit their involvement', 'textarea', NULL, true,
     'Now or in the future',
     'team_commitments', 'fill')
) AS v(seq, label, field_type, max_length, is_required, help_text, canonical_key, input_kind)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- Verify: Team block in place, ordered
-- ------------------------------------------------------------
SELECT seq, label, field_type, is_required, canonical_key
FROM app.application_form_fields ff
JOIN app.application_forms f ON f.id = ff.form_id
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq BETWEEN 201 AND 299
ORDER BY ff.seq;
