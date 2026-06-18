-- ============================================================================
-- 20260617180000_app_party_supply_links_omya_smi_batch4.sql
-- Batch 4: SMI satellite PCC plants verified against the authoritative source:
--   Minerals Technologies Inc. FORM 10-K (FY2006), Item 2 "Properties" --
--   the table listing the location and PRINCIPAL CUSTOMER of each of MTI's
--   51 satellite PCC plants as of Dec 31, 2006.
--   Source: https://investors.mineralstech.com/node/12751/html
--
-- Each row below is a plant-level SM variant matched 1:1 to a DB mill party
-- whose location and 2006 principal customer match the 10-K Item 2 entry.
-- Ownership changes since 2006 are noted (IP graphic papers -> Sylvamo 2021;
-- Soporcel -> Navigator; Advance Agro -> Double A; M-real -> Metsa Board).
-- link_type = active for all (operating per the filing); Aanekoski set to
-- medium confidence (Metsa later shifted toward board production).
--
-- Non-ASCII mill names (Aanekoski, Ruzomberok, Metsa) are referenced by UUID;
-- labels here are ASCII transliterations only (party_name in DB is unchanged).
--
-- Excluded by design: UPM Schongau (no Germany-Schongau SM variant in DB;
-- only generic "Germany" / "Germany - Stockstadt" exist), and Gold East-
-- Zhenjiang (Gold East already linked to SM Dagang in batch 3 = same mill).
--
-- Same idempotent/reversible model as batch1-3.
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
-- ============================================================================

BEGIN;

WITH rel(mill_id, filler_id, cust2006, owner_note, confidence, label) AS (
  VALUES
  ('79fb76ed-cd21-45a8-9301-4d68aaffde0f'::uuid,'b3499eb5-46d9-4374-b7af-c4d906a04837'::uuid,'International Paper Company','now Sylvamo (IP graphic papers spinoff 2021)','high','Sylvamo Ticonderoga Mill (NY)'),
  ('e4c573e5-5a7a-4025-bce3-58d8bd79a046'::uuid,'026684e2-2d91-465d-a30e-403ab4c24707'::uuid,'PT Indah Kiat Pulp and Paper Corporation','','high','PT Indah Kiat - Perawang (unit 1)'),
  ('e4c573e5-5a7a-4025-bce3-58d8bd79a046'::uuid,'55d012e2-1c60-45a7-9046-5e841f1858d3'::uuid,'PT Indah Kiat Pulp and Paper Corporation','','high','PT Indah Kiat - Perawang (unit 2)'),
  ('570aaa49-61e9-43b0-a1af-644d4403e36e'::uuid,'25c1a913-dd52-4eb2-8d63-37d76b8a4e23'::uuid,'Nippon Paper Group Inc.','SM FMT JV (filler-grade PCC)','high','Nippon Paper - Shiraoi Mill'),
  ('7b86ee8e-c3a7-4d2b-ab86-3665e81737cc'::uuid,'e14e5b00-8b6f-4a6d-a22f-acf8486d4a02'::uuid,'Mondi Paper Company Ltd.','Merebank mill is in Durban','high','Mondi Merebank (Durban)'),
  ('8a99e736-95a1-41da-9d36-09036fb96ebd'::uuid,'27dadd0f-94c5-4fcc-9030-a872c9719c58'::uuid,'Advance Agro Public Co. Ltd.','now Double A; Tha Toom mill is in Prachinburi','high','Double A - Prachinburi (Tha Toom)'),
  ('a336b16b-27d4-4153-ba11-c1bd8c594d81'::uuid,'4a418304-f0b3-45cd-9322-8687f150aa94'::uuid,'Soporcel - Sociedade Portuguesa de Papel','now The Navigator Company','high','Navigator Figueira da Foz'),
  ('e0457d0e-8072-47c6-8663-a18892ce40bc'::uuid,'992ce57b-edcc-411e-b396-1a6d5ff5bd17'::uuid,'International Paper Company','now Sylvamo (Saillat-sur-Vienne)','high','Sylvamo Saillat-sur-Vienne'),
  ('f1dd192e-832b-401e-84b1-a32f600100f4'::uuid,'ee500a51-16ab-425b-81b6-1d30b0cc495e'::uuid,'M-real Corporation','now Metsa Board; verify current paper-machine status','medium','Metsa Board Aanekoski'),
  ('27423257-e837-4103-9b55-0fef0fbb2c4d'::uuid,'7c88240a-501f-4363-ae34-a5c90855ef4d'::uuid,'Mondi Business Paper SCP','SM Slovakia variant = the Ruzomberok satellite (only SK site)','high','Mondi SCP Ruzomberok')
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, notes, extra_data, created_at, updated_at)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  r.mill_id, r.filler_id,
  'active',
  'PCC filler-grade (uncoated wood-free printing/writing)',
  NULL,
  r.confidence,
  NULL::date,
  r.label || ' | on-site satellite PCC | 2006 customer: ' || r.cust2006
    || CASE WHEN r.owner_note <> '' THEN ' | ' || r.owner_note ELSE '' END
    || ' | src: MTI 10-K FY2006 Item 2',
  jsonb_build_object(
    'evidence_url', 'https://investors.mineralstech.com/node/12751/html',
    'supply_structure', 'on-site satellite PCC',
    'link_kind', 'pcc_satellite',
    'source', 'MTI 10-K FY2006 Item 2 (Properties)',
    'principal_customer_2006', r.cust2006,
    'batch', 'omya_smi_batch4',
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
--        l.confidence, l.extra_data->>'principal_customer_2006' AS cust_2006
-- FROM app.party_supply_links l
-- JOIN app.parties m ON m.id = l.mill_party_id
-- JOIN app.parties f ON f.id = l.filler_party_id
-- WHERE l.extra_data->>'batch' = 'omya_smi_batch4' AND l.deleted_at IS NULL
-- ORDER BY f.party_name;

-- ROLLBACK helper
-- UPDATE app.party_supply_links SET deleted_at = now()
-- WHERE extra_data->>'batch' = 'omya_smi_batch4' AND deleted_at IS NULL;
