-- ============================================================
-- seed_20261016zzzw_car_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Central African Republic (CF) update (reports 2026-10-17). No paper
-- machine or filler plant - no rows created. Memos carry a sanctions note.
-- 1) Context, match only (7): Bangui stationers and printers.
-- 2) app.country_markets CF row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CF check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akram', null, 'akram', null, null, 'CF check 2026-10-16: Papeterie and Imprimerie Akram GR. Skaiki, Bangui BP 2084 - paper, stationery and printing - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('papyrus', null, 'papyrus', null, null, 'CF check 2026-10-16: Papeterie Papyrus, Bangui BP 920 - paper and stationery - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('dauphin royal', null, 'dauphin royal', null, null, 'CF check 2026-10-16: Printing and stationery, Av. Léopold Sédar Senghor, Bangui - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('imprimerie centrafricaine', null, 'imprimerie centrafricaine', null, null, 'CF check 2026-10-16: Printing, Bangui BP 329 - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('imprimerie ipc', null, 'imprimerie ipc', null, null, 'CF check 2026-10-16: Printing, Bangui BP 1442 - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('imprimerie ipm', null, 'imprimerie ipm', null, null, 'CF check 2026-10-16: Printing, Bangui BP 1597 - context only. Screen against UN and US Central African Republic sanctions lists.'),
  ('vopijus', null, 'vopijus', null, null, 'CF check 2026-10-16: Printing, Bangui BP 849 - context only. Screen against UN and US Central African Republic sanctions lists.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'car_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akram', null, 'akram'),
  ('papyrus', null, 'papyrus'),
  ('dauphin royal', null, 'dauphin royal'),
  ('imprimerie centrafricaine', null, 'imprimerie centrafricaine'),
  ('imprimerie ipc', null, 'imprimerie ipc'),
  ('imprimerie ipm', null, 'imprimerie ipm'),
  ('vopijus', null, 'vopijus')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akram', null, 'akram', true,
   $pj${"owner": "Akram GR. Skaiki", "products": "Papeterie and Imprimerie Akram GR. Skaiki, Bangui BP 2084 - paper, stationery and printing", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papyrus', null, 'papyrus', true,
   $pj${"owner": "Papyrus", "products": "Papeterie Papyrus, Bangui BP 920 - paper and stationery", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dauphin royal', null, 'dauphin royal', true,
   $pj${"owner": "Dauphin Royal", "products": "Printing and stationery, Av. Léopold Sédar Senghor, Bangui", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imprimerie centrafricaine', null, 'imprimerie centrafricaine', true,
   $pj${"owner": "Imprimerie Centrafricaine", "products": "Printing, Bangui BP 329", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imprimerie ipc', null, 'imprimerie ipc', true,
   $pj${"owner": "IPC", "products": "Printing, Bangui BP 1442", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imprimerie ipm', null, 'imprimerie ipm', true,
   $pj${"owner": "IPM", "products": "Printing, Bangui BP 1597", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vopijus', null, 'vopijus', true,
   $pj${"owner": "Vopijus", "products": "Printing, Bangui BP 849", "approach": "Printer or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CF', 'Central African Republic', 'none',
   $cm$No paper machine or paper filler plant - Bangui printers and stationers only - paper via Cameroon (SAMCO), Mali, Côte d'Ivoire$cm$,
   $cm$The Central African Republic has no confirmed paper mill and no paper PCC or GCC maker. Paper firms are Bangui stationers (Akram, Papyrus) and printers (Dauphin Royal, Imprimerie Centrafricaine, IPC, IPM, Vopijus). HS 48 imports about USD 6.44 m in 2024 (Mali, Côte d'Ivoire, Cameroon, China, France). Cameroon's SAMCO Paper (Limbe, sheeting plant at Ombe) sells to CAR buyers. Sanctions screening applies.$cm$,
   $cm${"fillers": "None.", "mills": "No paper machine. Context: two stationers, five printers in Bangui.", "strategy": "None direct - trace the base-paper mills behind SAMCO (CM) and Ivorian suppliers.", "risks": "Security, sanctions, landlocked logistics.", "next_steps": [], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 6.44 m"}], "files": ["seed_20261016zzzw_car_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — 방기 인쇄·문구업체뿐 — 카메룬(SAMCO)·말리·코트디부아르 경유$cm$,
   $cm$중앙아프리카공화국에는 확인된 제지공장·제지용 PCC·GCC 제조사 없음. 종이 관련은 방기 문구점(Akram, Papyrus)과 인쇄소(Dauphin Royal, Imprimerie Centrafricaine, IPC, IPM, Vopijus). HS 48 수입 2024 약 644만 달러(말리·코트디부아르·카메룬·중국·프랑스). 카메룬 SAMCO Paper(Limbe, Ombe 재단공장)가 CAR 구매자에게 판매. 제재 확인 필요.$cm$,
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
      ('akram', null, 'akram'),
  ('papyrus', null, 'papyrus'),
  ('dauphin royal', null, 'dauphin royal'),
  ('imprimerie centrafricaine', null, 'imprimerie centrafricaine'),
  ('imprimerie ipc', null, 'imprimerie ipc'),
  ('imprimerie ipm', null, 'imprimerie ipm'),
  ('vopijus', null, 'vopijus')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'car_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'car_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CF'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CF'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CF'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    