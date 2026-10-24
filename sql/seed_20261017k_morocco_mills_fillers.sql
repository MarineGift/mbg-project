-- ============================================================
-- seed_20261017k_morocco_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Morocco (MA) update (reports 2026-10-17). Omya and International Paper
-- guards are country-scoped.
-- 1) Fillers if missing (5): Omya Maroc, Broychim, Carbonate Chaouia,
--    SIGMAROC, Minerallum.
-- 2) Mills if missing (4) + plant blocks, priority 1-3: Med Paper, SIPAT,
--    CMCP-IP Kénitra. GPC no priority. Context (7).
-- 3) app.country_markets MA row (priority low).
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
           v.party_name, 'MA', v.region, v.city, v.website, 'active', 'morocco_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*maroc', 'Omya Maroc - Bouskoura', 'Casablanca-Settat', 'Bouskoura', null, 'Omya Maroc(Km 16 Route d''El Jadida, Bouskoura) 탄산칼슘 제조·판매·무역, 등록자본 3,000만 MAD — Omya 그룹 Hydrocarb·Omyapaque(GCC)·Syncarb(PCC)·Multifill, on-site 위성공장 모델.', 'Omya Maroc, Km 16 Route d''El Jadida, Bouskoura - calcium carbonate manufacturing, sales and trading, registered capital MAD 30 m. Omya group paper lines Hydrocarb and Omyapaque (GCC), Syncarb (PCC), Multifill, plus on-site satellite plants.', 'MA check 2026-10-17: local grades and any PCC line unconfirmed. Royalty licensee at HQ level - Multifill and FiberLean compete with FCC, NDA and IP scope first. +212 522 65 03 19. Candidate 1.'),
  ('broychim', 'Broychim - Casablanca', 'Casablanca-Settat', 'Casablanca', null, 'Broychim(1982, Oukacha Casablanca) 탄산칼슘·방해석·중정석·탈크 분쇄, 화학제품 수입, 50~100명, 자본 1,200만 MAD.', 'Broychim (1982), Oukacha, Casablanca - grinding of calcium carbonate, calcite, barite and talc, chemical imports, 50-100 staff, capital MAD 12 m.', 'MA check 2026-10-17: paper slurry and mill references unknown. Independent candidate 2.'),
  ('carbonate chaouia', 'Carbonate Chaouia - Ben Ahmed', 'Casablanca-Settat', 'Ben Ahmed', null, 'Carbonate Chaouia(Ben Ahmed, 1977 채석~) 파쇄·선별·미분화 2라인(38 μm 미만), 도료·세라믹·건자재, 180명+.', 'Carbonate Chaouia, Ben Ahmed - limestone quarrying since 1977, crushing, screening and two micronising lines (under 38 micron) for paint, ceramics and building, over 180 staff.', 'MA check 2026-10-17: 38 micron top size is not a paper PSD - wet ultrafine grinding to check. +212 523 407 211.'),
  ('sigmaroc', 'SIGMAROC', 'Morocco', null, null, 'SIGMAROC 석회석·석회 소재 — Pulp & Paper 용도(PCC·가성화·재활용·표백) 명시.', 'SIGMAROC - limestone and lime, lists pulp and paper uses (PCC, kraft causticising, recycling, bleaching).', 'MA check 2026-10-17: no own PCC plant confirmed - lime for a new PCC line.'),
  ('minerallum', 'Minerallum', 'Morocco', null, null, 'Minerallum 광물 가공·공급 — 탄산칼슘(제지·도료·플라스틱), 설비 현대화 투자.', 'Minerallum - mineral processing and supply incl. calcium carbonate for paper, paint and plastics, upgrading capacity.', 'MA check 2026-10-17: paper sales not confirmed. No Moroccan paper PCC plant confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MA check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*maroc', 'Omya Maroc - Bouskoura', 'Casablanca-Settat', 'Bouskoura', null, 'Omya Maroc(Km 16 Route d''El Jadida, Bouskoura) 탄산칼슘 제조·판매·무역, 등록자본 3,000만 MAD — Omya 그룹 Hydrocarb·Omyapaque(GCC)·Syncarb(PCC)·Multifill, on-site 위성공장 모델.', 'Omya Maroc, Km 16 Route d''El Jadida, Bouskoura - calcium carbonate manufacturing, sales and trading, registered capital MAD 30 m. Omya group paper lines Hydrocarb and Omyapaque (GCC), Syncarb (PCC), Multifill, plus on-site satellite plants.', 'MA check 2026-10-17: local grades and any PCC line unconfirmed. Royalty licensee at HQ level - Multifill and FiberLean compete with FCC, NDA and IP scope first. +212 522 65 03 19. Candidate 1.'),
  ('broychim', 'Broychim - Casablanca', 'Casablanca-Settat', 'Casablanca', null, 'Broychim(1982, Oukacha Casablanca) 탄산칼슘·방해석·중정석·탈크 분쇄, 화학제품 수입, 50~100명, 자본 1,200만 MAD.', 'Broychim (1982), Oukacha, Casablanca - grinding of calcium carbonate, calcite, barite and talc, chemical imports, 50-100 staff, capital MAD 12 m.', 'MA check 2026-10-17: paper slurry and mill references unknown. Independent candidate 2.'),
  ('carbonate chaouia', 'Carbonate Chaouia - Ben Ahmed', 'Casablanca-Settat', 'Ben Ahmed', null, 'Carbonate Chaouia(Ben Ahmed, 1977 채석~) 파쇄·선별·미분화 2라인(38 μm 미만), 도료·세라믹·건자재, 180명+.', 'Carbonate Chaouia, Ben Ahmed - limestone quarrying since 1977, crushing, screening and two micronising lines (under 38 micron) for paint, ceramics and building, over 180 staff.', 'MA check 2026-10-17: 38 micron top size is not a paper PSD - wet ultrafine grinding to check. +212 523 407 211.'),
  ('sigmaroc', 'SIGMAROC', 'Morocco', null, null, 'SIGMAROC 석회석·석회 소재 — Pulp & Paper 용도(PCC·가성화·재활용·표백) 명시.', 'SIGMAROC - limestone and lime, lists pulp and paper uses (PCC, kraft causticising, recycling, bleaching).', 'MA check 2026-10-17: no own PCC plant confirmed - lime for a new PCC line.'),
  ('minerallum', 'Minerallum', 'Morocco', null, null, 'Minerallum 광물 가공·공급 — 탄산칼슘(제지·도료·플라스틱), 설비 현대화 투자.', 'Minerallum - mineral processing and supply incl. calcium carbonate for paper, paint and plastics, upgrading capacity.', 'MA check 2026-10-17: paper sales not confirmed. No Moroccan paper PCC plant confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'morocco_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Maroc - Bouskoura', 'GCC producer', 'Omya local GCC plant - licensee group, candidate 1', 'merchant', 'B', 'gcc'),
  ('Broychim - Casablanca', 'GCC producer', 'Independent grinder - candidate 2', 'merchant', 'C', 'gcc'),
  ('Carbonate Chaouia - Ben Ahmed', 'GCC producer', 'Micronised limestone - raw-material partner', 'merchant', 'C', 'gcc'),
  ('SIGMAROC', 'Lime producer', 'Lime for PCC - raw material', 'merchant', 'C', 'pcc'),
  ('Minerallum', 'GCC producer', 'Mineral processor - option', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'morocco_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MA', v.region, v.city, v.website, 'active', 'morocco_update_20261017',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('med paper|papelera de t[eé]touan', 'tanger|moghogha', 'med paper', 'Med Paper - Tanger', 'Tanger-Tétouan-Al Hoceïma', 'Tanger', null, 'Med Paper(상장, Moghogha 산업단지 Tanger, 대표 Mohsine Sefrioui) — 구 Papelera de Tétouan·Safripac 통합, 인쇄·필기·사무·포장용지, 초지기 2기 이론 약 4.5만 t, 2026-09-30 상반기 실적 공시.', 'Med Paper S.A. (listed), Zone Industrielle Moghogha, Route de Tétouan, Tanger (CEO Mohsine Sefrioui) - formed of Papelera de Tétouan and Safripac, printing, writing, office and packaging papers on two machines of about 45,000 t/yr theoretical, H1 2026 results filed 2026-09-30.', 'MA check 2026-10-17: running rate to confirm. +212 539 36 21 00.'),
  ('\msipat\M|papiers tissues', 'mekn[eè]s|a[iï]n slougui', 'sipat', 'SIPAT - Meknès', 'Fès-Meknès', 'Meknès', null, 'SIPAT(1977, Aïn Slougui Meknès, El Kendouci) 티슈 초지기 PM1·PM2 약 1.6만 t(2010 Toscotec), 2024 ABB QCS, 2025 AMACO 자동화.', 'SIPAT (Société Industrielle des Papiers Tissues, 1977, El Kendouci family), Zone Industrielle Aïn Slougui, Meknès - PM1 and PM2 tissue machines, about 16,000 t/yr (Toscotec 2010 rebuild), ABB QCS on both machines 2024, AMACO automation 2025, facial, toilet, napkin and kitchen tissue.', 'MA check 2026-10-17: sipatpap@yahoo.fr, +212 535 50 05 26.'),
  ('cmcp|international paper.*(maroc|morocco|k[eé]nitra)', 'k[eé]nitra', 'cmcp|international paper', 'CMCP-International Paper - Kénitra', 'Rabat-Salé-Kénitra', 'Kénitra', null, 'CMCP–International Paper Kénitra — 모로코 최대 폐지 소비 공장, 재생 골판지원지 → 자사 골판지 공장 3곳(Casablanca·Agadir·Tanger Med Packaging).', 'CMCP-International Paper, Kénitra mill - the largest waste-paper user in Morocco, recycled containerboard feeding three IP corrugated plants (Casablanca HQ Aïn Sebâa, Agadir, Tanger Med Packaging).', 'MA check 2026-10-17: capacity not public - strength-led. +212 537 39 99 00. Same IP group as DS Smith rows (HR Belišće etc.).'),
  ('\mgpc\M.*(papier|carton)|gharb.*papier', 'mohammedia|k[eé]nitra', 'gpc|ynna', 'GPC Papier et Carton - Mohammedia', 'Casablanca-Settat', 'Mohammedia', null, 'Ynna Holding 계열 GPC — Mohammedia 등 골판지 포장, 2025-09 MAD 5억 투자로 약 9만 → 16만 t(2030, 포장재 기준).', 'GPC Papier et Carton (Ynna Holding), Mohammedia, Kénitra and others - corrugated packaging, MAD 500 m Mohammedia expansion (2025-09) lifting about 90 kt to 160 kt/yr by 2030 (packaging, not base paper).', 'MA check 2026-10-17: own paper machine to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MA check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('med paper|papelera de t[eé]touan', 'tanger|moghogha', 'med paper', 'Med Paper(상장, Moghogha 산업단지 Tanger, 대표 Mohsine Sefrioui) — 구 Papelera de Tétouan·Safripac 통합, 인쇄·필기·사무·포장용지, 초지기 2기 이론 약 4.5만 t, 2026-09-30 상반기 실적 공시.', 'Med Paper S.A. (listed), Zone Industrielle Moghogha, Route de Tétouan, Tanger (CEO Mohsine Sefrioui) - formed of Papelera de Tétouan and Safripac, printing, writing, office and packaging papers on two machines of about 45,000 t/yr theoretical, H1 2026 results filed 2026-09-30.', 'MA check 2026-10-17: running rate to confirm. +212 539 36 21 00.'),
  ('\msipat\M|papiers tissues', 'mekn[eè]s|a[iï]n slougui', 'sipat', 'SIPAT(1977, Aïn Slougui Meknès, El Kendouci) 티슈 초지기 PM1·PM2 약 1.6만 t(2010 Toscotec), 2024 ABB QCS, 2025 AMACO 자동화.', 'SIPAT (Société Industrielle des Papiers Tissues, 1977, El Kendouci family), Zone Industrielle Aïn Slougui, Meknès - PM1 and PM2 tissue machines, about 16,000 t/yr (Toscotec 2010 rebuild), ABB QCS on both machines 2024, AMACO automation 2025, facial, toilet, napkin and kitchen tissue.', 'MA check 2026-10-17: sipatpap@yahoo.fr, +212 535 50 05 26.'),
  ('cmcp|international paper.*(maroc|morocco|k[eé]nitra)', 'k[eé]nitra', 'cmcp|international paper', 'CMCP–International Paper Kénitra — 모로코 최대 폐지 소비 공장, 재생 골판지원지 → 자사 골판지 공장 3곳(Casablanca·Agadir·Tanger Med Packaging).', 'CMCP-International Paper, Kénitra mill - the largest waste-paper user in Morocco, recycled containerboard feeding three IP corrugated plants (Casablanca HQ Aïn Sebâa, Agadir, Tanger Med Packaging).', 'MA check 2026-10-17: capacity not public - strength-led. +212 537 39 99 00. Same IP group as DS Smith rows (HR Belišće etc.).'),
  ('\mgpc\M.*(papier|carton)|gharb.*papier', 'mohammedia|k[eé]nitra', 'gpc|ynna', 'Ynna Holding 계열 GPC — Mohammedia 등 골판지 포장, 2025-09 MAD 5억 투자로 약 9만 → 16만 t(2030, 포장재 기준).', 'GPC Papier et Carton (Ynna Holding), Mohammedia, Kénitra and others - corrugated packaging, MAD 500 m Mohammedia expansion (2025-09) lifting about 90 kt to 160 kt/yr by 2030 (packaging, not base paper).', 'MA check 2026-10-17: own paper machine to confirm.'),
  ('le carton', null, 'le carton', null, null, 'MA check 2026-10-17: Le Carton, Aïn Harrouda - grey board, corrugated, delisted - context only.'),
  ('mondi.*(maroc|morocco|casablanca)', null, 'mondi.*(maroc|morocco|casablanca)', null, null, 'MA check 2026-10-17: Mondi Morocco - industrial paper packaging converting - context only.'),
  ('complipack', null, 'complipack', null, null, 'MA check 2026-10-17: Corrugated converting - context only.'),
  ('safapac', null, 'safapac', null, null, 'MA check 2026-10-17: Paper box converting - context only.'),
  ('brior', null, 'brior', null, null, 'MA check 2026-10-17: Brior Industries, Casablanca - tissue and hygiene products - context only.'),
  ('sanipak', null, 'sanipak', null, null, 'MA check 2026-10-17: Sanipak Maroc, Bouskoura - hygiene paper products - context only.'),
  ('safripac', null, 'safripac', null, null, 'MA check 2026-10-17: Safripac, Tanger - now part of Med Paper - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'morocco_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('med paper|papelera de t[eé]touan', 'tanger|moghogha', 'med paper'),
  ('\msipat\M|papiers tissues', 'mekn[eè]s|a[iï]n slougui', 'sipat'),
  ('cmcp|international paper.*(maroc|morocco|k[eé]nitra)', 'k[eé]nitra', 'cmcp|international paper'),
  ('\mgpc\M.*(papier|carton)|gharb.*papier', 'mohammedia|k[eé]nitra', 'gpc|ynna'),
  ('le carton', null, 'le carton'),
  ('mondi.*(maroc|morocco|casablanca)', null, 'mondi.*(maroc|morocco|casablanca)'),
  ('complipack', null, 'complipack'),
  ('safapac', null, 'safapac'),
  ('brior', null, 'brior'),
  ('sanipak', null, 'sanipak'),
  ('safripac', null, 'safripac')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('med paper|papelera de t[eé]touan', 'tanger|moghogha', 'med paper', false,
   $pj${"owner": "Med Paper", "priority": 1, "products": "Printing, writing, packaging papers", "grades": ["UWF", "Packaging paper"], "machines": 2, "capacity": {"value": 45000, "unit": "metric_t", "year": "Older theoretical figure", "source": "medpaper.co.ma"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "UWF 5-10-15 pct trial."}, "pitch": "Med Paper + Moroccan GCC + MBG UWF trial", "approach": "Lead Moroccan account - stepwise UWF trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\msipat\M|papiers tissues', 'mekn[eè]s|a[iï]n slougui', 'sipat', false,
   $pj${"owner": "SIPAT", "priority": 2, "products": "Tissue", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 16000, "unit": "metric_t", "year": "2010 figure", "source": "toscotec.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue 1-3-5 pct."}, "approach": "Low-dose tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-17"}$pj$::jsonb),
  ('cmcp|international paper.*(maroc|morocco|k[eé]nitra)', 'k[eé]nitra', 'cmcp|international paper', false,
   $pj${"owner": "International Paper", "priority": 3, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "approach": "Ash and strength baseline, then fibre-saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\mgpc\M.*(papier|carton)|gharb.*papier', 'mohammedia|k[eé]nitra', 'gpc|ynna', false,
   $pj${"owner": "Ynna Holding", "products": "Corrugated packaging", "grades": [], "capacity_split": [{"label": "Packaging 2030 target", "value_t": 160000}], "approach": "Confirm paper machine.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-17"}$pj$::jsonb),
  ('le carton', null, 'le carton', true,
   $pj${"owner": "Le Carton", "products": "Le Carton, Aïn Harrouda - grey board, corrugated, delisted", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('mondi.*(maroc|morocco|casablanca)', null, 'mondi.*(maroc|morocco|casablanca)', true,
   $pj${"owner": "Mondi", "products": "Mondi Morocco - industrial paper packaging converting", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('complipack', null, 'complipack', true,
   $pj${"owner": "COMPLIPACK", "products": "Corrugated converting", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('safapac', null, 'safapac', true,
   $pj${"owner": "Safapac", "products": "Paper box converting", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('brior', null, 'brior', true,
   $pj${"owner": "Brior Industries", "products": "Brior Industries, Casablanca - tissue and hygiene products", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sanipak', null, 'sanipak', true,
   $pj${"owner": "Sanipak Maroc", "products": "Sanipak Maroc, Bouskoura - hygiene paper products", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('safripac', null, 'safripac', true,
   $pj${"owner": "Med Paper", "products": "Safripac, Tanger - now part of Med Paper", "approach": "Converter or merged.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MA', 'Morocco', 'low',
   $cm$Med Paper UWF (Tanger, about 45 kt) and SIPAT tissue (Meknès, 16 kt) - CMCP-IP Kénitra recycled liner - Omya Maroc GCC plant, independent grinders$cm$,
   $cm$Morocco has real paper machines: Med Paper (listed, Tanger, printing and writing on two machines, about 45 kt theoretical), SIPAT (Meknès tissue PM1 and PM2, about 16 kt, upgraded 2024-25) and CMCP-International Paper Kénitra (recycled containerboard). GPC (Ynna, 160 kt packaging target), Le Carton, Mondi and others convert. Fillers: Omya Maroc makes calcium carbonate at Bouskoura (Omya licensee group), independent grinders Broychim, Carbonate Chaouia (under 38 micron) and Minerallum, lime of SIGMAROC - no paper PCC plant confirmed. Morocco is the top paper supplier to Senegal and Mauritania.$cm$,
   $cm${"fillers": "GCC: Omya Maroc (licensee), Broychim, Carbonate Chaouia, Minerallum. Lime: SIGMAROC. No PCC confirmed.", "mills": "UWF: Med Paper. Tissue: SIPAT. Recycled liner: CMCP-IP Kénitra. To confirm: GPC. Context: Le Carton, Mondi, COMPLIPACK, Safapac, Brior, Sanipak, Safripac (merged).", "strategy": "UWF trial at Med Paper and tissue trial at SIPAT, Omya Maroc or Broychim as GCC partner (NDA and IP first with Omya). Then West African export via Moroccan mills.", "risks": "Omya competing tech, older capacity data.", "next_steps": ["Propose a Med Paper UWF trial", "Propose a SIPAT tissue trial"], "key_numbers": [{"label": "Med Paper", "value": "about 45 kt (2 PMs)"}, {"label": "SIPAT", "value": "about 16 kt tissue"}], "files": ["seed_20261017k_morocco_mills_fillers"]}$cm$::jsonb,
   $cm$Med Paper UWF(Tanger, 약 4.5만 t)·SIPAT 티슈(Meknès, 1.6만 t) — CMCP-IP Kénitra 재생 라이너 — Omya Maroc GCC 공장, 독립 분쇄업체$cm$,
   $cm$모로코 실제 초지기: Med Paper(상장, Tanger, 인쇄·필기 2기 이론 약 4.5만 t), SIPAT(Meknès 티슈 PM1·PM2 약 1.6만 t, 2024~25 개조), CMCP-International Paper Kénitra(재생 골판지원지). GPC(Ynna, 포장 16만 t 목표)·Le Carton·Mondi 등은 가공. 충전제: Omya Maroc Bouskoura 탄산칼슘 제조(Omya 라이선시 그룹), 독립 분쇄 Broychim·Carbonate Chaouia(38 μm 미만)·Minerallum, SIGMAROC 석회 — 제지용 PCC 공장 미확인. 모로코는 세네갈·모리타니 최대 종이 공급국.$cm$,
   2410, 7550,
   $cm$Med Paper 4.5만 t × 5~15% + SIPAT 1.6만 t × 1~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('med paper|papelera de t[eé]touan', 'tanger|moghogha', 'med paper'),
  ('\msipat\M|papiers tissues', 'mekn[eè]s|a[iï]n slougui', 'sipat'),
  ('cmcp|international paper.*(maroc|morocco|k[eé]nitra)', 'k[eé]nitra', 'cmcp|international paper'),
  ('\mgpc\M.*(papier|carton)|gharb.*papier', 'mohammedia|k[eé]nitra', 'gpc|ynna'),
  ('le carton', null, 'le carton'),
  ('mondi.*(maroc|morocco|casablanca)', null, 'mondi.*(maroc|morocco|casablanca)'),
  ('complipack', null, 'complipack'),
  ('safapac', null, 'safapac'),
  ('brior', null, 'brior'),
  ('sanipak', null, 'sanipak'),
  ('safripac', null, 'safripac')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'morocco_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'morocco_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*maroc' or p.party_name ~* 'broychim' or p.party_name ~* 'carbonate chaouia' or p.party_name ~* 'sigmaroc' or p.party_name ~* 'minerallum')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    