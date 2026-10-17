-- ============================================================
-- seed_20261016zzd_luxembourg_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Luxembourg update (reports 2026-10-16). No paper machine and no paper
-- filler plant - no rows created.
-- 1) Context, match only (1): COREX Luxembourg.
-- 2) app.country_markets LU row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LU check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('corex', 'niederkorn|differdange', 'corex', null, null, 'LU check 2026-10-16: COREX Luxembourg S.A. (B29267), 13 Z.I. Hahneboesch, Niederkorn - cardboard tubes and winding cores since 1988, about 16,500 t/yr in 2002 - converter, context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'luxembourg_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('corex', 'niederkorn|differdange', 'corex')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('corex', 'niederkorn|differdange', 'corex', true,
   $pj${"owner": "COREX Group", "products": "Cardboard tubes and cores", "approach": "Converter - trace core-board supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'LU', 'Luxembourg', 'none',
   $cm$No paper machine or paper filler plant - COREX tube converter, Garda Group holding (Cartiere del Garda, IT) - served by BE, DE, FR$cm$,
   $cm$Luxembourg has no confirmed paper machine (about 8 NACE 17 firms, mostly converters - historical mills at Manternach, Mühlenbach, Echternach, Diekirch are gone). COREX Luxembourg makes cardboard tubes at Niederkorn. Garda Group, a Luxembourg holding set up after the 2026-04 Lecta restructuring, owns Cartiere del Garda (Riva del Garda, Italy). No paper PCC or GCC. Treat as part of the BE-DE-FR zone - nearest real mill is Burgo Ardennes at Virton (BE).$cm$,
   $cm${"fillers": "None. Supply by Omya, Sibelco, Carmeuse, SMI in neighbouring countries.", "mills": "No paper machine. Context: COREX Luxembourg. Related: Garda Group (holding of Cartiere del Garda, IT row), Burgo Ardennes Virton (BE row).", "strategy": "No direct sales - Garda Group as a door to Cartiere del Garda, Burgo Ardennes trial next door.", "risks": "No direct volume.", "next_steps": ["Approach Garda Group for Cartiere del Garda"], "key_numbers": [{"label": "NACE 17 firms", "value": "about 8, mostly converters"}], "files": ["seed_20261016zzd_luxembourg_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — COREX 지관 가공, Garda Group 지주사(이탈리아 Cartiere del Garda) — BE·DE·FR 권역으로 관리$cm$,
   $cm$룩셈부르크에는 초지기 확인 없음(NACE 17 등록 약 8곳, 대부분 가공 — Manternach·Mühlenbach·Echternach·Diekirch 등 과거 공장은 없음). COREX Luxembourg 가 Niederkorn 에서 지관 제조. 2026-04 Lecta 구조조정 후 설립된 룩셈부르크 지주사 Garda Group 이 이탈리아 Cartiere del Garda 소유. 제지용 PCC·GCC 없음. BE·DE·FR 권역에 포함 — 가장 가까운 실제 공장은 벨기에 Virton 의 Burgo Ardennes.$cm$,
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
      ('corex', 'niederkorn|differdange', 'corex')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'luxembourg_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'luxembourg_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'LU'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'LU'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'LU'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    