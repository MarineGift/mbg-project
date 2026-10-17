-- ============================================================
-- seed_20261016zq_spain_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Spain update (reports 2026-10-16). Existing ES rows likely - name regex
-- OR city + owner regex first. El Burgo de Ebro (ICT, Saica) and Zaragoza
-- (Torraspapel, Saica) are kept apart by owner regex.
-- 1) Fillers if missing (4): Calmit Llierca (PCC), Reverté Minerals, Omya
--    Spain, TRICALSA.
-- 2) Mills if missing (9) + plant blocks, priority 1-8: Torraspapel, ICT
--    Ibérica, Gomà-Camps, Sofidel Buñuel, Essity Allo, Saica El Burgo,
--    Hinojosa Alquería, Smurfit Westrock Sangüesa. Saica Zaragoza no
--    priority. Context (4).
-- 3) app.country_markets ES row (priority high).
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
           v.party_name, 'ES', v.region, v.city, v.website, 'active', 'spain_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('llierca|calprec', 'Calmit Llierca (CALPREC PCC) - Argelaguer', 'Catalonia', 'Argelaguer', null, '1969년 설립, 1977년 PCC 생산 시작(구 Cales de Llierca, 2026 Calmit Llierca 로 사명 변경, Calcinor 그룹). 자체 채석장→소성→수화→탄산화 수직계열, CALPREC® PCC, 1978 첫 PCC 고객이 제지사.', 'Calmit Llierca S.A. (formerly Cales de Llierca, renamed 2026, Calcinor group), Afueras s/n, Argelaguer (Girona) - founded 1969, PCC since 1977: own limestone quarry, calcining, slaking and carbonation, CALPREC PCC grades, first PCC sale in 1978 to a paper mill, paper still a target market. Also quicklime and hydrated lime.', 'ES check 2026-10-16: PCC capacity not public. calmitllierca@calmit.com, +34 972 687 020. Independent PCC maker - FCC pilot and licence candidate 1. Calcinor group is the parent - not a second PCC plant.'),
  ('revert[eé] minerals', 'Reverté Minerals - Albox', 'Andalusia', 'Albox', null, '1958년 설립 탄산칼슘 전문 — Castellet i la Gornal(바르셀로나)·Albox(알메리아, 2000 가동 당시 연 40만 t) 공장, 미분쇄·슬러리 기술, 고광택 코팅지용 탄산칼슘 투자, 2026-07 CATbonate 백색도 향상 기술.', 'Reverté Minerals (1958) - GCC plants at Castellet i la Gornal (Barcelona) and Albox (Almería, opened 2000 at 400,000 t/yr), fine grinding and slurry know-how, Andalusian grant for high-gloss coated-paper carbonate at Albox, CATbonate impurity-removal and brightness technology announced 2026-07.', 'ES check 2026-10-16: current output not public. Paper GCC with slurry - FCC co-production candidate 1 (GCC side).'),
  ('omya.*(spain|espa)', 'Omya Specialty Materials Spain - Barcelona', 'Catalonia', 'Barcelona', null, 'Omya 스페인 법인(Carrer de Pallars 180 C, 바르셀로나) — 펄프·제지 주요 시장, 위성공장 모델.', 'Omya Specialty Materials (Spain) SLU, Carrer de Pallars 180 C, Barcelona - pulp and paper named as a main market, satellite-plant model.', 'ES check 2026-10-16: office address - Spanish plants not confirmed. +34 93 566 61 66. Royalty licensee at Omya HQ level.'),
  ('tricalsa|triturados c[aá]lcicos', 'TRICALSA - Arganda del Rey', 'Madrid', 'Arganda del Rey', null, '1983년 설립 가족기업 — Arganda del Rey 천연 탄산칼슘 채굴·분쇄·미분쇄.', 'Triturados Cálcicos S.A. (TRICALSA, 1983, family-owned), Arganda del Rey (Madrid) - natural calcium carbonate quarrying, grinding and micronising.', 'ES check 2026-10-16: paper sales and slurry not confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ES check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('llierca|calprec', 'Calmit Llierca (CALPREC PCC) - Argelaguer', 'Catalonia', 'Argelaguer', null, '1969년 설립, 1977년 PCC 생산 시작(구 Cales de Llierca, 2026 Calmit Llierca 로 사명 변경, Calcinor 그룹). 자체 채석장→소성→수화→탄산화 수직계열, CALPREC® PCC, 1978 첫 PCC 고객이 제지사.', 'Calmit Llierca S.A. (formerly Cales de Llierca, renamed 2026, Calcinor group), Afueras s/n, Argelaguer (Girona) - founded 1969, PCC since 1977: own limestone quarry, calcining, slaking and carbonation, CALPREC PCC grades, first PCC sale in 1978 to a paper mill, paper still a target market. Also quicklime and hydrated lime.', 'ES check 2026-10-16: PCC capacity not public. calmitllierca@calmit.com, +34 972 687 020. Independent PCC maker - FCC pilot and licence candidate 1. Calcinor group is the parent - not a second PCC plant.'),
  ('revert[eé] minerals', 'Reverté Minerals - Albox', 'Andalusia', 'Albox', null, '1958년 설립 탄산칼슘 전문 — Castellet i la Gornal(바르셀로나)·Albox(알메리아, 2000 가동 당시 연 40만 t) 공장, 미분쇄·슬러리 기술, 고광택 코팅지용 탄산칼슘 투자, 2026-07 CATbonate 백색도 향상 기술.', 'Reverté Minerals (1958) - GCC plants at Castellet i la Gornal (Barcelona) and Albox (Almería, opened 2000 at 400,000 t/yr), fine grinding and slurry know-how, Andalusian grant for high-gloss coated-paper carbonate at Albox, CATbonate impurity-removal and brightness technology announced 2026-07.', 'ES check 2026-10-16: current output not public. Paper GCC with slurry - FCC co-production candidate 1 (GCC side).'),
  ('omya.*(spain|espa)', 'Omya Specialty Materials Spain - Barcelona', 'Catalonia', 'Barcelona', null, 'Omya 스페인 법인(Carrer de Pallars 180 C, 바르셀로나) — 펄프·제지 주요 시장, 위성공장 모델.', 'Omya Specialty Materials (Spain) SLU, Carrer de Pallars 180 C, Barcelona - pulp and paper named as a main market, satellite-plant model.', 'ES check 2026-10-16: office address - Spanish plants not confirmed. +34 93 566 61 66. Royalty licensee at Omya HQ level.'),
  ('tricalsa|triturados c[aá]lcicos', 'TRICALSA - Arganda del Rey', 'Madrid', 'Arganda del Rey', null, '1983년 설립 가족기업 — Arganda del Rey 천연 탄산칼슘 채굴·분쇄·미분쇄.', 'Triturados Cálcicos S.A. (TRICALSA, 1983, family-owned), Arganda del Rey (Madrid) - natural calcium carbonate quarrying, grinding and micronising.', 'ES check 2026-10-16: paper sales and slurry not confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'spain_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calmit Llierca (CALPREC PCC) - Argelaguer', 'PCC producer', 'Independent PCC maker with paper history - candidate 1', 'merchant', 'B', 'pcc'),
  ('Reverté Minerals - Albox', 'GCC producer', 'Paper GCC with slurry - co-production candidate', 'merchant', 'B', 'gcc'),
  ('Omya Specialty Materials Spain - Barcelona', 'GCC and PCC supplier', 'Omya Spain - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('TRICALSA - Arganda del Rey', 'GCC producer', 'Micronised GCC', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'spain_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'ES', v.region, v.city, v.website, 'active', 'spain_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('torraspapel', 'zaragoza', 'torraspapel|lecta', 'Torraspapel (Lecta) - Zaragoza', 'Aragon', 'Zaragoza', null, 'Lecta 계열 Torraspapel — Zaragoza(펄프·비도공 특수지·원지), Sant Joan les Fonts(코팅지·판지), Motril(원지·편면코팅·이형지), Leitza(감열지 등).', 'Torraspapel (Lecta group) - Zaragoza (pulp, uncoated specialty and base papers), Sant Joan les Fonts (coated, food-service, board, specialty), Motril (base paper, one-side coated, release), Leitza (thermal, carbonless, metallised).', 'ES check 2026-10-16: Lecta restructuring - current mills and ownership to confirm. One row for the Spanish mills.'),
  ('\mict ib[eé]rica', 'burgo de ebro', '\mict\M|tronchetti', 'ICT Ibérica - El Burgo de Ebro', 'Aragon', 'El Burgo de Ebro', null, 'ICT Group 스페인 티슈 공장(El Burgo de Ebro) — 2005 가동, 2018 2호기 후 7만→15만 t, 원지·가공 통합.', 'ICT Ibérica (ICT Group), El Burgo de Ebro (Zaragoza) - integrated tissue mill since 2005, second machine 2018 raised capacity to 150,000 t/yr (was 70,000), toilet and kitchen tissue.', 'ES check 2026-10-16: '),
  ('gom[aà].?camps', 'la riba|valls|vilaverd', 'gom[aà]', 'Gomà-Camps - La Riba', 'Catalonia', 'La Riba', null, '1758년부터 제지 — 티슈 원지 연 6만 t, 완제품 6.5만 t(24라인), La Riba·Valls·Vilaverd(Tarragona), 버진·재생.', 'Gomà-Camps (papermaking since 1758), La Riba, Valls and Vilaverd (Tarragona) - tissue base paper 60,000 t/yr and finished products 65,000 t/yr on 24 lines, virgin and recycled fibre.', 'ES check 2026-10-16: base paper and finished goods are the same flow - only 60 kt counted.'),
  ('sofidel', 'bu[nñ]uel', 'sofidel', 'Sofidel Spain - Buñuel', 'Navarre', 'Buñuel', null, 'Sofidel 스페인 제지·가공 공장(Buñuel, Navarra).', 'Sofidel Spain, Polígono Industrial Calle B 16, Buñuel (Navarre) - tissue paper mill and converting for Iberia (EUR 80-90 m expansion reported to triple output).', 'ES check 2026-10-16: capacity not public here. +34 948 832080.'),
  ('essity.*allo|\mallo\M.*tissue', 'allo', 'essity', 'Essity - Allo', 'Navarre', 'Allo', null, 'Essity 스페인 티슈 공장(Allo) — Tork·Colhogar, 스페인 약 1,200명(Puigpelat·Telde 별도).', 'Essity Spain - tissue mill at Allo (Navarre), brands Tork, Colhogar, TENA, about 1,200 staff in Spain (other sites Puigpelat, Telde).', 'ES check 2026-10-16: capacity not public here.'),
  ('saica.*burgo', 'burgo de ebro', 'saica', 'Saica Paper - El Burgo de Ebro', 'Aragon', 'El Burgo de Ebro', null, 'Saica 최대 공장(El Burgo de Ebro) PM8·PM9·PM10 연 131만 t — 재생 골판지원지·경량·화이트탑.', 'Saica Paper, El Burgo de Ebro (Zaragoza) - PM8, PM9 and PM10, 1,310,000 t/yr recycled containerboard, lightweight and white-top grades.', 'ES check 2026-10-16: strength-led - white-top and lightweight angle only.'),
  ('saica.*zaragoza', 'zaragoza', 'saica', 'Saica Paper - Zaragoza', 'Aragon', 'Zaragoza', null, 'Saica Zaragoza PM6·PM7 연 56.5만 t 재생 골판지원지.', 'Saica Paper, Zaragoza - PM6 and PM7, 565,000 t/yr recycled containerboard.', 'ES check 2026-10-16: '),
  ('hinojosa.*alquer|alquer[ií]a', 'alquer', 'hinojosa', 'Hinojosa Paper Alquería - Alquería de Aznar', 'Valencia', 'Alquería de Aznar', null, 'Hinojosa Packaging 자체 원지 공장(Alquería de Aznar) — 재생 포장용지, 계열 Papelera de Sarrià(Girona).', 'Hinojosa Paper Alquería (Hinojosa Packaging Group), Alquería de Aznar (Alicante) - recycled packaging paper for the group box plants, sister mill Papelera de Sarrià (Sarrià de Ter, Girona).', 'ES check 2026-10-16: capacity not public here.'),
  ('smurfit.*sang[uü]esa|sang[uü]esa', 'sang[uü]esa', 'smurfit|westrock', 'Smurfit Westrock Sangüesa', 'Navarre', 'Sangüesa', null, 'Smurfit Westrock Sangüesa MG 크라프트 포장지 연 약 9만 t(버진펄프).', 'Smurfit Westrock Sangüesa (Navarre) - MG kraft packaging paper about 90,000 t/yr, mainly virgin pulp. Other Spanish sites: Nervión / Iurreta (Bizkaia), Mengíbar (Jaén).', 'ES check 2026-10-16: food-contact and strength checks first.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ES check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('torraspapel', 'zaragoza', 'torraspapel|lecta', 'Lecta 계열 Torraspapel — Zaragoza(펄프·비도공 특수지·원지), Sant Joan les Fonts(코팅지·판지), Motril(원지·편면코팅·이형지), Leitza(감열지 등).', 'Torraspapel (Lecta group) - Zaragoza (pulp, uncoated specialty and base papers), Sant Joan les Fonts (coated, food-service, board, specialty), Motril (base paper, one-side coated, release), Leitza (thermal, carbonless, metallised).', 'ES check 2026-10-16: Lecta restructuring - current mills and ownership to confirm. One row for the Spanish mills.'),
  ('\mict ib[eé]rica', 'burgo de ebro', '\mict\M|tronchetti', 'ICT Group 스페인 티슈 공장(El Burgo de Ebro) — 2005 가동, 2018 2호기 후 7만→15만 t, 원지·가공 통합.', 'ICT Ibérica (ICT Group), El Burgo de Ebro (Zaragoza) - integrated tissue mill since 2005, second machine 2018 raised capacity to 150,000 t/yr (was 70,000), toilet and kitchen tissue.', 'ES check 2026-10-16: '),
  ('gom[aà].?camps', 'la riba|valls|vilaverd', 'gom[aà]', '1758년부터 제지 — 티슈 원지 연 6만 t, 완제품 6.5만 t(24라인), La Riba·Valls·Vilaverd(Tarragona), 버진·재생.', 'Gomà-Camps (papermaking since 1758), La Riba, Valls and Vilaverd (Tarragona) - tissue base paper 60,000 t/yr and finished products 65,000 t/yr on 24 lines, virgin and recycled fibre.', 'ES check 2026-10-16: base paper and finished goods are the same flow - only 60 kt counted.'),
  ('sofidel', 'bu[nñ]uel', 'sofidel', 'Sofidel 스페인 제지·가공 공장(Buñuel, Navarra).', 'Sofidel Spain, Polígono Industrial Calle B 16, Buñuel (Navarre) - tissue paper mill and converting for Iberia (EUR 80-90 m expansion reported to triple output).', 'ES check 2026-10-16: capacity not public here. +34 948 832080.'),
  ('essity.*allo|\mallo\M.*tissue', 'allo', 'essity', 'Essity 스페인 티슈 공장(Allo) — Tork·Colhogar, 스페인 약 1,200명(Puigpelat·Telde 별도).', 'Essity Spain - tissue mill at Allo (Navarre), brands Tork, Colhogar, TENA, about 1,200 staff in Spain (other sites Puigpelat, Telde).', 'ES check 2026-10-16: capacity not public here.'),
  ('saica.*burgo', 'burgo de ebro', 'saica', 'Saica 최대 공장(El Burgo de Ebro) PM8·PM9·PM10 연 131만 t — 재생 골판지원지·경량·화이트탑.', 'Saica Paper, El Burgo de Ebro (Zaragoza) - PM8, PM9 and PM10, 1,310,000 t/yr recycled containerboard, lightweight and white-top grades.', 'ES check 2026-10-16: strength-led - white-top and lightweight angle only.'),
  ('saica.*zaragoza', 'zaragoza', 'saica', 'Saica Zaragoza PM6·PM7 연 56.5만 t 재생 골판지원지.', 'Saica Paper, Zaragoza - PM6 and PM7, 565,000 t/yr recycled containerboard.', 'ES check 2026-10-16: '),
  ('hinojosa.*alquer|alquer[ií]a', 'alquer', 'hinojosa', 'Hinojosa Packaging 자체 원지 공장(Alquería de Aznar) — 재생 포장용지, 계열 Papelera de Sarrià(Girona).', 'Hinojosa Paper Alquería (Hinojosa Packaging Group), Alquería de Aznar (Alicante) - recycled packaging paper for the group box plants, sister mill Papelera de Sarrià (Sarrià de Ter, Girona).', 'ES check 2026-10-16: capacity not public here.'),
  ('smurfit.*sang[uü]esa|sang[uü]esa', 'sang[uü]esa', 'smurfit|westrock', 'Smurfit Westrock Sangüesa MG 크라프트 포장지 연 약 9만 t(버진펄프).', 'Smurfit Westrock Sangüesa (Navarre) - MG kraft packaging paper about 90,000 t/yr, mainly virgin pulp. Other Spanish sites: Nervión / Iurreta (Bizkaia), Mengíbar (Jaén).', 'ES check 2026-10-16: food-contact and strength checks first.'),
  ('papelera de sarri[aà]', null, 'papelera de sarri[aà]', null, null, 'ES check 2026-10-16: Papelera de Sarrià, Sarrià de Ter - recycled packaging paper - context only.'),
  ('northwood|dicepa', null, 'northwood|dicepa', null, null, 'ES check 2026-10-16: Tissue, Navarre - details to collect - context only.'),
  ('ds smith.*due[nñ]as|europac', null, 'ds smith.*due[nñ]as|europac', null, null, 'ES check 2026-10-16: Dueñas containerboard (ex Europac) - context only.'),
  ('smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)', null, 'smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)', null, null, 'ES check 2026-10-16: Mengíbar containerboard and Nervión / Iurreta sites - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'spain_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('torraspapel', 'zaragoza', 'torraspapel|lecta'),
  ('\mict ib[eé]rica', 'burgo de ebro', '\mict\M|tronchetti'),
  ('gom[aà].?camps', 'la riba|valls|vilaverd', 'gom[aà]'),
  ('sofidel', 'bu[nñ]uel', 'sofidel'),
  ('essity.*allo|\mallo\M.*tissue', 'allo', 'essity'),
  ('saica.*burgo', 'burgo de ebro', 'saica'),
  ('saica.*zaragoza', 'zaragoza', 'saica'),
  ('hinojosa.*alquer|alquer[ií]a', 'alquer', 'hinojosa'),
  ('smurfit.*sang[uü]esa|sang[uü]esa', 'sang[uü]esa', 'smurfit|westrock'),
  ('papelera de sarri[aà]', null, 'papelera de sarri[aà]'),
  ('northwood|dicepa', null, 'northwood|dicepa'),
  ('ds smith.*due[nñ]as|europac', null, 'ds smith.*due[nñ]as|europac'),
  ('smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)', null, 'smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('torraspapel', 'zaragoza', 'torraspapel|lecta',
   $pj${"owner": "Lecta", "priority": 1, "products": "Uncoated specialty, base paper, coated paper", "grades": ["UWF", "Specialty paper", "Coated paper"], "pitch": "Internal filler swap on uncoated specialty and base paper", "approach": "Lead Spanish account - Calmit Llierca or Reverté as producer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mict ib[eé]rica', 'burgo de ebro', '\mict\M|tronchetti',
   $pj${"owner": "ICT Group", "priority": 2, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 150000, "unit": "metric_t", "year": "Company (2018)", "source": "ictgroup.it"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "FCC 1-5 pct tissue trial - link with ICT Italy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gom[aà].?camps', 'la riba|valls|vilaverd', 'gom[aà]',
   $pj${"owner": "Gomà-Camps", "priority": 3, "products": "Tissue base paper, toilet, napkins, AfH", "grades": ["Tissue"], "capacity": {"value": 60000, "unit": "metric_t", "year": "Company (base paper)", "source": "gomacamps.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Easier first trial - virgin vs recycled.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel', 'bu[nñ]uel', 'sofidel',
   $pj${"owner": "Sofidel", "priority": 4, "products": "Tissue", "grades": ["Tissue"], "approach": "Group trial path with Sofidel Italy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*allo|\mallo\M.*tissue', 'allo', 'essity',
   $pj${"owner": "Essity", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "approach": "Global R&D route.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saica.*burgo', 'burgo de ebro', 'saica',
   $pj${"owner": "Saica", "priority": 6, "products": "Recycled containerboard, white-top", "grades": ["Testliner", "Medium", "White-top liner"], "machines": 3, "capacity": {"value": 1310000, "unit": "metric_t", "year": "Company site", "source": "saica.com"}, "approach": "White-top and drying-energy angle.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saica.*zaragoza', 'zaragoza', 'saica',
   $pj${"owner": "Saica", "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "machines": 2, "capacity": {"value": 565000, "unit": "metric_t", "year": "Company site", "source": "saica.com"}, "approach": "After El Burgo.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hinojosa.*alquer|alquer[ií]a', 'alquer', 'hinojosa',
   $pj${"owner": "Hinojosa", "priority": 7, "products": "Recycled packaging paper", "grades": ["Testliner", "Medium"], "approach": "Recycled-fibre saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*sang[uü]esa|sang[uü]esa', 'sang[uü]esa', 'smurfit|westrock',
   $pj${"owner": "Smurfit Westrock", "priority": 8, "products": "MG kraft", "grades": ["MG paper"], "capacity": {"value": 90000, "unit": "metric_t", "year": "Company figure", "source": "smurfitwestrock.com"}, "approach": "Grade-specific co-development.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papelera de sarri[aà]', null, 'papelera de sarri[aà]',
   $pj${"owner": "Hinojosa", "products": "Papelera de Sarrià, Sarrià de Ter - recycled packaging paper", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('northwood|dicepa', null, 'northwood|dicepa',
   $pj${"owner": "Northwood Dicepa", "products": "Tissue, Navarre - details to collect", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*due[nñ]as|europac', null, 'ds smith.*due[nñ]as|europac',
   $pj${"owner": "DS Smith (International Paper)", "products": "Dueñas containerboard (ex Europac)", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)', null, 'smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)',
   $pj${"owner": "Smurfit Westrock", "products": "Mengíbar containerboard and Nervión / Iurreta sites", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ES', 'Spain', 'high',
   $cm$6.3 Mt paper and board - Torraspapel specialty, ICT Ibérica (150 kt) and Gomà-Camps tissue - Calmit Llierca PCC and Reverté GCC$cm$,
   $cm$Spain made 6.31 Mt paper and board and 1.62 Mt pulp in 2025 (EUR 5.09 bn, 5th in Europe), mostly recycled packaging. FCC-fit: Torraspapel (Lecta, uncoated specialty and base paper), tissue at ICT Ibérica (150 kt), Gomà-Camps (60 kt), Sofidel Buñuel and Essity Allo. Large containerboard at Saica (1.88 Mt in two mills), Hinojosa, Smurfit Westrock. Fillers: Calmit Llierca (Calcinor) makes CALPREC PCC since 1977 with paper roots, Reverté Minerals makes paper GCC and slurry (Albox, Castellet), Omya Spain, TRICALSA.$cm$,
   $cm${"fillers": "PCC: Calmit Llierca (Calcinor group). GCC: Reverté Minerals (Albox, Castellet i la Gornal), TRICALSA, Omya Spain (licensee).", "mills": "Specialty and printing: Torraspapel. Tissue: ICT Ibérica, Gomà-Camps, Sofidel Buñuel, Essity Allo. Packaging: Saica El Burgo and Zaragoza, Hinojosa Alquería, Smurfit Westrock Sangüesa. Context: Papelera de Sarrià, Northwood Dicepa, DS Smith Dueñas, other Smurfit sites.", "strategy": "Three-way deals: Calmit Llierca PCC or Reverté GCC with Torraspapel (printing) and ICT Ibérica, Gomà-Camps (tissue). Zaragoza cluster for site visits.", "risks": "Lecta restructuring, packaging strength limits.", "next_steps": ["Approach Calmit Llierca on an FCC pilot", "Propose tissue trials to ICT Ibérica and Gomà-Camps"], "key_numbers": [{"label": "2025 output", "value": "6.31 Mt paper and board, 1.62 Mt pulp"}, {"label": "Saica Spain", "value": "1.88 Mt (5 machines)"}, {"label": "ICT Ibérica", "value": "150 kt tissue"}], "files": ["seed_20261016zq_spain_mills_fillers"]}$cm$::jsonb,
   $cm$종이·판지 630만 t — Torraspapel 특수지, ICT Ibérica(15만 t)·Gomà-Camps 티슈 — Calmit Llierca PCC·Reverté GCC$cm$,
   $cm$스페인 2025 종이·판지 631만 t, 펄프 162만 t(50.9억 유로, 유럽 5위), 대부분 재생 포장용지. FCC 적합: Torraspapel(Lecta, 비도공 특수지·원지), 티슈 ICT Ibérica(15만 t)·Gomà-Camps(6만 t)·Sofidel Buñuel·Essity Allo. 대형 골판지원지 Saica(2개 공장 188만 t)·Hinojosa·Smurfit. 충전제: Calmit Llierca(Calcinor) 1977년부터 CALPREC PCC(제지 이력), Reverté Minerals 제지용 GCC·슬러리, Omya Spain, TRICALSA.$cm$,
   6300, 10500,
   $cm$ICT Ibérica 15만 + Gomà-Camps 6만 t 티슈 × FCC 3~5% (Torraspapel 생산량 미공개로 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('torraspapel', 'zaragoza', 'torraspapel|lecta'),
  ('\mict ib[eé]rica', 'burgo de ebro', '\mict\M|tronchetti'),
  ('gom[aà].?camps', 'la riba|valls|vilaverd', 'gom[aà]'),
  ('sofidel', 'bu[nñ]uel', 'sofidel'),
  ('essity.*allo|\mallo\M.*tissue', 'allo', 'essity'),
  ('saica.*burgo', 'burgo de ebro', 'saica'),
  ('saica.*zaragoza', 'zaragoza', 'saica'),
  ('hinojosa.*alquer|alquer[ií]a', 'alquer', 'hinojosa'),
  ('smurfit.*sang[uü]esa|sang[uü]esa', 'sang[uü]esa', 'smurfit|westrock'),
  ('papelera de sarri[aà]', null, 'papelera de sarri[aà]'),
  ('northwood|dicepa', null, 'northwood|dicepa'),
  ('ds smith.*due[nñ]as|europac', null, 'ds smith.*due[nñ]as|europac'),
  ('smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)', null, 'smurfit.*(mengibar|mengíbar|nervi[oó]n|iurreta)')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'spain_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'spain_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'llierca|calprec' or p.party_name ~* 'revert[eé] minerals' or p.party_name ~* 'omya.*(spain|espa)' or p.party_name ~* 'tricalsa|triturados c[aá]lcicos')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ES'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ES'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ES'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ES'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    