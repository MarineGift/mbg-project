-- ============================================================
-- seed_20261016zzzg_ethiopia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Ethiopia update (reports 2026-10-17). Gelan has Suzo and Kite - owner
-- regex keeps them apart. EPPSC guard also matches "Wonji Pulp and Paper".
-- 1) Fillers if missing (4): Min-Tech, DH Geda, MIDROC / MBI, Plaspia.
-- 2) Mills if missing (4) + plant blocks, priority 1-3: Purewood, EPPSC,
--    Suzo. Kite no priority. Context (2): Zak Green, Safe Tissue.
-- 3) app.country_markets ET row (priority low).
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
           v.party_name, 'ET', v.region, v.city, v.website, 'active', 'ethiopia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('min.?tech', 'Min-Tech Ethiopia - Dukem', 'Oromia', 'Dukem', null, 'Min-Tech(Dukem) 천연·표면처리 탄산칼슘·돌로마이트·탈크·석회석 필러 — 제지·도료·플라스틱·고무, 가공라인 최대 4.5 t/h(이론 연 약 3.6만 t).', 'Min-Tech Ethiopia, Dukem - natural and coated calcium carbonate, dolomite, talc and limestone filler for paper, paint, plastics and rubber, processing line up to 4.5 t/h (about 36,000 t/yr theoretical).', 'ET check 2026-10-16: real output and paper customers unknown. +251 11 432 0707. FCC co-production candidate 1 (Dukem, next to Purewood).'),
  ('dh geda|geda minerals', 'DH Geda Minerals - Gelan', 'Oromia', 'Gelan', null, 'DH Geda Trade and Industry(2011~, Gelan·Kality) 미분 탄산칼슘·돌로마이트·대리석 분말 연 3만 t — 제지·도료·플라스틱·고무·유리·건설화학.', 'DH Geda Trade and Industry PLC (carbonate processing since 2011), Gelan City (Kality, about 20 km of Addis Ababa) - micronised calcium carbonate, dolomite and marble powders, 30,000 t/yr, paper among target uses.', 'ET check 2026-10-16: PSD, brightness and slurry to confirm. Candidate 2 (Gelan, next to Suzo).'),
  ('modern building industries|midroc.*(carbonate|awash)', 'Modern Building Industries (MIDROC) - Awash 7 Kilo', 'Afar', 'Awash 7 Kilo', null, 'MIDROC 계열 MBI Awash 7 Kilo 표면처리 탄산칼슘 공장 2025-05-22 개장 — 설계 연 1.8만 t, 초기 15%, 원료 97% 인근 조달, 플라스틱·PVC·케이블.', 'Modern Building Industries PLC (MIDROC Investment Group), Awash 7 Kilo (Afar) - coated calcium carbonate plant opened 2025-05-22, 18,000 t/yr design running at 15 pct at start, 97 pct local ore, aimed at plastics, PVC and cables.', 'ET check 2026-10-16: stearic-coated grades are not paper filler. Long-term partner.'),
  ('plaspia', 'Plaspia - Addis Ababa', 'Addis Ababa', 'Addis Ababa', null, 'Plaspia 비코팅 탄산칼슘·돌로마이트 제조·유통(플라스틱·고무·도료·건축).', 'Plaspia, Bole Bulbula, Addis Ababa - uncoated calcium carbonate and dolomite for plastics, rubber, paint and building.', 'ET check 2026-10-16: no paper supply known. Not added: CITCO brochure items (DDP-PCC1 etc., maker unverified). UNIDO once studied a 1,500 t/yr PCC plant - not built as far as known. No Ethiopian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ET check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('min.?tech', 'Min-Tech Ethiopia - Dukem', 'Oromia', 'Dukem', null, 'Min-Tech(Dukem) 천연·표면처리 탄산칼슘·돌로마이트·탈크·석회석 필러 — 제지·도료·플라스틱·고무, 가공라인 최대 4.5 t/h(이론 연 약 3.6만 t).', 'Min-Tech Ethiopia, Dukem - natural and coated calcium carbonate, dolomite, talc and limestone filler for paper, paint, plastics and rubber, processing line up to 4.5 t/h (about 36,000 t/yr theoretical).', 'ET check 2026-10-16: real output and paper customers unknown. +251 11 432 0707. FCC co-production candidate 1 (Dukem, next to Purewood).'),
  ('dh geda|geda minerals', 'DH Geda Minerals - Gelan', 'Oromia', 'Gelan', null, 'DH Geda Trade and Industry(2011~, Gelan·Kality) 미분 탄산칼슘·돌로마이트·대리석 분말 연 3만 t — 제지·도료·플라스틱·고무·유리·건설화학.', 'DH Geda Trade and Industry PLC (carbonate processing since 2011), Gelan City (Kality, about 20 km of Addis Ababa) - micronised calcium carbonate, dolomite and marble powders, 30,000 t/yr, paper among target uses.', 'ET check 2026-10-16: PSD, brightness and slurry to confirm. Candidate 2 (Gelan, next to Suzo).'),
  ('modern building industries|midroc.*(carbonate|awash)', 'Modern Building Industries (MIDROC) - Awash 7 Kilo', 'Afar', 'Awash 7 Kilo', null, 'MIDROC 계열 MBI Awash 7 Kilo 표면처리 탄산칼슘 공장 2025-05-22 개장 — 설계 연 1.8만 t, 초기 15%, 원료 97% 인근 조달, 플라스틱·PVC·케이블.', 'Modern Building Industries PLC (MIDROC Investment Group), Awash 7 Kilo (Afar) - coated calcium carbonate plant opened 2025-05-22, 18,000 t/yr design running at 15 pct at start, 97 pct local ore, aimed at plastics, PVC and cables.', 'ET check 2026-10-16: stearic-coated grades are not paper filler. Long-term partner.'),
  ('plaspia', 'Plaspia - Addis Ababa', 'Addis Ababa', 'Addis Ababa', null, 'Plaspia 비코팅 탄산칼슘·돌로마이트 제조·유통(플라스틱·고무·도료·건축).', 'Plaspia, Bole Bulbula, Addis Ababa - uncoated calcium carbonate and dolomite for plastics, rubber, paint and building.', 'ET check 2026-10-16: no paper supply known. Not added: CITCO brochure items (DDP-PCC1 etc., maker unverified). UNIDO once studied a 1,500 t/yr PCC plant - not built as far as known. No Ethiopian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'ethiopia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Min-Tech Ethiopia - Dukem', 'GCC producer', 'Paper GCC named, Dukem - candidate 1', 'merchant', 'B', 'gcc'),
  ('DH Geda Minerals - Gelan', 'GCC producer', 'Micronised GCC, paper named - candidate 2', 'merchant', 'B', 'gcc'),
  ('Modern Building Industries (MIDROC) - Awash 7 Kilo', 'GCC producer', 'Coated carbonate (plastics) - long-term partner', 'merchant', 'C', 'gcc'),
  ('Plaspia - Addis Ababa', 'GCC producer', 'Uncoated carbonate - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'ethiopia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'ET', v.region, v.city, v.website, 'active', 'ethiopia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('purewood', 'dukem', 'purewood', 'Purewood Pulp Paper & Packaging - Dukem', 'Oromia', 'Dukem', null, 'Purewood(Dukem 동부산업단지, 디아스포라·중국 합작, USD 6,000만) — 냅킨·화장지 1만 t, 크라프트 1.5만 t, 판지 7,500 t(회사 발표 합 3.25만 t), JUMBO·KIYA.', 'Purewood Pulp Paper and Packaging PLC, Eastern Industrial Zone, Dukem (diaspora-Chinese JV, USD 60 m) - napkins and toilet tissue 10,000 t, kraft 15,000 t and carton board 7,500 t per year (company figures, 32,500 t), brands JUMBO and KIYA.', 'ET check 2026-10-16: sales@purewood.com, +251 904 636363.'),
  ('ethiopian pulp|\meppsc\M|wonji pulp', 'wonji|adama', 'ethiopian pulp|eppsc|wonji', 'Ethiopian Pulp & Paper (EPPSC) - Wonji', 'Oromia', 'Wonji', null, 'EPPSC(1963, Wonji·Adama, 정부 70%·IFC 30%) — 인쇄·필기·포장용지·판지·골판지 상자, 과거 설계 약 8,500~9,500 t, 이후 약 1만 t.', 'Ethiopian Pulp and Paper S.C. (1963), Wonji, Adama (Oromia), owned 70 pct by the state and 30 pct by IFC - printing, writing and wrapping paper, paperboard and corrugated boxes, design about 8,500-9,500 t/yr, about 10,000 t reported later. Also called Wonji Pulp and Paper.', 'ET check 2026-10-16: current output and filler use to confirm. eppsc.com@ethionet.et, +251 994 810 076.'),
  ('suzo', 'gelan', 'suzo', 'Suzo Industry - Gelan', 'Oromia', 'Gelan', null, 'Suzo(2008-12, Gelan) 폐지(교과서·잡지) 재활용 티슈 점보롤 연 1만 t+ — 후가공 16개사 공급, 정규 62명.', 'Suzo Industry PLC (2008-12), Gelan (Oromia) - recycled tissue jumbo rolls of collected textbooks and magazines, over 10,000 t/yr supplied to 16 converters (company), 62 permanent staff.', 'ET check 2026-10-16: info@suzoindustry.com, +251 113 206490.'),
  ('kite manufacturing', 'gelan', 'kite', 'Kite Manufacturing - Gelan', 'Oromia', 'Gelan', null, 'Kite(2004, Gelan Sunshine Terminal 인근) 위생지·골판지 — 화장지·키친·페이셜·냅킨, 2/3/5겹 골판지, 소유권 변경·현대화.', 'Kite Manufacturing PLC (2004), Gelan near Sunshine Terminal - toilet and kitchen rolls, facial tissue, napkins and 2/3/5-ply corrugated board, ownership change and upgrade announced.', 'ET check 2026-10-16: own paper machine not confirmed. info@kitemanufacturing.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ET check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('purewood', 'dukem', 'purewood', 'Purewood(Dukem 동부산업단지, 디아스포라·중국 합작, USD 6,000만) — 냅킨·화장지 1만 t, 크라프트 1.5만 t, 판지 7,500 t(회사 발표 합 3.25만 t), JUMBO·KIYA.', 'Purewood Pulp Paper and Packaging PLC, Eastern Industrial Zone, Dukem (diaspora-Chinese JV, USD 60 m) - napkins and toilet tissue 10,000 t, kraft 15,000 t and carton board 7,500 t per year (company figures, 32,500 t), brands JUMBO and KIYA.', 'ET check 2026-10-16: sales@purewood.com, +251 904 636363.'),
  ('ethiopian pulp|\meppsc\M|wonji pulp', 'wonji|adama', 'ethiopian pulp|eppsc|wonji', 'EPPSC(1963, Wonji·Adama, 정부 70%·IFC 30%) — 인쇄·필기·포장용지·판지·골판지 상자, 과거 설계 약 8,500~9,500 t, 이후 약 1만 t.', 'Ethiopian Pulp and Paper S.C. (1963), Wonji, Adama (Oromia), owned 70 pct by the state and 30 pct by IFC - printing, writing and wrapping paper, paperboard and corrugated boxes, design about 8,500-9,500 t/yr, about 10,000 t reported later. Also called Wonji Pulp and Paper.', 'ET check 2026-10-16: current output and filler use to confirm. eppsc.com@ethionet.et, +251 994 810 076.'),
  ('suzo', 'gelan', 'suzo', 'Suzo(2008-12, Gelan) 폐지(교과서·잡지) 재활용 티슈 점보롤 연 1만 t+ — 후가공 16개사 공급, 정규 62명.', 'Suzo Industry PLC (2008-12), Gelan (Oromia) - recycled tissue jumbo rolls of collected textbooks and magazines, over 10,000 t/yr supplied to 16 converters (company), 62 permanent staff.', 'ET check 2026-10-16: info@suzoindustry.com, +251 113 206490.'),
  ('kite manufacturing', 'gelan', 'kite', 'Kite(2004, Gelan Sunshine Terminal 인근) 위생지·골판지 — 화장지·키친·페이셜·냅킨, 2/3/5겹 골판지, 소유권 변경·현대화.', 'Kite Manufacturing PLC (2004), Gelan near Sunshine Terminal - toilet and kitchen rolls, facial tissue, napkins and 2/3/5-ply corrugated board, ownership change and upgrade announced.', 'ET check 2026-10-16: own paper machine not confirmed. info@kitemanufacturing.com.'),
  ('zak green', null, 'zak green', null, null, 'ET check 2026-10-16: Zak Green Soft and Pulp Factory, Hawassa (2019) - tissue products, machine not confirmed - context only.'),
  ('safe tissue', null, 'safe tissue', null, null, 'ET check 2026-10-16: Safe Tissue Paper, Akaki Kality (2017) - 100 pct virgin-pulp tissue products, machine not confirmed - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'ethiopia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('purewood', 'dukem', 'purewood'),
  ('ethiopian pulp|\meppsc\M|wonji pulp', 'wonji|adama', 'ethiopian pulp|eppsc|wonji'),
  ('suzo', 'gelan', 'suzo'),
  ('kite manufacturing', 'gelan', 'kite'),
  ('zak green', null, 'zak green'),
  ('safe tissue', null, 'safe tissue')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('purewood', 'dukem', 'purewood', false,
   $pj${"owner": "Purewood", "priority": 1, "products": "Tissue, kraft, carton board", "grades": ["Tissue", "Kraft paper", "Board"], "capacity_split": [{"label": "Tissue", "value_t": 10000}, {"label": "Kraft", "value_t": 15000}, {"label": "Carton board", "value_t": 7500}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "On 32.5 kt company total."}, "pitch": "Min-Tech GCC + MBG FCC trial at Dukem", "approach": "Lead Ethiopian account.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ethiopian pulp|\meppsc\M|wonji pulp', 'wonji|adama', 'ethiopian pulp|eppsc|wonji', false,
   $pj${"owner": "State / IFC", "priority": 2, "products": "Printing and writing, wrapping, board", "grades": ["UWF", "Board"], "capacity": {"value": 10000, "unit": "metric_t", "year": "Reported output (older)", "source": "eppsc.com.et"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Printing and writing."}, "approach": "Printing-paper filler trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('suzo', 'gelan', 'suzo', false,
   $pj${"owner": "Suzo", "priority": 3, "products": "Recycled tissue jumbo rolls", "grades": ["Tissue"], "capacity": {"value": 10000, "unit": "metric_t", "year": "Company claim", "source": "suzoindustry.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Recycled tissue - low dose first."}, "approach": "DH Geda GCC + MBG FCC low-dose trial at Gelan.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kite manufacturing', 'gelan', 'kite', false,
   $pj${"owner": "Kite", "products": "Tissue products, corrugated", "grades": ["Tissue"], "approach": "Confirm machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zak green', null, 'zak green', true,
   $pj${"owner": "Zak Green", "products": "Zak Green Soft and Pulp Factory, Hawassa (2019) - tissue products, machine not confirmed", "approach": "Confirm base-paper source.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('safe tissue', null, 'safe tissue', true,
   $pj${"owner": "Safe Tissue", "products": "Safe Tissue Paper, Akaki Kality (2017) - 100 pct virgin-pulp tissue products, machine not confirmed", "approach": "Confirm base-paper source.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ET', 'Ethiopia', 'low',
   $cm$Purewood (32.5 kt tissue, kraft, board), EPPSC Wonji UWF (about 10 kt), Suzo recycled tissue - Min-Tech and DH Geda GCC next door (Dukem, Gelan)$cm$,
   $cm$Ethiopia has real paper machines in the Addis Ababa - Dukem - Gelan belt and at Wonji: Purewood Dukem (tissue 10 kt, kraft 15 kt, board 7.5 kt - company figures), Ethiopian Pulp and Paper (EPPSC, Wonji, state 70 pct / IFC 30 pct, printing and writing about 10 kt), Suzo Gelan (recycled tissue over 10 kt), plus Kite, Zak Green and Safe Tissue (machines to confirm). Local GCC sits next to the mills: Min-Tech Dukem (paper named, 4.5 t/h), DH Geda Gelan (30 kt micronised, paper named), MIDROC coated carbonate (18 kt, plastics), Plaspia. No paper PCC. Djibouti is the import and re-export port.$cm$,
   $cm${"fillers": "GCC: Min-Tech, DH Geda, MIDROC / MBI (coated), Plaspia. Not added: CITCO items. No PCC.", "mills": "Tissue, kraft, board: Purewood. UWF: EPPSC Wonji. Recycled tissue: Suzo. To confirm: Kite. Context: Zak Green, Safe Tissue.", "strategy": "Small local OEM: Min-Tech or DH Geda GCC + MBG FCC process, trials at Purewood (Dukem) and Suzo (Gelan) next door, printing trial at EPPSC.", "risks": "Company figures unverified, FX and import controls.", "next_steps": ["Request Min-Tech and DH Geda PSD and brightness", "Propose a Purewood tissue trial"], "key_numbers": [{"label": "Purewood", "value": "32.5 kt (10 + 15 + 7.5)"}, {"label": "Three mills", "value": "about 52.5 kt"}], "files": ["seed_20261016zzzg_ethiopia_mills_fillers"]}$cm$::jsonb,
   $cm$Purewood(티슈·크라프트·판지 3.25만 t), EPPSC Wonji UWF(약 1만 t), Suzo 재생 티슈 — Min-Tech·DH Geda GCC 인접(Dukem, Gelan)$cm$,
   $cm$에티오피아 Addis Ababa-Dukem-Gelan 축과 Wonji 에 실제 초지기: Purewood Dukem(티슈 1만·크라프트 1.5만·판지 7,500 t, 회사 발표), EPPSC(Wonji, 정부 70%·IFC 30%, 인쇄·필기 약 1만 t), Suzo Gelan(재생 티슈 1만 t+), Kite·Zak Green·Safe Tissue(초지기 확인 필요). 현지 GCC 가 공장 옆: Min-Tech Dukem(제지 명시, 4.5 t/h), DH Geda Gelan(미분 3만 t, 제지 명시), MIDROC 코팅(1.8만 t, 플라스틱), Plaspia. 제지용 PCC 없음. 지부티가 수입·재수출 항.$cm$,
   1575, 2625,
   $cm$Purewood + EPPSC + Suzo 5.25만 t × FCC 3~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('purewood', 'dukem', 'purewood'),
  ('ethiopian pulp|\meppsc\M|wonji pulp', 'wonji|adama', 'ethiopian pulp|eppsc|wonji'),
  ('suzo', 'gelan', 'suzo'),
  ('kite manufacturing', 'gelan', 'kite'),
  ('zak green', null, 'zak green'),
  ('safe tissue', null, 'safe tissue')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'ethiopia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'ethiopia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'min.?tech' or p.party_name ~* 'dh geda|geda minerals' or p.party_name ~* 'modern building industries|midroc.*(carbonate|awash)' or p.party_name ~* 'plaspia')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ET'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ET'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ET'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ET'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    