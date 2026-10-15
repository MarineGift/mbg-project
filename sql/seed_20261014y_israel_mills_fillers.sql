-- ============================================================
-- seed_20261014y_israel_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Israel update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'IL check 2026-10-14',
-- plant data -> Mill profile card. Already in URM: Infinya, Shaniv.
--
-- 1) Fillers if missing: Omya Shefaya, Specialty Minerals Israel (closed
--    2006, kept as history), Negev Industrial Minerals.
-- 2) Mills if missing + plant blocks, priority 1-4: Shaniv, Panda (Sano),
--    Kimberly-Clark Israel, Infinya. context: Snir.
-- 3) HISTORICAL links to Infinya (Hadera): SMI Israel 1996-2006-04 (MTI
--    10-K), Omya Shefaya 2005-2020-12 (Hadera SEC filings, printing paper
--    exit 2019).
--    No FCC scenarios.
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
       v.party_name, 'IL', v.region, v.city, v.website, 'active', 'israel_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya Shefaya (Israel)', '%Shefaya%', 'Center District', 'Emek Hefer', 'https://www.omya.com', 'Omya 그룹의 이스라엘 법인 Omya Shfeya(Shefaya). 2005년 Hadera Paper 와 PCC 공급계약, 이스라엘 PCC 공장 건설·운영.', 'Omya Shfeya (Omya Shefaya Ltd.), Omya''s Israeli company - PCC supply contract with Hadera Paper since 2005, built and ran a PCC plant in Israel.', 'IL check 2026-10-14: 6 Nahal Alexander St, Emek Hefer Industrial Park (Omya site, may not be the plant). Contract extended to 2020-12. Current plant status and capacity unknown. Omya also runs Multifill and FiberLean - FCC partner and competitor. Royalty licensee at Omya HQ level.'),
  ('Specialty Minerals Israel (historical)', '%Specialty Minerals%Israel%', null, 'Hadera', 'https://www.mineralstech.com', 'MTI 의 이스라엘 법인 Specialty Minerals Israel. 1996년 하데라 위성 PCC 가동, 2006-04 가동 중단·2006 4분기 청산.', 'Specialty Minerals Israel Ltd. (MTI) - Hadera satellite PCC since early 1996 (about 25,000-35,000 t/yr), stopped 2006-04, subsidiary liquidated in Q4 2006.', 'IL check 2026-10-14: per MTI 2006 annual report - discontinued operation. Not a current supplier.'),
  ('Negev Industrial Minerals (NIM)', '%Negev Industrial%', 'Southern District', 'Rotem', 'https://www.nim.co.il', '1953년 설립 네게브의 Negev Industrial Minerals. Rotem 평원 석회석·생석회·소석회, Hatira 규사.', 'Negev Industrial Minerals (founded 1953), Negev - limestone, quicklime and hydrated lime at Rotem Plain (plant 1995), silica sand at Hatira.', 'IL check 2026-10-14: possible lime and limestone source for PCC-based FCC - paper-grade GCC or PCC not confirmed. A. Shitzer (chemical distributor) not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%IL check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Omya Shefaya (Israel)', '%Shefaya%', 'Center District', 'Emek Hefer', 'https://www.omya.com', 'Omya 그룹의 이스라엘 법인 Omya Shfeya(Shefaya). 2005년 Hadera Paper 와 PCC 공급계약, 이스라엘 PCC 공장 건설·운영.', 'Omya Shfeya (Omya Shefaya Ltd.), Omya''s Israeli company - PCC supply contract with Hadera Paper since 2005, built and ran a PCC plant in Israel.', 'IL check 2026-10-14: 6 Nahal Alexander St, Emek Hefer Industrial Park (Omya site, may not be the plant). Contract extended to 2020-12. Current plant status and capacity unknown. Omya also runs Multifill and FiberLean - FCC partner and competitor. Royalty licensee at Omya HQ level.'),
  ('Specialty Minerals Israel (historical)', '%Specialty Minerals%Israel%', null, 'Hadera', 'https://www.mineralstech.com', 'MTI 의 이스라엘 법인 Specialty Minerals Israel. 1996년 하데라 위성 PCC 가동, 2006-04 가동 중단·2006 4분기 청산.', 'Specialty Minerals Israel Ltd. (MTI) - Hadera satellite PCC since early 1996 (about 25,000-35,000 t/yr), stopped 2006-04, subsidiary liquidated in Q4 2006.', 'IL check 2026-10-14: per MTI 2006 annual report - discontinued operation. Not a current supplier.'),
  ('Negev Industrial Minerals (NIM)', '%Negev Industrial%', 'Southern District', 'Rotem', 'https://www.nim.co.il', '1953년 설립 네게브의 Negev Industrial Minerals. Rotem 평원 석회석·생석회·소석회, Hatira 규사.', 'Negev Industrial Minerals (founded 1953), Negev - limestone, quicklime and hydrated lime at Rotem Plain (plant 1995), silica sand at Hatira.', 'IL check 2026-10-14: possible lime and limestone source for PCC-based FCC - paper-grade GCC or PCC not confirmed. A. Shitzer (chemical distributor) not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'israel_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya Shefaya (Israel)', 'PCC producer', 'Omya Israel - PCC history with Hadera', 'satellite (on-site)', 'B', 'pcc'),
  ('Specialty Minerals Israel (historical)', 'PCC producer', 'Historical SMI satellite (closed 2006)', 'satellite (on-site)', 'A', 'pcc'),
  ('Negev Industrial Minerals (NIM)', 'GCC producer', 'Israeli limestone and lime - raw material option', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'israel_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'IL', v.region, v.city, v.website, 'active', 'israel_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Shaniv%', '%Shaniv Paper%', 'Shaniv Paper Industries (Ofakim)', 'Southern District', 'Ofakim', 'https://www.shaniv.com', '남부 오파킴의 Shaniv Paper Industries. 화장지·키친타월·미용티슈·냅킨, 연 3.5만 t 이상, 부지 약 8만 m2, 천연가스 자가발전.', 'Shaniv Paper Industries, Ofakim, southern Israel - toilet paper, towels, facial tissue and napkins, over 35,000 t/yr, about 80,000 m2 site, gas-fired own power.', 'IL check 2026-10-14: recycled paper and certified cellulose furnish. Company says over 40 pct of Israeli supply (its own segment).'),
  ('%Panda Paper%', '%IsraPaper%', 'Panda Paper Mills - Sano (Netanya)', 'Center District', 'Netanya', null, 'Sano 그룹의 Panda Paper Mills(네타냐). 재생섬유 AfH 티슈, 티슈기 PM1(Toscotec 건조부 개조 2024).', 'Panda Paper Mills (Sano group), Netanya - recycled-fibre AfH (away-at-work) tissue on one machine, PM1 dryer rebuild by Toscotec ordered 2023 for 2024.', 'IL check 2026-10-14: sister IsraPaper makes parent rolls of recovered paper, Snir Paper Industries (Kibbutz Snir) is the third Sano paper unit. Approach via Sano Paper and Complementary Products division.'),
  ('%Kimberly%Israel%', '%Hogla%', 'Kimberly-Clark Israel - Hadera (Hogla)', 'Haifa District', 'Hadera', 'https://www.kimberly-clark.com', 'Kimberly-Clark 이스라엘(구 Hogla-Kimberly). 하데라 티슈 시설, 화장지·미용티슈·타월.', 'Kimberly-Clark Israel (formerly Hogla-Kimberly) - Hadera tissue site, toilet and facial tissue, towels.', 'IL check 2026-10-14: Nahariya listed as a tissue site in 2008, only Hadera in 2019. Capacity not public.'),
  ('%Snir Paper%', '%Snir%', 'Snir Paper Industries (Kibbutz Snir)', 'Northern District', 'Snir', null, 'Sano 계열 Snir Paper Industries(키부츠 스니르). 화장지·티슈·산업용지.', 'Snir Paper Industries (1995), Kibbutz Snir, northern Israel (Sano group) - toilet paper, tissue, industrial paper.', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%IL check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Shaniv%', '%Shaniv Paper%', '%Shaniv%', '남부 오파킴의 Shaniv Paper Industries. 화장지·키친타월·미용티슈·냅킨, 연 3.5만 t 이상, 부지 약 8만 m2, 천연가스 자가발전.', 'Shaniv Paper Industries, Ofakim, southern Israel - toilet paper, towels, facial tissue and napkins, over 35,000 t/yr, about 80,000 m2 site, gas-fired own power.', 'IL check 2026-10-14: recycled paper and certified cellulose furnish. Company says over 40 pct of Israeli supply (its own segment).'),
  ('%Panda Paper%', '%IsraPaper%', '%Panda%', 'Sano 그룹의 Panda Paper Mills(네타냐). 재생섬유 AfH 티슈, 티슈기 PM1(Toscotec 건조부 개조 2024).', 'Panda Paper Mills (Sano group), Netanya - recycled-fibre AfH (away-at-work) tissue on one machine, PM1 dryer rebuild by Toscotec ordered 2023 for 2024.', 'IL check 2026-10-14: sister IsraPaper makes parent rolls of recovered paper, Snir Paper Industries (Kibbutz Snir) is the third Sano paper unit. Approach via Sano Paper and Complementary Products division.'),
  ('%Kimberly%Israel%', '%Hogla%', '%Kimberly%', 'Kimberly-Clark 이스라엘(구 Hogla-Kimberly). 하데라 티슈 시설, 화장지·미용티슈·타월.', 'Kimberly-Clark Israel (formerly Hogla-Kimberly) - Hadera tissue site, toilet and facial tissue, towels.', 'IL check 2026-10-14: Nahariya listed as a tissue site in 2008, only Hadera in 2019. Capacity not public.'),
  ('%Infinya%', '%Hadera Paper%', '%Infinya%', '1951년 American Israeli Paper Mills 로 출발한 Infinya(구 Hadera Paper). 하데라, 재생 골판지 원지(플루팅·테스트라이너) 연 약 32만 t.', 'Infinya (formerly Hadera Paper, founded 1951 as American Israeli Paper Mills), Hadera - recycled containerboard (fluting, testliner) about 320,000 t/yr, 60-70 pct sold in Israel.', 'IL check 2026-10-14: left white printing paper in 2019 and converted to packaging. PM8 (2009) raised packaging to 330,000 t. ANDRITZ OCC line 1,080 bdmt/day for 2024. Past PCC supply: SMI satellite 1996-2006, then Omya Shefaya since 2005 (contract to 2020-12).'),
  ('%Snir Paper%', '%Snir%', '%Snir%', 'Sano 계열 Snir Paper Industries(키부츠 스니르). 화장지·티슈·산업용지.', 'Snir Paper Industries (1995), Kibbutz Snir, northern Israel (Sano group) - toilet paper, tissue, industrial paper.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'israel_update_20261014';

-- ---------- 3) HISTORICAL LINKS -> Infinya ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'historical', 'PCC filler-grade', r.vol, 'high', r.since, r.until, r.label,
       jsonb_build_object('supply_structure', r.structure, 'source', r.src, 'batch', 'israel_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values
  ('%Infinya%', '%Hadera Paper%', '%Infinya%', '%Specialty Minerals%Israel%', '%Specialty Minerals (Israel%',
   '~25,000-35,000 t/yr (1996 estimate)', '1996-01-01'::date, '2006-04-30'::date, 'satellite PCC at Hadera', 'MTI 10-K 2006 + Roskill 2005',
   'SMI Israel satellite PCC at Hadera - stopped 2006-04, subsidiary liquidated Q4 2006'),
  ('%Infinya%', '%Hadera Paper%', '%Infinya%', '%Shefaya%', 'Omya%Israel%',
   null, '2005-09-01'::date, '2020-12-31'::date, 'PCC plant built and run by Omya in Israel', 'Hadera Paper SEC filings',
   'Omya Shefaya PCC supply to Hadera Paper 2005 - contract to 2020-12, white printing paper exit 2019')
) as v(name_like, alt_like, owner_like, f1, f2, vol, since, until, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and (x.party_name ilike v.f1 or x.party_name ilike v.f2)
  order by x.created_at limit 1
) f
cross join lateral (select v.vol, v.since, v.until, v.structure, v.src, v.label) r
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Shaniv%', '%Shaniv Paper%', '%Shaniv%'),
  ('%Panda Paper%', '%IsraPaper%', '%Panda%'),
  ('%Kimberly%Israel%', '%Hogla%', '%Kimberly%'),
  ('%Infinya%', '%Hadera Paper%', '%Infinya%'),
  ('%Snir Paper%', '%Snir%', '%Snir%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Shaniv%', '%Shaniv Paper%', '%Shaniv%',
   $pj${"owner": "Shaniv Paper Industries", "priority": 1, "products": "Toilet paper, towels, facial tissue, napkins", "grades": ["Tissue", "Towel"], "capacity_split": [{"label": "Company figure (over)", "value_t": 35000}], "pitch": "Tissue FCC - fibre saving on mixed recycled and virgin furnish", "approach": "First Israeli contact for tissue samples and a trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Panda Paper%', '%IsraPaper%', '%Panda%',
   $pj${"owner": "Sano Bruno's Enterprises", "priority": 2, "products": "Recycled AfH (away-at-work) tissue", "grades": ["Tissue"], "machines": 1, "pitch": "Recycled-fibre tissue FCC", "approach": "Group-level technical review with Sano - IsraPaper is the base-paper maker.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kimberly%Israel%', '%Hogla%', '%Kimberly%',
   $pj${"owner": "Kimberly-Clark", "priority": 3, "products": "Toilet and facial tissue, towels", "grades": ["Tissue"], "pitch": "A win can open the global Kimberly-Clark tissue network (also Kluang, Malaysia)", "approach": "Find the local R and D and manufacturing decision makers first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Infinya%', '%Hadera Paper%', '%Infinya%',
   $pj${"owner": "Infinya", "priority": 4, "products": "Recycled fluting and testliner", "grades": ["Fluting", "Testliner"], "capacity_split": [{"label": "Containerboard", "value_t": 320000}], "filler": [{"supplier": "Specialty Minerals Israel", "type": "Satellite PCC", "status": "Historical 1996-2006", "basis": "MTI 10-K 2006"}, {"supplier": "Omya Shefaya", "type": "PCC plant in Israel", "status": "Historical 2005-2020 (printing paper exit 2019)", "basis": "Hadera Paper SEC filings"}], "approach": "PCC demand ended with white printing paper. Recycled containerboard needs SCT, RCT, CMT and burst held - FCC only after strength data.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Snir Paper%', '%Snir%', '%Snir%',
   $pj${"owner": "Sano Bruno's Enterprises", "products": "Toilet paper, tissue, industrial paper", "approach": "Part of the Sano approach.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Shaniv%', '%Shaniv Paper%', '%Shaniv%'),
  ('%Panda Paper%', '%IsraPaper%', '%Panda%'),
  ('%Kimberly%Israel%', '%Hogla%', '%Kimberly%'),
  ('%Infinya%', '%Hadera Paper%', '%Infinya%'),
  ('%Snir Paper%', '%Snir%', '%Snir%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'israel_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IL'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'israel_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Shefaya%' or p.party_name ilike '%Specialty Minerals%Israel%' or p.party_name ilike '%Negev Industrial%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'israel_update_20261014'
order by 1, 4, 2;
