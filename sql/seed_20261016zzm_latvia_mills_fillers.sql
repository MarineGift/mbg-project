-- ============================================================
-- seed_20261016zzm_latvia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Latvia update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (2): SCHWENK Latvija, Saulkalne S.
-- 2) Mills if missing (3) + plant blocks: Līgatne Paper Mill (1), V.L.T. (2),
--    EKOPAPĪRS (no priority). Context (7): converters and sales offices.
-- 3) app.country_markets LV row (priority none).
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
           v.party_name, 'LV', v.region, v.city, v.website, 'active', 'latvia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('schwenk.*(latvi|broc)', 'SCHWENK Latvija - Brocēni', 'Saldus', 'Brocēni', null, 'SCHWENK Latvija(Brocēni) 시멘트·석회석 — Kūmas 채석장, SCHWENK Agro(CaCO3 환산 중화능 96.5%, 1 mm 미만 약 39~47%).', 'SCHWENK Latvija, Brocēni - cement plus limestone of the Kūmas quarry (Saldus), agricultural SCHWENK Agro (96.5 pct CaCO3-equivalent neutralising value - not purity, about 39-47 pct under 1 mm), aggregates.', 'LV check 2026-10-16: no paper grinding or PCC. Industrial minerals Gunta Pēterkopa, gunta.peterkopa@schwenk.com, +371 67033500.'),
  ('saulkalne', 'Saulkalne S - Saulkalne', 'Salaspils', 'Saulkalne', null, 'Saulkalne S(1995, 7개 시설·약 75명) 석회석·돌로마이트 채굴·분쇄 — Limestone Aggregate Filler(콘크리트·아스팔트), 벌크 탱커 공급.', 'Saulkalne S (Latvian capital, since 1995), Saulkalne (Salaspils) - limestone and dolomite quarrying and grinding at seven sites, about 75 staff, limestone aggregate filler for concrete and asphalt, bulk tanker delivery.', 'LV check 2026-10-16: building filler, not paper GCC. saulkalne.s@saulkalne.lv, +371 67948234. Not added: Brenntag Latvia (distributor). No Latvian paper PCC or GCC - Nordkalk (FI) is the nearest paper GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%LV check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('schwenk.*(latvi|broc)', 'SCHWENK Latvija - Brocēni', 'Saldus', 'Brocēni', null, 'SCHWENK Latvija(Brocēni) 시멘트·석회석 — Kūmas 채석장, SCHWENK Agro(CaCO3 환산 중화능 96.5%, 1 mm 미만 약 39~47%).', 'SCHWENK Latvija, Brocēni - cement plus limestone of the Kūmas quarry (Saldus), agricultural SCHWENK Agro (96.5 pct CaCO3-equivalent neutralising value - not purity, about 39-47 pct under 1 mm), aggregates.', 'LV check 2026-10-16: no paper grinding or PCC. Industrial minerals Gunta Pēterkopa, gunta.peterkopa@schwenk.com, +371 67033500.'),
  ('saulkalne', 'Saulkalne S - Saulkalne', 'Salaspils', 'Saulkalne', null, 'Saulkalne S(1995, 7개 시설·약 75명) 석회석·돌로마이트 채굴·분쇄 — Limestone Aggregate Filler(콘크리트·아스팔트), 벌크 탱커 공급.', 'Saulkalne S (Latvian capital, since 1995), Saulkalne (Salaspils) - limestone and dolomite quarrying and grinding at seven sites, about 75 staff, limestone aggregate filler for concrete and asphalt, bulk tanker delivery.', 'LV check 2026-10-16: building filler, not paper GCC. saulkalne.s@saulkalne.lv, +371 67948234. Not added: Brenntag Latvia (distributor). No Latvian paper PCC or GCC - Nordkalk (FI) is the nearest paper GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'latvia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('SCHWENK Latvija - Brocēni', 'Limestone producer', 'Limestone - raw material', 'merchant', 'C', 'gcc'),
  ('Saulkalne S - Saulkalne', 'GCC producer', 'Building filler - grinding partner at most', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'latvia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'LV', v.region, v.city, v.website, 'active', 'latvia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('l[iī]gatne', 'l[iī]gatne', 'l[iī]gatne', 'Līgatne Paper Mill - Līgatne', 'Cēsis', 'Līgatne', null, '200년+ Līgatne 제지공장(Pilsoņu iela 1) — 2014 기존 사업 종료 후 재생, 자체 개발 설비로 고급 면섬유 수채화지·특수지, 대마섬유·친환경 포장 R&D(LIAA 2025-06).', 'Līgatne Paper Mill, Pilsoņu iela 1, Līgatne - over 200 years old, old business ended 2014 and restarted, now makes premium cotton watercolour and specialty papers on a machine developed in Latvia, researching hemp fibre and eco packaging (LIAA, 2025-06).', 'LV check 2026-10-16: tonnage not public, carbonate may not suit archival art paper. edgars@ligatnemill.com.'),
  ('\mv\.?l\.?t\M|eggbox', 'valmiera', 'vlt|v\.l\.t|eggbox', 'V.L.T. - Valmiera', 'Valmiera', 'Valmiera', null, 'V.L.T.(1992, Mūrmuižas iela 11A, Valmiera) 발트 최대 재생지 계란판·트레이 — 연 5,000만 개+, 폐지 최대 4,500 t, 약 45명, 2025 매출 436만 유로.', 'SIA V.L.T. (1992), Mūrmuižas iela 11A, Valmiera - largest Baltic maker of recycled-paper egg boxes and transport trays, over 50 m pieces per year, up to 4,500 t/yr recovered paper, about 45 staff, 2025 sales EUR 4.36 m.', 'LV check 2026-10-16: moulded fibre - forming, vacuum drainage, drying tests. vlt@eggbox.lv, +371 64222145.'),
  ('ekopap[iī]rs', 'l[eē]dmane', 'ekopap', 'EKOPAPĪRS - Lēdmane', 'Ogre', 'Lēdmane', null, 'SIA EKOPAPĪRS(2013, Lēdmane) NACE 17.12 종이·판지 제조 등록, 2025 매출 약 111만 유로·11명 — 설비·제품 미확인.', 'SIA EKOPAPĪRS (2013, reg. 40103639760), Lēdmane (Ogre) - registered under NACE 17.12 paper and board making, 2025 sales about EUR 1.11 m, about 11 staff - machine and products not confirmed.', 'LV check 2026-10-16: site visit needed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LV check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('l[iī]gatne', 'l[iī]gatne', 'l[iī]gatne', '200년+ Līgatne 제지공장(Pilsoņu iela 1) — 2014 기존 사업 종료 후 재생, 자체 개발 설비로 고급 면섬유 수채화지·특수지, 대마섬유·친환경 포장 R&D(LIAA 2025-06).', 'Līgatne Paper Mill, Pilsoņu iela 1, Līgatne - over 200 years old, old business ended 2014 and restarted, now makes premium cotton watercolour and specialty papers on a machine developed in Latvia, researching hemp fibre and eco packaging (LIAA, 2025-06).', 'LV check 2026-10-16: tonnage not public, carbonate may not suit archival art paper. edgars@ligatnemill.com.'),
  ('\mv\.?l\.?t\M|eggbox', 'valmiera', 'vlt|v\.l\.t|eggbox', 'V.L.T.(1992, Mūrmuižas iela 11A, Valmiera) 발트 최대 재생지 계란판·트레이 — 연 5,000만 개+, 폐지 최대 4,500 t, 약 45명, 2025 매출 436만 유로.', 'SIA V.L.T. (1992), Mūrmuižas iela 11A, Valmiera - largest Baltic maker of recycled-paper egg boxes and transport trays, over 50 m pieces per year, up to 4,500 t/yr recovered paper, about 45 staff, 2025 sales EUR 4.36 m.', 'LV check 2026-10-16: moulded fibre - forming, vacuum drainage, drying tests. vlt@eggbox.lv, +371 64222145.'),
  ('ekopap[iī]rs', 'l[eē]dmane', 'ekopap', 'SIA EKOPAPĪRS(2013, Lēdmane) NACE 17.12 종이·판지 제조 등록, 2025 매출 약 111만 유로·11명 — 설비·제품 미확인.', 'SIA EKOPAPĪRS (2013, reg. 40103639760), Lēdmane (Ogre) - registered under NACE 17.12 paper and board making, 2025 sales about EUR 1.11 m, about 11 staff - machine and products not confirmed.', 'LV check 2026-10-16: site visit needed.'),
  ('stora enso.*(latvi|r[iī]ga)', null, 'stora enso.*(latvi|r[iī]ga)', null, null, 'LV check 2026-10-16: Riga corrugated sheets and boxes (2025 sales EUR 50.3 m) - Baltic 3 plants 155 m m2 - context only.'),
  ('kvadra', null, 'kvadra', null, null, 'LV check 2026-10-16: VG Kvadra Pak - printed folding cartons, Riga (2025 sales EUR 15.4 m) - context only.'),
  ('liep[aā]jas pap[iī]rs', null, 'liep[aā]jas pap[iī]rs', null, null, 'LV check 2026-10-16: Labels and stickers, Liepāja (2025 sales EUR 10.5 m) - context only.'),
  ('smurfit.*(baltic|jelgava)', null, 'smurfit.*(baltic|jelgava)', null, null, 'LV check 2026-10-16: Jelgava sales and design - supplied by Lithuania - context only.'),
  ('ds smith.*latvi', null, 'ds smith.*latvi', null, null, 'LV check 2026-10-16: DS Smith Packaging Latvia - sales and wholesale - context only.'),
  ('gofrapro', null, 'gofrapro', null, null, 'LV check 2026-10-16: Corrugated boxes, Riga - context only.'),
  ('asta pro', null, 'asta pro', null, null, 'LV check 2026-10-16: Hygiene paper products, Augšlīgatne - machine not confirmed - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'latvia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('l[iī]gatne', 'l[iī]gatne', 'l[iī]gatne'),
  ('\mv\.?l\.?t\M|eggbox', 'valmiera', 'vlt|v\.l\.t|eggbox'),
  ('ekopap[iī]rs', 'l[eē]dmane', 'ekopap'),
  ('stora enso.*(latvi|r[iī]ga)', null, 'stora enso.*(latvi|r[iī]ga)'),
  ('kvadra', null, 'kvadra'),
  ('liep[aā]jas pap[iī]rs', null, 'liep[aā]jas pap[iī]rs'),
  ('smurfit.*(baltic|jelgava)', null, 'smurfit.*(baltic|jelgava)'),
  ('ds smith.*latvi', null, 'ds smith.*latvi'),
  ('gofrapro', null, 'gofrapro'),
  ('asta pro', null, 'asta pro')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('l[iī]gatne', 'l[iī]gatne', 'l[iī]gatne', false,
   $pj${"owner": "Līgatne Paper Mill", "priority": 1, "products": "Cotton art and specialty paper", "grades": ["Specialty paper"], "approach": "Small R&D trial with natural fibres.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mv\.?l\.?t\M|eggbox', 'valmiera', 'vlt|v\.l\.t|eggbox', false,
   $pj${"owner": "V.L.T.", "priority": 2, "products": "Moulded-fibre egg boxes and trays", "grades": ["Moulded fibre"], "approach": "Moulded-fibre trial (about 225 t at 5 pct).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ekopap[iī]rs', 'l[eē]dmane', 'ekopap', false,
   $pj${"owner": "EKOPAPĪRS", "products": "Paper or board (to confirm)", "grades": [], "approach": "Confirm machine first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*(latvi|r[iī]ga)', null, 'stora enso.*(latvi|r[iī]ga)', true,
   $pj${"owner": "Stora Enso", "products": "Riga corrugated sheets and boxes (2025 sales EUR 50.3 m) - Baltic 3 plants 155 m m2", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kvadra', null, 'kvadra', true,
   $pj${"owner": "Van Genechten Packaging", "products": "VG Kvadra Pak - printed folding cartons, Riga (2025 sales EUR 15.4 m)", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('liep[aā]jas pap[iī]rs', null, 'liep[aā]jas pap[iī]rs', true,
   $pj${"owner": "Liepājas Papīrs", "products": "Labels and stickers, Liepāja (2025 sales EUR 10.5 m)", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(baltic|jelgava)', null, 'smurfit.*(baltic|jelgava)', true,
   $pj${"owner": "Smurfit Westrock", "products": "Jelgava sales and design - supplied by Lithuania", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*latvi', null, 'ds smith.*latvi', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "DS Smith Packaging Latvia - sales and wholesale", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gofrapro', null, 'gofrapro', true,
   $pj${"owner": "GOFRAPRO", "products": "Corrugated boxes, Riga", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('asta pro', null, 'asta pro', true,
   $pj${"owner": "Asta Pro", "products": "Hygiene paper products, Augšlīgatne - machine not confirmed", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'LV', 'Latvia', 'none',
   $cm$No large paper machine - Līgatne specialty art paper, V.L.T. moulded fibre, converters - limestone only (SCHWENK, Saulkalne)$cm$,
   $cm$Latvia has 131 active paper-product firms (EUR 153.7 m sales 2025) but only 6 under paper and board making (EUR 5.6 m). Real fibre processing: Līgatne Paper Mill (cotton art and specialty papers, natural-fibre R&D), V.L.T. Valmiera (moulded egg boxes, up to 4.5 kt recovered paper), EKOPAPĪRS (to confirm). Stora Enso Riga, VG Kvadra Pak, Liepājas Papīrs, Smurfit Westrock and DS Smith convert or sell. No large tissue machine found. No paper PCC or GCC - SCHWENK Latvija and Saulkalne S grind limestone for farming and building. 2025 output index -5.5 pct.$cm$,
   $cm${"fillers": "Limestone: SCHWENK Latvija (Kūmas), Saulkalne S. Distributor: Brenntag (not added). Nearest paper GCC: Nordkalk / Suomen Karbonaatti (FI).", "mills": "Specialty: Līgatne Paper Mill. Moulded fibre: V.L.T. To confirm: EKOPAPĪRS. Context: Stora Enso Riga, VG Kvadra Pak, Liepājas Papīrs, Smurfit Westrock Baltic, DS Smith, GOFRAPRO, Asta Pro.", "strategy": "R&D only (Līgatne natural-fibre papers, V.L.T. moulded fibre). Treat Latvia as part of the Baltic-Finland zone - volumes are in Finland, Sweden and Poland.", "risks": "No direct volume.", "next_steps": ["Offer a small R&D trial to Līgatne Paper Mill"], "key_numbers": [{"label": "NACE 17 firms 2025", "value": "131 active, EUR 153.7 m"}, {"label": "NACE 17.1 paper and board", "value": "6 firms, EUR 5.6 m"}], "files": ["seed_20261016zzm_latvia_mills_fillers"]}$cm$::jsonb,
   $cm$대형 초지기 없음 — Līgatne 특수 미술지, V.L.T. 몰드펄프, 가공업체 — 석회석만(SCHWENK, Saulkalne)$cm$,
   $cm$라트비아 종이제품 활성기업 131곳(2025 매출 1.537억 유로) 중 종이·판지 제조 6곳(560만 유로). 실제 섬유 공정: Līgatne(면섬유 미술·특수지, 천연섬유 R&D), V.L.T. Valmiera(계란판, 폐지 최대 4,500 t), EKOPAPĪRS(확인 필요). Stora Enso Riga·VG Kvadra Pak·Liepājas Papīrs·Smurfit·DS Smith 는 가공·판매. 대형 티슈 초지기 없음. 제지용 PCC·GCC 없음 — SCHWENK·Saulkalne 농업·건설용 석회석. 2025 생산지수 -5.5%.$cm$,
   null, null,
   $cm$대형 초지기 없음 — 직접 수요 미미 (V.L.T. 5% 가정 시 약 225 t)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('l[iī]gatne', 'l[iī]gatne', 'l[iī]gatne'),
  ('\mv\.?l\.?t\M|eggbox', 'valmiera', 'vlt|v\.l\.t|eggbox'),
  ('ekopap[iī]rs', 'l[eē]dmane', 'ekopap'),
  ('stora enso.*(latvi|r[iī]ga)', null, 'stora enso.*(latvi|r[iī]ga)'),
  ('kvadra', null, 'kvadra'),
  ('liep[aā]jas pap[iī]rs', null, 'liep[aā]jas pap[iī]rs'),
  ('smurfit.*(baltic|jelgava)', null, 'smurfit.*(baltic|jelgava)'),
  ('ds smith.*latvi', null, 'ds smith.*latvi'),
  ('gofrapro', null, 'gofrapro'),
  ('asta pro', null, 'asta pro')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'latvia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'latvia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'schwenk.*(latvi|broc)' or p.party_name ~* 'saulkalne')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'LV'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'LV'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'LV'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    