-- ============================================================
-- seed_20261016zv_finland_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Finland update (reports 2026-10-16). Existing FI rows likely.
-- Nordkalk guard is Finland-specific so it does not hit the Swedish row.
-- 1) Fillers if missing (5): Suomen Karbonaatti, Nordkalk Finland, SMI
--    Nordic (satellite PCC), SCHAEFER KALK Finland (on-site PCC), Omya Finland.
-- 2) Mills if missing (13) + plant blocks, priority 1-10, plus Jujo,
--    UPM Rauma, UPM Tervasaari (no priority). Context (8) incl. Kaukas and
--    Tako closures.
-- 3) Supply links (3, active, host to confirm): SMI -> Metsä Board
--    Äänekoski, SMI -> delfort Tervakoski, SCHAEFER KALK -> UPM Kymi.
-- 4) app.country_markets FI row (priority high).
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
           v.party_name, 'FI', v.region, v.city, v.website, 'active', 'finland_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('suomen karbonaatti', 'Suomen Karbonaatti - Lappeenranta (Nordkalk group)', 'South Karelia', 'Lappeenranta', null, 'Nordkalk 자회사 — Lappeenranta 고백색 대리석질 원료, 습식 분쇄·슬러리·부유선별 제지용 GCC(인쇄용지·고급지·판지). 2011 핀란드 국내 GCC 생산 2사 중 1곳.', 'Suomen Karbonaatti Oy (Nordkalk subsidiary), Lappeenranta - paper GCC of high-white marble: wet grinding, slurry and flotation, for printing, fine paper and board. One of the two Finnish GCC makers in 2011 (with Omya). Finnish wet GCC use was about 1.2 Mt dry in 2011.', 'FI check 2026-10-16: current output not public. Wet GCC slurry line - FCC co-production candidate (GCC side).'),
  ('nordkalk.*(lappeenranta|finland|oyj)', 'Nordkalk - Lappeenranta (Finland)', 'South Karelia', 'Lappeenranta', null, 'Nordkalk 핀란드 — 석회석·생석회(QL, PCC 제조용)·GCC 원료.', 'Nordkalk (Finland) - limestone, quicklime (Nordkalk QL for PCC making) and GCC raw material, parent of Suomen Karbonaatti.', 'FI check 2026-10-16: PCC raw-material supplier, not a PCC maker. Swedish site is a separate row (Köping).'),
  ('(specialty minerals|minerals technologies).*(nordic|finland|[aä][aä]nekoski|tervakoski)', 'Specialty Minerals Nordic - Äänekoski and Tervakoski (satellite PCC)', 'Central Finland', 'Äänekoski', null, 'MTI 핀란드 법인 — Äänekoski 위성 PCC(1993, Metsä Fibre 바이오제품 공장 배기 CO2 사용)·Tervakoski 위성 PCC(SEC 공시). 2025 매출 약 1,000만 유로·18명.', 'Specialty Minerals Nordic Oy Ab (Minerals Technologies), Sarvelantie 1, Äänekoski - satellite PCC at Äänekoski since 1993 using purified CO2 of the Metsä Fibre bioproduct mill flue gas, filler and coating PCC, and a satellite at Tervakoski (MTI SEC filings). 2025 sales about EUR 10 m, 18 staff.', 'FI check 2026-10-16: +358 2 284 4200, Business ID 0928926-9. SMI is the MBG tissue-track partner (NDA).'),
  ('schaefer kalk.*(finland|kuusankoski)', 'SCHAEFER KALK Finland - Kuusankoski (satellite PCC)', 'Kymenlaakso', 'Kuusankoski', null, 'SCHAEFER KALK(독일) 핀란드 현장 PCC 공장(Selluntie 1, Kuusankoski) — 석회유 탄산화, 입자·결정 조절.', 'SCHAEFER KALK Finland Oy (SCHAEFER KALK, Germany), Selluntie 1, Kuusankoski - on-site PCC plant (milk of lime carbonated with CO2, particle size and crystal form controlled), listed on the company site. Kuusankoski is the UPM Kymi mill location.', 'FI check 2026-10-16: capacity not public. Independent PCC maker - FCC licence candidate.'),
  ('omya.*(finland|oy\M|f[oö]rby|salo)', 'Omya Finland - Förby (Salo)', 'Southwest Finland', 'Salo', null, 'Omya Oy Förby/Salo GCC + Omya PCC (Finland) PCC 생산 이력(2011 자료).', 'Omya Oy - GCC at Förby / Salo and Omya PCC (Finland) PCC production recorded in 2011 data.', 'FI check 2026-10-16: 2026 status to confirm. Royalty licensee at Omya HQ level - FiberLean competes with FCC. Older EU records also list PCC at Lappeenranta, Myllykoski and Imatra (2006).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%FI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('suomen karbonaatti', 'Suomen Karbonaatti - Lappeenranta (Nordkalk group)', 'South Karelia', 'Lappeenranta', null, 'Nordkalk 자회사 — Lappeenranta 고백색 대리석질 원료, 습식 분쇄·슬러리·부유선별 제지용 GCC(인쇄용지·고급지·판지). 2011 핀란드 국내 GCC 생산 2사 중 1곳.', 'Suomen Karbonaatti Oy (Nordkalk subsidiary), Lappeenranta - paper GCC of high-white marble: wet grinding, slurry and flotation, for printing, fine paper and board. One of the two Finnish GCC makers in 2011 (with Omya). Finnish wet GCC use was about 1.2 Mt dry in 2011.', 'FI check 2026-10-16: current output not public. Wet GCC slurry line - FCC co-production candidate (GCC side).'),
  ('nordkalk.*(lappeenranta|finland|oyj)', 'Nordkalk - Lappeenranta (Finland)', 'South Karelia', 'Lappeenranta', null, 'Nordkalk 핀란드 — 석회석·생석회(QL, PCC 제조용)·GCC 원료.', 'Nordkalk (Finland) - limestone, quicklime (Nordkalk QL for PCC making) and GCC raw material, parent of Suomen Karbonaatti.', 'FI check 2026-10-16: PCC raw-material supplier, not a PCC maker. Swedish site is a separate row (Köping).'),
  ('(specialty minerals|minerals technologies).*(nordic|finland|[aä][aä]nekoski|tervakoski)', 'Specialty Minerals Nordic - Äänekoski and Tervakoski (satellite PCC)', 'Central Finland', 'Äänekoski', null, 'MTI 핀란드 법인 — Äänekoski 위성 PCC(1993, Metsä Fibre 바이오제품 공장 배기 CO2 사용)·Tervakoski 위성 PCC(SEC 공시). 2025 매출 약 1,000만 유로·18명.', 'Specialty Minerals Nordic Oy Ab (Minerals Technologies), Sarvelantie 1, Äänekoski - satellite PCC at Äänekoski since 1993 using purified CO2 of the Metsä Fibre bioproduct mill flue gas, filler and coating PCC, and a satellite at Tervakoski (MTI SEC filings). 2025 sales about EUR 10 m, 18 staff.', 'FI check 2026-10-16: +358 2 284 4200, Business ID 0928926-9. SMI is the MBG tissue-track partner (NDA).'),
  ('schaefer kalk.*(finland|kuusankoski)', 'SCHAEFER KALK Finland - Kuusankoski (satellite PCC)', 'Kymenlaakso', 'Kuusankoski', null, 'SCHAEFER KALK(독일) 핀란드 현장 PCC 공장(Selluntie 1, Kuusankoski) — 석회유 탄산화, 입자·결정 조절.', 'SCHAEFER KALK Finland Oy (SCHAEFER KALK, Germany), Selluntie 1, Kuusankoski - on-site PCC plant (milk of lime carbonated with CO2, particle size and crystal form controlled), listed on the company site. Kuusankoski is the UPM Kymi mill location.', 'FI check 2026-10-16: capacity not public. Independent PCC maker - FCC licence candidate.'),
  ('omya.*(finland|oy\M|f[oö]rby|salo)', 'Omya Finland - Förby (Salo)', 'Southwest Finland', 'Salo', null, 'Omya Oy Förby/Salo GCC + Omya PCC (Finland) PCC 생산 이력(2011 자료).', 'Omya Oy - GCC at Förby / Salo and Omya PCC (Finland) PCC production recorded in 2011 data.', 'FI check 2026-10-16: 2026 status to confirm. Royalty licensee at Omya HQ level - FiberLean competes with FCC. Older EU records also list PCC at Lappeenranta, Myllykoski and Imatra (2006).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'finland_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Suomen Karbonaatti - Lappeenranta (Nordkalk group)', 'GCC producer', 'Paper GCC slurry - co-production candidate', 'merchant', 'B', 'gcc'),
  ('Nordkalk - Lappeenranta (Finland)', 'Lime and limestone producer', 'PCC-grade quicklime and GCC feed', 'merchant', 'C', 'pcc'),
  ('Specialty Minerals Nordic - Äänekoski and Tervakoski (satellite PCC)', 'PCC producer', 'SMI Finnish satellites - partner route', 'satellite', 'B', 'pcc'),
  ('SCHAEFER KALK Finland - Kuusankoski (satellite PCC)', 'PCC producer', 'Independent on-site PCC - licence candidate', 'satellite', 'B', 'pcc'),
  ('Omya Finland - Förby (Salo)', 'GCC and PCC supplier', 'Omya Finland - licensee group, sites to confirm', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'finland_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'FI', v.region, v.city, v.website, 'active', 'finland_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm', 'UPM Kymi - Kuusankoski', 'Kymenlaakso', 'Kuusankoski', null, 'UPM Kymi(Kouvola Kuusankoski) — 펄프·인쇄용지, 신규 시트 커터. 같은 지역 SCHAEFER KALK 현장 PCC.', 'UPM Kymi mill, Kuusankoski (Kouvola) - pulp and printing papers (new sheeter installed). SCHAEFER KALK on-site PCC is at the same location.', 'FI check 2026-10-16: capacity not public here.'),
  ('j[aä]ms[aä]nkoski', 'j[aä]ms[aä]', 'upm', 'UPM Jämsänkoski - Jämsä', 'Central Finland', 'Jämsä', null, 'UPM Jämsänkoski 인쇄용지·특수지.', 'UPM Jämsänkoski, Jämsä - printing and specialty papers.', 'FI check 2026-10-16: line status to confirm.'),
  ('mets[aä] board.*kyro|\mkyro\M', 'kyr[oö]skoski', 'mets[aä]', 'Metsä Board Kyro - Kyröskoski', 'Pirkanmaa', 'Kyröskoski', null, 'Metsä Board Kyro FBB — 2025-06 Tako 생산 이전.', 'Metsä Board Kyro mill, Kyröskoski - folding boxboard, took over Tako products after Tako closed 2025-06-17.', 'FI check 2026-10-16: capacity not public here.'),
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]', 'Metsä Board Äänekoski', 'Central Finland', 'Äänekoski', null, 'Metsä Board Äänekoski FBB — SMI 위성 PCC 같은 단지.', 'Metsä Board Äänekoski - folding boxboard, in the same industrial site as the SMI satellite PCC and the Metsä Fibre bioproduct mill.', 'FI check 2026-10-16: capacity not public here.'),
  ('simpele', 'simpele', 'mets[aä]', 'Metsä Board Simpele', 'South Karelia', 'Simpele', null, 'Metsä Board Simpele FBB(현대화).', 'Metsä Board Simpele - folding boxboard (modernisation announced).', 'FI check 2026-10-16: capacity not public here.'),
  ('stora enso.*imatra|imatra mills', 'imatra', 'stora enso', 'Stora Enso Imatra Mills', 'South Karelia', 'Imatra', null, 'Stora Enso Imatra 식품·액체 포장용 판지.', 'Stora Enso Imatra Mills - food service and liquid packaging board.', 'FI check 2026-10-16: food-contact rules.'),
  ('m[aä]ntt[aä]', 'm[aä]ntt[aä]', 'mets[aä]', 'Metsä Tissue Mänttä', 'Pirkanmaa', 'Mänttä', null, 'Metsä Tissue Mänttä 티슈 — 재생섬유 생산 종료·티슈기 1대 폐쇄 결정, 버진 펄프 티슈 중심.', 'Metsä Tissue Mänttä - tissue, recycled-fibre production ended and one tissue machine closed, now virgin-pulp tissue (Lambi, Serla, Katrin).', 'FI check 2026-10-16: capacity not public here.'),
  ('kotkamills', 'kotka', '\mmm\M|kotkamills|mayr', 'MM Kotkamills - Kotka', 'Kymenlaakso', 'Kotka', null, 'MM Group 계열 Kotkamills — 식품포장 판지·배리어 판지·크라프트지(3,000만 유로 투자).', 'MM Kotkamills (MM Group), Kotka - food packaging board, barrier board and kraft paper (EUR 30 m investment completed).', 'FI check 2026-10-16: food-contact and barrier checks.'),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort', 'delfort Tervakoski', 'Kanta-Häme', 'Tervakoski', null, 'delfort Tervakoski 특수지 — 2026-02 대형 히트펌프·전극보일러로 무화석 연료 생산. SMI 위성 PCC 공시 지역.', 'delfort Tervakoski - specialty and functional papers, fossil-free energy by a large heat pump and electrode boiler (2026-02). Tervakoski also hosts an SMI satellite PCC (MTI filings).', 'FI check 2026-10-16: capacity not public here.'),
  ('pankaboard', 'pankakoski|lieksa', 'pankaboard', 'Pankaboard - Pankakoski', 'North Karelia', 'Lieksa', null, 'Pankaboard 특수 판지·고급 포장 판지(Pankakoski, Lieksa).', 'Pankaboard, Pankakoski (Lieksa) - specialty and premium packaging board.', 'FI check 2026-10-16: capacity not public here.'),
  ('jujo', 'kauttua|eura', 'jujo', 'Jujo Thermal - Kauttua', 'Satakunta', 'Eura', null, 'Jujo Thermal 감열지·특수지(Kauttua, Eura).', 'Jujo Thermal, Kauttua (Eura) - thermal and specialty papers.', 'FI check 2026-10-16: base-paper surface quality critical.'),
  ('upm.*rauma|\mrauma\M', 'rauma', 'upm', 'UPM Rauma', 'Satakunta', 'Rauma', null, 'UPM Rauma 인쇄용지.', 'UPM Rauma - printing papers.', 'FI check 2026-10-16: line status to confirm.'),
  ('tervasaari', 'valkeakoski', 'upm', 'UPM Tervasaari - Valkeakoski', 'Pirkanmaa', 'Valkeakoski', null, 'UPM Tervasaari 특수지·라벨 원지.', 'UPM Tervasaari, Valkeakoski - specialty and label base papers.', 'FI check 2026-10-16: capacity not public here.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%FI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm', 'UPM Kymi(Kouvola Kuusankoski) — 펄프·인쇄용지, 신규 시트 커터. 같은 지역 SCHAEFER KALK 현장 PCC.', 'UPM Kymi mill, Kuusankoski (Kouvola) - pulp and printing papers (new sheeter installed). SCHAEFER KALK on-site PCC is at the same location.', 'FI check 2026-10-16: capacity not public here.'),
  ('j[aä]ms[aä]nkoski', 'j[aä]ms[aä]', 'upm', 'UPM Jämsänkoski 인쇄용지·특수지.', 'UPM Jämsänkoski, Jämsä - printing and specialty papers.', 'FI check 2026-10-16: line status to confirm.'),
  ('mets[aä] board.*kyro|\mkyro\M', 'kyr[oö]skoski', 'mets[aä]', 'Metsä Board Kyro FBB — 2025-06 Tako 생산 이전.', 'Metsä Board Kyro mill, Kyröskoski - folding boxboard, took over Tako products after Tako closed 2025-06-17.', 'FI check 2026-10-16: capacity not public here.'),
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]', 'Metsä Board Äänekoski FBB — SMI 위성 PCC 같은 단지.', 'Metsä Board Äänekoski - folding boxboard, in the same industrial site as the SMI satellite PCC and the Metsä Fibre bioproduct mill.', 'FI check 2026-10-16: capacity not public here.'),
  ('simpele', 'simpele', 'mets[aä]', 'Metsä Board Simpele FBB(현대화).', 'Metsä Board Simpele - folding boxboard (modernisation announced).', 'FI check 2026-10-16: capacity not public here.'),
  ('stora enso.*imatra|imatra mills', 'imatra', 'stora enso', 'Stora Enso Imatra 식품·액체 포장용 판지.', 'Stora Enso Imatra Mills - food service and liquid packaging board.', 'FI check 2026-10-16: food-contact rules.'),
  ('m[aä]ntt[aä]', 'm[aä]ntt[aä]', 'mets[aä]', 'Metsä Tissue Mänttä 티슈 — 재생섬유 생산 종료·티슈기 1대 폐쇄 결정, 버진 펄프 티슈 중심.', 'Metsä Tissue Mänttä - tissue, recycled-fibre production ended and one tissue machine closed, now virgin-pulp tissue (Lambi, Serla, Katrin).', 'FI check 2026-10-16: capacity not public here.'),
  ('kotkamills', 'kotka', '\mmm\M|kotkamills|mayr', 'MM Group 계열 Kotkamills — 식품포장 판지·배리어 판지·크라프트지(3,000만 유로 투자).', 'MM Kotkamills (MM Group), Kotka - food packaging board, barrier board and kraft paper (EUR 30 m investment completed).', 'FI check 2026-10-16: food-contact and barrier checks.'),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort', 'delfort Tervakoski 특수지 — 2026-02 대형 히트펌프·전극보일러로 무화석 연료 생산. SMI 위성 PCC 공시 지역.', 'delfort Tervakoski - specialty and functional papers, fossil-free energy by a large heat pump and electrode boiler (2026-02). Tervakoski also hosts an SMI satellite PCC (MTI filings).', 'FI check 2026-10-16: capacity not public here.'),
  ('pankaboard', 'pankakoski|lieksa', 'pankaboard', 'Pankaboard 특수 판지·고급 포장 판지(Pankakoski, Lieksa).', 'Pankaboard, Pankakoski (Lieksa) - specialty and premium packaging board.', 'FI check 2026-10-16: capacity not public here.'),
  ('jujo', 'kauttua|eura', 'jujo', 'Jujo Thermal 감열지·특수지(Kauttua, Eura).', 'Jujo Thermal, Kauttua (Eura) - thermal and specialty papers.', 'FI check 2026-10-16: base-paper surface quality critical.'),
  ('upm.*rauma|\mrauma\M', 'rauma', 'upm', 'UPM Rauma 인쇄용지.', 'UPM Rauma - printing papers.', 'FI check 2026-10-16: line status to confirm.'),
  ('tervasaari', 'valkeakoski', 'upm', 'UPM Tervasaari 특수지·라벨 원지.', 'UPM Tervasaari, Valkeakoski - specialty and label base papers.', 'FI check 2026-10-16: capacity not public here.'),
  ('kaukas', null, 'kaukas', null, null, 'FI check 2026-10-16: Kaukas paper production ended 2025-10, pulp line paused about 6 weeks starting 2026-08 - context only.'),
  ('\mtako\M', null, '\mtako\M', null, null, 'FI check 2026-10-16: Tako board mill closed 2025-06-17, products moved to Kyro - context only.'),
  ('mets[aä] board.*kemi|\mkemi\M', null, 'mets[aä] board.*kemi|\mkemi\M', null, null, 'FI check 2026-10-16: Kemi white-top kraftliner - context only.'),
  ('stora enso.*oulu', null, 'stora enso.*oulu', null, null, 'FI check 2026-10-16: Oulu packaging board (former paper mill) - context only.'),
  ('stora enso.*varkaus|varkaus', null, 'stora enso.*varkaus|varkaus', null, null, 'FI check 2026-10-16: Varkaus packaging base paper - context only.'),
  ('heinola', null, 'heinola', null, null, 'FI check 2026-10-16: Heinola semi-chemical fluting - context only.'),
  ('anjala', null, 'anjala', null, null, 'FI check 2026-10-16: Anjala - restructured - context only.'),
  ('mondi.*(finland|powerflute)', null, 'mondi.*(finland|powerflute)', null, null, 'FI check 2026-10-16: Kraft and packaging paper, Finland - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'finland_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm'),
  ('j[aä]ms[aä]nkoski', 'j[aä]ms[aä]', 'upm'),
  ('mets[aä] board.*kyro|\mkyro\M', 'kyr[oö]skoski', 'mets[aä]'),
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]'),
  ('simpele', 'simpele', 'mets[aä]'),
  ('stora enso.*imatra|imatra mills', 'imatra', 'stora enso'),
  ('m[aä]ntt[aä]', 'm[aä]ntt[aä]', 'mets[aä]'),
  ('kotkamills', 'kotka', '\mmm\M|kotkamills|mayr'),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort'),
  ('pankaboard', 'pankakoski|lieksa', 'pankaboard'),
  ('jujo', 'kauttua|eura', 'jujo'),
  ('upm.*rauma|\mrauma\M', 'rauma', 'upm'),
  ('tervasaari', 'valkeakoski', 'upm'),
  ('kaukas', null, 'kaukas'),
  ('\mtako\M', null, '\mtako\M'),
  ('mets[aä] board.*kemi|\mkemi\M', null, 'mets[aä] board.*kemi|\mkemi\M'),
  ('stora enso.*oulu', null, 'stora enso.*oulu'),
  ('stora enso.*varkaus|varkaus', null, 'stora enso.*varkaus|varkaus'),
  ('heinola', null, 'heinola'),
  ('anjala', null, 'anjala'),
  ('mondi.*(finland|powerflute)', null, 'mondi.*(finland|powerflute)')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm',
   $pj${"owner": "UPM", "priority": 1, "products": "Printing paper, pulp", "grades": ["Printing paper", "Coated paper"], "pitch": "UPM + SCHAEFER KALK + MBG trial", "approach": "Lead Finnish account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('j[aä]ms[aä]nkoski', 'j[aä]ms[aä]', 'upm',
   $pj${"owner": "UPM", "priority": 2, "products": "Printing and specialty paper", "grades": ["Printing paper", "Specialty paper"], "approach": "Second UPM site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mets[aä] board.*kyro|\mkyro\M', 'kyr[oö]skoski', 'mets[aä]',
   $pj${"owner": "Metsä Group", "priority": 3, "products": "Folding boxboard", "grades": ["FBB"], "approach": "Ply-level fibre saving with bulk kept.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]',
   $pj${"owner": "Metsä Group", "priority": 4, "products": "Folding boxboard", "grades": ["FBB"], "pitch": "Metsä + SMI + MBG trial on site", "approach": "SMI partner route.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('simpele', 'simpele', 'mets[aä]',
   $pj${"owner": "Metsä Group", "priority": 5, "products": "Folding boxboard", "grades": ["FBB"], "approach": "After Kyro and Äänekoski.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*imatra|imatra mills', 'imatra', 'stora enso',
   $pj${"owner": "Stora Enso", "priority": 6, "products": "Food service and liquid packaging board", "grades": ["FBB", "LPB"], "approach": "Non-food-contact ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('m[aä]ntt[aä]', 'm[aä]ntt[aä]', 'mets[aä]',
   $pj${"owner": "Metsä Group", "priority": 7, "products": "Tissue", "grades": ["Tissue"], "approach": "1-5 pct virgin tissue trial - link with Metsä Sweden.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kotkamills', 'kotka', '\mmm\M|kotkamills|mayr',
   $pj${"owner": "MM Group", "priority": 8, "products": "Food packaging and barrier board", "grades": ["FBB"], "approach": "Opacity and coating fit tests.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort',
   $pj${"owner": "delfort", "priority": 9, "products": "Specialty and functional paper", "grades": ["Specialty paper"], "approach": "Co-development - SMI partner route.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pankaboard', 'pankakoski|lieksa', 'pankaboard',
   $pj${"owner": "Pankaboard", "priority": 10, "products": "Specialty board", "grades": ["Board"], "approach": "Stiffness and bulk kept.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jujo', 'kauttua|eura', 'jujo',
   $pj${"owner": "Jujo Thermal", "products": "Thermal paper", "grades": ["Specialty paper"], "approach": "Base-paper trial later.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('upm.*rauma|\mrauma\M', 'rauma', 'upm',
   $pj${"owner": "UPM", "products": "Printing paper", "grades": ["Printing paper"], "approach": "Status first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tervasaari', 'valkeakoski', 'upm',
   $pj${"owner": "UPM", "products": "Label and specialty paper", "grades": ["Specialty paper"], "approach": "Specialty trial later.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kaukas', null, 'kaukas',
   $pj${"owner": "UPM", "products": "Kaukas paper production ended 2025-10, pulp line paused about 6 weeks starting 2026-08", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mtako\M', null, '\mtako\M',
   $pj${"owner": "Metsä Group", "products": "Tako board mill closed 2025-06-17, products moved to Kyro", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mets[aä] board.*kemi|\mkemi\M', null, 'mets[aä] board.*kemi|\mkemi\M',
   $pj${"owner": "Metsä Group", "products": "Kemi white-top kraftliner", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*oulu', null, 'stora enso.*oulu',
   $pj${"owner": "Stora Enso", "products": "Oulu packaging board (former paper mill)", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*varkaus|varkaus', null, 'stora enso.*varkaus|varkaus',
   $pj${"owner": "Stora Enso", "products": "Varkaus packaging base paper", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('heinola', null, 'heinola',
   $pj${"owner": "Stora Enso", "products": "Heinola semi-chemical fluting", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('anjala', null, 'anjala',
   $pj${"owner": "Stora Enso", "products": "Anjala - restructured", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mondi.*(finland|powerflute)', null, 'mondi.*(finland|powerflute)',
   $pj${"owner": "Mondi", "products": "Kraft and packaging paper, Finland", "approach": "Closed, liner or restructured.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'finland_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]', '(specialty minerals|minerals technologies).*(nordic|finland|[aä][aä]nekoski|tervakoski)', 'active', 'medium', '1993-01-01'::date, null::date, null, 'satellite PCC in the Äänekoski mill site', 'MTI SEC filings, Metsä Fibre 2025', 'SMI satellite PCC at Äänekoski since 1993 - host line to confirm'),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort', '(specialty minerals|minerals technologies).*(nordic|finland|[aä][aä]nekoski|tervakoski)', 'active', 'medium', null::date, null::date, null, 'satellite PCC at the mill', 'MTI SEC filings', 'SMI satellite PCC at Tervakoski - delfort host to confirm'),
  ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm', 'schaefer kalk.*(finland|kuusankoski)', 'active', 'medium', null::date, null::date, null, 'on-site PCC at the mill site', 'SCHAEFER KALK site list', 'SCHAEFER KALK on-site PCC at Kuusankoski - UPM Kymi host to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'FI', 'Finland', 'high',
   $cm$UPM, Metsä Board, Stora Enso, Metsä Tissue - satellite PCC by SMI (Äänekoski, Tervakoski) and SCHAEFER KALK (Kuusankoski), GCC slurry by Suomen Karbonaatti$cm$,
   $cm$Finland combines big paper and board groups with on-site PCC. FCC-fit: UPM Kymi and Jämsänkoski printing, Metsä Board FBB (Kyro, Äänekoski, Simpele), Stora Enso Imatra board, Metsä Tissue Mänttä, MM Kotkamills, delfort Tervakoski, Pankaboard. Closures: UPM Kaukas paper (2025-10), Metsä Board Tako (2025-06). Fillers: SMI Nordic satellites at Äänekoski (1993, Metsä Fibre CO2) and Tervakoski, SCHAEFER KALK on-site PCC at Kuusankoski (UPM Kymi site), Suomen Karbonaatti wet GCC at Lappeenranta (Nordkalk), Omya Finland (historical Förby and PCC). Paper carbonate use was about 1 Mt (2005).$cm$,
   $cm${"fillers": "Satellite PCC: SMI Nordic (Äänekoski, Tervakoski), SCHAEFER KALK Kuusankoski. GCC slurry: Suomen Karbonaatti Lappeenranta. Lime: Nordkalk. Omya Finland (Förby, PCC history).", "mills": "Printing: UPM Kymi, Jämsänkoski, Rauma, Tervasaari. Board: Metsä Board Kyro, Äänekoski, Simpele, Stora Enso Imatra, MM Kotkamills, Pankaboard. Tissue: Metsä Tissue Mänttä. Specialty: delfort Tervakoski, Jujo Thermal. Context: Kaukas, Tako (closed), Kemi, Oulu, Varkaus, Heinola, Anjala, Mondi.", "strategy": "Three-way trials at host sites: UPM Kymi with SCHAEFER KALK, Metsä Board Äänekoski and delfort Tervakoski with SMI (partner route). Suomen Karbonaatti for a GCC-based FCC line.", "risks": "Printing-paper decline and closures, Omya FiberLean competition.", "next_steps": ["Raise Äänekoski and Tervakoski trials with SMI", "Approach SCHAEFER KALK on a Kymi pilot"], "key_numbers": [{"label": "Paper carbonate 2005", "value": "about 700 kt coating + 300 kt filler"}, {"label": "Wet GCC 2011", "value": "about 1.2 Mt dry"}, {"label": "SMI Nordic 2025", "value": "EUR 10 m sales, 18 staff"}], "files": ["seed_20261016zv_finland_mills_fillers"]}$cm$::jsonb,
   $cm$UPM·Metsä Board·Stora Enso·Metsä Tissue — 위성 PCC SMI(Äänekoski·Tervakoski)·SCHAEFER KALK(Kuusankoski), GCC 슬러리 Suomen Karbonaatti$cm$,
   $cm$핀란드는 대형 제지·판지 그룹과 현장 PCC 가 결합된 시장. FCC 적합: UPM Kymi·Jämsänkoski 인쇄용지, Metsä Board FBB(Kyro·Äänekoski·Simpele), Stora Enso Imatra, Metsä Tissue Mänttä, MM Kotkamills, delfort Tervakoski, Pankaboard. 폐쇄: UPM Kaukas 제지(2025-10), Metsä Board Tako(2025-06). 충전제: SMI Nordic 위성 PCC(Äänekoski 1993·Tervakoski), SCHAEFER KALK Kuusankoski 현장 PCC(UPM Kymi 부지), Suomen Karbonaatti 습식 GCC(Lappeenranta), Omya Finland(과거).$cm$,
   null, null,
   $cm$공장별 생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('upm.*kymi|\mkymi\M', 'kuusankoski|kouvola', 'upm'),
  ('j[aä]ms[aä]nkoski', 'j[aä]ms[aä]', 'upm'),
  ('mets[aä] board.*kyro|\mkyro\M', 'kyr[oö]skoski', 'mets[aä]'),
  ('mets[aä] board.*[aä][aä]nekoski', '[aä][aä]nekoski', 'mets[aä]'),
  ('simpele', 'simpele', 'mets[aä]'),
  ('stora enso.*imatra|imatra mills', 'imatra', 'stora enso'),
  ('m[aä]ntt[aä]', 'm[aä]ntt[aä]', 'mets[aä]'),
  ('kotkamills', 'kotka', '\mmm\M|kotkamills|mayr'),
  ('delfort.*tervakoski|tervakoski', 'tervakoski', 'delfort'),
  ('pankaboard', 'pankakoski|lieksa', 'pankaboard'),
  ('jujo', 'kauttua|eura', 'jujo'),
  ('upm.*rauma|\mrauma\M', 'rauma', 'upm'),
  ('tervasaari', 'valkeakoski', 'upm'),
  ('kaukas', null, 'kaukas'),
  ('\mtako\M', null, '\mtako\M'),
  ('mets[aä] board.*kemi|\mkemi\M', null, 'mets[aä] board.*kemi|\mkemi\M'),
  ('stora enso.*oulu', null, 'stora enso.*oulu'),
  ('stora enso.*varkaus|varkaus', null, 'stora enso.*varkaus|varkaus'),
  ('heinola', null, 'heinola'),
  ('anjala', null, 'anjala'),
  ('mondi.*(finland|powerflute)', null, 'mondi.*(finland|powerflute)')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'finland_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'finland_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'suomen karbonaatti' or p.party_name ~* 'nordkalk.*(lappeenranta|finland|oyj)' or p.party_name ~* '(specialty minerals|minerals technologies).*(nordic|finland|[aä][aä]nekoski|tervakoski)' or p.party_name ~* 'schaefer kalk.*(finland|kuusankoski)' or p.party_name ~* 'omya.*(finland|oy\M|f[oö]rby|salo)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'FI'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'FI'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'FI'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    