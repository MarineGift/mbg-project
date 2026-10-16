-- ============================================================
-- seed_20261016r_mongolia_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mongolia update (paper-company report 2026-10-16). The filler report
-- did not load, so no filler rows.
-- 1) Mills if missing (3) + plant blocks: Eco Tsaas (1), Urin Trade (2),
--    Sain Tsaas (no priority). Context (4): Khugjil Trade, Eco Pack,
--    Finpack, Selenge Press.
-- 2) app.country_markets MN row (priority low).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MN', v.region, v.city, v.website, 'active', 'mongolia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('eco ts[aа]+s|эко цаас', 'songino', 'eco ts|eco pack', 'Eco Tsaas - Ulaanbaatar (Songinokhairkhan)', 'Ulaanbaatar', 'Ulaanbaatar', null, '폐지·폐골판지 재활용 갈색 포장원지 공장(Eco Tsaas / Эко цаас, 2019 등록, Songinokhairkhan 20 Khoroo). 2022 가동, 일 30 t(2023 Eco Pack 자료), 옥수수 전분·재활용수.', 'Eco Tsaas LLC (Эко цаас, registered 2019-04), Songinokhairkhan District 20th Khoroo, Ulaanbaatar - recovered paper and OCC repulped to brown packaging base paper, plant opened 2022, about 30 t/day (2023, Eco Pack material), corn starch and recycled water. Linked to Eco Pack Mongolia (box maker). Extra environmental assessment approved 2026-04.', 'MN check 2026-10-16: machine specs and filler use not public. 9,000 t/yr is 30 t/day x 300 (calculated).'),
  ('urin trade|урин', 'ulaanbaatar', 'urin|урин', 'Urin Trade - Ulaanbaatar', null, null, null, '2017년부터 화장지·미용티슈·냅킨·키친타월 제조(Урин Трейд). 러시아산 목재 셀룰로오스 수입, 2023 일 6 t·직원 약 40명, 시장 10~20%(회사 발표).', 'Urin Trade LLC (Урин Трейд), making toilet tissue, facial, napkins and kitchen towel since 2017 on imported Russian wood pulp: about 6 t/day and about 40 staff (2023 report), claims 10-20 pct of the Mongolian household tissue market.', 'MN check 2026-10-16: whether it makes its own base paper or converts jumbo rolls is not confirmed. 1,800 t/yr is 6 t/day x 300 (calculated, product output).'),
  ('sain ts[aа]+s|сайн цаас', null, 'sain', 'Sain Tsaas - Ulaanbaatar', null, null, null, '폐골판지 재활용·포장재 업체(Сайн Цаас), 과거 환경부 방문 보도 일 20~25 t 폐지 처리.', 'Sain Tsaas (Сайн Цаас) - recovered corrugated recycling for packaging, 20-25 t/day waste paper processed in an older Ministry of Environment visit report.', 'MN check 2026-10-16: paper machine and 2026 operation not confirmed - waste input is not output capacity.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MN check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('eco ts[aа]+s|эко цаас', 'songino', 'eco ts|eco pack', '폐지·폐골판지 재활용 갈색 포장원지 공장(Eco Tsaas / Эко цаас, 2019 등록, Songinokhairkhan 20 Khoroo). 2022 가동, 일 30 t(2023 Eco Pack 자료), 옥수수 전분·재활용수.', 'Eco Tsaas LLC (Эко цаас, registered 2019-04), Songinokhairkhan District 20th Khoroo, Ulaanbaatar - recovered paper and OCC repulped to brown packaging base paper, plant opened 2022, about 30 t/day (2023, Eco Pack material), corn starch and recycled water. Linked to Eco Pack Mongolia (box maker). Extra environmental assessment approved 2026-04.', 'MN check 2026-10-16: machine specs and filler use not public. 9,000 t/yr is 30 t/day x 300 (calculated).'),
  ('urin trade|урин', 'ulaanbaatar', 'urin|урин', '2017년부터 화장지·미용티슈·냅킨·키친타월 제조(Урин Трейд). 러시아산 목재 셀룰로오스 수입, 2023 일 6 t·직원 약 40명, 시장 10~20%(회사 발표).', 'Urin Trade LLC (Урин Трейд), making toilet tissue, facial, napkins and kitchen towel since 2017 on imported Russian wood pulp: about 6 t/day and about 40 staff (2023 report), claims 10-20 pct of the Mongolian household tissue market.', 'MN check 2026-10-16: whether it makes its own base paper or converts jumbo rolls is not confirmed. 1,800 t/yr is 6 t/day x 300 (calculated, product output).'),
  ('sain ts[aа]+s|сайн цаас', null, 'sain', '폐골판지 재활용·포장재 업체(Сайн Цаас), 과거 환경부 방문 보도 일 20~25 t 폐지 처리.', 'Sain Tsaas (Сайн Цаас) - recovered corrugated recycling for packaging, 20-25 t/day waste paper processed in an older Ministry of Environment visit report.', 'MN check 2026-10-16: paper machine and 2026 operation not confirmed - waste input is not output capacity.'),
  ('khugjil|хөгжил', null, 'khugjil|хөгжил', null, null, 'MN check 2026-10-16: Tissue, napkins, wet wipes (Ariun brand, Khan-Uul, since 1992) - paper machine not confirmed - context only.'),
  ('eco pack', null, 'eco pack', null, null, 'MN check 2026-10-16: Corrugated boxes (Khan-Uul, since 2010, 100+ staff) - converter linked to Eco Tsaas - context only.'),
  ('finpack', null, 'finpack', null, null, 'MN check 2026-10-16: Paper food packaging on European base paper - converter - context only.'),
  ('selenge press', null, 'selenge press', null, null, 'MN check 2026-10-16: Printing paper import (Hansol, Sun Paper) and printing - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'mongolia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('eco ts[aа]+s|эко цаас', 'songino', 'eco ts|eco pack'),
  ('urin trade|урин', 'ulaanbaatar', 'urin|урин'),
  ('sain ts[aа]+s|сайн цаас', null, 'sain'),
  ('khugjil|хөгжил', null, 'khugjil|хөгжил'),
  ('eco pack', null, 'eco pack'),
  ('finpack', null, 'finpack'),
  ('selenge press', null, 'selenge press')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('eco ts[aа]+s|эко цаас', 'songino', 'eco ts|eco pack',
   $pj${"owner": "Eco Tsaas / Eco Pack", "priority": 1, "products": "Recycled brown packaging base paper", "grades": ["Testliner", "Medium"], "capacity": {"value": 9000, "unit": "metric_t", "year": "30 t/day x 300 (calculated, 2023)", "source": "ecopack.mn"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct - strength must be proven."}, "approach": "Only confirmed paper machine in Mongolia - ask machine specs and current filler use.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('urin trade|урин', 'ulaanbaatar', 'urin|урин',
   $pj${"owner": "Urin Trade", "priority": 2, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "capacity": {"value": 1800, "unit": "metric_t", "year": "6 t/day x 300 (calculated, 2023)", "source": "press 2023"}, "approach": "Confirm a tissue machine - FCC 1-5 pct to save imported pulp.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sain ts[aа]+s|сайн цаас', null, 'sain',
   $pj${"owner": "Sain Tsaas", "products": "Recycled packaging (to confirm)", "approach": "Confirm operation and machine.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('khugjil|хөгжил', null, 'khugjil|хөгжил',
   $pj${"owner": "Khugjil Trade (Ariun)", "products": "Tissue, napkins, wet wipes (Ariun brand, Khan-Uul, since 1992) - paper machine not confirmed", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('eco pack', null, 'eco pack',
   $pj${"owner": "Eco Pack Mongolia", "products": "Corrugated boxes (Khan-Uul, since 2010, 100+ staff) - converter linked to Eco Tsaas", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('finpack', null, 'finpack',
   $pj${"owner": "Finpack", "products": "Paper food packaging on European base paper - converter", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('selenge press', null, 'selenge press',
   $pj${"owner": "Selenge Press", "products": "Printing paper import (Hansol, Sun Paper) and printing", "approach": "Converter or importer.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MN', 'Mongolia', 'low',
   $cm$Small recycled packaging mill (Eco Tsaas, about 30 t/day) and tissue makers on imported pulp - no paper filler maker found$cm$,
   $cm$Mongolia has one confirmed paper machine: Eco Tsaas recycled brown packaging paper in Ulaanbaatar (about 30 t/day, 2022). Urin Trade makes tissue on imported Russian pulp (about 6 t/day), Sain Tsaas recycles OCC (status unknown). Khugjil (Ariun), Eco Pack, Finpack convert, Selenge Press imports printing paper. The filler report did not load - a Khutul calcium carbonate investment project was mentioned but not detailed.$cm$,
   $cm${"fillers": "Filler report did not load. Mentioned: a new calcium carbonate project at Khutul - details to collect.", "mills": "Eco Tsaas (recycled brown paper, 30 t/day). Urin Trade (tissue, imported pulp). Sain Tsaas (OCC recycling, to confirm). Context: Khugjil Trade (Ariun), Eco Pack Mongolia, Finpack, Selenge Press.", "strategy": "Small market - Eco Tsaas packaging trial and Urin tissue pulp saving. Supply by a future Khutul carbonate plant or Chinese producers.", "risks": "Very small volumes, base-paper making at tissue firms unconfirmed.", "next_steps": ["Re-run the Mongolia filler report (Khutul project)", "Ask Eco Tsaas for machine specs"], "key_numbers": [{"label": "Eco Tsaas", "value": "about 30 t/day (2023)"}, {"label": "Urin Trade", "value": "about 6 t/day tissue (2023)"}], "files": ["seed_20261016r_mongolia_mills"]}$cm$::jsonb,
   $cm$소형 재생 포장원지 공장(Eco Tsaas, 일 약 30 t) + 수입 펄프 티슈 업체 — 제지용 충전제 업체 미확인$cm$,
   $cm$몽골에서 확인된 초지기는 Eco Tsaas 재생 갈색원지(울란바토르, 일 약 30 t, 2022 가동) 1곳. Urin Trade 는 러시아산 펄프로 티슈(일 약 6 t), Sain Tsaas 는 폐골판지 재활용(가동 미확인). Khugjil(Ariun)·Eco Pack·Finpack 은 가공, Selenge Press 는 인쇄용지 수입. 충전제 보고서는 로딩 실패 — Khutul 탄산칼슘 신규 프로젝트 언급만 있음.$cm$,
   270, 450,
   $cm$Eco Tsaas 9,000 t(30 t/일 × 300일) × FCC 3~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('eco ts[aа]+s|эко цаас', 'songino', 'eco ts|eco pack'),
  ('urin trade|урин', 'ulaanbaatar', 'urin|урин'),
  ('sain ts[aа]+s|сайн цаас', null, 'sain'),
  ('khugjil|хөгжил', null, 'khugjil|хөгжил'),
  ('eco pack', null, 'eco pack'),
  ('finpack', null, 'finpack'),
  ('selenge press', null, 'selenge press')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'mongolia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'mongolia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MN'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MN'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MN'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    