-- ============================================================
-- seed_20261014ai_png_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Papua New Guinea update (reports 2026-10). LOW PRIORITY. Introduction ->
-- intro_ko / intro_en (only when empty), detail -> notes once with
-- 'PG check 2026-10-14', plant data -> Mill profile card.
--
-- 1) Fillers if missing: Bayawaha Limestone (99.8 pct CaCO3, feed grade),
--    Pacific Lime and Cement (quicklime project, first output 1H 2027).
--    No paper PCC or GCC plant in PNG.
-- 2) Mills if missing + plant blocks: 1 KK Kingston (past paper mill)
--    2 Star Mountain Paper  3 Niugini Paper - own paper machines to confirm.
--    context: Amalpack (box converter). Lae Packaging (plastic bags) not added.
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
       v.party_name, 'PG', v.region, v.city, v.website, 'active', 'png_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Bayawaha Limestone Company', '%Bayawaha%', 'Morobe', 'Bulolo', null, '모로베 Bulolo Buang 의 Bayawaha Limestone. 순도 99.8% 탄산칼슘(사료용)·광산용 소석회, ML28 광업권.', 'Bayawaha Limestone Company, Buang, Bulolo, Morobe - 99.8 pct calcium carbonate for animal feed and hydrated lime for mines (Mainland Holdings, K92, Harmony Gold), licence ML28.', 'PG check 2026-10-14: long-term capacity 600,000 t/yr stated, about 25 staff (The National 2026-06). 2020 resource estimate about 154.5 Mt across four blocks (97.4 pct CaCO3 in Block A). Paper brightness, impurities and fine grinding not checked. Julie Towak Yakam.'),
  ('Pacific Lime and Cement', '%Pacific Lime%', 'Central', 'Port Moresby', null, 'Pacific Lime and Cement(구 Mayur Resources, ASX PLA). 포트모르즈비 인근 Central Lime Project — 석회석 3.82억 t, 생석회 소성로 2기(각 600 t/일), 2027 상반기 첫 생산 목표.', 'Pacific Lime and Cement (formerly Mayur Resources, ASX: PLA, PNGX: PLC) - Central Lime Project at Kido and Rea Rea near Port Moresby, 382 Mt JORC limestone, two 600 t/day quicklime kilns, own export wharf, first output targeted 1H 2027.', 'PG check 2026-10-14: FID 2025-08, construction 2026. Mining, water treatment and construction lime - no paper PCC plant. Possible PCC raw-material partner long term. No Omya, MTI or Artemyn plant in PNG.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%PG check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Bayawaha Limestone Company', '%Bayawaha%', 'Morobe', 'Bulolo', null, '모로베 Bulolo Buang 의 Bayawaha Limestone. 순도 99.8% 탄산칼슘(사료용)·광산용 소석회, ML28 광업권.', 'Bayawaha Limestone Company, Buang, Bulolo, Morobe - 99.8 pct calcium carbonate for animal feed and hydrated lime for mines (Mainland Holdings, K92, Harmony Gold), licence ML28.', 'PG check 2026-10-14: long-term capacity 600,000 t/yr stated, about 25 staff (The National 2026-06). 2020 resource estimate about 154.5 Mt across four blocks (97.4 pct CaCO3 in Block A). Paper brightness, impurities and fine grinding not checked. Julie Towak Yakam.'),
  ('Pacific Lime and Cement', '%Pacific Lime%', 'Central', 'Port Moresby', null, 'Pacific Lime and Cement(구 Mayur Resources, ASX PLA). 포트모르즈비 인근 Central Lime Project — 석회석 3.82억 t, 생석회 소성로 2기(각 600 t/일), 2027 상반기 첫 생산 목표.', 'Pacific Lime and Cement (formerly Mayur Resources, ASX: PLA, PNGX: PLC) - Central Lime Project at Kido and Rea Rea near Port Moresby, 382 Mt JORC limestone, two 600 t/day quicklime kilns, own export wharf, first output targeted 1H 2027.', 'PG check 2026-10-14: FID 2025-08, construction 2026. Mining, water treatment and construction lime - no paper PCC plant. Possible PCC raw-material partner long term. No Omya, MTI or Artemyn plant in PNG.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'png_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Bayawaha Limestone Company', 'GCC producer', 'PNG high-purity carbonate - GCC upgrade candidate', 'merchant', 'C', 'gcc'),
  ('Pacific Lime and Cement', 'Lime producer', 'PNG quicklime project - PCC raw material', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'png_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'PG', v.region, v.city, v.website, 'active', 'png_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Kingston%', '%KK Kingston%', 'KK Kingston - Paper Products (Lae)', 'Morobe', 'Lae', 'https://www.kingston.com.pg', '1972년 설립 라에의 KK Kingston. 1996년 종이제품 사업 시작, 화장지·종이타월·냅킨(KleenSorb 등), 과거 PNG 최대 종이공장 운영.', 'KK Kingston Limited (founded 1972 by Keith Kingston), Milford Haven Road, Lae - paper products since 1996, toilet tissue, towels and napkins (KleenSorb, Nature Soft, Wanbel), ran the largest PNG paper mill.', 'PG check 2026-10-14: over 14.5m rolls of toilet tissue in 2015, about 40 mill staff then (The National 2016). Used paper machine bought in the 1990s - current base-paper making not confirmed. +675 472 2745, commercialsales_lae@kingston.com.pg.'),
  ('%Star Mountain Paper%', '%Star Mountain%', 'Star Mountain Paper Corporation (Lae)', 'Morobe', 'Lae', null, '라에 Malahang 산업단지의 Star Mountain Paper. 화장지·종이제품·포장재 제조·유통 등록.', 'Star Mountain Paper Corporation, Malahang Industrial Centre, Lae (branch Hohola, Port Moresby) - registered for toilet tissue, paper products and packaging.', 'PG check 2026-10-14: own paper machine not confirmed. Not the same company as Star Paper Mill (UAE). +675 472 1566, smpclaesales@gmail.com.'),
  ('%Niugini Paper%', '%Niugini Paper Corporation%', 'Niugini Paper Corporation (Port Moresby)', 'National Capital District', 'Port Moresby', null, '포트모르즈비(라에 지점)의 Niugini Paper Corporation. 화장지·종이제품 제조·유통.', 'Niugini Paper Corporation, Port Moresby with a Lae branch - toilet tissue and paper products.', 'PG check 2026-10-14: machine and capacity not public. +675 325 3211, npcpom@markham.com.pg.'),
  ('%Amalpack%', '%Amalpack Limited%', 'Amalpack (Lae)', 'Morobe', 'Lae', null, '1968년 설립 라에의 Amalpack(Nasfund 주주). PNG 최대 골판지 상자 제조사.', 'Amalpack Limited (founded 1968, Nasfund among shareholders), Lot 175 Speybank St, Lae - largest PNG corrugated box maker, customers incl. Coca-Cola, SP Brewery, RD Tuna.', 'PG check 2026-10-14: converter - no paper machine found. Useful to trace its liner and medium suppliers. Lae Packaging Industries makes plastic film bags - not added.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PG'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PG check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PG'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Kingston%', '%KK Kingston%', '%Kingston%', '1972년 설립 라에의 KK Kingston. 1996년 종이제품 사업 시작, 화장지·종이타월·냅킨(KleenSorb 등), 과거 PNG 최대 종이공장 운영.', 'KK Kingston Limited (founded 1972 by Keith Kingston), Milford Haven Road, Lae - paper products since 1996, toilet tissue, towels and napkins (KleenSorb, Nature Soft, Wanbel), ran the largest PNG paper mill.', 'PG check 2026-10-14: over 14.5m rolls of toilet tissue in 2015, about 40 mill staff then (The National 2016). Used paper machine bought in the 1990s - current base-paper making not confirmed. +675 472 2745, commercialsales_lae@kingston.com.pg.'),
  ('%Star Mountain Paper%', '%Star Mountain%', '%Star Mountain%', '라에 Malahang 산업단지의 Star Mountain Paper. 화장지·종이제품·포장재 제조·유통 등록.', 'Star Mountain Paper Corporation, Malahang Industrial Centre, Lae (branch Hohola, Port Moresby) - registered for toilet tissue, paper products and packaging.', 'PG check 2026-10-14: own paper machine not confirmed. Not the same company as Star Paper Mill (UAE). +675 472 1566, smpclaesales@gmail.com.'),
  ('%Niugini Paper%', '%Niugini Paper Corporation%', '%Niugini%', '포트모르즈비(라에 지점)의 Niugini Paper Corporation. 화장지·종이제품 제조·유통.', 'Niugini Paper Corporation, Port Moresby with a Lae branch - toilet tissue and paper products.', 'PG check 2026-10-14: machine and capacity not public. +675 325 3211, npcpom@markham.com.pg.'),
  ('%Amalpack%', '%Amalpack Limited%', '%Amalpack%', '1968년 설립 라에의 Amalpack(Nasfund 주주). PNG 최대 골판지 상자 제조사.', 'Amalpack Limited (founded 1968, Nasfund among shareholders), Lot 175 Speybank St, Lae - largest PNG corrugated box maker, customers incl. Coca-Cola, SP Brewery, RD Tuna.', 'PG check 2026-10-14: converter - no paper machine found. Useful to trace its liner and medium suppliers. Lae Packaging Industries makes plastic film bags - not added.')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'png_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PG'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Kingston%', '%KK Kingston%', '%Kingston%'),
  ('%Star Mountain Paper%', '%Star Mountain%', '%Star Mountain%'),
  ('%Niugini Paper%', '%Niugini Paper Corporation%', '%Niugini%'),
  ('%Amalpack%', '%Amalpack Limited%', '%Amalpack%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PG'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Kingston%', '%KK Kingston%', '%Kingston%',
   $pj${"owner": "KK Kingston", "priority": 1, "products": "Toilet tissue, paper towel, napkins", "grades": ["Tissue"], "approach": "Confirm first whether the paper machine still runs - only then an FCC tissue trial.", "to_collect": ["Does the mill make tissue base paper out of pulp now, or convert imported jumbo rolls", "Machine output (t/day), speed and furnish", "Recycled versus virgin pulp, filler use if any", "Interest in an FCC trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Star Mountain Paper%', '%Star Mountain%', '%Star Mountain%',
   $pj${"owner": "Star Mountain Paper Corporation", "priority": 2, "products": "Toilet tissue, paper products, packaging", "grades": ["Tissue"], "approach": "Confirm own base-paper making.", "to_collect": ["Does the mill make tissue base paper out of pulp now, or convert imported jumbo rolls", "Machine output (t/day), speed and furnish", "Recycled versus virgin pulp, filler use if any", "Interest in an FCC trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Niugini Paper%', '%Niugini Paper Corporation%', '%Niugini%',
   $pj${"owner": "Niugini Paper Corporation", "priority": 3, "products": "Toilet tissue, paper products", "grades": ["Tissue"], "approach": "Confirm base-paper making and supply origin.", "to_collect": ["Does the mill make tissue base paper out of pulp now, or convert imported jumbo rolls", "Machine output (t/day), speed and furnish", "Recycled versus virgin pulp, filler use if any", "Interest in an FCC trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Amalpack%', '%Amalpack Limited%', '%Amalpack%',
   $pj${"owner": "Amalpack", "products": "Corrugated boxes (converting)", "approach": "Not an FCC user - ask which mills supply its liner and medium.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Kingston%', '%KK Kingston%', '%Kingston%'),
  ('%Star Mountain Paper%', '%Star Mountain%', '%Star Mountain%'),
  ('%Niugini Paper%', '%Niugini Paper Corporation%', '%Niugini%'),
  ('%Amalpack%', '%Amalpack Limited%', '%Amalpack%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'png_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PG'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'png_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Bayawaha%' or p.party_name ilike '%Pacific Lime%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'png_update_20261014'
order by 1, 4, 2;
