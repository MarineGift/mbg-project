-- ============================================================
-- seed_20261016zzy_kenya_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Kenya update (reports 2026-10-16). Fixed generator.
-- Several Nairobi mills - owner regex keeps them apart.
-- 1) Fillers if missing (4): Mineral Enterprises (MELWIT), Kiki's, Dalit,
--    Sanvil.
-- 2) Mills if missing (8) + plant blocks, priority 1-7: Chandaria, Kenturian,
--    Kim-Fay, Transafrica, Rai Paper, EAPM, Mega Paper. Fortuna no
--    priority. Context (2): Cots, Jubilee Tissue.
-- 3) app.country_markets KE row (priority low).
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
           v.party_name, 'KE', v.region, v.city, v.website, 'active', 'kenya_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('mineral enterprises|melwit', 'Mineral Enterprises (MELWIT) - Athi River', 'Machakos', 'Athi River', null, 'MEL(1991~, Mzee Paunrana Rd, Athi River) — Kajiado 원료·Athi River 분쇄·포장, MELWIT 초미세 GCC(알칼리 초지 충전), 티슈용 미세 GCC, KAOMEL 카올린, DOLOMEL.', 'Mineral Enterprises Limited (since 1991), Mzee Paunrana Road, Athi River - carbonate ore of Kajiado County ground and packed at Athi River: MELWIT ultrafine GCC for alkaline papermaking, fine GCC for tissue, KAOMEL kaolin for paper filling, DOLOMEL dolomite.', 'KE check 2026-10-16: capacity and mill customers not public. +254 20 2047000. FCC co-production candidate 1 for East Africa.'),
  ('kiki.?s industrial', 'Kiki''s Industrial Chemicals - Nairobi', 'Nairobi', 'Nairobi', null, 'Kiki''s(나이로비 산업지역) 미분·코팅 GCC 400/600/1000 mesh, 초미세 사양 CaCO3 99%+·ISO 97%+·D50 1.2~2.0 μm·D98 5 μm 이하(웹 표시), 동아프리카 공급.', 'Kiki''s Industrial Chemicals Ltd, Nairobi Industrial Area - micronised and coated GCC 400, 600, 1000 mesh, ultrafine listing at over 99 pct CaCO3, ISO brightness over 97, D50 1.2-2.0 micron, D98 5 micron or less, Fe2O3 0.03 pct (website, out of stock when checked), supplies Uganda, Tanzania, Ethiopia.', 'KE check 2026-10-16: own mill and slurry to verify. +254 713 002 961.'),
  ('dalit', 'Dalit Chemical Solutions', 'Kenya', null, null, 'Dalit Chemical Solutions GCC·PCC 공급(제지 충전·코팅) — 제조 미확인.', 'Dalit Chemical Solutions - offers GCC and PCC for paper filling and coating in Kenya, no own reactor confirmed.', 'KE check 2026-10-16: distribution channel.'),
  ('sanvil', 'Sanvil Industries', 'Kenya', null, null, 'Sanvil Industries 산업용 CaCO3(98%+) 소포장~벌크, 케냐·우간다·탄자니아.', 'Sanvil Industries Ltd - industrial CaCO3 over 98 pct, small packs to bulk, Kenya, Uganda, Tanzania.', 'KE check 2026-10-16: paper grade and plant unknown. Not added: Innova (Indian PCC exporter), Karanwal (IN). No Kenyan paper PCC plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%KE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('mineral enterprises|melwit', 'Mineral Enterprises (MELWIT) - Athi River', 'Machakos', 'Athi River', null, 'MEL(1991~, Mzee Paunrana Rd, Athi River) — Kajiado 원료·Athi River 분쇄·포장, MELWIT 초미세 GCC(알칼리 초지 충전), 티슈용 미세 GCC, KAOMEL 카올린, DOLOMEL.', 'Mineral Enterprises Limited (since 1991), Mzee Paunrana Road, Athi River - carbonate ore of Kajiado County ground and packed at Athi River: MELWIT ultrafine GCC for alkaline papermaking, fine GCC for tissue, KAOMEL kaolin for paper filling, DOLOMEL dolomite.', 'KE check 2026-10-16: capacity and mill customers not public. +254 20 2047000. FCC co-production candidate 1 for East Africa.'),
  ('kiki.?s industrial', 'Kiki''s Industrial Chemicals - Nairobi', 'Nairobi', 'Nairobi', null, 'Kiki''s(나이로비 산업지역) 미분·코팅 GCC 400/600/1000 mesh, 초미세 사양 CaCO3 99%+·ISO 97%+·D50 1.2~2.0 μm·D98 5 μm 이하(웹 표시), 동아프리카 공급.', 'Kiki''s Industrial Chemicals Ltd, Nairobi Industrial Area - micronised and coated GCC 400, 600, 1000 mesh, ultrafine listing at over 99 pct CaCO3, ISO brightness over 97, D50 1.2-2.0 micron, D98 5 micron or less, Fe2O3 0.03 pct (website, out of stock when checked), supplies Uganda, Tanzania, Ethiopia.', 'KE check 2026-10-16: own mill and slurry to verify. +254 713 002 961.'),
  ('dalit', 'Dalit Chemical Solutions', 'Kenya', null, null, 'Dalit Chemical Solutions GCC·PCC 공급(제지 충전·코팅) — 제조 미확인.', 'Dalit Chemical Solutions - offers GCC and PCC for paper filling and coating in Kenya, no own reactor confirmed.', 'KE check 2026-10-16: distribution channel.'),
  ('sanvil', 'Sanvil Industries', 'Kenya', null, null, 'Sanvil Industries 산업용 CaCO3(98%+) 소포장~벌크, 케냐·우간다·탄자니아.', 'Sanvil Industries Ltd - industrial CaCO3 over 98 pct, small packs to bulk, Kenya, Uganda, Tanzania.', 'KE check 2026-10-16: paper grade and plant unknown. Not added: Innova (Indian PCC exporter), Karanwal (IN). No Kenyan paper PCC plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'kenya_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Mineral Enterprises (MELWIT) - Athi River', 'GCC producer', 'Paper and tissue GCC named - candidate 1', 'merchant', 'B', 'gcc'),
  ('Kiki''s Industrial Chemicals - Nairobi', 'GCC producer', 'Ultrafine GCC claim - second candidate', 'merchant', 'C', 'gcc'),
  ('Dalit Chemical Solutions', 'GCC and PCC supplier', 'PCC and GCC supply channel', 'merchant', 'C', 'pcc'),
  ('Sanvil Industries', 'Carbonate supplier', 'Industrial carbonate supply', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'kenya_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'KE', v.region, v.city, v.website, 'active', 'kenya_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('chandaria', 'nairobi', 'chandaria', 'Chandaria Industries - Nairobi', 'Nairobi', 'Nairobi', null, 'Chandaria(1964) 폐지 회수·재생 원료·티슈 제조·가공 — Velvex·Nice & Soft·Toilex·Rosy·Dawn Pekee, 동·중앙아프리카.', 'Chandaria Industries (1964), Nairobi - integrated recycled tissue: waste-paper collection, recycled fibre, tissue making and converting (Velvex, Nice and Soft, Toilex, Rosy, Dawn Pekee), East and Central Africa.', 'KE check 2026-10-16: tonnage not public. info@chandaria.com.'),
  ('kenturian', 'kisaju', 'kenturian', 'Kenturian Pulp & Paper - Kisaju', 'Kajiado', 'Kisaju', null, 'Kenturian(Kisaju) 티슈·크라프트 — 18~19 gsm 재생 티슈 점보롤 우간다 수출, 2026 초지 부품 수입 기록.', 'Kenturian Pulp and Paper Mills, Kisaju - tissue and kraft paper, exports 18-19 gsm recycled tissue jumbo rolls to Uganda, paper-machine parts imported in 2026.', 'KE check 2026-10-16: capacity not public.'),
  ('kim.?fay', 'nairobi|tatu', 'kim.?fay', 'Kim-Fay East Africa - Nairobi / Tatu City', 'Nairobi', 'Nairobi', null, 'Kim-Fay(Fay) 위생지 — 2024 Norfund·I&M 지원 Tatu City 재생지 티슈 공장(약 KSh 25억, 2025 가동 목표).', 'Kim-Fay East Africa, Maasai Road, Nairobi - Fay toilet, facial, napkin and kitchen tissue. New recycled-fibre tissue mill at Tatu City (Kiambu) funded with Norfund and I and M Bank (about KSh 2.5 bn, start targeted 2025).', 'KE check 2026-10-16: Tatu City status to confirm. customercare@kimfay.com.'),
  ('transafrica', 'nairobi', 'transafrica', 'Transafrica Paper Mills - Nairobi', 'Nairobi', 'Nairobi', null, 'Transafrica(Lunga Lunga Rd) 티슈 원지 — 폐지 재활용.', 'Transafrica Paper Mills, Lunga Lunga Road, Nairobi - tissue base paper of recovered paper.', 'KE check 2026-10-16: machine to confirm.'),
  ('rai paper|pan.?african paper|panpaper', 'webuye', 'rai|pan', 'Rai Paper (ex Pan African Paper Mills) - Webuye', 'Bungoma', 'Webuye', null, 'Rai Paper(구 Pan African Paper Mills, Webuye) — 2009 폐쇄 후 Rai Group 인수·단계 재가동, 2025 약 KSh 30억 재투자 보도. 과거 연 11만 t(UNIDO).', 'Rai Paper (former Pan African Paper Mills), Webuye (Bungoma) - closed 2009, bought by Rai Group and restarted in stages, about KSh 3 bn reinvestment reported 2025. Historic 110,000 t/yr capacity (UNIDO) is not today.', 'KE check 2026-10-16: running machines and grades to confirm.'),
  ('east african paper|\meapm\M', 'thika', 'east african|eapm', 'East African Paper Mills - Thika', 'Kiambu', 'Thika', null, 'EAPM(Factory St, Thika) Fluting·Testliner·크라프트.', 'East African Paper Mills Ltd, Factory Street, Thika - fluting, testliner and kraft paper.', 'KE check 2026-10-16: strength-led. info@eapm.co.ke.'),
  ('mega paper|mega spin', 'nakuru', 'mega', 'Mega Paper & Boards - Nakuru', 'Nakuru', 'Nakuru', null, 'Mega Paper & Boards(2015~) 연 3.6만 t, 폐지 월 약 2,000 t, 100~240 gsm 골판지원지.', 'Mega Paper and Boards (Mega Spin Group, running since 2015), Nakuru - 36,000 t/yr containerboard 100-240 gsm on about 2,000 t/month recovered paper.', 'KE check 2026-10-16: info@megaspingroup.com.'),
  ('fortuna', 'nairobi', 'fortuna', 'Fortuna Industries - Nairobi', 'Nairobi', 'Nairobi', null, 'Fortuna 티슈 점보롤.', 'Fortuna Industries, Nairobi - tissue jumbo rolls.', 'KE check 2026-10-16: details to collect.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%KE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('chandaria', 'nairobi', 'chandaria', 'Chandaria(1964) 폐지 회수·재생 원료·티슈 제조·가공 — Velvex·Nice & Soft·Toilex·Rosy·Dawn Pekee, 동·중앙아프리카.', 'Chandaria Industries (1964), Nairobi - integrated recycled tissue: waste-paper collection, recycled fibre, tissue making and converting (Velvex, Nice and Soft, Toilex, Rosy, Dawn Pekee), East and Central Africa.', 'KE check 2026-10-16: tonnage not public. info@chandaria.com.'),
  ('kenturian', 'kisaju', 'kenturian', 'Kenturian(Kisaju) 티슈·크라프트 — 18~19 gsm 재생 티슈 점보롤 우간다 수출, 2026 초지 부품 수입 기록.', 'Kenturian Pulp and Paper Mills, Kisaju - tissue and kraft paper, exports 18-19 gsm recycled tissue jumbo rolls to Uganda, paper-machine parts imported in 2026.', 'KE check 2026-10-16: capacity not public.'),
  ('kim.?fay', 'nairobi|tatu', 'kim.?fay', 'Kim-Fay(Fay) 위생지 — 2024 Norfund·I&M 지원 Tatu City 재생지 티슈 공장(약 KSh 25억, 2025 가동 목표).', 'Kim-Fay East Africa, Maasai Road, Nairobi - Fay toilet, facial, napkin and kitchen tissue. New recycled-fibre tissue mill at Tatu City (Kiambu) funded with Norfund and I and M Bank (about KSh 2.5 bn, start targeted 2025).', 'KE check 2026-10-16: Tatu City status to confirm. customercare@kimfay.com.'),
  ('transafrica', 'nairobi', 'transafrica', 'Transafrica(Lunga Lunga Rd) 티슈 원지 — 폐지 재활용.', 'Transafrica Paper Mills, Lunga Lunga Road, Nairobi - tissue base paper of recovered paper.', 'KE check 2026-10-16: machine to confirm.'),
  ('rai paper|pan.?african paper|panpaper', 'webuye', 'rai|pan', 'Rai Paper(구 Pan African Paper Mills, Webuye) — 2009 폐쇄 후 Rai Group 인수·단계 재가동, 2025 약 KSh 30억 재투자 보도. 과거 연 11만 t(UNIDO).', 'Rai Paper (former Pan African Paper Mills), Webuye (Bungoma) - closed 2009, bought by Rai Group and restarted in stages, about KSh 3 bn reinvestment reported 2025. Historic 110,000 t/yr capacity (UNIDO) is not today.', 'KE check 2026-10-16: running machines and grades to confirm.'),
  ('east african paper|\meapm\M', 'thika', 'east african|eapm', 'EAPM(Factory St, Thika) Fluting·Testliner·크라프트.', 'East African Paper Mills Ltd, Factory Street, Thika - fluting, testliner and kraft paper.', 'KE check 2026-10-16: strength-led. info@eapm.co.ke.'),
  ('mega paper|mega spin', 'nakuru', 'mega', 'Mega Paper & Boards(2015~) 연 3.6만 t, 폐지 월 약 2,000 t, 100~240 gsm 골판지원지.', 'Mega Paper and Boards (Mega Spin Group, running since 2015), Nakuru - 36,000 t/yr containerboard 100-240 gsm on about 2,000 t/month recovered paper.', 'KE check 2026-10-16: info@megaspingroup.com.'),
  ('fortuna', 'nairobi', 'fortuna', 'Fortuna 티슈 점보롤.', 'Fortuna Industries, Nairobi - tissue jumbo rolls.', 'KE check 2026-10-16: details to collect.'),
  ('cots paper', null, 'cots paper', null, null, 'KE check 2026-10-16: Waste-paper recycling (2018, KDC funded), moulded-pulp packaging plans - context only.'),
  ('jubilee tissue', null, 'jubilee tissue', null, null, 'KE check 2026-10-16: Toilet tissue and napkins converting, Nairobi - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'kenya_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('chandaria', 'nairobi', 'chandaria'),
  ('kenturian', 'kisaju', 'kenturian'),
  ('kim.?fay', 'nairobi|tatu', 'kim.?fay'),
  ('transafrica', 'nairobi', 'transafrica'),
  ('rai paper|pan.?african paper|panpaper', 'webuye', 'rai|pan'),
  ('east african paper|\meapm\M', 'thika', 'east african|eapm'),
  ('mega paper|mega spin', 'nakuru', 'mega'),
  ('fortuna', 'nairobi', 'fortuna'),
  ('cots paper', null, 'cots paper'),
  ('jubilee tissue', null, 'jubilee tissue')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('chandaria', 'nairobi', 'chandaria', false,
   $pj${"owner": "Chandaria", "priority": 1, "products": "Recycled tissue", "grades": ["Tissue"], "pitch": "MEL GCC + MBG FCC tissue trial", "approach": "Lead East Africa tissue account.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kenturian', 'kisaju', 'kenturian', false,
   $pj${"owner": "Kenturian", "priority": 2, "products": "Recycled tissue jumbo rolls, kraft", "grades": ["Tissue", "Kraft paper"], "approach": "Tissue base trial at 18-19 gsm.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kim.?fay', 'nairobi|tatu', 'kim.?fay', false,
   $pj${"owner": "Kim-Fay", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "approach": "Design FCC in the Tatu City line if early.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('transafrica', 'nairobi', 'transafrica', false,
   $pj${"owner": "Transafrica", "priority": 4, "products": "Tissue base paper", "grades": ["Tissue"], "approach": "Confirm machine, then trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rai paper|pan.?african paper|panpaper', 'webuye', 'rai|pan', false,
   $pj${"owner": "Rai Group", "priority": 5, "products": "Printing and packaging papers (lines to confirm)", "grades": ["UWF", "Kraft paper"], "approach": "If a P and W line runs - filler trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('east african paper|\meapm\M', 'thika', 'east african|eapm', false,
   $pj${"owner": "EAPM", "priority": 6, "products": "Fluting, testliner, kraft", "grades": ["Medium", "Testliner"], "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mega paper|mega spin', 'nakuru', 'mega', false,
   $pj${"owner": "Mega Spin Group", "priority": 7, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "capacity": {"value": 36000, "unit": "metric_t", "year": "Company figure", "source": "megaspingroup.com"}, "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fortuna', 'nairobi', 'fortuna', false,
   $pj${"owner": "Fortuna", "products": "Tissue jumbo rolls", "grades": ["Tissue"], "approach": "Details first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cots paper', null, 'cots paper', true,
   $pj${"owner": "Cots Paper and Board", "products": "Waste-paper recycling (2018, KDC funded), moulded-pulp packaging plans", "approach": "Converter or recycler.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jubilee tissue', null, 'jubilee tissue', true,
   $pj${"owner": "Jubilee Tissue", "products": "Toilet tissue and napkins converting, Nairobi", "approach": "Converter or recycler.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'KE', 'Kenya', 'low',
   $cm$East Africa tissue hub - Chandaria, Kenturian, Kim-Fay, Transafrica - Rai Paper Webuye restart, EAPM and Mega liner - MEL paper GCC at Athi River$cm$,
   $cm$Kenya has real tissue machines around Nairobi: Chandaria (integrated recycled tissue since 1964), Kenturian Kisaju (18-19 gsm recycled jumbo rolls, exports to Uganda), Kim-Fay (new Tatu City recycled tissue mill, about KSh 2.5 bn), Transafrica, Fortuna. Liner: East African Paper Mills Thika, Mega Paper and Boards Nakuru (36 kt). Rai Paper is restarting the former Pan African mill at Webuye (historic 110 kt). Fillers: Mineral Enterprises (MELWIT paper and tissue GCC, Athi River) and Kiki's (ultrafine GCC claim), plus suppliers Dalit and Sanvil. No paper PCC plant.$cm$,
   $cm${"fillers": "GCC: Mineral Enterprises (MELWIT), Kiki's. Supply: Dalit (GCC and PCC), Sanvil. No PCC.", "mills": "Tissue: Chandaria, Kenturian, Kim-Fay, Transafrica, Fortuna. Printing and packaging: Rai Paper Webuye. Liner: EAPM, Mega Paper. Context: Cots, Jubilee Tissue.", "strategy": "MEL GCC + MBG FCC tissue trials at Chandaria and Kenturian, early design talks with Kim-Fay Tatu City, check Rai P and W line. Then Uganda and Tanzania.", "risks": "Tonnages unpublished, company claims unverified.", "next_steps": ["Request MELWIT tissue-grade TDS", "Propose a tissue trial to Chandaria"], "key_numbers": [{"label": "Mega Paper", "value": "36 kt/yr"}, {"label": "Kim-Fay Tatu City", "value": "about KSh 2.5 bn"}], "files": ["seed_20261016zzy_kenya_mills_fillers"]}$cm$::jsonb,
   $cm$동아프리카 티슈 거점 — Chandaria·Kenturian·Kim-Fay·Transafrica — Rai Paper Webuye 재가동, EAPM·Mega 라이너 — Athi River MEL 제지용 GCC$cm$,
   $cm$케냐 나이로비 일대 실제 티슈 초지: Chandaria(1964~ 재생 티슈 일관), Kenturian Kisaju(18~19 gsm 재생 점보롤, 우간다 수출), Kim-Fay(Tatu City 신규 재생 티슈 공장 약 KSh 25억), Transafrica, Fortuna. 라이너: EAPM Thika, Mega Paper Nakuru(3.6만 t). Rai Paper 가 Webuye 구 Pan African 공장 재가동(과거 11만 t). 충전제: Mineral Enterprises(MELWIT 제지·티슈 GCC, Athi River), Kiki's(초미세 GCC 주장), 공급 Dalit·Sanvil. 제지용 PCC 없음.$cm$,
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
      ('chandaria', 'nairobi', 'chandaria'),
  ('kenturian', 'kisaju', 'kenturian'),
  ('kim.?fay', 'nairobi|tatu', 'kim.?fay'),
  ('transafrica', 'nairobi', 'transafrica'),
  ('rai paper|pan.?african paper|panpaper', 'webuye', 'rai|pan'),
  ('east african paper|\meapm\M', 'thika', 'east african|eapm'),
  ('mega paper|mega spin', 'nakuru', 'mega'),
  ('fortuna', 'nairobi', 'fortuna'),
  ('cots paper', null, 'cots paper'),
  ('jubilee tissue', null, 'jubilee tissue')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'kenya_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'kenya_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'mineral enterprises|melwit' or p.party_name ~* 'kiki.?s industrial' or p.party_name ~* 'dalit' or p.party_name ~* 'sanvil')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'KE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'KE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    