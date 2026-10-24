-- ============================================================
-- seed_20261017i_gambia_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- The Gambia (GM) update (reports 2026-10-17). No paper machine or carbonate
-- source - no rows created.
-- 1) Context, match only (4): Gampaper, Annaf, Abacous, Harch Cement.
-- 2) app.country_markets GM row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GM check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gampaper', null, 'gampaper', null, null, 'GM check 2026-10-17: Gampaper Industry (2016, Elwely Sidi Haiba), Kanifing Industrial Estate - paper bags and printed bags, 11-50 staff - no paper machine - context only.'),
  ('annaf', null, 'annaf', null, null, 'GM check 2026-10-17: Annaf Group, Kanifing - paper, glass and plastic packaging supply - context only.'),
  ('abacous', null, 'abacous', null, null, 'GM check 2026-10-17: Abacous Group, Kanifing - cake boxes and food packaging supply - context only.'),
  ('harch', null, 'harch', null, null, 'GM check 2026-10-17: Harch Cement - planned 500 kt/yr cement plant at Banjul for 2028 (unverified) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'gambia_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gampaper', null, 'gampaper'),
  ('annaf', null, 'annaf'),
  ('abacous', null, 'abacous'),
  ('harch', null, 'harch')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gampaper', null, 'gampaper', true,
   $pj${"owner": "Gampaper Industry", "products": "Gampaper Industry (2016, Elwely Sidi Haiba), Kanifing Industrial Estate - paper bags and printed bags, 11-50 staff - no paper machine", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('annaf', null, 'annaf', true,
   $pj${"owner": "Annaf Group", "products": "Annaf Group, Kanifing - paper, glass and plastic packaging supply", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('abacous', null, 'abacous', true,
   $pj${"owner": "Abacous Group", "products": "Abacous Group, Kanifing - cake boxes and food packaging supply", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('harch', null, 'harch', true,
   $pj${"owner": "Harch Corp", "products": "Harch Cement - planned 500 kt/yr cement plant at Banjul for 2028 (unverified)", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GM', 'The Gambia', 'none',
   $cm$No paper machine or paper filler plant - Gampaper bag maker and packaging traders - CaCO3 imported (565 t in 2023)$cm$,
   $cm$The Gambia has no paper machine and no paper PCC or GCC maker - the Geological Department found no large limestone deposits. Gampaper Industry (Kanifing) makes paper bags of imported reels, Annaf and Abacous trade packaging, Harch Cement plans a Banjul plant for 2028. HS 48 imports about USD 7.9 m in 2024 (UK, Morocco, China, Senegal). CaCO3 imports 565 t in 2023 (India, Egypt, Vietnam).$cm$,
   $cm${"fillers": "None. CaCO3 imported.", "mills": "No paper machine. Context: Gampaper, Annaf, Abacous, Harch Cement (plan).", "strategy": "None direct - treat with Senegal.", "risks": "No volume.", "next_steps": [], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 7.9 m"}, {"label": "CaCO3 imports 2023", "value": "565 t"}], "files": ["seed_20261017i_gambia_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — Gampaper 종이봉투·포장재 유통 — CaCO3 수입(2023 565 t)$cm$,
   $cm$감비아에는 초지기·제지용 PCC·GCC 제조사 없음 — 지질국 조사상 대규모 석회석 없음. Gampaper Industry(Kanifing)는 수입 원지로 종이봉투, Annaf·Abacous 는 포장재 유통, Harch Cement 는 2028 반줄 공장 계획. HS 48 수입 2024 약 790만 달러(영국·모로코·중국·세네갈). CaCO3 수입 2023 565 t(인도·이집트·베트남).$cm$,
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
      ('gampaper', null, 'gampaper'),
  ('annaf', null, 'annaf'),
  ('abacous', null, 'abacous'),
  ('harch', null, 'harch')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'gambia_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'gambia_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    