-- =============================================================================
-- 20260713200000_form_only_investor_worklist.sql   (READ-ONLY worklist)
-- =============================================================================
-- Form-only / portal-only investors do NOT receive email -- they must be
-- submitted through their web form or portal by hand. This query builds that
-- worklist, filtered to the SAME targeting as the email sequence:
--
--   sectors : deep_tech, advanced_materials, industrial, climate
--   stage   : Series A and later
--   exclude : healthcare, life_science, consumer
--   only    : preferred_contact_method in (web_form, portal)
--
-- Output = the list of forms to fill, with the URL to submit to.
-- Nothing is written. Use it as a checklist (export to CSV from the editor).
-- =============================================================================

WITH target_sector AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                  ON s.id = isf.sector_id
  WHERE s.code IN ('deep_tech','advanced_materials','industrial','climate')
),
excluded_sector AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                  ON s.id = isf.sector_id
  WHERE s.code IN ('healthcare','life_science','consumer')
),
series_a_plus AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_stage_focus sf ON sf.investor_profile_id = ip.id
  WHERE sf.stage_code IN ('series_a','series_b','series_c','growth','late_stage')
)
SELECT
  p.party_name,
  p.preferred_contact_method AS how,
  p.contact_form_url         AS submit_url,
  p.website,
  (SELECT string_agg(DISTINCT s2.code, ', ')
     FROM app.investor_profile ip2
     JOIN app.investor_sector_focus isf2 ON isf2.investor_profile_id = ip2.id
     JOIN app.sectors s2 ON s2.id = isf2.sector_id
    WHERE ip2.party_id = p.id) AS sectors
FROM app.parties p
JOIN app.investor_profile ip ON ip.party_id = p.id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND p.preferred_contact_method IN ('web_form','portal','form')
  AND p.id IN (SELECT party_id FROM target_sector)
  AND p.id IN (SELECT party_id FROM series_a_plus)
  AND p.id NOT IN (SELECT party_id FROM excluded_sector)
ORDER BY p.preferred_contact_method, p.party_name;


-- Companion count: form-only in target sectors REGARDLESS of stage
-- (in case stage focus data is sparse and the Series A filter is too strict).
WITH target_sector AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                  ON s.id = isf.sector_id
  WHERE s.code IN ('deep_tech','advanced_materials','industrial','climate')
)
SELECT COUNT(*) AS form_only_in_target_sectors_any_stage
FROM app.parties p
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND p.preferred_contact_method IN ('web_form','portal','form')
  AND p.id IN (SELECT party_id FROM target_sector);
