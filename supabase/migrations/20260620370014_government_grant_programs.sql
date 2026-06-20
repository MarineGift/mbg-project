-- ============================================================
-- 20260620370014_government_grant_programs.sql
-- Seed government_grant pipeline (party_type_id=7), currently empty. 17 programs/agencies:
-- US (5), EU (5), KR (7). Source: gov_grant_2026Q3. Public agencies/programmes (names verified 2026-06).
-- Party-level only; entity_type=1. Idempotent: NOT EXISTS on lower(party_name)+type=7+live.
-- country_code 'EU' used for pan-European programmes (ISO 3166 exceptionally-reserved).
-- Selection biased to MBG domains: advanced materials, marine bio, paper, climate, deep tech.
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select v.* from (values
  (7::smallint,1::smallint,'U.S. Department of Energy (DOE)','US','Washington DC','Washington','https://www.energy.gov','active','gov_grant_2026Q3','Federal energy/materials R&D funding; offices relevant to advanced materials and industrial decarbonization.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'ARPA-E','US','Washington DC','Washington','https://arpa-e.energy.gov','active','gov_grant_2026Q3','DOE high-risk energy tech agency; relevant to materials, process and carbon technologies.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'NSF SBIR/STTR (America''s Seed Fund)','US','Virginia','Alexandria','https://seedfund.nsf.gov','active','gov_grant_2026Q3','Non-dilutive seed grants for deep-tech startups incl. advanced materials and biotech.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'NIST','US','Maryland','Gaithersburg','https://www.nist.gov','active','gov_grant_2026Q3','Standards and materials-science programs; manufacturing and measurement grants.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'DOE Bioenergy Technologies Office (BETO)','US','Washington DC','Washington','https://www.energy.gov/eere/bioenergy','active','gov_grant_2026Q3','Bio-based materials, biomass and biorefinery funding; relevant to marine/bio feedstocks.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'Horizon Europe','EU','EU','Brussels','https://research-and-innovation.ec.europa.eu','active','gov_grant_2026Q3','EU flagship R&I framework programme; materials, climate, bioeconomy and industrial pillars.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'EIC Accelerator','EU','EU','Brussels','https://eic.ec.europa.eu','active','gov_grant_2026Q3','European Innovation Council blended finance (grant + equity) for deep-tech scale-ups.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'EIC Pathfinder','EU','EU','Brussels','https://eic.ec.europa.eu','active','gov_grant_2026Q3','EIC early-stage funding for breakthrough/deep science incl. novel materials.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'EU Innovation Fund','EU','EU','Brussels','https://climate.ec.europa.eu','active','gov_grant_2026Q3','Large-scale industrial decarbonization and clean-tech demonstration funding (ETS-financed).','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'LIFE Programme','EU','EU','Brussels','https://cinea.ec.europa.eu','active','gov_grant_2026Q3','EU environment and climate-action funding; circular economy and low-impact materials.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'KEIT (Korea Evaluation Institute of Industrial Technology)','KR','Daegu','Daegu','https://www.keit.re.kr','active','gov_grant_2026Q3','MOTIE industrial-technology R&D planning/evaluation agency; core materials and manufacturing programs.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'KIAT (Korea Institute for Advancement of Technology)','KR','Seoul','Seoul','https://www.kiat.or.kr','active','gov_grant_2026Q3','MOTIE industrial-tech innovation funding and international R&D cooperation agency.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'KIMST (Korea Institute of Marine Science & Technology Promotion)','KR','Seoul','Seoul','https://www.kimst.re.kr','active','gov_grant_2026Q3','Marine science & fisheries R&D funding agency; highly relevant to MBG marine-bio domain.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'KETEP (Korea Institute of Energy Technology Evaluation and Planning)','KR','Seoul','Seoul','https://www.ketep.re.kr','active','gov_grant_2026Q3','Energy-technology R&D evaluation/funding agency; energy materials and decarbonization.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'NRF (National Research Foundation of Korea)','KR','Daejeon','Daejeon','https://www.nrf.go.kr','active','gov_grant_2026Q3','National basic/applied research funding foundation across science and engineering.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'KEITI (Korea Environmental Industry & Technology Institute)','KR','Seoul','Seoul','https://www.keiti.re.kr','active','gov_grant_2026Q3','Environmental industry R&D and ecolabel agency; covers paper products, coatings, materials.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (7::smallint,1::smallint,'TIPS (Tech Incubator Program for Startups)','KR','Seoul','Seoul','https://www.jointips.or.kr','active','gov_grant_2026Q3','Government startup R&D matching program (via KISED/MSS) for deep-tech ventures.','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
where not exists (select 1 from app.parties p where lower(p.party_name)=lower(v.party_name) and p.party_type_id=7 and p.deleted_at is null);

commit;

-- Verify: select country_code, count(*) from app.parties where source='gov_grant_2026Q3' and party_type_id=7 group by country_code order by country_code; -- US 5, EU 5, KR 7
-- List:   select party_name,country_code from app.parties where source='gov_grant_2026Q3' and party_type_id=7 order by country_code, party_name;
-- Rollback: delete from app.parties where source='gov_grant_2026Q3';
