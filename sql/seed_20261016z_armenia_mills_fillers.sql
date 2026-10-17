-- ============================================================
-- seed_20261016z_armenia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Armenia update (reports 2026-10-16).
-- 1) Filler if missing (1): GALIK (limestone and lime, raw material).
-- 2) Mills if missing (2) + plant blocks: Grand Master Masis (1), Gofroline
--    Marmarashen (2). Context (7): Tukhtard-Tara, Kradan, Cleanland, Softex,
--    Unigroup, TOOP, BA LI Harutyunyan.
-- 3) app.country_markets AM row (priority low).
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
           v.party_name, 'AM', v.region, v.city, v.website, 'active', 'armenia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\mgalik\M', 'GALIK - Ararat', 'Ararat', 'Ararat', null, '1997년 설립 석회석·생석회·소석회 업체(Ararat, 구 시멘트공장 부속). 과거 석회 월 1,100~1,200 t, 광업·야금 수요.', 'GALIK LLC (1997), Ararat - limestone, quicklime and hydrated lime, spun out of the cement plant, own lab, about 1,100-1,200 t/month lime in older RECP data, mainly for mining and metallurgy.', 'AM check 2026-10-16: no paper GCC or PCC - raw material and lime base only (purity, Fe2O3, brightness to test). Not added: Araratcement and Hrazdan Cement (cement), Karmend Chemicals (importer), Arosha Powder (Iran - sanctioned, not a source). No paper PCC or GCC plant in Armenia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\mgalik\M', 'GALIK - Ararat', 'Ararat', 'Ararat', null, '1997년 설립 석회석·생석회·소석회 업체(Ararat, 구 시멘트공장 부속). 과거 석회 월 1,100~1,200 t, 광업·야금 수요.', 'GALIK LLC (1997), Ararat - limestone, quicklime and hydrated lime, spun out of the cement plant, own lab, about 1,100-1,200 t/month lime in older RECP data, mainly for mining and metallurgy.', 'AM check 2026-10-16: no paper GCC or PCC - raw material and lime base only (purity, Fe2O3, brightness to test). Not added: Araratcement and Hrazdan Cement (cement), Karmend Chemicals (importer), Arosha Powder (Iran - sanctioned, not a source). No paper PCC or GCC plant in Armenia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'armenia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('GALIK - Ararat', 'Carbonate raw material', 'Limestone and lime - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'armenia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'AM', v.region, v.city, v.website, 'active', 'armenia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('grand master', 'masis', 'grand master|grand holding', 'Grand Master - Masis', 'Ararat', 'Masis', null, 'Grand Holding 계열 Grand Master(2006, 전신 Masis Gofrotara 1969). Masis 에서 폐지·목재섬유로 종이·판지 원지·위생용 티슈 생산, 골판지·상자·종이봉투, 자체 시험실. 2025 완료 목표 투자.', 'Grand Master LLC (Grand Holding, 2006, successor of Masis Gofrotara 1969), 8 Hrant Vardanyan St, Masis (Ararat) - paper and board base paper and sanitary tissue on recovered paper and wood fibre, corrugated board, boxes, paper bags, own testing lab. Paper, board and tissue investment targeted for 2025.', 'AM check 2026-10-16: machine count and output not public. sales@grandmaster.am, +374 91 010407.'),
  ('gofroline', 'marmarashen', 'gofroline', 'Gofroline - Marmarashen', 'Ararat', 'Marmarashen', null, '2017년 설립(Marmarashen, Yerevan–Artashat 도로). 자체 생산 종이로 1·2겹 롤 원지·봉투용 롤·3겹 판지·골판지·상자.', 'Gofroline CJSC (2017), Yerevan - Artashat Highway 10/5, Marmarashen (Ararat) - one- and two-ply roll paper, bag paper, three-ply board, corrugated board and boxes made on its own paper, 51-250 staff.', 'AM check 2026-10-16: machine count and output not public. +374 60 754444.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grand master', 'masis', 'grand master|grand holding', 'Grand Holding 계열 Grand Master(2006, 전신 Masis Gofrotara 1969). Masis 에서 폐지·목재섬유로 종이·판지 원지·위생용 티슈 생산, 골판지·상자·종이봉투, 자체 시험실. 2025 완료 목표 투자.', 'Grand Master LLC (Grand Holding, 2006, successor of Masis Gofrotara 1969), 8 Hrant Vardanyan St, Masis (Ararat) - paper and board base paper and sanitary tissue on recovered paper and wood fibre, corrugated board, boxes, paper bags, own testing lab. Paper, board and tissue investment targeted for 2025.', 'AM check 2026-10-16: machine count and output not public. sales@grandmaster.am, +374 91 010407.'),
  ('gofroline', 'marmarashen', 'gofroline', '2017년 설립(Marmarashen, Yerevan–Artashat 도로). 자체 생산 종이로 1·2겹 롤 원지·봉투용 롤·3겹 판지·골판지·상자.', 'Gofroline CJSC (2017), Yerevan - Artashat Highway 10/5, Marmarashen (Ararat) - one- and two-ply roll paper, bag paper, three-ply board, corrugated board and boxes made on its own paper, 51-250 staff.', 'AM check 2026-10-16: machine count and output not public. +374 60 754444.'),
  ('tukhtard', null, 'tukhtard', null, null, 'AM check 2026-10-16: Corrugated boxes, Yerevan - converter - context only.'),
  ('kradan', null, 'kradan', null, null, 'AM check 2026-10-16: Paper, board and printing, Musaler - machine not confirmed - context only.'),
  ('cleanland', null, 'cleanland', null, null, 'AM check 2026-10-16: Paper and board, large boxes, Yerevan - machine not confirmed - context only.'),
  ('softex', null, 'softex', null, null, 'AM check 2026-10-16: Listed paper and board maker - products unknown - context only.'),
  ('unigroup', null, 'unigroup', null, null, 'AM check 2026-10-16: Listed paper and board maker, Agarak - products unknown - context only.'),
  ('\mtoop\M', null, '\mtoop\M', null, null, 'AM check 2026-10-16: Waste-paper collection, Gyumri - context only.'),
  ('harutyunyan|papertube', null, 'harutyunyan|papertube', null, null, 'AM check 2026-10-16: Paper tubes and industrial rolls - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'armenia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grand master', 'masis', 'grand master|grand holding'),
  ('gofroline', 'marmarashen', 'gofroline'),
  ('tukhtard', null, 'tukhtard'),
  ('kradan', null, 'kradan'),
  ('cleanland', null, 'cleanland'),
  ('softex', null, 'softex'),
  ('unigroup', null, 'unigroup'),
  ('\mtoop\M', null, '\mtoop\M'),
  ('harutyunyan|papertube', null, 'harutyunyan|papertube')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('grand master', 'masis', 'grand master|grand holding',
   $pj${"owner": "Grand Holding", "priority": 1, "products": "Paper and board base paper, tissue, corrugated", "grades": ["Tissue", "Testliner"], "pitch": "Tissue FCC trial plus recycled board", "approach": "Lead Armenian account - confirm machines and furnish.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gofroline', 'marmarashen', 'gofroline',
   $pj${"owner": "Gofroline", "priority": 2, "products": "Roll paper, bag paper, board, corrugated", "grades": ["Testliner", "Medium", "Bag paper"], "approach": "Packaging strength-hold trial (RCT, SCT, CMT, burst).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tukhtard', null, 'tukhtard',
   $pj${"owner": "Tukhtard-Tara", "products": "Corrugated boxes, Yerevan - converter", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kradan', null, 'kradan',
   $pj${"owner": "Kradan", "products": "Paper, board and printing, Musaler - machine not confirmed", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cleanland', null, 'cleanland',
   $pj${"owner": "Cleanland", "products": "Paper and board, large boxes, Yerevan - machine not confirmed", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('softex', null, 'softex',
   $pj${"owner": "Softex", "products": "Listed paper and board maker - products unknown", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unigroup', null, 'unigroup',
   $pj${"owner": "Unigroup", "products": "Listed paper and board maker, Agarak - products unknown", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mtoop\M', null, '\mtoop\M',
   $pj${"owner": "TOOP Waste Recycling", "products": "Waste-paper collection, Gyumri", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('harutyunyan|papertube', null, 'harutyunyan|papertube',
   $pj${"owner": "BA LI Harutyunyan", "products": "Paper tubes and industrial rolls - converter", "approach": "Converter or listing.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AM', 'Armenia', 'low',
   $cm$Grand Master (paper, board and tissue, Masis) and Gofroline (roll paper and board) - limestone and lime only, no paper filler maker$cm$,
   $cm$Armenia has two confirmed base-paper makers in Ararat Province: Grand Master (recycled paper and board plus sanitary tissue, Masis) and Gofroline (own roll paper, board and corrugated, Marmarashen). Others on the paper list convert or recycle. No paper PCC or GCC plant - GALIK makes limestone and lime, cement plants hold limestone, Karmend imports carbonate.$cm$,
   $cm${"fillers": "Raw material: GALIK (limestone and lime, Ararat). Not added: Araratcement, Hrazdan Cement, Karmend Chemicals (importer), Arosha Powder (Iran, sanctioned). No paper PCC or GCC.", "mills": "Grand Master Masis (paper, board, tissue), Gofroline Marmarashen (roll paper, board). Context: Tukhtard-Tara, Kradan, Cleanland, Softex, Unigroup, TOOP, BA LI Harutyunyan.", "strategy": "Direct trial at Grand Master tissue, then Gofroline packaging. FCC supply by a regional producer - never an Iranian one.", "risks": "Small volumes, no local paper-grade carbonate.", "next_steps": ["Ask Grand Master for machine specs and furnish"], "key_numbers": [{"label": "Spyur paper and board listings", "value": "9 (incl. converters)"}], "files": ["seed_20261016z_armenia_mills_fillers"]}$cm$::jsonb,
   $cm$Grand Master(종이·판지·티슈, Masis)·Gofroline(롤 원지·판지) — 석회석·석회만 있고 제지용 충전제 업체 없음$cm$,
   $cm$아르메니아에서 원지 제조가 확인된 곳은 Ararat 주 2곳: Grand Master(재생 종이·판지 + 위생용 티슈, Masis), Gofroline(자체 롤 원지·판지·골판지, Marmarashen). 나머지는 가공·재활용. 제지용 PCC·GCC 공장 없음 — GALIK 석회석·석회, 시멘트사 석회석, Karmend 수입.$cm$,
   null, null,
   $cm$생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('grand master', 'masis', 'grand master|grand holding'),
  ('gofroline', 'marmarashen', 'gofroline'),
  ('tukhtard', null, 'tukhtard'),
  ('kradan', null, 'kradan'),
  ('cleanland', null, 'cleanland'),
  ('softex', null, 'softex'),
  ('unigroup', null, 'unigroup'),
  ('\mtoop\M', null, '\mtoop\M'),
  ('harutyunyan|papertube', null, 'harutyunyan|papertube')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'armenia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'armenia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\mgalik\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    