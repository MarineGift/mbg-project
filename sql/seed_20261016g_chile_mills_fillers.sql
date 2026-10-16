-- ============================================================
-- seed_20261016g_chile_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Chile update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'CL check 2026-10-15'.
-- 1) Fillers if missing (3): Calidra Chile Noviciado, Carbonatos SGI,
--    IM Minerals. Distributors not added.
-- 2) Mills if missing (10) + plant blocks, priority 1-7: FPC Tissue, Softys
--    Talagante and Puente Alto, CMPC Boxboard Maule and Valdivia, FPC Papeles,
--    Coipsa CPP and Papelera Dos, CMPC Papeles Cordillera (sale pending),
--    CMPC Laja (no priority). Context: CMPC Santa Fe and Pacífico, Arauco,
--    Corrupac.
-- 3) app.country_markets CL row (priority high).
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
           v.party_name, 'CL', v.region, v.city, v.website, 'active', 'chile_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calidra.*(chile|noviciado)', 'Calidra Chile - Noviciado (Lampa)', 'Santiago Metropolitan', 'Lampa', null, 'Grupo Calidra 칠레 Noviciado(Lampa) 산업시설(석회 저장 3.5만 t). SEA 문서에 천연 탄산칼슘 파쇄·분쇄·분급 설비. 제지용 GCC(Fillpack)·PCC(Opacifill) 공급 명시.', 'Grupo Calidra Chile - Noviciado industrial site, Lampa (35,000 t lime storage), SEA environmental file lists crushing, grinding and classifying of natural calcium carbonate. Calidra states it supplies Chilean pulp and paper with GCC (Fillpack) and PCC (Opacifill).', 'CL check 2026-10-15: Opacifill PCC may be made at the Argentine Los Berros / La Laja plants - Chilean PCC making not confirmed. Mill volumes not public. FCC licence candidate 1.'),
  ('carbonatos sgi', 'Carbonatos SGI', 'Valparaíso', 'Nogales', null, 'Nogales(Valparaíso) 탄산칼슘 가공업체(CaCO3 90% 이상). 월 500 t → 2025-11 월 6,000 t 확대 계획.', 'Carbonatos SGI Ltda., Nogales, Valparaíso Region - ground calcium carbonate (over 90 pct CaCO3), expansion planned, 500 t/month rising to 6,000 t/month (2025-11).', 'CL check 2026-10-15: current output and paper grades not confirmed.'),
  ('im minerals', 'IM Minerals', 'Coquimbo', 'La Serena', null, 'La Serena(Coquimbo) 비금속 광물 가공 — 탄산칼슘·백운석·황산칼슘.', 'IM Minerals, La Serena, Coquimbo Region - non-metallic mineral processing: calcium carbonate, dolomite, calcium sulphate.', 'CL check 2026-10-15: paper grades not confirmed. ventas@imminerals.cl, +56 51 248 0904. Not added: Top Química Chile (supplier, own plant unknown), Barahona (CALPREC PCC distributor), CCI S.A. (distributor), Omya (no Chilean plant found).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CL check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calidra.*(chile|noviciado)', 'Calidra Chile - Noviciado (Lampa)', 'Santiago Metropolitan', 'Lampa', null, 'Grupo Calidra 칠레 Noviciado(Lampa) 산업시설(석회 저장 3.5만 t). SEA 문서에 천연 탄산칼슘 파쇄·분쇄·분급 설비. 제지용 GCC(Fillpack)·PCC(Opacifill) 공급 명시.', 'Grupo Calidra Chile - Noviciado industrial site, Lampa (35,000 t lime storage), SEA environmental file lists crushing, grinding and classifying of natural calcium carbonate. Calidra states it supplies Chilean pulp and paper with GCC (Fillpack) and PCC (Opacifill).', 'CL check 2026-10-15: Opacifill PCC may be made at the Argentine Los Berros / La Laja plants - Chilean PCC making not confirmed. Mill volumes not public. FCC licence candidate 1.'),
  ('carbonatos sgi', 'Carbonatos SGI', 'Valparaíso', 'Nogales', null, 'Nogales(Valparaíso) 탄산칼슘 가공업체(CaCO3 90% 이상). 월 500 t → 2025-11 월 6,000 t 확대 계획.', 'Carbonatos SGI Ltda., Nogales, Valparaíso Region - ground calcium carbonate (over 90 pct CaCO3), expansion planned, 500 t/month rising to 6,000 t/month (2025-11).', 'CL check 2026-10-15: current output and paper grades not confirmed.'),
  ('im minerals', 'IM Minerals', 'Coquimbo', 'La Serena', null, 'La Serena(Coquimbo) 비금속 광물 가공 — 탄산칼슘·백운석·황산칼슘.', 'IM Minerals, La Serena, Coquimbo Region - non-metallic mineral processing: calcium carbonate, dolomite, calcium sulphate.', 'CL check 2026-10-15: paper grades not confirmed. ventas@imminerals.cl, +56 51 248 0904. Not added: Top Química Chile (supplier, own plant unknown), Barahona (CALPREC PCC distributor), CCI S.A. (distributor), Omya (no Chilean plant found).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'chile_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calidra Chile - Noviciado (Lampa)', 'GCC and PCC supplier', 'Paper GCC and PCC - FCC licence candidate 1', 'merchant', 'B', 'gcc'),
  ('Carbonatos SGI', 'GCC producer', 'Local GCC grinder', 'merchant', 'C', 'gcc'),
  ('IM Minerals', 'GCC producer', 'Mineral processor - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'chile_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CL', v.region, v.city, v.website, 'active', 'chile_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('fpc tissue|forestal y papelera concepci[oó]n.*tissue', 'coronel', 'fpc.*tissue', 'FPC Tissue - Coronel', 'Biobío', 'Coronel', null, 'Coronel(Escuadrón II, Km 17.5)의 100% 버진 펄프 티슈 원지 제조사. Valmet Advantage NTT 구조화 티슈, 소비자 브랜드 + 점보롤 B2B 공급.', 'FPC Tissue (Forestal y Papelera Concepción), Parque Industrial Escuadrón II, Km 17.5, Coronel - tissue base paper on 100 pct virgin pulp, Valmet Advantage NTT textured tissue (unique in South America), own brands plus jumbo rolls for converters.', 'CL check 2026-10-15: capacity not public. contacto@fpc.cl.'),
  ('softys.*talagante', 'talagante', 'softys|cmpc', 'Softys - Talagante', 'Santiago Metropolitan', 'Talagante', null, 'CMPC 티슈 사업부 Softys 칠레 Talagante 공장. Softys 칠레 티슈 능력 합계 24.5만 t(2024 말).', 'Softys (CMPC tissue division) - Talagante tissue mill, Chile. Softys Chile tissue capacity totals 245,000 t/yr (CMPC, end 2024) across its Chilean mills.', 'CL check 2026-10-15: site split of the 245 kt not public.'),
  ('softys.*puente alto', 'puente alto', 'softys', 'Softys - Puente Alto', 'Santiago Metropolitan', 'Puente Alto', null, 'Softys 칠레 Puente Alto 티슈 제조·가공 공장.', 'Softys (CMPC) - Puente Alto tissue making and converting site, Chile.', 'CL check 2026-10-15: capacity included in the Softys Chile 245 kt total (on the Talagante row).'),
  ('boxboard.*maule|cmpc.*maule', 'maule|yerbas buenas', 'boxboard|cmpc|cartulinas', 'CMPC Boxboard - Maule', 'Maule', 'Maule', null, 'CMPC Boxboard(1951~) Maule 공장. 포장용 백판지·접이식 상자용 판지, Maule+Valdivia 합계 연 52만 t, 약 85% 45개국+ 수출.', 'CMPC Boxboard (Cartulinas CMPC, since 1951) - Maule mill: folding boxboard and white-lined board. Maule plus Valdivia total 520,000 t/yr (company), about 85 pct exported to over 45 countries.', 'CL check 2026-10-15: capacity split between Maule and Valdivia not public - the 520 kt total is kept on this row only.'),
  ('boxboard.*valdivia|cmpc.*valdivia', 'valdivia', 'boxboard|cmpc|cartulinas', 'CMPC Boxboard - Valdivia', 'Los Ríos', 'Valdivia', null, 'CMPC Boxboard Valdivia 고급 판지 공장.', 'CMPC Boxboard - Valdivia mill: premium folding boxboard.', 'CL check 2026-10-15: capacity within the 520 kt total on the Maule row.'),
  ('fpc papeles|papelera concepci[oó]n.*(liner|papeles)', 'coronel', 'fpc papeles', 'FPC Papeles - Coronel', 'Biobío', 'Coronel', null, 'FPC Papeles(Coronel) — 1995 신문·인쇄용지로 시작, 현재 100% 재생 테스트라이너·골심지(90~170 g/m²).', 'FPC Papeles, Coronel, Biobío - started 1995 on newsprint and printing paper, now testliner and fluting (Onda) on 100 pct recycled fibre, 90-170 g/m2.', 'CL check 2026-10-15: comercial@fpc.cl, +56 41 2885000. Capacity not public.'),
  ('papelera del pac[ií]fico.*(coipsa|chile)|compa[nñ][ií]a papelera del pac[ií]fico', 'san pedro de la paz', 'coipsa|papelera del pac', 'Compañía Papelera del Pacífico (Coipsa) - San Pedro de la Paz', 'Biobío', 'San Pedro de la Paz', null, 'Coipsa 그룹(Recupac 폐지·CPP 원지·Papelera Dos·Corrupac 상자)의 골판지 원지 공장 CPP.', 'Compañía Papelera del Pacífico (CPP, Coipsa group - Recupac collects waste paper, CPP and Papelera Dos make corrugating base paper, Corrupac makes boxes), San Pedro de la Paz per the Coipsa site.', 'CL check 2026-10-15: a 2026 competition filing places the CPP and Papelera Dos mills at San Francisco de Mostazal and San Pedro de la Paz - site mapping to confirm. Capacity not public.'),
  ('papelera dos', 'mostazal', 'papelera dos|coipsa', 'Papelera Dos (Coipsa) - San Francisco de Mostazal', 'O''Higgins', 'San Francisco de Mostazal', null, 'Coipsa 그룹 재생 골판지 원지 공장 Papelera Dos.', 'Papelera Dos (Coipsa group) - recycled corrugating base paper, San Francisco de Mostazal per the 2026 competition filing.', 'CL check 2026-10-15: site to confirm, capacity not public.'),
  ('papeles cordillera|cmpc.*cordillera', 'puente alto', 'cordillera', 'CMPC Papeles Cordillera - Puente Alto', 'Santiago Metropolitan', 'Puente Alto', null, 'CMPC Papeles Cordillera(Puente Alto) 골판지 원지·포장용지. 2026-09-23 칠레 골판지 사업을 Smurfit Westrock 에 4.2억 달러 매각 계약(승인 대기).', 'CMPC Papeles Cordillera, Puente Alto - corrugating base paper and packaging paper (CMPC Chile corrugating base paper 252,000 t/yr, end 2024). 2026-09-23: CMPC agreed to sell its Chilean corrugated business, incl. Puente Alto papermaking, to Smurfit Westrock for USD 420 m - subject to competition approval.', 'CL check 2026-10-15: ownership change not complete - buyer side may decide later.'),
  ('cmpc.*laja', 'laja', 'cmpc', 'CMPC - Laja', 'Biobío', 'Laja', null, 'CMPC Laja 침엽수 펄프 + 크라프트 종이(연 약 7만 t, sack kraft).', 'CMPC Laja, Biobío - softwood pulp and kraft paper, about 70,000 t/yr paper (sack kraft).', 'CL check 2026-10-15: paper line is sack kraft - strength-critical.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CL check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fpc tissue|forestal y papelera concepci[oó]n.*tissue', 'coronel', 'fpc.*tissue', 'Coronel(Escuadrón II, Km 17.5)의 100% 버진 펄프 티슈 원지 제조사. Valmet Advantage NTT 구조화 티슈, 소비자 브랜드 + 점보롤 B2B 공급.', 'FPC Tissue (Forestal y Papelera Concepción), Parque Industrial Escuadrón II, Km 17.5, Coronel - tissue base paper on 100 pct virgin pulp, Valmet Advantage NTT textured tissue (unique in South America), own brands plus jumbo rolls for converters.', 'CL check 2026-10-15: capacity not public. contacto@fpc.cl.'),
  ('softys.*talagante', 'talagante', 'softys|cmpc', 'CMPC 티슈 사업부 Softys 칠레 Talagante 공장. Softys 칠레 티슈 능력 합계 24.5만 t(2024 말).', 'Softys (CMPC tissue division) - Talagante tissue mill, Chile. Softys Chile tissue capacity totals 245,000 t/yr (CMPC, end 2024) across its Chilean mills.', 'CL check 2026-10-15: site split of the 245 kt not public.'),
  ('softys.*puente alto', 'puente alto', 'softys', 'Softys 칠레 Puente Alto 티슈 제조·가공 공장.', 'Softys (CMPC) - Puente Alto tissue making and converting site, Chile.', 'CL check 2026-10-15: capacity included in the Softys Chile 245 kt total (on the Talagante row).'),
  ('boxboard.*maule|cmpc.*maule', 'maule|yerbas buenas', 'boxboard|cmpc|cartulinas', 'CMPC Boxboard(1951~) Maule 공장. 포장용 백판지·접이식 상자용 판지, Maule+Valdivia 합계 연 52만 t, 약 85% 45개국+ 수출.', 'CMPC Boxboard (Cartulinas CMPC, since 1951) - Maule mill: folding boxboard and white-lined board. Maule plus Valdivia total 520,000 t/yr (company), about 85 pct exported to over 45 countries.', 'CL check 2026-10-15: capacity split between Maule and Valdivia not public - the 520 kt total is kept on this row only.'),
  ('boxboard.*valdivia|cmpc.*valdivia', 'valdivia', 'boxboard|cmpc|cartulinas', 'CMPC Boxboard Valdivia 고급 판지 공장.', 'CMPC Boxboard - Valdivia mill: premium folding boxboard.', 'CL check 2026-10-15: capacity within the 520 kt total on the Maule row.'),
  ('fpc papeles|papelera concepci[oó]n.*(liner|papeles)', 'coronel', 'fpc papeles', 'FPC Papeles(Coronel) — 1995 신문·인쇄용지로 시작, 현재 100% 재생 테스트라이너·골심지(90~170 g/m²).', 'FPC Papeles, Coronel, Biobío - started 1995 on newsprint and printing paper, now testliner and fluting (Onda) on 100 pct recycled fibre, 90-170 g/m2.', 'CL check 2026-10-15: comercial@fpc.cl, +56 41 2885000. Capacity not public.'),
  ('papelera del pac[ií]fico.*(coipsa|chile)|compa[nñ][ií]a papelera del pac[ií]fico', 'san pedro de la paz', 'coipsa|papelera del pac', 'Coipsa 그룹(Recupac 폐지·CPP 원지·Papelera Dos·Corrupac 상자)의 골판지 원지 공장 CPP.', 'Compañía Papelera del Pacífico (CPP, Coipsa group - Recupac collects waste paper, CPP and Papelera Dos make corrugating base paper, Corrupac makes boxes), San Pedro de la Paz per the Coipsa site.', 'CL check 2026-10-15: a 2026 competition filing places the CPP and Papelera Dos mills at San Francisco de Mostazal and San Pedro de la Paz - site mapping to confirm. Capacity not public.'),
  ('papelera dos', 'mostazal', 'papelera dos|coipsa', 'Coipsa 그룹 재생 골판지 원지 공장 Papelera Dos.', 'Papelera Dos (Coipsa group) - recycled corrugating base paper, San Francisco de Mostazal per the 2026 competition filing.', 'CL check 2026-10-15: site to confirm, capacity not public.'),
  ('papeles cordillera|cmpc.*cordillera', 'puente alto', 'cordillera', 'CMPC Papeles Cordillera(Puente Alto) 골판지 원지·포장용지. 2026-09-23 칠레 골판지 사업을 Smurfit Westrock 에 4.2억 달러 매각 계약(승인 대기).', 'CMPC Papeles Cordillera, Puente Alto - corrugating base paper and packaging paper (CMPC Chile corrugating base paper 252,000 t/yr, end 2024). 2026-09-23: CMPC agreed to sell its Chilean corrugated business, incl. Puente Alto papermaking, to Smurfit Westrock for USD 420 m - subject to competition approval.', 'CL check 2026-10-15: ownership change not complete - buyer side may decide later.'),
  ('cmpc.*laja', 'laja', 'cmpc', 'CMPC Laja 침엽수 펄프 + 크라프트 종이(연 약 7만 t, sack kraft).', 'CMPC Laja, Biobío - softwood pulp and kraft paper, about 70,000 t/yr paper (sack kraft).', 'CL check 2026-10-15: paper line is sack kraft - strength-critical.'),
  ('cmpc.*santa fe', null, 'cmpc.*santa fe', null, null, 'CL check 2026-10-15: Santa Fe, Nacimiento - eucalyptus bleached kraft pulp - context only.'),
  ('cmpc.*pac[ií]fico|pac[ií]fico.*mininco', null, 'cmpc.*pac[ií]fico|pac[ií]fico.*mininco', null, null, 'CL check 2026-10-15: Pacífico, Mininco - softwood bleached kraft pulp - context only.'),
  ('arauco', null, 'arauco', null, null, 'CL check 2026-10-15: Chilean pulp mills (4), Valdivia 550 kt dissolving pulp - pulp only - context only.'),
  ('corrupac', null, 'corrupac', null, null, 'CL check 2026-10-15: Corrugated boxes - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'chile_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fpc tissue|forestal y papelera concepci[oó]n.*tissue', 'coronel', 'fpc.*tissue'),
  ('softys.*talagante', 'talagante', 'softys|cmpc'),
  ('softys.*puente alto', 'puente alto', 'softys'),
  ('boxboard.*maule|cmpc.*maule', 'maule|yerbas buenas', 'boxboard|cmpc|cartulinas'),
  ('boxboard.*valdivia|cmpc.*valdivia', 'valdivia', 'boxboard|cmpc|cartulinas'),
  ('fpc papeles|papelera concepci[oó]n.*(liner|papeles)', 'coronel', 'fpc papeles'),
  ('papelera del pac[ií]fico.*(coipsa|chile)|compa[nñ][ií]a papelera del pac[ií]fico', 'san pedro de la paz', 'coipsa|papelera del pac'),
  ('papelera dos', 'mostazal', 'papelera dos|coipsa'),
  ('papeles cordillera|cmpc.*cordillera', 'puente alto', 'cordillera'),
  ('cmpc.*laja', 'laja', 'cmpc'),
  ('cmpc.*santa fe', null, 'cmpc.*santa fe'),
  ('cmpc.*pac[ií]fico|pac[ií]fico.*mininco', null, 'cmpc.*pac[ií]fico|pac[ií]fico.*mininco'),
  ('arauco', null, 'arauco'),
  ('corrupac', null, 'corrupac')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('fpc tissue|forestal y papelera concepci[oó]n.*tissue', 'coronel', 'fpc.*tissue',
   $pj${"owner": "FPC (Forestal y Papelera Concepción)", "priority": 1, "products": "Textured tissue base paper, jumbo rolls", "grades": ["Tissue"], "pitch": "Virgin-pulp saving at equal bulk and softness on NTT", "approach": "Independent - FCC 3-5 pct trial, check retention and forming on NTT.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys.*talagante', 'talagante', 'softys|cmpc',
   $pj${"owner": "Softys (CMPC)", "priority": 2, "products": "Toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "pitch": "Tissue FCC 3-5 pct", "approach": "Approach Softys tissue technical centrally - links to Uruguay and Argentina.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15", "capacity_split": [{"label": "Softys Chile total (all sites)", "value_t": 245000}]}$pj$::jsonb),
  ('softys.*puente alto', 'puente alto', 'softys',
   $pj${"owner": "Softys (CMPC)", "priority": 3, "products": "Toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "pitch": "Tissue FCC 3-5 pct", "approach": "Second Softys Chile trial site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('boxboard.*maule|cmpc.*maule', 'maule|yerbas buenas', 'boxboard|cmpc|cartulinas',
   $pj${"owner": "CMPC", "priority": 4, "products": "Folding boxboard", "grades": ["Folding boxboard"], "capacity_split": [{"label": "Maule + Valdivia total", "value_t": 520000}], "pitch": "Ply-level FCC (3-10 pct) for fibre saving, opacity, bulk, stiffness", "approach": "Get ply furnish first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('boxboard.*valdivia|cmpc.*valdivia', 'valdivia', 'boxboard|cmpc|cartulinas',
   $pj${"owner": "CMPC", "priority": 5, "products": "Folding boxboard", "grades": ["Folding boxboard"], "approach": "Opacity and stiffness trial after Maule.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('fpc papeles|papelera concepci[oó]n.*(liner|papeles)', 'coronel', 'fpc papeles',
   $pj${"owner": "FPC (Forestal y Papelera Concepción)", "priority": 6, "products": "Recycled testliner, fluting", "grades": ["Testliner", "Medium"], "approach": "Strength-hold trial (SCT, CMT, burst).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera del pac[ií]fico.*(coipsa|chile)|compa[nñ][ií]a papelera del pac[ií]fico', 'san pedro de la paz', 'coipsa|papelera del pac',
   $pj${"owner": "Coipsa", "priority": 7, "products": "Recycled corrugating base paper", "grades": ["Testliner", "Medium"], "approach": "SCT and CMT trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera dos', 'mostazal', 'papelera dos|coipsa',
   $pj${"owner": "Coipsa", "priority": 7, "products": "Recycled corrugating base paper", "grades": ["Medium"], "approach": "SCT and CMT trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeles cordillera|cmpc.*cordillera', 'puente alto', 'cordillera',
   $pj${"owner": "CMPC (sale to Smurfit Westrock pending)", "priority": 7, "products": "Corrugating base paper", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "CMPC Chile corrugating base paper (end 2024)", "value_t": 252000}], "approach": "Track the Smurfit Westrock deal - strength-led packaging only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cmpc.*laja', 'laja', 'cmpc',
   $pj${"owner": "CMPC", "products": "Sack kraft paper, softwood pulp", "grades": ["Sack kraft"], "capacity": {"value": 70000, "unit": "metric_t", "year": "CMPC data", "source": "cmpc.com"}, "approach": "Low priority - strength-critical.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cmpc.*santa fe', null, 'cmpc.*santa fe',
   $pj${"owner": "CMPC Pulp", "products": "Santa Fe, Nacimiento - eucalyptus bleached kraft pulp", "approach": "Pulp or converter - not a direct FCC customer.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cmpc.*pac[ií]fico|pac[ií]fico.*mininco', null, 'cmpc.*pac[ií]fico|pac[ií]fico.*mininco',
   $pj${"owner": "CMPC Pulp", "products": "Pacífico, Mininco - softwood bleached kraft pulp", "approach": "Pulp or converter - not a direct FCC customer.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('arauco', null, 'arauco',
   $pj${"owner": "Arauco", "products": "Chilean pulp mills (4), Valdivia 550 kt dissolving pulp - pulp only", "approach": "Pulp or converter - not a direct FCC customer.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corrupac', null, 'corrupac',
   $pj${"owner": "Corrupac (Coipsa)", "products": "Corrugated boxes - converter", "approach": "Pulp or converter - not a direct FCC customer.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CL', 'Chile', 'high',
   $cm$Softys and FPC tissue plus CMPC Boxboard (520 kt) - Calidra supplies paper GCC and PCC$cm$,
   $cm$Calidra supplies Chilean paper with GCC (Fillpack, Noviciado) and PCC (Opacifill, possibly made at its Argentine plants). Local GCC: Carbonatos SGI, IM Minerals. Paper: Softys tissue (245 kt in Chile), FPC Tissue (Coronel, NTT, virgin pulp), CMPC Boxboard Maule and Valdivia (520 kt), corrugating base paper at FPC Papeles, Coipsa (CPP, Papelera Dos) and CMPC Papeles Cordillera - the last being sold to Smurfit Westrock (USD 420 m, 2026-09, approval pending). CMPC and Arauco pulp mills are not FCC customers.$cm$,
   $cm${"fillers": "Calidra Chile (Noviciado GCC, Opacifill PCC), Carbonatos SGI (Nogales, 6,000 t/month plan), IM Minerals (La Serena). Distributors not added: Top Química, Barahona (CALPREC), CCI. Omya has no Chilean plant found.", "mills": "Tissue: FPC Tissue Coronel, Softys Talagante and Puente Alto (245 kt total). Board: CMPC Boxboard Maule and Valdivia (520 kt). Packaging: FPC Papeles Coronel, Coipsa CPP and Papelera Dos, CMPC Papeles Cordillera Puente Alto (252 kt, sale pending), CMPC Laja sack kraft (70 kt). Pulp only: CMPC Santa Fe and Pacífico, Arauco.", "strategy": "FPC Tissue and Softys tissue trials first, CMPC Boxboard ply-level next. Calidra as FCC licence candidate - pairs with the Argentine Calidra PCC plants.", "risks": "Packaging strength limits. Ownership change at Papeles Cordillera.", "next_steps": ["Propose an NTT tissue trial to FPC Tissue", "Ask Calidra which plant makes the Chilean Opacifill PCC"], "key_numbers": [{"label": "CMPC Chile capacity end 2024", "value": "tissue 245 kt, board 500 kt, corrugating base paper 252 kt, sack kraft 70 kt"}, {"label": "CMPC corrugated sale", "value": "USD 420 m to Smurfit Westrock (2026-09)"}, {"label": "Report scenario", "value": "3,725 t FCC (10 pct of 745 kt x 5 pct)"}], "files": ["seed_20261016g_chile_mills_fillers"]}$cm$::jsonb,
   $cm$Softys·FPC 티슈 + CMPC Boxboard(52만 t) — Calidra 가 제지용 GCC·PCC 공급$cm$,
   $cm$Calidra 가 칠레 제지산업에 GCC(Fillpack, Noviciado)·PCC(Opacifill, 아르헨티나 공장 생산 가능성) 공급. 현지 GCC: Carbonatos SGI·IM Minerals. 제지: Softys 티슈(칠레 24.5만 t), FPC Tissue(Coronel, NTT), CMPC Boxboard Maule·Valdivia(52만 t), 골판지 원지 FPC Papeles·Coipsa·CMPC Papeles Cordillera(Smurfit Westrock 매각 계약 2026-09). CMPC·Arauco 펄프공장은 FCC 직접 고객 아님.$cm$,
   3725, 7450,
   $cm$CMPC 칠레 티슈+판지 74.5만 t × 적용 10~20% × FCC 5% (보고서 시나리오)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('fpc tissue|forestal y papelera concepci[oó]n.*tissue', 'coronel', 'fpc.*tissue'),
  ('softys.*talagante', 'talagante', 'softys|cmpc'),
  ('softys.*puente alto', 'puente alto', 'softys'),
  ('boxboard.*maule|cmpc.*maule', 'maule|yerbas buenas', 'boxboard|cmpc|cartulinas'),
  ('boxboard.*valdivia|cmpc.*valdivia', 'valdivia', 'boxboard|cmpc|cartulinas'),
  ('fpc papeles|papelera concepci[oó]n.*(liner|papeles)', 'coronel', 'fpc papeles'),
  ('papelera del pac[ií]fico.*(coipsa|chile)|compa[nñ][ií]a papelera del pac[ií]fico', 'san pedro de la paz', 'coipsa|papelera del pac'),
  ('papelera dos', 'mostazal', 'papelera dos|coipsa'),
  ('papeles cordillera|cmpc.*cordillera', 'puente alto', 'cordillera'),
  ('cmpc.*laja', 'laja', 'cmpc'),
  ('cmpc.*santa fe', null, 'cmpc.*santa fe'),
  ('cmpc.*pac[ií]fico|pac[ií]fico.*mininco', null, 'cmpc.*pac[ií]fico|pac[ií]fico.*mininco'),
  ('arauco', null, 'arauco'),
  ('corrupac', null, 'corrupac')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'chile_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'chile_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calidra.*(chile|noviciado)' or p.party_name ~* 'carbonatos sgi' or p.party_name ~* 'im minerals')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CL'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CL'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CL'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CL'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    