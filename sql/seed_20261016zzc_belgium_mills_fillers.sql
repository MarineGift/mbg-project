-- ============================================================
-- seed_20261016zzc_belgium_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Belgium update (reports 2026-10-16). Fixed generator.
-- Guards are Belgium-specific so other countries' SMI, Imerys, Carmeuse and
-- Sibelco rows stay separate.
-- 1) Fillers if missing (5): SMI Hermalle-sous-Huy (historical PCC), Imerys
--    Lixhe (historical GCC), Carmeuse Belgium, Sibelco, Calcaires de la Sambre.
-- 2) Mills if missing (6) + plant blocks, priority 1-6: Essity Stembert,
--    Sofidel Duffel, Burgo Ardennes, Stora Enso Langerbrugge, VPK Oudegem,
--    Ahlstrom Malmedy. Context (2): Sappi Lanaken (closed), Gondardennes.
-- 3) app.country_markets BE row (priority medium).
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
           v.party_name, 'BE', v.region, v.city, v.website, 'active', 'belgium_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('(specialty minerals|minerals technologies).*(belgi|hermalle)', 'Specialty Minerals Belgium - Hermalle-sous-Huy (historical PCC)', 'Liège', 'Hermalle-sous-Huy', null, 'MTI 상업 PCC 공장(Hermalle-sous-Huy, 2001 Huber 인수) — 제지 코팅용 PCC(2005 Roskill·2006 EU 심사).', 'Specialty Minerals (Minerals Technologies) merchant PCC plant at Hermalle-sous-Huy (Liège), bought by MTI of Huber in 2001 - coating PCC for paper (2005 Roskill, 2006 EU merger review). MTI runs 56 satellites worldwide (2026).', 'BE check 2026-10-16: 2026 status and capacity to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('imerys.*(lixhe|belgi)', 'Imerys - Lixhe GCC (historical)', 'Liège', 'Lixhe', null, 'Imerys Lixhe(Visé 인근) GCC — 이탈리아 Carrara 대리석 수입 분쇄, 제지용·폴리올레핀 필름용(2005 자료).', 'Imerys GCC plant at Lixhe near Visé (Liège) - imported Carrara marble ground as paper and polyolefin-film GCC (2005 data).', 'BE check 2026-10-16: owner and status after the 2024 sale of Imerys paper minerals to Flacks Group to confirm.'),
  ('carmeuse.*(belgi|seilles|aisemont|moha)', 'Carmeuse Belgium - Seilles', 'Namur', 'Seilles', null, 'Carmeuse SA 벨기에 석회 — Seilles·Aisemont·Moha(신규 소화라인).', 'Carmeuse SA (Belgium) lime plants at Seilles (Rue du Château 13a), Aisemont (Rue de Boudjesse 1) and Moha (Rue du Val Notre Dame 300, new hydration line).', 'BE check 2026-10-16: lime only - PCC raw material.'),
  ('sibelco.*(belgi|antwerp)', 'Sibelco (Belgium)', 'Antwerp', 'Antwerp', null, '벨기에 기반 글로벌 산업광물 Sibelco — GCC·PCC 제품군.', 'Sibelco (Belgium-based global industrial minerals) - GCC and PCC in its product range.', 'BE check 2026-10-16: Belgian paper-grade plant not confirmed. Dutch site is a separate row (Maastricht).'),
  ('calcaires de la sambre', 'Calcaires de la Sambre - Landelies', 'Hainaut', 'Landelies', null, 'Landelies 미세 석회석 분말·산업용 필러.', 'Calcaires de la Sambre, Landelies - fine limestone powders and industrial fillers.', 'BE check 2026-10-16: paper grade not confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('(specialty minerals|minerals technologies).*(belgi|hermalle)', 'Specialty Minerals Belgium - Hermalle-sous-Huy (historical PCC)', 'Liège', 'Hermalle-sous-Huy', null, 'MTI 상업 PCC 공장(Hermalle-sous-Huy, 2001 Huber 인수) — 제지 코팅용 PCC(2005 Roskill·2006 EU 심사).', 'Specialty Minerals (Minerals Technologies) merchant PCC plant at Hermalle-sous-Huy (Liège), bought by MTI of Huber in 2001 - coating PCC for paper (2005 Roskill, 2006 EU merger review). MTI runs 56 satellites worldwide (2026).', 'BE check 2026-10-16: 2026 status and capacity to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('imerys.*(lixhe|belgi)', 'Imerys - Lixhe GCC (historical)', 'Liège', 'Lixhe', null, 'Imerys Lixhe(Visé 인근) GCC — 이탈리아 Carrara 대리석 수입 분쇄, 제지용·폴리올레핀 필름용(2005 자료).', 'Imerys GCC plant at Lixhe near Visé (Liège) - imported Carrara marble ground as paper and polyolefin-film GCC (2005 data).', 'BE check 2026-10-16: owner and status after the 2024 sale of Imerys paper minerals to Flacks Group to confirm.'),
  ('carmeuse.*(belgi|seilles|aisemont|moha)', 'Carmeuse Belgium - Seilles', 'Namur', 'Seilles', null, 'Carmeuse SA 벨기에 석회 — Seilles·Aisemont·Moha(신규 소화라인).', 'Carmeuse SA (Belgium) lime plants at Seilles (Rue du Château 13a), Aisemont (Rue de Boudjesse 1) and Moha (Rue du Val Notre Dame 300, new hydration line).', 'BE check 2026-10-16: lime only - PCC raw material.'),
  ('sibelco.*(belgi|antwerp)', 'Sibelco (Belgium)', 'Antwerp', 'Antwerp', null, '벨기에 기반 글로벌 산업광물 Sibelco — GCC·PCC 제품군.', 'Sibelco (Belgium-based global industrial minerals) - GCC and PCC in its product range.', 'BE check 2026-10-16: Belgian paper-grade plant not confirmed. Dutch site is a separate row (Maastricht).'),
  ('calcaires de la sambre', 'Calcaires de la Sambre - Landelies', 'Hainaut', 'Landelies', null, 'Landelies 미세 석회석 분말·산업용 필러.', 'Calcaires de la Sambre, Landelies - fine limestone powders and industrial fillers.', 'BE check 2026-10-16: paper grade not confirmed.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'belgium_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Specialty Minerals Belgium - Hermalle-sous-Huy (historical PCC)', 'PCC producer', 'SMI merchant PCC history - partner route', 'merchant', 'C', 'pcc'),
  ('Imerys - Lixhe GCC (historical)', 'GCC producer', 'Ex-Imerys paper GCC - owner to confirm', 'merchant', 'C', 'gcc'),
  ('Carmeuse Belgium - Seilles', 'Lime producer', 'Lime base - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Sibelco (Belgium)', 'GCC and PCC supplier', 'Global minerals group - possible partner', 'merchant', 'C', 'gcc'),
  ('Calcaires de la Sambre - Landelies', 'GCC producer', 'Fine limestone filler - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'belgium_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BE', v.region, v.city, v.website, 'active', 'belgium_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('essity.*stembert|stembert', 'verviers|stembert', 'essity', 'Essity - Stembert (Verviers)', 'Liège', 'Verviers', null, 'Essity Stembert(Rue de la Papeterie 2, Verviers) 베네룩스 대형 티슈 — 초지기 2대 24시간, 약 7.5만 t(2021). 2025 법인 매출 약 7,830만 유로.', 'Essity Stembert, Rue de la Papeterie 2, Verviers - large Benelux tissue mill, two machines running 24/7, about 75,000 t/yr (2021 figure), toilet and facial base paper and products. Essity PLD Belgium 2025 sales about EUR 78.3 m.', 'BE check 2026-10-16: '),
  ('sofidel.*duffel|duffel', 'duffel', 'sofidel', 'Sofidel Benelux - Duffel', 'Antwerp', 'Duffel', null, 'Sofidel Duffel(A. Stocletlaan 3) 티슈 원지·가공 — TAD 기술.', 'Sofidel Benelux, A. Stocletlaan 3, Duffel - tissue paper mill and converting, TAD (through-air-dried) technology.', 'BE check 2026-10-16: TAD needs its own trial design.'),
  ('burgo.*ardenne|virton', 'virton', 'burgo', 'Burgo Ardennes - Virton', 'Luxembourg', 'Virton', null, 'Burgo Ardennes(Rue de la Papeterie 1, Virton) 펄프·제지 통합 — 2025 매출 약 3.79억 유로, 592명.', 'Burgo Ardennes, Rue de la Papeterie 1, Virton - integrated pulp and paper (Burgo Group), 2025 sales about EUR 379.1 m, about 592 FTE. 2023: bleached chemical pulp about 385,000 t/yr and woodfree coated paper about 375,000 t/yr.', 'BE check 2026-10-16: pulp capacity not added. Grade mix and filler use to confirm.'),
  ('langerbrugge', 'langerbrugge|gent|ghent', 'stora enso', 'Stora Enso Langerbrugge - Ghent', 'East Flanders', 'Ghent', null, 'Stora Enso Langerbrugge 재생 신문용지·SC 용지, 초지기 2대(2024). 2022 1대 골판지원지(70만 t) 전환 검토.', 'Stora Enso Langerbrugge, Ghent - recycled newsprint and SC paper on two machines (2024). Conversion of one machine to 700,000 t/yr containerboard was studied in 2022.', 'BE check 2026-10-16: confirm whether SC is still made.'),
  ('vpk.*oudegem|oudegem', 'oudegem|dendermonde', 'vpk', 'VPK Paper - Oudegem', 'East Flanders', 'Oudegem', null, 'VPK Oudegem 재생 Testliner·Fluting·Greyboard, 초지기 3대, 연 약 50만 t(90~600 g/m²).', 'VPK Paper, Oudegem (Dendermonde) - recycled testliner, fluting and greyboard on three machines, about 500,000 t/yr, 90-600 g/m2.', 'BE check 2026-10-16: strength-led - packaging-specific FCC needed.'),
  ('ahlstrom.*malmedy|malmedy', 'malmedy', 'ahlstrom', 'Ahlstrom Malmedy', 'Liège', 'Malmedy', null, 'Ahlstrom Malmedy 고급 벽지용 부직포(천연+합성섬유), 2025 매출 약 4,150만 유로·112명.', 'Ahlstrom Malmedy, Avenue du Pont de Warche 40 - premium wallcover nonwoven base of natural and synthetic fibres, 2025 sales about EUR 41.5 m, about 112 FTE.', 'BE check 2026-10-16: functional co-development only.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('essity.*stembert|stembert', 'verviers|stembert', 'essity', 'Essity Stembert(Rue de la Papeterie 2, Verviers) 베네룩스 대형 티슈 — 초지기 2대 24시간, 약 7.5만 t(2021). 2025 법인 매출 약 7,830만 유로.', 'Essity Stembert, Rue de la Papeterie 2, Verviers - large Benelux tissue mill, two machines running 24/7, about 75,000 t/yr (2021 figure), toilet and facial base paper and products. Essity PLD Belgium 2025 sales about EUR 78.3 m.', 'BE check 2026-10-16: '),
  ('sofidel.*duffel|duffel', 'duffel', 'sofidel', 'Sofidel Duffel(A. Stocletlaan 3) 티슈 원지·가공 — TAD 기술.', 'Sofidel Benelux, A. Stocletlaan 3, Duffel - tissue paper mill and converting, TAD (through-air-dried) technology.', 'BE check 2026-10-16: TAD needs its own trial design.'),
  ('burgo.*ardenne|virton', 'virton', 'burgo', 'Burgo Ardennes(Rue de la Papeterie 1, Virton) 펄프·제지 통합 — 2025 매출 약 3.79억 유로, 592명.', 'Burgo Ardennes, Rue de la Papeterie 1, Virton - integrated pulp and paper (Burgo Group), 2025 sales about EUR 379.1 m, about 592 FTE. 2023: bleached chemical pulp about 385,000 t/yr and woodfree coated paper about 375,000 t/yr.', 'BE check 2026-10-16: pulp capacity not added. Grade mix and filler use to confirm.'),
  ('langerbrugge', 'langerbrugge|gent|ghent', 'stora enso', 'Stora Enso Langerbrugge 재생 신문용지·SC 용지, 초지기 2대(2024). 2022 1대 골판지원지(70만 t) 전환 검토.', 'Stora Enso Langerbrugge, Ghent - recycled newsprint and SC paper on two machines (2024). Conversion of one machine to 700,000 t/yr containerboard was studied in 2022.', 'BE check 2026-10-16: confirm whether SC is still made.'),
  ('vpk.*oudegem|oudegem', 'oudegem|dendermonde', 'vpk', 'VPK Oudegem 재생 Testliner·Fluting·Greyboard, 초지기 3대, 연 약 50만 t(90~600 g/m²).', 'VPK Paper, Oudegem (Dendermonde) - recycled testliner, fluting and greyboard on three machines, about 500,000 t/yr, 90-600 g/m2.', 'BE check 2026-10-16: strength-led - packaging-specific FCC needed.'),
  ('ahlstrom.*malmedy|malmedy', 'malmedy', 'ahlstrom', 'Ahlstrom Malmedy 고급 벽지용 부직포(천연+합성섬유), 2025 매출 약 4,150만 유로·112명.', 'Ahlstrom Malmedy, Avenue du Pont de Warche 40 - premium wallcover nonwoven base of natural and synthetic fibres, 2025 sales about EUR 41.5 m, about 112 FTE.', 'BE check 2026-10-16: functional co-development only.'),
  ('sappi.*lanaken|lanaken', null, 'sappi.*lanaken|lanaken', null, null, 'BE check 2026-10-16: Lanaken coated woodfree (530 kt) - paper ended 2023-12, assets sold 2024 - context only.'),
  ('gondardennes', null, 'gondardennes', null, null, 'BE check 2026-10-16: Board packaging - process to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'belgium_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('essity.*stembert|stembert', 'verviers|stembert', 'essity'),
  ('sofidel.*duffel|duffel', 'duffel', 'sofidel'),
  ('burgo.*ardenne|virton', 'virton', 'burgo'),
  ('langerbrugge', 'langerbrugge|gent|ghent', 'stora enso'),
  ('vpk.*oudegem|oudegem', 'oudegem|dendermonde', 'vpk'),
  ('ahlstrom.*malmedy|malmedy', 'malmedy', 'ahlstrom'),
  ('sappi.*lanaken|lanaken', null, 'sappi.*lanaken|lanaken'),
  ('gondardennes', null, 'gondardennes')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('essity.*stembert|stembert', 'verviers|stembert', 'essity', false,
   $pj${"owner": "Essity", "priority": 1, "products": "Toilet and facial tissue", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 75000, "unit": "metric_t", "year": "2021 figure", "source": "essity.be"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "Lead Belgian account - Essity R&D path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel.*duffel|duffel', 'duffel', 'sofidel', false,
   $pj${"owner": "Sofidel", "priority": 2, "products": "TAD tissue", "grades": ["Tissue"], "approach": "TAD-specific trial - Sofidel group path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('burgo.*ardenne|virton', 'virton', 'burgo', false,
   $pj${"owner": "Burgo", "priority": 3, "products": "Pulp, coated woodfree paper", "grades": ["Coated paper"], "capacity": {"value": 375000, "unit": "metric_t", "year": "2023 figure (coated woodfree)", "source": "burgo.com"}, "approach": "Check grades - link with Burgo Italy.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('langerbrugge', 'langerbrugge|gent|ghent', 'stora enso', false,
   $pj${"owner": "Stora Enso", "priority": 4, "products": "Recycled newsprint, SC paper", "grades": ["Newsprint", "SC paper"], "machines": 2, "approach": "SC trial if SC still runs.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vpk.*oudegem|oudegem', 'oudegem|dendermonde', 'vpk', false,
   $pj${"owner": "VPK Group", "priority": 5, "products": "Testliner, fluting, greyboard", "grades": ["Testliner", "Medium", "Greyboard"], "machines": 3, "capacity": {"value": 500000, "unit": "metric_t", "year": "Company figure", "source": "vpkgroup.com"}, "approach": "Packaging-specific trial (RCT, SCT, CMT).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ahlstrom.*malmedy|malmedy', 'malmedy', 'ahlstrom', false,
   $pj${"owner": "Ahlstrom", "priority": 6, "products": "Wallcover nonwoven base", "grades": ["Specialty paper"], "approach": "Marine-fibre functional material talks.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*lanaken|lanaken', null, 'sappi.*lanaken|lanaken', true,
   $pj${"owner": "Sappi", "products": "Lanaken coated woodfree (530 kt) - paper ended 2023-12, assets sold 2024", "approach": "Closed or converter.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gondardennes', null, 'gondardennes', true,
   $pj${"owner": "Cartonnages de Gondardennes", "products": "Board packaging - process to confirm", "approach": "Closed or converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BE', 'Belgium', 'medium',
   $cm$Essity Stembert and Sofidel Duffel tissue, Burgo Ardennes, Stora Enso Langerbrugge SC, VPK Oudegem liner (500 kt) - SMI and Imerys filler history$cm$,
   $cm$Belgium's FCC-fit mills: tissue at Essity Stembert (two machines, about 75 kt) and Sofidel Duffel (TAD), Burgo Ardennes Virton (integrated pulp and paper, EUR 379 m), Stora Enso Langerbrugge (recycled newsprint and SC), VPK Oudegem recycled liner (500 kt), Ahlstrom Malmedy nonwovens. Sappi Lanaken (530 kt coated) stopped paper in 2023-12. Fillers: SMI merchant PCC at Hermalle-sous-Huy (ex Huber 2001) and Imerys GCC at Lixhe (Carrara marble, paper grades) - both historical, Carmeuse lime (Seilles, Aisemont, Moha), Sibelco, Calcaires de la Sambre.$cm$,
   $cm${"fillers": "PCC history: SMI Hermalle-sous-Huy. GCC history: Imerys Lixhe. Lime: Carmeuse. Other: Sibelco, Calcaires de la Sambre.", "mills": "Tissue: Essity Stembert, Sofidel Duffel. Printing and SC: Burgo Ardennes, Stora Enso Langerbrugge. Liner: VPK Oudegem. Specialty: Ahlstrom Malmedy. Closed: Sappi Lanaken.", "strategy": "Tissue trials at Essity and Sofidel via group R&D. Confirm Burgo and Langerbrugge grades. Check whether SMI Hermalle still runs - a three-way base for NL-BE-DE.", "risks": "Historical filler sites, grade changes at Langerbrugge.", "next_steps": ["Confirm SMI Hermalle-sous-Huy status", "Ask Burgo Ardennes for grades and filler use"], "key_numbers": [{"label": "VPK Oudegem", "value": "500 kt/yr"}, {"label": "Essity Stembert", "value": "about 75 kt (2021)"}, {"label": "Sappi Lanaken", "value": "530 kt, closed 2023-12"}], "files": ["seed_20261016zzc_belgium_mills_fillers"]}$cm$::jsonb,
   $cm$Essity Stembert·Sofidel Duffel 티슈, Burgo Ardennes, Stora Enso Langerbrugge SC, VPK Oudegem 라이너(50만 t) — SMI·Imerys 충전제 이력$cm$,
   $cm$벨기에 FCC 적합: 티슈 Essity Stembert(2대, 약 7.5만 t)·Sofidel Duffel(TAD), Burgo Ardennes Virton(통합 펄프·제지, 3.79억 유로), Stora Enso Langerbrugge(재생 신문·SC), VPK Oudegem 재생 라이너(50만 t), Ahlstrom Malmedy. Sappi Lanaken(코팅 53만 t)은 2023-12 중단. 충전제: SMI Hermalle-sous-Huy 상업 PCC(2001 Huber 인수)·Imerys Lixhe GCC(Carrara, 제지용) — 둘 다 과거 이력, Carmeuse 석회, Sibelco, Calcaires de la Sambre.$cm$,
   2250, 28750,
   $cm$하한 Essity 7.5만 t × 3%, 상한 Essity + VPK 57.5만 t × 5% (보고서 시나리오, VPK 는 강도 제약)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('essity.*stembert|stembert', 'verviers|stembert', 'essity'),
  ('sofidel.*duffel|duffel', 'duffel', 'sofidel'),
  ('burgo.*ardenne|virton', 'virton', 'burgo'),
  ('langerbrugge', 'langerbrugge|gent|ghent', 'stora enso'),
  ('vpk.*oudegem|oudegem', 'oudegem|dendermonde', 'vpk'),
  ('ahlstrom.*malmedy|malmedy', 'malmedy', 'ahlstrom'),
  ('sappi.*lanaken|lanaken', null, 'sappi.*lanaken|lanaken'),
  ('gondardennes', null, 'gondardennes')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'belgium_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'belgium_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*(belgi|hermalle)' or p.party_name ~* 'imerys.*(lixhe|belgi)' or p.party_name ~* 'carmeuse.*(belgi|seilles|aisemont|moha)' or p.party_name ~* 'sibelco.*(belgi|antwerp)' or p.party_name ~* 'calcaires de la sambre')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    