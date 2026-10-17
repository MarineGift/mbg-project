-- ============================================================
-- seed_20261016zf_northmacedonia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- North Macedonia update (reports 2026-10-16).
-- 1) Fillers if missing (4): A&N Mikrogranulat, IGM Vratnica, Omya Minerali
--    (MK, to verify), Mermeren Kombinat Prilep (raw marble).
-- 2) Mill if missing + plant block: Paper Mill Kočani (1). Context (6):
--    DS Smith Skopje, Miskom, Fustelarko Borec, Evropa 92, Sofija Print,
--    Superior-ER.
-- 3) app.country_markets MK row (priority low).
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
           v.party_name, 'MK', v.region, v.city, v.website, 'active', 'northmacedonia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('mikrogranulat', 'A&N Mikrogranulat - Gostivar', 'Polog', 'Gostivar', null, '1990년 설립 Gostivar 산업지구 GCC — 자체 광산, Micronized Calcite 5(D97)·10·20·40·63~150 μm, 제지 용도 명시. 2023~2024 EU·독일 지원 신규 라인·공압이송·사일로.', 'A&N Mikrogranulat (1990), Industrial Zone bb, Gostivar - GCC of its own quarried calcite: micronised calcite 5 micron (D97), 10, 20, 40 and 63-150 micron plus granules, paper named. New line, pneumatic conveying and silos added 2023-2024 with EU and German support.', 'MK check 2026-10-16: annual capacity and wet capability not public. a.n.mikrogranulat@gmail.com, +389 42 273 796. FCC OEM candidate 1.'),
  ('igm vratnica', 'IGM Vratnica - Vizbegovo', 'Skopje', 'Skopje', null, 'Vratnica(Jegunovce) 광업기업 IGM — 2006 Skopje Vizbegovo 미분 방해석·돌로마이트 공장(0~100 μm), 제지·도료·고무·케이블·사료(2011 자료). 2025 장관 방문, 2026-06 재무 공시.', 'IGM Vratnica AD, Vratnica (Jegunovce) with a micronised calcite and dolomite plant at Vizbegovo industrial zone, Skopje (since 2006, 0-100 micron), customers named in 2011: paper, paint, rubber, cables, construction, feed. Active - minister visit 2025-03, financials filed 2026-06.', 'MK check 2026-10-16: current paper line not confirmed, contacts are 2011 data (igmvratnica@mt.net.mk).'),
  ('omya.*(mk|macedon|minerali)', 'Omya Minerali (MK) - Vizbegovo', 'Skopje', 'Skopje', null, 'Omya 관련 북마케도니아 사업장 등재(Vizbegovo 산업지구) — 현지 제조 여부 미확인.', 'Omya Minerali (MK), Vizbegovo industrial zone, Skopje - listed in a third-party directory as an Omya-related company.', 'MK check 2026-10-16: ownership, production and products not confirmed. Omya group is a royalty licensee at HQ level.'),
  ('mermeren|sivec', 'Mermeren Kombinat - Prilep', 'Pelagonia', 'Prilep', null, 'Prilep SIVEC 고백색 대리석 채굴·가공.', 'Mermeren Kombinat AD Prilep - SIVEC high-white marble quarrying and processing.', 'MK check 2026-10-16: white marble is a GCC raw-material option - purity and grinding not tested. Not added: TITAN Usje (cement limestone), Vardar Dolomit (refractory dolomite). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('mikrogranulat', 'A&N Mikrogranulat - Gostivar', 'Polog', 'Gostivar', null, '1990년 설립 Gostivar 산업지구 GCC — 자체 광산, Micronized Calcite 5(D97)·10·20·40·63~150 μm, 제지 용도 명시. 2023~2024 EU·독일 지원 신규 라인·공압이송·사일로.', 'A&N Mikrogranulat (1990), Industrial Zone bb, Gostivar - GCC of its own quarried calcite: micronised calcite 5 micron (D97), 10, 20, 40 and 63-150 micron plus granules, paper named. New line, pneumatic conveying and silos added 2023-2024 with EU and German support.', 'MK check 2026-10-16: annual capacity and wet capability not public. a.n.mikrogranulat@gmail.com, +389 42 273 796. FCC OEM candidate 1.'),
  ('igm vratnica', 'IGM Vratnica - Vizbegovo', 'Skopje', 'Skopje', null, 'Vratnica(Jegunovce) 광업기업 IGM — 2006 Skopje Vizbegovo 미분 방해석·돌로마이트 공장(0~100 μm), 제지·도료·고무·케이블·사료(2011 자료). 2025 장관 방문, 2026-06 재무 공시.', 'IGM Vratnica AD, Vratnica (Jegunovce) with a micronised calcite and dolomite plant at Vizbegovo industrial zone, Skopje (since 2006, 0-100 micron), customers named in 2011: paper, paint, rubber, cables, construction, feed. Active - minister visit 2025-03, financials filed 2026-06.', 'MK check 2026-10-16: current paper line not confirmed, contacts are 2011 data (igmvratnica@mt.net.mk).'),
  ('omya.*(mk|macedon|minerali)', 'Omya Minerali (MK) - Vizbegovo', 'Skopje', 'Skopje', null, 'Omya 관련 북마케도니아 사업장 등재(Vizbegovo 산업지구) — 현지 제조 여부 미확인.', 'Omya Minerali (MK), Vizbegovo industrial zone, Skopje - listed in a third-party directory as an Omya-related company.', 'MK check 2026-10-16: ownership, production and products not confirmed. Omya group is a royalty licensee at HQ level.'),
  ('mermeren|sivec', 'Mermeren Kombinat - Prilep', 'Pelagonia', 'Prilep', null, 'Prilep SIVEC 고백색 대리석 채굴·가공.', 'Mermeren Kombinat AD Prilep - SIVEC high-white marble quarrying and processing.', 'MK check 2026-10-16: white marble is a GCC raw-material option - purity and grinding not tested. Not added: TITAN Usje (cement limestone), Vardar Dolomit (refractory dolomite). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'northmacedonia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('A&N Mikrogranulat - Gostivar', 'GCC producer', 'Local micronised GCC, paper named - candidate 1', 'merchant', 'B', 'gcc'),
  ('IGM Vratnica - Vizbegovo', 'GCC producer', 'Micronised calcite with paper history', 'merchant', 'C', 'gcc'),
  ('Omya Minerali (MK) - Vizbegovo', 'GCC and PCC supplier', 'Omya-related site - to verify', 'merchant', 'C', 'gcc'),
  ('Mermeren Kombinat - Prilep', 'Carbonate raw material', 'High-white marble - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'northmacedonia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MK', v.region, v.city, v.website, 'active', 'northmacedonia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('paper mill ko[cč]ani|\mko[cč]ani\M.*paper', 'ko[cč]ani', 'paper mill|unitrade', 'Paper Mill Kočani', 'Eastern', 'Kočani', null, '1963년 설립 재생 포장원지 공장(Kočani), 2016 불가리아 UNITRADE CLUSTER 인수·재건. 폐지 처리 연 1.5만 t, Fluting WB·Schrenz·봉투용 갈색지·플로터지·지관원지, 120명.', 'Paper Mill Kočani (1963), Todosija Paunov 36, Kočani - bought by UNITRADE CLUSTER (Bulgaria) in 2016, rebuilt with over EUR 8 m in technical and environmental investment: 15,000 t/yr waste-paper recycling, Fluting WB, Schrenz, brown bag paper, plotter paper and core board paper, 80,000 m2 site, about 120 staff.', 'MK check 2026-10-16: 15 kt is waste input, not confirmed paper output - 2026 operation to confirm. office@paper-mill.eu, +389 70 376 213.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('paper mill ko[cč]ani|\mko[cč]ani\M.*paper', 'ko[cč]ani', 'paper mill|unitrade', '1963년 설립 재생 포장원지 공장(Kočani), 2016 불가리아 UNITRADE CLUSTER 인수·재건. 폐지 처리 연 1.5만 t, Fluting WB·Schrenz·봉투용 갈색지·플로터지·지관원지, 120명.', 'Paper Mill Kočani (1963), Todosija Paunov 36, Kočani - bought by UNITRADE CLUSTER (Bulgaria) in 2016, rebuilt with over EUR 8 m in technical and environmental investment: 15,000 t/yr waste-paper recycling, Fluting WB, Schrenz, brown bag paper, plotter paper and core board paper, 80,000 m2 site, about 120 staff.', 'MK check 2026-10-16: 15 kt is waste input, not confirmed paper output - 2026 operation to confirm. office@paper-mill.eu, +389 70 376 213.'),
  ('ds smith.*skopje|ds smith ad', null, 'ds smith.*skopje|ds smith ad', null, null, 'MK check 2026-10-16: Corrugated packaging, Skopje (2025 sales MKD 1,027 m, net loss) - no paper machine found - context only.'),
  ('miskom', null, 'miskom', null, null, 'MK check 2026-10-16: Corrugated board and boxes, Struga, 15 kt/yr - buys liner, own strength lab - context only.'),
  ('fustelarko', null, 'fustelarko', null, null, 'MK check 2026-10-16: Printed folding cartons, Bitola - converter - context only.'),
  ('evropa 92', null, 'evropa 92', null, null, 'MK check 2026-10-16: Printing and packaging, Kočani - converter - context only.'),
  ('sofija print', null, 'sofija print', null, null, 'MK check 2026-10-16: Packaging, metallised board, corrugated, Bogdanci - converter - context only.'),
  ('superior-?er', null, 'superior-?er', null, null, 'MK check 2026-10-16: Paper rolls and flexible packaging, Skopje - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'northmacedonia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('paper mill ko[cč]ani|\mko[cč]ani\M.*paper', 'ko[cč]ani', 'paper mill|unitrade'),
  ('ds smith.*skopje|ds smith ad', null, 'ds smith.*skopje|ds smith ad'),
  ('miskom', null, 'miskom'),
  ('fustelarko', null, 'fustelarko'),
  ('evropa 92', null, 'evropa 92'),
  ('sofija print', null, 'sofija print'),
  ('superior-?er', null, 'superior-?er')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('paper mill ko[cč]ani|\mko[cč]ani\M.*paper', 'ko[cč]ani', 'paper mill|unitrade',
   $pj${"owner": "UNITRADE CLUSTER", "priority": 1, "products": "Fluting, Schrenz, bag paper, plotter paper, core board", "grades": ["Medium", "Core board", "Bag paper"], "approach": "Only confirmed paper machine - 5-10 pct strength-hold pilot (CMT, SCT, RCT, burst).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*skopje|ds smith ad', null, 'ds smith.*skopje|ds smith ad',
   $pj${"owner": "DS Smith AD Skopje", "products": "Corrugated packaging, Skopje (2025 sales MKD 1,027 m, net loss) - no paper machine found", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('miskom', null, 'miskom',
   $pj${"owner": "Miskom", "products": "Corrugated board and boxes, Struga, 15 kt/yr - buys liner, own strength lab", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fustelarko', null, 'fustelarko',
   $pj${"owner": "Fustelarko Borec", "products": "Printed folding cartons, Bitola - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('evropa 92', null, 'evropa 92',
   $pj${"owner": "Evropa 92", "products": "Printing and packaging, Kočani - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofija print', null, 'sofija print',
   $pj${"owner": "Sofija Print", "products": "Packaging, metallised board, corrugated, Bogdanci - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('superior-?er', null, 'superior-?er',
   $pj${"owner": "Superior-ER", "products": "Paper rolls and flexible packaging, Skopje - converter", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MK', 'North Macedonia', 'low',
   $cm$One recycled paper mill (Kočani, 15 kt waste paper) - local micronised GCC at A&N Mikrogranulat and IGM Vratnica$cm$,
   $cm$North Macedonia's only confirmed paper machine is Paper Mill Kočani (UNITRADE CLUSTER, recycled fluting, Schrenz, bag and core board, 15 kt/yr waste-paper input). Corrugated and printed packaging plants convert (DS Smith Skopje, Miskom, Fustelarko, Evropa 92, Sofija Print). GCC: A&N Mikrogranulat (Gostivar, 5 micron, paper named, new line), IGM Vratnica (Vizbegovo, paper history), an Omya-related listing, SIVEC marble at Prilep. No paper PCC. MEL Macedonian Paper Mills is in Greece, not here.$cm$,
   $cm${"fillers": "GCC: A&N Mikrogranulat, IGM Vratnica, Omya Minerali (MK, to verify). Raw: Mermeren Kombinat (SIVEC). Not added: TITAN Usje, Vardar Dolomit. No PCC.", "mills": "Paper Mill Kočani. Converters (context): DS Smith AD Skopje, Miskom, Fustelarko Borec, Evropa 92, Sofija Print, Superior-ER.", "strategy": "Pilot at Kočani with A&N Mikrogranulat GCC - small Balkan reference. DS Smith Skopje as door to group mills.", "risks": "Tiny volume, recycled-liner strength limits.", "next_steps": ["Confirm Kočani operation and output"], "key_numbers": [{"label": "Paper Mill Kočani", "value": "15 kt/yr waste-paper input"}], "files": ["seed_20261016zf_northmacedonia_mills_fillers"]}$cm$::jsonb,
   $cm$재생 제지공장 1곳(Kočani, 폐지 1.5만 t) — 현지 미분 GCC A&N Mikrogranulat·IGM Vratnica$cm$,
   $cm$북마케도니아에서 초지기가 확인된 곳은 Paper Mill Kočani(UNITRADE CLUSTER, 재생 골심지·Schrenz·봉투·지관원지, 폐지 투입 연 1.5만 t) 뿐. 골판지·인쇄포장은 가공. GCC: A&N Mikrogranulat(Gostivar 5 μm, 제지 명시), IGM Vratnica(Vizbegovo), Omya 관련 등재, Prilep SIVEC 대리석. 제지용 PCC 없음. MEL Macedonian Paper Mills 는 그리스 회사.$cm$,
   750, 1500,
   $cm$Kočani 원지 1.5만 t 가정 × FCC 5~10%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('paper mill ko[cč]ani|\mko[cč]ani\M.*paper', 'ko[cč]ani', 'paper mill|unitrade'),
  ('ds smith.*skopje|ds smith ad', null, 'ds smith.*skopje|ds smith ad'),
  ('miskom', null, 'miskom'),
  ('fustelarko', null, 'fustelarko'),
  ('evropa 92', null, 'evropa 92'),
  ('sofija print', null, 'sofija print'),
  ('superior-?er', null, 'superior-?er')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'northmacedonia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'northmacedonia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'mikrogranulat' or p.party_name ~* 'igm vratnica' or p.party_name ~* 'omya.*(mk|macedon|minerali)' or p.party_name ~* 'mermeren|sivec')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MK'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MK'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MK'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    