-- ============================================================
-- seed_20261016zzzi_tanzania_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Tanzania update (reports 2026-10-17). Dar es Salaam has Tanpack and Kibo
-- Paper - owner regex keeps them apart. Four Tanga fillers have distinct
-- guards.
-- 1) Fillers if missing (4): Neelkanth Chemicals, Neelkanth Lime, ABM,
--    Alpha Lime.
-- 2) Mills if missing (4) + plant blocks, priority 1-3: Tanpack, Mufindi,
--    Fortune Paper. Kibo Paper no priority. Context (6).
-- 3) app.country_markets TZ row (priority low).
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
           v.party_name, 'TZ', v.region, v.city, v.website, 'active', 'tanzania_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('neelkanth chemicals', 'Neelkanth Chemicals - Tanga', 'Tanga', 'Tanga', null, 'Neelkanth Group Africa(2007~ Tanga) 계열 — 방해석·백운석 GCC·코팅 CaCO3(FG-Coated, NCC-16 2026 우간다 수출), Tanga 탄산칼슘 시설 USD 800만 투자. 플라스틱·도료·필러·건자재.', 'Neelkanth Chemicals Ltd (Neelkanth Group Africa, Tanga since 2007) - calcite and dolomite GCC and coated calcium carbonate (FG-Coated, NCC-16 exported to Uganda 2026-05/06), USD 8 m invested in the Tanga carbonate plant, for plastics, paint, fillers and building.', 'TZ check 2026-10-16: paper grade, D50, brightness and wet line to confirm. Plot 3, Block C, Kiomoni Ambani, Tanga, info@neelkanth-africa.com, +255 676 854 495. FCC co-production candidate 1.'),
  ('neelkanth lime', 'Neelkanth Lime - Tanga', 'Tanga', 'Tanga', null, 'Neelkanth Lime(2007) 생석회·소석회 — 금광·유리·설탕·철강·농업·수처리, STAMICO 소규모 광산 협력(2025).', 'Neelkanth Lime Ltd (2007), Tanga - quicklime and hydrated lime for gold mining, glass, sugar, steel, farming, water and building, small-miner supply link with STAMICO (2025).', 'TZ check 2026-10-16: PCC raw-material and process route only.'),
  ('abm equipment', 'ABM Equipment Services - Tanga', 'Tanga', 'Tanga', null, 'ABM(2012, Tanga 자체 채석) 석회석 분말 200~400 mesh·백운석·농업용 석회·석고, CaCO3 99%+(회사 표시).', 'ABM Equipment Services Ltd (2012), Tanga - own quarry, limestone powder 200-400 mesh, dolomite, agricultural lime, gypsum, over 99 pct CaCO3 claimed.', 'TZ check 2026-10-16: agricultural grades. +255 795 303 030.'),
  ('alpha lime', 'Alpha Lime - Tanga', 'Tanga', 'Tanga', null, 'Alpha Lime(Kiomoni Amboni, Tanga) 금광 침출용 석회.', 'Alpha Lime, Kiomoni Amboni, Tanga - lime for gold leaching.', 'TZ check 2026-10-16: not paper. Not added: Abouraya (trade records only), Innova (Indian PCC importer). UNIDO once planned 3 kt/yr PCC (Tanga, Dar es Salaam, Arusha) - not built as far as known. No Tanzanian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('neelkanth chemicals', 'Neelkanth Chemicals - Tanga', 'Tanga', 'Tanga', null, 'Neelkanth Group Africa(2007~ Tanga) 계열 — 방해석·백운석 GCC·코팅 CaCO3(FG-Coated, NCC-16 2026 우간다 수출), Tanga 탄산칼슘 시설 USD 800만 투자. 플라스틱·도료·필러·건자재.', 'Neelkanth Chemicals Ltd (Neelkanth Group Africa, Tanga since 2007) - calcite and dolomite GCC and coated calcium carbonate (FG-Coated, NCC-16 exported to Uganda 2026-05/06), USD 8 m invested in the Tanga carbonate plant, for plastics, paint, fillers and building.', 'TZ check 2026-10-16: paper grade, D50, brightness and wet line to confirm. Plot 3, Block C, Kiomoni Ambani, Tanga, info@neelkanth-africa.com, +255 676 854 495. FCC co-production candidate 1.'),
  ('neelkanth lime', 'Neelkanth Lime - Tanga', 'Tanga', 'Tanga', null, 'Neelkanth Lime(2007) 생석회·소석회 — 금광·유리·설탕·철강·농업·수처리, STAMICO 소규모 광산 협력(2025).', 'Neelkanth Lime Ltd (2007), Tanga - quicklime and hydrated lime for gold mining, glass, sugar, steel, farming, water and building, small-miner supply link with STAMICO (2025).', 'TZ check 2026-10-16: PCC raw-material and process route only.'),
  ('abm equipment', 'ABM Equipment Services - Tanga', 'Tanga', 'Tanga', null, 'ABM(2012, Tanga 자체 채석) 석회석 분말 200~400 mesh·백운석·농업용 석회·석고, CaCO3 99%+(회사 표시).', 'ABM Equipment Services Ltd (2012), Tanga - own quarry, limestone powder 200-400 mesh, dolomite, agricultural lime, gypsum, over 99 pct CaCO3 claimed.', 'TZ check 2026-10-16: agricultural grades. +255 795 303 030.'),
  ('alpha lime', 'Alpha Lime - Tanga', 'Tanga', 'Tanga', null, 'Alpha Lime(Kiomoni Amboni, Tanga) 금광 침출용 석회.', 'Alpha Lime, Kiomoni Amboni, Tanga - lime for gold leaching.', 'TZ check 2026-10-16: not paper. Not added: Abouraya (trade records only), Innova (Indian PCC importer). UNIDO once planned 3 kt/yr PCC (Tanga, Dar es Salaam, Arusha) - not built as far as known. No Tanzanian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'tanzania_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Neelkanth Chemicals - Tanga', 'GCC producer', 'Calcite GCC with exports - candidate 1', 'merchant', 'B', 'gcc'),
  ('Neelkanth Lime - Tanga', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc'),
  ('ABM Equipment Services - Tanga', 'GCC producer', 'High-purity limestone - raw material', 'merchant', 'C', 'gcc'),
  ('Alpha Lime - Tanga', 'Lime producer', 'Lime - raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'tanzania_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'TZ', v.region, v.city, v.website, 'active', 'tanzania_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('tanpack', 'dar es salaam|mikocheni', 'tanpack|chandaria', 'Tanpack Tissues - Dar es Salaam', 'Dar es Salaam', 'Dar es Salaam', null, 'Chandaria 그룹 Tanpack(1995, Mikocheni B) — 티슈 초지기·MG 초지기(60~125 gsm, 100% 재생), 폐지 수거·재활용, 약 180명. 케냐 Chandaria 계열.', 'Tanpack Tissues Ltd (1995, Chandaria Group), 82 Mikocheni B, Dar es Salaam - own tissue machine and MG paper machine (60-125 gsm, 100 pct recycled), waste-paper collection and repulping, about 180 staff. Sister of Chandaria Industries (KE).', 'TZ check 2026-10-16: output not public. CEO Rajesh Shah (recheck). info@tanpack.co.tz, +255 22 2773901.'),
  ('mufindi', 'mgololo|mufindi', 'mufindi|rai', 'Mufindi Paper Mills - Mgololo', 'Iringa', 'Mgololo', null, 'Mufindi(1986 가동, 2004 민영화 Rai Group) 일관 펄프·제지 — Sao Hill 침엽수, 색크라프트·크라프트라이너, 과거 14만 t(2012)·500명+. 2026-07 TBS 색크라프트 인증(2027-07 까지).', 'Mufindi Paper Mills, Mgololo (Iringa) - integrated pine pulp (Sao Hill forest) and paper, running since 1986, privatised to Rai Group 2004, natural and extensible sack kraft and kraftliner, about 140,000 t/yr and over 500 staff in 2012 data, TBS sack-kraft certificate valid to 2027-07. Same Rai Group as Rai Paper Webuye (KE).', 'TZ check 2026-10-16: strength-critical kraft. Dar office +255 685 212 760.'),
  ('fortune paper', 'kibaha|misugusugu', 'fortune', 'Fortune Paper Group - Kibaha', 'Pwani', 'Kibaha', null, 'Fortune Paper(Misugusugu, Kibaha) 폐지 재활용 Fluting·Testliner — 월 4,000 t(연 약 4.8만 t)·폐지 150 t/일+, 투자 USD 6,000만(2026 보도).', 'Fortune Paper Group Ltd, Misugusugu, Kibaha (Pwani) - recycled fluting and testliner, 4,000 t/month capacity (about 48,000 t/yr), over 150 t/day waste paper, USD 60 m plant (2026 press).', 'TZ check 2026-10-16: strength-led.'),
  ('kibo paper', 'dar es salaam', 'kibo paper', 'Kibo Paper Industries - Dar es Salaam', 'Dar es Salaam', 'Dar es Salaam', null, 'Kibo Paper 테스트라이너·골심지 — 과거 연 1만 t(UNIDO, Mufindi 펄프 사용).', 'Kibo Paper Industries, Dar es Salaam - testliner and corrugating medium, about 10,000 t/yr in older UNIDO data using Mufindi unbleached pulp.', 'TZ check 2026-10-16: running status to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tanpack', 'dar es salaam|mikocheni', 'tanpack|chandaria', 'Chandaria 그룹 Tanpack(1995, Mikocheni B) — 티슈 초지기·MG 초지기(60~125 gsm, 100% 재생), 폐지 수거·재활용, 약 180명. 케냐 Chandaria 계열.', 'Tanpack Tissues Ltd (1995, Chandaria Group), 82 Mikocheni B, Dar es Salaam - own tissue machine and MG paper machine (60-125 gsm, 100 pct recycled), waste-paper collection and repulping, about 180 staff. Sister of Chandaria Industries (KE).', 'TZ check 2026-10-16: output not public. CEO Rajesh Shah (recheck). info@tanpack.co.tz, +255 22 2773901.'),
  ('mufindi', 'mgololo|mufindi', 'mufindi|rai', 'Mufindi(1986 가동, 2004 민영화 Rai Group) 일관 펄프·제지 — Sao Hill 침엽수, 색크라프트·크라프트라이너, 과거 14만 t(2012)·500명+. 2026-07 TBS 색크라프트 인증(2027-07 까지).', 'Mufindi Paper Mills, Mgololo (Iringa) - integrated pine pulp (Sao Hill forest) and paper, running since 1986, privatised to Rai Group 2004, natural and extensible sack kraft and kraftliner, about 140,000 t/yr and over 500 staff in 2012 data, TBS sack-kraft certificate valid to 2027-07. Same Rai Group as Rai Paper Webuye (KE).', 'TZ check 2026-10-16: strength-critical kraft. Dar office +255 685 212 760.'),
  ('fortune paper', 'kibaha|misugusugu', 'fortune', 'Fortune Paper(Misugusugu, Kibaha) 폐지 재활용 Fluting·Testliner — 월 4,000 t(연 약 4.8만 t)·폐지 150 t/일+, 투자 USD 6,000만(2026 보도).', 'Fortune Paper Group Ltd, Misugusugu, Kibaha (Pwani) - recycled fluting and testliner, 4,000 t/month capacity (about 48,000 t/yr), over 150 t/day waste paper, USD 60 m plant (2026 press).', 'TZ check 2026-10-16: strength-led.'),
  ('kibo paper', 'dar es salaam', 'kibo paper', 'Kibo Paper 테스트라이너·골심지 — 과거 연 1만 t(UNIDO, Mufindi 펄프 사용).', 'Kibo Paper Industries, Dar es Salaam - testliner and corrugating medium, about 10,000 t/yr in older UNIDO data using Mufindi unbleached pulp.', 'TZ check 2026-10-16: running status to confirm.'),
  ('kibo match', null, 'kibo match', null, null, 'TZ check 2026-10-16: Kibo Match, Moshi - matches and board (older 9 kt) - status to confirm - context only.'),
  ('twiga paper', null, 'twiga paper', null, null, 'TZ check 2026-10-16: Corrugated boxes, Chuma Rd Dar es Salaam - context only.'),
  ('\m369 industries', null, '\m369 industries', null, null, 'TZ check 2026-10-16: MAX napkins and paper bags, Kunduchi - context only.'),
  ('tanzania printing services', null, 'tanzania printing services', null, null, 'TZ check 2026-10-16: Printing, stationery, packaging - context only.'),
  ('maxons', null, 'maxons', null, null, 'TZ check 2026-10-16: Envelopes, thermal rolls - context only.'),
  ('pee pee', null, 'pee pee', null, null, 'TZ check 2026-10-16: PP woven sacks - not paper - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'tanzania_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tanpack', 'dar es salaam|mikocheni', 'tanpack|chandaria'),
  ('mufindi', 'mgololo|mufindi', 'mufindi|rai'),
  ('fortune paper', 'kibaha|misugusugu', 'fortune'),
  ('kibo paper', 'dar es salaam', 'kibo paper'),
  ('kibo match', null, 'kibo match'),
  ('twiga paper', null, 'twiga paper'),
  ('\m369 industries', null, '\m369 industries'),
  ('tanzania printing services', null, 'tanzania printing services'),
  ('maxons', null, 'maxons'),
  ('pee pee', null, 'pee pee')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('tanpack', 'dar es salaam|mikocheni', 'tanpack|chandaria', false,
   $pj${"owner": "Chandaria Group", "priority": 1, "products": "Tissue, MG paper", "grades": ["Tissue", "MG paper"], "pitch": "Neelkanth GCC + MBG FCC tissue trial", "approach": "Lead Tanzanian account - Chandaria group trial with Nairobi.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mufindi', 'mgololo|mufindi', 'mufindi|rai', false,
   $pj${"owner": "Rai Group", "priority": 2, "products": "Sack kraft, kraftliner, pulp", "grades": ["Sack kraft", "Kraftliner"], "capacity": {"value": 140000, "unit": "metric_t", "year": "2012 figure (historical)", "source": "lse.ac.uk"}, "approach": "Strength-hold kraft trial - Rai group link with Webuye.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fortune paper', 'kibaha|misugusugu', 'fortune', false,
   $pj${"owner": "Fortune Paper", "priority": 3, "products": "Recycled fluting, testliner", "grades": ["Medium", "Testliner"], "capacity": {"value": 48000, "unit": "metric_t", "year": "2026 press (4,000 t/month)", "source": "mediawireexpress"}, "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kibo paper', 'dar es salaam', 'kibo paper', false,
   $pj${"owner": "Kibo Paper", "products": "Testliner, medium", "grades": ["Testliner", "Medium"], "approach": "Status first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kibo match', null, 'kibo match', true,
   $pj${"owner": "Kibo Match", "products": "Kibo Match, Moshi - matches and board (older 9 kt) - status to confirm", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('twiga paper', null, 'twiga paper', true,
   $pj${"owner": "Twiga Paper Products", "products": "Corrugated boxes, Chuma Rd Dar es Salaam", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\m369 industries', null, '\m369 industries', true,
   $pj${"owner": "369 Industries", "products": "MAX napkins and paper bags, Kunduchi", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tanzania printing services', null, 'tanzania printing services', true,
   $pj${"owner": "Tanzania Printing Services", "products": "Printing, stationery, packaging", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('maxons', null, 'maxons', true,
   $pj${"owner": "Maxons Paper Converters", "products": "Envelopes, thermal rolls", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pee pee', null, 'pee pee', true,
   $pj${"owner": "Pee Pee Tanzania", "products": "PP woven sacks - not paper", "approach": "Converter or not paper.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TZ', 'Tanzania', 'low',
   $cm$Tanpack tissue and MG (Chandaria), Mufindi kraft (Rai, about 140 kt historic), Fortune recycled liner (48 kt) - Neelkanth GCC at Tanga$cm$,
   $cm$Tanzania has real machines: Tanpack Tissues Dar es Salaam (Chandaria Group, tissue and MG paper on recycled fibre), Mufindi Paper Mills Mgololo (Rai Group, integrated pine pulp, sack kraft and kraftliner, about 140 kt in 2012 data, TBS certificate 2026), Fortune Paper Kibaha (recycled fluting and testliner, about 48 kt), plus Kibo Paper (older 10 kt). Converters: Twiga, 369 Industries, Maxons and others. Carbonate: Neelkanth Chemicals Tanga (calcite GCC and coated grades, exports to Uganda, USD 8 m plant), Neelkanth Lime, ABM, Alpha Lime. No paper PCC. Group links: Chandaria (KE) and Rai (Webuye KE).$cm$,
   $cm${"fillers": "GCC: Neelkanth Chemicals, ABM. Lime: Neelkanth Lime, Alpha Lime. No PCC.", "mills": "Tissue and MG: Tanpack. Kraft: Mufindi. Recycled liner: Fortune Paper, Kibo Paper. Context: Kibo Match, Twiga, 369 Industries, Tanzania Printing Services, Maxons, Pee Pee (not paper).", "strategy": "Neelkanth GCC + MBG FCC tissue trial at Tanpack (Chandaria group with Nairobi), then kraft strength tests at Mufindi (Rai group with Webuye).", "risks": "Strength-led kraft and liner, paper-grade GCC unverified.", "next_steps": ["Request Neelkanth Chemicals PSD and brightness", "Propose a Tanpack tissue trial"], "key_numbers": [{"label": "Mufindi (2012)", "value": "about 140 kt"}, {"label": "Fortune Paper", "value": "about 48 kt"}], "files": ["seed_20261016zzzi_tanzania_mills_fillers"]}$cm$::jsonb,
   $cm$Tanpack 티슈·MG(Chandaria), Mufindi 크라프트(Rai, 과거 약 14만 t), Fortune 재생 라이너(4.8만 t) — Tanga Neelkanth GCC$cm$,
   $cm$탄자니아 실제 초지기: Tanpack Dar es Salaam(Chandaria 그룹, 재생 티슈·MG지), Mufindi Mgololo(Rai 그룹, 소나무 펄프 일관, 색크라프트·크라프트라이너, 2012 약 14만 t, 2026 TBS 인증), Fortune Kibaha(재생 골심지·라이너 약 4.8만 t), Kibo Paper(과거 1만 t). 가공: Twiga, 369 Industries, Maxons 등. 탄산칼슘: Neelkanth Chemicals Tanga(방해석 GCC·코팅, 우간다 수출, USD 800만 설비), Neelkanth Lime, ABM, Alpha Lime. 제지용 PCC 없음. 그룹 연계: Chandaria(KE), Rai(Webuye KE).$cm$,
   3948, 6580,
   $cm$Mufindi 14만 + Fortune 4.8만 t × 가동 70% × FCC 3~5% (보고서 시나리오, Tanpack 미포함)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('tanpack', 'dar es salaam|mikocheni', 'tanpack|chandaria'),
  ('mufindi', 'mgololo|mufindi', 'mufindi|rai'),
  ('fortune paper', 'kibaha|misugusugu', 'fortune'),
  ('kibo paper', 'dar es salaam', 'kibo paper'),
  ('kibo match', null, 'kibo match'),
  ('twiga paper', null, 'twiga paper'),
  ('\m369 industries', null, '\m369 industries'),
  ('tanzania printing services', null, 'tanzania printing services'),
  ('maxons', null, 'maxons'),
  ('pee pee', null, 'pee pee')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'tanzania_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'tanzania_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'neelkanth chemicals' or p.party_name ~* 'neelkanth lime' or p.party_name ~* 'abm equipment' or p.party_name ~* 'alpha lime')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    