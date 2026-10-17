-- ============================================================
-- seed_20261016zn_moldova_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Moldova update (reports 2026-10-16).
-- 1) Fillers if missing (2): CALCAR (limestone), LIORMAX (filler powder).
-- 2) Mill if missing + plant block: CANDELUX-COM (1). Context (6): MITRA-GRUP
--    (Milta), Combinatul de Articole din Carton, CARTNORD, MoldPack,
--    Pergament, MOLDCARTON (liquidation).
-- 3) app.country_markets MD row (priority low).
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
           v.party_name, 'MD', v.region, v.city, v.website, 'active', 'moldova_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcar.*(briceni|beleavin)|^calcar( s.a.?)?$', 'CALCAR - Beleavinți (Briceni)', 'Briceni', 'Beleavinți', null, '1992년 설립 석회석 채굴·파쇄·분급(Briceni Beleavinți) — 연 약 100만 m³, 공장 2곳, 제당·야금·유리·건설 공급. 야금용 CaCO3 97.47%, 유리용 CaCO3+MgCO3 98.92%(Fe2O3 0.042%).', 'CALCAR S.A. (1992), quarry and two crushing and screening plants at Beleavinți (Briceni), logistics base 9 Constructorilor St, Vatra (Chișinău) - about 1 million m3/yr limestone products for sugar, metallurgy, glass and building, rail and truck. Metallurgical grade 97.47 pct CaCO3 (SiO2 0.34), glass grade 98.92 pct CaCO3 plus MgCO3 (Fe2O3 0.042).', 'MD check 2026-10-16: paper and pulp named only generally - no fine GCC. prodaji@calcar.md, +373 247 45 110. Raw-material partner.'),
  ('liormax', 'LIORMAX - Cricova', 'Chișinău', 'Cricova', null, '2000년 시작 석회석 필러 분말(Cricova) — 월 5,000 t 이상, 2025 설비 현대화, 도로·아스팔트·건식 혼합재.', 'LIORMAX, 41 Vasile Alecsandri St, Cricova (office 7/3 Onisifor Ghibu St, Chișinău) - limestone filler powder since 2000, over 5,000 t/month, equipment modernised 2025, for roads, asphalt and dry mixes.', 'MD check 2026-10-16: not paper fineness - check D50 1-3 micron and wet capability. liormax@yahoo.com, +373 69 126 831. Not added: MINERAL S.A., FPC GORNIAC, CP MINA FĂURARI (Cricova quarries). No paper PCC or GCC in Moldova.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcar.*(briceni|beleavin)|^calcar( s.a.?)?$', 'CALCAR - Beleavinți (Briceni)', 'Briceni', 'Beleavinți', null, '1992년 설립 석회석 채굴·파쇄·분급(Briceni Beleavinți) — 연 약 100만 m³, 공장 2곳, 제당·야금·유리·건설 공급. 야금용 CaCO3 97.47%, 유리용 CaCO3+MgCO3 98.92%(Fe2O3 0.042%).', 'CALCAR S.A. (1992), quarry and two crushing and screening plants at Beleavinți (Briceni), logistics base 9 Constructorilor St, Vatra (Chișinău) - about 1 million m3/yr limestone products for sugar, metallurgy, glass and building, rail and truck. Metallurgical grade 97.47 pct CaCO3 (SiO2 0.34), glass grade 98.92 pct CaCO3 plus MgCO3 (Fe2O3 0.042).', 'MD check 2026-10-16: paper and pulp named only generally - no fine GCC. prodaji@calcar.md, +373 247 45 110. Raw-material partner.'),
  ('liormax', 'LIORMAX - Cricova', 'Chișinău', 'Cricova', null, '2000년 시작 석회석 필러 분말(Cricova) — 월 5,000 t 이상, 2025 설비 현대화, 도로·아스팔트·건식 혼합재.', 'LIORMAX, 41 Vasile Alecsandri St, Cricova (office 7/3 Onisifor Ghibu St, Chișinău) - limestone filler powder since 2000, over 5,000 t/month, equipment modernised 2025, for roads, asphalt and dry mixes.', 'MD check 2026-10-16: not paper fineness - check D50 1-3 micron and wet capability. liormax@yahoo.com, +373 69 126 831. Not added: MINERAL S.A., FPC GORNIAC, CP MINA FĂURARI (Cricova quarries). No paper PCC or GCC in Moldova.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'moldova_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CALCAR - Beleavinți (Briceni)', 'Carbonate raw material', 'Large limestone producer - raw material', 'merchant', 'C', 'gcc'),
  ('LIORMAX - Cricova', 'GCC producer', 'Limestone filler grinder - processing partner', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'moldova_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MD', v.region, v.city, v.website, 'active', 'moldova_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('candelux', 'chi[sș]in[aă]u|uzinelor', 'candelux', 'CANDELUX-COM - Chișinău', 'Chișinău', 'Chișinău', null, '2010년 등록 폐지 재생 화장지·화장지용 원지 제조사(Uzinelor 19) — 폐지 해리·탈수·압착·건조 공정 공개, 몰도바 폐지 70% 이상 재활용(회사 발표).', 'CANDELUX-COM S.R.L. (2010), Str. Uzinelor 19, Chișinău - recycled toilet tissue and semi-finished tissue base paper on recovered paper: collection, repulping, dewatering, pressing and drying shown on its site, claims to recycle over 70 pct of collected Moldovan waste paper, 10-49 staff.', 'MD check 2026-10-16: machine count, speed and output not public. info@candelux.md, sales +373 78 305 011.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('candelux', 'chi[sș]in[aă]u|uzinelor', 'candelux', '2010년 등록 폐지 재생 화장지·화장지용 원지 제조사(Uzinelor 19) — 폐지 해리·탈수·압착·건조 공정 공개, 몰도바 폐지 70% 이상 재활용(회사 발표).', 'CANDELUX-COM S.R.L. (2010), Str. Uzinelor 19, Chișinău - recycled toilet tissue and semi-finished tissue base paper on recovered paper: collection, repulping, dewatering, pressing and drying shown on its site, claims to recycle over 70 pct of collected Moldovan waste paper, 10-49 staff.', 'MD check 2026-10-16: machine count, speed and output not public. info@candelux.md, sales +373 78 305 011.'),
  ('mitra-?grup|milta', null, 'mitra-?grup|milta', null, null, 'MD check 2026-10-16: Toilet tissue, towels, napkins (virgin and recycled), Chișinău - own machine not confirmed - context only.'),
  ('articole din carton', null, 'articole din carton', null, null, 'MD check 2026-10-16: 3- and 5-ply corrugated, boxes, waste-paper collection, Chișinău - liner making not confirmed - context only.'),
  ('cartnord', null, 'cartnord', null, null, 'MD check 2026-10-16: Paper sacks 45 m/yr, corrugated 15 m m2, bags, about 8,000 t/yr paper and board trading - context only.'),
  ('moldpack', null, 'moldpack', null, null, 'MD check 2026-10-16: Paper boxes and bags, Chișinău - converter - context only.'),
  ('pergament', null, 'pergament', null, null, 'MD check 2026-10-16: Printed board packaging, Chișinău (expanded 2026-04) - converter - context only.'),
  ('moldcarton', null, 'moldcarton', null, null, 'MD check 2026-10-16: Former pulp, paper and board maker, Sîngera - insolvency 2024, liquidation 2026-09 - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'moldova_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('candelux', 'chi[sș]in[aă]u|uzinelor', 'candelux'),
  ('mitra-?grup|milta', null, 'mitra-?grup|milta'),
  ('articole din carton', null, 'articole din carton'),
  ('cartnord', null, 'cartnord'),
  ('moldpack', null, 'moldpack'),
  ('pergament', null, 'pergament'),
  ('moldcarton', null, 'moldcarton')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('candelux', 'chi[sș]in[aă]u|uzinelor', 'candelux',
   $pj${"owner": "CANDELUX-COM", "priority": 1, "products": "Recycled toilet tissue, tissue base paper", "grades": ["Tissue"], "approach": "Only confirmed paper machine in Moldova - FCC 1-5 pct pilot after machine check.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mitra-?grup|milta', null, 'mitra-?grup|milta',
   $pj${"owner": "MITRA-GRUP (Milta)", "products": "Toilet tissue, towels, napkins (virgin and recycled), Chișinău - own machine not confirmed", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('articole din carton', null, 'articole din carton',
   $pj${"owner": "Combinatul de Articole din Carton", "products": "3- and 5-ply corrugated, boxes, waste-paper collection, Chișinău - liner making not confirmed", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartnord', null, 'cartnord',
   $pj${"owner": "CARTNORD", "products": "Paper sacks 45 m/yr, corrugated 15 m m2, bags, about 8,000 t/yr paper and board trading", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('moldpack', null, 'moldpack',
   $pj${"owner": "MoldPack", "products": "Paper boxes and bags, Chișinău - converter", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pergament', null, 'pergament',
   $pj${"owner": "Pergament", "products": "Printed board packaging, Chișinău (expanded 2026-04) - converter", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('moldcarton', null, 'moldcarton',
   $pj${"owner": "MOLDCARTON (in liquidation)", "products": "Former pulp, paper and board maker, Sîngera - insolvency 2024, liquidation 2026-09", "approach": "Converter, trader or closed.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MD', 'Moldova', 'low',
   $cm$One small recycled tissue mill (CANDELUX-COM) - converters and paper traders, limestone and filler powder only$cm$,
   $cm$Moldova's only confirmed paper making is CANDELUX-COM (Chișinău, recycled tissue base paper). Milta (MITRA-GRUP) sells tissue, Combinatul de Articole din Carton, CARTNORD, MoldPack and Pergament convert board, MOLDCARTON is in liquidation. Carbonate: CALCAR (large limestone quarry, 97-99 pct) and LIORMAX (limestone filler, 5 kt/month). No paper PCC or GCC.$cm$,
   $cm${"fillers": "Limestone: CALCAR Briceni. Filler powder: LIORMAX Cricova. Not added: MINERAL, GORNIAC, MINA FĂURARI.", "mills": "Recycled tissue: CANDELUX-COM. Context: MITRA-GRUP (Milta), Combinatul de Articole din Carton, CARTNORD, MoldPack, Pergament, MOLDCARTON (liquidation).", "strategy": "Small recycled-tissue pilot at CANDELUX-COM. Romania mills as the real market.", "risks": "Tiny volumes.", "next_steps": ["Ask CANDELUX-COM for machine specs and output"], "key_numbers": [{"label": "LIORMAX", "value": "over 5,000 t/month filler"}], "files": ["seed_20261016zn_moldova_mills_fillers"]}$cm$::jsonb,
   $cm$소형 재생 티슈 공장 1곳(CANDELUX-COM) — 가공·유통업체, 석회석·필러 분말만 존재$cm$,
   $cm$몰도바에서 원지 생산이 확인된 곳은 CANDELUX-COM(키시너우, 재생 티슈 원지) 뿐. Milta 는 티슈 판매, Combinatul de Articole din Carton·CARTNORD·MoldPack·Pergament 는 판지 가공, MOLDCARTON 은 청산 중. 탄산칼슘: CALCAR(대형 석회석, 97~99%), LIORMAX(석회석 필러 월 5천 t). 제지용 PCC·GCC 없음.$cm$,
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
      ('candelux', 'chi[sș]in[aă]u|uzinelor', 'candelux'),
  ('mitra-?grup|milta', null, 'mitra-?grup|milta'),
  ('articole din carton', null, 'articole din carton'),
  ('cartnord', null, 'cartnord'),
  ('moldpack', null, 'moldpack'),
  ('pergament', null, 'pergament'),
  ('moldcarton', null, 'moldcarton')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'moldova_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'moldova_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcar.*(briceni|beleavin)|^calcar( s.a.?)?$' or p.party_name ~* 'liormax')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MD'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MD'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MD'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    