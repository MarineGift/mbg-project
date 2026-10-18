-- ============================================================
-- seed_20261016zzzf_djibouti_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Djibouti update (reports 2026-10-17). No paper machine or paper filler
-- plant - no rows created.
-- 1) Context, match only (6): printers and distributors.
-- 2) app.country_markets DJ row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%DJ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('imprimerie nationale de djibouti', null, 'imprimerie nationale de djibouti', null, null, 'DJ check 2026-10-16: Imprimerie Nationale de Djibouti, Route de l''Aéroport - public printer - context only.'),
  ('n?djed', null, 'n?djed', null, null, 'DJ check 2026-10-16: NDJED / DJED - printing, earlier cut imported paper rolls for school notebooks (1984) - context only.'),
  ('spectrum imprimerie', null, 'spectrum imprimerie', null, null, 'DJ check 2026-10-16: Spectrum Imprimerie - digital and screen printing - context only.'),
  ('weprint|flexy', null, 'weprint|flexy', null, null, 'DJ check 2026-10-16: Weprint.dj - online print service - context only.'),
  ('multi services olympiques', null, 'multi services olympiques', null, null, 'DJ check 2026-10-16: Offset and inkjet printing, advertising (since 1993) - context only.'),
  ('amc papeterie', null, 'amc papeterie', null, null, 'DJ check 2026-10-16: AMC Papeterie - paper and stationery distribution, printing - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'djibouti_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('imprimerie nationale de djibouti', null, 'imprimerie nationale de djibouti'),
  ('n?djed', null, 'n?djed'),
  ('spectrum imprimerie', null, 'spectrum imprimerie'),
  ('weprint|flexy', null, 'weprint|flexy'),
  ('multi services olympiques', null, 'multi services olympiques'),
  ('amc papeterie', null, 'amc papeterie')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('imprimerie nationale de djibouti', null, 'imprimerie nationale de djibouti', true,
   $pj${"owner": "State", "products": "Imprimerie Nationale de Djibouti, Route de l'Aéroport - public printer", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('n?djed', null, 'n?djed', true,
   $pj${"owner": "NDJED", "products": "NDJED / DJED - printing, earlier cut imported paper rolls for school notebooks (1984)", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('spectrum imprimerie', null, 'spectrum imprimerie', true,
   $pj${"owner": "Spectrum", "products": "Spectrum Imprimerie - digital and screen printing", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('weprint|flexy', null, 'weprint|flexy', true,
   $pj${"owner": "Flexy SARL", "products": "Weprint.dj - online print service", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('multi services olympiques', null, 'multi services olympiques', true,
   $pj${"owner": "Multi Services Olympiques", "products": "Offset and inkjet printing, advertising (since 1993)", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('amc papeterie', null, 'amc papeterie', true,
   $pj${"owner": "AMC", "products": "AMC Papeterie - paper and stationery distribution, printing", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'DJ', 'Djibouti', 'none',
   $cm$No paper machine or paper filler plant - printers and paper distributors - port hub re-exporting CaCO3 to Ethiopia$cm$,
   $cm$Djibouti produced no pulp, paper or board (FAO 2019) and has no paper PCC or GCC maker - USGS lists cement, limestone, clay, salt and aggregates. Paper firms are printers and distributors (Imprimerie Nationale, NDJED, Spectrum, Weprint, Multi Services Olympiques, AMC Papeterie). Imports 2023: uncoated paper about 770 t, kraft about 424 t. CaCO3 imports about 1.8 kt in 2023 (Vietnam, Türkiye, UAE), of which about 1.2 kt went on to Ethiopia - a logistics hub for Ethiopian mills.$cm$,
   $cm${"fillers": "None. CaCO3 imported and partly re-exported to Ethiopia.", "mills": "No paper machine. Context: six printers and distributors.", "strategy": "Use the Djibouti and Doraleh ports as the supply route to Ethiopian mills.", "risks": "No local demand.", "next_steps": ["Get the Ethiopia reports"], "key_numbers": [{"label": "CaCO3 imports 2023", "value": "about 1.8 kt"}, {"label": "CaCO3 re-export to Ethiopia 2023", "value": "about 1.2 kt"}], "files": ["seed_20261016zzzf_djibouti_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — 인쇄·종이 유통업체 — 에티오피아로 CaCO3 재수출하는 항만 거점$cm$,
   $cm$지부티는 펄프·종이·판지 생산 없음(FAO 2019), 제지용 PCC·GCC 제조사 없음 — USGS 상 시멘트·석회석·점토·소금·골재. 종이 관련은 인쇄·유통(Imprimerie Nationale, NDJED, Spectrum, Weprint, Multi Services Olympiques, AMC Papeterie). 2023 수입: 비도공지 약 770 t, 크라프트 약 424 t. CaCO3 수입 2023 약 1.8천 t(베트남·튀르키예·UAE), 그중 약 1.2천 t 에티오피아로 — 에티오피아 제지사 물류 거점.$cm$,
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
      ('imprimerie nationale de djibouti', null, 'imprimerie nationale de djibouti'),
  ('n?djed', null, 'n?djed'),
  ('spectrum imprimerie', null, 'spectrum imprimerie'),
  ('weprint|flexy', null, 'weprint|flexy'),
  ('multi services olympiques', null, 'multi services olympiques'),
  ('amc papeterie', null, 'amc papeterie')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'djibouti_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'djibouti_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'DJ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'DJ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'DJ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    