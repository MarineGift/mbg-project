-- ============================================================================
-- 20260617140000_industry_omya_smi_linkages_batch1.sql
-- Enrich industry.supplier_mill_linkages with VERIFIED paper-mill supply
-- relationships for the two priority filler suppliers: Omya and SMI
-- (Specialty Minerals Inc. / Minerals Technologies).
--
-- Source quality: SEC 8-K filings, MTI/Specialty Minerals press releases, and
-- Domtar/Omya company announcements (all public). Each row carries an
-- evidence URL. Confidence grade A throughout.
--
-- >>> RUN MANUALLY IN THE SUPABASE SQL EDITOR. <<<
-- (Pushing this file to the repo only records it; it does NOT apply to the DB.)
--
-- Properties:
--   - Idempotent: re-running inserts nothing new (NOT EXISTS dedup).
--   - Safe when blind: supplier ids resolve by name; if a supplier or a
--     company/mill is not found, the row still records via the *_raw columns
--     (exactly how the existing ~52% unmatched linkages already work). No FK is
--     ever forced, so no bad joins and no fan-out duplicates.
--   - Reversible: every inserted row is tagged
--     assessment_scope = 'mbg-research-2026-06 (omya/smi batch1)'.
--     See the ROLLBACK helper at the bottom.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 0  (OPTIONAL, run first to sanity-check) -- safe read-only
-- ----------------------------------------------------------------------------
-- Confirm how Omya / SMI are named in industry.filler_suppliers and how many
-- linkages exist today. Uncomment to run on its own before the transaction.
--
-- SELECT id, name, market_code, supplier_type
-- FROM industry.filler_suppliers
-- WHERE lower(name) LIKE 'omya%'
--    OR lower(name) LIKE 'specialty mineral%'
--    OR lower(name) LIKE 'minerals technolog%'
--    OR lower(name) = 'smi'
-- ORDER BY name;
--
-- SELECT count(*) AS linkages_total,
--        count(*) FILTER (WHERE assessment_scope = 'mbg-research-2026-06 (omya/smi batch1)') AS already_this_batch
-- FROM industry.supplier_mill_linkages;

-- ----------------------------------------------------------------------------
-- MAIN TRANSACTION
-- ----------------------------------------------------------------------------
BEGIN;

-- 1) Resolve the two supplier ids by name (NULL-safe; raw name kept regardless).
CREATE TEMPORARY TABLE _sup_lookup ON COMMIT DROP AS
SELECT
  (SELECT id FROM industry.filler_suppliers
     WHERE lower(name) LIKE 'omya%'
     ORDER BY (lower(name) = 'omya') DESC, (market_code = 'switzerland') DESC, length(name), id
     LIMIT 1) AS omya_id,
  (SELECT id FROM industry.filler_suppliers
     WHERE lower(name) LIKE 'specialty mineral%'
        OR lower(name) LIKE 'minerals technolog%'
        OR lower(name) = 'smi'
     ORDER BY length(name), id
     LIMIT 1) AS smi_id;

-- 2) Batch 1 verified relationships (staging).
CREATE TEMPORARY TABLE _lk_stage (
  supplier          text,      -- 'omya' | 'smi'
  supplier_raw      text,
  market_code       text,
  company_raw       text,
  mill_raw          text,
  filler_type       text,
  supply_structure  text,
  relationship_type text,
  confidence_grade  char(1),
  evidence_level    text,
  evidence_url      text,
  current_status    text,
  notes             text
) ON COMMIT DROP;

INSERT INTO _lk_stage
  (supplier, supplier_raw, market_code, company_raw, mill_raw, filler_type,
   supply_structure, relationship_type, confidence_grade, evidence_level,
   evidence_url, current_status, notes) VALUES
