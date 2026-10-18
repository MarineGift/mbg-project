-- ============================================================
-- seed_20261016zzze_eritrea_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Eritrea update (reports 2026-10-17). No running paper machine or paper
-- filler plant - no rows created. Memos carry a sanctions-screening note.
-- 1) Context, match only (5): AMAP, Perrone, Villani (historical), Gejeret,
--    Sabur.
-- 2) app.country_markets ER row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ER check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ER'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('asmara match|\mamap\M', null, 'asmara match|\mamap\M', null, null, 'ER check 2026-10-16: Asmara Match and Paper Factory - historical wrapping paper and board (about 150 t/yr mill, 1946) - status unknown - context only. Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.'),
  ('perrone', null, 'perrone', null, null, 'ER check 2026-10-16: Historical mill off the Asmara-Keren road (1941) - grey and straw paper, board, about 25 t/month - status unknown - context only. Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.'),
  ('villani', null, 'villani', null, null, 'ER check 2026-10-16: Historical brown wrapping paper, Asmara (1950, about 15 staff) - status unknown - context only. Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.'),
  ('gejeret|nakfa corporation', null, 'gejeret|nakfa corporation', null, null, 'ER check 2026-10-16: Gejeret Corrugated Boxes, Asmara - corrugated converting - context only. Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.'),
  ('sabur', null, 'sabur', null, null, 'ER check 2026-10-16: Sabur Printing Press, Asmara (1997) - books and textbooks, about 280 staff in 2011 - context only. Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'eritrea_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ER'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('asmara match|\mamap\M', null, 'asmara match|\mamap\M'),
  ('perrone', null, 'perrone'),
  ('villani', null, 'villani'),
  ('gejeret|nakfa corporation', null, 'gejeret|nakfa corporation'),
  ('sabur', null, 'sabur')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ER'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('asmara match|\mamap\M', null, 'asmara match|\mamap\M', true,
   $pj${"owner": "AMAP", "products": "Asmara Match and Paper Factory - historical wrapping paper and board (about 150 t/yr mill, 1946) - status unknown", "approach": "Historical or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('perrone', null, 'perrone', true,
   $pj${"owner": "Cartiera Fratelli Perrone", "products": "Historical mill off the Asmara-Keren road (1941) - grey and straw paper, board, about 25 t/month - status unknown", "approach": "Historical or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('villani', null, 'villani', true,
   $pj${"owner": "M. Villani", "products": "Historical brown wrapping paper, Asmara (1950, about 15 staff) - status unknown", "approach": "Historical or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gejeret|nakfa corporation', null, 'gejeret|nakfa corporation', true,
   $pj${"owner": "Nakfa Corporation", "products": "Gejeret Corrugated Boxes, Asmara - corrugated converting", "approach": "Historical or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sabur', null, 'sabur', true,
   $pj${"owner": "Sabur Printing", "products": "Sabur Printing Press, Asmara (1997) - books and textbooks, about 280 staff in 2011", "approach": "Historical or converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ER', 'Eritrea', 'none',
   $cm$No running paper machine or paper filler plant - historical small mills (AMAP, Perrone, Villani), corrugated and printing - long-term watch$cm$,
   $cm$Eritrea has no confirmed running paper mill and no paper PCC or GCC maker. Historical mills: Asmara Match and Paper Factory (wrapping paper, about 150 t/yr in 1946), Cartiera Fratelli Perrone (1941, about 25 t/month grey and straw paper), M. Villani (1950, brown wrapping). Today: Gejeret Corrugated Boxes (Nakfa Corporation) and Sabur Printing Press. Limestone and marble exist but no paper-grade data. US sanctions apply to some state entities. Ethiopia and Egypt are the real regional markets.$cm$,
   $cm${"fillers": "None. Possible regional supply: Egypt (Minya GCC), Jordan.", "mills": "No running machine. Context: AMAP, Perrone, Villani (historical), Gejeret, Sabur.", "strategy": "Watch only - focus on Ethiopia and Egypt.", "risks": "Closed economy, sanctions on state entities, no data.", "next_steps": [], "key_numbers": [{"label": "Historical AMAP mill", "value": "about 150 t/yr (1946)"}], "files": ["seed_20261016zzze_eritrea_market"]}$cm$::jsonb,
   $cm$가동 초지기·제지용 충전제 공장 없음 — 과거 소형 공장(AMAP, Perrone, Villani), 골판지·인쇄 — 장기 관찰$cm$,
   $cm$에리트레아에는 가동 확인된 제지공장·제지용 PCC·GCC 제조사 없음. 과거 공장: Asmara Match and Paper(포장지, 1946 연 약 150 t), Cartiera Fratelli Perrone(1941, 월 약 25 t 회색·짚 종이), M. Villani(1950, 갈색 포장지). 현재: Gejeret Corrugated Boxes(Nakfa Corporation), Sabur Printing Press. 석회석·대리석은 있으나 제지 품질 자료 없음. 일부 국가기관에 미국 제재. 실제 지역 시장은 에티오피아·이집트.$cm$,
   null, null,
   $cm$가동 초지기 없음 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('asmara match|\mamap\M', null, 'asmara match|\mamap\M'),
  ('perrone', null, 'perrone'),
  ('villani', null, 'villani'),
  ('gejeret|nakfa corporation', null, 'gejeret|nakfa corporation'),
  ('sabur', null, 'sabur')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'eritrea_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ER'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'eritrea_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ER'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ER'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ER'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ER'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    