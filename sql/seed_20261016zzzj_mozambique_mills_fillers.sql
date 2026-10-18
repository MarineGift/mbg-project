-- ============================================================
-- seed_20261016zzzj_mozambique_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mozambique update (reports 2026-10-17).
-- 1) Filler if missing (1): Cimentos de Moçambique (Salamanga limestone).
-- 2) Mills if missing (2) + plant blocks: INCEP (1), Ecopac (no priority).
--    Context (7): Portucel pulp project and converters.
-- 3) app.country_markets MZ row (priority none).
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
           v.party_name, 'MZ', v.region, v.city, v.website, 'active', 'mozambique_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cimentos de mo[cç]ambique|salamanga', 'Cimentos de Moçambique (Salamanga limestone)', 'Maputo', 'Matola', null, 'Cimentos de Moçambique — Matola·Dondo·Nacala 시멘트, Matutuine Salamanga 채석장 석회석을 Matola 로 운송.', 'Cimentos de Moçambique - cement at Matola, Dondo and Nacala, long-running Salamanga (Matutuine) limestone quarry feeding Matola.', 'MZ check 2026-10-16: paper-grade quality untested - sample CaCO3, ISO brightness, Fe2O3, SiO2, MgO and ground PSD. Not added: Moçambique Dugongo Cimentos (5,000 t/day cement, Matutuine), CINAC Nacala, Cimentos da Beira (800 kt), Austral Cimentos Sofala (Heidelberg, imported raw materials). No Mozambican paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cimentos de mo[cç]ambique|salamanga', 'Cimentos de Moçambique (Salamanga limestone)', 'Maputo', 'Matola', null, 'Cimentos de Moçambique — Matola·Dondo·Nacala 시멘트, Matutuine Salamanga 채석장 석회석을 Matola 로 운송.', 'Cimentos de Moçambique - cement at Matola, Dondo and Nacala, long-running Salamanga (Matutuine) limestone quarry feeding Matola.', 'MZ check 2026-10-16: paper-grade quality untested - sample CaCO3, ISO brightness, Fe2O3, SiO2, MgO and ground PSD. Not added: Moçambique Dugongo Cimentos (5,000 t/day cement, Matutuine), CINAC Nacala, Cimentos da Beira (800 kt), Austral Cimentos Sofala (Heidelberg, imported raw materials). No Mozambican paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'mozambique_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Cimentos de Moçambique (Salamanga limestone)', 'Limestone owner (cement)', 'Limestone quarry - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'mozambique_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MZ', v.region, v.city, v.website, 'active', 'mozambique_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('incep', 'nacala|nampula|maputo', 'incep', 'INCEP - Nacala', 'Nampula', 'Nacala', null, 'INCEP(1995, 본사 Nampula, 사업장 Nacala, 원지공장 Maputo 표기) — Fluting 원지 월 500 t(연 약 6,000 t)·폭 1,900 mm, 골판지 2.2 m·8색 인쇄, UAE·인도·독일 수출 등록.', 'INCEP Limited (1995, HQ Rua 3 de Fevereiro 29, Nampula, site at Nacala, paper mill listed in Maputo) - fluting paper 500 t/month (about 6,000 t/yr) on a 1,900 mm machine, 2.2 m corrugator and 8-colour printing, exports listed to UAE, India, Germany, customers incl. CarPack.', 'MZ check 2026-10-16: machine location and current output to confirm. CEO Mashur Satar (PaperIndex).'),
  ('ecopac', 'matola|malhampsene', 'ecopac', 'Ecopac Moçambique - Matola', 'Maputo', 'Matola', null, 'Ecopac(Av. Samora Machel Parcela 464, Malhampsene, Matola) — 제지공장 등록, 초지기·제품 미확인.', 'Ecopac Moçambique, Av. Samora Machel Parcela 464, Malhampsene, Matola - listed as a paper mill, machine and products not confirmed.', 'MZ check 2026-10-16: +258 85 041 4400.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('incep', 'nacala|nampula|maputo', 'incep', 'INCEP(1995, 본사 Nampula, 사업장 Nacala, 원지공장 Maputo 표기) — Fluting 원지 월 500 t(연 약 6,000 t)·폭 1,900 mm, 골판지 2.2 m·8색 인쇄, UAE·인도·독일 수출 등록.', 'INCEP Limited (1995, HQ Rua 3 de Fevereiro 29, Nampula, site at Nacala, paper mill listed in Maputo) - fluting paper 500 t/month (about 6,000 t/yr) on a 1,900 mm machine, 2.2 m corrugator and 8-colour printing, exports listed to UAE, India, Germany, customers incl. CarPack.', 'MZ check 2026-10-16: machine location and current output to confirm. CEO Mashur Satar (PaperIndex).'),
  ('ecopac', 'matola|malhampsene', 'ecopac', 'Ecopac(Av. Samora Machel Parcela 464, Malhampsene, Matola) — 제지공장 등록, 초지기·제품 미확인.', 'Ecopac Moçambique, Av. Samora Machel Parcela 464, Malhampsene, Matola - listed as a paper mill, machine and products not confirmed.', 'MZ check 2026-10-16: +258 85 041 4400.'),
  ('portucel.*mo[cç]ambique|portucel moz', null, 'portucel.*mo[cç]ambique|portucel moz', null, null, 'MZ check 2026-10-16: Portucel Moçambique - forestry, planned 1 Mt woodchip and 1.5 Mt pulp mill (2032-34, on hold) - pulp, not a filler user - context only.'),
  ('paper tech', null, 'paper tech', null, null, 'MZ check 2026-10-16: Paper Tech Mozambique, Maputo - paper and board import and converting - context only.'),
  ('carpack', null, 'carpack', null, null, 'MZ check 2026-10-16: CarPack, Av. das Indústrias Maputo - corrugated packaging - context only.'),
  ('mozambique packaging', null, 'mozambique packaging', null, null, 'MZ check 2026-10-16: Paper boxes and packaging, Maputo - context only.'),
  ('\mamal\M.*ind', null, '\mamal\M.*ind', null, null, 'MZ check 2026-10-16: AMAL Indústrias, Beira - packaging - context only.'),
  ('mozindia', null, 'mozindia', null, null, 'MZ check 2026-10-16: Packaging, Beira - context only.'),
  ('right choice packaging', null, 'right choice packaging', null, null, 'MZ check 2026-10-16: Metal, plastic and paper packaging, Boane - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'mozambique_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('incep', 'nacala|nampula|maputo', 'incep'),
  ('ecopac', 'matola|malhampsene', 'ecopac'),
  ('portucel.*mo[cç]ambique|portucel moz', null, 'portucel.*mo[cç]ambique|portucel moz'),
  ('paper tech', null, 'paper tech'),
  ('carpack', null, 'carpack'),
  ('mozambique packaging', null, 'mozambique packaging'),
  ('\mamal\M.*ind', null, '\mamal\M.*ind'),
  ('mozindia', null, 'mozindia'),
  ('right choice packaging', null, 'right choice packaging')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('incep', 'nacala|nampula|maputo', 'incep', false,
   $pj${"owner": "INCEP", "priority": 1, "products": "Fluting, corrugated boxes", "grades": ["Medium"], "capacity_split": [{"label": "Fluting (500 t/month listed)", "value_t": 6000}], "approach": "Pilot strength-hold trial (about 300 t FCC at 5 pct).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ecopac', 'matola|malhampsene', 'ecopac', false,
   $pj${"owner": "Ecopac", "products": "Paper (to confirm)", "grades": [], "approach": "Confirm machine and grade.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('portucel.*mo[cç]ambique|portucel moz', null, 'portucel.*mo[cç]ambique|portucel moz', true,
   $pj${"owner": "The Navigator Company", "products": "Portucel Moçambique - forestry, planned 1 Mt woodchip and 1.5 Mt pulp mill (2032-34, on hold) - pulp, not a filler user", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('paper tech', null, 'paper tech', true,
   $pj${"owner": "Paper Tech", "products": "Paper Tech Mozambique, Maputo - paper and board import and converting", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('carpack', null, 'carpack', true,
   $pj${"owner": "CarPack", "products": "CarPack, Av. das Indústrias Maputo - corrugated packaging", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mozambique packaging', null, 'mozambique packaging', true,
   $pj${"owner": "Mozambique Packaging Industries", "products": "Paper boxes and packaging, Maputo", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mamal\M.*ind', null, '\mamal\M.*ind', true,
   $pj${"owner": "Capital Foods Group", "products": "AMAL Indústrias, Beira - packaging", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mozindia', null, 'mozindia', true,
   $pj${"owner": "Mozindia", "products": "Packaging, Beira", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('right choice packaging', null, 'right choice packaging', true,
   $pj${"owner": "Right Choice Packaging", "products": "Metal, plastic and paper packaging, Boane", "approach": "Pulp project or converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MZ', 'Mozambique', 'none',
   $cm$One small fluting mill (INCEP, about 6 kt), Ecopac to confirm, Portucel pulp project (on hold) - cement limestone only$cm$,
   $cm$Mozambique's paper base is small: INCEP lists a 1,900 mm fluting machine (500 t/month) with corrugating and printing, Ecopac Matola is registered as a paper mill (to confirm). Converters: Paper Tech, CarPack, Mozambique Packaging and others. Portucel Moçambique (The Navigator Company) plans woodchip (1 Mt) and pulp (1.5 Mt, 2032-34, on hold) - pulp is not a filler market. No paper PCC or GCC - Cimentos de Moçambique (Salamanga), Dugongo and other cement makers hold limestone. Serve via South Africa.$cm$,
   $cm${"fillers": "Limestone: Cimentos de Moçambique (Salamanga). Cement makers not added. No PCC or GCC.", "mills": "Fluting: INCEP. To confirm: Ecopac. Context: Portucel (pulp project), Paper Tech, CarPack, Mozambique Packaging, AMAL, Mozindia, Right Choice.", "strategy": "INCEP pilot only, Navigator group link via Portugal (Figueira / Setúbal rows). Volumes sit in South Africa.", "risks": "Tiny volume, project delays.", "next_steps": ["Confirm INCEP machine location and output"], "key_numbers": [{"label": "INCEP fluting", "value": "500 t/month listed"}, {"label": "Portucel pulp plan", "value": "1.5 Mt (on hold)"}], "files": ["seed_20261016zzzj_mozambique_mills_fillers"]}$cm$::jsonb,
   $cm$소형 골심지 공장 1곳(INCEP 약 6천 t), Ecopac 확인 필요, Portucel 펄프 프로젝트(보류) — 시멘트용 석회석뿐$cm$,
   $cm$모잠비크 제지 기반은 작음: INCEP 이 폭 1,900 mm 골심지 초지기(월 500 t)·골판지·인쇄 설비 등록, Ecopac Matola 는 제지공장 등록(확인 필요). 가공: Paper Tech, CarPack, Mozambique Packaging 등. Portucel Moçambique(Navigator)는 목재칩 100만·펄프 150만 t(2032~34, 보류) 계획 — 펄프는 충전제 시장 아님. 제지용 PCC·GCC 없음 — Cimentos de Moçambique(Salamanga)·Dugongo 등 시멘트사가 석회석 보유. 남아공 경유.$cm$,
   60, 300,
   $cm$INCEP 약 6천 t × FCC 1~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('incep', 'nacala|nampula|maputo', 'incep'),
  ('ecopac', 'matola|malhampsene', 'ecopac'),
  ('portucel.*mo[cç]ambique|portucel moz', null, 'portucel.*mo[cç]ambique|portucel moz'),
  ('paper tech', null, 'paper tech'),
  ('carpack', null, 'carpack'),
  ('mozambique packaging', null, 'mozambique packaging'),
  ('\mamal\M.*ind', null, '\mamal\M.*ind'),
  ('mozindia', null, 'mozindia'),
  ('right choice packaging', null, 'right choice packaging')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'mozambique_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'mozambique_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cimentos de mo[cç]ambique|salamanga')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    