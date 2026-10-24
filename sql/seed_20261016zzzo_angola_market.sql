-- ============================================================
-- seed_20261016zzzo_angola_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Angola update (reports 2026-10-17). No base-paper mill confirmed - no
-- mill rows.
-- 1) Fillers if missing (3): Terrafort, Calcários da Huíla, ESA (planned).
-- 2) Context, match only (10): tissue and corrugated converters.
-- 3) app.country_markets AO row (priority none).
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
           v.party_name, 'AO', v.region, v.city, v.website, 'active', 'angola_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('terrafort|cimenfort', 'Terrafort (Grupo Cimenfort) - Lobito', 'Benguela', 'Lobito', null, 'Grupo Cimenfort 계열 Terrafort(2024~, Lobito 회랑) 석회석 가공 설치능력 연 140만 t — Lobito 항 연계.', 'Terrafort (Grupo Cimenfort), Lobito corridor - limestone processing since 2024 with 1.4 Mt/yr installed capacity and Lobito port logistics.', 'AO check 2026-10-16: total limestone capacity, not paper GCC. Test CaCO3, MgCO3, ISO brightness, Fe2O3, SiO2, D50 / D90 and ask about fine grinding and slurry. Candidate 1.'),
  ('calc[aá]rios da hu[ií]la', 'Calcários da Huíla', 'Huíla', 'Lubango', null, 'Calcários da Huíla(2007) 방해석·백운석질 석회석 — 토양개량제·사료용 탄산칼슘·소석회, 수요 부진으로 일 420 t → 90~150 t.', 'Calcários da Huíla (2007), southern Angola - processes calcitic and dolomitic limestone as soil conditioners, animal-feed calcium carbonate and hydrated lime, output down to 90-150 t/day (was 420 t/day) on weak demand.', 'AO check 2026-10-16: feed grade is unlike paper GCC - analysis needed. Spare capacity may suit a trial.'),
  ('engineering services angola|\mesa\M.*angola', 'Engineering Services Angola (ESA) - Malanje', 'Malanje', 'Malanje', null, 'ESA 농업용 석회석 분쇄공장 — 2025-12-10 광물자원부 착공 발표, 지역 채석장 원료·석고 제품.', 'Engineering Services Angola (ESA), Malanje - agricultural limestone grinding plant, ground-breaking announced by the mineral resources ministry 2025-12-10, local quarry feed plus gypsum products.', 'AO check 2026-10-16: not built yet - watch for extra grinding lines. No Angolan paper PCC or GCC, no Omya or Imerys plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%AO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('terrafort|cimenfort', 'Terrafort (Grupo Cimenfort) - Lobito', 'Benguela', 'Lobito', null, 'Grupo Cimenfort 계열 Terrafort(2024~, Lobito 회랑) 석회석 가공 설치능력 연 140만 t — Lobito 항 연계.', 'Terrafort (Grupo Cimenfort), Lobito corridor - limestone processing since 2024 with 1.4 Mt/yr installed capacity and Lobito port logistics.', 'AO check 2026-10-16: total limestone capacity, not paper GCC. Test CaCO3, MgCO3, ISO brightness, Fe2O3, SiO2, D50 / D90 and ask about fine grinding and slurry. Candidate 1.'),
  ('calc[aá]rios da hu[ií]la', 'Calcários da Huíla', 'Huíla', 'Lubango', null, 'Calcários da Huíla(2007) 방해석·백운석질 석회석 — 토양개량제·사료용 탄산칼슘·소석회, 수요 부진으로 일 420 t → 90~150 t.', 'Calcários da Huíla (2007), southern Angola - processes calcitic and dolomitic limestone as soil conditioners, animal-feed calcium carbonate and hydrated lime, output down to 90-150 t/day (was 420 t/day) on weak demand.', 'AO check 2026-10-16: feed grade is unlike paper GCC - analysis needed. Spare capacity may suit a trial.'),
  ('engineering services angola|\mesa\M.*angola', 'Engineering Services Angola (ESA) - Malanje', 'Malanje', 'Malanje', null, 'ESA 농업용 석회석 분쇄공장 — 2025-12-10 광물자원부 착공 발표, 지역 채석장 원료·석고 제품.', 'Engineering Services Angola (ESA), Malanje - agricultural limestone grinding plant, ground-breaking announced by the mineral resources ministry 2025-12-10, local quarry feed plus gypsum products.', 'AO check 2026-10-16: not built yet - watch for extra grinding lines. No Angolan paper PCC or GCC, no Omya or Imerys plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'angola_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Terrafort (Grupo Cimenfort) - Lobito', 'Limestone processor', 'Large limestone plant - candidate 1', 'merchant', 'C', 'gcc'),
  ('Calcários da Huíla', 'Carbonate processor', 'Feed and agri carbonate - spare capacity', 'merchant', 'C', 'gcc'),
  ('Engineering Services Angola (ESA) - Malanje', 'Limestone processor (planned)', 'Planned grinding plant - long-term', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'angola_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saluna', null, 'saluna', null, null, 'AO check 2026-10-16: Saluna Indústria, Polo Industrial de Viana (2015) - tissue converting, 50+ staff, states a plan to add local base-paper production - context only.'),
  ('\msipa\M|sociedade industrial de papel', null, '\msipa\M|sociedade industrial de papel', null, null, 'AO check 2026-10-16: SIPA (Sociedade Industrial de Papel de Angola, 2009, producing 2014), Viana - tissue converting (Klean), base paper sourced incl. The Navigator Company (PT) - context only.'),
  ('joia ?fef', null, 'joia ?fef', null, null, 'AO check 2026-10-16: Joia FEF, Cacuaco (2017) - about 10 ha, 10 production lines, 250 staff (hygiene products, not 10 paper machines) - context only.'),
  ('miper', null, 'miper', null, null, 'AO check 2026-10-16: MIPER, Kikuxi Viana - tissue converting of jumbo rolls - context only.'),
  ('miatop|fofinho', null, 'miatop|fofinho', null, null, 'AO check 2026-10-16: Miatop (Fofinho), Kapalanca Viana - tissue converting, diapers, wipes - context only.'),
  ('heran', null, 'heran', null, null, 'AO check 2026-10-16: Heran Indústria, Kikuxi (2016) - tissue, napkins, diapers and till-receipt rolls - context only.'),
  ('cartaplast', null, 'cartaplast', null, null, 'AO check 2026-10-16: Cartaplast Angola, Catumbela (Benguela) - corrugated boxes for food, fish and farming - context only.'),
  ('fsf global|we1 group', null, 'fsf global|we1 group', null, null, 'AO check 2026-10-16: FSF Global / We1 Group, Luanda - corrugated sheets, boxes, paper pallets - context only.'),
  ('pacote certo', null, 'pacote certo', null, null, 'AO check 2026-10-16: Corrugated rolls, sheets and boxes, Luanda - context only.'),
  ('embalagem do sol|fozkudia', null, 'embalagem do sol|fozkudia', null, null, 'AO check 2026-10-16: Embalagem do Sol, Luanda - single-face corrugated and printed packaging - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'angola_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saluna', null, 'saluna'),
  ('\msipa\M|sociedade industrial de papel', null, '\msipa\M|sociedade industrial de papel'),
  ('joia ?fef', null, 'joia ?fef'),
  ('miper', null, 'miper'),
  ('miatop|fofinho', null, 'miatop|fofinho'),
  ('heran', null, 'heran'),
  ('cartaplast', null, 'cartaplast'),
  ('fsf global|we1 group', null, 'fsf global|we1 group'),
  ('pacote certo', null, 'pacote certo'),
  ('embalagem do sol|fozkudia', null, 'embalagem do sol|fozkudia')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saluna', null, 'saluna', true,
   $pj${"owner": "Saluna Indústria", "products": "Saluna Indústria, Polo Industrial de Viana (2015) - tissue converting, 50+ staff, states a plan to add local base-paper production", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\msipa\M|sociedade industrial de papel', null, '\msipa\M|sociedade industrial de papel', true,
   $pj${"owner": "SIPA", "products": "SIPA (Sociedade Industrial de Papel de Angola, 2009, producing 2014), Viana - tissue converting (Klean), base paper sourced incl. The Navigator Company (PT)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('joia ?fef', null, 'joia ?fef', true,
   $pj${"owner": "Fukur E Filhos", "products": "Joia FEF, Cacuaco (2017) - about 10 ha, 10 production lines, 250 staff (hygiene products, not 10 paper machines)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('miper', null, 'miper', true,
   $pj${"owner": "MIPER", "products": "MIPER, Kikuxi Viana - tissue converting of jumbo rolls", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('miatop|fofinho', null, 'miatop|fofinho', true,
   $pj${"owner": "Miatop", "products": "Miatop (Fofinho), Kapalanca Viana - tissue converting, diapers, wipes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('heran', null, 'heran', true,
   $pj${"owner": "Heran Indústria", "products": "Heran Indústria, Kikuxi (2016) - tissue, napkins, diapers and till-receipt rolls", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartaplast', null, 'cartaplast', true,
   $pj${"owner": "Cartaplast", "products": "Cartaplast Angola, Catumbela (Benguela) - corrugated boxes for food, fish and farming", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fsf global|we1 group', null, 'fsf global|we1 group', true,
   $pj${"owner": "We1 Group", "products": "FSF Global / We1 Group, Luanda - corrugated sheets, boxes, paper pallets", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pacote certo', null, 'pacote certo', true,
   $pj${"owner": "Pacote Certo", "products": "Corrugated rolls, sheets and boxes, Luanda", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('embalagem do sol|fozkudia', null, 'embalagem do sol|fozkudia', true,
   $pj${"owner": "Fozkudia", "products": "Embalagem do Sol, Luanda - single-face corrugated and printed packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AO', 'Angola', 'none',
   $cm$No base-paper mill confirmed - tissue and corrugated converters around Viana (SIPA, Saluna, Miatop, MIPER, Heran, Joia FEF) - Terrafort limestone 1.4 Mt$cm$,
   $cm$Angola converts imported base paper: tissue at Viana and Kikuxi (SIPA, Saluna, MIPER, Miatop, Heran, Joia FEF) and corrugated at Luanda and Catumbela (Cartaplast, FSF Global, Pacote Certo, Embalagem do Sol). Saluna states a plan to add local base-paper production - the one design-stage opening. SIPA sources base paper incl. The Navigator Company (PT). HS 48 imports about USD 107.2 m in 2024 (Portugal, China, Italy, India). No paper PCC or GCC: Terrafort (Grupo Cimenfort, Lobito, 1.4 Mt/yr limestone), Calcários da Huíla (feed and agri grades, spare capacity), ESA Malanje (planned).$cm$,
   $cm${"fillers": "Limestone: Terrafort, Calcários da Huíla, ESA (planned). No paper GCC or PCC.", "mills": "No confirmed machine. Context: SIPA, Saluna, MIPER, Miatop, Heran, Joia FEF, Cartaplast, FSF Global, Pacote Certo, Embalagem do Sol.", "strategy": "Ask Saluna about its base-paper plan, trace SIPA's suppliers (Navigator PT rows). Terrafort or Calcários for a local GCC trial if a machine appears.", "risks": "No confirmed machine, FX and import reliance.", "next_steps": ["Ask Saluna whether the base-paper line is funded", "Request Terrafort limestone analysis"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 107.2 m"}, {"label": "Terrafort", "value": "1.4 Mt/yr limestone"}], "files": ["seed_20261016zzzo_angola_market"]}$cm$::jsonb,
   $cm$원지공장 미확인 — Viana 일대 티슈·골판지 가공(SIPA·Saluna·Miatop·MIPER·Heran·Joia FEF) — Terrafort 석회석 140만 t$cm$,
   $cm$앙골라는 수입 원지 가공: Viana·Kikuxi 티슈(SIPA, Saluna, MIPER, Miatop, Heran, Joia FEF), Luanda·Catumbela 골판지(Cartaplast, FSF Global, Pacote Certo, Embalagem do Sol). Saluna 가 현지 원지 생산 도입 계획 명시 — 유일한 설계단계 접점. SIPA 는 포르투갈 Navigator 등에서 원지 조달. HS 48 수입 2024 약 1.072억 달러(포르투갈·중국·이탈리아·인도). 제지용 PCC·GCC 없음: Terrafort(Cimenfort, Lobito, 석회석 140만 t), Calcários da Huíla(사료·농업용, 여유 설비), ESA Malanje(계획).$cm$,
   null, null,
   $cm$원지공장 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('saluna', null, 'saluna'),
  ('\msipa\M|sociedade industrial de papel', null, '\msipa\M|sociedade industrial de papel'),
  ('joia ?fef', null, 'joia ?fef'),
  ('miper', null, 'miper'),
  ('miatop|fofinho', null, 'miatop|fofinho'),
  ('heran', null, 'heran'),
  ('cartaplast', null, 'cartaplast'),
  ('fsf global|we1 group', null, 'fsf global|we1 group'),
  ('pacote certo', null, 'pacote certo'),
  ('embalagem do sol|fozkudia', null, 'embalagem do sol|fozkudia')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'angola_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'angola_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'terrafort|cimenfort' or p.party_name ~* 'calc[aá]rios da hu[ií]la' or p.party_name ~* 'engineering services angola|\mesa\M.*angola')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'AO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'AO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    