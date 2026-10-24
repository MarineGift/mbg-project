-- ============================================================
-- seed_20261017h_guinea_bissau_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Guinea-Bissau (GW) update (reports 2026-10-17). No paper machine or
-- filler plant - no rows created.
-- 1) Context, match only (7): Sankofa Works and Bissau printers.
-- 2) app.country_markets GW row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GW check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sankofa|softy', null, 'sankofa|softy', null, null, 'GW check 2026-10-17: Sankofa Works (Softy), Bissau - tissue rewinding of bought jumbo rolls (FCFA 32.8 m plan) - context only.'),
  ('inacep', null, 'inacep', null, null, 'GW check 2026-10-17: INACEP (1978), Bissau - state printer - context only.'),
  ('kamatchol', null, 'kamatchol', null, null, 'GW check 2026-10-17: Kamatchol Gráfica, Bissau - printing, labels, packaging, paper bags - context only.'),
  ('bcassama', null, 'bcassama', null, null, 'GW check 2026-10-17: Bcassama Gráfica, Bairro Militar Bissau - digital and offset printing - context only.'),
  ('mille impress', null, 'mille impress', null, null, 'GW check 2026-10-17: Printing, Bissau (2010) - context only.'),
  ('copytop', null, 'copytop', null, null, 'GW check 2026-10-17: Gráfica Copytop, Bissau (2017) - context only.'),
  ('central gr[aá]fica', null, 'central gr[aá]fica', null, null, 'GW check 2026-10-17: Printing, Bissau (2018) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'guinea_bissau_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sankofa|softy', null, 'sankofa|softy'),
  ('inacep', null, 'inacep'),
  ('kamatchol', null, 'kamatchol'),
  ('bcassama', null, 'bcassama'),
  ('mille impress', null, 'mille impress'),
  ('copytop', null, 'copytop'),
  ('central gr[aá]fica', null, 'central gr[aá]fica')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sankofa|softy', null, 'sankofa|softy', true,
   $pj${"owner": "Sankofa Capital Group", "products": "Sankofa Works (Softy), Bissau - tissue rewinding of bought jumbo rolls (FCFA 32.8 m plan)", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('inacep', null, 'inacep', true,
   $pj${"owner": "State", "products": "INACEP (1978), Bissau - state printer", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('kamatchol', null, 'kamatchol', true,
   $pj${"owner": "Kamatchol", "products": "Kamatchol Gráfica, Bissau - printing, labels, packaging, paper bags", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('bcassama', null, 'bcassama', true,
   $pj${"owner": "Bcassama Tecnologias", "products": "Bcassama Gráfica, Bairro Militar Bissau - digital and offset printing", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('mille impress', null, 'mille impress', true,
   $pj${"owner": "Mille Impressão", "products": "Printing, Bissau (2010)", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('copytop', null, 'copytop', true,
   $pj${"owner": "Copytop", "products": "Gráfica Copytop, Bissau (2017)", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('central gr[aá]fica', null, 'central gr[aá]fica', true,
   $pj${"owner": "Central Gráfica", "products": "Printing, Bissau (2018)", "approach": "Converter or printer.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GW', 'Guinea-Bissau', 'none',
   $cm$No paper machine or paper filler plant - Sankofa Works (Softy) tissue rewinding and Bissau printers$cm$,
   $cm$Guinea-Bissau has no confirmed paper machine and no paper PCC or GCC maker. Sankofa Works (Softy brand) rewinds bought jumbo rolls in Bissau. Printers: INACEP, Mille Impressão, 360v2, INNOVA-SERVICE, Copytop, Central Gráfica, Alvalade, Nô Gráfica, Bcassama, Kamatchol. Small paper imports of Senegal, China, Türkiye, India. An IndexBox estimate of 273 t pulp output has no named plant.$cm$,
   $cm${"fillers": "None.", "mills": "No paper machine. Context: Sankofa Works and printers.", "strategy": "None direct - treat with Senegal.", "risks": "No volume.", "next_steps": [], "key_numbers": [], "files": ["seed_20261017h_guinea_bissau_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — Sankofa Works(Softy) 티슈 재권취·비사우 인쇄업체$cm$,
   $cm$기니비사우에는 확인된 초지기·제지용 PCC·GCC 제조사 없음. Sankofa Works(Softy)가 구매 점보롤을 비사우에서 재권취. 인쇄: INACEP, Mille Impressão, 360v2, INNOVA-SERVICE, Copytop, Central Gráfica, Alvalade, Nô Gráfica, Bcassama, Kamatchol. 종이 소량 수입(세네갈·중국·튀르키예·인도). IndexBox 펄프 273 t 추정은 공장명 없음.$cm$,
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
      ('sankofa|softy', null, 'sankofa|softy'),
  ('inacep', null, 'inacep'),
  ('kamatchol', null, 'kamatchol'),
  ('bcassama', null, 'bcassama'),
  ('mille impress', null, 'mille impress'),
  ('copytop', null, 'copytop'),
  ('central gr[aá]fica', null, 'central gr[aá]fica')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'guinea_bissau_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'guinea_bissau_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GW'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GW'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GW'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    