-- ============================================================
-- seed_20261016m_panama_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Panama update (reports 2026-10-15).
-- 1) Filler if missing (1): Calizas Finas Chiriquí. CALPRO not added.
-- 2) Mills if missing (2) + plant blocks: Papelera Istmeña / GrandBay (1),
--    Industria Panameña de Papel Chilibre (2). Context (4): La Reforma,
--    Industria Papelera del Caribe, Papelería Comercial, Empresas Galindo.
-- 3) app.country_markets PA row (priority low).
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
           v.party_name, 'PA', v.region, v.city, v.website, 'active', 'panama_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calizas finas', 'Calizas Finas Chiriquí', 'Chiriquí', 'San Pablo Viejo', null, 'Chiriquí San Juan del Tejar 자체 광산 탄산칼슘 분쇄 업체(CaCO3 95% 초과, 4~325 mesh). 제지 용도 명시, 2025-07 아루바 첫 수출(MICI).', 'Calizas Finas Chiriquí S.A., San Juan del Tejar, San Pablo Viejo (Chiriquí) - own high-purity limestone (over 95 pct CaCO3) ground to 4-325 mesh for agriculture, feed, building, paint, plastics, paper named. First export (to Aruba) announced by MICI 2025-07-12. Offers chemical and particle-size analysis.', 'PA check 2026-10-15: 325 mesh is far coarser than paper filler - fine or wet grinding needed. +507 787-0506, info@calizasfinas.com. Not added: CALPRO (Costa del Este, sells white carbonate min 70 pct CaCO3, own plant unclear). Carbotico is Costa Rican (CR row). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%PA check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calizas finas', 'Calizas Finas Chiriquí', 'Chiriquí', 'San Pablo Viejo', null, 'Chiriquí San Juan del Tejar 자체 광산 탄산칼슘 분쇄 업체(CaCO3 95% 초과, 4~325 mesh). 제지 용도 명시, 2025-07 아루바 첫 수출(MICI).', 'Calizas Finas Chiriquí S.A., San Juan del Tejar, San Pablo Viejo (Chiriquí) - own high-purity limestone (over 95 pct CaCO3) ground to 4-325 mesh for agriculture, feed, building, paint, plastics, paper named. First export (to Aruba) announced by MICI 2025-07-12. Offers chemical and particle-size analysis.', 'PA check 2026-10-15: 325 mesh is far coarser than paper filler - fine or wet grinding needed. +507 787-0506, info@calizasfinas.com. Not added: CALPRO (Costa del Este, sells white carbonate min 70 pct CaCO3, own plant unclear). Carbotico is Costa Rican (CR row). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'panama_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calizas Finas Chiriquí', 'GCC producer', 'Local GCC - FCC raw material and co-processing', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'panama_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'PA', v.region, v.city, v.website, 'active', 'panama_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('papelera istme|\mpapisa\M|grandbay.*panam', 'las ma[nñ]anitas|24 de diciembre', 'istme|grandbay', 'Papelera Istmeña (GrandBay) - Panamá', 'Panamá', 'Panama City', null, 'GrandBay Group 의 파나마 티슈 생산공장 Papelera Istmeña(2011 투자, 2021 100% 인수). 제품 90% 이상이 100% 재생섬유. Suave Gold·Rosal·Unico·Delux·SaniTisu Professional.', 'Papelera Istmeña S.A. (GrandBay Group - invested 2011, 100 pct owned since 2021) - tissue mill in Panama: toilet, facial, napkins, towels, institutional tissue (Suave Gold, Rosal, Unico, Delux, Sensación, Serviclass, SaniTisu Professional). Over 90 pct of products on 100 pct recycled fibre.', 'PA check 2026-10-15: registered sites at Las Mañanitas (Parque Logístico San Carlos) and 24 de Diciembre - machine site to confirm. Capacity not public. Same group as GrandBay PAINSA (Guatemala).'),
  ('industria paname[nñ]a de papel', 'chilibre', 'paname[nñ]a de papel|galindo', 'Industria Panameña de Papel - Chilibre', 'Panamá', 'Chilibre', null, 'Empresas Galindo 계열 재생원지 공장(1967 설립, 1969 가동, Chilibre). 골심지·테스트라이너·지관원지·내습 라이너, 월 2,300 t.', 'Industria Panameña de Papel S.A. (Empresas Galindo, founded 1967, running since 1969-04), San Vicente, Chilibre, Milla 15 Carretera Boyd Roosevelt - recycled medium, testliner, core stock and wet-strength liner, 2,300 t/month (27,600 t/yr), about 68 staff.', 'PA check 2026-10-15: group +507 215-0530, info@empresasgalindo.com. Group capacity must not be counted twice.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PA check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera istme|\mpapisa\M|grandbay.*panam', 'las ma[nñ]anitas|24 de diciembre', 'istme|grandbay', 'GrandBay Group 의 파나마 티슈 생산공장 Papelera Istmeña(2011 투자, 2021 100% 인수). 제품 90% 이상이 100% 재생섬유. Suave Gold·Rosal·Unico·Delux·SaniTisu Professional.', 'Papelera Istmeña S.A. (GrandBay Group - invested 2011, 100 pct owned since 2021) - tissue mill in Panama: toilet, facial, napkins, towels, institutional tissue (Suave Gold, Rosal, Unico, Delux, Sensación, Serviclass, SaniTisu Professional). Over 90 pct of products on 100 pct recycled fibre.', 'PA check 2026-10-15: registered sites at Las Mañanitas (Parque Logístico San Carlos) and 24 de Diciembre - machine site to confirm. Capacity not public. Same group as GrandBay PAINSA (Guatemala).'),
  ('industria paname[nñ]a de papel', 'chilibre', 'paname[nñ]a de papel|galindo', 'Empresas Galindo 계열 재생원지 공장(1967 설립, 1969 가동, Chilibre). 골심지·테스트라이너·지관원지·내습 라이너, 월 2,300 t.', 'Industria Panameña de Papel S.A. (Empresas Galindo, founded 1967, running since 1969-04), San Vicente, Chilibre, Milla 15 Carretera Boyd Roosevelt - recycled medium, testliner, core stock and wet-strength liner, 2,300 t/month (27,600 t/yr), about 68 staff.', 'PA check 2026-10-15: group +507 215-0530, info@empresasgalindo.com. Group capacity must not be counted twice.'),
  ('la reforma', null, 'la reforma', null, null, 'PA check 2026-10-15: Tissue converting at Parque Industrial Las Américas, Pacora (2022), new line 2026-09 (+70 pct converting) - no paper machine found - context only.'),
  ('industria papelera del caribe', null, 'industria papelera del caribe', null, null, 'PA check 2026-10-15: D&B pulp and paper listing - machine and products unknown - context only.'),
  ('papeler[ií]a comercial', null, 'papeler[ií]a comercial', null, null, 'PA check 2026-10-15: Thermal and bond rolls, bags, cores (Chilibre) - converts Koehler and Jujo paper - context only.'),
  ('empresas galindo', null, 'empresas galindo', null, null, 'PA check 2026-10-15: Group row - corrugated in five Central American countries - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'panama_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera istme|\mpapisa\M|grandbay.*panam', 'las ma[nñ]anitas|24 de diciembre', 'istme|grandbay'),
  ('industria paname[nñ]a de papel', 'chilibre', 'paname[nñ]a de papel|galindo'),
  ('la reforma', null, 'la reforma'),
  ('industria papelera del caribe', null, 'industria papelera del caribe'),
  ('papeler[ií]a comercial', null, 'papeler[ií]a comercial'),
  ('empresas galindo', null, 'empresas galindo')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera istme|\mpapisa\M|grandbay.*panam', 'las ma[nñ]anitas|24 de diciembre', 'istme|grandbay',
   $pj${"owner": "GrandBay Paper and Care Products", "priority": 1, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Recycled tissue FCC - extend to GrandBay Guatemala and other mills", "approach": "Approach together with GrandBay Guatemala.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('industria paname[nñ]a de papel', 'chilibre', 'paname[nñ]a de papel|galindo',
   $pj${"owner": "Empresas Galindo", "priority": 2, "products": "Recycled medium, testliner, core stock, wet-strength liner", "grades": ["Medium", "Testliner", "Core board"], "capacity": {"value": 27600, "unit": "metric_t", "year": "2,300 t/month x 12 (company)", "source": "empresasgalindo.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Planning scenario - packaging strength must be proven."}, "approach": "Strength-hold trial (SCT, CMT, RCT, burst, ply bond). Group-wide rollout possible.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('la reforma', null, 'la reforma',
   $pj${"owner": "Papelera La Reforma Panamá", "products": "Tissue converting at Parque Industrial Las Américas, Pacora (2022), new line 2026-09 (+70 pct converting) - no paper machine found", "approach": "Converter or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('industria papelera del caribe', null, 'industria papelera del caribe',
   $pj${"owner": "Industria Papelera del Caribe", "products": "D&B pulp and paper listing - machine and products unknown", "approach": "Converter or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeler[ií]a comercial', null, 'papeler[ií]a comercial',
   $pj${"owner": "Papelería Comercial", "products": "Thermal and bond rolls, bags, cores (Chilibre) - converts Koehler and Jujo paper", "approach": "Converter or group row.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('empresas galindo', null, 'empresas galindo',
   $pj${"owner": "Empresas Galindo", "products": "Group row - corrugated in five Central American countries", "approach": "Converter or group row.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PA', 'Panama', 'low',
   $cm$Papelera Istmeña (GrandBay) recycled tissue and Industria Panameña de Papel recycled liner (27.6 kt) - coarse local GCC only$cm$,
   $cm$Panama has two confirmed paper machines: Papelera Istmeña (GrandBay Group) recycled tissue and Industria Panameña de Papel (Empresas Galindo) recycled medium, testliner and core stock at 27,600 t/yr. La Reforma and Papelería Comercial convert. The only local carbonate grinder is Calizas Finas Chiriquí (to 325 mesh). No paper PCC.$cm$,
   $cm${"fillers": "Calizas Finas Chiriquí (over 95 pct, 4-325 mesh, paper named). Not added: CALPRO (reseller, min 70 pct CaCO3). Carbotico is in Costa Rica.", "mills": "Tissue: Papelera Istmeña (GrandBay). Recycled packaging: Industria Panameña de Papel Chilibre (2,300 t/month). Context: La Reforma (converting), Industria Papelera del Caribe (unknown), Papelería Comercial (converter), Empresas Galindo (group).", "strategy": "Run Panama with GrandBay Guatemala (one tissue pitch to the group) and Galindo group packaging. FCC supply by regional producers.", "risks": "Small volumes, no paper-grade filler maker.", "next_steps": ["Pitch GrandBay group (Guatemala plus Panama)"], "key_numbers": [{"label": "Industria Panameña de Papel", "value": "27,600 t/yr"}, {"label": "Report scenario", "value": "828-1,380 t FCC (3-5 pct)"}], "files": ["seed_20261016m_panama_mills_fillers"]}$cm$::jsonb,
   $cm$Papelera Istmeña(GrandBay) 재생 티슈 + Industria Panameña de Papel 재생 원지(2.76만 t) — 현지 GCC 는 조립품만$cm$,
   $cm$확인된 초지기는 2곳: Papelera Istmeña(GrandBay) 재생 티슈, Industria Panameña de Papel(Empresas Galindo) 재생 골심지·라이너·지관원지 연 2.76만 t. La Reforma·Papelería Comercial 은 가공. 현지 분쇄업체는 Calizas Finas Chiriquí(325 mesh) 뿐, 제지용 PCC 없음.$cm$,
   828, 1380,
   $cm$Industria Panameña de Papel 2.76만 t × FCC 3~5% (Papelera Istmeña 톤수 미공개)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('papelera istme|\mpapisa\M|grandbay.*panam', 'las ma[nñ]anitas|24 de diciembre', 'istme|grandbay'),
  ('industria paname[nñ]a de papel', 'chilibre', 'paname[nñ]a de papel|galindo'),
  ('la reforma', null, 'la reforma'),
  ('industria papelera del caribe', null, 'industria papelera del caribe'),
  ('papeler[ií]a comercial', null, 'papeler[ií]a comercial'),
  ('empresas galindo', null, 'empresas galindo')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'panama_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'panama_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calizas finas')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'PA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'PA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'PA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    