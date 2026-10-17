-- ============================================================
-- seed_20261016zd_greece_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Greece update (reports 2026-10-16).
-- 1) Fillers if missing (6): Omya Hellas, IOKAL, Industrial Minerals Greece,
--    Microfill, Dionyssomarble, Powder Ltd.
-- 2) Mills if missing (5) + plant blocks, priority 1-5: Intertrade Hellas,
--    MAXI, MEL, ELITE, UNIPAKHELLAS. Context (2): DS Smith Hellas, Dunapack.
-- 3) app.country_markets GR row (priority medium).
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
           v.party_name, 'GR', v.region, v.city, v.website, 'active', 'greece_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(hellas|greece)', 'Omya Hellas - Sindos', 'Central Macedonia', 'Sindos', null, 'Omya 그리스 법인(Sindos, 2003~) GCC — 과거 연 8~9만 t·수출 6만 t+, 제지·도료·폴리머. 2026 구조개편: Omya Hellas 가 탄산칼슘 사업 유지.', 'Omya Hellas S.A., Sindos Industrial Area, Thessaloniki - GCC since 2003 (about 80,000-90,000 t/yr, over 60,000 t exported in 2013-2014 data) for paper, paint, polymers, coatings, adhesives. 2026 reorganisation keeps carbonate resources, micronised marble and group carbonate sales in Omya Hellas (specialty chemicals moved to Omya Specialty Materials Greece).', 'GR check 2026-10-16: PCC in Greece not confirmed. Royalty licensee at Omya HQ level.'),
  ('iokal|ionian kalk', 'IONIAN KALK (IOKAL) - Kefalonia', 'Ionian Islands', 'Kefalonia', null, '그리스 대표 독립 탄산칼슘 그룹 IOKAL(1979) — Kefalonia·Mandra·Kavala 3개 공장. 미분 40 μm 미만 연 45만 t, 입상 19만 t, 탈크 4만 t. 제지 충전·코팅 안료 명시, 케팔로니아 원료 CaCO3 99.6%+, Fe2O3 0.01% 미만.', 'IONIAN KALK S.A. (IOKAL, 1979) - plants at Kefalonia, Mandra (Attica) and Kavala: micronised carbonate under 40 micron 450,000 t/yr, crystalline granules 190,000 t/yr, micronised talc 40,000 t/yr (nominal). Paper filler and paper coating pigment named. Kefalonia stone over 99.6 pct CaCO3, Fe2O3 under 0.01 pct, brightness over 96 in older data.', 'GR check 2026-10-16: paper share of output not public. Kefalonia +30 26710 41844, Mandra +30 210 555 2395, Kavala +30 2510 361 508. Independent - FCC licence and OEM candidate 1. KarboKal (IOKAL-related) not added separately.'),
  ('industrial minerals greece', 'Industrial Minerals Greece (IMG) - Nea Karvali', 'Eastern Macedonia and Thrace', 'Nea Karvali', null, '2006년 Imerys·Vougiouklis 참여 설립(Nea Karvali, Kavala). 제지용 탄산칼슘 가공·수출(북유럽·중남미), Vougiouklis 채석장 72만 m², 투자 약 1,000만 유로.', 'Industrial Minerals Greece S.A. (IMG, 2006, set up with Imerys and Vougiouklis), Nea Karvali (Kavala) - calcium carbonate processing and export mainly for paper (northern Europe, Latin America), raw material of Vougiouklis quarries (about 720,000 m2), about EUR 10 m investment.', 'GR check 2026-10-16: current shareholders and output not confirmed - do not assume an Imerys stake.'),
  ('microfill|zafranas', 'Microfill (K. Zafranas) - Corinth', 'Peloponnese', 'Corinth', null, '1949년부터 광물 가공, Corinth 공장(1979) 연 약 13만 t(75% 수출), 탄산칼슘 광산 3곳, 초미분쇄·분급·표면처리.', 'Microfill K. Zafranas S.A. (minerals since 1949, Corinth plant 1979) - GCC, talc and dolomite, about 130,000 t/yr with about 75 pct exported, three own carbonate quarries, ultrafine grinding, classification and surface treatment, mainly paint and plastics.', 'GR check 2026-10-16: paper sales not confirmed. +30 27410 26573.'),
  ('dionyssomarble', 'Dionyssomarble - Dionysos', 'Attica', 'Dionysos', null, '백색 대리석 기업 Dionyssomarble(Dionysos, Drama) — 대리석 분말·탄산칼슘 충전제.', 'Dionyssomarble S.A., Dionysos (Attica) and Drama - white-marble quarrying with marble powders and calcium carbonate fillers made of quarry by-product.', 'GR check 2026-10-16: paper grades not confirmed. +30 210 6211400.'),
  ('powder ltd', 'Powder Ltd - Oinoi (Kozani)', 'Western Macedonia', 'Kozani', null, 'Kozani Oinoi 분쇄 탄산칼슘(CaCO3 약 96%), 가공 연 약 8만 t, 건축자재용.', 'Powder Ltd, Oinoi (Kozani) - ground calcium carbonate about 96 pct CaCO3, about 80,000 t/yr processed and 40,000 t/yr raw stone, mainly building materials.', 'GR check 2026-10-16: paper grade not confirmed. Not added: Granule (to confirm). No paper PCC plant in Greece. Industry nominal GCC capacity 400-500 kt in 2013-2014, over 80 pct exported.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(hellas|greece)', 'Omya Hellas - Sindos', 'Central Macedonia', 'Sindos', null, 'Omya 그리스 법인(Sindos, 2003~) GCC — 과거 연 8~9만 t·수출 6만 t+, 제지·도료·폴리머. 2026 구조개편: Omya Hellas 가 탄산칼슘 사업 유지.', 'Omya Hellas S.A., Sindos Industrial Area, Thessaloniki - GCC since 2003 (about 80,000-90,000 t/yr, over 60,000 t exported in 2013-2014 data) for paper, paint, polymers, coatings, adhesives. 2026 reorganisation keeps carbonate resources, micronised marble and group carbonate sales in Omya Hellas (specialty chemicals moved to Omya Specialty Materials Greece).', 'GR check 2026-10-16: PCC in Greece not confirmed. Royalty licensee at Omya HQ level.'),
  ('iokal|ionian kalk', 'IONIAN KALK (IOKAL) - Kefalonia', 'Ionian Islands', 'Kefalonia', null, '그리스 대표 독립 탄산칼슘 그룹 IOKAL(1979) — Kefalonia·Mandra·Kavala 3개 공장. 미분 40 μm 미만 연 45만 t, 입상 19만 t, 탈크 4만 t. 제지 충전·코팅 안료 명시, 케팔로니아 원료 CaCO3 99.6%+, Fe2O3 0.01% 미만.', 'IONIAN KALK S.A. (IOKAL, 1979) - plants at Kefalonia, Mandra (Attica) and Kavala: micronised carbonate under 40 micron 450,000 t/yr, crystalline granules 190,000 t/yr, micronised talc 40,000 t/yr (nominal). Paper filler and paper coating pigment named. Kefalonia stone over 99.6 pct CaCO3, Fe2O3 under 0.01 pct, brightness over 96 in older data.', 'GR check 2026-10-16: paper share of output not public. Kefalonia +30 26710 41844, Mandra +30 210 555 2395, Kavala +30 2510 361 508. Independent - FCC licence and OEM candidate 1. KarboKal (IOKAL-related) not added separately.'),
  ('industrial minerals greece', 'Industrial Minerals Greece (IMG) - Nea Karvali', 'Eastern Macedonia and Thrace', 'Nea Karvali', null, '2006년 Imerys·Vougiouklis 참여 설립(Nea Karvali, Kavala). 제지용 탄산칼슘 가공·수출(북유럽·중남미), Vougiouklis 채석장 72만 m², 투자 약 1,000만 유로.', 'Industrial Minerals Greece S.A. (IMG, 2006, set up with Imerys and Vougiouklis), Nea Karvali (Kavala) - calcium carbonate processing and export mainly for paper (northern Europe, Latin America), raw material of Vougiouklis quarries (about 720,000 m2), about EUR 10 m investment.', 'GR check 2026-10-16: current shareholders and output not confirmed - do not assume an Imerys stake.'),
  ('microfill|zafranas', 'Microfill (K. Zafranas) - Corinth', 'Peloponnese', 'Corinth', null, '1949년부터 광물 가공, Corinth 공장(1979) 연 약 13만 t(75% 수출), 탄산칼슘 광산 3곳, 초미분쇄·분급·표면처리.', 'Microfill K. Zafranas S.A. (minerals since 1949, Corinth plant 1979) - GCC, talc and dolomite, about 130,000 t/yr with about 75 pct exported, three own carbonate quarries, ultrafine grinding, classification and surface treatment, mainly paint and plastics.', 'GR check 2026-10-16: paper sales not confirmed. +30 27410 26573.'),
  ('dionyssomarble', 'Dionyssomarble - Dionysos', 'Attica', 'Dionysos', null, '백색 대리석 기업 Dionyssomarble(Dionysos, Drama) — 대리석 분말·탄산칼슘 충전제.', 'Dionyssomarble S.A., Dionysos (Attica) and Drama - white-marble quarrying with marble powders and calcium carbonate fillers made of quarry by-product.', 'GR check 2026-10-16: paper grades not confirmed. +30 210 6211400.'),
  ('powder ltd', 'Powder Ltd - Oinoi (Kozani)', 'Western Macedonia', 'Kozani', null, 'Kozani Oinoi 분쇄 탄산칼슘(CaCO3 약 96%), 가공 연 약 8만 t, 건축자재용.', 'Powder Ltd, Oinoi (Kozani) - ground calcium carbonate about 96 pct CaCO3, about 80,000 t/yr processed and 40,000 t/yr raw stone, mainly building materials.', 'GR check 2026-10-16: paper grade not confirmed. Not added: Granule (to confirm). No paper PCC plant in Greece. Industry nominal GCC capacity 400-500 kt in 2013-2014, over 80 pct exported.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'greece_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Hellas - Sindos', 'GCC producer', 'Omya Greece - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('IONIAN KALK (IOKAL) - Kefalonia', 'GCC producer', 'Independent paper GCC - FCC licence candidate 1', 'merchant', 'B', 'gcc'),
  ('Industrial Minerals Greece (IMG) - Nea Karvali', 'GCC producer', 'Paper-focused GCC exporter', 'merchant', 'B', 'gcc'),
  ('Microfill (K. Zafranas) - Corinth', 'GCC producer', 'Ultrafine GCC (paint, plastics)', 'merchant', 'C', 'gcc'),
  ('Dionyssomarble - Dionysos', 'GCC producer', 'Marble carbonate filler', 'merchant', 'C', 'gcc'),
  ('Powder Ltd - Oinoi (Kozani)', 'GCC producer', 'Building-grade GCC', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'greece_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'GR', v.region, v.city, v.website, 'active', 'greece_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('intertrade', 'oinofyta', 'intertrade', 'Intertrade Hellas - Oinofyta', 'Central Greece', 'Oinofyta', null, '1992년 설립 티슈 원지 제조(Oinofyta 공장, 본사 Acharnes). Softex·Servin. 2026-02 Toscotec AHEAD 2.2L 2호기(연 8만 t, 5,600 mm, 2,200 m/분) 가동 — 공장 합계 14만 t 초과.', 'Intertrade Hellas S.A. (1992), HQ Iviskou 99, Acharnes - tissue mill at Oinofyta (Boeotia): second machine Toscotec AHEAD 2.2L with shoe press started 2026-02-24 (80,000 t/yr, 5,600 mm, 2,200 m/min), site total over 140,000 t/yr. Toilet, kitchen, facial, napkins, jumbo rolls, private label (Softex, Servin).', 'GR check 2026-10-16: info@intertrade-hellas.gr, +30 210 2400840.'),
  ('\mmaxi\M', 'katerini', 'maxi', 'MAXI - Katerini', 'Central Macedonia', 'Katerini', null, 'Katerini 티슈 제조사 MAXI — 자체 원지공장 2곳 연 7.5만 t, 가공라인 17개, 수출 약 17%.', 'MAXI S.A., 1st km Katerini - Thessaloniki Old National Road, Katerini (Pieria) - two own tissue base-paper mills, 75,000 t/yr jumbo rolls, 17 converting lines, home and AfH tissue, about 17 pct exports.', 'GR check 2026-10-16: marketing@maxi.gr, +30 23510 31322. Near north-Greece carbonate plants (Omya Sindos).'),
  ('macedonian paper|\mmel\M.*paper|melpaper', 'gefyra|thessalon', 'macedonian|\mmel\M|pak group', 'MEL Macedonian Paper Mills - Gefyra', 'Central Macedonia', 'Gefyra', null, 'PAK Group 계열 MEL(1967~, Gefyra Thessaloniki) 재생 코팅판지 연 약 12만 t — Duplex R·Triplex BR·Kraft, 30여 개국 수출.', 'MEL Macedonian Paper Mills S.S.A. (since 1967, PAK Group since 2012), K. Gefyra, Thessaloniki - recycled coated board about 120,000 t/yr: Duplex R (300-550 gsm), Triplex BR (300-600 gsm), Kraft, exports to about 30 countries.', 'GR check 2026-10-16: info@melpaper.com, +30 2310 728000.'),
  ('\melite\M|patraiki', 'patra|ities', 'elite|patraiki', 'ELITE (Patraiki Chartopoiia) - Patras', 'Western Greece', 'Patras', null, '1972년 설립, 1979년부터 자체 종이 생산 Patras 티슈 제조사 — 화장지·키친타월·냅킨.', 'Patraiki Chartopoiia - ELITE (1972, own paper since 1979), Kranau 2, Ities, Patras - toilet tissue, kitchen towel, napkins, tableware paper.', 'GR check 2026-10-16: machines and capacity not public. reception@elite.gr, +30 2610 520397.'),
  ('unipakhellas', 'pelasgia', 'unipak|indevco', 'UNIPAKHELLAS - Pelasgia', 'Central Greece', 'Pelasgia', null, 'INDEVCO 계열 UNIPAKHELLAS(2008) — 자체 제지공장 재생 테스트라이너·골심지(그리스 폐지 최대 40% 처리) + 골판지 상자.', 'UNIPAKHELLAS S.A. (INDEVCO group, 2008), Pelasgia (Fthiotida) and Thessaloniki - own mill making recycled testliner and fluting (uses up to about 40 pct of Greek recovered paper, 2024) plus corrugated sheets and boxes.', 'GR check 2026-10-16: base-paper capacity not public. info@unipakhellas.gr. Same group as Unipakcyprus.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('intertrade', 'oinofyta', 'intertrade', '1992년 설립 티슈 원지 제조(Oinofyta 공장, 본사 Acharnes). Softex·Servin. 2026-02 Toscotec AHEAD 2.2L 2호기(연 8만 t, 5,600 mm, 2,200 m/분) 가동 — 공장 합계 14만 t 초과.', 'Intertrade Hellas S.A. (1992), HQ Iviskou 99, Acharnes - tissue mill at Oinofyta (Boeotia): second machine Toscotec AHEAD 2.2L with shoe press started 2026-02-24 (80,000 t/yr, 5,600 mm, 2,200 m/min), site total over 140,000 t/yr. Toilet, kitchen, facial, napkins, jumbo rolls, private label (Softex, Servin).', 'GR check 2026-10-16: info@intertrade-hellas.gr, +30 210 2400840.'),
  ('\mmaxi\M', 'katerini', 'maxi', 'Katerini 티슈 제조사 MAXI — 자체 원지공장 2곳 연 7.5만 t, 가공라인 17개, 수출 약 17%.', 'MAXI S.A., 1st km Katerini - Thessaloniki Old National Road, Katerini (Pieria) - two own tissue base-paper mills, 75,000 t/yr jumbo rolls, 17 converting lines, home and AfH tissue, about 17 pct exports.', 'GR check 2026-10-16: marketing@maxi.gr, +30 23510 31322. Near north-Greece carbonate plants (Omya Sindos).'),
  ('macedonian paper|\mmel\M.*paper|melpaper', 'gefyra|thessalon', 'macedonian|\mmel\M|pak group', 'PAK Group 계열 MEL(1967~, Gefyra Thessaloniki) 재생 코팅판지 연 약 12만 t — Duplex R·Triplex BR·Kraft, 30여 개국 수출.', 'MEL Macedonian Paper Mills S.S.A. (since 1967, PAK Group since 2012), K. Gefyra, Thessaloniki - recycled coated board about 120,000 t/yr: Duplex R (300-550 gsm), Triplex BR (300-600 gsm), Kraft, exports to about 30 countries.', 'GR check 2026-10-16: info@melpaper.com, +30 2310 728000.'),
  ('\melite\M|patraiki', 'patra|ities', 'elite|patraiki', '1972년 설립, 1979년부터 자체 종이 생산 Patras 티슈 제조사 — 화장지·키친타월·냅킨.', 'Patraiki Chartopoiia - ELITE (1972, own paper since 1979), Kranau 2, Ities, Patras - toilet tissue, kitchen towel, napkins, tableware paper.', 'GR check 2026-10-16: machines and capacity not public. reception@elite.gr, +30 2610 520397.'),
  ('unipakhellas', 'pelasgia', 'unipak|indevco', 'INDEVCO 계열 UNIPAKHELLAS(2008) — 자체 제지공장 재생 테스트라이너·골심지(그리스 폐지 최대 40% 처리) + 골판지 상자.', 'UNIPAKHELLAS S.A. (INDEVCO group, 2008), Pelasgia (Fthiotida) and Thessaloniki - own mill making recycled testliner and fluting (uses up to about 40 pct of Greek recovered paper, 2024) plus corrugated sheets and boxes.', 'GR check 2026-10-16: base-paper capacity not public. info@unipakhellas.gr. Same group as Unipakcyprus.'),
  ('ds smith', null, 'ds smith', null, null, 'GR check 2026-10-16: Corrugated plants at Sindos, Ancient Corinth, Ierapetra (EUR 33.9 m programme) - converter - context only.'),
  ('dunapack', null, 'dunapack', null, null, 'GR check 2026-10-16: Corrugated boxes, Schimatari - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'greece_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('intertrade', 'oinofyta', 'intertrade'),
  ('\mmaxi\M', 'katerini', 'maxi'),
  ('macedonian paper|\mmel\M.*paper|melpaper', 'gefyra|thessalon', 'macedonian|\mmel\M|pak group'),
  ('\melite\M|patraiki', 'patra|ities', 'elite|patraiki'),
  ('unipakhellas', 'pelasgia', 'unipak|indevco'),
  ('ds smith', null, 'ds smith'),
  ('dunapack', null, 'dunapack')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('intertrade', 'oinofyta', 'intertrade',
   $pj${"owner": "Intertrade Hellas", "priority": 1, "products": "Tissue jumbo rolls, toilet, kitchen, facial", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 140000, "unit": "metric_t", "year": "Company and Toscotec 2026 (2 machines)", "source": "toscotec.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range - planning only."}, "pitch": "Tissue FCC on the new AHEAD 2.2L line", "approach": "Lead Greek account - IOKAL or Omya Hellas as producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "PM2 start-up 2026-02", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mmaxi\M', 'katerini', 'maxi',
   $pj${"owner": "MAXI", "priority": 2, "products": "Tissue jumbo rolls, toilet, kitchen, AfH", "grades": ["Tissue"], "capacity": {"value": 75000, "unit": "metric_t", "year": "Company figure", "source": "maxi.gr"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Pair with Omya Hellas Sindos supply.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('macedonian paper|\mmel\M.*paper|melpaper', 'gefyra|thessalon', 'macedonian|\mmel\M|pak group',
   $pj${"owner": "PAK Group", "priority": 3, "products": "Recycled coated duplex and triplex board", "grades": ["Coated board"], "capacity": {"value": 120000, "unit": "metric_t", "year": "Company figure", "source": "melpaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Ply-level only."}, "approach": "Inner-ply trial - ply bond, stiffness, coating quality.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\melite\M|patraiki', 'patra|ities', 'elite|patraiki',
   $pj${"owner": "Patraiki Chartopoiia", "priority": 4, "products": "Tissue", "grades": ["Tissue"], "approach": "Collect machine data, then pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unipakhellas', 'pelasgia', 'unipak|indevco',
   $pj${"owner": "INDEVCO", "priority": 5, "products": "Recycled testliner, fluting, corrugated", "grades": ["Testliner", "Medium"], "approach": "Strength-hold trial - can open INDEVCO mills elsewhere.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith', null, 'ds smith',
   $pj${"owner": "DS Smith Hellas", "products": "Corrugated plants at Sindos, Ancient Corinth, Ierapetra (EUR 33.9 m programme) - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dunapack', null, 'dunapack',
   $pj${"owner": "Dunapack Packaging Hellas (Prinzhorn)", "products": "Corrugated boxes, Schimatari - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GR', 'Greece', 'medium',
   $cm$Intertrade (140 kt tissue, new Toscotec PM2 2026) and MAXI tissue plus MEL coated board - IOKAL and Omya Hellas paper GCC$cm$,
   $cm$Greece has a strong export GCC base (400-500 kt nominal in 2013-2014): IOKAL (paper filler and coating pigment, 450 kt micronised), Omya Hellas (Sindos, licensee), Industrial Minerals Greece (paper-focused, Kavala), Microfill (130 kt). No paper PCC. Mills: Intertrade Hellas (over 140 kt tissue after a Toscotec PM2 in 2026-02), MAXI (75 kt tissue, Katerini), MEL (120 kt recycled coated board), ELITE (Patras tissue), UNIPAKHELLAS (recycled liner, INDEVCO). Corrugated output 370.9 kt in 2025 (HPPA). No large printing-paper mill.$cm$,
   $cm${"fillers": "Paper GCC: IOKAL (Kefalonia, Mandra, Kavala), Omya Hellas (Sindos), Industrial Minerals Greece (Nea Karvali). Other GCC: Microfill (Corinth), Dionyssomarble, Powder Ltd. Not added: Granule, KarboKal. No PCC.", "mills": "Tissue: Intertrade Hellas Oinofyta, MAXI Katerini, ELITE Patras. Coated board: MEL Thessaloniki. Recycled liner: UNIPAKHELLAS Pelasgia. Converters (context): DS Smith Hellas, Dunapack Hellas.", "strategy": "Tissue trials at Intertrade and MAXI, then MEL board. IOKAL as independent FCC licensee or OEM, Omya Hellas via HQ. UNIPAKHELLAS opens INDEVCO.", "risks": "No printing-paper mill, packaging strength limits.", "next_steps": ["Approach Intertrade Hellas on the new PM2", "Propose an FCC licence to IOKAL"], "key_numbers": [{"label": "Intertrade Hellas", "value": "over 140 kt/yr tissue (2026)"}, {"label": "Corrugated output 2025", "value": "370.9 kt (HPPA)"}, {"label": "Report scenario", "value": "3,350 t FCC (20 pct of 335 kt x 5 pct)"}], "files": ["seed_20261016zd_greece_mills_fillers"]}$cm$::jsonb,
   $cm$Intertrade(티슈 14만 t, 2026 Toscotec PM2)·MAXI 티슈 + MEL 코팅판지 — IOKAL·Omya Hellas 제지용 GCC$cm$,
   $cm$그리스는 수출형 GCC 기반이 강함(2013~2014 명목 40만~50만 t): IOKAL(제지 충전·코팅, 미분 45만 t), Omya Hellas(Sindos, 라이선시), IMG(제지 중심, Kavala), Microfill(13만 t). 제지용 PCC 없음. 제지: Intertrade(2026-02 Toscotec PM2 후 14만 t+), MAXI(7.5만 t), MEL(재생 코팅판지 12만 t), ELITE(Patras), UNIPAKHELLAS(INDEVCO). 대형 인쇄용지 공장 없음.$cm$,
   3350, 6700,
   $cm$Intertrade·MAXI·MEL 33.5만 t × 적용 20~40% × FCC 5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('intertrade', 'oinofyta', 'intertrade'),
  ('\mmaxi\M', 'katerini', 'maxi'),
  ('macedonian paper|\mmel\M.*paper|melpaper', 'gefyra|thessalon', 'macedonian|\mmel\M|pak group'),
  ('\melite\M|patraiki', 'patra|ities', 'elite|patraiki'),
  ('unipakhellas', 'pelasgia', 'unipak|indevco'),
  ('ds smith', null, 'ds smith'),
  ('dunapack', null, 'dunapack')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'greece_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'greece_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(hellas|greece)' or p.party_name ~* 'iokal|ionian kalk' or p.party_name ~* 'industrial minerals greece' or p.party_name ~* 'microfill|zafranas' or p.party_name ~* 'dionyssomarble' or p.party_name ~* 'powder ltd')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    