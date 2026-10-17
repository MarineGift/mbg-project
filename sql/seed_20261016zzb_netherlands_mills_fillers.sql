-- ============================================================
-- seed_20261016zzb_netherlands_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Netherlands update (reports 2026-10-16). Fixed generator (context rows keep
-- existing plant keys).
-- 1) Fillers if missing (2): Omya Moerdijk PCC (historical), Sibelco
--    Maastricht.
-- 2) Mills if missing (8) + plant blocks, priority 1-7: Sappi Maastricht,
--    Essity Cuijk, WEPA Swalmen, Schut Papier, Papierfabriek Doetinchem,
--    Smurfit Westrock Roermond, Solidus. Parenco no priority. Context (5)
--    incl. bankruptcies.
-- 3) app.country_markets NL row (priority medium).
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
           v.party_name, 'NL', v.region, v.city, v.website, 'active', 'netherlands_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(moerdijk|netherlands|nederland)', 'Omya - Moerdijk PCC (historical)', 'North Brabant', 'Moerdijk', null, 'Omya Moerdijk(로테르담 인근) PCC — 1999 1분기 가동, 연 약 10만 t, 스웨덴·독일 제지공장 판매(2005 Roskill).', 'Omya merchant PCC plant at Moerdijk near Rotterdam - started Q1 1999 at about 100,000 t/yr, sold mainly to Swedish and some German mills (2005 Roskill).', 'NL check 2026-10-16: historical - 2026 status to confirm. Royalty licensee at Omya HQ level. Nearest SMI PCC is Walsum, Duisburg (DE row).'),
  ('sibelco.*maastricht', 'Sibelco - Maastricht', 'Limburg', 'Maastricht', null, 'Sibelco Maastricht(Op de Bos 300) — 탄산칼슘·돌로마이트·벤토나이트·실리카, 세라믹·건설·유리·코팅·폴리머·농업.', 'Sibelco Maastricht, Op de Bos 300 - calcium carbonate, dolomite, bentonite and silica for ceramics, construction, glass, coatings, polymers and agriculture.', 'NL check 2026-10-16: paper grade not confirmed. Customersupport.NL@sibelco.com, +31 43 366 3737.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%NL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(moerdijk|netherlands|nederland)', 'Omya - Moerdijk PCC (historical)', 'North Brabant', 'Moerdijk', null, 'Omya Moerdijk(로테르담 인근) PCC — 1999 1분기 가동, 연 약 10만 t, 스웨덴·독일 제지공장 판매(2005 Roskill).', 'Omya merchant PCC plant at Moerdijk near Rotterdam - started Q1 1999 at about 100,000 t/yr, sold mainly to Swedish and some German mills (2005 Roskill).', 'NL check 2026-10-16: historical - 2026 status to confirm. Royalty licensee at Omya HQ level. Nearest SMI PCC is Walsum, Duisburg (DE row).'),
  ('sibelco.*maastricht', 'Sibelco - Maastricht', 'Limburg', 'Maastricht', null, 'Sibelco Maastricht(Op de Bos 300) — 탄산칼슘·돌로마이트·벤토나이트·실리카, 세라믹·건설·유리·코팅·폴리머·농업.', 'Sibelco Maastricht, Op de Bos 300 - calcium carbonate, dolomite, bentonite and silica for ceramics, construction, glass, coatings, polymers and agriculture.', 'NL check 2026-10-16: paper grade not confirmed. Customersupport.NL@sibelco.com, +31 43 366 3737.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'netherlands_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya - Moerdijk PCC (historical)', 'PCC producer', 'Omya Moerdijk PCC - historical, licensee group', 'merchant', 'C', 'pcc'),
  ('Sibelco - Maastricht', 'GCC producer', 'Industrial carbonate - possible toll partner', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'netherlands_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'NL', v.region, v.city, v.website, 'active', 'netherlands_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('sappi.*maastricht', 'maastricht', 'sappi', 'Sappi Maastricht', 'Limburg', 'Maastricht', null, 'Sappi Maastricht 코팅 우드프리 용지·고급 포장판지 연 약 26만 t, 약 480명.', 'Sappi Maastricht mill - coated woodfree paper and premium packaging board, about 260,000 t/yr, about 480 staff.', 'NL check 2026-10-16: ownership and grade mix to confirm.'),
  ('essity.*cuijk|cuijk', 'cuijk', 'essity', 'Essity - Cuijk', 'North Brabant', 'Cuijk', null, 'Essity Cuijk 위생용지 — 화장지·키친·핸드타월·와이퍼·냅킨(Tork, Tempo).', 'Essity Cuijk - toilet tissue, kitchen and hand towels, industrial wipers, napkins (Tork, Tempo).', 'NL check 2026-10-16: capacity not public here.'),
  ('wepa.*(swalmen|nederland)|swalmen', 'swalmen', 'wepa', 'WEPA Nederland - Swalmen', 'Limburg', 'Swalmen', null, 'WEPA Nederland Swalmen 위생용지.', 'WEPA Nederland, Swalmen - tissue.', 'NL check 2026-10-16: capacity not public here.'),
  ('schut papier|\mschut\M.*heelsum', 'heelsum', 'schut', 'Schut Papier - Heelsum', 'Gelderland', 'Heelsum', null, '약 400년 역사의 특수지(Heelsum) — 미술용지·고급 특수지, 코코아·토마토·데님 등 대체 섬유.', 'Schut Papier, Heelsum - about 400 years of papermaking, fine art and specialty papers using alternative fibres (cocoa, tomato, denim, grass).', 'NL check 2026-10-16: surface and archival quality matter more than cost.'),
  ('papierfabriek doetinchem|doetinchem', 'doetinchem', 'doetinchem', 'Papierfabriek Doetinchem', 'Gelderland', 'Doetinchem', null, 'Doetinchem 폐지 원료 경량 포장용지·티슈 계열.', 'Papierfabriek Doetinchem - lightweight packaging and tissue-type papers on recovered paper.', 'NL check 2026-10-16: capacity not public here.'),
  ('smurfit.*roermond|roermond', 'roermond', 'smurfit|westrock', 'Smurfit Westrock Roermond Paper', 'Limburg', 'Roermond', null, 'Smurfit Westrock Roermond 재생 골판지원지 — 2022 약 67만 t(폐지 약 140만 베일).', 'Smurfit Westrock Roermond Paper, Mijnheerkensweg 18, Roermond - recycled containerboard, about 670,000 t in 2022 (about 1.4 m bales of recovered paper).', 'NL check 2026-10-16: strength-led.'),
  ('solidus', 'coevorden|pekela|nieuweschans', 'solidus', 'Solidus - Coevorden', 'Drenthe', 'Coevorden', null, 'Solidus 재생 판지·솔리드보드(Coevorden·Oude Pekela 등).', 'Solidus Solutions - recycled solid board and packaging at Coevorden, Oude Pekela and other Dutch sites.', 'NL check 2026-10-16: one row for Dutch Solidus mills.'),
  ('parenco', 'renkum', 'parenco|smurfit', 'Smurfit Westrock Parenco - Renkum', 'Gelderland', 'Renkum', null, 'Parenco(Veerweg 1, Renkum) 그래픽·포장용지 이력, 약 200명.', 'Smurfit Westrock Parenco mill, Veerweg 1, Renkum - magazine and packaging paper history, about 200 staff.', 'NL check 2026-10-16: current grade to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NL check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sappi.*maastricht', 'maastricht', 'sappi', 'Sappi Maastricht 코팅 우드프리 용지·고급 포장판지 연 약 26만 t, 약 480명.', 'Sappi Maastricht mill - coated woodfree paper and premium packaging board, about 260,000 t/yr, about 480 staff.', 'NL check 2026-10-16: ownership and grade mix to confirm.'),
  ('essity.*cuijk|cuijk', 'cuijk', 'essity', 'Essity Cuijk 위생용지 — 화장지·키친·핸드타월·와이퍼·냅킨(Tork, Tempo).', 'Essity Cuijk - toilet tissue, kitchen and hand towels, industrial wipers, napkins (Tork, Tempo).', 'NL check 2026-10-16: capacity not public here.'),
  ('wepa.*(swalmen|nederland)|swalmen', 'swalmen', 'wepa', 'WEPA Nederland Swalmen 위생용지.', 'WEPA Nederland, Swalmen - tissue.', 'NL check 2026-10-16: capacity not public here.'),
  ('schut papier|\mschut\M.*heelsum', 'heelsum', 'schut', '약 400년 역사의 특수지(Heelsum) — 미술용지·고급 특수지, 코코아·토마토·데님 등 대체 섬유.', 'Schut Papier, Heelsum - about 400 years of papermaking, fine art and specialty papers using alternative fibres (cocoa, tomato, denim, grass).', 'NL check 2026-10-16: surface and archival quality matter more than cost.'),
  ('papierfabriek doetinchem|doetinchem', 'doetinchem', 'doetinchem', 'Doetinchem 폐지 원료 경량 포장용지·티슈 계열.', 'Papierfabriek Doetinchem - lightweight packaging and tissue-type papers on recovered paper.', 'NL check 2026-10-16: capacity not public here.'),
  ('smurfit.*roermond|roermond', 'roermond', 'smurfit|westrock', 'Smurfit Westrock Roermond 재생 골판지원지 — 2022 약 67만 t(폐지 약 140만 베일).', 'Smurfit Westrock Roermond Paper, Mijnheerkensweg 18, Roermond - recycled containerboard, about 670,000 t in 2022 (about 1.4 m bales of recovered paper).', 'NL check 2026-10-16: strength-led.'),
  ('solidus', 'coevorden|pekela|nieuweschans', 'solidus', 'Solidus 재생 판지·솔리드보드(Coevorden·Oude Pekela 등).', 'Solidus Solutions - recycled solid board and packaging at Coevorden, Oude Pekela and other Dutch sites.', 'NL check 2026-10-16: one row for Dutch Solidus mills.'),
  ('parenco', 'renkum', 'parenco|smurfit', 'Parenco(Veerweg 1, Renkum) 그래픽·포장용지 이력, 약 200명.', 'Smurfit Westrock Parenco mill, Veerweg 1, Renkum - magazine and packaging paper history, about 200 staff.', 'NL check 2026-10-16: current grade to confirm.'),
  ('crown van gelder', null, 'crown van gelder', null, null, 'NL check 2026-10-16: Specialty and inkjet paper, Velsen-Noord - Crown Van Gelder B.V. bankrupt 2023-01, current operator to confirm - context only.'),
  ('folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', null, 'folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', null, null, 'NL check 2026-10-16: Folding Boxboard Eerbeek - bankrupt 2026-06, restart failed 2026-08, closed - context only.'),
  ('coldenhove', null, 'coldenhove', null, null, 'NL check 2026-10-16: Sublimation and technical paper, Eerbeek - Coldenhove Paper B.V. bankrupt 2026-05, operator to confirm - context only.'),
  ('de hoop|ds smith.*eerbeek', null, 'de hoop|ds smith.*eerbeek', null, null, 'NL check 2026-10-16: De Hoop recycled containerboard, Eerbeek - context only.'),
  ('sappi.*nijmegen', null, 'sappi.*nijmegen', null, null, 'NL check 2026-10-16: Nijmegen graphic paper - status to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'netherlands_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sappi.*maastricht', 'maastricht', 'sappi'),
  ('essity.*cuijk|cuijk', 'cuijk', 'essity'),
  ('wepa.*(swalmen|nederland)|swalmen', 'swalmen', 'wepa'),
  ('schut papier|\mschut\M.*heelsum', 'heelsum', 'schut'),
  ('papierfabriek doetinchem|doetinchem', 'doetinchem', 'doetinchem'),
  ('smurfit.*roermond|roermond', 'roermond', 'smurfit|westrock'),
  ('solidus', 'coevorden|pekela|nieuweschans', 'solidus'),
  ('parenco', 'renkum', 'parenco|smurfit'),
  ('crown van gelder', null, 'crown van gelder'),
  ('folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', null, 'folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek'),
  ('coldenhove', null, 'coldenhove'),
  ('de hoop|ds smith.*eerbeek', null, 'de hoop|ds smith.*eerbeek'),
  ('sappi.*nijmegen', null, 'sappi.*nijmegen')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sappi.*maastricht', 'maastricht', 'sappi', false,
   $pj${"owner": "Sappi", "priority": 1, "products": "Coated woodfree paper, packaging board", "grades": ["Coated paper", "Board"], "capacity": {"value": 260000, "unit": "metric_t", "year": "Company figure", "source": "sappi.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Base paper only - same-ash comparison vs GCC."}, "pitch": "Same-ash FCC vs GCC on coated base paper", "approach": "Lead Dutch account - links with Sappi Alfeld (DE).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*cuijk|cuijk', 'cuijk', 'essity', false,
   $pj${"owner": "Essity", "priority": 2, "products": "Tissue", "grades": ["Tissue"], "approach": "Joint tissue trial - Essity R&D (Mannheim, Kunheim).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wepa.*(swalmen|nederland)|swalmen', 'swalmen', 'wepa', false,
   $pj${"owner": "WEPA", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "approach": "Recycled vs virgin tissue trial - WEPA group path.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('schut papier|\mschut\M.*heelsum', 'heelsum', 'schut', false,
   $pj${"owner": "Schut Papier", "priority": 4, "products": "Art and specialty paper", "grades": ["Specialty paper"], "pitch": "Marine-fibre specialty paper co-development", "approach": "R&D partner.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papierfabriek doetinchem|doetinchem', 'doetinchem', 'doetinchem', false,
   $pj${"owner": "Papierfabriek Doetinchem", "priority": 5, "products": "Lightweight packaging and tissue-type paper", "grades": ["Packaging paper", "Tissue"], "approach": "Lightweight fibre-saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*roermond|roermond', 'roermond', 'smurfit|westrock', false,
   $pj${"owner": "Smurfit Westrock", "priority": 6, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "capacity": {"value": 670000, "unit": "metric_t", "year": "Output 2022", "source": "smurfitwestrock.com"}, "approach": "Separate packaging trial later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('solidus', 'coevorden|pekela|nieuweschans', 'solidus', false,
   $pj${"owner": "Solidus", "priority": 7, "products": "Recycled solid board", "grades": ["Board"], "approach": "Ply-level strength trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('parenco', 'renkum', 'parenco|smurfit', false,
   $pj${"owner": "Smurfit Westrock", "products": "Graphic and packaging paper", "grades": ["Printing paper", "Packaging paper"], "approach": "Grade check first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('crown van gelder', null, 'crown van gelder', true,
   $pj${"owner": "Crown Van Gelder", "products": "Specialty and inkjet paper, Velsen-Noord - Crown Van Gelder B.V. bankrupt 2023-01, current operator to confirm", "approach": "Closed, bankrupt or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', null, 'folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', true,
   $pj${"owner": "(former MM)", "products": "Folding Boxboard Eerbeek - bankrupt 2026-06, restart failed 2026-08, closed", "approach": "Closed, bankrupt or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('coldenhove', null, 'coldenhove', true,
   $pj${"owner": "Coldenhove", "products": "Sublimation and technical paper, Eerbeek - Coldenhove Paper B.V. bankrupt 2026-05, operator to confirm", "approach": "Closed, bankrupt or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('de hoop|ds smith.*eerbeek', null, 'de hoop|ds smith.*eerbeek', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "De Hoop recycled containerboard, Eerbeek", "approach": "Closed, bankrupt or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*nijmegen', null, 'sappi.*nijmegen', true,
   $pj${"owner": "Sappi", "products": "Nijmegen graphic paper - status to confirm", "approach": "Closed, bankrupt or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'NL', 'Netherlands', 'medium',
   $cm$Sappi Maastricht coated paper (260 kt), Essity Cuijk and WEPA tissue, Schut Papier specialty - bankruptcies at Eerbeek - Omya Moerdijk PCC history$cm$,
   $cm$FCC-fit Dutch mills: Sappi Maastricht (coated woodfree and board, about 260 kt), tissue at Essity Cuijk and WEPA Swalmen, Schut Papier specialty (alternative fibres), Papierfabriek Doetinchem lightweight papers. Recycled board and liner: Smurfit Westrock Roermond (670 kt) and Parenco, Solidus, De Hoop. Recent failures: Crown Van Gelder (2023), Coldenhove (2026-05), Folding Boxboard Eerbeek (closed 2026-08). Fillers: Omya Moerdijk merchant PCC (1999, 100 kt, status unknown), Sibelco Maastricht industrial carbonate, SMI Walsum PCC nearby in Germany.$cm$,
   $cm${"fillers": "PCC: Omya Moerdijk (historical). Carbonate: Sibelco Maastricht. Nearby: SMI Walsum (DE), Omya and SCHAEFER KALK Germany.", "mills": "Coated: Sappi Maastricht. Tissue: Essity Cuijk, WEPA Swalmen. Specialty: Schut Papier. Lightweight: Doetinchem. Board and liner: Smurfit Westrock Roermond and Parenco, Solidus. Context: Crown Van Gelder, Folding Boxboard Eerbeek (closed), Coldenhove, De Hoop, Sappi Nijmegen.", "strategy": "Treat NL-BE-DE as one FCC zone. Sappi Maastricht same-ash trial, Essity and WEPA tissue via group R&D, Schut for marine-fibre specialty.", "risks": "Mill bankruptcies, energy cost, Omya competing tech.", "next_steps": ["Propose a same-ash trial to Sappi Maastricht", "Confirm Omya Moerdijk PCC status"], "key_numbers": [{"label": "Sappi Maastricht", "value": "about 260 kt/yr"}, {"label": "Smurfit Roermond 2022", "value": "about 670 kt"}, {"label": "Omya Moerdijk PCC (1999)", "value": "about 100 kt/yr"}], "files": ["seed_20261016zzb_netherlands_mills_fillers"]}$cm$::jsonb,
   $cm$Sappi Maastricht 코팅지(26만 t), Essity Cuijk·WEPA 티슈, Schut Papier 특수지 — Eerbeek 파산 — Omya Moerdijk PCC 이력$cm$,
   $cm$네덜란드 FCC 적합: Sappi Maastricht(코팅 우드프리·판지 약 26만 t), 티슈 Essity Cuijk·WEPA Swalmen, Schut Papier 특수지(대체 섬유), Doetinchem 경량지. 재생 판지·라이너: Smurfit Roermond(67만 t)·Parenco, Solidus, De Hoop. 최근 파산: Crown Van Gelder(2023), Coldenhove(2026-05), Folding Boxboard Eerbeek(2026-08 폐쇄). 충전제: Omya Moerdijk 상업 PCC(1999 10만 t, 현재 미확인), Sibelco Maastricht, 인근 독일 SMI Walsum.$cm$,
   7800, 13000,
   $cm$Sappi Maastricht 26만 t × FCC 3~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('sappi.*maastricht', 'maastricht', 'sappi'),
  ('essity.*cuijk|cuijk', 'cuijk', 'essity'),
  ('wepa.*(swalmen|nederland)|swalmen', 'swalmen', 'wepa'),
  ('schut papier|\mschut\M.*heelsum', 'heelsum', 'schut'),
  ('papierfabriek doetinchem|doetinchem', 'doetinchem', 'doetinchem'),
  ('smurfit.*roermond|roermond', 'roermond', 'smurfit|westrock'),
  ('solidus', 'coevorden|pekela|nieuweschans', 'solidus'),
  ('parenco', 'renkum', 'parenco|smurfit'),
  ('crown van gelder', null, 'crown van gelder'),
  ('folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek', null, 'folding boxboard eerbeek|\mmm\M.*eerbeek|mayr.*eerbeek'),
  ('coldenhove', null, 'coldenhove'),
  ('de hoop|ds smith.*eerbeek', null, 'de hoop|ds smith.*eerbeek'),
  ('sappi.*nijmegen', null, 'sappi.*nijmegen')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'netherlands_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'netherlands_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(moerdijk|netherlands|nederland)' or p.party_name ~* 'sibelco.*maastricht')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'NL'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'NL'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'NL'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    