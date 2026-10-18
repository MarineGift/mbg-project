-- ============================================================
-- seed_20261016zzp_denmark_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Denmark update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (2): Dankalk (Omya 44 pct), Faxe Kalk (Lhoist).
-- 2) Mills if missing (2) + plant blocks: Sonoco Skjern (1), Hartmann
--    Tønder (2). Context (8): converters, hygiene, closed mills.
-- 3) app.country_markets DK row (priority low).
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
           v.party_name, 'DK', v.region, v.city, v.website, 'active', 'denmark_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('dankalk', 'Dankalk (Omya 44 pct) - Aggersund', 'North Jutland', 'Løgstør', null, 'Dankalk K/S(DLG 56%·Omya 44%, Aggersundvej 50, Løgstør) — Aggersund 채굴지 약 300 ha·가공·건조·출하, Mjels 농업·환경용 석회. Betocarb·Lime Filler(콘크리트·아스팔트·도료·플라스틱).', 'Dankalk K/S (DLG 56 pct, Omya 44 pct), Aggersundvej 50, Løgstør - limestone and chalk quarry of about 300 ha at Aggersund with processing, drying and shipping, plus Mjels (agricultural and environmental lime). Products Betocarb and industrial lime filler for concrete, asphalt, paint and plastics.', 'DK check 2026-10-16: no paper GCC grade listed. dankalk@dankalk.dk, +45 33 68 74 00. Omya group route (licensee at HQ level, FiberLean competes).'),
  ('faxe kalk', 'Faxe Kalk (Lhoist) - Faxe', 'Zealand', 'Faxe', null, 'Lhoist 계열 Faxe Kalk — Faxe 채굴(원료 연 약 300만 t)·Faxe Ladeplads(Havnevej 1) 산업용 석회·백악·Vejle. 2025 매출 약 3.97억 DKK.', 'Faxe Kalk A/S (Lhoist Group) - limestone quarry at Faxe (about 3 Mt/yr raw material processed), industrial lime and chalk plant at Havnevej 1, Faxe Ladeplads, and a site at Vejle. 2025 sales about DKK 396.6 m.', 'DK check 2026-10-16: raw material only, 3 Mt is not paper GCC. No Danish paper PCC or satellite found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%DK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('dankalk', 'Dankalk (Omya 44 pct) - Aggersund', 'North Jutland', 'Løgstør', null, 'Dankalk K/S(DLG 56%·Omya 44%, Aggersundvej 50, Løgstør) — Aggersund 채굴지 약 300 ha·가공·건조·출하, Mjels 농업·환경용 석회. Betocarb·Lime Filler(콘크리트·아스팔트·도료·플라스틱).', 'Dankalk K/S (DLG 56 pct, Omya 44 pct), Aggersundvej 50, Løgstør - limestone and chalk quarry of about 300 ha at Aggersund with processing, drying and shipping, plus Mjels (agricultural and environmental lime). Products Betocarb and industrial lime filler for concrete, asphalt, paint and plastics.', 'DK check 2026-10-16: no paper GCC grade listed. dankalk@dankalk.dk, +45 33 68 74 00. Omya group route (licensee at HQ level, FiberLean competes).'),
  ('faxe kalk', 'Faxe Kalk (Lhoist) - Faxe', 'Zealand', 'Faxe', null, 'Lhoist 계열 Faxe Kalk — Faxe 채굴(원료 연 약 300만 t)·Faxe Ladeplads(Havnevej 1) 산업용 석회·백악·Vejle. 2025 매출 약 3.97억 DKK.', 'Faxe Kalk A/S (Lhoist Group) - limestone quarry at Faxe (about 3 Mt/yr raw material processed), industrial lime and chalk plant at Havnevej 1, Faxe Ladeplads, and a site at Vejle. 2025 sales about DKK 396.6 m.', 'DK check 2026-10-16: raw material only, 3 Mt is not paper GCC. No Danish paper PCC or satellite found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'denmark_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Dankalk (Omya 44 pct) - Aggersund', 'Chalk and lime producer', 'Omya-linked chalk filler - raw material', 'merchant', 'C', 'gcc'),
  ('Faxe Kalk (Lhoist) - Faxe', 'Lime producer', 'Limestone and lime - raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'denmark_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'DK', v.region, v.city, v.website, 'active', 'denmark_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('skjern', 'skjern', 'sonoco|skjern', 'Sonoco Skjern', 'Central Denmark', 'Skjern', null, 'Sonoco Skjern(Birkvej 14, 2022 인수, 구 Skjern Paper 1960년대~) — 100% 재활용 섬유 Greyboard·Greyliner·Blueliner·URB(지관·코어). 그룹 재생 판지 약 180만 t(2025 연차, 공장 단독 아님).', 'Sonoco Skjern ApS (bought 2022, formerly Skjern Paper, since the 1960s), Birkvej 14, Skjern - 100 pct recycled-fibre greyboard, greyliner, blueliner and uncoated recycled paperboard for tubes and cores. Sonoco group recycled board about 1.8 Mt/yr (2025 10-K, not this mill).', 'DK check 2026-10-16: mill capacity not public. +45 97 35 11 55.'),
  ('hartmann.*(t[oø]nder|packaging)|t[oø]nder', 't[oø]nder', 'hartmann', 'Hartmann Packaging - Tønder', 'Southern Denmark', 'Tønder', null, 'Hartmann Tønder(1966, Hartmannsvej 2) 몰드펄프 계란 포장재 — 약 350명(2026-03), 북유럽·영국 공급, 2026 신규 창고·라인 투자.', 'Hartmann Packaging, Hartmannsvej 2, Tønder (plant since 1966) - moulded-fibre egg packaging, about 350 staff (2026-03), supplies the Nordics and UK, new warehouse and line investment in 2026.', 'DK check 2026-10-16: moulded fibre - forming, drainage, drying, compression tests.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%DK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('skjern', 'skjern', 'sonoco|skjern', 'Sonoco Skjern(Birkvej 14, 2022 인수, 구 Skjern Paper 1960년대~) — 100% 재활용 섬유 Greyboard·Greyliner·Blueliner·URB(지관·코어). 그룹 재생 판지 약 180만 t(2025 연차, 공장 단독 아님).', 'Sonoco Skjern ApS (bought 2022, formerly Skjern Paper, since the 1960s), Birkvej 14, Skjern - 100 pct recycled-fibre greyboard, greyliner, blueliner and uncoated recycled paperboard for tubes and cores. Sonoco group recycled board about 1.8 Mt/yr (2025 10-K, not this mill).', 'DK check 2026-10-16: mill capacity not public. +45 97 35 11 55.'),
  ('hartmann.*(t[oø]nder|packaging)|t[oø]nder', 't[oø]nder', 'hartmann', 'Hartmann Tønder(1966, Hartmannsvej 2) 몰드펄프 계란 포장재 — 약 350명(2026-03), 북유럽·영국 공급, 2026 신규 창고·라인 투자.', 'Hartmann Packaging, Hartmannsvej 2, Tønder (plant since 1966) - moulded-fibre egg packaging, about 350 staff (2026-03), supplies the Nordics and UK, new warehouse and line investment in 2026.', 'DK check 2026-10-16: moulded fibre - forming, drainage, drying, compression tests.'),
  ('smurfit.*(danmark|denmark|kolding)', null, 'smurfit.*(danmark|denmark|kolding)', null, null, 'DK check 2026-10-16: Danish corrugated converting (2025 sales about DKK 1.3 bn) - context only.'),
  ('ds smith.*(danmark|denmark)', null, 'ds smith.*(danmark|denmark)', null, null, 'DK check 2026-10-16: Danish corrugated converting (about DKK 865 m) - context only.'),
  ('vpk.*(denmark|danmark|randers)|klingele.*randers', null, 'vpk.*(denmark|danmark|randers)|klingele.*randers', null, null, 'DK check 2026-10-16: Randers corrugated packaging - context only.'),
  ('schur', null, 'schur', null, null, 'DK check 2026-10-16: Folding cartons, Horsens (about DKK 443 m) - context only.'),
  ('abena', null, 'abena', null, null, 'DK check 2026-10-16: Hygiene and absorbent products, Aabenraa - no tissue machine confirmed - context only.'),
  ('elopak.*(denmark|danmark|lystrup)', null, 'elopak.*(denmark|danmark|lystrup)', null, null, 'DK check 2026-10-16: Liquid cartons, Lystrup - barrier-coating partner idea - context only.'),
  ('dalum', null, 'dalum', null, null, 'DK check 2026-10-16: Dalum Papir - closed 2012 - context only.'),
  ('grenaa', null, 'grenaa', null, null, 'DK check 2026-10-16: Grenaa Papfabrik - closed 2006 - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'denmark_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('skjern', 'skjern', 'sonoco|skjern'),
  ('hartmann.*(t[oø]nder|packaging)|t[oø]nder', 't[oø]nder', 'hartmann'),
  ('smurfit.*(danmark|denmark|kolding)', null, 'smurfit.*(danmark|denmark|kolding)'),
  ('ds smith.*(danmark|denmark)', null, 'ds smith.*(danmark|denmark)'),
  ('vpk.*(denmark|danmark|randers)|klingele.*randers', null, 'vpk.*(denmark|danmark|randers)|klingele.*randers'),
  ('schur', null, 'schur'),
  ('abena', null, 'abena'),
  ('elopak.*(denmark|danmark|lystrup)', null, 'elopak.*(denmark|danmark|lystrup)'),
  ('dalum', null, 'dalum'),
  ('grenaa', null, 'grenaa')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('skjern', 'skjern', 'sonoco|skjern', false,
   $pj${"owner": "Sonoco", "priority": 1, "products": "Recycled greyboard, liners, URB", "grades": ["Board"], "approach": "Stepwise 5-10-15 pct trial - Sonoco group path in Europe.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hartmann.*(t[oø]nder|packaging)|t[oø]nder', 't[oø]nder', 'hartmann', false,
   $pj${"owner": "Brødrene Hartmann", "priority": 2, "products": "Moulded-fibre egg packaging", "grades": ["Moulded fibre"], "approach": "Moulded-fibre R&D - links with V.L.T. (LV), Huhtamaki (CZ).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(danmark|denmark|kolding)', null, 'smurfit.*(danmark|denmark|kolding)', true,
   $pj${"owner": "Smurfit Westrock", "products": "Danish corrugated converting (2025 sales about DKK 1.3 bn)", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*(danmark|denmark)', null, 'ds smith.*(danmark|denmark)', true,
   $pj${"owner": "International Paper (DS Smith)", "products": "Danish corrugated converting (about DKK 865 m)", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vpk.*(denmark|danmark|randers)|klingele.*randers', null, 'vpk.*(denmark|danmark|randers)|klingele.*randers', true,
   $pj${"owner": "VPK Group", "products": "Randers corrugated packaging", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('schur', null, 'schur', true,
   $pj${"owner": "Schur", "products": "Folding cartons, Horsens (about DKK 443 m)", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('abena', null, 'abena', true,
   $pj${"owner": "ABENA", "products": "Hygiene and absorbent products, Aabenraa - no tissue machine confirmed", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('elopak.*(denmark|danmark|lystrup)', null, 'elopak.*(denmark|danmark|lystrup)', true,
   $pj${"owner": "Elopak", "products": "Liquid cartons, Lystrup - barrier-coating partner idea", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dalum', null, 'dalum', true,
   $pj${"owner": "(closed)", "products": "Dalum Papir - closed 2012", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('grenaa', null, 'grenaa', true,
   $pj${"owner": "(closed)", "products": "Grenaa Papfabrik - closed 2006", "approach": "Converter or closed.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'DK', 'Denmark', 'low',
   $cm$Sonoco Skjern recycled board and Hartmann Tønder moulded fibre - converters only otherwise - Dankalk (Omya 44 pct) and Faxe Kalk chalk, no paper PCC$cm$,
   $cm$Denmark's only clear paper machine site is Sonoco Skjern (100 pct recycled greyboard, liners and tube board). Hartmann Tønder makes moulded-fibre egg packaging. Smurfit Westrock, DS Smith, VPK, Schur, ABENA and Elopak convert or make hygiene products, and Dalum (2012) and Grenaa (2006) closed. No printing or large tissue machine. Carbonate: Dankalk (DLG 56 pct, Omya 44 pct) at Aggersund and Faxe Kalk (Lhoist) - building and agricultural grades, no paper GCC or PCC.$cm$,
   $cm${"fillers": "Chalk and lime: Dankalk (Omya-linked), Faxe Kalk (Lhoist). No paper PCC or GCC.", "mills": "Board: Sonoco Skjern. Moulded fibre: Hartmann Tønder. Context: Smurfit Westrock, DS Smith, VPK, Schur, ABENA, Elopak, Dalum and Grenaa (closed).", "strategy": "Sonoco Skjern stepwise trial then Sonoco Europe, Hartmann moulded-fibre R&D. Printing and tissue volumes sit in Sweden, Germany and Finland.", "risks": "Small volume, recycled-board strength limits.", "next_steps": ["Propose a stepwise trial to Sonoco Skjern"], "key_numbers": [{"label": "Faxe raw material", "value": "about 3 Mt/yr (not paper GCC)"}, {"label": "Sonoco group recycled board", "value": "about 1.8 Mt/yr"}], "files": ["seed_20261016zzp_denmark_mills_fillers"]}$cm$::jsonb,
   $cm$Sonoco Skjern 재생 판지·Hartmann Tønder 몰드펄프 — 나머지는 가공 — Dankalk(Omya 44%)·Faxe Kalk 백악, 제지용 PCC 없음$cm$,
   $cm$덴마크의 명확한 초지 공장은 Sonoco Skjern(100% 재생 Greyboard·라이너·지관 원지)뿐. Hartmann Tønder 는 몰드펄프 계란 포장. Smurfit·DS Smith·VPK·Schur·ABENA·Elopak 은 가공·위생용품, Dalum(2012)·Grenaa(2006) 폐쇄. 인쇄·대형 티슈 초지기 없음. 탄산칼슘: Dankalk(DLG 56%·Omya 44%) Aggersund, Faxe Kalk(Lhoist) — 건설·농업용, 제지용 GCC·PCC 없음.$cm$,
   null, null,
   $cm$공장 생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('skjern', 'skjern', 'sonoco|skjern'),
  ('hartmann.*(t[oø]nder|packaging)|t[oø]nder', 't[oø]nder', 'hartmann'),
  ('smurfit.*(danmark|denmark|kolding)', null, 'smurfit.*(danmark|denmark|kolding)'),
  ('ds smith.*(danmark|denmark)', null, 'ds smith.*(danmark|denmark)'),
  ('vpk.*(denmark|danmark|randers)|klingele.*randers', null, 'vpk.*(denmark|danmark|randers)|klingele.*randers'),
  ('schur', null, 'schur'),
  ('abena', null, 'abena'),
  ('elopak.*(denmark|danmark|lystrup)', null, 'elopak.*(denmark|danmark|lystrup)'),
  ('dalum', null, 'dalum'),
  ('grenaa', null, 'grenaa')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'denmark_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'denmark_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'dankalk' or p.party_name ~* 'faxe kalk')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'DK'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'DK'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'DK'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    