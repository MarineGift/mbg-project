-- ============================================================
-- seed_20261015t_guatemala_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Guatemala update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'GT check 2026-10-15',
-- plant data -> Mill profile card. Existing GT rows matched first
-- (name regex OR city + owner regex).
--
-- 1) Fillers if missing (6): GUAMINSA, Proservi, PROMISA, Mineral Resources
--    de Guatemala, Tercerón, EXGUAMISA. No PCC plant. Calera San Miguel and
--    Minerales y Agregados not added.
-- 2) Mills if missing (3) + plant blocks, priority 1-3: GrandBay PAINSA
--    Río Hondo, Papelera del Pacífico, COPACASA. Context, match only:
--    Kimberly-Clark Guatemala, CARTOGUA, Empresas Galindo (converters).
-- 3) No supply links (none public).
-- 4) app.country_markets GT row (priority medium).
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
       v.party_name, 'GT', v.region, v.city, v.website, 'active', 'guatemala_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('guaminsa|guatemalteca de minerales', 'GUAMINSA (Guatemalteca de Minerales)', 'Guatemala', 'Guatemala City', null, '과테말라 현지 탄산칼슘 제조사. 고백색 채석 원료, 조립~극초미립 제품군, 적용 분야에 제지 명시.', 'Guatemalteca de Minerales S.A. (GUAMINSA) - natural calcium carbonate made of high-white quarry stone, coarse to extra-ultrafine grades, paper named as a market. Office 46 Calle 18-11 Zona 12, Ofibodegas Petapa II, Guatemala City.', 'GT check 2026-10-15: +502 2477-7073. Wet slurry, d50 / d90, capacity and paper customers not public. FCC co-development candidate 1.'),
  ('proservi', 'Proservi S.A.', 'Guatemala', 'San Juan Sacatepéquez', null, '미세·초미세 탄산칼슘(Extra Fino RC·Fino·Azúcar·Granza) 업체. 제지용(백색도·불투명도) 명시.', 'Proservi S.A., Lote 5A, Sector Cementerio, Aldea Lo de Mejía I, San Juan Sacatepéquez - fine and extra-fine calcium carbonate (Extra Fino RC, Fino, Azúcar, Granza), paper named for brightness and opacity, also plastics, rubber, adhesives, agriculture.', 'GT check 2026-10-15: +502 4982-6402, p.proservi@grupoprocomsa.com. Mill customers, classifying and slurry capability not public.'),
  ('\mpromisa\M', 'PROMISA', 'Guatemala', null, null, '1972년 설립 과테말라 산업광물 미분화 기업. ProCarb(탄산칼슘)·ProTalc·ProKao·ProSilica·ProBent·ProBar, 공장 실험실 보유.', 'PROMISA (founded 1972) - micronised industrial minerals for Guatemala and Central America: ProCarb calcium carbonate, ProTalc, ProKao, ProSilica, ProBent, ProBar, plant laboratory.', 'GT check 2026-10-15: direct paper supply not confirmed. Grinding and blending lines could host FCC production.'),
  ('mineral resources.*guatemala', 'Mineral Resources de Guatemala S.A.', 'Guatemala', 'Villa Nueva', null, 'Minerali Industriali(이탈리아) 계열. Villa Nueva 건식 분쇄 200~400 mesh, 전 광물 합산 연 3만 t.', 'Mineral Resources de Guatemala S.A. (Minerali Industriali, Italy) - dry grinding and air classification at Parque Industrial Las Américas, Zona 4, Villa Nueva, 200-400 mesh, about 30,000 t/yr across calcium carbonate, silica, feldspar and barite.', 'GT check 2026-10-15: 30 kt is all minerals, not GCC only - grades coarse for paper filler, extra fine grinding needed. +502 6204-5134.'),
  ('tercer[oó]n', 'Tercerón S.A.', 'Chiquimula', 'Chiquimula', null, 'Chiquimula 의 산업광물 업체(석회석·탄산칼슘·벤토나이트·적철석). 탄산칼슘을 제지 충전제로 명시.', 'Tercerón S.A., Km 183 RD-CHI-01, Tierra Colorada, Chiquimula - limestone, calcium carbonate, bentonite, hematite, calcium carbonate named as filler for paint, plastics and paper.', 'GT check 2026-10-15: ventas@terceron.com, +502 3016-9866. High-white ultrafine volume not confirmed.'),
  ('exguamisa', 'EXGUAMISA S.A.', 'El Progreso', 'Morazán', null, 'El Progreso Morazán Cantera Corona 석회석·탄산칼슘 원료 업체. 주력 건설·시멘트·플라스틱.', 'EXGUAMISA S.A. - limestone and calcium carbonate at Cantera Corona, Morazán, El Progreso (about 105 km to the capital), main markets construction, cement, plastics.', 'GT check 2026-10-15: paper use not confirmed - raw-material source only. +502 2254-0710. Not added: Calera San Miguel (lime, Sanarate), Minerales y Agregados (Holcim stake, mortar and carbonate). No paper PCC plant in Guatemala.')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%GT check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('guaminsa|guatemalteca de minerales', 'GUAMINSA (Guatemalteca de Minerales)', 'Guatemala', 'Guatemala City', null, '과테말라 현지 탄산칼슘 제조사. 고백색 채석 원료, 조립~극초미립 제품군, 적용 분야에 제지 명시.', 'Guatemalteca de Minerales S.A. (GUAMINSA) - natural calcium carbonate made of high-white quarry stone, coarse to extra-ultrafine grades, paper named as a market. Office 46 Calle 18-11 Zona 12, Ofibodegas Petapa II, Guatemala City.', 'GT check 2026-10-15: +502 2477-7073. Wet slurry, d50 / d90, capacity and paper customers not public. FCC co-development candidate 1.'),
  ('proservi', 'Proservi S.A.', 'Guatemala', 'San Juan Sacatepéquez', null, '미세·초미세 탄산칼슘(Extra Fino RC·Fino·Azúcar·Granza) 업체. 제지용(백색도·불투명도) 명시.', 'Proservi S.A., Lote 5A, Sector Cementerio, Aldea Lo de Mejía I, San Juan Sacatepéquez - fine and extra-fine calcium carbonate (Extra Fino RC, Fino, Azúcar, Granza), paper named for brightness and opacity, also plastics, rubber, adhesives, agriculture.', 'GT check 2026-10-15: +502 4982-6402, p.proservi@grupoprocomsa.com. Mill customers, classifying and slurry capability not public.'),
  ('\mpromisa\M', 'PROMISA', 'Guatemala', null, null, '1972년 설립 과테말라 산업광물 미분화 기업. ProCarb(탄산칼슘)·ProTalc·ProKao·ProSilica·ProBent·ProBar, 공장 실험실 보유.', 'PROMISA (founded 1972) - micronised industrial minerals for Guatemala and Central America: ProCarb calcium carbonate, ProTalc, ProKao, ProSilica, ProBent, ProBar, plant laboratory.', 'GT check 2026-10-15: direct paper supply not confirmed. Grinding and blending lines could host FCC production.'),
  ('mineral resources.*guatemala', 'Mineral Resources de Guatemala S.A.', 'Guatemala', 'Villa Nueva', null, 'Minerali Industriali(이탈리아) 계열. Villa Nueva 건식 분쇄 200~400 mesh, 전 광물 합산 연 3만 t.', 'Mineral Resources de Guatemala S.A. (Minerali Industriali, Italy) - dry grinding and air classification at Parque Industrial Las Américas, Zona 4, Villa Nueva, 200-400 mesh, about 30,000 t/yr across calcium carbonate, silica, feldspar and barite.', 'GT check 2026-10-15: 30 kt is all minerals, not GCC only - grades coarse for paper filler, extra fine grinding needed. +502 6204-5134.'),
  ('tercer[oó]n', 'Tercerón S.A.', 'Chiquimula', 'Chiquimula', null, 'Chiquimula 의 산업광물 업체(석회석·탄산칼슘·벤토나이트·적철석). 탄산칼슘을 제지 충전제로 명시.', 'Tercerón S.A., Km 183 RD-CHI-01, Tierra Colorada, Chiquimula - limestone, calcium carbonate, bentonite, hematite, calcium carbonate named as filler for paint, plastics and paper.', 'GT check 2026-10-15: ventas@terceron.com, +502 3016-9866. High-white ultrafine volume not confirmed.'),
  ('exguamisa', 'EXGUAMISA S.A.', 'El Progreso', 'Morazán', null, 'El Progreso Morazán Cantera Corona 석회석·탄산칼슘 원료 업체. 주력 건설·시멘트·플라스틱.', 'EXGUAMISA S.A. - limestone and calcium carbonate at Cantera Corona, Morazán, El Progreso (about 105 km to the capital), main markets construction, cement, plastics.', 'GT check 2026-10-15: paper use not confirmed - raw-material source only. +502 2254-0710. Not added: Calera San Miguel (lime, Sanarate), Minerales y Agregados (Holcim stake, mortar and carbonate). No paper PCC plant in Guatemala.')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
  and coalesce(p.source, '') <> 'guatemala_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('GUAMINSA (Guatemalteca de Minerales)', 'GCC producer', 'Local GCC, paper named - FCC partner candidate 1', 'merchant', 'C', 'gcc'),
  ('Proservi S.A.', 'GCC producer', 'Local GCC, paper named - FCC partner candidate 2', 'merchant', 'C', 'gcc'),
  ('PROMISA', 'GCC producer', 'Micronised minerals - production partner candidate', 'merchant', 'C', 'gcc'),
  ('Mineral Resources de Guatemala S.A.', 'GCC producer', 'Dry GCC - needs finer grinding for paper', 'merchant', 'C', 'gcc'),
  ('Tercerón S.A.', 'GCC producer', 'Local GCC, paper named', 'merchant', 'C', 'gcc'),
  ('EXGUAMISA S.A.', 'Carbonate raw material', 'Raw-material source only', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'guatemala_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'GT', v.region, v.city, v.website, 'active', 'guatemala_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('grandbay|papelera internacional|painsa', 'r[ií]o hondo|teculut', 'papelera|grandbay', 'GrandBay - Papelera Internacional (PAINSA), Río Hondo', 'Zacapa', 'Río Hondo', null, 'GrandBay Paper & Care Products 의 과테말라 법인 PAINSA(2007 인수). Río Hondo(Zacapa) 재생섬유·탈묵·티슈 초지, Guatemala City 가공. Rosal·Nube Blanca·Sanitisu. 2023 Toscotec PM7(6만 t+) 로 연 13만 t.', 'Papelera Internacional S.A. (PAINSA), GrandBay Paper and Care Products (bought 2007) - recycled fibre, deinking and tissue machines at Km 129 Ruta al Atlántico, Teculután / Río Hondo, Zacapa, converting in Guatemala City (Zona 17). Brands Rosal, Nube Blanca, Sanitisu. Toscotec AHEAD 2.2L PM7 (2023, over 60,000 t/yr, 5,500 mm, 2,200 m/min, steel Yankee) took capacity to about 130,000 t/yr.', 'GT check 2026-10-15: mill +502 7929-1304, main +502 2427-1300. 130 kt is the 2023 announcement - current output to confirm. Trials go to Río Hondo, not the city converting plant.'),
  ('papelera del pac[ií]fico|negocios consolidados del pac', 'retalhuleu', 'pac[ií]fico', 'Papelera del Pacífico (Retalhuleu)', 'Retalhuleu', 'Retalhuleu', null, '1978년 설립, 2001년부터 100% 재생원료 크라프트지·라이너·골심지·칩보드 생산(Negocios Consolidados del Pacífico). 중미·멕시코·카리브 수출.', 'Papelera del Pacífico (Negocios Consolidados del Pacífico S.A., since 1978) - 100 pct recycled kraft paper, liner, medium and chipboard since 2001, production at Carretera Litoral del Pacífico Km 185, Cantón Recuerdo Ocosito, Retalhuleu, exports to Central America, Mexico and the Caribbean.', 'GT check 2026-10-15: office 23 Avenida 32-29 Zona 12, Guatemala City, +502 2244-6969. Capacity not public.'),
  ('copacasa|centroamericana de papeles', 'escuintla', 'copacasa|sigmaq|laki', 'COPACASA (SigmaQ), Escuintla', 'Escuintla', 'Escuintla', null, 'SigmaQ / LAKI 계열 COPACASA. Escuintla 재생 칩보드·판지 초지공장, 약 1.6만 short t (2022).', 'Compañía Centroamericana de Papeles y Cartones S.A. (COPACASA), SigmaQ / LAKI group - recycled chipboard and paperboard machine at Escuintla, about 16,000 short t/yr (2022 credit rating report), fibre supplied by group box plants and OCC.', 'GT check 2026-10-15: 2024 LAKI filing confirms the machine, latest tonnage not given.')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GT check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('grandbay|papelera internacional|painsa', 'r[ií]o hondo|teculut', 'papelera|grandbay', 'GrandBay Paper & Care Products 의 과테말라 법인 PAINSA(2007 인수). Río Hondo(Zacapa) 재생섬유·탈묵·티슈 초지, Guatemala City 가공. Rosal·Nube Blanca·Sanitisu. 2023 Toscotec PM7(6만 t+) 로 연 13만 t.', 'Papelera Internacional S.A. (PAINSA), GrandBay Paper and Care Products (bought 2007) - recycled fibre, deinking and tissue machines at Km 129 Ruta al Atlántico, Teculután / Río Hondo, Zacapa, converting in Guatemala City (Zona 17). Brands Rosal, Nube Blanca, Sanitisu. Toscotec AHEAD 2.2L PM7 (2023, over 60,000 t/yr, 5,500 mm, 2,200 m/min, steel Yankee) took capacity to about 130,000 t/yr.', 'GT check 2026-10-15: mill +502 7929-1304, main +502 2427-1300. 130 kt is the 2023 announcement - current output to confirm. Trials go to Río Hondo, not the city converting plant.'),
  ('papelera del pac[ií]fico|negocios consolidados del pac', 'retalhuleu', 'pac[ií]fico', '1978년 설립, 2001년부터 100% 재생원료 크라프트지·라이너·골심지·칩보드 생산(Negocios Consolidados del Pacífico). 중미·멕시코·카리브 수출.', 'Papelera del Pacífico (Negocios Consolidados del Pacífico S.A., since 1978) - 100 pct recycled kraft paper, liner, medium and chipboard since 2001, production at Carretera Litoral del Pacífico Km 185, Cantón Recuerdo Ocosito, Retalhuleu, exports to Central America, Mexico and the Caribbean.', 'GT check 2026-10-15: office 23 Avenida 32-29 Zona 12, Guatemala City, +502 2244-6969. Capacity not public.'),
  ('copacasa|centroamericana de papeles', 'escuintla', 'copacasa|sigmaq|laki', 'SigmaQ / LAKI 계열 COPACASA. Escuintla 재생 칩보드·판지 초지공장, 약 1.6만 short t (2022).', 'Compañía Centroamericana de Papeles y Cartones S.A. (COPACASA), SigmaQ / LAKI group - recycled chipboard and paperboard machine at Escuintla, about 16,000 short t/yr (2022 credit rating report), fibre supplied by group box plants and OCC.', 'GT check 2026-10-15: 2024 LAKI filing confirms the machine, latest tonnage not given.'),
  ('kimberly.*guatemala', null, 'kimberly.*guatemala', null, null, 'GT check 2026-10-15: Hygiene products - local paper machine not confirmed - context only.'),
  ('cartogua|cartones de guatemala', null, 'cartogua|cartones de guatemala', null, null, 'GT check 2026-10-15: Corrugated boxes (Morales, Masagua), up to 20,000 t/month - converter, no paper machine found - context only.'),
  ('galindo', null, 'galindo', null, null, 'GT check 2026-10-15: Corrugated and recycled paper - Guatemala mill not confirmed - context only.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'guatemala_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('grandbay|papelera internacional|painsa', 'r[ií]o hondo|teculut', 'papelera|grandbay'),
  ('papelera del pac[ií]fico|negocios consolidados del pac', 'retalhuleu', 'pac[ií]fico'),
  ('copacasa|centroamericana de papeles', 'escuintla', 'copacasa|sigmaq|laki'),
  ('kimberly.*guatemala', null, 'kimberly.*guatemala'),
  ('cartogua|cartones de guatemala', null, 'cartogua|cartones de guatemala'),
  ('galindo', null, 'galindo')
  ) as v(name_rx, city_rx, owner_rx)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('grandbay|papelera internacional|painsa', 'r[ií]o hondo|teculut', 'papelera|grandbay',
   $pj${"owner": "GrandBay Paper and Care Products", "priority": 1, "products": "Toilet tissue, towels, napkins (recycled fibre)", "grades": ["Tissue"], "capacity": {"value": 130000, "unit": "metric_t", "year": "2023 announcement (incl. PM7)", "source": "grandbay / Toscotec"}, "capacity_split": [{"label": "Total 2023", "value_t": 130000}, {"label": "PM7 (2023)", "value_t": 60000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 80 pct x 5 pct - tissue rate unproven, trial at 1-5 pct."}, "pitch": "Recycled-fibre tissue FCC trial on PM7", "approach": "NDA, lab tests on their furnish, then pilot and PM7 trial - forming, creping and drying must be checked. Pair with GUAMINSA or Proservi as local GCC source.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera del pac[ií]fico|negocios consolidados del pac', 'retalhuleu', 'pac[ií]fico',
   $pj${"owner": "Papelera del Pacífico", "priority": 2, "products": "Recycled kraft paper, liner, medium, chipboard", "grades": ["Kraft paper", "Testliner", "Medium", "Chipboard"], "approach": "Packaging FCC - keep Mullen, ring crush and SCT while cutting fibre or basis weight. Get capacity first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('copacasa|centroamericana de papeles', 'escuintla', 'copacasa|sigmaq|laki',
   $pj${"owner": "SigmaQ / LAKI", "priority": 3, "products": "Recycled chipboard and paperboard", "grades": ["Chipboard", "Paperboard"], "capacity": {"value": 16000, "unit": "short_t", "year": "2022 credit rating report", "source": "SigmaQ"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 80 pct x 5 pct - strength and ply bond first."}, "approach": "Group-integrated (OCC, machine, box plants) - board strength and ply-bond trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*guatemala', null, 'kimberly.*guatemala',
   $pj${"owner": "Kimberly-Clark Guatemala", "products": "Hygiene products - local paper machine not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartogua|cartones de guatemala', null, 'cartogua|cartones de guatemala',
   $pj${"owner": "CARTOGUA", "products": "Corrugated boxes (Morales, Masagua), up to 20,000 t/month - converter, no paper machine found", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('galindo', null, 'galindo',
   $pj${"owner": "Empresas Galindo", "products": "Corrugated and recycled paper - Guatemala mill not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GT', 'Guatemala', 'medium',
   $cm$GrandBay PAINSA tissue (130 kt, Toscotec PM7) plus recycled packaging - local GCC grinders, no paper PCC$cm$,
   $cm$No paper PCC plant and no Omya or SMI site. Local GCC grinders name paper - GUAMINSA, Proservi, Tercerón - plus PROMISA and Mineral Resources de Guatemala (30 kt all minerals). Paper machines: GrandBay PAINSA tissue at Río Hondo (130 kt after the 2023 PM7), Papelera del Pacífico recycled kraft and board, COPACASA (SigmaQ) chipboard at Escuintla. CARTOGUA and others are box converters.$cm$,
   $cm${"fillers": "Local GCC: GUAMINSA and Proservi (paper named, partner candidates), PROMISA (micronising), Mineral Resources de Guatemala (Villa Nueva, 200-400 mesh, 30 kt all minerals), Tercerón (Chiquimula), EXGUAMISA (raw material). Not added: Calera San Miguel (lime), Minerales y Agregados (Holcim). No PCC plant, no Omya or SMI site found.", "mills": "GrandBay PAINSA Río Hondo tissue 130 kt (PM7 2023). Papelera del Pacífico Retalhuleu (recycled kraft, liner, medium, chipboard). COPACASA Escuintla (SigmaQ, about 16,000 short t). Converters, no paper machine found: CARTOGUA, Empresas Galindo, INDUPASA, PAPELCO, TATI. Kimberly-Clark Guatemala machine not confirmed.", "strategy": "GrandBay tissue trial first, then packaging at Papelera del Pacífico and COPACASA. Local GCC partner (GUAMINSA or Proservi) as licensed FCC producer - no licensee plant in the country.", "risks": "Small volumes, mostly recycled tissue and packaging. Local GCC specs unproven for paper.", "next_steps": ["NDA and lab tests with GrandBay PAINSA", "Ask GUAMINSA and Proservi for d50, brightness and mill customers", "Get Papelera del Pacífico capacity"], "key_numbers": [{"label": "GrandBay PAINSA", "value": "130 kt tissue (2023)"}, {"label": "COPACASA", "value": "about 16,000 short t (2022)"}, {"label": "Report scenario", "value": "5,780 t FCC, USD 86,700 royalty"}], "files": ["seed_20261015t_guatemala_mills_fillers"]}$cm$::jsonb,
   $cm$GrandBay PAINSA 티슈(13만 t, PM7) + 재생 포장지 — 현지 GCC 분쇄업체, 제지용 PCC 없음$cm$,
   $cm$Omya·SMI 거점과 제지용 PCC 공장 없음. 현지 GCC(GUAMINSA·Proservi 제지 명시)를 라이선스 생산 후보로. 1순위 GrandBay PAINSA Río Hondo 티슈, 2 Papelera del Pacífico 재생 크라프트·판지, 3 COPACASA(SigmaQ) 칩보드. CARTOGUA 등은 가공업체.$cm$,
   3468, 5780,
   $cm$GrandBay 13만 t + COPACASA 약 1.45만 t × 가동 80% × FCC 3~5% (보고서 시나리오, 티슈 투입률 미검증)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('grandbay|papelera internacional|painsa', 'r[ií]o hondo|teculut', 'papelera|grandbay'),
  ('papelera del pac[ií]fico|negocios consolidados del pac', 'retalhuleu', 'pac[ií]fico'),
  ('copacasa|centroamericana de papeles', 'escuintla', 'copacasa|sigmaq|laki'),
  ('kimberly.*guatemala', null, 'kimberly.*guatemala'),
  ('cartogua|cartones de guatemala', null, 'cartogua|cartones de guatemala'),
  ('galindo', null, 'galindo')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'guatemala_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'guatemala_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'guaminsa|guatemalteca de minerales' or p.party_name ~* 'proservi' or p.party_name ~* '\mpromisa\M' or p.party_name ~* 'mineral resources.*guatemala' or p.party_name ~* 'tercer[oó]n' or p.party_name ~* 'exguamisa')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'GT'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'GT'
union all
select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
       coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GT'
  and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
order by 1, 4, 2;
