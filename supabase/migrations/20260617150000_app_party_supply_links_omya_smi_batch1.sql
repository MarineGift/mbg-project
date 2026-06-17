-- ============================================================================
-- 20260617150000_app_party_supply_links_omya_smi_batch1.sql
-- Record VERIFIED Omya + SMI (Specialty Minerals / Minerals Technologies)
-- paper-mill supply relationships in app.party_supply_links.
--
-- SUPERSEDES 20260617140000_industry_omya_smi_linkages_batch1.sql
-- (that one targeted the industry.* schema, which is NOT present in the live DB).
--
-- All party UUIDs below were taken from the live DB diagnostic (parties already
-- exist on both sides: paper_mill parties and filler_supplier parties, incl.
-- Specialty Minerals plant-level variants that match the satellite PCC sites).
-- The only thing missing was the link row -- that is what this inserts.
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<  Idempotent. Reversible.
--   - Dedup: NOT EXISTS on (mill_party_id, filler_party_id) among non-deleted rows.
--   - Reversible: every row tagged extra_data->>'batch' = 'omya_smi_batch1'.
--   - Source quality: SEC 8-K + MTI/Specialty Minerals press releases + Domtar/Omya
--     announcements (public). evidence_url stored per row in extra_data.
--
-- Confirmed mappings (14). Deferred (no mill party yet): APP China Dagang, APP China Suzhou.
-- ============================================================================

BEGIN;

