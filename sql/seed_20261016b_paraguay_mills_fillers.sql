-- ============================================================
-- seed_20261016b_paraguay_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Paraguay update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'PY check 2026-10-15'.
-- 1) Filler if missing (1): Calmax (raw material). Distributors (Grupo
--    Ferreira / FOZ QUÍMICA, Pyatra, OregonChem, Inovaquimica) not added.
-- 2) Mills if missing (2) + plant blocks: Kartotec Villeta (priority 1),
--    Trans River Internacional (no priority, machine unconfirmed).
--    Context, match only (10): Cartones Yaguareté, Venezia, CARFAL, A&Z,
--    CPI Paraguay, Envaco, Corrugadora Paraguaya, PACSA, ADS, Paracel.
-- 3) app.country_markets PY row (priority medium).
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
           v.party_name, 'PY', v.region, v.city, v.website, 'active', 'paraguay_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calmax', 'Calmax', 'Concepción', 'San Lázaro', null, 'Concepción San Lázaro(Vallemí, Colonia Río Apa) 공장의 석회석 기반 농업용 칼사이트·돌로마이트 제조사.', 'Calmax - Paraguayan limestone products made at San Lázaro, Colonia Río Apa, Vallemí (Concepción), office San Alberto (Alto Paraná): agricultural calcitic lime (49-54 pct CaO equivalent) and dolomitic lime (13-16 pct MgO).', 'PY check 2026-10-15: paper-grade GCC not confirmed - raw-material source. +595 981 204917, central@calmax.com.py. Not added: Grupo Ferreira / FOZ QUÍMICA (imports and distributes PCC Extra Leve AA and ground carbonate, Fernando de la Mora), Pyatra Minerals (micronised GCC, plant location unknown), OregonChem, Inovaquimica (distributors), Concret-Mix (lime). No PCC plant, no Omya or SMI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%PY check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calmax', 'Calmax', 'Concepción', 'San Lázaro', null, 'Concepción San Lázaro(Vallemí, Colonia Río Apa) 공장의 석회석 기반 농업용 칼사이트·돌로마이트 제조사.', 'Calmax - Paraguayan limestone products made at San Lázaro, Colonia Río Apa, Vallemí (Concepción), office San Alberto (Alto Paraná): agricultural calcitic lime (49-54 pct CaO equivalent) and dolomitic lime (13-16 pct MgO).', 'PY check 2026-10-15: paper-grade GCC not confirmed - raw-material source. +595 981 204917, central@calmax.com.py. Not added: Grupo Ferreira / FOZ QUÍMICA (imports and distributes PCC Extra Leve AA and ground carbonate, Fernando de la Mora), Pyatra Minerals (micronised GCC, plant location unknown), OregonChem, Inovaquimica (distributors), Concret-Mix (lime). No PCC plant, no Omya or SMI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'paraguay_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calmax', 'Carbonate raw material', 'Local limestone - raw-material source', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'paraguay_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'PY', v.region, v.city, v.website, 'active', 'paraguay_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('kartotec|yaguaret[eé] papeles', 'villeta', 'kartotec|yaguaret', 'Kartotec (Yaguareté Papeles) - Villeta', 'Central', 'Villeta', null, 'Grupo Yaguareté 계열 Kartotec. Villeta 초지기 2대에서 재생섬유 테스트라이너·골심지·석고보드용 원지(PBL) 생산, 연 9.5만 t. 2026-09 1.2억 달러 신규 초지기(10만~13만 t) 계획 발표.', 'Kartotec S.A. (Grupo Yaguareté), Villeta, Central - two paper machines on recycled fibre: testliner, fluting and plasterboard liner (PBL), 95,000 t/yr. 2026-09: USD 120 m new machine planned for plasterboard liner, 100,000-130,000 t/yr (not yet built).', 'PY check 2026-10-15: group +595 21 659 9000, compras@cysa.com.py (Luque). Filler use not public. Sister company Cartones Yaguareté converts boxes (7.5 m m2/month).'),
  ('trans river', 'mariano roque alonso', 'trans river', 'Trans River Internacional (Mariano Roque Alonso)', 'Central', 'Mariano Roque Alonso', null, '재생지 기반 티슈 점보롤 생산 프로젝트 기록이 있는 업체(Mariano Roque Alonso). 초지기 가동 여부 미확인.', 'Trans River Internacional S.A., Mariano Roque Alonso - records of a recycled-paper tissue jumbo-roll project. Whether a tissue machine runs is not confirmed.', 'PY check 2026-10-15: machine, output and grade to confirm - if running, the only local tissue base-paper maker.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PY check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kartotec|yaguaret[eé] papeles', 'villeta', 'kartotec|yaguaret', 'Grupo Yaguareté 계열 Kartotec. Villeta 초지기 2대에서 재생섬유 테스트라이너·골심지·석고보드용 원지(PBL) 생산, 연 9.5만 t. 2026-09 1.2억 달러 신규 초지기(10만~13만 t) 계획 발표.', 'Kartotec S.A. (Grupo Yaguareté), Villeta, Central - two paper machines on recycled fibre: testliner, fluting and plasterboard liner (PBL), 95,000 t/yr. 2026-09: USD 120 m new machine planned for plasterboard liner, 100,000-130,000 t/yr (not yet built).', 'PY check 2026-10-15: group +595 21 659 9000, compras@cysa.com.py (Luque). Filler use not public. Sister company Cartones Yaguareté converts boxes (7.5 m m2/month).'),
  ('trans river', 'mariano roque alonso', 'trans river', '재생지 기반 티슈 점보롤 생산 프로젝트 기록이 있는 업체(Mariano Roque Alonso). 초지기 가동 여부 미확인.', 'Trans River Internacional S.A., Mariano Roque Alonso - records of a recycled-paper tissue jumbo-roll project. Whether a tissue machine runs is not confirmed.', 'PY check 2026-10-15: machine, output and grade to confirm - if running, the only local tissue base-paper maker.'),
  ('cartones yaguaret', null, 'cartones yaguaret', null, null, 'PY check 2026-10-15: Corrugated boxes (Luque, since 1978), 7.5 m m2/month, new USD 20 m box plant in Alto Paraná (2026) - context only.'),
  ('venezia', null, 'venezia', null, null, 'PY check 2026-10-15: Tissue products (Villa Elisa) - making or converting unknown - context only.'),
  ('carfal', null, 'carfal', null, null, 'PY check 2026-10-15: Tissue converter since 2003 (Lambaré) - context only.'),
  ('a ?& ?z.*papelera|avila y zutano|ávila y zutano', null, 'a ?& ?z.*papelera|avila y zutano|ávila y zutano', null, null, 'PY check 2026-10-15: Tissue products - machine not confirmed - context only.'),
  ('papelera internacional paraguay|\mcpi paraguay', null, 'papelera internacional paraguay|\mcpi paraguay', null, null, 'PY check 2026-10-15: Tissue products (Luque) - machine not confirmed - context only.'),
  ('envaco', null, 'envaco', null, null, 'PY check 2026-10-15: Corrugated boxes, 15,000 t/yr converted - context only.'),
  ('corrugadora paraguaya', null, 'corrugadora paraguaya', null, null, 'PY check 2026-10-15: Packaging paper and board - own machine to confirm - context only.'),
  ('papelera central|\mpacsa\M', null, 'papelera central|\mpacsa\M', null, null, 'PY check 2026-10-15: Uncoated paper and board - machine to confirm - context only.'),
  ('ads industrial', null, 'ads industrial', null, null, 'PY check 2026-10-15: Tissue products - context only.'),
  ('paracel', null, 'paracel', null, null, 'PY check 2026-10-15: Eucalyptus kraft pulp project, Concepción, 1.8 Mt/yr design - pulp only, under construction - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'paraguay_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kartotec|yaguaret[eé] papeles', 'villeta', 'kartotec|yaguaret'),
  ('trans river', 'mariano roque alonso', 'trans river'),
  ('cartones yaguaret', null, 'cartones yaguaret'),
  ('venezia', null, 'venezia'),
  ('carfal', null, 'carfal'),
  ('a ?& ?z.*papelera|avila y zutano|ávila y zutano', null, 'a ?& ?z.*papelera|avila y zutano|ávila y zutano'),
  ('papelera internacional paraguay|\mcpi paraguay', null, 'papelera internacional paraguay|\mcpi paraguay'),
  ('envaco', null, 'envaco'),
  ('corrugadora paraguaya', null, 'corrugadora paraguaya'),
  ('papelera central|\mpacsa\M', null, 'papelera central|\mpacsa\M'),
  ('ads industrial', null, 'ads industrial'),
  ('paracel', null, 'paracel')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kartotec|yaguaret[eé] papeles', 'villeta', 'kartotec|yaguaret',
   $pj${"owner": "Grupo Yaguareté", "priority": 1, "products": "Testliner, fluting, plasterboard liner (recycled)", "grades": ["Testliner", "Medium", "Plasterboard liner"], "machines": 2, "capacity": {"value": 95000, "unit": "metric_t", "year": "Company figure (2 machines)", "source": "cysa.com.py"}, "capacity_split": [{"label": "Existing 2 machines", "value_t": 95000}, {"label": "Planned new machine (2026 announcement)", "value_t": 130000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 5 pct on existing 95 kt - packaging strength must be proven. New machine would add 5,000-6,500 t."}, "pitch": "Recycled-fibre saving at equal SCT, RCT, CMT, burst - and drainage", "approach": "Lead Paraguayan account - technical and purchasing contact, trial on one PM, then include FCC in the new PBL machine design.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "recent": "New USD 120 m PBL machine announced 2026-09", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('trans river', 'mariano roque alonso', 'trans river',
   $pj${"owner": "Trans River Internacional", "products": "Recycled tissue jumbo rolls (project)", "grades": ["Tissue"], "approach": "Confirm the machine first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones yaguaret', null, 'cartones yaguaret',
   $pj${"owner": "Cartones Yaguareté", "products": "Corrugated boxes (Luque, since 1978), 7.5 m m2/month, new USD 20 m box plant in Alto Paraná (2026)", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('venezia', null, 'venezia',
   $pj${"owner": "Venezia S.A.", "products": "Tissue products (Villa Elisa) - making or converting unknown", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('carfal', null, 'carfal',
   $pj${"owner": "CARFAL", "products": "Tissue converter since 2003 (Lambaré)", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('a ?& ?z.*papelera|avila y zutano|ávila y zutano', null, 'a ?& ?z.*papelera|avila y zutano|ávila y zutano',
   $pj${"owner": "A&Z / Ávila y Zutano", "products": "Tissue products - machine not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera internacional paraguay|\mcpi paraguay', null, 'papelera internacional paraguay|\mcpi paraguay',
   $pj${"owner": "Compañía Papelera Internacional Paraguay", "products": "Tissue products (Luque) - machine not confirmed", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('envaco', null, 'envaco',
   $pj${"owner": "Envaco", "products": "Corrugated boxes, 15,000 t/yr converted", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corrugadora paraguaya', null, 'corrugadora paraguaya',
   $pj${"owner": "Corrugadora Paraguaya", "products": "Packaging paper and board - own machine to confirm", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera central|\mpacsa\M', null, 'papelera central|\mpacsa\M',
   $pj${"owner": "Papelera Central (PACSA)", "products": "Uncoated paper and board - machine to confirm", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('ads industrial', null, 'ads industrial',
   $pj${"owner": "ADS Industrial y Comercial", "products": "Tissue products", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('paracel', null, 'paracel',
   $pj${"owner": "Paracel", "products": "Eucalyptus kraft pulp project, Concepción, 1.8 Mt/yr design - pulp only, under construction", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PY', 'Paraguay', 'medium',
   $cm$Kartotec recycled liner and plasterboard liner (95 kt, new 100-130 kt machine planned) - tissue mostly converters$cm$,
   $cm$The only confirmed paper machines are Kartotec's two at Villeta (Grupo Yaguareté) - recycled testliner, fluting and plasterboard liner, 95 kt/yr, with a USD 120 m new machine announced in 2026-09. Trans River may make recycled tissue jumbo rolls. Other tissue and box firms convert. Paracel (Concepción) is a 1.8 Mt eucalyptus pulp project. No paper PCC plant - PCC and ground carbonate are imported by Grupo Ferreira / FOZ QUÍMICA.$cm$,
   $cm${"fillers": "Local: Calmax (agricultural limestone, raw material). Distributors not added: Grupo Ferreira / FOZ QUÍMICA (PCC and ground carbonate for paper and board, over 6,000 t/yr of all raw materials), Pyatra Minerals (micronised GCC, plant unknown), OregonChem, Inovaquimica. Concret-Mix makes lime. No Omya or SMI site.", "mills": "Kartotec Villeta (2 PMs, 95 kt + planned 100-130 kt). Trans River (tissue project, to confirm). Converters (context): Cartones Yaguareté, Venezia, CARFAL, A&Z, CPI Paraguay, Envaco, Corrugadora Paraguaya, PACSA, ADS. Paracel pulp project.", "strategy": "Kartotec trial first, then FCC in the new PBL machine design. FCC supply by Brazilian or Argentine licensee plants, local distribution by Grupo Ferreira.", "risks": "Strength-critical recycled packaging only.", "next_steps": ["Contact Kartotec technical and purchasing", "Confirm the Trans River tissue machine"], "key_numbers": [{"label": "Kartotec", "value": "95 kt/yr, new 100-130 kt machine planned (USD 120 m)"}, {"label": "Paracel pulp design", "value": "1.8 Mt/yr"}, {"label": "Report scenario", "value": "4,750 t FCC now, 9,750-11,250 t with the new machine"}], "files": ["seed_20261016b_paraguay_mills_fillers"]}$cm$::jsonb,
   $cm$Kartotec 재생 라이너·석고보드 원지(9.5만 t, 신규 10만~13만 t 계획) — 티슈는 대부분 가공업체$cm$,
   $cm$확인된 초지기는 Grupo Yaguareté 계열 Kartotec Villeta 2대뿐(재생 테스트라이너·골심지·석고보드 원지 9.5만 t), 2026-09 1.2억 달러 신규 초지기 발표. Trans River 는 티슈 점보롤 프로젝트(가동 미확인). 나머지는 가공업체. 제지용 PCC 는 Grupo Ferreira 가 수입·유통. Paracel 은 180만 t 펄프 프로젝트.$cm$,
   4750, 11250,
   $cm$Kartotec 9.5만 t × 5% = 4,750 t, 신규 초지기 포함 시 9,750~11,250 t (가동 100% 가정, 포장지 강도 검증 필요)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('kartotec|yaguaret[eé] papeles', 'villeta', 'kartotec|yaguaret'),
  ('trans river', 'mariano roque alonso', 'trans river'),
  ('cartones yaguaret', null, 'cartones yaguaret'),
  ('venezia', null, 'venezia'),
  ('carfal', null, 'carfal'),
  ('a ?& ?z.*papelera|avila y zutano|ávila y zutano', null, 'a ?& ?z.*papelera|avila y zutano|ávila y zutano'),
  ('papelera internacional paraguay|\mcpi paraguay', null, 'papelera internacional paraguay|\mcpi paraguay'),
  ('envaco', null, 'envaco'),
  ('corrugadora paraguaya', null, 'corrugadora paraguaya'),
  ('papelera central|\mpacsa\M', null, 'papelera central|\mpacsa\M'),
  ('ads industrial', null, 'ads industrial'),
  ('paracel', null, 'paracel')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'paraguay_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'paraguay_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calmax')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'PY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'PY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'PY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    