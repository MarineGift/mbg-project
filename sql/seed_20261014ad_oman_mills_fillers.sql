-- ============================================================
-- seed_20261014ad_oman_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Oman update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'OM check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: IMC (Sohar, 120 kt GCC), GMMC (Salalah), SAC
--    (drilling grade), ALTAIF (planned 6,000 t/day GCC), Al Jood (limestone).
--    No PCC plant in Oman. Global Chemicals (distributor) skipped.
-- 2) Mills if missing + plant blocks, priority 1-2: Keryas (180 kt recycled
--    containerboard), Oman Royal Paper (100 t/day). context, match only:
--    CARMA (converter). Other tissue converters and box makers not added.
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
       v.party_name, 'OM', v.region, v.city, v.website, 'active', 'oman_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Industrial Minerals Company (IMC) - Northern Minerals', '%Industrial Minerals Company%', 'North Al Batinah', 'Sohar', 'https://www.nmc-oman.com', 'Northern Minerals 계열 Industrial Minerals Company(2009년 설립, 소하르). 분쇄·이중 분급 GCC·코팅 GCC, 연 12만 t.', 'Industrial Minerals Company (Northern Minerals, founded 2009), Sohar Industrial Estate - ground and double-classified GCC and stearic-coated GCC, 120,000 t/yr nameplate.', 'OM check 2026-10-14: particle range 2-250 or 8-300 um by source. Main uses PVC, plastics, paint - paper supply, sub-2 um share and brightness to confirm. Earlier 70,000 t plus 30,000 t expansion figures. Same estate as Keryas.'),
  ('Global Marble Manufacturing (GMMC)', '%Global Marble%', 'Dhofar', 'Salalah', 'https://www.gmmc.om', 'Global Mining 계열 Global Marble Manufacturing(2018년 설립, 살랄라 Raysut). 자체 석회석 광산, 탄산칼슘 분말, 제지 용도 명시.', 'Global Marble Manufacturing (Global Mining group, founded 2018), Raysut, Salalah - own limestone quarry, calcium carbonate powder, paper named among uses.', 'OM check 2026-10-14: particle range 5-160 um (web) versus 2-32 um+ (brochure). Capacity, wet plant and customers not public. marketing@gmmc.om, +968 23132668.'),
  ('Sohar Advanced Chemicals (SAC)', '%Sohar Advanced%', 'North Al Batinah', 'Sohar', 'https://www.sac-oman.com', '2011년 설립 Sohar Advanced Chemicals. 소하르(20만 t)·두큼(10만 t) 광물 공장, 시추용 탄산칼슘·벤토나이트·바라이트.', 'Sohar Advanced Chemicals (founded 2011) - Sohar (200,000 t/yr) and Duqm (100,000 t/yr) mineral plants, drilling-grade calcium carbonate, bentonite, barite.', 'OM check 2026-10-14: 300,000 t is all minerals. CaCO3 D50 5 / 10 / 25 / 50 um, purity 98 pct. Paper fit not shown. sacadmin@sac-oman.com.'),
  ('ALTAIF Mining', '%ALTAIF%', 'Ad Dhahirah', 'Wadi Dhank', 'https://www.altaifmining.com', 'Wadi Dhank 의 ALTAIF Mining. 석회석 채굴과 초미립 GCC 공장 개발(계획 6,000 t/일), 제지 용도 포함.', 'ALTAIF Mining, Wadi Dhank, Ad Dhahirah - limestone quarry and planned ultrafine GCC plant (6,000 t/day GCC, 30,000 t/day crushing), paper among target uses.', 'OM check 2026-10-14: project stage - commercial running not confirmed. Ore up to 96.12 pct CaCO3 may need upgrading for paper grades. Design FCC in if built. info@altaifmining.com.'),
  ('Al Jood Natural Resources', '%Al Jood%', 'Dhofar', 'Salalah', 'https://www.aljoodmining.com', '도파르의 Al Jood Natural Resources. 저실리카 석회석(CaO 54% 이상, SiO2 0.6% 이하) 공급.', 'Al Jood Natural Resources, Dhofar - low-silica limestone (CaO 54 pct+, SiO2 0.6 pct max) for paper, chemicals, paint and grinding plants.', 'OM check 2026-10-14: raw material only - no GCC or PCC plant. Global Chemicals (distributor of GCC and PCC) not added. No PCC plant found in Oman.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%OM check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Industrial Minerals Company (IMC) - Northern Minerals', '%Industrial Minerals Company%', 'North Al Batinah', 'Sohar', 'https://www.nmc-oman.com', 'Northern Minerals 계열 Industrial Minerals Company(2009년 설립, 소하르). 분쇄·이중 분급 GCC·코팅 GCC, 연 12만 t.', 'Industrial Minerals Company (Northern Minerals, founded 2009), Sohar Industrial Estate - ground and double-classified GCC and stearic-coated GCC, 120,000 t/yr nameplate.', 'OM check 2026-10-14: particle range 2-250 or 8-300 um by source. Main uses PVC, plastics, paint - paper supply, sub-2 um share and brightness to confirm. Earlier 70,000 t plus 30,000 t expansion figures. Same estate as Keryas.'),
  ('Global Marble Manufacturing (GMMC)', '%Global Marble%', 'Dhofar', 'Salalah', 'https://www.gmmc.om', 'Global Mining 계열 Global Marble Manufacturing(2018년 설립, 살랄라 Raysut). 자체 석회석 광산, 탄산칼슘 분말, 제지 용도 명시.', 'Global Marble Manufacturing (Global Mining group, founded 2018), Raysut, Salalah - own limestone quarry, calcium carbonate powder, paper named among uses.', 'OM check 2026-10-14: particle range 5-160 um (web) versus 2-32 um+ (brochure). Capacity, wet plant and customers not public. marketing@gmmc.om, +968 23132668.'),
  ('Sohar Advanced Chemicals (SAC)', '%Sohar Advanced%', 'North Al Batinah', 'Sohar', 'https://www.sac-oman.com', '2011년 설립 Sohar Advanced Chemicals. 소하르(20만 t)·두큼(10만 t) 광물 공장, 시추용 탄산칼슘·벤토나이트·바라이트.', 'Sohar Advanced Chemicals (founded 2011) - Sohar (200,000 t/yr) and Duqm (100,000 t/yr) mineral plants, drilling-grade calcium carbonate, bentonite, barite.', 'OM check 2026-10-14: 300,000 t is all minerals. CaCO3 D50 5 / 10 / 25 / 50 um, purity 98 pct. Paper fit not shown. sacadmin@sac-oman.com.'),
  ('ALTAIF Mining', '%ALTAIF%', 'Ad Dhahirah', 'Wadi Dhank', 'https://www.altaifmining.com', 'Wadi Dhank 의 ALTAIF Mining. 석회석 채굴과 초미립 GCC 공장 개발(계획 6,000 t/일), 제지 용도 포함.', 'ALTAIF Mining, Wadi Dhank, Ad Dhahirah - limestone quarry and planned ultrafine GCC plant (6,000 t/day GCC, 30,000 t/day crushing), paper among target uses.', 'OM check 2026-10-14: project stage - commercial running not confirmed. Ore up to 96.12 pct CaCO3 may need upgrading for paper grades. Design FCC in if built. info@altaifmining.com.'),
  ('Al Jood Natural Resources', '%Al Jood%', 'Dhofar', 'Salalah', 'https://www.aljoodmining.com', '도파르의 Al Jood Natural Resources. 저실리카 석회석(CaO 54% 이상, SiO2 0.6% 이하) 공급.', 'Al Jood Natural Resources, Dhofar - low-silica limestone (CaO 54 pct+, SiO2 0.6 pct max) for paper, chemicals, paint and grinding plants.', 'OM check 2026-10-14: raw material only - no GCC or PCC plant. Global Chemicals (distributor of GCC and PCC) not added. No PCC plant found in Oman.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'oman_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Industrial Minerals Company (IMC) - Northern Minerals', 'GCC producer', 'Oman GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Global Marble Manufacturing (GMMC)', 'GCC producer', 'Salalah GCC naming paper', 'merchant', 'C', 'gcc'),
  ('Sohar Advanced Chemicals (SAC)', 'GCC producer', 'Oman drilling-grade GCC', 'merchant', 'C', 'gcc'),
  ('ALTAIF Mining', 'GCC producer', 'Planned large Oman GCC - design-in FCC', 'merchant', 'C', 'gcc'),
  ('Al Jood Natural Resources', 'Limestone supplier', 'Oman limestone - raw material', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'oman_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'OM', v.region, v.city, v.website, 'active', 'oman_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Keryas%', '%Keryas Paper%', 'Keryas Paper Industry (Sohar)', 'North Al Batinah', 'Sohar', 'https://www.keryaspaper.com', '2018년 설립·2021-07 상업가동한 소하르의 Keryas Paper Industry. 3층 초지기(폭 4,400mm), 100% 재생섬유 플루팅·테스트라이너·코어보드, 연 18만 t.', 'Keryas Paper Industry (founded 2018, commercial since 2021-07), Sohar Industrial Area Phase 7 - three-ply machine (4,400 mm), 100 pct recycled fluting, testliner, core board, kraft and absorbent kraft, 180,000 t/yr nameplate.', 'OM check 2026-10-14: about 100,000 t produced in 2022 (interview). Markets Oman, UAE, Saudi Arabia. Plot 468, Phase 7, info@keryaspaper.com, +968 91411769. IMC (GCC) is in the same Sohar estate.'),
  ('%Oman Royal Paper%', '%Sea Dolphin%', 'Oman Royal Paper - International Sea Dolphin (Sohar)', 'North Al Batinah', 'Sohar', null, 'International Sea Dolphin 의 Oman Royal Paper(2020-10 개장, 소하르 Phase 7). 폐지 100% 크라프트·테스트라이너·플루팅, 최대 100 t/일.', 'Oman Royal Paper (International Sea Dolphin, opened 2020-10), Plot 430, Phase 7, Sohar - 100 pct waste-paper kraft, testliner and fluting, up to 100 t/day on about 36,000 m2.', 'OM check 2026-10-14: about 3,000 t/month in 2020, phase 2 target 9,500 t/month - not confirmed.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'OM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%OM check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'OM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Keryas%', '%Keryas Paper%', '%Keryas%', '2018년 설립·2021-07 상업가동한 소하르의 Keryas Paper Industry. 3층 초지기(폭 4,400mm), 100% 재생섬유 플루팅·테스트라이너·코어보드, 연 18만 t.', 'Keryas Paper Industry (founded 2018, commercial since 2021-07), Sohar Industrial Area Phase 7 - three-ply machine (4,400 mm), 100 pct recycled fluting, testliner, core board, kraft and absorbent kraft, 180,000 t/yr nameplate.', 'OM check 2026-10-14: about 100,000 t produced in 2022 (interview). Markets Oman, UAE, Saudi Arabia. Plot 468, Phase 7, info@keryaspaper.com, +968 91411769. IMC (GCC) is in the same Sohar estate.'),
  ('%Oman Royal Paper%', '%Sea Dolphin%', '%Oman Royal%', 'International Sea Dolphin 의 Oman Royal Paper(2020-10 개장, 소하르 Phase 7). 폐지 100% 크라프트·테스트라이너·플루팅, 최대 100 t/일.', 'Oman Royal Paper (International Sea Dolphin, opened 2020-10), Plot 430, Phase 7, Sohar - 100 pct waste-paper kraft, testliner and fluting, up to 100 t/day on about 36,000 m2.', 'OM check 2026-10-14: about 3,000 t/month in 2020, phase 2 target 9,500 t/month - not confirmed.'),
  ('%CARMA%', '%Carma Trading%', '%CARMA%', '알부라이미의 CARMA Trading & Converting. 화장지·냅킨·티슈 가공, 연 1.2만 t 이상.', 'CARMA Trading and Converting Industries (founded 2008), Al Buraimi - toilet, facial, napkin tissue converting, over 12,000 t/yr, Oman and Qatar.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'oman_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'OM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Keryas%', '%Keryas Paper%', '%Keryas%'),
  ('%Oman Royal Paper%', '%Sea Dolphin%', '%Oman Royal%'),
  ('%CARMA%', '%Carma Trading%', '%CARMA%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'OM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Keryas%', '%Keryas Paper%', '%Keryas%',
   $pj${"owner": "Keryas Paper Industry", "priority": 1, "products": "Fluting 80-200 gsm, testliner 80-175 gsm, core board 200-450 gsm, kraft liner, absorbent kraft", "grades": ["Fluting", "Testliner", "Core board"], "machines": 1, "capacity_split": [{"label": "Nameplate", "value_t": 180000}, {"label": "2022 output (interview)", "value_t": 100000}], "pitch": "Replace part of the recycled fibre while holding SCT, RCT, CMT, burst and bonding", "approach": "Lead Oman account - R and D meeting, low-dose trial. White printing-paper data does not transfer to packaging. Pair with IMC in Sohar as local FCC producer.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "keryaspaper.com, Papermart 2023"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Oman Royal Paper%', '%Sea Dolphin%', '%Oman Royal%',
   $pj${"owner": "International Sea Dolphin", "priority": 2, "products": "Kraft, testliner, fluting", "grades": ["Testliner", "Fluting"], "capacity_split": [{"label": "100 t/day x 360 (calculated)", "value_t": 36000}], "approach": "Smaller mill for a first industrial trial at 1-3 pct FCC - strength, basis weight, density, speed.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%CARMA%', '%Carma Trading%', '%CARMA%',
   $pj${"owner": "CARMA", "products": "Converted tissue", "approach": "Converter - product test partner, ask base-paper supplier. A new Salalah Free Zone tissue plant (commercial 2026-02) is also worth identifying.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Keryas%', '%Keryas Paper%', '%Keryas%'),
  ('%Oman Royal Paper%', '%Sea Dolphin%', '%Oman Royal%'),
  ('%CARMA%', '%Carma Trading%', '%CARMA%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'oman_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'OM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'oman_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Industrial Minerals Company%' or p.party_name ilike '%Global Marble%' or p.party_name ilike '%Sohar Advanced%' or p.party_name ilike '%ALTAIF%' or p.party_name ilike '%Al Jood%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'oman_update_20261014'
order by 1, 4, 2;
