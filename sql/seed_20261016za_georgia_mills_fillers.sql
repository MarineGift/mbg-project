-- ============================================================
-- seed_20261016za_georgia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Georgia (republic) update (reports 2026-10-16).
-- 1) Fillers if missing (2): Geo-Filler (Rustavi and Kutaisi), GMM.
-- 2) Mills if missing (3) + plant blocks: Green Paper (1), Neoprint (2),
--    Georgian Paper Mill (stopped, no priority). Context (8): Georgian
--    Cardboard, Georgian Paper Production, Simetra, Kriala, Fabrica 1900,
--    Royal Paper, Greenpack, GeoPaper.
-- 3) app.country_markets GE row (priority low).
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
           v.party_name, 'GE', v.region, v.city, v.website, 'active', 'georgia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('geo-?filler', 'Geo-Filler - Rustavi and Kutaisi', 'Kvemo Kartli', 'Rustavi', null, '2017년 등록 석회석 분쇄 업체(ID 405228114). Rustavi 연 3만 t(45~170 μm) + Kutaisi 연 6.5만 t(5~170 μm), 사일로 트럭 출하.', 'Geo-Filler LLC (registered 2017-09-15, ID 405228114) - ground limestone at 9 Javakhishvili St, Rustavi (30,000 t/yr, 45-170 micron) and 88 Avtomshenebeli St, Kutaisi (65,000 t/yr, 5-170 micron), 25 mm feed, silo-truck delivery.', 'GE check 2026-10-16: 95 kt is nominal for both sites - purity, brightness, PSD and wet grinding not public. +995 598 499 499. FCC partner candidate 1.'),
  ('georgian mineral materials|\mgmm\M', 'Georgian Mineral Materials (GMM)', null, null, null, '석회석·방해석·백운석·모래·소석회 원료 가공 + 건식 건설재(CMC 브랜드, 2018~).', 'Georgian Mineral Materials (GMM) - processing and supply of limestone, calcite, dolomite, sand and hydrated lime, plus dry building mixes (own brand CMC since 2018) and toll manufacturing.', 'GE check 2026-10-16: quarry, grinding and capacity not public. office@gmm.ge, +995 598 217 555. No paper PCC plant and no Omya, MTI or Imerys site in Georgia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('geo-?filler', 'Geo-Filler - Rustavi and Kutaisi', 'Kvemo Kartli', 'Rustavi', null, '2017년 등록 석회석 분쇄 업체(ID 405228114). Rustavi 연 3만 t(45~170 μm) + Kutaisi 연 6.5만 t(5~170 μm), 사일로 트럭 출하.', 'Geo-Filler LLC (registered 2017-09-15, ID 405228114) - ground limestone at 9 Javakhishvili St, Rustavi (30,000 t/yr, 45-170 micron) and 88 Avtomshenebeli St, Kutaisi (65,000 t/yr, 5-170 micron), 25 mm feed, silo-truck delivery.', 'GE check 2026-10-16: 95 kt is nominal for both sites - purity, brightness, PSD and wet grinding not public. +995 598 499 499. FCC partner candidate 1.'),
  ('georgian mineral materials|\mgmm\M', 'Georgian Mineral Materials (GMM)', null, null, null, '석회석·방해석·백운석·모래·소석회 원료 가공 + 건식 건설재(CMC 브랜드, 2018~).', 'Georgian Mineral Materials (GMM) - processing and supply of limestone, calcite, dolomite, sand and hydrated lime, plus dry building mixes (own brand CMC since 2018) and toll manufacturing.', 'GE check 2026-10-16: quarry, grinding and capacity not public. office@gmm.ge, +995 598 217 555. No paper PCC plant and no Omya, MTI or Imerys site in Georgia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'georgia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Geo-Filler - Rustavi and Kutaisi', 'GCC producer', 'Limestone grinder (95 kt nominal) - candidate 1', 'merchant', 'C', 'gcc'),
  ('Georgian Mineral Materials (GMM)', 'GCC producer', 'Calcite raw material and toll grinding', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'georgia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'GE', v.region, v.city, v.website, 'active', 'georgia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('green paper', 'natakhtari', 'green paper', 'Green Paper - Natakhtari', 'Mtskheta-Mtianeti', 'Natakhtari', null, '2021년 설립 재생 골판지원지 공장(Natakhtari). Testliner·Fluting, 화이트탑 개발. 2023 계획 명목 연 2.5만 t, 지폭 2.5 m(중국 Qinyang Anshun), Georgian Cardboard 연계.', 'Green Paper (2021), Natakhtari (Mtskheta) - recovered-paper testliner and fluting, white-top testliner in development. New machine planned 2023 at 25,000 t/yr nominal, 2.5 m wide, by Qinyang Anshun (China), linked to the Georgian Cardboard group (AFRY 2023).', 'GE check 2026-10-16: actual output not public. info@greenpaper.ge, +995 551 990182 (also listed for Neoprint - check ownership).'),
  ('neoprint', 'tserovani', 'neoprint', 'Neoprint - Tserovani', 'Mtskheta-Mtianeti', 'Tserovani', null, '2001년 등록(204963762) Tserovani 초지기 1대 — Testliner·Fluting·크라프트지, 명목 연 7,200 t, 실제 3,000 t 이하(2023), 아제르바이잔·아르메니아 수출.', 'Neoprint Ltd (registered 2001-06-07, ID 204963762), Tserovani 8 (Mtskheta-Mtianeti) - one paper machine for testliner, fluting and kraft paper, 7,200 t/yr nominal and under 3,000 t actual (AFRY 2023), exports to Azerbaijan and Armenia.', 'GE check 2026-10-16: cost and quality were weak points in 2023. Shares a phone number with Green Paper.'),
  ('georgian paper mill', 'tbilisi', 'georgian paper mill', 'Georgian Paper Mill - Tbilisi', 'Tbilisi', 'Tbilisi', null, '2005년 등록 Tbilisi 소형 초지기 1대(과거 연 1,000~2,000 t) — 2023 원지 생산 중단 보고, 포장재 업체로 등재.', 'Georgian Paper Mill (registered 2005-01-28), 21 Givi Amilakhvari St, Tbilisi - one machine, historical 1,000-2,000 t/yr testliner and fluting, base-paper production reported stopped in 2023, still listed for packaging.', 'GE check 2026-10-16: restart not confirmed. georgianbox@gmail.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('green paper', 'natakhtari', 'green paper', '2021년 설립 재생 골판지원지 공장(Natakhtari). Testliner·Fluting, 화이트탑 개발. 2023 계획 명목 연 2.5만 t, 지폭 2.5 m(중국 Qinyang Anshun), Georgian Cardboard 연계.', 'Green Paper (2021), Natakhtari (Mtskheta) - recovered-paper testliner and fluting, white-top testliner in development. New machine planned 2023 at 25,000 t/yr nominal, 2.5 m wide, by Qinyang Anshun (China), linked to the Georgian Cardboard group (AFRY 2023).', 'GE check 2026-10-16: actual output not public. info@greenpaper.ge, +995 551 990182 (also listed for Neoprint - check ownership).'),
  ('neoprint', 'tserovani', 'neoprint', '2001년 등록(204963762) Tserovani 초지기 1대 — Testliner·Fluting·크라프트지, 명목 연 7,200 t, 실제 3,000 t 이하(2023), 아제르바이잔·아르메니아 수출.', 'Neoprint Ltd (registered 2001-06-07, ID 204963762), Tserovani 8 (Mtskheta-Mtianeti) - one paper machine for testliner, fluting and kraft paper, 7,200 t/yr nominal and under 3,000 t actual (AFRY 2023), exports to Azerbaijan and Armenia.', 'GE check 2026-10-16: cost and quality were weak points in 2023. Shares a phone number with Green Paper.'),
  ('georgian paper mill', 'tbilisi', 'georgian paper mill', '2005년 등록 Tbilisi 소형 초지기 1대(과거 연 1,000~2,000 t) — 2023 원지 생산 중단 보고, 포장재 업체로 등재.', 'Georgian Paper Mill (registered 2005-01-28), 21 Givi Amilakhvari St, Tbilisi - one machine, historical 1,000-2,000 t/yr testliner and fluting, base-paper production reported stopped in 2023, still listed for packaging.', 'GE check 2026-10-16: restart not confirmed. georgianbox@gmail.com.'),
  ('georgian cardboard', null, 'georgian cardboard', null, null, 'GE check 2026-10-16: Corrugated board and boxes, Tbilisi - group behind Green Paper - context only.'),
  ('georgian paper production', null, 'georgian paper production', null, null, 'GE check 2026-10-16: Sanitary paper and waste-paper collection - own machine not confirmed - context only.'),
  ('simetra', null, 'simetra', null, null, 'GE check 2026-10-16: Toilet tissue products, Tbilisi - likely converts imported rolls - context only.'),
  ('kriala', null, 'kriala', null, null, 'GE check 2026-10-16: Napkins and sanitary paper, Tbilisi - likely converts imported rolls - context only.'),
  ('fabrica 1900', null, 'fabrica 1900', null, null, 'GE check 2026-10-16: Corrugated board 10 m m2/month, Dzegvi - converter - context only.'),
  ('royal paper', null, 'royal paper', null, null, 'GE check 2026-10-16: Corrugated boxes, Natakhtari - converter - context only.'),
  ('greenpack', null, 'greenpack', null, null, 'GE check 2026-10-16: Paper packaging, Natakhtari - converter - context only.'),
  ('geopaper', null, 'geopaper', null, null, 'GE check 2026-10-16: Printing and coated paper importer (APRIL, Sappi, UPM, Billerud) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'georgia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('green paper', 'natakhtari', 'green paper'),
  ('neoprint', 'tserovani', 'neoprint'),
  ('georgian paper mill', 'tbilisi', 'georgian paper mill'),
  ('georgian cardboard', null, 'georgian cardboard'),
  ('georgian paper production', null, 'georgian paper production'),
  ('simetra', null, 'simetra'),
  ('kriala', null, 'kriala'),
  ('fabrica 1900', null, 'fabrica 1900'),
  ('royal paper', null, 'royal paper'),
  ('greenpack', null, 'greenpack'),
  ('geopaper', null, 'geopaper')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('green paper', 'natakhtari', 'green paper',
   $pj${"owner": "Green Paper (Georgian Cardboard group)", "priority": 1, "products": "Testliner, fluting (white-top planned)", "grades": ["Testliner", "Medium", "White-top liner"], "capacity": {"value": 25000, "unit": "metric_t", "year": "Nominal (AFRY 2023)", "source": "AFRY"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "1-3 pct trial range - strength must hold."}, "approach": "Low-dose trial (SCT, RCT, burst, drainage), white-top liner optics.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('neoprint', 'tserovani', 'neoprint',
   $pj${"owner": "Neoprint", "priority": 2, "products": "Testliner, fluting, kraft paper", "grades": ["Testliner", "Medium", "Kraft paper"], "capacity": {"value": 7200, "unit": "metric_t", "year": "Nominal (AFRY 2023)", "source": "AFRY"}, "approach": "Confirm operation and ownership link to Green Paper.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('georgian paper mill', 'tbilisi', 'georgian paper mill',
   $pj${"owner": "Georgian Paper Mill", "products": "Testliner, fluting (stopped 2023), corrugated", "grades": ["Testliner"], "approach": "Long-term - restart only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('georgian cardboard', null, 'georgian cardboard',
   $pj${"owner": "Georgian Cardboard", "products": "Corrugated board and boxes, Tbilisi - group behind Green Paper", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('georgian paper production', null, 'georgian paper production',
   $pj${"owner": "Georgian Paper Production", "products": "Sanitary paper and waste-paper collection - own machine not confirmed", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('simetra', null, 'simetra',
   $pj${"owner": "Simetra", "products": "Toilet tissue products, Tbilisi - likely converts imported rolls", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kriala', null, 'kriala',
   $pj${"owner": "Kriala", "products": "Napkins and sanitary paper, Tbilisi - likely converts imported rolls", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fabrica 1900', null, 'fabrica 1900',
   $pj${"owner": "Fabrica 1900", "products": "Corrugated board 10 m m2/month, Dzegvi - converter", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('royal paper', null, 'royal paper',
   $pj${"owner": "Royal Paper", "products": "Corrugated boxes, Natakhtari - converter", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('greenpack', null, 'greenpack',
   $pj${"owner": "Greenpack", "products": "Paper packaging, Natakhtari - converter", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('geopaper', null, 'geopaper',
   $pj${"owner": "GeoPaper", "products": "Printing and coated paper importer (APRIL, Sappi, UPM, Billerud)", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GE', 'Georgia', 'low',
   $cm$Small recycled containerboard mills (Green Paper 25 kt nominal, Neoprint 7.2 kt) - limestone grinding at Geo-Filler (95 kt)$cm$,
   $cm$Georgia (the republic) makes only recycled containerboard: Green Paper (Natakhtari, 25 kt nominal machine, 2023) and Neoprint (Tserovani, 7.2 kt nominal, under 3 kt actual), with Georgian Paper Mill stopped in 2023. Tissue makers and box plants mostly convert imported rolls, printing paper is imported (GeoPaper). Containerboard demand about 23.3 kt in 2022, under 5 pct local. Carbonate: Geo-Filler grinds limestone at Rustavi and Kutaisi (95 kt nominal, to 5 micron), GMM supplies calcite. No paper PCC.$cm$,
   $cm${"fillers": "Geo-Filler (Rustavi 30 kt, Kutaisi 65 kt, 5-170 micron), GMM (calcite and limestone). No PCC, no global filler maker site.", "mills": "Green Paper Natakhtari, Neoprint Tserovani, Georgian Paper Mill Tbilisi (stopped). Context: Georgian Cardboard, Georgian Paper Production, Simetra, Kriala, Fabrica 1900, Royal Paper, Greenpack, GeoPaper.", "strategy": "Low-cost pilot at Green Paper with Geo-Filler as local carbonate source - base for Caucasus outreach.", "risks": "Small recycled-liner volumes, strength limits.", "next_steps": ["Ask Green Paper for output, furnish and filler use"], "key_numbers": [{"label": "Containerboard demand 2022", "value": "about 23.3 kt, under 5 pct local (AFRY)"}, {"label": "Green Paper", "value": "25 kt/yr nominal"}], "files": ["seed_20261016za_georgia_mills_fillers"]}$cm$::jsonb,
   $cm$소형 재생 골판지원지 공장(Green Paper 명목 2.5만 t, Neoprint 7,200 t) — Geo-Filler 석회석 분쇄(9.5만 t)$cm$,
   $cm$조지아(공화국)는 재생 골판지원지만 생산: Green Paper(Natakhtari, 명목 2.5만 t, 2023), Neoprint(Tserovani, 명목 7,200 t·실제 3,000 t 이하), Georgian Paper Mill 은 2023 중단. 티슈·상자업체는 대부분 수입 원지 가공, 인쇄용지는 수입(GeoPaper). 2022 골판지원지 수요 약 2.33만 t, 현지 5% 미만. 탄산칼슘: Geo-Filler(Rustavi·Kutaisi 9.5만 t), GMM. 제지용 PCC 없음.$cm$,
   322, 966,
   $cm$Green Paper 2.5만 + Neoprint 7,200 t × FCC 1~3%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('green paper', 'natakhtari', 'green paper'),
  ('neoprint', 'tserovani', 'neoprint'),
  ('georgian paper mill', 'tbilisi', 'georgian paper mill'),
  ('georgian cardboard', null, 'georgian cardboard'),
  ('georgian paper production', null, 'georgian paper production'),
  ('simetra', null, 'simetra'),
  ('kriala', null, 'kriala'),
  ('fabrica 1900', null, 'fabrica 1900'),
  ('royal paper', null, 'royal paper'),
  ('greenpack', null, 'greenpack'),
  ('geopaper', null, 'geopaper')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'georgia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'georgia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'geo-?filler' or p.party_name ~* 'georgian mineral materials|\mgmm\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    