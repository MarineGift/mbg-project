-- ============================================================
-- seed_20261015f_philippines_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Philippines update (reports 2026-10). Introduction -> intro_ko /
-- intro_en (only when empty), detail -> notes once with
-- 'PH check 2026-10-15', plant data -> Mill profile card. Already in URM:
-- TIPCO.
--
-- 1) Fillers if missing: Omya Mineral Philippines (GCC), Philstone,
--    Kingstone, South Pacific Chemical (light PCC listed), Busilak (paper
--    LPCC named). PCC synthesis not confirmed anywhere.
-- 2) Mills if missing + plant blocks, priority 1-5: Bataan 2020, Quanta
--    Paper (tissue, 5 PMs), TIPCO, Fifth Discipline (400 t/day), UPPC
--    (SCGP, 450 kt). context, match only: Multi Ply.
--    BOI also lists printing mills Alliance, Hansson, Rural, Vanson, Fedco -
--    no detail in the report, not added yet.
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
       v.party_name, 'PH', v.region, v.city, v.website, 'active', 'philippines_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya Mineral Philippines', '%Omya%Philippines%', 'Metro Manila', 'Makati', 'https://www.omya.com', 'Omya 의 필리핀 사업(2010년 설립). 코팅·비코팅 GCC 현지 제조, 영업은 Omya Chemical Merchants(마카티 BDO Plaza).', 'Omya Mineral Philippines (founded 2010) - coated and uncoated GCC made in the Philippines (power contract renewal 2017), sales via Omya Chemical Merchants, 17F BDO Plaza, Paseo de Roxas, Makati, +63 2 8813 0301.', 'PH check 2026-10-15: plant address, wet-grinding line and paper customers to confirm. Royalty licensee at Omya HQ level. Alad Mining (Romblon marble for Japanese paper) and HT Mining (Atimonan lime) not added. Brenntag and Dalkem are distributors.'),
  ('Philstone Industrial & Manufacturing', '%Philstone%', 'Metro Manila', 'Quezon City', 'https://www.philstone.com.ph', '1988년 불라칸에서 시작한 Philstone. 케손시티 Novaliches 공장, 비코팅·코팅 탄산칼슘(PHILCARB), ISO 9001.', 'Philstone Industrial and Manufacturing (since 1988), Manchester Ave, Sauyo, Novaliches, Quezon City - uncoated and coated calcium carbonate (PS and PC grades, PHILCARB), ISO 9001, listed by BOI as a domestic filler maker.', 'PH check 2026-10-15: mainly dry powder - wet slurry for paper to confirm. philstone@philstone.com.ph.'),
  ('Kingstone Mineral Industries', '%Kingstone%', 'Bulacan', 'Santa Maria', 'https://www.kingstonemineral.com.ph', '1988년 설립 불라칸 Santa Maria 의 Kingstone Mineral. 분쇄 탄산칼슘(100~400 mesh), 제지 충전·코팅 용도 명시.', 'Kingstone Mineral Industries (founded 1988), 442 Guyong, Santa Maria, Bulacan - ground calcium carbonate 100-400 mesh, paper filling and coating named.', 'PH check 2026-10-15: 400 mesh is not fine paper GCC - D50 / D97, brightness, slurry to confirm. kingstonemineral1988@gmail.com.'),
  ('South Pacific Chemical Industries', '%South Pacific Chemical%', 'Rizal', 'Cainta', null, '1962년 설립 리잘 Cainta 공장의 South Pacific Chemical. 중질·초미분 탄산칼슘과 경질 PCC(2,000~4,000 mesh)·탈크·클레이.', 'South Pacific Chemical Industries (founded 1962, Cainta plant since 1969) - heavy and superfine calcium carbonate, light PCC (2,000-4,000 mesh), talc, clay, silica.', 'PH check 2026-10-15: whether it synthesises PCC (carbonation) or trades it is not confirmed. spacind@gmail.com.'),
  ('Busilak Philippines', '%Busilak%', 'Bulacan', 'Pulilan', 'https://www.busilakphil.com', '불라칸 Pulilan 의 Busilak Philippines. 경질 PCC(LPCC)를 제지 충전·코팅용으로 소개, 실리카 등.', 'Busilak Philippines, 140 Sta. Peregrina, Pulilan, Bulacan - light precipitated calcium carbonate for paper filling and coating, silica and other minerals.', 'PH check 2026-10-15: own carbonation reactors and paper PCC output not confirmed. sales@busilakphil.com.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%PH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Omya Mineral Philippines', '%Omya%Philippines%', 'Metro Manila', 'Makati', 'https://www.omya.com', 'Omya 의 필리핀 사업(2010년 설립). 코팅·비코팅 GCC 현지 제조, 영업은 Omya Chemical Merchants(마카티 BDO Plaza).', 'Omya Mineral Philippines (founded 2010) - coated and uncoated GCC made in the Philippines (power contract renewal 2017), sales via Omya Chemical Merchants, 17F BDO Plaza, Paseo de Roxas, Makati, +63 2 8813 0301.', 'PH check 2026-10-15: plant address, wet-grinding line and paper customers to confirm. Royalty licensee at Omya HQ level. Alad Mining (Romblon marble for Japanese paper) and HT Mining (Atimonan lime) not added. Brenntag and Dalkem are distributors.'),
  ('Philstone Industrial & Manufacturing', '%Philstone%', 'Metro Manila', 'Quezon City', 'https://www.philstone.com.ph', '1988년 불라칸에서 시작한 Philstone. 케손시티 Novaliches 공장, 비코팅·코팅 탄산칼슘(PHILCARB), ISO 9001.', 'Philstone Industrial and Manufacturing (since 1988), Manchester Ave, Sauyo, Novaliches, Quezon City - uncoated and coated calcium carbonate (PS and PC grades, PHILCARB), ISO 9001, listed by BOI as a domestic filler maker.', 'PH check 2026-10-15: mainly dry powder - wet slurry for paper to confirm. philstone@philstone.com.ph.'),
  ('Kingstone Mineral Industries', '%Kingstone%', 'Bulacan', 'Santa Maria', 'https://www.kingstonemineral.com.ph', '1988년 설립 불라칸 Santa Maria 의 Kingstone Mineral. 분쇄 탄산칼슘(100~400 mesh), 제지 충전·코팅 용도 명시.', 'Kingstone Mineral Industries (founded 1988), 442 Guyong, Santa Maria, Bulacan - ground calcium carbonate 100-400 mesh, paper filling and coating named.', 'PH check 2026-10-15: 400 mesh is not fine paper GCC - D50 / D97, brightness, slurry to confirm. kingstonemineral1988@gmail.com.'),
  ('South Pacific Chemical Industries', '%South Pacific Chemical%', 'Rizal', 'Cainta', null, '1962년 설립 리잘 Cainta 공장의 South Pacific Chemical. 중질·초미분 탄산칼슘과 경질 PCC(2,000~4,000 mesh)·탈크·클레이.', 'South Pacific Chemical Industries (founded 1962, Cainta plant since 1969) - heavy and superfine calcium carbonate, light PCC (2,000-4,000 mesh), talc, clay, silica.', 'PH check 2026-10-15: whether it synthesises PCC (carbonation) or trades it is not confirmed. spacind@gmail.com.'),
  ('Busilak Philippines', '%Busilak%', 'Bulacan', 'Pulilan', 'https://www.busilakphil.com', '불라칸 Pulilan 의 Busilak Philippines. 경질 PCC(LPCC)를 제지 충전·코팅용으로 소개, 실리카 등.', 'Busilak Philippines, 140 Sta. Peregrina, Pulilan, Bulacan - light precipitated calcium carbonate for paper filling and coating, silica and other minerals.', 'PH check 2026-10-15: own carbonation reactors and paper PCC output not confirmed. sales@busilakphil.com.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'philippines_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya Mineral Philippines', 'GCC producer', 'Omya Philippines GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Philstone Industrial & Manufacturing', 'GCC producer', 'Philippine GCC - local OEM candidate', 'merchant', 'C', 'gcc'),
  ('Kingstone Mineral Industries', 'GCC producer', 'Bulacan GCC naming paper', 'merchant', 'C', 'gcc'),
  ('South Pacific Chemical Industries', 'PCC producer', 'PCC listed - synthesis to verify', 'merchant', 'C', 'pcc'),
  ('Busilak Philippines', 'PCC producer', 'Paper PCC named - synthesis to verify', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'philippines_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'PH', v.region, v.city, v.website, 'active', 'philippines_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Bataan 2020%', '%Bataan%Paper%', 'Bataan 2020 (Samal and Baesa)', 'Bataan', 'Samal', 'https://www.bataan2020.net', '1956년 기원, 2000년 기존 Bataan 제지공장 인수로 출범한 Bataan 2020. Samal(바탄)·Baesa(케손시티) 공장, 서적·본드지·티슈·포장용지, 연 10만 t 이상.', 'Bataan 2020 Inc. (roots 1956, took over the Bataan mill in 2000) - Samal, Bataan and Baesa, Quezon City mills, book and bond paper, tissue (toilet, facial, towel, napkin) and packaging, over 100,000 t/yr (company).', 'PH check 2026-10-15: 2018 environmental filing - 50,652 t/yr then, expansion plan to 190,652 t/yr (PHP 800m) - plan, not confirmed. sales@bataan2020.net.'),
  ('%Quanta Paper%', '%Quanta%', 'Quanta Paper Corporation (Mabalacat)', 'Pampanga', 'Mabalacat', 'https://www.quantapaper.com.ph', '2003년 설립 팜팡가 마발라캇의 Quanta Paper. 부지 약 70ha, 초지기 5대·가공설비 30대 이상, 재생·버진펄프 티슈(Fresh·Kami·Smart Choice).', 'Quanta Paper Corporation (founded 2003), Ninoy Aquino Highway, Paralayunan, Mabalacat, Pampanga - about 70 ha, five paper machines and over 30 converting lines, recycled and 100 pct virgin-pulp tissue (Fresh, Kami, Smart Choice).', 'PH check 2026-10-15: machine output, grammage, furnish and filler supplier not public. wecare@quantapaper.com, +63 2 8533 9250.'),
  ('%Fifth Discipline%', '%Fifth Discipline Packaging%', 'Fifth Discipline Packaging Paper (Mabalacat)', 'Pampanga', 'Mabalacat', 'https://www.fifthdiscipline.com.ph', '2017년 설립 TECO 산업단지의 Fifth Discipline Packaging Paper. 100% 재생 골심지·테스트라이너·백색지·신문용지, 400 t/일.', 'Fifth Discipline Packaging Paper (founded 2017), TECO Industrial Park, Mabalacat - 100 pct recycled corrugating medium, testliner, white grade and newsprint, 400 t/day rated, ISO 9001, FSC.', 'PH check 2026-10-15: sales@fifthdiscipline.com.ph.'),
  ('%United Pulp%', '%UPPC%', 'United Pulp and Paper (UPPC) - SCGP (Calumpit)', 'Bulacan', 'Calumpit', null, '태국 SCGP 계열 United Pulp and Paper(UPPC). 불라칸 Calumpit, 초지기 3대, 100% 회수폐지 테스트라이너·골심지 연 45만 t.', 'United Pulp and Paper Co. (UPPC, SCGP group), Calumpit, Bulacan - three paper machines, 100 pct recovered fibre testliner and corrugating medium, 450,000 t/yr.', 'PH check 2026-10-15: ANDRITZ OCC line 870 ADMT/day (2022) - stock prep, not paper output. Approach SCGP at group level (Thailand).')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bataan 2020%', '%Bataan%Paper%', '%Bataan%', '1956년 기원, 2000년 기존 Bataan 제지공장 인수로 출범한 Bataan 2020. Samal(바탄)·Baesa(케손시티) 공장, 서적·본드지·티슈·포장용지, 연 10만 t 이상.', 'Bataan 2020 Inc. (roots 1956, took over the Bataan mill in 2000) - Samal, Bataan and Baesa, Quezon City mills, book and bond paper, tissue (toilet, facial, towel, napkin) and packaging, over 100,000 t/yr (company).', 'PH check 2026-10-15: 2018 environmental filing - 50,652 t/yr then, expansion plan to 190,652 t/yr (PHP 800m) - plan, not confirmed. sales@bataan2020.net.'),
  ('%Quanta Paper%', '%Quanta%', '%Quanta%', '2003년 설립 팜팡가 마발라캇의 Quanta Paper. 부지 약 70ha, 초지기 5대·가공설비 30대 이상, 재생·버진펄프 티슈(Fresh·Kami·Smart Choice).', 'Quanta Paper Corporation (founded 2003), Ninoy Aquino Highway, Paralayunan, Mabalacat, Pampanga - about 70 ha, five paper machines and over 30 converting lines, recycled and 100 pct virgin-pulp tissue (Fresh, Kami, Smart Choice).', 'PH check 2026-10-15: machine output, grammage, furnish and filler supplier not public. wecare@quantapaper.com, +63 2 8533 9250.'),
  ('%TIPCO%', '%Trust International Paper%', '%TIPCO%', 'Trust International Paper(TIPCO). 마발라캇 TECO 산업단지 37ha, 100% 재생폐지·탈묵 신문용지·인쇄·필기용지·포장지.', 'Trust International Paper Corporation (TIPCO), TECO Industrial Park, Mabalacat, Pampanga - 37 ha, 100 pct recovered paper with deinking, newsprint, printing and writing and packaging (first machine 1987).', null),
  ('%Fifth Discipline%', '%Fifth Discipline Packaging%', '%Fifth Discipline%', '2017년 설립 TECO 산업단지의 Fifth Discipline Packaging Paper. 100% 재생 골심지·테스트라이너·백색지·신문용지, 400 t/일.', 'Fifth Discipline Packaging Paper (founded 2017), TECO Industrial Park, Mabalacat - 100 pct recycled corrugating medium, testliner, white grade and newsprint, 400 t/day rated, ISO 9001, FSC.', 'PH check 2026-10-15: sales@fifthdiscipline.com.ph.'),
  ('%United Pulp%', '%UPPC%', '%United Pulp%', '태국 SCGP 계열 United Pulp and Paper(UPPC). 불라칸 Calumpit, 초지기 3대, 100% 회수폐지 테스트라이너·골심지 연 45만 t.', 'United Pulp and Paper Co. (UPPC, SCGP group), Calumpit, Bulacan - three paper machines, 100 pct recovered fibre testliner and corrugating medium, 450,000 t/yr.', 'PH check 2026-10-15: ANDRITZ OCC line 870 ADMT/day (2022) - stock prep, not paper output. Approach SCGP at group level (Thailand).'),
  ('%Multi Ply%', '%Multi Ply Paper%', '%Multi Ply%', '2012년 설립 TECO 산업단지의 Multi Ply Paper Ventures. 재생 테스트라이너·골심지·백지, 200 t/일.', 'Multi Ply Paper Ventures (founded 2012), TECO Industrial Park, Mabalacat - recycled testliner, corrugating medium and bag paper, 200 t/day (company site).', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'philippines_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bataan 2020%', '%Bataan%Paper%', '%Bataan%'),
  ('%Quanta Paper%', '%Quanta%', '%Quanta%'),
  ('%TIPCO%', '%Trust International Paper%', '%TIPCO%'),
  ('%Fifth Discipline%', '%Fifth Discipline Packaging%', '%Fifth Discipline%'),
  ('%United Pulp%', '%UPPC%', '%United Pulp%'),
  ('%Multi Ply%', '%Multi Ply Paper%', '%Multi Ply%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bataan 2020%', '%Bataan%Paper%', '%Bataan%',
   $pj${"owner": "Bataan 2020", "priority": 1, "products": "Book and bond paper, tissue, packaging paper", "grades": ["Writing and printing", "Tissue", "Packaging"], "capacity_split": [{"label": "Company figure (over)", "value_t": 100000}, {"label": "2018 expansion plan", "value_t": 190652}], "pitch": "Several grades in one company - printing paper first, tissue as a separate trial", "approach": "Lead Philippine account. Pair with Omya Philippines or a local GCC maker (Philstone, Kingstone).", "to_collect": ["Current PCC / GCC supplier and loading per grade", "Pulp versus recovered fibre, ash in deinked pulp", "Machine-level output and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Quanta Paper%', '%Quanta%', '%Quanta%',
   $pj${"owner": "Quanta Paper Corporation", "priority": 2, "products": "Toilet and facial tissue, towels", "grades": ["Tissue"], "machines": 5, "pitch": "Virgin-pulp tissue - start FCC at 3-5 pct using MBG tissue data", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%TIPCO%', '%Trust International Paper%', '%TIPCO%',
   $pj${"owner": "Trust International Paper Corporation", "priority": 3, "products": "Newsprint, printing and writing, packaging", "grades": ["Writing and printing", "Newsprint"], "approach": "Deinked fibre - measure ash and residual filler first so FCC does not over-load ash.", "to_collect": ["Current PCC / GCC supplier and loading per grade", "Pulp versus recovered fibre, ash in deinked pulp", "Machine-level output and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Fifth Discipline%', '%Fifth Discipline Packaging%', '%Fifth Discipline%',
   $pj${"owner": "Fifth Discipline Packaging Paper", "priority": 4, "products": "Corrugating medium, testliner, white grade, newsprint", "grades": ["White grade", "Testliner"], "capacity_split": [{"label": "400 t/day x 330 (calculated)", "value_t": 132000}], "approach": "Trial the white recycled grade first, packaging later.", "to_collect": ["Current PCC / GCC supplier and loading per grade", "Pulp versus recovered fibre, ash in deinked pulp", "Machine-level output and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%United Pulp%', '%UPPC%', '%United Pulp%',
   $pj${"owner": "SCGP (SCG group)", "priority": 5, "products": "Testliner, corrugating medium", "grades": ["Testliner", "Medium"], "machines": 3, "capacity_split": [{"label": "Three machines", "value_t": 450000}], "approach": "Large but strength-critical - burst, SCT, RCT, CMT, bonding, drainage first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Multi Ply%', '%Multi Ply Paper%', '%Multi Ply%',
   $pj${"owner": "Multi Ply Paper Ventures", "products": "Testliner, corrugating medium, bag paper", "approach": "Packaging - later.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Bataan 2020%', '%Bataan%Paper%', '%Bataan%'),
  ('%Quanta Paper%', '%Quanta%', '%Quanta%'),
  ('%TIPCO%', '%Trust International Paper%', '%TIPCO%'),
  ('%Fifth Discipline%', '%Fifth Discipline Packaging%', '%Fifth Discipline%'),
  ('%United Pulp%', '%UPPC%', '%United Pulp%'),
  ('%Multi Ply%', '%Multi Ply Paper%', '%Multi Ply%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'philippines_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'philippines_update_20261015' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Omya%Philippines%' or p.party_name ilike '%Philstone%' or p.party_name ilike '%Kingstone%' or p.party_name ilike '%South Pacific Chemical%' or p.party_name ilike '%Busilak%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'philippines_update_20261015'
order by 1, 4, 2;
