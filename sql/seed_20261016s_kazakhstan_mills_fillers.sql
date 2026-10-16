-- ============================================================
-- seed_20261016s_kazakhstan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Kazakhstan update (reports 2026-10-16, latest mill version used).
-- 1) Fillers if missing (5): Asia Micron, TasUn (MARMAR), Kazhimtehsnab,
--    Aktau Minerals, Global Chemicals Company.
-- 2) Mills if missing (7) + plant blocks, priority 1-7: Karina Paper,
--    Alatau Kagazy, Lucrum Star, NUR KAGAZY, KZ Recycling (ex Kagazy),
--    Inter Multi Service, Sever-Kombinat. Context (9): PAPIRONE (linked to
--    Karina), BumProm, Goldman Astana, LisBum.KZ, Eco Pack Astana, Pavlodar
--    Cardboard-Ruberoid, Gofrotara, Amcor, Karaganda PPC.
-- 3) app.country_markets KZ row (priority medium).
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
           v.party_name, 'KZ', v.region, v.city, v.website, 'active', 'kazakhstan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('asia micron|азия микрон', 'Asia Micron - Tekeli', 'Zhetysu', 'Tekeli', null, 'A-Mra Group 계열 Asia Micron(1998~, Tekeli). 자체 대리석 채석장, GCC 1~500 μm(2·5·10·20 μm), 철도·트럭 공급, 게시가 39,000 KZT/t(2~20 μm).', 'Asia Micron LLP (A-Mra Group, since 1998), Tekeli - GCC of its own quarried marble, 1-500 micron (2, 5, 10, 20 micron grades), 30 kg bags, rail and truck across Kazakhstan and neighbours, posted price 39,000 KZT/t ex-works (2-20 micron).', 'KZ check 2026-10-16: whether 2 micron is D50 not stated - brightness, D90 and wet capability to confirm. info@alataumramor.kz, +7 727 274 01 45. FCC partner candidate 1 (supplies Almaty tissue mills).'),
  ('tasun|marmar', 'TasUn (MARMAR) - Tekeli', 'Zhetysu', 'Tekeli', null, 'Tekeli 대리석 채굴·분쇄 TasUn(MARMAR). MR2(2 μm)·7 μm·마이크로칼사이트 5~14 μm, CaCO3 약 98%, 제지 용도 명시.', 'TasUn LLP (brand MARMAR), Tekeli - marble quarrying and mechanical grinding: MR2 (2 micron), 7 micron, microcalcite 5-10 and 14 micron, about 98 pct CaCO3, paper industry named.', 'KZ check 2026-10-16: wet grinding and slurry not confirmed. tasun17@mail.ru, +7 707 777 95 19.'),
  ('kazhimtehsnab|казхимтехснаб', 'Kazhimtehsnab - Semey', 'Abai', 'Semey', null, 'Semey(73G Glinka St) GCC 분쇄 + 수산화칼슘 공장(2011), 자체 실험실·철도.', 'Kazhimtehsnab LLP, 73G Glinka Street, Semey (Abai Region) - ground calcium carbonate mill plus a hydrated lime plant (2011), own lab, warehouse and rail siding, for construction, paint and polymers.', 'KZ check 2026-10-16: hydrated lime is a PCC base, but no carbonation plant. kazhimts@mail.ru, +7 771 302 97 88.'),
  ('aktau minerals', 'Aktau Minerals - Mangystau', 'Mangystau', 'Mangistau-5', null, 'Mangystau 천연 백악 기반 신규 탄산칼슘 공장(1~10 μm, 98% 이상, 10~12 t/h 설계), 2026 가동 추진.', 'Aktau Minerals LLP, Mangistau-5 (Mangystau Region) - new calcium carbonate plant on natural chalk: 1-10 micron, over 98 pct CaCO3, moisture under 0.5 pct, pH 8.5-9.5, designed 10-12 t/h, rail, truck and Caspian port access, start-up being pursued in 2026.', 'KZ check 2026-10-16: continuous production not confirmed. New line could be designed for FCC.'),
  ('global chemicals company', 'Global Chemicals Company (GCC Group) - Almaty', 'Almaty', 'Almaty', null, '알마티 산업화학·광물 원료 업체. 탄산칼슘 98~98.5%, 주력 석유·가스(시추) 고객, 시장 55~60% 주장.', 'Global Chemicals Company (GCC Group), 92 Zhanibekov Street, Kok-Tobe 2, Almaty - industrial chemicals and minerals: calcium carbonate 98-98.5 pct, lime, mainly for oil, gas and drilling (Halliburton named), claims 55-60 pct of the Kazakh carbonate supply market (unverified).', 'KZ check 2026-10-16: no paper supply found. info@gcc.kz. Not added: MicroCalcit (Petropavlovsk, own plant unconfirmed), Mountain Mineral (Tekeli, building materials, status unknown). No paper PCC plant, no Omya or MTI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%KZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('asia micron|азия микрон', 'Asia Micron - Tekeli', 'Zhetysu', 'Tekeli', null, 'A-Mra Group 계열 Asia Micron(1998~, Tekeli). 자체 대리석 채석장, GCC 1~500 μm(2·5·10·20 μm), 철도·트럭 공급, 게시가 39,000 KZT/t(2~20 μm).', 'Asia Micron LLP (A-Mra Group, since 1998), Tekeli - GCC of its own quarried marble, 1-500 micron (2, 5, 10, 20 micron grades), 30 kg bags, rail and truck across Kazakhstan and neighbours, posted price 39,000 KZT/t ex-works (2-20 micron).', 'KZ check 2026-10-16: whether 2 micron is D50 not stated - brightness, D90 and wet capability to confirm. info@alataumramor.kz, +7 727 274 01 45. FCC partner candidate 1 (supplies Almaty tissue mills).'),
  ('tasun|marmar', 'TasUn (MARMAR) - Tekeli', 'Zhetysu', 'Tekeli', null, 'Tekeli 대리석 채굴·분쇄 TasUn(MARMAR). MR2(2 μm)·7 μm·마이크로칼사이트 5~14 μm, CaCO3 약 98%, 제지 용도 명시.', 'TasUn LLP (brand MARMAR), Tekeli - marble quarrying and mechanical grinding: MR2 (2 micron), 7 micron, microcalcite 5-10 and 14 micron, about 98 pct CaCO3, paper industry named.', 'KZ check 2026-10-16: wet grinding and slurry not confirmed. tasun17@mail.ru, +7 707 777 95 19.'),
  ('kazhimtehsnab|казхимтехснаб', 'Kazhimtehsnab - Semey', 'Abai', 'Semey', null, 'Semey(73G Glinka St) GCC 분쇄 + 수산화칼슘 공장(2011), 자체 실험실·철도.', 'Kazhimtehsnab LLP, 73G Glinka Street, Semey (Abai Region) - ground calcium carbonate mill plus a hydrated lime plant (2011), own lab, warehouse and rail siding, for construction, paint and polymers.', 'KZ check 2026-10-16: hydrated lime is a PCC base, but no carbonation plant. kazhimts@mail.ru, +7 771 302 97 88.'),
  ('aktau minerals', 'Aktau Minerals - Mangystau', 'Mangystau', 'Mangistau-5', null, 'Mangystau 천연 백악 기반 신규 탄산칼슘 공장(1~10 μm, 98% 이상, 10~12 t/h 설계), 2026 가동 추진.', 'Aktau Minerals LLP, Mangistau-5 (Mangystau Region) - new calcium carbonate plant on natural chalk: 1-10 micron, over 98 pct CaCO3, moisture under 0.5 pct, pH 8.5-9.5, designed 10-12 t/h, rail, truck and Caspian port access, start-up being pursued in 2026.', 'KZ check 2026-10-16: continuous production not confirmed. New line could be designed for FCC.'),
  ('global chemicals company', 'Global Chemicals Company (GCC Group) - Almaty', 'Almaty', 'Almaty', null, '알마티 산업화학·광물 원료 업체. 탄산칼슘 98~98.5%, 주력 석유·가스(시추) 고객, 시장 55~60% 주장.', 'Global Chemicals Company (GCC Group), 92 Zhanibekov Street, Kok-Tobe 2, Almaty - industrial chemicals and minerals: calcium carbonate 98-98.5 pct, lime, mainly for oil, gas and drilling (Halliburton named), claims 55-60 pct of the Kazakh carbonate supply market (unverified).', 'KZ check 2026-10-16: no paper supply found. info@gcc.kz. Not added: MicroCalcit (Petropavlovsk, own plant unconfirmed), Mountain Mineral (Tekeli, building materials, status unknown). No paper PCC plant, no Omya or MTI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'kazakhstan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Asia Micron - Tekeli', 'GCC producer', 'Fine marble GCC - FCC partner candidate 1', 'merchant', 'C', 'gcc'),
  ('TasUn (MARMAR) - Tekeli', 'GCC producer', 'Marble GCC, paper named - candidate 2', 'merchant', 'C', 'gcc'),
  ('Kazhimtehsnab - Semey', 'GCC and lime producer', 'GCC and hydrated lime - future PCC base', 'merchant', 'C', 'gcc'),
  ('Aktau Minerals - Mangystau', 'GCC producer', 'New chalk GCC plant - start-up stage', 'merchant', 'C', 'gcc'),
  ('Global Chemicals Company (GCC Group) - Almaty', 'GCC producer', 'Industrial carbonate for drilling', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'kazakhstan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'KZ', v.region, v.city, v.website, 'active', 'kazakhstan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('karina', 'kazybay', 'karina', 'Karina Paper - Almaty', 'Almaty', 'Almaty', null, '알마티 대표 위생지 기업 Karina Paper(Karina Trading, 264A Kazybayev St). 자체 티슈 초지기 — Baotuo SF12-1100(1,100 m/분, 2,860 mm, 2019-12), 과거 TM2 일 60 t. 2026-03 4번째 라인 착공 계획(약 50억 텡게).', 'Karina Paper / Karina Trading, 264A Kazybayev Street, Almaty - tissue base paper, toilet tissue, napkins, towels on virgin or recycled pulp. Baotuo SF12-1100 tissue machine (1,100 m/min, 2,860 mm, suction former) started 2019-12, older TM2 reached about 60 t/day after upgrade (2015). Fourth line construction planned for 2026-03 (about KZT 5 bn, 100+ jobs).', 'KZ check 2026-10-16: PAPIRONE uses the same address and phone - treated as linked, not counted twice. Karina plus PAPIRONE hold 40-60 pct of the tissue market with 788 staff (Almaty akimat 2025). info@karina.kz, +7 777 805 80 98.'),
  ('alatau kagazy', 'kokrek|almaty', 'alatau kagazy', 'Alatau Kagazy - Almaty', 'Almaty', 'Almaty', null, '1998년 시작 위생지 기업 Alatau Kagazy(777 Kokrek St). 2004 이탈리아·체코 기술 초지기 일 60 t, 2020 Fabio Perini 가공라인. 브랜드 Belosnezhka.', 'Alatau Kagazy (since 1998), 777 Kokrek Street, Almaty - tissue machine on Italian and Czech technology since 2004, 60 t/day, Fabio Perini converting line 2020, 3-ply tissue and wet-strength towels 2023, brand Belosnezhka.', 'KZ check 2026-10-16: 19,800 t/yr is 60 t/day x 330 (calculated). Phone on the site looks placeholder - verify. info@alataukagazy.kz.'),
  ('lucrum star', 'aktobe', 'lucrum', 'Lucrum Star - Aktobe', 'Aktobe', 'Aktobe', null, 'Aktobe 위생지 기업 Lucrum Star — 원지 연 3,335 t, 화장지 2,300만 롤·타월 300만 롤·냅킨 750만 팩. 100% 펄프·100% 폐지·70/30 배합.', 'Lucrum Star LLP, Industrial Zone 679D, Aktobe - tissue base paper 3,335 t/yr: 23 m toilet rolls, 3 m towel rolls, 7.5 m napkin packs, on 100 pct virgin pulp, 100 pct waste paper and 70/30 blends. Director Aslan Shoybekov, production head Dilmurat Tudakhunov.', 'KZ check 2026-10-16: +7 7132 74 90 27, lucrumstar@gmail.com.'),
  ('nur kagazy', 'panfilov|talgar', 'nur kagazy', 'NUR KAGAZY - Panfilovo (Talgar)', 'Almaty Region', 'Panfilovo', null, '재생 라이너보드·골심지·석고보드 이면지 제조(2018 가동, Panfilovo, Talgar). 110~200 g/m², 지폭 950~2,450 mm, 2022 골판지 1.2억 m² 라인. 연 4만 t(2022 정부 자료).', 'NUR KAGAZY, 121 Zhambyl Street, Panfilovo (Talgar District, Almaty Region) - paper mill since 2018: K0 linerboard, B0 and other medium (110-170 g/m2), plasterboard back paper (140-200 g/m2), widths 950-2,450 mm, plus a 120 m m2/yr corrugator (2022). About 40,000 t/yr (2022 government table).', 'KZ check 2026-10-16: +7 727 388 19 88, info@nurkagazy.kz.'),
  ('kz recycling|kagazy recycling|kazakhstan kagazy', 'abay|karasay', 'kagazy|kz recycling', 'KZ Recycling (ex Kagazy Recycling) - Abay', 'Almaty Region', 'Abay', null, 'Kagazy Recycling(2001~) 이 2022 인수돼 KZ Recycling 으로 전환. Abay(Karasay) 초지기 2대(2002·2006) 종이 연 6만 t, 골판지 1.2억 m², 830명. 폐지 15만 t 현대화 2028 목표(365억 KZT).', 'KZ Recycling (formerly Kagazy Recycling, Kazakhstan Kagazy group since 2001, new owners 2022), Accounting Quarter 272 Building 27, Abay village (Karasay District, Almaty Region) - two paper machines (2002, 2006), 60,000 t/yr paper and 120 m m2/yr corrugated board, 830 staff. Modernisation to 150,000 t/yr waste-paper processing by 2028 (KZT 36.5 bn).', 'KZ check 2026-10-16: Kagazy Recycling and KZ Recycling are one mill - do not count twice. +7 727 244 87 87, kagazy@kagazy.kz.'),
  ('inter multi service', 'turksib|bekmakhan', 'inter multi', 'Inter Multi Service - Almaty', 'Almaty', 'Almaty', null, '알마티(Turksib) 재생지·판지 제조, 폐지 약 5.5만 t 처리. 초지기 현대화로 연 5.04만 t 목표(2026 말, 11억 텡게+).', 'Inter Multi Service LLP (BIN 080240023694), 96V Bekmakhanov Street, Turksib District, Almaty - recycled paper and board with its own machine, about 55,000 t/yr waste paper processed, machine modernisation for 50,400 t/yr due end 2026 (over KZT 1.1 bn).', 'KZ check 2026-10-16: modernised capacity is a target.'),
  ('sever-?kombinat|север-?комбинат', 'kostanay', 'sever|север', 'Sever-Kombinat - Kostanay', 'Kostanay', 'Kostanay', null, 'Kostanay 신규 제지 프로젝트(83억 KZT, 7개 라인, 계획 연 1.7만 t). 2025 위생지·영수증지 라인, 2026 아스타나 위생지 라인. 브랜드 Arumi Care.', 'Sever-Kombinat, 24 Uzkokoleynaya Street, Kostanay - staged project of seven lines (KZT 8.3 bn, 17,000 t/yr planned, 200 jobs): tissue and receipt paper lines 2025, board and bleached paper planned 2026, tissue lines also in Astana (2026). Brand Arumi Care.', 'KZ check 2026-10-16: actual running output not confirmed - 17 kt is the plan.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%KZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('karina', 'kazybay', 'karina', '알마티 대표 위생지 기업 Karina Paper(Karina Trading, 264A Kazybayev St). 자체 티슈 초지기 — Baotuo SF12-1100(1,100 m/분, 2,860 mm, 2019-12), 과거 TM2 일 60 t. 2026-03 4번째 라인 착공 계획(약 50억 텡게).', 'Karina Paper / Karina Trading, 264A Kazybayev Street, Almaty - tissue base paper, toilet tissue, napkins, towels on virgin or recycled pulp. Baotuo SF12-1100 tissue machine (1,100 m/min, 2,860 mm, suction former) started 2019-12, older TM2 reached about 60 t/day after upgrade (2015). Fourth line construction planned for 2026-03 (about KZT 5 bn, 100+ jobs).', 'KZ check 2026-10-16: PAPIRONE uses the same address and phone - treated as linked, not counted twice. Karina plus PAPIRONE hold 40-60 pct of the tissue market with 788 staff (Almaty akimat 2025). info@karina.kz, +7 777 805 80 98.'),
  ('alatau kagazy', 'kokrek|almaty', 'alatau kagazy', '1998년 시작 위생지 기업 Alatau Kagazy(777 Kokrek St). 2004 이탈리아·체코 기술 초지기 일 60 t, 2020 Fabio Perini 가공라인. 브랜드 Belosnezhka.', 'Alatau Kagazy (since 1998), 777 Kokrek Street, Almaty - tissue machine on Italian and Czech technology since 2004, 60 t/day, Fabio Perini converting line 2020, 3-ply tissue and wet-strength towels 2023, brand Belosnezhka.', 'KZ check 2026-10-16: 19,800 t/yr is 60 t/day x 330 (calculated). Phone on the site looks placeholder - verify. info@alataukagazy.kz.'),
  ('lucrum star', 'aktobe', 'lucrum', 'Aktobe 위생지 기업 Lucrum Star — 원지 연 3,335 t, 화장지 2,300만 롤·타월 300만 롤·냅킨 750만 팩. 100% 펄프·100% 폐지·70/30 배합.', 'Lucrum Star LLP, Industrial Zone 679D, Aktobe - tissue base paper 3,335 t/yr: 23 m toilet rolls, 3 m towel rolls, 7.5 m napkin packs, on 100 pct virgin pulp, 100 pct waste paper and 70/30 blends. Director Aslan Shoybekov, production head Dilmurat Tudakhunov.', 'KZ check 2026-10-16: +7 7132 74 90 27, lucrumstar@gmail.com.'),
  ('nur kagazy', 'panfilov|talgar', 'nur kagazy', '재생 라이너보드·골심지·석고보드 이면지 제조(2018 가동, Panfilovo, Talgar). 110~200 g/m², 지폭 950~2,450 mm, 2022 골판지 1.2억 m² 라인. 연 4만 t(2022 정부 자료).', 'NUR KAGAZY, 121 Zhambyl Street, Panfilovo (Talgar District, Almaty Region) - paper mill since 2018: K0 linerboard, B0 and other medium (110-170 g/m2), plasterboard back paper (140-200 g/m2), widths 950-2,450 mm, plus a 120 m m2/yr corrugator (2022). About 40,000 t/yr (2022 government table).', 'KZ check 2026-10-16: +7 727 388 19 88, info@nurkagazy.kz.'),
  ('kz recycling|kagazy recycling|kazakhstan kagazy', 'abay|karasay', 'kagazy|kz recycling', 'Kagazy Recycling(2001~) 이 2022 인수돼 KZ Recycling 으로 전환. Abay(Karasay) 초지기 2대(2002·2006) 종이 연 6만 t, 골판지 1.2억 m², 830명. 폐지 15만 t 현대화 2028 목표(365억 KZT).', 'KZ Recycling (formerly Kagazy Recycling, Kazakhstan Kagazy group since 2001, new owners 2022), Accounting Quarter 272 Building 27, Abay village (Karasay District, Almaty Region) - two paper machines (2002, 2006), 60,000 t/yr paper and 120 m m2/yr corrugated board, 830 staff. Modernisation to 150,000 t/yr waste-paper processing by 2028 (KZT 36.5 bn).', 'KZ check 2026-10-16: Kagazy Recycling and KZ Recycling are one mill - do not count twice. +7 727 244 87 87, kagazy@kagazy.kz.'),
  ('inter multi service', 'turksib|bekmakhan', 'inter multi', '알마티(Turksib) 재생지·판지 제조, 폐지 약 5.5만 t 처리. 초지기 현대화로 연 5.04만 t 목표(2026 말, 11억 텡게+).', 'Inter Multi Service LLP (BIN 080240023694), 96V Bekmakhanov Street, Turksib District, Almaty - recycled paper and board with its own machine, about 55,000 t/yr waste paper processed, machine modernisation for 50,400 t/yr due end 2026 (over KZT 1.1 bn).', 'KZ check 2026-10-16: modernised capacity is a target.'),
  ('sever-?kombinat|север-?комбинат', 'kostanay', 'sever|север', 'Kostanay 신규 제지 프로젝트(83억 KZT, 7개 라인, 계획 연 1.7만 t). 2025 위생지·영수증지 라인, 2026 아스타나 위생지 라인. 브랜드 Arumi Care.', 'Sever-Kombinat, 24 Uzkokoleynaya Street, Kostanay - staged project of seven lines (KZT 8.3 bn, 17,000 t/yr planned, 200 jobs): tissue and receipt paper lines 2025, board and bleached paper planned 2026, tissue lines also in Astana (2026). Brand Arumi Care.', 'KZ check 2026-10-16: actual running output not confirmed - 17 kt is the plan.'),
  ('papirone', null, 'papirone', null, null, 'KZ check 2026-10-16: Premium tissue, same address as Karina Paper - linked - context only.'),
  ('bumprom', null, 'bumprom', null, null, 'KZ check 2026-10-16: Paper and board, Shymkent - 15,000 t/yr (2022 table), machine to confirm - context only.'),
  ('goldman astana', null, 'goldman astana', null, null, 'KZ check 2026-10-16: Paper and board products, 7,200 t/yr (2022 table) - context only.'),
  ('lisbum', null, 'lisbum', null, null, 'KZ check 2026-10-16: Paper and board, Lisakovsk, 3,000 t/yr (2022 table) - context only.'),
  ('eco pack astana', null, 'eco pack astana', null, null, 'KZ check 2026-10-16: Paper and board products, 5,400 t/yr (2022 table) - context only.'),
  ('картонно-рубероид|pavlodar.*(cardboard|ruberoid)', null, 'картонно-рубероид|pavlodar.*(cardboard|ruberoid)', null, null, 'KZ check 2026-10-16: Roofing board, industrial paper - status to confirm - context only.'),
  ('gofrotara|гофротара', null, 'gofrotara|гофротара', null, null, 'KZ check 2026-10-16: Corrugated boxes, Pavlodar - converter - context only.'),
  ('amcor', null, 'amcor', null, null, 'KZ check 2026-10-16: Folding cartons - converter - context only.'),
  ('karaganda pulp', null, 'karaganda pulp', null, null, 'KZ check 2026-10-16: Waste-paper baling - papermaking not confirmed - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'kazakhstan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('karina', 'kazybay', 'karina'),
  ('alatau kagazy', 'kokrek|almaty', 'alatau kagazy'),
  ('lucrum star', 'aktobe', 'lucrum'),
  ('nur kagazy', 'panfilov|talgar', 'nur kagazy'),
  ('kz recycling|kagazy recycling|kazakhstan kagazy', 'abay|karasay', 'kagazy|kz recycling'),
  ('inter multi service', 'turksib|bekmakhan', 'inter multi'),
  ('sever-?kombinat|север-?комбинат', 'kostanay', 'sever|север'),
  ('papirone', null, 'papirone'),
  ('bumprom', null, 'bumprom'),
  ('goldman astana', null, 'goldman astana'),
  ('lisbum', null, 'lisbum'),
  ('eco pack astana', null, 'eco pack astana'),
  ('картонно-рубероид|pavlodar.*(cardboard|ruberoid)', null, 'картонно-рубероид|pavlodar.*(cardboard|ruberoid)'),
  ('gofrotara|гофротара', null, 'gofrotara|гофротара'),
  ('amcor', null, 'amcor'),
  ('karaganda pulp', null, 'karaganda pulp')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('karina', 'kazybay', 'karina',
   $pj${"owner": "Karina Paper (with PAPIRONE)", "priority": 1, "products": "Toilet tissue, napkins, towels", "grades": ["Tissue"], "pitch": "15 gsm tissue FCC data - trial on the Baotuo machine", "approach": "Lead Kazakh account - Asia Micron or TasUn as local GCC producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('alatau kagazy', 'kokrek|almaty', 'alatau kagazy',
   $pj${"owner": "Alatau Kagazy", "priority": 2, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "capacity": {"value": 19800, "unit": "metric_t", "year": "60 t/day x 330 (calculated)", "source": "alataukagazy.kz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct - tissue rate unproven."}, "approach": "Confirm machine status and furnish.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lucrum star', 'aktobe', 'lucrum',
   $pj${"owner": "Lucrum Star", "priority": 3, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "capacity": {"value": 3335, "unit": "metric_t", "year": "Company figure", "source": "lucrumstar.kz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct."}, "pitch": "Compare FCC on virgin, recycled and blended furnish", "approach": "Small - good first trial site. Aktau Minerals nearby as future supply.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nur kagazy', 'panfilov|talgar', 'nur kagazy',
   $pj${"owner": "NUR KAGAZY", "priority": 4, "products": "Recycled linerboard, medium, plasterboard paper", "grades": ["Testliner", "Medium", "Plasterboard liner"], "capacity": {"value": 40000, "unit": "metric_t", "year": "2022 government table", "source": "gov.kz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct - packaging strength first."}, "approach": "Drainage and strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kz recycling|kagazy recycling|kazakhstan kagazy', 'abay|karasay', 'kagazy|kz recycling',
   $pj${"owner": "KZ Recycling", "priority": 5, "products": "Recycled corrugating base paper, corrugated board", "grades": ["Testliner", "Medium"], "machines": 2, "capacity": {"value": 60000, "unit": "metric_t", "year": "Company site", "source": "kagazy.kz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct - packaging strength first."}, "approach": "Strength-hold trial - time it with the 2028 project.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('inter multi service', 'turksib|bekmakhan', 'inter multi',
   $pj${"owner": "Inter Multi Service", "priority": 6, "products": "Recycled paper and board", "grades": ["Testliner", "Board"], "capacity": {"value": 50400, "unit": "metric_t", "year": "Target after modernisation (end 2026)", "source": "gov.kz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct."}, "approach": "Pitch during modernisation.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sever-?kombinat|север-?комбинат', 'kostanay', 'sever|север',
   $pj${"owner": "Sever-Kombinat", "priority": 7, "products": "Tissue, receipt paper, board (planned)", "grades": ["Tissue", "Board"], "capacity_split": [{"label": "Plan (7 lines)", "value_t": 17000}], "approach": "Check which machines run.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papirone', null, 'papirone',
   $pj${"owner": "PAPIRONE", "products": "Premium tissue, same address as Karina Paper - linked", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bumprom', null, 'bumprom',
   $pj${"owner": "BumProm", "products": "Paper and board, Shymkent - 15,000 t/yr (2022 table), machine to confirm", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('goldman astana', null, 'goldman astana',
   $pj${"owner": "Goldman Astana", "products": "Paper and board products, 7,200 t/yr (2022 table)", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lisbum', null, 'lisbum',
   $pj${"owner": "LisBum.KZ", "products": "Paper and board, Lisakovsk, 3,000 t/yr (2022 table)", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('eco pack astana', null, 'eco pack astana',
   $pj${"owner": "Eco Pack Astana", "products": "Paper and board products, 5,400 t/yr (2022 table)", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('картонно-рубероид|pavlodar.*(cardboard|ruberoid)', null, 'картонно-рубероид|pavlodar.*(cardboard|ruberoid)',
   $pj${"owner": "Pavlodar Cardboard-Ruberoid Plant", "products": "Roofing board, industrial paper - status to confirm", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gofrotara|гофротара', null, 'gofrotara|гофротара',
   $pj${"owner": "Zavod Gofrotara", "products": "Corrugated boxes, Pavlodar - converter", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('amcor', null, 'amcor',
   $pj${"owner": "Amcor Specialty Cartons Kazakhstan", "products": "Folding cartons - converter", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('karaganda pulp', null, 'karaganda pulp',
   $pj${"owner": "Karaganda Pulp and Paper Combine", "products": "Waste-paper baling - papermaking not confirmed", "approach": "Confirm machine and output.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'KZ', 'Kazakhstan', 'medium',
   $cm$Almaty tissue (Karina Paper, Alatau Kagazy) and recycled liner (KZ Recycling 60 kt, NUR KAGAZY 40 kt) - fine marble GCC at Tekeli$cm$,
   $cm$Kazakhstan makes tissue and recycled packaging, no large printing-paper mill. Tissue: Karina Paper (with PAPIRONE, 40-60 pct of the market, Baotuo machine 2019), Alatau Kagazy (60 t/day), Lucrum Star (3.3 kt). Recycled packaging: KZ Recycling (ex Kagazy, 60 kt, 2 PMs), NUR KAGAZY (40 kt), Inter Multi Service (50.4 kt target). Sever-Kombinat is a staged 17 kt project. GCC: Asia Micron and TasUn (Tekeli marble, 2-20 micron), Kazhimtehsnab (Semey, plus hydrated lime), Aktau Minerals (new chalk plant). No paper PCC.$cm$,
   $cm${"fillers": "GCC: Asia Micron (Tekeli, 1-500 micron, 39,000 KZT/t), TasUn MARMAR (Tekeli, 2-14 micron, paper named), Kazhimtehsnab (Semey, GCC and hydrated lime), Aktau Minerals (Mangystau chalk, 10-12 t/h, start-up 2026), Global Chemicals Company (drilling grades). Not added: MicroCalcit, Mountain Mineral. No PCC plant.", "mills": "Tissue: Karina Paper / PAPIRONE, Alatau Kagazy (Almaty), Lucrum Star (Aktobe), Sever-Kombinat (Kostanay, project). Recycled packaging: KZ Recycling (Abay), NUR KAGAZY (Panfilovo), Inter Multi Service (Almaty). Context: BumProm, Goldman Astana, LisBum.KZ, Eco Pack Astana, Pavlodar Cardboard-Ruberoid, Gofrotara, Amcor, Karaganda PPC.", "strategy": "Tissue trials at Karina and Alatau Kagazy with Asia Micron or TasUn GCC, Lucrum Star as small first site. Packaging after a packaging-grade FCC is proven.", "risks": "Packaging strength limits, older 2022 capacity table.", "next_steps": ["Propose a tissue trial to Karina Paper", "Ask Asia Micron for PSD, brightness and wet grinding"], "key_numbers": [{"label": "KZ Recycling", "value": "60 kt paper, 120 m m2 board"}, {"label": "Karina + PAPIRONE", "value": "40-60 pct tissue market, 788 staff"}, {"label": "Report scenario", "value": "8,677-17,354 t FCC (5-10 pct of 173.5 kt)"}], "files": ["seed_20261016s_kazakhstan_mills_fillers"]}$cm$::jsonb,
   $cm$알마티 티슈(Karina Paper·Alatau Kagazy) + 재생 라이너(KZ Recycling 6만 t·NUR KAGAZY 4만 t) — Tekeli 미세 대리석 GCC$cm$,
   $cm$카자흐스탄은 티슈·재생 포장지 중심, 대형 인쇄용지 공장 없음. 티슈: Karina Paper(PAPIRONE 연계, 점유율 40~60%, Baotuo 2019), Alatau Kagazy(일 60 t), Lucrum Star(3,335 t). 재생 포장: KZ Recycling(구 Kagazy, 6만 t), NUR KAGAZY(4만 t), Inter Multi Service(5.04만 t 목표). GCC: Asia Micron·TasUn(Tekeli 대리석 2~20 μm), Kazhimtehsnab(Semey, 소석회), Aktau Minerals(신규 백악). 제지용 PCC 없음.$cm$,
   8677, 17354,
   $cm$KZ Recycling·NUR KAGAZY·IMS·Alatau·Lucrum 합 17.35만 t × FCC 5~10% (보고서 시나리오, 포장지 강도 검증 필요)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('karina', 'kazybay', 'karina'),
  ('alatau kagazy', 'kokrek|almaty', 'alatau kagazy'),
  ('lucrum star', 'aktobe', 'lucrum'),
  ('nur kagazy', 'panfilov|talgar', 'nur kagazy'),
  ('kz recycling|kagazy recycling|kazakhstan kagazy', 'abay|karasay', 'kagazy|kz recycling'),
  ('inter multi service', 'turksib|bekmakhan', 'inter multi'),
  ('sever-?kombinat|север-?комбинат', 'kostanay', 'sever|север'),
  ('papirone', null, 'papirone'),
  ('bumprom', null, 'bumprom'),
  ('goldman astana', null, 'goldman astana'),
  ('lisbum', null, 'lisbum'),
  ('eco pack astana', null, 'eco pack astana'),
  ('картонно-рубероид|pavlodar.*(cardboard|ruberoid)', null, 'картонно-рубероид|pavlodar.*(cardboard|ruberoid)'),
  ('gofrotara|гофротара', null, 'gofrotara|гофротара'),
  ('amcor', null, 'amcor'),
  ('karaganda pulp', null, 'karaganda pulp')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'kazakhstan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'kazakhstan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'asia micron|азия микрон' or p.party_name ~* 'tasun|marmar' or p.party_name ~* 'kazhimtehsnab|казхимтехснаб' or p.party_name ~* 'aktau minerals' or p.party_name ~* 'global chemicals company')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'KZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'KZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    