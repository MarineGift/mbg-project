-- ============================================================
-- seed_20261017g_guinea_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Guinea (GN) update (reports 2026-10-17). No paper machine - no mill rows.
-- Diamond Cement guard is country-scoped (also in ML, TG).
-- 1) Filler if missing (1): Diamond Cement Guinea (Souguéta limestone).
-- 2) Context, match only (9): converters and new projects.
-- 3) app.country_markets GN row (priority none).
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
           v.party_name, 'GN', v.region, v.city, v.website, 'active', 'guinea_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('diamond cement.*guin', 'Diamond Cement Guinea - Souguéta', 'Kindia', 'Souguéta', null, 'Diamond Cement Guinea(Kagbelen·Dubréka) — 2014 Kindia Souguéta Wondé Fily·Amaraya 석회석 광상 개발 허가 보도.', 'Diamond Cement Guinea S.A., Kagbelen (Dubréka) - reported in 2014 to hold limestone permits at Wondé Fily and Amaraya, Souguéta (Kindia). Souguéta CaCO3 has been used in bauxite-leaching lime trials.', 'GN check 2026-10-17: permit status and paper-grade quality unknown. +224 628 68 65 30. Not added: CIMAF Guinée (1.5 Mt grinding, Dubréka), GI Ciments (1.4 Mt, Kagbelen), LafargeHolcim Guinée (Sonfonia). No Guinean paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GN check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('diamond cement.*guin', 'Diamond Cement Guinea - Souguéta', 'Kindia', 'Souguéta', null, 'Diamond Cement Guinea(Kagbelen·Dubréka) — 2014 Kindia Souguéta Wondé Fily·Amaraya 석회석 광상 개발 허가 보도.', 'Diamond Cement Guinea S.A., Kagbelen (Dubréka) - reported in 2014 to hold limestone permits at Wondé Fily and Amaraya, Souguéta (Kindia). Souguéta CaCO3 has been used in bauxite-leaching lime trials.', 'GN check 2026-10-17: permit status and paper-grade quality unknown. +224 628 68 65 30. Not added: CIMAF Guinée (1.5 Mt grinding, Dubréka), GI Ciments (1.4 Mt, Kagbelen), LafargeHolcim Guinée (Sonfonia). No Guinean paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'guinea_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Diamond Cement Guinea - Souguéta', 'Limestone owner (cement)', 'Limestone permit - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'guinea_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GN check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papel industries', null, 'papel industries', null, null, 'GN check 2026-10-17: Papel Industries (2024), Conakry - 3-ply facial tissue Papel Doux - machine not confirmed - context only.'),
  ('ali chehab|\macc\M.*(guin|conakry)', null, 'ali chehab|\macc\M.*(guin|conakry)', null, null, 'GN check 2026-10-17: ACC (Ali Chehab Corporation), Matam Conakry - toilet and facial tissue - context only.'),
  ('sodefa', null, 'sodefa', null, null, 'GN check 2026-10-17: SODEFA (2005), Km 41 Coyah - corrugated boxes - context only.'),
  ('sogepac', null, 'sogepac', null, null, 'GN check 2026-10-17: SOGEPAC (2004), Gomboyah Km 39 Coyah - corrugated boxes - context only.'),
  ('egepac', null, 'egepac', null, null, 'GN check 2026-10-17: EGEPAC Multi-Services, Matoto - paper and board packaging - context only.'),
  ('guin[eé]e industrie plus', null, 'guin[eé]e industrie plus', null, null, 'GN check 2026-10-17: Guinée Industrie Plus, Kagbélén - tissue, detergent, cosmetics plant, ESIA scoping 2026-05-08 - context only.'),
  ('globale invest', null, 'globale invest', null, null, 'GN check 2026-10-17: Globale Invest Co, Coyah - corrugated and paper packaging plant approved 2025-05-15 (GNF 26.7 bn, 54 jobs) - context only.'),
  ('eguifab', null, 'eguifab', null, null, 'GN check 2026-10-17: EGUIFAB, Forécariah - diapers, pads, tissue project (GNF 9.2 bn) - context only.'),
  ('barry kadiatou', null, 'barry kadiatou', null, null, 'GN check 2026-10-17: Etablissements Barry Kadiatou, Matoto - tissue and diaper project (GNF 7.4 bn) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'guinea_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papel industries', null, 'papel industries'),
  ('ali chehab|\macc\M.*(guin|conakry)', null, 'ali chehab|\macc\M.*(guin|conakry)'),
  ('sodefa', null, 'sodefa'),
  ('sogepac', null, 'sogepac'),
  ('egepac', null, 'egepac'),
  ('guin[eé]e industrie plus', null, 'guin[eé]e industrie plus'),
  ('globale invest', null, 'globale invest'),
  ('eguifab', null, 'eguifab'),
  ('barry kadiatou', null, 'barry kadiatou')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papel industries', null, 'papel industries', true,
   $pj${"owner": "Papel Industries", "products": "Papel Industries (2024), Conakry - 3-ply facial tissue Papel Doux - machine not confirmed", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('ali chehab|\macc\M.*(guin|conakry)', null, 'ali chehab|\macc\M.*(guin|conakry)', true,
   $pj${"owner": "ACC", "products": "ACC (Ali Chehab Corporation), Matam Conakry - toilet and facial tissue", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sodefa', null, 'sodefa', true,
   $pj${"owner": "SODEFA", "products": "SODEFA (2005), Km 41 Coyah - corrugated boxes", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sogepac', null, 'sogepac', true,
   $pj${"owner": "SOGEPAC", "products": "SOGEPAC (2004), Gomboyah Km 39 Coyah - corrugated boxes", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('egepac', null, 'egepac', true,
   $pj${"owner": "EGEPAC", "products": "EGEPAC Multi-Services, Matoto - paper and board packaging", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('guin[eé]e industrie plus', null, 'guin[eé]e industrie plus', true,
   $pj${"owner": "GI+", "products": "Guinée Industrie Plus, Kagbélén - tissue, detergent, cosmetics plant, ESIA scoping 2026-05-08", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('globale invest', null, 'globale invest', true,
   $pj${"owner": "Globale Invest", "products": "Globale Invest Co, Coyah - corrugated and paper packaging plant approved 2025-05-15 (GNF 26.7 bn, 54 jobs)", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('eguifab', null, 'eguifab', true,
   $pj${"owner": "EGUIFAB", "products": "EGUIFAB, Forécariah - diapers, pads, tissue project (GNF 9.2 bn)", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('barry kadiatou', null, 'barry kadiatou', true,
   $pj${"owner": "Barry Kadiatou", "products": "Etablissements Barry Kadiatou, Matoto - tissue and diaper project (GNF 7.4 bn)", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GN', 'Guinea', 'none',
   $cm$No paper machine - tissue (Papel, ACC) and corrugated converters (SODEFA, SOGEPAC) - new tissue and packaging projects (GI+, Globale Invest) - Souguéta limestone$cm$,
   $cm$Guinea has tissue converters (Papel Industries, ACC) and corrugated makers (SODEFA, SOGEPAC, EGEPAC) but no confirmed paper machine. New projects: Guinée Industrie Plus (Kagbélén tissue and hygiene plant, ESIA 2026-05), Globale Invest (Coyah packaging, approved 2025-05), EGUIFAB and Barry Kadiatou (tissue and diapers) - base-paper making not stated. No paper PCC or GCC: Diamond Cement holds Souguéta (Kindia) limestone permits, other cement firms grind clinker.$cm$,
   $cm${"fillers": "Limestone: Diamond Cement Guinea. Not added: CIMAF, GI Ciments, LafargeHolcim. No PCC or GCC.", "mills": "No paper machine. Context: Papel, ACC, SODEFA, SOGEPAC, EGEPAC, plus projects GI+, Globale Invest, EGUIFAB, Barry Kadiatou.", "strategy": "Ask GI+ whether its tissue line includes a paper machine - design-stage pitch if yes.", "risks": "No volume, projects unverified.", "next_steps": ["Ask Guinée Industrie Plus about its tissue line scope"], "key_numbers": [{"label": "Globale Invest", "value": "GNF 26.7 bn (2025)"}], "files": ["seed_20261017g_guinea_market"]}$cm$::jsonb,
   $cm$초지기 없음 — 티슈(Papel, ACC)·골판지(SODEFA, SOGEPAC) 가공 — 신규 티슈·포장 프로젝트(GI+, Globale Invest) — Souguéta 석회석$cm$,
   $cm$기니에는 티슈 가공(Papel Industries, ACC)·골판지(SODEFA, SOGEPAC, EGEPAC)는 있으나 초지기 미확인. 신규: Guinée Industrie Plus(Kagbélén 티슈·위생 공장, 2026-05 환경평가), Globale Invest(Coyah 포장, 2025-05 승인), EGUIFAB·Barry Kadiatou(티슈·기저귀) — 원지 생산 여부 미기재. 제지용 PCC·GCC 없음: Diamond Cement 의 Souguéta(Kindia) 석회석 허가, 나머지 시멘트사는 클링커 분쇄.$cm$,
   null, null,
   $cm$초지기 없음 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('papel industries', null, 'papel industries'),
  ('ali chehab|\macc\M.*(guin|conakry)', null, 'ali chehab|\macc\M.*(guin|conakry)'),
  ('sodefa', null, 'sodefa'),
  ('sogepac', null, 'sogepac'),
  ('egepac', null, 'egepac'),
  ('guin[eé]e industrie plus', null, 'guin[eé]e industrie plus'),
  ('globale invest', null, 'globale invest'),
  ('eguifab', null, 'eguifab'),
  ('barry kadiatou', null, 'barry kadiatou')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'guinea_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'guinea_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'diamond cement.*guin')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GN'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GN'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GN'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    