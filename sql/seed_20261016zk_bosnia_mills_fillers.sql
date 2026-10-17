-- ============================================================
-- seed_20261016zk_bosnia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bosnia and Herzegovina update (reports 2026-10-16).
-- 1) Fillers if missing (2): Carmeuse Doboj (lime), TERAKOP (limestone).
-- 2) Mills if missing (3) + plant blocks: SHP Celex Banja Luka (1),
--    Natron-Hayat Maglaj (2), Violeta Grude (no priority).
-- 3) app.country_markets BA row (priority medium).
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
           v.party_name, 'BA', v.region, v.city, v.website, 'active', 'bosnia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('carmeuse.*(doboj|bosn)', 'Carmeuse - Doboj', 'Republika Srpska', 'Doboj', null, 'Carmeuse 그룹(2008 진입) Doboj Ševarlije 석회석 광산 + 석회 공장.', 'Carmeuse Bosnia (Carmeuse group since 2008) - Rudnik krečnjaka Carmeuse d.o.o. limestone quarry (Ševarlije 322) and Fabrika kreča Carmeuse d.o.o. lime plant (Ševarlije 56), Doboj.', 'BA check 2026-10-16: lime and limestone only - no fine GCC or carbonation line confirmed. info@carmeuse.ba, +387 53 490 700. Lime base for a future PCC or FCC line.'),
  ('terakop', 'TERAKOP - Živinice', 'Tuzla', 'Živinice', null, 'Živinice(Tuzla) 석회석 채굴·파쇄(CaCO3 96% 이상) — 건설·석회·비료·소다 공급.', 'TERAKOP d.o.o., Gračanica bb, Živinice (Tuzla Canton) - limestone quarrying and crushing, over 96 pct CaCO3, 0-8 mm and 50-150 mm products for construction, lime making, fertiliser and soda.', 'BA check 2026-10-16: no micronised grade. info@terakop.ba, +387 35 764 000. Not added: Lukavac Cement (cement limestone), Šahin Kamen quarry. No paper PCC or GCC in Bosnia - regional: Omya Venčac (Aranđelovac, Serbia), STARAC (Croatia).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('carmeuse.*(doboj|bosn)', 'Carmeuse - Doboj', 'Republika Srpska', 'Doboj', null, 'Carmeuse 그룹(2008 진입) Doboj Ševarlije 석회석 광산 + 석회 공장.', 'Carmeuse Bosnia (Carmeuse group since 2008) - Rudnik krečnjaka Carmeuse d.o.o. limestone quarry (Ševarlije 322) and Fabrika kreča Carmeuse d.o.o. lime plant (Ševarlije 56), Doboj.', 'BA check 2026-10-16: lime and limestone only - no fine GCC or carbonation line confirmed. info@carmeuse.ba, +387 53 490 700. Lime base for a future PCC or FCC line.'),
  ('terakop', 'TERAKOP - Živinice', 'Tuzla', 'Živinice', null, 'Živinice(Tuzla) 석회석 채굴·파쇄(CaCO3 96% 이상) — 건설·석회·비료·소다 공급.', 'TERAKOP d.o.o., Gračanica bb, Živinice (Tuzla Canton) - limestone quarrying and crushing, over 96 pct CaCO3, 0-8 mm and 50-150 mm products for construction, lime making, fertiliser and soda.', 'BA check 2026-10-16: no micronised grade. info@terakop.ba, +387 35 764 000. Not added: Lukavac Cement (cement limestone), Šahin Kamen quarry. No paper PCC or GCC in Bosnia - regional: Omya Venčac (Aranđelovac, Serbia), STARAC (Croatia).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'bosnia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Carmeuse - Doboj', 'Lime producer', 'Limestone and lime - future PCC base', 'merchant', 'C', 'pcc'),
  ('TERAKOP - Živinice', 'Carbonate raw material', 'High-calcium limestone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bosnia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BA', v.region, v.city, v.website, 'active', 'bosnia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('celex|\mshp\M.*banja', 'banja luka', 'celex|shp', 'SHP Celex - Banja Luka', 'Republika Srpska', 'Banja Luka', null, '1966년 시작 티슈 제지공장, 슬로바키아 SHP Group 소속(Incel 산업단지). 초지기 연 약 4만 t, 화장지·키친타월(Harmony), 약 300명. 2026 신규 초지기 일 195 t 환경허가(6월), 초기 1,500만 유로 투자 발표(10월).', 'SHP Celex a.d. (paper since 1966, SHP Group / ECO-Investment), Veljka Mlađenovića bb, Incel industrial zone, Banja Luka - tissue machine about 40,000 t/yr, toilet tissue and kitchen towel (Harmony), about 300 staff, TL15 converting line 2022. New tissue machine of 195 t/day: environmental permit applied 2026-04, granted 2026-06, first EUR 15 m modernisation announced 2026-10 (up to about EUR 100 m discussed).', 'BA check 2026-10-16: new machine (about 68 kt/yr at 350 days) not built - kept as plan. +387 51 332 201.'),
  ('natron', 'maglaj', 'natron|hayat', 'Natron-Hayat - Maglaj', 'Zenica-Doboj', 'Maglaj', null, 'Hayat Holding(2005~) 일관 펄프·제지공장(Maglaj) — Sack Kraft(70~90 gsm)·MG Kraft(37~100)·Fluting(100~170)·Testliner, 펄프 약 10만 t, 750명+. PM1 2025-06 현대화 3만→5만 t(재생섬유 20~100%), 목표 7만 t.', 'Natron-Hayat d.o.o., Liješnica bb, Maglaj (Hayat Holding since 2005) - integrated pulp and paper: sack kraft 70-90 gsm (60-120 range), MG kraft 37-100 gsm (50/50 recycled and virgin), NH Fluting 100-170 gsm on 100 pct recycled, testliner, RCCM. Pulp about 100,000 t/yr (94 kt permitted). PM1 modernised 2025-06 to 50,000 t/yr (was 30,000) with 20-100 pct recycled fibre, 70,000 t target. Over 750 staff.', 'BA check 2026-10-16: total paper capacity of all machines not public - PM1 figure kept in split. info@natron-hayat.ba, +387 32 601 000. Same group as Hayat Kimya (TR, RU).'),
  ('violeta', 'grude', 'violeta', 'Violeta - Grude', 'West Herzegovina', 'Grude', null, '2001년 시작 위생용품 기업(Grude) — 화장지·키친타월·티슈·물티슈·기저귀, 크로아티아 Sv. Ivan Zelina 종이제품 공장.', 'Violeta d.o.o., Stjepana Radića 21, Grude (since 2001, founder Petar Ćorluka) - toilet tissue, kitchen towel, facial, wet wipes, diapers, also a paper-products plant at Sv. Ivan Zelina (Croatia).', 'BA check 2026-10-16: own tissue machine not confirmed - may convert bought jumbo rolls. +387 39 660 400.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('celex|\mshp\M.*banja', 'banja luka', 'celex|shp', '1966년 시작 티슈 제지공장, 슬로바키아 SHP Group 소속(Incel 산업단지). 초지기 연 약 4만 t, 화장지·키친타월(Harmony), 약 300명. 2026 신규 초지기 일 195 t 환경허가(6월), 초기 1,500만 유로 투자 발표(10월).', 'SHP Celex a.d. (paper since 1966, SHP Group / ECO-Investment), Veljka Mlađenovića bb, Incel industrial zone, Banja Luka - tissue machine about 40,000 t/yr, toilet tissue and kitchen towel (Harmony), about 300 staff, TL15 converting line 2022. New tissue machine of 195 t/day: environmental permit applied 2026-04, granted 2026-06, first EUR 15 m modernisation announced 2026-10 (up to about EUR 100 m discussed).', 'BA check 2026-10-16: new machine (about 68 kt/yr at 350 days) not built - kept as plan. +387 51 332 201.'),
  ('natron', 'maglaj', 'natron|hayat', 'Hayat Holding(2005~) 일관 펄프·제지공장(Maglaj) — Sack Kraft(70~90 gsm)·MG Kraft(37~100)·Fluting(100~170)·Testliner, 펄프 약 10만 t, 750명+. PM1 2025-06 현대화 3만→5만 t(재생섬유 20~100%), 목표 7만 t.', 'Natron-Hayat d.o.o., Liješnica bb, Maglaj (Hayat Holding since 2005) - integrated pulp and paper: sack kraft 70-90 gsm (60-120 range), MG kraft 37-100 gsm (50/50 recycled and virgin), NH Fluting 100-170 gsm on 100 pct recycled, testliner, RCCM. Pulp about 100,000 t/yr (94 kt permitted). PM1 modernised 2025-06 to 50,000 t/yr (was 30,000) with 20-100 pct recycled fibre, 70,000 t target. Over 750 staff.', 'BA check 2026-10-16: total paper capacity of all machines not public - PM1 figure kept in split. info@natron-hayat.ba, +387 32 601 000. Same group as Hayat Kimya (TR, RU).'),
  ('violeta', 'grude', 'violeta', '2001년 시작 위생용품 기업(Grude) — 화장지·키친타월·티슈·물티슈·기저귀, 크로아티아 Sv. Ivan Zelina 종이제품 공장.', 'Violeta d.o.o., Stjepana Radića 21, Grude (since 2001, founder Petar Ćorluka) - toilet tissue, kitchen towel, facial, wet wipes, diapers, also a paper-products plant at Sv. Ivan Zelina (Croatia).', 'BA check 2026-10-16: own tissue machine not confirmed - may convert bought jumbo rolls. +387 39 660 400.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'bosnia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('celex|\mshp\M.*banja', 'banja luka', 'celex|shp'),
  ('natron', 'maglaj', 'natron|hayat'),
  ('violeta', 'grude', 'violeta')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('celex|\mshp\M.*banja', 'banja luka', 'celex|shp',
   $pj${"owner": "SHP Group", "priority": 1, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "capacity": {"value": 40000, "unit": "metric_t", "year": "SHP Group figure", "source": "shp.eu"}, "capacity_split": [{"label": "Existing machine", "value_t": 40000}, {"label": "New machine plan (195 t/day)", "value_t": 68250}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "On the existing 40 kt only."}, "pitch": "Plan FCC dosing for the new 195 t/day machine", "approach": "Lead account - technical meeting on the new machine, pilot on the existing one.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "recent": "New machine permit 2026-06", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('natron', 'maglaj', 'natron|hayat',
   $pj${"owner": "Hayat Holding", "priority": 2, "products": "Sack kraft, MG kraft, fluting, testliner", "grades": ["Sack kraft", "MG paper", "Medium", "Testliner"], "capacity_split": [{"label": "PM1 after 2025 rebuild", "value_t": 50000}], "approach": "Recycled fluting and MG kraft first - strength-critical sack kraft later. Pitch with Hayat group tissue.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('violeta', 'grude', 'violeta',
   $pj${"owner": "Violeta", "products": "Toilet tissue, kitchen towel, hygiene", "grades": ["Tissue"], "approach": "Confirm base-paper making or its jumbo-roll supplier.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BA', 'Bosnia and Herzegovina', 'medium',
   $cm$SHP Celex tissue (40 kt, new 195 t/day machine permitted 2026) and Natron-Hayat kraft and recycled liner - lime and limestone only$cm$,
   $cm$Bosnia has two confirmed paper mill sites: SHP Celex (Banja Luka, about 40 kt tissue, new 195 t/day machine permitted 2026-06, EUR 15 m first step) and Natron-Hayat (Maglaj, integrated pulp and paper - sack kraft, MG kraft, recycled fluting and testliner, PM1 50 kt after 2025 rebuild). Violeta (Grude) makes hygiene products, machine unconfirmed. No paper PCC or GCC: Carmeuse Doboj (lime, limestone) and TERAKOP (96 pct limestone) are raw-material sources, regional GCC is Omya Venčac (Serbia) and STARAC (Croatia).$cm$,
   $cm${"fillers": "Lime: Carmeuse Doboj. Limestone: TERAKOP Živinice. Not added: Lukavac Cement, Šahin Kamen. Regional: Omya Venčac (RS), STARAC (HR).", "mills": "Tissue: SHP Celex Banja Luka. Kraft and recycled liner: Natron-Hayat Maglaj. Hygiene: Violeta Grude (machine unconfirmed). 159 paper and paper-product firms (2024) incl. converters.", "strategy": "SHP Celex first - put FCC in the new machine design, pilot on the existing one. Natron-Hayat recycled grades next, linked to Hayat group. Supply by Omya Venčac or STARAC.", "risks": "New SHP machine timing, packaging strength limits.", "next_steps": ["Request a technical meeting with SHP Celex on the new machine"], "key_numbers": [{"label": "SHP Celex", "value": "about 40 kt/yr, new 195 t/day planned"}, {"label": "Natron-Hayat PM1", "value": "50 kt/yr (2025 rebuild)"}], "files": ["seed_20261016zk_bosnia_mills_fillers"]}$cm$::jsonb,
   $cm$SHP Celex 티슈(4만 t, 2026 신규 일 195 t 초지기 허가) + Natron-Hayat 크라프트·재생 라이너 — 석회·석회석만 존재$cm$,
   $cm$보스니아 초지기 확인 2곳: SHP Celex(Banja Luka, 티슈 약 4만 t, 신규 일 195 t 초지기 2026-06 허가, 1단계 1,500만 유로)와 Natron-Hayat(Maglaj, 일관 펄프·제지 — sack kraft·MG·재생 플루팅·라이너, PM1 2025 현대화 후 5만 t). Violeta(Grude)는 초지기 미확인. 제지용 PCC·GCC 없음: Carmeuse Doboj·TERAKOP 원료, 인근 Omya Venčac(세르비아)·STARAC(크로아티아).$cm$,
   1200, 2000,
   $cm$SHP Celex 4만 t × FCC 3~5% (신규 초지기·Natron 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('celex|\mshp\M.*banja', 'banja luka', 'celex|shp'),
  ('natron', 'maglaj', 'natron|hayat'),
  ('violeta', 'grude', 'violeta')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'bosnia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'bosnia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'carmeuse.*(doboj|bosn)' or p.party_name ~* 'terakop')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    