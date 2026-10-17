-- ============================================================
-- seed_20261016zzg_austria_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Austria update (reports 2026-10-16). Fixed generator.
-- CALMIT name avoids "CALPREC" so the Spanish Calmit Llierca guard does not hit it.
-- 1) Fillers if missing (4): Omya Austria Gummern, Omya Hausmening satellite
--    PCC, CALMIT Bad Ischl, Shiraishi-Omya.
-- 2) Mills if missing (11) + plant blocks, priority 1-8: Mondi Neusiedler,
--    Sappi Gratkorn, Essity Ortmann, Brigl and Bergmeister, Lenzing Papier,
--    Norske Skog Bruck, MM Frohnleiten, delfort Traun. No priority: Papierfabrik
--    Wattens, Heinzel Steyrermühl, Hamburger Pitten. Context (7).
-- 3) Supply links (2): Omya -> Mondi Hausmening (active, to confirm),
--    SCHAEFER KALK -> Papierfabrik Wattens (historical).
-- 4) app.country_markets AT row (priority high).
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
           v.party_name, 'AT', v.region, v.city, v.website, 'active', 'austria_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(austria|[oö]sterreich|gummern)', 'Omya Austria - Gummern', 'Carinthia', 'Gummern', null, 'Omya GmbH 오스트리아 — Gummern(Gersheim Str. 1-2) 석회석·대리석 채굴·분쇄 GCC, Golling(Taggerstr. 273) 탄산칼슘·PCC(2000년대 초 약 8만 t, Unikristall), Hausmening 위성 PCC.', 'Omya GmbH (Austria) - Gummern, Gersheim Straße 1-2 (Carinthia): limestone and marble quarrying and ground calcium carbonate for paper, plastics, paint, building. Golling an der Salzach, Taggerstraße 273: carbonate fillers and PCC (about 80,000 t/yr in the early 2000s, Unikristall slurry). Satellite PCC at Hausmening (separate row).', 'AT check 2026-10-16: current paper grades and capacities to confirm. +43 4258 8550, Gummern contact thomas.mangelberger@omya.com. Royalty licensee at Omya HQ level.'),
  ('omya.*hausmening', 'Omya - Hausmening (satellite PCC)', 'Lower Austria', 'Hausmening', null, 'Omya Hausmening 위성 PCC — Mondi Neusiedler 연계(Theresientalstr. 50), 2001 가동, 2005 약 4.2만 t.', 'Omya satellite PCC at Hausmening (Theresientalstraße 50) for Mondi Neusiedler, started 2001, about 42,000 t/yr in 2005, address still on Omya site lists.', 'AT check 2026-10-16: current running status to confirm.'),
  ('calmit.*(bad ischl|austria|gmbh)', 'CALMIT - Bad Ischl (PCC)', 'Upper Austria', 'Bad Ischl', null, 'CALMIT Bad Ischl PCC(CALPREC)·생석회·소석회·석회석 분말 — Starnkogel 채석장 석회석 98%, 제지 용도 명시, 2026-01 2,500만 유로 신규 설비.', 'CALMIT GmbH, Bad Ischl (Upper Austria) - PCC (CALPREC), quicklime, hydrated lime and limestone powders of about 98 pct limestone of the nearby Starnkogel quarry, paper named among uses, EUR 25 m new production plant (2026-01), European supply.', 'AT check 2026-10-16: PCC capacity and satellites not public. Same CALPREC brand as Calmit Llierca (ES) - check group link. Independent PCC maker - FCC licence candidate.'),
  ('shiraishi.?omya', 'Shiraishi-Omya - Golling', 'Salzburg', 'Golling an der Salzach', null, 'Shiraishi·Omya 합작 Golling 초미립 PCC Hakuenka®(100 nm 미만, 건조·표면처리) — 접착제·실란트·잉크·플라스틱.', 'Shiraishi-Omya GmbH (Shiraishi and Omya JV), Golling - ultrafine PCC Hakuenka (under 100 nm, dry and coated) mainly for adhesives and sealants, also inks and plastics.', 'AT check 2026-10-16: not a paper filler product.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(austria|[oö]sterreich|gummern)', 'Omya Austria - Gummern', 'Carinthia', 'Gummern', null, 'Omya GmbH 오스트리아 — Gummern(Gersheim Str. 1-2) 석회석·대리석 채굴·분쇄 GCC, Golling(Taggerstr. 273) 탄산칼슘·PCC(2000년대 초 약 8만 t, Unikristall), Hausmening 위성 PCC.', 'Omya GmbH (Austria) - Gummern, Gersheim Straße 1-2 (Carinthia): limestone and marble quarrying and ground calcium carbonate for paper, plastics, paint, building. Golling an der Salzach, Taggerstraße 273: carbonate fillers and PCC (about 80,000 t/yr in the early 2000s, Unikristall slurry). Satellite PCC at Hausmening (separate row).', 'AT check 2026-10-16: current paper grades and capacities to confirm. +43 4258 8550, Gummern contact thomas.mangelberger@omya.com. Royalty licensee at Omya HQ level.'),
  ('omya.*hausmening', 'Omya - Hausmening (satellite PCC)', 'Lower Austria', 'Hausmening', null, 'Omya Hausmening 위성 PCC — Mondi Neusiedler 연계(Theresientalstr. 50), 2001 가동, 2005 약 4.2만 t.', 'Omya satellite PCC at Hausmening (Theresientalstraße 50) for Mondi Neusiedler, started 2001, about 42,000 t/yr in 2005, address still on Omya site lists.', 'AT check 2026-10-16: current running status to confirm.'),
  ('calmit.*(bad ischl|austria|gmbh)', 'CALMIT - Bad Ischl (PCC)', 'Upper Austria', 'Bad Ischl', null, 'CALMIT Bad Ischl PCC(CALPREC)·생석회·소석회·석회석 분말 — Starnkogel 채석장 석회석 98%, 제지 용도 명시, 2026-01 2,500만 유로 신규 설비.', 'CALMIT GmbH, Bad Ischl (Upper Austria) - PCC (CALPREC), quicklime, hydrated lime and limestone powders of about 98 pct limestone of the nearby Starnkogel quarry, paper named among uses, EUR 25 m new production plant (2026-01), European supply.', 'AT check 2026-10-16: PCC capacity and satellites not public. Same CALPREC brand as Calmit Llierca (ES) - check group link. Independent PCC maker - FCC licence candidate.'),
  ('shiraishi.?omya', 'Shiraishi-Omya - Golling', 'Salzburg', 'Golling an der Salzach', null, 'Shiraishi·Omya 합작 Golling 초미립 PCC Hakuenka®(100 nm 미만, 건조·표면처리) — 접착제·실란트·잉크·플라스틱.', 'Shiraishi-Omya GmbH (Shiraishi and Omya JV), Golling - ultrafine PCC Hakuenka (under 100 nm, dry and coated) mainly for adhesives and sealants, also inks and plastics.', 'AT check 2026-10-16: not a paper filler product.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'austria_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Austria - Gummern', 'GCC and PCC supplier', 'Omya Austria - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Omya - Hausmening (satellite PCC)', 'PCC producer', 'Omya satellite PCC at Mondi Hausmening - licensee group', 'satellite', 'B', 'pcc'),
  ('CALMIT - Bad Ischl (PCC)', 'PCC producer', 'Independent PCC maker - licence candidate', 'merchant', 'B', 'pcc'),
  ('Shiraishi-Omya - Golling', 'PCC producer', 'Nano PCC (adhesives) - not paper', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'austria_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'AT', v.region, v.city, v.website, 'active', 'austria_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler', 'Mondi Neusiedler - Hausmening', 'Lower Austria', 'Hausmening', null, 'Mondi Neusiedler — Hausmening·Kematen 2개 공장 초지기 3대, 비도공 인쇄·필기·사무용지, 최근 협회 자료 연 18만 t(과거 33만 t). Omya 위성 PCC 연계.', 'Mondi Neusiedler, Theresienthalstraße 50, Ulmerfeld-Hausmening (plus Kematen) - uncoated fine, office and printing papers on three machines across two mills, 180,000 t/yr in the latest Austropapier data (330,000 t in older figures). Omya satellite PCC on site.', 'AT check 2026-10-16: +43 7475 500 0.'),
  ('sappi.*gratkorn|gratkorn', 'gratkorn', 'sappi', 'Sappi Gratkorn', 'Styria', 'Gratkorn', null, 'Sappi Gratkorn(Brucker Str. 21) 코팅 고급 인쇄용지·라벨지 연 91만 t(PM9·PM11), TCF 아황산펄프 25만 t 별도.', 'Sappi Austria, Brucker Straße 21, Gratkorn - coated fine paper and label paper on PM9 and PM11, 910,000 t/yr paper (TCF sulphite pulp 250,000 t/yr, not added).', 'AT check 2026-10-16: base-paper filler first, coating pigment separately. gratkorn.mill@sappi.com, +43 3124 201 0.'),
  ('essity.*(ortmann|pernitz)|ortmann', 'pernitz|ortmann', 'essity', 'Essity Ortmann - Pernitz', 'Lower Austria', 'Pernitz', null, 'Essity Austria Ortmann(Hauptstr. 1, Pernitz) 티슈·위생용지 연 13만 t(PM4·PM9).', 'Essity Austria, Ortmann mill, Hauptstraße 1, Pernitz - tissue and hygiene paper, 130,000 t/yr on PM4 and PM9.', 'AT check 2026-10-16: welcome@essity.com.'),
  ('brigl|niklasdorf', 'niklasdorf', 'brigl', 'Brigl & Bergmeister - Niklasdorf', 'Styria', 'Niklasdorf', null, 'Brigl & Bergmeister Niklasdorf(Proleber Str. 10) 라벨 원지·특수 코팅지 — 슬로베니아 Vevče 와 같은 그룹.', 'Brigl and Bergmeister, Proleber Straße 10, Niklasdorf - label base and specialty coated papers. Same group as Papirnica Vevče (SI).', 'AT check 2026-10-16: marketing@brigl-bergmeister.com, +43 3842 800 0.'),
  ('lenzing papier', 'lenzing', 'lenzing', 'Lenzing Papier - Lenzing', 'Upper Austria', 'Lenzing', null, 'Lenzing Papier 재생섬유 고급지.', 'Lenzing Papier, Lenzing - recycled-fibre fine papers.', 'AT check 2026-10-16: capacity not public here.'),
  ('norske skog.*bruck|\mbruck\M.*mur', 'bruck', 'norske skog', 'Norske Skog Bruck - Bruck an der Mur', 'Styria', 'Bruck an der Mur', null, 'Norske Skog Bruck(Fabriksgasse 10) LWC·골판지원지 연 47만 t(PM3·PM4), 목재펄프 10만 t 별도.', 'Norske Skog Bruck, Fabriksgasse 10, Bruck an der Mur - LWC and containerboard on PM3 and PM4, 470,000 t/yr (mechanical pulp 100,000 t, not added).', 'AT check 2026-10-16: LWC base filler first. bruck@norskeskog.com.'),
  ('frohnleiten|\mmm\M.*frohnl|mayr.*frohnl', 'frohnleiten', '\mmm\M|mayr', 'MM Frohnleiten', 'Styria', 'Frohnleiten', null, 'MM Board & Paper Frohnleiten(Wannersdorf 80) 재생·배리어 판지 연 59만 t(KM2·KM3).', 'MM Board and Paper, Wannersdorf 80, Frohnleiten - recycled and barrier cartonboard on KM2 and KM3, 590,000 t/yr (pulp 70,000 t, not added).', 'AT check 2026-10-16: frohnleiten@mm.group.'),
  ('delfort.*traun|feurstein', 'traun', 'delfort|feurstein', 'delfort (Dr. Franz Feurstein) - Traun', 'Upper Austria', 'Traun', null, 'delfort 본사 공장 Traun(Dr. Franz Feurstein) 특수지·기능성 원지.', 'delfort / Dr. Franz Feurstein, Traun - specialty and functional papers (group also Tervakoski FI, Wattens).', 'AT check 2026-10-16: capacity not public here.'),
  ('wattens', 'wattens', 'delfort|wattens', 'Papierfabrik Wattens (delfort) - Wattens', 'Tyrol', 'Wattens', null, 'delfort 계열 Papierfabrik Wattens 특수지 — 2003 SCHAEFER KALK 위성 PCC 기록.', 'Papierfabrik Wattens (delfort), Wattens (Tyrol) - specialty papers, host of a SCHAEFER KALK satellite PCC opened 2003 (2005 report).', 'AT check 2026-10-16: PCC status to confirm.'),
  ('steyrerm[uü]hl', 'steyrerm[uü]hl', 'heinzel|steyrerm', 'Heinzel Steyrermühl', 'Upper Austria', 'Steyrermühl', null, 'Heinzel 그룹(2024~) Steyrermühl 백색·갈색 크라프트지 PM6 연 약 15만 t(신문용지에서 전환).', 'Steyrermühl (Heinzel Group since 2024) - white and brown kraft paper on PM6, about 150,000 t/yr, formerly newsprint.', 'AT check 2026-10-16: strength-led.'),
  ('hamburger.*pitten|pitten', 'pitten', 'hamburger|prinzhorn', 'Hamburger Containerboard - Pitten', 'Lower Austria', 'Pitten', null, 'Prinzhorn 본거지 Hamburger Pitten Testliner·Fluting 연 약 45만 t.', 'Hamburger Containerboard Pitten (Prinzhorn home mill) - testliner and fluting, about 450,000 t/yr.', 'AT check 2026-10-16: strength-led.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler', 'Mondi Neusiedler — Hausmening·Kematen 2개 공장 초지기 3대, 비도공 인쇄·필기·사무용지, 최근 협회 자료 연 18만 t(과거 33만 t). Omya 위성 PCC 연계.', 'Mondi Neusiedler, Theresienthalstraße 50, Ulmerfeld-Hausmening (plus Kematen) - uncoated fine, office and printing papers on three machines across two mills, 180,000 t/yr in the latest Austropapier data (330,000 t in older figures). Omya satellite PCC on site.', 'AT check 2026-10-16: +43 7475 500 0.'),
  ('sappi.*gratkorn|gratkorn', 'gratkorn', 'sappi', 'Sappi Gratkorn(Brucker Str. 21) 코팅 고급 인쇄용지·라벨지 연 91만 t(PM9·PM11), TCF 아황산펄프 25만 t 별도.', 'Sappi Austria, Brucker Straße 21, Gratkorn - coated fine paper and label paper on PM9 and PM11, 910,000 t/yr paper (TCF sulphite pulp 250,000 t/yr, not added).', 'AT check 2026-10-16: base-paper filler first, coating pigment separately. gratkorn.mill@sappi.com, +43 3124 201 0.'),
  ('essity.*(ortmann|pernitz)|ortmann', 'pernitz|ortmann', 'essity', 'Essity Austria Ortmann(Hauptstr. 1, Pernitz) 티슈·위생용지 연 13만 t(PM4·PM9).', 'Essity Austria, Ortmann mill, Hauptstraße 1, Pernitz - tissue and hygiene paper, 130,000 t/yr on PM4 and PM9.', 'AT check 2026-10-16: welcome@essity.com.'),
  ('brigl|niklasdorf', 'niklasdorf', 'brigl', 'Brigl & Bergmeister Niklasdorf(Proleber Str. 10) 라벨 원지·특수 코팅지 — 슬로베니아 Vevče 와 같은 그룹.', 'Brigl and Bergmeister, Proleber Straße 10, Niklasdorf - label base and specialty coated papers. Same group as Papirnica Vevče (SI).', 'AT check 2026-10-16: marketing@brigl-bergmeister.com, +43 3842 800 0.'),
  ('lenzing papier', 'lenzing', 'lenzing', 'Lenzing Papier 재생섬유 고급지.', 'Lenzing Papier, Lenzing - recycled-fibre fine papers.', 'AT check 2026-10-16: capacity not public here.'),
  ('norske skog.*bruck|\mbruck\M.*mur', 'bruck', 'norske skog', 'Norske Skog Bruck(Fabriksgasse 10) LWC·골판지원지 연 47만 t(PM3·PM4), 목재펄프 10만 t 별도.', 'Norske Skog Bruck, Fabriksgasse 10, Bruck an der Mur - LWC and containerboard on PM3 and PM4, 470,000 t/yr (mechanical pulp 100,000 t, not added).', 'AT check 2026-10-16: LWC base filler first. bruck@norskeskog.com.'),
  ('frohnleiten|\mmm\M.*frohnl|mayr.*frohnl', 'frohnleiten', '\mmm\M|mayr', 'MM Board & Paper Frohnleiten(Wannersdorf 80) 재생·배리어 판지 연 59만 t(KM2·KM3).', 'MM Board and Paper, Wannersdorf 80, Frohnleiten - recycled and barrier cartonboard on KM2 and KM3, 590,000 t/yr (pulp 70,000 t, not added).', 'AT check 2026-10-16: frohnleiten@mm.group.'),
  ('delfort.*traun|feurstein', 'traun', 'delfort|feurstein', 'delfort 본사 공장 Traun(Dr. Franz Feurstein) 특수지·기능성 원지.', 'delfort / Dr. Franz Feurstein, Traun - specialty and functional papers (group also Tervakoski FI, Wattens).', 'AT check 2026-10-16: capacity not public here.'),
  ('wattens', 'wattens', 'delfort|wattens', 'delfort 계열 Papierfabrik Wattens 특수지 — 2003 SCHAEFER KALK 위성 PCC 기록.', 'Papierfabrik Wattens (delfort), Wattens (Tyrol) - specialty papers, host of a SCHAEFER KALK satellite PCC opened 2003 (2005 report).', 'AT check 2026-10-16: PCC status to confirm.'),
  ('steyrerm[uü]hl', 'steyrerm[uü]hl', 'heinzel|steyrerm', 'Heinzel 그룹(2024~) Steyrermühl 백색·갈색 크라프트지 PM6 연 약 15만 t(신문용지에서 전환).', 'Steyrermühl (Heinzel Group since 2024) - white and brown kraft paper on PM6, about 150,000 t/yr, formerly newsprint.', 'AT check 2026-10-16: strength-led.'),
  ('hamburger.*pitten|pitten', 'pitten', 'hamburger|prinzhorn', 'Prinzhorn 본거지 Hamburger Pitten Testliner·Fluting 연 약 45만 t.', 'Hamburger Containerboard Pitten (Prinzhorn home mill) - testliner and fluting, about 450,000 t/yr.', 'AT check 2026-10-16: strength-led.'),
  ('laakirchen', null, 'laakirchen', null, null, 'AT check 2026-10-16: Laakirchen recycled packaging paper PM10 and PM11 (former SC) - context only.'),
  ('salzer', null, 'salzer', null, null, 'AT check 2026-10-16: Technical and specialty paper, St. Pölten - context only.'),
  ('nettingsdorf', null, 'nettingsdorf', null, null, 'AT check 2026-10-16: Nettingsdorf kraftliner - context only.'),
  ('frantschach', null, 'frantschach', null, null, 'AT check 2026-10-16: Frantschach kraft paper and pulp - context only.'),
  ('zellstoff p[oö]ls|starkraft', null, 'zellstoff p[oö]ls|starkraft', null, null, 'AT check 2026-10-16: Pöls kraft pulp and Starkraft kraft paper - context only.'),
  ('rondo ganahl', null, 'rondo ganahl', null, null, 'AT check 2026-10-16: Recycled board and base paper, Frastanz - context only.'),
  ('merckens', null, 'merckens', null, null, 'AT check 2026-10-16: Board, Schwertberg - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'austria_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler'),
  ('sappi.*gratkorn|gratkorn', 'gratkorn', 'sappi'),
  ('essity.*(ortmann|pernitz)|ortmann', 'pernitz|ortmann', 'essity'),
  ('brigl|niklasdorf', 'niklasdorf', 'brigl'),
  ('lenzing papier', 'lenzing', 'lenzing'),
  ('norske skog.*bruck|\mbruck\M.*mur', 'bruck', 'norske skog'),
  ('frohnleiten|\mmm\M.*frohnl|mayr.*frohnl', 'frohnleiten', '\mmm\M|mayr'),
  ('delfort.*traun|feurstein', 'traun', 'delfort|feurstein'),
  ('wattens', 'wattens', 'delfort|wattens'),
  ('steyrerm[uü]hl', 'steyrerm[uü]hl', 'heinzel|steyrerm'),
  ('hamburger.*pitten|pitten', 'pitten', 'hamburger|prinzhorn'),
  ('laakirchen', null, 'laakirchen'),
  ('salzer', null, 'salzer'),
  ('nettingsdorf', null, 'nettingsdorf'),
  ('frantschach', null, 'frantschach'),
  ('zellstoff p[oö]ls|starkraft', null, 'zellstoff p[oö]ls|starkraft'),
  ('rondo ganahl', null, 'rondo ganahl'),
  ('merckens', null, 'merckens')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler', false,
   $pj${"owner": "Mondi", "priority": 1, "products": "Uncoated fine and office paper", "grades": ["UWF", "Copy paper"], "machines": 3, "capacity": {"value": 180000, "unit": "metric_t", "year": "Austropapier latest", "source": "austropapier.at"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "UWF filler range."}, "pitch": "Mondi + Omya Hausmening + MBG three-way trial", "approach": "Lead Austrian account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*gratkorn|gratkorn', 'gratkorn', 'sappi', false,
   $pj${"owner": "Sappi", "priority": 2, "products": "Coated fine paper, label paper", "grades": ["Coated paper", "Label paper"], "machines": 2, "capacity": {"value": 910000, "unit": "metric_t", "year": "Austropapier", "source": "austropapier.at"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Base paper only."}, "approach": "Base-paper trial - Sappi group link (Alfeld DE, Maastricht NL).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*(ortmann|pernitz)|ortmann', 'pernitz|ortmann', 'essity', false,
   $pj${"owner": "Essity", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 130000, "unit": "metric_t", "year": "Austropapier", "source": "austropapier.at"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Essity R&D path (Mannheim, Kunheim).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('brigl|niklasdorf', 'niklasdorf', 'brigl', false,
   $pj${"owner": "Brigl and Bergmeister", "priority": 4, "products": "Label base, specialty coated paper", "grades": ["Label paper", "Specialty paper"], "approach": "Label base trial with Vevče.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lenzing papier', 'lenzing', 'lenzing', false,
   $pj${"owner": "Lenzing Papier", "priority": 5, "products": "Recycled fine paper", "grades": ["UWF"], "approach": "Recycled fine-paper fibre saving.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('norske skog.*bruck|\mbruck\M.*mur', 'bruck', 'norske skog', false,
   $pj${"owner": "Norske Skog", "priority": 6, "products": "LWC, containerboard", "grades": ["LWC", "Testliner"], "machines": 2, "capacity": {"value": 470000, "unit": "metric_t", "year": "Austropapier", "source": "austropapier.at"}, "approach": "LWC base-paper trial - group link Saugbrugs and Skogn (NO).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('frohnleiten|\mmm\M.*frohnl|mayr.*frohnl', 'frohnleiten', '\mmm\M|mayr', false,
   $pj${"owner": "MM Group", "priority": 7, "products": "Recycled and barrier cartonboard", "grades": ["WLC", "Coated board"], "machines": 2, "capacity": {"value": 590000, "unit": "metric_t", "year": "Austropapier", "source": "austropapier.at"}, "approach": "Ply-level trial - MM group link (Količevo SI, Kotkamills FI).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('delfort.*traun|feurstein', 'traun', 'delfort|feurstein', false,
   $pj${"owner": "delfort", "priority": 8, "products": "Specialty paper", "grades": ["Specialty paper"], "approach": "Group trial with Tervakoski (SMI on site).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wattens', 'wattens', 'delfort|wattens', false,
   $pj${"owner": "delfort", "products": "Specialty paper", "grades": ["Specialty paper"], "approach": "Check SCHAEFER KALK on-site status.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('steyrerm[uü]hl', 'steyrerm[uü]hl', 'heinzel|steyrerm', false,
   $pj${"owner": "Heinzel Group", "products": "Kraft paper", "grades": ["Kraft paper"], "capacity": {"value": 150000, "unit": "metric_t", "year": "Company figure", "source": "heinzel.com"}, "approach": "Later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hamburger.*pitten|pitten', 'pitten', 'hamburger|prinzhorn', false,
   $pj${"owner": "Prinzhorn", "products": "Testliner, fluting", "grades": ["Testliner", "Medium"], "capacity": {"value": 450000, "unit": "metric_t", "year": "Company figure", "source": "hamburger-containerboard.com"}, "approach": "Group view with TR and HU mills.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('laakirchen', null, 'laakirchen', true,
   $pj${"owner": "Heinzel Group", "products": "Laakirchen recycled packaging paper PM10 and PM11 (former SC)", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('salzer', null, 'salzer', true,
   $pj${"owner": "Salzer Papier", "products": "Technical and specialty paper, St. Pölten", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nettingsdorf', null, 'nettingsdorf', true,
   $pj${"owner": "Smurfit Westrock", "products": "Nettingsdorf kraftliner", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('frantschach', null, 'frantschach', true,
   $pj${"owner": "Mondi", "products": "Frantschach kraft paper and pulp", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zellstoff p[oö]ls|starkraft', null, 'zellstoff p[oö]ls|starkraft', true,
   $pj${"owner": "Heinzel Group", "products": "Pöls kraft pulp and Starkraft kraft paper", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rondo ganahl', null, 'rondo ganahl', true,
   $pj${"owner": "Rondo Ganahl", "products": "Recycled board and base paper, Frastanz", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('merckens', null, 'merckens', true,
   $pj${"owner": "Merckens", "products": "Board, Schwertberg", "approach": "Packaging or specialty - later.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'austria_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler', 'omya.*hausmening', 'active', 'medium', '2001-01-01'::date, null::date, 'about 42,000 t/yr (2005)', 'satellite PCC at the mill', 'Roskill 2005, Omya site list', 'Omya satellite PCC at Mondi Neusiedler Hausmening since 2001 - current status to confirm'),
  ('wattens', 'wattens', 'delfort|wattens', 'schaefer kalk.*(hahnst|diez|germany|deutschland)', 'historical', 'medium', '2003-01-01'::date, null::date, null, 'satellite PCC at the mill', 'Roskill 2005', 'SCHAEFER KALK satellite PCC at Papierfabrik Wattens (2003) - current status to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ~* v.filler_rx
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AT', 'Austria', 'high',
   $cm$Sappi Gratkorn (910 kt coated), Mondi Neusiedler UWF with Omya satellite PCC, Essity Ortmann tissue (130 kt) - CALMIT Bad Ischl PCC, Omya Gummern GCC$cm$,
   $cm$Austria's FCC-fit mills: Mondi Neusiedler (UWF and office paper, three machines, 180 kt, Omya satellite PCC at Hausmening since 2001), Sappi Gratkorn (coated fine and label, 910 kt), Essity Ortmann tissue (130 kt), Brigl and Bergmeister label base, Lenzing Papier, Norske Skog Bruck LWC (470 kt), MM Frohnleiten board (590 kt), delfort Traun and Wattens specialty. Packaging: Heinzel Laakirchen and Steyrermühl, Hamburger Pitten (450 kt), Nettingsdorf, Frantschach, Pöls. Fillers: Omya Austria (Gummern GCC, Golling PCC), CALMIT Bad Ischl PCC (CALPREC, new EUR 25 m plant 2026), Shiraishi-Omya nano PCC (not paper), SCHAEFER KALK Wattens satellite history.$cm$,
   $cm${"fillers": "GCC: Omya Gummern. PCC: Omya Golling and Hausmening satellite, CALMIT Bad Ischl, Shiraishi-Omya (nano, adhesives). History: SCHAEFER KALK Wattens satellite (2003).", "mills": "UWF: Mondi Neusiedler, Lenzing Papier. Coated and label: Sappi Gratkorn, Brigl and Bergmeister. LWC: Norske Skog Bruck. Tissue: Essity Ortmann. Board: MM Frohnleiten. Specialty: delfort Traun and Wattens. Packaging: Steyrermühl, Hamburger Pitten, plus context.", "strategy": "Mondi + Omya Hausmening + MBG three-way trial, Sappi Gratkorn base-paper trial, Essity tissue via group R&D. CALMIT as an independent PCC licence partner.", "risks": "Omya competing tech, packaging conversions (Laakirchen, Steyrermühl).", "next_steps": ["Propose a Hausmening three-way trial", "Open licence talks with CALMIT"], "key_numbers": [{"label": "Sappi Gratkorn", "value": "910 kt/yr"}, {"label": "Mondi Neusiedler", "value": "180 kt/yr (latest)"}, {"label": "Omya Hausmening PCC", "value": "about 42 kt (2005)"}], "files": ["seed_20261016zzg_austria_mills_fillers"]}$cm$::jsonb,
   $cm$Sappi Gratkorn(코팅 91만 t), Mondi Neusiedler UWF + Omya 위성 PCC, Essity Ortmann 티슈(13만 t) — CALMIT Bad Ischl PCC, Omya Gummern GCC$cm$,
   $cm$오스트리아 FCC 적합: Mondi Neusiedler(UWF·사무용지 3대 18만 t, 2001년부터 Hausmening Omya 위성 PCC), Sappi Gratkorn(코팅·라벨 91만 t), Essity Ortmann 티슈(13만 t), Brigl & Bergmeister 라벨 원지, Lenzing Papier, Norske Skog Bruck LWC(47만 t), MM Frohnleiten 판지(59만 t), delfort Traun·Wattens 특수지. 포장: Heinzel Laakirchen·Steyrermühl, Hamburger Pitten(45만 t) 등. 충전제: Omya Austria(Gummern GCC·Golling PCC), CALMIT Bad Ischl PCC(CALPREC, 2026 신규 2,500만 유로), Shiraishi-Omya 나노 PCC(제지 아님), SCHAEFER KALK Wattens 위성 이력.$cm$,
   36600, 61000,
   $cm$Mondi 18만 + Sappi 91만 + Essity 13만 t × FCC 3~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('neusiedler|mondi.*hausmening', 'hausmening|ulmerfeld', 'mondi|neusiedler'),
  ('sappi.*gratkorn|gratkorn', 'gratkorn', 'sappi'),
  ('essity.*(ortmann|pernitz)|ortmann', 'pernitz|ortmann', 'essity'),
  ('brigl|niklasdorf', 'niklasdorf', 'brigl'),
  ('lenzing papier', 'lenzing', 'lenzing'),
  ('norske skog.*bruck|\mbruck\M.*mur', 'bruck', 'norske skog'),
  ('frohnleiten|\mmm\M.*frohnl|mayr.*frohnl', 'frohnleiten', '\mmm\M|mayr'),
  ('delfort.*traun|feurstein', 'traun', 'delfort|feurstein'),
  ('wattens', 'wattens', 'delfort|wattens'),
  ('steyrerm[uü]hl', 'steyrerm[uü]hl', 'heinzel|steyrerm'),
  ('hamburger.*pitten|pitten', 'pitten', 'hamburger|prinzhorn'),
  ('laakirchen', null, 'laakirchen'),
  ('salzer', null, 'salzer'),
  ('nettingsdorf', null, 'nettingsdorf'),
  ('frantschach', null, 'frantschach'),
  ('zellstoff p[oö]ls|starkraft', null, 'zellstoff p[oö]ls|starkraft'),
  ('rondo ganahl', null, 'rondo ganahl'),
  ('merckens', null, 'merckens')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'austria_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'austria_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(austria|[oö]sterreich|gummern)' or p.party_name ~* 'omya.*hausmening' or p.party_name ~* 'calmit.*(bad ischl|austria|gmbh)' or p.party_name ~* 'shiraishi.?omya')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AT'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AT'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AT'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    