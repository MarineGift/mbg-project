-- ============================================================
-- seed_20261016c_uruguay_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Uruguay update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'UY check 2026-10-15'.
-- 1) Fillers if missing (3): CYCUSA, DARSA, Compañía Oriental de Minerales.
-- 2) Mills if missing (3) + plant blocks, priority 1-3: Softys Uruguay
--    (IPUSA) Pando, Amberplan Montevideo, PAMER Mercedes.
--    Context, match only (4): UPM Fray Bentos, UPM Paso de los Toros,
--    Montes del Plata (pulp only), FANAPEL (closed 2017).
-- 3) app.country_markets UY row (priority medium).
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
           v.party_name, 'UY', v.region, v.city, v.website, 'active', 'uruguay_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cycusa', 'CYCUSA', 'Lavalleja', 'Minas', null, '우루과이 석회·탄산칼슘 제조사. Minas·Montevideo 공장, 탄산칼슘·미분화 탄산칼슘(Carbonato Micronizado)·생석회·소석회. 자체 광상 평균 CaCO3 95.8%, 매장량 약 1,100만 t. 제지·펄프용 석회(PCC 원료) 명시.', 'CYCUSA - lime and calcium carbonate maker with plants at Av. Gral. Flores 1686, Minas (Lavalleja) and Cno. Corrales 3626, Montevideo: calcium carbonate, micronised carbonate, quicklime and hydrated lime. Own deposit averages 95.8 pct CaCO3, about 11 Mt proven reserves. Lime named for PCC making and kraft pulping.', 'UY check 2026-10-15: paper-grade GCC supply and slurry not confirmed - FCC producer candidate 1. Minas +598 44 423 335, plantaminas@cycusa.com.uy, Montevideo +598 2514 5331.'),
  ('\mdarsa\M', 'DARSA', null, null, null, '1962년부터 광물 채굴·가공 업체. 석회석 분쇄 #10~#635, 돌로마이트(액상 D98 22 μm), 활석·카올린.', 'DARSA (since 1962) - mining and micronising: ground limestone #10 to #635, dolomite powder and liquid (D98 22 micron and finer), talc and kaolin, for industry, agriculture and feed.', 'UY check 2026-10-15: paper-grade purity, brightness and fineness not confirmed. Plant address to confirm. Grinding pilot partner candidate.'),
  ('oriental de minerales', 'Compañía Oriental de Minerales', null, null, null, '1937년부터 탄산칼슘 생산, 자체 석회석 광상. 사료·농업용(2 mm 통과).', 'Compañía Oriental de Minerales S.A. (since 1937) - own limestone deposit, natural calcium carbonate for feed and agriculture (100 pct under 2 mm), dolomitic carbonate.', 'UY check 2026-10-15: far coarser than paper filler - raw-material source. Not added: Calera Carapé (lime kilns, Minas), Omya (sells in Uruguay, no local plant found), Droguería Uruguayana (PCC reseller).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%UY check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cycusa', 'CYCUSA', 'Lavalleja', 'Minas', null, '우루과이 석회·탄산칼슘 제조사. Minas·Montevideo 공장, 탄산칼슘·미분화 탄산칼슘(Carbonato Micronizado)·생석회·소석회. 자체 광상 평균 CaCO3 95.8%, 매장량 약 1,100만 t. 제지·펄프용 석회(PCC 원료) 명시.', 'CYCUSA - lime and calcium carbonate maker with plants at Av. Gral. Flores 1686, Minas (Lavalleja) and Cno. Corrales 3626, Montevideo: calcium carbonate, micronised carbonate, quicklime and hydrated lime. Own deposit averages 95.8 pct CaCO3, about 11 Mt proven reserves. Lime named for PCC making and kraft pulping.', 'UY check 2026-10-15: paper-grade GCC supply and slurry not confirmed - FCC producer candidate 1. Minas +598 44 423 335, plantaminas@cycusa.com.uy, Montevideo +598 2514 5331.'),
  ('\mdarsa\M', 'DARSA', null, null, null, '1962년부터 광물 채굴·가공 업체. 석회석 분쇄 #10~#635, 돌로마이트(액상 D98 22 μm), 활석·카올린.', 'DARSA (since 1962) - mining and micronising: ground limestone #10 to #635, dolomite powder and liquid (D98 22 micron and finer), talc and kaolin, for industry, agriculture and feed.', 'UY check 2026-10-15: paper-grade purity, brightness and fineness not confirmed. Plant address to confirm. Grinding pilot partner candidate.'),
  ('oriental de minerales', 'Compañía Oriental de Minerales', null, null, null, '1937년부터 탄산칼슘 생산, 자체 석회석 광상. 사료·농업용(2 mm 통과).', 'Compañía Oriental de Minerales S.A. (since 1937) - own limestone deposit, natural calcium carbonate for feed and agriculture (100 pct under 2 mm), dolomitic carbonate.', 'UY check 2026-10-15: far coarser than paper filler - raw-material source. Not added: Calera Carapé (lime kilns, Minas), Omya (sells in Uruguay, no local plant found), Droguería Uruguayana (PCC reseller).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'uruguay_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CYCUSA', 'GCC and lime producer', 'Local GCC and lime - FCC producer candidate 1', 'merchant', 'C', 'gcc'),
  ('DARSA', 'GCC producer', 'Micronised minerals - pilot partner candidate', 'merchant', 'C', 'gcc'),
  ('Compañía Oriental de Minerales', 'Carbonate raw material', 'Raw-material source only', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'uruguay_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'UY', v.region, v.city, v.website, 'active', 'uruguay_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('softys.*uruguay|\mipusa\M|industria papelera uruguaya', 'pando', 'softys|ipusa|cmpc', 'Softys Uruguay (IPUSA) - Pando', 'Canelones', 'Pando', null, 'IPUSA(1937, 1994 CMPC 인수) — Softys 우루과이 티슈 공장(Pando). 초지·가공·위생용품·폐수처리, 화장지 Higienol·Noble, 타월·냅킨 Nova. 2011년 연 2.27만 t 티슈기 설치.', 'Softys Uruguay - IPUSA (Industria Papelera Uruguaya, 1937, CMPC since 1994), Pando, Canelones: tissue machine, converting, personal care and effluent treatment. Brands Higienol, Noble (toilet tissue), Nova (towels, napkins). A 22,700 t/yr tissue machine was installed in 2011. Made-in-Uruguay certification 2025, tissue exports to Texas.', 'UY check 2026-10-15: 22.7 kt is the 2011 machine only - site total not public.'),
  ('amberplan', 'montevideo', 'amberplan', 'Amberplan - Montevideo', 'Montevideo', 'Montevideo', null, '2020년 설립 티슈 기업(Montevideo). 가공 월 400 t, 2024 자체 초지기 계획(1단계 월 1,000 t, 최종 월 4,000 t). 브랜드 Celeste·Sak, OEM.', 'Amberplan, Av. José Belloni 6775, Montevideo (founded 2020) - tissue converting about 400 t/month, own tissue machine announced 2024: phase 1 1,000 t/month (12,000 t/yr, start targeted 2024-12), final target 4,000 t/month (48,000 t/yr). Brands Celeste and Sak, private label. USD 32 m investment.', 'UY check 2026-10-15: machine start-up and later phases not confirmed. info@amberplantissue.com, +598 2512 8602.'),
  ('\mpamer\M|papelera mercedes', 'mercedes', 'pamer|papelera mercedes', 'PAMER (Papelera Mercedes) - Mercedes', 'Soriano', 'Mercedes', null, '1937년 설립 우루과이 최대 골판지 기업(Mercedes). OCC 재생섬유로 골판지 원지 자체 생산 후 시트·상자 제조.', 'PAMER - Papelera Mercedes S.A., Ejido de Chacra s/n, Mercedes, Soriano (1937) - largest Uruguayan corrugated maker, makes its own corrugating paper on recycled OCC and converts it to sheets and boxes.', 'UY check 2026-10-15: machine capacity not public.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%UY check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('softys.*uruguay|\mipusa\M|industria papelera uruguaya', 'pando', 'softys|ipusa|cmpc', 'IPUSA(1937, 1994 CMPC 인수) — Softys 우루과이 티슈 공장(Pando). 초지·가공·위생용품·폐수처리, 화장지 Higienol·Noble, 타월·냅킨 Nova. 2011년 연 2.27만 t 티슈기 설치.', 'Softys Uruguay - IPUSA (Industria Papelera Uruguaya, 1937, CMPC since 1994), Pando, Canelones: tissue machine, converting, personal care and effluent treatment. Brands Higienol, Noble (toilet tissue), Nova (towels, napkins). A 22,700 t/yr tissue machine was installed in 2011. Made-in-Uruguay certification 2025, tissue exports to Texas.', 'UY check 2026-10-15: 22.7 kt is the 2011 machine only - site total not public.'),
  ('amberplan', 'montevideo', 'amberplan', '2020년 설립 티슈 기업(Montevideo). 가공 월 400 t, 2024 자체 초지기 계획(1단계 월 1,000 t, 최종 월 4,000 t). 브랜드 Celeste·Sak, OEM.', 'Amberplan, Av. José Belloni 6775, Montevideo (founded 2020) - tissue converting about 400 t/month, own tissue machine announced 2024: phase 1 1,000 t/month (12,000 t/yr, start targeted 2024-12), final target 4,000 t/month (48,000 t/yr). Brands Celeste and Sak, private label. USD 32 m investment.', 'UY check 2026-10-15: machine start-up and later phases not confirmed. info@amberplantissue.com, +598 2512 8602.'),
  ('\mpamer\M|papelera mercedes', 'mercedes', 'pamer|papelera mercedes', '1937년 설립 우루과이 최대 골판지 기업(Mercedes). OCC 재생섬유로 골판지 원지 자체 생산 후 시트·상자 제조.', 'PAMER - Papelera Mercedes S.A., Ejido de Chacra s/n, Mercedes, Soriano (1937) - largest Uruguayan corrugated maker, makes its own corrugating paper on recycled OCC and converts it to sheets and boxes.', 'UY check 2026-10-15: machine capacity not public.'),
  ('upm.*fray bentos|fray bentos', null, 'upm.*fray bentos|fray bentos', null, null, 'UY check 2026-10-15: Fray Bentos bleached eucalyptus pulp, 1.3 Mt/yr (permit review to 1.5 Mt) - pulp only - not an FCC customer, context only.'),
  ('upm.*paso de los toros|paso de los toros', null, 'upm.*paso de los toros|paso de los toros', null, null, 'UY check 2026-10-15: Paso de los Toros (Centenario) bleached eucalyptus pulp, 2.1 Mt/yr, started 2023 - pulp only - not an FCC customer, context only.'),
  ('montes del plata', null, 'montes del plata', null, null, 'UY check 2026-10-15: Punta Pereira bleached eucalyptus kraft pulp, 1.4 Mt/yr, talc-free since 2026-08 - pulp only - not an FCC customer, context only.'),
  ('fanapel', null, 'fanapel', null, null, 'UY check 2026-10-15: Juan Lacaze printing and writing paper - closed 2017 - not an FCC customer, context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'uruguay_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('softys.*uruguay|\mipusa\M|industria papelera uruguaya', 'pando', 'softys|ipusa|cmpc'),
  ('amberplan', 'montevideo', 'amberplan'),
  ('\mpamer\M|papelera mercedes', 'mercedes', 'pamer|papelera mercedes'),
  ('upm.*fray bentos|fray bentos', null, 'upm.*fray bentos|fray bentos'),
  ('upm.*paso de los toros|paso de los toros', null, 'upm.*paso de los toros|paso de los toros'),
  ('montes del plata', null, 'montes del plata'),
  ('fanapel', null, 'fanapel')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('softys.*uruguay|\mipusa\M|industria papelera uruguaya', 'pando', 'softys|ipusa|cmpc',
   $pj${"owner": "Softys (CMPC)", "priority": 1, "products": "Toilet tissue, towels, napkins", "grades": ["Tissue"], "capacity": {"value": 22700, "unit": "metric_t", "year": "2011 tissue machine only", "source": "press 2011"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct of the 2011 machine - planning only."}, "pitch": "Tissue FCC trial with a path to other Softys mills (Chile, Argentina, Brazil, Mexico)", "approach": "Technical meeting and machine trial at Pando - tensile, softness, absorbency, wet strength, retention.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('amberplan', 'montevideo', 'amberplan',
   $pj${"owner": "Amberplan", "priority": 2, "products": "Toilet tissue, tissue products", "grades": ["Tissue"], "capacity": {"value": 12000, "unit": "metric_t", "year": "Phase 1 plan (2024 announcement)", "source": "amberplan.uy"}, "capacity_split": [{"label": "Phase 1 plan", "value_t": 12000}, {"label": "Final target", "value_t": 48000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct of phase 1 - planning only."}, "pitch": "Include FCC dosing in the new tissue machine", "approach": "Independent, new machine - confirm start-up, then trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mpamer\M|papelera mercedes', 'mercedes', 'pamer|papelera mercedes',
   $pj${"owner": "PAMER", "priority": 3, "products": "Corrugating paper (recycled), sheets and boxes", "grades": ["Medium", "Testliner"], "approach": "Low-dose strength trial - SCT, RCT, CMT, burst, ply bond, starch, drainage.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('upm.*fray bentos|fray bentos', null, 'upm.*fray bentos|fray bentos',
   $pj${"owner": "UPM", "products": "Fray Bentos bleached eucalyptus pulp, 1.3 Mt/yr (permit review to 1.5 Mt) - pulp only", "approach": "Pulp supplier or closed - partner for pulp or mill introductions only.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('upm.*paso de los toros|paso de los toros', null, 'upm.*paso de los toros|paso de los toros',
   $pj${"owner": "UPM", "products": "Paso de los Toros (Centenario) bleached eucalyptus pulp, 2.1 Mt/yr, started 2023 - pulp only", "approach": "Pulp supplier or closed - partner for pulp or mill introductions only.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('montes del plata', null, 'montes del plata',
   $pj${"owner": "Montes del Plata (Stora Enso / Arauco)", "products": "Punta Pereira bleached eucalyptus kraft pulp, 1.4 Mt/yr, talc-free since 2026-08 - pulp only", "approach": "Pulp supplier or closed - partner for pulp or mill introductions only.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('fanapel', null, 'fanapel',
   $pj${"owner": "FANAPEL", "products": "Juan Lacaze printing and writing paper - closed 2017", "approach": "Pulp supplier or closed - partner for pulp or mill introductions only.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'UY', 'Uruguay', 'medium',
   $cm$Softys (IPUSA) and Amberplan tissue plus PAMER recycled medium - 4.8 Mt of pulp is export, not paper$cm$,
   $cm$Uruguay exports 4.8 Mt of eucalyptus pulp (UPM Fray Bentos 1.3 Mt, Paso de los Toros 2.1 Mt, Montes del Plata 1.4 Mt) but makes little paper. FCC customers: Softys Uruguay (IPUSA) tissue at Pando, Amberplan (new tissue machine, 12 kt phase 1, 48 kt target) and PAMER recycled corrugating paper at Mercedes. FANAPEL closed in 2017. Local carbonate: CYCUSA (micronised carbonate and lime, Minas and Montevideo), DARSA, Compañía Oriental de Minerales - no paper PCC plant.$cm$,
   $cm${"fillers": "CYCUSA (95.8 pct CaCO3 deposit, micronised carbonate, lime for PCC), DARSA (#10-#635 ground limestone), Compañía Oriental de Minerales (feed and agriculture). Not added: Calera Carapé (lime kilns), Omya (no local plant found), Droguería Uruguayana (reseller).", "mills": "Tissue: Softys Uruguay Pando (2011 machine 22.7 kt), Amberplan Montevideo (12 kt phase 1, 48 kt target). Packaging: PAMER Mercedes. Pulp only (context): UPM Fray Bentos, UPM Paso de los Toros, Montes del Plata. Closed: FANAPEL (2017).", "strategy": "Softys tissue trial first (path to other Softys mills), Amberplan new machine second. CYCUSA or DARSA as local licensed FCC producer.", "risks": "Small paper volumes, current tissue tonnage not public.", "next_steps": ["Meet Softys Uruguay technical staff", "Confirm Amberplan machine start-up"], "key_numbers": [{"label": "Pulp capacity", "value": "4.8 Mt/yr (UPM 3.4, Montes del Plata 1.4)"}, {"label": "Amberplan", "value": "12 kt phase 1, 48 kt target"}, {"label": "Report scenario", "value": "1,735-3,535 t FCC (5 pct)"}], "files": ["seed_20261016c_uruguay_mills_fillers"]}$cm$::jsonb,
   $cm$Softys(IPUSA)·Amberplan 티슈 + PAMER 재생 골심지 — 480만 t 펄프는 수출용$cm$,
   $cm$우루과이는 펄프 480만 t 수출국(UPM 340만·Montes del Plata 140만)이나 종이 생산은 소규모. FCC 고객은 Softys Uruguay(IPUSA) Pando 티슈, Amberplan(신규 티슈기 1단계 1.2만 t·최종 4.8만 t), PAMER Mercedes 재생 골심지. FANAPEL 2017 폐쇄. 현지 탄산칼슘은 CYCUSA·DARSA·Compañía Oriental — 제지용 PCC 없음.$cm$,
   1735, 3535,
   $cm$Softys 2011 설비 2.27만 t + Amberplan 1.2만~4.8만 t × FCC 5% (보고서 예시)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('softys.*uruguay|\mipusa\M|industria papelera uruguaya', 'pando', 'softys|ipusa|cmpc'),
  ('amberplan', 'montevideo', 'amberplan'),
  ('\mpamer\M|papelera mercedes', 'mercedes', 'pamer|papelera mercedes'),
  ('upm.*fray bentos|fray bentos', null, 'upm.*fray bentos|fray bentos'),
  ('upm.*paso de los toros|paso de los toros', null, 'upm.*paso de los toros|paso de los toros'),
  ('montes del plata', null, 'montes del plata'),
  ('fanapel', null, 'fanapel')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'uruguay_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'uruguay_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cycusa' or p.party_name ~* '\mdarsa\M' or p.party_name ~* 'oriental de minerales')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'UY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'UY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'UY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    