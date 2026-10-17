-- ============================================================
-- seed_20261016zj_montenegro_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Montenegro update (reports 2026-10-16). No paper machine - no mills created.
-- 1) Fillers if missing (2): Nimont (Bar), Maljat Stone (Danilovgrad) -
--    limestone raw material only.
-- 2) Context, match only (10): TRING, Montcarton, Oscar Co, PG-PAK,
--    Montekarton, LEGEND, BOY IV, Micromedia, Himpeks, Berane mill (closed).
-- 3) app.country_markets ME row (priority none).
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
           v.party_name, 'ME', v.region, v.city, v.website, 'active', 'montenegro_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('nimont', 'Nimont - Bar (Volujica quarry)', 'Bar', 'Bar', null, 'Bar 항 인근 Volujica 석회석 채석장 약 20년 운영, 골재 누적 450만 t 이상 수출, ISO 9001.', 'Nimont d.o.o., Maršala Tita 54, Bar - Volujica limestone quarry next to Bar port for about 20 years, over 4.5 Mt aggregates exported, ISO 9001:2015.', 'ME check 2026-10-16: aggregates only - no fine grinding. commercial@nimont.me, +382 30 317 170, manager Aleksandar Mišović.'),
  ('maljat', 'Maljat Stone - Danilovgrad', 'Danilovgrad', 'Danilovgrad', null, '1964년 기반(구 Mermer) 석회석 채굴·석재 가공(Danilovgrad), 2020부터 30년 채굴권, 광산 1·공장 2, 2023 신규 석판 공장 연 25만 m².', 'Maljat Stone a.d. (since 1964, formerly Mermer a.d.), II Dalmatinske bb, Danilovgrad - 30-year Maljat concession since 2020, one quarry (254,233 m2) and two processing plants, new slab plant 2023 (over 250,000 m2/yr), building stone.', 'ME check 2026-10-16: dimension stone only - paper suitability of the limestone untested. info.maljat@fhgroup.eu. No paper PCC or GCC in Montenegro - regional sources: Omya Specialty Materials Serbia (Banja-Aranđelovac), STARAC Croatia (White Rock, 1-100 micron, paper slurry named).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ME check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('nimont', 'Nimont - Bar (Volujica quarry)', 'Bar', 'Bar', null, 'Bar 항 인근 Volujica 석회석 채석장 약 20년 운영, 골재 누적 450만 t 이상 수출, ISO 9001.', 'Nimont d.o.o., Maršala Tita 54, Bar - Volujica limestone quarry next to Bar port for about 20 years, over 4.5 Mt aggregates exported, ISO 9001:2015.', 'ME check 2026-10-16: aggregates only - no fine grinding. commercial@nimont.me, +382 30 317 170, manager Aleksandar Mišović.'),
  ('maljat', 'Maljat Stone - Danilovgrad', 'Danilovgrad', 'Danilovgrad', null, '1964년 기반(구 Mermer) 석회석 채굴·석재 가공(Danilovgrad), 2020부터 30년 채굴권, 광산 1·공장 2, 2023 신규 석판 공장 연 25만 m².', 'Maljat Stone a.d. (since 1964, formerly Mermer a.d.), II Dalmatinske bb, Danilovgrad - 30-year Maljat concession since 2020, one quarry (254,233 m2) and two processing plants, new slab plant 2023 (over 250,000 m2/yr), building stone.', 'ME check 2026-10-16: dimension stone only - paper suitability of the limestone untested. info.maljat@fhgroup.eu. No paper PCC or GCC in Montenegro - regional sources: Omya Specialty Materials Serbia (Banja-Aranđelovac), STARAC Croatia (White Rock, 1-100 micron, paper slurry named).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'montenegro_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Nimont - Bar (Volujica quarry)', 'Carbonate raw material', 'Limestone and port logistics - raw material', 'merchant', 'C', 'gcc'),
  ('Maljat Stone - Danilovgrad', 'Carbonate raw material', 'Limestone stone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'montenegro_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ME check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ME'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mtring\M', null, '\mtring\M', null, null, 'ME check 2026-10-16: Thermal rolls and food packaging, Danilovgrad (2025 sales EUR 3.35 m) - converter - context only.'),
  ('montcarton', null, 'montcarton', null, null, 'ME check 2026-10-16: Printed folding cartons, Podgorica (EUR 1.63 m) - converter - context only.'),
  ('oscar co', null, 'oscar co', null, null, 'ME check 2026-10-16: Paper and board packaging, Bijelo Polje (EUR 1.34 m) - machine unknown - context only.'),
  ('pg-?pak', null, 'pg-?pak', null, null, 'ME check 2026-10-16: Food paper packaging and napkins, Podgorica - converter - context only.'),
  ('montekarton', null, 'montekarton', null, null, 'ME check 2026-10-16: Toilet tissue and paper bags, Bijelo Polje - converter - context only.'),
  ('\mlegend\M', null, '\mlegend\M', null, null, 'ME check 2026-10-16: Napkins, tissue, paper bags, Podgorica - converter - context only.'),
  ('boy iv', null, 'boy iv', null, null, 'ME check 2026-10-16: Food paper and board packaging, Herceg Novi - converter - context only.'),
  ('micromedia', null, 'micromedia', null, null, 'ME check 2026-10-16: Boxes and corrugated packaging, Podgorica - converter - context only.'),
  ('himpeks', null, 'himpeks', null, null, 'ME check 2026-10-16: Paper and board containers, Podgorica - converter - context only.'),
  ('berane', null, 'berane', null, null, 'ME check 2026-10-16: Former pulp and paper mill, closed, remains being dismantled (2026-09) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'montenegro_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ME'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mtring\M', null, '\mtring\M'),
  ('montcarton', null, 'montcarton'),
  ('oscar co', null, 'oscar co'),
  ('pg-?pak', null, 'pg-?pak'),
  ('montekarton', null, 'montekarton'),
  ('\mlegend\M', null, '\mlegend\M'),
  ('boy iv', null, 'boy iv'),
  ('micromedia', null, 'micromedia'),
  ('himpeks', null, 'himpeks'),
  ('berane', null, 'berane')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ME'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mtring\M', null, '\mtring\M',
   $pj${"owner": "TRING", "products": "Thermal rolls and food packaging, Danilovgrad (2025 sales EUR 3.35 m) - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('montcarton', null, 'montcarton',
   $pj${"owner": "Montcarton", "products": "Printed folding cartons, Podgorica (EUR 1.63 m) - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('oscar co', null, 'oscar co',
   $pj${"owner": "Oscar Co", "products": "Paper and board packaging, Bijelo Polje (EUR 1.34 m) - machine unknown", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pg-?pak', null, 'pg-?pak',
   $pj${"owner": "PG-PAK", "products": "Food paper packaging and napkins, Podgorica - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('montekarton', null, 'montekarton',
   $pj${"owner": "Montekarton", "products": "Toilet tissue and paper bags, Bijelo Polje - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mlegend\M', null, '\mlegend\M',
   $pj${"owner": "LEGEND", "products": "Napkins, tissue, paper bags, Podgorica - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('boy iv', null, 'boy iv',
   $pj${"owner": "BOY IV", "products": "Food paper and board packaging, Herceg Novi - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('micromedia', null, 'micromedia',
   $pj${"owner": "Micromedia", "products": "Boxes and corrugated packaging, Podgorica - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('himpeks', null, 'himpeks',
   $pj${"owner": "Himpeks Packaging", "products": "Paper and board containers, Podgorica - converter", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('berane', null, 'berane',
   $pj${"owner": "Berane Pulp and Paper Mill (closed)", "products": "Former pulp and paper mill, closed, remains being dismantled (2026-09)", "approach": "Converter or closed - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ME', 'Montenegro', 'none',
   $cm$No paper machine since Berane closed - packaging and tissue converters on imported paper, limestone only$cm$,
   $cm$Montenegro has no pulp or base-paper mill since the Berane mill closed (UNECE report): TRING, Montcarton, Oscar Co, PG-PAK, Montekarton and about 20 other small firms convert imported paper and board. Carbonate is limited to limestone quarries (Nimont at Bar port, Maljat Stone at Danilovgrad). No paper PCC or GCC. Regional supply: Omya Serbia, STARAC Croatia. Femić (tissue) is a Serbian company, not local.$cm$,
   $cm${"fillers": "Raw: Nimont (Volujica limestone, Bar port), Maljat Stone (Danilovgrad). No PCC or GCC. Regional: Omya Specialty Materials Serbia, STARAC Croatia.", "mills": "No paper machine. Context: TRING, Montcarton, Oscar Co, PG-PAK, Montekarton, LEGEND, BOY IV, Micromedia, Himpeks, Berane mill (closed).", "strategy": "Indirect - ask converters for their base-paper mills in Serbia, Croatia, Bosnia.", "risks": "No direct volume.", "next_steps": ["Ask Montcarton and PG-PAK for their base-paper suppliers"], "key_numbers": [{"label": "NACE 1721 firms", "value": "23, mostly under 50 staff"}], "files": ["seed_20261016zj_montenegro_fillers"]}$cm$::jsonb,
   $cm$Berane 폐쇄 후 초지기 없음 — 수입 원지 포장·티슈 가공업체, 석회석만 존재$cm$,
   $cm$몬테네그로는 Berane 펄프·제지공장 폐쇄 이후 원지 공장 없음(UNECE): TRING·Montcarton·Oscar Co·PG-PAK·Montekarton 등 20여 소기업이 수입 원지 가공. 탄산칼슘은 석회석 채석장(Nimont Bar항, Maljat Stone)뿐, 제지용 PCC·GCC 없음. 인근 공급: Omya Serbia, STARAC(크로아티아). Femić 는 세르비아 기업.$cm$,
   null, null,
   $cm$초지기 없음 — 직접 수요 없음$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('\mtring\M', null, '\mtring\M'),
  ('montcarton', null, 'montcarton'),
  ('oscar co', null, 'oscar co'),
  ('pg-?pak', null, 'pg-?pak'),
  ('montekarton', null, 'montekarton'),
  ('\mlegend\M', null, '\mlegend\M'),
  ('boy iv', null, 'boy iv'),
  ('micromedia', null, 'micromedia'),
  ('himpeks', null, 'himpeks'),
  ('berane', null, 'berane')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'montenegro_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ME'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'montenegro_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'nimont' or p.party_name ~* 'maljat')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ME'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ME'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ME'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ME'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    