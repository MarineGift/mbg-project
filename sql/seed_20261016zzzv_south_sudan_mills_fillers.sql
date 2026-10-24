-- ============================================================
-- seed_20261016zzzv_south_sudan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- South Sudan (SS) update (reports 2026-10-17). Memos carry a sanctions note.
-- 1) Filler if missing (1): Upper Nile Cement (unverified).
-- 2) Mills if missing (2, no priority, machine to verify): Gentle Hubs,
--    PAL Investment. Context (2): importers.
-- 3) app.country_markets SS row (priority none).
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
           v.party_name, 'SS', v.region, v.city, v.website, 'active', 'south_sudan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('upper nile cement', 'Upper Nile Cement Industries - Kapoeta', 'Eastern Equatoria', 'Kapoeta', null, 'Upper Nile Cement(웹사이트상 Kapoeta) 석회석 조달·시멘트 분쇄·포장, 연 48만 t 주장 — 독립 검증 없음.', 'Upper Nile Cement Industries Ltd, Kapoeta (Eastern Equatoria) per its website - limestone sourcing, cement grinding and bagging, 480,000 t/yr claimed, not independently verified.', 'SS check 2026-10-16: existence and operation to verify. Ministry of Mining lists limestone, marble, dolomite, kaolin potential. GCC-11 and PCC-12 (China), Ugandan and coated CaCO3 imports on record (2024). No South Sudanese paper PCC or GCC. Screen against UN and US South Sudan sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SS check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('upper nile cement', 'Upper Nile Cement Industries - Kapoeta', 'Eastern Equatoria', 'Kapoeta', null, 'Upper Nile Cement(웹사이트상 Kapoeta) 석회석 조달·시멘트 분쇄·포장, 연 48만 t 주장 — 독립 검증 없음.', 'Upper Nile Cement Industries Ltd, Kapoeta (Eastern Equatoria) per its website - limestone sourcing, cement grinding and bagging, 480,000 t/yr claimed, not independently verified.', 'SS check 2026-10-16: existence and operation to verify. Ministry of Mining lists limestone, marble, dolomite, kaolin potential. GCC-11 and PCC-12 (China), Ugandan and coated CaCO3 imports on record (2024). No South Sudanese paper PCC or GCC. Screen against UN and US South Sudan sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'south_sudan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Upper Nile Cement Industries - Kapoeta', 'Limestone owner (cement, unverified)', 'Cement claim - verify first', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'south_sudan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'SS', v.region, v.city, v.website, 'active', 'south_sudan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('gentle hubs', 'juba|gumbo', 'gentle hubs', 'Gentle Hubs - Juba', 'Central Equatoria', 'Juba', null, 'Gentle Hubs(Gumbo North, Juba) 100% 버진펄프 화장지·냅킨 — 웹사이트에 펄프 준비·시트 형성·엠보싱 공정 소개.', 'Gentle Hubs Co. Ltd, Gumbo North, Juba - toilet paper and serviettes of 100 pct virgin wood pulp, website describes pulp preparation, sheet formation and embossing.', 'SS check 2026-10-16: paper machine, photos and t/day to verify. info@gentlehubs.com, +211 911 310 058. Screen against UN and US South Sudan sanctions lists.'),
  ('pal investment', 'juba|nyarjua', 'pal investment', 'PAL Investment - Juba', 'Central Equatoria', 'Juba', null, 'PAL Investment(2022, Plot 233 Block 1 Nyarjua Na Mere, Juba) 화장지·점보롤·키친타월·페이셜·종이컵·인쇄용지, 재활용 소재 언급.', 'PAL Investment Ltd (2022), Plot 233 Block 1, Nyarjua Na Mere, Juba - toilet, jumbo and kitchen rolls, facial tissue, paper cups and printing paper, mentions recycled input.', 'SS check 2026-10-16: own machine vs converting unknown, website figures unverified. info@palinvestmentltd.com, +211 924 778 500. Screen against UN and US South Sudan sanctions lists.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SS check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gentle hubs', 'juba|gumbo', 'gentle hubs', 'Gentle Hubs(Gumbo North, Juba) 100% 버진펄프 화장지·냅킨 — 웹사이트에 펄프 준비·시트 형성·엠보싱 공정 소개.', 'Gentle Hubs Co. Ltd, Gumbo North, Juba - toilet paper and serviettes of 100 pct virgin wood pulp, website describes pulp preparation, sheet formation and embossing.', 'SS check 2026-10-16: paper machine, photos and t/day to verify. info@gentlehubs.com, +211 911 310 058. Screen against UN and US South Sudan sanctions lists.'),
  ('pal investment', 'juba|nyarjua', 'pal investment', 'PAL Investment(2022, Plot 233 Block 1 Nyarjua Na Mere, Juba) 화장지·점보롤·키친타월·페이셜·종이컵·인쇄용지, 재활용 소재 언급.', 'PAL Investment Ltd (2022), Plot 233 Block 1, Nyarjua Na Mere, Juba - toilet, jumbo and kitchen rolls, facial tissue, paper cups and printing paper, mentions recycled input.', 'SS check 2026-10-16: own machine vs converting unknown, website figures unverified. info@palinvestmentltd.com, +211 924 778 500. Screen against UN and US South Sudan sanctions lists.'),
  ('carnak', null, 'carnak', null, null, 'SS check 2026-10-16: Carnak South Sudan - corrugated box imports - context only. Screen against UN and US South Sudan sanctions lists.'),
  ('ezgiamin', null, 'ezgiamin', null, null, 'SS check 2026-10-16: Ezgiamin General Trading, Juba - packaging imports - context only. Screen against UN and US South Sudan sanctions lists.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'south_sudan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gentle hubs', 'juba|gumbo', 'gentle hubs'),
  ('pal investment', 'juba|nyarjua', 'pal investment'),
  ('carnak', null, 'carnak'),
  ('ezgiamin', null, 'ezgiamin')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gentle hubs', 'juba|gumbo', 'gentle hubs', false,
   $pj${"owner": "Gentle Hubs", "products": "Tissue (virgin pulp)", "grades": ["Tissue"], "approach": "Verify machine, then stepwise tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pal investment', 'juba|nyarjua', 'pal investment', false,
   $pj${"owner": "PAL Investment", "products": "Tissue, jumbo rolls (to confirm)", "grades": ["Tissue"], "approach": "Verify machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('carnak', null, 'carnak', true,
   $pj${"owner": "Carnak", "products": "Carnak South Sudan - corrugated box imports", "approach": "Importer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ezgiamin', null, 'ezgiamin', true,
   $pj${"owner": "Ezgiamin", "products": "Ezgiamin General Trading, Juba - packaging imports", "approach": "Importer.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SS', 'South Sudan', 'none',
   $cm$Two Juba tissue makers claiming machines (Gentle Hubs, PAL Investment) - no paper PCC or GCC - supplied via Kenya and Uganda$cm$,
   $cm$South Sudan's paper sector is tiny: Gentle Hubs (Juba, virgin-pulp tissue, website shows pulp preparation and sheet forming) and PAL Investment (Juba, tissue and jumbo rolls) claim local manufacturing - machines unverified. Paper products come mainly of Kenya and Uganda (HS 48 top five about USD 11.8 m, 2024). No paper PCC or GCC - Upper Nile Cement (Kapoeta, 480 kt claim) is unverified, and GCC / PCC grades are imported in small lots of China.$cm$,
   $cm${"fillers": "Cement claim: Upper Nile Cement (unverified). No PCC or GCC.", "mills": "To verify: Gentle Hubs, PAL Investment. Context: importers (Carnak, Ezgiamin).", "strategy": "Verify Gentle Hubs' machine. Otherwise serve via Ugandan and Kenyan mills.", "risks": "Security, sanctions screening, infrastructure.", "next_steps": ["Ask Gentle Hubs for machine details"], "key_numbers": [{"label": "HS 48 top-5 suppliers 2024", "value": "about USD 11.8 m"}], "files": ["seed_20261016zzzv_south_sudan_mills_fillers"]}$cm$::jsonb,
   $cm$초지기 주장 Juba 티슈 업체 2곳(Gentle Hubs, PAL Investment) — 제지용 PCC·GCC 없음 — 케냐·우간다 공급$cm$,
   $cm$남수단 제지업은 매우 작음: Gentle Hubs(Juba, 버진펄프 티슈, 웹에 펄프 준비·시트 형성 공정)·PAL Investment(Juba, 티슈·점보롤)가 현지 제조 주장 — 초지기 미검증. 종이제품은 주로 케냐·우간다산(HS 48 상위 5개국 약 1,184만 달러, 2024). 제지용 PCC·GCC 없음 — Upper Nile Cement(Kapoeta, 48만 t 주장) 미검증, GCC·PCC 는 중국산 소량 수입.$cm$,
   null, null,
   $cm$초지기 미검증 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('gentle hubs', 'juba|gumbo', 'gentle hubs'),
  ('pal investment', 'juba|nyarjua', 'pal investment'),
  ('carnak', null, 'carnak'),
  ('ezgiamin', null, 'ezgiamin')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'south_sudan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'south_sudan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'upper nile cement')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SS'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SS'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SS'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    