WITH rel(mill_id, filler_id, link_type, supply_type, product_grade,
         volume_estimate, confidence, active_since, evidence_url, src, structure, label) AS (
  VALUES
  -- SMI / Specialty Minerals -- on-site satellite PCC (filler_id = matching SM plant/country variant)
  ('3f29730f-528e-47a3-bd4c-ac82c5dd2d8d'::uuid,'45a93fab-a2c0-4726-9a0f-4062f2d06511'::uuid,'pcc_satellite','active','PCC filler-grade','~46,000 mt/yr','high','2012-01-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-build-satellite-pcc-plant-india-jk-paper','MTI press release','on-site satellite PCC (JV)','JK Paper Limited - Rayagada'),
  ('99a0ef69-a3cf-4be0-b9c3-69f2c842a445'::uuid,'52f22cbe-44bc-44c8-92f5-5c42f2a580a3'::uuid,'pcc_satellite','active','PCC filler-grade','~25,000-35,000 t/yr (1 unit)','high','2003-01-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-inc-build-satellite-pcc-plant-sabah-forest','MTI press release','on-site satellite PCC','Sabah Forest Industries - Sipitang'),
  ('3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,'53b4f1fe-7d61-4ea4-bfd9-70daf624cae0'::uuid,'pcc_satellite','active','PCC filler-grade','~35,000 t/yr','high','2011-10-01'::date,'https://www.businesswire.com/news/home/20110121005554/en/Minerals-Technologies-to-Build-a-Satellite-PCC-Plant-in-India-for-the-West-Coast-Paper-Mills-Limited','Business Wire / MTI','on-site satellite PCC','West Coast Paper Mills - Dandeli'),
  ('de740c5b-323c-4a74-9a4a-7212ec9a7dd9'::uuid,'91e60359-f0e1-4127-8e78-a4557a937587'::uuid,'pcc_satellite','active','PCC filler-grade','~65,000 mt/yr (also Ashti)','high','2010-01-01'::date,'https://papermart.in/minerals-tech-to-build-a-satellite-pcc-plant-for-bilt/','Papermart / MTI','on-site satellite PCC (JV)','Ballarpur Industries (BILT) - Ballarshah'),
  ('4a2112db-b063-42c8-afb0-4126c0c7a38b'::uuid,'e6292004-1fb4-4680-ac6e-6ab7b2a61fcd'::uuid,'pcc_satellite','active','PCC filler-grade','~15,000 mt/yr','high','2011-01-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-build-another-satellite-pcc-plant-india','MTI press release','on-site satellite PCC (JV)','BILT Sewa Unit - Gaganapur'),
  ('1bb3361c-f55d-4aad-8b08-9104133beaca'::uuid,'b49cd54c-fa4d-41f0-89f4-f52f8bd59ccd'::uuid,'pcc_satellite','active','PCC filler-grade','~35,000 t/yr','high','2019-11-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-phoenix-paper-rebuild-and','MTI press release','on-site satellite PCC','Phoenix Paper LLC - Wickliffe KY'),
  ('9f3719af-21fb-4fb5-b5aa-866416b7231f'::uuid,'c2fda98a-04cf-474f-9da8-54c41ca80bac'::uuid,'pcc_satellite','active','PCC filler-grade','~45,000 mt/yr','high','2020-04-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-century-pulp-paper-install','MTI press release','on-site satellite PCC','Century Pulp & Paper - Lalkuan'),
  ('30923c37-257f-44cb-a889-fbd99f2f518b'::uuid,'96f2e46e-4fde-40d7-aa53-d976df352f16'::uuid,'pcc_satellite','active','PCC filler-grade','satellite','high','2010-01-01'::date,'https://www.sec.gov/Archives/edgar/data/0000891014/000089101409000102/ex99-1.htm','SEC 8-K','on-site satellite PCC (Mucuri)','Suzano Papel e Celulose - Mucuri'),
  ('49f234b1-f442-479c-92a0-edadf3c36964'::uuid,'b2cd5da3-ddca-45a1-ac91-9c577f46d8e6'::uuid,'pcc_satellite','active','PCC filler-grade','~2 units (50,000-70,000 t/yr)','high','2008-04-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-phoenix-pulp-paper-company','MTI press release','on-site satellite PCC (Nam Phong)','Phoenix Pulp & Paper - Nam Phong'),
  ('4f416164-129c-40d7-b835-fcfc871e7f8c'::uuid,'03badee1-e551-46ba-96f2-adaa84fd6415'::uuid,'pcc_satellite','active','PCC filler-grade','~25,000 mt/yr','high','2012-07-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-inc-build-satellite-pcc-plant-india-abc','MTI press release','on-site satellite PCC','ABC Paper Limited - Saila Khurd'),
  ('4a8427e1-a1c9-4d11-a045-dee92a50840f'::uuid,'0bb0e5c1-2b0f-4bf9-9fbb-d01851290024'::uuid,'pcc_satellite','active','PCC filler-grade','~50,000 mt/yr','high','2022-01-01'::date,'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-baiyun-paper-construct','MTI press release','on-site satellite PCC (MTI-owned)','Zhumadian Baiyun Paper - Suiping'),
  ('979a84eb-6857-42f5-bbb2-8f080879af36'::uuid,'9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,'pcc_satellite','active','PCC filler-grade','8 satellite plants (US & EU)','high',NULL,'https://www.sec.gov/Archives/edgar/data/0000891014/000089101403000027/ex99iprelease.htm','SEC 8-K','on-site satellite PCC (company-level; 8 plants)','International Paper - company-level (verify per-mill)'),
  -- Omya -- on-site / near-site (filler_id = Omya USA)
  ('42107ee3-2894-49c9-8af4-98eb4ddbd865'::uuid,'3bccf3f8-8b1e-43af-9fdd-049b62af066b'::uuid,'pcc_onsite','active','PCC filler-grade','~27,500 dry t/yr','high','2024-09-01'::date,'https://www.domtar.com/nekoosa-mill-pcc-plant/','Domtar / Omya','on-site PCC (Omya designed/owned/operated)','Domtar Nekoosa - Omya on-site'),
  ('ea842041-1311-4d41-b76f-a0c7a212f30e'::uuid,'3bccf3f8-8b1e-43af-9fdd-049b62af066b'::uuid,'pcc_nearsite','active','PCC filler-grade','supplied from Nekoosa','high','2024-09-01'::date,'https://www.domtar.com/nekoosa-mill-pcc-plant/','Domtar / Omya','near-site (from Nekoosa Omya plant)','Domtar Rothschild - Omya near-site')
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type, supply_type,
   product_grade, volume_estimate, confidence, active_since, notes, extra_data, created_at, updated_at)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  r.mill_id, r.filler_id, r.link_type,
  r.supply_type::app.supply_link_type,
  r.product_grade, r.volume_estimate, r.confidence, r.active_since,
  r.label || ' | ' || r.structure || ' | src: ' || r.src,
  jsonb_build_object(
    'evidence_url', r.evidence_url,
    'supply_structure', r.structure,
    'source', r.src,
    'batch', 'omya_smi_batch1',
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

-- ----------------------------------------------------------------------------
-- VERIFY (optional, read-only)
-- ----------------------------------------------------------------------------
-- SELECT m.party_name AS mill, f.party_name AS filler, l.link_type, l.supply_type,
--        l.volume_estimate, l.active_since, l.extra_data->>'evidence_url' AS evidence
-- FROM app.party_supply_links l
-- JOIN app.parties m ON m.id = l.mill_party_id
-- JOIN app.parties f ON f.id = l.filler_party_id
-- WHERE l.extra_data->>'batch' = 'omya_smi_batch1' AND l.deleted_at IS NULL
-- ORDER BY f.party_name, m.party_name;

-- ----------------------------------------------------------------------------
-- ROLLBACK helper (soft-delete this batch)
-- ----------------------------------------------------------------------------
-- UPDATE app.party_supply_links SET deleted_at = now()
-- WHERE extra_data->>'batch' = 'omya_smi_batch1' AND deleted_at IS NULL;
