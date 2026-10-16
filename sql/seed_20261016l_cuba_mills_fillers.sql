-- ============================================================
-- seed_20261016l_cuba_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Cuba update (reports 2026-10-15). Data only - market priority on_hold
-- because of the US embargo, every memo carries a sanctions note.
-- 1) Fillers if missing (3): EMO Roberto Coco Peredo, Geominera del Centro,
--    Geominera de Pinar del Río.
-- 2) Mills if missing (4) + plant blocks: PROSA Cárdenas (1), Damují
--    Abreus (2), Pulpa Cuba and Papeles Finos (no priority, idle or plan).
--    Context (4): Cartones y Cartulinas, Tejas Infinitas, Jatimol,
--    Compacto Caribe.
-- 3) app.country_markets CU row (priority on_hold).
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
           v.party_name, 'CU', v.region, v.city, v.website, 'active', 'cuba_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('minera de occidente|roberto coco peredo', 'Empresa Minera de Occidente - Roberto Coco Peredo', 'Mayabeque', 'San José de las Lajas', null, '쿠바 국영 Empresa Minera de Occidente(EMO) 의 탄산칼슘 미분쇄 공장 UEB Roberto Coco Peredo. 미세품 3만 t + 조립 6만 t 설비(2022), CARCAL(98%+, 2~5 μm). Colina·Carbonato Beluca 광구 허가에 제지 용도 명시.', 'Empresa Minera de Occidente (EMO, state-owned, GEOMINSAL) - UEB Roberto Coco Peredo carbonate plant, Carretera Jaruco - Tapaste Km 11.5, San José de las Lajas (Mayabeque): installed about 30,000 t/yr fine and 60,000 t/yr coarse grades (2022), CARCAL ground carbonate over 98 pct CaCO3, 2-5 micron, up to 11,200 t/yr. Mining permits for the Colina and Carbonato Beluca (Jaruco, 2016, 25 years) deposits list paper as a use.', 'CU check 2026-10-15: actual paper supply not confirmed. 2022 deal for about 400 t/month to Winperas (Cuba-Spain JV). +53 47 891447. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('geominera del centro', 'Empresa Geominera del Centro', 'Villa Clara', 'Remedios', null, 'Villa Clara 국영 광업기업 — Tanque de Viñas(Remedios) 탄산칼슘 광구(2048까지 연장), 사료·건설용.', 'Empresa Geominera del Centro, Villa Clara - natural calcium carbonate at the Tanque de Viñas deposit, Remedios (permit extended to 2048-10-26), for feed and construction.', 'CU check 2026-10-15: paper grade not confirmed - raw material. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('geominera de pinar', 'Empresa Geominera de Pinar del Río', 'Pinar del Río', 'Pinar del Río', null, 'Pinar del Río La Lata II-Pons 석회석 채굴·탄산칼슘 허가(2025).', 'Empresa Geominera de Pinar del Río - limestone mining and calcium carbonate at La Lata II-Pons (permit 2025-04) for metals, agriculture, food, public works, paint.', 'CU check 2026-10-15: paper grade not confirmed - raw material. No paper PCC plant and no Omya, MTI or Imerys plant in Cuba. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CU check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('minera de occidente|roberto coco peredo', 'Empresa Minera de Occidente - Roberto Coco Peredo', 'Mayabeque', 'San José de las Lajas', null, '쿠바 국영 Empresa Minera de Occidente(EMO) 의 탄산칼슘 미분쇄 공장 UEB Roberto Coco Peredo. 미세품 3만 t + 조립 6만 t 설비(2022), CARCAL(98%+, 2~5 μm). Colina·Carbonato Beluca 광구 허가에 제지 용도 명시.', 'Empresa Minera de Occidente (EMO, state-owned, GEOMINSAL) - UEB Roberto Coco Peredo carbonate plant, Carretera Jaruco - Tapaste Km 11.5, San José de las Lajas (Mayabeque): installed about 30,000 t/yr fine and 60,000 t/yr coarse grades (2022), CARCAL ground carbonate over 98 pct CaCO3, 2-5 micron, up to 11,200 t/yr. Mining permits for the Colina and Carbonato Beluca (Jaruco, 2016, 25 years) deposits list paper as a use.', 'CU check 2026-10-15: actual paper supply not confirmed. 2022 deal for about 400 t/month to Winperas (Cuba-Spain JV). +53 47 891447. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('geominera del centro', 'Empresa Geominera del Centro', 'Villa Clara', 'Remedios', null, 'Villa Clara 국영 광업기업 — Tanque de Viñas(Remedios) 탄산칼슘 광구(2048까지 연장), 사료·건설용.', 'Empresa Geominera del Centro, Villa Clara - natural calcium carbonate at the Tanque de Viñas deposit, Remedios (permit extended to 2048-10-26), for feed and construction.', 'CU check 2026-10-15: paper grade not confirmed - raw material. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('geominera de pinar', 'Empresa Geominera de Pinar del Río', 'Pinar del Río', 'Pinar del Río', null, 'Pinar del Río La Lata II-Pons 석회석 채굴·탄산칼슘 허가(2025).', 'Empresa Geominera de Pinar del Río - limestone mining and calcium carbonate at La Lata II-Pons (permit 2025-04) for metals, agriculture, food, public works, paint.', 'CU check 2026-10-15: paper grade not confirmed - raw material. No paper PCC plant and no Omya, MTI or Imerys plant in Cuba. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'cuba_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Empresa Minera de Occidente - Roberto Coco Peredo', 'GCC producer', 'State GCC plant, paper use in permits', 'merchant', 'C', 'gcc'),
  ('Empresa Geominera del Centro', 'Carbonate raw material', 'State limestone - raw material', 'merchant', 'C', 'gcc'),
  ('Empresa Geominera de Pinar del Río', 'Carbonate raw material', 'New limestone permit - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'cuba_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CU', v.region, v.city, v.website, 'active', 'cuba_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('\mprosa\M|productos sanitarios', 'c[aá]rdenas', 'prosa|productos sanitarios', 'PROSA (Productos Sanitarios) - Cárdenas', 'Matanzas', 'Cárdenas', null, 'Cárdenas(Matanzas) 합작 위생지 기업 PROSA — 화장지·냅킨·종이타월·점보롤, 호텔·관광 시장. 2015 화장지 4,500만 롤 → 2022 1,600만 롤, 2023-05 생산 재개.', 'Productos Sanitarios S.A. (PROSA, joint venture), Carretera Cárdenas - Sagua Km 7.5, Cárdenas (Matanzas) - toilet tissue, napkins, towels and mini-jumbo rolls for home and tourism. About 45 m rolls in 2015, 16 m in 2022 (fibre shortage), restarted 2023-05.', 'CU check 2026-10-15: tonnage and furnish not public. +53 45 613011. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('damuj', 'abreus', 'damuj|sergio gonz', 'Papelera Damují - Abreus', 'Cienfuegos', 'Abreus', null, '국영 Papelera Damují(Sergio González López, Abreus) — 재생원료 판지·포장지. 2020 중단, 2023-12 재가동, 2025 일 15~17 t, 2026 160 g/m² 판지를 Compacto Caribe 에 공급.', 'Papelera Damují - Sergio González López (state paper industry), Abreus (Cienfuegos) - board, packaging and kraft-type paper on recovered paper since the 1960s. Stopped 2020, restarted 2023-12, 15-17 t/day in 2025-10, 160 g/m2 board supplied to Compacto Caribe in 2026.', 'CU check 2026-10-15: 4,800 t/yr is 16 t/day x 300 days (calculated). Mill manager in reports: Ibrahim Bastida Díaz. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('pulpa cuba', 'trinidad', 'pulpa cuba|cubapel', 'Papelera Pulpa Cuba - Trinidad', 'Sancti Spíritus', 'Trinidad', null, '국영 Pulpa Cuba(Trinidad) — 테스트라이너·포장지·판지, 과거 연 약 2.4만 t, 2020 중단 언급.', 'Papelera Pulpa Cuba (Cubapel / Empresa del Papel), Carretera Sancti Spíritus - Trinidad Km 15.5 - testliner, packaging paper, board and envelope paper, historical capacity about 24,000 t/yr, reported stopped in 2020.', 'CU check 2026-10-15: current operation not confirmed - historical 24 kt kept in notes only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('papeles finos', 'jatibonico', 'papeles finos', 'Papeles Finos y Conversión - Jatibonico', 'Sancti Spíritus', 'Jatibonico', null, 'Jatibonico 인쇄·필기용지 공장. 외국인 투자 제안: 개조 후 연 6만 t(인쇄·필기 4만 + 신문 2만, 8,130만 달러).', 'Papeles Finos y Conversión S.A., Jatibonico (Sancti Spíritus) - printing and writing paper mill, with a foreign-investment proposal that planned 60,000 t/yr after rebuild (40,000 t printing and writing, 20,000 t newsprint, about USD 81.3 m).', 'CU check 2026-10-15: plan only - current output unknown. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CU check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mprosa\M|productos sanitarios', 'c[aá]rdenas', 'prosa|productos sanitarios', 'Cárdenas(Matanzas) 합작 위생지 기업 PROSA — 화장지·냅킨·종이타월·점보롤, 호텔·관광 시장. 2015 화장지 4,500만 롤 → 2022 1,600만 롤, 2023-05 생산 재개.', 'Productos Sanitarios S.A. (PROSA, joint venture), Carretera Cárdenas - Sagua Km 7.5, Cárdenas (Matanzas) - toilet tissue, napkins, towels and mini-jumbo rolls for home and tourism. About 45 m rolls in 2015, 16 m in 2022 (fibre shortage), restarted 2023-05.', 'CU check 2026-10-15: tonnage and furnish not public. +53 45 613011. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('damuj', 'abreus', 'damuj|sergio gonz', '국영 Papelera Damují(Sergio González López, Abreus) — 재생원료 판지·포장지. 2020 중단, 2023-12 재가동, 2025 일 15~17 t, 2026 160 g/m² 판지를 Compacto Caribe 에 공급.', 'Papelera Damují - Sergio González López (state paper industry), Abreus (Cienfuegos) - board, packaging and kraft-type paper on recovered paper since the 1960s. Stopped 2020, restarted 2023-12, 15-17 t/day in 2025-10, 160 g/m2 board supplied to Compacto Caribe in 2026.', 'CU check 2026-10-15: 4,800 t/yr is 16 t/day x 300 days (calculated). Mill manager in reports: Ibrahim Bastida Díaz. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('pulpa cuba', 'trinidad', 'pulpa cuba|cubapel', '국영 Pulpa Cuba(Trinidad) — 테스트라이너·포장지·판지, 과거 연 약 2.4만 t, 2020 중단 언급.', 'Papelera Pulpa Cuba (Cubapel / Empresa del Papel), Carretera Sancti Spíritus - Trinidad Km 15.5 - testliner, packaging paper, board and envelope paper, historical capacity about 24,000 t/yr, reported stopped in 2020.', 'CU check 2026-10-15: current operation not confirmed - historical 24 kt kept in notes only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('papeles finos', 'jatibonico', 'papeles finos', 'Jatibonico 인쇄·필기용지 공장. 외국인 투자 제안: 개조 후 연 6만 t(인쇄·필기 4만 + 신문 2만, 8,130만 달러).', 'Papeles Finos y Conversión S.A., Jatibonico (Sancti Spíritus) - printing and writing paper mill, with a foreign-investment proposal that planned 60,000 t/yr after rebuild (40,000 t printing and writing, 20,000 t newsprint, about USD 81.3 m).', 'CU check 2026-10-15: plan only - current output unknown. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('cartones y cartulinas', null, 'cartones y cartulinas', null, null, 'CU check 2026-10-15: Board and corrugating paper, Santa Cruz del Norte - status unknown (20 kt tissue project proposed nearby) - context only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('tejas infinitas', null, 'tejas infinitas', null, null, 'CU check 2026-10-15: Grey board and chipboard, Camagüey - status unknown - context only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('jatimol', null, 'jatimol', null, null, 'CU check 2026-10-15: Recycled paper converting, Sancti Spíritus - context only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.'),
  ('compacto caribe', null, 'compacto caribe', null, null, 'CU check 2026-10-15: Corrugated boxes, La Habana - buys Damují board - context only. US embargo (OFAC Cuban Assets Control Regulations) - no dealings until a sanctions review clears it.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'cuba_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mprosa\M|productos sanitarios', 'c[aá]rdenas', 'prosa|productos sanitarios'),
  ('damuj', 'abreus', 'damuj|sergio gonz'),
  ('pulpa cuba', 'trinidad', 'pulpa cuba|cubapel'),
  ('papeles finos', 'jatibonico', 'papeles finos'),
  ('cartones y cartulinas', null, 'cartones y cartulinas'),
  ('tejas infinitas', null, 'tejas infinitas'),
  ('jatimol', null, 'jatimol'),
  ('compacto caribe', null, 'compacto caribe')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mprosa\M|productos sanitarios', 'c[aá]rdenas', 'prosa|productos sanitarios',
   $pj${"owner": "PROSA (joint venture)", "priority": 1, "products": "Toilet tissue, napkins, towels", "grades": ["Tissue"], "approach": "On hold - sanctions review first. Technically the most direct tissue trial site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('damuj', 'abreus', 'damuj|sergio gonz',
   $pj${"owner": "State paper industry", "priority": 2, "products": "Recycled board, packaging paper", "grades": ["Board", "Kraft paper"], "capacity": {"value": 4800, "unit": "metric_t", "year": "16 t/day x 300 (calculated, 2025)", "source": "press 2025"}, "approach": "On hold - sanctions review first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('pulpa cuba', 'trinidad', 'pulpa cuba|cubapel',
   $pj${"owner": "State paper industry", "products": "Testliner, packaging paper, board", "grades": ["Testliner"], "approach": "Check restart.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeles finos', 'jatibonico', 'papeles finos',
   $pj${"owner": "State paper industry", "products": "Printing and writing paper (plan)", "grades": ["Printing and writing"], "approach": "Check operation and the investment plan.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones y cartulinas', null, 'cartones y cartulinas',
   $pj${"owner": "Cartones y Cartulinas S.A.", "products": "Board and corrugating paper, Santa Cruz del Norte - status unknown (20 kt tissue project proposed nearby)", "approach": "On hold - sanctions.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('tejas infinitas', null, 'tejas infinitas',
   $pj${"owner": "Papelera Tejas Infinitas", "products": "Grey board and chipboard, Camagüey - status unknown", "approach": "On hold - sanctions.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('jatimol', null, 'jatimol',
   $pj${"owner": "Jatimol", "products": "Recycled paper converting, Sancti Spíritus", "approach": "On hold - sanctions.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('compacto caribe', null, 'compacto caribe',
   $pj${"owner": "Compacto Caribe", "products": "Corrugated boxes, La Habana - buys Damují board", "approach": "On hold - sanctions.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CU', 'Cuba', 'on_hold',
   $cm$On hold (US embargo) - state GCC plant at Roberto Coco Peredo, small tissue (PROSA) and recycled board (Damují)$cm$,
   $cm$Cuba has a state GCC plant (EMO Roberto Coco Peredo, Mayabeque, CARCAL 2-5 micron, paper listed in its mining permits) but no paper PCC. Running mills are small: PROSA tissue at Cárdenas (16 m rolls in 2022, restarted 2023) and Damují recycled board (15-17 t/day, 2025). Pulpa Cuba (24 kt historical) and Papeles Finos (60 kt plan) are idle or planned. Any dealing is blocked by the US embargo until a sanctions review clears it.$cm$,
   $cm${"fillers": "GCC: Empresa Minera de Occidente - Roberto Coco Peredo (30 kt fine + 60 kt coarse installed, CARCAL 98 pct, 2-5 micron), Carbonato Beluca deposit (Jaruco). Raw material: Geominera del Centro (Villa Clara), Geominera de Pinar del Río. No PCC.", "mills": "Tissue: PROSA Cárdenas. Recycled board: Damují Abreus. Idle or planned: Pulpa Cuba Trinidad, Papeles Finos Jatibonico. Context: Cartones y Cartulinas, Tejas Infinitas, Jatimol, Compacto Caribe.", "strategy": "On hold. If a sanctions review ever allows it: PROSA tissue and Damují board trials with EMO GCC.", "risks": "US embargo (OFAC CACR) - keep out of campaigns. Fibre, energy and spare-parts shortages.", "next_steps": ["Add CU to the sanctioned-country exclusion list (pending item 3)"], "key_numbers": [{"label": "Roberto Coco Peredo", "value": "30 kt fine + 60 kt coarse installed (2022)"}, {"label": "Damují", "value": "15-17 t/day (2025)"}, {"label": "PROSA", "value": "16 m toilet rolls (2022)"}], "files": ["seed_20261016l_cuba_mills_fillers"]}$cm$::jsonb,
   $cm$보류(미국 금수) — 국영 GCC 공장(Roberto Coco Peredo), 소형 티슈(PROSA)·재생 판지(Damují)$cm$,
   $cm$쿠바에는 국영 GCC 공장(EMO Roberto Coco Peredo, CARCAL 2~5 μm, 광업 허가에 제지 용도 명시)이 있으나 제지용 PCC 없음. 가동 확인 공장은 소규모 — PROSA 티슈(Cárdenas)와 Damují 재생 판지(일 15~17 t). Pulpa Cuba·Papeles Finos 는 중단 또는 계획 단계. 미국 금수(OFAC CACR)로 제재 검토 전 거래 불가 — 캠페인 제외 대상.$cm$,
   null, null,
   $cm$보류 — 제재로 산정하지 않음$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('\mprosa\M|productos sanitarios', 'c[aá]rdenas', 'prosa|productos sanitarios'),
  ('damuj', 'abreus', 'damuj|sergio gonz'),
  ('pulpa cuba', 'trinidad', 'pulpa cuba|cubapel'),
  ('papeles finos', 'jatibonico', 'papeles finos'),
  ('cartones y cartulinas', null, 'cartones y cartulinas'),
  ('tejas infinitas', null, 'tejas infinitas'),
  ('jatimol', null, 'jatimol'),
  ('compacto caribe', null, 'compacto caribe')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'cuba_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'cuba_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'minera de occidente|roberto coco peredo' or p.party_name ~* 'geominera del centro' or p.party_name ~* 'geominera de pinar')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CU'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CU'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CU'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    