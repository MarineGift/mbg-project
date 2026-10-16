-- ============================================================
-- seed_20261015v_nicaragua_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Nicaragua update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'NI check 2026-10-15'.
-- 1) Filler if missing (1): Calcios de Nicaragua (raw material only).
--    Brenntag (distributor) and Carbotico (Costa Rica) not added.
-- 2) Mill if missing + plant block, priority 1: Innova Industrias (Tipitapa).
--    Context, match only: Empaques Santo Domingo, Envanic, Astro Carton,
--    Industrias Gráficas Mercurio, Ecocentro (converters).
-- 3) app.country_markets NI row (priority low).
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
           v.party_name, 'NI', v.region, v.city, v.website, 'active', 'nicaragua_update_20261015',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcios de nicaragua', 'Calcios de Nicaragua', null, null, null, '니카라과 현지 천연 탄산칼슘(해양 화석 유래) 생산업체. 60 μm~7 mm, 사료·건설·비료·농업·양식 공급.', 'Calcios de Nicaragua (founder Henry Manuel Sánchez, over 20 years) - natural calcium carbonate of marine fossil origin, 60 micron to 7 mm, also lime and quartz, in 45 kg bags and 1 t big bags, in-house and LAQUISA lab tests. Markets feed, construction, fertiliser, agriculture, aquaculture.', 'NI check 2026-10-15: finest grade 60 micron - far coarser than paper filler, no wet grinding or slurry known. Raw-material source only. Not added: Brenntag Nicaragua (distributor, Ciudad Sandino), Carbotico (Costa Rica, Guanacaste). No paper PCC or GCC plant in Nicaragua.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%NI check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcios de nicaragua', 'Calcios de Nicaragua', null, null, null, '니카라과 현지 천연 탄산칼슘(해양 화석 유래) 생산업체. 60 μm~7 mm, 사료·건설·비료·농업·양식 공급.', 'Calcios de Nicaragua (founder Henry Manuel Sánchez, over 20 years) - natural calcium carbonate of marine fossil origin, 60 micron to 7 mm, also lime and quartz, in 45 kg bags and 1 t big bags, in-house and LAQUISA lab tests. Markets feed, construction, fertiliser, agriculture, aquaculture.', 'NI check 2026-10-15: finest grade 60 micron - far coarser than paper filler, no wet grinding or slurry known. Raw-material source only. Not added: Brenntag Nicaragua (distributor, Ciudad Sandino), Carbotico (Costa Rica, Guanacaste). No paper PCC or GCC plant in Nicaragua.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'nicaragua_update_20261015';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calcios de Nicaragua', 'Carbonate raw material', 'Raw-material source only', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'nicaragua_update_20261015'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'NI', v.region, v.city, v.website, 'active', 'nicaragua_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('innova industrias', 'tipitapa', 'innova', 'Innova Industrias (Tipitapa)', 'Managua', 'Tipitapa', null, '2013년 설립 니카라과 자본 티슈 제조사(Tipitapa). 폐지 재활용 화장지(Papiel·Vueno)·냅킨·종이타월, 과거 일 약 15 t 생산.', 'Innova Industrias S.A. (Nicaraguan-owned, founded 2013), Km 19.5 Carretera Vieja a Tipitapa, Managua - tissue on recycled fibre: toilet tissue (Papiel, Vueno), napkins, kitchen and hand towels, jumbo rolls. Historical output about 15 t/day (about 14 t/day waste paper in 2017), 201-500 staff.', 'NI check 2026-10-15: machine width, speed and current output not public. 4,950 t/yr is 15 t/day x 330 (calculated).')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NI check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('innova industrias', 'tipitapa', 'innova', '2013년 설립 니카라과 자본 티슈 제조사(Tipitapa). 폐지 재활용 화장지(Papiel·Vueno)·냅킨·종이타월, 과거 일 약 15 t 생산.', 'Innova Industrias S.A. (Nicaraguan-owned, founded 2013), Km 19.5 Carretera Vieja a Tipitapa, Managua - tissue on recycled fibre: toilet tissue (Papiel, Vueno), napkins, kitchen and hand towels, jumbo rolls. Historical output about 15 t/day (about 14 t/day waste paper in 2017), 201-500 staff.', 'NI check 2026-10-15: machine width, speed and current output not public. 4,950 t/yr is 15 t/day x 330 (calculated).'),
  ('santo domingo', null, 'santo domingo', null, null, 'NI check 2026-10-15: Corrugated boxes - no liner or medium machine found - context only.'),
  ('envanic', null, 'envanic', null, null, 'NI check 2026-10-15: Corrugated boxes - context only.'),
  ('astro (carton|empaques)', null, 'astro (carton|empaques)', null, null, 'NI check 2026-10-15: Paper packaging - machine not confirmed - context only.'),
  ('mercurio', null, 'mercurio', null, null, 'NI check 2026-10-15: Paper bags and multiwall sacks - converter - context only.'),
  ('ecocentro', null, 'ecocentro', null, null, 'NI check 2026-10-15: Waste corrugated recycling (about 2,000 t/yr historical) - paper making not confirmed - context only.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'nicaragua_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('innova industrias', 'tipitapa', 'innova'),
  ('santo domingo', null, 'santo domingo'),
  ('envanic', null, 'envanic'),
  ('astro (carton|empaques)', null, 'astro (carton|empaques)'),
  ('mercurio', null, 'mercurio'),
  ('ecocentro', null, 'ecocentro')
  ) as v(name_rx, city_rx, owner_rx)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('innova industrias', 'tipitapa', 'innova',
   $pj${"owner": "Innova Industrias", "priority": 1, "products": "Toilet tissue, napkins, kitchen and hand towels (recycled fibre)", "grades": ["Tissue"], "capacity": {"value": 4950, "unit": "metric_t", "year": "15 t/day x 330 (historical, calculated)", "source": "local studies"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 3-5 pct - tissue trial at 1, 3, 5 pct."}, "pitch": "Recycled tissue FCC trial (1-3-5 pct)", "approach": "Confirm the machine first. Supply would come by Guatemala, Mexico or Costa Rica producers. Regional scale is Alas Doradas (El Salvador, Grupo Coen).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('santo domingo', null, 'santo domingo',
   $pj${"owner": "Empaques Santo Domingo (Grupo COMECA)", "products": "Corrugated boxes - no liner or medium machine found", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('envanic', null, 'envanic',
   $pj${"owner": "Envanic (Global Packaging Group)", "products": "Corrugated boxes", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('astro (carton|empaques)', null, 'astro (carton|empaques)',
   $pj${"owner": "Astro Carton America / Astro Empaques", "products": "Paper packaging - machine not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('mercurio', null, 'mercurio',
   $pj${"owner": "Industrias Gráficas Mercurio", "products": "Paper bags and multiwall sacks - converter", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('ecocentro', null, 'ecocentro',
   $pj${"owner": "Ecocentro", "products": "Waste corrugated recycling (about 2,000 t/yr historical) - paper making not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'NI', 'Nicaragua', 'low',
   $cm$One small recycled-tissue mill (Innova Industrias, Tipitapa) - no paper PCC or GCC, box converters$cm$,
   $cm$No paper-grade PCC or GCC plant - Calcios de Nicaragua grinds marine-fossil carbonate to 60 micron at best, Brenntag distributes. Calcium carbonate imports 3,459 t in 2024 (Costa Rica, Mexico, Honduras, Guatemala). The only confirmed papermaker is Innova Industrias (recycled tissue, about 15 t/day historical). Others convert boxes and bags. Much waste paper is exported to mills in El Salvador, Costa Rica and Guatemala.$cm$,
   $cm${"fillers": "Calcios de Nicaragua (60 micron - 7 mm, raw material only). Not added: Brenntag Nicaragua (distributor), Carbotico (in Costa Rica). No Omya, SMI or Artemyn plant. HS 283650 imports 2024: 3,459 t, USD 0.96 m.", "mills": "Innova Industrias, Tipitapa - recycled tissue. Converters, no paper machine found: Empaques Santo Domingo (COMECA), Envanic, Astro Carton America, Industrias Gráficas Mercurio, Ecocentro, Papeles y Cartones, Rollam. Kimberly-Clark Nicaragua is distribution only. Alas Doradas (Grupo Coen, 65 kt) is in El Salvador.", "strategy": "Small tissue trial at Innova. For volume, treat Nicaragua with the regional mills - Alas Doradas (El Salvador) and Guatemala, Mexico, Costa Rica producers.", "risks": "Very small volumes, machine data not public.", "next_steps": ["Confirm the Innova paper machine and output", "Add El Salvador (Alas Doradas) when its reports come in"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "USD 292 m (El Salvador, Guatemala, Mexico, Costa Rica lead)"}, {"label": "Tissue base paper imports 2024", "value": "1,205 t (HS 4803)"}, {"label": "Calcium carbonate imports 2024", "value": "3,459 t"}], "files": ["seed_20261015v_nicaragua_mills_fillers"]}$cm$::jsonb,
   $cm$소형 재생 티슈 공장 1곳(Innova Industrias, Tipitapa) — 제지용 PCC·GCC 없음, 골판지 가공업체 중심$cm$,
   $cm$제지용 PCC·GCC 공장 없음(Calcios de Nicaragua 최소 60 μm, Brenntag 는 유통). 2024 탄산칼슘 수입 3,459 t. 원지 제조가 확인된 곳은 Innova Industrias 재생 티슈(과거 일 15 t)뿐, 나머지는 골판지·봉투 가공. 물량은 엘살바도르 Alas Doradas(Grupo Coen) 등 권역 단위로.$cm$,
   149, 248,
   $cm$Innova 15 t/일 × 330일(약 4,950 t) × FCC 3~5% (과거 수치 기반 계산)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('innova industrias', 'tipitapa', 'innova'),
  ('santo domingo', null, 'santo domingo'),
  ('envanic', null, 'envanic'),
  ('astro (carton|empaques)', null, 'astro (carton|empaques)'),
  ('mercurio', null, 'mercurio'),
  ('ecocentro', null, 'ecocentro')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'nicaragua_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'nicaragua_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcios de nicaragua')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'NI'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'NI'
union all
select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
       coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'NI'
  and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
order by 1, 4, 2;
