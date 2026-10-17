-- ============================================================
-- seed_20261016ze_albania_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Albania update (reports 2026-10-16).
-- 1) Filler if missing (1): Berdica Cement (industrial carbonate supplier).
-- 2) Mills if missing (3) + plant blocks: Edipack (1), GERIS (2), Elisabet
--    (no priority). Context (6): So Cart, Eurokartoni, Alba Box, Unieuro,
--    Kartonteks, Novopack.
-- 3) app.country_markets AL row (priority low).
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
           v.party_name, 'AL', v.region, v.city, v.website, 'active', 'albania_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('berdica', 'Berdica Cement - Shkodër', 'Shkodër', 'Shkodër', null, 'Shkodër 본사(Durrës Xhafzotaj 유통) 탄산칼슘·건축화학 소재 공급 — CaCO3 최대 99%, 미분 15~100 μm, 100·200 μm, 0.2~3 mm, 제지 용도 언급.', 'Berdica Cement SH.P.K., Rr. Studenti P. 21, Shkodër (depot Xhafzotaj, Durrës) - calcium carbonate up to 99 pct CaCO3: micronised 15-100 micron, 100 and 200 micron powders, 0.2-3 mm granules for mortars, tile adhesives, paint, plastics, rubber, paper named.', 'AL check 2026-10-16: own plant not confirmed and 15 micron is coarse for paper. +355 22 800 350. Not added: REY PLASTICA (importer, 70-90 t/month), ALBANERA (mining listing), Colacem Albania (cement grinding), Shijaku Group (aggregates). Regional paper GCC: Calcit (Slovenia, Croatia Gospić), Omya Italy, Aydın (Turkey).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('berdica', 'Berdica Cement - Shkodër', 'Shkodër', 'Shkodër', null, 'Shkodër 본사(Durrës Xhafzotaj 유통) 탄산칼슘·건축화학 소재 공급 — CaCO3 최대 99%, 미분 15~100 μm, 100·200 μm, 0.2~3 mm, 제지 용도 언급.', 'Berdica Cement SH.P.K., Rr. Studenti P. 21, Shkodër (depot Xhafzotaj, Durrës) - calcium carbonate up to 99 pct CaCO3: micronised 15-100 micron, 100 and 200 micron powders, 0.2-3 mm granules for mortars, tile adhesives, paint, plastics, rubber, paper named.', 'AL check 2026-10-16: own plant not confirmed and 15 micron is coarse for paper. +355 22 800 350. Not added: REY PLASTICA (importer, 70-90 t/month), ALBANERA (mining listing), Colacem Albania (cement grinding), Shijaku Group (aggregates). Regional paper GCC: Calcit (Slovenia, Croatia Gospić), Omya Italy, Aydın (Turkey).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'albania_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Berdica Cement - Shkodër', 'GCC supplier', 'Industrial carbonate supplier - plant to verify', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'albania_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'AL', v.region, v.city, v.website, 'active', 'albania_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('edipack', 'durr[eë]s|porto romano', 'edipack', 'Edipack - Porto Romano (Durrës)', 'Durrës', 'Durrës', null, '2003년 설립 재생 포장원지·골판지 업체(Porto Romano). 재생 원지 라인 투자, Fluting·Testliner 80~150 gsm, B·C·E 골판지, 1~5색 인쇄.', 'Edipack (2003), Rruga Aleksandër Goga, Porto Romano, Durrës - waste-paper collection, recycled fluting and testliner 80-150 gsm on its own base-paper line (investment reported), corrugated board B, C, E, BC, EC, EB and printed boxes.', 'AL check 2026-10-16: line capacity not public. porosi@edipack.al, +355 69 700 9782, production contact erti.harizi@edipack.al (older data).'),
  ('\mgeris\M', 'xhafzotaj|koxhas', 'geris', 'GERIS - Xhafzotaj', 'Durrës', 'Xhafzotaj', null, 'Tirana–Durrës 고속도로 Km 20(Koxhas) 셀룰로오스 위생지 제조사 — 월 600 t(제품), 10,000 m², 생산 스테이션 15개, ISO 9001·14001·45001, FSC.', 'GERIS, Tirana - Durrës Highway Km 20, Koxhas, Xhafzotaj - 100 pct cellulose toilet tissue and kitchen towel, 600 t/month product capacity, 10,000 m2 site, 15 production stations, 75 delivery trucks, ISO 9001, 14001, 45001 and FSC.', 'AL check 2026-10-16: 600 t/month is product output - own tissue machine not confirmed (7,200 t/yr kept in notes only). info@geris.al, +355 52 219 440.'),
  ('elisabet', 'kor[cç][eë]', 'elisabet', 'Elisabet - Korçë', 'Korçë', 'Korçë', null, '1994년 설립 위생용 티슈 제조·유통(Korçë), 51~200명.', 'Elisabet Sh.p.k. (1994), Korçë - toilet tissue and other hygiene paper making and distribution, 51-200 staff.', 'AL check 2026-10-16: own base-paper machine not confirmed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('edipack', 'durr[eë]s|porto romano', 'edipack', '2003년 설립 재생 포장원지·골판지 업체(Porto Romano). 재생 원지 라인 투자, Fluting·Testliner 80~150 gsm, B·C·E 골판지, 1~5색 인쇄.', 'Edipack (2003), Rruga Aleksandër Goga, Porto Romano, Durrës - waste-paper collection, recycled fluting and testliner 80-150 gsm on its own base-paper line (investment reported), corrugated board B, C, E, BC, EC, EB and printed boxes.', 'AL check 2026-10-16: line capacity not public. porosi@edipack.al, +355 69 700 9782, production contact erti.harizi@edipack.al (older data).'),
  ('\mgeris\M', 'xhafzotaj|koxhas', 'geris', 'Tirana–Durrës 고속도로 Km 20(Koxhas) 셀룰로오스 위생지 제조사 — 월 600 t(제품), 10,000 m², 생산 스테이션 15개, ISO 9001·14001·45001, FSC.', 'GERIS, Tirana - Durrës Highway Km 20, Koxhas, Xhafzotaj - 100 pct cellulose toilet tissue and kitchen towel, 600 t/month product capacity, 10,000 m2 site, 15 production stations, 75 delivery trucks, ISO 9001, 14001, 45001 and FSC.', 'AL check 2026-10-16: 600 t/month is product output - own tissue machine not confirmed (7,200 t/yr kept in notes only). info@geris.al, +355 52 219 440.'),
  ('elisabet', 'kor[cç][eë]', 'elisabet', '1994년 설립 위생용 티슈 제조·유통(Korçë), 51~200명.', 'Elisabet Sh.p.k. (1994), Korçë - toilet tissue and other hygiene paper making and distribution, 51-200 staff.', 'AL check 2026-10-16: own base-paper machine not confirmed.'),
  ('so ?cart', null, 'so ?cart', null, null, 'AL check 2026-10-16: Tissue converting, Tirana - context only.'),
  ('eurokartoni', null, 'eurokartoni', null, null, 'AL check 2026-10-16: Corrugated boxes, Fier and Vlorë - converter - context only.'),
  ('alba ?box', null, 'alba ?box', null, null, 'AL check 2026-10-16: Paper and board boxes, Durrës (2019) - converter - context only.'),
  ('unieuro', null, 'unieuro', null, null, 'AL check 2026-10-16: Premium paper bags and boxes, Durrës - converter - context only.'),
  ('kartonteks', null, 'kartonteks', null, null, 'AL check 2026-10-16: Listed paper and board maker, Shkodër - context only.'),
  ('novopack', null, 'novopack', null, null, 'AL check 2026-10-16: Listed paper and board maker, Elbasan - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'albania_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('edipack', 'durr[eë]s|porto romano', 'edipack'),
  ('\mgeris\M', 'xhafzotaj|koxhas', 'geris'),
  ('elisabet', 'kor[cç][eë]', 'elisabet'),
  ('so ?cart', null, 'so ?cart'),
  ('eurokartoni', null, 'eurokartoni'),
  ('alba ?box', null, 'alba ?box'),
  ('unieuro', null, 'unieuro'),
  ('kartonteks', null, 'kartonteks'),
  ('novopack', null, 'novopack')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('edipack', 'durr[eë]s|porto romano', 'edipack',
   $pj${"owner": "Edipack", "priority": 1, "products": "Recycled fluting, testliner, corrugated", "grades": ["Medium", "Testliner"], "approach": "Confirm the base-paper line and output - strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mgeris\M', 'xhafzotaj|koxhas', 'geris',
   $pj${"owner": "GERIS", "priority": 2, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "approach": "Confirm own base-paper making - then 3-5 pct trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('elisabet', 'kor[cç][eë]', 'elisabet',
   $pj${"owner": "Elisabet", "products": "Hygiene tissue", "grades": ["Tissue"], "approach": "Confirm machine or trace its jumbo-roll supplier.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('so ?cart', null, 'so ?cart',
   $pj${"owner": "So Cart (Alkos Group)", "products": "Tissue converting, Tirana", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('eurokartoni', null, 'eurokartoni',
   $pj${"owner": "Eurokartoni", "products": "Corrugated boxes, Fier and Vlorë - converter", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('alba ?box', null, 'alba ?box',
   $pj${"owner": "Alba Box", "products": "Paper and board boxes, Durrës (2019) - converter", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unieuro', null, 'unieuro',
   $pj${"owner": "Unieuro", "products": "Premium paper bags and boxes, Durrës - converter", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kartonteks', null, 'kartonteks',
   $pj${"owner": "Kartonteks", "products": "Listed paper and board maker, Shkodër", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('novopack', null, 'novopack',
   $pj${"owner": "Novopack", "products": "Listed paper and board maker, Elbasan", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AL', 'Albania', 'low',
   $cm$Edipack recycled liner and GERIS tissue (600 t/month) around Durrës - no paper filler maker, regional GCC by Calcit or Omya Italy$cm$,
   $cm$Albania is a small market: Edipack (Durrës) makes recycled fluting and testliner on its own line, GERIS (Xhafzotaj) makes cellulose tissue at about 600 t/month product, Elisabet (Korçë) makes hygiene tissue, others convert. No paper PCC or GCC - Berdica Cement supplies industrial carbonate (15 micron and coarser). Nearest paper-grade GCC: Calcit (Slovenia, Croatia), Omya Italy, Aydın (Turkey).$cm$,
   $cm${"fillers": "Berdica Cement (industrial carbonate, plant to verify). Not added: REY PLASTICA, ALBANERA, Colacem Albania, Shijaku Group. Regional: Calcit (SI, HR), Omya Italy, Aydın (TR).", "mills": "Edipack Porto Romano (recycled liner), GERIS Xhafzotaj (tissue), Elisabet Korçë (tissue, machine unconfirmed). Context: So Cart, Eurokartoni, Alba Box, Unieuro, Kartonteks, Novopack.", "strategy": "Small trials at Edipack and GERIS, supply by Calcit Gospić or Omya Italy. Albania as an extension of a Balkan push.", "risks": "Tiny volumes, machine data missing.", "next_steps": ["Ask Edipack for base-paper output", "Ask GERIS whether it runs its own tissue machine"], "key_numbers": [{"label": "GERIS", "value": "600 t/month product capacity"}], "files": ["seed_20261016ze_albania_mills_fillers"]}$cm$::jsonb,
   $cm$Durrës 권 Edipack 재생 라이너·GERIS 티슈(월 600 t) — 제지용 충전제 업체 없음, 인근 Calcit·Omya Italy$cm$,
   $cm$알바니아는 소규모: Edipack(Durrës) 자체 라인 재생 골심지·라이너, GERIS(Xhafzotaj) 셀룰로오스 티슈 월 약 600 t(제품), Elisabet(Korçë) 위생지, 나머지 가공. 제지용 PCC·GCC 없음 — Berdica Cement 산업용 탄산칼슘(15 μm 이상). 인근 제지용 GCC: Calcit(슬로베니아·크로아티아), Omya Italy, Aydın(튀르키예).$cm$,
   null, null,
   $cm$원지 생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('edipack', 'durr[eë]s|porto romano', 'edipack'),
  ('\mgeris\M', 'xhafzotaj|koxhas', 'geris'),
  ('elisabet', 'kor[cç][eë]', 'elisabet'),
  ('so ?cart', null, 'so ?cart'),
  ('eurokartoni', null, 'eurokartoni'),
  ('alba ?box', null, 'alba ?box'),
  ('unieuro', null, 'unieuro'),
  ('kartonteks', null, 'kartonteks'),
  ('novopack', null, 'novopack')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'albania_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'albania_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'berdica')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AL'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AL'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AL'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    