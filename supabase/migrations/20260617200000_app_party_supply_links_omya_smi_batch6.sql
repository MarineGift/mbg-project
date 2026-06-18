-- ============================================================================
-- 20260617200000_app_party_supply_links_omya_smi_batch6.sql  (FINAL)
-- Batch 6: Chillicothe -> HISTORICAL + three NEW SMI/GCC satellites.
-- Resolved against the 2026-06-17 diagnostic (exact UUIDs / party names).
--
-- All four SM/GCC filler-site parties ALREADY EXIST (filler UUIDs used directly):
--   Sri Muktsar Sahib = c62365b8-c3b6-43e7-a87a-3d37d8a2ee92
--   Erode             = 7ed2a5a7-f4c8-46f4-a409-1a4e2b8874d2
--   Rugao             = 1634a616-31c0-4db6-ade9-af470c898fe3
--   Chillicothe OH    = 5455bfb0-51d1-4eb6-94a8-b76b86facb9b
--
-- Mills: Satia / SPB / Asia Symbol (Rugao) already exist -> linked by exact name.
--   The Chillicothe host mill is ABSENT -> created in section A, then linked.
--
--   - Satia Industries (Sri Muktsar Sahib, Punjab): PCC, op. 2021. active/high.
--     src: MTI PR 2020-05-21
--   - Seshasayee Paper & Boards / SPB (Erode, Tamil Nadu): PCC, op. 2022. active/high.
--     src: MTI PR 2021-12-16
--   - Asia Symbol (Rugao, Nantong, Jiangsu): GCC for coated paperboard
--     (first GCC-for-packaging satellite), ~2023. active/high. link_kind=gcc_satellite.
--     src: MTI PR 2021-12-16
--   - Chillicothe OH (ex-Glatfelter, now Pixelle): 2006 10-K satellite; mill
--     CLOSED by Pixelle ~Aug 2025. historical/high. active_until 2025-08-10.
--     src: MTI 10-K FY2006 Item 2 + 2025 closure news
--
-- Idempotent (NOT EXISTS) and reversible (batch tag). ASCII only.
-- >>> RUN IN THE SUPABASE SQL EDITOR. (repo push does NOT touch the DB.) <<<
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- SECTION A -- create the Chillicothe host mill (absent per diagnostic).
--   entity_type_id is NOT NULL -> inherit from an existing paper_mill party.
-- ----------------------------------------------------------------------------
INSERT INTO app.parties
  (id, organization_id, party_type_id, entity_type_id, party_name, country_code, region, city,
   status, source, notes, created_at, updated_at)
SELECT gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169', 2,
       COALESCE((SELECT p.entity_type_id FROM app.parties p
                   WHERE p.organization_id='b25de8f2-1020-482f-9012-183f63883169' AND p.deleted_at IS NULL
                     AND p.party_type_id=2 AND p.entity_type_id IS NOT NULL LIMIT 1), 1),
       'Pixelle Specialty Solutions (Chillicothe, OH) [closed 2025]','US','Ohio','Chillicothe',
       'inactive','industry-research','ex-Glatfelter; SMI satellite host mill; closed by Pixelle Aug 2025',
       now(), now()
WHERE NOT EXISTS (
  SELECT 1 FROM app.parties p
  WHERE p.organization_id='b25de8f2-1020-482f-9012-183f63883169' AND p.deleted_at IS NULL
    AND p.party_type_id=2
    AND lower(p.party_name)=lower('Pixelle Specialty Solutions (Chillicothe, OH) [closed 2025]')
);

