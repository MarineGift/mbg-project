-- ============================================================
-- seed_20261015d_laos_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Laos update (reports 2026-10). Introduction -> intro_ko / intro_en (only
-- when empty), detail -> notes once with 'LA check 2026-10-15', plant data
-- -> Mill profile card.
--
-- 1) Fillers if missing: MCS Mining Industry Lao (GCC + lime), Viet Lao
--    Stone (plant under construction), Dong Nhan Stone Laos plant (started
--    2025-10). No paper PCC plant in Laos.
-- 2) Mills if missing + plant blocks, priority 1-3: Sun Paper Laos (800 kt
--    packaging - only paper part of 1.5 Mt), Khamhung (exports to Vietnam),
--    Asia Paper Mill (tissue). Namalat (bag converter) not added.
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
       v.party_name, 'LA', v.region, v.city, v.website, 'active', 'laos_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('MCS Mining Industry Lao', '%MCS Mining%', 'Khammouane', 'Thakhek', 'https://www.mcsminingindustry.org', '2013년 설립 캄무안 Thakhek 의 MCS Mining Industry Lao(태국계). 코팅·비코팅 GCC(325~2,500 mesh)·생석회·소석회·골재, 제지·펄프 용도 명시.', 'MCS Mining Industry Lao (Thai-owned, founded 2013), Ban Phin, Thakhek, Khammouane - coated and uncoated GCC (325-2,500 mesh, German equipment), quick and hydrated lime and aggregates, pulp and paper named as a market.', 'LA check 2026-10-15: plants confirmed by Thai consulate (2023), about 80 pct of the Lao lime market (lime, not GCC). GCC capacity, paper customers and wet slurry not public. Company-claimed 2 Bt reserve on 434 ha not independently verified. info@mcsminingindustry.org, +856 20 9588 0112.'),
  ('Viet Lao Stone Minerals', '%Viet Lao Stone%', null, null, null, '하노이 본사 Viet Lao Stone Minerals. 라오스 석회석 광산 3곳, 비코팅·코팅 GCC(제지용 사양 공개), 라오스 가공공장 건설 중.', 'Viet Lao Stone Minerals JSC (Hanoi head office) - three Lao limestone quarries, uncoated and coated GCC with a paper spec (CaCO3 98.5 pct, whiteness 98, brightness 96, D50 1.5-3.5 um), Lao processing plant under construction.', 'LA check 2026-10-15: confirm whether grinding is in Laos or Vietnam. TDS values, no batch COA. vietlaostone@gmail.com, +856 20 9131 6666.'),
  ('Dong Nhan Stone - Laos plant', '%Dong Nhan%', null, null, null, '베트남 Dong Nhan Stone 이 2025-10 라오스 자체 광산 인근에 신규 탄산칼슘 공장 착공.', 'Dong Nhan Stone (Vietnam) - new calcium carbonate plant started 2025-10 near its own Lao quarry, high-white stone (whiteness 98, brightness 96).', 'LA check 2026-10-15: group capacity 45,000 t/month is not the Lao plant figure. Address, completion and paper sales unknown - design-in FCC if timing fits. +84 904 946 568. S K Chemical Traders (trader) not added. No paper PCC plant in Laos.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%LA check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('MCS Mining Industry Lao', '%MCS Mining%', 'Khammouane', 'Thakhek', 'https://www.mcsminingindustry.org', '2013년 설립 캄무안 Thakhek 의 MCS Mining Industry Lao(태국계). 코팅·비코팅 GCC(325~2,500 mesh)·생석회·소석회·골재, 제지·펄프 용도 명시.', 'MCS Mining Industry Lao (Thai-owned, founded 2013), Ban Phin, Thakhek, Khammouane - coated and uncoated GCC (325-2,500 mesh, German equipment), quick and hydrated lime and aggregates, pulp and paper named as a market.', 'LA check 2026-10-15: plants confirmed by Thai consulate (2023), about 80 pct of the Lao lime market (lime, not GCC). GCC capacity, paper customers and wet slurry not public. Company-claimed 2 Bt reserve on 434 ha not independently verified. info@mcsminingindustry.org, +856 20 9588 0112.'),
  ('Viet Lao Stone Minerals', '%Viet Lao Stone%', null, null, null, '하노이 본사 Viet Lao Stone Minerals. 라오스 석회석 광산 3곳, 비코팅·코팅 GCC(제지용 사양 공개), 라오스 가공공장 건설 중.', 'Viet Lao Stone Minerals JSC (Hanoi head office) - three Lao limestone quarries, uncoated and coated GCC with a paper spec (CaCO3 98.5 pct, whiteness 98, brightness 96, D50 1.5-3.5 um), Lao processing plant under construction.', 'LA check 2026-10-15: confirm whether grinding is in Laos or Vietnam. TDS values, no batch COA. vietlaostone@gmail.com, +856 20 9131 6666.'),
  ('Dong Nhan Stone - Laos plant', '%Dong Nhan%', null, null, null, '베트남 Dong Nhan Stone 이 2025-10 라오스 자체 광산 인근에 신규 탄산칼슘 공장 착공.', 'Dong Nhan Stone (Vietnam) - new calcium carbonate plant started 2025-10 near its own Lao quarry, high-white stone (whiteness 98, brightness 96).', 'LA check 2026-10-15: group capacity 45,000 t/month is not the Lao plant figure. Address, completion and paper sales unknown - design-in FCC if timing fits. +84 904 946 568. S K Chemical Traders (trader) not added. No paper PCC plant in Laos.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'laos_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('MCS Mining Industry Lao', 'GCC producer', 'Laos GCC and lime - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Viet Lao Stone Minerals', 'GCC producer', 'High-white GCC with Lao quarries', 'merchant', 'C', 'gcc'),
  ('Dong Nhan Stone - Laos plant', 'GCC producer', 'New Lao GCC plant - design-in FCC', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'laos_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'LA', v.region, v.city, v.website, 'active', 'laos_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Sun Paper%', '%Sun Paper%Laos%', 'Sun Paper Holding Laos (Savannakhet)', 'Savannakhet', 'Xepon', null, 'Shandong Sun Paper 의 라오스 생산기지(사반나켓). 고급 포장용지 80만 t·재생섬유 펄프 40만 t·용해펄프 30만 t, 2018년 이후 6억 달러 이상 투자.', 'Sun Paper Holding Laos (Shandong Sun Paper), Savannakhet - packaging paper 800,000 t/yr (testliner, corrugating medium), recycled-fibre pulp 400,000 t/yr and dissolving pulp 300,000 t/yr, over USD 600m invested since 2018, about 60,000 ha own plantations.', 'LA check 2026-10-15: two OCC lines and two paper machines by ANDRITZ (1,434 t/day max each - design, not sales), Valmet pulp line (run cycle 6 to 15 months, 2026). 1.5 Mt is the sum of different units - only 800 kt is paper. Group parent also runs Sun Paper Yanzhou (China) with SMI satellite PCC.'),
  ('%Khamhung%', '%Khamhung Paper%', 'Khamhung Paper Product Factory (Vientiane Province)', 'Vientiane Province', 'Xanakham', null, '비엔티안주 Xanakham 의 Khamhung Paper Product Factory. 비도공·미표백 원지(기계펄프 계열) 베트남 수출.', 'Khamhung Paper Product Factory, Takdet Village, Xanakham, Vientiane Province - uncoated unbleached roll paper (68.3 pct mechanical and CTMP in one 2026-07 shipment) exported to Vietnam.', 'LA check 2026-10-15: about 134 export shipments in 2025 and 90 by 2026-07 (trade data), buyers incl. Vilaconic, B and C Vietnam, Dai Nam Plastic. Machines, capacity and filler use not public.'),
  ('%Asia Paper Mill%', '%Asia Paper Mill Factory%', 'Asia Paper Mill Factory (Vientiane)', 'Vientiane', 'Vientiane', null, '비엔티안 Thadeua 로드의 Asia Paper Mill Factory. 화장지·미용티슈.', 'Asia Paper Mill Factory, Km 10 Thadeua Road, Somsanouk, Vientiane - toilet and facial tissue.', 'LA check 2026-10-15: listed in Paper-World directory, current running and own base-paper making not confirmed. +856 21 314961. Namalat Paper Bag (bag converter) not added.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LA check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sun Paper%', '%Sun Paper%Laos%', '%Sun Paper%', 'Shandong Sun Paper 의 라오스 생산기지(사반나켓). 고급 포장용지 80만 t·재생섬유 펄프 40만 t·용해펄프 30만 t, 2018년 이후 6억 달러 이상 투자.', 'Sun Paper Holding Laos (Shandong Sun Paper), Savannakhet - packaging paper 800,000 t/yr (testliner, corrugating medium), recycled-fibre pulp 400,000 t/yr and dissolving pulp 300,000 t/yr, over USD 600m invested since 2018, about 60,000 ha own plantations.', 'LA check 2026-10-15: two OCC lines and two paper machines by ANDRITZ (1,434 t/day max each - design, not sales), Valmet pulp line (run cycle 6 to 15 months, 2026). 1.5 Mt is the sum of different units - only 800 kt is paper. Group parent also runs Sun Paper Yanzhou (China) with SMI satellite PCC.'),
  ('%Khamhung%', '%Khamhung Paper%', '%Khamhung%', '비엔티안주 Xanakham 의 Khamhung Paper Product Factory. 비도공·미표백 원지(기계펄프 계열) 베트남 수출.', 'Khamhung Paper Product Factory, Takdet Village, Xanakham, Vientiane Province - uncoated unbleached roll paper (68.3 pct mechanical and CTMP in one 2026-07 shipment) exported to Vietnam.', 'LA check 2026-10-15: about 134 export shipments in 2025 and 90 by 2026-07 (trade data), buyers incl. Vilaconic, B and C Vietnam, Dai Nam Plastic. Machines, capacity and filler use not public.'),
  ('%Asia Paper Mill%', '%Asia Paper Mill Factory%', '%Asia Paper%', '비엔티안 Thadeua 로드의 Asia Paper Mill Factory. 화장지·미용티슈.', 'Asia Paper Mill Factory, Km 10 Thadeua Road, Somsanouk, Vientiane - toilet and facial tissue.', 'LA check 2026-10-15: listed in Paper-World directory, current running and own base-paper making not confirmed. +856 21 314961. Namalat Paper Bag (bag converter) not added.')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'laos_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sun Paper%', '%Sun Paper%Laos%', '%Sun Paper%'),
  ('%Khamhung%', '%Khamhung Paper%', '%Khamhung%'),
  ('%Asia Paper Mill%', '%Asia Paper Mill Factory%', '%Asia Paper%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sun Paper%', '%Sun Paper%Laos%', '%Sun Paper%',
   $pj${"owner": "Shandong Sun Paper", "priority": 1, "products": "Testliner and corrugating medium, recycled-fibre pulp, dissolving pulp", "grades": ["Testliner", "Medium"], "machines": 2, "capacity_split": [{"label": "Packaging paper", "value_t": 800000}, {"label": "Recycled-fibre pulp", "value_t": 400000}, {"label": "Dissolving pulp", "value_t": 300000}], "pitch": "Hold strength while saving fibre on recycled packaging grades", "approach": "Biggest Laos customer but packaging - test SCT, RCT, burst, bond, drainage before sizing. Decisions likely sit with Shandong HQ - approach through the Sun Paper group account.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "Sun Paper group, ANDRITZ, Valmet, Thai consulate 2025-08"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Khamhung%', '%Khamhung Paper%', '%Khamhung%',
   $pj${"owner": "Khamhung Paper Product Factory", "priority": 2, "products": "Uncoated unbleached roll paper, kraft-type base paper", "grades": ["Uncoated base paper"], "approach": "Real exporter - check machine, furnish and current carbonate use before a pilot.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Asia Paper Mill%', '%Asia Paper Mill Factory%', '%Asia Paper%',
   $pj${"owner": "Asia Paper Mill Factory", "priority": 3, "products": "Toilet and facial tissue", "grades": ["Tissue"], "approach": "Confirm it runs a tissue machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Sun Paper%', '%Sun Paper%Laos%', '%Sun Paper%'),
  ('%Khamhung%', '%Khamhung Paper%', '%Khamhung%'),
  ('%Asia Paper Mill%', '%Asia Paper Mill Factory%', '%Asia Paper%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'laos_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'laos_update_20261015' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%MCS Mining%' or p.party_name ilike '%Viet Lao Stone%' or p.party_name ilike '%Dong Nhan%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'laos_update_20261015'
order by 1, 4, 2;
