-- =====================================================================
-- 20260714220001_final_verify_ip_anon.sql   (READ-ONLY, single query)
-- Final gate for IP anonymization. Searches ALL four sensitive markers
-- (incl. 'executive level'). Expect 0 rows -> anonymization complete.
-- =====================================================================
SELECT
  p.party_name,
  aff.label,
  af.status,
  afa.char_count,
  (afa.final_text ILIKE '%Marinepad%')         AS affil,
  (afa.final_text ILIKE '%500,000 USD%')        AS k500,
  (afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%') AS cpstage
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