-- ----------------------------------------------------------------------------
-- SECTION B -- the supply links (filler by UUID, mill by exact name).
-- ----------------------------------------------------------------------------
WITH rel(mill_name, filler_id, link_type, active_since, active_until, confidence,
         link_kind, product, cust_note, src, evidence_url, label) AS (
  VALUES
  ('Satia Industries Limited',
     'c62365b8-c3b6-43e7-a87a-3d37d8a2ee92'::uuid,'active','2021-04-01'::date,NULL::date,'high',
     'pcc_satellite','PCC filler-grade (uncoated wood-free printing/writing)',
     'Satia Industries (new SMI customer 2020); ~42,000 mt/yr','MTI press release 2020-05-21',
     'https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-satia-industries-limited',
     'Satia Industries - Sri Muktsar Sahib (PCC)'),
  ('Seshasayee Paper & Boards Ltd.',
     '7ed2a5a7-f4c8-46f4-a409-1a4e2b8874d2'::uuid,'active','2022-10-01'::date,NULL::date,'high',
     'pcc_satellite','PCC filler-grade (uncoated wood-free printing/writing)',
     'Seshasayee Paper & Boards (SPB); ~22,000 mt/yr','MTI press release 2021-12-16',
     'https://www.globenewswire.com/news-release/2021/12/16/2353551/0/en/Minerals-Technologies-Announces-Two-New-Satellite-Contracts-in-Asia.html',
     'Seshasayee Paper & Boards - Erode (PCC)'),
  ('Asia Symbol (Rugao, Nantong)',
     '1634a616-31c0-4db6-ade9-af470c898fe3'::uuid,'active','2023-01-01'::date,NULL::date,'high',
     'gcc_satellite','GCC for coated paperboard (packaging)',
     'Asia Symbol coated-paperboard mill; MTI first GCC-for-packaging satellite','MTI press release 2021-12-16',
     'https://www.globenewswire.com/news-release/2021/12/16/2353551/0/en/Minerals-Technologies-Announces-Two-New-Satellite-Contracts-in-Asia.html',
     'Asia Symbol - Rugao (GCC, coated paperboard)'),
  ('Pixelle Specialty Solutions (Chillicothe, OH) [closed 2025]',
     '5455bfb0-51d1-4eb6-94a8-b76b86facb9b'::uuid,'historical','2006-01-01'::date,'2025-08-10'::date,'high',
     'pcc_satellite','PCC filler-grade (uncoated/coated wood-free printing/writing)',
     'Glatfelter (2006 customer); mill closed by Pixelle Aug 2025','MTI 10-K FY2006 Item 2 + 2025 closure news',
     'https://www.globenewswire.com/news-release/2025/04/15/3061838/0/en/Pixelle-Specialty-Solutions-Announces-Closure-of-Chillicothe-Mill.html',
     'Pixelle Chillicothe (ex-Glatfelter) -- CLOSED 2025')
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until, notes, extra_data, created_at, updated_at)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  m.id, r.filler_id,
  r.link_type,
  r.product,
  NULL,
  r.confidence,
  r.active_since,
  r.active_until,
  r.label || ' | on-site satellite | ' || r.cust_note || ' | src: ' || r.src,
  jsonb_build_object(
    'evidence_url', r.evidence_url,
    'supply_structure', 'on-site satellite',
    'link_kind', r.link_kind,
    'source', r.src,
    'customer_note', r.cust_note,
    'batch', 'omya_smi_batch6',
    'researched_at', '2026-06-17'
  ),
  now(), now()
FROM rel r
JOIN app.parties m
  ON lower(m.party_name) = lower(r.mill_name)
 AND m.organization_id='b25de8f2-1020-482f-9012-183f63883169' AND m.deleted_at IS NULL
 AND m.party_type_id = (SELECT id FROM app.party_types WHERE code='paper_mill')
WHERE NOT EXISTS (
  SELECT 1 FROM app.party_supply_links x
  WHERE x.mill_party_id = m.id AND x.filler_party_id = r.filler_id AND x.deleted_at IS NULL
);

COMMIT;

-- VERIFY (read-only) -- expect 4 rows
-- SELECT m.party_name AS mill, f.party_name AS filler, l.link_type, l.confidence,
--        l.active_until, l.extra_data->>'link_kind' AS kind
-- FROM app.party_supply_links l
-- JOIN app.parties m ON m.id = l.mill_party_id
-- JOIN app.parties f ON f.id = l.filler_party_id
-- WHERE l.extra_data->>'batch' = 'omya_smi_batch6' AND l.deleted_at IS NULL
-- ORDER BY f.party_name;

-- ROLLBACK helper (links only; does NOT remove the created Chillicothe mill)
-- UPDATE app.party_supply_links SET deleted_at = now()
-- WHERE extra_data->>'batch' = 'omya_smi_batch6' AND deleted_at IS NULL;
