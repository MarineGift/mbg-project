-- ============================================================
-- 20260620370016_government_grant_notes_enrich.sql
-- Enrich notes for the 17 government_grant programs (type=7, source gov_grant_2026Q3):
-- focus areas + funding mechanism + qualitative MBG fit level. Per-program UPDATEs.
-- Idempotent (overwrites notes with the enriched version). Deadlines are intentionally
-- NOT hard-coded (they recur annually); fit levels guide prioritization.
-- ============================================================

begin;

update app.parties set notes = 'Federal energy & materials R&D via national labs and program offices (EERE, FECM, Office of Science). Funded through FOAs, cooperative agreements and loan programs. MBG fit: MEDIUM - industrial materials, process decarbonization, CO2 utilization.', updated_at = now()
where party_name = 'U.S. Department of Energy (DOE)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'DOE agency for high-risk/high-impact energy tech; OPEN and focused FOAs, typically USD 0.5-10M awards. MBG fit: MEDIUM - novel materials and carbon/process technologies.', updated_at = now()
where party_name = 'ARPA-E' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Non-dilutive Phase I (~USD 275k) / Phase II (~USD 1M) grants for deep-tech startups. MBG fit: HIGH for a US entity - advanced materials, biotech, sustainability.', updated_at = now()
where party_name = 'NSF SBIR/STTR (America''s Seed Fund)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Standards, measurement and advanced-manufacturing programs (MEP, Manufacturing USA); grants & cooperative agreements. MBG fit: MEDIUM - materials characterization and standards.', updated_at = now()
where party_name = 'NIST' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Bio-based materials, biomass conversion and biorefinery FOAs. MBG fit: HIGH - marine/bio feedstocks and bio-based materials.', updated_at = now()
where party_name = 'DOE Bioenergy Technologies Office (BETO)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'EU flagship R&I programme (2021-2027, ~EUR 95.5bn); collaborative Pillar II calls incl. ''Digital, Industry & Space'' and ''Climate, Energy & Mobility''. MBG fit: HIGH - materials, bioeconomy, circular-economy consortia.', updated_at = now()
where party_name = 'Horizon Europe' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'European Innovation Council blended finance (grant up to EUR 2.5M + equity up to EUR 10M) for single deep-tech SMEs; cut-off calls. MBG fit: HIGH - deep-tech scale-up with an EU entity/partner.', updated_at = now()
where party_name = 'EIC Accelerator' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'EIC early-stage grants (~EUR 3-4M) for breakthrough/deep-science research incl. novel materials. MBG fit: MEDIUM-HIGH - early-stage science.', updated_at = now()
where party_name = 'EIC Pathfinder' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Large-scale industrial decarbonization & clean-tech demonstration grants (ETS-financed); large/small-scale calls. MBG fit: MEDIUM - industrial-scale low-carbon materials/process demos.', updated_at = now()
where party_name = 'EU Innovation Fund' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'EU environment & climate-action funding; circular economy, low-impact materials, environmental tech. MBG fit: MEDIUM - sustainable-materials / environmental angle.', updated_at = now()
where party_name = 'LIFE Programme' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'MOTIE core industrial-technology R&D (materials/components/equipment, manufacturing) planning & evaluation; annual national calls. MBG fit: HIGH - advanced materials / CaCO3 process as a Korean entity.', updated_at = now()
where party_name = 'KEIT (Korea Evaluation Institute of Industrial Technology)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'MOTIE industrial-tech innovation & international joint R&D (Eureka, bilateral CR&D with UK/EU/US). MBG fit: HIGH - materials + international collaboration funding.', updated_at = now()
where party_name = 'KIAT (Korea Institute for Advancement of Technology)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Marine science, fisheries and ocean-tech R&D funding under MOF. MBG fit: VERY HIGH - directly aligned with the MBG marine-bio domain.', updated_at = now()
where party_name = 'KIMST (Korea Institute of Marine Science & Technology Promotion)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Energy-technology R&D evaluation/funding under MOTIE; energy materials and decarbonization. MBG fit: MEDIUM - energy-materials angle.', updated_at = now()
where party_name = 'KETEP (Korea Institute of Energy Technology Evaluation and Planning)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'National basic/applied research foundation; broad science & engineering grants incl. university-industry. MBG fit: MEDIUM - upstream research partnerships.', updated_at = now()
where party_name = 'NRF (National Research Foundation of Korea)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Environmental-industry R&D and Korea Eco-label (covers paper products, paints/coatings, construction materials) under ME. MBG fit: HIGH - eco-label and green materials/paper.', updated_at = now()
where party_name = 'KEITI (Korea Environmental Industry & Technology Institute)' and party_type_id = 7 and deleted_at is null;

update app.parties set notes = 'Government-matched startup R&D program (via KISED/MSS); private-investor-led selection + gov R&D matching for deep-tech ventures. MBG fit: MEDIUM-HIGH - for a qualifying MBG startup track.', updated_at = now()
where party_name = 'TIPS (Tech Incubator Program for Startups)' and party_type_id = 7 and deleted_at is null;

commit;

-- Verify: select party_name, left(notes,40) from app.parties where source='gov_grant_2026Q3' and party_type_id=7 order by party_name;
