-- ============================================================
-- seed_20261016q_bolivia_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bolivia filler report (2026-10-15). Mills were done in seed_20261016a.
-- 1) Fillers if missing (4): MAPRIN, LUVEBOL, Estuquera Cayara, CALCO.
--    Oxametal not added.
-- 2) app.country_markets BO row refreshed (PAPELBOL tender detail added).
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
           v.party_name, 'BO', v.region, v.city, v.website, 'active', 'bolivia_fillers_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\mmaprin\M|materias primas industriales', 'MAPRIN (Materias Primas Industriales) - Santiváñez', 'Cochabamba', 'Santiváñez', null, '1979년 설립 산업광물 미분화 업체(Cochabamba Santiváñez 산업단지, 9,800 m²). 탄산칼슘 400~2,500 mesh, 폐회로 분급, 제지 용도 명시.', 'MAPRIN - Materias Primas Industriales (1979), Santiváñez industrial park, Cochabamba (about 9,800 m2) - ground limestone and marble carbonate in 400, 700, 1000, 2000 and 2500 mesh with closed-circuit classification, plus kaolin, bentonite, dolomite, paper named among uses.', 'BO check 2026-10-16: D50, brightness, capacity and wet slurry not public. Same park as the PAPELBOL cutting plant. FCC producer candidate 1.'),
  ('luvebol|carbocal', 'LUVEBOL (CARBOCAL)', null, null, null, 'CARBOCAL 브랜드 미분화 탄산칼슘(CaCO3 97~99%, pH 8~9, 수분 0.5% 이하). 제지 충전·코팅 용도 명시.', 'LUVEBOL - CARBOCAL micronised natural calcium carbonate (97-99 pct CaCO3, density 2.7-2.9, pH 8-9, moisture under 0.5 pct) in 25 and 30 kg bags, paper filler and surface coating named.', 'BO check 2026-10-16: size distribution, brightness and abrasion not public. Candidate 2.'),
  ('estuquera cayara', 'Estuquera Cayara', null, null, null, '1977년부터 백색 대리석계 탄산칼슘(Carbonato de Calcio Marmolado)·방해석·석회 업체. 제지·플라스틱·도료 용도 명시.', 'Estuquera Cayara S.R.L. (since 1977) - white-marble calcium carbonate (Carbonato de Calcio Marmolado), calcite in several sizes, quick and hydrated lime, paper, plastics and paint named, 40 kg bags and 1 t big bags.', 'BO check 2026-10-16: brightness and fines not public.'),
  ('\mcalco\M|caleras cochabamba', 'CALCO Bolivia (Caleras Cochabamba)', 'Cochabamba', 'Parotani', null, '1950년대 중반부터 석회·방해석·탄산칼슘 가공(Cochabamba Parotani·Santiváñez). 미분 탄산칼슘 97% 이상, 석회는 PCC 원료 용도 언급.', 'CALCO Bolivia - Caleras Cochabamba (since the mid 1950s), Parotani and Santiváñez (Cochabamba) - ground calcite, micronised calcium carbonate over 97 pct, quick and hydrated lime (lime named for PCC making).', 'BO check 2026-10-16: does not make PCC itself - lime source for a future PCC line. Not added: Global Company Oxametal (Kulla, Potosí - plan-stage material). No paper PCC plant in Bolivia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\mmaprin\M|materias primas industriales', 'MAPRIN (Materias Primas Industriales) - Santiváñez', 'Cochabamba', 'Santiváñez', null, '1979년 설립 산업광물 미분화 업체(Cochabamba Santiváñez 산업단지, 9,800 m²). 탄산칼슘 400~2,500 mesh, 폐회로 분급, 제지 용도 명시.', 'MAPRIN - Materias Primas Industriales (1979), Santiváñez industrial park, Cochabamba (about 9,800 m2) - ground limestone and marble carbonate in 400, 700, 1000, 2000 and 2500 mesh with closed-circuit classification, plus kaolin, bentonite, dolomite, paper named among uses.', 'BO check 2026-10-16: D50, brightness, capacity and wet slurry not public. Same park as the PAPELBOL cutting plant. FCC producer candidate 1.'),
  ('luvebol|carbocal', 'LUVEBOL (CARBOCAL)', null, null, null, 'CARBOCAL 브랜드 미분화 탄산칼슘(CaCO3 97~99%, pH 8~9, 수분 0.5% 이하). 제지 충전·코팅 용도 명시.', 'LUVEBOL - CARBOCAL micronised natural calcium carbonate (97-99 pct CaCO3, density 2.7-2.9, pH 8-9, moisture under 0.5 pct) in 25 and 30 kg bags, paper filler and surface coating named.', 'BO check 2026-10-16: size distribution, brightness and abrasion not public. Candidate 2.'),
  ('estuquera cayara', 'Estuquera Cayara', null, null, null, '1977년부터 백색 대리석계 탄산칼슘(Carbonato de Calcio Marmolado)·방해석·석회 업체. 제지·플라스틱·도료 용도 명시.', 'Estuquera Cayara S.R.L. (since 1977) - white-marble calcium carbonate (Carbonato de Calcio Marmolado), calcite in several sizes, quick and hydrated lime, paper, plastics and paint named, 40 kg bags and 1 t big bags.', 'BO check 2026-10-16: brightness and fines not public.'),
  ('\mcalco\M|caleras cochabamba', 'CALCO Bolivia (Caleras Cochabamba)', 'Cochabamba', 'Parotani', null, '1950년대 중반부터 석회·방해석·탄산칼슘 가공(Cochabamba Parotani·Santiváñez). 미분 탄산칼슘 97% 이상, 석회는 PCC 원료 용도 언급.', 'CALCO Bolivia - Caleras Cochabamba (since the mid 1950s), Parotani and Santiváñez (Cochabamba) - ground calcite, micronised calcium carbonate over 97 pct, quick and hydrated lime (lime named for PCC making).', 'BO check 2026-10-16: does not make PCC itself - lime source for a future PCC line. Not added: Global Company Oxametal (Kulla, Potosí - plan-stage material). No paper PCC plant in Bolivia.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'bolivia_fillers_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('MAPRIN (Materias Primas Industriales) - Santiváñez', 'GCC producer', 'Micronised GCC, paper named - FCC producer candidate 1', 'merchant', 'C', 'gcc'),
  ('LUVEBOL (CARBOCAL)', 'GCC producer', 'High-purity GCC, paper named - candidate 2', 'merchant', 'C', 'gcc'),
  ('Estuquera Cayara', 'GCC producer', 'Marble GCC, paper named', 'merchant', 'C', 'gcc'),
  ('CALCO Bolivia (Caleras Cochabamba)', 'GCC and lime producer', 'GCC and lime - future PCC base', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bolivia_fillers_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BO', 'Bolivia', 'medium',
   $cm$PAPELBOL recycled printing paper (state, buys calcium carbonate) plus COPELME, Vinto and KUPEL tissue$cm$,
   $cm$State-owned PAPELBOL (Villa Tunari) makes recycled printing, copy and kraft paper - over 10 kt forecast for 2024 - and tenders for calcium carbonate. Tissue is led by COPELME (Grupo Mendoza, PM3 and PM4) and Papelera Vinto (virgin pulp), 34 pct retail share each, then Empacar / KUPEL (16 pct). Kimberly-Clark reportedly stopped making paper in Bolivia and sold assets to Empacar. La Papelera mainly converts. Local GCC with paper named: MAPRIN, LUVEBOL, Estuquera Cayara, plus CALCO lime.$cm$,
   $cm${"fillers": "GCC, paper named: MAPRIN (Santiváñez, 400-2500 mesh), LUVEBOL CARBOCAL (97-99 pct), Estuquera Cayara (white marble). GCC and lime: CALCO (Parotani). Not added: Oxametal (plan stage). No PCC plant. PAPELBOL tender 2026-09-15: 75 t calcium carbonate, Bs 2.50/kg, delivery by 2026-11-03 (no. 26-0132-00-1676800-2-1).", "mills": "PAPELBOL Villa Tunari (printing, copy, kraft). Tissue: COPELME Cochabamba, Papelera Vinto, KUPEL / Empacar Santa Cruz. Context: Kimberly Bolivia (stopped, assets to Empacar), La Papelera (converter), Paper King, Papelex, Novopel, Riverijos, Indamika.", "strategy": "PAPELBOL printing-paper FCC first (it already buys calcium carbonate), COPELME tissue trial in parallel. Local GCC producer as licensed FCC maker.", "risks": "Tonnage mostly unpublished, small volumes.", "next_steps": ["Follow the PAPELBOL tender result", "Ask MAPRIN and LUVEBOL for D50, brightness and slurry", "Get COPELME PM3 / PM4 tonnage"], "key_numbers": [{"label": "Retail tissue shares 2025", "value": "COPELME 34, Vinto 34, Empacar 16 pct (Euromonitor)"}, {"label": "PAPELBOL 2024", "value": "over 10,000 t forecast, Bs 44 m sales"}, {"label": "D&B paper listings", "value": "137 (incl. converters)"}], "files": ["seed_20261016a_bolivia_mills", "seed_20261016q_bolivia_fillers"]}$cm$::jsonb,
   $cm$PAPELBOL 재생 인쇄용지(국영, 탄산칼슘 구매) + COPELME·Vinto·KUPEL 티슈$cm$,
   $cm$국영 PAPELBOL(Villa Tunari) 재생 인쇄·복사·크라프트지, 2024 1만 t+ 전망, 탄산칼슘 구매 공고(2026-09 75 t). 티슈는 COPELME(PM3·PM4)·Papelera Vinto 각 34%, Empacar/KUPEL 16%. Kimberly-Clark 는 현지 생산 중단·자산 Empacar 매각 보도. La Papelera 는 주로 가공. 현지 GCC(제지 명시): MAPRIN·LUVEBOL·Estuquera Cayara, 석회 CALCO.$cm$,
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
select 'filler' as kind, p.party_name as name,
       case when p.source = 'bolivia_fillers_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\mmaprin\M|materias primas industriales' or p.party_name ~* 'luvebol|carbocal' or p.party_name ~* 'estuquera cayara' or p.party_name ~* '\mcalco\M|caleras cochabamba')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'BO'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BO'
order by 1, 2;
