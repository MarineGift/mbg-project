-- ============================================================
-- seed_20261016zg_bulgaria_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bulgaria update (reports 2026-10-16).
-- 1) Fillers if missing (4): Calcit JSC Asenovgrad (PCC - guard is site
--    specific, not the Slovenian Calcit Group), Kaolin EAD Ignatievo,
--    Bulterra S, Omya Bulgaria.
-- 2) Mills if missing (4) + plant blocks, priority 1-4: Belovo, Kostenets
--    HHI, GFF Nikopol, Nova Knizhna Fabrika. Context (5): Mondi Stambolijski
--    (closed), Svilocell (stopped), Dunapack-Rodina, Velpa 91, Vitavel.
-- 3) app.country_markets BG row (priority medium).
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
           v.party_name, 'BG', v.region, v.city, v.website, 'active', 'bulgaria_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcit.*(asenovgrad|jsc|bulgar)|caltsit', 'Calcit JSC - Asenovgrad (PCC)', 'Plovdiv', 'Asenovgrad', null, '1952년 설립 Asenovgrad PCC·생석회·소석회·탄화칼슘 제조사. PCC CaCO3 98.5%, 백색도 94, 5 μm 이하 60%·10 μm 이하 97%, 구형+침상 아라고나이트. SDS 에 제지 용도 명시. 2005 자료 연 약 2.1만 t.', 'Calcit JSC (1952), Industrial Zone North, Asenovgrad (Plovdiv) - PCC, quicklime, hydrated lime, calcium carbide, acetylene, ISO 9001: PCC 98.5 pct CaCO3, brightness 94 (MgO basis), Fe 0.08 pct, 60 pct under 5 micron and 97 pct under 10 micron, spherical and needle aragonite crystals, 25 kg bags, paper making named in its SDS. About 21,000 t/yr PCC in 2005 (Roskill, as Caltsit-952).', 'BG check 2026-10-16: coarser than paper filler PCC - paper grade, slurry and current capacity to confirm. office@calcit-bg.com, +359 331 63300. Not the Slovenian Calcit Group.'),
  ('kaolin.*ignatievo|kaolin ead', 'Kaolin EAD - Ignatievo (carbonate)', 'Varna', 'Ignatievo', null, '불가리아 주요 산업광물 기업 Kaolin EAD — Ignatievo 공장 1985년부터 탄산염 충전제(분쇄 석회석, 플라스틱·고무·도료). 제지용 카올린 충전·코팅 별도 생산.', 'Kaolin EAD - Ignatievo processing plant making carbonate fillers since 1985 (ground limestone mainly for plastics, rubber, paint), plus paper-grade kaolin fillers and coating minerals at Senovo, Vetovo, Kaolinovo.', 'BG check 2026-10-16: ground limestone not confirmed for paper. Paper minerals contact: Virginia Bliznakova, bliznakova.virginia@kaolin.bg, +359 2 4893 683.'),
  ('bulterra', 'Bulterra S - Dolna Gradeshnitsa', 'Blagoevgrad', 'Dolna Gradeshnitsa', null, '2008년 설립 대리석 GCC(Dolna Gradeshnitsa), 2017 Ilindentsi 대리석 광산 공동 채굴권. CaCO3 97% 이상, 5~150 μm, 제지 용도 명시.', 'Bulterra S Ltd (2008), Dolna Gradeshnitsa (Blagoevgrad) - GCC of natural marble (Ilindentsi quarry concession shared since 2017), over 97 pct CaCO3, 5-150 micron, paper, paint, building, glass and fertiliser named.', 'BG check 2026-10-16: wet ultrafine and paper deliveries not confirmed.'),
  ('omya.*bulgar', 'Omya Bulgaria - Sofia', 'Sofia', 'Sofia', null, 'Omya Bulgaria EOOD(Sofia) — 제지·도료·플라스틱·고무 충전제 공급 법인, 현지 생산 미확인.', 'Omya Bulgaria EOOD, 8 Orel Street, Sofia - supplies fillers for paper, paint, plastics and rubber.', 'BG check 2026-10-16: no Bulgarian plant confirmed. Royalty licensee at Omya HQ level. Not added: Heidelberg Materials Devnya / Vulkan (micro limestone, now sold for construction), Carboplast (Erciyes Mikron reseller).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcit.*(asenovgrad|jsc|bulgar)|caltsit', 'Calcit JSC - Asenovgrad (PCC)', 'Plovdiv', 'Asenovgrad', null, '1952년 설립 Asenovgrad PCC·생석회·소석회·탄화칼슘 제조사. PCC CaCO3 98.5%, 백색도 94, 5 μm 이하 60%·10 μm 이하 97%, 구형+침상 아라고나이트. SDS 에 제지 용도 명시. 2005 자료 연 약 2.1만 t.', 'Calcit JSC (1952), Industrial Zone North, Asenovgrad (Plovdiv) - PCC, quicklime, hydrated lime, calcium carbide, acetylene, ISO 9001: PCC 98.5 pct CaCO3, brightness 94 (MgO basis), Fe 0.08 pct, 60 pct under 5 micron and 97 pct under 10 micron, spherical and needle aragonite crystals, 25 kg bags, paper making named in its SDS. About 21,000 t/yr PCC in 2005 (Roskill, as Caltsit-952).', 'BG check 2026-10-16: coarser than paper filler PCC - paper grade, slurry and current capacity to confirm. office@calcit-bg.com, +359 331 63300. Not the Slovenian Calcit Group.'),
  ('kaolin.*ignatievo|kaolin ead', 'Kaolin EAD - Ignatievo (carbonate)', 'Varna', 'Ignatievo', null, '불가리아 주요 산업광물 기업 Kaolin EAD — Ignatievo 공장 1985년부터 탄산염 충전제(분쇄 석회석, 플라스틱·고무·도료). 제지용 카올린 충전·코팅 별도 생산.', 'Kaolin EAD - Ignatievo processing plant making carbonate fillers since 1985 (ground limestone mainly for plastics, rubber, paint), plus paper-grade kaolin fillers and coating minerals at Senovo, Vetovo, Kaolinovo.', 'BG check 2026-10-16: ground limestone not confirmed for paper. Paper minerals contact: Virginia Bliznakova, bliznakova.virginia@kaolin.bg, +359 2 4893 683.'),
  ('bulterra', 'Bulterra S - Dolna Gradeshnitsa', 'Blagoevgrad', 'Dolna Gradeshnitsa', null, '2008년 설립 대리석 GCC(Dolna Gradeshnitsa), 2017 Ilindentsi 대리석 광산 공동 채굴권. CaCO3 97% 이상, 5~150 μm, 제지 용도 명시.', 'Bulterra S Ltd (2008), Dolna Gradeshnitsa (Blagoevgrad) - GCC of natural marble (Ilindentsi quarry concession shared since 2017), over 97 pct CaCO3, 5-150 micron, paper, paint, building, glass and fertiliser named.', 'BG check 2026-10-16: wet ultrafine and paper deliveries not confirmed.'),
  ('omya.*bulgar', 'Omya Bulgaria - Sofia', 'Sofia', 'Sofia', null, 'Omya Bulgaria EOOD(Sofia) — 제지·도료·플라스틱·고무 충전제 공급 법인, 현지 생산 미확인.', 'Omya Bulgaria EOOD, 8 Orel Street, Sofia - supplies fillers for paper, paint, plastics and rubber.', 'BG check 2026-10-16: no Bulgarian plant confirmed. Royalty licensee at Omya HQ level. Not added: Heidelberg Materials Devnya / Vulkan (micro limestone, now sold for construction), Carboplast (Erciyes Mikron reseller).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'bulgaria_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calcit JSC - Asenovgrad (PCC)', 'PCC producer', 'Local PCC maker - FCC co-production candidate 1', 'merchant', 'B', 'pcc'),
  ('Kaolin EAD - Ignatievo (carbonate)', 'GCC producer', 'GCC plus paper kaolin know-how', 'merchant', 'C', 'gcc'),
  ('Bulterra S - Dolna Gradeshnitsa', 'GCC producer', 'Marble GCC, paper named', 'merchant', 'C', 'gcc'),
  ('Omya Bulgaria - Sofia', 'GCC and PCC supplier', 'Omya Bulgaria - sales office (licensee group)', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bulgaria_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BG', v.region, v.city, v.website, 'active', 'bulgaria_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('belovo|belana', 'belovo', 'belovo|belana', 'Belovo Paper Mill (Belana) - Belovo', 'Pazardzhik', 'Belovo', null, '1900년 설립 불가리아 최대 티슈 제조사(Belana) — 초지기 4대, 티슈·포장지 연 약 5.8만 t, 원지~완제품 통합, 수출.', 'Belovo Paper Mill (1900, brand Belana), 1A Dabravsko Shose, Belovo (Pazardzhik) - largest Bulgarian tissue maker: four paper machines, about 58,000 t/yr tissue and packaging paper, integrated jumbo rolls to toilet, kitchen, napkins, facial and pocket tissue, exports in Europe.', 'BG check 2026-10-16: office@belana.bg, +359 3581 2105.'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi', 'Kostenets HHI - Kostenets', 'Sofia Province', 'Kostenets', null, 'Kostenets HHI — PM1 재생 플루팅(8,000 t+), PM2 MG지 1.5만 t 또는 티슈 9,000 t, PM3 크레센트 티슈(15~35 gsm, 1,800 m/분) 2만~2.7만 t.', 'Kostenets HHI AD, 2 Saedinenie St, Kostenets - PM1 Voith recycled fluting 80-220 gsm (over 8,000 t/yr), PM2 MG paper 15,000 t/yr or tissue 9,000 t/yr (17-70 gsm), PM3 OverMeccanica crescent-former tissue 15-35 gsm at 1,800 m/min (20,000-27,000 t/yr), virgin and recycled tissue.', 'BG check 2026-10-16: PM2 alternates grades - 50 kt is the upper sum. kosthhi@hhi-bg.eu, +359 7142 2131. Listed - 2025 annual and 2026 half-year reports published.'),
  ('\mgff\M|gff paper', 'nikopol', 'gff', 'GFF Paper Mill - Nikopol', 'Pleven', 'Nikopol', null, 'Nikopol 티슈 공장(2010 판지→티슈 전환) — PM1 Voith 평망 4,500 mm 2만 t + PM2 Recard 크레센트 2,800 mm 2만 t = 연 4만 t, 재생·버진 펄프.', 'GFF Paper Mill, Industrial Zone Nikopol / Cherkovitsa (Pleven) - former board mill, tissue since 2010: PM1 Voith flat-wire 4,500 mm (20,000 t/yr) and PM2 Recard crescent former 2,800 mm (20,000 t/yr), 40,000 t/yr tissue on recycled and virgin pulp, about 273,000 m2 site.', 'BG check 2026-10-16: gffpaper@gmail.com, sales Ivo Yordanov +359 888 711 176.'),
  ('nova knizhna|knizhna fabrika', 'gara iskar|sofia', 'knizhna', 'Nova Knizhna Fabrika - Gara Iskar (Sofia)', 'Sofia', 'Sofia', null, '1937년 Iskar 제지공장 승계 — 현재 재생 포장지·플루팅(과거 복사·지도·보안용지 이력).', 'Nova Knizhna Fabrika EOOD, Gara Iskar, Sofia - successor of the 1937 Iskar paper factory (formerly copy, map, wallpaper and security paper), now recycled packaging paper and fluting.', 'BG check 2026-10-16: capacity not public. office@nkfabrika.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('belovo|belana', 'belovo', 'belovo|belana', '1900년 설립 불가리아 최대 티슈 제조사(Belana) — 초지기 4대, 티슈·포장지 연 약 5.8만 t, 원지~완제품 통합, 수출.', 'Belovo Paper Mill (1900, brand Belana), 1A Dabravsko Shose, Belovo (Pazardzhik) - largest Bulgarian tissue maker: four paper machines, about 58,000 t/yr tissue and packaging paper, integrated jumbo rolls to toilet, kitchen, napkins, facial and pocket tissue, exports in Europe.', 'BG check 2026-10-16: office@belana.bg, +359 3581 2105.'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi', 'Kostenets HHI — PM1 재생 플루팅(8,000 t+), PM2 MG지 1.5만 t 또는 티슈 9,000 t, PM3 크레센트 티슈(15~35 gsm, 1,800 m/분) 2만~2.7만 t.', 'Kostenets HHI AD, 2 Saedinenie St, Kostenets - PM1 Voith recycled fluting 80-220 gsm (over 8,000 t/yr), PM2 MG paper 15,000 t/yr or tissue 9,000 t/yr (17-70 gsm), PM3 OverMeccanica crescent-former tissue 15-35 gsm at 1,800 m/min (20,000-27,000 t/yr), virgin and recycled tissue.', 'BG check 2026-10-16: PM2 alternates grades - 50 kt is the upper sum. kosthhi@hhi-bg.eu, +359 7142 2131. Listed - 2025 annual and 2026 half-year reports published.'),
  ('\mgff\M|gff paper', 'nikopol', 'gff', 'Nikopol 티슈 공장(2010 판지→티슈 전환) — PM1 Voith 평망 4,500 mm 2만 t + PM2 Recard 크레센트 2,800 mm 2만 t = 연 4만 t, 재생·버진 펄프.', 'GFF Paper Mill, Industrial Zone Nikopol / Cherkovitsa (Pleven) - former board mill, tissue since 2010: PM1 Voith flat-wire 4,500 mm (20,000 t/yr) and PM2 Recard crescent former 2,800 mm (20,000 t/yr), 40,000 t/yr tissue on recycled and virgin pulp, about 273,000 m2 site.', 'BG check 2026-10-16: gffpaper@gmail.com, sales Ivo Yordanov +359 888 711 176.'),
  ('nova knizhna|knizhna fabrika', 'gara iskar|sofia', 'knizhna', '1937년 Iskar 제지공장 승계 — 현재 재생 포장지·플루팅(과거 복사·지도·보안용지 이력).', 'Nova Knizhna Fabrika EOOD, Gara Iskar, Sofia - successor of the 1937 Iskar paper factory (formerly copy, map, wallpaper and security paper), now recycled packaging paper and fluting.', 'BG check 2026-10-16: capacity not public. office@nkfabrika.com.'),
  ('mondi.*stamboli', null, 'mondi.*stamboli', null, null, 'BG check 2026-10-16: Mondi Stambolijski kraft mill - closed after the 2024-09 fire (about EUR 113 m closure cost, 2025 report) - context only.'),
  ('svilocell|svilosa', null, 'svilocell|svilosa', null, null, 'BG check 2026-10-16: Svilocell Svishtov kraft pulp 150 kt/yr - production stopped (2026-08) - context only.'),
  ('dunapack.*rodina|rodina', null, 'dunapack.*rodina|rodina', null, null, 'BG check 2026-10-16: Corrugated packaging, Plovdiv - converter - context only.'),
  ('velpa', null, 'velpa', null, null, 'BG check 2026-10-16: Corrugated packaging, Strazhitsa - converter - context only.'),
  ('vitavel', null, 'vitavel', null, null, 'BG check 2026-10-16: Corrugated packaging, Lukovit - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'bulgaria_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('belovo|belana', 'belovo', 'belovo|belana'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi'),
  ('\mgff\M|gff paper', 'nikopol', 'gff'),
  ('nova knizhna|knizhna fabrika', 'gara iskar|sofia', 'knizhna'),
  ('mondi.*stamboli', null, 'mondi.*stamboli'),
  ('svilocell|svilosa', null, 'svilocell|svilosa'),
  ('dunapack.*rodina|rodina', null, 'dunapack.*rodina|rodina'),
  ('velpa', null, 'velpa'),
  ('vitavel', null, 'vitavel')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('belovo|belana', 'belovo', 'belovo|belana',
   $pj${"owner": "Belovo", "priority": 1, "products": "Tissue, packaging paper", "grades": ["Tissue"], "machines": 4, "capacity": {"value": 58000, "unit": "metric_t", "year": "Company figure", "source": "belana.bg"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 1-5 pct."}, "pitch": "Tissue FCC 1-3-5 pct trial", "approach": "Lead Bulgarian account - Calcit PCC or Kaolin as local producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi',
   $pj${"owner": "Kostenets HHI", "priority": 2, "products": "Tissue, MG paper, recycled fluting", "grades": ["Tissue", "MG paper", "Medium"], "machines": 3, "capacity": {"value": 50000, "unit": "metric_t", "year": "Company (PM1 8 + PM2 15 + PM3 27, upper)", "source": "hhi-bg.eu"}, "capacity_split": [{"label": "PM3 tissue", "value_t": 27000}, {"label": "PM2 MG or tissue", "value_t": 15000}, {"label": "PM1 fluting", "value_t": 8000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.54, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 0.54, "fcc_loading": 0.05}], "note": "PM3 tissue share only."}, "approach": "PM3 tissue trial, compare with PM2.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mgff\M|gff paper', 'nikopol', 'gff',
   $pj${"owner": "GFF", "priority": 3, "products": "Tissue jumbo rolls, toilet, kitchen, napkins", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 40000, "unit": "metric_t", "year": "Company figure", "source": "gffpapermill.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 1-5 pct."}, "pitch": "Compare FCC on flat-wire and crescent machines", "approach": "Virgin vs recycled furnish trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nova knizhna|knizhna fabrika', 'gara iskar|sofia', 'knizhna',
   $pj${"owner": "Nova Knizhna Fabrika", "priority": 4, "products": "Recycled packaging paper, fluting", "grades": ["Medium"], "approach": "Strength-hold trial only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mondi.*stamboli', null, 'mondi.*stamboli',
   $pj${"owner": "Mondi", "products": "Mondi Stambolijski kraft mill - closed after the 2024-09 fire (about EUR 113 m closure cost, 2025 report)", "approach": "Closed, pulp only or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('svilocell|svilosa', null, 'svilocell|svilosa',
   $pj${"owner": "Svilosa", "products": "Svilocell Svishtov kraft pulp 150 kt/yr - production stopped (2026-08)", "approach": "Closed, pulp only or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dunapack.*rodina|rodina', null, 'dunapack.*rodina|rodina',
   $pj${"owner": "Dunapack-Rodina (Prinzhorn)", "products": "Corrugated packaging, Plovdiv - converter", "approach": "Closed, pulp only or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('velpa', null, 'velpa',
   $pj${"owner": "Velpa 91", "products": "Corrugated packaging, Strazhitsa - converter", "approach": "Closed, pulp only or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vitavel', null, 'vitavel',
   $pj${"owner": "Vitavel", "products": "Corrugated packaging, Lukovit - converter", "approach": "Closed, pulp only or converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BG', 'Bulgaria', 'medium',
   $cm$Tissue cluster (Belovo 58 kt, GFF 40 kt, Kostenets PM3 27 kt) - local PCC maker Calcit Asenovgrad$cm$,
   $cm$Bulgaria is a tissue market: Belovo (Belana, 58 kt), GFF Nikopol (40 kt, two machines) and Kostenets HHI (PM3 tissue 27 kt plus MG and fluting) - about 125 kt tissue nameplate - plus Nova Knizhna Fabrika recycled fluting. Mondi Stambolijski closed after the 2024 fire, Svilocell pulp is stopped. Fillers: Calcit JSC makes PCC at Asenovgrad (coarse, paper named in SDS), Kaolin EAD (Ignatievo carbonate plus paper kaolin), Bulterra (marble GCC), Omya Bulgaria sales office.$cm$,
   $cm${"fillers": "PCC: Calcit JSC Asenovgrad (98.5 pct, 97 pct under 10 micron). GCC: Kaolin EAD Ignatievo, Bulterra S. Licensee office: Omya Bulgaria. Not added: Heidelberg Materials Devnya, Carboplast.", "mills": "Tissue: Belovo, GFF Nikopol, Kostenets HHI. Recycled fluting: Nova Knizhna Fabrika. Closed or stopped: Mondi Stambolijski, Svilocell. Converters: Dunapack-Rodina, Velpa 91, Vitavel.", "strategy": "Tissue trials at Belovo, Kostenets PM3 and GFF, with Calcit PCC or Kaolin as local FCC producer.", "risks": "Calcit PCC is coarse - may need a new fine line.", "next_steps": ["Propose a tissue trial to Belovo", "Ask Calcit for paper-grade PCC and slurry capacity"], "key_numbers": [{"label": "Tissue nameplate (3 mills)", "value": "about 125 kt/yr"}, {"label": "Calcit PCC (2005)", "value": "about 21 kt/yr"}], "files": ["seed_20261016zg_bulgaria_mills_fillers"]}$cm$::jsonb,
   $cm$티슈 클러스터(Belovo 5.8만·GFF 4만·Kostenets PM3 2.7만 t) — 현지 PCC 제조사 Calcit Asenovgrad$cm$,
   $cm$불가리아는 티슈 시장: Belovo(Belana 5.8만 t), GFF Nikopol(4만 t), Kostenets HHI(PM3 티슈 2.7만 t + MG·플루팅) — 티슈 명목 약 12.5만 t — 와 Nova Knizhna Fabrika 재생 플루팅. Mondi Stambolijski 는 2024 화재 후 폐쇄, Svilocell 펄프 중단. 충전제: Calcit JSC 가 Asenovgrad 에서 PCC 생산(입도 굵음, SDS 에 제지 명시), Kaolin EAD, Bulterra, Omya Bulgaria 영업소.$cm$,
   1250, 6250,
   $cm$티슈 3개 공장 12.5만 t × FCC 1~5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('belovo|belana', 'belovo', 'belovo|belana'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi'),
  ('\mgff\M|gff paper', 'nikopol', 'gff'),
  ('nova knizhna|knizhna fabrika', 'gara iskar|sofia', 'knizhna'),
  ('mondi.*stamboli', null, 'mondi.*stamboli'),
  ('svilocell|svilosa', null, 'svilocell|svilosa'),
  ('dunapack.*rodina|rodina', null, 'dunapack.*rodina|rodina'),
  ('velpa', null, 'velpa'),
  ('vitavel', null, 'vitavel')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'bulgaria_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'bulgaria_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcit.*(asenovgrad|jsc|bulgar)|caltsit' or p.party_name ~* 'kaolin.*ignatievo|kaolin ead' or p.party_name ~* 'bulterra' or p.party_name ~* 'omya.*bulgar')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    