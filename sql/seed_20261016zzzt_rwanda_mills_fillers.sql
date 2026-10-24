-- ============================================================
-- seed_20261016zzzt_rwanda_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Rwanda update (reports 2026-10-17).
-- 1) Fillers if missing (2): ALICOMEC, CIMERWA.
-- 2) Mills if missing (2) + plant blocks: Kigali Mingyang Paper (1),
--    Roba Industries (2). Context (9): converters.
-- 3) app.country_markets RW row (priority low).
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
           v.party_name, 'RW', v.region, v.city, v.website, 'active', 'rwanda_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('alicomec', 'ALICOMEC - Western Province', 'Western', 'Rusizi', null, 'ALICOMEC(서부주) 파쇄 석회석·석회석 분말·미분 석회석 분말·생석회·소석회 — 농업·산업·건설·수처리.', 'ALICOMEC Ltd, Western Province - crushed limestone, limestone powder, fine limestone powder, quicklime and hydrated lime for farming, industry, building and water treatment.', 'RW check 2026-10-16: plant address, PSD and brightness unknown - request samples. alicomec.info@gmail.com, +250 788 307 506. Candidate 1 for a local GCC trial.'),
  ('cimerwa', 'CIMERWA - Bugarama', 'Western', 'Bugarama', null, 'CIMERWA(Rusizi Bugarama) 석회석 채굴·시멘트 연 약 60만 t — Mashyuza 석회질(트래버틴)·규암 채석. Prime Cement 제품도 CIMERWA 자산에서 생산 표기.', 'CIMERWA Plc, Bugarama (Rusizi) - integrated cement, about 600,000 t/yr, calcareous (travertine) and quartzite quarries at Mashyuza. Prime Cement products are now listed as made on CIMERWA assets. HQ CIMERWA House, Kimihurura, Kigali.', 'RW check 2026-10-16: travertine purity and colour vary - analyse per bench. sales@cimerwa.rw, +250 788 190 400. Not added: Kigali Cement Company, Anjia Cement. No Rwandan paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%RW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('alicomec', 'ALICOMEC - Western Province', 'Western', 'Rusizi', null, 'ALICOMEC(서부주) 파쇄 석회석·석회석 분말·미분 석회석 분말·생석회·소석회 — 농업·산업·건설·수처리.', 'ALICOMEC Ltd, Western Province - crushed limestone, limestone powder, fine limestone powder, quicklime and hydrated lime for farming, industry, building and water treatment.', 'RW check 2026-10-16: plant address, PSD and brightness unknown - request samples. alicomec.info@gmail.com, +250 788 307 506. Candidate 1 for a local GCC trial.'),
  ('cimerwa', 'CIMERWA - Bugarama', 'Western', 'Bugarama', null, 'CIMERWA(Rusizi Bugarama) 석회석 채굴·시멘트 연 약 60만 t — Mashyuza 석회질(트래버틴)·규암 채석. Prime Cement 제품도 CIMERWA 자산에서 생산 표기.', 'CIMERWA Plc, Bugarama (Rusizi) - integrated cement, about 600,000 t/yr, calcareous (travertine) and quartzite quarries at Mashyuza. Prime Cement products are now listed as made on CIMERWA assets. HQ CIMERWA House, Kimihurura, Kigali.', 'RW check 2026-10-16: travertine purity and colour vary - analyse per bench. sales@cimerwa.rw, +250 788 190 400. Not added: Kigali Cement Company, Anjia Cement. No Rwandan paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'rwanda_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('ALICOMEC - Western Province', 'Limestone grinder and lime', 'Limestone powder and lime - candidate 1', 'merchant', 'C', 'gcc'),
  ('CIMERWA - Bugarama', 'Limestone owner (cement)', 'Travertine and limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'rwanda_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'RW', v.region, v.city, v.website, 'active', 'rwanda_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('mingyang', 'kigali|kayovu', 'mingyang', 'Kigali Mingyang Paper - Kigali', 'Kigali', 'Kigali', null, 'Kigali Mingyang Paper — 120 gsm 골심지 우간다 수출(롤 폭 850~1,500 mm, 2024~25), 초지기 펠트·성형망 수입 기록.', 'Kigali Mingyang Paper Co. Ltd, Kigali area (Colline Kayovu) - exports 120 gsm fluting to Uganda in 850-1,500 mm reels (2024-25 customs records) and imports paper-machine felts and forming fabrics.', 'RW check 2026-10-16: capacity and furnish not public. +250 787 640 312.'),
  ('roba industries|roba group', 'bugesera|ntarama', 'roba', 'Roba Industries - Bugesera', 'Eastern', 'Ntarama', null, 'Roba Industries(Ntarama, Kanzenze, Bugesera) 폐지 재활용 공장 — 화장지, 2026-03-11 2026~27 생산용 2등급 폐지 조달 공고.', 'Roba Industries Ltd, Ntarama, Kanzenze, Bugesera (Kigali-Nyamata road) - waste-paper recycling plant making toilet tissue of recovered paper, tender for 2nd-grade waste paper for 2026-27 production issued 2026-03-11.', 'RW check 2026-10-16: machine specs and t/day not public. admin@robageneral.rw, +250 788 383 007.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%RW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mingyang', 'kigali|kayovu', 'mingyang', 'Kigali Mingyang Paper — 120 gsm 골심지 우간다 수출(롤 폭 850~1,500 mm, 2024~25), 초지기 펠트·성형망 수입 기록.', 'Kigali Mingyang Paper Co. Ltd, Kigali area (Colline Kayovu) - exports 120 gsm fluting to Uganda in 850-1,500 mm reels (2024-25 customs records) and imports paper-machine felts and forming fabrics.', 'RW check 2026-10-16: capacity and furnish not public. +250 787 640 312.'),
  ('roba industries|roba group', 'bugesera|ntarama', 'roba', 'Roba Industries(Ntarama, Kanzenze, Bugesera) 폐지 재활용 공장 — 화장지, 2026-03-11 2026~27 생산용 2등급 폐지 조달 공고.', 'Roba Industries Ltd, Ntarama, Kanzenze, Bugesera (Kigali-Nyamata road) - waste-paper recycling plant making toilet tissue of recovered paper, tender for 2nd-grade waste paper for 2026-27 production issued 2026-03-11.', 'RW check 2026-10-16: machine specs and t/day not public. admin@robageneral.rw, +250 788 383 007.'),
  ('safari center|\msupa\M', null, 'safari center|\msupa\M', null, null, 'RW check 2026-10-16: SUPA (Safari Center, 1998), Kicukiro - tissue, napkins, towels, RSB-certified to 2030 - context only.'),
  ('salama industries', null, 'salama industries', null, null, 'RW check 2026-10-16: Salama Industries, Masoro - virgin, blended, recycled tissue converting (30+ staff) - context only.'),
  ('star overseas', null, 'star overseas', null, null, 'RW check 2026-10-16: Star Overseas, Prime Economic Zone Masoro - virgin jumbo-roll converting - context only.'),
  ('alvyo|\msafi\M.*toilet', null, 'alvyo|\msafi\M.*toilet', null, null, 'RW check 2026-10-16: ALVYO Rwanda (SAFI recycled toilet paper, napkins) - status to confirm - context only.'),
  ('basil industries', null, 'basil industries', null, null, 'RW check 2026-10-16: Basil Industries - virgin and recycled tissue, corrugated boxes - context only.'),
  ('v.?plus packaging', null, 'v.?plus packaging', null, null, 'RW check 2026-10-16: V-Plus Packaging (2014), Kigali - corrugated, egg trays, food boxes - context only.'),
  ('jabbar', null, 'jabbar', null, null, 'RW check 2026-10-16: Quality Box Factory, Kigali SEZ Phase I - 3 and 5-ply boxes - context only.'),
  ('bonus industries|bonus group', null, 'bonus industries|bonus group', null, null, 'RW check 2026-10-16: Bonus Industries, Kigali - A4 80 gsm copy paper, kraft bags - own machine to confirm - context only.'),
  ('nyungwe paper', null, 'nyungwe paper', null, null, 'RW check 2026-10-16: Office printing paper - machine to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'rwanda_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mingyang', 'kigali|kayovu', 'mingyang'),
  ('roba industries|roba group', 'bugesera|ntarama', 'roba'),
  ('safari center|\msupa\M', null, 'safari center|\msupa\M'),
  ('salama industries', null, 'salama industries'),
  ('star overseas', null, 'star overseas'),
  ('alvyo|\msafi\M.*toilet', null, 'alvyo|\msafi\M.*toilet'),
  ('basil industries', null, 'basil industries'),
  ('v.?plus packaging', null, 'v.?plus packaging'),
  ('jabbar', null, 'jabbar'),
  ('bonus industries|bonus group', null, 'bonus industries|bonus group'),
  ('nyungwe paper', null, 'nyungwe paper')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mingyang', 'kigali|kayovu', 'mingyang', false,
   $pj${"owner": "Mingyang", "priority": 1, "products": "Fluting 120 gsm", "grades": ["Medium"], "approach": "Strength-hold trial (SCT, RCT, CMT).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('roba industries|roba group', 'bugesera|ntarama', 'roba', false,
   $pj${"owner": "Roba Group", "priority": 2, "products": "Recycled toilet tissue", "grades": ["Tissue"], "approach": "Recycled tissue trial - ALICOMEC or imported GCC.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('safari center|\msupa\M', null, 'safari center|\msupa\M', true,
   $pj${"owner": "Safari Center", "products": "SUPA (Safari Center, 1998), Kicukiro - tissue, napkins, towels, RSB-certified to 2030", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('salama industries', null, 'salama industries', true,
   $pj${"owner": "Salama", "products": "Salama Industries, Masoro - virgin, blended, recycled tissue converting (30+ staff)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('star overseas', null, 'star overseas', true,
   $pj${"owner": "Star Overseas", "products": "Star Overseas, Prime Economic Zone Masoro - virgin jumbo-roll converting", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('alvyo|\msafi\M.*toilet', null, 'alvyo|\msafi\M.*toilet', true,
   $pj${"owner": "ALVYO", "products": "ALVYO Rwanda (SAFI recycled toilet paper, napkins) - status to confirm", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('basil industries', null, 'basil industries', true,
   $pj${"owner": "Basil", "products": "Basil Industries - virgin and recycled tissue, corrugated boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('v.?plus packaging', null, 'v.?plus packaging', true,
   $pj${"owner": "V-Plus", "products": "V-Plus Packaging (2014), Kigali - corrugated, egg trays, food boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jabbar', null, 'jabbar', true,
   $pj${"owner": "Jabbar Developments", "products": "Quality Box Factory, Kigali SEZ Phase I - 3 and 5-ply boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bonus industries|bonus group', null, 'bonus industries|bonus group', true,
   $pj${"owner": "Bonus Industries", "products": "Bonus Industries, Kigali - A4 80 gsm copy paper, kraft bags - own machine to confirm", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nyungwe paper', null, 'nyungwe paper', true,
   $pj${"owner": "Nyungwe Paper", "products": "Office printing paper - machine to confirm", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'RW', 'Rwanda', 'low',
   $cm$Kigali Mingyang fluting (exports to Uganda) and Roba recycled tissue (Bugesera) - tissue and box converters - ALICOMEC limestone powder, CIMERWA$cm$,
   $cm$Rwanda has two likely paper machines: Kigali Mingyang Paper (120 gsm fluting exported to Uganda, imports machine felts and forming fabrics) and Roba Industries Bugesera (waste-paper recycling to toilet tissue, 2026-27 waste-paper tender). Converters: SUPA, Salama, Star Overseas, ALVYO (SAFI), Basil (tissue), V-Plus, Jabbar (boxes), Bonus and Nyungwe (copy paper, to confirm). The government lists paper and board as an import-substitution investment area. No paper PCC or GCC: ALICOMEC (limestone powder, lime), CIMERWA (Bugarama, travertine, about 600 kt cement).$cm$,
   $cm${"fillers": "Limestone powder and lime: ALICOMEC. Cement and travertine: CIMERWA. Not added: Kigali Cement, Anjia. No PCC or GCC.", "mills": "Fluting: Kigali Mingyang. Recycled tissue: Roba Industries. Context: SUPA, Salama, Star Overseas, ALVYO, Basil, V-Plus, Jabbar, Bonus, Nyungwe Paper.", "strategy": "Trials at Mingyang (strength-hold) and Roba (tissue), ALICOMEC samples for local GCC. Link with Uganda and Kenya supply chains.", "risks": "Output unknown, strength-led fluting.", "next_steps": ["Ask Mingyang for machine capacity and furnish", "Ask Roba for tissue machine specs"], "key_numbers": [{"label": "Mingyang fluting", "value": "120 gsm, exports to UG"}, {"label": "CIMERWA", "value": "about 600 kt/yr cement"}], "files": ["seed_20261016zzzt_rwanda_mills_fillers"]}$cm$::jsonb,
   $cm$Kigali Mingyang 골심지(우간다 수출)·Roba 재생 티슈(Bugesera) — 티슈·상자 가공 — ALICOMEC 석회석 분말, CIMERWA$cm$,
   $cm$르완다 초지기 유력 2곳: Kigali Mingyang Paper(120 gsm 골심지 우간다 수출, 초지기 펠트·성형망 수입), Roba Industries Bugesera(폐지 재활용 화장지, 2026~27 폐지 조달 공고). 가공: SUPA, Salama, Star Overseas, ALVYO(SAFI), Basil(티슈), V-Plus, Jabbar(상자), Bonus·Nyungwe(복사용지, 확인 필요). 정부가 종이·판지를 수입대체 투자 분야로 제시. 제지용 PCC·GCC 없음: ALICOMEC(석회석 분말·석회), CIMERWA(Bugarama, 트래버틴, 시멘트 약 60만 t).$cm$,
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
      ('mingyang', 'kigali|kayovu', 'mingyang'),
  ('roba industries|roba group', 'bugesera|ntarama', 'roba'),
  ('safari center|\msupa\M', null, 'safari center|\msupa\M'),
  ('salama industries', null, 'salama industries'),
  ('star overseas', null, 'star overseas'),
  ('alvyo|\msafi\M.*toilet', null, 'alvyo|\msafi\M.*toilet'),
  ('basil industries', null, 'basil industries'),
  ('v.?plus packaging', null, 'v.?plus packaging'),
  ('jabbar', null, 'jabbar'),
  ('bonus industries|bonus group', null, 'bonus industries|bonus group'),
  ('nyungwe paper', null, 'nyungwe paper')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'rwanda_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'rwanda_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'alicomec' or p.party_name ~* 'cimerwa')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'RW'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'RW'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'RW'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    