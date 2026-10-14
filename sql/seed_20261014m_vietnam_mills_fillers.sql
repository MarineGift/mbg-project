-- ============================================================
-- seed_20261014m_vietnam_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Vietnam update (reports "Vietnam PCC/GCC producers" + "Vietnam paper
-- companies", 2026-10). Already in URM: VSV Group, Global Filler, VINAPACO,
-- Dong Hai Ben Tre.
--
-- 1) Filler rows if missing + profiles: VMPC, YBM, EAMC, Tan Ky, ACBM,
--    Mien Trung Mineral, Nimex, Phu Thanh Dat. Eco Green skipped
--    (plastics). Contacts in notes only.
-- 2) Mill rows if missing: An Hoa, VINAPACO Bai Bang, Saigon Paper,
--    New Toyo Pulppy, Vina Kraft, Cheng Loong, Lee and Man Vietnam,
--    Nine Dragons Vietnam.
-- 3) Plant blocks, Vietnam priority 1-4:
--      1 An Hoa (copy, 140 kt)  2 VINAPACO Bai Bang  3 Saigon Paper (tissue)
--      4 New Toyo Pulppy (tissue)
--    context: Vina Kraft, Cheng Loong, Lee and Man, Nine Dragons, Dohaco.
--    FCC scenario only for An Hoa. Bai Bang is mid-conversion, so no
--    scenario. No supply links - no mill-filler pair publicly confirmed.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'VN'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'VN', v.region, v.city, v.website, 'active', 'vietnam_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('VMPC Joint Stock Company', '%VMPC%', 'Yen Bai', 'Yen Bai', 'https://www.vmpc.com.vn', 'GCC maker in Yen Bai industrial park, about 300,000 t/yr (company profile). Hosokawa Alpine grinding and classifying, Mong Son white limestone, D97 about 3-30 um. Paper filler and coating listed, also offers GCC as PCC replacement. Contact per report: Jenny@vmpc.com.vn, +84 912 817 807.'),
  ('YBM Joint Stock Company', '%YBM%', 'Yen Bai', 'Yen Bai', 'https://www.ybm.com.vn', 'Yen Bai Industry Mineral JSC - five plants, 25 lines, over 1 Mt/yr stated (plant list adds to about 990,000 t: 150 + 220 + 200 + 220 + 200 kt). Ultrafine and surface-treated GCC, ISO/IEC 17025 lab, wastewater treatment. Mainly dry grinding - wet FCC equipment to confirm.'),
  ('East Asia Mineral JSC (EAMC)', '%East Asia Mineral%', 'Nghe An', 'Quy Hop', 'https://www.eamcvina.com', 'Two white marble quarries and two plants in Nghe An - Factory 1 Nghia Xuan commune (Quy Hop), Factory 2 Nghia My industrial park (Thai Hoa). Over 200,000 t/yr uncoated and stearic-coated GCC for paper, paint, plastics, rubber, exported in Asia including Korea.'),
  ('Tan Ky Mineral Processing JSC', '%Tan Ky%', 'Nghe An', 'Nam Cam', 'https://www.tankymineral.com.vn', 'Nam Cam industrial park, Nghe An - own quarry, Hosokawa Alpine grinding, GCC, coated GCC and a PCC product page. Paper uses named include printing paper and paper towel. Own PCC synthesis (lime burning, slaking, carbonation) not confirmed. Contact per report: salesmanager@tankymineral.com.vn, +84 868 989 350.'),
  ('ACBM Vietnam JSC', '%ACBM%', 'Nghe An', null, 'https://www.acbminerals.vn', 'Founded 2011, Nghe An mineral base, German processing equipment. Lists GCC and PCC for paper, paint, plastics, rubber. Own PCC plant, capacity and paper customers not confirmed.'),
  ('Mien Trung Mineral JSC (MTM)', '%Mien Trung Mineral%', 'Nghe An', null, null, 'Nghe An GCC maker, Hosokawa Alpine grinding line, paper-grade GCC, about 70,000 t/yr.'),
  ('Nimex Joint Stock Company', '%Nimex%', 'Yen Bai', 'Yen Bai', null, 'Yen Bai GCC maker and mineral trader, also handles PCC. Capacity not published.'),
  ('Phu Thanh Dat', '%Phu Thanh Dat%', null, null, null, 'States PCC manufacture and supply, published spec CaCO3 over 98 pct, brightness over 95 pct, D50 under 3.8 um. Own synthesis plant and paper fit not confirmed.')
) as v(party_name, guard_like, region, city, website, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('VMPC Joint Stock Company', 'GCC producer', 'Northern Vietnam paper-grade GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('YBM Joint Stock Company', 'GCC producer', 'Large Vietnam GCC base - regional FCC hub candidate', 'merchant', 'B', 'gcc'),
  ('East Asia Mineral JSC (EAMC)', 'GCC producer', 'Nghe An GCC, two plants - pilot then scale', 'merchant', 'B', 'gcc'),
  ('Tan Ky Mineral Processing JSC', 'GCC producer', 'Nghe An GCC with PCC products', 'merchant', 'C', 'gcc'),
  ('ACBM Vietnam JSC', 'GCC producer', 'GCC and PCC products - PCC plant to confirm', 'merchant', 'C', 'gcc'),
  ('Mien Trung Mineral JSC (MTM)', 'GCC producer', 'Nghe An paper-grade GCC', 'merchant', 'C', 'gcc'),
  ('Nimex Joint Stock Company', 'GCC producer', 'Yen Bai GCC', 'merchant', 'C', 'gcc'),
  ('Phu Thanh Dat', 'PCC producer', 'Vietnam PCC supplier - plant to confirm', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'vietnam_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'VN'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'VN', v.region, v.city, v.website, 'active', 'vietnam_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%An Hoa%', '%Tuyen Quang%', 'An Hoa Paper - Tuyen Quang Mill (Tuyen Quang)', 'Tuyen Quang', 'Tuyen Quang', 'https://www.anhoapaper.vn', 'An Hoa Paper Corporation, founded 2002, integrated BHKP pulp and uncoated freesheet mill on about 223 ha in Tuyen Quang. Contact listed in the 2026-10 report: marketing@anhoapaper.vn, +84 2076 257 184.'),
  ('%Bai Bang%', '%Vinapaco%', 'VINAPACO - Bai Bang Paper Mill (Phu Tho)', 'Phu Tho', 'Phu Ninh', 'https://www.vinapaco.com.vn', 'Vietnam Paper Corporation (VINAPACO) Bai Bang integrated pulp and printing paper mill, Phu Tho.'),
  ('%Saigon Paper%', '%Sai Gon Paper%', 'Saigon Paper - My Xuan Mills (Phu My)', 'Ba Ria - Vung Tau', 'Phu My', 'https://www.saigonpaper.com', 'Saigon Paper Corporation, founded 1997, Sojitz group since 2018 - My Xuan 1 and 2 mills, tissue and industrial paper. contact@saigonpaper.com per report.'),
  ('%Pulppy%', '%New Toyo%', 'New Toyo Pulppy Vietnam - VSIP (Binh Duong)', 'Binh Duong', 'Thuan An', 'https://www.pulppytissue.com', 'New Toyo Pulppy (Vietnam), founded 1998, tissue plant in Vietnam-Singapore Industrial Park, about 40,000 m2 - Pulppy, May, AnAn brands and jumbo rolls.'),
  ('%Vina Kraft%', '%VinaKraft%', 'Vina Kraft Paper (Binh Duong)', 'Binh Duong', null, 'https://www.scgpackaging.com', 'SCGP and Rengo joint-venture packaging paper maker in Binh Duong.'),
  ('%Cheng Loong%', '%Cheng Loong%', 'Cheng Loong Vietnam - Binh Duong Mill (Binh Duong)', 'Binh Duong', null, 'https://www.clc.com.tw', 'Taiwan Cheng Loong recycled packaging paper mill in Binh Duong.'),
  ('%Lee & Man%', '%Lee and Man%', 'Lee & Man Paper - Vietnam Mill (Hau Giang)', 'Hau Giang', null, 'https://www.leemanpaper.com', 'Lee and Man Paper Manufacturing Vietnamese packaging paper mill, Hau Giang.'),
  ('%Nine Dragons%', '%ND Paper%', 'Nine Dragons Paper - Vietnam Mill (Binh Duong)', 'Binh Duong', null, 'https://www.ndpaper.com', 'Nine Dragons Vietnamese kraftliner and testliner mill, My Phuoc industrial park, Binh Duong.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%An Hoa%', '%Tuyen Quang%', '%An Hoa%'),
  ('%Bai Bang%', '%Vinapaco%', '%Vinapaco%'),
  ('%Saigon Paper%', '%Sai Gon Paper%', '%Saigon%'),
  ('%Pulppy%', '%New Toyo%', '%Pulppy%'),
  ('%Vina Kraft%', '%VinaKraft%', '%Vina Kraft%'),
  ('%Cheng Loong%', '%Cheng Loong%', '%Cheng Loong%'),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%'),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%'),
  ('%Dong Hai%', '%Dohaco%', '%Dong Hai%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant,
         (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%An Hoa%', '%Tuyen Quang%', '%An Hoa%',
   $pj${"owner": "An Hoa Paper Corporation", "priority": 1, "products": "Copy, printing and writing papers (ISO 85 and 95 brightness), bleached hardwood kraft pulp", "grades": ["Copy paper", "Writing and printing"], "capacity": {"value": 140000, "unit": "metric_t", "year": "Company site - paper, plus 130,000 t/yr pulp", "source": "anhoapaper.vn"}, "filler": [{"supplier": "Not confirmed", "type": "-", "status": "Unknown", "basis": "No public PCC / GCC supplier - candidates VMPC, YBM (northern GCC)"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Pulp saving in copy paper with opacity and brightness held - plus freeing own pulp", "approach": "First Vietnam customer. Mill trial first, find the current filler supplier, then bring that supplier in as FCC producer. ECF pulp line, Allimand / Andritz / ABB machinery.", "to_collect": ["Current PCC / GCC supplier and contract term", "Filler loading per grade and fibre furnish", "Internal pulp cost versus market pulp", "Quality gates - opacity, brightness, tensile, stiffness, retention", "Who approves a machine trial"], "sources": [{"label": "anhoapaper.vn"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Bai Bang%', '%Vinapaco%', '%Vinapaco%',
   $pj${"owner": "Vietnam Paper Corporation (VINAPACO)", "priority": 2, "products": "Printing and writing, copy paper, pulp", "grades": ["Writing and printing", "Copy paper"], "capacity_split": [{"label": "Existing printing and writing line", "value_t": 100000}, {"label": "After planned conversion - part moves to packaging", "value_t": 180000}], "pitch": "High-quality FCC for the printing and writing line that stays", "approach": "Confirm which line stays on printing paper after the 2026 conversion before sizing. State group - a win can spread to other VINAPACO mills.", "recent": [{"date": "2026-06", "text": "Tender for a line rebuild - capacity 100,000 to 180,000 t/yr, part shifting to industrial packaging"}], "to_collect": ["Current PCC / GCC supplier and contract term", "Filler loading per grade and fibre furnish", "Internal pulp cost versus market pulp", "Quality gates - opacity, brightness, tensile, stiffness, retention", "Who approves a machine trial"], "sources": [{"label": "VINAPACO tender notice 2026-06 (DauThau.info)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Saigon Paper%', '%Sai Gon Paper%', '%Saigon%',
   $pj${"owner": "Saigon Paper Corporation (Sojitz group)", "priority": 3, "products": "Toilet and facial tissue, napkins, towels, industrial paper", "grades": ["Tissue", "Industrial paper"], "capacity_split": [{"label": "Tissue (directory figure)", "value_t": 43680}, {"label": "Industrial paper (directory figure)", "value_t": 224640}], "pitch": "Tissue FCC using MBG low-grammage tissue trial data", "approach": "Tissue track first. Industrial paper only for white top or smoothness grades - not brown medium.", "to_collect": ["Is tissue base paper made on own machines (not bought as jumbo rolls)", "Current filler use, if any, and supplier", "Furnish - virgin versus recycled fibre", "Strength, softness, absorbency and dust limits for a trial", "Who approves a machine trial"], "sources": [{"label": "saigonpaper.com, manufacturer directory"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Pulppy%', '%New Toyo%', '%Pulppy%',
   $pj${"owner": "New Toyo Pulppy (Vietnam)", "priority": 4, "products": "Toilet and facial tissue, napkins, jumbo rolls (also export to Korea, Japan, Malaysia)", "grades": ["Tissue", "Jumbo roll"], "pitch": "Low-dose FCC in 13-18 gsm toilet and facial base paper", "approach": "Confirm its own paper machine first - FCC is used in base-paper making, not converting.", "to_collect": ["Is tissue base paper made on own machines (not bought as jumbo rolls)", "Current filler use, if any, and supplier", "Furnish - virgin versus recycled fibre", "Strength, softness, absorbency and dust limits for a trial", "Who approves a machine trial"], "sources": [{"label": "pulppytissue.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Vina Kraft%', '%VinaKraft%', '%Vina Kraft%',
   $pj${"owner": "SCG Packaging and Rengo (JV)", "products": "Kraftliner, testliner, corrugating medium", "capacity_split": [{"label": "Capacity 2025 (500,000 in 2022)", "value_t": 870000}], "approach": "Packaging - only high-strength liner surface or white liner is worth a test.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs - compression, burst, ply bond", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Cheng Loong%', '%Cheng Loong%', '%Cheng Loong%',
   $pj${"owner": "Cheng Loong Corporation", "products": "Recycled-fibre packaging base paper", "capacity_split": [{"label": "About, after phase 3 started 2026", "value_t": 1000000}], "approach": "Large scale proof site later - prove fibre replacement with strength held first.", "recent": [{"date": "2026", "text": "Phase 3 expansion line in commercial operation"}], "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs - compression, burst, ply bond", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%',
   $pj${"owner": "Lee and Man Paper Manufacturing", "products": "Industrial packaging paper", "capacity_split": [{"label": "Vietnam, 2025 annual report", "value_t": 550000}], "approach": "Joint development of high-strength testliner - not an early FCC customer.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs - compression, burst, ply bond", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%',
   $pj${"owner": "Nine Dragons Paper (Holdings)", "products": "Kraftlinerboard, testlinerboard", "machines": 2, "capacity_split": [{"label": "Paper", "value_t": 430000}, {"label": "Wood fibre", "value_t": 100000}], "approach": "Check high-grade liner mix and fibre furnish before any test.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs - compression, burst, ply bond", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Dong Hai%', '%Dohaco%', '%Dong Hai%',
   $pj${"owner": "Dong Hai Ben Tre (Dohaco)", "products": "Kraftliner and packaging paper", "capacity_split": [{"label": "Giao Long mills, combined", "value_t": 300000}, {"label": "Giao Long 3 planned (2027, broker estimate 340-390 kt)", "value_t": 340000}], "approach": "A new machine is the chance to propose a material trial - strength-critical kraftliner needs full validation.", "recent": [{"date": "2027", "text": "Giao Long 3 start-up expected (broker estimates)"}], "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs - compression, burst, ply bond", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%An Hoa%', '%Tuyen Quang%', '%An Hoa%'),
  ('%Bai Bang%', '%Vinapaco%', '%Vinapaco%'),
  ('%Saigon Paper%', '%Sai Gon Paper%', '%Saigon%'),
  ('%Pulppy%', '%New Toyo%', '%Pulppy%'),
  ('%Vina Kraft%', '%VinaKraft%', '%Vina Kraft%'),
  ('%Cheng Loong%', '%Cheng Loong%', '%Cheng Loong%'),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%'),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%'),
  ('%Dong Hai%', '%Dohaco%', '%Dong Hai%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'vietnam_update_20261014' then 'added now' when m.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'vietnam_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%VMPC%' or p.party_name ilike '%YBM%' or p.party_name ilike '%East Asia Mineral%' or p.party_name ilike '%Tan Ky%' or p.party_name ilike '%ACBM%' or p.party_name ilike '%Mien Trung Mineral%' or p.party_name ilike '%Nimex%' or p.party_name ilike '%Phu Thanh Dat%')
order by 1, 4, 2;
