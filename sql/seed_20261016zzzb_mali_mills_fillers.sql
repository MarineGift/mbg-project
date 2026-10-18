-- ============================================================
-- seed_20261016zzzb_mali_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mali update (reports 2026-10-17).
-- 1) Filler if missing (1): Diamond Cement Mali (limestone).
-- 2) Mills if missing (2, no priority, machine to confirm): SAP Mali, SCS
--    Malienne de Cartonnerie. Context (4): SOCEM, Graphique Industrie,
--    Emball'Print, CMP.
-- 3) app.country_markets ML row (priority none).
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
           v.party_name, 'ML', v.region, v.city, v.website, 'active', 'mali_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('diamond cement.*mali', 'Diamond Cement Mali', 'Mali', null, null, 'Diamond Cement Mali — 석회석·클링커(연 약 100만 t)·시멘트, 과거 조사 석회석 약 6,700만 t.', 'Diamond Cement Mali S.A. - limestone, about 1 Mt/yr clinker and cement, an earlier study cited about 67 Mt limestone. Buys cement sacks of SCS Malienne de Cartonnerie.', 'ML check 2026-10-16: cement-grade stone - purity and brightness untested. Not added: CIMAF Mali (Diago and Sikasso grinding about 2 Mt), CMM (about 0.5 Mt), Carrières et Chaux du Mali, SECDO. No Malian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ML check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('diamond cement.*mali', 'Diamond Cement Mali', 'Mali', null, null, 'Diamond Cement Mali — 석회석·클링커(연 약 100만 t)·시멘트, 과거 조사 석회석 약 6,700만 t.', 'Diamond Cement Mali S.A. - limestone, about 1 Mt/yr clinker and cement, an earlier study cited about 67 Mt limestone. Buys cement sacks of SCS Malienne de Cartonnerie.', 'ML check 2026-10-16: cement-grade stone - purity and brightness untested. Not added: CIMAF Mali (Diago and Sikasso grinding about 2 Mt), CMM (about 0.5 Mt), Carrières et Chaux du Mali, SECDO. No Malian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'mali_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Diamond Cement Mali', 'Limestone owner (cement)', 'Limestone - long-term raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'mali_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'ML', v.region, v.city, v.website, 'active', 'mali_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('soci[eé]t[eé] africaine de papier|sap mali', 'sotuba|bamako', 'dahdah|sap', 'SAP Mali (Société Africaine de Papiers) - Bamako', 'Bamako', 'Bamako', null, 'Dahdah 그룹 SAP(Sotuba 산업지구, Porte 31-42) — 그룹이 종이공장으로 소개, 생산능력·초지기 미공개.', 'Société Africaine de Papiers SARL (Dahdah Group, founded in Bamako 2000), Zone Industrielle, Route de Sotuba, Porte 31-42, Bamako - described by the group as a paper factory, capacity and paper machine not disclosed.', 'ML check 2026-10-16: ask products, machine, fibre and daily output. infosapmali@gmail.com, +223 20 21 39 39.'),
  ('scs malienne|malienne de cartonnerie', 'kamal[eé]', 'scs', 'SCS Malienne de Cartonnerie - Kamalé', 'Koulikoro', 'Kamalé', null, 'SCS International 계열 Kamalé 공장(바마코 35 km, 2019 가동) — 골판지·식품 상자·시멘트용 크라프트 포대, 계획 판지 2만 t(2018), Diamond Cement 포대 2,000만 장+(2019 계약).', 'SCS Malienne de Cartonnerie (SCS International), Kamalé Soba (Mandé, about 35 km of Bamako) - corrugated packaging, food boxes and kraft cement sacks, production started 2019, 20,000 t/yr board planned (2018), over 20 m sacks contracted with Diamond Cement (2019).', 'ML check 2026-10-16: corrugator and sack lines, own paper machine not confirmed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ML check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('soci[eé]t[eé] africaine de papier|sap mali', 'sotuba|bamako', 'dahdah|sap', 'Dahdah 그룹 SAP(Sotuba 산업지구, Porte 31-42) — 그룹이 종이공장으로 소개, 생산능력·초지기 미공개.', 'Société Africaine de Papiers SARL (Dahdah Group, founded in Bamako 2000), Zone Industrielle, Route de Sotuba, Porte 31-42, Bamako - described by the group as a paper factory, capacity and paper machine not disclosed.', 'ML check 2026-10-16: ask products, machine, fibre and daily output. infosapmali@gmail.com, +223 20 21 39 39.'),
  ('scs malienne|malienne de cartonnerie', 'kamal[eé]', 'scs', 'SCS International 계열 Kamalé 공장(바마코 35 km, 2019 가동) — 골판지·식품 상자·시멘트용 크라프트 포대, 계획 판지 2만 t(2018), Diamond Cement 포대 2,000만 장+(2019 계약).', 'SCS Malienne de Cartonnerie (SCS International), Kamalé Soba (Mandé, about 35 km of Bamako) - corrugated packaging, food boxes and kraft cement sacks, production started 2019, 20,000 t/yr board planned (2018), over 20 m sacks contracted with Diamond Cement (2019).', 'ML check 2026-10-16: corrugator and sack lines, own paper machine not confirmed.'),
  ('socem|cartons et emballages du mali', null, 'socem|cartons et emballages du mali', null, null, 'ML check 2026-10-16: SOCEM, Banancoro - board and packaging, machine not confirmed - context only.'),
  ('graphique industrie', null, 'graphique industrie', null, null, 'ML check 2026-10-16: Printing, exercise books, labels, boxes (1989, IFC) - context only.'),
  ('emball.?print', null, 'emball.?print', null, null, 'ML check 2026-10-16: Paper bags and boxes, Bamako - context only.'),
  ('compagnie malienne du papier', null, 'compagnie malienne du papier', null, null, 'ML check 2026-10-16: Copy and printing paper distribution, Bamako - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'mali_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('soci[eé]t[eé] africaine de papier|sap mali', 'sotuba|bamako', 'dahdah|sap'),
  ('scs malienne|malienne de cartonnerie', 'kamal[eé]', 'scs'),
  ('socem|cartons et emballages du mali', null, 'socem|cartons et emballages du mali'),
  ('graphique industrie', null, 'graphique industrie'),
  ('emball.?print', null, 'emball.?print'),
  ('compagnie malienne du papier', null, 'compagnie malienne du papier')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('soci[eé]t[eé] africaine de papier|sap mali', 'sotuba|bamako', 'dahdah|sap', false,
   $pj${"owner": "Dahdah Group", "products": "Paper (to confirm)", "grades": [], "approach": "Confirm paper machine first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('scs malienne|malienne de cartonnerie', 'kamal[eé]', 'scs', false,
   $pj${"owner": "SCS International", "products": "Corrugated packaging, kraft sacks", "grades": [], "capacity_split": [{"label": "Board plan 2018 (converting)", "value_t": 20000}], "approach": "Confirm base paper source.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('socem|cartons et emballages du mali', null, 'socem|cartons et emballages du mali', true,
   $pj${"owner": "SOCEM", "products": "SOCEM, Banancoro - board and packaging, machine not confirmed", "approach": "Converter or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('graphique industrie', null, 'graphique industrie', true,
   $pj${"owner": "Graphique Industrie", "products": "Printing, exercise books, labels, boxes (1989, IFC)", "approach": "Converter or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('emball.?print', null, 'emball.?print', true,
   $pj${"owner": "Emball'Print", "products": "Paper bags and boxes, Bamako", "approach": "Converter or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('compagnie malienne du papier', null, 'compagnie malienne du papier', true,
   $pj${"owner": "CMP", "products": "Copy and printing paper distribution, Bamako", "approach": "Converter or distributor.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ML', 'Mali', 'none',
   $cm$No confirmed paper machine - SAP Mali (to confirm), SCS Kamalé corrugated and sacks, converters - limestone only via cement makers$cm$,
   $cm$Mali's paper sector is SAP Mali (Dahdah Group 'paper factory' in Sotuba, machine not confirmed), SCS Malienne de Cartonnerie at Kamalé (corrugated and kraft cement sacks since 2019), SOCEM, plus printers and distributors (Graphique Industrie, Emball'Print, CMP). HS 48 imports about USD 42.6 m in 2024, 54 pct Côte d'Ivoire and Ghana. No paper PCC or GCC - limestone only at cement makers (Diamond Cement about 1 Mt clinker, CIMAF, CMM). Landlocked - FCC demand would be served by coastal mills.$cm$,
   $cm${"fillers": "Limestone: Diamond Cement Mali. Cement grinders: CIMAF, CMM (not added). No PCC or GCC.", "mills": "To confirm: SAP Mali, SCS Malienne de Cartonnerie. Context: SOCEM, Graphique Industrie, Emball'Print, CMP.", "strategy": "Confirm SAP's machine. Otherwise serve via Ivorian and Ghanaian suppliers.", "risks": "Landlocked logistics, security situation.", "next_steps": ["Ask SAP Mali about its paper machine"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 42.6 m"}, {"label": "CI + GH share", "value": "about 54 pct"}], "files": ["seed_20261016zzzb_mali_mills_fillers"]}$cm$::jsonb,
   $cm$초지기 미확인 — SAP Mali(확인 필요), SCS Kamalé 골판지·포대, 가공업체 — 석회석은 시멘트사뿐$cm$,
   $cm$말리 제지 관련: SAP Mali(Dahdah 그룹이 Sotuba '종이공장'으로 소개, 초지기 미확인), SCS Malienne de Cartonnerie Kamalé(2019~ 골판지·시멘트 크라프트 포대), SOCEM, 인쇄·유통(Graphique Industrie, Emball'Print, CMP). HS 48 수입 2024 약 4,263만 달러, 54% 코트디부아르·가나. 제지용 PCC·GCC 없음 — 석회석은 시멘트사(Diamond Cement 클링커 약 100만 t, CIMAF, CMM). 내륙국 — 연안국 제지사 경유.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('soci[eé]t[eé] africaine de papier|sap mali', 'sotuba|bamako', 'dahdah|sap'),
  ('scs malienne|malienne de cartonnerie', 'kamal[eé]', 'scs'),
  ('socem|cartons et emballages du mali', null, 'socem|cartons et emballages du mali'),
  ('graphique industrie', null, 'graphique industrie'),
  ('emball.?print', null, 'emball.?print'),
  ('compagnie malienne du papier', null, 'compagnie malienne du papier')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'mali_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'mali_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'diamond cement.*mali')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ML'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ML'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ML'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ML'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    