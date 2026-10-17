-- ============================================================
-- seed_20261016x_turkmenistan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Turkmenistan update (reports 2026-10-16).
-- 1) Filler if missing (1): Magdanly Construction Materials Plant (PCC,
--    paint grade). Koytendag project and stone or building firms not added.
-- 2) Mills if missing (2) + plant blocks: Blue Hills / Gök Depeler (1),
--    Toprak / NowaEco (2). Context (5): Tere, MONA, Rowaç/Aýla, Türkmengala
--    cones, Derýa ýoly (Ekoston).
-- 3) app.country_markets TM row (priority low).
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
           v.party_name, 'TM', v.region, v.city, v.website, 'active', 'turkmenistan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('magdanly', 'Magdanly Construction Materials Plant (PCC)', 'Lebap', 'Magdanly', null, 'Lebap Magdanly 건설자재공장 — 2019 화학 침강 백악(PCC) 설비(현지 석회석, 1,200°C 소성로, 반응기), 초기 12 t 이상, 수성 도료용.', 'Magdanly Construction Materials Plant, Magdanly (Lebap) - chemically precipitated chalk (PCC) unit set up 2019 on local limestone with kiln (over 1,200 C, about 72 h), mill and reactor partly built with Turkmenmashinstroy, first output over 12 t for water-based emulsion paint.', 'TM check 2026-10-16: current operation and capacity not public, paper use not confirmed. Not added: Koytendag 50 kt/yr calcite plant (tenders 2020 and 2022, completion unconfirmed), Turkmenmermer (marble and granite stone), Ak Gaya (building materials), foreign GCC sellers.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('magdanly', 'Magdanly Construction Materials Plant (PCC)', 'Lebap', 'Magdanly', null, 'Lebap Magdanly 건설자재공장 — 2019 화학 침강 백악(PCC) 설비(현지 석회석, 1,200°C 소성로, 반응기), 초기 12 t 이상, 수성 도료용.', 'Magdanly Construction Materials Plant, Magdanly (Lebap) - chemically precipitated chalk (PCC) unit set up 2019 on local limestone with kiln (over 1,200 C, about 72 h), mill and reactor partly built with Turkmenmashinstroy, first output over 12 t for water-based emulsion paint.', 'TM check 2026-10-16: current operation and capacity not public, paper use not confirmed. Not added: Koytendag 50 kt/yr calcite plant (tenders 2020 and 2022, completion unconfirmed), Turkmenmermer (marble and granite stone), Ak Gaya (building materials), foreign GCC sellers.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'turkmenistan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Magdanly Construction Materials Plant (PCC)', 'PCC producer', 'Small state PCC unit (paint grade)', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'turkmenistan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'TM', v.region, v.city, v.website, 'active', 'turkmenistan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('blue hills|g[oö]k ?depeler', 'g[oö]kdepe|owadandepe|ovadandepe', 'blue hills|g[oö]k ?depeler', 'Blue Hills (Gök Depeler) - Gökdepe', 'Ahal', 'Gökdepe', null, '2025-06 가동 복사용지·오프셋 인쇄용지 공장(법인 Gök Depeler). 설계 연 14,400 t, 2026 월 1,200 t. 100% 표백 버진 펄프 수입(포르투갈·브라질·오스트리아·스페인·튀르키예), 40~120 g/m², 중앙아시아·이란 등 수출.', 'Blue Hills paper mill (legal entity ES Gök Depeler), Owadandepe, 4 km east of Nedir, Gökdepe (Ahal) - started 2025-06: A3 and A4 office paper and offset printing paper, 40-120 g/m2 on 100 pct imported bleached virgin pulp (Portugal, Brazil, Austria, Spain, Turkey). Design 14,400 t/yr, output raised to 1,200 t/month in 2026 (600 before). Exports to Uzbekistan, Tajikistan, Iran, Azerbaijan, Pakistan, Armenia.', 'TM check 2026-10-16: filler use not public. Do not count Gök Depeler separately. info@bluehillspm.com, +993 63 05 93 04.'),
  ('toprak|nowaeco', 'ya[sş]lyk|ovadandepe', 'toprak|nowaeco', 'Toprak (NowaEco) - Yashlyk', 'Ahal', 'Yashlyk', null, '1999년부터 골판지·포장 사업 Toprak(NowaEco). 폐지·섬유·농업 부산물 원지공장(2013 EBRD 계획 일 25 t), 사무용지 A4 월 10만 팩(2024), 포장원지·골판지·종이봉투.', 'Toprak Economic Society (NowaEco brand), Yashlyk and Ovadandepe (Ahal) - corrugated and packaging since 1999, own base-paper mill on waste paper and textile and farm residues (EBRD-financed, planned up to 25 t/day in 2013), A4 office paper about 100,000 packs/month (2024), packaging base paper, corrugated board, paper bags. UNDP recycling partner.', 'TM check 2026-10-16: 25 t/day is the 2013 plan, not current capacity - kept in notes only. hydyrtaymaz@gmail.com (2022 listing).')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('blue hills|g[oö]k ?depeler', 'g[oö]kdepe|owadandepe|ovadandepe', 'blue hills|g[oö]k ?depeler', '2025-06 가동 복사용지·오프셋 인쇄용지 공장(법인 Gök Depeler). 설계 연 14,400 t, 2026 월 1,200 t. 100% 표백 버진 펄프 수입(포르투갈·브라질·오스트리아·스페인·튀르키예), 40~120 g/m², 중앙아시아·이란 등 수출.', 'Blue Hills paper mill (legal entity ES Gök Depeler), Owadandepe, 4 km east of Nedir, Gökdepe (Ahal) - started 2025-06: A3 and A4 office paper and offset printing paper, 40-120 g/m2 on 100 pct imported bleached virgin pulp (Portugal, Brazil, Austria, Spain, Turkey). Design 14,400 t/yr, output raised to 1,200 t/month in 2026 (600 before). Exports to Uzbekistan, Tajikistan, Iran, Azerbaijan, Pakistan, Armenia.', 'TM check 2026-10-16: filler use not public. Do not count Gök Depeler separately. info@bluehillspm.com, +993 63 05 93 04.'),
  ('toprak|nowaeco', 'ya[sş]lyk|ovadandepe', 'toprak|nowaeco', '1999년부터 골판지·포장 사업 Toprak(NowaEco). 폐지·섬유·농업 부산물 원지공장(2013 EBRD 계획 일 25 t), 사무용지 A4 월 10만 팩(2024), 포장원지·골판지·종이봉투.', 'Toprak Economic Society (NowaEco brand), Yashlyk and Ovadandepe (Ahal) - corrugated and packaging since 1999, own base-paper mill on waste paper and textile and farm residues (EBRD-financed, planned up to 25 t/day in 2013), A4 office paper about 100,000 packs/month (2024), packaging base paper, corrugated board, paper bags. UNDP recycling partner.', 'TM check 2026-10-16: 25 t/day is the 2013 plan, not current capacity - kept in notes only. hydyrtaymaz@gmail.com (2022 listing).'),
  ('\mtere\M', null, '\mtere\M', null, null, 'TM check 2026-10-16: Toilet tissue, towels, napkins, Ashgabat (2020), 100 pct cellulose - own machine not confirmed - context only.'),
  ('\mmona\M', null, '\mmona\M', null, null, 'TM check 2026-10-16: 3-ply tissue and wet wipes, Ak Bugday (2018) - own machine not confirmed - context only.'),
  ('rowa[cç]|a[yý]la', null, 'rowa[cç]|a[yý]la', null, null, 'TM check 2026-10-16: Napkins, towels, toilet tissue, Gökdepe (2016, Turkish machines) - converter - context only.'),
  ('t[uü]rkmengala', null, 't[uü]rkmengala', null, null, 'TM check 2026-10-16: Textile paper cones on bought 320 g/m2 board - converter - context only.'),
  ('der[yý]a [yý]oly|ekoston', null, 'der[yý]a [yý]oly|ekoston', null, null, 'TM check 2026-10-16: Stone paper 5,500 t/yr on calcite and polymer (2025) - not a pulp mill - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'turkmenistan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('blue hills|g[oö]k ?depeler', 'g[oö]kdepe|owadandepe|ovadandepe', 'blue hills|g[oö]k ?depeler'),
  ('toprak|nowaeco', 'ya[sş]lyk|ovadandepe', 'toprak|nowaeco'),
  ('\mtere\M', null, '\mtere\M'),
  ('\mmona\M', null, '\mmona\M'),
  ('rowa[cç]|a[yý]la', null, 'rowa[cç]|a[yý]la'),
  ('t[uü]rkmengala', null, 't[uü]rkmengala'),
  ('der[yý]a [yý]oly|ekoston', null, 'der[yý]a [yý]oly|ekoston')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('blue hills|g[oö]k ?depeler', 'g[oö]kdepe|owadandepe|ovadandepe', 'blue hills|g[oö]k ?depeler',
   $pj${"owner": "Gök Depeler", "priority": 1, "products": "Office copy paper, offset paper", "grades": ["Copy paper", "UWF"], "capacity": {"value": 14400, "unit": "metric_t", "year": "Design (2026 press)", "source": "Business Turkmenistan"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct - planning only."}, "pitch": "Imported-pulp saving on copy paper - opacity, strength, retention", "approach": "Lead Turkmen account - new mill, imported pulp. GCC via CEMIX (Uzbekistan) as nearest paper-grade source.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "Start-up 2025-06, 1,200 t/month 2026", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('toprak|nowaeco', 'ya[sş]lyk|ovadandepe', 'toprak|nowaeco',
   $pj${"owner": "Toprak", "priority": 2, "products": "Recycled office paper, packaging base paper, corrugated", "grades": ["Copy paper", "Testliner", "Medium"], "approach": "Office-paper line first, packaging later.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mtere\M', null, '\mtere\M',
   $pj${"owner": "Tere Paper Factory", "products": "Toilet tissue, towels, napkins, Ashgabat (2020), 100 pct cellulose - own machine not confirmed", "approach": "Converter or non-pulp.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mmona\M', null, '\mmona\M',
   $pj${"owner": "MONA", "products": "3-ply tissue and wet wipes, Ak Bugday (2018) - own machine not confirmed", "approach": "Converter or non-pulp.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rowa[cç]|a[yý]la', null, 'rowa[cç]|a[yý]la',
   $pj${"owner": "Rowaç / Aýla", "products": "Napkins, towels, toilet tissue, Gökdepe (2016, Turkish machines) - converter", "approach": "Converter or non-pulp.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('t[uü]rkmengala', null, 't[uü]rkmengala',
   $pj${"owner": "Türkmengala Paper Cone Factory", "products": "Textile paper cones on bought 320 g/m2 board - converter", "approach": "Converter or non-pulp.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('der[yý]a [yý]oly|ekoston', null, 'der[yý]a [yý]oly|ekoston',
   $pj${"owner": "Derýa ýoly (Ekoston)", "products": "Stone paper 5,500 t/yr on calcite and polymer (2025) - not a pulp mill", "approach": "Converter or non-pulp.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TM', 'Turkmenistan', 'low',
   $cm$Blue Hills new copy-paper mill (14.4 kt, imported virgin pulp, 2025) and Toprak recycled paper - small state PCC unit at Magdanly$cm$,
   $cm$Turkmenistan's lead mill is Blue Hills (Gök Depeler, Gökdepe): copy and offset paper on imported bleached pulp, started 2025-06, 14,400 t/yr design and 1,200 t/month in 2026, exporting across Central Asia. Toprak (NowaEco) makes recycled office and packaging paper. Tissue firms (Tere, MONA, Rowaç/Aýla) look like converters. Filler side: a small state PCC unit at Magdanly (2019, paint grade) and a 50 kt calcite plant tendered at Koytendag (completion unconfirmed). Derýa ýoly makes stone paper on calcite.$cm$,
   $cm${"fillers": "PCC: Magdanly Construction Materials Plant (2019, paint grade). Not added: Koytendag calcite plant (50 kt tender, unconfirmed), Turkmenmermer, Ak Gaya. Foreign sellers named: Arosha Powder and MAD KOOHZAD (Iran - sanctioned), CEMIX (Uzbekistan), Mikron'S (Turkey).", "mills": "Copy and offset: Blue Hills (Gök Depeler). Recycled office and packaging: Toprak (NowaEco). Context: Tere, MONA, Rowaç/Aýla (tissue, machines unconfirmed), Türkmengala cones, Ekoston stone paper.", "strategy": "Blue Hills trial on imported-pulp saving, GCC via CEMIX (Uzbekistan). Do not source Iranian GCC (sanctions).", "risks": "Small volumes, Iranian supply route is sanctioned.", "next_steps": ["Approach Blue Hills technical with copy-paper FCC data"], "key_numbers": [{"label": "Blue Hills", "value": "14,400 t/yr design, 1,200 t/month 2026"}, {"label": "Ekoston stone paper", "value": "5,500 t/yr"}], "files": ["seed_20261016x_turkmenistan_mills_fillers"]}$cm$::jsonb,
   $cm$Blue Hills 신규 복사용지 공장(1.44만 t, 수입 버진 펄프, 2025) + Toprak 재생지 — Magdanly 소형 국영 PCC$cm$,
   $cm$핵심 제지사는 Blue Hills(Gök Depeler, Gökdepe): 수입 표백 펄프 복사·오프셋용지, 2025-06 가동, 설계 1.44만 t·2026 월 1,200 t, 중앙아시아 수출. Toprak(NowaEco) 재생 사무·포장용지. 티슈 업체(Tere·MONA·Rowaç/Aýla)는 가공 추정. 충전제: Magdanly 소형 국영 PCC(2019, 도료용), Koytendag 5만 t 방해석 공장 입찰(완공 미확인). Ekoston 스톤페이퍼.$cm$,
   720, 1440,
   $cm$Blue Hills 1.44만 t × FCC 5~10% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('blue hills|g[oö]k ?depeler', 'g[oö]kdepe|owadandepe|ovadandepe', 'blue hills|g[oö]k ?depeler'),
  ('toprak|nowaeco', 'ya[sş]lyk|ovadandepe', 'toprak|nowaeco'),
  ('\mtere\M', null, '\mtere\M'),
  ('\mmona\M', null, '\mmona\M'),
  ('rowa[cç]|a[yý]la', null, 'rowa[cç]|a[yý]la'),
  ('t[uü]rkmengala', null, 't[uü]rkmengala'),
  ('der[yý]a [yý]oly|ekoston', null, 'der[yý]a [yý]oly|ekoston')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'turkmenistan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'turkmenistan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'magdanly')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    