-- ============================================================
-- seed_20261016k_dominican_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Dominican Republic update (reports 2026-10-15, latest mill version used).
-- 1) Fillers if missing (5): Industrias GAT Haina, DOCALSA, INREGOSA,
--    Industrias Dominca, Belfond Barahona (raw limestone for INCOA, USA).
-- 2) Mills if missing (2) + plant blocks: César Iglesias Santo Domingo
--    (priority 1, PM1 + PM2), Industria del Papel Sido (priority 2).
--    Context, match only (13): INPADOM, INPACA, Nigua, Formosa, AG Supply,
--    Velvety, Kimberly-Clark, Familia, Cartones del Caribe, HUED, UPI,
--    Pico Duarte, Smurfit Westrock.
-- 3) app.country_markets DO row (priority medium).
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
           v.party_name, 'DO', v.region, v.city, v.website, 'active', 'dominican_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('^industrias gat|\mgat-?ii\M', 'Industrias GAT (GAT-II) - Haina', 'San Cristóbal', 'Haina', null, '1976년 설립 GCC 업체. Haina GAT-II 분쇄공장, Pomier GAT-TBS 골재. 2011 스웨덴 초미세 분쇄설비(2.5 μm 미만), 원석 CaCO3 99% 초과, 1984부터 수출. 종이용 나노 탄산칼슘(PNCC) 소개.', 'Industrias GAT S.A. (1976) - GAT-II carbonate grinding plant at Km 19.5 Autopista Sánchez, Haina, and GAT-TBS aggregates at Pomier (San Cristóbal). Swedish ultrafine mill since 2011 (under 2.5 micron), stone over 99 pct CaCO3, exports since 1984. Promotes nano calcium carbonate (PNCC) for paper, inks and coatings.', 'DO check 2026-10-15: PNCC process (precipitated or ground) not confirmed - not counted as PCC. +1 809-542-2171. Wet slurry and paper customers to confirm. FCC partner candidate 1.'),
  ('docalsa|dominicana de cales', 'DOCALSA (Dominicana de Cales) - El Pomier', 'San Cristóbal', 'El Pomier', null, '2000년 설립 석회·석회석·탄산칼슘 통합 업체(El Pomier). 2018 탄산칼슘 생산, 20·45·100 μm 등급, CaCO3 약 98%.', 'Dominicana de Cales S.A. (DOCALSA, 2000), Calle 1era, El Borbón, El Pomier (San Cristóbal) - quarry, limestone, quick and hydrated lime, calcium carbonate since 2018 in 20, 45 and 100 micron and 1.18 mm grades (about 98 pct CaCO3).', 'DO check 2026-10-15: coarse for paper - raw material or new wet line. comercial@docalsa.com, +1 809-368-1010.'),
  ('inregosa|reynoso gonell', 'INREGOSA (Industria Reynoso Gonell) - Santiago', 'Santiago', 'Santiago de los Caballeros', null, '1978년 설립 비금속 광물 분쇄 업체(Santiago). Carbonato de Calcio Fino Malla 325.', 'Industria Reynoso Gonell S.A. (INREGOSA, 1978), Carretera Licey, Santiago - non-metallic mineral grinding, Carbonato de Calcio Fino Malla 325 for paint, rubber, detergents, ceramics, agricultural lime.', 'DO check 2026-10-15: paper grades not confirmed. info@inregosa.com.'),
  ('industrias dominca', 'Industrias Dominca - Santiago', 'Santiago', 'Santiago de los Caballeros', null, '2021년 설립 탄산칼슘·드라이 모르타르 업체(Santiago).', 'Industrias Dominca (2021-03), Av. Circunvalación Norte Km 25, Santiago - calcium carbonate, dry mortar and tile adhesive for construction, paint, plastics and feed.', 'DO check 2026-10-15: scale and fineness not public. info@industriasdominca.com.'),
  ('belfond', 'Belfond Enterprise - Barahona', 'Barahona', 'Barahona', null, 'Barahona 고순도(99% 초과) 석회석 채굴·수출 — 미국 Alabama INCOA GCC 공장 원료.', 'Belfond Enterprise - mines over 99 pct CaCO3 limestone at Barahona and exports it, feeding the INCOA Performance Minerals GCC plant at Theodore, Alabama (InCal 3, 7, 11 and 1T grades).', 'DO check 2026-10-15: INCOA itself is a US plant - add under US if wanted. Raw-material source. Not added: GEOTEK Lime and Minerals (Boca Chica lime project, not producing).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%DO check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('^industrias gat|\mgat-?ii\M', 'Industrias GAT (GAT-II) - Haina', 'San Cristóbal', 'Haina', null, '1976년 설립 GCC 업체. Haina GAT-II 분쇄공장, Pomier GAT-TBS 골재. 2011 스웨덴 초미세 분쇄설비(2.5 μm 미만), 원석 CaCO3 99% 초과, 1984부터 수출. 종이용 나노 탄산칼슘(PNCC) 소개.', 'Industrias GAT S.A. (1976) - GAT-II carbonate grinding plant at Km 19.5 Autopista Sánchez, Haina, and GAT-TBS aggregates at Pomier (San Cristóbal). Swedish ultrafine mill since 2011 (under 2.5 micron), stone over 99 pct CaCO3, exports since 1984. Promotes nano calcium carbonate (PNCC) for paper, inks and coatings.', 'DO check 2026-10-15: PNCC process (precipitated or ground) not confirmed - not counted as PCC. +1 809-542-2171. Wet slurry and paper customers to confirm. FCC partner candidate 1.'),
  ('docalsa|dominicana de cales', 'DOCALSA (Dominicana de Cales) - El Pomier', 'San Cristóbal', 'El Pomier', null, '2000년 설립 석회·석회석·탄산칼슘 통합 업체(El Pomier). 2018 탄산칼슘 생산, 20·45·100 μm 등급, CaCO3 약 98%.', 'Dominicana de Cales S.A. (DOCALSA, 2000), Calle 1era, El Borbón, El Pomier (San Cristóbal) - quarry, limestone, quick and hydrated lime, calcium carbonate since 2018 in 20, 45 and 100 micron and 1.18 mm grades (about 98 pct CaCO3).', 'DO check 2026-10-15: coarse for paper - raw material or new wet line. comercial@docalsa.com, +1 809-368-1010.'),
  ('inregosa|reynoso gonell', 'INREGOSA (Industria Reynoso Gonell) - Santiago', 'Santiago', 'Santiago de los Caballeros', null, '1978년 설립 비금속 광물 분쇄 업체(Santiago). Carbonato de Calcio Fino Malla 325.', 'Industria Reynoso Gonell S.A. (INREGOSA, 1978), Carretera Licey, Santiago - non-metallic mineral grinding, Carbonato de Calcio Fino Malla 325 for paint, rubber, detergents, ceramics, agricultural lime.', 'DO check 2026-10-15: paper grades not confirmed. info@inregosa.com.'),
  ('industrias dominca', 'Industrias Dominca - Santiago', 'Santiago', 'Santiago de los Caballeros', null, '2021년 설립 탄산칼슘·드라이 모르타르 업체(Santiago).', 'Industrias Dominca (2021-03), Av. Circunvalación Norte Km 25, Santiago - calcium carbonate, dry mortar and tile adhesive for construction, paint, plastics and feed.', 'DO check 2026-10-15: scale and fineness not public. info@industriasdominca.com.'),
  ('belfond', 'Belfond Enterprise - Barahona', 'Barahona', 'Barahona', null, 'Barahona 고순도(99% 초과) 석회석 채굴·수출 — 미국 Alabama INCOA GCC 공장 원료.', 'Belfond Enterprise - mines over 99 pct CaCO3 limestone at Barahona and exports it, feeding the INCOA Performance Minerals GCC plant at Theodore, Alabama (InCal 3, 7, 11 and 1T grades).', 'DO check 2026-10-15: INCOA itself is a US plant - add under US if wanted. Raw-material source. Not added: GEOTEK Lime and Minerals (Boca Chica lime project, not producing).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'dominican_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Industrias GAT (GAT-II) - Haina', 'GCC producer', 'Ultrafine GCC - FCC partner candidate 1', 'merchant', 'C', 'gcc'),
  ('DOCALSA (Dominicana de Cales) - El Pomier', 'GCC and lime producer', 'Limestone, lime and coarse GCC', 'merchant', 'C', 'gcc'),
  ('INREGOSA (Industria Reynoso Gonell) - Santiago', 'GCC producer', '325 mesh GCC', 'merchant', 'C', 'gcc'),
  ('Industrias Dominca - Santiago', 'GCC producer', 'New GCC maker', 'merchant', 'C', 'gcc'),
  ('Belfond Enterprise - Barahona', 'Carbonate raw material', 'High-purity limestone for US GCC', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'dominican_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'DO', v.region, v.city, v.website, 'active', 'dominican_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('c[eé]sar iglesias', 'santo domingo', 'iglesias', 'César Iglesias - Santo Domingo', 'Santo Domingo', 'Santo Domingo', null, '1910년 설립 종합 소비재 기업의 티슈 초지공장(Dominó·Bingo). PM1(2019 Toscotec Steel Yankee) 약 1.5만 t, 신규 PM2 Toscotec AHEAD 1.8(2.8 m, 3만 t 초과) 2026 가동 목표. RD$15억 투자, 2025 Gambini Seicento 가공라인.', 'César Iglesias S.A. (1910), Av. Independencia 2403, Santo Domingo - tissue mill (Dominó, Bingo): PM1 with a Toscotec steel Yankee (2019), about 15,000 t/yr, and new PM2 Toscotec AHEAD 1.8 (2,800 mm, shoe press, full stock prep, over 30,000 t/yr) targeted for 2026 under an RD$1.5 bn investment. Gambini Seicento converting line chosen 2025-09. About 18 pct of retail tissue value (2025).', 'DO check 2026-10-15: PM2 start-up not confirmed. Technical Director named in the Toscotec release: Jesús Feris Ferrús (check current role). +1 809-535-5511.'),
  ('papel sido|\mips\M.*gu[aá]yiga', 'gu[aá]yiga|pedro brand', 'sido', 'Industria del Papel Sido - La Guáyiga', 'Santo Domingo', 'Pedro Brand', null, '1983년 설립 재활용 크라프트지·화장지·냅킨 제조사(La Guáyiga, Pedro Brand). 현지 폐지 원료, 약 80% 재활용, 아이티 수출.', 'Industria del Papel Sido (IPS, 1983), Autopista Duarte Km 22.5, La Guáyiga, Pedro Brand - recycled kraft paper, packaging paper, toilet tissue and napkins on locally collected waste paper (about 80 pct recycled), sells in the Dominican Republic and Haiti, 51-200 staff.', 'DO check 2026-10-15: site shows 6,480 t processed with no period - not used as capacity. Paper machine specs to confirm. info@papelsido.com, +1 809-561-5535.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%DO check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('c[eé]sar iglesias', 'santo domingo', 'iglesias', '1910년 설립 종합 소비재 기업의 티슈 초지공장(Dominó·Bingo). PM1(2019 Toscotec Steel Yankee) 약 1.5만 t, 신규 PM2 Toscotec AHEAD 1.8(2.8 m, 3만 t 초과) 2026 가동 목표. RD$15억 투자, 2025 Gambini Seicento 가공라인.', 'César Iglesias S.A. (1910), Av. Independencia 2403, Santo Domingo - tissue mill (Dominó, Bingo): PM1 with a Toscotec steel Yankee (2019), about 15,000 t/yr, and new PM2 Toscotec AHEAD 1.8 (2,800 mm, shoe press, full stock prep, over 30,000 t/yr) targeted for 2026 under an RD$1.5 bn investment. Gambini Seicento converting line chosen 2025-09. About 18 pct of retail tissue value (2025).', 'DO check 2026-10-15: PM2 start-up not confirmed. Technical Director named in the Toscotec release: Jesús Feris Ferrús (check current role). +1 809-535-5511.'),
  ('papel sido|\mips\M.*gu[aá]yiga', 'gu[aá]yiga|pedro brand', 'sido', '1983년 설립 재활용 크라프트지·화장지·냅킨 제조사(La Guáyiga, Pedro Brand). 현지 폐지 원료, 약 80% 재활용, 아이티 수출.', 'Industria del Papel Sido (IPS, 1983), Autopista Duarte Km 22.5, La Guáyiga, Pedro Brand - recycled kraft paper, packaging paper, toilet tissue and napkins on locally collected waste paper (about 80 pct recycled), sells in the Dominican Republic and Haiti, 51-200 staff.', 'DO check 2026-10-15: site shows 6,480 t processed with no period - not used as capacity. Paper machine specs to confirm. info@papelsido.com, +1 809-561-5535.'),
  ('inpadom|industria papelera dominicana', null, 'inpadom|industria papelera dominicana', null, null, 'DO check 2026-10-15: Household and hygiene paper (Los Alcarrizos, 2014) - machine not confirmed - context only.'),
  ('inpaca|industria papelera del caribe', null, 'inpaca|industria papelera del caribe', null, null, 'DO check 2026-10-15: Paper trading and products (Haina, Soft INPACA) - machine not confirmed - context only.'),
  ('industrias nigua', null, 'industrias nigua', null, null, 'DO check 2026-10-15: Tissue converter (Niveo, Gaviota, Apolo) - first toilet tissue plant 1960 - context only.'),
  ('formosa', null, 'formosa', null, null, 'DO check 2026-10-15: Toilet tissue, napkins, towels (Herrera) - machine not confirmed - context only.'),
  ('ag supply', null, 'ag supply', null, null, 'DO check 2026-10-15: Tissue converting, 400 t/month (Santiago) - context only.'),
  ('velvety', null, 'velvety', null, null, 'DO check 2026-10-15: Tissue products (Haina) - context only.'),
  ('kimberly.*dominic', null, 'kimberly.*dominic', null, null, 'DO check 2026-10-15: Hygiene products, 24 pct retail tissue share - no local machine found - context only.'),
  ('familia.*dominic', null, 'familia.*dominic', null, null, 'DO check 2026-10-15: Hygiene products (San Cristóbal) - local machine not confirmed - context only.'),
  ('cartones del caribe|cartocar', null, 'cartones del caribe|cartocar', null, null, 'DO check 2026-10-15: Corrugated boxes - imports US and Indian liner and medium - context only.'),
  ('hued', null, 'hued', null, null, 'DO check 2026-10-15: Corrugated boxes - converter - context only.'),
  ('cartonera upi', null, 'cartonera upi', null, null, 'DO check 2026-10-15: Export produce boxes - converter - context only.'),
  ('pico duarte', null, 'pico duarte', null, null, 'DO check 2026-10-15: Corrugated boxes (Haina) - imports raw materials - context only.'),
  ('smurfit.*dominic|smurfit.*itabo', null, 'smurfit.*dominic|smurfit.*itabo', null, null, 'DO check 2026-10-15: Corrugated packaging (Santo Domingo, Itabo) - no local paper machine found - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'dominican_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('c[eé]sar iglesias', 'santo domingo', 'iglesias'),
  ('papel sido|\mips\M.*gu[aá]yiga', 'gu[aá]yiga|pedro brand', 'sido'),
  ('inpadom|industria papelera dominicana', null, 'inpadom|industria papelera dominicana'),
  ('inpaca|industria papelera del caribe', null, 'inpaca|industria papelera del caribe'),
  ('industrias nigua', null, 'industrias nigua'),
  ('formosa', null, 'formosa'),
  ('ag supply', null, 'ag supply'),
  ('velvety', null, 'velvety'),
  ('kimberly.*dominic', null, 'kimberly.*dominic'),
  ('familia.*dominic', null, 'familia.*dominic'),
  ('cartones del caribe|cartocar', null, 'cartones del caribe|cartocar'),
  ('hued', null, 'hued'),
  ('cartonera upi', null, 'cartonera upi'),
  ('pico duarte', null, 'pico duarte'),
  ('smurfit.*dominic|smurfit.*itabo', null, 'smurfit.*dominic|smurfit.*itabo')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('c[eé]sar iglesias', 'santo domingo', 'iglesias',
   $pj${"owner": "César Iglesias", "priority": 1, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 15000, "unit": "metric_t", "year": "PM1 (2024 press)", "source": "Diario Libre"}, "capacity_split": [{"label": "PM1", "value_t": 15000}, {"label": "PM2 (2026 target)", "value_t": 30000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "On PM1 only - PM2 would add 900-1,500 t at 3-5 pct."}, "pitch": "FCC on the new PM2 - fibre saving with bulk, softness, absorbency kept", "approach": "Lead Caribbean account - approach the technical director about PM2 start-up trials.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "Toscotec PM2 order 2025-04", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papel sido|\mips\M.*gu[aá]yiga', 'gu[aá]yiga|pedro brand', 'sido',
   $pj${"owner": "Industria del Papel Sido", "priority": 2, "products": "Recycled kraft paper, toilet tissue, napkins", "grades": ["Kraft paper", "Tissue"], "approach": "Confirm the paper machine first - then recycled tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('inpadom|industria papelera dominicana', null, 'inpadom|industria papelera dominicana',
   $pj${"owner": "INPADOM", "products": "Household and hygiene paper (Los Alcarrizos, 2014) - machine not confirmed", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('inpaca|industria papelera del caribe', null, 'inpaca|industria papelera del caribe',
   $pj${"owner": "INPACA (Industria Papelera del Caribe)", "products": "Paper trading and products (Haina, Soft INPACA) - machine not confirmed", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('industrias nigua', null, 'industrias nigua',
   $pj${"owner": "Industrias Nigua", "products": "Tissue converter (Niveo, Gaviota, Apolo) - first toilet tissue plant 1960", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('formosa', null, 'formosa',
   $pj${"owner": "Grupo Formosa Industrial", "products": "Toilet tissue, napkins, towels (Herrera) - machine not confirmed", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('ag supply', null, 'ag supply',
   $pj${"owner": "AG Supply", "products": "Tissue converting, 400 t/month (Santiago)", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('velvety', null, 'velvety',
   $pj${"owner": "Velvety", "products": "Tissue products (Haina)", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*dominic', null, 'kimberly.*dominic',
   $pj${"owner": "Kimberly-Clark Dominicana", "products": "Hygiene products, 24 pct retail tissue share - no local machine found", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('familia.*dominic', null, 'familia.*dominic',
   $pj${"owner": "Productos Familia Dominicana", "products": "Hygiene products (San Cristóbal) - local machine not confirmed", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones del caribe|cartocar', null, 'cartones del caribe|cartocar',
   $pj${"owner": "Cartones del Caribe (GPG)", "products": "Corrugated boxes - imports US and Indian liner and medium", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('hued', null, 'hued',
   $pj${"owner": "Cartonera Alfredo HUED (GPG)", "products": "Corrugated boxes - converter", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartonera upi', null, 'cartonera upi',
   $pj${"owner": "Cartonera UPI (GPG)", "products": "Export produce boxes - converter", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('pico duarte', null, 'pico duarte',
   $pj${"owner": "Pico Duarte Cartón", "products": "Corrugated boxes (Haina) - imports raw materials", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('smurfit.*dominic|smurfit.*itabo', null, 'smurfit.*dominic|smurfit.*itabo',
   $pj${"owner": "Smurfit Westrock Dominican Republic", "products": "Corrugated packaging (Santo Domingo, Itabo) - no local paper machine found", "approach": "Converter or unconfirmed - trace base-paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'DO', 'Dominican Republic', 'medium',
   $cm$César Iglesias tissue (PM1 15 kt, new Toscotec PM2 30 kt+ for 2026) - local ultrafine GCC at Industrias GAT$cm$,
   $cm$César Iglesias runs a tissue mill in Santo Domingo (PM1 about 15 kt) and is adding a Toscotec PM2 of over 30 kt/yr for 2026. Industria del Papel Sido makes recycled kraft and tissue. Most others convert imported base paper (Nigua, Formosa, AG Supply) or boxes (Cartones del Caribe, Pico Duarte, Smurfit Westrock). Local carbonate: Industrias GAT (ultrafine GCC, Haina), DOCALSA, INREGOSA, Dominca, and Belfond high-purity limestone feeding INCOA in Alabama. No paper PCC plant. Retail tissue: Kimberly-Clark 24 pct, Familia, César Iglesias 18 pct.$cm$,
   $cm${"fillers": "GCC: Industrias GAT (2.5 micron ultrafine, 99 pct stone), DOCALSA (20-100 micron), INREGOSA (325 mesh), Industrias Dominca. Raw material: Belfond Barahona (over 99 pct, feeds INCOA Theodore AL). Not added: GEOTEK (lime project). No PCC plant.", "mills": "Tissue: César Iglesias Santo Domingo (PM1 + PM2 2026). Recycled kraft and tissue: Industria del Papel Sido. Unconfirmed: INPADOM, INPACA. Converters: Industrias Nigua, Grupo Formosa, AG Supply, Velvety, Kimberly-Clark, Familia, Cartones del Caribe, HUED, UPI, Pico Duarte, Smurfit Westrock.", "strategy": "César Iglesias PM2 start-up trial with Industrias GAT as local FCC producer. Converters lead to their foreign base-paper mills.", "risks": "Small volumes, PM2 start-up unconfirmed.", "next_steps": ["Contact César Iglesias technical on PM2", "Ask Industrias GAT about wet grinding and slurry"], "key_numbers": [{"label": "César Iglesias", "value": "PM1 about 15 kt + PM2 over 30 kt (2026)"}, {"label": "Retail tissue 2025", "value": "Kimberly-Clark 24, César Iglesias 18 pct"}, {"label": "D&B paper listings", "value": "55 (incl. converters)"}], "files": ["seed_20261016k_dominican_mills_fillers"]}$cm$::jsonb,
   $cm$César Iglesias 티슈(PM1 1.5만 t + Toscotec PM2 3만 t+, 2026) — Industrias GAT 초미세 GCC$cm$,
   $cm$César Iglesias 가 Santo Domingo 티슈 초지(PM1 약 1.5만 t)에 Toscotec PM2(3만 t 초과, 2026 목표) 추가. Industria del Papel Sido 재활용 크라프트·티슈. 나머지는 대부분 수입 원지 가공(Nigua·Formosa·AG Supply) 또는 골판지 가공. 현지 탄산칼슘: Industrias GAT(초미세)·DOCALSA·INREGOSA·Dominca, Belfond 고순도 석회석(미국 INCOA 원료). 제지용 PCC 없음.$cm$,
   1350, 2250,
   $cm$César Iglesias PM1 1.5만 t + PM2 3만 t × FCC 3~5% (PM2 가동 전제)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('c[eé]sar iglesias', 'santo domingo', 'iglesias'),
  ('papel sido|\mips\M.*gu[aá]yiga', 'gu[aá]yiga|pedro brand', 'sido'),
  ('inpadom|industria papelera dominicana', null, 'inpadom|industria papelera dominicana'),
  ('inpaca|industria papelera del caribe', null, 'inpaca|industria papelera del caribe'),
  ('industrias nigua', null, 'industrias nigua'),
  ('formosa', null, 'formosa'),
  ('ag supply', null, 'ag supply'),
  ('velvety', null, 'velvety'),
  ('kimberly.*dominic', null, 'kimberly.*dominic'),
  ('familia.*dominic', null, 'familia.*dominic'),
  ('cartones del caribe|cartocar', null, 'cartones del caribe|cartocar'),
  ('hued', null, 'hued'),
  ('cartonera upi', null, 'cartonera upi'),
  ('pico duarte', null, 'pico duarte'),
  ('smurfit.*dominic|smurfit.*itabo', null, 'smurfit.*dominic|smurfit.*itabo')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'dominican_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'dominican_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '^industrias gat|\mgat-?ii\M' or p.party_name ~* 'docalsa|dominicana de cales' or p.party_name ~* 'inregosa|reynoso gonell' or p.party_name ~* 'industrias dominca' or p.party_name ~* 'belfond')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'DO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'DO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'DO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    