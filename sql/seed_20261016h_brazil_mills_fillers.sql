-- ============================================================
-- seed_20261016h_brazil_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Brazil update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'BR check 2026-10-15'.
-- Many BR rows may exist - name regex OR city + owner regex first.
-- 1) Fillers if missing (8): Specialty Minerals (Brazil), Imerys Brás Cubas,
--    Imerys Cachoeiro, Imerys Quixeré, Omya do Brasil, Mineração São Judas,
--    Fillercal, Carbomil.
-- 2) Mills if missing (21) + plant blocks, priority 1-8: Sylvamo x3, Suzano
--    x6, BO Paper x2, Bracell, Softys, Klabin x2, Santher, Smurfit Westrock
--    Três Barras, Irani, CMPC Piraí do Sul. Group totals kept on one row.
--    Context: Papirus, Mili, Melhoramentos.
-- 3) Supply links (5): SMI -> Suzano and Mucuri (active), SMI -> Luiz Antônio,
--    Omya -> Mogi Guaçu and Três Lagoas (historical).
-- 4) app.country_markets BR row (priority high).
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
           v.party_name, 'BR', v.region, v.city, v.website, 'active', 'brazil_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('(specialty minerals|minerals technologies).*bra[sz]il', 'Specialty Minerals (Brazil)', null, null, null, 'Minerals Technologies(SMI) 브라질 위성 PCC 사업. SEC 공시상 Suzano·Mucuri·Jacareí·Luiz Antônio 4곳. 2023-07 기존 브라질 PCC 공장에 NewYield LO 적용 계약.', 'Specialty Minerals, Minerals Technologies do Brasil - satellite PCC plants listed in MTI SEC filings at Suzano (SP, built 1996, expanded 2009, 25,000-35,000 t/yr per unit), Mucuri (BA, Bahia Sul / Suzano), Jacareí and Luiz Antônio (SP, ex Votorantim Celulose e Papel). 2023-07: NewYield LO PCC (mill waste streams to filler) contract at an existing Brazilian PCC plant.', 'BR check 2026-10-15: four-site total 175,000-245,000 t/yr in 2005 data - current output not public. Royalty licensee at MTI HQ level.'),
  ('imerys.*(br[aá]s cubas|mogi)', 'Imerys - Brás Cubas (Mogi das Cruzes)', 'São Paulo', 'Mogi das Cruzes', null, 'Imerys 브라질 Brás Cubas(Mogi das Cruzes) 탄산칼슘 공장 — 연 약 18.5만 t, 약 68% 습식분쇄, 제지·도료·플라스틱·식품 공급(2025).', 'Imerys - Brás Cubas carbonate plant, Mogi das Cruzes (SP): about 185,000 t/yr processed calcium carbonate, about 68 pct by wet grinding, for paper, paint, plastics and food (2025). Imerys Brazil carbonates: six plants, about 400,000 t/yr installed (2025 report).', 'BR check 2026-10-15: paper share of the 185 kt not public. Historical Imerys PCC (ex Quimbarra) at Arcos (stand-alone), Limeira and Santanésia (satellites) - current status to confirm.'),
  ('imerys.*cachoeiro', 'Imerys - Cachoeiro de Itapemirim', 'Espírito Santo', 'Cachoeiro de Itapemirim', null, 'Imerys 의 Espírito Santo Cachoeiro de Itapemirim 천연 탄산칼슘 미세분쇄·분쇄 공장.', 'Imerys - natural calcium carbonate fine and standard grinding at Cachoeiro de Itapemirim, Espírito Santo (2023 mining data).', 'BR check 2026-10-15: paper slurry output not confirmed.'),
  ('imerys.*quixer', 'Imerys - Quixeré (Ceará)', 'Ceará', 'Quixeré', null, 'Imerys Quixeré(Ceará) 신규 탄산칼슘 가공시설(2024-09 가동).', 'Imerys - new calcium carbonate processing plant at Quixeré, Ceará, started 2024-09.', 'BR check 2026-10-15: product mix not public.'),
  ('omya.*bra[sz]il', 'Omya do Brasil', null, null, null, 'Omya 브라질 법인 — 제지 충전·코팅. 과거 기록: Ponta Grossa(PR) GCC, Mogi Guaçu(SP)·Três Lagoas(MS) PCC 공장 운영지원(2008~2010), Cachoeiro de Itapemirim 사업장.', 'Omya do Brasil - pulp and paper filler and coating (Hydrocarb, Syncarb, Omyaboard, Multifill, FiberLean). 2008-2010 records: GCC plant at Ponta Grossa (PR), PCC plant operation support at Mogi Guaçu (SP) and Três Lagoas (MS), site at Cachoeiro de Itapemirim (ES).', 'BR check 2026-10-15: current plant status not confirmed - addresses registered in 2026. Royalty licensee at Omya HQ level, also holds competing fibre-mineral tech (Multifill, FiberLean).'),
  ('s[aã]o judas', 'Mineração São Judas', 'São Paulo', 'Bom Sucesso de Itararé', null, '1972년 설립 광물 업체. 제지·판지용 천연 탄산칼슘 슬러리(백색도 90 ISO, SiO2 <0.5%, MgO <2%). 공장 Bom Sucesso de Itararé(SP)·Sengés·Ponta Grossa(PR).', 'Mineração São Judas (1972) - natural calcium carbonate slurry for paper and board (90 ISO brightness, SiO2 under 0.5 pct, MgO under 2 pct), plants at Bom Sucesso de Itararé (SP), Sengés and Ponta Grossa (PR), own trucking.', 'BR check 2026-10-15: vendas@saojudas.com.br, +55 15 3531-8100. Slurry volume and mill customers not public. Local FCC pilot partner candidate.'),
  ('fillercal', 'Fillercal', 'Goiás', 'Indiara', null, '1994년 설립 Indiara(Goiás) GCC 채굴·분쇄. 자체 광산 최대 연 100만 t, 2021 PVC용 미분.', 'Fillercal (1994), Indiara, Goiás - own limestone mine (up to 1 Mt/yr extraction), grinding and micronising, PVC grades since 2021.', 'BR check 2026-10-15: paper slurry not confirmed - mine figure is not GCC output.'),
  ('carbomil', 'Carbomil', 'Ceará', 'Limoeiro do Norte', null, 'Limoeiro do Norte(Ceará) 천연 탄산칼슘 공장, Microfluid 미분.', 'Carbomil - natural calcium carbonate plant at Limoeiro do Norte, Ceará (office Fortaleza), Microfluid micronised grades for plastics, paint, rubber.', 'BR check 2026-10-15: paper grades not confirmed. +55 85 3636-0901. Not added: Minerjato (paper named, production unconfirmed).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('(specialty minerals|minerals technologies).*bra[sz]il', 'Specialty Minerals (Brazil)', null, null, null, 'Minerals Technologies(SMI) 브라질 위성 PCC 사업. SEC 공시상 Suzano·Mucuri·Jacareí·Luiz Antônio 4곳. 2023-07 기존 브라질 PCC 공장에 NewYield LO 적용 계약.', 'Specialty Minerals, Minerals Technologies do Brasil - satellite PCC plants listed in MTI SEC filings at Suzano (SP, built 1996, expanded 2009, 25,000-35,000 t/yr per unit), Mucuri (BA, Bahia Sul / Suzano), Jacareí and Luiz Antônio (SP, ex Votorantim Celulose e Papel). 2023-07: NewYield LO PCC (mill waste streams to filler) contract at an existing Brazilian PCC plant.', 'BR check 2026-10-15: four-site total 175,000-245,000 t/yr in 2005 data - current output not public. Royalty licensee at MTI HQ level.'),
  ('imerys.*(br[aá]s cubas|mogi)', 'Imerys - Brás Cubas (Mogi das Cruzes)', 'São Paulo', 'Mogi das Cruzes', null, 'Imerys 브라질 Brás Cubas(Mogi das Cruzes) 탄산칼슘 공장 — 연 약 18.5만 t, 약 68% 습식분쇄, 제지·도료·플라스틱·식품 공급(2025).', 'Imerys - Brás Cubas carbonate plant, Mogi das Cruzes (SP): about 185,000 t/yr processed calcium carbonate, about 68 pct by wet grinding, for paper, paint, plastics and food (2025). Imerys Brazil carbonates: six plants, about 400,000 t/yr installed (2025 report).', 'BR check 2026-10-15: paper share of the 185 kt not public. Historical Imerys PCC (ex Quimbarra) at Arcos (stand-alone), Limeira and Santanésia (satellites) - current status to confirm.'),
  ('imerys.*cachoeiro', 'Imerys - Cachoeiro de Itapemirim', 'Espírito Santo', 'Cachoeiro de Itapemirim', null, 'Imerys 의 Espírito Santo Cachoeiro de Itapemirim 천연 탄산칼슘 미세분쇄·분쇄 공장.', 'Imerys - natural calcium carbonate fine and standard grinding at Cachoeiro de Itapemirim, Espírito Santo (2023 mining data).', 'BR check 2026-10-15: paper slurry output not confirmed.'),
  ('imerys.*quixer', 'Imerys - Quixeré (Ceará)', 'Ceará', 'Quixeré', null, 'Imerys Quixeré(Ceará) 신규 탄산칼슘 가공시설(2024-09 가동).', 'Imerys - new calcium carbonate processing plant at Quixeré, Ceará, started 2024-09.', 'BR check 2026-10-15: product mix not public.'),
  ('omya.*bra[sz]il', 'Omya do Brasil', null, null, null, 'Omya 브라질 법인 — 제지 충전·코팅. 과거 기록: Ponta Grossa(PR) GCC, Mogi Guaçu(SP)·Três Lagoas(MS) PCC 공장 운영지원(2008~2010), Cachoeiro de Itapemirim 사업장.', 'Omya do Brasil - pulp and paper filler and coating (Hydrocarb, Syncarb, Omyaboard, Multifill, FiberLean). 2008-2010 records: GCC plant at Ponta Grossa (PR), PCC plant operation support at Mogi Guaçu (SP) and Três Lagoas (MS), site at Cachoeiro de Itapemirim (ES).', 'BR check 2026-10-15: current plant status not confirmed - addresses registered in 2026. Royalty licensee at Omya HQ level, also holds competing fibre-mineral tech (Multifill, FiberLean).'),
  ('s[aã]o judas', 'Mineração São Judas', 'São Paulo', 'Bom Sucesso de Itararé', null, '1972년 설립 광물 업체. 제지·판지용 천연 탄산칼슘 슬러리(백색도 90 ISO, SiO2 <0.5%, MgO <2%). 공장 Bom Sucesso de Itararé(SP)·Sengés·Ponta Grossa(PR).', 'Mineração São Judas (1972) - natural calcium carbonate slurry for paper and board (90 ISO brightness, SiO2 under 0.5 pct, MgO under 2 pct), plants at Bom Sucesso de Itararé (SP), Sengés and Ponta Grossa (PR), own trucking.', 'BR check 2026-10-15: vendas@saojudas.com.br, +55 15 3531-8100. Slurry volume and mill customers not public. Local FCC pilot partner candidate.'),
  ('fillercal', 'Fillercal', 'Goiás', 'Indiara', null, '1994년 설립 Indiara(Goiás) GCC 채굴·분쇄. 자체 광산 최대 연 100만 t, 2021 PVC용 미분.', 'Fillercal (1994), Indiara, Goiás - own limestone mine (up to 1 Mt/yr extraction), grinding and micronising, PVC grades since 2021.', 'BR check 2026-10-15: paper slurry not confirmed - mine figure is not GCC output.'),
  ('carbomil', 'Carbomil', 'Ceará', 'Limoeiro do Norte', null, 'Limoeiro do Norte(Ceará) 천연 탄산칼슘 공장, Microfluid 미분.', 'Carbomil - natural calcium carbonate plant at Limoeiro do Norte, Ceará (office Fortaleza), Microfluid micronised grades for plastics, paint, rubber.', 'BR check 2026-10-15: paper grades not confirmed. +55 85 3636-0901. Not added: Minerjato (paper named, production unconfirmed).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'brazil_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Specialty Minerals (Brazil)', 'PCC producer', 'Satellite PCC at Suzano mills - royalty licensee (MTI HQ)', 'satellite (on-site)', 'B', 'pcc'),
  ('Imerys - Brás Cubas (Mogi das Cruzes)', 'GCC producer', 'Wet-ground GCC slurry - FCC production candidate', 'merchant', 'B', 'gcc'),
  ('Imerys - Cachoeiro de Itapemirim', 'GCC producer', 'GCC grinding', 'merchant', 'C', 'gcc'),
  ('Imerys - Quixeré (Ceará)', 'GCC producer', 'New GCC plant (northeast)', 'merchant', 'C', 'gcc'),
  ('Omya do Brasil', 'GCC and PCC supplier', 'Omya do Brasil - royalty licensee (Omya HQ)', 'satellite (on-site)', 'C', 'gcc'),
  ('Mineração São Judas', 'GCC producer', 'Paper GCC slurry - local pilot partner', 'merchant', 'B', 'gcc'),
  ('Fillercal', 'GCC producer', 'GCC raw material and new-line candidate', 'merchant', 'C', 'gcc'),
  ('Carbomil', 'GCC producer', 'Northeast GCC', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'brazil_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BR', v.region, v.city, v.website, 'active', 'brazil_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper', 'Sylvamo - Mogi Guaçu', 'São Paulo', 'Mogi Guaçu', null, 'Sylvamo(IP 분사) 브라질 비도공지(Chamex·Chamequinho) 공장 Mogi Guaçu. 라틴아메리카 비도공지 연 110만 short t(약 100만 t, 2025).', 'Sylvamo (International Paper spin-off) - Mogi Guaçu (SP) uncoated freesheet, copy and offset paper (Chamex, Chamequinho). Latin America UFS capacity 1.1 m short t/yr (about 1.0 Mt, 2025 annual report) across Mogi Guaçu, Luiz Antônio and Três Lagoas.', 'BR check 2026-10-15: site split not public - LatAm total kept on this row only. Omya supported a PCC plant here (2008-2010).'),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper', 'Sylvamo - Luiz Antônio', 'São Paulo', 'Luiz Antônio', null, 'Sylvamo Luiz Antônio(SP) 비도공지 공장. 과거 Votorantim 시절 SMI 위성 PCC.', 'Sylvamo - Luiz Antônio (SP) uncoated freesheet mill (ex Votorantim Celulose e Papel, later International Paper) - SMI satellite PCC in MTI filings.', 'BR check 2026-10-15: capacity inside the LatAm total on the Mogi Guaçu row.'),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper', 'Sylvamo - Três Lagoas', 'Mato Grosso do Sul', 'Três Lagoas', null, 'Sylvamo Três Lagoas(MS) 라틴아메리카 생산 네트워크 사업장.', 'Sylvamo - Três Lagoas (MS) site of its Latin American network. Omya supported a PCC plant here (2008-2010).', 'BR check 2026-10-15: paper machine scope to confirm.'),
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano', 'Suzano - Suzano (SP)', 'São Paulo', 'Suzano', null, 'Suzano 의 Suzano(SP) 공장 — 인쇄·필기용지 35만 t + 판지 20만 t(IR 설계능력). SMI 위성 PCC(1996 건설, 2009 증설).', 'Suzano S.A. - Suzano (SP) mill: printing and writing paper 350,000 t/yr (incl. swing lines) and paperboard 200,000 t/yr (IR nameplate). SMI satellite PCC since 1996, expanded 2009. Brands Report, Paperfect. Suzano sold about 944,600 t P&W in 2025 (45.3 pct of Brazilian makers domestic sales).', 'BR check 2026-10-15: current PCC supplier contract to confirm.'),
  ('suzano.*limeira', 'limeira', 'suzano', 'Suzano - Limeira', 'São Paulo', 'Limeira', null, 'Suzano Limeira(SP) 인쇄·필기용지 공장, 연 40만 t. 과거 Imerys 위성 PCC 기록.', 'Suzano S.A. - Limeira (SP) printing and writing paper, 400,000 t/yr (IR). Older records show an Imerys satellite PCC at a Limeira paper mill.', 'BR check 2026-10-15: current filler supplier to confirm.'),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul', 'Suzano - Mucuri', 'Bahia', 'Mucuri', null, 'Suzano Mucuri(BA) 인쇄·필기용지 25만 t + 티슈 6만 t. SMI 위성 PCC(구 Bahia Sul).', 'Suzano S.A. - Mucuri (BA): printing and writing paper 250,000 t/yr and tissue 60,000 t/yr (IR). SMI satellite PCC (ex Bahia Sul).', 'BR check 2026-10-15: current PCC contract to confirm.'),
  ('suzano.*mogi das cruzes', 'mogi das cruzes', 'suzano', 'Suzano Tissue - Mogi das Cruzes', 'São Paulo', 'Mogi das Cruzes', null, 'Suzano Mogi das Cruzes 티슈 공장, 연 130,000 t (IR).', 'Suzano S.A. - Mogi das Cruzes tissue mill, 130,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('suzano.*imperatriz', 'imperatriz', 'suzano', 'Suzano Tissue - Imperatriz', 'Maranhão', 'Imperatriz', null, 'Suzano Imperatriz 티슈 공장, 연 60,000 t (IR).', 'Suzano S.A. - Imperatriz tissue mill, 60,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('suzano.*aracruz', 'aracruz', 'suzano', 'Suzano Tissue - Aracruz', 'Espírito Santo', 'Aracruz', null, 'Suzano Aracruz 티슈 공장, 연 60,000 t (IR).', 'Suzano S.A. - Aracruz tissue mill, 60,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('bo paper.*arapoti|arapoti', 'arapoti', 'bo paper|inversiones bo', 'BO Paper - Arapoti', 'Paraná', 'Arapoti', null, 'Inversiones BO 계열 BO Paper Arapoti(PR) — 도공지·인쇄용지·특수지 연 15만 t, TMP 6만 t.', 'BO Paper (Inversiones BO, Chile) - Arapoti (PR): coated and printing papers and specialty grades, 150,000 t/yr, with 60,000 t/yr TMP pulp.', 'BR check 2026-10-15: filler supplier not public.'),
  ('bo paper.*(pisa|jaguar)|\mpisa\M.*jaguar', 'jaguar', 'bo paper|pisa', 'BO Paper - Pisa (Jaguariaíva)', 'Paraná', 'Jaguariaíva', null, 'BO Paper Pisa(Jaguariaíva, PR) — 신문·출판·포장용지 연 약 21만 t.', 'BO Paper - Pisa mill, Jaguariaíva (PR): newsprint, publication and packaging papers, about 210,000 t/yr (ANDRITZ recycled stock line).', 'BR check 2026-10-15: grade mix not public.'),
  ('bracell.*len[cç][oó]is|bracell.*tissue', 'len[cç][oó]is', 'bracell|ol pap', 'Bracell Papéis - Lençóis Paulista', 'São Paulo', 'Lençóis Paulista', null, 'RGE 계열 Bracell 티슈(2023 OL Papéis 인수). Lençóis Paulista 티슈기 4대 24만 t, 2대 12만 t 추가 계획(2026 말, R$50억).', 'Bracell Papéis (RGE, bought OL Papéis in 2023) - Lençóis Paulista (SP) tissue: four machines 240,000 t/yr, two more planned for 120,000 t/yr by end 2026 (about BRL 5 bn) - 360 kt when done. Also Feira de Santana (BA).', 'BR check 2026-10-15: new machines not confirmed running.'),
  ('softys.*caieiras|softys.*bra[sz]il', 'caieiras', 'softys|sepac', 'Softys Brasil - Caieiras', 'São Paulo', 'Caieiras', null, 'CMPC Softys 브라질 티슈(Elite·Sublime·Duetto·Paloma). 2019 SEPAC 인수로 약 28만 t.', 'Softys Brasil (CMPC) - tissue (Elite, Sublime, Duetto, Paloma), Caieiras (SP) and other sites. 2019 SEPAC acquisition raised capacity, 145,000 to about 280,000 t/yr.', 'BR check 2026-10-15: site split not public - 280 kt group figure kept on this row.'),
  ('klabin.*ortigueira|klabin.*puma', 'ortigueira', 'klabin', 'Klabin - Ortigueira (Puma)', 'Paraná', 'Ortigueira', null, 'Klabin Puma 단지(Ortigueira, PR) — 대형 판지·포장용지·펄프.', 'Klabin - Puma complex, Ortigueira (PR): large board, packaging paper and pulp lines. Klabin total pulp, paper and packaging capacity about 4.5 Mt (2025 interview).', 'BR check 2026-10-15: paper capacity by mill not public.'),
  ('klabin.*monte alegre|klabin.*tel[eê]maco', 'tel[eê]maco', 'klabin', 'Klabin - Monte Alegre (Telêmaco Borba)', 'Paraná', 'Telêmaco Borba', null, 'Klabin Monte Alegre(Telêmaco Borba, PR) 판지·포장용지.', 'Klabin - Monte Alegre mill, Telêmaco Borba (PR): board and packaging paper.', 'BR check 2026-10-15: capacity not public.'),
  ('santher.*bragan', 'bragan', 'santher', 'Santher - Bragança Paulista', 'São Paulo', 'Bragança Paulista', null, 'Daio Paper·Marubeni 계열 Santher(Personal·Snob·Kiss) 티슈·특수포장지. 종이 연 약 18만 t(Penha·Bragança Paulista·Guaíba).', 'Santher (Daio Paper / Marubeni group, brands Personal, Snob, Kiss) - tissue and specialty packaging paper, about 180,000 t/yr paper across Penha and Bragança Paulista (SP) and Guaíba (RS).', 'BR check 2026-10-15: site split not public - group total kept on this row.'),
  ('smurfit.*tr[eê]s barras|tr[eê]s barras', 'tr[eê]s barras', 'smurfit|westrock|rigesa', 'Smurfit Westrock - Três Barras', 'Santa Catarina', 'Três Barras', null, 'Smurfit Westrock Três Barras(SC) 크라프트라이너·골판지원지 공장(2025 현대화 3,100만 달러).', 'Smurfit Westrock - Três Barras (SC) kraftliner and corrugating paper mill (ex Rigesa / WestRock), USD 31 m modernisation 2025.', 'BR check 2026-10-15: capacity not public.'),
  ('\mirani\M', null, 'irani', 'Irani Papel e Embalagem', null, null, null, 'Irani — 크라프트지·Kraftliner·Testliner·골심지(SC·RS).', 'Irani Papel e Embalagem S.A. - kraft paper, kraftliner, testliner and medium, mills in Santa Catarina and Rio Grande do Sul.', 'BR check 2026-10-15: mill split not public.'),
  ('cmpc.*pira[ií]|igua[cç]u celulose', 'pira[ií] do sul', 'cmpc|igua', 'CMPC - Piraí do Sul (ex Iguaçu)', 'Paraná', 'Piraí do Sul', null, 'CMPC 가 2022 인수한 Iguaçu Celulose e Papel — sack kraft 12만 t, 특수지 2.1만 t(Piraí do Sul·São José dos Pinhais·Campos Novos).', 'CMPC - ex Iguaçu Celulose e Papel (bought 2022): sack kraft 120,000 t/yr and specialty paper 21,000 t/yr across Piraí do Sul, São José dos Pinhais and Campos Novos.', 'BR check 2026-10-15: group figure kept on this row.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper', 'Sylvamo(IP 분사) 브라질 비도공지(Chamex·Chamequinho) 공장 Mogi Guaçu. 라틴아메리카 비도공지 연 110만 short t(약 100만 t, 2025).', 'Sylvamo (International Paper spin-off) - Mogi Guaçu (SP) uncoated freesheet, copy and offset paper (Chamex, Chamequinho). Latin America UFS capacity 1.1 m short t/yr (about 1.0 Mt, 2025 annual report) across Mogi Guaçu, Luiz Antônio and Três Lagoas.', 'BR check 2026-10-15: site split not public - LatAm total kept on this row only. Omya supported a PCC plant here (2008-2010).'),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper', 'Sylvamo Luiz Antônio(SP) 비도공지 공장. 과거 Votorantim 시절 SMI 위성 PCC.', 'Sylvamo - Luiz Antônio (SP) uncoated freesheet mill (ex Votorantim Celulose e Papel, later International Paper) - SMI satellite PCC in MTI filings.', 'BR check 2026-10-15: capacity inside the LatAm total on the Mogi Guaçu row.'),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper', 'Sylvamo Três Lagoas(MS) 라틴아메리카 생산 네트워크 사업장.', 'Sylvamo - Três Lagoas (MS) site of its Latin American network. Omya supported a PCC plant here (2008-2010).', 'BR check 2026-10-15: paper machine scope to confirm.'),
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano', 'Suzano 의 Suzano(SP) 공장 — 인쇄·필기용지 35만 t + 판지 20만 t(IR 설계능력). SMI 위성 PCC(1996 건설, 2009 증설).', 'Suzano S.A. - Suzano (SP) mill: printing and writing paper 350,000 t/yr (incl. swing lines) and paperboard 200,000 t/yr (IR nameplate). SMI satellite PCC since 1996, expanded 2009. Brands Report, Paperfect. Suzano sold about 944,600 t P&W in 2025 (45.3 pct of Brazilian makers domestic sales).', 'BR check 2026-10-15: current PCC supplier contract to confirm.'),
  ('suzano.*limeira', 'limeira', 'suzano', 'Suzano Limeira(SP) 인쇄·필기용지 공장, 연 40만 t. 과거 Imerys 위성 PCC 기록.', 'Suzano S.A. - Limeira (SP) printing and writing paper, 400,000 t/yr (IR). Older records show an Imerys satellite PCC at a Limeira paper mill.', 'BR check 2026-10-15: current filler supplier to confirm.'),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul', 'Suzano Mucuri(BA) 인쇄·필기용지 25만 t + 티슈 6만 t. SMI 위성 PCC(구 Bahia Sul).', 'Suzano S.A. - Mucuri (BA): printing and writing paper 250,000 t/yr and tissue 60,000 t/yr (IR). SMI satellite PCC (ex Bahia Sul).', 'BR check 2026-10-15: current PCC contract to confirm.'),
  ('suzano.*mogi das cruzes', 'mogi das cruzes', 'suzano', 'Suzano Mogi das Cruzes 티슈 공장, 연 130,000 t (IR).', 'Suzano S.A. - Mogi das Cruzes tissue mill, 130,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('suzano.*imperatriz', 'imperatriz', 'suzano', 'Suzano Imperatriz 티슈 공장, 연 60,000 t (IR).', 'Suzano S.A. - Imperatriz tissue mill, 60,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('suzano.*aracruz', 'aracruz', 'suzano', 'Suzano Aracruz 티슈 공장, 연 60,000 t (IR).', 'Suzano S.A. - Aracruz tissue mill, 60,000 t/yr (IR nameplate).', 'BR check 2026-10-15: tissue FCC needs softness and dust checks.'),
  ('bo paper.*arapoti|arapoti', 'arapoti', 'bo paper|inversiones bo', 'Inversiones BO 계열 BO Paper Arapoti(PR) — 도공지·인쇄용지·특수지 연 15만 t, TMP 6만 t.', 'BO Paper (Inversiones BO, Chile) - Arapoti (PR): coated and printing papers and specialty grades, 150,000 t/yr, with 60,000 t/yr TMP pulp.', 'BR check 2026-10-15: filler supplier not public.'),
  ('bo paper.*(pisa|jaguar)|\mpisa\M.*jaguar', 'jaguar', 'bo paper|pisa', 'BO Paper Pisa(Jaguariaíva, PR) — 신문·출판·포장용지 연 약 21만 t.', 'BO Paper - Pisa mill, Jaguariaíva (PR): newsprint, publication and packaging papers, about 210,000 t/yr (ANDRITZ recycled stock line).', 'BR check 2026-10-15: grade mix not public.'),
  ('bracell.*len[cç][oó]is|bracell.*tissue', 'len[cç][oó]is', 'bracell|ol pap', 'RGE 계열 Bracell 티슈(2023 OL Papéis 인수). Lençóis Paulista 티슈기 4대 24만 t, 2대 12만 t 추가 계획(2026 말, R$50억).', 'Bracell Papéis (RGE, bought OL Papéis in 2023) - Lençóis Paulista (SP) tissue: four machines 240,000 t/yr, two more planned for 120,000 t/yr by end 2026 (about BRL 5 bn) - 360 kt when done. Also Feira de Santana (BA).', 'BR check 2026-10-15: new machines not confirmed running.'),
  ('softys.*caieiras|softys.*bra[sz]il', 'caieiras', 'softys|sepac', 'CMPC Softys 브라질 티슈(Elite·Sublime·Duetto·Paloma). 2019 SEPAC 인수로 약 28만 t.', 'Softys Brasil (CMPC) - tissue (Elite, Sublime, Duetto, Paloma), Caieiras (SP) and other sites. 2019 SEPAC acquisition raised capacity, 145,000 to about 280,000 t/yr.', 'BR check 2026-10-15: site split not public - 280 kt group figure kept on this row.'),
  ('klabin.*ortigueira|klabin.*puma', 'ortigueira', 'klabin', 'Klabin Puma 단지(Ortigueira, PR) — 대형 판지·포장용지·펄프.', 'Klabin - Puma complex, Ortigueira (PR): large board, packaging paper and pulp lines. Klabin total pulp, paper and packaging capacity about 4.5 Mt (2025 interview).', 'BR check 2026-10-15: paper capacity by mill not public.'),
  ('klabin.*monte alegre|klabin.*tel[eê]maco', 'tel[eê]maco', 'klabin', 'Klabin Monte Alegre(Telêmaco Borba, PR) 판지·포장용지.', 'Klabin - Monte Alegre mill, Telêmaco Borba (PR): board and packaging paper.', 'BR check 2026-10-15: capacity not public.'),
  ('santher.*bragan', 'bragan', 'santher', 'Daio Paper·Marubeni 계열 Santher(Personal·Snob·Kiss) 티슈·특수포장지. 종이 연 약 18만 t(Penha·Bragança Paulista·Guaíba).', 'Santher (Daio Paper / Marubeni group, brands Personal, Snob, Kiss) - tissue and specialty packaging paper, about 180,000 t/yr paper across Penha and Bragança Paulista (SP) and Guaíba (RS).', 'BR check 2026-10-15: site split not public - group total kept on this row.'),
  ('smurfit.*tr[eê]s barras|tr[eê]s barras', 'tr[eê]s barras', 'smurfit|westrock|rigesa', 'Smurfit Westrock Três Barras(SC) 크라프트라이너·골판지원지 공장(2025 현대화 3,100만 달러).', 'Smurfit Westrock - Três Barras (SC) kraftliner and corrugating paper mill (ex Rigesa / WestRock), USD 31 m modernisation 2025.', 'BR check 2026-10-15: capacity not public.'),
  ('\mirani\M', null, 'irani', 'Irani — 크라프트지·Kraftliner·Testliner·골심지(SC·RS).', 'Irani Papel e Embalagem S.A. - kraft paper, kraftliner, testliner and medium, mills in Santa Catarina and Rio Grande do Sul.', 'BR check 2026-10-15: mill split not public.'),
  ('cmpc.*pira[ií]|igua[cç]u celulose', 'pira[ií] do sul', 'cmpc|igua', 'CMPC 가 2022 인수한 Iguaçu Celulose e Papel — sack kraft 12만 t, 특수지 2.1만 t(Piraí do Sul·São José dos Pinhais·Campos Novos).', 'CMPC - ex Iguaçu Celulose e Papel (bought 2022): sack kraft 120,000 t/yr and specialty paper 21,000 t/yr across Piraí do Sul, São José dos Pinhais and Campos Novos.', 'BR check 2026-10-15: group figure kept on this row.'),
  ('papirus', null, 'papirus', null, null, 'BR check 2026-10-15: Recycled and specialty board, São Paulo state - context only, details to collect.'),
  ('\mmili\M', null, '\mmili\M', null, null, 'BR check 2026-10-15: Tissue - toilet, towels, napkins (Paraná) - context only, details to collect.'),
  ('melhoramentos', null, 'melhoramentos', null, null, 'BR check 2026-10-15: Specialty paper, fibre packaging - context only, details to collect.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'brazil_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper'),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper'),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper'),
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano'),
  ('suzano.*limeira', 'limeira', 'suzano'),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul'),
  ('suzano.*mogi das cruzes', 'mogi das cruzes', 'suzano'),
  ('suzano.*imperatriz', 'imperatriz', 'suzano'),
  ('suzano.*aracruz', 'aracruz', 'suzano'),
  ('bo paper.*arapoti|arapoti', 'arapoti', 'bo paper|inversiones bo'),
  ('bo paper.*(pisa|jaguar)|\mpisa\M.*jaguar', 'jaguar', 'bo paper|pisa'),
  ('bracell.*len[cç][oó]is|bracell.*tissue', 'len[cç][oó]is', 'bracell|ol pap'),
  ('softys.*caieiras|softys.*bra[sz]il', 'caieiras', 'softys|sepac'),
  ('klabin.*ortigueira|klabin.*puma', 'ortigueira', 'klabin'),
  ('klabin.*monte alegre|klabin.*tel[eê]maco', 'tel[eê]maco', 'klabin'),
  ('santher.*bragan', 'bragan', 'santher'),
  ('smurfit.*tr[eê]s barras|tr[eê]s barras', 'tr[eê]s barras', 'smurfit|westrock|rigesa'),
  ('\mirani\M', null, 'irani'),
  ('cmpc.*pira[ií]|igua[cç]u celulose', 'pira[ií] do sul', 'cmpc|igua'),
  ('papirus', null, 'papirus'),
  ('\mmili\M', null, '\mmili\M'),
  ('melhoramentos', null, 'melhoramentos')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper',
   $pj${"owner": "Sylvamo", "priority": 1, "products": "Uncoated freesheet, copy, offset", "grades": ["UWF", "Copy paper"], "capacity_split": [{"label": "Sylvamo Latin America total (3 mills)", "value_t": 1000000}], "pitch": "UWF fibre saving - tensile, internal bond, opacity, retention", "approach": "Lead Brazilian account with Luiz Antônio - trial through the existing PCC supplier (SMI or Omya).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper',
   $pj${"owner": "Sylvamo", "priority": 1, "products": "Uncoated freesheet", "grades": ["UWF"], "approach": "Trial through SMI.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper',
   $pj${"owner": "Sylvamo", "priority": 1, "products": "Uncoated freesheet", "grades": ["UWF"], "approach": "Confirm machine, then trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano',
   $pj${"owner": "Suzano S.A.", "priority": 2, "products": "Printing and writing paper, paperboard", "grades": ["Printing and writing", "Paperboard"], "capacity": {"value": 550000, "unit": "metric_t", "year": "IR nameplate (P&W 350 + board 200)", "source": "suzano.com.br"}, "capacity_split": [{"label": "Printing and writing", "value_t": 350000}, {"label": "Paperboard", "value_t": 200000}], "pitch": "FCC alongside SMI PCC - fibre saving at equal opacity and strength", "approach": "Three-way trial Suzano + SMI + MBG.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('suzano.*limeira', 'limeira', 'suzano',
   $pj${"owner": "Suzano S.A.", "priority": 2, "products": "Printing and writing paper", "grades": ["Printing and writing"], "capacity": {"value": 400000, "unit": "metric_t", "year": "IR nameplate", "source": "suzano.com.br"}, "approach": "P&W trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul',
   $pj${"owner": "Suzano S.A.", "priority": 2, "products": "Printing and writing paper, tissue", "grades": ["Printing and writing", "Tissue"], "capacity": {"value": 310000, "unit": "metric_t", "year": "IR nameplate (P&W 250 + tissue 60)", "source": "suzano.com.br"}, "capacity_split": [{"label": "Printing and writing", "value_t": 250000}, {"label": "Tissue", "value_t": 60000}], "approach": "Trial through SMI.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('suzano.*mogi das cruzes', 'mogi das cruzes', 'suzano',
   $pj${"owner": "Suzano S.A.", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 130000, "unit": "metric_t", "year": "IR nameplate", "source": "suzano.com.br"}, "approach": "Tissue trial after the P&W work.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('suzano.*imperatriz', 'imperatriz', 'suzano',
   $pj${"owner": "Suzano S.A.", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 60000, "unit": "metric_t", "year": "IR nameplate", "source": "suzano.com.br"}, "approach": "Tissue trial after the P&W work.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('suzano.*aracruz', 'aracruz', 'suzano',
   $pj${"owner": "Suzano S.A.", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 60000, "unit": "metric_t", "year": "IR nameplate", "source": "suzano.com.br"}, "approach": "Tissue trial after the P&W work.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('bo paper.*arapoti|arapoti', 'arapoti', 'bo paper|inversiones bo',
   $pj${"owner": "BO Paper", "priority": 3, "products": "Coated paper, printing paper, specialty", "grades": ["Coated paper", "Printing and writing"], "capacity": {"value": 150000, "unit": "metric_t", "year": "Company figure", "source": "bopaper.com.br"}, "pitch": "FCC in the coating base paper", "approach": "Mid-size - line-specific joint trial, with Omya, São Judas or Imerys GCC.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('bo paper.*(pisa|jaguar)|\mpisa\M.*jaguar', 'jaguar', 'bo paper|pisa',
   $pj${"owner": "BO Paper", "priority": 3, "products": "Newsprint, publication, packaging", "grades": ["Newsprint", "Publication"], "capacity": {"value": 210000, "unit": "metric_t", "year": "Company figure", "source": "bopaper.com.br"}, "approach": "Second BO site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('bracell.*len[cç][oó]is|bracell.*tissue', 'len[cç][oó]is', 'bracell|ol pap',
   $pj${"owner": "Bracell (RGE)", "priority": 4, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "machines": 4, "capacity": {"value": 240000, "unit": "metric_t", "year": "2025 company (existing 4 machines)", "source": "bracell.com"}, "capacity_split": [{"label": "Existing 4 machines", "value_t": 240000}, {"label": "Planned 2 machines", "value_t": 120000}], "pitch": "Build FCC trials around the new tissue machines", "approach": "Tissue trial - softness, absorbency, dust, tensile.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*caieiras|softys.*bra[sz]il', 'caieiras', 'softys|sepac',
   $pj${"owner": "Softys (CMPC)", "priority": 5, "products": "Toilet tissue, towels, napkins, away tissue", "grades": ["Tissue"], "capacity_split": [{"label": "Softys Brazil total (2019)", "value_t": 280000}], "approach": "Links to Softys Chile, Uruguay, Argentina trials.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('klabin.*ortigueira|klabin.*puma', 'ortigueira', 'klabin',
   $pj${"owner": "Klabin", "priority": 6, "products": "White-top board, kraftliner, liquid packaging board", "grades": ["Folding boxboard", "Kraftliner", "LPB"], "approach": "White board top ply first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('klabin.*monte alegre|klabin.*tel[eê]maco', 'tel[eê]maco', 'klabin',
   $pj${"owner": "Klabin", "priority": 6, "products": "Board, packaging paper", "grades": ["Board", "Kraftliner"], "approach": "After Ortigueira.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('santher.*bragan', 'bragan', 'santher',
   $pj${"owner": "Santher (Daio Paper)", "priority": 7, "products": "Tissue, specialty packaging paper", "grades": ["Tissue", "Specialty paper"], "capacity_split": [{"label": "Santher total (3 sites)", "value_t": 180000}], "approach": "Can involve Daio Paper technical in Japan.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('smurfit.*tr[eê]s barras|tr[eê]s barras', 'tr[eê]s barras', 'smurfit|westrock|rigesa',
   $pj${"owner": "Smurfit Westrock", "priority": 8, "products": "Kraftliner, corrugating paper", "grades": ["Kraftliner", "Medium"], "approach": "Strength-critical - later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mirani\M', null, 'irani',
   $pj${"owner": "Irani", "priority": 8, "products": "Kraft paper, kraftliner, testliner, medium", "grades": ["Kraftliner", "Testliner"], "approach": "Low-basis-weight kraft only, later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cmpc.*pira[ií]|igua[cç]u celulose', 'pira[ií] do sul', 'cmpc|igua',
   $pj${"owner": "CMPC", "priority": 8, "products": "Sack kraft, specialty paper", "grades": ["Sack kraft"], "capacity_split": [{"label": "Sack kraft (3 sites)", "value_t": 120000}, {"label": "Specialty", "value_t": 21000}], "approach": "Strength-critical - later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papirus', null, 'papirus',
   $pj${"owner": "Papirus", "products": "Recycled and specialty board, São Paulo state", "approach": "Collect machine and grade data first.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mmili\M', null, '\mmili\M',
   $pj${"owner": "Mili", "products": "Tissue - toilet, towels, napkins (Paraná)", "approach": "Collect machine and grade data first.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('melhoramentos', null, 'melhoramentos',
   $pj${"owner": "Melhoramentos", "products": "Specialty paper, fibre packaging", "approach": "Collect machine and grade data first.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'brazil_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano', '(specialty minerals|minerals technologies).*bra[sz]il', 'active', 'medium', null::date, null::date, '25,000-35,000 t/yr per unit (2009)', 'satellite PCC at the mill', 'MTI press releases and SEC filings', 'SMI satellite PCC at Suzano, built 1996, expanded 2009'),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul', '(specialty minerals|minerals technologies).*bra[sz]il', 'active', 'medium', null::date, null::date, null, 'satellite PCC at the mill', 'MTI SEC filings', 'SMI satellite PCC at Mucuri (ex Bahia Sul)'),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper', '(specialty minerals|minerals technologies).*bra[sz]il', 'historical', 'medium', null::date, null::date, null, 'satellite PCC at the mill', 'MTI SEC filings', 'SMI satellite PCC at Luiz Antônio (ex Votorantim) - current status to confirm'),
  ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper', 'omya.*bra[sz]il', 'historical', 'low', null::date, null::date, null, 'PCC plant operation support', 'Omya Brazil technical service records 2008-2010', 'Omya PCC plant support at Mogi Guaçu 2008-2010 - current status to confirm'),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper', 'omya.*bra[sz]il', 'historical', 'low', null::date, null::date, null, 'PCC plant operation support', 'Omya Brazil technical service records 2008-2010', 'Omya PCC plant support at Três Lagoas 2008-2010 - current status to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BR', 'Brazil', 'high',
   $cm$11.3 Mt paper (2024) - Sylvamo and Suzano UWF on SMI and Omya PCC, BO Paper coated, Bracell and Softys tissue$cm$,
   $cm$Brazil made 11.3 Mt of paper in 2024 (7th in the world): 6.4 Mt packaging, 2.2 Mt printing and writing, 1.9 Mt tissue and other, 0.8 Mt board. All three licensee groups are present - SMI satellite PCC at Suzano, Mucuri, Jacareí and Luiz Antônio, Omya (Ponta Grossa GCC, Mogi Guaçu and Três Lagoas PCC support), Imerys (Brás Cubas 185 kt wet-ground GCC, six plants). Local GCC slurry: Mineração São Judas. Lead mills: Sylvamo (about 1.0 Mt UFS) and Suzano (Suzano, Limeira, Mucuri), then BO Paper, Bracell (240 kt tissue, 360 kt planned), Softys, Klabin, Santher.$cm$,
   $cm${"fillers": "PCC: Specialty Minerals (4 satellite sites, NewYield LO 2023), Omya do Brasil (PCC support at Mogi Guaçu and Três Lagoas 2008-2010, Ponta Grossa GCC), Imerys (historical PCC at Arcos, Limeira, Santanésia). GCC: Imerys Brás Cubas (185 kt, 68 pct wet), Cachoeiro de Itapemirim, Quixeré, Mineração São Judas (paper slurry, 90 ISO), Fillercal, Carbomil. Not added: Minerjato.", "mills": "UWF: Sylvamo Mogi Guaçu, Luiz Antônio, Três Lagoas. P&W and board: Suzano (Suzano SP, Limeira, Mucuri). Coated and publication: BO Paper Arapoti and Pisa. Tissue: Suzano (Mogi das Cruzes, Imperatriz, Aracruz), Bracell Lençóis Paulista, Softys Caieiras, Santher. Packaging: Klabin Ortigueira and Monte Alegre, Smurfit Westrock Três Barras, Irani, CMPC Piraí do Sul. Context: Papirus, Mili, Melhoramentos.", "strategy": "Three-way trials: Sylvamo + PCC supplier + MBG, Suzano + SMI + MBG, BO Paper + local GCC + MBG. Then tissue at Bracell, Softys, Santher. SMI, Omya and Imerys are licensees - Omya also has competing tech (Multifill, FiberLean).", "risks": "Existing PCC contracts may be exclusive. Packaging is strength-critical.", "next_steps": ["Approach Sylvamo Brazil technical", "Agree a three-way trial structure with SMI for Suzano"], "key_numbers": [{"label": "Paper output 2024", "value": "11.3 Mt (IBÁ)"}, {"label": "Pulp output 2025", "value": "29.4 Mt (+6.9 pct)"}, {"label": "Printing and writing 2024", "value": "about 2.2 Mt"}, {"label": "Report scenario", "value": "22,000 t FCC (10 pct of P&W x 10 pct), USD 330,000"}], "files": ["seed_20261016h_brazil_mills_fillers"]}$cm$::jsonb,
   $cm$종이 1,130만 t(2024) — Sylvamo·Suzano 비도공지(SMI·Omya PCC), BO Paper 도공지, Bracell·Softys 티슈$cm$,
   $cm$브라질 종이 생산 1,130만 t(세계 7위): 포장 640만·인쇄필기 220만·티슈 등 190만·판지 80만 t. 라이선시 3사 모두 진출 — SMI 위성 PCC(Suzano·Mucuri·Jacareí·Luiz Antônio), Omya(Ponta Grossa GCC, Mogi Guaçu·Três Lagoas PCC 지원), Imerys(Brás Cubas 습식 GCC 18.5만 t). 현지 GCC 슬러리 São Judas. 1순위 Sylvamo(UFS 약 100만 t)·Suzano, 이어 BO Paper, Bracell, Softys, Klabin, Santher.$cm$,
   22000, 44000,
   $cm$인쇄·필기용지 220만 t × 도입 10~20% × FCC 10% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('sylvamo.*mogi gua|chamex.*mogi', 'mogi gua', 'sylvamo|international paper'),
  ('sylvamo.*luiz ant|luiz ant.*sylvamo', 'luiz ant', 'sylvamo|international paper'),
  ('sylvamo.*tr[eê]s lagoas', 'tr[eê]s lagoas', 'sylvamo|international paper'),
  ('^suzano - suzano|suzano.*unidade suzano', '^suzano$', 'suzano'),
  ('suzano.*limeira', 'limeira', 'suzano'),
  ('suzano.*mucuri', 'mucuri', 'suzano|bahia sul'),
  ('suzano.*mogi das cruzes', 'mogi das cruzes', 'suzano'),
  ('suzano.*imperatriz', 'imperatriz', 'suzano'),
  ('suzano.*aracruz', 'aracruz', 'suzano'),
  ('bo paper.*arapoti|arapoti', 'arapoti', 'bo paper|inversiones bo'),
  ('bo paper.*(pisa|jaguar)|\mpisa\M.*jaguar', 'jaguar', 'bo paper|pisa'),
  ('bracell.*len[cç][oó]is|bracell.*tissue', 'len[cç][oó]is', 'bracell|ol pap'),
  ('softys.*caieiras|softys.*bra[sz]il', 'caieiras', 'softys|sepac'),
  ('klabin.*ortigueira|klabin.*puma', 'ortigueira', 'klabin'),
  ('klabin.*monte alegre|klabin.*tel[eê]maco', 'tel[eê]maco', 'klabin'),
  ('santher.*bragan', 'bragan', 'santher'),
  ('smurfit.*tr[eê]s barras|tr[eê]s barras', 'tr[eê]s barras', 'smurfit|westrock|rigesa'),
  ('\mirani\M', null, 'irani'),
  ('cmpc.*pira[ií]|igua[cç]u celulose', 'pira[ií] do sul', 'cmpc|igua'),
  ('papirus', null, 'papirus'),
  ('\mmili\M', null, '\mmili\M'),
  ('melhoramentos', null, 'melhoramentos')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'brazil_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'brazil_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*bra[sz]il' or p.party_name ~* 'imerys.*(br[aá]s cubas|mogi)' or p.party_name ~* 'imerys.*cachoeiro' or p.party_name ~* 'imerys.*quixer' or p.party_name ~* 'omya.*bra[sz]il' or p.party_name ~* 's[aã]o judas' or p.party_name ~* 'fillercal' or p.party_name ~* 'carbomil')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    