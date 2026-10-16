-- ============================================================
-- seed_20261016i_peru_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Peru update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'PE check 2026-10-15'.
-- 1) Fillers if missing (6): Mineralium, OLAH Group, Dogaresa, Abastecedora
--    Andina, Alpamayo, Comando Group. Lime companies not added.
-- 2) Mills if missing (10) + plant blocks, priority 1-8: Papelera Reyes,
--    Papelera Zárate, Softys Santa Anita and Cañete, Kimberly-Clark Puente
--    Piedra, CARVIMSA, Trupal Trujillo and Lima, PANASA Paramonga (Peru, not
--    Ecuador), Papelera del Sur. Context (5): Campoy, Panamericana,
--    El Chasqui, Schroth, Softys Arequipa.
-- 3) app.country_markets PE row (priority medium).
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
           v.party_name, 'PE', v.region, v.city, v.website, 'active', 'peru_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('mineralium', 'Mineralium (Carbomin)', 'Lima', 'Huachipa', null, 'Huachipa(Lima) 비금속 광물 미분화 업체. Carbomin 탄산칼슘 325·400·600 mesh, 해발 4,000 m 이상 광산 원료, 종이 용도 명시.', 'Mineralium - Carbomin calcium carbonate micronised at Av. Los Robles / Calle Jacarandá, Mz. K Lote 13, Huachipa (Lima): 325, 400 and 600 mesh, mined above 4,000 m, paper named among uses (also paint, adhesives, cement, PVC).', 'PE check 2026-10-15: mesh does not prove paper-filler d50 - wet dispersion and slurry not confirmed. info@mineralium.pe, +51 992 744 744. Near CARVIMSA Huachipa mill. FCC partner candidate 1.'),
  ('\molah\M', 'OLAH Group', 'Lima', 'Lurín', null, '페루 자본 산업용 탄산칼슘 제조사(2023-01 사업 개시). 완전 자동화 라인 5개, 자체 원료, 주력 사료·축산.', 'OLAH Group S.A.C. - Peruvian-owned industrial calcium carbonate maker, operating since 2023-01-04, five fully automated lines, own limestone supply, mainly feed and livestock. Contact address Av. Eucalipto Km 40, Lurín (Lima).', 'PE check 2026-10-15: plant address and paper grades to confirm. ventas@quarksperu.com, +51 946 290 954. OEM candidate.'),
  ('dogaresa', 'Sociedad Minera Dogaresa', 'Lima', 'Ate Vitarte', null, '1962년부터 탄산칼슘 분쇄·입도 분리(Ate Vitarte). 산업용·화학용 맞춤 입도.', 'Sociedad Minera Dogaresa S.A.C., Av. Los Castillos 311, Ate Vitarte (Lima) - grinding and classifying calcium carbonate since 1962, custom particle sizes for industry and chemicals (sold by Química Andina).', 'PE check 2026-10-15: paper brightness and wet GCC not confirmed. ventas@quimand.com.pe.'),
  ('abastecedora andina', 'Cía. Minera Abastecedora Andina', 'Lima', 'El Agustino', null, '비금속광물 분쇄·가공(El Agustino). 미분 탄산칼슘 325·400·Super 1000 mesh.', 'Cía. Minera Abastecedora Andina S.A.C., Av. 1 de Mayo 2359, Vicentelo Alto, El Agustino (Lima) - micronised calcium carbonate 325, 400 and Super 1000 mesh (directory data).', 'PE check 2026-10-15: current production to confirm. +51 1 385 0103.'),
  ('alpamayo', 'Molinos Calcáreos Alpamayo', 'Ancash', 'Carhuaz', null, 'Ancash Acopampa(Carhuaz) 석회석·탄산칼슘·석회 채굴·가공.', 'Molinos Calcáreos Alpamayo E.I.R.L., Carretera Huaraz - Caraz Km 229, Acopampa, Carhuaz (Ancash) - limestone, calcium carbonate, quick and hydrated lime for mining, building, agriculture, water treatment.', 'PE check 2026-10-15: raw-material source - a long haul to Lima mills. ventas@molinoscalcareoalpamayo.com.'),
  ('comando group', 'Comando Group', 'Arequipa', 'Arequipa', null, 'Arequipa 석회석·트래버틴·석고 채굴·가공, 고순도 탄산칼슘(95.36%).', 'Comando Group, Arequipa - limestone, travertine and gypsum quarrying, high-purity calcium carbonate (95.36 pct CaCO3) and asphalt filler.', 'PE check 2026-10-15: raw-material source only. Not added: Calidra Perú (quicklime, Callalli), ABC Carbon, Procasac, COPROCAL (lime and limestone). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%PE check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('mineralium', 'Mineralium (Carbomin)', 'Lima', 'Huachipa', null, 'Huachipa(Lima) 비금속 광물 미분화 업체. Carbomin 탄산칼슘 325·400·600 mesh, 해발 4,000 m 이상 광산 원료, 종이 용도 명시.', 'Mineralium - Carbomin calcium carbonate micronised at Av. Los Robles / Calle Jacarandá, Mz. K Lote 13, Huachipa (Lima): 325, 400 and 600 mesh, mined above 4,000 m, paper named among uses (also paint, adhesives, cement, PVC).', 'PE check 2026-10-15: mesh does not prove paper-filler d50 - wet dispersion and slurry not confirmed. info@mineralium.pe, +51 992 744 744. Near CARVIMSA Huachipa mill. FCC partner candidate 1.'),
  ('\molah\M', 'OLAH Group', 'Lima', 'Lurín', null, '페루 자본 산업용 탄산칼슘 제조사(2023-01 사업 개시). 완전 자동화 라인 5개, 자체 원료, 주력 사료·축산.', 'OLAH Group S.A.C. - Peruvian-owned industrial calcium carbonate maker, operating since 2023-01-04, five fully automated lines, own limestone supply, mainly feed and livestock. Contact address Av. Eucalipto Km 40, Lurín (Lima).', 'PE check 2026-10-15: plant address and paper grades to confirm. ventas@quarksperu.com, +51 946 290 954. OEM candidate.'),
  ('dogaresa', 'Sociedad Minera Dogaresa', 'Lima', 'Ate Vitarte', null, '1962년부터 탄산칼슘 분쇄·입도 분리(Ate Vitarte). 산업용·화학용 맞춤 입도.', 'Sociedad Minera Dogaresa S.A.C., Av. Los Castillos 311, Ate Vitarte (Lima) - grinding and classifying calcium carbonate since 1962, custom particle sizes for industry and chemicals (sold by Química Andina).', 'PE check 2026-10-15: paper brightness and wet GCC not confirmed. ventas@quimand.com.pe.'),
  ('abastecedora andina', 'Cía. Minera Abastecedora Andina', 'Lima', 'El Agustino', null, '비금속광물 분쇄·가공(El Agustino). 미분 탄산칼슘 325·400·Super 1000 mesh.', 'Cía. Minera Abastecedora Andina S.A.C., Av. 1 de Mayo 2359, Vicentelo Alto, El Agustino (Lima) - micronised calcium carbonate 325, 400 and Super 1000 mesh (directory data).', 'PE check 2026-10-15: current production to confirm. +51 1 385 0103.'),
  ('alpamayo', 'Molinos Calcáreos Alpamayo', 'Ancash', 'Carhuaz', null, 'Ancash Acopampa(Carhuaz) 석회석·탄산칼슘·석회 채굴·가공.', 'Molinos Calcáreos Alpamayo E.I.R.L., Carretera Huaraz - Caraz Km 229, Acopampa, Carhuaz (Ancash) - limestone, calcium carbonate, quick and hydrated lime for mining, building, agriculture, water treatment.', 'PE check 2026-10-15: raw-material source - a long haul to Lima mills. ventas@molinoscalcareoalpamayo.com.'),
  ('comando group', 'Comando Group', 'Arequipa', 'Arequipa', null, 'Arequipa 석회석·트래버틴·석고 채굴·가공, 고순도 탄산칼슘(95.36%).', 'Comando Group, Arequipa - limestone, travertine and gypsum quarrying, high-purity calcium carbonate (95.36 pct CaCO3) and asphalt filler.', 'PE check 2026-10-15: raw-material source only. Not added: Calidra Perú (quicklime, Callalli), ABC Carbon, Procasac, COPROCAL (lime and limestone). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'peru_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Mineralium (Carbomin)', 'GCC producer', 'Local GCC, paper named - FCC partner candidate 1', 'merchant', 'C', 'gcc'),
  ('OLAH Group', 'GCC producer', 'Automated GCC lines - OEM candidate', 'merchant', 'C', 'gcc'),
  ('Sociedad Minera Dogaresa', 'GCC producer', 'Custom-size GCC - co-development candidate', 'merchant', 'C', 'gcc'),
  ('Cía. Minera Abastecedora Andina', 'GCC producer', 'Fine dry GCC - raw material', 'merchant', 'C', 'gcc'),
  ('Molinos Calcáreos Alpamayo', 'Carbonate raw material', 'Limestone and carbonate - raw material', 'merchant', 'C', 'gcc'),
  ('Comando Group', 'Carbonate raw material', 'Limestone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'peru_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'PE', v.region, v.city, v.website, 'active', 'peru_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('papelera reyes|papel paracas', 'callao', 'reyes|paracas', 'Papelera Reyes - Callao', 'Callao', 'Callao', null, '1966년 Papeles Paracas 에서 시작한 현지 티슈 원지 제조사(Callao). 브랜드 Paracas·Sedita, 펄프 준비설비·티슈기 운영, 2018 신규 설비로 생산 3배.', 'Papelera Reyes S.A.C., Av. Néstor Gambetta 6693, Callao - tissue maker since Papeles Paracas (1966): stock preparation and tissue machines on about 12,000 m2, output tripled with new equipment in 2018 (Hergen machine). Brands Paracas, Sedita. About 20 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: tonnage not public. +51 1 577-5024, contactos.internacionales@papelparacas.com. Environmental study renewal approved 2024.'),
  ('papelera z[aá]rate', 'puente piedra', 'z[aá]rate', 'Papelera Zárate - Puente Piedra', 'Lima', 'Puente Piedra', null, '1966년부터 티슈 사업. Puente Piedra 에서 재생지·펄프로 티슈 점보롤(폭 2.42 m, 약 900 kg) 생산·공급, ISO 9001.', 'Papelera Zárate S.A.C., Panamericana Norte Km 24.5, Puente Piedra (Lima) - tissue since 1966, makes jumbo rolls (2.42 m width, 1.19 m diameter, about 900 kg) on recycled fibre and pulp for converters, ISO 9001.', 'PE check 2026-10-15: 2025 boiler and output-increase report was not approved by PRODUCE - do not count added capacity. areacomercial@pzarate.com.'),
  ('softys.*santa anita|protisa.*santa anita', 'santa anita', 'softys|protisa|cmpc', 'Softys Perú - Santa Anita', 'Lima', 'Santa Anita', null, 'CMPC Softys 페루 주력 티슈 제지·위생용품 공장(Av. Santa Rosa 550, Santa Anita). 2025 소매 점유율 44%.', 'Softys Perú (CMPC, ex Protisa) - main tissue and hygiene plant at Av. Santa Rosa 550, Santa Anita (Lima). About 44 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: tonnage not public.'),
  ('softys.*ca[nñ]ete|protisa.*ca[nñ]ete', 'ca[nñ]ete', 'softys|protisa|cmpc', 'Softys Perú - Cañete', 'Lima', 'Cañete', null, 'Softys 페루 Cañete 티슈 제지공장(2017, 1.4억 달러+, 페루 티슈 능력 약 70% 증가).', 'Softys Perú - Cañete tissue mill (2017, over USD 140 m, raised Peruvian tissue capacity by about 70 pct). Arequipa adds converting only (over 1,000 t/month finished goods, 2024).', 'PE check 2026-10-15: tonnage not public.'),
  ('kimberly.*per[uú]', 'puente piedra', 'kimberly', 'Kimberly-Clark Perú - Puente Piedra', 'Lima', 'Puente Piedra', null, 'Kimberly-Clark 페루 Puente Piedra 티슈 공장(Suave·Scott). 2025 소매 점유율 26%, 생물학적 수처리·열병합.', 'Kimberly-Clark Perú - Puente Piedra (Lima) tissue plant (Suave toilet tissue, Scott towels), biological water treatment and cogeneration (60 pct of its power). About 26 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: later public mentions of a business or asset transfer - confirm the operating company and buyer before contact (possibly Arbex).'),
  ('carvimsa|cartones villa marina', 'huachipa', 'carvimsa|villa marina', 'CARVIMSA - Huachipa', 'Lima', 'Huachipa', null, 'Cartones Villa Marina(CARVIMSA, 1974~) — 2010 Huachipa 자체 제지공장, 2018 특수지, 2024 제지 능력 20%+ 확대. 원지→골판지 통합.', 'CARVIMSA - Cartones Villa Marina S.A. (since 1974, COMECA-related) - own paper mill at Huachipa (Lima) since 2010, specialty papers since 2018, mill capacity up over 20 pct in 2024 with more planned in 2025, integrated through corrugated boxes (also Villa El Salvador).', 'PE check 2026-10-15: tonnage not public. +51 1 201-6600. Same district as Mineralium.'),
  ('trupal.*trujillo', 'trujillo', 'trupal', 'Trupal - Trujillo', 'La Libertad', 'Trujillo', null, 'Grupo Gloria 계열 Trupal — 재생섬유 골판지 원지·포장지, 제지공장 Lima·Trujillo, 전체 연 약 30만 t(2025).', 'Trupal S.A. (Grupo Gloria) - recycled-fibre corrugating base paper and packaging paper, paper mills in Trujillo and Lima, integrated to boxes, company capacity about 300,000 t/yr (2025 report), also Sullana.', 'PE check 2026-10-15: 300 kt company total kept on this row only.'),
  ('trupal.*lima', 'lima', 'trupal', 'Trupal - Lima', 'Lima', 'Lima', null, 'Trupal Lima 제지공장.', 'Trupal S.A. (Grupo Gloria) - Lima paper mill.', 'PE check 2026-10-15: capacity within the Trupal total on the Trujillo row.'),
  ('papelera nacional.*paramonga|panasa.*paramonga', 'paramonga', 'papelera nacional|panasa', 'Papelera Nacional (PANASA) - Paramonga', 'Lima', 'Paramonga', null, '페루 Papelera Nacional — Paramonga(Panamericana Norte Km 200) 종이 제조·가공 공장, 제지기 개선·기관용 라인 계획.', 'Papelera Nacional S.A. (Peru), Av. Julio Peschiera s/n, Panamericana Norte Km 200, Paramonga - paper making and converting (2023 government record), paper-machine upgrade and an institutional-products line planned (2025).', 'PE check 2026-10-15: not the Ecuadorian PANASA - its 165 kt figure does not apply. Grades and tonnage to confirm.'),
  ('papelera del sur', 'chincha', 'papelera del sur', 'Papelera del Sur - Chincha Baja', 'Ica', 'Chincha Baja', null, 'Ica Chincha Baja(Panamericana Sur Km 202) 종이 공장. 2021 생산능력 71% 증설 승인.', 'Papelera del Sur S.A. (Peru), Carretera Panamericana Sur Km 202, Chincha Baja (Ica) - paper plant, 71 pct capacity increase approved 2021-12.', 'PE check 2026-10-15: grade and output unknown. papeleradelsur.com.ar is an unrelated Argentine company.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PE check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera reyes|papel paracas', 'callao', 'reyes|paracas', '1966년 Papeles Paracas 에서 시작한 현지 티슈 원지 제조사(Callao). 브랜드 Paracas·Sedita, 펄프 준비설비·티슈기 운영, 2018 신규 설비로 생산 3배.', 'Papelera Reyes S.A.C., Av. Néstor Gambetta 6693, Callao - tissue maker since Papeles Paracas (1966): stock preparation and tissue machines on about 12,000 m2, output tripled with new equipment in 2018 (Hergen machine). Brands Paracas, Sedita. About 20 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: tonnage not public. +51 1 577-5024, contactos.internacionales@papelparacas.com. Environmental study renewal approved 2024.'),
  ('papelera z[aá]rate', 'puente piedra', 'z[aá]rate', '1966년부터 티슈 사업. Puente Piedra 에서 재생지·펄프로 티슈 점보롤(폭 2.42 m, 약 900 kg) 생산·공급, ISO 9001.', 'Papelera Zárate S.A.C., Panamericana Norte Km 24.5, Puente Piedra (Lima) - tissue since 1966, makes jumbo rolls (2.42 m width, 1.19 m diameter, about 900 kg) on recycled fibre and pulp for converters, ISO 9001.', 'PE check 2026-10-15: 2025 boiler and output-increase report was not approved by PRODUCE - do not count added capacity. areacomercial@pzarate.com.'),
  ('softys.*santa anita|protisa.*santa anita', 'santa anita', 'softys|protisa|cmpc', 'CMPC Softys 페루 주력 티슈 제지·위생용품 공장(Av. Santa Rosa 550, Santa Anita). 2025 소매 점유율 44%.', 'Softys Perú (CMPC, ex Protisa) - main tissue and hygiene plant at Av. Santa Rosa 550, Santa Anita (Lima). About 44 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: tonnage not public.'),
  ('softys.*ca[nñ]ete|protisa.*ca[nñ]ete', 'ca[nñ]ete', 'softys|protisa|cmpc', 'Softys 페루 Cañete 티슈 제지공장(2017, 1.4억 달러+, 페루 티슈 능력 약 70% 증가).', 'Softys Perú - Cañete tissue mill (2017, over USD 140 m, raised Peruvian tissue capacity by about 70 pct). Arequipa adds converting only (over 1,000 t/month finished goods, 2024).', 'PE check 2026-10-15: tonnage not public.'),
  ('kimberly.*per[uú]', 'puente piedra', 'kimberly', 'Kimberly-Clark 페루 Puente Piedra 티슈 공장(Suave·Scott). 2025 소매 점유율 26%, 생물학적 수처리·열병합.', 'Kimberly-Clark Perú - Puente Piedra (Lima) tissue plant (Suave toilet tissue, Scott towels), biological water treatment and cogeneration (60 pct of its power). About 26 pct of Peruvian retail tissue value (2025).', 'PE check 2026-10-15: later public mentions of a business or asset transfer - confirm the operating company and buyer before contact (possibly Arbex).'),
  ('carvimsa|cartones villa marina', 'huachipa', 'carvimsa|villa marina', 'Cartones Villa Marina(CARVIMSA, 1974~) — 2010 Huachipa 자체 제지공장, 2018 특수지, 2024 제지 능력 20%+ 확대. 원지→골판지 통합.', 'CARVIMSA - Cartones Villa Marina S.A. (since 1974, COMECA-related) - own paper mill at Huachipa (Lima) since 2010, specialty papers since 2018, mill capacity up over 20 pct in 2024 with more planned in 2025, integrated through corrugated boxes (also Villa El Salvador).', 'PE check 2026-10-15: tonnage not public. +51 1 201-6600. Same district as Mineralium.'),
  ('trupal.*trujillo', 'trujillo', 'trupal', 'Grupo Gloria 계열 Trupal — 재생섬유 골판지 원지·포장지, 제지공장 Lima·Trujillo, 전체 연 약 30만 t(2025).', 'Trupal S.A. (Grupo Gloria) - recycled-fibre corrugating base paper and packaging paper, paper mills in Trujillo and Lima, integrated to boxes, company capacity about 300,000 t/yr (2025 report), also Sullana.', 'PE check 2026-10-15: 300 kt company total kept on this row only.'),
  ('trupal.*lima', 'lima', 'trupal', 'Trupal Lima 제지공장.', 'Trupal S.A. (Grupo Gloria) - Lima paper mill.', 'PE check 2026-10-15: capacity within the Trupal total on the Trujillo row.'),
  ('papelera nacional.*paramonga|panasa.*paramonga', 'paramonga', 'papelera nacional|panasa', '페루 Papelera Nacional — Paramonga(Panamericana Norte Km 200) 종이 제조·가공 공장, 제지기 개선·기관용 라인 계획.', 'Papelera Nacional S.A. (Peru), Av. Julio Peschiera s/n, Panamericana Norte Km 200, Paramonga - paper making and converting (2023 government record), paper-machine upgrade and an institutional-products line planned (2025).', 'PE check 2026-10-15: not the Ecuadorian PANASA - its 165 kt figure does not apply. Grades and tonnage to confirm.'),
  ('papelera del sur', 'chincha', 'papelera del sur', 'Ica Chincha Baja(Panamericana Sur Km 202) 종이 공장. 2021 생산능력 71% 증설 승인.', 'Papelera del Sur S.A. (Peru), Carretera Panamericana Sur Km 202, Chincha Baja (Ica) - paper plant, 71 pct capacity increase approved 2021-12.', 'PE check 2026-10-15: grade and output unknown. papeleradelsur.com.ar is an unrelated Argentine company.'),
  ('campoy', null, 'campoy', null, null, 'PE check 2026-10-15: Tissue base paper (older data) - operation to confirm - context only.'),
  ('papelera panamericana', null, 'papelera panamericana', null, null, 'PE check 2026-10-15: Tissue (older data) - operation to confirm - context only.'),
  ('chasqui', null, 'chasqui', null, null, 'PE check 2026-10-15: Tissue products - making or converting unknown - context only.'),
  ('schroth', null, 'schroth', null, null, 'PE check 2026-10-15: Paper - products to confirm - context only.'),
  ('softys.*arequipa|protisa.*arequipa', null, 'softys.*arequipa|protisa.*arequipa', null, null, 'PE check 2026-10-15: Converting lines (2024) - no paper machine - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'peru_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera reyes|papel paracas', 'callao', 'reyes|paracas'),
  ('papelera z[aá]rate', 'puente piedra', 'z[aá]rate'),
  ('softys.*santa anita|protisa.*santa anita', 'santa anita', 'softys|protisa|cmpc'),
  ('softys.*ca[nñ]ete|protisa.*ca[nñ]ete', 'ca[nñ]ete', 'softys|protisa|cmpc'),
  ('kimberly.*per[uú]', 'puente piedra', 'kimberly'),
  ('carvimsa|cartones villa marina', 'huachipa', 'carvimsa|villa marina'),
  ('trupal.*trujillo', 'trujillo', 'trupal'),
  ('trupal.*lima', 'lima', 'trupal'),
  ('papelera nacional.*paramonga|panasa.*paramonga', 'paramonga', 'papelera nacional|panasa'),
  ('papelera del sur', 'chincha', 'papelera del sur'),
  ('campoy', null, 'campoy'),
  ('papelera panamericana', null, 'papelera panamericana'),
  ('chasqui', null, 'chasqui'),
  ('schroth', null, 'schroth'),
  ('softys.*arequipa|protisa.*arequipa', null, 'softys.*arequipa|protisa.*arequipa')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera reyes|papel paracas', 'callao', 'reyes|paracas',
   $pj${"owner": "Corporación Reyes", "priority": 1, "products": "Toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "pitch": "Tissue FCC 1-5 pct stepwise trial", "approach": "Independent - fast decision, first Peruvian trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera z[aá]rate', 'puente piedra', 'z[aá]rate',
   $pj${"owner": "Papelera Zárate", "priority": 2, "products": "Tissue jumbo rolls (recycled and pulp)", "grades": ["Tissue"], "pitch": "Fibre-cost saving on recycled tissue", "approach": "Check ash balance and retention on recycled furnish first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*santa anita|protisa.*santa anita', 'santa anita', 'softys|protisa|cmpc',
   $pj${"owner": "Softys (CMPC)", "priority": 3, "products": "Toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "approach": "Group-level technical approval - links to Softys Chile, Uruguay, Argentina, Brazil.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*ca[nñ]ete|protisa.*ca[nñ]ete', 'ca[nñ]ete', 'softys|protisa|cmpc',
   $pj${"owner": "Softys (CMPC)", "priority": 3, "products": "Tissue base paper", "grades": ["Tissue"], "approach": "Newest Softys Peru machine - trial site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*per[uú]', 'puente piedra', 'kimberly',
   $pj${"owner": "Kimberly-Clark (confirm current operator)", "priority": 4, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "approach": "Confirm operator first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('carvimsa|cartones villa marina', 'huachipa', 'carvimsa|villa marina',
   $pj${"owner": "CARVIMSA", "priority": 5, "products": "Corrugating base paper, specialty packaging paper", "grades": ["Testliner", "Medium", "Specialty paper"], "pitch": "Joint trial with Mineralium (same Huachipa area)", "approach": "Packaging strength first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('trupal.*trujillo', 'trujillo', 'trupal',
   $pj${"owner": "Trupal (Grupo Gloria)", "priority": 6, "products": "Corrugating base paper, packaging paper", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "Trupal total (2025)", "value_t": 300000}], "approach": "SCT, RCT, burst trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('trupal.*lima', 'lima', 'trupal',
   $pj${"owner": "Trupal (Grupo Gloria)", "priority": 6, "products": "Corrugating base paper", "grades": ["Testliner", "Medium"], "approach": "After Trujillo.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera nacional.*paramonga|panasa.*paramonga', 'paramonga', 'papelera nacional|panasa',
   $pj${"owner": "Papelera Nacional (Peru)", "priority": 7, "products": "Paper and paper products", "approach": "Confirm grades first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera del sur', 'chincha', 'papelera del sur',
   $pj${"owner": "Papelera del Sur (Peru)", "priority": 8, "products": "Industrial paper (to confirm)", "approach": "Confirm grade first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('campoy', null, 'campoy',
   $pj${"owner": "Papelera Campoy", "products": "Tissue base paper (older data) - operation to confirm", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera panamericana', null, 'papelera panamericana',
   $pj${"owner": "Papelera Panamericana", "products": "Tissue (older data) - operation to confirm", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('chasqui', null, 'chasqui',
   $pj${"owner": "Compañía Papelera El Chasqui", "products": "Tissue products - making or converting unknown", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('schroth', null, 'schroth',
   $pj${"owner": "Schroth Corporación Papelera", "products": "Paper - products to confirm", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*arequipa|protisa.*arequipa', null, 'softys.*arequipa|protisa.*arequipa',
   $pj${"owner": "Softys Perú Arequipa", "products": "Converting lines (2024) - no paper machine", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PE', 'Peru', 'medium',
   $cm$Tissue (Softys 44 pct, Kimberly-Clark 26, Reyes 20) plus recycled packaging (Trupal, CARVIMSA) - local GCC grinders, no paper PCC$cm$,
   $cm$Peru has no paper PCC plant and no Omya site. Local GCC: Mineralium (Huachipa, paper named), OLAH Group (five automated lines), Dogaresa, Abastecedora Andina, plus raw material at Alpamayo and Comando. Imports of calcium carbonate USD 5.5 m (2024), mostly Spanish (Reverté). Paper machines: tissue at Papelera Reyes (Callao), Papelera Zárate (Puente Piedra), Softys (Santa Anita, Cañete), Kimberly-Clark (Puente Piedra), and packaging at Trupal (about 300 kt, Trujillo and Lima), CARVIMSA (Huachipa), PANASA Paramonga, Papelera del Sur.$cm$,
   $cm${"fillers": "GCC: Mineralium (325-600 mesh, paper named), OLAH Group (Lurín, 5 lines), Dogaresa (Ate, since 1962), Abastecedora Andina (Super 1000 mesh), Alpamayo and Comando (raw material). Lime only, not added: Calidra Perú, ABC Carbon, Procasac, COPROCAL. HS 283650 imports 2024 USD 5.54 m, Spain about USD 4.3 m.", "mills": "Tissue: Papelera Reyes Callao, Papelera Zárate Puente Piedra, Softys Santa Anita and Cañete, Kimberly-Clark Puente Piedra. Packaging: Trupal Trujillo and Lima, CARVIMSA Huachipa, PANASA Paramonga, Papelera del Sur Chincha. Context: Campoy, Panamericana, El Chasqui, Schroth, Softys Arequipa (converting).", "strategy": "Fast trials at Reyes and Zárate, then Softys and Kimberly-Clark at group level. Mineralium or OLAH as local licensed FCC producer - pilot Mineralium with CARVIMSA in Huachipa.", "risks": "Tonnage mostly unpublished. Kimberly-Clark operator may change.", "next_steps": ["Contact Papelera Reyes for a tissue trial", "Ask Mineralium for paper-grade specs"], "key_numbers": [{"label": "Retail tissue shares 2025", "value": "Softys 44, Kimberly-Clark 26, Reyes 20 pct (Euromonitor)"}, {"label": "Tissue output 2018", "value": "about 199 kt (historical)"}, {"label": "Trupal", "value": "about 300 kt/yr (2025)"}], "files": ["seed_20261016i_peru_mills_fillers"]}$cm$::jsonb,
   $cm$티슈(Softys 44%·Kimberly-Clark 26%·Reyes 20%) + 재생 포장지(Trupal·CARVIMSA) — 현지 GCC 분쇄업체, 제지용 PCC 없음$cm$,
   $cm$페루에는 제지용 PCC 공장·Omya 거점 없음. 현지 GCC: Mineralium(Huachipa, 제지 명시)·OLAH(자동화 5라인)·Dogaresa·Abastecedora Andina. 탄산칼슘 수입 554만 달러(2024, 스페인 Reverté 중심). 초지: 티슈 Papelera Reyes·Zárate·Softys(Santa Anita·Cañete)·Kimberly-Clark, 포장 Trupal(약 30만 t)·CARVIMSA·PANASA Paramonga·Papelera del Sur.$cm$,
   6000, 10000,
   $cm$티슈 생산 약 20만 t(2018 과거 자료) × FCC 3~5% — 개별 공장 톤수 미공개$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('papelera reyes|papel paracas', 'callao', 'reyes|paracas'),
  ('papelera z[aá]rate', 'puente piedra', 'z[aá]rate'),
  ('softys.*santa anita|protisa.*santa anita', 'santa anita', 'softys|protisa|cmpc'),
  ('softys.*ca[nñ]ete|protisa.*ca[nñ]ete', 'ca[nñ]ete', 'softys|protisa|cmpc'),
  ('kimberly.*per[uú]', 'puente piedra', 'kimberly'),
  ('carvimsa|cartones villa marina', 'huachipa', 'carvimsa|villa marina'),
  ('trupal.*trujillo', 'trujillo', 'trupal'),
  ('trupal.*lima', 'lima', 'trupal'),
  ('papelera nacional.*paramonga|panasa.*paramonga', 'paramonga', 'papelera nacional|panasa'),
  ('papelera del sur', 'chincha', 'papelera del sur'),
  ('campoy', null, 'campoy'),
  ('papelera panamericana', null, 'papelera panamericana'),
  ('chasqui', null, 'chasqui'),
  ('schroth', null, 'schroth'),
  ('softys.*arequipa|protisa.*arequipa', null, 'softys.*arequipa|protisa.*arequipa')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'peru_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'peru_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'mineralium' or p.party_name ~* '\molah\M' or p.party_name ~* 'dogaresa' or p.party_name ~* 'abastecedora andina' or p.party_name ~* 'alpamayo' or p.party_name ~* 'comando group')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'PE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'PE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'PE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    