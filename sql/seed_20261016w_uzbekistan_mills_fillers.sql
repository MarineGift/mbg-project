-- ============================================================
-- seed_20261016w_uzbekistan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Uzbekistan update (reports 2026-10-16).
-- 1) Fillers if missing (4): CEMIX FE, DAVR-STROY, KITOB MARMAR ZAVOD,
--    NAYMAN MEL. Resellers and unverified listings not added.
-- 2) Mills if missing (4) + plant blocks: Tashkent Paper Factory (1),
--    Angren Karton / Angren Pack (2), Perfect Paper Group (3), Uzbek China
--    Paper (no priority). Context (8): Huanrong project, Global KOMSCO
--    Daewoo, Daewoo Pack, Pulp and Paper LLC, Premium Alliance, Ravshan
--    Yodik, Profpack, Ahangaran Hygienic Pro.
-- 3) app.country_markets UZ row (priority medium).
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
           v.party_name, 'UZ', v.region, v.city, v.website, 'active', 'uzbekistan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cemix', 'CEMIX FE (Prowhite GCC) - Sazagon', 'Samarkand', 'Sazagon', null, 'LASSELSBERGER 계열 CEMIX FE(Samarkand Nurobod Sazagon). 선별 대리석, 링롤러밀 6대·공기분급, Sedigraph·XRF. GCC 1001(D50 1.0 μm, D98 4 μm, Ry 92.5, <2 μm 80%)~1005, 인쇄·코팅·판지·특수지 용도 명시.', 'CEMIX FE LLC (LASSELSBERGER group), 36 Tepakul-1 St, Sazagon, Nurobod District (Samarkand) - Prowhite GCC of selected marble on six ring-roller mills with air classification, Sedigraph III Plus and XRF QC: GCC 1001 (D50 1.0, D98 4 micron, 98 pct, Ry 92.5, 80 pct under 2 micron, Fe2O3 under 0.05 pct), 1002 (D50 2.3), 1003 (D50 3.0), 1005 (D50 5.5), for printing, coated paper, board and specialty paper. 25 kg bags, big bags, silo trucks, 10,000 m2 warehouse.', 'UZ check 2026-10-16: annual capacity, slurry line and mill customers not public - dry GCC only. GM Jaroslav Hrbek, sales saidislom.khodjaev@cemix.uz, +998 77 363 68 46. FCC partner candidate 1.'),
  ('davr-?stroy', 'DAVR-STROY', null, null, null, '대리석 채굴·가공·마이크로칼사이트 업체. 2~500 μm(2·3·5·7·10 μm), CaCO3 최대 98%, 제지 용도 명시.', 'DAVR-STROY LLC - marble quarrying, processing and microcalcite, 2-500 micron (2, 3, 5, 7, 10 micron grades), up to 98 pct CaCO3, paper named with building, paint and plastics.', 'UZ check 2026-10-16: plant address and capacity to confirm. davrstroy.info@gmail.com, +998 94 444 05 44.'),
  ('kitob marmar|kitabcarb', 'KITOB MARMAR ZAVOD (KITABCARB) - Shahrisabz', 'Qashqadaryo', 'Shahrisabz', null, '1998년부터 카슈카다리야(Shahrisabz·Kitob) 마이크로칼사이트·탄산칼슘·대리석 분말·백악·돌로마이트.', 'KITOB MARMAR ZAVOD LLC (KITABCARB, since 1998), Pillakashlik St 77, Shahrisabz (Qashqadaryo) - microcalcite, calcium carbonate and marble powder, ground chalk, dolomite, mainly for paint and plastics.', 'UZ check 2026-10-16: paper supply not confirmed, plant and legal addresses differ. marmarzavod@mail.ru.'),
  ('nayman mel', 'NAYMAN MEL - Andijan', 'Andijan', 'Bulakbashi', null, '안디잔 Bulakbashi Sarbontepa 의 마이크로칼사이트·분쇄 백악 업체(디렉터리).', 'NAYMAN MEL LLC, Sarbontepa, Bulakbashi District (Andijan) - microcalcite and ground chalk (directory listing).', 'UZ check 2026-10-16: specs and output not confirmed. naymanmel@mail.ru. Not added: MIKRO GRAND, Nurmix and Paint, MASTER PERFECT GYPSUM (production unconfirmed), Global Optimals (PCC reseller), Calpet Plastic (PCC user). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%UZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cemix', 'CEMIX FE (Prowhite GCC) - Sazagon', 'Samarkand', 'Sazagon', null, 'LASSELSBERGER 계열 CEMIX FE(Samarkand Nurobod Sazagon). 선별 대리석, 링롤러밀 6대·공기분급, Sedigraph·XRF. GCC 1001(D50 1.0 μm, D98 4 μm, Ry 92.5, <2 μm 80%)~1005, 인쇄·코팅·판지·특수지 용도 명시.', 'CEMIX FE LLC (LASSELSBERGER group), 36 Tepakul-1 St, Sazagon, Nurobod District (Samarkand) - Prowhite GCC of selected marble on six ring-roller mills with air classification, Sedigraph III Plus and XRF QC: GCC 1001 (D50 1.0, D98 4 micron, 98 pct, Ry 92.5, 80 pct under 2 micron, Fe2O3 under 0.05 pct), 1002 (D50 2.3), 1003 (D50 3.0), 1005 (D50 5.5), for printing, coated paper, board and specialty paper. 25 kg bags, big bags, silo trucks, 10,000 m2 warehouse.', 'UZ check 2026-10-16: annual capacity, slurry line and mill customers not public - dry GCC only. GM Jaroslav Hrbek, sales saidislom.khodjaev@cemix.uz, +998 77 363 68 46. FCC partner candidate 1.'),
  ('davr-?stroy', 'DAVR-STROY', null, null, null, '대리석 채굴·가공·마이크로칼사이트 업체. 2~500 μm(2·3·5·7·10 μm), CaCO3 최대 98%, 제지 용도 명시.', 'DAVR-STROY LLC - marble quarrying, processing and microcalcite, 2-500 micron (2, 3, 5, 7, 10 micron grades), up to 98 pct CaCO3, paper named with building, paint and plastics.', 'UZ check 2026-10-16: plant address and capacity to confirm. davrstroy.info@gmail.com, +998 94 444 05 44.'),
  ('kitob marmar|kitabcarb', 'KITOB MARMAR ZAVOD (KITABCARB) - Shahrisabz', 'Qashqadaryo', 'Shahrisabz', null, '1998년부터 카슈카다리야(Shahrisabz·Kitob) 마이크로칼사이트·탄산칼슘·대리석 분말·백악·돌로마이트.', 'KITOB MARMAR ZAVOD LLC (KITABCARB, since 1998), Pillakashlik St 77, Shahrisabz (Qashqadaryo) - microcalcite, calcium carbonate and marble powder, ground chalk, dolomite, mainly for paint and plastics.', 'UZ check 2026-10-16: paper supply not confirmed, plant and legal addresses differ. marmarzavod@mail.ru.'),
  ('nayman mel', 'NAYMAN MEL - Andijan', 'Andijan', 'Bulakbashi', null, '안디잔 Bulakbashi Sarbontepa 의 마이크로칼사이트·분쇄 백악 업체(디렉터리).', 'NAYMAN MEL LLC, Sarbontepa, Bulakbashi District (Andijan) - microcalcite and ground chalk (directory listing).', 'UZ check 2026-10-16: specs and output not confirmed. naymanmel@mail.ru. Not added: MIKRO GRAND, Nurmix and Paint, MASTER PERFECT GYPSUM (production unconfirmed), Global Optimals (PCC reseller), Calpet Plastic (PCC user). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'uzbekistan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CEMIX FE (Prowhite GCC) - Sazagon', 'GCC producer', 'Paper-grade ultrafine GCC - FCC partner candidate 1', 'merchant', 'B', 'gcc'),
  ('DAVR-STROY', 'GCC producer', 'Marble microcalcite, paper named - candidate 2', 'merchant', 'C', 'gcc'),
  ('KITOB MARMAR ZAVOD (KITABCARB) - Shahrisabz', 'GCC producer', 'Microcalcite - raw material candidate', 'merchant', 'C', 'gcc'),
  ('NAYMAN MEL - Andijan', 'GCC producer', 'Chalk microcalcite', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'uzbekistan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'UZ', v.region, v.city, v.website, 'active', 'uzbekistan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('tashkent paper factory|ташкентская бумажная', null, 'tashkent paper', 'Tashkent Paper Factory', 'Tashkent Region', null, null, '중앙은행 산하 Tashkent Paper Factory — 필기용지(70~80 g/m²)·색지·도화지·의료·지도용지·보안용지.', 'Tashkent Paper Factory (Central Bank of Uzbekistan organisation) - writing paper 70-80 g/m2, coloured paper 80-90, drawing paper 120-180, coloured board 180, medical paper 70, map paper 80-85, plus security, passport and banknote paper.', 'UZ check 2026-10-16: capacity and plant location not public. Security grades are not trial targets - general writing paper only.'),
  ('angren (pack|karton)|ангрен', 'angren', 'angren', 'Angren Karton Qogʻoz Kombinati (Angren Pack) - Angren', 'Tashkent Region', 'Angren', null, '1988년 설립 앙그렌 산업용 제지(Gulbag). 재생고지 Fluting·Testliner·석고보드 원지·화이트탑 라이너, 연 10만 t 공개. 2024 Bellmer 화이트탑 설비, 폭 4,250 mm·최대 400 m/분.', 'Angren Karton Qogʻoz Kombinati / Angren Pack (since 1988), Gulbag, Angren (Tashkent Region) - recycled fluting, testliner, gypsum-board back liner and white-top liner, 100,000 t/yr (company). Bellmer white-top equipment added 2024 on a 4,250 mm, up to 400 m/min machine (up to 320 t/day potential per press).', 'UZ check 2026-10-16: legal identity of the two names to confirm. Supplier page lists pulp, waste paper, starch, defoamer, flocculant purchases. info@angrenkarton.uz, purchasing +998 99 086 82 68.'),
  ('perfect paper|\mppg\M', 'chinaz|chinoz', 'perfect paper', 'Perfect Paper Group - Chinaz', 'Tashkent Region', 'Chinaz', null, '치나즈(Gulzarabad) 산업용 종이 — 골판지용지·크라프트지·판지·섬유용 종이 콘·튜브.', 'Perfect Paper Group LLC, Gulzarabad, Chinaz District (Tashkent Region) - corrugating paper, kraft paper, industrial board and paper cones and tubes for the textile industry.', 'UZ check 2026-10-16: capacity and filler use not public. Site ppg.uz.'),
  ('uzbek china paper', null, 'uzbek china', 'Uzbek China Paper - Uchqoʻrgʻon', 'Namangan', 'Uchqoʻrgʻon', null, '나망간 Uchqoʻrgʻon 볏짚 등 농업 부산물 기반 제지공장(2020 생산 개시 보도).', 'Uzbek China Paper, Uchqoʻrgʻon (Namangan) - paper on rice straw and other farm residues, production start reported in 2020 (Kun.uz).', 'UZ check 2026-10-16: 2026 operation, capacity and grades not confirmed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%UZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tashkent paper factory|ташкентская бумажная', null, 'tashkent paper', '중앙은행 산하 Tashkent Paper Factory — 필기용지(70~80 g/m²)·색지·도화지·의료·지도용지·보안용지.', 'Tashkent Paper Factory (Central Bank of Uzbekistan organisation) - writing paper 70-80 g/m2, coloured paper 80-90, drawing paper 120-180, coloured board 180, medical paper 70, map paper 80-85, plus security, passport and banknote paper.', 'UZ check 2026-10-16: capacity and plant location not public. Security grades are not trial targets - general writing paper only.'),
  ('angren (pack|karton)|ангрен', 'angren', 'angren', '1988년 설립 앙그렌 산업용 제지(Gulbag). 재생고지 Fluting·Testliner·석고보드 원지·화이트탑 라이너, 연 10만 t 공개. 2024 Bellmer 화이트탑 설비, 폭 4,250 mm·최대 400 m/분.', 'Angren Karton Qogʻoz Kombinati / Angren Pack (since 1988), Gulbag, Angren (Tashkent Region) - recycled fluting, testliner, gypsum-board back liner and white-top liner, 100,000 t/yr (company). Bellmer white-top equipment added 2024 on a 4,250 mm, up to 400 m/min machine (up to 320 t/day potential per press).', 'UZ check 2026-10-16: legal identity of the two names to confirm. Supplier page lists pulp, waste paper, starch, defoamer, flocculant purchases. info@angrenkarton.uz, purchasing +998 99 086 82 68.'),
  ('perfect paper|\mppg\M', 'chinaz|chinoz', 'perfect paper', '치나즈(Gulzarabad) 산업용 종이 — 골판지용지·크라프트지·판지·섬유용 종이 콘·튜브.', 'Perfect Paper Group LLC, Gulzarabad, Chinaz District (Tashkent Region) - corrugating paper, kraft paper, industrial board and paper cones and tubes for the textile industry.', 'UZ check 2026-10-16: capacity and filler use not public. Site ppg.uz.'),
  ('uzbek china paper', null, 'uzbek china', '나망간 Uchqoʻrgʻon 볏짚 등 농업 부산물 기반 제지공장(2020 생산 개시 보도).', 'Uzbek China Paper, Uchqoʻrgʻon (Namangan) - paper on rice straw and other farm residues, production start reported in 2020 (Kun.uz).', 'UZ check 2026-10-16: 2026 operation, capacity and grades not confirmed.'),
  ('huanrong', null, 'huanrong', null, null, 'UZ check 2026-10-16: USD 500 m office paper, board and packaging project, Urgut FEZ Hishrau-2 (Samarkand), 5 phases, 3,000 jobs - agreed 2026-01, not built - context only.'),
  ('komsco|\mgkd\M', null, 'komsco|\mgkd\M', null, null, 'UZ check 2026-10-16: Cotton cellulose for security paper, Yangiyul - not a filler user - context only.'),
  ('daewoo pack', null, 'daewoo pack', null, null, 'UZ check 2026-10-16: Paper and packaging, Bektemir - context only.'),
  ('pulp and paper llc', null, 'pulp and paper llc', null, null, 'UZ check 2026-10-16: Listed paper maker, Yangihayot - context only.'),
  ('premium alliance', null, 'premium alliance', null, null, 'UZ check 2026-10-16: Listed paper maker, Chilanzar - context only.'),
  ('ravshan yodik', null, 'ravshan yodik', null, null, 'UZ check 2026-10-16: Listed paper maker, Yangihayot - context only.'),
  ('profpack', null, 'profpack', null, null, 'UZ check 2026-10-16: Paper and packaging, Yangihayot - context only.'),
  ('ahangaran hygienic', null, 'ahangaran hygienic', null, null, 'UZ check 2026-10-16: Hygiene products (diapers) - not a tissue mill - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'uzbekistan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tashkent paper factory|ташкентская бумажная', null, 'tashkent paper'),
  ('angren (pack|karton)|ангрен', 'angren', 'angren'),
  ('perfect paper|\mppg\M', 'chinaz|chinoz', 'perfect paper'),
  ('uzbek china paper', null, 'uzbek china'),
  ('huanrong', null, 'huanrong'),
  ('komsco|\mgkd\M', null, 'komsco|\mgkd\M'),
  ('daewoo pack', null, 'daewoo pack'),
  ('pulp and paper llc', null, 'pulp and paper llc'),
  ('premium alliance', null, 'premium alliance'),
  ('ravshan yodik', null, 'ravshan yodik'),
  ('profpack', null, 'profpack'),
  ('ahangaran hygienic', null, 'ahangaran hygienic')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tashkent paper factory|ташкентская бумажная', null, 'tashkent paper',
   $pj${"owner": "Central Bank of Uzbekistan", "priority": 1, "products": "Writing, coloured, drawing, medical, map and security paper", "grades": ["Printing and writing", "Security paper"], "pitch": "FCC on general writing paper - opacity and fibre saving", "approach": "Writing-paper line only. CEMIX GCC as local producer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('angren (pack|karton)|ангрен', 'angren', 'angren',
   $pj${"owner": "Angren Karton / Angren Pack", "priority": 2, "products": "Fluting, testliner, gypsum-board liner, white-top liner", "grades": ["Medium", "Testliner", "Plasterboard liner", "White-top liner"], "capacity": {"value": 100000, "unit": "metric_t", "year": "Company figure", "source": "angrenkarton.uz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Planning scenario - white-top and plasterboard liner first, strength must hold."}, "approach": "Technical plus purchasing contact - white-top liner trial first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('perfect paper|\mppg\M', 'chinaz|chinoz', 'perfect paper',
   $pj${"owner": "Perfect Paper Group", "priority": 3, "products": "Corrugating paper, kraft, board, textile cones", "grades": ["Medium", "Kraft paper", "Board"], "approach": "Check grades and current filler use.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('uzbek china paper', null, 'uzbek china',
   $pj${"owner": "Uzbek China Paper", "products": "Non-wood fibre paper", "approach": "Confirm operation first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('huanrong', null, 'huanrong',
   $pj${"owner": "Huanrong Paper", "products": "USD 500 m office paper, board and packaging project, Urgut FEZ Hishrau-2 (Samarkand), 5 phases, 3,000 jobs - agreed 2026-01, not built", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('komsco|\mgkd\M', null, 'komsco|\mgkd\M',
   $pj${"owner": "Global KOMSCO Daewoo", "products": "Cotton cellulose for security paper, Yangiyul - not a filler user", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('daewoo pack', null, 'daewoo pack',
   $pj${"owner": "Daewoo Pack", "products": "Paper and packaging, Bektemir", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pulp and paper llc', null, 'pulp and paper llc',
   $pj${"owner": "Pulp and Paper LLC", "products": "Listed paper maker, Yangihayot", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('premium alliance', null, 'premium alliance',
   $pj${"owner": "Premium Alliance Papper", "products": "Listed paper maker, Chilanzar", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ravshan yodik', null, 'ravshan yodik',
   $pj${"owner": "Ravshan Yodik Production", "products": "Listed paper maker, Yangihayot", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('profpack', null, 'profpack',
   $pj${"owner": "Profpack", "products": "Paper and packaging, Yangihayot", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ahangaran hygienic', null, 'ahangaran hygienic',
   $pj${"owner": "Ahangaran Hygienic Pro", "products": "Hygiene products (diapers) - not a tissue mill", "approach": "Project, converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'UZ', 'Uzbekistan', 'medium',
   $cm$CEMIX paper-grade GCC (D50 1 micron) plus Angren Karton (100 kt recycled liner) and Tashkent Paper Factory writing paper - Huanrong USD 500 m project$cm$,
   $cm$Uzbekistan has a real paper-grade GCC maker - CEMIX (LASSELSBERGER, Samarkand) with D50 1-5.5 micron grades and Sedigraph QC - plus DAVR-STROY, KITOB MARMAR and NAYMAN MEL. No paper PCC plant (PCC is resold by Global Optimals). Mills: Angren Karton / Angren Pack (100 kt recycled fluting, testliner, white-top), Perfect Paper Group (Chinaz), Tashkent Paper Factory (writing and security paper, Central Bank). Huanrong Paper agreed a USD 500 m office-paper and board complex at Urgut FEZ (2026-01). Sector output UZS 10.2 trillion in 2025 (+10.5 pct), 70.7 pct in Tashkent city and region.$cm$,
   $cm${"fillers": "Paper-grade GCC: CEMIX (GCC 1001 D50 1.0 / D98 4 micron, Ry 92.5). Microcalcite: DAVR-STROY (2-10 micron, paper named), KITOB MARMAR ZAVOD, NAYMAN MEL. Not added: MIKRO GRAND, Nurmix, MASTER (unverified), Global Optimals (PCC reseller), Calpet (PCC user).", "mills": "Angren Karton / Angren Pack (100 kt), Perfect Paper Group (Chinaz), Tashkent Paper Factory, Uzbek China Paper (rice straw, status unknown). Project: Huanrong Paper Urgut (USD 500 m). Context: Global KOMSCO Daewoo, Daewoo Pack, Pulp and Paper LLC, Premium Alliance, Ravshan Yodik, Profpack, Ahangaran Hygienic Pro.", "strategy": "CEMIX as licensed FCC producer, first trials at Tashkent Paper Factory (writing paper) and Angren white-top liner. Take part early in the Huanrong office-paper line design.", "risks": "Tissue base-paper makers not identified, capacities mostly unpublished.", "next_steps": ["Approach CEMIX on an FCC licence", "Track Huanrong Paper project", "Identify tissue base-paper makers"], "key_numbers": [{"label": "Paper sector output 2025", "value": "UZS 10.2 trillion (+10.5 pct)"}, {"label": "Angren Karton", "value": "100 kt/yr"}, {"label": "Huanrong project", "value": "USD 500 m, 5 phases"}], "files": ["seed_20261016w_uzbekistan_mills_fillers"]}$cm$::jsonb,
   $cm$CEMIX 제지용 GCC(D50 1 μm) + Angren Karton(재생 라이너 10만 t)·Tashkent Paper Factory 필기용지 — Huanrong 5억 달러 프로젝트$cm$,
   $cm$우즈베키스탄에는 제지용 GCC 제조사 CEMIX(LASSELSBERGER, 사마르칸트, D50 1~5.5 μm, Sedigraph 품질관리)가 있고 DAVR-STROY·KITOB MARMAR·NAYMAN MEL. 제지용 PCC 없음. 제지: Angren Karton(10만 t 재생 골심지·라이너·화이트탑), Perfect Paper Group, Tashkent Paper Factory(필기·보안용지). Huanrong Paper 가 Urgut 특구에 5억 달러 사무용지·판지 단지 합의(2026-01). 2025 제지 생산액 10.2조 숨(+10.5%).$cm$,
   3000, 5000,
   $cm$Angren Karton 10만 t × FCC 3~5% (Tashkent Paper Factory 톤수 미공개, Huanrong 미완공)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('tashkent paper factory|ташкентская бумажная', null, 'tashkent paper'),
  ('angren (pack|karton)|ангрен', 'angren', 'angren'),
  ('perfect paper|\mppg\M', 'chinaz|chinoz', 'perfect paper'),
  ('uzbek china paper', null, 'uzbek china'),
  ('huanrong', null, 'huanrong'),
  ('komsco|\mgkd\M', null, 'komsco|\mgkd\M'),
  ('daewoo pack', null, 'daewoo pack'),
  ('pulp and paper llc', null, 'pulp and paper llc'),
  ('premium alliance', null, 'premium alliance'),
  ('ravshan yodik', null, 'ravshan yodik'),
  ('profpack', null, 'profpack'),
  ('ahangaran hygienic', null, 'ahangaran hygienic')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'uzbekistan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'uzbekistan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cemix' or p.party_name ~* 'davr-?stroy' or p.party_name ~* 'kitob marmar|kitabcarb' or p.party_name ~* 'nayman mel')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'UZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'UZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'UZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    