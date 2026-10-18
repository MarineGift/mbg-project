-- ============================================================
-- seed_20261016zzza_mauritania_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mauritania update (reports 2026-10-17). No paper machine - no mill rows.
-- 1) Filler if missing (1): Carmeuse Mauritania (hydrated lime).
-- 2) Context, match only (7): corrugated and sack converters.
-- 3) app.country_markets MR row (priority none).
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
           v.party_name, 'MR', v.region, v.city, v.website, 'active', 'mauritania_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('carmeuse.*(mauritan|nouakchott)', 'Carmeuse Mauritania - Nouakchott', 'Nouakchott', 'Nouakchott', null, 'Carmeuse Trading & Services Mauritania — 누악쇼트 우정항 Wharf 산업지구, 생석회 수입·수화석회 제조(10 t/h)·저장·유통, 광업·산업 고객.', 'Carmeuse Trading and Services Mauritania, Wharf industrial zone by the Port of Friendship, Nouakchott - imports quicklime and runs a 10 t/h hydration plant for hydrated lime, storage and distribution to mining and industry.', 'MR check 2026-10-16: not a PCC plant. PCC lime route only. Not added: Ciment de Mauritanie, MAFCI (400 kt cement), CIMAF, Cinord, Mauricim (cement grinding). 2024 CaCO3 imports (HS 283650) about 12.9 kt, USD 2.54 m - mainly Egypt, Türkiye, Morocco, Tunisia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('carmeuse.*(mauritan|nouakchott)', 'Carmeuse Mauritania - Nouakchott', 'Nouakchott', 'Nouakchott', null, 'Carmeuse Trading & Services Mauritania — 누악쇼트 우정항 Wharf 산업지구, 생석회 수입·수화석회 제조(10 t/h)·저장·유통, 광업·산업 고객.', 'Carmeuse Trading and Services Mauritania, Wharf industrial zone by the Port of Friendship, Nouakchott - imports quicklime and runs a 10 t/h hydration plant for hydrated lime, storage and distribution to mining and industry.', 'MR check 2026-10-16: not a PCC plant. PCC lime route only. Not added: Ciment de Mauritanie, MAFCI (400 kt cement), CIMAF, Cinord, Mauricim (cement grinding). 2024 CaCO3 imports (HS 283650) about 12.9 kt, USD 2.54 m - mainly Egypt, Türkiye, Morocco, Tunisia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'mauritania_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Carmeuse Mauritania - Nouakchott', 'Lime producer', 'Hydrated lime - PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'mauritania_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', null, 'mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', null, null, 'MR check 2026-10-16: Klingele / Mauripack corrugated processing plants, Nouakchott (2015) and Nouadhibou (2011), about 16 staff each - context only.'),
  ('\mspie\M', null, '\mspie\M', null, null, 'MR check 2026-10-16: SPIE SA (1993), Nouadhibou port - fish-export corrugated boxes, about 4 m boxes/yr stated - context only.'),
  ('smpco', null, 'smpco', null, null, 'MR check 2026-10-16: SMPCO SA (2025), Nouakchott - corrugated board and boxes - context only.'),
  ('sipe', null, 'sipe', null, null, 'MR check 2026-10-16: SIPE CARTON, Nouakchott - boxes of imported board (since 1976) - context only.'),
  ('somacar', null, 'somacar', null, null, 'MR check 2026-10-16: SOMACAR, Nouadhibou - paper and board packaging - context only.'),
  ('maurisac', null, 'maurisac', null, null, 'MR check 2026-10-16: MAURISAC, Nouakchott - kraft sacks - context only.'),
  ('mauritano chinoise', null, 'mauritano chinoise', null, null, 'MR check 2026-10-16: Board packaging, Nouadhibou - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'mauritania_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', null, 'mauripack|klingele.*(mauritan|nouakchott|nouadhibou)'),
  ('\mspie\M', null, '\mspie\M'),
  ('smpco', null, 'smpco'),
  ('sipe', null, 'sipe'),
  ('somacar', null, 'somacar'),
  ('maurisac', null, 'maurisac'),
  ('mauritano chinoise', null, 'mauritano chinoise')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', null, 'mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', true,
   $pj${"owner": "Klingele Group", "products": "Klingele / Mauripack corrugated processing plants, Nouakchott (2015) and Nouadhibou (2011), about 16 staff each", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mspie\M', null, '\mspie\M', true,
   $pj${"owner": "AON Group", "products": "SPIE SA (1993), Nouadhibou port - fish-export corrugated boxes, about 4 m boxes/yr stated", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smpco', null, 'smpco', true,
   $pj${"owner": "SMPCO", "products": "SMPCO SA (2025), Nouakchott - corrugated board and boxes", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sipe', null, 'sipe', true,
   $pj${"owner": "SIPE", "products": "SIPE CARTON, Nouakchott - boxes of imported board (since 1976)", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('somacar', null, 'somacar', true,
   $pj${"owner": "SOMACAR", "products": "SOMACAR, Nouadhibou - paper and board packaging", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('maurisac', null, 'maurisac', true,
   $pj${"owner": "MAURISAC", "products": "MAURISAC, Nouakchott - kraft sacks", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mauritano chinoise', null, 'mauritano chinoise', true,
   $pj${"owner": "Mauritano Chinoise de Carton", "products": "Board packaging, Nouadhibou", "approach": "Converter - trace base-paper suppliers (MA, ES, TR).", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MR', 'Mauritania', 'none',
   $cm$No paper machine - corrugated and sack converters on imported base paper (Mauripack, SPIE) - Carmeuse hydrated lime, CaCO3 imported (12.9 kt in 2024)$cm$,
   $cm$Mauritania has no paper machine. The government GHG inventory lists five packaging plants (2018) that convert imported base paper to corrugated boxes and kraft sacks: Klingele / Mauripack (Nouakchott and Nouadhibou), SPIE (fish-export boxes, about 4 m/yr), SIPE Carton, SOMACAR, MAURISAC, Mauritano Chinoise de Carton, plus new SMPCO (2025). HS 48 imports about USD 41.9 m in 2024 (Spain, Morocco, Türkiye, China). Carbonate: Carmeuse hydrated-lime plant (10 t/h) at Nouakchott port, cement grinders - no paper PCC or GCC. CaCO3 imports about 12.9 kt (2024).$cm$,
   $cm${"fillers": "Lime: Carmeuse Mauritania. Cement grinders only. CaCO3 imported (EG, TR, MA, TN).", "mills": "No paper machine. Converters: Mauripack, SPIE, SMPCO, SIPE, SOMACAR, MAURISAC, Mauritano Chinoise de Carton.", "strategy": "No direct sales - reach the base-paper mills supplying these converters (Morocco, Spain, Türkiye) and the Klingele group.", "risks": "No direct volume.", "next_steps": ["Ask Klingele which mills supply Mauripack"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 41.9 m"}, {"label": "CaCO3 imports 2024", "value": "about 12.9 kt"}], "files": ["seed_20261016zzza_mauritania_market"]}$cm$::jsonb,
   $cm$초지기 없음 — 수입 원지로 골판지·포대 가공(Mauripack, SPIE) — Carmeuse 수화석회, CaCO3 수입(2024 1.29만 t)$cm$,
   $cm$모리타니에는 초지기 없음. 정부 온실가스 인벤토리(2018)상 포장 공장 5곳이 수입 원지로 골판지 상자·크라프트 포대 가공: Klingele/Mauripack(누악쇼트·누아디부), SPIE(수산물 상자 연 약 400만 개), SIPE Carton, SOMACAR, MAURISAC, Mauritano Chinoise de Carton, 신규 SMPCO(2025). HS 48 수입 2024 약 4,187만 달러(스페인·모로코·튀르키예·중국). 탄산칼슘: Carmeuse 누악쇼트 수화석회(10 t/h), 시멘트 분쇄 — 제지용 PCC·GCC 없음. CaCO3 수입 약 1.29만 t(2024).$cm$,
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
      ('mauripack|klingele.*(mauritan|nouakchott|nouadhibou)', null, 'mauripack|klingele.*(mauritan|nouakchott|nouadhibou)'),
  ('\mspie\M', null, '\mspie\M'),
  ('smpco', null, 'smpco'),
  ('sipe', null, 'sipe'),
  ('somacar', null, 'somacar'),
  ('maurisac', null, 'maurisac'),
  ('mauritano chinoise', null, 'mauritano chinoise')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'mauritania_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'mauritania_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'carmeuse.*(mauritan|nouakchott)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    