-- ============================================================
-- seed_20261016e_ecuador_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Ecuador update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'EC check 2026-10-15'.
-- 1) Fillers if missing (5): Omya Ecuador (LACEC), La Colina, Morrocal,
--    INDAMI, ACTEK.
-- 2) Mills if missing (4) + plant blocks, priority 1-4: Familia Sancela
--    (Essity) Lasso, Cartopel Cuenca, Papelera Nacional, Surpapelcorp.
--    Context, match only (10): INPAECSA / Essity Babahoyo (stopped 2026-08),
--    Softys, Kimberly-Clark, Grupasa, INCARPALM, Procarsa, Industria
--    Cartonera Ecuatoriana, Papelesa, Zaimella, Absoreforma.
-- 3) app.country_markets EC row (priority medium).
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
           v.party_name, 'EC', v.region, v.city, v.website, 'active', 'ecuador_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('lacec|omya.*ecuador', 'Omya Ecuador (LACEC) - Ascázubi', 'Pichincha', 'Ascázubi', null, 'Omya Ecuador / LACEC — 1982년부터 탄산칼슘 생산(Quito 북동 Ascázubi). 제지·신문용지·펄프·티슈·판지·특수포장 공급 명시.', 'Omya Ecuador / LACEC - calcium carbonate since 1982 at Panamericana E-35 Km 2, Santa Rosa de Cusubamba - El Quinche, Ascázubi (northeast of Quito), high-purity high-white limestone, supplies paper, newsprint, pulp, tissue, board and specialty packaging.', 'EC check 2026-10-15: PCC at this plant not confirmed. +593 2-248-0501, lacec@lacec.com.ec. Royalty licensee at Omya HQ level.'),
  ('la colina|inducolina', 'La Colina (INDUCOLINA)', 'Guayas', 'El Progreso', null, '1991년 설립 석회석 가공·탄산칼슘 분쇄(Vía Guayaquil–Playas Km 68). Calizas San Antonio M40/M100, CarboSuin M200/M325(CaCO3 약 98%), 제지 용도 명시.', 'La Colina / INDUCOLINA Cía. Ltda. (1991), plant at Vía Guayaquil - Playas Km 68, El Progreso near the San Antonio de Playas quarry, office Cuenca - Calizas San Antonio M40 / M100 and CarboSuin M200 / M325 (about 98 pct CaCO3), paper named for brightness, opacity and print quality.', 'EC check 2026-10-15: mesh grades do not prove paper-filler fineness - wet grinding and slurry to confirm. ventas@lacolina.com, +593 99-119-8358. Local FCC co-production candidate 1.'),
  ('morrocal', 'Morrocal', 'Guayas', 'El Morro', null, '30년+ 탄산칼슘 채굴·분쇄·미분화(El Morro·Playas). 자체 채석장과 미분화 공장.', 'Morrocal - calcium carbonate quarrying, crushing and micronising around El Morro / Playas (Guayas) for over 30 years, own quarry and micronising plant, office Km 14.6 Vía a Salitre.', 'EC check 2026-10-15: paper grades not public. ventas@morrocal.com, +593 4-600-7463.'),
  ('indami', 'INDAMI (Grupo INDAMI)', 'Guayas', null, null, '초미립 탄산칼슘(INDAMICAL PREMIUM) 업체, 공장 Vía Guayaquil–Salinas Km 22.', 'INDAMI Cía. Ltda. (Grupo INDAMI) - ultrafine calcium carbonate (INDAMICAL PREMIUM), plant at Km 22 Vía Guayaquil - Salinas, head office Km 19.5.', 'EC check 2026-10-15: paper brightness, size and slurry not public. ventas@grupoindami.com.ec.'),
  ('\mactek\M', 'ACTEK Ecuador', 'Chimborazo', 'Riobamba', null, 'Riobamba 탄산칼슘(Tipo A, 98%+, 40~400 mesh)·석회·황산바륨 가공.', 'ACTEK Ecuador, Riobamba (Chimborazo) - calcium carbonate Tipo A (over 98 pct, 40-400 mesh), calcium oxide and hydroxide, barium sulphate, for paint and plastics.', 'EC check 2026-10-15: paper grade not confirmed - raw-material source. No paper PCC plant in Ecuador.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%EC check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('lacec|omya.*ecuador', 'Omya Ecuador (LACEC) - Ascázubi', 'Pichincha', 'Ascázubi', null, 'Omya Ecuador / LACEC — 1982년부터 탄산칼슘 생산(Quito 북동 Ascázubi). 제지·신문용지·펄프·티슈·판지·특수포장 공급 명시.', 'Omya Ecuador / LACEC - calcium carbonate since 1982 at Panamericana E-35 Km 2, Santa Rosa de Cusubamba - El Quinche, Ascázubi (northeast of Quito), high-purity high-white limestone, supplies paper, newsprint, pulp, tissue, board and specialty packaging.', 'EC check 2026-10-15: PCC at this plant not confirmed. +593 2-248-0501, lacec@lacec.com.ec. Royalty licensee at Omya HQ level.'),
  ('la colina|inducolina', 'La Colina (INDUCOLINA)', 'Guayas', 'El Progreso', null, '1991년 설립 석회석 가공·탄산칼슘 분쇄(Vía Guayaquil–Playas Km 68). Calizas San Antonio M40/M100, CarboSuin M200/M325(CaCO3 약 98%), 제지 용도 명시.', 'La Colina / INDUCOLINA Cía. Ltda. (1991), plant at Vía Guayaquil - Playas Km 68, El Progreso near the San Antonio de Playas quarry, office Cuenca - Calizas San Antonio M40 / M100 and CarboSuin M200 / M325 (about 98 pct CaCO3), paper named for brightness, opacity and print quality.', 'EC check 2026-10-15: mesh grades do not prove paper-filler fineness - wet grinding and slurry to confirm. ventas@lacolina.com, +593 99-119-8358. Local FCC co-production candidate 1.'),
  ('morrocal', 'Morrocal', 'Guayas', 'El Morro', null, '30년+ 탄산칼슘 채굴·분쇄·미분화(El Morro·Playas). 자체 채석장과 미분화 공장.', 'Morrocal - calcium carbonate quarrying, crushing and micronising around El Morro / Playas (Guayas) for over 30 years, own quarry and micronising plant, office Km 14.6 Vía a Salitre.', 'EC check 2026-10-15: paper grades not public. ventas@morrocal.com, +593 4-600-7463.'),
  ('indami', 'INDAMI (Grupo INDAMI)', 'Guayas', null, null, '초미립 탄산칼슘(INDAMICAL PREMIUM) 업체, 공장 Vía Guayaquil–Salinas Km 22.', 'INDAMI Cía. Ltda. (Grupo INDAMI) - ultrafine calcium carbonate (INDAMICAL PREMIUM), plant at Km 22 Vía Guayaquil - Salinas, head office Km 19.5.', 'EC check 2026-10-15: paper brightness, size and slurry not public. ventas@grupoindami.com.ec.'),
  ('\mactek\M', 'ACTEK Ecuador', 'Chimborazo', 'Riobamba', null, 'Riobamba 탄산칼슘(Tipo A, 98%+, 40~400 mesh)·석회·황산바륨 가공.', 'ACTEK Ecuador, Riobamba (Chimborazo) - calcium carbonate Tipo A (over 98 pct, 40-400 mesh), calcium oxide and hydroxide, barium sulphate, for paint and plastics.', 'EC check 2026-10-15: paper grade not confirmed - raw-material source. No paper PCC plant in Ecuador.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'ecuador_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Ecuador (LACEC) - Ascázubi', 'GCC producer', 'Omya Ecuador GCC - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('La Colina (INDUCOLINA)', 'GCC producer', 'Local GCC, paper named - FCC partner candidate 1', 'merchant', 'C', 'gcc'),
  ('Morrocal', 'GCC producer', 'Quarry-to-mill GCC', 'merchant', 'C', 'gcc'),
  ('INDAMI (Grupo INDAMI)', 'GCC producer', 'Ultrafine GCC - co-development candidate', 'merchant', 'C', 'gcc'),
  ('ACTEK Ecuador', 'GCC producer', 'Ground carbonate for paint and plastics', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'ecuador_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'EC', v.region, v.city, v.website, 'active', 'ecuador_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('familia sancela|sancela|essity.*lasso', 'lasso', 'familia|sancela|essity', 'Productos Familia Sancela (Essity) - Lasso', 'Cotopaxi', 'Lasso', null, 'Essity 계열 Familia Sancela 의 에콰도르 티슈·위생용품 공장(Lasso, Cotopaxi). 과거 자료 PM2 7,920 t + PM5 17,170 t. 브랜드 Familia·Nosotras·Pequeñín·TENA.', 'Productos Familia Sancela del Ecuador (Essity) - tissue and hygiene plant at Lasso, Cotopaxi: PM2 7,920 t and PM5 17,170 t per year in about 2017 data. Brands Familia, Nosotras, Pequeñín, TENA. 2025 sales about USD 154 m.', 'EC check 2026-10-15: current machines and output to confirm. Essity Babahoyo (ex INPAECSA) stopped in 2026-08.'),
  ('cartopel|cartones nacionales s\.?a\.?i', 'cuenca', 'cartopel', 'Cartopel - Cuenca Paper Mill', 'Azuay', 'Cuenca', null, 'Cartones Nacionales S.A.I.(Cartopel, 1990) — Cuenca 제지공장 + Cuenca·Guayaquil·Machala 골판지 공장. 2025 매출 약 2.19억 달러.', 'Cartopel - Cartones Nacionales S.A.I. (1990): Cuenca paper mill (Molino Papelero Cuenca, Av. Cornelio Vintimilla y Carlos Tosi, Parque Industrial) plus corrugated plants in Cuenca, Guayaquil and Machala - four sites, 2025 sales about USD 219 m (largest in the sector).', 'EC check 2026-10-15: paper-machine capacity not public. +593 7-286-0600, ventas@cartopel.com.'),
  ('papelera nacional|\mpanasa\M', 'maridue', 'papelera nacional|panasa', 'Papelera Nacional (PANASA) - Marcelino Maridueña', 'Guayas', 'Coronel Marcelino Maridueña', null, '1961년 설립(1968 가동) 산업용 포장원지 제조사. 재생 테스트라이너·골심지·크라프트, 연 약 16.5만 t.', 'Papelera Nacional S.A. (PANASA, founded 1961, producing since 1968), Av. Papelera s/n, Coronel Marcelino Maridueña, Guayas - recycled testliner, super corrugating medium and kraft, about 165,000 t/yr (company figure), bagasse pulp in its history. 2025 sales about USD 160.5 m.', 'EC check 2026-10-15: +593 4-272-9008, ventas@panasa.com.ec.'),
  ('surpapel', 'dur[aá]n', 'surpapel', 'Surpapelcorp - Durán', 'Guayas', 'Durán', null, 'Surpapel Group(Repapers 폐지·Surpapelcorp 원지·Procarsa 상자)의 재생 포장원지 공장(Durán, 2012 가동). 연 14만 t(MIGA 2020).', 'Surpapelcorp S.A. (Surpapel Group: Repapers for OCC, Surpapelcorp for base paper, Procarsa for boxes), Durán, Guayas - recycled packaging paper machine since 2012, 140,000 t/yr (MIGA 2020), about 80 pct goes to Procarsa (168,000 t/yr box capacity).', 'EC check 2026-10-15: capacity figures are 2020 MIGA project data.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%EC check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('familia sancela|sancela|essity.*lasso', 'lasso', 'familia|sancela|essity', 'Essity 계열 Familia Sancela 의 에콰도르 티슈·위생용품 공장(Lasso, Cotopaxi). 과거 자료 PM2 7,920 t + PM5 17,170 t. 브랜드 Familia·Nosotras·Pequeñín·TENA.', 'Productos Familia Sancela del Ecuador (Essity) - tissue and hygiene plant at Lasso, Cotopaxi: PM2 7,920 t and PM5 17,170 t per year in about 2017 data. Brands Familia, Nosotras, Pequeñín, TENA. 2025 sales about USD 154 m.', 'EC check 2026-10-15: current machines and output to confirm. Essity Babahoyo (ex INPAECSA) stopped in 2026-08.'),
  ('cartopel|cartones nacionales s\.?a\.?i', 'cuenca', 'cartopel', 'Cartones Nacionales S.A.I.(Cartopel, 1990) — Cuenca 제지공장 + Cuenca·Guayaquil·Machala 골판지 공장. 2025 매출 약 2.19억 달러.', 'Cartopel - Cartones Nacionales S.A.I. (1990): Cuenca paper mill (Molino Papelero Cuenca, Av. Cornelio Vintimilla y Carlos Tosi, Parque Industrial) plus corrugated plants in Cuenca, Guayaquil and Machala - four sites, 2025 sales about USD 219 m (largest in the sector).', 'EC check 2026-10-15: paper-machine capacity not public. +593 7-286-0600, ventas@cartopel.com.'),
  ('papelera nacional|\mpanasa\M', 'maridue', 'papelera nacional|panasa', '1961년 설립(1968 가동) 산업용 포장원지 제조사. 재생 테스트라이너·골심지·크라프트, 연 약 16.5만 t.', 'Papelera Nacional S.A. (PANASA, founded 1961, producing since 1968), Av. Papelera s/n, Coronel Marcelino Maridueña, Guayas - recycled testliner, super corrugating medium and kraft, about 165,000 t/yr (company figure), bagasse pulp in its history. 2025 sales about USD 160.5 m.', 'EC check 2026-10-15: +593 4-272-9008, ventas@panasa.com.ec.'),
  ('surpapel', 'dur[aá]n', 'surpapel', 'Surpapel Group(Repapers 폐지·Surpapelcorp 원지·Procarsa 상자)의 재생 포장원지 공장(Durán, 2012 가동). 연 14만 t(MIGA 2020).', 'Surpapelcorp S.A. (Surpapel Group: Repapers for OCC, Surpapelcorp for base paper, Procarsa for boxes), Durán, Guayas - recycled packaging paper machine since 2012, 140,000 t/yr (MIGA 2020), about 80 pct goes to Procarsa (168,000 t/yr box capacity).', 'EC check 2026-10-15: capacity figures are 2020 MIGA project data.'),
  ('inpaecsa|essity.*babahoyo', null, 'inpaecsa|essity.*babahoyo', null, null, 'EC check 2026-10-15: Recycled tissue mill, 18,400 t/yr (2014), Hada brand - production stopped 2026-08, equipment being removed - context only.'),
  ('softys.*ecuador', null, 'softys.*ecuador', null, null, 'EC check 2026-10-15: Tissue converting and diapers, Guayaquil - no paper machine - context only.'),
  ('kimberly.*ecuador', null, 'kimberly.*ecuador', null, null, 'EC check 2026-10-15: Hygiene products, Guayaquil - own tissue machine not confirmed - context only.'),
  ('grupasa', null, 'grupasa', null, null, 'EC check 2026-10-15: Corrugated and folding cartons, El Sauce - converter - context only.'),
  ('incarpalm', null, 'incarpalm', null, null, 'EC check 2026-10-15: Corrugated packaging - converter - context only.'),
  ('procarsa', null, 'procarsa', null, null, 'EC check 2026-10-15: Corrugated boxes, 168 kt/yr - converter - context only.'),
  ('industria cartonera ecuatoriana', null, 'industria cartonera ecuatoriana', null, null, 'EC check 2026-10-15: Corrugated packaging - converter - context only.'),
  ('papelesa', null, 'papelesa', null, null, 'EC check 2026-10-15: Notebooks and paper distribution - context only.'),
  ('zaimella', null, 'zaimella', null, null, 'EC check 2026-10-15: Diapers and hygiene products - context only.'),
  ('absoreforma', null, 'absoreforma', null, null, 'EC check 2026-10-15: Tissue products, Durán - machine not confirmed - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'ecuador_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('familia sancela|sancela|essity.*lasso', 'lasso', 'familia|sancela|essity'),
  ('cartopel|cartones nacionales s\.?a\.?i', 'cuenca', 'cartopel'),
  ('papelera nacional|\mpanasa\M', 'maridue', 'papelera nacional|panasa'),
  ('surpapel', 'dur[aá]n', 'surpapel'),
  ('inpaecsa|essity.*babahoyo', null, 'inpaecsa|essity.*babahoyo'),
  ('softys.*ecuador', null, 'softys.*ecuador'),
  ('kimberly.*ecuador', null, 'kimberly.*ecuador'),
  ('grupasa', null, 'grupasa'),
  ('incarpalm', null, 'incarpalm'),
  ('procarsa', null, 'procarsa'),
  ('industria cartonera ecuatoriana', null, 'industria cartonera ecuatoriana'),
  ('papelesa', null, 'papelesa'),
  ('zaimella', null, 'zaimella'),
  ('absoreforma', null, 'absoreforma')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('familia sancela|sancela|essity.*lasso', 'lasso', 'familia|sancela|essity',
   $pj${"owner": "Essity", "priority": 1, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 25090, "unit": "metric_t", "year": "About 2017 (PM2 + PM5)", "source": "process study"}, "capacity_split": [{"label": "PM5", "value_t": 17170}, {"label": "PM2", "value_t": 7920}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Tissue trial assumption 3 pct - planning only."}, "pitch": "Tissue fibre saving with existing FCC trial data", "approach": "Confirm running machines at Lasso, approach Essity technical.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartopel|cartones nacionales s\.?a\.?i', 'cuenca', 'cartopel',
   $pj${"owner": "Cartopel", "priority": 2, "products": "Corrugating base paper, boxes", "grades": ["Testliner", "Medium"], "approach": "Own machine - low-dose (1-3 pct) packaging FCC trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera nacional|\mpanasa\M', 'maridue', 'papelera nacional|panasa',
   $pj${"owner": "Papelera Nacional", "priority": 3, "products": "Testliner, corrugating medium, kraft", "grades": ["Testliner", "Medium", "Kraft paper"], "capacity": {"value": 165000, "unit": "metric_t", "year": "Company figure", "source": "papeleranacional.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report scenario 80 pct x 1-3 pct - packaging strength first."}, "approach": "FCC 1-3 pct trial for fibre saving at equal strength.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('surpapel', 'dur[aá]n', 'surpapel',
   $pj${"owner": "Surpapel Group", "priority": 4, "products": "Recycled packaging base paper", "grades": ["Testliner", "Medium"], "capacity": {"value": 140000, "unit": "metric_t", "year": "MIGA 2020", "source": "miga.org"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report scenario 80 pct x 1-3 pct."}, "approach": "Recycled-fibre saving and drainage trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('inpaecsa|essity.*babahoyo', null, 'inpaecsa|essity.*babahoyo',
   $pj${"owner": "INPAECSA / Essity Babahoyo", "products": "Recycled tissue mill, 18,400 t/yr (2014), Hada brand - production stopped 2026-08, equipment being removed", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*ecuador', null, 'softys.*ecuador',
   $pj${"owner": "Softys Ecuador (CMPC)", "products": "Tissue converting and diapers, Guayaquil - no paper machine", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*ecuador', null, 'kimberly.*ecuador',
   $pj${"owner": "Kimberly-Clark Ecuador", "products": "Hygiene products, Guayaquil - own tissue machine not confirmed", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('grupasa', null, 'grupasa',
   $pj${"owner": "Grupasa (Papelesa group)", "products": "Corrugated and folding cartons, El Sauce - converter", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('incarpalm', null, 'incarpalm',
   $pj${"owner": "INCARPALM", "products": "Corrugated packaging - converter", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('procarsa', null, 'procarsa',
   $pj${"owner": "Procarsa (Surpapel Group)", "products": "Corrugated boxes, 168 kt/yr - converter", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('industria cartonera ecuatoriana', null, 'industria cartonera ecuatoriana',
   $pj${"owner": "Industria Cartonera Ecuatoriana", "products": "Corrugated packaging - converter", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelesa', null, 'papelesa',
   $pj${"owner": "Papelesa", "products": "Notebooks and paper distribution", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('zaimella', null, 'zaimella',
   $pj${"owner": "Zaimella", "products": "Diapers and hygiene products", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('absoreforma', null, 'absoreforma',
   $pj${"owner": "Absoreforma", "products": "Tissue products, Durán - machine not confirmed", "approach": "Converter or stopped mill.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'EC', 'Ecuador', 'medium',
   $cm$Recycled packaging mills (PANASA 165 kt, Surpapelcorp 140 kt, Cartopel) plus Essity tissue - Omya LACEC GCC on site$cm$,
   $cm$Omya (LACEC, Ascázubi) runs a paper-grade GCC plant - an MBG licensee. Local GCC: La Colina (paper named), Morrocal, INDAMI, ACTEK. No paper PCC plant. Paper machines: Papelera Nacional (165 kt recycled liner and medium), Surpapelcorp (140 kt), Cartopel (Cuenca). Tissue: Familia Sancela / Essity at Lasso (about 25 kt historical). Essity Babahoyo (ex INPAECSA) stopped in 2026-08. Softys and Kimberly-Clark only convert. Sector sales USD 1.67 bn (2025, incl. converters).$cm$,
   $cm${"fillers": "Licensee: Omya Ecuador / LACEC (Ascázubi, since 1982). Local GCC: La Colina / INDUCOLINA (98 pct, M200 / M325, paper named), Morrocal, INDAMI (ultrafine), ACTEK (Riobamba). No PCC plant.", "mills": "Packaging: Papelera Nacional (Marcelino Maridueña), Surpapelcorp (Durán), Cartopel (Cuenca mill). Tissue: Familia Sancela / Essity Lasso. Stopped: Essity Babahoyo (ex INPAECSA, 2026-08). Converters: Softys, Kimberly-Clark, Grupasa, INCARPALM, Procarsa, Industria Cartonera Ecuatoriana, Papelesa, Zaimella, Absoreforma.", "strategy": "Through Omya (LACEC) as licensee: Essity tissue trial, then low-dose packaging FCC at Cartopel, PANASA and Surpapelcorp. La Colina as additional local producer.", "risks": "Most capacity is strength-critical recycled packaging. Tissue capacity data old.", "next_steps": ["Confirm Essity Lasso machines", "Low-dose packaging trial proposal to Cartopel"], "key_numbers": [{"label": "Sector sales 2025", "value": "USD 1.67 bn (paper and paper products)"}, {"label": "PANASA + Surpapelcorp", "value": "305 kt/yr"}, {"label": "Report scenario", "value": "7,320 t FCC (80 pct x 3 pct packaging)"}], "files": ["seed_20261016e_ecuador_mills_fillers"]}$cm$::jsonb,
   $cm$재생 포장원지(PANASA 16.5만 t·Surpapelcorp 14만 t·Cartopel) + Essity 티슈 — Omya LACEC GCC 공장 보유$cm$,
   $cm$라이선시 Omya(LACEC, Ascázubi) 제지용 GCC 공장 가동. 현지 GCC: La Colina(제지 명시)·Morrocal·INDAMI·ACTEK, 제지용 PCC 없음. 초지: Papelera Nacional 16.5만 t, Surpapelcorp 14만 t, Cartopel Cuenca. 티슈: Familia Sancela/Essity Lasso(과거 약 2.5만 t). Essity Babahoyo(구 INPAECSA) 2026-08 가동 중단. Softys·Kimberly-Clark 는 가공만.$cm$,
   2440, 8073,
   $cm$PANASA+Surpapelcorp 30.5만 t × 80% × 1~3% + Essity Lasso 2.5만 t × 3% (보고서 시나리오, 포장지 강도 검증 필요)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('familia sancela|sancela|essity.*lasso', 'lasso', 'familia|sancela|essity'),
  ('cartopel|cartones nacionales s\.?a\.?i', 'cuenca', 'cartopel'),
  ('papelera nacional|\mpanasa\M', 'maridue', 'papelera nacional|panasa'),
  ('surpapel', 'dur[aá]n', 'surpapel'),
  ('inpaecsa|essity.*babahoyo', null, 'inpaecsa|essity.*babahoyo'),
  ('softys.*ecuador', null, 'softys.*ecuador'),
  ('kimberly.*ecuador', null, 'kimberly.*ecuador'),
  ('grupasa', null, 'grupasa'),
  ('incarpalm', null, 'incarpalm'),
  ('procarsa', null, 'procarsa'),
  ('industria cartonera ecuatoriana', null, 'industria cartonera ecuatoriana'),
  ('papelesa', null, 'papelesa'),
  ('zaimella', null, 'zaimella'),
  ('absoreforma', null, 'absoreforma')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'ecuador_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'ecuador_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'lacec|omya.*ecuador' or p.party_name ~* 'la colina|inducolina' or p.party_name ~* 'morrocal' or p.party_name ~* 'indami' or p.party_name ~* '\mactek\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'EC'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'EC'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'EC'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EC'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    