-- ============================================================
-- seed_20261016zza_ireland_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Ireland update (reports 2026-10-16). No paper machine - no mills created.
-- Uses the fixed generator (context rows keep existing plant keys).
-- 1) Filler if missing (1): McGraths Limestone (CongCal).
-- 2) Context, match only (8): Smurfit Westrock Irish plants, VPK Limerick,
--    Saica Pack, CavanBox, Aldar Tissues, Dawn Paper, Corrugated Containers
--    Ireland, Pakform.
-- 3) app.country_markets IE row (priority none).
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
           v.party_name, 'IE', v.region, v.city, v.website, 'active', 'ireland_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('mcgraths|congcal', 'McGraths Limestone (CongCal) - Cong', 'Mayo', 'Cong', null, 'Mayo 고순도 석회석 GCC(Cregaree, Cong) — 2007 고사양 설비(파쇄·분쇄·건조·공기분급). CongCal 10m: CaCO3 98.5%, Fe2O3 0.03%, 5 μm 이하 85%, D50 약 2 μm.', 'McGraths Limestone (Cong) Ltd., Cregaree, Cong (Co. Mayo) - high-purity limestone GCC (brand CongCal), specialist plant since 2007 with crushing, grinding, drying and air classification. CongCal 10m: 98.5 pct CaCO3, MgCO3 1.0, SiO2 0.32, Fe2O3 0.03, 100 pct under 10 micron, 85 pct under 5, D50 about 2 micron.', 'IE check 2026-10-16: paper supply, brightness and wet slurry not confirmed. info@mcgraths.ie, +353 94 955 3900. Not added: Roadstone and Grolime members (agricultural ground limestone, about 16 producers at 30 sites). No paper PCC plant in Ireland.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%IE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('mcgraths|congcal', 'McGraths Limestone (CongCal) - Cong', 'Mayo', 'Cong', null, 'Mayo 고순도 석회석 GCC(Cregaree, Cong) — 2007 고사양 설비(파쇄·분쇄·건조·공기분급). CongCal 10m: CaCO3 98.5%, Fe2O3 0.03%, 5 μm 이하 85%, D50 약 2 μm.', 'McGraths Limestone (Cong) Ltd., Cregaree, Cong (Co. Mayo) - high-purity limestone GCC (brand CongCal), specialist plant since 2007 with crushing, grinding, drying and air classification. CongCal 10m: 98.5 pct CaCO3, MgCO3 1.0, SiO2 0.32, Fe2O3 0.03, 100 pct under 10 micron, 85 pct under 5, D50 about 2 micron.', 'IE check 2026-10-16: paper supply, brightness and wet slurry not confirmed. info@mcgraths.ie, +353 94 955 3900. Not added: Roadstone and Grolime members (agricultural ground limestone, about 16 producers at 30 sites). No paper PCC plant in Ireland.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'ireland_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('McGraths Limestone (CongCal) - Cong', 'GCC producer', 'Fine GCC (D50 2 micron) - FCC partner candidate 1', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'ireland_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%IE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', null, 'smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', null, null, 'IE check 2026-10-16: Irish packaging plants (Walkinstown, Cork, Galway, Raheen, Arklow, Westport) - global HQ Dublin, 57 paper mills and about 8.3 Mt worldwide - context only.'),
  ('vpk.*limerick', null, 'vpk.*limerick', null, null, 'IE check 2026-10-16: Limerick corrugator and box plant - plant GM Noel Maguire (2025-12) - context only.'),
  ('saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', null, 'saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', null, null, 'IE check 2026-10-16: Ashbourne and Dublin corrugated packaging (new rotary die-cutter 2026-09) - context only.'),
  ('cavanbox|cavan box', null, 'cavanbox|cavan box', null, null, 'IE check 2026-10-16: Corrugator and boxes, Ballyjamesduff (1983) - context only.'),
  ('aldar', null, 'aldar', null, null, 'IE check 2026-10-16: Aldar Tissues tissue converting, Rathcoole (2022 plant) - context only.'),
  ('dawn paper', null, 'dawn paper', null, null, 'IE check 2026-10-16: Tissue and wipers, Slane - own machine to confirm - context only.'),
  ('corrugated containers.*ireland', null, 'corrugated containers.*ireland', null, null, 'IE check 2026-10-16: Industrial corrugated packaging, Navan - context only.'),
  ('pakform', null, 'pakform', null, null, 'IE check 2026-10-16: Corrugated boxes, Little Island, Cork - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'ireland_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', null, 'smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)'),
  ('vpk.*limerick', null, 'vpk.*limerick'),
  ('saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', null, 'saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne'),
  ('cavanbox|cavan box', null, 'cavanbox|cavan box'),
  ('aldar', null, 'aldar'),
  ('dawn paper', null, 'dawn paper'),
  ('corrugated containers.*ireland', null, 'corrugated containers.*ireland'),
  ('pakform', null, 'pakform')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', null, 'smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', true,
   $pj${"owner": "Smurfit Westrock", "products": "Irish packaging plants (Walkinstown, Cork, Galway, Raheen, Arklow, Westport) - global HQ Dublin, 57 paper mills and about 8.3 Mt worldwide", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vpk.*limerick', null, 'vpk.*limerick', true,
   $pj${"owner": "VPK Group", "products": "Limerick corrugator and box plant - plant GM Noel Maguire (2025-12)", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', null, 'saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', true,
   $pj${"owner": "Saica", "products": "Ashbourne and Dublin corrugated packaging (new rotary die-cutter 2026-09)", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cavanbox|cavan box', null, 'cavanbox|cavan box', true,
   $pj${"owner": "CavanBox", "products": "Corrugator and boxes, Ballyjamesduff (1983)", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('aldar', null, 'aldar', true,
   $pj${"owner": "Zeus Packaging", "products": "Aldar Tissues tissue converting, Rathcoole (2022 plant)", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dawn paper', null, 'dawn paper', true,
   $pj${"owner": "Dawn Paper and Tissue", "products": "Tissue and wipers, Slane - own machine to confirm", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('corrugated containers.*ireland', null, 'corrugated containers.*ireland', true,
   $pj${"owner": "Corrugated Containers Ireland", "products": "Industrial corrugated packaging, Navan", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pakform', null, 'pakform', true,
   $pj${"owner": "Pakform", "products": "Corrugated boxes, Little Island, Cork", "approach": "Converter - reach group paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'IE', 'Ireland', 'none',
   $cm$No paper machine since 2005 (Smurfit Clonskeagh) - packaging and tissue converters, Smurfit Westrock global HQ, CongCal fine GCC$cm$,
   $cm$Ireland lost its last paper mill when Smurfit Clonskeagh closed in 2005. Today it has corrugated and tissue converters (Smurfit Westrock plants, VPK Limerick, Saica Pack, CavanBox, Aldar Tissues, Dawn Paper, Pakform). Value is as a door: Smurfit Westrock's global HQ in Dublin (57 mills, about 8.3 Mt) and the European mills of Saica and VPK. Carbonate: McGraths CongCal fine GCC (D50 about 2 micron) at Cong, agricultural ground limestone elsewhere. No paper PCC.$cm$,
   $cm${"fillers": "Fine GCC: McGraths Limestone (CongCal). Not added: Roadstone, Grolime members (agricultural).", "mills": "No paper machine. Context: Smurfit Westrock Irish plants, VPK Limerick, Saica Pack, CavanBox, Aldar Tissues, Dawn Paper, Corrugated Containers Ireland, Pakform.", "strategy": "Pitch FCC to Smurfit Westrock HQ for its mill network, Saica Paper and VPK mills abroad. Trace tissue converters' base-paper suppliers.", "risks": "No direct volume.", "next_steps": ["Contact Smurfit Westrock HQ R&D and purchasing"], "key_numbers": [{"label": "Last paper mill", "value": "Smurfit Clonskeagh, closed 2005"}, {"label": "Smurfit Westrock", "value": "57 paper mills, about 8.3 Mt"}], "files": ["seed_20261016zza_ireland_fillers"]}$cm$::jsonb,
   $cm$2005년(Smurfit Clonskeagh 폐쇄) 이후 초지기 없음 — 포장·티슈 가공업체, Smurfit Westrock 글로벌 본사, CongCal 미분 GCC$cm$,
   $cm$아일랜드는 2005년 Smurfit Clonskeagh 폐쇄로 마지막 제지공장이 사라짐. 현재는 골판지·티슈 가공업체(Smurfit Westrock 공장들, VPK Limerick, Saica Pack, CavanBox, Aldar, Dawn Paper, Pakform). 가치는 창구 역할: 더블린의 Smurfit Westrock 글로벌 본사(제지공장 57곳, 약 830만 t)와 Saica·VPK 유럽 공장. 탄산칼슘: McGraths CongCal(D50 약 2 μm), 나머지는 농업용. 제지용 PCC 없음.$cm$,
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
      ('smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)', null, 'smurfit.*(ireland|dublin|walkinstown|cork|galway|raheen|arklow|westport)'),
  ('vpk.*limerick', null, 'vpk.*limerick'),
  ('saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne', null, 'saica pack.*(ireland|ashbourne|dublin)|saica.*ashbourne'),
  ('cavanbox|cavan box', null, 'cavanbox|cavan box'),
  ('aldar', null, 'aldar'),
  ('dawn paper', null, 'dawn paper'),
  ('corrugated containers.*ireland', null, 'corrugated containers.*ireland'),
  ('pakform', null, 'pakform')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'ireland_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'ireland_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'mcgraths|congcal')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'IE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'IE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'IE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    