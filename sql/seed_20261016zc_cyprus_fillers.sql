-- ============================================================
-- seed_20261016zc_cyprus_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Cyprus update (reports 2026-10-16). No paper machine found - no mills
-- created.
-- 1) Fillers if missing (2): Peletico (feed-grade carbonate), Latomia
--    Latouros (limestone quarry). Both raw material only.
-- 2) Context, match only (11): Nikyr, Harco, P and S Carton, Unipakcyprus,
--    AMS Box, Caterways, Emes, G. P. Braspaper, Atensa, Cyprus Printing
--    Global, Abatay (the last three in the north).
-- 3) app.country_markets CY row (priority none).
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
           v.party_name, 'CY', v.region, v.city, v.website, 'active', 'cyprus_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('peletico', 'Peletico - Strovolos', 'Nicosia', 'Strovolos', null, '1960년 설립 산업광물·석고·벤토나이트·건자재 업체(Strovolos). 분쇄 탄산칼슘 FILLER K(150 μm 99% 통과, 사료용).', 'Peletico Ltd (1960), 19 Kampou, Strovolos (Nicosia) - industrial minerals, gypsum, bentonite, plasters and paints (Peletico Plasters), ground calcium carbonate FILLER K (99 pct under 150 micron, feed grade, 25 kg and 1 t bags).', 'CY check 2026-10-16: no paper grade - fine grinding and slurry would be new. peletico@peletico.com, +357 22 482265.'),
  ('latouros', 'Latomia Latouros - Dali', 'Nicosia', 'Dali', null, 'MSC Latouros 그룹 석회질 석회석 채굴·파쇄(Dali, 1977~), 0~4 mm 골재, 병렬 파쇄라인. 계열 Elmeni(Agios Sozomenos).', 'Latomia Latouros Ltd (MSC Latouros group, since 1977), Kosta Latourou 10, Dali (Nicosia) - calcareous limestone quarry with two parallel crushing lines (500 t/h jaw crusher), 0-4 mm sands and aggregates (EPD). Sister quarry Elmeni (Latomia) at Agios Sozomenos.', 'CY check 2026-10-16: aggregate sizes only - raw-material source. latouros@latouros.com. Not added: Chr. Peppos, Avraam Pittakis, Vassiliko Cement (cement, over 3 Mt/yr quarried), Neochrom (200-670 micron sand). No paper PCC or GCC in Cyprus.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('peletico', 'Peletico - Strovolos', 'Nicosia', 'Strovolos', null, '1960년 설립 산업광물·석고·벤토나이트·건자재 업체(Strovolos). 분쇄 탄산칼슘 FILLER K(150 μm 99% 통과, 사료용).', 'Peletico Ltd (1960), 19 Kampou, Strovolos (Nicosia) - industrial minerals, gypsum, bentonite, plasters and paints (Peletico Plasters), ground calcium carbonate FILLER K (99 pct under 150 micron, feed grade, 25 kg and 1 t bags).', 'CY check 2026-10-16: no paper grade - fine grinding and slurry would be new. peletico@peletico.com, +357 22 482265.'),
  ('latouros', 'Latomia Latouros - Dali', 'Nicosia', 'Dali', null, 'MSC Latouros 그룹 석회질 석회석 채굴·파쇄(Dali, 1977~), 0~4 mm 골재, 병렬 파쇄라인. 계열 Elmeni(Agios Sozomenos).', 'Latomia Latouros Ltd (MSC Latouros group, since 1977), Kosta Latourou 10, Dali (Nicosia) - calcareous limestone quarry with two parallel crushing lines (500 t/h jaw crusher), 0-4 mm sands and aggregates (EPD). Sister quarry Elmeni (Latomia) at Agios Sozomenos.', 'CY check 2026-10-16: aggregate sizes only - raw-material source. latouros@latouros.com. Not added: Chr. Peppos, Avraam Pittakis, Vassiliko Cement (cement, over 3 Mt/yr quarried), Neochrom (200-670 micron sand). No paper PCC or GCC in Cyprus.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'cyprus_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Peletico - Strovolos', 'Carbonate raw material', 'Ground carbonate (feed grade) - pilot contact', 'merchant', 'C', 'gcc'),
  ('Latomia Latouros - Dali', 'Carbonate raw material', 'Limestone quarry - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'cyprus_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nikyr', null, 'nikyr', null, null, 'CY check 2026-10-16: Tissue converting (Fay, Faytex, Charm, Rolly), Ergates, 120 staff - no paper machine found - context only.'),
  ('harco', null, 'harco', null, null, 'CY check 2026-10-16: Hygiene paper converting (Elite, Viva, Morana), Dali, ISO 9001 - context only.'),
  ('p ?& ?s carton', null, 'p ?& ?s carton', null, null, 'CY check 2026-10-16: Corrugated boxes, Ypsonas - about 60 pct of local demand, 51 pct stake sale announced 2026 - context only.'),
  ('unipak', null, 'unipak', null, null, 'CY check 2026-10-16: Corrugated and board packaging - INDEVCO group has paper mills abroad - context only.'),
  ('ams box', null, 'ams box', null, null, 'CY check 2026-10-16: Food boxes, Dali - converter - context only.'),
  ('caterways', null, 'caterways', null, null, 'CY check 2026-10-16: Food-service paper packaging - converter - context only.'),
  ('emes paper', null, 'emes paper', null, null, 'CY check 2026-10-16: Bakery trays and wraps, Ypsonas - converter - context only.'),
  ('braspaper', null, 'braspaper', null, null, 'CY check 2026-10-16: Paper, board, tissue base paper and pulp trader (Limassol, Dubai) - context only.'),
  ('atensa', null, 'atensa', null, null, 'CY check 2026-10-16: Tissue converting, north Nicosia - converter - context only.'),
  ('cyprus printing global', null, 'cyprus printing global', null, null, 'CY check 2026-10-16: Corrugated boxes, 7 m boxes/yr - converter - context only.'),
  ('abatay', null, 'abatay', null, null, 'CY check 2026-10-16: Paper boxes, Famagusta - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'cyprus_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nikyr', null, 'nikyr'),
  ('harco', null, 'harco'),
  ('p ?& ?s carton', null, 'p ?& ?s carton'),
  ('unipak', null, 'unipak'),
  ('ams box', null, 'ams box'),
  ('caterways', null, 'caterways'),
  ('emes paper', null, 'emes paper'),
  ('braspaper', null, 'braspaper'),
  ('atensa', null, 'atensa'),
  ('cyprus printing global', null, 'cyprus printing global'),
  ('abatay', null, 'abatay')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nikyr', null, 'nikyr',
   $pj${"owner": "Nikyr Products", "products": "Tissue converting (Fay, Faytex, Charm, Rolly), Ergates, 120 staff - no paper machine found", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('harco', null, 'harco',
   $pj${"owner": "Harco Trading", "products": "Hygiene paper converting (Elite, Viva, Morana), Dali, ISO 9001", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('p ?& ?s carton', null, 'p ?& ?s carton',
   $pj${"owner": "P and S Carton Industries", "products": "Corrugated boxes, Ypsonas - about 60 pct of local demand, 51 pct stake sale announced 2026", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('unipak', null, 'unipak',
   $pj${"owner": "UNIPAKCYPRUS (INDEVCO)", "products": "Corrugated and board packaging - INDEVCO group has paper mills abroad", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ams box', null, 'ams box',
   $pj${"owner": "AMS Box Making Factory", "products": "Food boxes, Dali - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('caterways', null, 'caterways',
   $pj${"owner": "Caterways", "products": "Food-service paper packaging - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('emes paper', null, 'emes paper',
   $pj${"owner": "Emes Paper Products", "products": "Bakery trays and wraps, Ypsonas - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('braspaper', null, 'braspaper',
   $pj${"owner": "G. P. Braspaper", "products": "Paper, board, tissue base paper and pulp trader (Limassol, Dubai)", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('atensa', null, 'atensa',
   $pj${"owner": "Atensa (north)", "products": "Tissue converting, north Nicosia - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cyprus printing global', null, 'cyprus printing global',
   $pj${"owner": "Cyprus Printing Global (north)", "products": "Corrugated boxes, 7 m boxes/yr - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('abatay', null, 'abatay',
   $pj${"owner": "Abatay Karton (north)", "products": "Paper boxes, Famagusta - converter", "approach": "Converter or trader - route to their base-paper mills abroad.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CY', 'Cyprus', 'none',
   $cm$No paper machine - tissue and box converters plus a paper trader (Braspaper) and INDEVCO link (Unipak)$cm$,
   $cm$Cyprus has no confirmed paper machine: Nikyr and Harco convert tissue, P and S Carton (about 60 pct of local boxes), Unipakcyprus, AMS and others convert board, G. P. Braspaper trades paper and pulp. Carbonate is limited to feed-grade powder (Peletico FILLER K) and limestone quarries (Latouros, Vassiliko Cement). No paper PCC or GCC. Value is as a door to INDEVCO mills and Braspaper suppliers abroad. North Cyprus firms (Atensa, Cyprus Printing Global, Abatay) are listed separately in notes.$cm$,
   $cm${"fillers": "Feed-grade ground carbonate: Peletico. Quarry: Latouros (with Elmeni). Not added: Chr. Peppos, Avraam Pittakis, Vassiliko Cement, Neochrom.", "mills": "No paper machine. Converters and traders (context): Nikyr, Harco, P and S Carton, Unipakcyprus, AMS Box, Caterways, Emes, G. P. Braspaper, north: Atensa, Cyprus Printing Global, Abatay.", "strategy": "No direct FCC sales - use Unipakcyprus to reach INDEVCO mills and Braspaper to reach its supplier mills. Supply by Turkish or Greek producers.", "risks": "No local volume, north Cyprus legal status.", "next_steps": ["Ask Unipakcyprus for an INDEVCO paper-mill contact"], "key_numbers": [{"label": "P and S Carton", "value": "about 60 pct of local box demand"}], "files": ["seed_20261016zc_cyprus_fillers"]}$cm$::jsonb,
   $cm$초지기 없음 — 티슈·상자 가공업체 + 종이 무역회사(Braspaper)·INDEVCO 연결(Unipak)$cm$,
   $cm$키프로스에는 초지기 확인 없음: Nikyr·Harco 티슈 가공, P&S Carton(현지 상자 약 60%)·Unipakcyprus·AMS 판지 가공, G. P. Braspaper 종이·펄프 무역. 탄산칼슘은 사료용 분말(Peletico)과 석회석 채석장(Latouros)뿐, 제지용 PCC·GCC 없음. 가치는 INDEVCO 제지공장·Braspaper 공급처로 가는 창구. 북키프로스 업체는 메모로 별도 표기.$cm$,
   null, null,
   $cm$초지기 없음 — 직접 수요 없음$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('nikyr', null, 'nikyr'),
  ('harco', null, 'harco'),
  ('p ?& ?s carton', null, 'p ?& ?s carton'),
  ('unipak', null, 'unipak'),
  ('ams box', null, 'ams box'),
  ('caterways', null, 'caterways'),
  ('emes paper', null, 'emes paper'),
  ('braspaper', null, 'braspaper'),
  ('atensa', null, 'atensa'),
  ('cyprus printing global', null, 'cyprus printing global'),
  ('abatay', null, 'abatay')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'cyprus_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'cyprus_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'peletico' or p.party_name ~* 'latouros')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    