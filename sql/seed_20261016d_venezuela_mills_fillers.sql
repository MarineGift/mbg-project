-- ============================================================
-- seed_20261016d_venezuela_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Venezuela update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'VE check 2026-10-15'.
-- 1) Fillers if missing (6): RIASCA, ESVENCA, VE-CA-FO, Minerales Yaracal,
--    MICRA, EXIN. Lime makers and distributors not added.
-- 2) Mills if missing (5) + plant blocks, priority 1-4: MANPA Maracay,
--    PAVECA Guacara, Cartonal Valencia, Mocarpel San Felipe, Cacique Maracay
--    (capacities are historical, kept in capacity_split).
--    Context, match only (7): ex Smurfit group row, Vencartón, INVEPAL,
--    PULPACA, Cartoenvases, Unión Gráfica, Corrugadora Maracay.
-- 3) app.country_markets VE row (priority low, sanctions check noted).
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
           v.party_name, 'VE', v.region, v.city, v.website, 'active', 'venezuela_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\mrias(ca)?\M|rias, c\.?a', 'RIAS, C.A. (RIASCA)', null, null, null, '1984년 설립 산업광물 업체. 1999년 미분쇄 공장(월 2,700 t) 설치, RIASCARB-RD·4(635 mesh)~15(140 mesh).', 'RIAS, C.A. (RIASCA, 1984) - industrial minerals, micronising plant since 1999 (2,700 t/month nameplate then), RIASCARB-RD and RIASCARB 4 (635 mesh) down to RIASCARB 15 (140 mesh), for paint, PVC, construction, oil and rubber.', 'VE check 2026-10-15: paper supply not confirmed, d50 unknown, plant location to confirm. FCC producer candidate 1.'),
  ('esvenca|environmental solutions de venezuela', 'ESVENCA (Environmental Solutions de Venezuela)', 'Monagas', 'Maturín', null, 'Cariaco(Sucre) 석회석 가공 탄산칼슘. MTW-138 분쇄기 2대, 일 32~40 t 설치능력. Maturín(Monagas)·Cabimas(Zulia).', 'Environmental Solutions de Venezuela (ESVENCA), Maturín (Monagas) and Cabimas (Zulia) - calcium carbonate made of Cariaco (Sucre) limestone, two MTW-138 mills, 32-40 t/day installed (about 10,600-13,200 t/yr at 330 days), bags, big bags and bulk for construction, paint, agriculture, oil.', 'VE check 2026-10-15: which site runs the mills, fine grades and wet slurry not confirmed.'),
  ('ve-?ca-?fo|venezolana de calcio', 'VE-CA-FO (Industria Venezolana de Calcio y Fosfato)', 'Aragua', 'Villa de Cura', null, '1965년 설립 탄산칼슘·인산염·벤토나이트 가공·유통(Villa de Cura, Aragua).', 'Industria Venezolana de Calcio y Fosfato, C.A. (VE-CA-FO, 1965), Carretera Cagua - Villa de Cura, Aragua - calcium carbonate in several sizes, phosphate and bentonite for agriculture, feed, building and industry.', 'VE check 2026-10-15: paper grades and capacity not public.'),
  ('minerales yaracal', 'Minerales Yaracal', 'Yaracuy', 'Yaritagua', null, '2015년 설립 Yaracuy Yaritagua 석회석 채굴·미분쇄·탄산칼슘 업체.', 'Minerales Yaracal (2015), Yaritagua, Yaracuy - limestone quarrying, micronising and calcium carbonate, food and oil markets, export aims.', 'VE check 2026-10-15: paper-grade brightness and slurry not confirmed.'),
  ('micronizados caribe|\mmicra\M', 'Micronizados Caribe (MICRA)', 'Sucre', 'Cumaná', null, '1994년 설립 미분쇄 탄산칼슘 업체(Güirintal·Cumaná El Peñón). 현재 가동 미확인.', 'Micronizados Caribe, C.A. (MICRA, 1994) - micronised calcium carbonate, plants at Güirintal and El Peñón industrial zone, Cumaná (Sucre) in older listings.', 'VE check 2026-10-15: 2026 operation not confirmed.'),
  ('exin de venezuela', 'EXIN de Venezuela', 'Yaracuy', null, null, 'Yaracuy GCC(CaCO3 94~97%, 4~100 mesh, 월 1,000 t, 과거 자료).', 'EXIN de Venezuela, C.A., Yaracuy - ground calcium carbonate 94-97 pct CaCO3, 4-100 mesh, about 1,000 t/month (older data), for agriculture, feed, building.', 'VE check 2026-10-15: coarse - raw-material source. Not added: SUPRACAL and Maxical (lime), Corporación Venezolana de Agregados and Venza (distributors). No paper PCC plant, no Omya site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%VE check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\mrias(ca)?\M|rias, c\.?a', 'RIAS, C.A. (RIASCA)', null, null, null, '1984년 설립 산업광물 업체. 1999년 미분쇄 공장(월 2,700 t) 설치, RIASCARB-RD·4(635 mesh)~15(140 mesh).', 'RIAS, C.A. (RIASCA, 1984) - industrial minerals, micronising plant since 1999 (2,700 t/month nameplate then), RIASCARB-RD and RIASCARB 4 (635 mesh) down to RIASCARB 15 (140 mesh), for paint, PVC, construction, oil and rubber.', 'VE check 2026-10-15: paper supply not confirmed, d50 unknown, plant location to confirm. FCC producer candidate 1.'),
  ('esvenca|environmental solutions de venezuela', 'ESVENCA (Environmental Solutions de Venezuela)', 'Monagas', 'Maturín', null, 'Cariaco(Sucre) 석회석 가공 탄산칼슘. MTW-138 분쇄기 2대, 일 32~40 t 설치능력. Maturín(Monagas)·Cabimas(Zulia).', 'Environmental Solutions de Venezuela (ESVENCA), Maturín (Monagas) and Cabimas (Zulia) - calcium carbonate made of Cariaco (Sucre) limestone, two MTW-138 mills, 32-40 t/day installed (about 10,600-13,200 t/yr at 330 days), bags, big bags and bulk for construction, paint, agriculture, oil.', 'VE check 2026-10-15: which site runs the mills, fine grades and wet slurry not confirmed.'),
  ('ve-?ca-?fo|venezolana de calcio', 'VE-CA-FO (Industria Venezolana de Calcio y Fosfato)', 'Aragua', 'Villa de Cura', null, '1965년 설립 탄산칼슘·인산염·벤토나이트 가공·유통(Villa de Cura, Aragua).', 'Industria Venezolana de Calcio y Fosfato, C.A. (VE-CA-FO, 1965), Carretera Cagua - Villa de Cura, Aragua - calcium carbonate in several sizes, phosphate and bentonite for agriculture, feed, building and industry.', 'VE check 2026-10-15: paper grades and capacity not public.'),
  ('minerales yaracal', 'Minerales Yaracal', 'Yaracuy', 'Yaritagua', null, '2015년 설립 Yaracuy Yaritagua 석회석 채굴·미분쇄·탄산칼슘 업체.', 'Minerales Yaracal (2015), Yaritagua, Yaracuy - limestone quarrying, micronising and calcium carbonate, food and oil markets, export aims.', 'VE check 2026-10-15: paper-grade brightness and slurry not confirmed.'),
  ('micronizados caribe|\mmicra\M', 'Micronizados Caribe (MICRA)', 'Sucre', 'Cumaná', null, '1994년 설립 미분쇄 탄산칼슘 업체(Güirintal·Cumaná El Peñón). 현재 가동 미확인.', 'Micronizados Caribe, C.A. (MICRA, 1994) - micronised calcium carbonate, plants at Güirintal and El Peñón industrial zone, Cumaná (Sucre) in older listings.', 'VE check 2026-10-15: 2026 operation not confirmed.'),
  ('exin de venezuela', 'EXIN de Venezuela', 'Yaracuy', null, null, 'Yaracuy GCC(CaCO3 94~97%, 4~100 mesh, 월 1,000 t, 과거 자료).', 'EXIN de Venezuela, C.A., Yaracuy - ground calcium carbonate 94-97 pct CaCO3, 4-100 mesh, about 1,000 t/month (older data), for agriculture, feed, building.', 'VE check 2026-10-15: coarse - raw-material source. Not added: SUPRACAL and Maxical (lime), Corporación Venezolana de Agregados and Venza (distributors). No paper PCC plant, no Omya site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'venezuela_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('RIAS, C.A. (RIASCA)', 'GCC producer', 'Micronised GCC - FCC producer candidate 1', 'merchant', 'C', 'gcc'),
  ('ESVENCA (Environmental Solutions de Venezuela)', 'GCC producer', 'Dry GCC line - FCC producer candidate 2', 'merchant', 'C', 'gcc'),
  ('VE-CA-FO (Industria Venezolana de Calcio y Fosfato)', 'GCC producer', 'Carbonate processor near Maracay mills', 'merchant', 'C', 'gcc'),
  ('Minerales Yaracal', 'GCC producer', 'Limestone and micronising', 'merchant', 'C', 'gcc'),
  ('Micronizados Caribe (MICRA)', 'GCC producer', 'Micronised carbonate - status unknown', 'merchant', 'C', 'gcc'),
  ('EXIN de Venezuela', 'Carbonate raw material', 'Coarse GCC - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'venezuela_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'VE', v.region, v.city, v.website, 'active', 'venezuela_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('\mmanpa\M|manufacturas de papel', 'maracay', 'manpa|manufacturas de papel', 'MANPA (Manufacturas de Papel) - Maracay', 'Aragua', 'Maracay', null, '1950년 설립 종합 제지사(증권 코드 MPA). Maracay 인쇄·필기·포장용지 초지기 3대(과거 연 약 12만 t), La Hamaca 티슈(과거 연 5만 t). 2026-06 2023~24 감사 재무제표 공시.', 'Manufacturas de Papel C.A. (MANPA, 1950, listed MPA) - Maracay, Aragua: printing and writing, copy, colour and kraft papers on three machines (about 120,000 t/yr in older data), tissue at Zona Industrial La Hamaca (50,000 t/yr in older CAF data), bags, sacks and notebooks. 2023-2024 audited accounts published 2026-06.', 'VE check 2026-10-15: which machines run in 2026 and current tonnage not confirmed - capacities are historical.'),
  ('paveca|papeles venezolanos', 'guacara', 'paveca|papeles venezolanos', 'PAVECA (Papeles Venezolanos) - Guacara', 'Carabobo', 'Guacara', null, '1953년 설립 티슈·흡수성 종이 전문(Guacara, Carabobo). Suave Gold·Rosal 화장지, Z·Sedita 냅킨, Don Toallín, Sanitisu Professional. 과거 7대·연 약 9.4만 t.', 'Papeles Venezolanos C.A. (PAVECA, 1953), Carretera Nacional Guacara - San Joaquín Km 1, Zona Industrial El Tigre, Guacara, Carabobo - tissue and absorbent paper: Suave Gold and Rosal toilet tissue, Z and Sedita napkins, Don Toallín towels, Sanitisu Professional. Older data: seven machines, about 94,000 t/yr.', 'VE check 2026-10-15: 2025-08 management-system document confirms tissue making at Guacara. Current output not public. +58 245 4003430.'),
  ('cartonal|cartones nacionales', 'valencia', 'cartonal|cartones nacionales', 'Cartonal (Cartones Nacionales) - Valencia', 'Carabobo', 'Valencia', null, '구 Smurfit Kappa Cartón de Venezuela 계열 산업용 판지 제지공장(Valencia). 2024-11 정부 특별관리위원회 지정.', 'Cartones Nacionales (Cartonal), Valencia, Carabobo - industrial board mill of the former Smurfit Kappa Cartón de Venezuela group, under a government special management board since 2024-11 (Gaceta 43.012).', 'VE check 2026-10-15: current machine operation and operator to confirm.'),
  ('mocarpel|molinos de cart[oó]n y papel', 'san felipe', 'mocarpel', 'Mocarpel - San Felipe', 'Yaracuy', 'San Felipe', null, '구 Smurfit 계열 펄프·제지·산업용 판지 공장(San Felipe, Yaracuy).', 'Mocarpel - Molinos de Cartón y Papel, San Felipe, Yaracuy - pulp, paper and industrial board mill of the former Smurfit group.', 'VE check 2026-10-15: whether paper machines run or pulp only is not confirmed.'),
  ('cacique maracay|kimberly.*venezuela', 'maracay', 'cacique|kimberly', 'Cacique Maracay (ex Kimberly-Clark Venezuela)', 'Aragua', 'Maracay', null, '2016-07 Kimberly-Clark 철수 후 정부 관리 Maracay 티슈 공장(Cacique Maracay). 과거 티슈 연 3만 t, 가공 2.88만 t.', 'Cacique Maracay - the former Kimberly-Clark Venezuela tissue plant in Maracay, state-run since Kimberly-Clark left in 2016-07. Older data: 30,000 t/yr tissue, 28,800 t/yr converting.', 'VE check 2026-10-15: operator (reports link Papeles Luciano''s), running machine and decision maker to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%VE check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mmanpa\M|manufacturas de papel', 'maracay', 'manpa|manufacturas de papel', '1950년 설립 종합 제지사(증권 코드 MPA). Maracay 인쇄·필기·포장용지 초지기 3대(과거 연 약 12만 t), La Hamaca 티슈(과거 연 5만 t). 2026-06 2023~24 감사 재무제표 공시.', 'Manufacturas de Papel C.A. (MANPA, 1950, listed MPA) - Maracay, Aragua: printing and writing, copy, colour and kraft papers on three machines (about 120,000 t/yr in older data), tissue at Zona Industrial La Hamaca (50,000 t/yr in older CAF data), bags, sacks and notebooks. 2023-2024 audited accounts published 2026-06.', 'VE check 2026-10-15: which machines run in 2026 and current tonnage not confirmed - capacities are historical.'),
  ('paveca|papeles venezolanos', 'guacara', 'paveca|papeles venezolanos', '1953년 설립 티슈·흡수성 종이 전문(Guacara, Carabobo). Suave Gold·Rosal 화장지, Z·Sedita 냅킨, Don Toallín, Sanitisu Professional. 과거 7대·연 약 9.4만 t.', 'Papeles Venezolanos C.A. (PAVECA, 1953), Carretera Nacional Guacara - San Joaquín Km 1, Zona Industrial El Tigre, Guacara, Carabobo - tissue and absorbent paper: Suave Gold and Rosal toilet tissue, Z and Sedita napkins, Don Toallín towels, Sanitisu Professional. Older data: seven machines, about 94,000 t/yr.', 'VE check 2026-10-15: 2025-08 management-system document confirms tissue making at Guacara. Current output not public. +58 245 4003430.'),
  ('cartonal|cartones nacionales', 'valencia', 'cartonal|cartones nacionales', '구 Smurfit Kappa Cartón de Venezuela 계열 산업용 판지 제지공장(Valencia). 2024-11 정부 특별관리위원회 지정.', 'Cartones Nacionales (Cartonal), Valencia, Carabobo - industrial board mill of the former Smurfit Kappa Cartón de Venezuela group, under a government special management board since 2024-11 (Gaceta 43.012).', 'VE check 2026-10-15: current machine operation and operator to confirm.'),
  ('mocarpel|molinos de cart[oó]n y papel', 'san felipe', 'mocarpel', '구 Smurfit 계열 펄프·제지·산업용 판지 공장(San Felipe, Yaracuy).', 'Mocarpel - Molinos de Cartón y Papel, San Felipe, Yaracuy - pulp, paper and industrial board mill of the former Smurfit group.', 'VE check 2026-10-15: whether paper machines run or pulp only is not confirmed.'),
  ('cacique maracay|kimberly.*venezuela', 'maracay', 'cacique|kimberly', '2016-07 Kimberly-Clark 철수 후 정부 관리 Maracay 티슈 공장(Cacique Maracay). 과거 티슈 연 3만 t, 가공 2.88만 t.', 'Cacique Maracay - the former Kimberly-Clark Venezuela tissue plant in Maracay, state-run since Kimberly-Clark left in 2016-07. Older data: 30,000 t/yr tissue, 28,800 t/yr converting.', 'VE check 2026-10-15: operator (reports link Papeles Luciano''s), running machine and decision maker to confirm.'),
  ('cart[oó]n de venezuela|smurfit.*venezuela', null, 'cart[oó]n de venezuela|smurfit.*venezuela', null, null, 'VE check 2026-10-15: Group row - board and corrugated, state-managed since 2024-11 - context only.'),
  ('vencart[oó]n', null, 'vencart[oó]n', null, null, 'VE check 2026-10-15: Corrugated boxes (Mariara), restarted 2025-03 - converter - context only.'),
  ('invepal', null, 'invepal', null, null, 'VE check 2026-10-15: State paper company - current machines unknown - context only.'),
  ('pulpaca', null, 'pulpaca', null, null, 'VE check 2026-10-15: Newsprint and pulp project, 250 kt planned - not completed - context only.'),
  ('cartoenvases', null, 'cartoenvases', null, null, 'VE check 2026-10-15: Corrugated boxes - converter - context only.'),
  ('uni[oó]n gr[aá]fica', null, 'uni[oó]n gr[aá]fica', null, null, 'VE check 2026-10-15: Folding cartons - converter - context only.'),
  ('corrugadora maracay', null, 'corrugadora maracay', null, null, 'VE check 2026-10-15: Corrugated - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'venezuela_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mmanpa\M|manufacturas de papel', 'maracay', 'manpa|manufacturas de papel'),
  ('paveca|papeles venezolanos', 'guacara', 'paveca|papeles venezolanos'),
  ('cartonal|cartones nacionales', 'valencia', 'cartonal|cartones nacionales'),
  ('mocarpel|molinos de cart[oó]n y papel', 'san felipe', 'mocarpel'),
  ('cacique maracay|kimberly.*venezuela', 'maracay', 'cacique|kimberly'),
  ('cart[oó]n de venezuela|smurfit.*venezuela', null, 'cart[oó]n de venezuela|smurfit.*venezuela'),
  ('vencart[oó]n', null, 'vencart[oó]n'),
  ('invepal', null, 'invepal'),
  ('pulpaca', null, 'pulpaca'),
  ('cartoenvases', null, 'cartoenvases'),
  ('uni[oó]n gr[aá]fica', null, 'uni[oó]n gr[aá]fica'),
  ('corrugadora maracay', null, 'corrugadora maracay')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mmanpa\M|manufacturas de papel', 'maracay', 'manpa|manufacturas de papel',
   $pj${"owner": "MANPA", "priority": 1, "products": "Printing and writing, copy, kraft, tissue", "grades": ["Printing and writing", "Copy paper", "Kraft paper", "Tissue"], "machines": 3, "capacity_split": [{"label": "Printing, writing, packaging (historical)", "value_t": 120000}, {"label": "Tissue (historical CAF)", "value_t": 50000}], "pitch": "FCC fibre saving on printing and writing paper, then tissue", "approach": "Confirm running machines and decision makers first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('paveca|papeles venezolanos', 'guacara', 'paveca|papeles venezolanos',
   $pj${"owner": "PAVECA", "priority": 2, "products": "Toilet tissue, napkins, towels, institutional tissue", "grades": ["Tissue"], "machines": 7, "capacity_split": [{"label": "Historical (7 machines)", "value_t": 94000}], "pitch": "Tissue FCC trial at 3-5-7 pct", "approach": "Active and reachable - easiest first contact.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartonal|cartones nacionales', 'valencia', 'cartonal|cartones nacionales',
   $pj${"owner": "Ex Smurfit Kappa Cartón de Venezuela (state-managed)", "priority": 3, "products": "Industrial board, recycled packaging paper", "grades": ["Board", "Testliner"], "approach": "Confirm operator and running machine - strength-led packaging FCC only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('mocarpel|molinos de cart[oó]n y papel', 'san felipe', 'mocarpel',
   $pj${"owner": "Ex Smurfit Kappa Cartón de Venezuela (state-managed)", "priority": 3, "products": "Pulp, paper, industrial board", "grades": ["Board"], "approach": "Confirm machines in use.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cacique maracay|kimberly.*venezuela', 'maracay', 'cacique|kimberly',
   $pj${"owner": "State-managed", "priority": 4, "products": "Toilet tissue (historical)", "grades": ["Tissue"], "capacity_split": [{"label": "Tissue (historical)", "value_t": 30000}], "approach": "Confirm operator first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cart[oó]n de venezuela|smurfit.*venezuela', null, 'cart[oó]n de venezuela|smurfit.*venezuela',
   $pj${"owner": "Ex Smurfit Kappa Cartón de Venezuela", "products": "Group row - board and corrugated, state-managed since 2024-11", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('vencart[oó]n', null, 'vencart[oó]n',
   $pj${"owner": "Vencartón", "products": "Corrugated boxes (Mariara), restarted 2025-03 - converter", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('invepal', null, 'invepal',
   $pj${"owner": "INVEPAL", "products": "State paper company - current machines unknown", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('pulpaca', null, 'pulpaca',
   $pj${"owner": "PULPACA", "products": "Newsprint and pulp project, 250 kt planned - not completed", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartoenvases', null, 'cartoenvases',
   $pj${"owner": "Cartoenvases Valencia", "products": "Corrugated boxes - converter", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('uni[oó]n gr[aá]fica', null, 'uni[oó]n gr[aá]fica',
   $pj${"owner": "Unión Gráfica", "products": "Folding cartons - converter", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corrugadora maracay', null, 'corrugadora maracay',
   $pj${"owner": "Corrugadora Maracay", "products": "Corrugated - converter", "approach": "Converter, project or group row.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'VE', 'Venezuela', 'low',
   $cm$MANPA and PAVECA (tissue, printing) plus state-managed ex-Smurfit board mills - capacities are historical$cm$,
   $cm$Venezuela had sizeable paper capacity (426 kt output in 2001 at about 54 pct utilisation) but many mills were nationalised, closed or are state-managed. Active: PAVECA tissue (Guacara, historical 94 kt) and MANPA (Maracay, historical 120 kt printing and packaging plus 50 kt tissue). Ex-Smurfit Cartonal and Mocarpel are under a government board since 2024-11. Cacique Maracay is the ex Kimberly-Clark tissue plant. Local GCC grinders (RIASCA, ESVENCA, VE-CA-FO, Yaracal) - no paper PCC plant.$cm$,
   $cm${"fillers": "GCC: RIASCA (635 mesh, micronising), ESVENCA (2 x MTW-138, 32-40 t/day), VE-CA-FO (Villa de Cura), Minerales Yaracal (Yaritagua), MICRA (Cumaná, status unknown), EXIN (coarse). Lime only: SUPRACAL, Maxical. No paper PCC plant, no Omya site.", "mills": "MANPA Maracay (printing, kraft, tissue), PAVECA Guacara (tissue), Cartonal Valencia and Mocarpel San Felipe (ex Smurfit, state-managed), Cacique Maracay (ex Kimberly-Clark). Context: Vencartón, INVEPAL, PULPACA (unfinished 250 kt project), Cartoenvases, Unión Gráfica, Corrugadora Maracay.", "strategy": "PAVECA tissue trial first (active, reachable), MANPA printing paper if machines run. Local GCC partner (RIASCA or ESVENCA) as licensed producer.", "risks": "Machine status and operators uncertain, capacities historical. Check current US sanctions and payment routes before any outreach or contract.", "next_steps": ["Confirm running machines at MANPA and PAVECA", "Check sanctions status before contact"], "key_numbers": [{"label": "Paper and board output 2001", "value": "426,239 t (about 54 pct utilisation)"}, {"label": "PAVECA historical", "value": "94 kt, 7 machines"}, {"label": "MANPA historical", "value": "120 kt + 50 kt tissue"}], "files": ["seed_20261016d_venezuela_mills_fillers"]}$cm$::jsonb,
   $cm$MANPA·PAVECA(티슈·인쇄용지) + 정부 관리 구 Smurfit 판지공장 — 생산능력은 과거 수치$cm$,
   $cm$베네수엘라는 과거 제지 생산 기반(2001 42.6만 t, 가동률 약 54%)이 컸으나 국유화·폐쇄·정부 관리가 많음. 활동 확인: PAVECA 티슈(Guacara, 과거 9.4만 t), MANPA(Maracay, 과거 인쇄·포장 12만 t + 티슈 5만 t). 구 Smurfit Cartonal·Mocarpel 은 2024-11 정부 관리. Cacique Maracay 는 구 Kimberly-Clark 공장. 현지 GCC(RIASCA·ESVENCA 등)만 있고 제지용 PCC 없음. 접촉 전 미국 제재 확인 필요.$cm$,
   null, null,
   $cm$현재 생산량 미공개(과거 수치만) — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('\mmanpa\M|manufacturas de papel', 'maracay', 'manpa|manufacturas de papel'),
  ('paveca|papeles venezolanos', 'guacara', 'paveca|papeles venezolanos'),
  ('cartonal|cartones nacionales', 'valencia', 'cartonal|cartones nacionales'),
  ('mocarpel|molinos de cart[oó]n y papel', 'san felipe', 'mocarpel'),
  ('cacique maracay|kimberly.*venezuela', 'maracay', 'cacique|kimberly'),
  ('cart[oó]n de venezuela|smurfit.*venezuela', null, 'cart[oó]n de venezuela|smurfit.*venezuela'),
  ('vencart[oó]n', null, 'vencart[oó]n'),
  ('invepal', null, 'invepal'),
  ('pulpaca', null, 'pulpaca'),
  ('cartoenvases', null, 'cartoenvases'),
  ('uni[oó]n gr[aá]fica', null, 'uni[oó]n gr[aá]fica'),
  ('corrugadora maracay', null, 'corrugadora maracay')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'venezuela_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'venezuela_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\mrias(ca)?\M|rias, c\.?a' or p.party_name ~* 'esvenca|environmental solutions de venezuela' or p.party_name ~* 've-?ca-?fo|venezolana de calcio' or p.party_name ~* 'minerales yaracal' or p.party_name ~* 'micronizados caribe|\mmicra\M' or p.party_name ~* 'exin de venezuela')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'VE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'VE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'VE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'VE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    