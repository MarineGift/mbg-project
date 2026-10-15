-- ============================================================
-- seed_20261014x_lebanon_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Lebanon update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'LB check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: Lebanese Calcium Carbonate (Amchit), Microfillers
--    (Al Koura). No PCC plant found. Not added: Roky Plast (plastics),
--    traders, Jordanian suppliers (separate country).
-- 2) Mills if missing + plant blocks, priority 1-5:
--      1 Unipak Tissue Mill (INDEVCO, 22 kt)  2 MIMOSA (15 kt tissue)
--      3 SICOMO (25 kt board)  4 Solicar  5 SIPCO
--    Converters (UNIPAK boxes, Sanita, Perla, Gemayel) not added.
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
       v.party_name, 'LB', v.region, v.city, v.website, 'active', 'lebanon_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Lebanese Calcium Carbonate S.A.L.', '%Carbonate de Calcium Libanais%', 'Mount Lebanon', 'Amchit', null, '1996년 설립 Amchit 의 Société du Carbonate de Calcium Libanais S.A.L. 탄산칼슘·황산칼슘 제조, 클링커 분쇄.', 'Société du Carbonate de Calcium Libanais S.A.L. (founded 1996), Amchit, Jbeil - calcium carbonate and calcium sulphate, clinker grinding.', 'LB check 2026-10-14: about 21-50 staff (older data). Paper-grade spec, wet grinding and capacity not public. Contact per directory +961 9 622327, carbonat_co@hotmail.com. No PCC plant found in Lebanon (the firm called PCC is ready-mix concrete).'),
  ('Microfillers Ltd.', '%Microfillers%', 'North Lebanon', 'Al Koura', null, '북부 레바논 Al Koura 의 미분화 탄산칼슘 생산업체 Microfillers.', 'Microfillers Ltd., Al Koura, North Lebanon - micronised calcium carbonate.', 'LB check 2026-10-14: registered at 2514 Tripoli El Mina, +961 6 416737, contact Nabil Habib (older directory). Running status, paper supply and capacity unknown. Roky Plast (plastics masterbatch) and traders not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%LB check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Lebanese Calcium Carbonate S.A.L.', '%Carbonate de Calcium Libanais%', 'Mount Lebanon', 'Amchit', null, '1996년 설립 Amchit 의 Société du Carbonate de Calcium Libanais S.A.L. 탄산칼슘·황산칼슘 제조, 클링커 분쇄.', 'Société du Carbonate de Calcium Libanais S.A.L. (founded 1996), Amchit, Jbeil - calcium carbonate and calcium sulphate, clinker grinding.', 'LB check 2026-10-14: about 21-50 staff (older data). Paper-grade spec, wet grinding and capacity not public. Contact per directory +961 9 622327, carbonat_co@hotmail.com. No PCC plant found in Lebanon (the firm called PCC is ready-mix concrete).'),
  ('Microfillers Ltd.', '%Microfillers%', 'North Lebanon', 'Al Koura', null, '북부 레바논 Al Koura 의 미분화 탄산칼슘 생산업체 Microfillers.', 'Microfillers Ltd., Al Koura, North Lebanon - micronised calcium carbonate.', 'LB check 2026-10-14: registered at 2514 Tripoli El Mina, +961 6 416737, contact Nabil Habib (older directory). Running status, paper supply and capacity unknown. Roky Plast (plastics masterbatch) and traders not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'lebanon_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Lebanese Calcium Carbonate S.A.L.', 'GCC producer', 'Lebanon GCC - specs to confirm', 'merchant', 'C', 'gcc'),
  ('Microfillers Ltd.', 'GCC producer', 'Lebanon micronised GCC', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'lebanon_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'LB', v.region, v.city, v.website, 'active', 'lebanon_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Unipak Tissue%', '%UTM%Halat%', 'Unipak Tissue Mill (Halat)', 'Mount Lebanon', 'Halat', 'https://www.indevcopapermaking.com', 'INDEVCO Group 제지사업부의 Unipak Tissue Mill(1995년 설립, Halat). Beloit PM1(1,500 m/min, 폭 2.7m) 연 2.2만 t, 버진·재생 티슈 점보롤.', 'Unipak Tissue Mill (INDEVCO Paper Making, founded 1995), Halat, Jbeil - Beloit PM1 at 1,500 m/min, 2.7 m, about 22,000 t/yr, virgin and recycled tissue jumbo rolls for converters in Europe, US, Middle East and Africa.', 'LB check 2026-10-14: PM2 moved to Egypt 2012 - older 30,000-32,000 t figures included it. INDEVCO tissue in Lebanon plus Egypt (Interstate Paper Industries) over 90,000 t/yr (2025). Group CEO Neemat Frem, INDEVCO Paper Making president Imad Issa El Khoury. Contact per report +961 9 478911, tissuemill@utmlb.com, papermaking@indevcogroup.com.'),
  ('%Mimosa%', '%Sanitary Paper%', 'Sanitary Paper Co. - MIMOSA (Zahle)', 'Bekaa', 'Qaa El Rim', null, '베카 Zahle Qaa El Rim 의 Sanitary Paper Co.(MIMOSA). Toscotec 티슈기 PM4(7,000 t)·PM5(8,000 t), 연 1.5만 t.', 'Sanitary Paper Co. (MIMOSA), Qaa El Rim, Zahle, Bekaa - Toscotec tissue machines PM4 (7,000 t/yr) and PM5 (8,000 t/yr), 15,000 t/yr.', 'LB check 2026-10-14: registry also lists board and packaging - tell tissue base-paper lines apart and converting. Contact per report +961 8 823600, info@mimosa.com.lb.'),
  ('%Sicomo%', '%Sicomo%', 'SICOMO (Kab Elias)', 'Bekaa', 'Kab Elias', 'https://www.sicomo.com.lb', '1974년 설립 베카 Kab Elias 의 SICOMO. 재생 폐지 판지(SICOGREY·SICOWITE·SICOPLEX·SICOCORE·SICOPET), 연 약 2.5만 t, 폐수 재활용·폐기물 에너지화.', 'SICOMO (founded 1974), Kab Elias, Bekaa - recycled-fibre board (SICOGREY, SICOWITE, SICOPLEX, SICOCORE, SICOPET), about 25,000 t/yr, water recycling and waste-to-energy.', 'LB check 2026-10-14: own machine since 1975, raised to 80 t/day 2000-2005. Contact per report +961 8 500550, sicomo@sicomo.com.lb.'),
  ('%Solicar%', '%Libanaise de Carton%', 'Solicar (Wadi Chahrour)', 'Mount Lebanon', 'Wadi Chahrour', 'https://www.solicar.com', '1964년 설립 Wadi Chahrour 의 Solicar(Société Libanaise de Carton). 100% 재생 폐지 테스트라이너·골심지·화이트 테스트라이너·그레이보드.', 'Solicar (Société Libanaise de Carton, founded 1964), Wadi Chahrour - 100 pct recovered-paper testliner, fluting, white testliner, grey board, duplex.', 'LB check 2026-10-14: about 40,000-42,000 t/yr reported in 2010 - not current. Ownership tie to Gemayel Frères (packaging). Contact per report +961 5 943000.'),
  ('%Sipco%', '%Industrielle de Papier%', 'SIPCO (Kfarchima)', 'Mount Lebanon', 'Kfarchima', 'https://www.sipco.co', '1965년 설립 Kfarchima 의 SIPCO. 재생 듀플렉스 판지(225~475 gsm)·적층판지·계란 트레이, 인근국 수출.', 'SIPCO (Société Industrielle de Papier et de Carton, founded 1965), Kfarchima - recycled duplex board (225-475 gsm), laminated board and egg trays, exports in the region.', 'LB check 2026-10-14: capacity not published. Contact per report +961 5 433553, sipco@sipco.co.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LB'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LB check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LB'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Unipak Tissue%', '%UTM%Halat%', '%Unipak%', 'INDEVCO Group 제지사업부의 Unipak Tissue Mill(1995년 설립, Halat). Beloit PM1(1,500 m/min, 폭 2.7m) 연 2.2만 t, 버진·재생 티슈 점보롤.', 'Unipak Tissue Mill (INDEVCO Paper Making, founded 1995), Halat, Jbeil - Beloit PM1 at 1,500 m/min, 2.7 m, about 22,000 t/yr, virgin and recycled tissue jumbo rolls for converters in Europe, US, Middle East and Africa.', 'LB check 2026-10-14: PM2 moved to Egypt 2012 - older 30,000-32,000 t figures included it. INDEVCO tissue in Lebanon plus Egypt (Interstate Paper Industries) over 90,000 t/yr (2025). Group CEO Neemat Frem, INDEVCO Paper Making president Imad Issa El Khoury. Contact per report +961 9 478911, tissuemill@utmlb.com, papermaking@indevcogroup.com.'),
  ('%Mimosa%', '%Sanitary Paper%', '%Mimosa%', '베카 Zahle Qaa El Rim 의 Sanitary Paper Co.(MIMOSA). Toscotec 티슈기 PM4(7,000 t)·PM5(8,000 t), 연 1.5만 t.', 'Sanitary Paper Co. (MIMOSA), Qaa El Rim, Zahle, Bekaa - Toscotec tissue machines PM4 (7,000 t/yr) and PM5 (8,000 t/yr), 15,000 t/yr.', 'LB check 2026-10-14: registry also lists board and packaging - tell tissue base-paper lines apart and converting. Contact per report +961 8 823600, info@mimosa.com.lb.'),
  ('%Sicomo%', '%Sicomo%', '%Sicomo%', '1974년 설립 베카 Kab Elias 의 SICOMO. 재생 폐지 판지(SICOGREY·SICOWITE·SICOPLEX·SICOCORE·SICOPET), 연 약 2.5만 t, 폐수 재활용·폐기물 에너지화.', 'SICOMO (founded 1974), Kab Elias, Bekaa - recycled-fibre board (SICOGREY, SICOWITE, SICOPLEX, SICOCORE, SICOPET), about 25,000 t/yr, water recycling and waste-to-energy.', 'LB check 2026-10-14: own machine since 1975, raised to 80 t/day 2000-2005. Contact per report +961 8 500550, sicomo@sicomo.com.lb.'),
  ('%Solicar%', '%Libanaise de Carton%', '%Solicar%', '1964년 설립 Wadi Chahrour 의 Solicar(Société Libanaise de Carton). 100% 재생 폐지 테스트라이너·골심지·화이트 테스트라이너·그레이보드.', 'Solicar (Société Libanaise de Carton, founded 1964), Wadi Chahrour - 100 pct recovered-paper testliner, fluting, white testliner, grey board, duplex.', 'LB check 2026-10-14: about 40,000-42,000 t/yr reported in 2010 - not current. Ownership tie to Gemayel Frères (packaging). Contact per report +961 5 943000.'),
  ('%Sipco%', '%Industrielle de Papier%', '%Sipco%', '1965년 설립 Kfarchima 의 SIPCO. 재생 듀플렉스 판지(225~475 gsm)·적층판지·계란 트레이, 인근국 수출.', 'SIPCO (Société Industrielle de Papier et de Carton, founded 1965), Kfarchima - recycled duplex board (225-475 gsm), laminated board and egg trays, exports in the region.', 'LB check 2026-10-14: capacity not published. Contact per report +961 5 433553, sipco@sipco.co.')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'lebanon_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LB'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Unipak Tissue%', '%UTM%Halat%', '%Unipak%'),
  ('%Mimosa%', '%Sanitary Paper%', '%Mimosa%'),
  ('%Sicomo%', '%Sicomo%', '%Sicomo%'),
  ('%Solicar%', '%Libanaise de Carton%', '%Solicar%'),
  ('%Sipco%', '%Industrielle de Papier%', '%Sipco%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LB'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Unipak Tissue%', '%UTM%Halat%', '%Unipak%',
   $pj${"owner": "INDEVCO Group - INDEVCO Paper Making", "priority": 1, "products": "Virgin and recycled facial, toilet, napkin and towel tissue jumbo rolls", "grades": ["Facial tissue", "Toilet tissue", "Towel"], "machines": 1, "capacity_split": [{"label": "PM1 (MET 2026)", "value_t": 22000}], "pitch": "Tissue FCC on virgin grades first (3-5 pct pulp replacement) using MBG 5 pct tissue data", "approach": "Approach INDEVCO Paper Making centrally - a win can extend to Interstate Paper Industries (Egypt) and UNIPAKHELLAS (Greece).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "MET Issue 69 (2026)"}, {"label": "INDEVCO news 2025, 2026"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Mimosa%', '%Sanitary Paper%', '%Mimosa%',
   $pj${"owner": "Sanitary Paper Co. (MIMOSA)", "priority": 2, "products": "Toilet and facial tissue base paper and hygiene paper", "grades": ["Tissue"], "machines": 2, "capacity_split": [{"label": "PM4 + PM5", "value_t": 15000}], "pitch": "Small-scale tissue pilot at 3 and 5 pct FCC", "approach": "Local owner - shorter decision path for a trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Sicomo%', '%Sicomo%', '%Sicomo%',
   $pj${"owner": "SICOMO", "priority": 3, "products": "Grey, white and packaging board, coreboard", "grades": ["White board", "Grey board"], "capacity_split": [{"label": "Company figure", "value_t": 25000}], "pitch": "White and premium packaging board first", "approach": "Check ply bond, stiffness, coatability and the ash already in recovered paper.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Solicar%', '%Libanaise de Carton%', '%Solicar%',
   $pj${"owner": "Solicar (Gemayel Fr\u00e8res related)", "priority": 4, "products": "Testliner, fluting, white testliner, grey board, duplex", "grades": ["White testliner", "Testliner"], "capacity_split": [{"label": "2010 reported output (historical)", "value_t": 40000}], "approach": "White testliner and duplex first - fluting is compression critical.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Sipco%', '%Industrielle de Papier%', '%Sipco%',
   $pj${"owner": "SIPCO", "priority": 5, "products": "Recycled duplex board, laminated board, egg trays", "grades": ["Duplex board"], "approach": "Trial on uncoated grey back and duplex - egg trays are moulded pulp, separate question.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Unipak Tissue%', '%UTM%Halat%', '%Unipak%'),
  ('%Mimosa%', '%Sanitary Paper%', '%Mimosa%'),
  ('%Sicomo%', '%Sicomo%', '%Sicomo%'),
  ('%Solicar%', '%Libanaise de Carton%', '%Solicar%'),
  ('%Sipco%', '%Industrielle de Papier%', '%Sipco%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'lebanon_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LB'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'lebanon_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Carbonate de Calcium Libanais%' or p.party_name ilike '%Microfillers%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'lebanon_update_20261014'
order by 1, 4, 2;