-- ---- SMI / Specialty Minerals (Minerals Technologies) -- satellite PCC = on-site ----
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','JK Paper Limited','Rayagada mill (Odisha)','PCC','on-site (satellite PCC, JV)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-build-satellite-pcc-plant-india-jk-paper','reported active (verify current 2026)','~46,000 mt/yr; JV; announced 2011; JK largest mill near Rayagada'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','malaysia','Sabah Forest Industries (BILT group)','Sipitang mill (Sabah)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-inc-build-satellite-pcc-plant-sabah-forest','reported active (verify current 2026)','1 unit (25-35k t/yr); announced 2002, online 2003; SFI owned by Ballarpur/BILT'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','china','Asia Pulp and Paper (APP China)','Dagang mill','PCC','on-site (satellite PCC, JV)','filler supply (PCC)','A','E1','https://www.sec.gov/Archives/edgar/data/0000891014/000089101404000119/ex99_appagr.htm','reported active (verify current 2026)','4-unit satellite via JV APP China Specialty Minerals Pte Ltd; filling + coating woodfree'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','china','Asia Pulp and Paper (APP China)','Suzhou mill','PCC','on-site (satellite PCC, JV)','filler supply (PCC)','A','E1','https://www.sec.gov/Archives/edgar/data/0000891014/000089101404000119/ex99_appagr.htm','reported active (verify current 2026)','4-unit satellite via JV; online Q1 2005; filling UFS and other grades'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','West Coast Paper Mills Limited','Dandeli mill (Karnataka)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E2','https://www.businesswire.com/news/home/20110121005554/en/Minerals-Technologies-to-Build-a-Satellite-PCC-Plant-in-India-for-the-West-Coast-Paper-Mills-Limited','reported active (verify current 2026)','~35,000 t/yr; long-term agreement; online Q4 2011; Kali River, Dandeli'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','Ballarpur Industries Limited (BILT)','Ballarshah Unit mill (Maharashtra)','PCC','on-site (satellite PCC, JV)','filler supply (PCC)','A','E2','https://papermart.in/minerals-tech-to-build-a-satellite-pcc-plant-for-bilt/','reported active (verify current 2026)','~65,000 mt/yr; also supplies BILT Ashti Unit; JV SMI NewQuest India; announced 2009'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','Ballarpur Industries Limited (BILT)','Sewa Unit mill, Gaganapur (Orissa)','PCC','on-site (satellite PCC, JV)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-build-another-satellite-pcc-plant-india','reported active (verify current 2026)','15,000 mt/yr; JV SMI NewQuest India; online Q1 2011'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','usa','Phoenix Paper LLC (Shanying International)','Wickliffe mill (Kentucky)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-phoenix-paper-rebuild-and','active','35,000 t/yr; rebuilt satellite, agreement 2020; mill restarted 2019'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','Century Pulp and Paper (Century Textiles and Industries)','Lalkuan mill, District Nainital (Uttarakhand)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-century-pulp-paper-install','active','45,000 mt/yr; agreement 2019, online Q2 2020; fine paper grades'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','brazil','Suzano Papel e Celulose','Mucuri mill (Bahia)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://www.sec.gov/Archives/edgar/data/0000891014/000089101409000102/ex99-1.htm','reported active (verify current 2026)','satellite at Mucuri mill; expansion in operation Q1 2010'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','thailand','Phoenix Pulp and Paper (Siam Cement Group)','Nam Phong mill (Khon Kaen)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-phoenix-pulp-paper-company','reported active (verify current 2026)','2 units; agreement 2007, online Q2 2008; uses mill CO2'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','india','ABC Paper Limited','Saila Khurd mill (Punjab)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-inc-build-satellite-pcc-plant-india-abc','reported active (verify current 2026)','25,000 mt/yr; agreement 2011, online Q3 2012; agro-fiber printing/writing'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','china','Zhumadianshi Baiyun Paper Co Ltd','Suiping County mill, Zhumadian (Henan)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://investors.mineralstech.com/news-releases/news-release-details/minerals-technologies-signs-agreement-baiyun-paper-construct','active','50,000 mt/yr; wholly MTI-owned; online H1 2022; 10th China satellite'),
('smi','Specialty Minerals Inc. (Minerals Technologies)','usa','International Paper Company','(8 satellite PCC plants at IP mills, US and Europe)','PCC','on-site (satellite PCC)','filler supply (PCC)','A','E1','https://www.sec.gov/Archives/edgar/data/0000891014/000089101403000027/ex99iprelease.htm','long-term (contracts extended to 2015; verify current 2026)','MTI largest customer; 8 satellite plant supply contracts; ~11.5% of MTI 2002 sales; company-level (specific mills not enumerated in this filing)'),
-- ---- Omya -- on-site / near-site GCC-PCC ----
('omya','Omya','usa','Domtar (Paper Excellence)','Nekoosa mill (Wisconsin)','PCC','on-site (Omya designed/owned/operated)','filler supply (PCC)','A','E1','https://www.domtar.com/nekoosa-mill-pcc-plant/','active','27,500 dry t/yr; online Sep 2024; built within Nekoosa mill footprint; agreed Jul 2022'),
('omya','Omya','usa','Domtar (Paper Excellence)','Rothschild mill (Wisconsin)','PCC','near-site (supplied from Nekoosa on-site plant)','filler supply (PCC)','A','E1','https://www.domtar.com/nekoosa-mill-pcc-plant/','active','PCC supplied from Domtar Nekoosa Omya plant; replaced 2020-closed regional supplier');

