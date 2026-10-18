-- ============================================================
-- seed_20261016zzn_estonia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Estonia update (reports 2026-10-16). Fixed generator.
-- Nordkalk guard is Estonia-specific (FI, SE, PL Nordkalk rows stay apart).
-- 1) Filler if missing (1): Nordkalk Estonia Rakke.
-- 2) Mills if missing (2) + plant blocks: Räpina Paberivabrik (1), Horizon
--    Kehra (2). Context (5): Estonian Cell, DS Smith, Stora Enso Packaging,
--    Nefab, Kohila.
-- 3) app.country_markets EE row (priority low).
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
           v.party_name, 'EE', v.region, v.city, v.website, 'active', 'estonia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('nordkalk.*(eston|rakke|vasalemma)', 'Nordkalk Estonia - Rakke', 'Lääne-Viru', 'Rakke', null, 'Nordkalk AS 에스토니아 — Rakke(Faehlmanni 11a) 분쇄·석회로, Karinu 채석, 2025-02 허가 필러 연 15만 t·석회 10만 t 상한(석회로 일시 중단). Vasalemma 채석장(CaCO3 약 95.6~97.4%).', 'Nordkalk AS (Estonia) - Rakke, Faehlmanni 11a: grinding plant and lime kilns, limestone of the nearby Karinu quarry, permit caps 150,000 t/yr fillers and 100,000 t/yr lime (2025-02, kiln idle then). Vasalemma quarry (Lemmaru) with contract grinding, about 95.6-97.4 pct CaCO3 in published samples.', 'EE check 2026-10-16: agricultural, building and environmental grades - permit caps are not paper GCC. +372 326 0720. Nearest paper GCC is Suomen Karbonaatti (FI row). Not added: Heidelberg Materials Kunda (cement, aggregates). No Estonian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%EE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('nordkalk.*(eston|rakke|vasalemma)', 'Nordkalk Estonia - Rakke', 'Lääne-Viru', 'Rakke', null, 'Nordkalk AS 에스토니아 — Rakke(Faehlmanni 11a) 분쇄·석회로, Karinu 채석, 2025-02 허가 필러 연 15만 t·석회 10만 t 상한(석회로 일시 중단). Vasalemma 채석장(CaCO3 약 95.6~97.4%).', 'Nordkalk AS (Estonia) - Rakke, Faehlmanni 11a: grinding plant and lime kilns, limestone of the nearby Karinu quarry, permit caps 150,000 t/yr fillers and 100,000 t/yr lime (2025-02, kiln idle then). Vasalemma quarry (Lemmaru) with contract grinding, about 95.6-97.4 pct CaCO3 in published samples.', 'EE check 2026-10-16: agricultural, building and environmental grades - permit caps are not paper GCC. +372 326 0720. Nearest paper GCC is Suomen Karbonaatti (FI row). Not added: Heidelberg Materials Kunda (cement, aggregates). No Estonian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'estonia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Nordkalk Estonia - Rakke', 'Limestone and lime producer', 'Limestone fillers and lime - possible local FCC site', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'estonia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'EE', v.region, v.city, v.website, 'active', 'estonia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('r[aä]pina|rappin', 'r[aä]pina', 'r[aä]pina|rappin', 'Räpina Paberivabrik - Räpina', 'Põlva', 'Räpina', null, 'Räpina Paberivabrik(1734~, Pargi 23) 회수 폐지 100% 재생 판지·포장지·모서리 보호대 180~540 gsm, 자체 초지기, 2025 매출 1,662만 유로.', 'Räpina Paberivabrik AS, Pargi 23, Räpina (oldest Estonian industrial company) - 100 pct recovered paper, own pulping, cleaning, refining and board machine, recycled board 180-540 gsm, packaging paper and edge protectors. 2025 sales about EUR 16.6 m.', 'EE check 2026-10-16: strength-led recycled board. rappin@rappin.ee, +372 799 8240.'),
  ('horizon', 'kehra', 'horizon|tolaram', 'Horizon Pulp & Paper - Kehra', 'Harju', 'Kehra', null, 'Horizon Tselluloosi ja Paberi(1938, Anija mnt 10, Kehra, Tolaram) 통합 펄프·제지 — 미표백 장섬유 색크라프트 50~100 gsm, 70개국+ 수출, 2025 매출 약 3,497만 유로.', 'Horizon Tselluloosi ja Paberi AS (Kehra mill since 1938, Tolaram Group, Singapore), Anija mnt 10, Kehra - integrated pulp and paper, unbleached long-fibre sack kraft 50-100 gsm (standard, semi- and fully extensible), exported to over 70 countries. 2025 sales about EUR 35.0 m.', 'EE check 2026-10-16: strength, TEA, stretch and porosity critical. info@horizon.ee, +372 608 5007.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%EE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('r[aä]pina|rappin', 'r[aä]pina', 'r[aä]pina|rappin', 'Räpina Paberivabrik(1734~, Pargi 23) 회수 폐지 100% 재생 판지·포장지·모서리 보호대 180~540 gsm, 자체 초지기, 2025 매출 1,662만 유로.', 'Räpina Paberivabrik AS, Pargi 23, Räpina (oldest Estonian industrial company) - 100 pct recovered paper, own pulping, cleaning, refining and board machine, recycled board 180-540 gsm, packaging paper and edge protectors. 2025 sales about EUR 16.6 m.', 'EE check 2026-10-16: strength-led recycled board. rappin@rappin.ee, +372 799 8240.'),
  ('horizon', 'kehra', 'horizon|tolaram', 'Horizon Tselluloosi ja Paberi(1938, Anija mnt 10, Kehra, Tolaram) 통합 펄프·제지 — 미표백 장섬유 색크라프트 50~100 gsm, 70개국+ 수출, 2025 매출 약 3,497만 유로.', 'Horizon Tselluloosi ja Paberi AS (Kehra mill since 1938, Tolaram Group, Singapore), Anija mnt 10, Kehra - integrated pulp and paper, unbleached long-fibre sack kraft 50-100 gsm (standard, semi- and fully extensible), exported to over 70 countries. 2025 sales about EUR 35.0 m.', 'EE check 2026-10-16: strength, TEA, stretch and porosity critical. info@horizon.ee, +372 608 5007.'),
  ('estonian cell', null, 'estonian cell', null, null, 'EE check 2026-10-16: Estonian Cell Kunda - aspen BCTMP 170 kt nominal, 127.7 kt in 2025 (2-month stop 2025-07) - pulp only, group link to Heinzel AT mills - context only.'),
  ('ds smith.*eston', null, 'ds smith.*eston', null, null, 'EE check 2026-10-16: DS Smith Packaging Estonia, Tallinn - corrugated converting - context only.'),
  ('stora enso.*(eston|t[aä]nassilma)', null, 'stora enso.*(eston|t[aä]nassilma)', null, null, 'EE check 2026-10-16: Stora Enso Packaging, Tänassilma - packaging - context only.'),
  ('nefab', null, 'nefab', null, null, 'EE check 2026-10-16: Industrial packaging, Lagedi - context only.'),
  ('kohila', null, 'kohila', null, null, 'EE check 2026-10-16: Former paper mill, Kohila - status to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'estonia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('r[aä]pina|rappin', 'r[aä]pina', 'r[aä]pina|rappin'),
  ('horizon', 'kehra', 'horizon|tolaram'),
  ('estonian cell', null, 'estonian cell'),
  ('ds smith.*eston', null, 'ds smith.*eston'),
  ('stora enso.*(eston|t[aä]nassilma)', null, 'stora enso.*(eston|t[aä]nassilma)'),
  ('nefab', null, 'nefab'),
  ('kohila', null, 'kohila')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('r[aä]pina|rappin', 'r[aä]pina', 'r[aä]pina|rappin', false,
   $pj${"owner": "Räpina Paberivabrik", "priority": 1, "products": "Recycled board, edge protectors", "grades": ["Board"], "approach": "Pilot trial - SCT, burst, internal bond, drainage.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('horizon', 'kehra', 'horizon|tolaram', false,
   $pj${"owner": "Tolaram Group", "priority": 2, "products": "Unbleached sack kraft", "grades": ["Sack kraft"], "approach": "Fibre-saving test - strength critical.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('estonian cell', null, 'estonian cell', true,
   $pj${"owner": "Heinzel Group", "products": "Estonian Cell Kunda - aspen BCTMP 170 kt nominal, 127.7 kt in 2025 (2-month stop 2025-07) - pulp only, group link to Heinzel AT mills", "approach": "Pulp, converter or historical.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*eston', null, 'ds smith.*eston', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "DS Smith Packaging Estonia, Tallinn - corrugated converting", "approach": "Pulp, converter or historical.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*(eston|t[aä]nassilma)', null, 'stora enso.*(eston|t[aä]nassilma)', true,
   $pj${"owner": "Stora Enso", "products": "Stora Enso Packaging, Tänassilma - packaging", "approach": "Pulp, converter or historical.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nefab', null, 'nefab', true,
   $pj${"owner": "Nefab", "products": "Industrial packaging, Lagedi", "approach": "Pulp, converter or historical.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kohila', null, 'kohila', true,
   $pj${"owner": "Kohila Paber", "products": "Former paper mill, Kohila - status to confirm", "approach": "Pulp, converter or historical.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'EE', 'Estonia', 'low',
   $cm$Räpina recycled board and Horizon Kehra sack kraft - Estonian Cell BCTMP (Heinzel) - Nordkalk Rakke limestone, no paper PCC or GCC$cm$,
   $cm$Estonia's paper machines: Räpina Paberivabrik (100 pct recovered-fibre board 180-540 gsm) and Horizon Pulp & Paper Kehra (unbleached sack kraft, Tolaram). Estonian Cell Kunda makes aspen BCTMP (170 kt nominal, 127.7 kt 2025, Heinzel). DS Smith, Stora Enso and Nefab convert packaging. No white printing or large tissue machine. Fillers: Nordkalk Rakke (permit 150 kt fillers, agricultural and building grades) and Vasalemma - no paper PCC or GCC, nearest paper GCC in Finland.$cm$,
   $cm${"fillers": "Limestone fillers and lime: Nordkalk Rakke and Vasalemma. Not added: Heidelberg Materials Kunda. Nearest paper GCC: Suomen Karbonaatti (FI).", "mills": "Board: Räpina. Sack kraft: Horizon Kehra. Context: Estonian Cell (BCTMP), DS Smith, Stora Enso Packaging, Nefab, Kohila (historical).", "strategy": "Räpina pilot for recycled board, Horizon strength test. Use Estonian Cell / Heinzel as a link to Austrian mills. Volumes sit in Finland and Sweden.", "risks": "Strength-led grades only.", "next_steps": ["Offer a pilot to Räpina Paberivabrik"], "key_numbers": [{"label": "Estonian Cell 2025", "value": "127.7 kt BCTMP"}, {"label": "Nordkalk Rakke permit", "value": "150 kt fillers, 100 kt lime"}], "files": ["seed_20261016zzn_estonia_mills_fillers"]}$cm$::jsonb,
   $cm$Räpina 재생 판지·Horizon Kehra 색크라프트 — Estonian Cell BCTMP(Heinzel) — Nordkalk Rakke 석회석, 제지용 PCC·GCC 없음$cm$,
   $cm$에스토니아 초지기: Räpina Paberivabrik(회수지 100% 판지 180~540 gsm), Horizon Kehra(미표백 색크라프트, Tolaram). Estonian Cell Kunda 아스펜 BCTMP(공칭 17만, 2025 12.77만 t, Heinzel). DS Smith·Stora Enso·Nefab 은 포장 가공. 백색 인쇄용지·대형 티슈 초지기 없음. 충전제: Nordkalk Rakke(필러 15만 t 허가, 농업·건설용)·Vasalemma — 제지용 PCC·GCC 없음, 가장 가까운 제지용 GCC 는 핀란드.$cm$,
   null, null,
   $cm$생산량 미공개, 강도 지종뿐 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('r[aä]pina|rappin', 'r[aä]pina', 'r[aä]pina|rappin'),
  ('horizon', 'kehra', 'horizon|tolaram'),
  ('estonian cell', null, 'estonian cell'),
  ('ds smith.*eston', null, 'ds smith.*eston'),
  ('stora enso.*(eston|t[aä]nassilma)', null, 'stora enso.*(eston|t[aä]nassilma)'),
  ('nefab', null, 'nefab'),
  ('kohila', null, 'kohila')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'estonia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'estonia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'nordkalk.*(eston|rakke|vasalemma)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'EE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'EE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'EE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    