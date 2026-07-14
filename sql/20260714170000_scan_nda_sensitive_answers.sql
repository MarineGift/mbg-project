-- =====================================================================
-- 20260714170000_scan_nda_sensitive_answers.sql   (READ-ONLY)
-- Find every per-field answer that leaks NDA-sensitive detail into a
-- public web form: the affiliate name, the deferred consideration, the
-- counterparty approval status, etc. These must be replaced with a
-- public/anonymized version before submission.
--
-- Sensitivity markers (any one is a red flag for a public form):
--   * 'Marinepad'            - names the affiliate holding the KR patents
--   * '500,000 USD'          - the deferred assignment consideration
--   * 'executive approval'   - counterparty deal-stage detail
--   * '9,000-ton' + payee    - links a named counterparty to a contract
-- =====================================================================

SELECT
  p.party_name,
  aff.label,
  af.status                                   AS form_status,
  afa.char_count,
  (afa.final_text ILIKE '%Marinepad%')        AS has_affiliate,
  (afa.final_text ILIKE '%500,000 USD%')      AS has_deferred_500k,
  (afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%') AS has_counterparty_stage,
  left(afa.final_text, 120)                   AS preview
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

-- Count + distinct exact texts (so we know how many UPDATE variants we need)
SELECT
  COUNT(*)                          AS sensitive_rows,
  COUNT(DISTINCT afa.final_text)    AS distinct_texts
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (
       afa.final_text ILIKE '%Marinepad%'
    OR afa.final_text ILIKE '%500,000 USD%'
    OR afa.final_text ILIKE '%executive approval%'
  );
