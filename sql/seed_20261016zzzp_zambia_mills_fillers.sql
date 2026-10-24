-- ============================================================
-- seed_20261016zzzp_zambia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Zambia update (reports 2026-10-17). Carmeuse guard is country-scoped.
-- 1) Fillers if missing (4): Calcite Ltd, Handyman's Lime (Carmeuse),
--    Limestone Resources, Changzhou Zambia.
-- 2) Mills if missing (4) + plant blocks, priority 1-2: Book Hut, Zambezi
--    Paper Mills. Huiyu, Falcom no priority. Context (13).
-- 3) app.country_markets ZM row (priority low).
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
           v.party_name, 'ZM', v.region, v.city, v.website, 'active', 'zambia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcite limited', 'Calcite Limited - Lusaka', 'Lusaka', 'Lusaka', null, 'Calcite Limited(Plot 12747 Mumbwa Rd, Chinika) 미분 탄산칼슘·코팅 탄산칼슘·충전 과립·탈크 — 도료·플라스틱·제지 용도, 금속 캔 사업 병행.', 'Calcite Limited, Plot 12747 Mumbwa Road, Chinika, Lusaka - micronised and coated calcium carbonate, filler granules and talc for paint, plastics and paper, also metal cans.', 'ZM check 2026-10-16: PSD, brightness, wet line and mill supply unknown. +260 974 762 765. Candidate 1 for local GCC.'),
  ('handyman.?s lime|carmeuse.*zambia|astro quarries', 'Handyman''s Lime (Carmeuse) - Masaiti', 'Copperbelt', 'Masaiti', null, 'Carmeuse 운영(2017-07~) Handyman''s Lime(Masaiti) — Astro Quarries 석회석, Maerz PFR 소성로 생석회 600 t/일, 잠비아·짐바브웨·DRC 광산 고객.', 'Handyman''s Lime Ltd, Masaiti (Copperbelt), run by Carmeuse since 2017-07 - limestone of Astro Quarries, Maerz PFR kiln with 600 t/day quicklime, customers mainly mines in Zambia, Zimbabwe and DR Congo.', 'ZM check 2026-10-16: no PCC here - Carmeuse lists PCC and paper as applications globally. bupe.nalungwe@hllcarmeuse.com. PCC lime route and group link.'),
  ('limestone resources|ndola lime', 'Limestone Resources (ex Ndola Lime) - Ndola', 'Copperbelt', 'Ndola', null, 'Limestone Resources(1931, 구 Ndola Lime) 생석회·소석회·농업용 석회 — 생석회 500 t/일. 2026-05-28 ZCCM-IH·Wonderful Group 합작 Ndola Lime (2026) USD 3,000만(55:45) 석회·시멘트 계획.', 'Limestone Resources Ltd (1931, formerly Ndola Lime Company), Ndola / Masaiti - quicklime about 500 t/day, hydrated and agricultural lime, aggregates. 2026-05-28: ZCCM-IH and Wonderful Group JV Ndola Lime (2026) Ltd, USD 30 m, 55:45, for an integrated lime and cement plant.', 'ZM check 2026-10-16: JV scope and asset transfer to confirm. sales@lrl.co.zm.'),
  ('changzhou zambia', 'Changzhou Zambia Resources - Ndola', 'Copperbelt', 'Ndola', null, 'Changzhou Zambia(2014, Itawa Ndola) 자체 석회석 광산(Masaiti) — 파쇄 2라인 3,000 t/일, 석회 600 t/일, 투자 USD 1,000만+.', 'Changzhou Zambia Resources Co. Ltd (2014), Plot 5844 Airport Road, Itawa, Ndola - own limestone quarry at Masaiti, two crushing lines 3,000 t/day, lime 600 t/day, over USD 10 m invested.', 'ZM check 2026-10-16: raw-material supply. Not added: Clean Lime Zambia (Chiwala, lime). No Zambian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ZM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcite limited', 'Calcite Limited - Lusaka', 'Lusaka', 'Lusaka', null, 'Calcite Limited(Plot 12747 Mumbwa Rd, Chinika) 미분 탄산칼슘·코팅 탄산칼슘·충전 과립·탈크 — 도료·플라스틱·제지 용도, 금속 캔 사업 병행.', 'Calcite Limited, Plot 12747 Mumbwa Road, Chinika, Lusaka - micronised and coated calcium carbonate, filler granules and talc for paint, plastics and paper, also metal cans.', 'ZM check 2026-10-16: PSD, brightness, wet line and mill supply unknown. +260 974 762 765. Candidate 1 for local GCC.'),
  ('handyman.?s lime|carmeuse.*zambia|astro quarries', 'Handyman''s Lime (Carmeuse) - Masaiti', 'Copperbelt', 'Masaiti', null, 'Carmeuse 운영(2017-07~) Handyman''s Lime(Masaiti) — Astro Quarries 석회석, Maerz PFR 소성로 생석회 600 t/일, 잠비아·짐바브웨·DRC 광산 고객.', 'Handyman''s Lime Ltd, Masaiti (Copperbelt), run by Carmeuse since 2017-07 - limestone of Astro Quarries, Maerz PFR kiln with 600 t/day quicklime, customers mainly mines in Zambia, Zimbabwe and DR Congo.', 'ZM check 2026-10-16: no PCC here - Carmeuse lists PCC and paper as applications globally. bupe.nalungwe@hllcarmeuse.com. PCC lime route and group link.'),
  ('limestone resources|ndola lime', 'Limestone Resources (ex Ndola Lime) - Ndola', 'Copperbelt', 'Ndola', null, 'Limestone Resources(1931, 구 Ndola Lime) 생석회·소석회·농업용 석회 — 생석회 500 t/일. 2026-05-28 ZCCM-IH·Wonderful Group 합작 Ndola Lime (2026) USD 3,000만(55:45) 석회·시멘트 계획.', 'Limestone Resources Ltd (1931, formerly Ndola Lime Company), Ndola / Masaiti - quicklime about 500 t/day, hydrated and agricultural lime, aggregates. 2026-05-28: ZCCM-IH and Wonderful Group JV Ndola Lime (2026) Ltd, USD 30 m, 55:45, for an integrated lime and cement plant.', 'ZM check 2026-10-16: JV scope and asset transfer to confirm. sales@lrl.co.zm.'),
  ('changzhou zambia', 'Changzhou Zambia Resources - Ndola', 'Copperbelt', 'Ndola', null, 'Changzhou Zambia(2014, Itawa Ndola) 자체 석회석 광산(Masaiti) — 파쇄 2라인 3,000 t/일, 석회 600 t/일, 투자 USD 1,000만+.', 'Changzhou Zambia Resources Co. Ltd (2014), Plot 5844 Airport Road, Itawa, Ndola - own limestone quarry at Masaiti, two crushing lines 3,000 t/day, lime 600 t/day, over USD 10 m invested.', 'ZM check 2026-10-16: raw-material supply. Not added: Clean Lime Zambia (Chiwala, lime). No Zambian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'zambia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calcite Limited - Lusaka', 'GCC producer', 'Micronised CaCO3 maker - candidate 1', 'merchant', 'C', 'gcc'),
  ('Handyman''s Lime (Carmeuse) - Masaiti', 'Lime producer', 'Quicklime (Carmeuse) - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Limestone Resources (ex Ndola Lime) - Ndola', 'Lime producer', 'Lime - PCC raw material, new JV', 'merchant', 'C', 'pcc'),
  ('Changzhou Zambia Resources - Ndola', 'Lime producer', 'Limestone and lime - raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'zambia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'ZM', v.region, v.city, v.website, 'active', 'zambia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('book hut', 'lusaka', 'book hut', 'Book Hut - Lusaka', 'Lusaka', 'Lusaka', null, 'Book Hut(1996) 신규 제지공장 — 2021-06 Scan Machineries 턴키 시운전, Double Wire Fourdrinier 와이어 2,600 mm, 70~250 gsm Testliner·Fluting·White Top, 사이즈프레스·캘린더·QCS, 슬러지는 계란판.', 'Book Hut Ltd (1996), Lusaka - exercise books and printing plus a new paper mill commissioned 2021-06 by Scan Machineries (India): double-wire Fourdrinier, 2,600 mm wire, 70-250 gsm testliner, fluting and white top, size press, calender, QCS, sludge to egg trays.', 'ZM check 2026-10-16: daily output and 2026 running rate to confirm. +260 211 234087.'),
  ('zambezi paper', 'ndola', 'zambezi', 'Zambezi Paper Mills - Ndola', 'Copperbelt', 'Ndola', null, 'Zambezi Paper Mills(1981~, Mushili Rd Ndola) 폐지 재활용 — 티슈·필기용지·Fluting·Testliner·포장지 등록, 과거 티슈 약 10 t/일, Lusaka·Kitwe 폐지 수거.', 'Zambezi Paper Mills Ltd, Plot 4087/5/6/7 Mushili Road, Ndola (since 1981) - recycled tissue, writing paper, fluting, testliner and wrapping paper listed, about 10 t/day tissue in older research, waste-paper depots in Lusaka and Kitwe. Named as a kraft and tissue maker in a 2024 investment paper.', 'ZM check 2026-10-16: running lines to confirm. zpm@zamnet.zm, +260 212 650829.'),
  ('huiyu|hui yu|hiuyu', 'chibombo', 'huiyu|hui yu', 'Zambia Huiyu Paper Plant - Chibombo', 'Central', 'Chibombo', null, 'Zambia Huiyu(Great North Rd, Chibombo) 폐지(HS 4707) 수입 기록(짐바브웨, 2023-02).', 'Zambia Huiyu Paper Plant Ltd (also Hiuyu / Hui Yu), Great North Road, Chibombo - imports of waste paper (HS 4707) of Zimbabwe on record (2023-02).', 'ZM check 2026-10-16: paper machine and grade to confirm.'),
  ('falco[mn] paper', 'kanakantapa|lusaka', 'falco', 'Falcom Paper Mills - Kanakantapa', 'Lusaka', 'Kanakantapa', null, 'Falcom Paper Mills(Kanakantapa, Great North Rd 인근) 폐지 수입(2024-10 약 34 t·31 t), D&B 종이가공 등록.', 'Falcom Paper Mills Ltd, Kanakantapa near the Great North Road (Lusaka) - waste-paper imports of about 34 t and 31 t in 2024-10, listed by D&B as a paper converter. Spelt Falcon in some records.', 'ZM check 2026-10-16: machine and grade to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ZM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('book hut', 'lusaka', 'book hut', 'Book Hut(1996) 신규 제지공장 — 2021-06 Scan Machineries 턴키 시운전, Double Wire Fourdrinier 와이어 2,600 mm, 70~250 gsm Testliner·Fluting·White Top, 사이즈프레스·캘린더·QCS, 슬러지는 계란판.', 'Book Hut Ltd (1996), Lusaka - exercise books and printing plus a new paper mill commissioned 2021-06 by Scan Machineries (India): double-wire Fourdrinier, 2,600 mm wire, 70-250 gsm testliner, fluting and white top, size press, calender, QCS, sludge to egg trays.', 'ZM check 2026-10-16: daily output and 2026 running rate to confirm. +260 211 234087.'),
  ('zambezi paper', 'ndola', 'zambezi', 'Zambezi Paper Mills(1981~, Mushili Rd Ndola) 폐지 재활용 — 티슈·필기용지·Fluting·Testliner·포장지 등록, 과거 티슈 약 10 t/일, Lusaka·Kitwe 폐지 수거.', 'Zambezi Paper Mills Ltd, Plot 4087/5/6/7 Mushili Road, Ndola (since 1981) - recycled tissue, writing paper, fluting, testliner and wrapping paper listed, about 10 t/day tissue in older research, waste-paper depots in Lusaka and Kitwe. Named as a kraft and tissue maker in a 2024 investment paper.', 'ZM check 2026-10-16: running lines to confirm. zpm@zamnet.zm, +260 212 650829.'),
  ('huiyu|hui yu|hiuyu', 'chibombo', 'huiyu|hui yu', 'Zambia Huiyu(Great North Rd, Chibombo) 폐지(HS 4707) 수입 기록(짐바브웨, 2023-02).', 'Zambia Huiyu Paper Plant Ltd (also Hiuyu / Hui Yu), Great North Road, Chibombo - imports of waste paper (HS 4707) of Zimbabwe on record (2023-02).', 'ZM check 2026-10-16: paper machine and grade to confirm.'),
  ('falco[mn] paper', 'kanakantapa|lusaka', 'falco', 'Falcom Paper Mills(Kanakantapa, Great North Rd 인근) 폐지 수입(2024-10 약 34 t·31 t), D&B 종이가공 등록.', 'Falcom Paper Mills Ltd, Kanakantapa near the Great North Road (Lusaka) - waste-paper imports of about 34 t and 31 t in 2024-10, listed by D&B as a paper converter. Spelt Falcon in some records.', 'ZM check 2026-10-16: machine and grade to confirm.'),
  ('sobi', null, 'sobi', null, null, 'ZM check 2026-10-16: Sobi Industries, Luanshya Road Lusaka (1972) - tissue, exercise books, about 240 staff (2014) - context only.'),
  ('yasha', null, 'yasha', null, null, 'ZM check 2026-10-16: Yasha Papers (Compact Tissue), Mwembeshi Road Lusaka (2021) - tissue converting - context only.'),
  ('pureply', null, 'pureply', null, null, 'ZM check 2026-10-16: PurePly Soft, Kitwe - tissue products - context only.'),
  ('imco ?& ?bisco', null, 'imco ?& ?bisco', null, null, 'ZM check 2026-10-16: Tissue, paper bags, packaging, Lusaka - context only.'),
  ('fairy investments', null, 'fairy investments', null, null, 'ZM check 2026-10-16: Fairy toilet tissue, Lusaka - context only.'),
  ('cloud 9 tissue', null, 'cloud 9 tissue', null, null, 'ZM check 2026-10-16: Tissue products, Lusaka - context only.'),
  ('premium pure', null, 'premium pure', null, null, 'ZM check 2026-10-16: Tissue, napkins, towels, Cairo Road Lusaka - context only.'),
  ('unity packages', null, 'unity packages', null, null, 'ZM check 2026-10-16: Corrugated boxes, Ndola - exports to AO, CD, MW, ZW - context only.'),
  ('industrial cartons', null, 'industrial cartons', null, null, 'ZM check 2026-10-16: Industrial Cartons of Zambia, Lusaka - cartons - context only.'),
  ('boxpack', null, 'boxpack', null, null, 'ZM check 2026-10-16: Corrugated boxes, Lusaka - context only.'),
  ('devsai', null, 'devsai', null, null, 'ZM check 2026-10-16: Board and packaging, Lusaka - context only.'),
  ('nisco|best pack', null, 'nisco|best pack', null, null, 'ZM check 2026-10-16: Packaging and corrugated, Lusaka - context only.'),
  ('nampak zambia|diversified liquid packaging', null, 'nampak zambia|diversified liquid packaging', null, null, 'ZM check 2026-10-16: Ex-Nampak Zambia paper bags and cartons, Lusaka - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'zambia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('book hut', 'lusaka', 'book hut'),
  ('zambezi paper', 'ndola', 'zambezi'),
  ('huiyu|hui yu|hiuyu', 'chibombo', 'huiyu|hui yu'),
  ('falco[mn] paper', 'kanakantapa|lusaka', 'falco'),
  ('sobi', null, 'sobi'),
  ('yasha', null, 'yasha'),
  ('pureply', null, 'pureply'),
  ('imco ?& ?bisco', null, 'imco ?& ?bisco'),
  ('fairy investments', null, 'fairy investments'),
  ('cloud 9 tissue', null, 'cloud 9 tissue'),
  ('premium pure', null, 'premium pure'),
  ('unity packages', null, 'unity packages'),
  ('industrial cartons', null, 'industrial cartons'),
  ('boxpack', null, 'boxpack'),
  ('devsai', null, 'devsai'),
  ('nisco|best pack', null, 'nisco|best pack'),
  ('nampak zambia|diversified liquid packaging', null, 'nampak zambia|diversified liquid packaging')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('book hut', 'lusaka', 'book hut', false,
   $pj${"owner": "Book Hut", "priority": 1, "products": "Testliner, fluting, white top", "grades": ["Testliner", "Medium", "White-top liner"], "approach": "Strength-hold trial on white top first - Calcite Ltd GCC.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zambezi paper', 'ndola', 'zambezi', false,
   $pj${"owner": "Zambezi Paper Mills", "priority": 2, "products": "Recycled tissue, writing, liner", "grades": ["Tissue", "UWF", "Testliner"], "approach": "Tissue and writing-paper filler trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('huiyu|hui yu|hiuyu', 'chibombo', 'huiyu|hui yu', false,
   $pj${"owner": "Huiyu", "products": "Recycled paper (to confirm)", "grades": [], "approach": "Confirm machine.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('falco[mn] paper', 'kanakantapa|lusaka', 'falco', false,
   $pj${"owner": "Falcom", "products": "Recycled paper (to confirm)", "grades": [], "approach": "Confirm machine.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sobi', null, 'sobi', true,
   $pj${"owner": "Sobi Group", "products": "Sobi Industries, Luanshya Road Lusaka (1972) - tissue, exercise books, about 240 staff (2014)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('yasha', null, 'yasha', true,
   $pj${"owner": "Yasha", "products": "Yasha Papers (Compact Tissue), Mwembeshi Road Lusaka (2021) - tissue converting", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pureply', null, 'pureply', true,
   $pj${"owner": "PurePly Soft", "products": "PurePly Soft, Kitwe - tissue products", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imco ?& ?bisco', null, 'imco ?& ?bisco', true,
   $pj${"owner": "IMCO and BISCO", "products": "Tissue, paper bags, packaging, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fairy investments', null, 'fairy investments', true,
   $pj${"owner": "Fairy", "products": "Fairy toilet tissue, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cloud 9 tissue', null, 'cloud 9 tissue', true,
   $pj${"owner": "Cloud 9", "products": "Tissue products, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('premium pure', null, 'premium pure', true,
   $pj${"owner": "Premium Pure", "products": "Tissue, napkins, towels, Cairo Road Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unity packages', null, 'unity packages', true,
   $pj${"owner": "Unity Packages", "products": "Corrugated boxes, Ndola - exports to AO, CD, MW, ZW", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('industrial cartons', null, 'industrial cartons', true,
   $pj${"owner": "ICZ", "products": "Industrial Cartons of Zambia, Lusaka - cartons", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('boxpack', null, 'boxpack', true,
   $pj${"owner": "Boxpack", "products": "Corrugated boxes, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('devsai', null, 'devsai', true,
   $pj${"owner": "Devsai", "products": "Board and packaging, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nisco|best pack', null, 'nisco|best pack', true,
   $pj${"owner": "Nisco Group", "products": "Packaging and corrugated, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nampak zambia|diversified liquid packaging', null, 'nampak zambia|diversified liquid packaging', true,
   $pj${"owner": "DLPG", "products": "Ex-Nampak Zambia paper bags and cartons, Lusaka", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ZM', 'Zambia', 'low',
   $cm$Book Hut liner machine (2,600 mm, 2021) and Zambezi Paper Mills Ndola (recycled tissue and writing) - Calcite Ltd GCC, Carmeuse lime at Masaiti$cm$,
   $cm$Zambia has real paper machines: Book Hut Lusaka (new 2,600 mm double-wire Fourdrinier, 2021, testliner, fluting, white top) and Zambezi Paper Mills Ndola (recycled tissue, writing paper and liner since 1981), plus waste-paper importers Huiyu (Chibombo) and Falcom (Kanakantapa) to confirm. Converters: Sobi, Yasha, PurePly and others (tissue), Unity Packages, ICZ, Boxpack (corrugated). Carbonate: Calcite Ltd Lusaka (micronised CaCO3, paper named), Handyman's Lime (Carmeuse, 600 t/day quicklime), Limestone Resources (new Ndola Lime 2026 JV), Changzhou Zambia. No paper PCC. Paper imports about USD 140 m (2021).$cm$,
   $cm${"fillers": "GCC: Calcite Ltd. Lime: Handyman's Lime (Carmeuse), Limestone Resources / Ndola Lime 2026, Changzhou Zambia. No PCC.", "mills": "Liner: Book Hut. Tissue and writing: Zambezi Paper Mills. To confirm: Huiyu, Falcom. Context: 13 converters.", "strategy": "Calcite Ltd GCC + MBG FCC trials at Book Hut (white top) and Zambezi (tissue, writing). Carmeuse lime as a PCC route later.", "risks": "Output unknown, strength-led liner, landlocked.", "next_steps": ["Ask Book Hut for daily output and furnish", "Confirm Zambezi running lines"], "key_numbers": [{"label": "Book Hut PM", "value": "2,600 mm, 70-250 gsm"}, {"label": "Handyman's Lime", "value": "600 t/day quicklime"}], "files": ["seed_20261016zzzp_zambia_mills_fillers"]}$cm$::jsonb,
   $cm$Book Hut 라이너 초지기(2,600 mm, 2021)·Zambezi Paper Mills Ndola(재생 티슈·필기용지) — Calcite Ltd GCC, Masaiti Carmeuse 석회$cm$,
   $cm$잠비아 실제 초지기: Book Hut Lusaka(2021 신규 2,600 mm 더블와이어, 테스트라이너·골심지·화이트탑), Zambezi Paper Mills Ndola(1981~ 재생 티슈·필기용지·라이너), 폐지 수입 Huiyu(Chibombo)·Falcom(Kanakantapa) 확인 필요. 가공: Sobi·Yasha·PurePly 등 티슈, Unity·ICZ·Boxpack 골판지. 탄산칼슘: Calcite Ltd(미분 CaCO3, 제지 명시), Handyman's Lime(Carmeuse 생석회 600 t/일), Limestone Resources(Ndola Lime 2026 합작), Changzhou Zambia. 제지용 PCC 없음. 종이 수입 약 1.4억 달러(2021).$cm$,
   null, null,
   $cm$공장별 생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('book hut', 'lusaka', 'book hut'),
  ('zambezi paper', 'ndola', 'zambezi'),
  ('huiyu|hui yu|hiuyu', 'chibombo', 'huiyu|hui yu'),
  ('falco[mn] paper', 'kanakantapa|lusaka', 'falco'),
  ('sobi', null, 'sobi'),
  ('yasha', null, 'yasha'),
  ('pureply', null, 'pureply'),
  ('imco ?& ?bisco', null, 'imco ?& ?bisco'),
  ('fairy investments', null, 'fairy investments'),
  ('cloud 9 tissue', null, 'cloud 9 tissue'),
  ('premium pure', null, 'premium pure'),
  ('unity packages', null, 'unity packages'),
  ('industrial cartons', null, 'industrial cartons'),
  ('boxpack', null, 'boxpack'),
  ('devsai', null, 'devsai'),
  ('nisco|best pack', null, 'nisco|best pack'),
  ('nampak zambia|diversified liquid packaging', null, 'nampak zambia|diversified liquid packaging')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'zambia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'zambia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcite limited' or p.party_name ~* 'handyman.?s lime|carmeuse.*zambia|astro quarries' or p.party_name ~* 'limestone resources|ndola lime' or p.party_name ~* 'changzhou zambia')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ZM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ZM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ZM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    