-- ============================================================
-- seed_20261014ah_newzealand_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- New Zealand update (reports 2026-10). Introduction -> intro_ko /
-- intro_en (only when empty), detail -> notes once with
-- 'NZ check 2026-10-14', plant data -> Mill profile card.
--
-- 1) Fillers if missing: Omya New Zealand (Te Kuiti GCC), Graymont NZ.
-- 2) Mills if missing + plant blocks, priority 1-2: Whakatane Mill (FBB
--    150 kt), Essity Kawerau (tissue 55 kt). context, match only: Oji
--    Kinleith (PM6 closed 2025-06), Oji Penrose (closed 2024-12), Norske
--    Skog Tasman (closed 2021). Pan Pac and Oji Tasman (pulp only) not added.
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
       v.party_name, 'NZ', v.region, v.city, v.website, 'active', 'newzealand_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya New Zealand (Te Kuiti)', '%Omya%New Zealand%', 'Waikato', 'Te Kuiti', 'https://www.omya.com', 'Omya 의 뉴질랜드 Te Kuiti 광물 가공공장. 석회석·대리석 채석장, 건식·습식 분쇄 탄산칼슘, 2018년 연 10만 t 초과.', 'Omya Specialty Materials (New Zealand), 260 Hangatiki East Road, Te Kuiti - limestone and marble quarries and a mineral plant, dry and wet ground calcium carbonate, over 100,000 t/yr in 2018, serves paper among others.', 'NZ check 2026-10-14: 2018 Quarry Association visit figure - current paper-grade output and customers to confirm. Omya Multifill overlaps the FCC aim (partner and competitor). Tel 0800 822 802. Royalty licensee at Omya HQ level. No paper PCC plant found in NZ.'),
  ('Graymont New Zealand', '%Graymont%New Zealand%', 'Waikato', 'Hamilton', 'https://www.graymont.com', 'Graymont 뉴질랜드(2015년 McDonald''s Lime·Taylor''s Lime 인수). Oparure 채석장, Te Kuiti·Otorohanga 석회공장, Makareao(오타고) 고순도 석회석.', 'Graymont (NZ) - acquired McDonald''s Lime and Taylor''s Lime in 2015, Oparure quarry, Te Kuiti and Otorohanga lime plants, Makareao plant and quarry in Otago (limestone 96-99 pct CaCO3).', 'NZ check 2026-10-14: limestone, quick and hydrated lime - raw material for GCC or PCC, no paper PCC plant. Office Level 4, 214 Collingwood St, Hamilton, +64 7 839 3210. Sibelco (sells in NZ, no NZ plant found) and small NZ lime firms not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%NZ check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Omya New Zealand (Te Kuiti)', '%Omya%New Zealand%', 'Waikato', 'Te Kuiti', 'https://www.omya.com', 'Omya 의 뉴질랜드 Te Kuiti 광물 가공공장. 석회석·대리석 채석장, 건식·습식 분쇄 탄산칼슘, 2018년 연 10만 t 초과.', 'Omya Specialty Materials (New Zealand), 260 Hangatiki East Road, Te Kuiti - limestone and marble quarries and a mineral plant, dry and wet ground calcium carbonate, over 100,000 t/yr in 2018, serves paper among others.', 'NZ check 2026-10-14: 2018 Quarry Association visit figure - current paper-grade output and customers to confirm. Omya Multifill overlaps the FCC aim (partner and competitor). Tel 0800 822 802. Royalty licensee at Omya HQ level. No paper PCC plant found in NZ.'),
  ('Graymont New Zealand', '%Graymont%New Zealand%', 'Waikato', 'Hamilton', 'https://www.graymont.com', 'Graymont 뉴질랜드(2015년 McDonald''s Lime·Taylor''s Lime 인수). Oparure 채석장, Te Kuiti·Otorohanga 석회공장, Makareao(오타고) 고순도 석회석.', 'Graymont (NZ) - acquired McDonald''s Lime and Taylor''s Lime in 2015, Oparure quarry, Te Kuiti and Otorohanga lime plants, Makareao plant and quarry in Otago (limestone 96-99 pct CaCO3).', 'NZ check 2026-10-14: limestone, quick and hydrated lime - raw material for GCC or PCC, no paper PCC plant. Office Level 4, 214 Collingwood St, Hamilton, +64 7 839 3210. Sibelco (sells in NZ, no NZ plant found) and small NZ lime firms not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'newzealand_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya New Zealand (Te Kuiti)', 'GCC producer', 'Omya NZ GCC (dry and wet) - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Graymont New Zealand', 'Lime producer', 'NZ limestone and lime - raw material', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'newzealand_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'NZ', v.region, v.city, v.website, 'active', 'newzealand_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Whakat%Mill%', '%Whakatane Mill%', 'Whakatane Mill (Bay of Plenty)', 'Bay of Plenty', 'Whakatane', 'https://www.wml.biz', '베이오브플렌티 와카타네의 Whakatāne Mill(Power Paperboard 중심 투자자 그룹). 폴딩박스보드(FBB)·캐리어보드, 연 약 15만 t.', 'Whakatane Mill Limited (investor group led by Power Paperboard), Whakatane, Bay of Plenty - folding boxboard and carrier board, about 150,000 t/yr, target 200,000-210,000 t/yr after modernisation.', 'NZ check 2026-10-14: 150,000 t per EECA. Main NZ printing and packaging-paper mills have closed (Norske Skog Tasman 2021, Oji Penrose 2024-12, Oji Kinleith PM6 2025-06) - Whakatane is the key remaining board mill. Food-contact rules apply to food packaging grades.'),
  ('%Essity%Kawerau%', '%Essity%New Zealand%', 'Essity New Zealand - Kawerau Mill (Kawerau)', 'Bay of Plenty', 'Kawerau', 'https://www.essity.com', '카웨라우의 Essity 뉴질랜드 공장. 뉴질랜드 유일의 티슈 원지 현지 생산, 연 약 5.5만 t(Purex·Sorbent·Handee·Tork), 지열 증기 건조.', 'Essity New Zealand Kawerau Mill, Bay of Plenty - the only NZ maker of tissue base paper, about 55,000 t/yr (Purex, Sorbent, Handee, Tork), about 200 staff, geothermal-steam drying (about NZD 20m, 2025).', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NZ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NZ check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NZ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Whakat%Mill%', '%Whakatane Mill%', '%Whakat%', '베이오브플렌티 와카타네의 Whakatāne Mill(Power Paperboard 중심 투자자 그룹). 폴딩박스보드(FBB)·캐리어보드, 연 약 15만 t.', 'Whakatane Mill Limited (investor group led by Power Paperboard), Whakatane, Bay of Plenty - folding boxboard and carrier board, about 150,000 t/yr, target 200,000-210,000 t/yr after modernisation.', 'NZ check 2026-10-14: 150,000 t per EECA. Main NZ printing and packaging-paper mills have closed (Norske Skog Tasman 2021, Oji Penrose 2024-12, Oji Kinleith PM6 2025-06) - Whakatane is the key remaining board mill. Food-contact rules apply to food packaging grades.'),
  ('%Essity%Kawerau%', '%Essity%New Zealand%', '%Essity%', '카웨라우의 Essity 뉴질랜드 공장. 뉴질랜드 유일의 티슈 원지 현지 생산, 연 약 5.5만 t(Purex·Sorbent·Handee·Tork), 지열 증기 건조.', 'Essity New Zealand Kawerau Mill, Bay of Plenty - the only NZ maker of tissue base paper, about 55,000 t/yr (Purex, Sorbent, Handee, Tork), about 200 staff, geothermal-steam drying (about NZD 20m, 2025).', null),
  ('%Kinleith%', '%Oji%Kinleith%', '%Oji%', '토코로아의 Oji Fibre Solutions Kinleith 공장. 크라프트 라이너 PM6(약 33만 t) 2025-06 영구 정지, 펄프만 생산.', 'Oji Fibre Solutions Kinleith Mill, Tokoroa - kraft liner machine PM6 (about 330,000 t/yr) closed permanently 2025-06, pulp only now.', null),
  ('%Penrose%', '%Oji%Penrose%', '%Oji%', '오클랜드의 Oji Fibre Solutions Penrose 공장. 재생 골판지원지 약 8.5만 t, 2024-12 폐쇄.', 'Oji Fibre Solutions Penrose Mill, Auckland - recycled corrugating medium about 85,000 t/yr, closed 2024-12.', null),
  ('%Norske Skog%Tasman%', '%Tasman%Newsprint%', '%Norske%', '카웨라우의 Norske Skog Tasman 신문용지 공장 — 2021년 생산 종료.', 'Norske Skog Tasman, Kawerau - newsprint mill, production ended 2021.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'newzealand_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NZ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Whakat%Mill%', '%Whakatane Mill%', '%Whakat%'),
  ('%Essity%Kawerau%', '%Essity%New Zealand%', '%Essity%'),
  ('%Kinleith%', '%Oji%Kinleith%', '%Oji%'),
  ('%Penrose%', '%Oji%Penrose%', '%Oji%'),
  ('%Norske Skog%Tasman%', '%Tasman%Newsprint%', '%Norske%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NZ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Whakat%Mill%', '%Whakatane Mill%', '%Whakat%',
   $pj${"owner": "Power Paperboard investor group", "priority": 1, "products": "Folding boxboard, carrier board", "grades": ["Folding boxboard", "Carrier board"], "capacity_split": [{"label": "Current output (EECA)", "value_t": 150000}, {"label": "Modernisation target", "value_t": 205000}], "filler": [{"supplier": "Not confirmed", "type": "-", "status": "Unknown", "basis": "Omya Te Kuiti is the nearest local GCC maker"}], "pitch": "Fibre cost saving with ply bond, bending stiffness, fold and print quality held", "approach": "Lead NZ account. Ply-by-ply trial design. Ask current GCC / PCC use and supplier first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Essity%Kawerau%', '%Essity%New Zealand%', '%Essity%',
   $pj${"owner": "Essity", "priority": 2, "products": "Toilet tissue, paper towel, AfH (commercial) tissue", "grades": ["Tissue", "Towel"], "capacity_split": [{"label": "Output", "value_t": 55000}], "pitch": "Tissue FCC at 3-5 pct - pulp saving with softness, strength, dust and absorbency held", "approach": "Global Essity - a NZ trial could open other Essity mills.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kinleith%', '%Oji%Kinleith%', '%Oji%',
   $pj${"owner": "Oji Fibre Solutions (Oji Holdings)", "products": "Pulp (paper machine closed 2025-06)", "approach": "Excluded for FCC - no paper machine. Approach Oji at group level (Japan, Malaysia) instead.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Penrose%', '%Oji%Penrose%', '%Oji%',
   $pj${"owner": "Oji Fibre Solutions (Oji Holdings)", "products": "Formerly recycled corrugating medium", "approach": "Excluded - closed 2024-12.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Norske Skog%Tasman%', '%Tasman%Newsprint%', '%Norske%',
   $pj${"owner": "Norske Skog", "products": "Formerly newsprint", "approach": "Excluded - closed 2021.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Whakat%Mill%', '%Whakatane Mill%', '%Whakat%'),
  ('%Essity%Kawerau%', '%Essity%New Zealand%', '%Essity%'),
  ('%Kinleith%', '%Oji%Kinleith%', '%Oji%'),
  ('%Penrose%', '%Oji%Penrose%', '%Oji%'),
  ('%Norske Skog%Tasman%', '%Tasman%Newsprint%', '%Norske%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'newzealand_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NZ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'newzealand_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Omya%New Zealand%' or p.party_name ilike '%Graymont%New Zealand%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'newzealand_update_20261014'
order by 1, 4, 2;
