-- =====================================================================
-- 20260714150000_scan_stale_round_figures.sql   (READ-ONLY scan)
-- Purpose: find EVERY place the old round terms ($5M / $30M pre /
--          $35M post) still live, before running any UPDATE. Two
--          sources feed the forms:
--            A. app.answer_library.body_en/body_ko  (reusable answers)
--            B. app.application_field_answers.final_text (per-field text,
--               which may be edited copies not tied to a library row)
--
-- Current round is $3,000,000 at $27,000,000 pre / $30,000,000 post.
-- NOTE the trap: "$30,000,000" is the OLD pre-money AND the NEW post-money,
-- so a blind replace of "30,000,000" would corrupt correct rows. This scan
-- shows context so the fix can be targeted. Nothing is written here.
--
-- CTAN is intentionally a separate $100k SAFE @ $10M cap milestone round -
-- do NOT flag or change CTAN figures.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A1. answer_library rows containing any old-round figure
-- ---------------------------------------------------------------------
SELECT id, answer_key, title, disclosure_level,
       length(body_en) AS len_en,
       (body_en ILIKE '%5,000,000%' OR body_en ILIKE '%5 million%'
          OR body_en ILIKE '%$5M%')                       AS has_5m,
       (body_en ILIKE '%35,000,000%')                     AS has_35m_post,
       (body_en ILIKE '%30,000,000%')                     AS has_30m,
       body_en
FROM app.answer_library
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (
       body_en ILIKE '%5,000,000%'
    OR body_en ILIKE '%5 million%'
    OR body_en ILIKE '%$5M%'
    OR body_en ILIKE '%35,000,000%'
    OR body_en ILIKE '%30,000,000 USD pre%'
    OR body_en ILIKE '%30,000,000 pre%'
  )
ORDER BY answer_key;

-- A2. same scan on the Korean body (in case a KO variant carries it)
SELECT id, answer_key, title, length(body_ko) AS len_ko, body_ko
FROM app.answer_library
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND body_ko IS NOT NULL
  AND (
       body_ko ILIKE '%5,000,000%'
    OR body_ko ILIKE '%500만%'
    OR body_ko ILIKE '%35,000,000%'
    OR body_ko ILIKE '%30,000,000%'
  )
ORDER BY answer_key;

-- ---------------------------------------------------------------------
-- B. per-field bound answers containing old-round figures, with the
--    party + field label + whether it is tied to a library row.
--    These are what actually gets pasted into each form.
-- ---------------------------------------------------------------------
SELECT
  p.party_name,
  aff.label,
  af.status                              AS form_status,
  afa.answer_id IS NOT NULL              AS from_library,
  afa.char_count,
  afa.final_text
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name NOT ILIKE '%central texas angel%'   -- CTAN is a separate $100k round
  AND (
       afa.final_text ILIKE '%5,000,000%'
    OR afa.final_text ILIKE '%5 million%'
    OR afa.final_text ILIKE '%$5M%'
    OR afa.final_text ILIKE '%35,000,000%'
    OR afa.final_text ILIKE '%30,000,000 USD pre%'
    OR afa.final_text ILIKE '%30,000,000 pre%'
  )
ORDER BY p.party_name, aff.seq, aff.label;

-- ---------------------------------------------------------------------
-- C. counts: how big is the fix? (library rows vs per-field answers)
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM app.answer_library
     WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
       AND (body_en ILIKE '%5,000,000%' OR body_en ILIKE '%35,000,000%'
            OR body_en ILIKE '%30,000,000 pre%' OR body_en ILIKE '%30,000,000 USD pre%'))
      AS library_rows_to_fix,
  (SELECT COUNT(*) FROM app.application_field_answers afa
     JOIN app.application_form_fields aff ON aff.id = afa.field_id
     JOIN app.application_forms af        ON af.id = aff.form_id
     JOIN app.parties p                   ON p.id = af.party_id
     WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
       AND p.party_name NOT ILIKE '%central texas angel%'
       AND (afa.final_text ILIKE '%5,000,000%' OR afa.final_text ILIKE '%35,000,000%'
            OR afa.final_text ILIKE '%30,000,000 pre%' OR afa.final_text ILIKE '%30,000,000 USD pre%'))
      AS field_answers_to_fix;

-- ---------------------------------------------------------------------
-- D. the 3M Ventures one-liner mismap (asset-light cost text landed in
--    "One-line company description" and is OVER LIMIT). Confirm it here
--    so the fix can re-point it to the real 196-char one-liner.
-- ---------------------------------------------------------------------
SELECT p.party_name, aff.label, aff.max_length, afa.char_count, afa.final_text
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND aff.label ILIKE '%one-line%'
  AND aff.max_length IS NOT NULL
  AND afa.char_count > aff.max_length
ORDER BY p.party_name;
