-- ============================================================
-- seed_20261016zb_turkiye_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Türkiye update (reports 2026-10-16, latest mill version used).
-- Many TR rows may exist - name regex OR city + owner regex first.
-- 1) Fillers if missing (7): Omya Turkey, Adaçal (PCC), Mikron'S, Esen
--    Mikronize, Niğtaş, Aydın Madencilik, Ottocarb.
-- 2) Mills if missing (16) + plant blocks, priority 1-8: Alkim, Mopak,
--    Kartonsan, Lila, Aktül, Sanipak, Batı Kipaş, Europap Tezol. No priority:
--    Modern Karton, OYKA, Varaka, KMK, Kıvanç, Hamburger, Viking, Hayat.
-- 3) app.country_markets TR row (priority high).
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
           v.party_name, 'TR', v.region, v.city, v.website, 'active', 'turkiye_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(turk|t[uü]rk)', 'Omya Turkey (Omya Madencilik)', null, null, null, 'Omya 튀르키예 법인 Omya Madencilik — Çanakkale·İzmir·İzmit·Kırşehir 4개 광물 가공시설, 제지·플라스틱·도료·식품 공급.', 'Omya Madencilik A.S. (Omya Turkey), office Metrocity D Blok, Esentepe, Istanbul - four mineral plants at Çanakkale, İzmir, İzmit and Kırşehir (calcium carbonate, barite, talc, clay, dolomite), supplying paper, plastics, paint and food. Group offers on-site and near-site carbonate plants.', 'TR check 2026-10-16: paper grades by plant and any Turkish PCC not confirmed. +90 212 337 46 46. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('ada[cç]al', 'Adaçal Endüstriyel Mineraller - Emirdağ', 'Afyonkarahisar', 'Emirdağ', null, '2000년 설립 Emirdağ(Afyonkarahisar) PCC·GCC·석회 업체. PCC 공장 실제 가동(2026-05 대학 견학 기록), 천연·표면처리 칼사이트.', 'Adaçal Endüstriyel Mineraller (2000), Menderes Mah., Emir Afşin Bulvarı, Emirdağ (Afyonkarahisar) - PCC plant (precipitation process shown to Afyon Kocatepe University chemistry students 2026-05-18), natural and coated calcite GCC, lime, aggregates, marble.', 'TR check 2026-10-16: paper PCC grade, crystal form, slurry and mill customers not public. info@adacal.com, +90 272 442 83 20. Independent PCC maker - FCC licence candidate.'),
  ('mikron''?s|turkcarb', 'Mikron''S (TURKCARB) - Niğde', 'Niğde', 'Niğde', null, '2004년 생산 시작 Mikron''S — Niğde·Muğla(Yatağan) 공장, 제지·판지용 TURKCARB UF·95·90·75·65(2 μm 미만 최대 90%), 글로벌 제지사 승인 명시. PCC 도 판매 목록(자체 생산 미확인).', 'Mikron''S Mikronize Mineral A.S. (production since 2004), plants at Niğde-Kayseri road km 7 (Niğde) and Yatağan (Muğla), HQ Üsküdar - paper and board GCC range TURKCARB UF, 95, 90, 75, 65 and 1/2 series (up to 90 pct under 2 micron), states approvals by global paper makers. PCC also listed - own PCC plant not confirmed.', 'TR check 2026-10-16: info@mikrons.com.tr, +90 216 333 50 00. Paper-grade GCC with paper customers - FCC partner candidate.'),
  ('esen mikronize', 'Esen Mikronize - Tuzla', 'Istanbul', 'Tuzla', null, '1988년 설립 Esen Mikronize(Tuzla) — Marmara 섬 자체 칼사이트 광산, 건식 GCC 연 70만 t(1~40 μm) + 습식 GCC 슬러리 연 10만 t(1~5 μm), 표면처리·비처리.', 'Esen Mikronize (1988), Tuzla, Istanbul - own calcite quarry on Marmara Island, dry GCC capacity 700,000 t/yr (1-40 micron) and wet GCC slurry 100,000 t/yr (1-5 micron), coated and uncoated, bulk, big bag and bag.', 'TR check 2026-10-16: paper share of slurry not public. Wet slurry line makes it the first FCC co-production candidate in Turkey.'),
  ('ni[gğ]ta[sş]|mikrokal', 'Niğtaş (Mikrokal) - Niğde', 'Niğde', 'Niğde', null, '1986년부터 Niğde·Kırıkkale 고순도 GCC(최대 99.6%)·나노 칼사이트·표면처리 — 제지 공급, 자체 R&D·파일럿 설비, 철도.', 'Niğtaş (with Mikrokal, since 1986), Niğde and Kırıkkale - high-purity GCC (up to 99.6 pct claimed), nano-grade calcite and coated carbonate for paper, paint, plastics, glass and building, own R&D and pilot plant, rail wagons, 60+ countries.', 'TR check 2026-10-16: +90 388 214 15 00. Pilot plant suits FCC co-development.'),
  ('ayd[iı]n madencilik', 'Aydın Madencilik - Gemlik', 'Bursa', 'Gemlik', null, '1999년 생산 시작 Gemlik(Bursa) GCC — Hosokawa Alpine 분쇄·분급, AY 103(고급 종이 코팅)·AY 106(Wet-end 충전), 1~100 μm.', 'Aydın Madencilik, Gemlik (Bursa), producing since 1999 - GCC of its own high-purity quarry on Hosokawa Alpine grinding and classifying, 1-100 micron, paper grades AY 103 (premium paper coating) and AY 106 (wet-end filler).', 'TR check 2026-10-16: slurry supply to confirm.'),
  ('ottocarb', 'Ottocarb - İscehisar', 'Afyonkarahisar', 'İscehisar', null, 'Afyonkarahisar İscehisar 산업단지 미분화 칼사이트(천연·표면처리).', 'Ottocarb, İscehisar industrial zone (Afyonkarahisar) - micronised natural and coated calcite.', 'TR check 2026-10-16: paper grade not confirmed. Not added: PERO Minerals (CALCARB supplier, own plant unconfirmed).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(turk|t[uü]rk)', 'Omya Turkey (Omya Madencilik)', null, null, null, 'Omya 튀르키예 법인 Omya Madencilik — Çanakkale·İzmir·İzmit·Kırşehir 4개 광물 가공시설, 제지·플라스틱·도료·식품 공급.', 'Omya Madencilik A.S. (Omya Turkey), office Metrocity D Blok, Esentepe, Istanbul - four mineral plants at Çanakkale, İzmir, İzmit and Kırşehir (calcium carbonate, barite, talc, clay, dolomite), supplying paper, plastics, paint and food. Group offers on-site and near-site carbonate plants.', 'TR check 2026-10-16: paper grades by plant and any Turkish PCC not confirmed. +90 212 337 46 46. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('ada[cç]al', 'Adaçal Endüstriyel Mineraller - Emirdağ', 'Afyonkarahisar', 'Emirdağ', null, '2000년 설립 Emirdağ(Afyonkarahisar) PCC·GCC·석회 업체. PCC 공장 실제 가동(2026-05 대학 견학 기록), 천연·표면처리 칼사이트.', 'Adaçal Endüstriyel Mineraller (2000), Menderes Mah., Emir Afşin Bulvarı, Emirdağ (Afyonkarahisar) - PCC plant (precipitation process shown to Afyon Kocatepe University chemistry students 2026-05-18), natural and coated calcite GCC, lime, aggregates, marble.', 'TR check 2026-10-16: paper PCC grade, crystal form, slurry and mill customers not public. info@adacal.com, +90 272 442 83 20. Independent PCC maker - FCC licence candidate.'),
  ('mikron''?s|turkcarb', 'Mikron''S (TURKCARB) - Niğde', 'Niğde', 'Niğde', null, '2004년 생산 시작 Mikron''S — Niğde·Muğla(Yatağan) 공장, 제지·판지용 TURKCARB UF·95·90·75·65(2 μm 미만 최대 90%), 글로벌 제지사 승인 명시. PCC 도 판매 목록(자체 생산 미확인).', 'Mikron''S Mikronize Mineral A.S. (production since 2004), plants at Niğde-Kayseri road km 7 (Niğde) and Yatağan (Muğla), HQ Üsküdar - paper and board GCC range TURKCARB UF, 95, 90, 75, 65 and 1/2 series (up to 90 pct under 2 micron), states approvals by global paper makers. PCC also listed - own PCC plant not confirmed.', 'TR check 2026-10-16: info@mikrons.com.tr, +90 216 333 50 00. Paper-grade GCC with paper customers - FCC partner candidate.'),
  ('esen mikronize', 'Esen Mikronize - Tuzla', 'Istanbul', 'Tuzla', null, '1988년 설립 Esen Mikronize(Tuzla) — Marmara 섬 자체 칼사이트 광산, 건식 GCC 연 70만 t(1~40 μm) + 습식 GCC 슬러리 연 10만 t(1~5 μm), 표면처리·비처리.', 'Esen Mikronize (1988), Tuzla, Istanbul - own calcite quarry on Marmara Island, dry GCC capacity 700,000 t/yr (1-40 micron) and wet GCC slurry 100,000 t/yr (1-5 micron), coated and uncoated, bulk, big bag and bag.', 'TR check 2026-10-16: paper share of slurry not public. Wet slurry line makes it the first FCC co-production candidate in Turkey.'),
  ('ni[gğ]ta[sş]|mikrokal', 'Niğtaş (Mikrokal) - Niğde', 'Niğde', 'Niğde', null, '1986년부터 Niğde·Kırıkkale 고순도 GCC(최대 99.6%)·나노 칼사이트·표면처리 — 제지 공급, 자체 R&D·파일럿 설비, 철도.', 'Niğtaş (with Mikrokal, since 1986), Niğde and Kırıkkale - high-purity GCC (up to 99.6 pct claimed), nano-grade calcite and coated carbonate for paper, paint, plastics, glass and building, own R&D and pilot plant, rail wagons, 60+ countries.', 'TR check 2026-10-16: +90 388 214 15 00. Pilot plant suits FCC co-development.'),
  ('ayd[iı]n madencilik', 'Aydın Madencilik - Gemlik', 'Bursa', 'Gemlik', null, '1999년 생산 시작 Gemlik(Bursa) GCC — Hosokawa Alpine 분쇄·분급, AY 103(고급 종이 코팅)·AY 106(Wet-end 충전), 1~100 μm.', 'Aydın Madencilik, Gemlik (Bursa), producing since 1999 - GCC of its own high-purity quarry on Hosokawa Alpine grinding and classifying, 1-100 micron, paper grades AY 103 (premium paper coating) and AY 106 (wet-end filler).', 'TR check 2026-10-16: slurry supply to confirm.'),
  ('ottocarb', 'Ottocarb - İscehisar', 'Afyonkarahisar', 'İscehisar', null, 'Afyonkarahisar İscehisar 산업단지 미분화 칼사이트(천연·표면처리).', 'Ottocarb, İscehisar industrial zone (Afyonkarahisar) - micronised natural and coated calcite.', 'TR check 2026-10-16: paper grade not confirmed. Not added: PERO Minerals (CALCARB supplier, own plant unconfirmed).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'turkiye_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Turkey (Omya Madencilik)', 'GCC and PCC supplier', 'Omya Turkey - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Adaçal Endüstriyel Mineraller - Emirdağ', 'PCC and GCC producer', 'Independent PCC maker - FCC licence candidate', 'merchant', 'B', 'pcc'),
  ('Mikron''S (TURKCARB) - Niğde', 'GCC producer', 'Paper-grade GCC with paper customers', 'merchant', 'B', 'gcc'),
  ('Esen Mikronize - Tuzla', 'GCC producer', 'GCC plus 100 kt slurry - FCC co-production candidate 1', 'merchant', 'B', 'gcc'),
  ('Niğtaş (Mikrokal) - Niğde', 'GCC producer', 'High-purity GCC with pilot plant - co-development', 'merchant', 'C', 'gcc'),
  ('Aydın Madencilik - Gemlik', 'GCC producer', 'Paper coating and wet-end GCC', 'merchant', 'B', 'gcc'),
  ('Ottocarb - İscehisar', 'GCC producer', 'Micronised calcite', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'turkiye_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'TR', v.region, v.city, v.website, 'active', 'turkiye_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('alkim ka[gğ][iı]t|alkim.*kemalpa', 'kemalpa', 'alkim', 'Alkim Kağıt - Kemalpaşa', 'İzmir', 'Kemalpaşa', null, 'Alkim Alkali Kimya 계열 인쇄·필기용지 공장(Kemalpaşa, 1998~). Woodfree Offset·복사용지·코팅지 60~220 g/m², 55,000 → 90,000 t 증설 후 약 20% 추가 증산.', 'Alkim Kağıt (Alkim Alkali Kimya group), Kemalpaşa (İzmir) - woodfree offset, A4 and A3 copy and coated printing paper 60-220 g/m2 (mainly 70-80), started 1998 at 55,000 t/yr, expanded to 90,000 t/yr plus about 20 pct more, DCS/QCS controls, 85-90 pct home sales.', 'TR check 2026-10-16: 2026 machine capacity to confirm. +90 232 877 06 06, info@alkimkagit.com.tr.'),
  ('mopak', 'dalaman', 'mopak', 'Mopak Kağıt - Dalaman', 'Muğla', 'Dalaman', null, '1926년부터 종이사업 Mopak — Dalaman 통합 공장, Kemalpaşa·Taşköprü, 18~500 g/m² 인쇄·사무·기술용지·판지·특수지.', 'Mopak Kağıt (paper since 1926) - integrated mill at Dalaman (Muğla) plus Kemalpaşa (İzmir) and Taşköprü (Kastamonu, specialty): printing, office and technical paper, board, cigarette and other specialty papers, 18-500 g/m2.', 'TR check 2026-10-16: capacity by grade not current. +90 232 877 02 35, mopak@mopak.com.tr.'),
  ('kartonsan', 'kocaeli|ba[sş]iskele|kullar', 'kartonsan', 'Kartonsan - Kocaeli', 'Kocaeli', 'Başiskele', null, '1967년 설립 백색 코팅판지(Kullar, Başiskele). Duplex·Triplex·Luxtriplex, BM2 연 16만 t(2024 BM1+BM2 24만 t), 국내 코팅판지 약 30%, 회수지 95% 초과.', 'Kartonsan (1967), Kullar, Başiskele (Kocaeli) - coated duplex and triplex board (Normprint, Exprint, Luxtriplex), BM2 160,000 t/yr on the current site (BM1 plus BM2 240,000 t in the 2024 report), about 30 pct of Turkish coated board (2025), over 95 pct recovered fibre.', 'TR check 2026-10-16: current line set to confirm. +90 262 349 61 50.'),
  ('lila ka[gğ][iı]t|\mlila\M', 'ergene|tekirda', 'lila', 'Lila Kağıt - Ergene', 'Tekirdağ', 'Ergene', null, 'Ergene(Tekirdağ) 티슈 원지 — 4개 라인 연 27.1만 t, 2025 순생산 20.42만 t, 점보롤 수출. Erzurum TM5 연 7만 t+(2027 계획).', 'Lila Kağıt, Ergene (Tekirdağ) - tissue base paper and jumbo rolls, toilet and kitchen towel, four lines 271,000 t/yr, net output about 204,200 t in 2025 (annual report), export-led. Erzurum TM5 over 70,000 t/yr planned for 2027.', 'TR check 2026-10-16: TM5 not counted.'),
  ('akt[uü]l', 'pamukova', 'akt[uü]l', 'Aktül Kağıt - Pamukova', 'Sakarya', 'Pamukova', null, 'Pamukova(Sakarya) 버진 셀룰로오스 티슈(2011~) — 초지 연 21만 t(3라인), 가공 16만 t, Belinno, 60개국 수출.', 'Aktül Kağıt, Pamukova (Sakarya) - tissue on 100 pct virgin cellulose since 2011: 210,000 t/yr on three machines and 160,000 t/yr converting, jumbo rolls and Belinno brand, exports to 60 countries.', 'TR check 2026-10-16: '),
  ('sanipak|eczac[iı]ba[sş][iı].*(t[uü]ketim|consumer)|[iı]pek ka[gğ][iı]t', 'yalova', 'sanipak|eczac|[iı]pek', 'Sanipak (Eczacıbaşı) - Yalova', 'Yalova', 'Yalova', null, '구 Eczacıbaşı Consumer Products(İpek Kağıt 계보, 2025-01 사명 변경) — Selpak·Solo·Silen·Marathon, Yalova·Manisa, 2023 PM5 가동 후 연 25만 t.', 'Sanipak (formerly Eczacıbaşı Consumer Products, İpek Kağıt lineage since 1970, renamed 2025-01) - Selpak, Solo, Silen, Marathon tissue at Yalova and Manisa, 250,000 t/yr after PM5 started in 2023 (group figure).', 'TR check 2026-10-16: site split not public - group total kept on this row.'),
  ('kipa[sş]', 's[oö]ke', 'kipa', 'Batı Kipaş Kağıt - Söke', 'Aydın', 'Söke', null, 'Kipaş Holding Söke 대형 종이·판지 공장(부지 62만 m²) — 연 130만 t, 코팅 Duplex·Triplex·White Top·Krafttop·Fluting·Grey·Coreboard, 70~450 g/m², 회수지.', 'Batı Kipaş Kağıt (Kipaş Holding), Söke (Aydın), 620,000 m2 site - 1,300,000 t/yr coated duplex and triplex, white-top and krafttop testliner, fluting, grey board and coreboard, 70-450 g/m2, almost all recovered fibre.', 'TR check 2026-10-16: FCC only for coated board and white-top lines.'),
  ('tezol|europap', 'torbal', 'tezol|europap', 'Europap Tezol - Torbalı', 'İzmir', 'Torbalı', null, 'Europap Tezol — 탈묵 재생섬유 티슈, Torbalı(İzmir)·Tarsus(Mersin), 4라인 연 13.5만~14.2만 t.', 'Europap Tezol, Torbalı (İzmir) and Tarsus (Mersin) - deinked recycled-fibre tissue on four machines, 142,000 t/yr (135,000 on older pages).', 'TR check 2026-10-16: confirm capacity in investor material.'),
  ('modern karton', '[cç]orlu', 'modern karton|eren', 'Modern Karton - Çorlu', 'Tekirdağ', 'Çorlu', null, 'Eren Holding 계열 재생 골판지원지(Çorlu·Zonguldak, 4대) — Zonguldak PM6 65만 t(2025 가동, 2026-07 준공식) 포함 연 약 200만 t.', 'Modern Karton (Eren Holding) - recycled testliner and fluting on four machines at Çorlu (Tekirdağ) and Zonguldak, about 2,000,000 t/yr incl. the 650,000 t Zonguldak PM6 (started 2025, inaugurated 2026-07-10), 100 pct recovered fibre.', 'TR check 2026-10-16: group total on this row. Strength-led grades - low FCC fit.'),
  ('\moyka\M', '[cç]aycuma', 'oyka|oyak', 'OYKA - Çaycuma', 'Zonguldak', 'Çaycuma', null, 'OYAK 계열 일관 크라프트 펄프·제지(Çaycuma) 연 10만 t — Kraft·Kraftliner·포대지·습윤강도지.', 'OYKA (OYAK group), Çaycuma (Zonguldak) - integrated kraft pulp and paper, about 100,000 t/yr kraft paper, kraftliner, Klupak sack paper and wet-strength paper, plus sacks.', 'TR check 2026-10-16: strength-critical - low FCC fit.'),
  ('varaka', 'bal[iı]kesir', 'varaka', 'Varaka Kağıt - Balıkesir', 'Balıkesir', 'Balıkesir', null, '구 SEKA Balıkesir 공장 현대화 — 재생 포장용지 연 30만 t 설계.', 'Varaka Kağıt, Balıkesir - modernised former SEKA mill, recycled packaging paper, 300,000 t/yr design.', 'TR check 2026-10-16: design capacity.'),
  ('\mkmk\M', 'k[uü]tahya', 'kmk', 'KMK Paper - Kütahya', 'Kütahya', 'Kütahya', null, 'Kütahya 재생 포장용지 연 11만 t.', 'KMK Paper, Kütahya - recycled packaging paper, 110,000 t/yr. Near Adaçal (Afyonkarahisar).', 'TR check 2026-10-16: '),
  ('k[iı]van[cç]', 'adana', 'k[iı]van', 'Kıvanç Paper - Adana', 'Adana', 'Adana', null, 'Adana 재생 포장용 판지 신규 PM1(2024 가을, Valmet OCC·초지·자동화).', 'Kıvanç Paper, Adana - recycled packaging board on a new PM1 started autumn 2024 (Valmet OCC line, machine and automation, case study 2026-03).', 'TR check 2026-10-16: capacity not public.'),
  ('hamburger', '[cç]orlu|denizli', 'hamburger|prinzhorn', 'Hamburger Containerboard - Çorlu', 'Tekirdağ', 'Çorlu', null, 'Prinzhorn 계열 Hamburger Containerboard — Çorlu·Denizli 재생 골심지·라이너·특수 포장용지.', 'Hamburger Containerboard (Prinzhorn group), Çorlu and Denizli - recycled fluting, liner and special packaging papers.', 'TR check 2026-10-16: capacity not current - group link to European mills.'),
  ('viking ka[gğ][iı]t', 'alia[gğ]a', 'viking', 'Viking Kağıt - Aliağa', 'İzmir', 'Aliağa', null, 'Yaşar 그룹 Viking 티슈(Aliağa) 연 약 4만 t(과거 4.58만 t) — Lily·Senso·Pufla 등.', 'Viking Kağıt (Yaşar group), Aliağa (İzmir) - toilet tissue, towels, napkins, facial (Lily, Senso, Pufla and others), about 40,000 t/yr (45,800 on an older investor page).', 'TR check 2026-10-16: '),
  ('hayat.*(kimya|tissue|ka[gğ][iı]t)', 'yenik[oö]y|kocaeli', 'hayat', 'Hayat Kimya - Kocaeli (Yeniköy)', 'Kocaeli', 'Yeniköy', null, 'Hayat Kimya 티슈(Papia·Familia·Focus) — Kocaeli Yeniköy·Mersin 고속 Valmet 티슈기.', 'Hayat Kimya - tissue (Papia, Familia, Focus) on high-speed Valmet machines at Yeniköy (Kocaeli) and Mersin, also large plants abroad (Hayat Russia).', 'TR check 2026-10-16: Turkish capacity by site not public.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alkim ka[gğ][iı]t|alkim.*kemalpa', 'kemalpa', 'alkim', 'Alkim Alkali Kimya 계열 인쇄·필기용지 공장(Kemalpaşa, 1998~). Woodfree Offset·복사용지·코팅지 60~220 g/m², 55,000 → 90,000 t 증설 후 약 20% 추가 증산.', 'Alkim Kağıt (Alkim Alkali Kimya group), Kemalpaşa (İzmir) - woodfree offset, A4 and A3 copy and coated printing paper 60-220 g/m2 (mainly 70-80), started 1998 at 55,000 t/yr, expanded to 90,000 t/yr plus about 20 pct more, DCS/QCS controls, 85-90 pct home sales.', 'TR check 2026-10-16: 2026 machine capacity to confirm. +90 232 877 06 06, info@alkimkagit.com.tr.'),
  ('mopak', 'dalaman', 'mopak', '1926년부터 종이사업 Mopak — Dalaman 통합 공장, Kemalpaşa·Taşköprü, 18~500 g/m² 인쇄·사무·기술용지·판지·특수지.', 'Mopak Kağıt (paper since 1926) - integrated mill at Dalaman (Muğla) plus Kemalpaşa (İzmir) and Taşköprü (Kastamonu, specialty): printing, office and technical paper, board, cigarette and other specialty papers, 18-500 g/m2.', 'TR check 2026-10-16: capacity by grade not current. +90 232 877 02 35, mopak@mopak.com.tr.'),
  ('kartonsan', 'kocaeli|ba[sş]iskele|kullar', 'kartonsan', '1967년 설립 백색 코팅판지(Kullar, Başiskele). Duplex·Triplex·Luxtriplex, BM2 연 16만 t(2024 BM1+BM2 24만 t), 국내 코팅판지 약 30%, 회수지 95% 초과.', 'Kartonsan (1967), Kullar, Başiskele (Kocaeli) - coated duplex and triplex board (Normprint, Exprint, Luxtriplex), BM2 160,000 t/yr on the current site (BM1 plus BM2 240,000 t in the 2024 report), about 30 pct of Turkish coated board (2025), over 95 pct recovered fibre.', 'TR check 2026-10-16: current line set to confirm. +90 262 349 61 50.'),
  ('lila ka[gğ][iı]t|\mlila\M', 'ergene|tekirda', 'lila', 'Ergene(Tekirdağ) 티슈 원지 — 4개 라인 연 27.1만 t, 2025 순생산 20.42만 t, 점보롤 수출. Erzurum TM5 연 7만 t+(2027 계획).', 'Lila Kağıt, Ergene (Tekirdağ) - tissue base paper and jumbo rolls, toilet and kitchen towel, four lines 271,000 t/yr, net output about 204,200 t in 2025 (annual report), export-led. Erzurum TM5 over 70,000 t/yr planned for 2027.', 'TR check 2026-10-16: TM5 not counted.'),
  ('akt[uü]l', 'pamukova', 'akt[uü]l', 'Pamukova(Sakarya) 버진 셀룰로오스 티슈(2011~) — 초지 연 21만 t(3라인), 가공 16만 t, Belinno, 60개국 수출.', 'Aktül Kağıt, Pamukova (Sakarya) - tissue on 100 pct virgin cellulose since 2011: 210,000 t/yr on three machines and 160,000 t/yr converting, jumbo rolls and Belinno brand, exports to 60 countries.', 'TR check 2026-10-16: '),
  ('sanipak|eczac[iı]ba[sş][iı].*(t[uü]ketim|consumer)|[iı]pek ka[gğ][iı]t', 'yalova', 'sanipak|eczac|[iı]pek', '구 Eczacıbaşı Consumer Products(İpek Kağıt 계보, 2025-01 사명 변경) — Selpak·Solo·Silen·Marathon, Yalova·Manisa, 2023 PM5 가동 후 연 25만 t.', 'Sanipak (formerly Eczacıbaşı Consumer Products, İpek Kağıt lineage since 1970, renamed 2025-01) - Selpak, Solo, Silen, Marathon tissue at Yalova and Manisa, 250,000 t/yr after PM5 started in 2023 (group figure).', 'TR check 2026-10-16: site split not public - group total kept on this row.'),
  ('kipa[sş]', 's[oö]ke', 'kipa', 'Kipaş Holding Söke 대형 종이·판지 공장(부지 62만 m²) — 연 130만 t, 코팅 Duplex·Triplex·White Top·Krafttop·Fluting·Grey·Coreboard, 70~450 g/m², 회수지.', 'Batı Kipaş Kağıt (Kipaş Holding), Söke (Aydın), 620,000 m2 site - 1,300,000 t/yr coated duplex and triplex, white-top and krafttop testliner, fluting, grey board and coreboard, 70-450 g/m2, almost all recovered fibre.', 'TR check 2026-10-16: FCC only for coated board and white-top lines.'),
  ('tezol|europap', 'torbal', 'tezol|europap', 'Europap Tezol — 탈묵 재생섬유 티슈, Torbalı(İzmir)·Tarsus(Mersin), 4라인 연 13.5만~14.2만 t.', 'Europap Tezol, Torbalı (İzmir) and Tarsus (Mersin) - deinked recycled-fibre tissue on four machines, 142,000 t/yr (135,000 on older pages).', 'TR check 2026-10-16: confirm capacity in investor material.'),
  ('modern karton', '[cç]orlu', 'modern karton|eren', 'Eren Holding 계열 재생 골판지원지(Çorlu·Zonguldak, 4대) — Zonguldak PM6 65만 t(2025 가동, 2026-07 준공식) 포함 연 약 200만 t.', 'Modern Karton (Eren Holding) - recycled testliner and fluting on four machines at Çorlu (Tekirdağ) and Zonguldak, about 2,000,000 t/yr incl. the 650,000 t Zonguldak PM6 (started 2025, inaugurated 2026-07-10), 100 pct recovered fibre.', 'TR check 2026-10-16: group total on this row. Strength-led grades - low FCC fit.'),
  ('\moyka\M', '[cç]aycuma', 'oyka|oyak', 'OYAK 계열 일관 크라프트 펄프·제지(Çaycuma) 연 10만 t — Kraft·Kraftliner·포대지·습윤강도지.', 'OYKA (OYAK group), Çaycuma (Zonguldak) - integrated kraft pulp and paper, about 100,000 t/yr kraft paper, kraftliner, Klupak sack paper and wet-strength paper, plus sacks.', 'TR check 2026-10-16: strength-critical - low FCC fit.'),
  ('varaka', 'bal[iı]kesir', 'varaka', '구 SEKA Balıkesir 공장 현대화 — 재생 포장용지 연 30만 t 설계.', 'Varaka Kağıt, Balıkesir - modernised former SEKA mill, recycled packaging paper, 300,000 t/yr design.', 'TR check 2026-10-16: design capacity.'),
  ('\mkmk\M', 'k[uü]tahya', 'kmk', 'Kütahya 재생 포장용지 연 11만 t.', 'KMK Paper, Kütahya - recycled packaging paper, 110,000 t/yr. Near Adaçal (Afyonkarahisar).', 'TR check 2026-10-16: '),
  ('k[iı]van[cç]', 'adana', 'k[iı]van', 'Adana 재생 포장용 판지 신규 PM1(2024 가을, Valmet OCC·초지·자동화).', 'Kıvanç Paper, Adana - recycled packaging board on a new PM1 started autumn 2024 (Valmet OCC line, machine and automation, case study 2026-03).', 'TR check 2026-10-16: capacity not public.'),
  ('hamburger', '[cç]orlu|denizli', 'hamburger|prinzhorn', 'Prinzhorn 계열 Hamburger Containerboard — Çorlu·Denizli 재생 골심지·라이너·특수 포장용지.', 'Hamburger Containerboard (Prinzhorn group), Çorlu and Denizli - recycled fluting, liner and special packaging papers.', 'TR check 2026-10-16: capacity not current - group link to European mills.'),
  ('viking ka[gğ][iı]t', 'alia[gğ]a', 'viking', 'Yaşar 그룹 Viking 티슈(Aliağa) 연 약 4만 t(과거 4.58만 t) — Lily·Senso·Pufla 등.', 'Viking Kağıt (Yaşar group), Aliağa (İzmir) - toilet tissue, towels, napkins, facial (Lily, Senso, Pufla and others), about 40,000 t/yr (45,800 on an older investor page).', 'TR check 2026-10-16: '),
  ('hayat.*(kimya|tissue|ka[gğ][iı]t)', 'yenik[oö]y|kocaeli', 'hayat', 'Hayat Kimya 티슈(Papia·Familia·Focus) — Kocaeli Yeniköy·Mersin 고속 Valmet 티슈기.', 'Hayat Kimya - tissue (Papia, Familia, Focus) on high-speed Valmet machines at Yeniköy (Kocaeli) and Mersin, also large plants abroad (Hayat Russia).', 'TR check 2026-10-16: Turkish capacity by site not public.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'turkiye_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alkim ka[gğ][iı]t|alkim.*kemalpa', 'kemalpa', 'alkim'),
  ('mopak', 'dalaman', 'mopak'),
  ('kartonsan', 'kocaeli|ba[sş]iskele|kullar', 'kartonsan'),
  ('lila ka[gğ][iı]t|\mlila\M', 'ergene|tekirda', 'lila'),
  ('akt[uü]l', 'pamukova', 'akt[uü]l'),
  ('sanipak|eczac[iı]ba[sş][iı].*(t[uü]ketim|consumer)|[iı]pek ka[gğ][iı]t', 'yalova', 'sanipak|eczac|[iı]pek'),
  ('kipa[sş]', 's[oö]ke', 'kipa'),
  ('tezol|europap', 'torbal', 'tezol|europap'),
  ('modern karton', '[cç]orlu', 'modern karton|eren'),
  ('\moyka\M', '[cç]aycuma', 'oyka|oyak'),
  ('varaka', 'bal[iı]kesir', 'varaka'),
  ('\mkmk\M', 'k[uü]tahya', 'kmk'),
  ('k[iı]van[cç]', 'adana', 'k[iı]van'),
  ('hamburger', '[cç]orlu|denizli', 'hamburger|prinzhorn'),
  ('viking ka[gğ][iı]t', 'alia[gğ]a', 'viking'),
  ('hayat.*(kimya|tissue|ka[gğ][iı]t)', 'yenik[oö]y|kocaeli', 'hayat')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alkim ka[gğ][iı]t|alkim.*kemalpa', 'kemalpa', 'alkim',
   $pj${"owner": "Alkim Alkali Kimya", "priority": 1, "products": "Woodfree offset, copy paper, coated paper", "grades": ["UWF", "Copy paper", "Coated paper"], "capacity": {"value": 90000, "unit": "metric_t", "year": "Company figure (before 20 pct increase)", "source": "alkim.com.tr"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 5 pct - planning only."}, "pitch": "Pulp saving on copy and offset - opacity, strength, retention", "approach": "Lead Turkish account - with Omya Turkey or Mikron'S GCC.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mopak', 'dalaman', 'mopak',
   $pj${"owner": "Mopak", "priority": 2, "products": "Printing, office, technical paper, board, specialty", "grades": ["UWF", "Board", "Specialty paper"], "approach": "Trial on office paper and white board separately.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kartonsan', 'kocaeli|ba[sş]iskele|kullar', 'kartonsan',
   $pj${"owner": "Kartonsan", "priority": 3, "products": "Coated duplex and triplex board", "grades": ["Coated board"], "capacity": {"value": 160000, "unit": "metric_t", "year": "Company site (BM2)", "source": "kartonsan.com.tr"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 5 pct - ply-level only."}, "approach": "Top or under ply trial - ply bond, stiffness, print.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lila ka[gğ][iı]t|\mlila\M', 'ergene|tekirda', 'lila',
   $pj${"owner": "Lila Group", "priority": 4, "products": "Tissue jumbo rolls, toilet tissue, towels", "grades": ["Tissue"], "machines": 4, "capacity": {"value": 271000, "unit": "metric_t", "year": "Company (4 lines)", "source": "lilakagit.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 5 pct."}, "approach": "Jumbo-roll tissue trial - tensile, softness, absorbency, dust.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('akt[uü]l', 'pamukova', 'akt[uü]l',
   $pj${"owner": "Aktül", "priority": 5, "products": "Tissue jumbo rolls, consumer tissue", "grades": ["Tissue"], "machines": 3, "capacity": {"value": 210000, "unit": "metric_t", "year": "Company figure", "source": "aktulkagit.com.tr"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 5 pct."}, "approach": "Virgin-pulp saving trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sanipak|eczac[iı]ba[sş][iı].*(t[uü]ketim|consumer)|[iı]pek ka[gğ][iı]t', 'yalova', 'sanipak|eczac|[iı]pek',
   $pj${"owner": "Eczacıbaşı", "priority": 6, "products": "Consumer tissue", "grades": ["Tissue"], "capacity_split": [{"label": "Sanipak total (2023)", "value_t": 250000}], "approach": "Premium tissue - softness and dust critical.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kipa[sş]', 's[oö]ke', 'kipa',
   $pj${"owner": "Kipaş Holding", "priority": 7, "products": "Coated board, white-top testliner, fluting", "grades": ["Coated board", "White-top liner", "Medium"], "capacity": {"value": 1300000, "unit": "metric_t", "year": "Company figure", "source": "kipas.com.tr"}, "approach": "White-top and coated board trial first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tezol|europap', 'torbal', 'tezol|europap',
   $pj${"owner": "Europap Tezol", "priority": 8, "products": "Recycled tissue", "grades": ["Tissue"], "capacity": {"value": 142000, "unit": "metric_t", "year": "Company site", "source": "tezol.com.tr"}, "approach": "Recycled tissue - ash, drainage, strength.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('modern karton', '[cç]orlu', 'modern karton|eren',
   $pj${"owner": "Eren Holding", "products": "Testliner, fluting", "grades": ["Testliner", "Medium"], "capacity": {"value": 2000000, "unit": "metric_t", "year": "Group (Çorlu + Zonguldak)", "source": "erenholding.com.tr"}, "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\moyka\M', '[cç]aycuma', 'oyka|oyak',
   $pj${"owner": "OYAK", "products": "Kraft, kraftliner, sack paper", "grades": ["Sack kraft", "Kraftliner"], "capacity": {"value": 100000, "unit": "metric_t", "year": "Company figure", "source": "oyka.com.tr"}, "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('varaka', 'bal[iı]kesir', 'varaka',
   $pj${"owner": "Varaka", "products": "Recycled packaging paper", "grades": ["Testliner", "Medium"], "capacity": {"value": 300000, "unit": "metric_t", "year": "Design", "source": "varaka.com.tr"}, "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mkmk\M', 'k[uü]tahya', 'kmk',
   $pj${"owner": "KMK", "products": "Recycled packaging paper", "grades": ["Testliner", "Medium"], "capacity": {"value": 110000, "unit": "metric_t", "year": "Company figure", "source": "kmk.com.tr"}, "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('k[iı]van[cç]', 'adana', 'k[iı]van',
   $pj${"owner": "Kıvanç", "products": "Recycled packaging board", "grades": ["Testliner"], "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hamburger', '[cç]orlu|denizli', 'hamburger|prinzhorn',
   $pj${"owner": "Prinzhorn", "products": "Recycled fluting, liner", "grades": ["Medium", "Testliner"], "approach": "No priority - strength-led or later tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('viking ka[gğ][iı]t', 'alia[gğ]a', 'viking',
   $pj${"owner": "Yaşar Holding", "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 40000, "unit": "metric_t", "year": "Company site", "source": "viking.com.tr"}, "approach": "No priority - strength-led or later tissue.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hayat.*(kimya|tissue|ka[gğ][iı]t)', 'yenik[oö]y|kocaeli', 'hayat',
   $pj${"owner": "Hayat Kimya", "products": "Tissue", "grades": ["Tissue"], "approach": "No priority - strength-led or later tissue.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TR', 'Türkiye', 'high',
   $cm$5.7 Mt paper and board - Alkim and Mopak printing paper, Kartonsan coated board, Lila, Aktül, Sanipak tissue - Adaçal PCC, Esen slurry, Mikron'S paper GCC$cm$,
   $cm$Türkiye makes about 5.7 Mt paper and board. FCC-fit mills: Alkim (Kemalpaşa) and Mopak (Dalaman) printing paper, Kartonsan (160 kt coated board), Lila (271 kt), Aktül (210 kt), Sanipak (250 kt) and Europap Tezol (142 kt) tissue, Batı Kipaş coated and white-top board (1.3 Mt). Large recycled liner at Modern Karton (2 Mt), Varaka, KMK, Kıvanç, Hamburger. Fillers: Omya Turkey (4 plants, licensee), Adaçal (independent PCC, Emirdağ), Esen Mikronize (700 kt GCC plus 100 kt slurry), Mikron'S (paper TURKCARB with approvals), Aydın (AY 103 coating, AY 106 wet-end), Niğtaş (pilot plant).$cm$,
   $cm${"fillers": "PCC: Adaçal Emirdağ. GCC: Omya Turkey (Çanakkale, İzmir, İzmit, Kırşehir), Esen Mikronize (700 kt dry, 100 kt slurry), Mikron'S (TURKCARB paper grades), Aydın Madencilik (AY 103, AY 106), Niğtaş / Mikrokal, Ottocarb. Not added: PERO Minerals.", "mills": "Printing: Alkim Kemalpaşa, Mopak Dalaman. Coated board: Kartonsan, Batı Kipaş. Tissue: Lila, Aktül, Sanipak, Europap Tezol, Viking, Hayat. Recycled liner and kraft: Modern Karton, Varaka, KMK, Kıvanç, Hamburger, OYKA.", "strategy": "Alkim plus Omya Turkey or Mikron'S (printing), Kartonsan plus Esen Mikronize slurry (board), Lila or Aktül plus a regional GCC (tissue). Adaçal as independent PCC licence partner.", "risks": "Omya competing tech, recycled liner strength limits.", "next_steps": ["Approach Esen Mikronize on slurry co-production", "Propose a copy-paper trial to Alkim"], "key_numbers": [{"label": "Paper and board output", "value": "about 5.7 Mt (SKSV)"}, {"label": "Modern Karton", "value": "2 Mt after PM6 (2026-07)"}, {"label": "Report scenario", "value": "43,650 t FCC (5 pct of 873 kt FCC-fit lines)"}], "files": ["seed_20261016zb_turkiye_mills_fillers"]}$cm$::jsonb,
   $cm$종이·판지 570만 t — Alkim·Mopak 인쇄용지, Kartonsan 코팅판지, Lila·Aktül·Sanipak 티슈 — Adaçal PCC, Esen 슬러리, Mikron'S 제지용 GCC$cm$,
   $cm$튀르키예 종이·판지 약 570만 t. FCC 적합: Alkim(Kemalpaşa)·Mopak(Dalaman) 인쇄용지, Kartonsan(코팅판지 16만 t), 티슈 Lila(27.1만)·Aktül(21만)·Sanipak(25만)·Tezol(14.2만), Batı Kipaş 코팅·화이트탑(130만 t). 대형 재생 라이너 Modern Karton(200만 t) 등. 충전제: Omya Turkey(4개 공장, 라이선시), Adaçal(독립 PCC), Esen Mikronize(GCC 70만+슬러리 10만 t), Mikron'S(TURKCARB 제지 승인), Aydın(AY 103·106), Niğtaş(파일럿).$cm$,
   21825, 43650,
   $cm$Alkim·Kartonsan·Lila·Aktül·Tezol 87.3만 t × FCC 2.5~5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('alkim ka[gğ][iı]t|alkim.*kemalpa', 'kemalpa', 'alkim'),
  ('mopak', 'dalaman', 'mopak'),
  ('kartonsan', 'kocaeli|ba[sş]iskele|kullar', 'kartonsan'),
  ('lila ka[gğ][iı]t|\mlila\M', 'ergene|tekirda', 'lila'),
  ('akt[uü]l', 'pamukova', 'akt[uü]l'),
  ('sanipak|eczac[iı]ba[sş][iı].*(t[uü]ketim|consumer)|[iı]pek ka[gğ][iı]t', 'yalova', 'sanipak|eczac|[iı]pek'),
  ('kipa[sş]', 's[oö]ke', 'kipa'),
  ('tezol|europap', 'torbal', 'tezol|europap'),
  ('modern karton', '[cç]orlu', 'modern karton|eren'),
  ('\moyka\M', '[cç]aycuma', 'oyka|oyak'),
  ('varaka', 'bal[iı]kesir', 'varaka'),
  ('\mkmk\M', 'k[uü]tahya', 'kmk'),
  ('k[iı]van[cç]', 'adana', 'k[iı]van'),
  ('hamburger', '[cç]orlu|denizli', 'hamburger|prinzhorn'),
  ('viking ka[gğ][iı]t', 'alia[gğ]a', 'viking'),
  ('hayat.*(kimya|tissue|ka[gğ][iı]t)', 'yenik[oö]y|kocaeli', 'hayat')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'turkiye_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'turkiye_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(turk|t[uü]rk)' or p.party_name ~* 'ada[cç]al' or p.party_name ~* 'mikron''?s|turkcarb' or p.party_name ~* 'esen mikronize' or p.party_name ~* 'ni[gğ]ta[sş]|mikrokal' or p.party_name ~* 'ayd[iı]n madencilik' or p.party_name ~* 'ottocarb')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    