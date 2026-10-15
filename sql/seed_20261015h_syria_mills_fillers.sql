-- ============================================================
-- seed_20261015h_syria_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Syria update (reports 2026-10-15). LOW PRIORITY. Introduction ->
-- intro_ko / intro_en (only when empty), detail -> notes once with
-- 'SY check 2026-10-15', plant data -> Mill profile card.
--
-- SANCTIONS: US Syria sanctions program ended 2025-06-30 and the Caesar Act
-- was repealed 2025-12-18 - but Assad-era (PAARSS) and terrorism
-- designations remain. Every plant block says to screen against the OFAC
-- SDN list first.
--
-- 1) Fillers if missing: Al-Siraj (Adra, paper named), SCI, Phoenician
--    Stone, Al-Thiqa Bil-Amal. No paper PCC plant confirmed.
-- 2) Mills if missing + plant blocks, priority 1-7: Mediterranean Paper
--    Mills (tissue 40 t/day), Dinatex, Lanatex, Oriental Paper (tissue,
--    historical nameplates - may be one group), ARAPEPCO, Asian Paper
--    Industries (recycled packaging, Aleppo), United Paper Industry.
--    context, match only: Saffoury. Deir ez-Zor state mill not added
--    (damaged).
-- 3) Country market row SY in app.country_markets (upsert).
--    No FCC scenarios, no supply links.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'SY', v.region, v.city, v.website, 'active', 'syria_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Al-Siraj Calcium Carbonate (Syria)', '%Al-Siraj%', 'Rif Dimashq', 'Adra', null, '2007년 설립 아드라 산업단지의 Al-Siraj(Al-Seeraj) Calcium Carbonate. 독일 IVA 라인 미분화·표면처리 GCC(2~200 µm), 제지 포함 공급.', 'Al-Siraj (Al-Seeraj) Calcium Carbonate, Adra Industrial City chemical section, Rif Dimashq (founded 2007) - micronised and surface-treated GCC on German IVA lines, 2-200 um, paper among served industries, own test lab.', 'SY check 2026-10-15: site also describes PCC processes, but no PCC plant is confirmed. Second address Old Al-Kisweh Road, Al-Bardeh. factory@alseraj-caco3.com, +963 11 32265042. Screen against OFAC SDN first.'),
  ('SCI - Micronized Calcium Carbonate (Adra)', '%SCI%Adra%', 'Rif Dimashq', 'Adra', null, '아드라 산업단지 1구역의 SCI. 표면처리·비처리 미분화 탄산칼슘.', 'SCI, Adra Industrial City sector 1 - treated and untreated micronised calcium carbonate and white fillers.', 'SY check 2026-10-15: equipment, size distribution, paper customers and current status not public.'),
  ('Phoenician Stone Group', '%Phoenician Stone%', null, null, 'https://www.phoenicianstone.net', '2004년 설립 Phoenician Stone Group. 팔미라·라타키아 채석장, 탄산칼슘·실리카·카올린 채굴·가공·유통.', 'Phoenician Stone Group (founded 2004) - quarries around Palmyra and the Latakia mountains, mining and processing of calcium carbonate, silica and kaolin, coastal and inland plants.', 'SY check 2026-10-15: paper fine GCC, wet milling and PCC not confirmed - raw material or OEM option.'),
  ('Al-Thiqa Bil-Amal', '%Thiqa Bil-Amal%', null, null, null, '고순도(98.5%) 탄산칼슘·실리카 사업을 2022-02 발표한 Al-Thiqa Bil-Amal.', 'Al-Thiqa Bil-Amal LLC - announced calcium carbonate (98.5 pct target purity) and silica production in 2022-02 for paper, plastics, paint and building materials.', 'SY check 2026-10-15: 2026 output and paper sales unknown. Other Adra registrants (Syrian Carbonate, Fawaz Al-Istwani, Bilal Harash, Horsh Qassab, Absi and Haj Khadr, Amer Boghos) are directory-only - not added. No paper PCC plant in Syria.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%SY check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Al-Siraj Calcium Carbonate (Syria)', '%Al-Siraj%', 'Rif Dimashq', 'Adra', null, '2007년 설립 아드라 산업단지의 Al-Siraj(Al-Seeraj) Calcium Carbonate. 독일 IVA 라인 미분화·표면처리 GCC(2~200 µm), 제지 포함 공급.', 'Al-Siraj (Al-Seeraj) Calcium Carbonate, Adra Industrial City chemical section, Rif Dimashq (founded 2007) - micronised and surface-treated GCC on German IVA lines, 2-200 um, paper among served industries, own test lab.', 'SY check 2026-10-15: site also describes PCC processes, but no PCC plant is confirmed. Second address Old Al-Kisweh Road, Al-Bardeh. factory@alseraj-caco3.com, +963 11 32265042. Screen against OFAC SDN first.'),
  ('SCI - Micronized Calcium Carbonate (Adra)', '%SCI%Adra%', 'Rif Dimashq', 'Adra', null, '아드라 산업단지 1구역의 SCI. 표면처리·비처리 미분화 탄산칼슘.', 'SCI, Adra Industrial City sector 1 - treated and untreated micronised calcium carbonate and white fillers.', 'SY check 2026-10-15: equipment, size distribution, paper customers and current status not public.'),
  ('Phoenician Stone Group', '%Phoenician Stone%', null, null, 'https://www.phoenicianstone.net', '2004년 설립 Phoenician Stone Group. 팔미라·라타키아 채석장, 탄산칼슘·실리카·카올린 채굴·가공·유통.', 'Phoenician Stone Group (founded 2004) - quarries around Palmyra and the Latakia mountains, mining and processing of calcium carbonate, silica and kaolin, coastal and inland plants.', 'SY check 2026-10-15: paper fine GCC, wet milling and PCC not confirmed - raw material or OEM option.'),
  ('Al-Thiqa Bil-Amal', '%Thiqa Bil-Amal%', null, null, null, '고순도(98.5%) 탄산칼슘·실리카 사업을 2022-02 발표한 Al-Thiqa Bil-Amal.', 'Al-Thiqa Bil-Amal LLC - announced calcium carbonate (98.5 pct target purity) and silica production in 2022-02 for paper, plastics, paint and building materials.', 'SY check 2026-10-15: 2026 output and paper sales unknown. Other Adra registrants (Syrian Carbonate, Fawaz Al-Istwani, Bilal Harash, Horsh Qassab, Absi and Haj Khadr, Amer Boghos) are directory-only - not added. No paper PCC plant in Syria.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'syria_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Al-Siraj Calcium Carbonate (Syria)', 'GCC producer', 'Syrian GCC naming paper - partner priority 1', 'merchant', 'C', 'gcc'),
  ('SCI - Micronized Calcium Carbonate (Adra)', 'GCC producer', 'Syrian treated and untreated GCC', 'merchant', 'C', 'gcc'),
  ('Phoenician Stone Group', 'GCC producer', 'Syrian mineral miner and processor', 'merchant', 'C', 'gcc'),
  ('Al-Thiqa Bil-Amal', 'GCC producer', 'High-purity carbonate - raw material option', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'syria_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'SY', v.region, v.city, v.website, 'active', 'syria_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Mediterranean Paper%', '%MPM%Syria%', 'Mediterranean Paper Mills (Jableh)', 'Latakia', 'Jableh', null, '1989년 설립 라타키아 Jableh 의 Mediterranean Paper Mills(Jalloul 가문). Toscotec MODULO 크레센트 포머 티슈기(2011, 폭 2,250mm, 900 m/min), 40 t/일.', 'Mediterranean Paper Mills (Jalloul family, founded 1989), Jableh, Latakia - Toscotec MODULO crescent-former tissue machine started 2011-03 (2,250 mm, 900 m/min), 40 t/day, toilet, facial and napkins, virgin or recycled furnish.', 'SY check 2026-10-15: current running status to confirm. Directory phone +963 41 814537.'),
  ('%Dinatex%', '%Dinatex Paper%', 'Dinatex Paper Manufacturing (Damascus)', 'Rif Dimashq', null, null, '다마스쿠스의 Dinatex Paper Manufacturing. OverMade PM3 티슈기(2007, 1,800 m/min, 폭 2.72m), 과거 명목 연 2.8만 t.', 'Dinatex Paper Manufacturing, Damascus - OverMade PM3 tissue machine (2007, 1,800 m/min, 2.72 m), 28,000 t/yr nameplate (historical listing).', 'SY check 2026-10-15: possibly linked to Lanatex and Oriental Paper (PM1-PM3 numbering) - check ownership before counting separately. +963 11 5850870 (directory).'),
  ('%Lanatex%', '%Lanatex%', 'Lanatex (Damascus)', 'Rif Dimashq', null, null, '다마스쿠스의 Lanatex. OverMade PM2 티슈기(2000, 1,100 m/min), 과거 명목 연 1.7만 t.', 'Lanatex, Damascus - OverMade PM2 tissue machine (2000, 1,100 m/min, 2.72 m), 17,000 t/yr nameplate (historical listing).', null),
  ('%Oriental Paper%', '%Oriental Paper Manufacturing%', 'Oriental Paper Manufacturing (Damascus)', 'Rif Dimashq', null, null, '다마스쿠스 교외의 Oriental Paper Manufacturing. Recard PM1 티슈기(1995, 600 m/min), 과거 명목 연 9,000 t, 천연 셀룰로오스 화장지·미용티슈.', 'Oriental Paper Manufacturing, Damascus outskirts - Recard PM1 tissue machine (1995, 600 m/min, 2.7 m), 9,000 t/yr nameplate, virgin-cellulose toilet and facial tissue.', 'SY check 2026-10-15: +963 11 6470000 (directory).'),
  ('%ARAPEPCO%', '%Arab Company for Paper%', 'ARAPEPCO - Arab Company for Paper Products (Aleppo)', 'Aleppo', 'Khan Al-Asal', 'https://www.arapepco.com', '1994년 설립 알레포 Khan Al-Asal 의 ARAPEPCO(Badanjki 가문). 100% 재생섬유 플루팅·테스트라이너·그레이보드(90~330 gsm), Toscotec PM1 개조(2020).', 'Arab Company for Paper Products (ARAPEPCO, Badanjki family, founded 1994), Khan Al-Asal, Aleppo - 24,000 m2, 160 staff, 100 pct recycled fluting, testliner, coloured wrapping and grey board 90-330 gsm, PM1 rebuilt by Toscotec 2020 (2,850 mm, 800 m/min).', 'SY check 2026-10-15: info@arapepco.com, +963 21 5788225. Aleppo mills said in 2026-09 they cover about 70 pct of national demand.'),
  ('%Asian Paper Industries%', '%Asian Paper%Aleppo%', 'Asian Paper Industries (Aleppo)', 'Aleppo', 'Sheikh Najjar', null, '알레포 Sheikh Najjar 산업도시의 Asian Paper Industries. 폐지 갈색 포장용지, 2020-07 가동, 150 t/일·연 3.9만 t 보도.', 'Asian Paper Industries, Sheikh Najjar Industrial City, Aleppo - recycled brown packaging paper, started 2020-07, 150 t/day and 39,000 t/yr reported.', null),
  ('%United Paper Industry%', '%UniPaper%', 'United Paper Industry (Syrian-Jordanian Free Zone)', null, null, 'https://www.unipaper.co', '시리아·요르단 자유무역지대의 United Paper Industry. 플루팅지·골판지 시트·석고보드 라이너.', 'United Paper Industry, Syrian-Jordanian Free Zone - fluting paper, corrugated sheets and plasterboard liner.', 'SY check 2026-10-15: info@unipaper.co, +963 933 258878.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SY check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mediterranean Paper%', '%MPM%Syria%', '%Mediterranean%', '1989년 설립 라타키아 Jableh 의 Mediterranean Paper Mills(Jalloul 가문). Toscotec MODULO 크레센트 포머 티슈기(2011, 폭 2,250mm, 900 m/min), 40 t/일.', 'Mediterranean Paper Mills (Jalloul family, founded 1989), Jableh, Latakia - Toscotec MODULO crescent-former tissue machine started 2011-03 (2,250 mm, 900 m/min), 40 t/day, toilet, facial and napkins, virgin or recycled furnish.', 'SY check 2026-10-15: current running status to confirm. Directory phone +963 41 814537.'),
  ('%Dinatex%', '%Dinatex Paper%', '%Dinatex%', '다마스쿠스의 Dinatex Paper Manufacturing. OverMade PM3 티슈기(2007, 1,800 m/min, 폭 2.72m), 과거 명목 연 2.8만 t.', 'Dinatex Paper Manufacturing, Damascus - OverMade PM3 tissue machine (2007, 1,800 m/min, 2.72 m), 28,000 t/yr nameplate (historical listing).', 'SY check 2026-10-15: possibly linked to Lanatex and Oriental Paper (PM1-PM3 numbering) - check ownership before counting separately. +963 11 5850870 (directory).'),
  ('%Lanatex%', '%Lanatex%', '%Lanatex%', '다마스쿠스의 Lanatex. OverMade PM2 티슈기(2000, 1,100 m/min), 과거 명목 연 1.7만 t.', 'Lanatex, Damascus - OverMade PM2 tissue machine (2000, 1,100 m/min, 2.72 m), 17,000 t/yr nameplate (historical listing).', null),
  ('%Oriental Paper%', '%Oriental Paper Manufacturing%', '%Oriental%', '다마스쿠스 교외의 Oriental Paper Manufacturing. Recard PM1 티슈기(1995, 600 m/min), 과거 명목 연 9,000 t, 천연 셀룰로오스 화장지·미용티슈.', 'Oriental Paper Manufacturing, Damascus outskirts - Recard PM1 tissue machine (1995, 600 m/min, 2.7 m), 9,000 t/yr nameplate, virgin-cellulose toilet and facial tissue.', 'SY check 2026-10-15: +963 11 6470000 (directory).'),
  ('%ARAPEPCO%', '%Arab Company for Paper%', '%ARAPEPCO%', '1994년 설립 알레포 Khan Al-Asal 의 ARAPEPCO(Badanjki 가문). 100% 재생섬유 플루팅·테스트라이너·그레이보드(90~330 gsm), Toscotec PM1 개조(2020).', 'Arab Company for Paper Products (ARAPEPCO, Badanjki family, founded 1994), Khan Al-Asal, Aleppo - 24,000 m2, 160 staff, 100 pct recycled fluting, testliner, coloured wrapping and grey board 90-330 gsm, PM1 rebuilt by Toscotec 2020 (2,850 mm, 800 m/min).', 'SY check 2026-10-15: info@arapepco.com, +963 21 5788225. Aleppo mills said in 2026-09 they cover about 70 pct of national demand.'),
  ('%Asian Paper Industries%', '%Asian Paper%Aleppo%', '%Asian Paper%', '알레포 Sheikh Najjar 산업도시의 Asian Paper Industries. 폐지 갈색 포장용지, 2020-07 가동, 150 t/일·연 3.9만 t 보도.', 'Asian Paper Industries, Sheikh Najjar Industrial City, Aleppo - recycled brown packaging paper, started 2020-07, 150 t/day and 39,000 t/yr reported.', null),
  ('%United Paper Industry%', '%UniPaper%', '%United Paper%', '시리아·요르단 자유무역지대의 United Paper Industry. 플루팅지·골판지 시트·석고보드 라이너.', 'United Paper Industry, Syrian-Jordanian Free Zone - fluting paper, corrugated sheets and plasterboard liner.', 'SY check 2026-10-15: info@unipaper.co, +963 933 258878.'),
  ('%Saffoury%', '%Saffoury Paper%', '%Saffoury%', '다마스쿠스 교외 Housh Sahba 의 Saffoury Paper Mill Industries. 티슈·화장지·위생용품.', 'Saffoury Paper Mill Industries, Housh Sahba, Rif Dimashq - tissue, toilet and kitchen paper, hygiene products.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'syria_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mediterranean Paper%', '%MPM%Syria%', '%Mediterranean%'),
  ('%Dinatex%', '%Dinatex Paper%', '%Dinatex%'),
  ('%Lanatex%', '%Lanatex%', '%Lanatex%'),
  ('%Oriental Paper%', '%Oriental Paper Manufacturing%', '%Oriental%'),
  ('%ARAPEPCO%', '%Arab Company for Paper%', '%ARAPEPCO%'),
  ('%Asian Paper Industries%', '%Asian Paper%Aleppo%', '%Asian Paper%'),
  ('%United Paper Industry%', '%UniPaper%', '%United Paper%'),
  ('%Saffoury%', '%Saffoury Paper%', '%Saffoury%')
  ) as v(name_like, alt_like, owner_like)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mediterranean Paper%', '%MPM%Syria%', '%Mediterranean%',
   $pj${"owner": "Mediterranean Paper Mills", "priority": 1, "products": "Toilet tissue, facial, napkins", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "40 t/day x 330 (calculated, 2011)", "value_t": 13200}], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply. Then confirm the machine runs - tissue trial at 3-5 pct FCC.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Dinatex%', '%Dinatex Paper%', '%Dinatex%',
   $pj${"owner": "Dinatex Paper Manufacturing", "priority": 2, "products": "Tissue base paper", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "PM3 nameplate (historical)", "value_t": 28000}], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply. Then confirm PM3 runs.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lanatex%', '%Lanatex%', '%Lanatex%',
   $pj${"owner": "Lanatex", "priority": 3, "products": "Tissue base paper", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "PM2 nameplate (historical)", "value_t": 17000}], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply. Then check the link to Dinatex and Oriental Paper.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Oriental Paper%', '%Oriental Paper Manufacturing%', '%Oriental%',
   $pj${"owner": "Oriental Paper Manufacturing", "priority": 4, "products": "Toilet and facial tissue", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "PM1 nameplate (historical)", "value_t": 9000}], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%ARAPEPCO%', '%Arab Company for Paper%', '%ARAPEPCO%',
   $pj${"owner": "ARAPEPCO", "priority": 5, "products": "Fluting, testliner, grey board, wrapping paper", "grades": ["Fluting", "Testliner", "Grey board"], "machines": 1, "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply. Packaging - strength and fibre-saving trial only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Asian Paper Industries%', '%Asian Paper%Aleppo%', '%Asian Paper%',
   $pj${"owner": "Asian Paper Industries", "priority": 6, "products": "Brown packaging paper", "grades": ["Packaging"], "capacity_split": [{"label": "Reported", "value_t": 39000}], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%United Paper Industry%', '%UniPaper%', '%United Paper%',
   $pj${"owner": "United Paper Industry", "priority": 7, "products": "Fluting, plasterboard liner", "grades": ["Fluting", "Plasterboard liner"], "approach": "Screen each party against the OFAC SDN list first - the Syria program ended 2025-06-30 and the Caesar Act was repealed 2025-12-18, but Assad-era and terrorism designations still apply. Plasterboard liner needs its own trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Saffoury%', '%Saffoury Paper%', '%Saffoury%',
   $pj${"owner": "Saffoury", "products": "Tissue and hygiene products", "approach": "Confirm own paper machine.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 4b) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SY', 'Syria', 'low',
   $cm$Recovering recycled packaging in Aleppo, tissue mills with old nameplates - screen OFAC SDN$cm$,
   $cm$US Syria sanctions ended in 2025 (program closed 2025-06-30, Caesar Act repealed 2025-12-18) but SDN designations remain. Aleppo recycled-packaging mills report covering about 70 pct of demand. Tissue mills (Mediterranean, Dinatex, Lanatex, Oriental) are the FCC fit. Local GCC grinders cluster in Adra.$cm$,
   $cm${"fillers": "Al-Siraj (Adra, IVA lines, paper named), SCI, Phoenician Stone, Al-Thiqa Bil-Amal, plus directory-only Adra grinders. No paper PCC plant confirmed.", "mills": "Tissue: Mediterranean Paper Mills (Jableh), Dinatex, Lanatex, Oriental Paper. Recycled packaging in Aleppo: ARAPEPCO, Asian Paper Industries. United Paper Industry (Syrian-Jordanian Free Zone).", "strategy": "Tissue mills are the direct FCC fit - confirm which machines run. Al-Siraj as local GCC partner. Screen every party against OFAC SDN first.", "risks": "Remaining SDN designations, power and fuel supply, waste-paper shortage, old nameplate data.", "next_steps": ["Confirm running machines at the four tissue mills", "Check ownership links between Dinatex, Lanatex and Oriental Paper"], "key_numbers": [{"label": "Aleppo mills share of demand", "value": "about 70 pct (industry, 2026-09)"}, {"label": "Tissue nameplates (historical)", "value": "about 67 kt across four mills"}], "files": ["seed_20261015h_syria_mills_fillers"]}$cm$::jsonb, '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, checked_at = excluded.checked_at, updated_at = now();

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Mediterranean Paper%', '%MPM%Syria%', '%Mediterranean%'),
  ('%Dinatex%', '%Dinatex Paper%', '%Dinatex%'),
  ('%Lanatex%', '%Lanatex%', '%Lanatex%'),
  ('%Oriental Paper%', '%Oriental Paper Manufacturing%', '%Oriental%'),
  ('%ARAPEPCO%', '%Arab Company for Paper%', '%ARAPEPCO%'),
  ('%Asian Paper Industries%', '%Asian Paper%Aleppo%', '%Asian Paper%'),
  ('%United Paper Industry%', '%UniPaper%', '%United Paper%'),
  ('%Saffoury%', '%Saffoury Paper%', '%Saffoury%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'syria_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'syria_update_20261015' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Al-Siraj%' or p.party_name ilike '%SCI%Adra%' or p.party_name ilike '%Phoenician Stone%' or p.party_name ilike '%Thiqa Bil-Amal%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'syria_update_20261015'
order by 1, 4, 2;
