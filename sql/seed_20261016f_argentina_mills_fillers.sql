-- ============================================================
-- seed_20261016f_argentina_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Argentina update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'AR check 2026-10-15'.
-- 1) Fillers if missing (6): Calidra Los Berros, Calidra La Laja, Omya
--    Argentina, Dolomita, Verdol, FGH. Imerys not added (status unknown).
--    Calidra guards are site-specific, so the Mexican Calidra row is not hit.
-- 2) Mills if missing (12) + plant blocks, priority 1-7: Ledesma, Softys
--    Zárate, San Andrés de Giles, Papel Prensa, Papelera del NOA, Cartocor x4,
--    Papel Misionero, Celulosa Argentina x2 (stopped). Context: Arauco (pulp).
-- 3) Supply link: Omya -> Celulosa Argentina Zárate (historical, medium).
-- 4) app.country_markets AR row (priority high).
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
           v.party_name, 'AR', v.region, v.city, v.website, 'active', 'argentina_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calidra.*los berros', 'Calidra Argentina - Los Berros (PCC)', 'San Juan', 'Los Berros', null, 'Grupo Calidra(멕시코계) 아르헨티나 PCC·석회석 공장(Ruta 153 Km 24, Los Berros, San Juan). 2024 배기 CO2 회수 개선 적용. 제지용 PCC·GCC 공급 명시.', 'Grupo Calidra Argentina - PCC and limestone plant at Ruta 153 Km 24, Los Berros, San Juan (exhaust CO2 recovery upgrade 2024). Calidra states it supplies paper with ground and precipitated calcium carbonate - about 70 pct of PCC goes to paint, 30 pct to rubber, paper, agriculture, chemicals, cosmetics.', 'AR check 2026-10-15: PCC tonnage and paper share not public. Lead Argentine FCC licence candidate.'),
  ('calidra.*la laja', 'Calidra Argentina - La Laja (PCC)', 'San Juan', 'Albardón', null, 'Grupo Calidra 아르헨티나 PCC 공장(La Laja, Albardón, San Juan). 2025 역삼투 수처리 투자, Maerz 석회로.', 'Grupo Calidra Argentina - PCC plant at Calle La Laja s/n, Albardón, San Juan (reverse-osmosis water treatment investment 2025, Maerz lime kiln).', 'AR check 2026-10-15: capacity not public.'),
  ('omya.*argentin', 'Omya Argentina', null, null, null, 'Omya 아르헨티나 사업(아르헨티나·파라과이·우루과이 담당), Pulp & Paper 주요 시장. 과거 Huber 인수로 Zárate Celulosa Argentina 위성 PCC(연 2.5만~3만 t, 2003 비가동 기록).', 'Omya Argentina - covers Argentina, Paraguay and Uruguay, pulp and paper a key market. Through the Huber PCC acquisition (2005) it took over the satellite PCC at the Celulosa Argentina Zárate mill (25,000-30,000 t/yr estimated, idle in 2003).', 'AR check 2026-10-15: current Argentine plant locations and capacity not confirmed. Royalty licensee at Omya HQ level.'),
  ('dolomita', 'Dolomita SAIC', 'Córdoba', 'Alta Gracia', null, '1948년 설립 Alta Gracia(Córdoba) 광물 업체. 분쇄기 20기 이상·일 500 t, 평균 입경 약 2.5 μm, 별도 PCC 생산시설(종이 충전제 용도 명시).', 'Dolomita SAIC (1948), Alta Gracia, Córdoba - about 80,000 m2 site, over 20 mills with 500 t/day installed grinding (all minerals), products to about 2.5 micron mean size, plus a separate PCC plant - PCC named as filler for paper, plastics, paint, adhesives.', 'AR check 2026-10-15: PCC capacity not public. Both PCC and fine GCC on one site - FCC trial production candidate.'),
  ('verdol', 'Verdol S.A.', 'Córdoba', null, null, '1968년 설립 Córdoba GCC·돌로마이트·방해석·탈크 업체. 자체 광산, 일 약 450 t, 코팅 설비(플라스틱용).', 'Verdol S.A. (1968), Córdoba - own calcium carbonate and dolomite quarries, grinding since 1985, about 450 t/day (all minerals), about 5,000 m2 indoor plant, surface-coated grades for plastics, also calcite and talc.', 'AR check 2026-10-15: paper grades not confirmed.'),
  ('\mfgh\M|cal fgh', 'FGH S.A. (Cal FGH) - Los Berros', 'San Juan', 'Los Berros', null, '50년+ 석회석 업체(Los Berros, San Juan). CALCIO TOTAL — 천연 탄산칼슘·PCC·생석회·소석회.', 'FGH S.A. (Cal FGH), Ruta Nacional 153 y Miguel Bogdan 800, Los Berros, San Juan - over 50 years in limestone, CALCIO TOTAL range: natural calcium carbonate, PCC, quicklime, hydrated lime.', 'AR check 2026-10-15: paper grades, PCC crystal form and slurry not confirmed. Plant +54 264 4975031. Not added: Imerys (PCC at Capitán Bermúdez, Ledesma, Los Berros about 50 kt in 2005 - current status unknown).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calidra.*los berros', 'Calidra Argentina - Los Berros (PCC)', 'San Juan', 'Los Berros', null, 'Grupo Calidra(멕시코계) 아르헨티나 PCC·석회석 공장(Ruta 153 Km 24, Los Berros, San Juan). 2024 배기 CO2 회수 개선 적용. 제지용 PCC·GCC 공급 명시.', 'Grupo Calidra Argentina - PCC and limestone plant at Ruta 153 Km 24, Los Berros, San Juan (exhaust CO2 recovery upgrade 2024). Calidra states it supplies paper with ground and precipitated calcium carbonate - about 70 pct of PCC goes to paint, 30 pct to rubber, paper, agriculture, chemicals, cosmetics.', 'AR check 2026-10-15: PCC tonnage and paper share not public. Lead Argentine FCC licence candidate.'),
  ('calidra.*la laja', 'Calidra Argentina - La Laja (PCC)', 'San Juan', 'Albardón', null, 'Grupo Calidra 아르헨티나 PCC 공장(La Laja, Albardón, San Juan). 2025 역삼투 수처리 투자, Maerz 석회로.', 'Grupo Calidra Argentina - PCC plant at Calle La Laja s/n, Albardón, San Juan (reverse-osmosis water treatment investment 2025, Maerz lime kiln).', 'AR check 2026-10-15: capacity not public.'),
  ('omya.*argentin', 'Omya Argentina', null, null, null, 'Omya 아르헨티나 사업(아르헨티나·파라과이·우루과이 담당), Pulp & Paper 주요 시장. 과거 Huber 인수로 Zárate Celulosa Argentina 위성 PCC(연 2.5만~3만 t, 2003 비가동 기록).', 'Omya Argentina - covers Argentina, Paraguay and Uruguay, pulp and paper a key market. Through the Huber PCC acquisition (2005) it took over the satellite PCC at the Celulosa Argentina Zárate mill (25,000-30,000 t/yr estimated, idle in 2003).', 'AR check 2026-10-15: current Argentine plant locations and capacity not confirmed. Royalty licensee at Omya HQ level.'),
  ('dolomita', 'Dolomita SAIC', 'Córdoba', 'Alta Gracia', null, '1948년 설립 Alta Gracia(Córdoba) 광물 업체. 분쇄기 20기 이상·일 500 t, 평균 입경 약 2.5 μm, 별도 PCC 생산시설(종이 충전제 용도 명시).', 'Dolomita SAIC (1948), Alta Gracia, Córdoba - about 80,000 m2 site, over 20 mills with 500 t/day installed grinding (all minerals), products to about 2.5 micron mean size, plus a separate PCC plant - PCC named as filler for paper, plastics, paint, adhesives.', 'AR check 2026-10-15: PCC capacity not public. Both PCC and fine GCC on one site - FCC trial production candidate.'),
  ('verdol', 'Verdol S.A.', 'Córdoba', null, null, '1968년 설립 Córdoba GCC·돌로마이트·방해석·탈크 업체. 자체 광산, 일 약 450 t, 코팅 설비(플라스틱용).', 'Verdol S.A. (1968), Córdoba - own calcium carbonate and dolomite quarries, grinding since 1985, about 450 t/day (all minerals), about 5,000 m2 indoor plant, surface-coated grades for plastics, also calcite and talc.', 'AR check 2026-10-15: paper grades not confirmed.'),
  ('\mfgh\M|cal fgh', 'FGH S.A. (Cal FGH) - Los Berros', 'San Juan', 'Los Berros', null, '50년+ 석회석 업체(Los Berros, San Juan). CALCIO TOTAL — 천연 탄산칼슘·PCC·생석회·소석회.', 'FGH S.A. (Cal FGH), Ruta Nacional 153 y Miguel Bogdan 800, Los Berros, San Juan - over 50 years in limestone, CALCIO TOTAL range: natural calcium carbonate, PCC, quicklime, hydrated lime.', 'AR check 2026-10-15: paper grades, PCC crystal form and slurry not confirmed. Plant +54 264 4975031. Not added: Imerys (PCC at Capitán Bermúdez, Ledesma, Los Berros about 50 kt in 2005 - current status unknown).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'argentina_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calidra Argentina - Los Berros (PCC)', 'PCC and GCC producer', 'Merchant PCC for paper - FCC licence candidate 1', 'merchant', 'B', 'pcc'),
  ('Calidra Argentina - La Laja (PCC)', 'PCC and GCC producer', 'Merchant PCC - second Calidra site', 'merchant', 'B', 'pcc'),
  ('Omya Argentina', 'GCC and PCC supplier', 'Omya Argentina - royalty licensee (Omya HQ)', 'satellite (on-site)', 'C', 'gcc'),
  ('Dolomita SAIC', 'PCC and GCC producer', 'PCC plus fine GCC - FCC trial candidate', 'merchant', 'B', 'pcc'),
  ('Verdol S.A.', 'GCC producer', 'Large GCC grinder - co-development candidate', 'merchant', 'C', 'gcc'),
  ('FGH S.A. (Cal FGH) - Los Berros', 'PCC and GCC producer', 'Independent PCC maker - small trial partner', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'argentina_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'AR', v.region, v.city, v.website, 'active', 'argentina_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('ledesma', 'libertador', 'ledesma', 'Ledesma - Libertador General San Martín (Jujuy)', 'Jujuy', 'Libertador General San Martín', null, '사탕수수 바가스 펄프 기반 인쇄·필기용지 제조사. 연 13만 t 이상, 80% 내수. 브랜드 Éxito·Autor·Gloria·Ledesma NAT.', 'Ledesma S.A.A.I. - bagasse-pulp printing and writing paper at Libertador General San Martín, Jujuy: over 130,000 t/yr, about 80 pct for the home market. Brands Éxito, Autor, Gloria, Ledesma NAT (100 pct bagasse), copy paper, reels and notebooks.', 'AR check 2026-10-15: filler supplier and loading not public. 2005 data listed an Imerys PCC plant at Ledesma (status unknown).'),
  ('softys.*argentin|softys.*z[aá]rate|papelera del plata', 'z[aá]rate', 'softys|papelera del plata', 'Softys Argentina - Zárate', 'Buenos Aires', 'Zárate', null, 'CMPC 계열 Softys Argentina(구 Papelera del Plata) Zárate 티슈 원지·가공 공장. 브랜드 Elite·Higienol·Sussex.', 'Softys Argentina (CMPC, ex Papelera del Plata) - tissue base paper and converting at Zárate, Buenos Aires (two tissue machines in its history), brands Elite, Higienol, Sussex. Other site Naschel, San Luis.', 'AR check 2026-10-15: machine capacity not public.'),
  ('san andr[eé]s de giles|\mpsag\M', 'giles', 'papelera', 'Papelera San Andrés de Giles', 'Buenos Aires', 'San Andrés de Giles', null, '1981년경 설립 독립 티슈 제조·가공사. 화장지·키친타월·냅킨·미용티슈, 브랜드 Felpita·Sweety.', 'Papelera San Andrés de Giles (about 1981), Ruta Provincial 41 y Ruta Nacional 7, San Andrés de Giles, Buenos Aires - independent tissue maker and converter: toilet tissue, kitchen towel, napkins, facial, brands Felpita and Sweety plus private label.', 'AR check 2026-10-15: info@psag.com.ar, +54 2325 440800. Capacity not public.'),
  ('papel prensa', 'san pedro', 'papel prensa', 'Papel Prensa - San Pedro', 'Buenos Aires', 'San Pedro', null, '아르헨티나 신문용지 주요 기업(San Pedro). 버드나무·포플러·소나무 펄프, 신문·인쇄·포장용지. 펄프 설비 연 17만 t.', 'Papel Prensa S.A., San Pedro, Buenos Aires - main Argentine newsprint maker on willow, poplar and pine pulp, also printing and packaging paper. Pulp capacity 170,000 t/yr (government data).', 'AR check 2026-10-15: paper-machine capacity not given - pulp figure kept out of capacity.'),
  ('papelera del noa|grupo noa', 'r[ií]o blanco', 'noa', 'Papelera del NOA - Río Blanco (Jujuy)', 'Jujuy', 'Río Blanco', null, 'Grupo NOA(Papelera del NOA + Papel Pampa Quilmes) — 천연섬유 4.8만 t + 재생지 3.6만 t, 골판지원지·Kraftliner·백색 표면용지.', 'Papelera del NOA, Río Blanco, Jujuy (Grupo NOA, with Papel Pampa in Quilmes) - group makes about 48,000 t/yr virgin-fibre and 36,000 t/yr recycled paper in two mills: corrugating base paper, kraftliner, white-top liner.', 'AR check 2026-10-15: group figures cover both mills. Pulp capacity 70,000 t/yr (government data).'),
  ('cartocor.*arroyito|arcor.*arroyito', 'arroyito', 'cartocor|arcor|zucamor', 'Cartocor (Arcor) - Arroyito', 'Córdoba', 'Arroyito', null, 'Grupo Arcor 의 Cartocor Arroyito 제지·포장 공장. Recycled packaging paper (surface-treated).', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Arroyito mill: recycled packaging paper (surface-treated).', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*ranelagh|zucamor.*ranelagh', 'ranelagh', 'cartocor|arcor|zucamor', 'Cartocor (Arcor) - Ranelagh', 'Buenos Aires', 'Ranelagh', null, 'Grupo Arcor 의 Cartocor Ranelagh 제지·포장 공장. Recycled packaging paper.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Ranelagh mill: recycled packaging paper.', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*mendoza|zucamor.*mendoza', 'mendoza', 'cartocor|arcor|zucamor', 'Cartocor (Arcor) - Mendoza', 'Mendoza', 'Mendoza', null, 'Grupo Arcor 의 Cartocor Mendoza 제지·포장 공장. Recycled packaging paper.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Mendoza mill: recycled packaging paper.', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*luj[aá]n', 'luj[aá]n', 'cartocor|arcor|zucamor', 'Cartocor (Arcor) - Luján', 'Buenos Aires', 'Luján', null, 'Grupo Arcor 의 Cartocor Luján 제지·포장 공장. Paper and packaging complex.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Luján mill: paper and packaging complex.', 'AR check 2026-10-15: machine capacity not public.'),
  ('papel misionero|cartocor.*(misiones|capiov)', 'capiov', 'misionero|cartocor|arcor', 'Papel Misionero (Cartocor) - Capioví', 'Misiones', 'Capioví', null, 'Arcor/Cartocor 계열 Papel Misionero — 소나무 크라프트 펄프 Kraftliner·Sack Kraft(Capioví, Misiones). 펄프 설비 9만 t.', 'Papel Misionero, Capioví, Misiones (Cartocor / Grupo Arcor since 2017) - pine kraft pulp to kraftliner and sack kraft, pulp capacity 90,000 t/yr (government data), biomass boiler.', 'AR check 2026-10-15: paper capacity not given - same group as Cartocor, do not count twice.'),
  ('celulosa argentina.*berm[uú]dez', 'berm[uú]dez', 'celulosa argentina', 'Celulosa Argentina - Capitán Bermúdez', 'Santa Fe', 'Capitán Bermúdez', null, 'Celulosa Argentina Capitán Bermúdez 인쇄·필기·포장용지 공장. 2025-07 생산 중단, 2025-09 채무조정(concurso preventivo) 신청.', 'Celulosa Argentina - Capitán Bermúdez mill, printing and writing and packaging paper (chemical pulp 194,000 t/yr, government data). Production stopped 2025-07, concurso preventivo filed 2025-09.', 'AR check 2026-10-15: financial distress - commercial priority low until production and finances recover.'),
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina', 'Celulosa Argentina - Zárate', 'Buenos Aires', 'Zárate', null, 'Celulosa Argentina Zárate 인쇄·필기·포장용지 공장. 2025-07 생산 중단, 2025-09 채무조정(concurso preventivo) 신청.', 'Celulosa Argentina - Zárate mill, printing and writing and packaging paper. Production stopped 2025-07, concurso preventivo filed 2025-09, and Zárate stopped again for about two months (report 2026-09-21).', 'AR check 2026-10-15: financial distress - commercial priority low until production and finances recover. Omya (ex Huber) satellite PCC served this mill, idle in 2003.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ledesma', 'libertador', 'ledesma', '사탕수수 바가스 펄프 기반 인쇄·필기용지 제조사. 연 13만 t 이상, 80% 내수. 브랜드 Éxito·Autor·Gloria·Ledesma NAT.', 'Ledesma S.A.A.I. - bagasse-pulp printing and writing paper at Libertador General San Martín, Jujuy: over 130,000 t/yr, about 80 pct for the home market. Brands Éxito, Autor, Gloria, Ledesma NAT (100 pct bagasse), copy paper, reels and notebooks.', 'AR check 2026-10-15: filler supplier and loading not public. 2005 data listed an Imerys PCC plant at Ledesma (status unknown).'),
  ('softys.*argentin|softys.*z[aá]rate|papelera del plata', 'z[aá]rate', 'softys|papelera del plata', 'CMPC 계열 Softys Argentina(구 Papelera del Plata) Zárate 티슈 원지·가공 공장. 브랜드 Elite·Higienol·Sussex.', 'Softys Argentina (CMPC, ex Papelera del Plata) - tissue base paper and converting at Zárate, Buenos Aires (two tissue machines in its history), brands Elite, Higienol, Sussex. Other site Naschel, San Luis.', 'AR check 2026-10-15: machine capacity not public.'),
  ('san andr[eé]s de giles|\mpsag\M', 'giles', 'papelera', '1981년경 설립 독립 티슈 제조·가공사. 화장지·키친타월·냅킨·미용티슈, 브랜드 Felpita·Sweety.', 'Papelera San Andrés de Giles (about 1981), Ruta Provincial 41 y Ruta Nacional 7, San Andrés de Giles, Buenos Aires - independent tissue maker and converter: toilet tissue, kitchen towel, napkins, facial, brands Felpita and Sweety plus private label.', 'AR check 2026-10-15: info@psag.com.ar, +54 2325 440800. Capacity not public.'),
  ('papel prensa', 'san pedro', 'papel prensa', '아르헨티나 신문용지 주요 기업(San Pedro). 버드나무·포플러·소나무 펄프, 신문·인쇄·포장용지. 펄프 설비 연 17만 t.', 'Papel Prensa S.A., San Pedro, Buenos Aires - main Argentine newsprint maker on willow, poplar and pine pulp, also printing and packaging paper. Pulp capacity 170,000 t/yr (government data).', 'AR check 2026-10-15: paper-machine capacity not given - pulp figure kept out of capacity.'),
  ('papelera del noa|grupo noa', 'r[ií]o blanco', 'noa', 'Grupo NOA(Papelera del NOA + Papel Pampa Quilmes) — 천연섬유 4.8만 t + 재생지 3.6만 t, 골판지원지·Kraftliner·백색 표면용지.', 'Papelera del NOA, Río Blanco, Jujuy (Grupo NOA, with Papel Pampa in Quilmes) - group makes about 48,000 t/yr virgin-fibre and 36,000 t/yr recycled paper in two mills: corrugating base paper, kraftliner, white-top liner.', 'AR check 2026-10-15: group figures cover both mills. Pulp capacity 70,000 t/yr (government data).'),
  ('cartocor.*arroyito|arcor.*arroyito', 'arroyito', 'cartocor|arcor|zucamor', 'Grupo Arcor 의 Cartocor Arroyito 제지·포장 공장. Recycled packaging paper (surface-treated).', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Arroyito mill: recycled packaging paper (surface-treated).', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*ranelagh|zucamor.*ranelagh', 'ranelagh', 'cartocor|arcor|zucamor', 'Grupo Arcor 의 Cartocor Ranelagh 제지·포장 공장. Recycled packaging paper.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Ranelagh mill: recycled packaging paper.', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*mendoza|zucamor.*mendoza', 'mendoza', 'cartocor|arcor|zucamor', 'Grupo Arcor 의 Cartocor Mendoza 제지·포장 공장. Recycled packaging paper.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Mendoza mill: recycled packaging paper.', 'AR check 2026-10-15: machine capacity not public.'),
  ('cartocor.*luj[aá]n', 'luj[aá]n', 'cartocor|arcor|zucamor', 'Grupo Arcor 의 Cartocor Luján 제지·포장 공장. Paper and packaging complex.', 'Cartocor (Grupo Arcor, incl. ex Zucamor since 2017) - Luján mill: paper and packaging complex.', 'AR check 2026-10-15: machine capacity not public.'),
  ('papel misionero|cartocor.*(misiones|capiov)', 'capiov', 'misionero|cartocor|arcor', 'Arcor/Cartocor 계열 Papel Misionero — 소나무 크라프트 펄프 Kraftliner·Sack Kraft(Capioví, Misiones). 펄프 설비 9만 t.', 'Papel Misionero, Capioví, Misiones (Cartocor / Grupo Arcor since 2017) - pine kraft pulp to kraftliner and sack kraft, pulp capacity 90,000 t/yr (government data), biomass boiler.', 'AR check 2026-10-15: paper capacity not given - same group as Cartocor, do not count twice.'),
  ('celulosa argentina.*berm[uú]dez', 'berm[uú]dez', 'celulosa argentina', 'Celulosa Argentina Capitán Bermúdez 인쇄·필기·포장용지 공장. 2025-07 생산 중단, 2025-09 채무조정(concurso preventivo) 신청.', 'Celulosa Argentina - Capitán Bermúdez mill, printing and writing and packaging paper (chemical pulp 194,000 t/yr, government data). Production stopped 2025-07, concurso preventivo filed 2025-09.', 'AR check 2026-10-15: financial distress - commercial priority low until production and finances recover.'),
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina', 'Celulosa Argentina Zárate 인쇄·필기·포장용지 공장. 2025-07 생산 중단, 2025-09 채무조정(concurso preventivo) 신청.', 'Celulosa Argentina - Zárate mill, printing and writing and packaging paper. Production stopped 2025-07, concurso preventivo filed 2025-09, and Zárate stopped again for about two months (report 2026-09-21).', 'AR check 2026-10-15: financial distress - commercial priority low until production and finances recover. Omya (ex Huber) satellite PCC served this mill, idle in 2003.'),
  ('arauco.*argentin|arauco.*esperanza', null, 'arauco', null, null, 'AR check 2026-10-15: Arauco Argentina, Puerto Esperanza (Misiones) - bleached kraft and fluff pulp, 350 kt/yr - pulp only, context.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'argentina_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ledesma', 'libertador', 'ledesma'),
  ('softys.*argentin|softys.*z[aá]rate|papelera del plata', 'z[aá]rate', 'softys|papelera del plata'),
  ('san andr[eé]s de giles|\mpsag\M', 'giles', 'papelera'),
  ('papel prensa', 'san pedro', 'papel prensa'),
  ('papelera del noa|grupo noa', 'r[ií]o blanco', 'noa'),
  ('cartocor.*arroyito|arcor.*arroyito', 'arroyito', 'cartocor|arcor|zucamor'),
  ('cartocor.*ranelagh|zucamor.*ranelagh', 'ranelagh', 'cartocor|arcor|zucamor'),
  ('cartocor.*mendoza|zucamor.*mendoza', 'mendoza', 'cartocor|arcor|zucamor'),
  ('cartocor.*luj[aá]n', 'luj[aá]n', 'cartocor|arcor|zucamor'),
  ('papel misionero|cartocor.*(misiones|capiov)', 'capiov', 'misionero|cartocor|arcor'),
  ('celulosa argentina.*berm[uú]dez', 'berm[uú]dez', 'celulosa argentina'),
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina'),
  ('arauco.*argentin|arauco.*esperanza', null, 'arauco')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ledesma', 'libertador', 'ledesma',
   $pj${"owner": "Ledesma", "priority": 1, "products": "Printing and writing, copy paper, notebooks (bagasse pulp)", "grades": ["Printing and writing", "Copy paper"], "capacity": {"value": 130000, "unit": "metric_t", "year": "Company figure", "source": "ledesma.com.ar"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 0.5, "fcc_loading": 0.05}, {"label": "Expanded", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 50 pct of output x 5 pct - planning only."}, "pitch": "Bagasse-pulp saving at equal brightness, opacity and strength", "approach": "Lead Argentine account - pilot with retention, drainage, formation checks on bagasse furnish. Supply by Calidra or Omya.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*argentin|softys.*z[aá]rate|papelera del plata', 'z[aá]rate', 'softys|papelera del plata',
   $pj${"owner": "Softys (CMPC)", "priority": 2, "products": "Toilet tissue, kitchen towel, napkins, facial", "grades": ["Tissue"], "pitch": "Tissue FCC 1-5 pct - links to Softys Uruguay and Chile", "approach": "Pick one grade (toilet or towel) for a low-dose trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('san andr[eé]s de giles|\mpsag\M', 'giles', 'papelera',
   $pj${"owner": "Papelera San Andrés de Giles", "priority": 3, "products": "Toilet tissue, kitchen towel, napkins, facial", "grades": ["Tissue"], "approach": "Independent - small joint pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papel prensa', 'san pedro', 'papel prensa',
   $pj${"owner": "Papel Prensa", "priority": 4, "products": "Newsprint, printing paper, packaging paper", "grades": ["Newsprint", "Printing and writing"], "approach": "Opacity and strength trial - mechanical pulp economics differ.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera del noa|grupo noa', 'r[ií]o blanco', 'noa',
   $pj${"owner": "Grupo NOA", "priority": 5, "products": "Kraftliner, corrugating base paper, white-top liner", "grades": ["Kraftliner", "White-top liner", "Medium"], "capacity_split": [{"label": "Group virgin fibre (2 mills)", "value_t": 48000}, {"label": "Group recycled", "value_t": 36000}], "approach": "White-top liner - surface and strength trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartocor.*arroyito|arcor.*arroyito', 'arroyito', 'cartocor|arcor|zucamor',
   $pj${"owner": "Cartocor (Grupo Arcor)", "priority": 6, "products": "Recycled packaging paper (surface-treated)", "grades": ["Testliner", "Medium"], "approach": "Low-dose strength trial on recycled packaging.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartocor.*ranelagh|zucamor.*ranelagh', 'ranelagh', 'cartocor|arcor|zucamor',
   $pj${"owner": "Cartocor (Grupo Arcor)", "priority": 6, "products": "Recycled packaging paper", "grades": ["Testliner", "Medium"], "approach": "Low-dose strength trial on recycled packaging.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartocor.*mendoza|zucamor.*mendoza', 'mendoza', 'cartocor|arcor|zucamor',
   $pj${"owner": "Cartocor (Grupo Arcor)", "priority": 6, "products": "Recycled packaging paper", "grades": ["Testliner", "Medium"], "approach": "Low-dose strength trial on recycled packaging.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartocor.*luj[aá]n', 'luj[aá]n', 'cartocor|arcor|zucamor',
   $pj${"owner": "Cartocor (Grupo Arcor)", "priority": 6, "products": "Paper and packaging complex", "grades": ["Testliner", "Medium"], "approach": "Low-dose strength trial on recycled packaging.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papel misionero|cartocor.*(misiones|capiov)', 'capiov', 'misionero|cartocor|arcor',
   $pj${"owner": "Cartocor (Grupo Arcor)", "priority": 6, "products": "Kraftliner, sack kraft", "grades": ["Kraftliner", "Sack kraft"], "approach": "Strength-critical - later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('celulosa argentina.*berm[uú]dez', 'berm[uú]dez', 'celulosa argentina',
   $pj${"owner": "Celulosa Argentina", "priority": 7, "products": "Printing and writing, packaging paper", "grades": ["Printing and writing"], "approach": "Wait for restart and financial recovery.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina',
   $pj${"owner": "Celulosa Argentina", "priority": 7, "products": "Printing and writing, packaging paper", "grades": ["Printing and writing"], "approach": "Wait for restart and financial recovery.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('arauco.*argentin|arauco.*esperanza', null, 'arauco',
   $pj${"owner": "Arauco", "products": "Market pulp (350 kt)", "approach": "Pulp only - not an FCC customer.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'argentina_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina', 'omya.*argentin', 'historical', 'medium', null::date, null::date, '25,000-30,000 t/yr estimated', 'satellite PCC at Zárate (ex Huber)', 'Industry report 2005', 'Omya (ex Huber) satellite PCC at Celulosa Argentina Zárate - idle in 2003 per 2005 report')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AR', 'Argentina', 'high',
   $cm$Ledesma bagasse printing paper (130 kt), Softys and San Andrés de Giles tissue - merchant PCC at Calidra and Dolomita$cm$,
   $cm$Argentina makes both PCC and GCC: Calidra runs two PCC plants in San Juan (Los Berros, La Laja) and states it supplies paper, Dolomita (Córdoba) has PCC plus fine GCC, FGH makes PCC, Verdol grinds GCC, Omya covers the region. Lead mill is Ledesma (130 kt bagasse printing and writing paper), then Softys Zárate and Papelera San Andrés de Giles tissue, Papel Prensa, Grupo NOA and Cartocor packaging. Celulosa Argentina stopped in 2025-07 and is in concurso preventivo.$cm$,
   $cm${"fillers": "PCC: Calidra Los Berros and La Laja (70 pct of PCC to paint, rest incl. paper), Dolomita Alta Gracia (PCC plus 500 t/day grinding), FGH Los Berros. GCC: Verdol Córdoba (450 t/day). Licensee: Omya Argentina (ex Huber Zárate satellite, idle 2003). Imerys had about 50 kt PCC in 2005 - current status unknown, not added.", "mills": "Printing and writing: Ledesma (Jujuy), Celulosa Argentina Capitán Bermúdez and Zárate (stopped 2025-07). Tissue: Softys Zárate, Papelera San Andrés de Giles. Newsprint: Papel Prensa San Pedro. Packaging: Grupo NOA Río Blanco (84 kt group), Cartocor Arroyito, Ranelagh, Mendoza, Luján, Papel Misionero Capioví. Pulp only: Arauco Argentina.", "strategy": "Ledesma pilot first, Softys and San Andrés de Giles tissue trials. Production by Calidra or Dolomita as new licensees, or by Omya.", "risks": "Celulosa Argentina distress, packaging strength limits, mill-level filler use not public.", "next_steps": ["Approach Calidra and Dolomita on an FCC licence", "Propose a bagasse-pulp pilot to Ledesma"], "key_numbers": [{"label": "Ledesma", "value": "over 130 kt/yr printing and writing"}, {"label": "Grupo NOA", "value": "84 kt/yr (2 mills)"}, {"label": "Report scenario", "value": "3,250 t FCC at Ledesma (50 pct x 5 pct)"}], "files": ["seed_20261016f_argentina_mills_fillers"]}$cm$::jsonb,
   $cm$Ledesma 바가스 인쇄용지(13만 t) + Softys·San Andrés de Giles 티슈 — Calidra·Dolomita 상업 PCC$cm$,
   $cm$아르헨티나는 PCC·GCC 모두 생산: Calidra 가 San Juan 에 PCC 공장 2곳(제지 공급 명시), Dolomita(PCC+미분 GCC), FGH(PCC), Verdol(GCC), Omya 지역 담당. 1순위 Ledesma(바가스 인쇄·필기 13만 t), 이어 Softys Zárate·San Andrés de Giles 티슈, Papel Prensa, Grupo NOA·Cartocor 포장. Celulosa Argentina 는 2025-07 생산 중단·채무조정.$cm$,
   3250, 6500,
   $cm$Ledesma 13만 t × 적용 50~100% × FCC 5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('ledesma', 'libertador', 'ledesma'),
  ('softys.*argentin|softys.*z[aá]rate|papelera del plata', 'z[aá]rate', 'softys|papelera del plata'),
  ('san andr[eé]s de giles|\mpsag\M', 'giles', 'papelera'),
  ('papel prensa', 'san pedro', 'papel prensa'),
  ('papelera del noa|grupo noa', 'r[ií]o blanco', 'noa'),
  ('cartocor.*arroyito|arcor.*arroyito', 'arroyito', 'cartocor|arcor|zucamor'),
  ('cartocor.*ranelagh|zucamor.*ranelagh', 'ranelagh', 'cartocor|arcor|zucamor'),
  ('cartocor.*mendoza|zucamor.*mendoza', 'mendoza', 'cartocor|arcor|zucamor'),
  ('cartocor.*luj[aá]n', 'luj[aá]n', 'cartocor|arcor|zucamor'),
  ('papel misionero|cartocor.*(misiones|capiov)', 'capiov', 'misionero|cartocor|arcor'),
  ('celulosa argentina.*berm[uú]dez', 'berm[uú]dez', 'celulosa argentina'),
  ('celulosa argentina.*z[aá]rate', 'z[aá]rate', 'celulosa argentina'),
  ('arauco.*argentin|arauco.*esperanza', null, 'arauco')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'argentina_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'argentina_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calidra.*los berros' or p.party_name ~* 'calidra.*la laja' or p.party_name ~* 'omya.*argentin' or p.party_name ~* 'dolomita' or p.party_name ~* 'verdol' or p.party_name ~* '\mfgh\M|cal fgh')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    