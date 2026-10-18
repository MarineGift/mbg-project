-- ============================================================
-- seed_20261016zzs_tunisia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Tunisia update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (5): SOFAP, HERMESS (STICC), STPM, MBS, SOCHEM.
-- 2) Mills if missing (2) + plant blocks: Azur Papier (1), SOTIPAPIER (2).
--    Context (4): SAH / Lilas, Cartonnerie Tunisienne, SITPEC, Yamama.
-- 3) app.country_markets TN row (priority low).
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
           v.party_name, 'TN', v.region, v.city, v.website, 'active', 'tunisia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('sofap', 'SOFAP - Sfax', 'Sfax', 'Sfax', null, 'SOFAP(1981, Sfax) 분쇄 탄산칼슘·백악·광물 충전제 — Gabès 자체 채석장, 용도에 종이 명시, 연 약 25만~35만 t(페이지별 상이), 알제리·모로코·세네갈 수출.', 'SOFAP (Société de Fabrication de Poudre, 1981), Sfax - ground calcium carbonate, chalk and mineral fillers of its own Gabès quarry, paper named among uses, about 250,000-350,000 t/yr (figures differ by page), exports to Algeria, Morocco, Senegal.', 'TN check 2026-10-16: mill supply and wet slurry to confirm. contact@sofap-poudre.com, +216 74 453 983. FCC co-production candidate 1.'),
  ('hermess|sticc', 'HERMESS Carbonate de Calcium - Feriana', 'Kasserine', 'Feriana', null, 'HERMESS(Feriana) 자체 채석장 고순도 GCC — HERMACARB 3FN: CaCO3 99.92%·평균 4 μm·2 μm 이하 30%·L 97, 15FN: 12 μm·12%·L 96.', 'HERMESS Carbonate de Calcium, Feriana (Kasserine) - high-purity GCC of its own quarry: HERMACARB 3FN 99.92 pct CaCO3, mean 4 micron, 30 pct under 2 micron, L 97, and 15FN mean 12 micron, 12 pct under 2 micron, L 96.', 'TN check 2026-10-16: PSD and paper trials needed. +216 36 404 520 - same number as STICC in directories, check the link.'),
  ('\mstpm\M', 'STPM - Sidi Bouzid', 'Sidi Bouzid', 'Sidi Bouzid', null, 'STPM(2011) Jbel El Kbar 석회석 채굴·분쇄 GCC — Perle 3·5·10·15.', 'STPM (Société Tunisienne des Produits Minéraux, 2011), Sidi Bouzid - limestone of Jbel El Kbar ground as GCC Perle 3, 5, 10 and 15, high purity and whiteness claimed.', 'TN check 2026-10-16: PSD and capacity to confirm. +216 22 590 533.'),
  ('min[eé]raux broy[eé]s du sud|\mmbs\M.*(gab|tunis)|mbs-hf', 'MBS Minéraux Broyés du Sud - Gabès', 'Gabès', 'Gabès', null, 'Hamdi Frères 계열 MBS(2004, Gabès) 탄산칼슘 분쇄 — 0~2 μm 표기, 현재는 100·200 μm 위주.', 'MBS Minéraux Broyés du Sud (Hamdi Frères group, 2004), Gabès - calcium carbonate grinding, 0-2 micron grade listed in the profile but the product site shows mainly 100 and 200 micron.', 'TN check 2026-10-16: confirm fine-grade output. contact@mbs-hf.com.'),
  ('sochem', 'SOCHEM - Gabès', 'Gabès', 'Ghannouch', null, 'SOCHEM(Ghannouch 산업단지) 탄산칼슘 충전제·플라스틱 컴파운드.', 'SOCHEM, Ghannouch industrial zone (Gabès) - calcium carbonate fillers and plastic compounds.', 'TN check 2026-10-16: plastics focus. contact@sochem.com.tn. No Tunisian paper PCC or satellite found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TN check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('sofap', 'SOFAP - Sfax', 'Sfax', 'Sfax', null, 'SOFAP(1981, Sfax) 분쇄 탄산칼슘·백악·광물 충전제 — Gabès 자체 채석장, 용도에 종이 명시, 연 약 25만~35만 t(페이지별 상이), 알제리·모로코·세네갈 수출.', 'SOFAP (Société de Fabrication de Poudre, 1981), Sfax - ground calcium carbonate, chalk and mineral fillers of its own Gabès quarry, paper named among uses, about 250,000-350,000 t/yr (figures differ by page), exports to Algeria, Morocco, Senegal.', 'TN check 2026-10-16: mill supply and wet slurry to confirm. contact@sofap-poudre.com, +216 74 453 983. FCC co-production candidate 1.'),
  ('hermess|sticc', 'HERMESS Carbonate de Calcium - Feriana', 'Kasserine', 'Feriana', null, 'HERMESS(Feriana) 자체 채석장 고순도 GCC — HERMACARB 3FN: CaCO3 99.92%·평균 4 μm·2 μm 이하 30%·L 97, 15FN: 12 μm·12%·L 96.', 'HERMESS Carbonate de Calcium, Feriana (Kasserine) - high-purity GCC of its own quarry: HERMACARB 3FN 99.92 pct CaCO3, mean 4 micron, 30 pct under 2 micron, L 97, and 15FN mean 12 micron, 12 pct under 2 micron, L 96.', 'TN check 2026-10-16: PSD and paper trials needed. +216 36 404 520 - same number as STICC in directories, check the link.'),
  ('\mstpm\M', 'STPM - Sidi Bouzid', 'Sidi Bouzid', 'Sidi Bouzid', null, 'STPM(2011) Jbel El Kbar 석회석 채굴·분쇄 GCC — Perle 3·5·10·15.', 'STPM (Société Tunisienne des Produits Minéraux, 2011), Sidi Bouzid - limestone of Jbel El Kbar ground as GCC Perle 3, 5, 10 and 15, high purity and whiteness claimed.', 'TN check 2026-10-16: PSD and capacity to confirm. +216 22 590 533.'),
  ('min[eé]raux broy[eé]s du sud|\mmbs\M.*(gab|tunis)|mbs-hf', 'MBS Minéraux Broyés du Sud - Gabès', 'Gabès', 'Gabès', null, 'Hamdi Frères 계열 MBS(2004, Gabès) 탄산칼슘 분쇄 — 0~2 μm 표기, 현재는 100·200 μm 위주.', 'MBS Minéraux Broyés du Sud (Hamdi Frères group, 2004), Gabès - calcium carbonate grinding, 0-2 micron grade listed in the profile but the product site shows mainly 100 and 200 micron.', 'TN check 2026-10-16: confirm fine-grade output. contact@mbs-hf.com.'),
  ('sochem', 'SOCHEM - Gabès', 'Gabès', 'Ghannouch', null, 'SOCHEM(Ghannouch 산업단지) 탄산칼슘 충전제·플라스틱 컴파운드.', 'SOCHEM, Ghannouch industrial zone (Gabès) - calcium carbonate fillers and plastic compounds.', 'TN check 2026-10-16: plastics focus. contact@sochem.com.tn. No Tunisian paper PCC or satellite found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'tunisia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('SOFAP - Sfax', 'GCC producer', 'GCC with paper named, North Africa exports - candidate 1', 'merchant', 'B', 'gcc'),
  ('HERMESS Carbonate de Calcium - Feriana', 'GCC producer', 'High-purity GCC with specs - raw-material partner', 'merchant', 'B', 'gcc'),
  ('STPM - Sidi Bouzid', 'GCC producer', 'GCC range - raw-material partner', 'merchant', 'C', 'gcc'),
  ('MBS Minéraux Broyés du Sud - Gabès', 'GCC producer', 'Carbonate grinding - fine grade to confirm', 'merchant', 'C', 'gcc'),
  ('SOCHEM - Gabès', 'GCC producer', 'Plastics filler - second-line', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'tunisia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'TN', v.region, v.city, v.website, 'active', 'tunisia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('azur papier', 'zriba|zaghouan', 'azur|sah|lilas', 'Azur Papier - Zriba', 'Zaghouan', 'Zriba', null, 'SAH(Lilas) 그룹 티슈 원지 Azur Papier(2009 설립·2013 가동) — PM1 80 t/일(2013)·PM2 115 t/일·1,800 m/분(2021-02, Recard), 2024 생산 약 5.5만 t, 2022 수출 2.5만 t+(53%). Metsä Fibre 장기 펄프 공급. 3호기(연 8만 t) 계획.', 'Azur Papier (SAH / Lilas group, founded 2009, running 2013), Zriba (Zaghouan) - tissue base paper on PM1 (80 t/day, 2013) and PM2 (115 t/day, 1,800 m/min, 2021-02, both Recard), virgin and recycled pulp, about 55,000 t produced in 2024, over 25,000 t exported in 2022 (53 pct). Long-term pulp supplier Metsä Fibre. Third line of about 80,000 t/yr planned.', 'TN check 2026-10-16: third line status unknown. +216 71 809 222.'),
  ('sotipapier', 'belli|nabeul', 'sotipapier', 'SOTIPAPIER - Belli', 'Nabeul', 'Belli', null, 'SOTIPAPIER(1981, Belli Nabeul) — PM2 Kraft bag 5만 t(Shoe press·Sizer) + PM3 Fluting·Testliner 3만 t = 8만 t.', 'SOTIPAPIER (1981, listed), Belli Village, Nabeul - PM2 kraft bag and packaging paper 50,000 t/yr (shoe press, sizer) and PM3 fluting and testliner 30,000 t/yr, 80,000 t/yr total.', 'TN check 2026-10-16: strength-led. +216 72 200 120, relation.investisseurs@sotipapier.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TN check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('azur papier', 'zriba|zaghouan', 'azur|sah|lilas', 'SAH(Lilas) 그룹 티슈 원지 Azur Papier(2009 설립·2013 가동) — PM1 80 t/일(2013)·PM2 115 t/일·1,800 m/분(2021-02, Recard), 2024 생산 약 5.5만 t, 2022 수출 2.5만 t+(53%). Metsä Fibre 장기 펄프 공급. 3호기(연 8만 t) 계획.', 'Azur Papier (SAH / Lilas group, founded 2009, running 2013), Zriba (Zaghouan) - tissue base paper on PM1 (80 t/day, 2013) and PM2 (115 t/day, 1,800 m/min, 2021-02, both Recard), virgin and recycled pulp, about 55,000 t produced in 2024, over 25,000 t exported in 2022 (53 pct). Long-term pulp supplier Metsä Fibre. Third line of about 80,000 t/yr planned.', 'TN check 2026-10-16: third line status unknown. +216 71 809 222.'),
  ('sotipapier', 'belli|nabeul', 'sotipapier', 'SOTIPAPIER(1981, Belli Nabeul) — PM2 Kraft bag 5만 t(Shoe press·Sizer) + PM3 Fluting·Testliner 3만 t = 8만 t.', 'SOTIPAPIER (1981, listed), Belli Village, Nabeul - PM2 kraft bag and packaging paper 50,000 t/yr (shoe press, sizer) and PM3 fluting and testliner 30,000 t/yr, 80,000 t/yr total.', 'TN check 2026-10-16: strength-led. +216 72 200 120, relation.investisseurs@sotipapier.com.'),
  ('\msah\M|lilas', null, '\msah\M|lilas', null, null, 'TN check 2026-10-16: Lilas hygiene products (converting and sales, 1994) - base paper by Azur Papier - context only.'),
  ('cartonnerie tunisienne', null, 'cartonnerie tunisienne', null, null, 'TN check 2026-10-16: Board and paper products - process to confirm - context only.'),
  ('sitpec', null, 'sitpec', null, null, 'TN check 2026-10-16: Notebooks, stationery, printing - context only.'),
  ('yamama', null, 'yamama', null, null, 'TN check 2026-10-16: Paper and board converting - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'tunisia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('azur papier', 'zriba|zaghouan', 'azur|sah|lilas'),
  ('sotipapier', 'belli|nabeul', 'sotipapier'),
  ('\msah\M|lilas', null, '\msah\M|lilas'),
  ('cartonnerie tunisienne', null, 'cartonnerie tunisienne'),
  ('sitpec', null, 'sitpec'),
  ('yamama', null, 'yamama')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('azur papier', 'zriba|zaghouan', 'azur|sah|lilas', false,
   $pj${"owner": "SAH Group", "priority": 1, "products": "Tissue base paper", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 55000, "unit": "metric_t", "year": "Output 2024", "source": "metsagroup.com"}, "capacity_split": [{"label": "PM3 plan", "value_t": 80000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "pitch": "Azur Papier + SOFAP / HERMESS GCC + MBG", "approach": "Lead North-Africa tissue account - SAH R&D and purchasing.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sotipapier', 'belli|nabeul', 'sotipapier', false,
   $pj${"owner": "SOTIPAPIER", "priority": 2, "products": "Kraft bag paper, fluting, testliner", "grades": ["Sack kraft", "Medium", "Testliner"], "machines": 2, "capacity": {"value": 80000, "unit": "metric_t", "year": "Company figure", "source": "sotipapier.com"}, "capacity_split": [{"label": "PM2 kraft", "value_t": 50000}, {"label": "PM3 fluting / testliner", "value_t": 30000}], "approach": "Low-dose strength trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\msah\M|lilas', null, '\msah\M|lilas', true,
   $pj${"owner": "SAH Group", "products": "Lilas hygiene products (converting and sales, 1994) - base paper by Azur Papier", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartonnerie tunisienne', null, 'cartonnerie tunisienne', true,
   $pj${"owner": "UTIC Group", "products": "Board and paper products - process to confirm", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sitpec', null, 'sitpec', true,
   $pj${"owner": "SITPEC", "products": "Notebooks, stationery, printing", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('yamama', null, 'yamama', true,
   $pj${"owner": "Groupe Yamama", "products": "Paper and board converting", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TN', 'Tunisia', 'low',
   $cm$Azur Papier tissue (55 kt, SAH / Lilas) and SOTIPAPIER kraft and liner (80 kt) - SOFAP and HERMESS GCC - no paper PCC$cm$,
   $cm$Tunisia's base paper: Azur Papier at Zriba (SAH / Lilas group tissue, two Recard machines, about 55 kt in 2024, half exported, third line planned) and SOTIPAPIER at Belli (kraft bag 50 kt plus fluting and testliner 30 kt). Converters: SAH, Cartonnerie Tunisienne, SITPEC, Yamama. Fillers: SOFAP Sfax (GCC with paper named, 250-350 kt, African exports), HERMESS Feriana (99.92 pct, 3FN mean 4 micron), STPM, MBS, SOCHEM. No paper PCC.$cm$,
   $cm${"fillers": "GCC: SOFAP, HERMESS (STICC link), STPM, MBS, SOCHEM. No PCC.", "mills": "Tissue: Azur Papier. Kraft and liner: SOTIPAPIER. Context: SAH / Lilas, Cartonnerie Tunisienne, SITPEC, Yamama.", "strategy": "Azur Papier tissue trial (SAH approval), then local GCC partner (SOFAP or HERMESS) for a North-Africa FCC site serving Algeria and Morocco too.", "risks": "Small volumes, slurry freight south to north-east.", "next_steps": ["Propose a tissue trial to Azur Papier", "Request SOFAP and HERMESS TDS and PSD"], "key_numbers": [{"label": "Azur Papier 2024", "value": "about 55 kt tissue"}, {"label": "SOTIPAPIER", "value": "80 kt (50 + 30)"}], "files": ["seed_20261016zzs_tunisia_mills_fillers"]}$cm$::jsonb,
   $cm$Azur Papier 티슈(5.5만 t, SAH/Lilas)·SOTIPAPIER 크라프트·라이너(8만 t) — SOFAP·HERMESS GCC — 제지용 PCC 없음$cm$,
   $cm$튀니지 원지: Azur Papier Zriba(SAH/Lilas 그룹 티슈, Recard 2대, 2024 약 5.5만 t, 절반 수출, 3호기 계획), SOTIPAPIER Belli(크라프트 백 5만 + 골심지·라이너 3만 t). 가공: SAH, Cartonnerie Tunisienne, SITPEC, Yamama. 충전제: SOFAP Sfax(제지 용도 명시, 25만~35만 t, 아프리카 수출), HERMESS Feriana(99.92%, 3FN 평균 4 μm), STPM, MBS, SOCHEM. 제지용 PCC 없음.$cm$,
   1650, 3550,
   $cm$Azur 5.5만 t × 3~5% + SOTIPAPIER 8만 t × 0~1%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('azur papier', 'zriba|zaghouan', 'azur|sah|lilas'),
  ('sotipapier', 'belli|nabeul', 'sotipapier'),
  ('\msah\M|lilas', null, '\msah\M|lilas'),
  ('cartonnerie tunisienne', null, 'cartonnerie tunisienne'),
  ('sitpec', null, 'sitpec'),
  ('yamama', null, 'yamama')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'tunisia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'tunisia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'sofap' or p.party_name ~* 'hermess|sticc' or p.party_name ~* '\mstpm\M' or p.party_name ~* 'min[eé]raux broy[eé]s du sud|\mmbs\M.*(gab|tunis)|mbs-hf' or p.party_name ~* 'sochem')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TN'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TN'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TN'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    