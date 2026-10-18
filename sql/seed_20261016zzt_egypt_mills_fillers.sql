-- ============================================================
-- seed_20261016zzt_egypt_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Egypt update (reports 2026-10-16). Fixed generator.
-- 10th of Ramadan has Al Zeina and Bardi - owner regex keeps them apart.
-- 1) Fillers if missing (6): ACCM, ACMA, Alfacarb, Minya Carbonate,
--    HERBOCAL, El Sayaad Stone.
-- 2) Mills if missing (7) + plant blocks, priority 1-7: QPIC, Hayat Egypt,
--    Al Zeina, Misr Edfu, Fine Hygienic, Uniboard, Bardi. Context (3):
--    Rakta (liquidation), National Paper, Interpac.
-- 3) app.country_markets EG row (priority medium).
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
           v.party_name, 'EG', v.region, v.city, v.website, 'active', 'egypt_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\maccm\M|ascom carbonate', 'ACCM (ASCOM Carbonate) - Minya', 'Minya', 'El-Metahra', null, 'ASEC Mining(ASCOM) 계열 ACCM(2009~, El-Metahra 산업단지, Minya) — 제지 충전제·코팅 안료 명시, 원료 CaCO3 99.2~99.6%·백색도 약 97%, Hosokawa Alpine, 2020 연 40만 t 증설 목표.', 'ASCOM Carbonate and Chemicals Manufacturing (ACCM, ASEC Company for Mining), plant at El-Metahra Industrial Zone (Minya) since 2009, HQ New Maadi, Cairo - GCC, ultrafine and coated GCC, paper fillers and coating pigments named, ore up to about 99.2-99.6 pct CaCO3 and about 97 pct brightness, Hosokawa Alpine grinding, 400,000 t/yr expansion target (2020), exports to Asia, Middle East, Africa, South America.', 'EG check 2026-10-16: current capacity and wet slurry to confirm. sales@accm.com.eg, +20 2 2517 7980. FCC co-production candidate 1.'),
  ('\macma\M.*(chemical|mining)|acma for', 'ACMA for Chemicals and Mining - Minya', 'Minya', 'Minya', null, 'ACMA(Minya, 광산 약 100만 m²) — Hosokawa Alpine, 3~200 μm GCC, CaCO3 약 99.5%·백색도 약 99%(회사 발표), 제지 용도 명시.', 'ACMA for Chemicals and Mining, Minya - about 1 million m2 quarry site, Hosokawa Alpine mills, GCC 3-200 micron, about 99.5 pct CaCO3 and 99 pct brightness (company claim), paper named.', 'EG check 2026-10-16: fine-grade output and paper sales to confirm.'),
  ('alfacarb|alfa carbonate', 'Alfacarb - Minya', 'Minya', 'Minya', null, 'Alfacarb(1955 첫 공장, 가족기업, Ehab Edward Faltas) Minya 고순도 GCC — CaCO3 약 99.6%·백색도 약 98%.', 'Alfacarb (Alfa Carbonate, family firm, first plant 1955, run by Ehab Edward Faltas), Minya - high-purity GCC, about 99.6 pct CaCO3 and 98 pct brightness.', 'EG check 2026-10-16: paper slurry and mill sales to confirm.'),
  ('minya carbonate|kastour', 'Minya Carbonate Company (Abo Kastour) - Minya', 'Minya', 'Minya', null, 'Abo Kastour 그룹 MCC(2014) 자체 채석장·분쇄(Hosokawa Alpine) 3~45 μm GCC.', 'Minya Carbonate Company (MCC, Abo Kastour Group, 2014), Minya - own quarry and grinding plant (Hosokawa Alpine), GCC 3-45 micron.', 'EG check 2026-10-16: mcc-kastour.com.'),
  ('herbocal', 'HERBOCAL - Minya', 'Minya', 'Minya', null, 'HERBOCAL Minya 0.7~200 μm 미분 GCC, 제지 용도 명시.', 'HERBOCAL, Minya - micronised GCC 0.7-200 micron, paper named.', 'EG check 2026-10-16: D50 / D90 per grade to confirm.'),
  ('sayaad|sayad stone', 'El Sayaad Stone - Minya', 'Minya', 'Minya', null, 'El Sayaad Stone Minya GCC·코팅 GCC 월 1만 t(연 12만 t) — ES-5·ES-8·ES-10, 8~50 μm.', 'El Sayaad Stone, Minya - GCC and coated GCC, about 10,000 t/month (120,000 t/yr stated), ES-5 UltraFine, ES-8, ES-10, 8-50 micron, for plastics, paint, paper, rubber, building.', 'EG check 2026-10-16: too coarse for fine paper as listed. logistics@elsayaadstone.com. Not added: Rihan Trade (small, Minya), Innova (Indian PCC importer). No Egyptian paper PCC found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%EG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\maccm\M|ascom carbonate', 'ACCM (ASCOM Carbonate) - Minya', 'Minya', 'El-Metahra', null, 'ASEC Mining(ASCOM) 계열 ACCM(2009~, El-Metahra 산업단지, Minya) — 제지 충전제·코팅 안료 명시, 원료 CaCO3 99.2~99.6%·백색도 약 97%, Hosokawa Alpine, 2020 연 40만 t 증설 목표.', 'ASCOM Carbonate and Chemicals Manufacturing (ACCM, ASEC Company for Mining), plant at El-Metahra Industrial Zone (Minya) since 2009, HQ New Maadi, Cairo - GCC, ultrafine and coated GCC, paper fillers and coating pigments named, ore up to about 99.2-99.6 pct CaCO3 and about 97 pct brightness, Hosokawa Alpine grinding, 400,000 t/yr expansion target (2020), exports to Asia, Middle East, Africa, South America.', 'EG check 2026-10-16: current capacity and wet slurry to confirm. sales@accm.com.eg, +20 2 2517 7980. FCC co-production candidate 1.'),
  ('\macma\M.*(chemical|mining)|acma for', 'ACMA for Chemicals and Mining - Minya', 'Minya', 'Minya', null, 'ACMA(Minya, 광산 약 100만 m²) — Hosokawa Alpine, 3~200 μm GCC, CaCO3 약 99.5%·백색도 약 99%(회사 발표), 제지 용도 명시.', 'ACMA for Chemicals and Mining, Minya - about 1 million m2 quarry site, Hosokawa Alpine mills, GCC 3-200 micron, about 99.5 pct CaCO3 and 99 pct brightness (company claim), paper named.', 'EG check 2026-10-16: fine-grade output and paper sales to confirm.'),
  ('alfacarb|alfa carbonate', 'Alfacarb - Minya', 'Minya', 'Minya', null, 'Alfacarb(1955 첫 공장, 가족기업, Ehab Edward Faltas) Minya 고순도 GCC — CaCO3 약 99.6%·백색도 약 98%.', 'Alfacarb (Alfa Carbonate, family firm, first plant 1955, run by Ehab Edward Faltas), Minya - high-purity GCC, about 99.6 pct CaCO3 and 98 pct brightness.', 'EG check 2026-10-16: paper slurry and mill sales to confirm.'),
  ('minya carbonate|kastour', 'Minya Carbonate Company (Abo Kastour) - Minya', 'Minya', 'Minya', null, 'Abo Kastour 그룹 MCC(2014) 자체 채석장·분쇄(Hosokawa Alpine) 3~45 μm GCC.', 'Minya Carbonate Company (MCC, Abo Kastour Group, 2014), Minya - own quarry and grinding plant (Hosokawa Alpine), GCC 3-45 micron.', 'EG check 2026-10-16: mcc-kastour.com.'),
  ('herbocal', 'HERBOCAL - Minya', 'Minya', 'Minya', null, 'HERBOCAL Minya 0.7~200 μm 미분 GCC, 제지 용도 명시.', 'HERBOCAL, Minya - micronised GCC 0.7-200 micron, paper named.', 'EG check 2026-10-16: D50 / D90 per grade to confirm.'),
  ('sayaad|sayad stone', 'El Sayaad Stone - Minya', 'Minya', 'Minya', null, 'El Sayaad Stone Minya GCC·코팅 GCC 월 1만 t(연 12만 t) — ES-5·ES-8·ES-10, 8~50 μm.', 'El Sayaad Stone, Minya - GCC and coated GCC, about 10,000 t/month (120,000 t/yr stated), ES-5 UltraFine, ES-8, ES-10, 8-50 micron, for plastics, paint, paper, rubber, building.', 'EG check 2026-10-16: too coarse for fine paper as listed. logistics@elsayaadstone.com. Not added: Rihan Trade (small, Minya), Innova (Indian PCC importer). No Egyptian paper PCC found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'egypt_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('ACCM (ASCOM Carbonate) - Minya', 'GCC producer', 'Paper GCC named, large Minya plant - candidate 1', 'merchant', 'B', 'gcc'),
  ('ACMA for Chemicals and Mining - Minya', 'GCC producer', 'Fine GCC with paper named - candidate 2', 'merchant', 'C', 'gcc'),
  ('Alfacarb - Minya', 'GCC producer', 'High-purity GCC - raw-material partner', 'merchant', 'C', 'gcc'),
  ('Minya Carbonate Company (Abo Kastour) - Minya', 'GCC producer', 'Own-quarry GCC - co-production option', 'merchant', 'C', 'gcc'),
  ('HERBOCAL - Minya', 'GCC producer', 'Ultrafine GCC claim - pilot option', 'merchant', 'C', 'gcc'),
  ('El Sayaad Stone - Minya', 'GCC producer', 'Coarse GCC - raw material and OEM', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'egypt_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'EG', v.region, v.city, v.website, 'active', 'egypt_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('quena paper|qena paper|\mqpic\M', 'qus|qena', 'quena|qena|qpic', 'Quena Paper Industry (QPIC) - Qus', 'Qena', 'Qus', null, 'QPIC(1995, Qus) 사탕수수 바가스 기반 인쇄·필기·A4 복사(70~80 gsm)·크라프트, 연 12만 t, 국내 시장 약 25%, 수출 약 20%.', 'Quena Paper Industry Company (QPIC, 1995), Qus (Qena) next to the Qus sugar factory - bagasse-based printing, writing, A4 copy (70-80 gsm) and kraft papers, 120,000 t/yr, about 25 pct of the local market, about 20 pct exported (Sudan, Libya, Syria and others).', 'EG check 2026-10-16: HQ 3 Mamer Behlar, Kasr El Nil, Cairo. info@qpicpaper.com, +20 2 3960783.'),
  ('hayat.*(egypt|sokhna)', 'sokhna|sukhna', 'hayat', 'Hayat Egypt - Ain Sokhna', 'Suez', 'Ain Sokhna', null, 'Hayat Kimya 이집트 Ain Sokhna 티슈 공장(1.25억 달러, 2017 연 7만 t) — 2023 이집트 5개 시설·누적 5.5억 달러.', 'Hayat Egypt (Hayat Kimya, Türkiye), Ain Sokhna - tissue mill (USD 125 m, 70,000 t/yr announced 2017), five Egyptian sites and USD 550 m invested by 2023.', 'EG check 2026-10-16: base-paper output today to confirm. Group link with Hayat TR.'),
  ('zeina', '10th of ramadan|tenth of ramadan|ramadan', 'zeina', 'Al Zeina Tissue Mill - 10th of Ramadan', 'Sharqia', '10th of Ramadan', null, 'Zeina Group Al Zeina 티슈 원지 공장(2008, 10th of Ramadan) 연 3.2만 t.', 'Al Zeina Tissue Mill (Zeina Group, 2008), 10th of Ramadan City - tissue base paper, about 32,000 t/yr.', 'EG check 2026-10-16: virgin vs recycled share to confirm.'),
  ('edfu', 'edfu', 'edfu', 'Misr Edfu Paper - Edfu', 'Aswan', 'Edfu', null, 'Misr Edfu(Aswan) 바가스 펄프 인쇄·필기용지 50~100 gsm 연 6만 t(7.5만 t 증설 계획 — 과거 자료).', 'Misr Edfu Paper, Edfu (Aswan) - bagasse pulp and printing and writing papers 50-100 gsm, 60,000 t/yr (75,000 t expansion planned, old site data).', 'EG check 2026-10-16: reported production stops - 2026 status and owner to confirm.'),
  ('fine hygienic|\mfine\M.*egypt', 'egypt', 'fine|nuqul', 'Fine Hygienic Holding Egypt', null, null, null, 'Fine Hygienic Holding(Nuqul) 이집트 1989 진출·1990 첫 제지공장 — 티슈·화장지·위생용지.', 'Fine Hygienic Holding (Nuqul Group) - in Egypt since 1989, first Egyptian paper mill 1990, tissue, toilet and hygiene papers (IFC records).', 'EG check 2026-10-16: site and capacity to confirm.'),
  ('uniboard', 'sadat', 'uniboard', 'Uniboard - Sadat City', 'Monufia', 'Sadat City', null, 'Uniboard(2013, Shorouk Press·Youssef Allam 그룹) Duplex Board — 국내 수요 70%+ 공급, 수출 약 30%(회사 발표).', 'Uniboard (2013, linked to Shorouk Press and Youssef Allam Group), Sadat City - duplex board, claims over 70 pct of Egyptian demand, about 30 pct exported.', 'EG check 2026-10-16: white top ply only. info@uniboard-egypt.com.'),
  ('bardi', '10th of ramadan|tenth of ramadan|ramadan', 'bardi', 'Bardi Egypt - 10th of Ramadan', 'Sharqia', '10th of Ramadan', null, 'Bardi Egypt 재활용·제지·가공 — 컨테이너보드·카톤보드.', 'Bardi Egypt, 10th of Ramadan City - recycling, paper making and converting, containerboard and cartonboard.', 'EG check 2026-10-16: strength-led. info@bardi-egypt.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%EG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('quena paper|qena paper|\mqpic\M', 'qus|qena', 'quena|qena|qpic', 'QPIC(1995, Qus) 사탕수수 바가스 기반 인쇄·필기·A4 복사(70~80 gsm)·크라프트, 연 12만 t, 국내 시장 약 25%, 수출 약 20%.', 'Quena Paper Industry Company (QPIC, 1995), Qus (Qena) next to the Qus sugar factory - bagasse-based printing, writing, A4 copy (70-80 gsm) and kraft papers, 120,000 t/yr, about 25 pct of the local market, about 20 pct exported (Sudan, Libya, Syria and others).', 'EG check 2026-10-16: HQ 3 Mamer Behlar, Kasr El Nil, Cairo. info@qpicpaper.com, +20 2 3960783.'),
  ('hayat.*(egypt|sokhna)', 'sokhna|sukhna', 'hayat', 'Hayat Kimya 이집트 Ain Sokhna 티슈 공장(1.25억 달러, 2017 연 7만 t) — 2023 이집트 5개 시설·누적 5.5억 달러.', 'Hayat Egypt (Hayat Kimya, Türkiye), Ain Sokhna - tissue mill (USD 125 m, 70,000 t/yr announced 2017), five Egyptian sites and USD 550 m invested by 2023.', 'EG check 2026-10-16: base-paper output today to confirm. Group link with Hayat TR.'),
  ('zeina', '10th of ramadan|tenth of ramadan|ramadan', 'zeina', 'Zeina Group Al Zeina 티슈 원지 공장(2008, 10th of Ramadan) 연 3.2만 t.', 'Al Zeina Tissue Mill (Zeina Group, 2008), 10th of Ramadan City - tissue base paper, about 32,000 t/yr.', 'EG check 2026-10-16: virgin vs recycled share to confirm.'),
  ('edfu', 'edfu', 'edfu', 'Misr Edfu(Aswan) 바가스 펄프 인쇄·필기용지 50~100 gsm 연 6만 t(7.5만 t 증설 계획 — 과거 자료).', 'Misr Edfu Paper, Edfu (Aswan) - bagasse pulp and printing and writing papers 50-100 gsm, 60,000 t/yr (75,000 t expansion planned, old site data).', 'EG check 2026-10-16: reported production stops - 2026 status and owner to confirm.'),
  ('fine hygienic|\mfine\M.*egypt', 'egypt', 'fine|nuqul', 'Fine Hygienic Holding(Nuqul) 이집트 1989 진출·1990 첫 제지공장 — 티슈·화장지·위생용지.', 'Fine Hygienic Holding (Nuqul Group) - in Egypt since 1989, first Egyptian paper mill 1990, tissue, toilet and hygiene papers (IFC records).', 'EG check 2026-10-16: site and capacity to confirm.'),
  ('uniboard', 'sadat', 'uniboard', 'Uniboard(2013, Shorouk Press·Youssef Allam 그룹) Duplex Board — 국내 수요 70%+ 공급, 수출 약 30%(회사 발표).', 'Uniboard (2013, linked to Shorouk Press and Youssef Allam Group), Sadat City - duplex board, claims over 70 pct of Egyptian demand, about 30 pct exported.', 'EG check 2026-10-16: white top ply only. info@uniboard-egypt.com.'),
  ('bardi', '10th of ramadan|tenth of ramadan|ramadan', 'bardi', 'Bardi Egypt 재활용·제지·가공 — 컨테이너보드·카톤보드.', 'Bardi Egypt, 10th of Ramadan City - recycling, paper making and converting, containerboard and cartonboard.', 'EG check 2026-10-16: strength-led. info@bardi-egypt.com.'),
  ('rakta', null, 'rakta', null, null, 'EG check 2026-10-16: Rakta Paper, Alexandria - in liquidation (liquidator report and H1 2026 accounts, 2026-09-30) - context only.'),
  ('national paper', null, 'national paper', null, null, 'EG check 2026-10-16: Paper and board, Alexandria - status to confirm - context only.'),
  ('interpac', null, 'interpac', null, null, 'EG check 2026-10-16: Interpac Egypt - MM paper division, three paper machines - details to collect - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'egypt_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('quena paper|qena paper|\mqpic\M', 'qus|qena', 'quena|qena|qpic'),
  ('hayat.*(egypt|sokhna)', 'sokhna|sukhna', 'hayat'),
  ('zeina', '10th of ramadan|tenth of ramadan|ramadan', 'zeina'),
  ('edfu', 'edfu', 'edfu'),
  ('fine hygienic|\mfine\M.*egypt', 'egypt', 'fine|nuqul'),
  ('uniboard', 'sadat', 'uniboard'),
  ('bardi', '10th of ramadan|tenth of ramadan|ramadan', 'bardi'),
  ('rakta', null, 'rakta'),
  ('national paper', null, 'national paper'),
  ('interpac', null, 'interpac')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('quena paper|qena paper|\mqpic\M', 'qus|qena', 'quena|qena|qpic', false,
   $pj${"owner": "QPIC", "priority": 1, "products": "Bagasse printing, writing, copy paper", "grades": ["UWF", "Copy paper", "Kraft paper"], "capacity": {"value": 120000, "unit": "metric_t", "year": "Company figure", "source": "qpicpaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "UWF filler range."}, "pitch": "QPIC + ACCM GCC + MBG bagasse-paper trial", "approach": "Lead Egyptian account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hayat.*(egypt|sokhna)', 'sokhna|sukhna', 'hayat', false,
   $pj${"owner": "Hayat Kimya", "priority": 2, "products": "Tissue base paper and products", "grades": ["Tissue"], "capacity": {"value": 70000, "unit": "metric_t", "year": "2017 announcement", "source": "hayat.com.tr"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Tissue trial - Hayat group path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zeina', '10th of ramadan|tenth of ramadan|ramadan', 'zeina', false,
   $pj${"owner": "Zeina Group", "priority": 3, "products": "Tissue base paper", "grades": ["Tissue"], "capacity": {"value": 32000, "unit": "metric_t", "year": "Company profile", "source": "zeina"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Direct tissue trial with local management.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('edfu', 'edfu', 'edfu', false,
   $pj${"owner": "Misr Edfu", "priority": 4, "products": "Bagasse printing and writing paper", "grades": ["UWF"], "capacity": {"value": 60000, "unit": "metric_t", "year": "Old company figure", "source": "misredfu.com"}, "approach": "Status first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fine hygienic|\mfine\M.*egypt', 'egypt', 'fine|nuqul', false,
   $pj${"owner": "Fine Hygienic Holding", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "approach": "Tissue trial - group path (Jordan, UAE).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('uniboard', 'sadat', 'uniboard', false,
   $pj${"owner": "Uniboard", "priority": 6, "products": "Duplex board", "grades": ["WLC"], "approach": "Top-ply and coating trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bardi', '10th of ramadan|tenth of ramadan|ramadan', 'bardi', false,
   $pj${"owner": "Bardi", "priority": 7, "products": "Containerboard, cartonboard", "grades": ["Testliner", "Board"], "approach": "Strength-hold trial later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rakta', null, 'rakta', true,
   $pj${"owner": "Rakta", "products": "Rakta Paper, Alexandria - in liquidation (liquidator report and H1 2026 accounts, 2026-09-30)", "approach": "Liquidation or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('national paper', null, 'national paper', true,
   $pj${"owner": "National Paper Company", "products": "Paper and board, Alexandria - status to confirm", "approach": "Liquidation or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('interpac', null, 'interpac', true,
   $pj${"owner": "MM Group", "products": "Interpac Egypt - MM paper division, three paper machines - details to collect", "approach": "Liquidation or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'EG', 'Egypt', 'medium',
   $cm$Minya GCC cluster (ACCM, ACMA, Alfacarb, MCC, HERBOCAL) - QPIC bagasse UWF (120 kt), Hayat and Al Zeina tissue, Uniboard duplex - Rakta in liquidation$cm$,
   $cm$Egypt has a large GCC cluster at Minya: ACCM (ASCOM, paper fillers and coating named, 400 kt target), ACMA, Alfacarb, Minya Carbonate, HERBOCAL and El Sayaad Stone. No paper PCC plant. Mills: Quena Paper (QPIC, bagasse printing and copy paper, 120 kt), Misr Edfu (bagasse UWF 60 kt, status to confirm), tissue at Hayat Egypt Ain Sokhna (70 kt, 2017), Al Zeina (32 kt) and Fine Hygienic, Uniboard duplex board (over 70 pct of local demand), Bardi containerboard, Interpac (MM). Rakta is in liquidation (2026-09).$cm$,
   $cm${"fillers": "GCC Minya: ACCM, ACMA, Alfacarb, MCC, HERBOCAL, El Sayaad Stone. Not added: Rihan Trade, Innova (importer). No PCC.", "mills": "UWF: QPIC, Misr Edfu. Tissue: Hayat Egypt, Al Zeina, Fine Hygienic. Board: Uniboard, Bardi. Context: Rakta (liquidation), National Paper, Interpac.", "strategy": "Local model: ACCM or ACMA GCC + MBG FCC process, trials at QPIC (bagasse UWF) and Hayat / Al Zeina (tissue). Egypt can serve Sudan, Libya and the Levant.", "risks": "Fine-grade and slurry capability unverified, FX and payment risk.", "next_steps": ["Request ACCM paper-grade TDS and samples", "Propose a QPIC copy-paper trial"], "key_numbers": [{"label": "QPIC", "value": "120 kt UWF"}, {"label": "Four confirmed mills", "value": "282 kt (QPIC, Edfu, Hayat, Al Zeina)"}, {"label": "ACCM target", "value": "400 kt/yr (2020)"}], "files": ["seed_20261016zzt_egypt_mills_fillers"]}$cm$::jsonb,
   $cm$Minya GCC 클러스터(ACCM·ACMA·Alfacarb·MCC·HERBOCAL) — QPIC 바가스 UWF(12만 t), Hayat·Al Zeina 티슈, Uniboard 듀플렉스 — Rakta 청산$cm$,
   $cm$이집트 Minya 에 대형 GCC 클러스터: ACCM(ASCOM, 제지 충전·코팅 명시, 40만 t 목표), ACMA, Alfacarb, MCC, HERBOCAL, El Sayaad. 제지용 PCC 없음. 제지: QPIC(바가스 인쇄·복사 12만 t), Misr Edfu(바가스 UWF 6만 t, 상태 확인), 티슈 Hayat Egypt Ain Sokhna(7만 t, 2017)·Al Zeina(3.2만 t)·Fine Hygienic, Uniboard 듀플렉스(국내 70%+), Bardi 컨테이너보드, Interpac(MM). Rakta 청산 중(2026-09).$cm$,
   8460, 14100,
   $cm$QPIC + Edfu + Hayat + Al Zeina 28.2만 t × FCC 3~5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('quena paper|qena paper|\mqpic\M', 'qus|qena', 'quena|qena|qpic'),
  ('hayat.*(egypt|sokhna)', 'sokhna|sukhna', 'hayat'),
  ('zeina', '10th of ramadan|tenth of ramadan|ramadan', 'zeina'),
  ('edfu', 'edfu', 'edfu'),
  ('fine hygienic|\mfine\M.*egypt', 'egypt', 'fine|nuqul'),
  ('uniboard', 'sadat', 'uniboard'),
  ('bardi', '10th of ramadan|tenth of ramadan|ramadan', 'bardi'),
  ('rakta', null, 'rakta'),
  ('national paper', null, 'national paper'),
  ('interpac', null, 'interpac')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'egypt_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'egypt_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\maccm\M|ascom carbonate' or p.party_name ~* '\macma\M.*(chemical|mining)|acma for' or p.party_name ~* 'alfacarb|alfa carbonate' or p.party_name ~* 'minya carbonate|kastour' or p.party_name ~* 'herbocal' or p.party_name ~* 'sayaad|sayad stone')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'EG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'EG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'EG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'EG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    