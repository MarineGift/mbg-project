-- ============================================================
-- seed_20261016n_honduras_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Honduras update (reports 2026-10-15).
-- 1) Fillers if missing (2): Calidra Honduras INCAL (site guard, so the
--    Mexican Calidra row is not hit), Carbonatos de Honduras.
-- 2) Mills if missing (2) + plant blocks: PAFISA (1), PACASA (2).
--    Context (7): Kimberly-Clark, Corrugados de Sula, Astro Cartón, CANASA,
--    Cartones Sula, PAINSA de Honduras, Alas Doradas.
-- 3) app.country_markets HN row (priority low).
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
           v.party_name, 'HN', v.region, v.city, v.website, 'active', 'honduras_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calidra.*(honduras|potrerillos)|\mincal\M', 'Calidra Honduras (INCAL) - Potrerillos', 'Cortés', 'Potrerillos', null, 'Grupo Calidra 의 온두라스 INCAL(1984~, Potrerillos) — 석회석 채굴·석회·탄산칼슘·돌로마이트. NUTRICALCIO(20 mesh~분말 0.25 mm 미만) 농업·사료용, 중미·카리브 수출.', 'Calidra Honduras - INCAL S.A. de C.V. (since 1984), Km 210 old San Pedro Sula - Tegucigalpa road, Aldea Corte Culebra, Potrerillos (Cortés) - limestone quarrying, lime, calcium carbonate and dolomite, NUTRICALCIO grades (20 mesh to powder under 0.25 mm) for agriculture and feed, exports to Central America and the Caribbean.', 'HN check 2026-10-15: no paper grade or PCC line confirmed - lime base could support PCC later. +504 2637-1070, industrial carbonate +504 3174-7386.'),
  ('carbonatos? de honduras', 'Carbonatos de Honduras - Choloma', 'Cortés', 'Choloma', null, 'Choloma Río Nance 천연 탄산칼슘 분쇄 공장 — 100·200·325 mesh(CaCO3 95~97%, 백색도 88~92%), 10 μm 미만 미분.', 'Carbonatos de Honduras, Río Nance, Choloma (Cortés) - natural calcium carbonate ground to 100, 200 and 325 mesh (95-97 pct CaCO3, 88-92 brightness, self-declared) plus a sub-10 micron grade, bulk or 50 kg bags, for paint, plastics, building, adhesives, feed.', 'HN check 2026-10-15: not paper-filler fineness - wet grinding needed. +504 9965-8999. Not added: Brenntag and OregonChem (distributors). No paper PCC plant, no Omya or MTI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%HN check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calidra.*(honduras|potrerillos)|\mincal\M', 'Calidra Honduras (INCAL) - Potrerillos', 'Cortés', 'Potrerillos', null, 'Grupo Calidra 의 온두라스 INCAL(1984~, Potrerillos) — 석회석 채굴·석회·탄산칼슘·돌로마이트. NUTRICALCIO(20 mesh~분말 0.25 mm 미만) 농업·사료용, 중미·카리브 수출.', 'Calidra Honduras - INCAL S.A. de C.V. (since 1984), Km 210 old San Pedro Sula - Tegucigalpa road, Aldea Corte Culebra, Potrerillos (Cortés) - limestone quarrying, lime, calcium carbonate and dolomite, NUTRICALCIO grades (20 mesh to powder under 0.25 mm) for agriculture and feed, exports to Central America and the Caribbean.', 'HN check 2026-10-15: no paper grade or PCC line confirmed - lime base could support PCC later. +504 2637-1070, industrial carbonate +504 3174-7386.'),
  ('carbonatos? de honduras', 'Carbonatos de Honduras - Choloma', 'Cortés', 'Choloma', null, 'Choloma Río Nance 천연 탄산칼슘 분쇄 공장 — 100·200·325 mesh(CaCO3 95~97%, 백색도 88~92%), 10 μm 미만 미분.', 'Carbonatos de Honduras, Río Nance, Choloma (Cortés) - natural calcium carbonate ground to 100, 200 and 325 mesh (95-97 pct CaCO3, 88-92 brightness, self-declared) plus a sub-10 micron grade, bulk or 50 kg bags, for paint, plastics, building, adhesives, feed.', 'HN check 2026-10-15: not paper-filler fineness - wet grinding needed. +504 9965-8999. Not added: Brenntag and OregonChem (distributors). No paper PCC plant, no Omya or MTI site.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'honduras_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calidra Honduras (INCAL) - Potrerillos', 'GCC and lime producer', 'Limestone and lime - raw material, future PCC base', 'merchant', 'C', 'gcc'),
  ('Carbonatos de Honduras - Choloma', 'GCC producer', 'Local GCC grinder - FCC pilot candidate', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'honduras_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'HN', v.region, v.city, v.website, 'active', 'honduras_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('papelera fiesta|\mpafisa\M', 'san pedro sula', 'fiesta|pafisa', 'Papelera Fiesta (PAFISA) - San Pedro Sula', 'Cortés', 'San Pedro Sula', null, 'San Pedro Sula 의 현지 티슈 제조사(2020). 버진 원료 화장지 Cariñoso, 현대식 종이 생산설비, DIFIESTA 독점 유통.', 'Papelera Fiesta (PAFISA, about 2020), San Pedro Sula (Cortés) - tissue maker on virgin fibre with its own papermaking line, Cariñoso toilet tissue distributed exclusively by DIFIESTA, private label offered, exports in Central America.', 'HN check 2026-10-15: machine count, speed and output not public - mill address to confirm.'),
  ('papelera calpules|\mpacasa\M', 'san pedro sula', 'calpules|pacasa', 'Papelera Calpules (PACASA) - San Pedro Sula', 'Cortés', 'San Pedro Sula', null, '1986년 설립 재생 종이·판지 제조사(San Pedro Sula). 폐지·폐골판지 원료 초지 + 가공, 학용·사무 용지, 중미·남미·카리브 수출.', 'Papelera Calpules S.A. (PACASA, 1986), Barrio El Benque, San Pedro Sula - paper mill and converting plant on recovered paper and OCC: industrial paper, board, school and office paper, exports to Central and South America and the Caribbean. A 2019 UNITEC study analysed the mill energy use.', 'HN check 2026-10-15: capacity not public (D&B revenue estimate about USD 20 m). Mill address may not match the sales office. +504 3152-0089.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%HN check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera fiesta|\mpafisa\M', 'san pedro sula', 'fiesta|pafisa', 'San Pedro Sula 의 현지 티슈 제조사(2020). 버진 원료 화장지 Cariñoso, 현대식 종이 생산설비, DIFIESTA 독점 유통.', 'Papelera Fiesta (PAFISA, about 2020), San Pedro Sula (Cortés) - tissue maker on virgin fibre with its own papermaking line, Cariñoso toilet tissue distributed exclusively by DIFIESTA, private label offered, exports in Central America.', 'HN check 2026-10-15: machine count, speed and output not public - mill address to confirm.'),
  ('papelera calpules|\mpacasa\M', 'san pedro sula', 'calpules|pacasa', '1986년 설립 재생 종이·판지 제조사(San Pedro Sula). 폐지·폐골판지 원료 초지 + 가공, 학용·사무 용지, 중미·남미·카리브 수출.', 'Papelera Calpules S.A. (PACASA, 1986), Barrio El Benque, San Pedro Sula - paper mill and converting plant on recovered paper and OCC: industrial paper, board, school and office paper, exports to Central and South America and the Caribbean. A 2019 UNITEC study analysed the mill energy use.', 'HN check 2026-10-15: capacity not public (D&B revenue estimate about USD 20 m). Mill address may not match the sales office. +504 3152-0089.'),
  ('kimberly.*honduras', null, 'kimberly.*honduras', null, null, 'HN check 2026-10-15: Villanueva site - own paper machine not confirmed - context only.'),
  ('corrugados de sula', null, 'corrugados de sula', null, null, 'HN check 2026-10-15: Corrugated boxes, Choloma (29,000 m2, 2 corrugators) - group paper mill is in Panama - context only.'),
  ('astro cart[oó]n', null, 'astro cart[oó]n', null, null, 'HN check 2026-10-15: Corrugated boxes, San Pedro Sula free zone - imports Saica rolls - context only.'),
  ('cartonera nacional|\mcanasa\M', null, 'cartonera nacional|\mcanasa\M', null, null, 'HN check 2026-10-15: Corrugated converting - context only.'),
  ('cartones sula', null, 'cartones sula', null, null, 'HN check 2026-10-15: Listed under paper and board - machine not confirmed - context only.'),
  ('painsa|papelera internacional', null, 'painsa|papelera internacional', null, null, 'HN check 2026-10-15: Warehouse and distribution - mill is in Guatemala - context only.'),
  ('alas doradas', null, 'alas doradas', null, null, 'HN check 2026-10-15: Sales company - mill is in El Salvador - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'honduras_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera fiesta|\mpafisa\M', 'san pedro sula', 'fiesta|pafisa'),
  ('papelera calpules|\mpacasa\M', 'san pedro sula', 'calpules|pacasa'),
  ('kimberly.*honduras', null, 'kimberly.*honduras'),
  ('corrugados de sula', null, 'corrugados de sula'),
  ('astro cart[oó]n', null, 'astro cart[oó]n'),
  ('cartonera nacional|\mcanasa\M', null, 'cartonera nacional|\mcanasa\M'),
  ('cartones sula', null, 'cartones sula'),
  ('painsa|papelera internacional', null, 'painsa|papelera internacional'),
  ('alas doradas', null, 'alas doradas')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('papelera fiesta|\mpafisa\M', 'san pedro sula', 'fiesta|pafisa',
   $pj${"owner": "PAFISA", "priority": 1, "products": "Toilet tissue", "grades": ["Tissue"], "pitch": "Tissue FCC 3-5 pct pilot on virgin furnish", "approach": "Get machine specs first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera calpules|\mpacasa\M', 'san pedro sula', 'calpules|pacasa',
   $pj${"owner": "PACASA", "priority": 2, "products": "Recycled paper and board, industrial paper", "grades": ["Board", "Industrial paper"], "approach": "Recycled-fibre saving with strength checks.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*honduras', null, 'kimberly.*honduras',
   $pj${"owner": "Kimberly-Clark Honduras", "products": "Villanueva site - own paper machine not confirmed", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corrugados de sula', null, 'corrugados de sula',
   $pj${"owner": "Corrugados de Sula (Empresas Galindo)", "products": "Corrugated boxes, Choloma (29,000 m2, 2 corrugators) - group paper mill is in Panama", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('astro cart[oó]n', null, 'astro cart[oó]n',
   $pj${"owner": "Astro Cartón Honduras", "products": "Corrugated boxes, San Pedro Sula free zone - imports Saica rolls", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartonera nacional|\mcanasa\M', null, 'cartonera nacional|\mcanasa\M',
   $pj${"owner": "Cartonera Nacional (CANASA)", "products": "Corrugated converting", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones sula', null, 'cartones sula',
   $pj${"owner": "Cartones Sula", "products": "Listed under paper and board - machine not confirmed", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('painsa|papelera internacional', null, 'painsa|papelera internacional',
   $pj${"owner": "PAINSA de Honduras (GrandBay)", "products": "Warehouse and distribution - mill is in Guatemala", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('alas doradas', null, 'alas doradas',
   $pj${"owner": "Alas Doradas", "products": "Sales company - mill is in El Salvador", "approach": "Converter or sales company.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'HN', 'Honduras', 'low',
   $cm$PAFISA tissue and PACASA recycled paper in San Pedro Sula - coarse local GCC (Calidra INCAL, Carbonatos de Honduras)$cm$,
   $cm$Two confirmed paper makers, both in San Pedro Sula: PAFISA (virgin-fibre tissue, Cariñoso) and PACASA (recycled paper and board since 1986). Box plants convert imported rolls (Corrugados de Sula, Astro Cartón, CANASA). Retail tissue is led by Papelera Internacional (Guatemala), Kimberly-Clark and Alas Doradas (El Salvador) - about 72 pct together. Local carbonate: Calidra INCAL (Potrerillos, lime and coarse carbonate) and Carbonatos de Honduras (to 325 mesh). No paper PCC.$cm$,
   $cm${"fillers": "Calidra Honduras INCAL (Potrerillos, lime, NUTRICALCIO), Carbonatos de Honduras (Choloma, 325 mesh, sub-10 micron). Not added: Brenntag, OregonChem (distributors).", "mills": "Tissue: PAFISA San Pedro Sula. Recycled paper and board: PACASA San Pedro Sula. Context: Kimberly-Clark Honduras (Villanueva), Corrugados de Sula, Astro Cartón, CANASA, Cartones Sula, PAINSA de Honduras (warehouse), Alas Doradas (sales).", "strategy": "PAFISA tissue pilot, then PACASA. Supply by Guatemala or Mexico producers, Calidra as a lime-based PCC option later.", "risks": "Small volumes, no capacity data.", "next_steps": ["Get PAFISA machine specs"], "key_numbers": [{"label": "Retail tissue top 3 (2025)", "value": "Papelera Internacional, Kimberly-Clark, Alas Doradas - about 72 pct"}, {"label": "D&B paper listings", "value": "22 (incl. converters)"}], "files": ["seed_20261016n_honduras_mills_fillers"]}$cm$::jsonb,
   $cm$San Pedro Sula 의 PAFISA 티슈·PACASA 재생지 — 현지 GCC 는 조립품(Calidra INCAL·Carbonatos de Honduras)$cm$,
   $cm$원지 제조 확인 2곳(모두 San Pedro Sula): PAFISA 버진 티슈(Cariñoso), PACASA 재생 종이·판지(1986~). 골판지 업체는 수입 원지 가공. 소매 티슈는 Papelera Internacional(과테말라)·Kimberly-Clark·Alas Doradas(엘살바도르) 약 72%. 현지 탄산칼슘: Calidra INCAL·Carbonatos de Honduras, 제지용 PCC 없음.$cm$,
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
      ('papelera fiesta|\mpafisa\M', 'san pedro sula', 'fiesta|pafisa'),
  ('papelera calpules|\mpacasa\M', 'san pedro sula', 'calpules|pacasa'),
  ('kimberly.*honduras', null, 'kimberly.*honduras'),
  ('corrugados de sula', null, 'corrugados de sula'),
  ('astro cart[oó]n', null, 'astro cart[oó]n'),
  ('cartonera nacional|\mcanasa\M', null, 'cartonera nacional|\mcanasa\M'),
  ('cartones sula', null, 'cartones sula'),
  ('painsa|papelera internacional', null, 'painsa|papelera internacional'),
  ('alas doradas', null, 'alas doradas')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'honduras_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'honduras_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calidra.*(honduras|potrerillos)|\mincal\M' or p.party_name ~* 'carbonatos? de honduras')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'HN'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'HN'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'HN'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    