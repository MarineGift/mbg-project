-- ============================================================
-- seed_20261016zy_germany_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Germany update (reports 2026-10-16). Existing DE rows likely.
-- SCHAEFER KALK guard is Germany-specific (Finnish row stays separate).
-- 1) Fillers if missing (6): SCHAEFER KALK Hahnstätten, ALPHA CALCIT,
--    Omya Germany, SMI Germany (historical), sh minerals, Lhoist / Rheinkalk.
-- 2) Mills if missing (10) + plant blocks, priority 1-8: Koehler Oberkirch,
--    UPM Nordland, Felix Schoeller Osnabrück, LEIPA Schwedt, Sappi Alfeld,
--    Essity Mannheim, WEPA Müschede, Progroup. No priority: Koehler Kehl,
--    UPM Schongau. Context (16) incl. closures.
-- 3) Supply links (2): SCHAEFER KALK -> Koehler Kehl (active, to confirm),
--    SMI -> UPM Schongau (historical).
-- 4) app.country_markets DE row (priority high).
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
           v.party_name, 'DE', v.region, v.city, v.website, 'active', 'germany_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('schaefer kalk.*(hahnst|diez|germany|deutschland)', 'SCHAEFER KALK - Hahnstätten (PCC)', 'Rhineland-Palatinate', 'Hahnstätten', null, '독일 석회·PCC 전문(본사 Diez) — Hahnstätten PCC·표면처리 PCC·분쇄·R&D, Steeden 석회, 현장 PCC Neidenfels·Kehl. 전 세계 PCC 라인 약 44.2만 t. PRECARB 100~800(스칼레노·아라고나이트·판상), 담배·경량·고급 인쇄·감열·감압·잉크젯용지.', 'SCHAEFER KALK GmbH and Co. KG, Louise-Seher-Str. 6, Diez - PCC and coated PCC plus limestone grinding and R&D at Hahnstätten, lime at Steeden, on-site PCC plants at Neidenfels and Kehl, about 442,000 t/yr PCC lines worldwide (group, incl. Finland Kuusankoski). Paper PCC PRECARB 100, 110, 120, 150, 200 (scalenohedral), 400 (calcite / aragonite), 800 (platelet) for cigarette, lightweight, fine printing, thermal, carbonless and inkjet papers.', 'DE check 2026-10-16: PCC sales Thomas Steinbrecher, thomas.steinbrecher@schaeferkalk.de, +49 6432 503 106. Independent PCC maker with on-site plants - FCC licence and co-development candidate 1.'),
  ('alpha calcit', 'ALPHA CALCIT Füllstoff - Köln', 'North Rhine-Westphalia', 'Köln', null, '채굴~완제품 탄산칼슘(Otto-Hahn-Str. 9-11, 쾰른) — 제지용 CALCICELL(충전·코팅, 고백색·저마모, 2 μm 미만 가능), CALCIFIN·ECOCARB.', 'ALPHA CALCIT Füllstoff GmbH and Co. KG, Otto-Hahn-Straße 9-11, Köln - quarry-to-product calcium carbonate, paper range CALCICELL (filler and coating pigment, high brightness and purity, low abrasion, under 2 micron on request), plus CALCIFIN and ECOCARB.', 'DE check 2026-10-16: +49 2236 8914-0. Paper GCC maker - FCC co-production candidate (GCC side).'),
  ('omya.*(germany|deutschland|gmbh)', 'Omya Germany', 'Germany', null, null, 'Omya 독일 사업 조직 — Hydrocarb·Syncarb·Omyapaque·Multifill·Omyaboard·Corefill, 위성공장 모델.', 'Omya in Germany - paper range Hydrocarb, Syncarb PCC, Omyapaque, Multifill, Omyaboard, Corefill and on-site satellite model.', 'DE check 2026-10-16: individual German plants to confirm. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('(specialty minerals|minerals technologies).*(germany|deutschland|schongau|walsum)', 'Specialty Minerals Germany - Schongau and Walsum (historical)', 'Bavaria', 'Schongau', null, 'MTI 독일 PCC 과거 기록(2005) — Schongau 위성 PCC 5만~7만 t, Walsum 상업 PCC 12.5만~14만 t.', 'Minerals Technologies PCC in Germany (2005 industry data): satellite PCC at Schongau about 50,000-70,000 t/yr and merchant PCC at Walsum about 125,000-140,000 t/yr.', 'DE check 2026-10-16: historical - 2026 status to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('sh minerals', 'sh minerals - Heidenheim', 'Baden-Württemberg', 'Heidenheim', null, 'Heidenheim 천연 탄산칼슘·돌로마이트 — 독일 5개 거점, CALCIT MX 10(평균 약 2 μm), 도료·플라스틱·건축화학 위주.', 'sh minerals GmbH, Heidenheim - natural calcite and dolomite fillers at five German sites (CALCIT, Saxolith extra, Saxodol), CALCIT MX 10 median about 2 micron, mainly paint, plastics, building chemicals.', 'DE check 2026-10-16: paper supply not confirmed. info@sh-minerals.de.'),
  ('rheinkalk|lhoist.*(germany|deutschland|w[uü]lfrath)', 'Lhoist Germany (Rheinkalk) - Wülfrath', 'North Rhine-Westphalia', 'Wülfrath', null, 'Lhoist 독일(Rheinkalk) 석회석·석회 — Wülfrath·Rheine·Lennestadt·Hagen·Herzberg·Brilon, 제지·PCC 용 석회.', 'Lhoist Germany / Rheinkalk - limestone and lime at Wülfrath, Rheine, Lennestadt-Grevenbrück, Hagen, Herzberg-Scharzfeld, Brilon-Messinghausen, lime for paper and PCC making.', 'DE check 2026-10-16: raw material only. Not added: Dr. Paul Lohmann (specialty chemicals). Calcit d.o.o. (Slovenia) supplied GCC to UPM Augsburg, Plattling and Ettringen (2017) - add under SI.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%DE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('schaefer kalk.*(hahnst|diez|germany|deutschland)', 'SCHAEFER KALK - Hahnstätten (PCC)', 'Rhineland-Palatinate', 'Hahnstätten', null, '독일 석회·PCC 전문(본사 Diez) — Hahnstätten PCC·표면처리 PCC·분쇄·R&D, Steeden 석회, 현장 PCC Neidenfels·Kehl. 전 세계 PCC 라인 약 44.2만 t. PRECARB 100~800(스칼레노·아라고나이트·판상), 담배·경량·고급 인쇄·감열·감압·잉크젯용지.', 'SCHAEFER KALK GmbH and Co. KG, Louise-Seher-Str. 6, Diez - PCC and coated PCC plus limestone grinding and R&D at Hahnstätten, lime at Steeden, on-site PCC plants at Neidenfels and Kehl, about 442,000 t/yr PCC lines worldwide (group, incl. Finland Kuusankoski). Paper PCC PRECARB 100, 110, 120, 150, 200 (scalenohedral), 400 (calcite / aragonite), 800 (platelet) for cigarette, lightweight, fine printing, thermal, carbonless and inkjet papers.', 'DE check 2026-10-16: PCC sales Thomas Steinbrecher, thomas.steinbrecher@schaeferkalk.de, +49 6432 503 106. Independent PCC maker with on-site plants - FCC licence and co-development candidate 1.'),
  ('alpha calcit', 'ALPHA CALCIT Füllstoff - Köln', 'North Rhine-Westphalia', 'Köln', null, '채굴~완제품 탄산칼슘(Otto-Hahn-Str. 9-11, 쾰른) — 제지용 CALCICELL(충전·코팅, 고백색·저마모, 2 μm 미만 가능), CALCIFIN·ECOCARB.', 'ALPHA CALCIT Füllstoff GmbH and Co. KG, Otto-Hahn-Straße 9-11, Köln - quarry-to-product calcium carbonate, paper range CALCICELL (filler and coating pigment, high brightness and purity, low abrasion, under 2 micron on request), plus CALCIFIN and ECOCARB.', 'DE check 2026-10-16: +49 2236 8914-0. Paper GCC maker - FCC co-production candidate (GCC side).'),
  ('omya.*(germany|deutschland|gmbh)', 'Omya Germany', 'Germany', null, null, 'Omya 독일 사업 조직 — Hydrocarb·Syncarb·Omyapaque·Multifill·Omyaboard·Corefill, 위성공장 모델.', 'Omya in Germany - paper range Hydrocarb, Syncarb PCC, Omyapaque, Multifill, Omyaboard, Corefill and on-site satellite model.', 'DE check 2026-10-16: individual German plants to confirm. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('(specialty minerals|minerals technologies).*(germany|deutschland|schongau|walsum)', 'Specialty Minerals Germany - Schongau and Walsum (historical)', 'Bavaria', 'Schongau', null, 'MTI 독일 PCC 과거 기록(2005) — Schongau 위성 PCC 5만~7만 t, Walsum 상업 PCC 12.5만~14만 t.', 'Minerals Technologies PCC in Germany (2005 industry data): satellite PCC at Schongau about 50,000-70,000 t/yr and merchant PCC at Walsum about 125,000-140,000 t/yr.', 'DE check 2026-10-16: historical - 2026 status to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('sh minerals', 'sh minerals - Heidenheim', 'Baden-Württemberg', 'Heidenheim', null, 'Heidenheim 천연 탄산칼슘·돌로마이트 — 독일 5개 거점, CALCIT MX 10(평균 약 2 μm), 도료·플라스틱·건축화학 위주.', 'sh minerals GmbH, Heidenheim - natural calcite and dolomite fillers at five German sites (CALCIT, Saxolith extra, Saxodol), CALCIT MX 10 median about 2 micron, mainly paint, plastics, building chemicals.', 'DE check 2026-10-16: paper supply not confirmed. info@sh-minerals.de.'),
  ('rheinkalk|lhoist.*(germany|deutschland|w[uü]lfrath)', 'Lhoist Germany (Rheinkalk) - Wülfrath', 'North Rhine-Westphalia', 'Wülfrath', null, 'Lhoist 독일(Rheinkalk) 석회석·석회 — Wülfrath·Rheine·Lennestadt·Hagen·Herzberg·Brilon, 제지·PCC 용 석회.', 'Lhoist Germany / Rheinkalk - limestone and lime at Wülfrath, Rheine, Lennestadt-Grevenbrück, Hagen, Herzberg-Scharzfeld, Brilon-Messinghausen, lime for paper and PCC making.', 'DE check 2026-10-16: raw material only. Not added: Dr. Paul Lohmann (specialty chemicals). Calcit d.o.o. (Slovenia) supplied GCC to UPM Augsburg, Plattling and Ettringen (2017) - add under SI.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'germany_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('SCHAEFER KALK - Hahnstätten (PCC)', 'PCC producer', 'Independent PCC maker with on-site plants - candidate 1', 'satellite', 'B', 'pcc'),
  ('ALPHA CALCIT Füllstoff - Köln', 'GCC producer', 'Paper GCC (CALCICELL) - co-production candidate', 'merchant', 'B', 'gcc'),
  ('Omya Germany', 'GCC and PCC supplier', 'Omya Germany - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Specialty Minerals Germany - Schongau and Walsum (historical)', 'PCC producer', 'SMI German PCC history - partner route', 'satellite', 'C', 'pcc'),
  ('sh minerals - Heidenheim', 'GCC producer', 'Fine calcite (paint, plastics) - possible partner', 'merchant', 'C', 'gcc'),
  ('Lhoist Germany (Rheinkalk) - Wülfrath', 'Lime producer', 'PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'germany_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'DE', v.region, v.city, v.website, 'active', 'germany_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('koehler.*oberkirch', 'oberkirch', 'koehler', 'Koehler Paper - Oberkirch', 'Baden-Württemberg', 'Oberkirch', null, 'Koehler 본사 공장(Hauptstraße 2, Oberkirch) — 고급지·감압복사지·장식지. 독일 5개 거점(Oberkirch·Kehl·Greiz·Weisenbach·Willstätt).', 'Koehler Paper, Hauptstraße 2, Oberkirch - fine papers, carbonless and decor papers. German sites: Oberkirch, Kehl (thermal and specialty), Greiz (recycled specialty), Weisenbach (board), Willstätt (flexible packaging paper).', 'DE check 2026-10-16: +49 7802 81-0.'),
  ('nordland|upm.*d[oö]rpen', 'd[oö]rpen', 'upm', 'UPM Nordland Papier - Dörpen', 'Lower Saxony', 'Dörpen', null, 'UPM Nordland Papier(Dörpen) 고급 인쇄·필기용지 — PM3 2024 말 종료, 나머지 설비 유지.', 'UPM Nordland Papier, Dörpen - fine printing and writing papers, PM3 stopped end 2024, remaining lines continue.', 'DE check 2026-10-16: line capacities not public here.'),
  ('felix schoeller.*osnabr|schoeller.*osnabr', 'osnabr[uü]ck', 'schoeller', 'Felix Schoeller - Osnabrück', 'Lower Saxony', 'Osnabrück', null, 'Felix Schoeller Osnabrück 연 12만 t — 인쇄 원지·릴리스 라이너·특수지. Günzach 6만·Neustadt 3만 t, Penig 2025-06 폐쇄.', 'Felix Schoeller, Osnabrück - 120,000 t/yr printing base papers, release liners and specialty papers. Other mills: Günzach (60,000 t decor and print base), Neustadt (30,000 t decor and nonwoven-type), Weißenborn, Penig closed 2025-06.', 'DE check 2026-10-16: '),
  ('leipa.*schwedt|leipa', 'schwedt', 'leipa', 'LEIPA - Schwedt', 'Brandenburg', 'Schwedt', null, 'LEIPA Schwedt 재생 인쇄용지·선물포장지·포장용지 — 그룹 회수지 연 130만 t+, 약 1,400명, 매출 약 8억 유로.', 'LEIPA Georg Leinfelder, Schwedt/Oder - recycled printing paper, gift wrap and packaging papers. Group processes over 1.3 Mt/yr recovered paper, about 1,400 staff, about EUR 800 m sales. Also Schrobenhausen (board and flexible packaging).', 'DE check 2026-10-16: stepwise dosing - recycled strength.'),
  ('sappi.*alfeld|alfeld', 'alfeld', 'sappi', 'Sappi Alfeld', 'Lower Saxony', 'Alfeld', null, 'Sappi Alfeld 펄프·특수지·고배리어 포장용지.', 'Sappi Alfeld mill - pulp, specialty and high-barrier packaging papers. Sister mill Ehingen (pulp and fine paper).', 'DE check 2026-10-16: coating pigment and base-paper filler are separate trials.'),
  ('essity.*mannheim', 'mannheim', 'essity', 'Essity - Mannheim', 'Baden-Württemberg', 'Mannheim', null, 'Essity Mannheim 티슈(Tempo·Zewa) — 짚 대체섬유 도입, 2026-02 EU PROTEUS 해조류 흡수재 프로젝트 참여. 독일 2025 매출 약 16억 유로.', 'Essity Mannheim - tissue (Tempo, Zewa, Tork), uses straw as an alternative fibre, joined the EU PROTEUS seaweed-based bio-absorbent project (2026-02). Germany is the largest Essity market in Europe (about EUR 1.6 bn sales 2025). Other sites: Mainz-Kostheim, Neuss, Witzenhausen.', 'DE check 2026-10-16: seaweed interest is a door-opener, not FCC demand.'),
  ('wepa.*(m[uü]schede|arnsberg)', 'arnsberg|m[uü]schede', 'wepa', 'WEPA - Arnsberg-Müschede', 'North Rhine-Westphalia', 'Arnsberg', null, 'WEPA 독일 티슈(Arnsberg-Müschede, Marsberg-Giershagen, Kriebstein) — 그룹 6개국 15개 거점.', 'WEPA Deutschland, Arnsberg-Müschede - tissue, other German mills Marsberg-Giershagen and Kriebstein (group: 15 sites in 6 countries).', 'DE check 2026-10-16: one row for German WEPA mills.'),
  ('progroup', null, 'progroup', 'Progroup (Germany)', null, null, null, 'Progroup 재생 골판지원지 — Burg·Eisenhüttenstadt·Sandersdorf-Brehna.', 'Progroup - recycled containerboard at Burg, Eisenhüttenstadt and Sandersdorf-Brehna.', 'DE check 2026-10-16: strength-led - one group row.'),
  ('koehler.*kehl', 'kehl', 'koehler', 'Koehler Paper - Kehl', 'Baden-Württemberg', 'Kehl', null, 'Koehler Kehl 감열지·특수지 — SCHAEFER KALK 현장 PCC 소재지.', 'Koehler Paper Kehl - thermal and specialty papers. SCHAEFER KALK lists an on-site PCC plant at Kehl.', 'DE check 2026-10-16: host of the Kehl on-site PCC to confirm.'),
  ('upm.*schongau|schongau', 'schongau', 'upm', 'UPM Schongau', 'Bavaria', 'Schongau', null, 'UPM Schongau 인쇄용지 — 2005 SMI 위성 PCC 기록.', 'UPM Schongau - printing papers, host of an SMI satellite PCC in 2005 records.', 'DE check 2026-10-16: current lines and PCC to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%DE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('koehler.*oberkirch', 'oberkirch', 'koehler', 'Koehler 본사 공장(Hauptstraße 2, Oberkirch) — 고급지·감압복사지·장식지. 독일 5개 거점(Oberkirch·Kehl·Greiz·Weisenbach·Willstätt).', 'Koehler Paper, Hauptstraße 2, Oberkirch - fine papers, carbonless and decor papers. German sites: Oberkirch, Kehl (thermal and specialty), Greiz (recycled specialty), Weisenbach (board), Willstätt (flexible packaging paper).', 'DE check 2026-10-16: +49 7802 81-0.'),
  ('nordland|upm.*d[oö]rpen', 'd[oö]rpen', 'upm', 'UPM Nordland Papier(Dörpen) 고급 인쇄·필기용지 — PM3 2024 말 종료, 나머지 설비 유지.', 'UPM Nordland Papier, Dörpen - fine printing and writing papers, PM3 stopped end 2024, remaining lines continue.', 'DE check 2026-10-16: line capacities not public here.'),
  ('felix schoeller.*osnabr|schoeller.*osnabr', 'osnabr[uü]ck', 'schoeller', 'Felix Schoeller Osnabrück 연 12만 t — 인쇄 원지·릴리스 라이너·특수지. Günzach 6만·Neustadt 3만 t, Penig 2025-06 폐쇄.', 'Felix Schoeller, Osnabrück - 120,000 t/yr printing base papers, release liners and specialty papers. Other mills: Günzach (60,000 t decor and print base), Neustadt (30,000 t decor and nonwoven-type), Weißenborn, Penig closed 2025-06.', 'DE check 2026-10-16: '),
  ('leipa.*schwedt|leipa', 'schwedt', 'leipa', 'LEIPA Schwedt 재생 인쇄용지·선물포장지·포장용지 — 그룹 회수지 연 130만 t+, 약 1,400명, 매출 약 8억 유로.', 'LEIPA Georg Leinfelder, Schwedt/Oder - recycled printing paper, gift wrap and packaging papers. Group processes over 1.3 Mt/yr recovered paper, about 1,400 staff, about EUR 800 m sales. Also Schrobenhausen (board and flexible packaging).', 'DE check 2026-10-16: stepwise dosing - recycled strength.'),
  ('sappi.*alfeld|alfeld', 'alfeld', 'sappi', 'Sappi Alfeld 펄프·특수지·고배리어 포장용지.', 'Sappi Alfeld mill - pulp, specialty and high-barrier packaging papers. Sister mill Ehingen (pulp and fine paper).', 'DE check 2026-10-16: coating pigment and base-paper filler are separate trials.'),
  ('essity.*mannheim', 'mannheim', 'essity', 'Essity Mannheim 티슈(Tempo·Zewa) — 짚 대체섬유 도입, 2026-02 EU PROTEUS 해조류 흡수재 프로젝트 참여. 독일 2025 매출 약 16억 유로.', 'Essity Mannheim - tissue (Tempo, Zewa, Tork), uses straw as an alternative fibre, joined the EU PROTEUS seaweed-based bio-absorbent project (2026-02). Germany is the largest Essity market in Europe (about EUR 1.6 bn sales 2025). Other sites: Mainz-Kostheim, Neuss, Witzenhausen.', 'DE check 2026-10-16: seaweed interest is a door-opener, not FCC demand.'),
  ('wepa.*(m[uü]schede|arnsberg)', 'arnsberg|m[uü]schede', 'wepa', 'WEPA 독일 티슈(Arnsberg-Müschede, Marsberg-Giershagen, Kriebstein) — 그룹 6개국 15개 거점.', 'WEPA Deutschland, Arnsberg-Müschede - tissue, other German mills Marsberg-Giershagen and Kriebstein (group: 15 sites in 6 countries).', 'DE check 2026-10-16: one row for German WEPA mills.'),
  ('progroup', null, 'progroup', 'Progroup 재생 골판지원지 — Burg·Eisenhüttenstadt·Sandersdorf-Brehna.', 'Progroup - recycled containerboard at Burg, Eisenhüttenstadt and Sandersdorf-Brehna.', 'DE check 2026-10-16: strength-led - one group row.'),
  ('koehler.*kehl', 'kehl', 'koehler', 'Koehler Kehl 감열지·특수지 — SCHAEFER KALK 현장 PCC 소재지.', 'Koehler Paper Kehl - thermal and specialty papers. SCHAEFER KALK lists an on-site PCC plant at Kehl.', 'DE check 2026-10-16: host of the Kehl on-site PCC to confirm.'),
  ('upm.*schongau|schongau', 'schongau', 'upm', 'UPM Schongau 인쇄용지 — 2005 SMI 위성 PCC 기록.', 'UPM Schongau - printing papers, host of an SMI satellite PCC in 2005 records.', 'DE check 2026-10-16: current lines and PCC to confirm.'),
  ('upm.*h[uü]rth|h[uü]rth', null, 'upm.*h[uü]rth|h[uü]rth', null, null, 'DE check 2026-10-16: Hürth printing paper ended 2024-08 - context only.'),
  ('upm.*ettringen|ettringen', null, 'upm.*ettringen|ettringen', null, null, 'DE check 2026-10-16: Ettringen production ended end 2025 - context only.'),
  ('upm.*(augsburg|plattling)', null, 'upm.*(augsburg|plattling)', null, null, 'DE check 2026-10-16: Augsburg / Plattling printing papers - Calcit GCC supply in 2017 - context only.'),
  ('schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', null, 'schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', null, null, 'DE check 2026-10-16: Günzach, Neustadt, Weißenborn mills, Penig closed 2025-06 - context only.'),
  ('koehler.*(greiz|weisenbach|willst)', null, 'koehler.*(greiz|weisenbach|willst)', null, null, 'DE check 2026-10-16: Greiz, Weisenbach, Willstätt mills - context only.'),
  ('sappi.*ehingen|ehingen', null, 'sappi.*ehingen|ehingen', null, null, 'DE check 2026-10-16: Ehingen pulp and fine paper - context only.'),
  ('essity.*(mainz|kostheim|neuss|witzenhausen)', null, 'essity.*(mainz|kostheim|neuss|witzenhausen)', null, null, 'DE check 2026-10-16: Mainz-Kostheim, Neuss, Witzenhausen tissue - context only.'),
  ('wepa.*(giershagen|marsberg|kriebstein)', null, 'wepa.*(giershagen|marsberg|kriebstein)', null, null, 'DE check 2026-10-16: Marsberg-Giershagen and Kriebstein tissue - context only.'),
  ('\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', null, '\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', null, null, 'DE check 2026-10-16: Containerboard and newsprint, Aalen, Wörth - context only.'),
  ('hamburger.*(gelsenkirchen|spremberg)', null, 'hamburger.*(gelsenkirchen|spremberg)', null, null, 'DE check 2026-10-16: Recycled containerboard, Gelsenkirchen, Spremberg - context only.'),
  ('schoellershammer', null, 'schoellershammer', null, null, 'DE check 2026-10-16: Containerboard, Düren - context only.'),
  ('drewsen', null, 'drewsen', null, null, 'DE check 2026-10-16: Security and technical paper, Lachendorf - context only.'),
  ('hahnem[uü]hle', null, 'hahnem[uü]hle', null, null, 'DE check 2026-10-16: Fine art paper - context only.'),
  ('mitsubishi hitec', null, 'mitsubishi hitec', null, null, 'DE check 2026-10-16: Coated specialty paper - context only.'),
  ('feldmuehle|feldm[uü]hle', null, 'feldmuehle|feldm[uü]hle', null, null, 'DE check 2026-10-16: Label and packaging paper, Uetersen - context only.'),
  ('norske skog.*bruckm', null, 'norske skog.*bruckm', null, null, 'DE check 2026-10-16: Bruckmühl - status to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'germany_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('koehler.*oberkirch', 'oberkirch', 'koehler'),
  ('nordland|upm.*d[oö]rpen', 'd[oö]rpen', 'upm'),
  ('felix schoeller.*osnabr|schoeller.*osnabr', 'osnabr[uü]ck', 'schoeller'),
  ('leipa.*schwedt|leipa', 'schwedt', 'leipa'),
  ('sappi.*alfeld|alfeld', 'alfeld', 'sappi'),
  ('essity.*mannheim', 'mannheim', 'essity'),
  ('wepa.*(m[uü]schede|arnsberg)', 'arnsberg|m[uü]schede', 'wepa'),
  ('progroup', null, 'progroup'),
  ('koehler.*kehl', 'kehl', 'koehler'),
  ('upm.*schongau|schongau', 'schongau', 'upm'),
  ('upm.*h[uü]rth|h[uü]rth', null, 'upm.*h[uü]rth|h[uü]rth'),
  ('upm.*ettringen|ettringen', null, 'upm.*ettringen|ettringen'),
  ('upm.*(augsburg|plattling)', null, 'upm.*(augsburg|plattling)'),
  ('schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', null, 'schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)'),
  ('koehler.*(greiz|weisenbach|willst)', null, 'koehler.*(greiz|weisenbach|willst)'),
  ('sappi.*ehingen|ehingen', null, 'sappi.*ehingen|ehingen'),
  ('essity.*(mainz|kostheim|neuss|witzenhausen)', null, 'essity.*(mainz|kostheim|neuss|witzenhausen)'),
  ('wepa.*(giershagen|marsberg|kriebstein)', null, 'wepa.*(giershagen|marsberg|kriebstein)'),
  ('\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', null, '\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm'),
  ('hamburger.*(gelsenkirchen|spremberg)', null, 'hamburger.*(gelsenkirchen|spremberg)'),
  ('schoellershammer', null, 'schoellershammer'),
  ('drewsen', null, 'drewsen'),
  ('hahnem[uü]hle', null, 'hahnem[uü]hle'),
  ('mitsubishi hitec', null, 'mitsubishi hitec'),
  ('feldmuehle|feldm[uü]hle', null, 'feldmuehle|feldm[uü]hle'),
  ('norske skog.*bruckm', null, 'norske skog.*bruckm')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('koehler.*oberkirch', 'oberkirch', 'koehler', false,
   $pj${"owner": "Koehler", "priority": 1, "products": "Fine, carbonless, decor paper", "grades": ["Specialty paper", "UWF"], "pitch": "Koehler + SCHAEFER KALK + MBG trial", "approach": "Lead German account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nordland|upm.*d[oö]rpen', 'd[oö]rpen', 'upm', false,
   $pj${"owner": "UPM", "priority": 2, "products": "Fine printing and writing paper", "grades": ["UWF"], "approach": "Volume UWF trial with a filler partner.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('felix schoeller.*osnabr|schoeller.*osnabr', 'osnabr[uü]ck', 'schoeller', false,
   $pj${"owner": "Felix Schoeller", "priority": 3, "products": "Print base paper, release liner, specialty", "grades": ["Specialty paper"], "capacity": {"value": 120000, "unit": "metric_t", "year": "Company figure", "source": "felix-schoeller.com"}, "approach": "Opacity-led decor and print-base trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('leipa.*schwedt|leipa', 'schwedt', 'leipa', false,
   $pj${"owner": "LEIPA", "priority": 4, "products": "Recycled printing paper, packaging paper", "grades": ["Printing paper", "Packaging paper"], "approach": "Recycled printing trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*alfeld|alfeld', 'alfeld', 'sappi', false,
   $pj${"owner": "Sappi", "priority": 5, "products": "Specialty and barrier packaging paper", "grades": ["Specialty paper"], "approach": "Base-paper fibre saving.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*mannheim', 'mannheim', 'essity', false,
   $pj${"owner": "Essity", "priority": 6, "products": "Tissue", "grades": ["Tissue"], "pitch": "Marine-fibre FCC fits the alternative-fibre and seaweed agenda", "approach": "Mannheim R&D - joint tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wepa.*(m[uü]schede|arnsberg)', 'arnsberg|m[uü]schede', 'wepa', false,
   $pj${"owner": "WEPA", "priority": 7, "products": "Tissue", "grades": ["Tissue"], "approach": "FCC 3-5 pct tissue trial - links with WEPA FR and UK.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('progroup', null, 'progroup', false,
   $pj${"owner": "Progroup", "priority": 8, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "approach": "Strength-hold trial later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('koehler.*kehl', 'kehl', 'koehler', false,
   $pj${"owner": "Koehler", "products": "Thermal and specialty paper", "grades": ["Specialty paper"], "approach": "With SCHAEFER KALK on site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('upm.*schongau|schongau', 'schongau', 'upm', false,
   $pj${"owner": "UPM", "products": "Printing paper", "grades": ["Printing paper"], "approach": "Check SMI satellite status.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('upm.*h[uü]rth|h[uü]rth', null, 'upm.*h[uü]rth|h[uü]rth', true,
   $pj${"owner": "UPM", "products": "Hürth printing paper ended 2024-08", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('upm.*ettringen|ettringen', null, 'upm.*ettringen|ettringen', true,
   $pj${"owner": "UPM", "products": "Ettringen production ended end 2025", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('upm.*(augsburg|plattling)', null, 'upm.*(augsburg|plattling)', true,
   $pj${"owner": "UPM", "products": "Augsburg / Plattling printing papers - Calcit GCC supply in 2017", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', null, 'schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', true,
   $pj${"owner": "Felix Schoeller", "products": "Günzach, Neustadt, Weißenborn mills, Penig closed 2025-06", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('koehler.*(greiz|weisenbach|willst)', null, 'koehler.*(greiz|weisenbach|willst)', true,
   $pj${"owner": "Koehler", "products": "Greiz, Weisenbach, Willstätt mills", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*ehingen|ehingen', null, 'sappi.*ehingen|ehingen', true,
   $pj${"owner": "Sappi", "products": "Ehingen pulp and fine paper", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*(mainz|kostheim|neuss|witzenhausen)', null, 'essity.*(mainz|kostheim|neuss|witzenhausen)', true,
   $pj${"owner": "Essity", "products": "Mainz-Kostheim, Neuss, Witzenhausen tissue", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wepa.*(giershagen|marsberg|kriebstein)', null, 'wepa.*(giershagen|marsberg|kriebstein)', true,
   $pj${"owner": "WEPA", "products": "Marsberg-Giershagen and Kriebstein tissue", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', null, '\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', true,
   $pj${"owner": "Palm", "products": "Containerboard and newsprint, Aalen, Wörth", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hamburger.*(gelsenkirchen|spremberg)', null, 'hamburger.*(gelsenkirchen|spremberg)', true,
   $pj${"owner": "Prinzhorn", "products": "Recycled containerboard, Gelsenkirchen, Spremberg", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('schoellershammer', null, 'schoellershammer', true,
   $pj${"owner": "Schoellershammer", "products": "Containerboard, Düren", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('drewsen', null, 'drewsen', true,
   $pj${"owner": "Drewsen Spezialpapiere", "products": "Security and technical paper, Lachendorf", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hahnem[uü]hle', null, 'hahnem[uü]hle', true,
   $pj${"owner": "Hahnemühle", "products": "Fine art paper", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mitsubishi hitec', null, 'mitsubishi hitec', true,
   $pj${"owner": "Mitsubishi HiTec Paper Europe", "products": "Coated specialty paper", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('feldmuehle|feldm[uü]hle', null, 'feldmuehle|feldm[uü]hle', true,
   $pj${"owner": "Feldmuehle", "products": "Label and packaging paper, Uetersen", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('norske skog.*bruckm', null, 'norske skog.*bruckm', true,
   $pj${"owner": "Norske Skog", "products": "Bruckmühl - status to confirm", "approach": "Closed, liner or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'germany_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('koehler.*kehl', 'kehl', 'koehler', 'schaefer kalk.*(hahnst|diez|germany|deutschland)', 'active', 'medium', null::date, null::date, null, 'on-site PCC at the mill site', 'SCHAEFER KALK site list', 'SCHAEFER KALK on-site PCC at Kehl - Koehler host to confirm'),
  ('upm.*schongau|schongau', 'schongau', 'upm', '(specialty minerals|minerals technologies).*(germany|deutschland|schongau|walsum)', 'historical', 'medium', null::date, null::date, '50,000-70,000 t/yr (2005)', 'satellite PCC at the mill', 'Industry report 2005', 'SMI satellite PCC at UPM Schongau (2005) - current status to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'DE', 'Germany', 'high',
   $cm$18.7 Mt paper and board, 128 mills - Koehler, UPM Nordland, Felix Schoeller, LEIPA, Sappi, Essity and WEPA tissue - SCHAEFER KALK PCC, ALPHA CALCIT GCC$cm$,
   $cm$Germany made 18.7 Mt paper and board in 2025 (-2.5 pct, EUR 14.2 bn, 128 mills, 216 machines), about 84 pct recovered-fibre use. FCC-fit: Koehler (Oberkirch, Kehl), UPM Nordland Dörpen, Felix Schoeller Osnabrück (120 kt), LEIPA Schwedt, Sappi Alfeld, tissue at Essity Mannheim (straw fibre, EU seaweed absorbent project) and WEPA. Closures: UPM Hürth (2024), Dörpen PM3 (2024), Ettringen (2025), Felix Schoeller Penig (2025). Fillers: SCHAEFER KALK (Hahnstätten PCC, on-site at Neidenfels and Kehl, PRECARB range), ALPHA CALCIT (CALCICELL paper GCC), Omya Germany, SMI history (Schongau, Walsum), sh minerals, Lhoist / Rheinkalk lime. Calcit (Slovenia) supplied UPM German mills.$cm$,
   $cm${"fillers": "PCC: SCHAEFER KALK (Hahnstätten, Neidenfels and Kehl on-site), SMI history (Schongau satellite, Walsum merchant). GCC: ALPHA CALCIT CALCICELL, Omya Germany, sh minerals. Lime: Lhoist / Rheinkalk. Foreign: Calcit (SI).", "mills": "Specialty and printing: Koehler, UPM Nordland, Felix Schoeller, LEIPA, Sappi Alfeld, Koehler Kehl, UPM Schongau. Tissue: Essity Mannheim, WEPA. Containerboard: Progroup. Context: about 16 more incl. closures.", "strategy": "Koehler + SCHAEFER KALK (Kehl on-site) three-way trial, UPM Nordland with a filler partner, Essity Mannheim through its alternative-fibre and seaweed agenda, ALPHA CALCIT for a GCC-based FCC line.", "risks": "Closures and high energy cost, Omya competing tech, recycled-fibre strength limits.", "next_steps": ["Approach SCHAEFER KALK PCC sales", "Propose a tissue trial to Essity Mannheim R&D"], "key_numbers": [{"label": "2025 output", "value": "18.7 Mt, 128 mills, 216 machines"}, {"label": "Recovered fibre 2024", "value": "16.1 Mt, about 84 pct"}, {"label": "SCHAEFER KALK PCC", "value": "about 442 kt worldwide"}], "files": ["seed_20261016zy_germany_mills_fillers"]}$cm$::jsonb,
   $cm$종이·판지 1,870만 t·공장 128곳 — Koehler·UPM Nordland·Felix Schoeller·LEIPA·Sappi, Essity·WEPA 티슈 — SCHAEFER KALK PCC·ALPHA CALCIT GCC$cm$,
   $cm$독일 2025 종이·판지 1,870만 t(-2.5%, 142억 유로, 공장 128·초지기 216), 회수지 약 84%. FCC 적합: Koehler(Oberkirch·Kehl), UPM Nordland Dörpen, Felix Schoeller Osnabrück(12만 t), LEIPA Schwedt, Sappi Alfeld, 티슈 Essity Mannheim(짚 섬유, EU 해조류 흡수재 프로젝트)·WEPA. 폐쇄: UPM Hürth(2024)·Dörpen PM3·Ettringen(2025)·Schoeller Penig(2025). 충전제: SCHAEFER KALK(Hahnstätten PCC, Neidenfels·Kehl 현장), ALPHA CALCIT(CALCICELL), Omya, SMI 과거(Schongau·Walsum), sh minerals, Rheinkalk.$cm$,
   15000, 30000,
   $cm$적용 가능 종이 300만 t × 채택 10~20% × FCC 5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('koehler.*oberkirch', 'oberkirch', 'koehler'),
  ('nordland|upm.*d[oö]rpen', 'd[oö]rpen', 'upm'),
  ('felix schoeller.*osnabr|schoeller.*osnabr', 'osnabr[uü]ck', 'schoeller'),
  ('leipa.*schwedt|leipa', 'schwedt', 'leipa'),
  ('sappi.*alfeld|alfeld', 'alfeld', 'sappi'),
  ('essity.*mannheim', 'mannheim', 'essity'),
  ('wepa.*(m[uü]schede|arnsberg)', 'arnsberg|m[uü]schede', 'wepa'),
  ('progroup', null, 'progroup'),
  ('koehler.*kehl', 'kehl', 'koehler'),
  ('upm.*schongau|schongau', 'schongau', 'upm'),
  ('upm.*h[uü]rth|h[uü]rth', null, 'upm.*h[uü]rth|h[uü]rth'),
  ('upm.*ettringen|ettringen', null, 'upm.*ettringen|ettringen'),
  ('upm.*(augsburg|plattling)', null, 'upm.*(augsburg|plattling)'),
  ('schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)', null, 'schoeller.*(g[uü]nzach|neustadt|wei[sß]enborn|penig)'),
  ('koehler.*(greiz|weisenbach|willst)', null, 'koehler.*(greiz|weisenbach|willst)'),
  ('sappi.*ehingen|ehingen', null, 'sappi.*ehingen|ehingen'),
  ('essity.*(mainz|kostheim|neuss|witzenhausen)', null, 'essity.*(mainz|kostheim|neuss|witzenhausen)'),
  ('wepa.*(giershagen|marsberg|kriebstein)', null, 'wepa.*(giershagen|marsberg|kriebstein)'),
  ('\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm', null, '\mpalm\M.*(aalen|w[oö]rth)|papierfabrik palm'),
  ('hamburger.*(gelsenkirchen|spremberg)', null, 'hamburger.*(gelsenkirchen|spremberg)'),
  ('schoellershammer', null, 'schoellershammer'),
  ('drewsen', null, 'drewsen'),
  ('hahnem[uü]hle', null, 'hahnem[uü]hle'),
  ('mitsubishi hitec', null, 'mitsubishi hitec'),
  ('feldmuehle|feldm[uü]hle', null, 'feldmuehle|feldm[uü]hle'),
  ('norske skog.*bruckm', null, 'norske skog.*bruckm')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'germany_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'germany_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'schaefer kalk.*(hahnst|diez|germany|deutschland)' or p.party_name ~* 'alpha calcit' or p.party_name ~* 'omya.*(germany|deutschland|gmbh)' or p.party_name ~* '(specialty minerals|minerals technologies).*(germany|deutschland|schongau|walsum)' or p.party_name ~* 'sh minerals' or p.party_name ~* 'rheinkalk|lhoist.*(germany|deutschland|w[uü]lfrath)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'DE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'DE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'DE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    