-- ============================================================
-- seed_20261016a_bolivia_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bolivia update - paper-company report (2026-10-15). Introduction ->
-- intro_ko / intro_en (only when empty), detail -> notes once with
-- 'BO check 2026-10-15', plant data -> Mill profile card.
-- 1) Mills if missing (4) + plant blocks, priority 1-4: PAPELBOL Villa Tunari,
--    COPELME Cochabamba, Papelera Vinto, KUPEL (Empacar) Santa Cruz.
--    Context, match only (7): Kimberly Bolivia, La Papelera, Paper King,
--    Papelex, Novopel Tissue, Riverijos, Indamika.
-- 2) app.country_markets BO row (priority medium).
-- Fillers (MAPRIN, LUVEBOL) wait for the filler report.
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BO', v.region, v.city, v.website, 'active', 'bolivia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('papelbol|papeles de bolivia', 'villa tunari', 'papel', 'PAPELBOL - Villa Tunari', 'Cochabamba', 'Villa Tunari', null, '볼리비아 국영 제지사 PAPELBOL(2007 설립). Villa Tunari 공장에서 재생섬유 인쇄·필기용지(Papel Ecológico)·복사용지·크라프트지 생산, Santiváñez 재단시설. 2024 생산 1만 t 이상 전망, 2021부터 페루 수출.', 'Empresa Pública Productiva Papeles de Bolivia (PAPELBOL, state-owned, 2007) - recycled-fibre printing and writing paper (Papel Ecológico), copy paper and kraft at Villa Tunari, Cochabamba (reels up to 2.30 m), cutting at Santiváñez. Over 10,000 t forecast for 2024 (about 70 pct of sales kraft and eco paper to packaging and graphics), exports to Peru since 2021.', 'BO check 2026-10-15: a 75 t calcium carbonate purchase tender (2026-09) was found in the earlier filler research - real filler demand. papelbol.nacional@papelbol.com.bo, +591 71561074. 10 kt is a forecast, not nameplate.'),
  ('copelme|papelera de industria y comercio mendoza', 'cochabamba', 'copelme|mendoza', 'COPELME (Grupo Mendoza) - Cochabamba', 'Cochabamba', 'Cochabamba', null, 'Grupo Mendoza de Inversiones 의 티슈 제조사 COPELME(1996). Cochabamba PM3·PM4, 재생섬유 티슈, 브랜드 Nacional·Excelsior·Súper. 2025 소매 점유율 34%, 월 5,000만 롤 → 6,200만 롤 확대(Valmet Perini MyGo).', 'COPELME - Compañía Papelera de Industria y Comercio Mendoza S.A. (Grupo Mendoza de Inversiones, 1996), Av. Villazón Km 4.5, Cochabamba - tissue on PM3 (upgraded, +30 pct) and PM4, about 45 pct recycled fibre, brands Nacional, Excelsior, Súper. 34 pct of Bolivian retail tissue value (2025), converting raised 50 m to 62-63 m rolls/month (Valmet Perini MyGo, 2025), over 650 staff. New tissue plant at Warnes industrial park pursued.', 'BO check 2026-10-15: tonnage not public. info@copelme.com, +591 72208217.'),
  ('papelera vinto', 'vinto|quillacollo', 'vinto', 'Papelera Vinto (Quillacollo)', 'Cochabamba', 'Vinto', null, 'Cochabamba Vinto Chico(Quillacollo) 의 100% 천연 펄프 티슈 제조·가공사(15년+). 브랜드 Perla·Perlita, 2025 소매 점유율 34%.', 'Papelera Vinto S.R.L., Vinto Chico, Quillacollo, Cochabamba (over 15 years) - toilet tissue, napkins and towels on 100 pct virgin pulp, manufacturing and converting, brands Perla and Perlita (Perlita Ultra). 34 pct of Bolivian retail tissue value (2025).', 'BO check 2026-10-15: machine specs and tonnage not public.'),
  ('kupel|cruce.?a del papel', 'santa cruz', 'kupel|empacar', 'KUPEL (Empacar) - Santa Cruz', 'Santa Cruz', 'Santa Cruz de la Sierra', null, 'Empacar 계열 Industria Cruceña del Papel KUPEL(1970년대 말 시작). Santa Cruz 화장지 공장, 2024 재가동, 브랜드 Finesse. Empacar 2025 소매 점유율 16%.', 'Industria Cruceña del Papel KUPEL Ltda. (Empacar group, papermaking since the late 1970s), Santa Cruz de la Sierra - toilet tissue, plant restarted 2024, brand Finesse. Historically recycled waste paper and imported pulp for tissue and corrugating medium. Empacar holds 16 pct of retail tissue value (2025).', 'BO check 2026-10-15: current machine and tonnage not public. News headline - Kimberly-Clark stopped manufacturing in Bolivia and sold its assets to Empacar (to confirm which machines moved).')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BO check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelbol|papeles de bolivia', 'villa tunari', 'papel', '볼리비아 국영 제지사 PAPELBOL(2007 설립). Villa Tunari 공장에서 재생섬유 인쇄·필기용지(Papel Ecológico)·복사용지·크라프트지 생산, Santiváñez 재단시설. 2024 생산 1만 t 이상 전망, 2021부터 페루 수출.', 'Empresa Pública Productiva Papeles de Bolivia (PAPELBOL, state-owned, 2007) - recycled-fibre printing and writing paper (Papel Ecológico), copy paper and kraft at Villa Tunari, Cochabamba (reels up to 2.30 m), cutting at Santiváñez. Over 10,000 t forecast for 2024 (about 70 pct of sales kraft and eco paper to packaging and graphics), exports to Peru since 2021.', 'BO check 2026-10-15: a 75 t calcium carbonate purchase tender (2026-09) was found in the earlier filler research - real filler demand. papelbol.nacional@papelbol.com.bo, +591 71561074. 10 kt is a forecast, not nameplate.'),
  ('copelme|papelera de industria y comercio mendoza', 'cochabamba', 'copelme|mendoza', 'Grupo Mendoza de Inversiones 의 티슈 제조사 COPELME(1996). Cochabamba PM3·PM4, 재생섬유 티슈, 브랜드 Nacional·Excelsior·Súper. 2025 소매 점유율 34%, 월 5,000만 롤 → 6,200만 롤 확대(Valmet Perini MyGo).', 'COPELME - Compañía Papelera de Industria y Comercio Mendoza S.A. (Grupo Mendoza de Inversiones, 1996), Av. Villazón Km 4.5, Cochabamba - tissue on PM3 (upgraded, +30 pct) and PM4, about 45 pct recycled fibre, brands Nacional, Excelsior, Súper. 34 pct of Bolivian retail tissue value (2025), converting raised 50 m to 62-63 m rolls/month (Valmet Perini MyGo, 2025), over 650 staff. New tissue plant at Warnes industrial park pursued.', 'BO check 2026-10-15: tonnage not public. info@copelme.com, +591 72208217.'),
  ('papelera vinto', 'vinto|quillacollo', 'vinto', 'Cochabamba Vinto Chico(Quillacollo) 의 100% 천연 펄프 티슈 제조·가공사(15년+). 브랜드 Perla·Perlita, 2025 소매 점유율 34%.', 'Papelera Vinto S.R.L., Vinto Chico, Quillacollo, Cochabamba (over 15 years) - toilet tissue, napkins and towels on 100 pct virgin pulp, manufacturing and converting, brands Perla and Perlita (Perlita Ultra). 34 pct of Bolivian retail tissue value (2025).', 'BO check 2026-10-15: machine specs and tonnage not public.'),
  ('kupel|cruce.?a del papel', 'santa cruz', 'kupel|empacar', 'Empacar 계열 Industria Cruceña del Papel KUPEL(1970년대 말 시작). Santa Cruz 화장지 공장, 2024 재가동, 브랜드 Finesse. Empacar 2025 소매 점유율 16%.', 'Industria Cruceña del Papel KUPEL Ltda. (Empacar group, papermaking since the late 1970s), Santa Cruz de la Sierra - toilet tissue, plant restarted 2024, brand Finesse. Historically recycled waste paper and imported pulp for tissue and corrugating medium. Empacar holds 16 pct of retail tissue value (2025).', 'BO check 2026-10-15: current machine and tonnage not public. News headline - Kimberly-Clark stopped manufacturing in Bolivia and sold its assets to Empacar (to confirm which machines moved).'),
  ('kimberly.*bolivia', null, 'kimberly.*bolivia', null, null, 'BO check 2026-10-15: Santa Cruz Parque Industrial PI-5 - per news, stopped manufacturing after 25 years and sold assets to Empacar - context only.'),
  ('^la papelera', null, '^la papelera', null, null, 'BO check 2026-10-15: Corrugated boxes, paper sacks and bags (El Alto, Cochabamba, Santa Cruz) - mainly converting, small recycled board line in old World Bank data - context only.'),
  ('paper king', null, 'paper king', null, null, 'BO check 2026-10-15: Listed paper manufacturer, Santa Cruz - machine unknown - context only.'),
  ('papelex', null, 'papelex', null, null, 'BO check 2026-10-15: Paper and board manufacturing listing, Santa Cruz - context only.'),
  ('novopel', null, 'novopel', null, null, 'BO check 2026-10-15: Tissue company, Santa Cruz - making or converting unknown - context only.'),
  ('riverijos', null, 'riverijos', null, null, 'BO check 2026-10-15: Paper-industry company, La Paz - context only.'),
  ('indamika', null, 'indamika', null, null, 'BO check 2026-10-15: Paper and board company, La Paz - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'bolivia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelbol|papeles de bolivia', 'villa tunari', 'papel'),
  ('copelme|papelera de industria y comercio mendoza', 'cochabamba', 'copelme|mendoza'),
  ('papelera vinto', 'vinto|quillacollo', 'vinto'),
  ('kupel|cruce.?a del papel', 'santa cruz', 'kupel|empacar'),
  ('kimberly.*bolivia', null, 'kimberly.*bolivia'),
  ('^la papelera', null, '^la papelera'),
  ('paper king', null, 'paper king'),
  ('papelex', null, 'papelex'),
  ('novopel', null, 'novopel'),
  ('riverijos', null, 'riverijos'),
  ('indamika', null, 'indamika')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelbol|papeles de bolivia', 'villa tunari', 'papel',
   $pj${"owner": "Bolivian state (PAPELBOL)", "priority": 1, "products": "Recycled printing and writing paper, copy paper, kraft", "grades": ["Printing and writing", "Copy paper", "Kraft paper"], "capacity": {"value": 10000, "unit": "metric_t", "year": "2024 forecast", "source": "press 2024-12"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Planning scenario 3-5 pct of the 2024 forecast - not an order."}, "pitch": "Replace part of the purchased calcium carbonate with FCC and save fibre on eco printing paper", "approach": "Lead Bolivian account - state buyer, follow its tenders. Local GCC partner (MAPRIN or LUVEBOL, earlier filler research) as licensed producer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "Calcium carbonate tender 75 t (2026-09)", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('copelme|papelera de industria y comercio mendoza', 'cochabamba', 'copelme|mendoza',
   $pj${"owner": "Grupo Mendoza de Inversiones", "priority": 2, "products": "Toilet tissue, facial, napkins", "grades": ["Tissue"], "machines": 2, "pitch": "Low-dose FCC fibre replacement on recycled tissue (1-3-5 pct)", "approach": "Trial on PM3 or PM4 - tensile, absorbency, softness, brightness, dust, retention.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera vinto', 'vinto|quillacollo', 'vinto',
   $pj${"owner": "Papelera Vinto", "priority": 3, "products": "Toilet tissue, napkins, towels (virgin pulp)", "grades": ["Tissue"], "pitch": "Virgin-pulp saving with FCC", "approach": "Separate toilet tissue and napkin trials.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kupel|cruce.?a del papel', 'santa cruz', 'kupel|empacar',
   $pj${"owner": "Empacar", "priority": 4, "products": "Toilet tissue", "grades": ["Tissue"], "approach": "Confirm the running machine and whether ex Kimberly-Clark assets are in use.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*bolivia', null, 'kimberly.*bolivia',
   $pj${"owner": "Kimberly Bolivia", "products": "Santa Cruz Parque Industrial PI-5 - per news, stopped manufacturing after 25 years and sold assets to Empacar", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('^la papelera', null, '^la papelera',
   $pj${"owner": "La Papelera S.A.", "products": "Corrugated boxes, paper sacks and bags (El Alto, Cochabamba, Santa Cruz) - mainly converting, small recycled board line in old World Bank data", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('paper king', null, 'paper king',
   $pj${"owner": "Paper King", "products": "Listed paper manufacturer, Santa Cruz - machine unknown", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelex', null, 'papelex',
   $pj${"owner": "Papelex", "products": "Paper and board manufacturing listing, Santa Cruz", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('novopel', null, 'novopel',
   $pj${"owner": "Novopel Tissue", "products": "Tissue company, Santa Cruz - making or converting unknown", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('riverijos', null, 'riverijos',
   $pj${"owner": "Riverijos", "products": "Paper-industry company, La Paz", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('indamika', null, 'indamika',
   $pj${"owner": "Indamika", "products": "Paper and board company, La Paz", "approach": "Confirm an own paper machine before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BO', 'Bolivia', 'medium',
   $cm$PAPELBOL recycled printing paper (state, buys calcium carbonate) plus COPELME, Vinto and KUPEL tissue$cm$,
   $cm$State-owned PAPELBOL (Villa Tunari) makes recycled printing, copy and kraft paper - over 10 kt forecast for 2024 - and tenders for calcium carbonate. Tissue is led by COPELME (Grupo Mendoza, PM3 and PM4) and Papelera Vinto (virgin pulp), 34 pct retail share each, then Empacar / KUPEL (16 pct). Kimberly-Clark reportedly stopped making paper in Bolivia and sold assets to Empacar. La Papelera mainly converts.$cm$,
   $cm${"fillers": "Filler report not provided here - earlier research named MAPRIN and LUVEBOL as local GCC producers. PAPELBOL tendered 75 t of calcium carbonate (2026-09).", "mills": "PAPELBOL Villa Tunari (printing, copy, kraft). Tissue: COPELME Cochabamba, Papelera Vinto, KUPEL / Empacar Santa Cruz. Context: Kimberly Bolivia (stopped, assets to Empacar), La Papelera (converter), Paper King, Papelex, Novopel, Riverijos, Indamika.", "strategy": "PAPELBOL printing-paper FCC first (it already buys calcium carbonate), COPELME tissue trial in parallel. Local GCC producer as licensed FCC maker.", "risks": "Tonnage mostly unpublished, small volumes.", "next_steps": ["Follow PAPELBOL calcium carbonate tenders", "Get COPELME PM3 / PM4 tonnage", "Enter the Bolivia filler report (MAPRIN, LUVEBOL)"], "key_numbers": [{"label": "Retail tissue shares 2025", "value": "COPELME 34, Vinto 34, Empacar 16 pct (Euromonitor)"}, {"label": "PAPELBOL 2024", "value": "over 10,000 t forecast, Bs 44 m sales"}, {"label": "D&B paper listings", "value": "137 (incl. converters)"}], "files": ["seed_20261016a_bolivia_mills"]}$cm$::jsonb,
   $cm$PAPELBOL 재생 인쇄용지(국영, 탄산칼슘 구매) + COPELME·Vinto·KUPEL 티슈$cm$,
   $cm$국영 PAPELBOL(Villa Tunari) 재생 인쇄·복사·크라프트지, 2024 1만 t+ 전망, 탄산칼슘 구매 공고(2026-09 75 t). 티슈는 COPELME(PM3·PM4)·Papelera Vinto 각 34%, Empacar/KUPEL 16%. Kimberly-Clark 는 현지 생산 중단·자산 Empacar 매각 보도. La Papelera 는 주로 가공.$cm$,
   300, 500,
   $cm$PAPELBOL 1만 t × FCC 3~5% (티슈 3사는 톤수 미공개로 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('papelbol|papeles de bolivia', 'villa tunari', 'papel'),
  ('copelme|papelera de industria y comercio mendoza', 'cochabamba', 'copelme|mendoza'),
  ('papelera vinto', 'vinto|quillacollo', 'vinto'),
  ('kupel|cruce.?a del papel', 'santa cruz', 'kupel|empacar'),
  ('kimberly.*bolivia', null, 'kimberly.*bolivia'),
  ('^la papelera', null, '^la papelera'),
  ('paper king', null, 'paper king'),
  ('papelex', null, 'papelex'),
  ('novopel', null, 'novopel'),
  ('riverijos', null, 'riverijos'),
  ('indamika', null, 'indamika')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'bolivia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'bolivia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    