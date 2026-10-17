-- ============================================================
-- seed_20261016zp_italy_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Italy update (reports 2026-10-16). Existing IT rows likely - name regex
-- OR city + owner regex first. Porcari has Sofidel, Lucart and DS Smith -
-- owner regexes keep them apart.
-- 1) Fillers if missing (4): Omya Italy, Nicem, Fassa Bortolo, Unicalce.
-- 2) Mills if missing (10) + plant blocks, priority 1-8: Fedrigoni, Burgo,
--    Favini, Sofidel, Lucart, ICT, RDM, DS Smith Lucca. No priority:
--    Smurfit Westrock Verzuolo, Cartiere del Garda. Context (4).
-- 3) app.country_markets IT row (priority high).
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
           v.party_name, 'IT', v.region, v.city, v.website, 'active', 'italy_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*ital', 'Omya Specialty Materials Italy - Milano', 'Lombardy', 'Milano', null, 'Omya 이탈리아 법인(Via A. Cechov 48, 밀라노) — Hydrocarb·Omyapaque·Syncarb·Multifill·Omyaboard, 위성공장 모델.', 'Omya Specialty Materials Italy Srl, Via A. Cechov 48, Milano - Omya paper range (Hydrocarb, Omyapaque, Syncarb PCC, Multifill, Omyaboard) and satellite-plant model.', 'IT check 2026-10-16: Italian plant sites and capacities not confirmed. +39 02 380831. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('nicem|carbopaper', 'Nicem - Casazza', 'Lombardy', 'Casazza', null, 'Carrara 고백색 탄산칼슘을 Casazza(Bergamo)에서 건식 분쇄·공기분급 — 제지용 CarboPaper BCM 8(D50 <2.0, D90 <6.5 μm)·10·20·30.', 'Nicem S.r.l., Casazza (Bergamo) - high-white Carrara calcium carbonate dry-ground and air-classified as the CarboPaper paper range: BCM 8 (D50 under 2.0, D90 under 6.5 micron), BCM 10 (2.5 / 10.5), BCM 20 (3.0 / 12), BCM 30 (4.5 / 20).', 'IT check 2026-10-16: dry process - wet dispersion for FCC to confirm. Independent paper GCC maker - FCC co-production candidate.'),
  ('fassa bortolo', 'Fassa Bortolo - Spresiano', 'Veneto', 'Spresiano', null, '석회·탄산칼슘 제조(Spresiano, Treviso) — 미분 탄산칼슘 제지 용도 명시, 석회 공장 Montichiari·Ceraino di Dolcè·Schio.', 'Fassa Bortolo, Spresiano (Treviso) - limestone-derived micronised calcium carbonate with paper named, lime plants at Spresiano, Montichiari, Ceraino di Dolcè and Schio.', 'IT check 2026-10-16: paper slurry grade not confirmed. No PCC.'),
  ('unicalce', 'Unicalce (Carmeuse) - Lecco', 'Lombardy', 'Lecco', null, 'Lecco 대형 석회·탄산염 원료기업 — 전국 11개 거점, 석회 연 약 200만 t 이상, Carmeuse 가 지분 인수·통합.', 'Unicalce, Via Tonio da Belledo 30, Lecco - lime and carbonate raw materials at 11 Italian sites, over 2 Mt/yr lime, now controlled by Carmeuse.', 'IT check 2026-10-16: lime only - no Italian paper PCC confirmed. info@unicalce.it, +39 0341 2571. PCC raw-material partner. Not added: Minerals Technologies Italy (no plant identified).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%IT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*ital', 'Omya Specialty Materials Italy - Milano', 'Lombardy', 'Milano', null, 'Omya 이탈리아 법인(Via A. Cechov 48, 밀라노) — Hydrocarb·Omyapaque·Syncarb·Multifill·Omyaboard, 위성공장 모델.', 'Omya Specialty Materials Italy Srl, Via A. Cechov 48, Milano - Omya paper range (Hydrocarb, Omyapaque, Syncarb PCC, Multifill, Omyaboard) and satellite-plant model.', 'IT check 2026-10-16: Italian plant sites and capacities not confirmed. +39 02 380831. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('nicem|carbopaper', 'Nicem - Casazza', 'Lombardy', 'Casazza', null, 'Carrara 고백색 탄산칼슘을 Casazza(Bergamo)에서 건식 분쇄·공기분급 — 제지용 CarboPaper BCM 8(D50 <2.0, D90 <6.5 μm)·10·20·30.', 'Nicem S.r.l., Casazza (Bergamo) - high-white Carrara calcium carbonate dry-ground and air-classified as the CarboPaper paper range: BCM 8 (D50 under 2.0, D90 under 6.5 micron), BCM 10 (2.5 / 10.5), BCM 20 (3.0 / 12), BCM 30 (4.5 / 20).', 'IT check 2026-10-16: dry process - wet dispersion for FCC to confirm. Independent paper GCC maker - FCC co-production candidate.'),
  ('fassa bortolo', 'Fassa Bortolo - Spresiano', 'Veneto', 'Spresiano', null, '석회·탄산칼슘 제조(Spresiano, Treviso) — 미분 탄산칼슘 제지 용도 명시, 석회 공장 Montichiari·Ceraino di Dolcè·Schio.', 'Fassa Bortolo, Spresiano (Treviso) - limestone-derived micronised calcium carbonate with paper named, lime plants at Spresiano, Montichiari, Ceraino di Dolcè and Schio.', 'IT check 2026-10-16: paper slurry grade not confirmed. No PCC.'),
  ('unicalce', 'Unicalce (Carmeuse) - Lecco', 'Lombardy', 'Lecco', null, 'Lecco 대형 석회·탄산염 원료기업 — 전국 11개 거점, 석회 연 약 200만 t 이상, Carmeuse 가 지분 인수·통합.', 'Unicalce, Via Tonio da Belledo 30, Lecco - lime and carbonate raw materials at 11 Italian sites, over 2 Mt/yr lime, now controlled by Carmeuse.', 'IT check 2026-10-16: lime only - no Italian paper PCC confirmed. info@unicalce.it, +39 0341 2571. PCC raw-material partner. Not added: Minerals Technologies Italy (no plant identified).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'italy_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Specialty Materials Italy - Milano', 'GCC and PCC supplier', 'Omya Italy - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Nicem - Casazza', 'GCC producer', 'Independent paper GCC (CarboPaper) - co-production candidate', 'merchant', 'B', 'gcc'),
  ('Fassa Bortolo - Spresiano', 'GCC and lime producer', 'Micronised carbonate, paper named', 'merchant', 'C', 'gcc'),
  ('Unicalce (Carmeuse) - Lecco', 'Lime producer', 'Lime base - PCC raw material (Carmeuse)', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'italy_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'IT', v.region, v.city, v.website, 'active', 'italy_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('fedrigoni', 'verona', 'fedrigoni', 'Fedrigoni - Verona', 'Veneto', 'Verona', null, 'Fedrigoni 그룹(2025 매출 약 19억 유로, 특수지 36%) — 특수지·고급 인쇄지·포장지·미술용지(Fabriano), Verona·Arco·Varone·Scurelle·Fabriano.', 'Fedrigoni group, Verona - specialty, fine printing, packaging and fine-art papers (Fabriano brand), historical mills at Verona, Arco, Varone, Scurelle and Fabriano. 2025 group sales about EUR 1.9 bn, specialty papers about 36 pct (rest labels and RFID).', 'IT check 2026-10-16: current mill list and outputs to confirm - one group row.'),
  ('\mburgo\M', null, 'burgo', 'Burgo Group', null, null, null, 'Burgo Group — 북부 이탈리아 인쇄용지·코팅지·특수지·포장용지 대형 제지그룹.', 'Burgo Group - large northern Italian maker of printing, coated, specialty and packaging papers.', 'IT check 2026-10-16: mill list and outputs to confirm - one group row.'),
  ('favini', 'rossano', 'favini', 'Favini - Rossano Veneto', 'Veneto', 'Rossano Veneto', null, '고급지·디자인지·지속가능 특수지(Rossano Veneto). 1992 해조류 종이 Alga Carta(베네치아 석호 해조류 분쇄 첨가).', 'Favini, Rossano Veneto - fine, design and sustainable specialty papers made with by-products, launched Alga Carta in 1992 using dried, milled Venice-lagoon algae in the furnish.', 'IT check 2026-10-16: algae-paper know-how - check its IP before joint work. Not the same as FCC (algae fibre plus carbonate composite).'),
  ('sofidel|soffass', 'porcari', 'sofidel|soffass', 'Sofidel (Soffass) - Porcari', 'Tuscany', 'Porcari', null, '1966년 설립 세계적 티슈 기업 Sofidel(Regina) — 그룹 200만 t 이상·13개국. 이탈리아 Soffass Porcari·Via Leccio·Monfalcone·Val Fegana·Valdottavo.', 'Sofidel (1966, Regina brand), Porcari (Lucca) - group tissue capacity over 2 Mt/yr in 13 countries. Italian mills: Soffass Porcari and Via Leccio (Porcari), Monfalcone, Val Fegana (Bagni di Lucca), Valdottavo (Borgo a Mozzano).', 'IT check 2026-10-16: global figure - not counted for Italy. One row for the Italian mills.'),
  ('lucart', 'porcari|diecimo', 'lucart', 'Lucart - Porcari', 'Tuscany', 'Porcari', null, 'Lucart(Tenderly, Lucart Professional) 재생펄프·탈묵 티슈 — Porcari·Diecimo·Torre di Mosto·Castelnuovo di Garfagnana.', 'Lucart (Tenderly, Lucart Professional), Porcari - recycled and deinked tissue, Italian mills at Porcari, Diecimo, Torre di Mosto and Castelnuovo di Garfagnana.', 'IT check 2026-10-16: capacity not public here.'),
  ('\mict\M.*(group|tronchetti)|tronchetti', 'lucca|coreglia|diecimo', 'tronchetti|\mict\M', 'ICT Group (Industrie Cartarie Tronchetti) - Lucca', 'Tuscany', 'Lucca', null, '1976년 설립 고급 버진 티슈(Foxy) — Piano della Rocca·Diecimo·Piano di Coreglia.', 'Industrie Cartarie Tronchetti (ICT Group, 1976), Lucca - premium virgin-pulp tissue (Foxy), mills at Piano della Rocca, Diecimo and Piano di Coreglia.', 'IT check 2026-10-16: capacity not public here.'),
  ('\mrdm\M|reno de medici', null, 'rdm|reno de medici', 'RDM Group (Italy)', null, null, null, 'RDM Group 재생 백판지·포장용 판지(식품·소비재).', 'RDM Group (Reno De Medici) - recycled coated board for food and consumer packaging, Italian mills in Lombardy and elsewhere.', 'IT check 2026-10-16: mill list to confirm - one group row.'),
  ('ds smith.*(lucca|porcari)', 'porcari', 'ds smith', 'DS Smith Lucca Mill - Porcari', 'Tuscany', 'Porcari', null, 'DS Smith Lucca 공장(Porcari) — White Liner·Kraft Top·골판지 원지, PM1 17.5만 + PM2 23.5만 = 41만 t(115~200 g/m²).', 'DS Smith Lucca Mill, Porcari - white-top liner, kraft-top and containerboard on recycled fibre: PM1 175,000 t/yr and PM2 235,000 t/yr (115-200 g/m2), 410,000 t/yr nameplate.', 'IT check 2026-10-16: now part of International Paper (DS Smith acquisition).'),
  ('smurfit.*verzuolo|verzuolo', 'verzuolo', 'smurfit|westrock', 'Smurfit Westrock Cartiera di Verzuolo', 'Piedmont', 'Verzuolo', null, 'Smurfit Westrock 이탈리아 Verzuolo 포장용지·골판지 원지.', 'Smurfit Westrock Cartiera di Verzuolo S.r.l., Verzuolo (Cuneo) - packaging paper and containerboard.', 'IT check 2026-10-16: capacity not public here.'),
  ('cartiere del garda', 'riva del garda', 'garda', 'Cartiere del Garda - Riva del Garda', 'Trentino', 'Riva del Garda', null, 'Riva del Garda 코팅 인쇄용지.', 'Cartiere del Garda, Riva del Garda - coated printing papers.', 'IT check 2026-10-16: capacity not public here.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%IT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fedrigoni', 'verona', 'fedrigoni', 'Fedrigoni 그룹(2025 매출 약 19억 유로, 특수지 36%) — 특수지·고급 인쇄지·포장지·미술용지(Fabriano), Verona·Arco·Varone·Scurelle·Fabriano.', 'Fedrigoni group, Verona - specialty, fine printing, packaging and fine-art papers (Fabriano brand), historical mills at Verona, Arco, Varone, Scurelle and Fabriano. 2025 group sales about EUR 1.9 bn, specialty papers about 36 pct (rest labels and RFID).', 'IT check 2026-10-16: current mill list and outputs to confirm - one group row.'),
  ('\mburgo\M', null, 'burgo', 'Burgo Group — 북부 이탈리아 인쇄용지·코팅지·특수지·포장용지 대형 제지그룹.', 'Burgo Group - large northern Italian maker of printing, coated, specialty and packaging papers.', 'IT check 2026-10-16: mill list and outputs to confirm - one group row.'),
  ('favini', 'rossano', 'favini', '고급지·디자인지·지속가능 특수지(Rossano Veneto). 1992 해조류 종이 Alga Carta(베네치아 석호 해조류 분쇄 첨가).', 'Favini, Rossano Veneto - fine, design and sustainable specialty papers made with by-products, launched Alga Carta in 1992 using dried, milled Venice-lagoon algae in the furnish.', 'IT check 2026-10-16: algae-paper know-how - check its IP before joint work. Not the same as FCC (algae fibre plus carbonate composite).'),
  ('sofidel|soffass', 'porcari', 'sofidel|soffass', '1966년 설립 세계적 티슈 기업 Sofidel(Regina) — 그룹 200만 t 이상·13개국. 이탈리아 Soffass Porcari·Via Leccio·Monfalcone·Val Fegana·Valdottavo.', 'Sofidel (1966, Regina brand), Porcari (Lucca) - group tissue capacity over 2 Mt/yr in 13 countries. Italian mills: Soffass Porcari and Via Leccio (Porcari), Monfalcone, Val Fegana (Bagni di Lucca), Valdottavo (Borgo a Mozzano).', 'IT check 2026-10-16: global figure - not counted for Italy. One row for the Italian mills.'),
  ('lucart', 'porcari|diecimo', 'lucart', 'Lucart(Tenderly, Lucart Professional) 재생펄프·탈묵 티슈 — Porcari·Diecimo·Torre di Mosto·Castelnuovo di Garfagnana.', 'Lucart (Tenderly, Lucart Professional), Porcari - recycled and deinked tissue, Italian mills at Porcari, Diecimo, Torre di Mosto and Castelnuovo di Garfagnana.', 'IT check 2026-10-16: capacity not public here.'),
  ('\mict\M.*(group|tronchetti)|tronchetti', 'lucca|coreglia|diecimo', 'tronchetti|\mict\M', '1976년 설립 고급 버진 티슈(Foxy) — Piano della Rocca·Diecimo·Piano di Coreglia.', 'Industrie Cartarie Tronchetti (ICT Group, 1976), Lucca - premium virgin-pulp tissue (Foxy), mills at Piano della Rocca, Diecimo and Piano di Coreglia.', 'IT check 2026-10-16: capacity not public here.'),
  ('\mrdm\M|reno de medici', null, 'rdm|reno de medici', 'RDM Group 재생 백판지·포장용 판지(식품·소비재).', 'RDM Group (Reno De Medici) - recycled coated board for food and consumer packaging, Italian mills in Lombardy and elsewhere.', 'IT check 2026-10-16: mill list to confirm - one group row.'),
  ('ds smith.*(lucca|porcari)', 'porcari', 'ds smith', 'DS Smith Lucca 공장(Porcari) — White Liner·Kraft Top·골판지 원지, PM1 17.5만 + PM2 23.5만 = 41만 t(115~200 g/m²).', 'DS Smith Lucca Mill, Porcari - white-top liner, kraft-top and containerboard on recycled fibre: PM1 175,000 t/yr and PM2 235,000 t/yr (115-200 g/m2), 410,000 t/yr nameplate.', 'IT check 2026-10-16: now part of International Paper (DS Smith acquisition).'),
  ('smurfit.*verzuolo|verzuolo', 'verzuolo', 'smurfit|westrock', 'Smurfit Westrock 이탈리아 Verzuolo 포장용지·골판지 원지.', 'Smurfit Westrock Cartiera di Verzuolo S.r.l., Verzuolo (Cuneo) - packaging paper and containerboard.', 'IT check 2026-10-16: capacity not public here.'),
  ('cartiere del garda', 'riva del garda', 'garda', 'Riva del Garda 코팅 인쇄용지.', 'Cartiere del Garda, Riva del Garda - coated printing papers.', 'IT check 2026-10-16: capacity not public here.'),
  ('cartiere carrara', null, 'cartiere carrara', null, null, 'IT check 2026-10-16: Tissue, Tuscany - context only, details to collect.'),
  ('pro-?gest', null, 'pro-?gest', null, null, 'IT check 2026-10-16: Recycled packaging paper and corrugated, Veneto - context only, details to collect.'),
  ('cartiere saci', null, 'cartiere saci', null, null, 'IT check 2026-10-16: Recycled packaging paper, Veneto - context only, details to collect.'),
  ('cartiera di ferrara', null, 'cartiera di ferrara', null, null, 'IT check 2026-10-16: Packaging paper, Ferrara - context only, details to collect.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'italy_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fedrigoni', 'verona', 'fedrigoni'),
  ('\mburgo\M', null, 'burgo'),
  ('favini', 'rossano', 'favini'),
  ('sofidel|soffass', 'porcari', 'sofidel|soffass'),
  ('lucart', 'porcari|diecimo', 'lucart'),
  ('\mict\M.*(group|tronchetti)|tronchetti', 'lucca|coreglia|diecimo', 'tronchetti|\mict\M'),
  ('\mrdm\M|reno de medici', null, 'rdm|reno de medici'),
  ('ds smith.*(lucca|porcari)', 'porcari', 'ds smith'),
  ('smurfit.*verzuolo|verzuolo', 'verzuolo', 'smurfit|westrock'),
  ('cartiere del garda', 'riva del garda', 'garda'),
  ('cartiere carrara', null, 'cartiere carrara'),
  ('pro-?gest', null, 'pro-?gest'),
  ('cartiere saci', null, 'cartiere saci'),
  ('cartiera di ferrara', null, 'cartiera di ferrara')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fedrigoni', 'verona', 'fedrigoni',
   $pj${"owner": "Fedrigoni", "priority": 1, "products": "Specialty and fine printing paper, packaging, fine art", "grades": ["Specialty paper", "UWF"], "pitch": "Higher filler and fibre saving on printing and specialty grades", "approach": "Lead Italian account - Omya Italy or Nicem as producer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mburgo\M', null, 'burgo',
   $pj${"owner": "Burgo", "priority": 2, "products": "Printing, coated, specialty, packaging paper", "grades": ["Coated paper", "UWF", "Specialty paper"], "approach": "FCC vs existing GCC and PCC on printing lines.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('favini', 'rossano', 'favini',
   $pj${"owner": "Favini", "priority": 3, "products": "Fine and specialty paper, algae paper", "grades": ["Specialty paper"], "pitch": "Joint development of a marine-fibre filler paper", "approach": "Co-development partner - not only a buyer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel|soffass', 'porcari', 'sofidel|soffass',
   $pj${"owner": "Sofidel", "priority": 4, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "pitch": "Virgin-pulp saving with softness and absorbency kept", "approach": "Group approval - can roll out abroad.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lucart', 'porcari|diecimo', 'lucart',
   $pj${"owner": "Lucart", "priority": 5, "products": "Recycled tissue, AfH tissue", "grades": ["Tissue"], "approach": "Recycled-fibre saving and quality stability.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mict\M.*(group|tronchetti)|tronchetti', 'lucca|coreglia|diecimo', 'tronchetti|\mict\M',
   $pj${"owner": "ICT Group", "priority": 6, "products": "Premium tissue", "grades": ["Tissue"], "approach": "Quality-kept fibre saving.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mrdm\M|reno de medici', null, 'rdm|reno de medici',
   $pj${"owner": "RDM Group", "priority": 7, "products": "Recycled coated board", "grades": ["Coated board"], "approach": "Ply-level FCC trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*(lucca|porcari)', 'porcari', 'ds smith',
   $pj${"owner": "DS Smith (International Paper)", "priority": 8, "products": "White-top liner, kraft-top, containerboard", "grades": ["White-top liner", "Testliner"], "machines": 2, "capacity": {"value": 410000, "unit": "metric_t", "year": "Company site (PM1 + PM2)", "source": "dssmith.com"}, "capacity_split": [{"label": "PM2", "value_t": 235000}, {"label": "PM1", "value_t": 175000}], "approach": "White-top surface-ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*verzuolo|verzuolo', 'verzuolo', 'smurfit|westrock',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "approach": "Strength-led - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartiere del garda', 'riva del garda', 'garda',
   $pj${"owner": "Cartiere del Garda", "products": "Coated printing paper", "grades": ["Coated paper"], "approach": "Base-paper filler trial candidate.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartiere carrara', null, 'cartiere carrara',
   $pj${"owner": "Cartiere Carrara", "products": "Tissue, Tuscany", "approach": "Collect machine data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pro-?gest', null, 'pro-?gest',
   $pj${"owner": "Pro-Gest", "products": "Recycled packaging paper and corrugated, Veneto", "approach": "Collect machine data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartiere saci', null, 'cartiere saci',
   $pj${"owner": "Cartiere Saci", "products": "Recycled packaging paper, Veneto", "approach": "Collect machine data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartiera di ferrara', null, 'cartiera di ferrara',
   $pj${"owner": "Cartiera di Ferrara", "products": "Packaging paper, Ferrara", "approach": "Collect machine data.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'IT', 'Italy', 'high',
   $cm$7.8 Mt paper and board - Fedrigoni, Burgo printing and specialty, Lucca tissue cluster (Sofidel, Lucart, ICT), Favini algae paper - Omya and Nicem GCC$cm$,
   $cm$Italy made 7.8 Mt paper and board in 2025 (-2.2 pct, EUR 7.9 bn, 151 mills, consumption 10 Mt). FCC-fit: Fedrigoni and Burgo (printing, coated, specialty), Favini (fine paper, Alga Carta algae paper since 1992 - joint development fit), the Lucca tissue cluster (Sofidel, Lucart, ICT, Cartiere Carrara), RDM recycled board, DS Smith Lucca white-top liner (410 kt). Fillers: Omya Italy (licensee), Nicem (Casazza, CarboPaper D50 under 2 micron), Fassa Bortolo, Unicalce lime (Carmeuse). No Italian PCC plant identified.$cm$,
   $cm${"fillers": "GCC: Omya Italy (licensee), Nicem CarboPaper BCM 8-30, Fassa Bortolo. Lime: Unicalce (Carmeuse, 2 Mt+). Not added: MTI Italy (no plant identified).", "mills": "Printing and specialty: Fedrigoni, Burgo, Favini, Cartiere del Garda. Tissue: Sofidel, Lucart, ICT (Lucca cluster). Board and liner: RDM, DS Smith Lucca, Smurfit Westrock Verzuolo. Context: Cartiere Carrara, Pro-Gest, Cartiere Saci, Cartiera di Ferrara.", "strategy": "Omya Italy or Nicem as producer. Printing trials at Fedrigoni and Burgo, tissue at Sofidel and Lucart, co-development with Favini on marine-fibre paper.", "risks": "Omya competing tech, Favini algae IP, high energy cost.", "next_steps": ["Approach Nicem on FCC co-production", "Open a joint-development talk with Favini"], "key_numbers": [{"label": "2025 output", "value": "7.8 Mt (-2.2 pct), EUR 7.9 bn"}, {"label": "Mills", "value": "151 (2024)"}, {"label": "DS Smith Lucca", "value": "410 kt (PM1 + PM2)"}], "files": ["seed_20261016zp_italy_mills_fillers"]}$cm$::jsonb,
   $cm$종이·판지 780만 t — Fedrigoni·Burgo 인쇄·특수지, Lucca 티슈 클러스터(Sofidel·Lucart·ICT), Favini 해조류 종이 — Omya·Nicem GCC$cm$,
   $cm$이탈리아 2025 종이·판지 780만 t(-2.2%, 79억 유로, 제지공장 151곳). FCC 적합: Fedrigoni·Burgo(인쇄·코팅·특수지), Favini(1992 해조류 종이 Alga Carta — 공동개발 적합), Lucca 티슈 클러스터(Sofidel·Lucart·ICT), RDM 재생 백판지, DS Smith Lucca 화이트탑(41만 t). 충전제: Omya Italy(라이선시), Nicem(CarboPaper D50 2 μm 미만), Fassa Bortolo, Unicalce(Carmeuse). 이탈리아 PCC 공장 미확인.$cm$,
   null, null,
   $cm$공장별 생산량 대부분 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('fedrigoni', 'verona', 'fedrigoni'),
  ('\mburgo\M', null, 'burgo'),
  ('favini', 'rossano', 'favini'),
  ('sofidel|soffass', 'porcari', 'sofidel|soffass'),
  ('lucart', 'porcari|diecimo', 'lucart'),
  ('\mict\M.*(group|tronchetti)|tronchetti', 'lucca|coreglia|diecimo', 'tronchetti|\mict\M'),
  ('\mrdm\M|reno de medici', null, 'rdm|reno de medici'),
  ('ds smith.*(lucca|porcari)', 'porcari', 'ds smith'),
  ('smurfit.*verzuolo|verzuolo', 'verzuolo', 'smurfit|westrock'),
  ('cartiere del garda', 'riva del garda', 'garda'),
  ('cartiere carrara', null, 'cartiere carrara'),
  ('pro-?gest', null, 'pro-?gest'),
  ('cartiere saci', null, 'cartiere saci'),
  ('cartiera di ferrara', null, 'cartiera di ferrara')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'italy_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'italy_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*ital' or p.party_name ~* 'nicem|carbopaper' or p.party_name ~* 'fassa bortolo' or p.party_name ~* 'unicalce')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'IT'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'IT'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'IT'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    