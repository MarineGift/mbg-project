-- ============================================================
-- seed_20261016zzzr_drc_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- DR Congo (CD) update (reports 2026-10-17). Memos carry a sanctions note.
-- 1) Fillers if missing (3): JDE DRC, Datong, GCK.
-- 2) Mills if missing (3, no priority, machine to confirm): All Pack
--    Industries, LANI Services, Nduw's Family. Context (6).
-- 3) app.country_markets CD row (priority none).
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
           v.party_name, 'CD', v.region, v.city, v.website, 'active', 'drc_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\mjde\M.*(drc|congo)|jde group', 'JDE DRC - Lubumbashi', 'Haut-Katanga', 'Lubumbashi', null, 'JDE DRC(2014, Lubumbashi) 석회석 분말(표준 75 μm, 최대 106 μm)·골재 — 공급능력 5,400 t/일(연 194만 t 주장), 구리·코발트 제련 고객.', 'JDE DRC SARL (2014), Lubumbashi - limestone powder (75 micron standard, up to 106), aggregates and rock, 5,400 t/day claimed (1.94 Mt/yr), copper and cobalt smelter customers.', 'CD check 2026-10-16: far coarser than paper GCC - would need fine grinding and classifying. contact@jde-group.com, +243 834 855 299. Screen against UN and US DR Congo sanctions lists.'),
  ('datong', 'Datong SARL - Lubumbashi', 'Haut-Katanga', 'Lubumbashi', null, 'Datong SARL(1334 Av. Basoko, Lubumbashi) 산업광물 소싱·공급 — 석회석 CaCO3 98% 초과 주장(시멘트·야금·농업).', 'Datong SARL (Mining and Refinery), 1334 Avenue Basoko, Lubumbashi - industrial-mineral sourcing and export, limestone claimed over 98 pct CaCO3 for cement, metallurgy and farming.', 'CD check 2026-10-16: own quarry and grinding not confirmed - ask for a CoA. info@datongminingrefinery.com, +260 778 807 002 (Zambian number). Screen against UN and US DR Congo sanctions lists.'),
  ('grande cimenterie du katanga|\mgck\M', 'Grande Cimenterie du Katanga - Kakontwe', 'Haut-Katanga', 'Likasi', null, 'GCK(2011, Kakontwe) 석회석 채석·석회·시멘트 — Gécamines·HMIE·West China Cement 관계, 구 Gécamines 시설 기반.', 'Grande Cimenterie du Katanga (GCK, 2011), Kakontwe near Likasi - limestone quarry, lime and cement built on former Gécamines assets, linked to Gécamines, HMIE and West China Cement.', 'CD check 2026-10-16: lime and stone lead only. Not added: ABICOM (mining chemicals distributor, 85-95 pct CaCO3), PPC Barnet DRC (Kongo Central cement, up to 1.25 Mt). No Congolese paper PCC or GCC. Screen against UN and US DR Congo sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\mjde\M.*(drc|congo)|jde group', 'JDE DRC - Lubumbashi', 'Haut-Katanga', 'Lubumbashi', null, 'JDE DRC(2014, Lubumbashi) 석회석 분말(표준 75 μm, 최대 106 μm)·골재 — 공급능력 5,400 t/일(연 194만 t 주장), 구리·코발트 제련 고객.', 'JDE DRC SARL (2014), Lubumbashi - limestone powder (75 micron standard, up to 106), aggregates and rock, 5,400 t/day claimed (1.94 Mt/yr), copper and cobalt smelter customers.', 'CD check 2026-10-16: far coarser than paper GCC - would need fine grinding and classifying. contact@jde-group.com, +243 834 855 299. Screen against UN and US DR Congo sanctions lists.'),
  ('datong', 'Datong SARL - Lubumbashi', 'Haut-Katanga', 'Lubumbashi', null, 'Datong SARL(1334 Av. Basoko, Lubumbashi) 산업광물 소싱·공급 — 석회석 CaCO3 98% 초과 주장(시멘트·야금·농업).', 'Datong SARL (Mining and Refinery), 1334 Avenue Basoko, Lubumbashi - industrial-mineral sourcing and export, limestone claimed over 98 pct CaCO3 for cement, metallurgy and farming.', 'CD check 2026-10-16: own quarry and grinding not confirmed - ask for a CoA. info@datongminingrefinery.com, +260 778 807 002 (Zambian number). Screen against UN and US DR Congo sanctions lists.'),
  ('grande cimenterie du katanga|\mgck\M', 'Grande Cimenterie du Katanga - Kakontwe', 'Haut-Katanga', 'Likasi', null, 'GCK(2011, Kakontwe) 석회석 채석·석회·시멘트 — Gécamines·HMIE·West China Cement 관계, 구 Gécamines 시설 기반.', 'Grande Cimenterie du Katanga (GCK, 2011), Kakontwe near Likasi - limestone quarry, lime and cement built on former Gécamines assets, linked to Gécamines, HMIE and West China Cement.', 'CD check 2026-10-16: lime and stone lead only. Not added: ABICOM (mining chemicals distributor, 85-95 pct CaCO3), PPC Barnet DRC (Kongo Central cement, up to 1.25 Mt). No Congolese paper PCC or GCC. Screen against UN and US DR Congo sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'drc_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('JDE DRC - Lubumbashi', 'Limestone grinder', 'Coarse limestone powder - raw-material lead', 'merchant', 'C', 'gcc'),
  ('Datong SARL - Lubumbashi', 'Limestone supplier', 'High-purity limestone claim - sample source', 'merchant', 'C', 'gcc'),
  ('Grande Cimenterie du Katanga - Kakontwe', 'Limestone owner (cement and lime)', 'Limestone and lime - raw-material lead', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'drc_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CD', v.region, v.city, v.website, 'active', 'drc_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('all pack industries', 'kinshasa|kingabwa|limete', 'all pack', 'All Pack Industries - Kinshasa', 'Kinshasa', 'Kinshasa', null, 'All Pack Industries(21 Av. des Brasseries, Kingabwa, Limete) 폐지 재활용 — 크라프트지·골판지·화장지 생산 소개, 문서 파쇄·재활용 서비스.', 'All Pack Industries, 21 Avenue des Brasseries, Kingabwa, Limete, Kinshasa - recycles waste paper and is described as making kraft paper, corrugated board and toilet paper, plus document shredding.', 'CD check 2026-10-16: own paper machine and output to confirm. +243 854 818 576. Screen against UN and US DR Congo sanctions lists.'),
  ('lani services', 'lubumbashi', 'lani', 'LANI Services - Lubumbashi', 'Haut-Katanga', 'Lubumbashi', null, 'LANI Services(Lubumbashi, 대표 Immaculée Ndombi) 화장지·냅킨·미용티슈·키친타월, OEM 가능, D&B 추정 매출 약 623만 달러.', 'LANI Services SARL, Lubumbashi (led by Immaculée Ndombi) - toilet paper, napkins, facial tissue, towels for retail, hotels and firms, private label offered, D&B sales estimate about USD 6.23 m.', 'CD check 2026-10-16: tissue machine or jumbo-roll converting to confirm. +243 975 304 990. Screen against UN and US DR Congo sanctions lists.'),
  ('nduw', 'kolwezi', 'nduw', 'Nduw''s Family - Kolwezi', 'Lualaba', 'Kolwezi', null, 'Nduw''s Family(Kolwezi) 100% 재생지 티슈 제조 — 2025-02 산업부 장관 방문(ACP).', 'Nduw''s Family, Kolwezi (Lualaba) - tissue made of 100 pct recovered paper, visited by the industry minister 2025-02 (ACP).', 'CD check 2026-10-16: machine type and output not public. Screen against UN and US DR Congo sanctions lists.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('all pack industries', 'kinshasa|kingabwa|limete', 'all pack', 'All Pack Industries(21 Av. des Brasseries, Kingabwa, Limete) 폐지 재활용 — 크라프트지·골판지·화장지 생산 소개, 문서 파쇄·재활용 서비스.', 'All Pack Industries, 21 Avenue des Brasseries, Kingabwa, Limete, Kinshasa - recycles waste paper and is described as making kraft paper, corrugated board and toilet paper, plus document shredding.', 'CD check 2026-10-16: own paper machine and output to confirm. +243 854 818 576. Screen against UN and US DR Congo sanctions lists.'),
  ('lani services', 'lubumbashi', 'lani', 'LANI Services(Lubumbashi, 대표 Immaculée Ndombi) 화장지·냅킨·미용티슈·키친타월, OEM 가능, D&B 추정 매출 약 623만 달러.', 'LANI Services SARL, Lubumbashi (led by Immaculée Ndombi) - toilet paper, napkins, facial tissue, towels for retail, hotels and firms, private label offered, D&B sales estimate about USD 6.23 m.', 'CD check 2026-10-16: tissue machine or jumbo-roll converting to confirm. +243 975 304 990. Screen against UN and US DR Congo sanctions lists.'),
  ('nduw', 'kolwezi', 'nduw', 'Nduw''s Family(Kolwezi) 100% 재생지 티슈 제조 — 2025-02 산업부 장관 방문(ACP).', 'Nduw''s Family, Kolwezi (Lualaba) - tissue made of 100 pct recovered paper, visited by the industry minister 2025-02 (ACP).', 'CD check 2026-10-16: machine type and output not public. Screen against UN and US DR Congo sanctions lists.'),
  ('african paper ?& ?pulp|\mappi\M', null, 'african paper ?& ?pulp|\mappi\M', null, null, 'CD check 2026-10-16: APPI, 8ème Rue Limete Kinshasa - Special toilet paper, Be Free hygiene, water - machine not confirmed - context only. Screen against UN and US DR Congo sanctions lists.'),
  ('bopeto', null, 'bopeto', null, null, 'CD check 2026-10-16: BOPETO, Gombe Kinshasa - tissue, napkins, wipes - context only. Screen against UN and US DR Congo sanctions lists.'),
  ('cpack|congo store', null, 'cpack|congo store', null, null, 'CD check 2026-10-16: cPack, Kinshasa - 3 and 5-ply corrugated boxes, flexo printing - context only. Screen against UN and US DR Congo sanctions lists.'),
  ('\mwrite sarl', null, '\mwrite sarl', null, null, 'CD check 2026-10-16: WRITE SARL, Goma - listed in paper industry, details unknown - context only. Screen against UN and US DR Congo sanctions lists.'),
  ('ebenezer', null, 'ebenezer', null, null, 'CD check 2026-10-16: EBENEZER - planned paper mill at Maluku SEZ (2022 claim of 150 kt/month - unverified) - context only. Screen against UN and US DR Congo sanctions lists.'),
  ('\mmpc sas|instaprint|lubum link', null, '\mmpc sas|instaprint|lubum link', null, null, 'CD check 2026-10-16: MPC SAS, Instaprint, Lubum Link - D&B paper-sector listings, machines unknown - context only. Screen against UN and US DR Congo sanctions lists.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'drc_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('all pack industries', 'kinshasa|kingabwa|limete', 'all pack'),
  ('lani services', 'lubumbashi', 'lani'),
  ('nduw', 'kolwezi', 'nduw'),
  ('african paper ?& ?pulp|\mappi\M', null, 'african paper ?& ?pulp|\mappi\M'),
  ('bopeto', null, 'bopeto'),
  ('cpack|congo store', null, 'cpack|congo store'),
  ('\mwrite sarl', null, '\mwrite sarl'),
  ('ebenezer', null, 'ebenezer'),
  ('\mmpc sas|instaprint|lubum link', null, '\mmpc sas|instaprint|lubum link')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('all pack industries', 'kinshasa|kingabwa|limete', 'all pack', false,
   $pj${"owner": "All Pack Industries", "products": "Recycled kraft, corrugated, tissue (to confirm)", "grades": ["Kraft paper", "Tissue"], "approach": "Confirm paper machine first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lani services', 'lubumbashi', 'lani', false,
   $pj${"owner": "LANI Services", "products": "Tissue products", "grades": ["Tissue"], "approach": "Confirm machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nduw', 'kolwezi', 'nduw', false,
   $pj${"owner": "Nduw's Family", "products": "Recycled tissue", "grades": ["Tissue"], "approach": "Confirm wet-end process.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('african paper ?& ?pulp|\mappi\M', null, 'african paper ?& ?pulp|\mappi\M', true,
   $pj${"owner": "APPI", "products": "APPI, 8ème Rue Limete Kinshasa - Special toilet paper, Be Free hygiene, water - machine not confirmed", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bopeto', null, 'bopeto', true,
   $pj${"owner": "BOPETO", "products": "BOPETO, Gombe Kinshasa - tissue, napkins, wipes", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cpack|congo store', null, 'cpack|congo store', true,
   $pj${"owner": "Congo Store", "products": "cPack, Kinshasa - 3 and 5-ply corrugated boxes, flexo printing", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mwrite sarl', null, '\mwrite sarl', true,
   $pj${"owner": "WRITE", "products": "WRITE SARL, Goma - listed in paper industry, details unknown", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ebenezer', null, 'ebenezer', true,
   $pj${"owner": "EBENEZER", "products": "EBENEZER - planned paper mill at Maluku SEZ (2022 claim of 150 kt/month - unverified)", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mmpc sas|instaprint|lubum link', null, '\mmpc sas|instaprint|lubum link', true,
   $pj${"owner": "D&B listings", "products": "MPC SAS, Instaprint, Lubum Link - D&B paper-sector listings, machines unknown", "approach": "Converter or project.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CD', 'DR Congo', 'none',
   $cm$No confirmed paper machine - recycled kraft and tissue claims (All Pack, LANI, Nduw's Family) - Katanga limestone (JDE, Datong, GCK) - sanctions screening$cm$,
   $cm$DR Congo produced about 3 kt paper and board in 2019 (FAO) with about 13 kt imported. Firms making paper products: All Pack Industries Kinshasa (says it makes recycled kraft, corrugated and tissue), LANI Services Lubumbashi (tissue), Nduw's Family Kolwezi (100 pct recycled tissue), plus APPI, BOPETO (tissue) and cPack (corrugated) - none with a confirmed paper machine. EBENEZER's Maluku mill plan (2022) is unverified. A 2026-05 measure extended limits on tissue imports in the west. No paper PCC or GCC: JDE (75 micron limestone powder), Datong (98 pct claim), GCK Kakontwe, PPC Barnet cement.$cm$,
   $cm${"fillers": "Limestone: JDE, Datong, GCK. Not added: ABICOM, PPC Barnet. No PCC or GCC.", "mills": "To confirm: All Pack Industries, LANI Services, Nduw's Family. Context: APPI, BOPETO, cPack, WRITE, EBENEZER (plan), D&B listings.", "strategy": "Confirm machines at All Pack and LANI. Tissue import limits may push local base-paper investment.", "risks": "Security, sanctions screening, logistics, no verified data.", "next_steps": ["Ask All Pack Industries about its paper machine"], "key_numbers": [{"label": "Paper and board output 2019", "value": "about 3 kt"}, {"label": "Imports 2019", "value": "about 13 kt"}], "files": ["seed_20261016zzzr_drc_mills_fillers"]}$cm$::jsonb,
   $cm$초지기 미확인 — 재생 크라프트·티슈 주장(All Pack, LANI, Nduw's Family) — 카탕가 석회석(JDE, Datong, GCK) — 제재 확인$cm$,
   $cm$콩고민주공화국 종이·판지 생산 2019 약 3천 t(FAO), 수입 약 1.3만 t. 종이제품 업체: All Pack Industries 킨샤사(재생 크라프트·골판지·화장지 생산 주장), LANI Services 루붐바시(티슈), Nduw's Family 콜웨지(100% 재생 티슈), APPI·BOPETO(티슈), cPack(골판지) — 초지기 확인된 곳 없음. EBENEZER Maluku 계획(2022)은 미검증. 2026-05 서부 티슈 수입 제한 연장. 제지용 PCC·GCC 없음: JDE(75 μm 석회석 분말), Datong(98% 주장), GCK Kakontwe, PPC Barnet 시멘트.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('all pack industries', 'kinshasa|kingabwa|limete', 'all pack'),
  ('lani services', 'lubumbashi', 'lani'),
  ('nduw', 'kolwezi', 'nduw'),
  ('african paper ?& ?pulp|\mappi\M', null, 'african paper ?& ?pulp|\mappi\M'),
  ('bopeto', null, 'bopeto'),
  ('cpack|congo store', null, 'cpack|congo store'),
  ('\mwrite sarl', null, '\mwrite sarl'),
  ('ebenezer', null, 'ebenezer'),
  ('\mmpc sas|instaprint|lubum link', null, '\mmpc sas|instaprint|lubum link')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'drc_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'drc_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\mjde\M.*(drc|congo)|jde group' or p.party_name ~* 'datong' or p.party_name ~* 'grande cimenterie du katanga|\mgck\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CD'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CD'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CD'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    