-- ============================================================================
-- 20260617160000_app_party_supply_links_omya_smi_batch2.sql
-- Batch 2: 4 more VERIFIED Omya + SMI paper-mill supply links.
-- Same model as batch1 (app.party_supply_links; link_type='active'; UUIDs from
-- live diagnostic; idempotent; reversible via extra_data->>'batch').
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
--
-- Sources:
--   - Omya/NewPage Escanaba on-site PCC (2013): PRNewswire.
--   - MTI 2023 three new satellite agreements (Andhra Paper Rajahmundry IN,
--     Nine Dragons Beihai CN, Zhejiang Zhefeng Quzhou CN), online late 2023/2024:
--     GLOBE NEWSWIRE 2023-04-18 (combined >180,000 mt/yr).
-- NOTE: Escanaba is OMYA, not SMI (a common mislabel -- the SM "USA - Escanaba"
--       filler variant must NOT be linked here).
-- ============================================================================

BEGIN;

WITH rel(mill_id, filler_id, link_kind, product_grade,
         volume_estimate, confidence, active_since, evidence_url, src, structure, label) AS (
  VALUES
  -- Omya on-site (filler_id = Omya USA)
  ('2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid,'3bccf3f8-8b1e-43af-9fdd-049b62af066b'::uuid,'pcc_onsite','PCC filler-grade','on-site PCC','high','2013-08-01'::date,'https://www.prnewswire.com/news-releases/omya-and-newpage-escanaba-enter-into-agreement-to-build-pcc-plant-214897231.html','PRNewswire / Omya-NewPage','on-site PCC (Omya built/operated; uses mill CO2)','Billerud Escanaba (ex-NewPage) - Omya on-site'),
  -- SMI satellites (2023 agreements; filler_id = matching SM plant variant)
  ('6ad04789-209f-4df1-b185-24a50c60717d'::uuid,'25dce85a-bd2f-4929-95ca-4eb054bc2160'::uuid,'pcc_satellite','PCC filler-grade (NewYield LO)','~60,000 mt/yr (3-site combined >180k)','high','2024-01-01'::date,'https://www.globenewswire.com/news-release/2023/04/18/2649591/0/en/Minerals-Technologies-Further-Expands-in-China-and-India-Paper-Markets.html','MTI press release 2023','on-site satellite PCC (NewYield LO; mill waste-stream feed)','Andhra Paper - Rajahmundry'),
  ('6f7c12be-0182-4ccd-bced-89c8cc41901d'::uuid,'e5bdc53e-f60f-4769-8b85-de58d9abe44c'::uuid,'pcc_satellite','PCC filler-grade','~60,000 mt/yr (3-site combined >180k)','high','2024-01-01'::date,'https://www.globenewswire.com/news-release/2023/04/18/2649591/0/en/Minerals-Technologies-Further-Expands-in-China-and-India-Paper-Markets.html','MTI press release 2023','on-site satellite PCC','Nine Dragons - Beihai'),
  ('6939a129-bfa2-4114-be61-529b8e487ec1'::uuid,'7afab3d5-07a8-4bf7-bc17-cc0d798025a1'::uuid,'pcc_satellite','PCC filler-grade','~60,000 mt/yr (3-site combined >180k)','high','2024-01-01'::date,'https://www.globenewswire.com/news-release/2023/04/18/2649591/0/en/Minerals-Technologies-Further-Expands-in-China-and-India-Paper-Markets.html','MTI press release 2023','on-site satellite PCC','Zhejiang Zhefeng New Materials - Quzhou')
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, notes, extra_data, created_at, updated_at)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  r.mill_id, r.filler_id,
  'active',
  r.product_grade, r.volume_estimate, r.confidence, r.active_since,
  r.label || ' | ' || r.structure || ' | src: ' || r.src,
  jsonb_build_object(
    'evidence_url', r.evidence_url,
    'supply_structure', r.structure,
    'link_kind', r.link_kind,
    'source', r.src,
    'batch', 'omya_smi_batch2',
    'researched_at', '2026-06-17'
  ),
  now(), now()
FROM rel r
WHERE NOT EXISTS (
  SELECT 1 FROM app.party_supply_links x
  WHERE x.mill_party_id = r.mill_id
    AND x.filler_party_id = r.filler_id
    AND x.deleted_at IS NULL
);

COMMIT;

-- VERIFY (optional, read-only)
-- SELECT m.party_name AS mill, f.party_name AS filler, l.link_type,
--        l.extra_data->>'link_kind' AS kind, l.volume_estimate, l.active_since,
--        l.extra_data->>'evidence_url' AS evidence
-- FROM app.party_supply_links l
-- JOIN app.parties m ON m.id = l.mill_party_id
-- JOIN app.parties f ON f.id = l.filler_party_id
-- WHERE l.extra_data->>'batch' = 'omya_smi_batch2' AND l.deleted_at IS NULL
-- ORDER BY f.party_name, m.party_name;

-- ROLLBACK helper
-- UPDATE app.party_supply_links SET deleted_at = now()
-- WHERE extra_data->>'batch' = 'omya_smi_batch2' AND deleted_at IS NULL;
