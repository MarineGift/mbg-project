-- ============================================================
-- seed_20261017b_togo_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Togo update (reports 2026-10-17). No confirmed paper machine - no mill rows.
-- 1) Fillers if missing (3): Scantogo, WACEM, POMAR.
-- 2) Context, match only (6): converters.
-- 3) app.country_markets TG row (priority none).
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
           v.party_name, 'TG', v.region, v.city, v.website, 'active', 'togo_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('scantogo', 'Scantogo Mines (Heidelberg) - Tabligbo', 'Maritime', 'Tabligbo', null, 'Heidelberg 계열 Scantogo(Tabligbo, 2014-11~) 자체 석회석 채석·클링커 연 150만 t — 파쇄 1,000 t/h, 원료 수직밀 410 t/h, 소성로 5,000 t/일.', 'Scantogo Mines SA (Heidelberg Materials), Tabligbo (Yoto) - own limestone quarry and clinker, 1.5 Mt/yr since 2014-11, crusher 1,000 t/h, raw vertical mill 410 t/h, kiln 5,000 t/day.', 'TG check 2026-10-17: cement raw mill is not a paper GCC line - test whiteness, purity, Fe. scantogo@hcafrica.com, +228 22 27 06 81. Raw-material lead 1.'),
  ('wacem|west african cement', 'WACEM - Tabligbo', 'Maritime', 'Tabligbo', null, 'WACEM(Diamond Cement 그룹, Tabligbo) 석회석 채석·클링커 연 약 120만 t, 2개 라인.', 'West African Cement (WACEM, Diamond Cement group), Tabligbo - limestone quarry and two clinker lines, about 1.2 Mt/yr (IFC).', 'TG check 2026-10-17: selective mining of high-purity beds to test.'),
  ('\mpomar\M|pagala', 'POMAR (Pagala marble)', 'Plateaux', 'Pagala', null, 'POMAR Pagala 대리석 광상 개발 허가(EITI 과거 자료).', 'POMAR - marble deposit permit at Pagala (central Togo), EITI and World Bank records.', 'TG check 2026-10-17: operating status and marble whiteness unknown - long-term GCC feed candidate. Not added: Cimtogo (Heidelberg cement), Diamond Cement Togo. No Togolese paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TG check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('scantogo', 'Scantogo Mines (Heidelberg) - Tabligbo', 'Maritime', 'Tabligbo', null, 'Heidelberg 계열 Scantogo(Tabligbo, 2014-11~) 자체 석회석 채석·클링커 연 150만 t — 파쇄 1,000 t/h, 원료 수직밀 410 t/h, 소성로 5,000 t/일.', 'Scantogo Mines SA (Heidelberg Materials), Tabligbo (Yoto) - own limestone quarry and clinker, 1.5 Mt/yr since 2014-11, crusher 1,000 t/h, raw vertical mill 410 t/h, kiln 5,000 t/day.', 'TG check 2026-10-17: cement raw mill is not a paper GCC line - test whiteness, purity, Fe. scantogo@hcafrica.com, +228 22 27 06 81. Raw-material lead 1.'),
  ('wacem|west african cement', 'WACEM - Tabligbo', 'Maritime', 'Tabligbo', null, 'WACEM(Diamond Cement 그룹, Tabligbo) 석회석 채석·클링커 연 약 120만 t, 2개 라인.', 'West African Cement (WACEM, Diamond Cement group), Tabligbo - limestone quarry and two clinker lines, about 1.2 Mt/yr (IFC).', 'TG check 2026-10-17: selective mining of high-purity beds to test.'),
  ('\mpomar\M|pagala', 'POMAR (Pagala marble)', 'Plateaux', 'Pagala', null, 'POMAR Pagala 대리석 광상 개발 허가(EITI 과거 자료).', 'POMAR - marble deposit permit at Pagala (central Togo), EITI and World Bank records.', 'TG check 2026-10-17: operating status and marble whiteness unknown - long-term GCC feed candidate. Not added: Cimtogo (Heidelberg cement), Diamond Cement Togo. No Togolese paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'togo_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Scantogo Mines (Heidelberg) - Tabligbo', 'Limestone owner (cement)', 'Large limestone quarry - raw-material lead', 'merchant', 'C', 'gcc'),
  ('WACEM - Tabligbo', 'Limestone owner (cement)', 'Limestone quarry - raw-material lead', 'merchant', 'C', 'gcc'),
  ('POMAR (Pagala marble)', 'Marble deposit', 'Marble - long-term GCC feed', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'togo_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TG check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('facam', null, 'facam', null, null, 'TG check 2026-10-17: FACAM STAIRWAY, Baguida Lomé (2023) - tissue, towels, napkins, diapers (Kleena, Angel Soft, Lala) - machine not confirmed, sells to BJ, BF - context only.'),
  ('sotopa|soci[eé]t[eé] togolaise de papier', null, 'sotopa|soci[eé]t[eé] togolaise de papier', null, null, 'TG check 2026-10-17: SOTOPA (AURA), Katanga Lomé - tissue on pure cellulose base paper - machine not confirmed - context only.'),
  ('\mimep\M', null, '\mimep\M', null, null, 'TG check 2026-10-17: IMEP SA, Lacs 1 Aného (2022, FCFA 7 bn, about 128 staff) - boxes 25,000/hour, labels up to 1 m/hour - context only.'),
  ('civicbag', null, 'civicbag', null, null, 'TG check 2026-10-17: CivicBag, Agoè-Nyivé Lomé (2016) - paper bags and boxes - context only.'),
  ('safa pak|baklini', null, 'safa pak|baklini', null, null, 'TG check 2026-10-17: SAFA PAK Togo, Lomé port (registered 2021) - paper and corrugated packaging, running status unknown - context only.'),
  ('rame.?store', null, 'rame.?store', null, null, 'TG check 2026-10-17: Papeterie Rame-Store (registered 2018) - paper making and sales listed, plant unknown - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'togo_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('facam', null, 'facam'),
  ('sotopa|soci[eé]t[eé] togolaise de papier', null, 'sotopa|soci[eé]t[eé] togolaise de papier'),
  ('\mimep\M', null, '\mimep\M'),
  ('civicbag', null, 'civicbag'),
  ('safa pak|baklini', null, 'safa pak|baklini'),
  ('rame.?store', null, 'rame.?store')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('facam', null, 'facam', true,
   $pj${"owner": "FACAM STAIRWAY", "products": "FACAM STAIRWAY, Baguida Lomé (2023) - tissue, towels, napkins, diapers (Kleena, Angel Soft, Lala) - machine not confirmed, sells to BJ, BF", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sotopa|soci[eé]t[eé] togolaise de papier', null, 'sotopa|soci[eé]t[eé] togolaise de papier', true,
   $pj${"owner": "SOTOPA", "products": "SOTOPA (AURA), Katanga Lomé - tissue on pure cellulose base paper - machine not confirmed", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\mimep\M', null, '\mimep\M', true,
   $pj${"owner": "IMEP SA", "products": "IMEP SA, Lacs 1 Aného (2022, FCFA 7 bn, about 128 staff) - boxes 25,000/hour, labels up to 1 m/hour", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('civicbag', null, 'civicbag', true,
   $pj${"owner": "CivicBag", "products": "CivicBag, Agoè-Nyivé Lomé (2016) - paper bags and boxes", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('safa pak|baklini', null, 'safa pak|baklini', true,
   $pj${"owner": "Baklini Group", "products": "SAFA PAK Togo, Lomé port (registered 2021) - paper and corrugated packaging, running status unknown", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('rame.?store', null, 'rame.?store', true,
   $pj${"owner": "Rame-Store", "products": "Papeterie Rame-Store (registered 2018) - paper making and sales listed, plant unknown", "approach": "Converter - trace jumbo-roll supplier.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TG', 'Togo', 'none',
   $cm$No confirmed paper machine - tissue (FACAM STAIRWAY, SOTOPA) and box converters (IMEP) - Tabligbo limestone (Scantogo, WACEM)$cm$,
   $cm$Togo's paper firms convert: FACAM STAIRWAY (Baguida, 2023, tissue and hygiene, sells to Benin and Burkina Faso), SOTOPA (AURA tissue on bought base paper), IMEP (Aného, 25,000 boxes/hour), CivicBag, SAFA PAK and Rame-Store (registered). No paper machine confirmed. No paper PCC or GCC: Tabligbo limestone at Scantogo (Heidelberg, 1.5 Mt clinker) and WACEM (1.2 Mt), Pagala marble (POMAR). Ghana's Delta Paper Mill lists Togo as a market.$cm$,
   $cm${"fillers": "Limestone: Scantogo, WACEM. Marble: POMAR. Not added: Cimtogo, Diamond Cement Togo. No PCC or GCC.", "mills": "No confirmed machine. Context: FACAM STAIRWAY, SOTOPA, IMEP, CivicBag, SAFA PAK, Rame-Store.", "strategy": "Ask FACAM and SOTOPA about jumbo-roll sources. Treat with Ghana and Benin as one zone.", "risks": "No direct volume.", "next_steps": ["Ask FACAM STAIRWAY whether it runs a tissue machine"], "key_numbers": [{"label": "Scantogo clinker", "value": "1.5 Mt/yr"}, {"label": "IMEP boxes", "value": "25,000/hour"}], "files": ["seed_20261017b_togo_market"]}$cm$::jsonb,
   $cm$초지기 미확인 — 티슈(FACAM STAIRWAY, SOTOPA)·상자(IMEP) 가공 — Tabligbo 석회석(Scantogo, WACEM)$cm$,
   $cm$토고 종이 업체는 가공: FACAM STAIRWAY(Baguida, 2023, 티슈·위생, 베냉·부르키나파소 판매), SOTOPA(AURA, 구매 원지 티슈), IMEP(Aného, 상자 시간당 2.5만 개), CivicBag, SAFA PAK·Rame-Store(등록). 초지기 미확인. 제지용 PCC·GCC 없음: Tabligbo 석회석 Scantogo(Heidelberg, 클링커 150만 t)·WACEM(120만 t), Pagala 대리석(POMAR). 가나 Delta Paper Mill 이 토고를 판매시장으로 명시.$cm$,
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
      ('facam', null, 'facam'),
  ('sotopa|soci[eé]t[eé] togolaise de papier', null, 'sotopa|soci[eé]t[eé] togolaise de papier'),
  ('\mimep\M', null, '\mimep\M'),
  ('civicbag', null, 'civicbag'),
  ('safa pak|baklini', null, 'safa pak|baklini'),
  ('rame.?store', null, 'rame.?store')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'togo_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'togo_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'scantogo' or p.party_name ~* 'wacem|west african cement' or p.party_name ~* '\mpomar\M|pagala')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    