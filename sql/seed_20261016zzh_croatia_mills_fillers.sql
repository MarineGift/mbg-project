-- ============================================================
-- seed_20261016zzh_croatia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Croatia update (reports 2026-10-16). Fixed generator.
-- Calcit Lika and InterCal Croatia guards are Croatia-specific (Slovenian
-- Calcit and InterCal rows stay apart).
-- 1) Fillers if missing (3): Calcit Lika, STARAC, InterCal Croatia.
-- 2) Mills if missing (2) + plant blocks: DS Smith Belišće (1), Violeta
--    (no priority). Context (4): Drvenjača, Valica, Jaška, PAN Zagreb.
-- 3) app.country_markets HR row (priority low).
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
           v.party_name, 'HR', v.region, v.city, v.website, 'active', 'croatia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcit.*(lika|gosp|croatia)', 'Calcit Lika - Gospić', 'Lika-Senj', 'Gospić', null, 'Calcit 그룹 크로아티아 공장(2012 가동, Gospić) — 자체 채석장 고순도 원광, 산업용 철도. 그룹 제지용 HydroPlex·CalPlex·CoverPlex, 2025 Thiele Kaolin 유럽 유통 협력.', 'Calcit Lika (Calcit group, Slovenia), Gospić - GCC plant opened 2012 using high-purity ore of its own quarry, with an industrial rail link. Group paper grades HydroPlex, CalPlex, CoverPlex, group claims about 20 pct of European paper GCC. 2025 European distribution tie-up with Thiele Kaolin (US).', 'HR check 2026-10-16: plant capacity and wet slurry line not public. info@calcit.hr, +385 53 743 036. Licence route via Calcit HQ (SI row).'),
  ('starac|white rock', 'STARAC (White Rock) - Siverić', 'Šibenik-Knin', 'Siverić', null, 'STARAC — Siverić 공장, Plano(Trogir 인근) 채석·파쇄, White Rock Fillers 1~100 μm·Granules 100~3,000 μm, 제지 슬러리 용도 명시, 홈페이지 표기 연 35만 t.', 'STARAC d.o.o., plant at Siverić and quarry and crushing at Plano near Trogir - high-purity limestone crushed, ground, dried and classified: White Rock Fillers 1-100 micron and Granules 100-3,000 micron, paper slurry use named, 350,000 t/yr shown on its site (scope unclear).', 'HR check 2026-10-16: paper grade PSD and wet capability to confirm. prodaja@starac.hr, +385 98 253 917. Local pilot partner (1-5 t trial).'),
  ('intercal.*(croatia|hrvatska|sira|li[cč]ko)', 'InterCal Croatia - Sirač', 'Bjelovar-Bilogora', 'Sirač', null, 'Wietersdorfer 계열 InterCal Croatia — Sirač·Ličko Lešće 석회석·생석회·소석회.', 'InterCal Croatia (WIG Wietersdorfer group) - limestone, quicklime and hydrated lime at Sirač and Ličko Lešće.', 'HR check 2026-10-16: PCC raw material only. No Croatian paper PCC plant found - Omya supplies Hydrocarb slurry to Croatia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%HR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcit.*(lika|gosp|croatia)', 'Calcit Lika - Gospić', 'Lika-Senj', 'Gospić', null, 'Calcit 그룹 크로아티아 공장(2012 가동, Gospić) — 자체 채석장 고순도 원광, 산업용 철도. 그룹 제지용 HydroPlex·CalPlex·CoverPlex, 2025 Thiele Kaolin 유럽 유통 협력.', 'Calcit Lika (Calcit group, Slovenia), Gospić - GCC plant opened 2012 using high-purity ore of its own quarry, with an industrial rail link. Group paper grades HydroPlex, CalPlex, CoverPlex, group claims about 20 pct of European paper GCC. 2025 European distribution tie-up with Thiele Kaolin (US).', 'HR check 2026-10-16: plant capacity and wet slurry line not public. info@calcit.hr, +385 53 743 036. Licence route via Calcit HQ (SI row).'),
  ('starac|white rock', 'STARAC (White Rock) - Siverić', 'Šibenik-Knin', 'Siverić', null, 'STARAC — Siverić 공장, Plano(Trogir 인근) 채석·파쇄, White Rock Fillers 1~100 μm·Granules 100~3,000 μm, 제지 슬러리 용도 명시, 홈페이지 표기 연 35만 t.', 'STARAC d.o.o., plant at Siverić and quarry and crushing at Plano near Trogir - high-purity limestone crushed, ground, dried and classified: White Rock Fillers 1-100 micron and Granules 100-3,000 micron, paper slurry use named, 350,000 t/yr shown on its site (scope unclear).', 'HR check 2026-10-16: paper grade PSD and wet capability to confirm. prodaja@starac.hr, +385 98 253 917. Local pilot partner (1-5 t trial).'),
  ('intercal.*(croatia|hrvatska|sira|li[cč]ko)', 'InterCal Croatia - Sirač', 'Bjelovar-Bilogora', 'Sirač', null, 'Wietersdorfer 계열 InterCal Croatia — Sirač·Ličko Lešće 석회석·생석회·소석회.', 'InterCal Croatia (WIG Wietersdorfer group) - limestone, quicklime and hydrated lime at Sirač and Ličko Lešće.', 'HR check 2026-10-16: PCC raw material only. No Croatian paper PCC plant found - Omya supplies Hydrocarb slurry to Croatia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'croatia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calcit Lika - Gospić', 'GCC producer', 'Calcit group GCC plant - licence via Calcit HQ', 'merchant', 'B', 'gcc'),
  ('STARAC (White Rock) - Siverić', 'GCC producer', 'Local GCC, paper slurry named - pilot partner', 'merchant', 'B', 'gcc'),
  ('InterCal Croatia - Sirač', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'croatia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'HR', v.region, v.city, v.website, 'active', 'croatia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('beli[sš][cć]e', 'beli[sš][cć]e', 'ds smith|beli|international paper', 'DS Smith Belišće', 'Osijek-Baranja', 'Belišće', null, '1960년부터 제지, 2015 DS Smith 인수(2025-01 International Paper 편입) — PM2 12.5만 t(90~200 g/m²) + PM3 9만 t(80~150) = 21.5만 t, Liner 3·Medium·Medium HP 계열.', 'DS Smith Belišće, Vijenac S. H. Gutmanna 30, Belišće - papermaking since 1960, DS Smith since 2015 (International Paper since 2025-01-31): PM2 Fourdrinier / Topformer 125,000 t/yr (90-200 g/m2, 5.0 m) and PM3 twin-wire 90,000 t/yr (80-150 g/m2, 4.4 m), Liner 3, Medium, Medium HP, HP Plus, HP WS.', 'HR check 2026-10-16: strength-led - stepwise trial. +385 31 516 202.'),
  ('violeta', 'zelina|sveta helena', 'violeta', 'Violeta - Sveti Ivan Zelina', 'Zagreb County', 'Sveti Ivan Zelina', null, 'Violeta 크로아티아 티슈제품 공장(2011, 약 1,200만 유로) — 화장지·키친타월. 2025 매출 8,785만 유로·270명. 보스니아 Grude 본사.', 'Violeta (Croatian company of the Grude, BA group), Sveti Ivan Zelina / Sveta Helena - toilet tissue and kitchen towel plant opened 2011 (about EUR 12 m). 2025 sales EUR 87.85 m, net EUR 2.15 m, 270 staff.', 'HR check 2026-10-16: own base-paper machine not confirmed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%HR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('beli[sš][cć]e', 'beli[sš][cć]e', 'ds smith|beli|international paper', '1960년부터 제지, 2015 DS Smith 인수(2025-01 International Paper 편입) — PM2 12.5만 t(90~200 g/m²) + PM3 9만 t(80~150) = 21.5만 t, Liner 3·Medium·Medium HP 계열.', 'DS Smith Belišće, Vijenac S. H. Gutmanna 30, Belišće - papermaking since 1960, DS Smith since 2015 (International Paper since 2025-01-31): PM2 Fourdrinier / Topformer 125,000 t/yr (90-200 g/m2, 5.0 m) and PM3 twin-wire 90,000 t/yr (80-150 g/m2, 4.4 m), Liner 3, Medium, Medium HP, HP Plus, HP WS.', 'HR check 2026-10-16: strength-led - stepwise trial. +385 31 516 202.'),
  ('violeta', 'zelina|sveta helena', 'violeta', 'Violeta 크로아티아 티슈제품 공장(2011, 약 1,200만 유로) — 화장지·키친타월. 2025 매출 8,785만 유로·270명. 보스니아 Grude 본사.', 'Violeta (Croatian company of the Grude, BA group), Sveti Ivan Zelina / Sveta Helena - toilet tissue and kitchen towel plant opened 2011 (about EUR 12 m). 2025 sales EUR 87.85 m, net EUR 2.15 m, 270 staff.', 'HR check 2026-10-16: own base-paper machine not confirmed.'),
  ('drvenja[cč]a', null, 'drvenja[cč]a', null, null, 'HR check 2026-10-16: RMP mechanical pulp about 45 kt/yr, Fužine - supplies RDM and MM board mills - context only.'),
  ('\mvalica\M', null, '\mvalica\M', null, null, 'HR check 2026-10-16: Tissue products, Pazin - own machine not confirmed - context only.'),
  ('ja[sš]ka', null, 'ja[sš]ka', null, null, 'HR check 2026-10-16: Corrugated board and boxes 2-7 ply, Sesvete (35 kt converting) - context only.'),
  ('\mpan\M.*papir|tvornica papira zagreb', null, '\mpan\M.*papir|tvornica papira zagreb', null, null, 'HR check 2026-10-16: Former paper and board mill, Zagreb - in bankruptcy, 0 staff (2025) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'croatia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('beli[sš][cć]e', 'beli[sš][cć]e', 'ds smith|beli|international paper'),
  ('violeta', 'zelina|sveta helena', 'violeta'),
  ('drvenja[cč]a', null, 'drvenja[cč]a'),
  ('\mvalica\M', null, '\mvalica\M'),
  ('ja[sš]ka', null, 'ja[sš]ka'),
  ('\mpan\M.*papir|tvornica papira zagreb', null, '\mpan\M.*papir|tvornica papira zagreb')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('beli[sš][cć]e', 'beli[sš][cć]e', 'ds smith|beli|international paper', false,
   $pj${"owner": "International Paper (DS Smith)", "priority": 1, "products": "Recycled liner and fluting", "grades": ["Testliner", "Medium"], "machines": 2, "capacity": {"value": 215000, "unit": "metric_t", "year": "Company site (PM2 + PM3)", "source": "dssmith.com"}, "capacity_split": [{"label": "PM2", "value_t": 125000}, {"label": "PM3", "value_t": 90000}], "approach": "Fibre-saving strength-hold trial - could pair with Calcit Lika GCC.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('violeta', 'zelina|sveta helena', 'violeta', false,
   $pj${"owner": "Violeta", "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "approach": "Confirm base-paper source first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('drvenja[cč]a', null, 'drvenja[cč]a', true,
   $pj${"owner": "Drvenjača", "products": "RMP mechanical pulp about 45 kt/yr, Fužine - supplies RDM and MM board mills", "approach": "Pulp, converter or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mvalica\M', null, '\mvalica\M', true,
   $pj${"owner": "Valica", "products": "Tissue products, Pazin - own machine not confirmed", "approach": "Pulp, converter or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ja[sš]ka', null, 'ja[sš]ka', true,
   $pj${"owner": "Jaška", "products": "Corrugated board and boxes 2-7 ply, Sesvete (35 kt converting)", "approach": "Pulp, converter or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mpan\M.*papir|tvornica papira zagreb', null, '\mpan\M.*papir|tvornica papira zagreb', true,
   $pj${"owner": "PAN Tvornica Papira Zagreb", "products": "Former paper and board mill, Zagreb - in bankruptcy, 0 staff (2025)", "approach": "Pulp, converter or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'HR', 'Croatia', 'low',
   $cm$DS Smith Belišće recycled liner (215 kt) - Calcit Lika and STARAC GCC - no paper PCC$cm$,
   $cm$Croatia's only large paper machine site is DS Smith Belišće (International Paper since 2025-01), recycled liner and fluting on PM2 and PM3, 215 kt. Violeta (Sveti Ivan Zelina) and Valica make tissue products (machines unconfirmed), Jaška converts corrugated, Drvenjača makes RMP pulp for board mills, PAN Zagreb is bankrupt. Fillers: Calcit Lika at Gospić (Calcit group GCC plant since 2012), STARAC White Rock GCC at Siverić (paper slurry named), InterCal lime. No paper PCC plant.$cm$,
   $cm${"fillers": "GCC: Calcit Lika Gospić, STARAC Siverić. Lime: InterCal Croatia. No PCC - Omya slurry imported.", "mills": "Liner: DS Smith Belišće. Tissue products: Violeta (machine to confirm). Context: Drvenjača (pulp), Valica, Jaška, PAN Zagreb (bankrupt).", "strategy": "Calcit group licence covers Lika. Belišće fibre-saving trial possibly with Calcit Lika GCC, via International Paper Europe R&D.", "risks": "Strength-led liner, small tissue volumes.", "next_steps": ["Raise Lika in the Calcit HQ talks", "Ask IP Europe about a Belišće trial"], "key_numbers": [{"label": "DS Smith Belišće", "value": "215 kt (PM2 125 + PM3 90)"}, {"label": "STARAC", "value": "350 kt/yr shown (scope unclear)"}], "files": ["seed_20261016zzh_croatia_mills_fillers"]}$cm$::jsonb,
   $cm$DS Smith Belišće 재생 라이너(21.5만 t) — Calcit Lika·STARAC GCC — 제지용 PCC 없음$cm$,
   $cm$크로아티아의 대형 초지기는 DS Smith Belišće(2025-01 International Paper 편입) PM2·PM3 재생 라이너·골심지 21.5만 t 뿐. Violeta·Valica 티슈제품(초지기 미확인), Jaška 골판지 가공, Drvenjača 판지용 RMP 펄프, PAN Zagreb 파산. 충전제: Calcit Lika(Gospić, 2012 Calcit 그룹 GCC 공장), STARAC White Rock(Siverić, 제지 슬러리 명시), InterCal 석회. 제지용 PCC 없음.$cm$,
   2150, 6450,
   $cm$Belišće 21.5만 t × FCC 1~3% (라이너 강도 제약)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('beli[sš][cć]e', 'beli[sš][cć]e', 'ds smith|beli|international paper'),
  ('violeta', 'zelina|sveta helena', 'violeta'),
  ('drvenja[cč]a', null, 'drvenja[cč]a'),
  ('\mvalica\M', null, '\mvalica\M'),
  ('ja[sš]ka', null, 'ja[sš]ka'),
  ('\mpan\M.*papir|tvornica papira zagreb', null, '\mpan\M.*papir|tvornica papira zagreb')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'croatia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'croatia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcit.*(lika|gosp|croatia)' or p.party_name ~* 'starac|white rock' or p.party_name ~* 'intercal.*(croatia|hrvatska|sira|li[cč]ko)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'HR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'HR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'HR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    