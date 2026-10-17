-- ============================================================
-- seed_20261016zze_switzerland_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Switzerland update (reports 2026-10-16). Fixed generator.
-- Omya HQ guard targets Swiss names only (or a bare "Omya" / "Omya AG" row).
-- 1) Fillers if missing (2): Omya (Schweiz) AG Oftringen HQ, Kalkfabrik
--    Netstal.
-- 2) Mills if missing (7) + plant blocks, priority 1-5: Perlen, Swiss
--    Quality Paper, Tela / Cartaseta, Model Weinfelden, Model Niedergösgen.
--    No priority: Papierfabrik Netstal, Landqart.
-- 3) app.country_markets CH row (priority medium).
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
           v.party_name, 'CH', v.region, v.city, v.website, 'active', 'switzerland_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(schweiz|oftringen|switzerland|suisse)|^omya( ag| group)?$', 'Omya (Schweiz) AG - Oftringen (HQ)', 'Aargau', 'Oftringen', null, 'Omya 그룹 본사(1884, Baslerstrasse 42, Oftringen) — 약 9,000명·50개국+, GCC·PCC·기능성 광물. R&D·응용연구 Oftringen·Egerkingen. Hydrocarb·Syncarb·Omyapaque·Multifill(바이오폴리머·PCC 응집·MFC 복합), On-site·Near-site. 2023 중국·인니 7개 제지공장 연계 100만 t 계획(GCC 74%·PCC 26%).', 'Omya group HQ (founded 1884), Baslerstrasse 42, Oftringen (Aargau) - about 9,000 staff in over 50 countries, GCC, PCC and functional minerals, R&D and application labs at Oftringen and Egerkingen. Paper range Hydrocarb, Syncarb, Omyapaque, Multifill (biopolymers, PCC aggregation control, MFC-mineral composites, FiberLean) and on-site / near-site plants. 2023 plan: seven mill-linked plants in China and Indonesia, 1 Mt/yr (74 pct GCC, 26 pct PCC).', 'CH check 2026-10-16: +41 62 789 29 29. Royalty licensee - approach Pulp and Paper and On-site Solutions heads. Multifill / FiberLean compete with FCC - NDA and background-IP terms before process detail. Swiss commercial output not public.'),
  ('kalkfabrik netstal|\mkfn\M', 'Kalkfabrik Netstal (KFN) - Netstal', 'Glarus', 'Netstal', null, '1900년부터 Glarus 고순도 석회석(CaCO3 98%+) — 생석회 약 9만 t/년, 소석회.', 'Kalkfabrik Netstal AG (KFN, since 1900), Netstal (Glarus) - high-purity limestone (over 98 pct CaCO3), about 90,000 t/yr quicklime plus hydrated lime.', 'CH check 2026-10-16: lime only - PCC raw material. Not added: PERFECO (Villigen filler test lab - possible evaluation partner).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CH check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(schweiz|oftringen|switzerland|suisse)|^omya( ag| group)?$', 'Omya (Schweiz) AG - Oftringen (HQ)', 'Aargau', 'Oftringen', null, 'Omya 그룹 본사(1884, Baslerstrasse 42, Oftringen) — 약 9,000명·50개국+, GCC·PCC·기능성 광물. R&D·응용연구 Oftringen·Egerkingen. Hydrocarb·Syncarb·Omyapaque·Multifill(바이오폴리머·PCC 응집·MFC 복합), On-site·Near-site. 2023 중국·인니 7개 제지공장 연계 100만 t 계획(GCC 74%·PCC 26%).', 'Omya group HQ (founded 1884), Baslerstrasse 42, Oftringen (Aargau) - about 9,000 staff in over 50 countries, GCC, PCC and functional minerals, R&D and application labs at Oftringen and Egerkingen. Paper range Hydrocarb, Syncarb, Omyapaque, Multifill (biopolymers, PCC aggregation control, MFC-mineral composites, FiberLean) and on-site / near-site plants. 2023 plan: seven mill-linked plants in China and Indonesia, 1 Mt/yr (74 pct GCC, 26 pct PCC).', 'CH check 2026-10-16: +41 62 789 29 29. Royalty licensee - approach Pulp and Paper and On-site Solutions heads. Multifill / FiberLean compete with FCC - NDA and background-IP terms before process detail. Swiss commercial output not public.'),
  ('kalkfabrik netstal|\mkfn\M', 'Kalkfabrik Netstal (KFN) - Netstal', 'Glarus', 'Netstal', null, '1900년부터 Glarus 고순도 석회석(CaCO3 98%+) — 생석회 약 9만 t/년, 소석회.', 'Kalkfabrik Netstal AG (KFN, since 1900), Netstal (Glarus) - high-purity limestone (over 98 pct CaCO3), about 90,000 t/yr quicklime plus hydrated lime.', 'CH check 2026-10-16: lime only - PCC raw material. Not added: PERFECO (Villigen filler test lab - possible evaluation partner).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'switzerland_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya (Schweiz) AG - Oftringen (HQ)', 'GCC and PCC supplier', 'Omya HQ - royalty licensee, global route', 'merchant', 'B', 'gcc'),
  ('Kalkfabrik Netstal (KFN) - Netstal', 'Lime producer', 'Quicklime - PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'switzerland_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CH', v.region, v.city, v.website, 'active', 'switzerland_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('perlen', 'perlen', 'perlen', 'Perlen Papier - Perlen', 'Lucerne', 'Perlen', null, 'Perlen Papier — 신문용지·LWC 잡지용지, 2025 구조조정 후 초지기 2대 유지, 식품포장·라벨 특수지·성형섬유 확대. 2026-03 Pulpex 종이병 독점 파트너십(2027 이후).', 'Perlen Papier AG, Perlen (Lucerne) - newsprint and LWC magazine paper on two machines kept after the 2025 restructuring, expanding to food-packaging and label specialty papers and moulded fibre. Exclusive paper-bottle partnership with Pulpex (2026-03, production 2027 at the earliest).', 'CH check 2026-10-16: capacity not public here.'),
  ('swiss quality paper', 'balsthal', 'swiss quality', 'Swiss Quality Paper - Balsthal', 'Solothurn', 'Balsthal', null, '1883년부터 Balsthal 특수지 — 120종+, 20개국+, 자체 R&D 연구소, 초지기 1대 3.08 m·연 2.5만 t(마스킹테이프·식품·위생 특수지).', 'Swiss Quality Paper AG, Tiergartenweg 1, Balsthal - specialty papers since 1883, over 120 grades for over 20 countries, own R&D lab, one 3.08 m machine at 25,000 t/yr (masking-tape base, food, hygiene and cleaning papers).', 'CH check 2026-10-16: order@swissqualitypaper.com, +41 62 386 41 11.'),
  ('cartaseta|\mtela\M', 'gretzenbach|niederbipp', 'cartaseta|tela', 'Tela / Cartaseta - Gretzenbach', 'Solothurn', 'Gretzenbach', null, 'Tela·Cartaseta 스위스 위생용지 — 연 약 1.91만 t·91명, Gretzenbach(Cartaseta)·Niederbipp(Tela).', 'Tela and Cartaseta, Sandackerstrasse 3, Gretzenbach (Cartaseta) and Niederbipp (Tela) - toilet tissue, kitchen towels, sanitary paper, own and private-label brands, about 19,133 t/yr paper and 91 staff.', 'CH check 2026-10-16: machine vs converting split per site to confirm. info@cartaseta.ch.'),
  ('model.*weinfelden|weinfelden', 'weinfelden', 'model', 'Model - Weinfelden', 'Thurgau', 'Weinfelden', null, 'Model Group Weinfelden 재생 테스트라이너·골심지 — 초지기 2대(2.5 m), 연 19만 t, 100% 회수지, 90~220 g/m².', 'Model Group, Weinfelden (Thurgau) - recycled testliner and fluting on two 2.5 m machines, 190,000 t/yr, 100 pct recovered paper, 90-220 g/m2.', 'CH check 2026-10-16: strength-led.'),
  ('model.*nieder|niederg[oö]sgen', 'niederg[oö]sgen', 'model', 'Model - Niedergösgen', 'Solothurn', 'Niedergösgen', null, 'Model Group Niedergösgen 재생 골판지원지 — 초지기 1대(5.15 m), 연 24만 t.', 'Model Group, Niedergösgen - recycled containerboard on one 5.15 m machine, 240,000 t/yr.', 'CH check 2026-10-16: strength-led.'),
  ('papierfabrik netstal|\mpfn\M', 'netstal', 'netstal|konos', 'Papierfabrik Netstal - Netstal', 'Glarus', 'Netstal', null, 'Papierfabrik Netstal(17세기~) — 커피 필터·크레이프 필터·식품·의료·농업 특수지, 고습윤강도 원지. 독일 KONOS 연계.', 'Papierfabrik Netstal AG, Industrie Kleinzaun, Netstal - coffee filter and crepe filter papers, food, medical and agricultural specialty papers, high wet-strength wipe base, linked to KONOS GmbH (Germany).', 'CH check 2026-10-16: filter porosity limits filler use. Mill head Steffen Egetemeyer, info@pfn.ch.'),
  ('landqart', 'landquart', 'landqart', 'Landqart - Landquart', 'Graubünden', 'Landquart', null, 'Landqart 은행권·여권 보안용지 연 1만 t+·240명(Durasafe·Digisafe).', 'Landqart AG, Landquart - banknote, passport and visa security substrates (Durasafe, Digisafe, Irisafe Micro), over 10,000 t/yr, about 240 staff.', 'CH check 2026-10-16: qualification burden too high for a new filler - long-term only.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CH check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('perlen', 'perlen', 'perlen', 'Perlen Papier — 신문용지·LWC 잡지용지, 2025 구조조정 후 초지기 2대 유지, 식품포장·라벨 특수지·성형섬유 확대. 2026-03 Pulpex 종이병 독점 파트너십(2027 이후).', 'Perlen Papier AG, Perlen (Lucerne) - newsprint and LWC magazine paper on two machines kept after the 2025 restructuring, expanding to food-packaging and label specialty papers and moulded fibre. Exclusive paper-bottle partnership with Pulpex (2026-03, production 2027 at the earliest).', 'CH check 2026-10-16: capacity not public here.'),
  ('swiss quality paper', 'balsthal', 'swiss quality', '1883년부터 Balsthal 특수지 — 120종+, 20개국+, 자체 R&D 연구소, 초지기 1대 3.08 m·연 2.5만 t(마스킹테이프·식품·위생 특수지).', 'Swiss Quality Paper AG, Tiergartenweg 1, Balsthal - specialty papers since 1883, over 120 grades for over 20 countries, own R&D lab, one 3.08 m machine at 25,000 t/yr (masking-tape base, food, hygiene and cleaning papers).', 'CH check 2026-10-16: order@swissqualitypaper.com, +41 62 386 41 11.'),
  ('cartaseta|\mtela\M', 'gretzenbach|niederbipp', 'cartaseta|tela', 'Tela·Cartaseta 스위스 위생용지 — 연 약 1.91만 t·91명, Gretzenbach(Cartaseta)·Niederbipp(Tela).', 'Tela and Cartaseta, Sandackerstrasse 3, Gretzenbach (Cartaseta) and Niederbipp (Tela) - toilet tissue, kitchen towels, sanitary paper, own and private-label brands, about 19,133 t/yr paper and 91 staff.', 'CH check 2026-10-16: machine vs converting split per site to confirm. info@cartaseta.ch.'),
  ('model.*weinfelden|weinfelden', 'weinfelden', 'model', 'Model Group Weinfelden 재생 테스트라이너·골심지 — 초지기 2대(2.5 m), 연 19만 t, 100% 회수지, 90~220 g/m².', 'Model Group, Weinfelden (Thurgau) - recycled testliner and fluting on two 2.5 m machines, 190,000 t/yr, 100 pct recovered paper, 90-220 g/m2.', 'CH check 2026-10-16: strength-led.'),
  ('model.*nieder|niederg[oö]sgen', 'niederg[oö]sgen', 'model', 'Model Group Niedergösgen 재생 골판지원지 — 초지기 1대(5.15 m), 연 24만 t.', 'Model Group, Niedergösgen - recycled containerboard on one 5.15 m machine, 240,000 t/yr.', 'CH check 2026-10-16: strength-led.'),
  ('papierfabrik netstal|\mpfn\M', 'netstal', 'netstal|konos', 'Papierfabrik Netstal(17세기~) — 커피 필터·크레이프 필터·식품·의료·농업 특수지, 고습윤강도 원지. 독일 KONOS 연계.', 'Papierfabrik Netstal AG, Industrie Kleinzaun, Netstal - coffee filter and crepe filter papers, food, medical and agricultural specialty papers, high wet-strength wipe base, linked to KONOS GmbH (Germany).', 'CH check 2026-10-16: filter porosity limits filler use. Mill head Steffen Egetemeyer, info@pfn.ch.'),
  ('landqart', 'landquart', 'landqart', 'Landqart 은행권·여권 보안용지 연 1만 t+·240명(Durasafe·Digisafe).', 'Landqart AG, Landquart - banknote, passport and visa security substrates (Durasafe, Digisafe, Irisafe Micro), over 10,000 t/yr, about 240 staff.', 'CH check 2026-10-16: qualification burden too high for a new filler - long-term only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'switzerland_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('perlen', 'perlen', 'perlen'),
  ('swiss quality paper', 'balsthal', 'swiss quality'),
  ('cartaseta|\mtela\M', 'gretzenbach|niederbipp', 'cartaseta|tela'),
  ('model.*weinfelden|weinfelden', 'weinfelden', 'model'),
  ('model.*nieder|niederg[oö]sgen', 'niederg[oö]sgen', 'model'),
  ('papierfabrik netstal|\mpfn\M', 'netstal', 'netstal|konos'),
  ('landqart', 'landquart', 'landqart')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('perlen', 'perlen', 'perlen', false,
   $pj${"owner": "CPH Group", "priority": 1, "products": "Newsprint, LWC, specialty packaging paper", "grades": ["Newsprint", "LWC", "Specialty paper"], "machines": 2, "pitch": "LWC base-paper FCC with Omya HQ next door", "approach": "Lead Swiss account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('swiss quality paper', 'balsthal', 'swiss quality', false,
   $pj${"owner": "Swiss Quality Paper", "priority": 2, "products": "Specialty papers", "grades": ["Specialty paper"], "machines": 1, "capacity": {"value": 25000, "unit": "metric_t", "year": "Company figure", "source": "swissqualitypaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Pilot scale."}, "approach": "European pilot and custom-grade partner.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartaseta|\mtela\M', 'gretzenbach|niederbipp', 'cartaseta|tela', false,
   $pj${"owner": "Tela / Cartaseta", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 19133, "unit": "metric_t", "year": "Company output figure", "source": "tela-cartaseta.ch"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "FCC 5 pct tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('model.*weinfelden|weinfelden', 'weinfelden', 'model', false,
   $pj${"owner": "Model Group", "priority": 4, "products": "Recycled testliner, fluting", "grades": ["Testliner", "Medium"], "machines": 2, "capacity": {"value": 190000, "unit": "metric_t", "year": "Company figure", "source": "model.ch"}, "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('model.*nieder|niederg[oö]sgen', 'niederg[oö]sgen', 'model', false,
   $pj${"owner": "Model Group", "priority": 5, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "machines": 1, "capacity": {"value": 240000, "unit": "metric_t", "year": "Company figure", "source": "model.ch"}, "approach": "After Weinfelden.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papierfabrik netstal|\mpfn\M', 'netstal', 'netstal|konos', false,
   $pj${"owner": "KONOS", "products": "Filter and specialty paper", "grades": ["Specialty paper"], "approach": "Small R&D trial on wet-strength grades only.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('landqart', 'landquart', 'landqart', false,
   $pj${"owner": "Landqart", "products": "Security paper", "grades": ["Security paper"], "approach": "Long-term R&D only.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CH', 'Switzerland', 'medium',
   $cm$Omya group HQ (Oftringen) - Perlen LWC, Swiss Quality Paper specialty, Tela / Cartaseta tissue, Model recycled liner (430 kt)$cm$,
   $cm$Switzerland hosts Omya's global HQ and R&D (Oftringen, Egerkingen) - the main route to Omya's worldwide GCC and PCC network (licensee, but Multifill and FiberLean compete with FCC). Mills: Perlen Papier (newsprint and LWC, two machines, specialty and moulded-fibre push), Swiss Quality Paper (25 kt specialty, own R&D), Tela / Cartaseta tissue (about 19 kt), Model Group recycled liner at Weinfelden (190 kt) and Niedergösgen (240 kt), Papierfabrik Netstal filter papers, Landqart security paper. KFN Netstal makes quicklime (90 kt).$cm$,
   $cm${"fillers": "Omya HQ Oftringen (licensee, global route). Lime: Kalkfabrik Netstal (90 kt quicklime). Test lab: PERFECO (not added).", "mills": "LWC and newsprint: Perlen. Specialty: Swiss Quality Paper, Papierfabrik Netstal, Landqart. Tissue: Tela / Cartaseta. Recycled liner: Model Weinfelden and Niedergösgen.", "strategy": "Omya HQ talks (license, joint benchmark vs Multifill) with NDA first. Perlen LWC trial, Swiss Quality Paper pilot, Tela tissue test.", "risks": "Omya competing tech and IP, small Swiss volumes.", "next_steps": ["Prepare a non-confidential FCC deck for Omya HQ", "Propose a pilot to Swiss Quality Paper"], "key_numbers": [{"label": "Omya group", "value": "about 9,000 staff, 50+ countries"}, {"label": "Model Group CH", "value": "430 kt (190 + 240)"}, {"label": "Report scenario", "value": "about 23,700 t FCC (5 pct of 474 kt)"}], "files": ["seed_20261016zze_switzerland_mills_fillers"]}$cm$::jsonb,
   $cm$Omya 그룹 본사(Oftringen) — Perlen LWC, Swiss Quality Paper 특수지, Tela/Cartaseta 티슈, Model 재생 라이너(43만 t)$cm$,
   $cm$스위스에는 Omya 글로벌 본사·R&D(Oftringen·Egerkingen) — Omya 전 세계 GCC·PCC 망으로 가는 핵심 창구(라이선시, 단 Multifill·FiberLean 경쟁). 제지: Perlen(신문·LWC 2대, 특수지·성형섬유 확대), Swiss Quality Paper(특수지 2.5만 t, 자체 R&D), Tela/Cartaseta 티슈(약 1.9만 t), Model 재생 라이너 Weinfelden(19만)·Niedergösgen(24만 t), Papierfabrik Netstal 필터지, Landqart 보안용지. KFN Netstal 생석회 9만 t.$cm$,
   2207, 23707,
   $cm$하한 Swiss Quality Paper + Tela 4.4만 t × 5%, 상한 Model 포함 47.4만 t × 5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('perlen', 'perlen', 'perlen'),
  ('swiss quality paper', 'balsthal', 'swiss quality'),
  ('cartaseta|\mtela\M', 'gretzenbach|niederbipp', 'cartaseta|tela'),
  ('model.*weinfelden|weinfelden', 'weinfelden', 'model'),
  ('model.*nieder|niederg[oö]sgen', 'niederg[oö]sgen', 'model'),
  ('papierfabrik netstal|\mpfn\M', 'netstal', 'netstal|konos'),
  ('landqart', 'landquart', 'landqart')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'switzerland_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'switzerland_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(schweiz|oftringen|switzerland|suisse)|^omya( ag| group)?$' or p.party_name ~* 'kalkfabrik netstal|\mkfn\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CH'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CH'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CH'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    