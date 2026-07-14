-- =====================================================================
-- 20260714200000_list_nda_rows_full.sql   (READ-ONLY, single query)
-- Returns the 9 NDA-sensitive per-field answers, one row each, with the
-- FULL text and which markers tripped. Single SELECT so the editor shows
-- exactly these rows (no trailing result set to overwrite the capture).
--
-- Paste the result back so the 6 anonymized UPDATE variants can be built.
-- =====================================================================
SELECT
  p.party_name,
  aff.label,
  af.status                                        AS form_status,
  afa.field_id,
  (afa.final_text ILIKE '%Marinepad%')             AS has_affiliate,
  (afa.final_text ILIKE '%500,000 USD%')           AS has_deferred_500k,
  (afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%')   AS has_counterparty_stage,
  afa.char_count,
  afa.final_text
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (
       afa.final_text ILIKE '%Marinepad%'
    OR afa.final_text ILIKE '%500,000 USD%'
    OR afa.final_text ILIKE '%executive approval%'
  )
ORDER BY p.party_name, aff.seq, aff.label;
