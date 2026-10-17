-- ============================================================
-- seed_20261016zzj_czechia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Czechia update (reports 2026-10-16). Fixed generator.
-- Two Mondi rows in Štětí: White Paper (PS7) and the kraft site - the kraft
-- guard excludes "white" and has no city fallback so they stay apart.
-- 1) Fillers if missing (6): Omya Czechia, LB Cemix Kotouč, Lhoist Čertovy
--    schody, Carmeuse Mokrá, Vitošov, Vitoul.
-- 2) Mills if missing (7) + plant blocks, priority 1-7: Mondi Štětí White
--    Paper, OP papírna, KRPA PAPER, Mondi Štětí, Huhtamaki, EMBA, Morava
--    Paper. Context (2): Lenzing Biocel, JIP Větřní (closed).
-- 3) app.country_markets CZ row (priority medium).
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
           v.party_name, 'CZ', v.region, v.city, v.website, 'active', 'czechia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(czech|lipov)', 'Omya Czechia - Lipová-lázně', 'Olomouc', 'Lipová-lázně', null, 'Omya Specialty Materials (Czechia) s.r.o.(790 61 Lipová-lázně) — 제지용 GCC·PCC 공급·기술지원.', 'Omya Specialty Materials (Czechia) s.r.o., 790 61 Lipová-lázně (Jeseník) - paper GCC and PCC supply and technical service.', 'CZ check 2026-10-16: local paper-grade production not confirmed. Royalty licensee at Omya HQ level - FiberLean competes with FCC.'),
  ('cemix|kotou[cč]', 'LB Cemix - Kotouč Štramberk', 'Moravian-Silesian', 'Štramberk', null, 'LB Cemix Kotouč Štramberk(Libotín 500) — 분쇄·괴상 석회석, 생석회·소석회, 제지산업 공급 명시.', 'LB Cemix, Kotouč Štramberk plant, Libotín 500, Štramberk - ground and lump limestone, quicklime and hydrated lime, paper industry named among customers.', 'CZ check 2026-10-16: fine grinding and slurry for paper to confirm. obchod.kotouc@cemix.cz, +420 556 873 504. Local GCC-based FCC partner candidate.'),
  ('[cč]ertovy schody|lhoist.*(czech|tma[nň])', 'Lhoist - Vápenka Čertovy schody (Tmaň)', 'Central Bohemia', 'Tmaň', null, 'Lhoist 계열 Vápenka Čertovy schody(Tmaň 200) — 체코 최대 석회·석회석 생산.', 'Vápenka Čertovy schody a.s. (Lhoist group since the early 1990s), Tmaň 200 - largest Czech lime and limestone producer.', 'CZ check 2026-10-16: PCC raw material only.'),
  ('carmeuse.*(czech|mokr)', 'Carmeuse Czech Republic - Mokrá', 'South Moravian', 'Mokrá', null, 'Carmeuse Czech Vápenka Mokrá(Mokrá 359) 석회·석회석.', 'Carmeuse Czech Republic s.r.o., Vápenka Mokrá, Mokrá 359 - lime and limestone products.', 'CZ check 2026-10-16: paper-fine GCC not confirmed.'),
  ('vito[sš]ov', 'Vápenka Vitošov - Hrabová', 'Olomouc', 'Hrabová', null, 'Vápenka Vitošov(Hrabová 54, SigmaRoc 2024~) 분쇄 석회석·생석회·소석회.', 'Vápenka Vitošov s.r.o. (SigmaRoc since 2024), Hrabová 54 - ground limestone, quicklime, hydrated lime, one of the three largest Czech lime makers.', 'CZ check 2026-10-16: technical head Petr Hrbek, petr.hrbek@vapenka-vitosov.cz.'),
  ('vitoul', 'Vápenka Vitoul - Mladeč', 'Olomouc', 'Mladeč', null, 'Vápenka Vitoul(Mladeč 132) 자체 광산·미분쇄 석회석(40 μm 체 관리).', 'Vápenka Vitoul, Mladeč 132 - own quarry, micronised limestone (40 micron sieve control) and industrial carbonate.', 'CZ check 2026-10-16: not paper fineness (1-3 micron). odbyt@vitoul.cz. Not added: Hasit Šumavské vápenice. No Czech paper PCC satellite identified.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(czech|lipov)', 'Omya Czechia - Lipová-lázně', 'Olomouc', 'Lipová-lázně', null, 'Omya Specialty Materials (Czechia) s.r.o.(790 61 Lipová-lázně) — 제지용 GCC·PCC 공급·기술지원.', 'Omya Specialty Materials (Czechia) s.r.o., 790 61 Lipová-lázně (Jeseník) - paper GCC and PCC supply and technical service.', 'CZ check 2026-10-16: local paper-grade production not confirmed. Royalty licensee at Omya HQ level - FiberLean competes with FCC.'),
  ('cemix|kotou[cč]', 'LB Cemix - Kotouč Štramberk', 'Moravian-Silesian', 'Štramberk', null, 'LB Cemix Kotouč Štramberk(Libotín 500) — 분쇄·괴상 석회석, 생석회·소석회, 제지산업 공급 명시.', 'LB Cemix, Kotouč Štramberk plant, Libotín 500, Štramberk - ground and lump limestone, quicklime and hydrated lime, paper industry named among customers.', 'CZ check 2026-10-16: fine grinding and slurry for paper to confirm. obchod.kotouc@cemix.cz, +420 556 873 504. Local GCC-based FCC partner candidate.'),
  ('[cč]ertovy schody|lhoist.*(czech|tma[nň])', 'Lhoist - Vápenka Čertovy schody (Tmaň)', 'Central Bohemia', 'Tmaň', null, 'Lhoist 계열 Vápenka Čertovy schody(Tmaň 200) — 체코 최대 석회·석회석 생산.', 'Vápenka Čertovy schody a.s. (Lhoist group since the early 1990s), Tmaň 200 - largest Czech lime and limestone producer.', 'CZ check 2026-10-16: PCC raw material only.'),
  ('carmeuse.*(czech|mokr)', 'Carmeuse Czech Republic - Mokrá', 'South Moravian', 'Mokrá', null, 'Carmeuse Czech Vápenka Mokrá(Mokrá 359) 석회·석회석.', 'Carmeuse Czech Republic s.r.o., Vápenka Mokrá, Mokrá 359 - lime and limestone products.', 'CZ check 2026-10-16: paper-fine GCC not confirmed.'),
  ('vito[sš]ov', 'Vápenka Vitošov - Hrabová', 'Olomouc', 'Hrabová', null, 'Vápenka Vitošov(Hrabová 54, SigmaRoc 2024~) 분쇄 석회석·생석회·소석회.', 'Vápenka Vitošov s.r.o. (SigmaRoc since 2024), Hrabová 54 - ground limestone, quicklime, hydrated lime, one of the three largest Czech lime makers.', 'CZ check 2026-10-16: technical head Petr Hrbek, petr.hrbek@vapenka-vitosov.cz.'),
  ('vitoul', 'Vápenka Vitoul - Mladeč', 'Olomouc', 'Mladeč', null, 'Vápenka Vitoul(Mladeč 132) 자체 광산·미분쇄 석회석(40 μm 체 관리).', 'Vápenka Vitoul, Mladeč 132 - own quarry, micronised limestone (40 micron sieve control) and industrial carbonate.', 'CZ check 2026-10-16: not paper fineness (1-3 micron). odbyt@vitoul.cz. Not added: Hasit Šumavské vápenice. No Czech paper PCC satellite identified.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'czechia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Czechia - Lipová-lázně', 'GCC and PCC supplier', 'Omya Czechia - licensee group', 'merchant', 'C', 'gcc'),
  ('LB Cemix - Kotouč Štramberk', 'GCC and lime producer', 'Ground limestone, paper named - local partner', 'merchant', 'C', 'gcc'),
  ('Lhoist - Vápenka Čertovy schody (Tmaň)', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Carmeuse Czech Republic - Mokrá', 'Lime producer', 'Lime and limestone - raw material', 'merchant', 'C', 'pcc'),
  ('Vápenka Vitošov - Hrabová', 'Lime producer', 'Limestone and lime - raw material', 'merchant', 'C', 'pcc'),
  ('Vápenka Vitoul - Mladeč', 'GCC producer', 'Micronised limestone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'czechia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CZ', v.region, v.city, v.website, 'active', 'czechia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('white paper|\mps7\M', '[sš]t[eě]t[ií]', 'white paper', 'Mondi Štětí White Paper', 'Ústí nad Labem', 'Štětí', null, 'Mondi Štětí White Paper s.r.o.(Litoměřická 250) — PS7 백색 제지 운영자(2026 환경허가).', 'Mondi Štětí White Paper s.r.o., Litoměřická 250, Štětí - operator of the PS7 white-paper machine (2026 IPPC records).', 'CZ check 2026-10-16: grade, filler use and capacity to confirm.'),
  ('op pap[ií]rna|ol[sš]any', 'ol[sš]any', 'delfort|op pap', 'OP papírna (delfort) - Olšany', 'Olomouc', 'Olšany', null, 'delfort 계열 OP papírna(Olšany 18) — 초지기 3대, 약 500명, 박엽 인쇄용지·의약품 설명서용지·담배 특수지, 수출 95%+.', 'OP papírna s.r.o. (delfort group), Olšany 18 - three paper machines, about 500 staff, lightweight printing, pharma leaflet and tobacco specialty papers, over 95 pct exported.', 'CZ check 2026-10-16: oppapirna@delfortgroup.com, +420 583 384 501.'),
  ('krpa', 'hostinn[eé]', 'krpa', 'KRPA PAPER - Hostinné', 'Hradec Králové', 'Hostinné', null, 'KRPA PAPER(Hostinné, KRPA Holding) — 내유지·식품포장·배리어·실리콘 코팅지.', 'KRPA PAPER a.s. (KRPA Holding), Hostinné - greaseproof, food packaging, barrier and silicone-coated papers.', 'CZ check 2026-10-16: filler vs barrier coating to be tested separately.'),
  ('^(?!.*white).*mondi.*[sš]t[eě]t[ií]', null, 'mondi', 'Mondi Štětí', 'Ústí nad Labem', 'Štětí', null, 'Mondi Štětí(Litoměřická 272) 체코 최대 펄프·제지 — 초지기 6대, 펄프 2라인, 색크라프트·특수 크라프트. 2024-12 PM10 21만 t(4억 유로).', 'Mondi Štětí, Litoměřická 272, Štětí - largest Czech pulp and paper mill, six paper machines and two pulp lines, sack kraft and specialty kraft. PM10 started 2024-12 (about 210,000 t/yr, EUR 400 m).', 'CZ check 2026-10-16: strength-critical kraft - PM10 figure is not the site total. +420 416 801 111.'),
  ('huhtamaki', 'p[rř]ibyslavice', 'huhtamaki', 'Huhtamaki Czech Republic - Přibyslavice', 'Vysočina', 'Přibyslavice', null, 'Huhtamaki Přibyslavice(Petrovická 101) 몰드펄프 계란판·트레이·과채 포장, 22개국.', 'Huhtamaki Czech Republic, Petrovická 101, Přibyslavice - moulded-fibre egg boxes, trays and fruit packaging, sold to 22 countries.', 'CZ check 2026-10-16: moulded fibre - drainage, forming, drying tests.'),
  ('\memba\M', 'paseky', 'emba', 'EMBA - Paseky nad Jizerou', 'Liberec', 'Paseky nad Jizerou', null, 'EMBA(1882~) 재생 판지·기록보존 판지·파일보드.', 'EMBA spol. s r.o., Paseky nad Jizerou (since 1882) - recycled board, archival board and file board.', 'CZ check 2026-10-16: archival grades need pH and stability checks.'),
  ('morava paper|[zž]imrovice', '[zž]imrovice', 'smurfit|morava', 'Smurfit Westrock Morava Paper - Žimrovice', 'Moravian-Silesian', 'Žimrovice', null, 'Smurfit Westrock 계열 Morava Paper(Žimrovice) 판지·포장재.', 'Morava Paper (Smurfit Westrock Czech), Žimrovice - board and packaging.', 'CZ check 2026-10-16: base-paper line to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('white paper|\mps7\M', '[sš]t[eě]t[ií]', 'white paper', 'Mondi Štětí White Paper s.r.o.(Litoměřická 250) — PS7 백색 제지 운영자(2026 환경허가).', 'Mondi Štětí White Paper s.r.o., Litoměřická 250, Štětí - operator of the PS7 white-paper machine (2026 IPPC records).', 'CZ check 2026-10-16: grade, filler use and capacity to confirm.'),
  ('op pap[ií]rna|ol[sš]any', 'ol[sš]any', 'delfort|op pap', 'delfort 계열 OP papírna(Olšany 18) — 초지기 3대, 약 500명, 박엽 인쇄용지·의약품 설명서용지·담배 특수지, 수출 95%+.', 'OP papírna s.r.o. (delfort group), Olšany 18 - three paper machines, about 500 staff, lightweight printing, pharma leaflet and tobacco specialty papers, over 95 pct exported.', 'CZ check 2026-10-16: oppapirna@delfortgroup.com, +420 583 384 501.'),
  ('krpa', 'hostinn[eé]', 'krpa', 'KRPA PAPER(Hostinné, KRPA Holding) — 내유지·식품포장·배리어·실리콘 코팅지.', 'KRPA PAPER a.s. (KRPA Holding), Hostinné - greaseproof, food packaging, barrier and silicone-coated papers.', 'CZ check 2026-10-16: filler vs barrier coating to be tested separately.'),
  ('^(?!.*white).*mondi.*[sš]t[eě]t[ií]', null, 'mondi', 'Mondi Štětí(Litoměřická 272) 체코 최대 펄프·제지 — 초지기 6대, 펄프 2라인, 색크라프트·특수 크라프트. 2024-12 PM10 21만 t(4억 유로).', 'Mondi Štětí, Litoměřická 272, Štětí - largest Czech pulp and paper mill, six paper machines and two pulp lines, sack kraft and specialty kraft. PM10 started 2024-12 (about 210,000 t/yr, EUR 400 m).', 'CZ check 2026-10-16: strength-critical kraft - PM10 figure is not the site total. +420 416 801 111.'),
  ('huhtamaki', 'p[rř]ibyslavice', 'huhtamaki', 'Huhtamaki Přibyslavice(Petrovická 101) 몰드펄프 계란판·트레이·과채 포장, 22개국.', 'Huhtamaki Czech Republic, Petrovická 101, Přibyslavice - moulded-fibre egg boxes, trays and fruit packaging, sold to 22 countries.', 'CZ check 2026-10-16: moulded fibre - drainage, forming, drying tests.'),
  ('\memba\M', 'paseky', 'emba', 'EMBA(1882~) 재생 판지·기록보존 판지·파일보드.', 'EMBA spol. s r.o., Paseky nad Jizerou (since 1882) - recycled board, archival board and file board.', 'CZ check 2026-10-16: archival grades need pH and stability checks.'),
  ('morava paper|[zž]imrovice', '[zž]imrovice', 'smurfit|morava', 'Smurfit Westrock 계열 Morava Paper(Žimrovice) 판지·포장재.', 'Morava Paper (Smurfit Westrock Czech), Žimrovice - board and packaging.', 'CZ check 2026-10-16: base-paper line to confirm.'),
  ('lenzing.*paskov|biocel', null, 'lenzing.*paskov|biocel', null, null, 'CZ check 2026-10-16: Biocel Paskov dissolving pulp - context only.'),
  ('v[eě]t[rř]n[ií]|\mjip\M', null, 'v[eě]t[rř]n[ií]|\mjip\M', null, null, 'CZ check 2026-10-16: Packaging paper mill - PM4 and PM6 stopped 2025-09-30 - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'czechia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('white paper|\mps7\M', '[sš]t[eě]t[ií]', 'white paper'),
  ('op pap[ií]rna|ol[sš]any', 'ol[sš]any', 'delfort|op pap'),
  ('krpa', 'hostinn[eé]', 'krpa'),
  ('^(?!.*white).*mondi.*[sš]t[eě]t[ií]', null, 'mondi'),
  ('huhtamaki', 'p[rř]ibyslavice', 'huhtamaki'),
  ('\memba\M', 'paseky', 'emba'),
  ('morava paper|[zž]imrovice', '[zž]imrovice', 'smurfit|morava'),
  ('lenzing.*paskov|biocel', null, 'lenzing.*paskov|biocel'),
  ('v[eě]t[rř]n[ií]|\mjip\M', null, 'v[eě]t[rř]n[ií]|\mjip\M')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('white paper|\mps7\M', '[sš]t[eě]t[ií]', 'white paper', false,
   $pj${"owner": "Mondi", "priority": 1, "products": "White paper (PS7)", "grades": ["UWF"], "approach": "Confirm grade - then UWF filler trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('op pap[ií]rna|ol[sš]any', 'ol[sš]any', 'delfort|op pap', false,
   $pj${"owner": "delfort", "priority": 2, "products": "Lightweight printing, leaflet, tobacco papers", "grades": ["Specialty paper"], "machines": 3, "approach": "delfort group trial (Traun AT, Tervakoski FI).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('krpa', 'hostinn[eé]', 'krpa', false,
   $pj${"owner": "KRPA Holding", "priority": 3, "products": "Greaseproof, barrier and food packaging papers", "grades": ["Specialty paper"], "approach": "Functional packaging co-development.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('^(?!.*white).*mondi.*[sš]t[eě]t[ií]', null, 'mondi', false,
   $pj${"owner": "Mondi", "priority": 4, "products": "Sack and specialty kraft", "grades": ["Sack kraft"], "capacity_split": [{"label": "PM10 (2024-12)", "value_t": 210000}], "approach": "Strength-hold trial only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('huhtamaki', 'p[rř]ibyslavice', 'huhtamaki', false,
   $pj${"owner": "Huhtamaki", "priority": 5, "products": "Moulded-fibre packaging", "grades": ["Moulded fibre"], "approach": "New moulded-fibre application.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\memba\M', 'paseky', 'emba', false,
   $pj${"owner": "EMBA", "priority": 6, "products": "Recycled and archival board", "grades": ["Board"], "approach": "Raw-material saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('morava paper|[zž]imrovice', '[zž]imrovice', 'smurfit|morava', false,
   $pj${"owner": "Smurfit Westrock", "priority": 7, "products": "Board, packaging", "grades": ["Board"], "approach": "Confirm line.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lenzing.*paskov|biocel', null, 'lenzing.*paskov|biocel', true,
   $pj${"owner": "Lenzing", "products": "Biocel Paskov dissolving pulp", "approach": "Pulp or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('v[eě]t[rř]n[ií]|\mjip\M', null, 'v[eě]t[rř]n[ií]|\mjip\M', true,
   $pj${"owner": "JIP Papírny Větřní", "products": "Packaging paper mill - PM4 and PM6 stopped 2025-09-30", "approach": "Pulp or closed.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CZ', 'Czechia', 'medium',
   $cm$Mondi Štětí (kraft, PM10 210 kt) and Štětí White Paper PS7, OP papírna and KRPA specialty - Omya Czechia, LB Cemix ground limestone - JIP Větřní closed$cm$,
   $cm$Czech FCC-fit mills: Mondi Štětí White Paper (PS7 white paper - grade to confirm), OP papírna Olšany (delfort, three machines, lightweight and tobacco papers), KRPA PAPER Hostinné (greaseproof and barrier), plus Huhtamaki moulded fibre, EMBA recycled board and Morava Paper. Mondi Štětí main site makes sack and specialty kraft (six machines, new PM10 210 kt). JIP Papírny Větřní stopped 2025-09. Fillers: Omya Czechia (Lipová-lázně, local production unconfirmed), LB Cemix Kotouč (ground limestone, paper named), lime at Lhoist Čertovy schody, Carmeuse Mokrá, Vitošov, Vitoul. No Czech paper PCC satellite identified.$cm$,
   $cm${"fillers": "GCC and PCC sales: Omya Czechia. Ground limestone: LB Cemix Kotouč, Vitoul. Lime: Lhoist Čertovy schody, Carmeuse Mokrá, Vitošov.", "mills": "White and specialty: Mondi Štětí White Paper, OP papírna, KRPA PAPER. Kraft: Mondi Štětí. Other: Huhtamaki, EMBA, Morava Paper. Context: Lenzing Biocel, JIP Větřní (closed).", "strategy": "Confirm PS7 grade, delfort group trial (OP papírna with Traun and Tervakoski), KRPA functional packaging, LB Cemix for a local GCC-based line.", "risks": "Kraft-heavy output, unknown filler supply.", "next_steps": ["Ask Mondi Štětí White Paper for PS7 grade and filler use"], "key_numbers": [{"label": "Mondi Štětí PM10", "value": "210 kt (2024-12)"}, {"label": "OP papírna", "value": "3 machines, 95 pct exported"}], "files": ["seed_20261016zzj_czechia_mills_fillers"]}$cm$::jsonb,
   $cm$Mondi Štětí(크라프트, PM10 21만 t)·Štětí White Paper PS7, OP papírna·KRPA 특수지 — Omya Czechia, LB Cemix 분쇄 석회석 — JIP Větřní 중단$cm$,
   $cm$체코 FCC 적합: Mondi Štětí White Paper(PS7 백색지, 지종 확인 필요), OP papírna Olšany(delfort, 3대, 박엽·담배지), KRPA Hostinné(내유·배리어), Huhtamaki 몰드펄프, EMBA, Morava Paper. Mondi Štětí 본 공장은 색크라프트·특수 크라프트(6대, PM10 21만 t). JIP Větřní 2025-09 중단. 충전제: Omya Czechia(현지 생산 미확인), LB Cemix Kotouč(제지 명시), 석회 Lhoist·Carmeuse·Vitošov·Vitoul. 제지용 PCC 위성공장 미확인.$cm$,
   null, null,
   $cm$공장별 생산량·지종 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('white paper|\mps7\M', '[sš]t[eě]t[ií]', 'white paper'),
  ('op pap[ií]rna|ol[sš]any', 'ol[sš]any', 'delfort|op pap'),
  ('krpa', 'hostinn[eé]', 'krpa'),
  ('^(?!.*white).*mondi.*[sš]t[eě]t[ií]', null, 'mondi'),
  ('huhtamaki', 'p[rř]ibyslavice', 'huhtamaki'),
  ('\memba\M', 'paseky', 'emba'),
  ('morava paper|[zž]imrovice', '[zž]imrovice', 'smurfit|morava'),
  ('lenzing.*paskov|biocel', null, 'lenzing.*paskov|biocel'),
  ('v[eě]t[rř]n[ií]|\mjip\M', null, 'v[eě]t[rř]n[ií]|\mjip\M')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'czechia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'czechia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(czech|lipov)' or p.party_name ~* 'cemix|kotou[cč]' or p.party_name ~* '[cč]ertovy schody|lhoist.*(czech|tma[nň])' or p.party_name ~* 'carmeuse.*(czech|mokr)' or p.party_name ~* 'vito[sš]ov' or p.party_name ~* 'vitoul')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    