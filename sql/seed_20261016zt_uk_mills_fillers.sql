-- ============================================================
-- seed_20261016zt_uk_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- United Kingdom update (reports 2026-10-16), country code GB.
-- 1) Fillers if missing (4): Omya UK, SMI Lifford (merchant PCC), European
--    Calcium Carbonates Westwood (ex Imerys), Longcliffe.
-- 2) Mills if missing (10) + plant blocks, priority 1-8: Sofidel UK, Essity
--    Prudhoe, James Cropper, Holmen Workington, Northwood, DS Smith Kemsley,
--    Saica Partington, Shotton Mill (plan). No priority: WEPA Bridgend,
--    Kimberly-Clark Barrow. Context (4) incl. Smurfit Birmingham SSK
--    (closed 2026-07-27).
-- 3) app.country_markets GB row (priority high).
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
           v.party_name, 'GB', v.region, v.city, v.website, 'active', 'uk_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(\muk\M|united kingdom|melton|ferriby)', 'Omya UK - Melton (North Ferriby)', 'East Riding of Yorkshire', 'North Ferriby', null, 'Omya UK(Melton Bottom, North Ferriby, Humber 산업단지) — GCC·PCC 제지용 충전제·코팅 안료, Multifill·FiberLean.', 'Omya UK, Melton Bottom, North Ferriby HU14 3HU (Humber Industrial Estate) - paper GCC and PCC fillers and coating pigments, Multifill and FiberLean (MFC plus mineral).', 'GB check 2026-10-16: +44 1482 636800. Royalty licensee at Omya HQ level - FiberLean is the closest competing tech to FCC.'),
  ('(specialty minerals|minerals technologies).*(\muk\M|lifford|birmingham|united kingdom)', 'Specialty Minerals UK - Lifford (Birmingham)', 'West Midlands', 'Birmingham', null, 'MTI SEC 공시의 영국 Merchant PCC 공장(Lifford Lane, Kings Norton, 버밍엄) — 제지사 공급.', 'Specialty Minerals (Minerals Technologies) merchant PCC plant at Lifford Lane, Kings Norton, Birmingham, listed in MTI SEC filings as supplying paper mills. Satellite contracts usually run 10 years initially.', 'GB check 2026-10-16: 2026 status, capacity and customers to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('european calcium carbonates|imerys.*(beverley|westwood)', 'European Calcium Carbonates - Westwood (Beverley)', 'East Riding of Yorkshire', 'Beverley', null, 'Beverley Westwood 고백색 백악 채굴·분쇄·분급 — 미분·초미분 GCC, 수성 슬러리(도료·접착제), 표면처리.', 'European Calcium Carbonates (former Imerys Minerals UK), Westwood, Beverley - high-white chalk quarried, ground and classified as micronised and ultrafine GCC, aqueous slurry (paint, adhesives) and coated grades (BSI-certified site).', 'GB check 2026-10-16: paper supply not confirmed. Imerys sold its paper minerals to Flacks Group in 2024 - check current owner.'),
  ('longcliffe', 'Longcliffe Quarries - Brassington', 'Derbyshire', 'Brassington', null, '독립 탄산칼슘 제조(Brassington, Matlock) — 고순도 GCC 분말·입상, 석회석 연 100만 t 이상.', 'Longcliffe Quarries, Brassington, Matlock (Derbyshire) - independent high-purity GCC powders and granules, over 1 Mt/yr limestone and products.', 'GB check 2026-10-16: paper-fine grade not confirmed. Not added: Sibelco UK, Ben Bennett Jr, CEMEX UK, LKAB Minerals (no paper grade).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GB check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(\muk\M|united kingdom|melton|ferriby)', 'Omya UK - Melton (North Ferriby)', 'East Riding of Yorkshire', 'North Ferriby', null, 'Omya UK(Melton Bottom, North Ferriby, Humber 산업단지) — GCC·PCC 제지용 충전제·코팅 안료, Multifill·FiberLean.', 'Omya UK, Melton Bottom, North Ferriby HU14 3HU (Humber Industrial Estate) - paper GCC and PCC fillers and coating pigments, Multifill and FiberLean (MFC plus mineral).', 'GB check 2026-10-16: +44 1482 636800. Royalty licensee at Omya HQ level - FiberLean is the closest competing tech to FCC.'),
  ('(specialty minerals|minerals technologies).*(\muk\M|lifford|birmingham|united kingdom)', 'Specialty Minerals UK - Lifford (Birmingham)', 'West Midlands', 'Birmingham', null, 'MTI SEC 공시의 영국 Merchant PCC 공장(Lifford Lane, Kings Norton, 버밍엄) — 제지사 공급.', 'Specialty Minerals (Minerals Technologies) merchant PCC plant at Lifford Lane, Kings Norton, Birmingham, listed in MTI SEC filings as supplying paper mills. Satellite contracts usually run 10 years initially.', 'GB check 2026-10-16: 2026 status, capacity and customers to confirm. SMI is the MBG tissue-track partner (NDA).'),
  ('european calcium carbonates|imerys.*(beverley|westwood)', 'European Calcium Carbonates - Westwood (Beverley)', 'East Riding of Yorkshire', 'Beverley', null, 'Beverley Westwood 고백색 백악 채굴·분쇄·분급 — 미분·초미분 GCC, 수성 슬러리(도료·접착제), 표면처리.', 'European Calcium Carbonates (former Imerys Minerals UK), Westwood, Beverley - high-white chalk quarried, ground and classified as micronised and ultrafine GCC, aqueous slurry (paint, adhesives) and coated grades (BSI-certified site).', 'GB check 2026-10-16: paper supply not confirmed. Imerys sold its paper minerals to Flacks Group in 2024 - check current owner.'),
  ('longcliffe', 'Longcliffe Quarries - Brassington', 'Derbyshire', 'Brassington', null, '독립 탄산칼슘 제조(Brassington, Matlock) — 고순도 GCC 분말·입상, 석회석 연 100만 t 이상.', 'Longcliffe Quarries, Brassington, Matlock (Derbyshire) - independent high-purity GCC powders and granules, over 1 Mt/yr limestone and products.', 'GB check 2026-10-16: paper-fine grade not confirmed. Not added: Sibelco UK, Ben Bennett Jr, CEMEX UK, LKAB Minerals (no paper grade).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'uk_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya UK - Melton (North Ferriby)', 'GCC and PCC supplier', 'Omya UK - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Specialty Minerals UK - Lifford (Birmingham)', 'PCC producer', 'SMI merchant PCC Lifford - partner route', 'merchant', 'B', 'pcc'),
  ('European Calcium Carbonates - Westwood (Beverley)', 'GCC producer', 'Chalk GCC and slurry - pilot candidate', 'merchant', 'C', 'gcc'),
  ('Longcliffe Quarries - Brassington', 'GCC producer', 'High-purity GCC - raw material and pilot', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'uk_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'GB', v.region, v.city, v.website, 'active', 'uk_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('sofidel.*(uk|hamilton|leicester|baglan)', 'leicester|hamilton', 'sofidel', 'Sofidel UK - Hamilton (Leicester)', 'Leicestershire', 'Leicester', null, 'Sofidel 영국 티슈 — Hamilton(Leicester)·Baglan(Neath)·Lancaster 원지·가공, Rothley Lodge 가공 전용.', 'Sofidel UK - tissue paper making and converting at Hamilton (Leicester) and Baglan (Neath, Wales), paper making at Lancaster, converting only at Rothley Lodge.', 'GB check 2026-10-16: capacity not public here. One row for the UK machines.'),
  ('essity.*prudhoe|prudhoe', 'prudhoe', 'essity', 'Essity - Prudhoe', 'Northumberland', 'Prudhoe', null, 'Essity Prudhoe 티슈 — 2026-04 £3,000만+ 재생섬유 처리시설 개장(연 10만 t 이상).', 'Essity Prudhoe (Northumberland) - consumer tissue, new recycled-fibre processing plant opened 2026-04 (over GBP 30 m, over 100,000 t/yr recovered fibre).', 'GB check 2026-10-16: tissue capacity not public here.'),
  ('james cropper|burneside', 'burneside', 'cropper', 'James Cropper - Burneside', 'Cumbria', 'Burneside', null, 'Burneside 고급 컬러지·특수 포장지·맞춤 종이·성형섬유 포장.', 'James Cropper, Burneside (Cumbria) - premium coloured papers, specialty packaging, bespoke papers and moulded-fibre packaging, strong new-materials R&D.', 'GB check 2026-10-16: +44 1539 722002.'),
  ('holmen.*workington|workington', 'workington', 'holmen|iggesund', 'Holmen Workington Mill - Workington', 'Cumbria', 'Workington', null, 'Holmen Workington — Incada 고급 FBB(현장 기계펄프 + 구매 화학펄프), 화장품·식품 포장.', 'Holmen Board and Paper, Workington Mill (Cumbria) - Incada folding boxboard, on-site mechanical pulp plus bought chemical pulp, for cosmetics, food and premium packaging.', 'GB check 2026-10-16: capacity not public here.'),
  ('northwood', null, 'northwood', 'Northwood (UK)', null, null, null, 'Northwood 영국 티슈 제조·가공 — Chesterfield·Disley·Lancaster 등.', 'Northwood - UK tissue making and converting at Chesterfield, Disley, Lancaster and other sites (CPI members).', 'GB check 2026-10-16: machine sites to confirm - one group row.'),
  ('kemsley', 'kemsley|sittingbourne', 'ds smith|international paper', 'DS Smith Kemsley Mill', 'Kent', 'Sittingbourne', null, 'DS Smith(International Paper) Kemsley 재생 골판지원지·포장용지.', 'DS Smith Kemsley Mill (International Paper), Sittingbourne (Kent) - recycled containerboard and packaging papers.', 'GB check 2026-10-16: strength-led.'),
  ('saica.*partington|partington', 'partington', 'saica', 'Saica Paper UK - Partington', 'Greater Manchester', 'Partington', null, 'Saica Partington(맨체스터 인근) 재생 골판지원지.', 'Saica Paper UK, Partington (Manchester) - recycled containerboard.', 'GB check 2026-10-16: capacity not public here.'),
  ('shotton', 'deeside|shotton', 'shotton|eren', 'Shotton Mill (Eren Holding) - Deeside', 'Flintshire', 'Deeside', null, 'Eren Holding 신규 Shotton Mill(Deeside) — 골판지원지 연 75만 t + 티슈 6.7만 t(최대 21만 t) 계획, 2026-08 잔여 공사.', 'Shotton Mill (Eren Holding, same group as Modern Karton), Deeside (Flintshire) - new containerboard mill planned at 750,000 t/yr plus tissue 67,000 t/yr (up to 210,000 t), construction largely done but still finishing in 2026-08.', 'GB check 2026-10-16: plans only - not counted until start-up. info@shottonmill.co.uk, +44 1244 280000.'),
  ('wepa.*bridgend|bridgend', 'bridgend', 'wepa', 'WEPA UK - Bridgend', 'Wales', 'Bridgend', null, 'WEPA 영국 티슈(Bridgend).', 'WEPA UK, Bridgend (Wales) - tissue.', 'GB check 2026-10-16: capacity not public here.'),
  ('kimberly.*barrow|barrow-in-furness', 'barrow', 'kimberly', 'Kimberly-Clark - Barrow-in-Furness', 'Cumbria', 'Barrow-in-Furness', null, 'Kimberly-Clark 영국 위생지(Barrow-in-Furness).', 'Kimberly-Clark UK, Barrow-in-Furness - tissue and hygiene paper.', 'GB check 2026-10-16: status and machines to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GB check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sofidel.*(uk|hamilton|leicester|baglan)', 'leicester|hamilton', 'sofidel', 'Sofidel 영국 티슈 — Hamilton(Leicester)·Baglan(Neath)·Lancaster 원지·가공, Rothley Lodge 가공 전용.', 'Sofidel UK - tissue paper making and converting at Hamilton (Leicester) and Baglan (Neath, Wales), paper making at Lancaster, converting only at Rothley Lodge.', 'GB check 2026-10-16: capacity not public here. One row for the UK machines.'),
  ('essity.*prudhoe|prudhoe', 'prudhoe', 'essity', 'Essity Prudhoe 티슈 — 2026-04 £3,000만+ 재생섬유 처리시설 개장(연 10만 t 이상).', 'Essity Prudhoe (Northumberland) - consumer tissue, new recycled-fibre processing plant opened 2026-04 (over GBP 30 m, over 100,000 t/yr recovered fibre).', 'GB check 2026-10-16: tissue capacity not public here.'),
  ('james cropper|burneside', 'burneside', 'cropper', 'Burneside 고급 컬러지·특수 포장지·맞춤 종이·성형섬유 포장.', 'James Cropper, Burneside (Cumbria) - premium coloured papers, specialty packaging, bespoke papers and moulded-fibre packaging, strong new-materials R&D.', 'GB check 2026-10-16: +44 1539 722002.'),
  ('holmen.*workington|workington', 'workington', 'holmen|iggesund', 'Holmen Workington — Incada 고급 FBB(현장 기계펄프 + 구매 화학펄프), 화장품·식품 포장.', 'Holmen Board and Paper, Workington Mill (Cumbria) - Incada folding boxboard, on-site mechanical pulp plus bought chemical pulp, for cosmetics, food and premium packaging.', 'GB check 2026-10-16: capacity not public here.'),
  ('northwood', null, 'northwood', 'Northwood 영국 티슈 제조·가공 — Chesterfield·Disley·Lancaster 등.', 'Northwood - UK tissue making and converting at Chesterfield, Disley, Lancaster and other sites (CPI members).', 'GB check 2026-10-16: machine sites to confirm - one group row.'),
  ('kemsley', 'kemsley|sittingbourne', 'ds smith|international paper', 'DS Smith(International Paper) Kemsley 재생 골판지원지·포장용지.', 'DS Smith Kemsley Mill (International Paper), Sittingbourne (Kent) - recycled containerboard and packaging papers.', 'GB check 2026-10-16: strength-led.'),
  ('saica.*partington|partington', 'partington', 'saica', 'Saica Partington(맨체스터 인근) 재생 골판지원지.', 'Saica Paper UK, Partington (Manchester) - recycled containerboard.', 'GB check 2026-10-16: capacity not public here.'),
  ('shotton', 'deeside|shotton', 'shotton|eren', 'Eren Holding 신규 Shotton Mill(Deeside) — 골판지원지 연 75만 t + 티슈 6.7만 t(최대 21만 t) 계획, 2026-08 잔여 공사.', 'Shotton Mill (Eren Holding, same group as Modern Karton), Deeside (Flintshire) - new containerboard mill planned at 750,000 t/yr plus tissue 67,000 t/yr (up to 210,000 t), construction largely done but still finishing in 2026-08.', 'GB check 2026-10-16: plans only - not counted until start-up. info@shottonmill.co.uk, +44 1244 280000.'),
  ('wepa.*bridgend|bridgend', 'bridgend', 'wepa', 'WEPA 영국 티슈(Bridgend).', 'WEPA UK, Bridgend (Wales) - tissue.', 'GB check 2026-10-16: capacity not public here.'),
  ('kimberly.*barrow|barrow-in-furness', 'barrow', 'kimberly', 'Kimberly-Clark 영국 위생지(Barrow-in-Furness).', 'Kimberly-Clark UK, Barrow-in-Furness - tissue and hygiene paper.', 'GB check 2026-10-16: status and machines to confirm.'),
  ('smurfit.*(birmingham|ssk)|\mssk\M', null, 'smurfit.*(birmingham|ssk)|\mssk\M', null, null, 'GB check 2026-10-16: Birmingham SSK containerboard mill (about 200 kt) - production stopped 2026-07-27 - context only.'),
  ('palm paper|king.?s lynn', null, 'palm paper|king.?s lynn', null, null, 'GB check 2026-10-16: Recycled newsprint, King s Lynn - context only.'),
  ('portals', null, 'portals', null, null, 'GB check 2026-10-16: Security and specialty paper, Bathford - context only.'),
  ('mondi.*(uk|united kingdom)', null, 'mondi.*(uk|united kingdom)', null, null, 'GB check 2026-10-16: UK packaging converting - mill to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'uk_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sofidel.*(uk|hamilton|leicester|baglan)', 'leicester|hamilton', 'sofidel'),
  ('essity.*prudhoe|prudhoe', 'prudhoe', 'essity'),
  ('james cropper|burneside', 'burneside', 'cropper'),
  ('holmen.*workington|workington', 'workington', 'holmen|iggesund'),
  ('northwood', null, 'northwood'),
  ('kemsley', 'kemsley|sittingbourne', 'ds smith|international paper'),
  ('saica.*partington|partington', 'partington', 'saica'),
  ('shotton', 'deeside|shotton', 'shotton|eren'),
  ('wepa.*bridgend|bridgend', 'bridgend', 'wepa'),
  ('kimberly.*barrow|barrow-in-furness', 'barrow', 'kimberly'),
  ('smurfit.*(birmingham|ssk)|\mssk\M', null, 'smurfit.*(birmingham|ssk)|\mssk\M'),
  ('palm paper|king.?s lynn', null, 'palm paper|king.?s lynn'),
  ('portals', null, 'portals'),
  ('mondi.*(uk|united kingdom)', null, 'mondi.*(uk|united kingdom)')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sofidel.*(uk|hamilton|leicester|baglan)', 'leicester|hamilton', 'sofidel',
   $pj${"owner": "Sofidel", "priority": 1, "products": "Tissue", "grades": ["Tissue"], "pitch": "Tissue FCC 3-5 pct on three UK machines", "approach": "Lead UK account - group path with Sofidel Italy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*prudhoe|prudhoe', 'prudhoe', 'essity',
   $pj${"owner": "Essity", "priority": 2, "products": "Consumer tissue", "grades": ["Tissue"], "approach": "Recycled-fibre tissue trial - brightness and dust checks.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "Recycled-fibre plant 2026-04", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('james cropper|burneside', 'burneside', 'cropper',
   $pj${"owner": "James Cropper", "priority": 3, "products": "Coloured and specialty paper, moulded fibre", "grades": ["Specialty paper"], "approach": "New-material co-development partner.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('holmen.*workington|workington', 'workington', 'holmen|iggesund',
   $pj${"owner": "Holmen", "priority": 4, "products": "Folding boxboard (Incada)", "grades": ["FBB"], "approach": "Ply-level fibre saving with stiffness kept.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('northwood', null, 'northwood',
   $pj${"owner": "Northwood", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "approach": "Faster pilot decisions.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kemsley', 'kemsley|sittingbourne', 'ds smith|international paper',
   $pj${"owner": "International Paper (DS Smith)", "priority": 6, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saica.*partington|partington', 'partington', 'saica',
   $pj${"owner": "Saica", "priority": 7, "products": "Recycled containerboard", "grades": ["Testliner", "Medium"], "approach": "Strength and cost balance.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('shotton', 'deeside|shotton', 'shotton|eren',
   $pj${"owner": "Eren Holding", "priority": 8, "products": "Containerboard and tissue (planned)", "grades": ["Testliner", "Tissue"], "capacity_split": [{"label": "Containerboard plan", "value_t": 750000}, {"label": "Tissue plan", "value_t": 67000}], "approach": "Design-stage FCC proposal for the tissue line - pair with Modern Karton TR.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wepa.*bridgend|bridgend', 'bridgend', 'wepa',
   $pj${"owner": "WEPA", "products": "Tissue", "grades": ["Tissue"], "approach": "Link with WEPA France.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kimberly.*barrow|barrow-in-furness', 'barrow', 'kimberly',
   $pj${"owner": "Kimberly-Clark", "products": "Tissue", "grades": ["Tissue"], "approach": "Confirm status.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(birmingham|ssk)|\mssk\M', null, 'smurfit.*(birmingham|ssk)|\mssk\M',
   $pj${"owner": "Smurfit Westrock", "products": "Birmingham SSK containerboard mill (about 200 kt) - production stopped 2026-07-27", "approach": "Closed, converter or selective.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('palm paper|king.?s lynn', null, 'palm paper|king.?s lynn',
   $pj${"owner": "Palm Paper", "products": "Recycled newsprint, King s Lynn", "approach": "Closed, converter or selective.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('portals', null, 'portals',
   $pj${"owner": "Portals", "products": "Security and specialty paper, Bathford", "approach": "Closed, converter or selective.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mondi.*(uk|united kingdom)', null, 'mondi.*(uk|united kingdom)',
   $pj${"owner": "Mondi", "products": "UK packaging converting - mill to confirm", "approach": "Closed, converter or selective.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GB', 'United Kingdom', 'high',
   $cm$3.29 Mt paper and board - Sofidel, Essity, Northwood tissue, James Cropper, Holmen Workington - Omya UK, SMI Lifford PCC - Shotton Mill under construction$cm$,
   $cm$The UK made 3.29 Mt paper and board in 2024 (1.44 Mt containerboard, CPI). FCC-fit: tissue at Sofidel (Hamilton, Baglan, Lancaster), Essity Prudhoe (new 100 kt recycled-fibre plant 2026-04), Northwood, WEPA Bridgend, plus James Cropper specialty and Holmen Workington FBB. Containerboard at DS Smith Kemsley and Saica Partington, Smurfit Westrock Birmingham SSK closed 2026-07-27, Shotton Mill (Eren, 750 kt liner plus 67 kt tissue) still finishing. Fillers: Omya UK (licensee, FiberLean), SMI merchant PCC at Lifford Birmingham, chalk GCC at Westwood Beverley (ex Imerys), Longcliffe.$cm$,
   $cm${"fillers": "GCC and PCC: Omya UK (Melton). Merchant PCC: SMI Lifford Birmingham. Chalk GCC: European Calcium Carbonates Westwood (ex Imerys). Limestone GCC: Longcliffe. Not added: Sibelco, Ben Bennett, CEMEX, LKAB.", "mills": "Tissue: Sofidel UK, Essity Prudhoe, Northwood, WEPA Bridgend, Kimberly-Clark Barrow. Specialty and board: James Cropper, Holmen Workington. Containerboard: DS Smith Kemsley, Saica Partington, Shotton Mill (plan). Context: Smurfit Birmingham SSK (closed), Palm Paper, Portals, Mondi.", "strategy": "Tissue trials at Sofidel and Essity, specialty co-development at James Cropper, FBB at Holmen. SMI Lifford via the tissue-track partnership, Omya UK via HQ (FiberLean benchmark). Shotton tissue line at design stage.", "risks": "FiberLean competes directly, UK mill closures.", "next_steps": ["Propose tissue trials to Sofidel UK", "Ask SMI about Lifford PCC capacity"], "key_numbers": [{"label": "2024 output", "value": "3.29 Mt (1.44 Mt containerboard)"}, {"label": "Shotton Mill plan", "value": "750 kt liner + 67 kt tissue"}], "files": ["seed_20261016zt_uk_mills_fillers"]}$cm$::jsonb,
   $cm$종이·판지 329만 t — Sofidel·Essity·Northwood 티슈, James Cropper, Holmen Workington — Omya UK·SMI Lifford PCC — Shotton Mill 건설 중$cm$,
   $cm$영국 2024 종이·판지 329만 t(골판지원지 144만 t). FCC 적합: 티슈 Sofidel(Hamilton·Baglan·Lancaster)·Essity Prudhoe(2026-04 재생섬유 10만 t 시설)·Northwood·WEPA, 특수지 James Cropper, FBB Holmen Workington. 골판지원지 DS Smith Kemsley·Saica Partington, Smurfit Birmingham SSK 는 2026-07-27 중단, Shotton Mill(Eren, 라이너 75만+티슈 6.7만 t) 마무리 공사. 충전제: Omya UK(라이선시, FiberLean), SMI Lifford 상업 PCC, Westwood 백악 GCC(구 Imerys), Longcliffe.$cm$,
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
      ('sofidel.*(uk|hamilton|leicester|baglan)', 'leicester|hamilton', 'sofidel'),
  ('essity.*prudhoe|prudhoe', 'prudhoe', 'essity'),
  ('james cropper|burneside', 'burneside', 'cropper'),
  ('holmen.*workington|workington', 'workington', 'holmen|iggesund'),
  ('northwood', null, 'northwood'),
  ('kemsley', 'kemsley|sittingbourne', 'ds smith|international paper'),
  ('saica.*partington|partington', 'partington', 'saica'),
  ('shotton', 'deeside|shotton', 'shotton|eren'),
  ('wepa.*bridgend|bridgend', 'bridgend', 'wepa'),
  ('kimberly.*barrow|barrow-in-furness', 'barrow', 'kimberly'),
  ('smurfit.*(birmingham|ssk)|\mssk\M', null, 'smurfit.*(birmingham|ssk)|\mssk\M'),
  ('palm paper|king.?s lynn', null, 'palm paper|king.?s lynn'),
  ('portals', null, 'portals'),
  ('mondi.*(uk|united kingdom)', null, 'mondi.*(uk|united kingdom)')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'uk_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'uk_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(\muk\M|united kingdom|melton|ferriby)' or p.party_name ~* '(specialty minerals|minerals technologies).*(\muk\M|lifford|birmingham|united kingdom)' or p.party_name ~* 'european calcium carbonates|imerys.*(beverley|westwood)' or p.party_name ~* 'longcliffe')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GB'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GB'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GB'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GB'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    