-- 3) Insert linkages that do not already exist for this batch.
--    FK match (paper_company_id / paper_mill_id) is attempted via scalar
--    subqueries with prefix-containment (safe, no fan-out). If no confident
--    match, FK stays NULL and the *_raw columns carry the data.
INSERT INTO industry.supplier_mill_linkages
  (market_code, filler_supplier_id, paper_company_id, paper_mill_id,
   supplier_name_raw, paper_company_name_raw, mill_site_raw, country_region,
   relationship_type, filler_type, supply_structure, confirmation_status,
   confidence_grade, evidence_level, supplier_evidence_url, transaction_evidence_url,
   current_status, assessment_scope, notes)
SELECT
  s.market_code,
  CASE s.supplier WHEN 'omya' THEN l.omya_id WHEN 'smi' THEN l.smi_id END,
  (SELECT pc.id FROM industry.paper_companies pc
     WHERE pc.market_code = s.market_code
       AND ( lower(s.company_raw) LIKE lower(pc.name) || '%'
          OR lower(pc.name)       LIKE lower(s.company_raw) || '%' )
     ORDER BY length(pc.name) DESC, pc.id
     LIMIT 1),
  (SELECT pm.id FROM industry.paper_mills pm
     WHERE pm.market_code = s.market_code
       AND lower(s.mill_raw) LIKE '%' || lower(pm.mill_name) || '%'
       AND length(pm.mill_name) >= 4
     ORDER BY length(pm.mill_name) DESC, pm.id
     LIMIT 1),
  s.supplier_raw,
  s.company_raw,
  s.mill_raw,
  (SELECT name FROM industry.markets m WHERE m.code = s.market_code),
  s.relationship_type, s.filler_type, s.supply_structure, 'confirmed',
  s.confidence_grade, s.evidence_level, s.evidence_url, s.evidence_url,
  s.current_status, 'mbg-research-2026-06 (omya/smi batch1)', s.notes
FROM _lk_stage s
CROSS JOIN _sup_lookup l
WHERE NOT EXISTS (
  SELECT 1 FROM industry.supplier_mill_linkages x
  WHERE x.market_code = s.market_code
    AND lower(coalesce(x.mill_site_raw, '')) = lower(s.mill_raw)
    AND coalesce(x.supplier_name_raw, '') ILIKE left(s.supplier_raw, 12) || '%'
);

COMMIT;

-- ----------------------------------------------------------------------------
-- STEP 4  (OPTIONAL verification) -- safe read-only
-- ----------------------------------------------------------------------------
-- SELECT l.supplier_name_raw, l.paper_company_name_raw, l.mill_site_raw,
--        l.market_code, l.supply_structure, l.confidence_grade,
--        (l.filler_supplier_id IS NOT NULL) AS supplier_fk,
--        (l.paper_company_id  IS NOT NULL) AS company_fk,
--        (l.paper_mill_id     IS NOT NULL) AS mill_fk,
--        l.current_status, l.supplier_evidence_url
-- FROM industry.supplier_mill_linkages l
-- WHERE l.assessment_scope = 'mbg-research-2026-06 (omya/smi batch1)'
-- ORDER BY l.supplier_name_raw, l.market_code, l.paper_company_name_raw;

-- ----------------------------------------------------------------------------
-- ROLLBACK HELPER (only if you want to remove this batch)
-- ----------------------------------------------------------------------------
-- DELETE FROM industry.supplier_mill_linkages
-- WHERE assessment_scope = 'mbg-research-2026-06 (omya/smi batch1)';
