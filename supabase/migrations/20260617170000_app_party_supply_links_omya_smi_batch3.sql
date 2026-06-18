-- ============================================================================
-- 20260617170000_app_party_supply_links_omya_smi_batch3.sql
-- Batch 3: resolves the APP China deferral + adds the historical first satellite.
-- Same model/safety as batch1/2. link_type is PER-ROW (active vs historical).
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
--
-- Resolved mappings (no new party needed):
--   APP China "Dagang" mill = Gold East Paper (Jiangsu), Dagang/Zhenjiang
--       (mill has on-site GCC + PCC plant). SEC 8-K FY2004 (JV satellite).
--   APP China "Suzhou" mill = Gold Huasheng Paper (Suzhou Industrial Park).
--       SEC 8-K FY2004 (JV satellite).
--   Wisconsin Rapids mill = Consolidated Papers (now idled) -- site of the MTI
--       FIRST commercial satellite PCC plant (1986). SEC 10-K FY2000. -> historical.
-- ============================================================================

BEGIN;

WITH rel(mill_id, filler_id, lk_type, link_kind, product_grade,
         volume_estimate, confidence, active_since, evidence_url, src, structure, label) AS (
  VALUES
  ('000812ab-3fe9-45ad-9773-07f22d0283d1'::uuid,'052d5520-d52a-4ea8-8f0c-54875b0aa723'::uuid,'active','pcc_satellite','PCC filler-grade (filling + coating woodfree)','4-unit + expansion','high','2005-01-01'::date,'https://www.sec.gov/Archives/edgar/data/0000891014/000089101404000119/ex99_appagr.htm','SEC 8-K FY2004','on-site satellite PCC (JV; Gold East has on-site GCC+PCC)','Gold East Paper (APP Dagang/Zhenjiang)'),
  ('a6f46744-3238-4057-a7c9-e62403fe968b'::uuid,'2ad24bf4-b9c5-4763-aa0f-018dbcc96116'::uuid,'active','pcc_satellite','PCC filler-grade (filling UFS)','4-unit','high','2005-01-01'::date,'https://www.sec.gov/Archives/edgar/data/0000891014/000089101404000119/ex99_appagr.htm','SEC 8-K FY2004','on-site satellite PCC (JV)','Gold Huasheng Paper (APP Suzhou)'),
  ('471e45e3-b982-4704-a436-49867c91aa93'::uuid,'7a7d2a03-a727-4a5d-afd4-ec227fe6faec'::uuid,'historical','pcc_satellite','PCC filler-grade','first commercial satellite (1986)','high','1986-01-01'::date,'https://www.sec.gov/Archives/edgar/data/891014/000089101401000006/0000891014-01-000006-0001.htm','SEC 10-K FY2000','on-site satellite PCC (MTI first ever, 1986; Wisconsin Rapids mill now idled)','Consolidated Papers - Wisconsin Rapids (historical)')
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, notes, extra_data, created_at, updated_at)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  r.mill_id, r.filler_id,
  r.lk_type,
  r.product_grade, r.volume_estimate, r.confidence, r.active_since,
  r.label || ' | ' || r.structure || ' | src: ' || r.src,
  jsonb_build_object(
    'evidence_url', r.evidence_url,
    'supply_structure', r.structure,
    'link_kind', r.link_kind,
    'source', r.src,
    'batch', 'omya_smi_batch3',
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
-- WHERE l.extra_data->>'batch' = 'omya_smi_batch3' AND l.deleted_at IS NULL
-- ORDER BY f.party_name, m.party_name;

-- ROLLBACK helper
-- UPDATE app.party_supply_links SET deleted_at = now()
-- WHERE extra_data->>'batch' = 'omya_smi_batch3' AND deleted_at IS NULL;
