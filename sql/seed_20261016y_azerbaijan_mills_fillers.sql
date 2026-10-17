-- ============================================================
-- seed_20261016y_azerbaijan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Azerbaijan update (reports 2026-10-16).
-- 1) Fillers if missing (3): Azeka BM (36 kt planned), Caltech, Fortis Group.
-- 2) Mills if missing (2) + plant blocks: Azersun Paper and Cardboard Plant
--    (1), Azersun Tissue Paper Factory (2). Context (3): Baku Cardboard,
--    Fabriora, Azersun Khirdalan Cardboard.
-- 3) app.country_markets AZ row (priority low).
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
           v.party_name, 'AZ', v.region, v.city, v.website, 'active', 'azerbaijan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('azeka', 'Azeka BM - Sumgait', 'Sumgait', 'Sumgait', null, 'Sumgait 화학산업단지 입주(2021-10) GCC·분쇄 방해석 공장 계획 — 연 3.6만 t, 약 700만 AZN, 중국·튀르키예 기술.', 'Azeka BM LLC, Sumgait Chemical Industrial Park (resident since 2021-10) - ground calcium carbonate and milled calcite plant planned at 36,000 t/yr, about AZN 7 m, Chinese and Turkish equipment, 40 jobs, home and export market.', 'AZ check 2026-10-16: 36 kt is the plan - operation and paper grades not confirmed.'),
  ('caltech', 'Caltech - Agdam', 'Agdam', 'Agdam', null, 'Agdam 산업단지(2024-06) 미분화·코팅 방해석 공장 계획(370만 AZN).', 'Caltech LLC, Agdam Industrial Park (resident since 2024-06) - micronised and coated calcite plant, about AZN 3.7 m, 30 jobs.', 'AZ check 2026-10-16: coated calcite is the hydrophobic plastics grade, not paper coating - uncoated line to confirm. info@caltech.az, +994 50 285 68 35.'),
  ('fortis group', 'Fortis Group - Khirdalan', 'Absheron', 'Khirdalan', null, '2004년부터 건축자재 기업(Khirdalan). Calcite powder(CaCO3+MgCO3 97.5%, Fe2O3 0.08%, 반사율 90% 이상), 종이 용도 명시.', 'Fortis Group LLC (since 2004), Khirdalan (Absheron) - building materials, calcite powder (CaCO3 plus MgCO3 97.5 pct, Fe2O3 max 0.08 pct, SiO2 1 pct, reflectance min 90) for paper, paint, rubber, cables, plastics.', 'AZ check 2026-10-16: fine particle size and own grinding not confirmed. info@fortisgroup.az, +994 12 349 75 00. No paper PCC plant or Omya site in Azerbaijan.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('azeka', 'Azeka BM - Sumgait', 'Sumgait', 'Sumgait', null, 'Sumgait 화학산업단지 입주(2021-10) GCC·분쇄 방해석 공장 계획 — 연 3.6만 t, 약 700만 AZN, 중국·튀르키예 기술.', 'Azeka BM LLC, Sumgait Chemical Industrial Park (resident since 2021-10) - ground calcium carbonate and milled calcite plant planned at 36,000 t/yr, about AZN 7 m, Chinese and Turkish equipment, 40 jobs, home and export market.', 'AZ check 2026-10-16: 36 kt is the plan - operation and paper grades not confirmed.'),
  ('caltech', 'Caltech - Agdam', 'Agdam', 'Agdam', null, 'Agdam 산업단지(2024-06) 미분화·코팅 방해석 공장 계획(370만 AZN).', 'Caltech LLC, Agdam Industrial Park (resident since 2024-06) - micronised and coated calcite plant, about AZN 3.7 m, 30 jobs.', 'AZ check 2026-10-16: coated calcite is the hydrophobic plastics grade, not paper coating - uncoated line to confirm. info@caltech.az, +994 50 285 68 35.'),
  ('fortis group', 'Fortis Group - Khirdalan', 'Absheron', 'Khirdalan', null, '2004년부터 건축자재 기업(Khirdalan). Calcite powder(CaCO3+MgCO3 97.5%, Fe2O3 0.08%, 반사율 90% 이상), 종이 용도 명시.', 'Fortis Group LLC (since 2004), Khirdalan (Absheron) - building materials, calcite powder (CaCO3 plus MgCO3 97.5 pct, Fe2O3 max 0.08 pct, SiO2 1 pct, reflectance min 90) for paper, paint, rubber, cables, plastics.', 'AZ check 2026-10-16: fine particle size and own grinding not confirmed. info@fortisgroup.az, +994 12 349 75 00. No paper PCC plant or Omya site in Azerbaijan.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'azerbaijan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Azeka BM - Sumgait', 'GCC producer', 'Planned 36 kt GCC plant - candidate 1', 'merchant', 'C', 'gcc'),
  ('Caltech - Agdam', 'GCC producer', 'Micronised calcite - candidate 2', 'merchant', 'C', 'gcc'),
  ('Fortis Group - Khirdalan', 'GCC producer', 'Calcite powder, paper named', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'azerbaijan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'AZ', v.region, v.city, v.website, 'active', 'azerbaijan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('ka[gğ][iı]z v[eə] karton|paper and cardboard (production|plant)|akk[iı]k', 'sumqay|sumgay', 'ka[gğ][iı]z|paper and cardboard|akk[iı]k', 'Azersun - Azerbaijan Paper and Cardboard Plant (Sumgayit)', 'Sumgait', 'Sumgayit', null, 'Azersun 그룹 재생 종이·판지 공장(AKKIK, Sumgayit Azersun 산업단지, 2014-02 준공). 폐지 처리 연 5만 t, 재생 종이 롤·골판지 원지.', 'Azerbaijan Paper and Cardboard Production Plant (Azərbaycan Kağız və Karton İstehsalat Kombinatı, Azersun Holding), Azersun Industrial Estate, Sumgayit - opened 2014-02, 50,000 t/yr waste-paper processing, about 90 pct recovered fibre, recycled paper rolls and corrugating base paper. Azersun announced (2026-09-26) plans to double its recycling and packaging plants.', 'AZ check 2026-10-16: 50 kt is waste-paper input, not paper output - machine specs not public. info@azersun.com.'),
  ('azersun.*(tissue|gigiyen)|qafqaz ka[gğ][iı]z', 'sumqay|sumgay', 'tissue|gigiyen|qafqaz', 'Azersun - Tissue Paper Factory (Sumgayit)', 'Sumgait', 'Sumgayit', null, 'Azersun 위생용지 공장(1997 냅킨 사업 시작, 구 Caucasus Paper Industry) — 화장지·타월·냅킨·물티슈(Sun·Aura·Papi), 이탈리아·튀르키예 설비, FSC 2021. 2026-10-06 현장 공개.', 'Azersun Tissue Paper Factory (napkins since 1997, formerly Caucasus Paper Industry / Qafqaz Kağız Sənayesi, about 2,500 t/yr after 2005 upgrade), Azersun Industrial Estate, Sumgayit - toilet tissue, towels, napkins, wet wipes (Sun, Aura, Papi), Italian and Turkish machinery, FSC since 2021. Site shown 2026-10-06 by plant manager Kamil Safarov.', 'AZ check 2026-10-16: own tissue machine to confirm - 2,500 t is a 2005 figure, kept in notes only.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ka[gğ][iı]z v[eə] karton|paper and cardboard (production|plant)|akk[iı]k', 'sumqay|sumgay', 'ka[gğ][iı]z|paper and cardboard|akk[iı]k', 'Azersun 그룹 재생 종이·판지 공장(AKKIK, Sumgayit Azersun 산업단지, 2014-02 준공). 폐지 처리 연 5만 t, 재생 종이 롤·골판지 원지.', 'Azerbaijan Paper and Cardboard Production Plant (Azərbaycan Kağız və Karton İstehsalat Kombinatı, Azersun Holding), Azersun Industrial Estate, Sumgayit - opened 2014-02, 50,000 t/yr waste-paper processing, about 90 pct recovered fibre, recycled paper rolls and corrugating base paper. Azersun announced (2026-09-26) plans to double its recycling and packaging plants.', 'AZ check 2026-10-16: 50 kt is waste-paper input, not paper output - machine specs not public. info@azersun.com.'),
  ('azersun.*(tissue|gigiyen)|qafqaz ka[gğ][iı]z', 'sumqay|sumgay', 'tissue|gigiyen|qafqaz', 'Azersun 위생용지 공장(1997 냅킨 사업 시작, 구 Caucasus Paper Industry) — 화장지·타월·냅킨·물티슈(Sun·Aura·Papi), 이탈리아·튀르키예 설비, FSC 2021. 2026-10-06 현장 공개.', 'Azersun Tissue Paper Factory (napkins since 1997, formerly Caucasus Paper Industry / Qafqaz Kağız Sənayesi, about 2,500 t/yr after 2005 upgrade), Azersun Industrial Estate, Sumgayit - toilet tissue, towels, napkins, wet wipes (Sun, Aura, Papi), Italian and Turkish machinery, FSC since 2021. Site shown 2026-10-06 by plant manager Kamil Safarov.', 'AZ check 2026-10-16: own tissue machine to confirm - 2,500 t is a 2005 figure, kept in notes only.'),
  ('bak[iı] karton|baku cardboard', null, 'bak[iı] karton|baku cardboard', null, null, 'AZ check 2026-10-16: Corrugated sheets and boxes, Sumgayit Industrial Park, 55 m m2/yr (opened 2026-01-27, AZN 20 m) - waste recycling planned as phase 2 - context only.'),
  ('fabriora', null, 'fabriora', null, null, 'AZ check 2026-10-16: Hygiene products, towels, napkins, diapers, Garadagh (opened 2026-09-10, AZN 27 m) - tissue machine not confirmed - context only.'),
  ('x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan', null, 'x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan', null, null, 'AZ check 2026-10-16: Khirdalan Cardboard Factory - corrugated converting - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'azerbaijan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ka[gğ][iı]z v[eə] karton|paper and cardboard (production|plant)|akk[iı]k', 'sumqay|sumgay', 'ka[gğ][iı]z|paper and cardboard|akk[iı]k'),
  ('azersun.*(tissue|gigiyen)|qafqaz ka[gğ][iı]z', 'sumqay|sumgay', 'tissue|gigiyen|qafqaz'),
  ('bak[iı] karton|baku cardboard', null, 'bak[iı] karton|baku cardboard'),
  ('fabriora', null, 'fabriora'),
  ('x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan', null, 'x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ka[gğ][iı]z v[eə] karton|paper and cardboard (production|plant)|akk[iı]k', 'sumqay|sumgay', 'ka[gğ][iı]z|paper and cardboard|akk[iı]k',
   $pj${"owner": "Azersun Holding", "priority": 1, "products": "Recycled paper rolls, corrugating base paper", "grades": ["Testliner", "Medium"], "pitch": "Strength-hold FCC on recycled liner (SCT, RCT, burst, Cobb)", "approach": "Lead account - also pitch the 2026 expansion design.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('azersun.*(tissue|gigiyen)|qafqaz ka[gğ][iı]z', 'sumqay|sumgay', 'tissue|gigiyen|qafqaz',
   $pj${"owner": "Azersun Holding", "priority": 2, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "approach": "Confirm base-paper machine, then low-dose trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bak[iı] karton|baku cardboard', null, 'bak[iı] karton|baku cardboard',
   $pj${"owner": "Baku Cardboard and Box Factory", "products": "Corrugated sheets and boxes, Sumgayit Industrial Park, 55 m m2/yr (opened 2026-01-27, AZN 20 m) - waste recycling planned as phase 2", "approach": "Converter or new project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fabriora', null, 'fabriora',
   $pj${"owner": "Fabriora Group", "products": "Hygiene products, towels, napkins, diapers, Garadagh (opened 2026-09-10, AZN 27 m) - tissue machine not confirmed", "approach": "Converter or new project.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan', null, 'x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan',
   $pj${"owner": "Azersun Holding", "products": "Khirdalan Cardboard Factory - corrugated converting", "approach": "Converter or new project.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AZ', 'Azerbaijan', 'low',
   $cm$Azersun recycled paper and board (50 kt waste paper) and tissue in Sumgayit - planned GCC plants (Azeka 36 kt, Caltech)$cm$,
   $cm$Azerbaijan's paper sector is Azersun Holding at Sumgayit: a recycled paper and board plant (2014, 50 kt/yr waste-paper input) and a tissue factory (Sun, Aura), with expansion announced in 2026-09. New converters opened in 2026: Baku Cardboard and Box (55 m m2) and Fabriora (hygiene products). GCC: Azeka BM (36 kt planned, Sumgait), Caltech (Agdam, micronised and coated), Fortis Group calcite powder (paper named). No paper PCC.$cm$,
   $cm${"fillers": "Planned GCC: Azeka BM (36 kt), Caltech (micronised and coated calcite). Calcite powder: Fortis Group (97.5 pct carbonates, paper named). No PCC.", "mills": "Azersun Paper and Cardboard Plant (Sumgayit), Azersun Tissue Paper Factory (Sumgayit). Context: Baku Cardboard and Box, Fabriora Group, Azersun Khirdalan Cardboard.", "strategy": "Azersun first - recycled liner strength trial and tissue, pitch the 2026 expansion. Azeka BM as local GCC partner if running.", "risks": "Machine specs and output not public, GCC plants unconfirmed.", "next_steps": ["Ask Azersun for machine specs and filler use", "Confirm Azeka BM operation"], "key_numbers": [{"label": "Azersun recycling plant", "value": "50 kt/yr waste paper (2014)"}, {"label": "Azeka BM", "value": "36 kt/yr GCC (planned)"}], "files": ["seed_20261016y_azerbaijan_mills_fillers"]}$cm$::jsonb,
   $cm$Sumgayit 의 Azersun 재생 종이·판지(폐지 5만 t)·티슈 — 계획 GCC 공장(Azeka 3.6만 t, Caltech)$cm$,
   $cm$아제르바이잔 제지산업은 Sumgayit 의 Azersun Holding 중심: 재생 종이·판지 공장(2014, 폐지 연 5만 t 투입)과 티슈 공장(Sun·Aura), 2026-09 증설 발표. 2026 신규 가공공장: Baku Cardboard(5,500만 m²)·Fabriora. GCC: Azeka BM(3.6만 t 계획), Caltech(Agdam), Fortis Group(제지 명시). 제지용 PCC 없음.$cm$,
   500, 1500,
   $cm$Azersun 원지 5만 t 가정 × FCC 1~3% (폐지 투입량 기준 가정, 실제 생산량 미공개)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('ka[gğ][iı]z v[eə] karton|paper and cardboard (production|plant)|akk[iı]k', 'sumqay|sumgay', 'ka[gğ][iı]z|paper and cardboard|akk[iı]k'),
  ('azersun.*(tissue|gigiyen)|qafqaz ka[gğ][iı]z', 'sumqay|sumgay', 'tissue|gigiyen|qafqaz'),
  ('bak[iı] karton|baku cardboard', null, 'bak[iı] karton|baku cardboard'),
  ('fabriora', null, 'fabriora'),
  ('x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan', null, 'x[iı]rdalan.*(karton|cardboard)|azersun.*khirdalan')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'azerbaijan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'azerbaijan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'azeka' or p.party_name ~* 'caltech' or p.party_name ~* 'fortis group')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    