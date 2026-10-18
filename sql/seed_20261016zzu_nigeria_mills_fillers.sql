-- ============================================================
-- seed_20261016zzu_nigeria_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Nigeria update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (6): IzeCarb, Lafarge Africa GCC, Freedom Group,
--    Bees Industries, NovaCore, NARICT PCC pilot.
-- 2) Mills if missing (2) + plant blocks: Speciality Pulp and Paper (1),
--    NIXIN (2) - stated capacities only in split. Context (3): idle state mills.
-- 3) app.country_markets NG row (priority low).
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
           v.party_name, 'NG', v.region, v.city, v.website, 'active', 'nigeria_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('izecarb|izedon', 'Izedon Carbonates (IzeCarb) - Lampese', 'Edo', 'Lampese', null, 'IzeCarb — 채굴~GCC 일괄, Lampese 공장 2024-12-06 가동(약 4 ha, 초미세·미분쇄·분급·코팅), 2025 생산 7.2만 t, 2026 1분기 50만 t·2027 100만 t 목표.', 'Izedon Carbonates Limited (IzeCarb) - quarry-to-GCC, Lampese plant (Off Lampese-Bekuma Road, Edo) started 2024-12-06 on about 4 ha with ultrafine and fine mills, classifiers and coating, 72,000 t produced in 2025, targets 500,000 t/yr in Q1 2026 and 1 Mt/yr in 2027 (company, 2025-11). HQ Ikate, Lekki, Lagos.', 'NG check 2026-10-16: dry powder lines - wet slurry and paper sales to confirm, 2026 target status unknown. sales@izecarb.com, +234 915 111 1160. FCC co-production candidate 1.'),
  ('lafarge.*(africa|nigeria)', 'Lafarge Africa - GCC', 'Ogun', 'Ewekoro', null, 'Lafarge Africa 2025 GCC 출시 — CaCO3 92% 이상, 종이·도료·고무·세라믹·PVC 용도. Ewekoro·Sagamu·Mfamosing·Ashaka(시멘트 1,050만 t 은 GCC 아님).', 'Lafarge Africa Plc - launched Grand Calcium Carbonate in 2025, over 92 pct CaCO3, for paper, paint, rubber, ceramics, PVC and coatings. Sites at Ewekoro, Sagamu, Mfamosing, Ashaka (10.5 Mt/yr is cement, not GCC).', 'NG check 2026-10-16: GCC plant, capacity and brightness to confirm. ng-m-crt@lafargeholcim.com, +234 1 2713990.'),
  ('freedom group|\mtfg\M|ultracal', 'Freedom Group (CALCO, ULTRACAL) - Benin City', 'Edo', 'Benin City', null, 'Freedom Group(Benin City, Edo·Kwara 생산) — CALCO-15/30/60, ULTRACAL 초미세(15 μm 미만), CalCOAT 코팅, KAOLAY 카올린, 종이·포장 충전·코팅 명시.', 'Freedom Group, Benin City (production in Edo and Kwara) - GCC CALCO-15/30/60, ultrafine ULTRACAL (under 15 micron), stearic-coated CalCOAT and KAOLAY kaolin, paper and packaging filler and coating named, in-house testing.', 'NG check 2026-10-16: use uncoated grades for FCC. info@tfg.ng, +234 802 373 3366.'),
  ('bees industries', 'Bees Industries', 'Nigeria', null, null, 'Bees Industries(1985) 석회석·방해석·백운석 채굴·가공 — GCC 5~200 μm·표면처리 분말, 제지 명시.', 'Bees Industries Limited (1985) - mining and processing of limestone, calcite and dolomite, GCC 5-200 micron and surface-treated powders, paper named.', 'NG check 2026-10-16: fine paper grade not proven.'),
  ('novacore', 'NovaCore Minerals', 'Nigeria', null, null, 'NovaCore — GCC 10~45 μm, 초미세 1~10 μm, 순도 최대 98%, 백색도 95%+(회사 사양), 제지 명시.', 'NovaCore Minerals Ltd - GCC about 10-45 micron and ultrafine 1-10 micron, up to 98 pct purity and over 95 pct brightness (company specs), paper named.', 'NG check 2026-10-16: plant and scale to verify. Not added: Associated Mineral Resource (precision grinding, no specs).'),
  ('narict', 'NARICT PCC pilot - Zaria', 'Kaduna', 'Zaria', null, 'NARICT·RMRDC PCC 파일럿(Zaria) — 설계 PCC 3.57 t/일 + NaOH 2.88 t/일, 제약 등 목표, 2022 건물 준공·2025-01 특허.', 'National Research Institute for Chemical Technology (NARICT) with RMRDC, Zaria (Kaduna) - PCC pilot co-producing caustic soda, design 3.57 t/day PCC and 2.88 t/day NaOH aimed at pharma, building finished 2022, patent certified 2025-01.', 'NG check 2026-10-16: research pilot, no paper sales. Possible R and D link. No commercial paper PCC in Nigeria.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%NG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('izecarb|izedon', 'Izedon Carbonates (IzeCarb) - Lampese', 'Edo', 'Lampese', null, 'IzeCarb — 채굴~GCC 일괄, Lampese 공장 2024-12-06 가동(약 4 ha, 초미세·미분쇄·분급·코팅), 2025 생산 7.2만 t, 2026 1분기 50만 t·2027 100만 t 목표.', 'Izedon Carbonates Limited (IzeCarb) - quarry-to-GCC, Lampese plant (Off Lampese-Bekuma Road, Edo) started 2024-12-06 on about 4 ha with ultrafine and fine mills, classifiers and coating, 72,000 t produced in 2025, targets 500,000 t/yr in Q1 2026 and 1 Mt/yr in 2027 (company, 2025-11). HQ Ikate, Lekki, Lagos.', 'NG check 2026-10-16: dry powder lines - wet slurry and paper sales to confirm, 2026 target status unknown. sales@izecarb.com, +234 915 111 1160. FCC co-production candidate 1.'),
  ('lafarge.*(africa|nigeria)', 'Lafarge Africa - GCC', 'Ogun', 'Ewekoro', null, 'Lafarge Africa 2025 GCC 출시 — CaCO3 92% 이상, 종이·도료·고무·세라믹·PVC 용도. Ewekoro·Sagamu·Mfamosing·Ashaka(시멘트 1,050만 t 은 GCC 아님).', 'Lafarge Africa Plc - launched Grand Calcium Carbonate in 2025, over 92 pct CaCO3, for paper, paint, rubber, ceramics, PVC and coatings. Sites at Ewekoro, Sagamu, Mfamosing, Ashaka (10.5 Mt/yr is cement, not GCC).', 'NG check 2026-10-16: GCC plant, capacity and brightness to confirm. ng-m-crt@lafargeholcim.com, +234 1 2713990.'),
  ('freedom group|\mtfg\M|ultracal', 'Freedom Group (CALCO, ULTRACAL) - Benin City', 'Edo', 'Benin City', null, 'Freedom Group(Benin City, Edo·Kwara 생산) — CALCO-15/30/60, ULTRACAL 초미세(15 μm 미만), CalCOAT 코팅, KAOLAY 카올린, 종이·포장 충전·코팅 명시.', 'Freedom Group, Benin City (production in Edo and Kwara) - GCC CALCO-15/30/60, ultrafine ULTRACAL (under 15 micron), stearic-coated CalCOAT and KAOLAY kaolin, paper and packaging filler and coating named, in-house testing.', 'NG check 2026-10-16: use uncoated grades for FCC. info@tfg.ng, +234 802 373 3366.'),
  ('bees industries', 'Bees Industries', 'Nigeria', null, null, 'Bees Industries(1985) 석회석·방해석·백운석 채굴·가공 — GCC 5~200 μm·표면처리 분말, 제지 명시.', 'Bees Industries Limited (1985) - mining and processing of limestone, calcite and dolomite, GCC 5-200 micron and surface-treated powders, paper named.', 'NG check 2026-10-16: fine paper grade not proven.'),
  ('novacore', 'NovaCore Minerals', 'Nigeria', null, null, 'NovaCore — GCC 10~45 μm, 초미세 1~10 μm, 순도 최대 98%, 백색도 95%+(회사 사양), 제지 명시.', 'NovaCore Minerals Ltd - GCC about 10-45 micron and ultrafine 1-10 micron, up to 98 pct purity and over 95 pct brightness (company specs), paper named.', 'NG check 2026-10-16: plant and scale to verify. Not added: Associated Mineral Resource (precision grinding, no specs).'),
  ('narict', 'NARICT PCC pilot - Zaria', 'Kaduna', 'Zaria', null, 'NARICT·RMRDC PCC 파일럿(Zaria) — 설계 PCC 3.57 t/일 + NaOH 2.88 t/일, 제약 등 목표, 2022 건물 준공·2025-01 특허.', 'National Research Institute for Chemical Technology (NARICT) with RMRDC, Zaria (Kaduna) - PCC pilot co-producing caustic soda, design 3.57 t/day PCC and 2.88 t/day NaOH aimed at pharma, building finished 2022, patent certified 2025-01.', 'NG check 2026-10-16: research pilot, no paper sales. Possible R and D link. No commercial paper PCC in Nigeria.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'nigeria_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Izedon Carbonates (IzeCarb) - Lampese', 'GCC producer', 'Fast-growing GCC maker - candidate 1', 'merchant', 'B', 'gcc'),
  ('Lafarge Africa - GCC', 'GCC producer', 'Large industrial group GCC - partner option', 'merchant', 'C', 'gcc'),
  ('Freedom Group (CALCO, ULTRACAL) - Benin City', 'GCC producer', 'Ultrafine GCC and kaolin, paper named', 'merchant', 'C', 'gcc'),
  ('Bees Industries', 'GCC producer', 'Industrial GCC - raw material', 'merchant', 'C', 'gcc'),
  ('NovaCore Minerals', 'GCC producer', 'Fine GCC specs - raw-material option', 'merchant', 'C', 'gcc'),
  ('NARICT PCC pilot - Zaria', 'PCC pilot (research)', 'Research PCC pilot - R and D link', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'nigeria_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'NG', v.region, v.city, v.website, 'active', 'nigeria_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('speciality pulp|specialty pulp', 'nigeria', 'speciality|specialty', 'Speciality Pulp and Paper', null, null, null, 'Speciality Pulp and Paper — 포장용지 275 t/일(크라프트·백색 라이너), 인쇄·필기용지 175 t/일 신규 계획(2023 인터뷰).', 'Speciality Pulp and Paper - packaging papers on a 275 t/day line (kraft, white-top liner) and a planned 175 t/day printing and writing line (2023 interview).', 'NG check 2026-10-16: site, running status of the P and W line to confirm.'),
  ('nixin', 'nigeria', 'nixin', 'NIXIN Paper Mill', null, null, null, 'NIXIN 인쇄·필기용지 — 지종별 월 최대 8,000 t 가능(2025 보도).', 'NIXIN Paper Mill - printing and writing papers, up to 8,000 t/month depending on grade (2025 press, company claim).', 'NG check 2026-10-16: site and real output to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('speciality pulp|specialty pulp', 'nigeria', 'speciality|specialty', 'Speciality Pulp and Paper — 포장용지 275 t/일(크라프트·백색 라이너), 인쇄·필기용지 175 t/일 신규 계획(2023 인터뷰).', 'Speciality Pulp and Paper - packaging papers on a 275 t/day line (kraft, white-top liner) and a planned 175 t/day printing and writing line (2023 interview).', 'NG check 2026-10-16: site, running status of the P and W line to confirm.'),
  ('nixin', 'nigeria', 'nixin', 'NIXIN 인쇄·필기용지 — 지종별 월 최대 8,000 t 가능(2025 보도).', 'NIXIN Paper Mill - printing and writing papers, up to 8,000 t/month depending on grade (2025 press, company claim).', 'NG check 2026-10-16: site and real output to confirm.'),
  ('iwopin', null, 'iwopin', null, null, 'NG check 2026-10-16: Iwopin Pulp and Paper - printing and writing and pulp, old plant - restart status to confirm - context only.'),
  ('nigerian paper mill|jebba', null, 'nigerian paper mill|jebba', null, null, 'NG check 2026-10-16: Nigerian Paper Mill Jebba - former state mill, status to confirm - context only.'),
  ('oku.?iboku|nigerian newsprint', null, 'oku.?iboku|nigerian newsprint', null, null, 'NG check 2026-10-16: Nigerian Newsprint Manufacturing, Oku-Iboku - idle state mill - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'nigeria_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('speciality pulp|specialty pulp', 'nigeria', 'speciality|specialty'),
  ('nixin', 'nigeria', 'nixin'),
  ('iwopin', null, 'iwopin'),
  ('nigerian paper mill|jebba', null, 'nigerian paper mill|jebba'),
  ('oku.?iboku|nigerian newsprint', null, 'oku.?iboku|nigerian newsprint')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('speciality pulp|specialty pulp', 'nigeria', 'speciality|specialty', false,
   $pj${"owner": "Speciality Pulp and Paper", "priority": 1, "products": "Kraft, white-top liner, planned printing and writing", "grades": ["Kraft paper", "White-top liner", "UWF"], "capacity_split": [{"label": "Packaging line (275 t/day)", "value_t": 91000}, {"label": "P and W line plan (175 t/day)", "value_t": 58000}], "approach": "IzeCarb GCC + MBG trial on the white grades.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nixin', 'nigeria', 'nixin', false,
   $pj${"owner": "NIXIN", "priority": 2, "products": "Printing and writing paper", "grades": ["UWF"], "capacity_split": [{"label": "Stated max (8,000 t/month)", "value_t": 96000}], "approach": "UWF filler trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('iwopin', null, 'iwopin', true,
   $pj${"owner": "(state, idle)", "products": "Iwopin Pulp and Paper - printing and writing and pulp, old plant - restart status to confirm", "approach": "Idle - status first.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nigerian paper mill|jebba', null, 'nigerian paper mill|jebba', true,
   $pj${"owner": "(former state)", "products": "Nigerian Paper Mill Jebba - former state mill, status to confirm", "approach": "Idle - status first.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('oku.?iboku|nigerian newsprint', null, 'oku.?iboku|nigerian newsprint', true,
   $pj${"owner": "(former state)", "products": "Nigerian Newsprint Manufacturing, Oku-Iboku - idle state mill", "approach": "Idle - status first.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'NG', 'Nigeria', 'low',
   $cm$IzeCarb GCC (72 kt 2025, 500 kt target) and several GCC makers - few running paper machines (Speciality Pulp and Paper, NIXIN) - PCC only as NARICT pilot$cm$,
   $cm$Nigeria has growing GCC capacity: IzeCarb at Lampese (started 2024-12, 72 kt in 2025, targets 500 kt and 1 Mt), Lafarge Africa GCC (2025), Freedom Group (CALCO, ULTRACAL, kaolin), Bees Industries, NovaCore. PCC exists only as the NARICT pilot (3.57 t/day). Paper making is thin after the old state mills (Iwopin, Jebba, Oku-Iboku) stopped: Speciality Pulp and Paper (275 t/day packaging, 175 t/day P and W planned) and NIXIN (up to 8 kt/month P and W). Paper is largely imported.$cm$,
   $cm${"fillers": "GCC: IzeCarb, Lafarge Africa, Freedom Group, Bees Industries, NovaCore. PCC pilot: NARICT. Not added: Associated Mineral Resource.", "mills": "Speciality Pulp and Paper, NIXIN. Context: Iwopin, Nigerian Paper Mill Jebba, Nigerian Newsprint Oku-Iboku (idle).", "strategy": "IzeCarb as GCC partner, trials at Speciality and NIXIN white grades. Volume grows only if new P and W lines run - West Africa export option.", "risks": "Thin paper base, FX and power supply, unverified company claims.", "next_steps": ["Request IzeCarb TDS and plant list", "Confirm Speciality P and W line status"], "key_numbers": [{"label": "IzeCarb 2025", "value": "72 kt GCC, 500 kt target"}, {"label": "NIXIN stated max", "value": "8 kt/month"}], "files": ["seed_20261016zzu_nigeria_mills_fillers"]}$cm$::jsonb,
   $cm$IzeCarb GCC(2025 7.2만 t, 50만 t 목표) 등 GCC 업체 다수 — 가동 초지기 소수(Speciality Pulp and Paper, NIXIN) — PCC 는 NARICT 파일럿뿐$cm$,
   $cm$나이지리아 GCC 확대: IzeCarb Lampese(2024-12 가동, 2025 7.2만 t, 50만·100만 t 목표), Lafarge Africa GCC(2025), Freedom Group(CALCO·ULTRACAL·카올린), Bees, NovaCore. PCC 는 NARICT 파일럿(3.57 t/일)뿐. 국영 공장(Iwopin·Jebba·Oku-Iboku) 중단 후 제지 기반 약함: Speciality Pulp and Paper(포장 275 t/일, P&W 175 t/일 계획), NIXIN(월 최대 8천 t P&W). 종이는 주로 수입.$cm$,
   2880, 7700,
   $cm$NIXIN 연 9.6만 t × 3% ~ + Speciality P&W 계획 5.8만 t, 합계 × 5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('speciality pulp|specialty pulp', 'nigeria', 'speciality|specialty'),
  ('nixin', 'nigeria', 'nixin'),
  ('iwopin', null, 'iwopin'),
  ('nigerian paper mill|jebba', null, 'nigerian paper mill|jebba'),
  ('oku.?iboku|nigerian newsprint', null, 'oku.?iboku|nigerian newsprint')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'nigeria_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'nigeria_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'izecarb|izedon' or p.party_name ~* 'lafarge.*(africa|nigeria)' or p.party_name ~* 'freedom group|\mtfg\M|ultracal' or p.party_name ~* 'bees industries' or p.party_name ~* 'novacore' or p.party_name ~* 'narict')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'NG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'NG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'NG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    