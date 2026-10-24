-- ============================================================
-- seed_20261017f_sierra_leone_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Sierra Leone (SL) update (reports 2026-10-17). No paper machine.
-- 1) Filler if missing (1): Kalmax Resources (limestone claim).
-- 2) Context, match only (4): Devmanco, Flora Tissue, Saltucks, Dorlbee.
-- 3) app.country_markets SL row (priority none).
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
           v.party_name, 'SL', v.region, v.city, v.website, 'active', 'sierra_leone_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('kalmax', 'Kalmax Resources - Freetown', 'Western Area', 'Freetown', null, 'Kalmax Resources(26A Jones St, Freetown) 석회석·지르콘·루타일·일메나이트·금·다이아 채굴·수출 — 석회석 광구·공급능력 주장, 제지·플라스틱·시멘트 용도 소개.', 'Kalmax Resources and Business Development Ltd, 26A Jones Street, Freetown - mining and export of limestone, zircon, rutile, ilmenite, gold and diamonds, claims a limestone deposit and supply capacity, mentions paper, plastics and cement uses.', 'SL check 2026-10-17: claims conflict with older UNIDO view of scarce limestone - verify deposit, purity, output. info@kalmaxresources.com, +232 76 924 182. Coastal shell lime is small, informal, building grade. CaCO3 imports 2,745 t in 2018, mainly Tunisia and Egypt (2023). No Sierra Leonean paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SL check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('kalmax', 'Kalmax Resources - Freetown', 'Western Area', 'Freetown', null, 'Kalmax Resources(26A Jones St, Freetown) 석회석·지르콘·루타일·일메나이트·금·다이아 채굴·수출 — 석회석 광구·공급능력 주장, 제지·플라스틱·시멘트 용도 소개.', 'Kalmax Resources and Business Development Ltd, 26A Jones Street, Freetown - mining and export of limestone, zircon, rutile, ilmenite, gold and diamonds, claims a limestone deposit and supply capacity, mentions paper, plastics and cement uses.', 'SL check 2026-10-17: claims conflict with older UNIDO view of scarce limestone - verify deposit, purity, output. info@kalmaxresources.com, +232 76 924 182. Coastal shell lime is small, informal, building grade. CaCO3 imports 2,745 t in 2018, mainly Tunisia and Egypt (2023). No Sierra Leonean paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'sierra_leone_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Kalmax Resources - Freetown', 'Limestone miner (claimed)', 'Limestone claim - verify first', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'sierra_leone_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SL check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('devmanco|develop manufacturing', null, 'devmanco|develop manufacturing', null, null, 'SL check 2026-10-17: Develop Manufacturing (SL), Freetown - tissue, hygiene and packaging, 200+ staff claimed, machine not confirmed - website mixes a Lebanese group address - context only.'),
  ('flora tissue', null, 'flora tissue', null, null, 'SL check 2026-10-17: Flora Tissue (2024), 110 Wilkinson Road Freetown - tissue products, linked to Devmanco - context only.'),
  ('saltucks', null, 'saltucks', null, null, 'SL check 2026-10-17: Saltucks Investment (Henry O. J. Tucker) - plans A4 copy paper and tissue production - context only.'),
  ('dorlbee', null, 'dorlbee', null, null, 'SL check 2026-10-17: Dorlbee Group, Goderich Freetown - paper and printing services - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'sierra_leone_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('devmanco|develop manufacturing', null, 'devmanco|develop manufacturing'),
  ('flora tissue', null, 'flora tissue'),
  ('saltucks', null, 'saltucks'),
  ('dorlbee', null, 'dorlbee')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('devmanco|develop manufacturing', null, 'devmanco|develop manufacturing', true,
   $pj${"owner": "Develop Manufacturing", "products": "Develop Manufacturing (SL), Freetown - tissue, hygiene and packaging, 200+ staff claimed, machine not confirmed - website mixes a Lebanese group address", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('flora tissue', null, 'flora tissue', true,
   $pj${"owner": "Develop Manufacturing", "products": "Flora Tissue (2024), 110 Wilkinson Road Freetown - tissue products, linked to Devmanco", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('saltucks', null, 'saltucks', true,
   $pj${"owner": "Saltucks Investment", "products": "Saltucks Investment (Henry O. J. Tucker) - plans A4 copy paper and tissue production", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('dorlbee', null, 'dorlbee', true,
   $pj${"owner": "Dorlbee Group", "products": "Dorlbee Group, Goderich Freetown - paper and printing services", "approach": "Converter or project.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SL', 'Sierra Leone', 'none',
   $cm$No paper machine or paper filler plant - tissue converters (Devmanco / Flora Tissue), Saltucks paper plan - Kalmax limestone claim$cm$,
   $cm$Sierra Leone has no confirmed paper machine: Develop Manufacturing and its Flora Tissue brand (Freetown tissue and packaging), Saltucks Investment (planned copy paper and tissue) and Dorlbee (printing). A 2023 buyer RFQ for 36 t of tissue jumbo rolls shows a converting model. No paper PCC or GCC - Kalmax Resources claims limestone (unverified, conflicts with older UNIDO data), shell lime is informal. CaCO3 comes of Tunisia and Egypt.$cm$,
   $cm${"fillers": "Limestone claim: Kalmax Resources. No PCC or GCC.", "mills": "No paper machine. Context: Devmanco, Flora Tissue, Saltucks, Dorlbee.", "strategy": "Watch Saltucks' plan for a design-stage pitch, trace Devmanco's jumbo-roll source.", "risks": "No volume, unverified claims.", "next_steps": [], "key_numbers": [{"label": "CaCO3 imports 2018", "value": "2,745 t"}], "files": ["seed_20261017f_sierra_leone_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — 티슈 가공(Devmanco / Flora Tissue), Saltucks 종이 계획 — Kalmax 석회석 주장$cm$,
   $cm$시에라리온에는 확인된 초지기 없음: Develop Manufacturing 과 Flora Tissue(프리타운 티슈·포장), Saltucks Investment(복사용지·티슈 계획), Dorlbee(인쇄). 2023 티슈 점보롤 36 t 구매 문의 → 가공 모델. 제지용 PCC·GCC 없음 — Kalmax Resources 석회석 주장(미검증, 과거 UNIDO 자료와 상충), 조개껍데기 석회는 소규모. CaCO3 는 튀니지·이집트산.$cm$,
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
      ('devmanco|develop manufacturing', null, 'devmanco|develop manufacturing'),
  ('flora tissue', null, 'flora tissue'),
  ('saltucks', null, 'saltucks'),
  ('dorlbee', null, 'dorlbee')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'sierra_leone_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'sierra_leone_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'kalmax')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SL'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SL'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SL'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    