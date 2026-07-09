-- ============================================================
-- seed_ctan_overview_fields.sql
-- CTAN application on Dealum, step 1 of N: Overview
-- Source: real form content pasted 2026-07-09 (not estimates)
--
-- seq numbering: step blocks. Overview = 101..119.
-- Later steps will use 201.., 301.. The original 8 estimated
-- questions (seq 1..8) stay untouched until every step is
-- captured, then a separate reconcile script cleans them up.
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
    (101, 'Brand or trade name', 'text', NULL::integer, true,
     'Brand name customers know you by, not the full legal name',
     'brand_name', 'fill'),
    (102, 'Company logo', 'file', NULL, false,
     'Vector svg or high resolution image recommended',
     'company_logo', 'upload'),
    (103, 'Primary currency', 'dropdown', NULL, true,
     'All financial information is gathered in this currency - use USD',
     'primary_currency', 'select_option'),
    (104, 'One-liner', 'textarea', NULL, true,
     'Descriptive sentence, not marketing. Formula: company is developing a defined offering to help a defined audience solve a problem with a secret sauce',
     'company_one_liner', 'fill'),
    (105, 'Website', 'url', NULL, true,
     NULL,
     'website', 'fill'),
    (106, 'Is your company registered or incorporated', 'dropdown', NULL, true,
     'Yes or no toggle',
     'is_incorporated', 'check'),
    (107, 'Company legal name', 'text', NULL, true,
     NULL,
     'company_legal_name', 'fill'),
    (108, 'Registration date', 'date', NULL, true,
     NULL,
     'incorporation_date', 'fill'),
    (109, 'Company legal entity type', 'text', NULL, true,
     'For example LLC or C-Corp',
     'legal_entity_type', 'fill'),
    (110, 'Country', 'dropdown', NULL, true,
     'United States',
     'hq_country', 'select_option'),
    (111, 'Address line 1', 'text', NULL, true,
     NULL,
     'hq_address_1', 'fill'),
    (112, 'Address line 2', 'text', NULL, false,
     NULL,
     'hq_address_2', 'fill'),
    (113, 'City or town', 'text', NULL, true,
     NULL,
     'hq_city', 'fill'),
    (114, 'State province or region', 'text', NULL, true,
     NULL,
     'hq_state', 'fill'),
    (115, 'Postal code', 'text', NULL, true,
     'ZIP code in the US',
     'hq_postal_code', 'fill'),
    (116, 'Customer focus', 'dropdown', NULL, true,
     'Customer types you sell to: B2B or B2B2B or B2C or B2G or C2C or B2B2C',
     'customer_focus', 'select_option'),
    (117, 'Pitch deck pdf', 'file', NULL, true,
     'Slides summarizing your company, shown only on deal room applications',
     'pitch_deck', 'upload'),
    (118, 'Video link', 'url', NULL, false,
     'YouTube or Vimeo or Loom',
     'video_link', 'fill'),
    (119, 'Images', 'file', NULL, false,
     'Product images, charts, diagrams',
     'product_images', 'upload')
) AS v(seq, label, field_type, max_length, is_required, help_text, canonical_key, input_kind)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- Verify: Overview block in place, ordered
-- ------------------------------------------------------------
SELECT seq, label, field_type, is_required, canonical_key, input_kind
FROM app.application_form_fields ff
JOIN app.application_forms f ON f.id = ff.form_id
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq BETWEEN 101 AND 199
ORDER BY ff.seq;
