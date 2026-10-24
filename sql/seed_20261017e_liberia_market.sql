-- ============================================================
-- seed_20261017e_liberia_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Liberia update (reports 2026-10-17). No paper machine or carbonate
-- source - no rows created.
-- 1) Context, match only (5): tissue and box converters, cement grinders.
-- 2) app.country_markets LR row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LR check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national toiletries', null, 'national toiletries', null, null, 'LR check 2026-10-17: National Toiletries Inc. (CEO Fomba Trawally), Bernard Farm Paynesville - toilet tissue, napkins, towels - imports HS 4803 base rolls, likely converting - context only.'),
  ('doito', null, 'doito', null, null, 'LR check 2026-10-17: Doito Soft Premium Tissue, Congo Town Monrovia - virgin-pulp tissue products and jumbo rolls - machine not confirmed - context only.'),
  ('liberia paper products|caton factory|carton factory', null, 'liberia paper products|caton factory|carton factory', null, null, 'LR check 2026-10-17: Liberia Paper Products and Carton Factory, Ashmun and Johnson St Monrovia - boxes, kraftliner imports, flexo inks - context only.'),
  ('cemenco|liberia cement', null, 'cemenco|liberia cement', null, null, 'LR check 2026-10-17: CEMENCO, Monrovia (1968) - cement grinding 65 t/h, imported clinker - not a carbonate source - context only.'),
  ('fouta cement', null, 'fouta cement', null, null, 'LR check 2026-10-17: Fouta Cement Corporation, Monrovia - cement over 500 kt/yr - not a carbonate source - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'liberia_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national toiletries', null, 'national toiletries'),
  ('doito', null, 'doito'),
  ('liberia paper products|caton factory|carton factory', null, 'liberia paper products|caton factory|carton factory'),
  ('cemenco|liberia cement', null, 'cemenco|liberia cement'),
  ('fouta cement', null, 'fouta cement')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national toiletries', null, 'national toiletries', true,
   $pj${"owner": "National Toiletries", "products": "National Toiletries Inc. (CEO Fomba Trawally), Bernard Farm Paynesville - toilet tissue, napkins, towels - imports HS 4803 base rolls, likely converting", "approach": "Converter or cement grinder.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('doito', null, 'doito', true,
   $pj${"owner": "Doito Soft", "products": "Doito Soft Premium Tissue, Congo Town Monrovia - virgin-pulp tissue products and jumbo rolls - machine not confirmed", "approach": "Converter or cement grinder.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('liberia paper products|caton factory|carton factory', null, 'liberia paper products|caton factory|carton factory', true,
   $pj${"owner": "Liberia Paper Products", "products": "Liberia Paper Products and Carton Factory, Ashmun and Johnson St Monrovia - boxes, kraftliner imports, flexo inks", "approach": "Converter or cement grinder.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('cemenco|liberia cement', null, 'cemenco|liberia cement', true,
   $pj${"owner": "Heidelberg (CEMENCO)", "products": "CEMENCO, Monrovia (1968) - cement grinding 65 t/h, imported clinker - not a carbonate source", "approach": "Converter or cement grinder.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('fouta cement', null, 'fouta cement', true,
   $pj${"owner": "Fouta Cement", "products": "Fouta Cement Corporation, Monrovia - cement over 500 kt/yr - not a carbonate source", "approach": "Converter or cement grinder.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'LR', 'Liberia', 'none',
   $cm$No paper machine or paper filler plant - tissue converters (National Toiletries, Doito Soft) and box maker - cement grinders on imported clinker$cm$,
   $cm$Liberia has no confirmed paper machine. Tissue converters: National Toiletries (Paynesville, imports tissue base rolls), Doito Soft (Congo Town). Box maker: Liberia Paper Products and Carton Factory. Historic firms UNIPAC and VAANG-AHN (1985) also converted imports. HS 48 imports USD 12.0 m in 2024 (China, India, USA, Türkiye), HS 4818 about 2.0 kt. No paper PCC or GCC - CEMENCO and Fouta grind cement on imported clinker. Ghana's Delta Paper Mill sells here.$cm$,
   $cm${"fillers": "None - cement grinders only (CEMENCO, Fouta) on imported clinker.", "mills": "No paper machine. Context: National Toiletries, Doito Soft, Liberia Paper Products and Carton Factory, CEMENCO, Fouta Cement.", "strategy": "Trace jumbo-roll suppliers (China, Egypt, Ghana).", "risks": "No direct volume.", "next_steps": [], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 12.0 m"}, {"label": "HS 4818 imports 2024", "value": "about 2.0 kt"}], "files": ["seed_20261017e_liberia_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — 티슈 가공(National Toiletries, Doito Soft)·상자 업체 — 수입 클링커 시멘트 분쇄뿐$cm$,
   $cm$라이베리아에는 확인된 초지기 없음. 티슈 가공: National Toiletries(Paynesville, 티슈 원지 롤 수입), Doito Soft(Congo Town). 상자: Liberia Paper Products and Carton Factory. 과거 UNIPAC·VAANG-AHN(1985)도 수입품 가공. HS 48 수입 2024 1,197만 달러(중국·인도·미국·튀르키예), HS 4818 약 2천 t. 제지용 PCC·GCC 없음 — CEMENCO·Fouta 는 수입 클링커 시멘트 분쇄. 가나 Delta Paper Mill 이 판매.$cm$,
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
      ('national toiletries', null, 'national toiletries'),
  ('doito', null, 'doito'),
  ('liberia paper products|caton factory|carton factory', null, 'liberia paper products|caton factory|carton factory'),
  ('cemenco|liberia cement', null, 'cemenco|liberia cement'),
  ('fouta cement', null, 'fouta cement')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'liberia_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'liberia_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'LR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'LR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'LR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    