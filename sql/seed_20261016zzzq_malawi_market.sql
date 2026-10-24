-- ============================================================
-- seed_20261016zzzq_malawi_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Malawi update (reports 2026-10-17). No confirmed paper machine - no mill rows.
-- 1) Fillers if missing (2): Shayona Cement, Cement Products (limestone).
-- 2) Context, match only (6): tissue, carton and print converters.
-- 3) app.country_markets MW row (priority none).
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
           v.party_name, 'MW', v.region, v.city, v.website, 'active', 'malawi_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('shayona', 'Shayona Cement - Kasungu', 'Central', 'Kasungu', null, 'Shayona Cement(1994, 공장 Kasungu·본사 Lilongwe) 자체 석회석 채굴 시멘트 1,600 t/일 — Akshar·Buildplast·Thanthwe.', 'Shayona Cement Corporation (1994), plant in Kasungu District, HQ Lilongwe - cement about 1,600 t/day of its own limestone (brands Akshar, Buildplast, Thanthwe).', 'MW check 2026-10-16: cement capacity, not GCC - test CaCO3, Fe, ISO brightness. sales1@shayonacement.com, +265 1 752 791.'),
  ('cement products limited|njeleza', 'Cement Products Ltd - Njeleza', 'Southern', 'Mangochi', null, 'Cement Products Ltd(Njeleza, Mangochi) 현지 석회석 채굴·시멘트(MWEITI).', 'Cement Products Limited (CPL), Njeleza, Mangochi District - quarries local limestone for cement (MWEITI report).', 'MW check 2026-10-16: raw-material lead only. Not added: Bwanje Cement Products, Kulimba Mineral Resources, OG Quarry (old permits). No Malawian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('shayona', 'Shayona Cement - Kasungu', 'Central', 'Kasungu', null, 'Shayona Cement(1994, 공장 Kasungu·본사 Lilongwe) 자체 석회석 채굴 시멘트 1,600 t/일 — Akshar·Buildplast·Thanthwe.', 'Shayona Cement Corporation (1994), plant in Kasungu District, HQ Lilongwe - cement about 1,600 t/day of its own limestone (brands Akshar, Buildplast, Thanthwe).', 'MW check 2026-10-16: cement capacity, not GCC - test CaCO3, Fe, ISO brightness. sales1@shayonacement.com, +265 1 752 791.'),
  ('cement products limited|njeleza', 'Cement Products Ltd - Njeleza', 'Southern', 'Mangochi', null, 'Cement Products Ltd(Njeleza, Mangochi) 현지 석회석 채굴·시멘트(MWEITI).', 'Cement Products Limited (CPL), Njeleza, Mangochi District - quarries local limestone for cement (MWEITI report).', 'MW check 2026-10-16: raw-material lead only. Not added: Bwanje Cement Products, Kulimba Mineral Resources, OG Quarry (old permits). No Malawian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'malawi_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Shayona Cement - Kasungu', 'Limestone owner (cement)', 'Limestone quarry - raw-material lead', 'merchant', 'C', 'gcc'),
  ('Cement Products Ltd - Njeleza', 'Limestone owner (cement)', 'Limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'malawi_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('zamm|cool touch', null, 'zamm|cool touch', null, null, 'MW check 2026-10-16: Zamm Investments (Cool Touch), Six Miles Lilongwe (2016) - virgin and 100 pct recycled toilet tissue, towels, napkins - own machine not confirmed - context only.'),
  ('andrex industries', null, 'andrex industries', null, null, 'MW check 2026-10-16: Andrex Industries Malawi, Zalewa Road Blantyre (1990) - tissue, exercise books, printing - machine not confirmed - context only.'),
  ('unicare', null, 'unicare', null, null, 'MW check 2026-10-16: Unicare (Silky), Area 3 Lilongwe (2017) - tissue rolls and hygiene products - context only.'),
  ('dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', null, 'dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', null, null, 'MW check 2026-10-16: DLPG Malawi (ex Nampak Malawi), Macleod Road Blantyre - conical beverage cartons of Zambian board - context only.'),
  ('kris offset', null, 'kris offset', null, null, 'MW check 2026-10-16: Kris Offset and Screen Printers, Chichiri Blantyre (1983) - corrugated boxes, egg trays, exercise books - context only.'),
  ('capital printing press', null, 'capital printing press', null, null, 'MW check 2026-10-16: Commercial printing, Lilongwe (1984, about 100 staff) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'malawi_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('zamm|cool touch', null, 'zamm|cool touch'),
  ('andrex industries', null, 'andrex industries'),
  ('unicare', null, 'unicare'),
  ('dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', null, 'dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi'),
  ('kris offset', null, 'kris offset'),
  ('capital printing press', null, 'capital printing press')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('zamm|cool touch', null, 'zamm|cool touch', true,
   $pj${"owner": "Zamm Investments", "products": "Zamm Investments (Cool Touch), Six Miles Lilongwe (2016) - virgin and 100 pct recycled toilet tissue, towels, napkins - own machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('andrex industries', null, 'andrex industries', true,
   $pj${"owner": "Andrex Industries", "products": "Andrex Industries Malawi, Zalewa Road Blantyre (1990) - tissue, exercise books, printing - machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unicare', null, 'unicare', true,
   $pj${"owner": "Unicare", "products": "Unicare (Silky), Area 3 Lilongwe (2017) - tissue rolls and hygiene products", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', null, 'dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', true,
   $pj${"owner": "DLPG", "products": "DLPG Malawi (ex Nampak Malawi), Macleod Road Blantyre - conical beverage cartons of Zambian board", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kris offset', null, 'kris offset', true,
   $pj${"owner": "Kris Offset", "products": "Kris Offset and Screen Printers, Chichiri Blantyre (1983) - corrugated boxes, egg trays, exercise books", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('capital printing press', null, 'capital printing press', true,
   $pj${"owner": "Capital Printing Press", "products": "Commercial printing, Lilongwe (1984, about 100 staff)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MW', 'Malawi', 'none',
   $cm$No confirmed paper machine - tissue converters (Zamm Cool Touch, Andrex, Unicare) and carton / box makers - cement limestone only$cm$,
   $cm$Malawi's paper firms are tissue makers (Zamm Investments Cool Touch, Andrex Industries, Unicare Silky) and packaging and printing (DLPG Malawi beverage cartons, Kris Offset boxes and egg trays, Capital Printing Press) - no paper machine confirmed. HS 48 imports about USD 76.6 m in 2024, mainly South Africa, Italy, India, Zimbabwe, Zambia. No paper PCC or GCC: Shayona (Kasungu, 1,600 t/day cement) and Cement Products (Njeleza) quarry limestone.$cm$,
   $cm${"fillers": "Limestone: Shayona, Cement Products. Old permits not added. No PCC or GCC.", "mills": "No confirmed machine. Context: Zamm, Andrex, Unicare, DLPG Malawi, Kris Offset, Capital Printing Press.", "strategy": "Ask Zamm and Andrex whether they run tissue machines, otherwise trace their jumbo-roll suppliers (ZA, ZM).", "risks": "No direct volume, landlocked.", "next_steps": ["Ask Zamm and Andrex about tissue machines"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 76.6 m"}], "files": ["seed_20261016zzzq_malawi_market"]}$cm$::jsonb,
   $cm$초지기 미확인 — 티슈 가공(Zamm Cool Touch, Andrex, Unicare)·카톤·상자 업체 — 시멘트용 석회석뿐$cm$,
   $cm$말라위 종이 업체는 티슈(Zamm Investments Cool Touch, Andrex Industries, Unicare Silky)와 포장·인쇄(DLPG Malawi 음료 카톤, Kris Offset 상자·난좌, Capital Printing Press) — 초지기 미확인. HS 48 수입 2024 약 7,661만 달러(남아공·이탈리아·인도·짐바브웨·잠비아). 제지용 PCC·GCC 없음: Shayona(Kasungu, 시멘트 1,600 t/일)·Cement Products(Njeleza) 석회석.$cm$,
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
      ('zamm|cool touch', null, 'zamm|cool touch'),
  ('andrex industries', null, 'andrex industries'),
  ('unicare', null, 'unicare'),
  ('dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi', null, 'dlpg.*malawi|diversified liquid packaging.*malawi|nampak malawi'),
  ('kris offset', null, 'kris offset'),
  ('capital printing press', null, 'capital printing press')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'malawi_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'malawi_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'shayona' or p.party_name ~* 'cement products limited|njeleza')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MW'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MW'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MW'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    