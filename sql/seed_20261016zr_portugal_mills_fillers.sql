-- ============================================================
-- seed_20261016zr_portugal_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Portugal update (reports 2026-10-16).
-- 1) Fillers if missing (5): SMI Figueira da Foz (satellite PCC), Omya
--    Setúbal (satellite PCC), Omya Mineral Portuguesa (GCC), Microlime,
--    Calcidrata.
-- 2) Mills if missing (8) + plant blocks, priority 1-7: Navigator Figueira,
--    Navigator Setúbal, Fortissue, Fapajal, Renova, Prado, Paper Prime.
--    DS Smith Viana no priority. Context (6).
-- 3) Supply links (2, active): SMI -> Navigator Figueira, Omya -> Navigator
--    Setúbal.
-- 4) app.country_markets PT row (priority high).
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
           v.party_name, 'PT', v.region, v.city, v.website, 'active', 'portugal_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('(specialty minerals|minerals technologies).*(portug|figueira)', 'Specialty Minerals Portugal - Figueira da Foz (satellite PCC)', 'Coimbra', 'Figueira da Foz', null, 'MTI/SMI 위성 PCC 공장 — Navigator Figueira da Foz 산업단지 내(1995 가동, 2000 증설), 제지공장 CO2·탄산칼슘 부산물 활용. 2005 자료 포르투갈 위성 PCC 3곳 합계 15.5만~20.5만 t.', 'Specialty Minerals Inc. (Minerals Technologies) satellite PCC plant inside The Navigator Company complex at Figueira da Foz - first unit 1995, second 2000, uses mill CO2 and carbonate by-products, supplies UWF filler PCC (Navigator 2023 sustainability report). Three Portuguese satellite PCC units totalled about 155,000-205,000 t/yr in 2005.', 'PT check 2026-10-16: 2026 capacity and line count to confirm. SMI is the MBG tissue-track partner (NDA) - raise the Figueira trial through that relationship.'),
  ('omya.*set[uú]bal', 'Omya - Setúbal (satellite PCC)', 'Setúbal', 'Setúbal', null, 'Omya 위성 PCC 공장 — Navigator Setúbal 산업단지 내부(Navigator 2023 보고서).', 'Omya satellite PCC plant inside The Navigator Company Setúbal complex, supplying UWF filler PCC (Navigator 2023 report).', 'PT check 2026-10-16: capacity not public. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('omya mineral portuguesa', 'Omya Mineral Portuguesa - Perulheira', 'Lisbon', 'Perulheira', null, 'Salmon·Omya AG 합작 GCC(1983~, Perulheira) — 연 약 10만 t, 대리석·방해석 미분·표면처리, 플라스틱·도료 위주, ISO 9001·14001·45001.', 'Omya Mineral Portuguesa, Lda. (joint venture of Salmon and Omya AG, plant since 1983), Perulheira - about 100,000 t/yr micronised and coated marble and calcite GCC, mainly plastics, paint, adhesives, ceramics.', 'PT check 2026-10-16: paper share and wet slurry not confirmed. Not added: LDM Minerais / BIOCAL (agricultural carbonate, 88.2 pct), Lhoist (lime, no Portuguese PCC plant identified).'),
  ('microlime', 'Microlime', 'Leiria', null, null, 'PCC 제조용 고순도·고반응성 생석회 공급, 펄프·제지 응용 명시.', 'Microlime - Produtos de Cal e Derivados, S.A. - high-purity, high-reactivity quicklime for PCC making plus hydrated and dolomitic lime, pulp and paper named.', 'PT check 2026-10-16: raw material for PCC.'),
  ('calcidrata', 'Calcidrata - Alcanede', 'Santarém', 'Alcanede', null, 'Alcanede 석회 제조 — 크라프트 펄프 약품 회수·PCC 충전제 제조용 석회 명시.', 'Calcidrata, Pé da Pedreira, Alcanede - lime products for kraft-pulp recausticising and PCC filler making.', 'PT check 2026-10-16: calcidrata@calcidrata.pt, +351 243 409 030.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%PT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('(specialty minerals|minerals technologies).*(portug|figueira)', 'Specialty Minerals Portugal - Figueira da Foz (satellite PCC)', 'Coimbra', 'Figueira da Foz', null, 'MTI/SMI 위성 PCC 공장 — Navigator Figueira da Foz 산업단지 내(1995 가동, 2000 증설), 제지공장 CO2·탄산칼슘 부산물 활용. 2005 자료 포르투갈 위성 PCC 3곳 합계 15.5만~20.5만 t.', 'Specialty Minerals Inc. (Minerals Technologies) satellite PCC plant inside The Navigator Company complex at Figueira da Foz - first unit 1995, second 2000, uses mill CO2 and carbonate by-products, supplies UWF filler PCC (Navigator 2023 sustainability report). Three Portuguese satellite PCC units totalled about 155,000-205,000 t/yr in 2005.', 'PT check 2026-10-16: 2026 capacity and line count to confirm. SMI is the MBG tissue-track partner (NDA) - raise the Figueira trial through that relationship.'),
  ('omya.*set[uú]bal', 'Omya - Setúbal (satellite PCC)', 'Setúbal', 'Setúbal', null, 'Omya 위성 PCC 공장 — Navigator Setúbal 산업단지 내부(Navigator 2023 보고서).', 'Omya satellite PCC plant inside The Navigator Company Setúbal complex, supplying UWF filler PCC (Navigator 2023 report).', 'PT check 2026-10-16: capacity not public. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('omya mineral portuguesa', 'Omya Mineral Portuguesa - Perulheira', 'Lisbon', 'Perulheira', null, 'Salmon·Omya AG 합작 GCC(1983~, Perulheira) — 연 약 10만 t, 대리석·방해석 미분·표면처리, 플라스틱·도료 위주, ISO 9001·14001·45001.', 'Omya Mineral Portuguesa, Lda. (joint venture of Salmon and Omya AG, plant since 1983), Perulheira - about 100,000 t/yr micronised and coated marble and calcite GCC, mainly plastics, paint, adhesives, ceramics.', 'PT check 2026-10-16: paper share and wet slurry not confirmed. Not added: LDM Minerais / BIOCAL (agricultural carbonate, 88.2 pct), Lhoist (lime, no Portuguese PCC plant identified).'),
  ('microlime', 'Microlime', 'Leiria', null, null, 'PCC 제조용 고순도·고반응성 생석회 공급, 펄프·제지 응용 명시.', 'Microlime - Produtos de Cal e Derivados, S.A. - high-purity, high-reactivity quicklime for PCC making plus hydrated and dolomitic lime, pulp and paper named.', 'PT check 2026-10-16: raw material for PCC.'),
  ('calcidrata', 'Calcidrata - Alcanede', 'Santarém', 'Alcanede', null, 'Alcanede 석회 제조 — 크라프트 펄프 약품 회수·PCC 충전제 제조용 석회 명시.', 'Calcidrata, Pé da Pedreira, Alcanede - lime products for kraft-pulp recausticising and PCC filler making.', 'PT check 2026-10-16: calcidrata@calcidrata.pt, +351 243 409 030.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'portugal_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Specialty Minerals Portugal - Figueira da Foz (satellite PCC)', 'PCC producer', 'SMI satellite PCC at Navigator Figueira - three-way trial', 'satellite', 'B', 'pcc'),
  ('Omya - Setúbal (satellite PCC)', 'PCC producer', 'Omya satellite PCC at Navigator Setúbal - licensee', 'satellite', 'B', 'pcc'),
  ('Omya Mineral Portuguesa - Perulheira', 'GCC producer', 'Omya JV GCC 100 kt', 'merchant', 'B', 'gcc'),
  ('Microlime', 'Lime producer', 'PCC-grade quicklime', 'merchant', 'C', 'pcc'),
  ('Calcidrata - Alcanede', 'Lime producer', 'Lime for PCC and pulp', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'portugal_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'PT', v.region, v.city, v.website, 'active', 'portugal_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel', 'The Navigator Company - Figueira da Foz', 'Coimbra', 'Figueira da Foz', null, 'Navigator Figueira da Foz 통합 공장 — 비도공지(UWF) 연 약 80만 t + 표백 유칼립투스 펄프 약 57만 t. SMI 위성 PCC.', 'The Navigator Company, Figueira da Foz - integrated uncoated woodfree (UWF) mill about 800,000 t/yr plus about 570,000 t/yr bleached eucalyptus pulp, SMI satellite PCC on site.', 'PT check 2026-10-16: Navigator total UWF about 1.6 Mt (with Setúbal).'),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel', 'The Navigator Company - Setúbal', 'Setúbal', 'Setúbal', null, 'Navigator Setúbal UWF 연 약 77.5만~80만 t, Omya 위성 PCC.', 'The Navigator Company, Setúbal - UWF mill about 775,000-800,000 t/yr, Omya satellite PCC on site.', 'PT check 2026-10-16: '),
  ('fortissue', 'alvar[aã]es', 'fortissue', 'Fortissue - Alvarães', 'Viana do Castelo', 'Alvarães', null, '2015 첫 생산 티슈 원지(Alvarães) 연 3.5만 t, 100% 버진펄프, 크레센트 포머+슈프레스.', 'Fortissue - Produção de Papel, S.A., Alvarães (Viana do Castelo) - tissue base paper since 2015, 35,000 t/yr on 100 pct virgin pulp, crescent former with shoe press.', 'PT check 2026-10-16: info@fortissue.pt, +351 258 358 190.'),
  ('fapajal', 'loures|tojal', 'fapajal', 'Fapajal Papermaking - Loures', 'Lisbon', 'Loures', null, '1755년 전통 티슈 원지(Parent Reels) 제조(São Julião do Tojal), 150명+.', 'Fapajal Papermaking, S.A. (tradition since 1755), São Julião do Tojal, Loures - tissue parent reels for Portuguese and foreign converters, over 150 staff.', 'PT check 2026-10-16: capacity not public.'),
  ('renova', 'torres novas|zibreira', 'renova', 'Renova - Torres Novas', 'Santarém', 'Torres Novas', null, 'Renova(Fábrica de Papel do Almonda) 프리미엄 티슈(Torres Novas/Zibreira).', 'Renova - Fábrica de Papel do Almonda, S.A., Torres Novas / Zibreira - premium toilet tissue, towels and napkins, design-led products.', 'PT check 2026-10-16: capacity not public.'),
  ('prado|cartolinas da lous', 'lous[aã]', 'prado', 'Prado Cartolinas da Lousã - Lousã', 'Coimbra', 'Lousã', null, 'Lousã 버진펄프 고평량 인쇄용지·브리스톨 판지·색지·미술용지, 2024 수출 85%·약 50개국.', 'Prado - Cartolinas da Lousã, S.A., Lousã - virgin-pulp heavyweight printing papers, Bristol board, coloured and art papers, food-contact grades, 85 pct exported to about 50 countries (2024).', 'PT check 2026-10-16: capacity not public.'),
  ('paper prime', 'r[oó]d[aã]o', 'paper prime', 'Paper Prime - Vila Velha de Ródão', 'Castelo Branco', 'Vila Velha de Ródão', null, 'Vila Velha de Ródão 티슈 원지(Toscotec 업그레이드).', 'Paper Prime, S.A., Vila Velha de Ródão - tissue base paper (Toscotec production upgrade).', 'PT check 2026-10-16: capacity not public.'),
  ('ds smith.*viana|viana paper', 'viana', 'ds smith', 'DS Smith Paper Viana - Viana do Castelo', 'Viana do Castelo', 'Viana do Castelo', null, 'DS Smith Viana 크라프트라이너(PortoPAC·VianaPAC) 연 약 44만 t, 115~275 g/m², 6.55 m·1,100 m/분.', 'DS Smith Paper Viana, Viana do Castelo - kraftliner PortoPAC and VianaPAC, about 440,000 t/yr, 115-275 g/m2, two-ply machine 6.55 m wide at 1,100 m/min. Now part of International Paper.', 'PT check 2026-10-16: strength-led.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PT check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel', 'Navigator Figueira da Foz 통합 공장 — 비도공지(UWF) 연 약 80만 t + 표백 유칼립투스 펄프 약 57만 t. SMI 위성 PCC.', 'The Navigator Company, Figueira da Foz - integrated uncoated woodfree (UWF) mill about 800,000 t/yr plus about 570,000 t/yr bleached eucalyptus pulp, SMI satellite PCC on site.', 'PT check 2026-10-16: Navigator total UWF about 1.6 Mt (with Setúbal).'),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel', 'Navigator Setúbal UWF 연 약 77.5만~80만 t, Omya 위성 PCC.', 'The Navigator Company, Setúbal - UWF mill about 775,000-800,000 t/yr, Omya satellite PCC on site.', 'PT check 2026-10-16: '),
  ('fortissue', 'alvar[aã]es', 'fortissue', '2015 첫 생산 티슈 원지(Alvarães) 연 3.5만 t, 100% 버진펄프, 크레센트 포머+슈프레스.', 'Fortissue - Produção de Papel, S.A., Alvarães (Viana do Castelo) - tissue base paper since 2015, 35,000 t/yr on 100 pct virgin pulp, crescent former with shoe press.', 'PT check 2026-10-16: info@fortissue.pt, +351 258 358 190.'),
  ('fapajal', 'loures|tojal', 'fapajal', '1755년 전통 티슈 원지(Parent Reels) 제조(São Julião do Tojal), 150명+.', 'Fapajal Papermaking, S.A. (tradition since 1755), São Julião do Tojal, Loures - tissue parent reels for Portuguese and foreign converters, over 150 staff.', 'PT check 2026-10-16: capacity not public.'),
  ('renova', 'torres novas|zibreira', 'renova', 'Renova(Fábrica de Papel do Almonda) 프리미엄 티슈(Torres Novas/Zibreira).', 'Renova - Fábrica de Papel do Almonda, S.A., Torres Novas / Zibreira - premium toilet tissue, towels and napkins, design-led products.', 'PT check 2026-10-16: capacity not public.'),
  ('prado|cartolinas da lous', 'lous[aã]', 'prado', 'Lousã 버진펄프 고평량 인쇄용지·브리스톨 판지·색지·미술용지, 2024 수출 85%·약 50개국.', 'Prado - Cartolinas da Lousã, S.A., Lousã - virgin-pulp heavyweight printing papers, Bristol board, coloured and art papers, food-contact grades, 85 pct exported to about 50 countries (2024).', 'PT check 2026-10-16: capacity not public.'),
  ('paper prime', 'r[oó]d[aã]o', 'paper prime', 'Vila Velha de Ródão 티슈 원지(Toscotec 업그레이드).', 'Paper Prime, S.A., Vila Velha de Ródão - tissue base paper (Toscotec production upgrade).', 'PT check 2026-10-16: capacity not public.'),
  ('ds smith.*viana|viana paper', 'viana', 'ds smith', 'DS Smith Viana 크라프트라이너(PortoPAC·VianaPAC) 연 약 44만 t, 115~275 g/m², 6.55 m·1,100 m/분.', 'DS Smith Paper Viana, Viana do Castelo - kraftliner PortoPAC and VianaPAC, about 440,000 t/yr, 115-275 g/m2, two-ply machine 6.55 m wide at 1,100 m/min. Now part of International Paper.', 'PT check 2026-10-16: strength-led.'),
  ('navigator.*(cacia|aveiro)', null, 'navigator.*(cacia|aveiro)', null, null, 'PT check 2026-10-16: Aveiro / Cacia pulp and tissue - context only.'),
  ('navigator.*r[oó]d[aã]o', null, 'navigator.*r[oó]d[aã]o', null, null, 'PT check 2026-10-16: Vila Velha de Ródão tissue - context only.'),
  ('coreboard', null, 'coreboard', null, null, 'PT check 2026-10-16: Core board paper, north Portugal - context only.'),
  ('ponte redonda', null, 'ponte redonda', null, null, 'PT check 2026-10-16: Industrial and specialty paper - context only.'),
  ('\mcelbi\M|biotek', null, '\mcelbi\M|biotek', null, null, 'PT check 2026-10-16: Celbi BEKP 800 kt, Biotek 260 kt - pulp only - context only.'),
  ('\mcaima\M', null, '\mcaima\M', null, null, 'PT check 2026-10-16: Caima dissolving pulp 115 kt - pulp only - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'portugal_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel'),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel'),
  ('fortissue', 'alvar[aã]es', 'fortissue'),
  ('fapajal', 'loures|tojal', 'fapajal'),
  ('renova', 'torres novas|zibreira', 'renova'),
  ('prado|cartolinas da lous', 'lous[aã]', 'prado'),
  ('paper prime', 'r[oó]d[aã]o', 'paper prime'),
  ('ds smith.*viana|viana paper', 'viana', 'ds smith'),
  ('navigator.*(cacia|aveiro)', null, 'navigator.*(cacia|aveiro)'),
  ('navigator.*r[oó]d[aã]o', null, 'navigator.*r[oó]d[aã]o'),
  ('coreboard', null, 'coreboard'),
  ('ponte redonda', null, 'ponte redonda'),
  ('\mcelbi\M|biotek', null, '\mcelbi\M|biotek'),
  ('\mcaima\M', null, '\mcaima\M')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel',
   $pj${"owner": "The Navigator Company", "priority": 1, "products": "UWF copy and offset paper, eucalyptus pulp", "grades": ["UWF", "Copy paper"], "capacity": {"value": 800000, "unit": "metric_t", "year": "Company site (UWF)", "source": "thenavigatorcompany.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct of UWF."}, "pitch": "Navigator + SMI + MBG three-way FCC trial on copy paper (5, 10, 15 pct)", "approach": "Top European target - SMI satellite on site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel',
   $pj${"owner": "The Navigator Company", "priority": 2, "products": "UWF copy and offset paper", "grades": ["UWF", "Copy paper"], "capacity": {"value": 775000, "unit": "metric_t", "year": "Company site (UWF)", "source": "thenavigatorcompany.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario 5-10 pct."}, "pitch": "FCC vs Omya Multifill / FiberLean benchmark", "approach": "Second Navigator site - Omya on site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fortissue', 'alvar[aã]es', 'fortissue',
   $pj${"owner": "Fortissue", "priority": 3, "products": "Tissue base paper", "grades": ["Tissue"], "capacity": {"value": 35000, "unit": "metric_t", "year": "Company figure", "source": "fortissue.pt"}, "approach": "Simple structure - joint tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fapajal', 'loures|tojal', 'fapajal',
   $pj${"owner": "Fapajal", "priority": 4, "products": "Tissue parent reels", "grades": ["Tissue"], "approach": "Softness vs strength trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('renova', 'torres novas|zibreira', 'renova',
   $pj${"owner": "Renova", "priority": 5, "products": "Premium tissue", "grades": ["Tissue"], "approach": "Premium co-development.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('prado|cartolinas da lous', 'lous[aã]', 'prado',
   $pj${"owner": "Prado", "priority": 6, "products": "Heavyweight printing paper, Bristol board, coloured paper", "grades": ["UWF", "Board"], "approach": "Fibre saving with opacity kept.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('paper prime', 'r[oó]d[aã]o', 'paper prime',
   $pj${"owner": "Paper Prime", "priority": 7, "products": "Tissue base paper", "grades": ["Tissue"], "approach": "Trial after machine data.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*viana|viana paper', 'viana', 'ds smith',
   $pj${"owner": "DS Smith (International Paper)", "products": "Kraftliner", "grades": ["Kraftliner"], "capacity": {"value": 440000, "unit": "metric_t", "year": "Company site", "source": "dssmith.com"}, "approach": "After packaging FCC is proven.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('navigator.*(cacia|aveiro)', null, 'navigator.*(cacia|aveiro)',
   $pj${"owner": "The Navigator Company", "products": "Aveiro / Cacia pulp and tissue", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('navigator.*r[oó]d[aã]o', null, 'navigator.*r[oó]d[aã]o',
   $pj${"owner": "The Navigator Company", "products": "Vila Velha de Ródão tissue", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('coreboard', null, 'coreboard',
   $pj${"owner": "Papeleira Coreboard", "products": "Core board paper, north Portugal", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ponte redonda', null, 'ponte redonda',
   $pj${"owner": "Fábrica de Papel Ponte Redonda", "products": "Industrial and specialty paper", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mcelbi\M|biotek', null, '\mcelbi\M|biotek',
   $pj${"owner": "Altri", "products": "Celbi BEKP 800 kt, Biotek 260 kt - pulp only", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mcaima\M', null, '\mcaima\M',
   $pj${"owner": "Altri", "products": "Caima dissolving pulp 115 kt - pulp only", "approach": "Pulp or details to collect.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'portugal_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel', '(specialty minerals|minerals technologies).*(portug|figueira)', 'active', 'high', '1995-01-01'::date, null::date, null, 'satellite PCC inside the mill complex', 'Navigator 2023 sustainability report, Roskill 2005', 'SMI satellite PCC at Navigator Figueira da Foz since 1995 (second unit 2000)'),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel', 'omya.*set[uú]bal', 'active', 'high', null::date, null::date, null, 'satellite PCC inside the mill complex', 'Navigator 2023 sustainability report', 'Omya satellite PCC at Navigator Setúbal')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ~* v.filler_rx
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PT', 'Portugal', 'high',
   $cm$Navigator 1.6 Mt UWF (Figueira da Foz, Setúbal) with SMI and Omya satellite PCC - tissue at Fortissue, Fapajal, Renova$cm$,
   $cm$Portugal's FCC case is Navigator: about 1.6 Mt uncoated woodfree at Figueira da Foz (800 kt, SMI satellite PCC since 1995) and Setúbal (775 kt, Omya satellite PCC). Tissue at Fortissue (35 kt virgin), Fapajal, Renova, Paper Prime and Navigator Ródão, heavyweight papers at Prado. DS Smith Viana kraftliner 440 kt. Pulp at Altri (Celbi, Biotek, Caima). GCC at Omya Mineral Portuguesa (100 kt), PCC-grade lime at Microlime and Calcidrata.$cm$,
   $cm${"fillers": "Satellite PCC: SMI at Navigator Figueira, Omya at Navigator Setúbal. GCC: Omya Mineral Portuguesa (Perulheira, 100 kt). Lime: Microlime, Calcidrata. Not added: LDM / BIOCAL, Lhoist.", "mills": "UWF: Navigator Figueira da Foz and Setúbal. Tissue: Fortissue, Fapajal, Renova, Paper Prime, Navigator Ródão and Cacia. Board and specialty: Prado. Kraftliner: DS Smith Viana. Context: Coreboard, Ponte Redonda, Altri pulp.", "strategy": "Three-way trial Navigator + SMI + MBG at Figueira (copy paper 5-10-15 pct). Benchmark against Omya Multifill and FiberLean at Setúbal. Tissue trials at Fortissue and Fapajal.", "risks": "SMI and Omya control the satellites - need their consent, Omya competing tech.", "next_steps": ["Propose a Figueira three-way trial to Navigator and SMI"], "key_numbers": [{"label": "Navigator UWF", "value": "about 1.6 Mt/yr"}, {"label": "Satellite PCC 2005", "value": "3 units, 155-205 kt/yr"}, {"label": "Report scenario", "value": "78,750-157,500 t FCC (5-10 pct of UWF)"}], "files": ["seed_20261016zr_portugal_mills_fillers"]}$cm$::jsonb,
   $cm$Navigator UWF 160만 t(Figueira da Foz·Setúbal)와 SMI·Omya 위성 PCC — Fortissue·Fapajal·Renova 티슈$cm$,
   $cm$포르투갈 FCC 핵심은 Navigator: Figueira da Foz(UWF 80만 t, 1995년부터 SMI 위성 PCC)와 Setúbal(77.5만 t, Omya 위성 PCC), 합계 약 160만 t. 티슈 Fortissue(3.5만 t)·Fapajal·Renova·Paper Prime, 고평량지 Prado, DS Smith Viana 크라프트라이너 44만 t. 펄프 Altri. GCC Omya Mineral Portuguesa(10만 t), PCC 용 석회 Microlime·Calcidrata.$cm$,
   78750, 157500,
   $cm$Navigator UWF 157.5만 t × FCC 5~10% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('navigator.*figueira|soporcel', 'figueira', 'navigator|soporcel'),
  ('navigator.*set[uú]bal|portucel.*set[uú]bal', 'set[uú]bal', 'navigator|portucel'),
  ('fortissue', 'alvar[aã]es', 'fortissue'),
  ('fapajal', 'loures|tojal', 'fapajal'),
  ('renova', 'torres novas|zibreira', 'renova'),
  ('prado|cartolinas da lous', 'lous[aã]', 'prado'),
  ('paper prime', 'r[oó]d[aã]o', 'paper prime'),
  ('ds smith.*viana|viana paper', 'viana', 'ds smith'),
  ('navigator.*(cacia|aveiro)', null, 'navigator.*(cacia|aveiro)'),
  ('navigator.*r[oó]d[aã]o', null, 'navigator.*r[oó]d[aã]o'),
  ('coreboard', null, 'coreboard'),
  ('ponte redonda', null, 'ponte redonda'),
  ('\mcelbi\M|biotek', null, '\mcelbi\M|biotek'),
  ('\mcaima\M', null, '\mcaima\M')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'portugal_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'portugal_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*(portug|figueira)' or p.party_name ~* 'omya.*set[uú]bal' or p.party_name ~* 'omya mineral portuguesa' or p.party_name ~* 'microlime' or p.party_name ~* 'calcidrata')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'PT'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'PT'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'PT'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PT'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    