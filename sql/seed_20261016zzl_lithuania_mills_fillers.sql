-- ============================================================
-- seed_20261016zzl_lithuania_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Lithuania update (reports 2026-10-16). Fixed generator.
-- Grigeo Tissue has no city fallback so it never lands on a Grigeo Hygiene
-- or Packaging row in Grigiškės.
-- 1) Filler if missing (1): Naujasis Kalcitas.
-- 2) Mills if missing (2) + plant blocks: Grigeo Tissue (1), Grigeo
--    Klaipėda (2). Context (5): Grigeo Hygiene, Grigeo Packaging, DS Smith,
--    Smurfit Westrock Baltic, Stora Enso Packaging.
-- 3) app.country_markets LT row (priority low).
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
           v.party_name, 'LT', v.region, v.city, v.website, 'active', 'lithuania_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('naujasis kalcitas', 'Naujasis Kalcitas - Menčiai (Akmenė)', 'Šiauliai', 'Akmenė', null, 'AB Naujasis Kalcitas(1997 법인, Menčiai 채석장·Aušros g. 21 공장) — 석회석 채굴·파쇄·건조·분쇄, 탄산염 94%+, 0~0.2 mm, 농업·축산·건설·도로용.', 'AB Naujasis Kalcitas (company 1997, limestone mined there since 1932), plant at Aušros g. 21, Menčiai (Akmenė) - limestone quarrying, crushing, drying and grinding, over 94 pct carbonates, 0-0.2 mm, for agriculture, livestock, building and roads.', 'LT check 2026-10-16: paper D50, brightness and slurry not available. sales@naujasiskalcitas.lt, +370 616 25736. Not added: AB Kalcitas (Karpėnai limestone), Akmenės Cementas (cement over 1 Mt), Mortar Akmenė. No Lithuanian paper PCC or satellite.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%LT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('naujasis kalcitas', 'Naujasis Kalcitas - Menčiai (Akmenė)', 'Šiauliai', 'Akmenė', null, 'AB Naujasis Kalcitas(1997 법인, Menčiai 채석장·Aušros g. 21 공장) — 석회석 채굴·파쇄·건조·분쇄, 탄산염 94%+, 0~0.2 mm, 농업·축산·건설·도로용.', 'AB Naujasis Kalcitas (company 1997, limestone mined there since 1932), plant at Aušros g. 21, Menčiai (Akmenė) - limestone quarrying, crushing, drying and grinding, over 94 pct carbonates, 0-0.2 mm, for agriculture, livestock, building and roads.', 'LT check 2026-10-16: paper D50, brightness and slurry not available. sales@naujasiskalcitas.lt, +370 616 25736. Not added: AB Kalcitas (Karpėnai limestone), Akmenės Cementas (cement over 1 Mt), Mortar Akmenė. No Lithuanian paper PCC or satellite.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'lithuania_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Naujasis Kalcitas - Menčiai (Akmenė)', 'GCC producer', 'Ground limestone - raw material, new FCC site candidate', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'lithuania_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'LT', v.region, v.city, v.website, 'active', 'lithuania_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('grigeo tissue|grigeo.*grigi[sš]k|grigi[sš]k[eė]s', null, 'grigeo', 'Grigeo Tissue - Grigiškės', 'Vilnius', 'Grigiškės', null, 'Grigeo Tissue(Vilniaus g. 10, Grigiškės) 티슈 원지 — 1965 위생지 시작, PM5(2008)·PM6(2015). 2025-07 PM7 결정(Toscotec, 5.6 m·2,100 m/분, 연 7만 t, 2028 상반기, LT 투자 9,700만 유로+). 그룹 7만→14만 t(폴란드 포함).', 'Grigeo Tissue UAB, Vilniaus g. 10, Grigiškės - tissue base paper since 1965, PM5 (2008) and PM6 (2015). PM7 ordered 2025-07 (Toscotec, 5.6 m, up to 2,100 m/min, 70,000 t/yr, start H1 2028, over EUR 97 m in Lithuania of EUR 106 m total). Group tissue about 70,000 rising to 140,000 t/yr incl. Poland (Niedomice, bought 2024) - Huchtemeier Papier (DE) bought 2025.', 'LT check 2026-10-16: Lithuanian capacity alone not split. GM Almantas Tamošiūnas, tissue.LT@grigeo.com.'),
  ('grigeo.*klaip|klaip[eė]dos kartonas', 'klaip[eė]d', 'grigeo', 'Grigeo Klaipėda', 'Klaipėda', 'Klaipėda', null, 'Grigeo Klaipėda(Nemuno g. 2, 구 Klaipėdos Kartonas) 재생 Testliner·Fluting·종이 허니컴 코어. 2024 매출 4,970만 유로.', 'Grigeo Klaipėda AB (formerly Klaipėdos Kartonas), Nemuno g. 2, Klaipėda - recycled testliner and fluting plus paper honeycomb cores. 2024 sales EUR 49.7 m.', 'LT check 2026-10-16: strength-led. GM Gitana Šeršniovienė, klaipeda@grigeo.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grigeo tissue|grigeo.*grigi[sš]k|grigi[sš]k[eė]s', null, 'grigeo', 'Grigeo Tissue(Vilniaus g. 10, Grigiškės) 티슈 원지 — 1965 위생지 시작, PM5(2008)·PM6(2015). 2025-07 PM7 결정(Toscotec, 5.6 m·2,100 m/분, 연 7만 t, 2028 상반기, LT 투자 9,700만 유로+). 그룹 7만→14만 t(폴란드 포함).', 'Grigeo Tissue UAB, Vilniaus g. 10, Grigiškės - tissue base paper since 1965, PM5 (2008) and PM6 (2015). PM7 ordered 2025-07 (Toscotec, 5.6 m, up to 2,100 m/min, 70,000 t/yr, start H1 2028, over EUR 97 m in Lithuania of EUR 106 m total). Group tissue about 70,000 rising to 140,000 t/yr incl. Poland (Niedomice, bought 2024) - Huchtemeier Papier (DE) bought 2025.', 'LT check 2026-10-16: Lithuanian capacity alone not split. GM Almantas Tamošiūnas, tissue.LT@grigeo.com.'),
  ('grigeo.*klaip|klaip[eė]dos kartonas', 'klaip[eė]d', 'grigeo', 'Grigeo Klaipėda(Nemuno g. 2, 구 Klaipėdos Kartonas) 재생 Testliner·Fluting·종이 허니컴 코어. 2024 매출 4,970만 유로.', 'Grigeo Klaipėda AB (formerly Klaipėdos Kartonas), Nemuno g. 2, Klaipėda - recycled testliner and fluting plus paper honeycomb cores. 2024 sales EUR 49.7 m.', 'LT check 2026-10-16: strength-led. GM Gitana Šeršniovienė, klaipeda@grigeo.com.'),
  ('grigeo hygiene', null, 'grigeo hygiene', null, null, 'LT check 2026-10-16: Grigeo Hygiene - hygiene products business (GM Darius Belevičius) - context only.'),
  ('grigeo.*packaging', null, 'grigeo.*packaging', null, null, 'LT check 2026-10-16: Grigeo Packaging and Paper Packaging - corrugated sheets and boxes - context only.'),
  ('ds smith.*(lithuan|lietuv)', null, 'ds smith.*(lithuan|lietuv)', null, null, 'LT check 2026-10-16: DS Smith Packaging Lithuania - corrugated converting (2025 sales EUR 64.3 m) - context only.'),
  ('smurfit.*baltic', null, 'smurfit.*baltic', null, null, 'LT check 2026-10-16: Smurfit Westrock Baltic - packaging - context only.'),
  ('stora enso.*(lithuan|lietuv|packaging)', null, 'stora enso.*(lithuan|lietuv|packaging)', null, null, 'LT check 2026-10-16: Stora Enso Packaging Lithuania - corrugated - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'lithuania_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grigeo tissue|grigeo.*grigi[sš]k|grigi[sš]k[eė]s', null, 'grigeo'),
  ('grigeo.*klaip|klaip[eė]dos kartonas', 'klaip[eė]d', 'grigeo'),
  ('grigeo hygiene', null, 'grigeo hygiene'),
  ('grigeo.*packaging', null, 'grigeo.*packaging'),
  ('ds smith.*(lithuan|lietuv)', null, 'ds smith.*(lithuan|lietuv)'),
  ('smurfit.*baltic', null, 'smurfit.*baltic'),
  ('stora enso.*(lithuan|lietuv|packaging)', null, 'stora enso.*(lithuan|lietuv|packaging)')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grigeo tissue|grigeo.*grigi[sš]k|grigi[sš]k[eė]s', null, 'grigeo', false,
   $pj${"owner": "Grigeo Group", "priority": 1, "products": "Tissue base paper", "grades": ["Tissue"], "capacity_split": [{"label": "Group tissue now (incl. PL)", "value_t": 70000}, {"label": "PM7 plan 2028", "value_t": 70000}], "pitch": "FCC 3-5 pct on PM5 / PM6, then PM7 furnish design", "approach": "Lead Baltic account - group path to Niedomice (PL) and Huchtemeier (DE).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "PM7 order 2025-07, start H1 2028", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('grigeo.*klaip|klaip[eė]dos kartonas', 'klaip[eė]d', 'grigeo', false,
   $pj${"owner": "Grigeo Group", "priority": 2, "products": "Recycled testliner, fluting", "grades": ["Testliner", "Medium"], "approach": "Strength-hold fibre-saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('grigeo hygiene', null, 'grigeo hygiene', true,
   $pj${"owner": "Grigeo Group", "products": "Grigeo Hygiene - hygiene products business (GM Darius Belevičius)", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('grigeo.*packaging', null, 'grigeo.*packaging', true,
   $pj${"owner": "Grigeo Group", "products": "Grigeo Packaging and Paper Packaging - corrugated sheets and boxes", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*(lithuan|lietuv)', null, 'ds smith.*(lithuan|lietuv)', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "DS Smith Packaging Lithuania - corrugated converting (2025 sales EUR 64.3 m)", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*baltic', null, 'smurfit.*baltic', true,
   $pj${"owner": "Smurfit Westrock", "products": "Smurfit Westrock Baltic - packaging", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*(lithuan|lietuv|packaging)', null, 'stora enso.*(lithuan|lietuv|packaging)', true,
   $pj${"owner": "Stora Enso", "products": "Stora Enso Packaging Lithuania - corrugated", "approach": "Converter - no paper machine.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'LT', 'Lithuania', 'low',
   $cm$Grigeo Tissue Grigiškės (PM5, PM6, new PM7 70 kt in 2028) and Grigeo Klaipėda recycled liner - no paper PCC or GCC, ground limestone at Akmenė$cm$,
   $cm$Lithuania's paper machines belong to Grigeo Group (2024 sales about EUR 213 m): Grigeo Tissue at Grigiškės (PM5, PM6, PM7 ordered with Toscotec for 2028, group tissue 70 to 140 kt incl. Poland) and Grigeo Klaipėda (recycled testliner and fluting). DS Smith, Smurfit Westrock and Stora Enso run packaging converters. No paper PCC or paper GCC - AB Naujasis Kalcitas grinds agricultural limestone at Akmenė.$cm$,
   $cm${"fillers": "Ground limestone: Naujasis Kalcitas (agricultural grades). Not added: AB Kalcitas, Akmenės Cementas. No paper PCC.", "mills": "Tissue: Grigeo Tissue. Liner: Grigeo Klaipėda. Context: Grigeo Hygiene and Packaging, DS Smith, Smurfit Westrock Baltic, Stora Enso Packaging.", "strategy": "Grigeo Tissue trial on PM5 / PM6 and FCC in the PM7 furnish design, then group roll-out to Poland and Germany. Naujasis Kalcitas only as raw material for a possible Baltic FCC site.", "risks": "Small volume, tissue filler limits.", "next_steps": ["Send Korean tissue trial data to Grigeo Tissue"], "key_numbers": [{"label": "Grigeo group 2024", "value": "EUR 213 m sales, EBITDA EUR 34.8 m"}, {"label": "PM7", "value": "70 kt, H1 2028"}], "files": ["seed_20261016zzl_lithuania_mills_fillers"]}$cm$::jsonb,
   $cm$Grigeo Tissue Grigiškės(PM5·PM6, 신규 PM7 7만 t 2028)·Grigeo Klaipėda 재생 라이너 — 제지용 PCC·GCC 없음, Akmenė 분쇄 석회석$cm$,
   $cm$리투아니아 초지기는 Grigeo 그룹(2024 매출 약 2.13억 유로) 소유: Grigeo Tissue Grigiškės(PM5·PM6, 2028 PM7 Toscotec, 그룹 티슈 7만→14만 t 폴란드 포함), Grigeo Klaipėda(재생 테스트라이너·골심지). DS Smith·Smurfit Westrock·Stora Enso 는 포장 가공. 제지용 PCC·GCC 없음 — Naujasis Kalcitas 가 Akmenė 에서 농업용 석회석 분쇄.$cm$,
   2100, 7000,
   $cm$Grigeo 티슈 7만 t × 3% ~ PM7 후 그룹 14만 t × 5% (폴란드 포함)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('grigeo tissue|grigeo.*grigi[sš]k|grigi[sš]k[eė]s', null, 'grigeo'),
  ('grigeo.*klaip|klaip[eė]dos kartonas', 'klaip[eė]d', 'grigeo'),
  ('grigeo hygiene', null, 'grigeo hygiene'),
  ('grigeo.*packaging', null, 'grigeo.*packaging'),
  ('ds smith.*(lithuan|lietuv)', null, 'ds smith.*(lithuan|lietuv)'),
  ('smurfit.*baltic', null, 'smurfit.*baltic'),
  ('stora enso.*(lithuan|lietuv|packaging)', null, 'stora enso.*(lithuan|lietuv|packaging)')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'lithuania_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'lithuania_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'naujasis kalcitas')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'LT'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'LT'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'LT'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    