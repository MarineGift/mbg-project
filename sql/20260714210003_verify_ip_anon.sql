-- =====================================================================
-- 20260714210003_verify_ip_anon.sql   (READ-ONLY, single query)
-- Final check for the IP anonymization: NO public web-form answer may
-- still contain the affiliate name, the transfer figure, or the
-- counterparty deal-stage. Expect 0 rows.
--
-- If rows come back, the matching UPDATE (PART 1-6 of
-- 20260714210000_anonymize_ip_answers.sql) did not run for that text -
-- re-run that part.
-- =====================================================================
SELECT
  p.party_name,
  aff.label,
  af.status,
  afa.char_count,
  (afa.final_text ILIKE '%Marinepad%')        AS has_affiliate,
  (afa.final_text ILIKE '%500,000 USD%')       AS has_deferred_500k,
  (afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%') AS has_counterparty_stage
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (afa.final_text ILIKE '%Marinepad%'
    OR afa.final_text ILIKE '%500,000 USD%'
    OR afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%')
ORDER BY p.party_name, aff.label;
