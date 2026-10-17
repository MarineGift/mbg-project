-- ============================================================
-- seed_20261016zzi_poland_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Poland update (reports 2026-10-16). Fixed generator.
-- Kostrzyn has Arctic Paper and ICT - owner regex keeps them apart.
-- 1) Fillers if missing (4): SMI Poland Kwidzyn (satellite PCC), Omya Poland,
--    Nordkalk Poland, Lhoist Bukowa.
-- 2) Mills if missing (9) + plant blocks, priority 1-8: MM Kwidzyn, Arctic
--    Paper Kostrzyn, Velvet CARE, ICT Poland, Sofidel Ciechanów, Metsä Tissue
--    Krapkowice, WEPA Piechowice, Mondi Świecie. Stora Enso Ostrołęka no
--    priority. Context (3).
-- 3) Supply link (1): SMI -> MM Kwidzyn (active, to confirm).
-- 4) app.country_markets PL row (priority high).
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
           v.party_name, 'PL', v.region, v.city, v.website, 'active', 'poland_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('(specialty minerals|minerals technologies).*(pol|kwidzyn)', 'Specialty Minerals Poland - Kwidzyn (satellite PCC)', 'Pomeranian', 'Kwidzyn', null, 'MTI 폴란드 위성 PCC(Kwidzyn 제지공장 인접, 1990년대 중반~) — 과거 약 5만 t, SEC 공시 기록.', 'Specialty Minerals Poland (Minerals Technologies) satellite PCC next to the Kwidzyn mill since the mid-1990s, about 50,000 t/yr in older Polish Geological Institute data, listed in MTI SEC filings.', 'PL check 2026-10-16: 2026 status to confirm (mill now MM Kwidzyn). SMI is the MBG tissue-track partner (NDA).'),
  ('omya.*(pol|warsz|warsaw)', 'Omya Poland - Warszawa', 'Masovian', 'Warszawa', null, 'Omya Sp. z o.o.(al. Armii Ludowej 26, 바르샤바) — 제지용 GCC·PCC·코팅 안료·기술서비스.', 'Omya Sp. z o.o., al. Armii Ludowej 26, Warszawa - paper GCC, PCC, coating pigments and technical service for Polish paper and board mills.', 'PL check 2026-10-16: Polish production sites not identified. +48 22 525 8900. Royalty licensee at Omya HQ level.'),
  ('nordkalk.*(pol|wolica|ostr[oó]wka|s[lł]awno)', 'Nordkalk Poland', 'Świętokrzyskie', 'Wolica', null, 'Nordkalk 폴란드 — Wolica·Ostrówka·Sławno 석회석·석회석 분말·석회(제지용 GCC 원료는 핀란드).', 'Nordkalk Sp. z o.o. - limestone, limestone powder and lime at Wolica, Ostrówka and Sławno. Paper-grade GCC is made in Finland (Lappeenranta).', 'PL check 2026-10-16: raw material and PCC lime only.'),
  ('lhoist.*bukowa|bukowa', 'Lhoist Bukowa', 'Świętokrzyskie', 'Bukowa', null, 'Lhoist 폴란드 Bukowa·Tarnów Opolski 석회석·생석회.', 'Lhoist Bukowa - limestone, high-purity limestone powder and quicklime at Bukowa and Tarnów Opolski.', 'PL check 2026-10-16: PCC raw material only. Not added: Qemetica (ex CIECH, Inowrocław PCC about 20 kt in 2005, now not in its range, Janikowo soda stopping 2025), WKG, EGM, Labtar, Czatkowice (limestone powders 96-98 pct).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%PL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('(specialty minerals|minerals technologies).*(pol|kwidzyn)', 'Specialty Minerals Poland - Kwidzyn (satellite PCC)', 'Pomeranian', 'Kwidzyn', null, 'MTI 폴란드 위성 PCC(Kwidzyn 제지공장 인접, 1990년대 중반~) — 과거 약 5만 t, SEC 공시 기록.', 'Specialty Minerals Poland (Minerals Technologies) satellite PCC next to the Kwidzyn mill since the mid-1990s, about 50,000 t/yr in older Polish Geological Institute data, listed in MTI SEC filings.', 'PL check 2026-10-16: 2026 status to confirm (mill now MM Kwidzyn). SMI is the MBG tissue-track partner (NDA).'),
  ('omya.*(pol|warsz|warsaw)', 'Omya Poland - Warszawa', 'Masovian', 'Warszawa', null, 'Omya Sp. z o.o.(al. Armii Ludowej 26, 바르샤바) — 제지용 GCC·PCC·코팅 안료·기술서비스.', 'Omya Sp. z o.o., al. Armii Ludowej 26, Warszawa - paper GCC, PCC, coating pigments and technical service for Polish paper and board mills.', 'PL check 2026-10-16: Polish production sites not identified. +48 22 525 8900. Royalty licensee at Omya HQ level.'),
  ('nordkalk.*(pol|wolica|ostr[oó]wka|s[lł]awno)', 'Nordkalk Poland', 'Świętokrzyskie', 'Wolica', null, 'Nordkalk 폴란드 — Wolica·Ostrówka·Sławno 석회석·석회석 분말·석회(제지용 GCC 원료는 핀란드).', 'Nordkalk Sp. z o.o. - limestone, limestone powder and lime at Wolica, Ostrówka and Sławno. Paper-grade GCC is made in Finland (Lappeenranta).', 'PL check 2026-10-16: raw material and PCC lime only.'),
  ('lhoist.*bukowa|bukowa', 'Lhoist Bukowa', 'Świętokrzyskie', 'Bukowa', null, 'Lhoist 폴란드 Bukowa·Tarnów Opolski 석회석·생석회.', 'Lhoist Bukowa - limestone, high-purity limestone powder and quicklime at Bukowa and Tarnów Opolski.', 'PL check 2026-10-16: PCC raw material only. Not added: Qemetica (ex CIECH, Inowrocław PCC about 20 kt in 2005, now not in its range, Janikowo soda stopping 2025), WKG, EGM, Labtar, Czatkowice (limestone powders 96-98 pct).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'poland_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Specialty Minerals Poland - Kwidzyn (satellite PCC)', 'PCC producer', 'SMI satellite PCC at Kwidzyn - partner route', 'satellite', 'B', 'pcc'),
  ('Omya Poland - Warszawa', 'GCC and PCC supplier', 'Omya Poland - sales office, licensee group', 'merchant', 'C', 'gcc'),
  ('Nordkalk Poland', 'Lime and limestone producer', 'Limestone and lime - raw material', 'merchant', 'C', 'gcc'),
  ('Lhoist Bukowa', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'poland_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'PL', v.region, v.city, v.website, 'active', 'poland_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn', 'MM Kwidzyn', 'Pomeranian', 'Kwidzyn', null, 'MM Group MM Kwidzyn(ul. Lotnicza 1, 구 International Paper) — 백색 복사·오프셋용지·GC1/GC2 코팅판지·크라프트지·펄프, 종이·판지 연 66만 t(NBSK 8만 t 별도). SMI 위성 PCC 인접.', 'MM Kwidzyn (MM Group, formerly International Paper Kwidzyn), ul. Lotnicza 1, Kwidzyn - white copy and offset paper, GC1 and GC2 coated board, kraft paper and market pulp, 660,000 t/yr paper and board (NBSK pulp 80,000 t, not added). SMI satellite PCC next door.', 'PL check 2026-10-16: one mill - do not count IP Kwidzyn separately.'),
  ('arctic paper.*kostrzyn', 'kostrzyn', 'arctic paper', 'Arctic Paper Kostrzyn', 'Lubusz', 'Kostrzyn nad Odrą', null, 'Arctic Paper Kostrzyn(ul. Fabryczna 1) 비도공지·오프셋·복사·디지털 인쇄용지(Amber) 2대, 연 28.5만 t, 수출 약 70%. 과거 Nordkalk 스웨덴 GCC 사용 추정.', 'Arctic Paper Kostrzyn, ul. Fabryczna 1, Kostrzyn nad Odrą - uncoated woodfree, offset, copy and digital papers (Amber) on two machines, 285,000 t/yr, about 70 pct exported. A 2020 study suggested GCC supply by Nordkalk Sweden.', 'PL check 2026-10-16: group link with Munkedals and Grycksbo (SE).'),
  ('velvet|klucze', 'klucze', 'velvet', 'Velvet CARE - Klucze', 'Lesser Poland', 'Klucze', null, 'Velvet CARE Klucze 티슈 — 2025 말 TM9 가동 후 연 21만 t+, Sulęcin 신규 공장 건설(2025~).', 'Velvet CARE, Klucze - tissue, over 210,000 t/yr after TM9 started end 2025, new Sulęcin mill under construction since 2025.', 'PL check 2026-10-16: Sulęcin not counted.'),
  ('\mict\M.*pol|ict.*kostrzyn', 'kostrzyn', '\mict\M|tronchetti', 'ICT Poland - Kostrzyn', 'Lubusz', 'Kostrzyn nad Odrą', null, 'ICT Group 폴란드 Kostrzyn 티슈 3대, 연 약 21만 t.', 'ICT Poland (ICT Group), Kostrzyn nad Odrą - tissue on three machines, about 210,000 t/yr.', 'PL check 2026-10-16: ICT group link (IT, ES, FR).'),
  ('sofidel.*(pol|ciechan)', 'ciechan[oó]w', 'sofidel', 'Sofidel Poland - Ciechanów', 'Masovian', 'Ciechanów', null, 'Sofidel Ciechanów(ul. Mleczarska 31) 티슈 제지·가공 통합, Valmet NTT, 연 약 9만 t(2023), Regina·Softis.', 'Sofidel Poland, ul. Mleczarska 31, Ciechanów - integrated tissue paper mill and converting on Valmet NTT, about 90,000 t/yr (2023), Regina and Softis.', 'PL check 2026-10-16: '),
  ('mets[aä].*krapkowice|krapkowice', 'krapkowice', 'mets[aä]', 'Metsä Tissue Krapkowice', 'Opole', 'Krapkowice', null, 'Metsä Tissue Krapkowice 화장지·키친타월 연 약 5.9만 t(Lambi·Mola·Katrin).', 'Metsä Tissue Krapkowice - toilet tissue and kitchen towel, about 59,000 t/yr (Lambi, Mola, Katrin).', 'PL check 2026-10-16: '),
  ('wepa.*piechowice|piechowice', 'piechowice', 'wepa', 'WEPA Piechowice', 'Lower Silesia', 'Piechowice', null, 'WEPA 폴란드 Piechowice 화장지·종이타월.', 'WEPA Piechowice - toilet tissue and paper towels.', 'PL check 2026-10-16: capacity not public here.'),
  ('mondi.*[sś]wiecie|[sś]wiecie', '[sś]wiecie', 'mondi', 'Mondi Świecie', 'Kuyavian-Pomeranian', 'Świecie', null, 'Mondi Świecie 통합 펄프·제지 — 크라프트라이너·테스트라이너·골심지·산업용 포장지.', 'Mondi Świecie - integrated pulp and paper, kraftliner, testliner, fluting and industrial packaging papers.', 'PL check 2026-10-16: strength-led - low dose only.'),
  ('stora enso.*ostro[lł][eę]ka|ostro[lł][eę]ka', 'ostro[lł][eę]ka', 'stora enso', 'Stora Enso Ostrołęka', 'Masovian', 'Ostrołęka', null, 'Stora Enso Ostrołęka 재생 골판지원지·포장재.', 'Stora Enso Ostrołęka - recycled containerboard and packaging.', 'PL check 2026-10-16: strength-led.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn', 'MM Group MM Kwidzyn(ul. Lotnicza 1, 구 International Paper) — 백색 복사·오프셋용지·GC1/GC2 코팅판지·크라프트지·펄프, 종이·판지 연 66만 t(NBSK 8만 t 별도). SMI 위성 PCC 인접.', 'MM Kwidzyn (MM Group, formerly International Paper Kwidzyn), ul. Lotnicza 1, Kwidzyn - white copy and offset paper, GC1 and GC2 coated board, kraft paper and market pulp, 660,000 t/yr paper and board (NBSK pulp 80,000 t, not added). SMI satellite PCC next door.', 'PL check 2026-10-16: one mill - do not count IP Kwidzyn separately.'),
  ('arctic paper.*kostrzyn', 'kostrzyn', 'arctic paper', 'Arctic Paper Kostrzyn(ul. Fabryczna 1) 비도공지·오프셋·복사·디지털 인쇄용지(Amber) 2대, 연 28.5만 t, 수출 약 70%. 과거 Nordkalk 스웨덴 GCC 사용 추정.', 'Arctic Paper Kostrzyn, ul. Fabryczna 1, Kostrzyn nad Odrą - uncoated woodfree, offset, copy and digital papers (Amber) on two machines, 285,000 t/yr, about 70 pct exported. A 2020 study suggested GCC supply by Nordkalk Sweden.', 'PL check 2026-10-16: group link with Munkedals and Grycksbo (SE).'),
  ('velvet|klucze', 'klucze', 'velvet', 'Velvet CARE Klucze 티슈 — 2025 말 TM9 가동 후 연 21만 t+, Sulęcin 신규 공장 건설(2025~).', 'Velvet CARE, Klucze - tissue, over 210,000 t/yr after TM9 started end 2025, new Sulęcin mill under construction since 2025.', 'PL check 2026-10-16: Sulęcin not counted.'),
  ('\mict\M.*pol|ict.*kostrzyn', 'kostrzyn', '\mict\M|tronchetti', 'ICT Group 폴란드 Kostrzyn 티슈 3대, 연 약 21만 t.', 'ICT Poland (ICT Group), Kostrzyn nad Odrą - tissue on three machines, about 210,000 t/yr.', 'PL check 2026-10-16: ICT group link (IT, ES, FR).'),
  ('sofidel.*(pol|ciechan)', 'ciechan[oó]w', 'sofidel', 'Sofidel Ciechanów(ul. Mleczarska 31) 티슈 제지·가공 통합, Valmet NTT, 연 약 9만 t(2023), Regina·Softis.', 'Sofidel Poland, ul. Mleczarska 31, Ciechanów - integrated tissue paper mill and converting on Valmet NTT, about 90,000 t/yr (2023), Regina and Softis.', 'PL check 2026-10-16: '),
  ('mets[aä].*krapkowice|krapkowice', 'krapkowice', 'mets[aä]', 'Metsä Tissue Krapkowice 화장지·키친타월 연 약 5.9만 t(Lambi·Mola·Katrin).', 'Metsä Tissue Krapkowice - toilet tissue and kitchen towel, about 59,000 t/yr (Lambi, Mola, Katrin).', 'PL check 2026-10-16: '),
  ('wepa.*piechowice|piechowice', 'piechowice', 'wepa', 'WEPA 폴란드 Piechowice 화장지·종이타월.', 'WEPA Piechowice - toilet tissue and paper towels.', 'PL check 2026-10-16: capacity not public here.'),
  ('mondi.*[sś]wiecie|[sś]wiecie', '[sś]wiecie', 'mondi', 'Mondi Świecie 통합 펄프·제지 — 크라프트라이너·테스트라이너·골심지·산업용 포장지.', 'Mondi Świecie - integrated pulp and paper, kraftliner, testliner, fluting and industrial packaging papers.', 'PL check 2026-10-16: strength-led - low dose only.'),
  ('stora enso.*ostro[lł][eę]ka|ostro[lł][eę]ka', 'ostro[lł][eę]ka', 'stora enso', 'Stora Enso Ostrołęka 재생 골판지원지·포장재.', 'Stora Enso Ostrołęka - recycled containerboard and packaging.', 'PL check 2026-10-16: strength-led.'),
  ('g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', null, 'g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', null, null, 'PL check 2026-10-16: Tissue and specialty, Głuchołazy - details to collect - context only.'),
  ('schumacher|myszk[oó]w', null, 'schumacher|myszk[oó]w', null, null, 'PL check 2026-10-16: Corrugated packaging, Myszków - context only.'),
  ('ds smith.*pol', null, 'ds smith.*pol', null, null, 'PL check 2026-10-16: Polish recycled packaging sites - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'poland_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn'),
  ('arctic paper.*kostrzyn', 'kostrzyn', 'arctic paper'),
  ('velvet|klucze', 'klucze', 'velvet'),
  ('\mict\M.*pol|ict.*kostrzyn', 'kostrzyn', '\mict\M|tronchetti'),
  ('sofidel.*(pol|ciechan)', 'ciechan[oó]w', 'sofidel'),
  ('mets[aä].*krapkowice|krapkowice', 'krapkowice', 'mets[aä]'),
  ('wepa.*piechowice|piechowice', 'piechowice', 'wepa'),
  ('mondi.*[sś]wiecie|[sś]wiecie', '[sś]wiecie', 'mondi'),
  ('stora enso.*ostro[lł][eę]ka|ostro[lł][eę]ka', 'ostro[lł][eę]ka', 'stora enso'),
  ('g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', null, 'g[lł]ucho[lł]azy|g[lł]ucho[lł]askie'),
  ('schumacher|myszk[oó]w', null, 'schumacher|myszk[oó]w'),
  ('ds smith.*pol', null, 'ds smith.*pol')
      ) as v(name_rx, city_rx, owner_rx)
    ) m
    where m.id is not null
      and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);
    
update app.paper_mill_profile mp
    set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant',
          case when m.ctx then m.plant || coalesce(mp.extra_data -> 'plant', '{}'::jsonb)  -- context row: keep existing keys
               else m.plant end),
        main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
        updated_at = now()
    from (
      select v.plant, v.ctx, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn', false,
   $pj${"owner": "MM Group", "priority": 1, "products": "Copy and offset paper, coated board, kraft", "grades": ["UWF", "Copy paper", "Coated board"], "capacity": {"value": 660000, "unit": "metric_t", "year": "Company figure", "source": "mm.group"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.5, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 0.5, "fcc_loading": 0.1}], "note": "Report scenario 50 pct of output at 5 pct."}, "pitch": "MM + SMI + MBG three-way trial on copy paper", "approach": "Lead Polish account - MM group link (Frohnleiten, Količevo, Kotkamills).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('arctic paper.*kostrzyn', 'kostrzyn', 'arctic paper', false,
   $pj${"owner": "Arctic Paper", "priority": 2, "products": "Uncoated woodfree, offset, copy", "grades": ["UWF", "Copy paper"], "machines": 2, "capacity": {"value": 285000, "unit": "metric_t", "year": "Company figure", "source": "arcticpaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.5, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 0.5, "fcc_loading": 0.1}], "note": "Report scenario."}, "pitch": "FCC 5-10-15 pct vs current GCC", "approach": "Arctic Paper group trial (PL + SE).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('velvet|klucze', 'klucze', 'velvet', false,
   $pj${"owner": "Velvet CARE", "priority": 3, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "capacity": {"value": 210000, "unit": "metric_t", "year": "Company figure (after TM9)", "source": "velvetcare.pl"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Low-grammage tissue trial - Sulęcin design stage.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "TM9 start-up end 2025", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mict\M.*pol|ict.*kostrzyn', 'kostrzyn', '\mict\M|tronchetti', false,
   $pj${"owner": "ICT Group", "priority": 4, "products": "Tissue", "grades": ["Tissue"], "machines": 3, "capacity": {"value": 210000, "unit": "metric_t", "year": "Company figure", "source": "ictgroup.it"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "High-speed tissue trial - ICT group path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel.*(pol|ciechan)', 'ciechan[oó]w', 'sofidel', false,
   $pj${"owner": "Sofidel", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 90000, "unit": "metric_t", "year": "Company 2023", "source": "sofidel.com"}, "approach": "NTT line trial - Sofidel group path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mets[aä].*krapkowice|krapkowice', 'krapkowice', 'mets[aä]', false,
   $pj${"owner": "Metsä Group", "priority": 6, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 59000, "unit": "metric_t", "year": "Company output", "source": "metsatissue.com"}, "approach": "Metsä group trial (FI, SE).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wepa.*piechowice|piechowice', 'piechowice', 'wepa', false,
   $pj${"owner": "WEPA", "priority": 7, "products": "Tissue", "grades": ["Tissue"], "approach": "WEPA group trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mondi.*[sś]wiecie|[sś]wiecie', '[sś]wiecie', 'mondi', false,
   $pj${"owner": "Mondi", "priority": 8, "products": "Kraftliner, testliner, fluting", "grades": ["Kraftliner", "Testliner", "Medium"], "approach": "Low-dose strength trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*ostro[lł][eę]ka|ostro[lł][eę]ka', 'ostro[lł][eę]ka', 'stora enso', false,
   $pj${"owner": "Stora Enso", "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "approach": "Later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', null, 'g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', true,
   $pj${"owner": "Głuchołaskie Zakłady Papiernicze", "products": "Tissue and specialty, Głuchołazy - details to collect", "approach": "Converter or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('schumacher|myszk[oó]w', null, 'schumacher|myszk[oó]w', true,
   $pj${"owner": "Schumacher Packaging", "products": "Corrugated packaging, Myszków", "approach": "Converter or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*pol', null, 'ds smith.*pol', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "Polish recycled packaging sites", "approach": "Converter or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'poland_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn', '(specialty minerals|minerals technologies).*(pol|kwidzyn)', 'active', 'medium', null::date, null::date, 'about 50,000 t/yr (older data)', 'satellite PCC next to the mill', 'MTI SEC filings, PGI data', 'SMI satellite PCC at Kwidzyn (since mid-1990s) - status under MM to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ~* v.filler_rx
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PL', 'Poland', 'high',
   $cm$MM Kwidzyn (660 kt, SMI satellite PCC) and Arctic Paper Kostrzyn UWF (285 kt), tissue at Velvet CARE, ICT, Sofidel, Metsä, WEPA$cm$,
   $cm$Poland's FCC-fit mills: MM Kwidzyn (ex International Paper, copy and offset, coated board and kraft, 660 kt, SMI satellite PCC since the mid-1990s) and Arctic Paper Kostrzyn (UWF, 285 kt). Tissue cluster: Velvet CARE Klucze (210 kt+ after TM9, Sulęcin under construction), ICT Poland Kostrzyn (210 kt), Sofidel Ciechanów (90 kt, NTT), Metsä Tissue Krapkowice (59 kt), WEPA Piechowice. Packaging: Mondi Świecie, Stora Enso Ostrołęka. Fillers: SMI Poland Kwidzyn PCC, Omya Poland (sales, plants unknown), Nordkalk and Lhoist limestone and lime. Qemetica's old PCC is no longer offered.$cm$,
   $cm${"fillers": "Satellite PCC: SMI Kwidzyn. GCC and PCC sales: Omya Poland. Lime and limestone: Nordkalk Poland, Lhoist Bukowa. Not added: Qemetica, WKG, EGM, Labtar, Czatkowice.", "mills": "UWF and board: MM Kwidzyn, Arctic Paper Kostrzyn. Tissue: Velvet CARE, ICT Poland, Sofidel, Metsä Tissue, WEPA. Packaging: Mondi Świecie, Stora Enso Ostrołęka. Context: Głuchołazy, Schumacher, DS Smith Poland.", "strategy": "MM + SMI + MBG three-way trial at Kwidzyn, Arctic Paper group trial (PL + SE), tissue via group paths (ICT, Sofidel, Metsä, WEPA) and Velvet CARE direct.", "risks": "SMI status under MM, Omya competing tech.", "next_steps": ["Raise a Kwidzyn trial with SMI and MM", "Propose a GCC-swap trial to Arctic Paper Kostrzyn"], "key_numbers": [{"label": "MM Kwidzyn", "value": "660 kt paper and board"}, {"label": "Arctic Paper Kostrzyn", "value": "285 kt UWF"}, {"label": "Tissue (5 mills)", "value": "about 569 kt + WEPA"}], "files": ["seed_20261016zzi_poland_mills_fillers"]}$cm$::jsonb,
   $cm$MM Kwidzyn(66만 t, SMI 위성 PCC)·Arctic Paper Kostrzyn UWF(28.5만 t), 티슈 Velvet CARE·ICT·Sofidel·Metsä·WEPA$cm$,
   $cm$폴란드 FCC 적합: MM Kwidzyn(구 IP, 복사·오프셋·코팅판지·크라프트 66만 t, 1990년대 중반부터 SMI 위성 PCC), Arctic Paper Kostrzyn(UWF 28.5만 t). 티슈 클러스터: Velvet CARE Klucze(TM9 후 21만 t+, Sulęcin 건설 중), ICT Poland(21만 t), Sofidel Ciechanów(9만 t, NTT), Metsä Krapkowice(5.9만 t), WEPA Piechowice. 포장: Mondi Świecie, Stora Enso Ostrołęka. 충전제: SMI Kwidzyn PCC, Omya Poland(영업, 공장 미확인), Nordkalk·Lhoist 석회석·석회.$cm$,
   23625, 40695,
   $cm$하한 MM + Arctic 94.5만 t × 적용 50% × FCC 5% (보고서), 상한 + 티슈 5곳 56.9만 t × 3%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('kwidzyn', 'kwidzyn', '\mmm\M|mayr|international paper|kwidzyn'),
  ('arctic paper.*kostrzyn', 'kostrzyn', 'arctic paper'),
  ('velvet|klucze', 'klucze', 'velvet'),
  ('\mict\M.*pol|ict.*kostrzyn', 'kostrzyn', '\mict\M|tronchetti'),
  ('sofidel.*(pol|ciechan)', 'ciechan[oó]w', 'sofidel'),
  ('mets[aä].*krapkowice|krapkowice', 'krapkowice', 'mets[aä]'),
  ('wepa.*piechowice|piechowice', 'piechowice', 'wepa'),
  ('mondi.*[sś]wiecie|[sś]wiecie', '[sś]wiecie', 'mondi'),
  ('stora enso.*ostro[lł][eę]ka|ostro[lł][eę]ka', 'ostro[lł][eę]ka', 'stora enso'),
  ('g[lł]ucho[lł]azy|g[lł]ucho[lł]askie', null, 'g[lł]ucho[lł]azy|g[lł]ucho[lł]askie'),
  ('schumacher|myszk[oó]w', null, 'schumacher|myszk[oó]w'),
  ('ds smith.*pol', null, 'ds smith.*pol')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'poland_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'poland_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*(pol|kwidzyn)' or p.party_name ~* 'omya.*(pol|warsz|warsaw)' or p.party_name ~* 'nordkalk.*(pol|wolica|ostr[oó]wka|s[lł]awno)' or p.party_name ~* 'lhoist.*bukowa|bukowa')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'PL'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'PL'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'PL'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    