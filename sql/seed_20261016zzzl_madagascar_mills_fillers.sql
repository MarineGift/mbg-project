-- ============================================================
-- seed_20261016zzzl_madagascar_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Madagascar update (reports 2026-10-17). SPAH and PAPMAD are both at
-- Ambohimanambola - owner regex keeps them apart.
-- 1) Fillers if missing (3): Chaux Roca, Soalara Calcaire (Cassius),
--    Agro Industrie / Ocean Trade.
-- 2) Mills if missing (2) + plant blocks: SPAH (1), PAPMAD (2). Context (8).
-- 3) app.country_markets MG row (priority none).
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
           v.party_name, 'MG', v.region, v.city, v.website, 'active', 'madagascar_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('chaux roca', 'Chaux Roca', 'Madagascar', null, null, 'Chaux Roca 자체 대리석 광상 분쇄 탄산칼슘(CaCO3 95.5%·MgCO3 2.8%·Fe2O3 0.3%·SiO2 0.9%) — 주로 농업용, 분쇄 조정 가능.', 'Chaux Roca - marble, limestone and aggregates, ground natural calcium carbonate of its own deposit (95.5 pct CaCO3, 2.8 MgCO3, 0.3 Fe2O3, 0.9 SiO2), mainly agricultural, mill settings adjustable.', 'MG check 2026-10-16: Fe2O3 0.3 pct limits brightness - test before paper use. Local GCC partner candidate.'),
  ('soalara|cassius', 'Soalara Calcaire (Cassius Mining) - Toliara', 'Atsimo-Andrefana', 'Soalara', null, 'Cassius Mining 계열 Soalara 석회석(Toliara 항 남쪽 약 28 km) — 상부층 CaO 56.01%·MgO 0.21%·SiO2 0.27%·Fe2O3 0.07%, 광업권 18.75 km² 2055 만료, 탐사·평가 단계.', 'Soalara Calcaire SARL (Cassius Mining), Soalara, about 28 km south of Toliara port - upper limestone averaging 56.01 pct CaO (near pure CaCO3), 0.21 MgO, 0.27 SiO2, 0.07 Fe2O3, 18.75 km2 licence to 2055, exploration and resource stage.', 'MG check 2026-10-16: no grinding plant yet - long-term export GCC feed candidate.'),
  ('agro industrie|ocean trade', 'Agro Industrie (Ocean Trade) - Antananarivo', 'Analamanga', 'Antananarivo', null, 'Agro Industrie/Ocean Trade(Andraharo, 안타나나리보) CaCO3 99%·5 μm·25 kg 판매 — 원산지·제조사 미확인.', 'Agro Industrie / Ocean Trade, Galaxy Village, Andraharo, Antananarivo - sells calcium carbonate 99 pct, 5 micron, 25 kg bags - origin, maker and GCC / PCC type unknown.', 'MG check 2026-10-16: ask whether 5 micron is D50 or top size. agroindustrie@oceantrade.mg. Not added: SCB Madagascar (aggregates), MBS (Tunisia, already a TN row, lists Madagascar exports). Belobaka quarry (Mahajanga) stopped 2026-01. No Malagasy paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%MG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('chaux roca', 'Chaux Roca', 'Madagascar', null, null, 'Chaux Roca 자체 대리석 광상 분쇄 탄산칼슘(CaCO3 95.5%·MgCO3 2.8%·Fe2O3 0.3%·SiO2 0.9%) — 주로 농업용, 분쇄 조정 가능.', 'Chaux Roca - marble, limestone and aggregates, ground natural calcium carbonate of its own deposit (95.5 pct CaCO3, 2.8 MgCO3, 0.3 Fe2O3, 0.9 SiO2), mainly agricultural, mill settings adjustable.', 'MG check 2026-10-16: Fe2O3 0.3 pct limits brightness - test before paper use. Local GCC partner candidate.'),
  ('soalara|cassius', 'Soalara Calcaire (Cassius Mining) - Toliara', 'Atsimo-Andrefana', 'Soalara', null, 'Cassius Mining 계열 Soalara 석회석(Toliara 항 남쪽 약 28 km) — 상부층 CaO 56.01%·MgO 0.21%·SiO2 0.27%·Fe2O3 0.07%, 광업권 18.75 km² 2055 만료, 탐사·평가 단계.', 'Soalara Calcaire SARL (Cassius Mining), Soalara, about 28 km south of Toliara port - upper limestone averaging 56.01 pct CaO (near pure CaCO3), 0.21 MgO, 0.27 SiO2, 0.07 Fe2O3, 18.75 km2 licence to 2055, exploration and resource stage.', 'MG check 2026-10-16: no grinding plant yet - long-term export GCC feed candidate.'),
  ('agro industrie|ocean trade', 'Agro Industrie (Ocean Trade) - Antananarivo', 'Analamanga', 'Antananarivo', null, 'Agro Industrie/Ocean Trade(Andraharo, 안타나나리보) CaCO3 99%·5 μm·25 kg 판매 — 원산지·제조사 미확인.', 'Agro Industrie / Ocean Trade, Galaxy Village, Andraharo, Antananarivo - sells calcium carbonate 99 pct, 5 micron, 25 kg bags - origin, maker and GCC / PCC type unknown.', 'MG check 2026-10-16: ask whether 5 micron is D50 or top size. agroindustrie@oceantrade.mg. Not added: SCB Madagascar (aggregates), MBS (Tunisia, already a TN row, lists Madagascar exports). Belobaka quarry (Mahajanga) stopped 2026-01. No Malagasy paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'madagascar_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Chaux Roca', 'GCC producer', 'Local ground carbonate - partner candidate', 'merchant', 'C', 'gcc'),
  ('Soalara Calcaire (Cassius Mining) - Toliara', 'Limestone deposit', 'High-purity limestone - long-term GCC feed', 'merchant', 'C', 'gcc'),
  ('Agro Industrie (Ocean Trade) - Antananarivo', 'Carbonate supplier', 'Fine carbonate supply - sample source', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'madagascar_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'MG', v.region, v.city, v.website, 'active', 'madagascar_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('\mspah\M|articles hygi[eé]niques', 'ambohimanambola', 'spah|sipromad', 'SPAH (Sipromad) - Ambohimanambola', 'Analamanga', 'Ambohimanambola', null, 'Sipromad 그룹 SPAH(2010 설립·2012 생산) 폐지 수거·펄프화·원지·롤 가공 일관 — 폐지 연 1,200 t+, 화장지 약 1,800만 롤, Doucy Eco·Lys.', 'SPAH (Société de Production d''Articles Hygiéniques, Groupe Sipromad, founded 2010, producing since 2012), Ambohimanambola - collects, sorts and pulps waste paper and makes base paper and rolls in house, over 1,200 t/yr waste paper, about 18 m rolls/yr, brands Doucy Eco and Lys, no chlorine bleach.', 'MG check 2026-10-16: base-paper tonnage not public. collecte@spah.mg.'),
  ('papmad|papeteries de madagascar', 'ambohimanambola', 'papmad|papeteries', 'PAPMAD (Papeteries de Madagascar) - Ambohimanambola', 'Analamanga', 'Ambohimanambola', null, 'PAPMAD(1963, Ambohimanambola) — 과거 인도양 유일 제지공장, 연 9,000~10,000 t·약 900명(UNIDO). 등록 지종: 본드·복사 원지·신문·골심지·라이너·포장지·화장지.', 'Papeteries de Madagascar (PAPMAD, 1963), Ambohimanambola east of Antananarivo - once the only paper mill in the Indian Ocean region, about 9,000-10,000 t/yr and about 900 staff in UNIDO data, listed grades bond and copy base, newsprint, fluting, testliner, wrapping and toilet paper.', 'MG check 2026-10-16: machine status and current output to confirm. papmad@malagasy.com (old), +261 20 22 20634.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mspah\M|articles hygi[eé]niques', 'ambohimanambola', 'spah|sipromad', 'Sipromad 그룹 SPAH(2010 설립·2012 생산) 폐지 수거·펄프화·원지·롤 가공 일관 — 폐지 연 1,200 t+, 화장지 약 1,800만 롤, Doucy Eco·Lys.', 'SPAH (Société de Production d''Articles Hygiéniques, Groupe Sipromad, founded 2010, producing since 2012), Ambohimanambola - collects, sorts and pulps waste paper and makes base paper and rolls in house, over 1,200 t/yr waste paper, about 18 m rolls/yr, brands Doucy Eco and Lys, no chlorine bleach.', 'MG check 2026-10-16: base-paper tonnage not public. collecte@spah.mg.'),
  ('papmad|papeteries de madagascar', 'ambohimanambola', 'papmad|papeteries', 'PAPMAD(1963, Ambohimanambola) — 과거 인도양 유일 제지공장, 연 9,000~10,000 t·약 900명(UNIDO). 등록 지종: 본드·복사 원지·신문·골심지·라이너·포장지·화장지.', 'Papeteries de Madagascar (PAPMAD, 1963), Ambohimanambola east of Antananarivo - once the only paper mill in the Indian Ocean region, about 9,000-10,000 t/yr and about 900 staff in UNIDO data, listed grades bond and copy base, newsprint, fluting, testliner, wrapping and toilet paper.', 'MG check 2026-10-16: machine status and current output to confirm. papmad@malagasy.com (old), +261 20 22 20634.'),
  ('g[eé]n[eé]rale de papeteries|\mgpm\M', null, 'g[eé]n[eé]rale de papeteries|\mgpm\M', null, null, 'MG check 2026-10-16: GPM SA (1980) - premium board in a case study, existence to confirm - context only.'),
  ('semba', null, 'semba', null, null, 'MG check 2026-10-16: SEMBA, Ivato (2020) - BHS corrugator, 50 m m2/yr corrugated - context only.'),
  ('newpack', null, 'newpack', null, null, 'MG check 2026-10-16: NEWPACK (1988), Antananarivo - over 50 m boxes/yr, ISO 9001, FSC - context only.'),
  ('\mmhpc\M|madagascar hygienics', null, '\mmhpc\M|madagascar hygienics', null, null, 'MG check 2026-10-16: Madagascar Hygienics and Paper Corporation, Anosibe - tissue converting - context only.'),
  ('cellupack|softy', null, 'cellupack|softy', null, null, 'MG check 2026-10-16: Cellupack Madagascar (Softy), Ivato - tissue, towels, napkins - machine to confirm - context only.'),
  ('epic international', null, 'epic international', null, null, 'MG check 2026-10-16: Thermal rolls, labels, food papers - context only.'),
  ('europli', null, 'europli', null, null, 'MG check 2026-10-16: Envelopes and office paper products - context only.'),
  ('eco.?pulp', null, 'eco.?pulp', null, null, 'MG check 2026-10-16: Waste-paper collection and recycled fibre (2026) - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'madagascar_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mspah\M|articles hygi[eé]niques', 'ambohimanambola', 'spah|sipromad'),
  ('papmad|papeteries de madagascar', 'ambohimanambola', 'papmad|papeteries'),
  ('g[eé]n[eé]rale de papeteries|\mgpm\M', null, 'g[eé]n[eé]rale de papeteries|\mgpm\M'),
  ('semba', null, 'semba'),
  ('newpack', null, 'newpack'),
  ('\mmhpc\M|madagascar hygienics', null, '\mmhpc\M|madagascar hygienics'),
  ('cellupack|softy', null, 'cellupack|softy'),
  ('epic international', null, 'epic international'),
  ('europli', null, 'europli'),
  ('eco.?pulp', null, 'eco.?pulp')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mspah\M|articles hygi[eé]niques', 'ambohimanambola', 'spah|sipromad', false,
   $pj${"owner": "Groupe Sipromad", "priority": 1, "products": "Recycled toilet tissue", "grades": ["Tissue"], "approach": "Recycled tissue FCC trial - Chaux Roca or imported GCC.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papmad|papeteries de madagascar', 'ambohimanambola', 'papmad|papeteries', false,
   $pj${"owner": "PAPMAD", "priority": 2, "products": "Printing, newsprint, packaging, tissue (listed)", "grades": ["UWF", "Newsprint", "Medium"], "capacity": {"value": 10000, "unit": "metric_t", "year": "Older UNIDO figure", "source": "unido.org"}, "approach": "Confirm running machine, then filler trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('g[eé]n[eé]rale de papeteries|\mgpm\M', null, 'g[eé]n[eé]rale de papeteries|\mgpm\M', true,
   $pj${"owner": "GPM", "products": "GPM SA (1980) - premium board in a case study, existence to confirm", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('semba', null, 'semba', true,
   $pj${"owner": "SEMBA", "products": "SEMBA, Ivato (2020) - BHS corrugator, 50 m m2/yr corrugated", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('newpack', null, 'newpack', true,
   $pj${"owner": "NEWPACK", "products": "NEWPACK (1988), Antananarivo - over 50 m boxes/yr, ISO 9001, FSC", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mmhpc\M|madagascar hygienics', null, '\mmhpc\M|madagascar hygienics', true,
   $pj${"owner": "MHPC", "products": "Madagascar Hygienics and Paper Corporation, Anosibe - tissue converting", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cellupack|softy', null, 'cellupack|softy', true,
   $pj${"owner": "Cellupack", "products": "Cellupack Madagascar (Softy), Ivato - tissue, towels, napkins - machine to confirm", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('epic international', null, 'epic international', true,
   $pj${"owner": "EPIC International", "products": "Thermal rolls, labels, food papers", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('europli', null, 'europli', true,
   $pj${"owner": "EUROPLI", "products": "Envelopes and office paper products", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('eco.?pulp', null, 'eco.?pulp', true,
   $pj${"owner": "Eco-Pulp", "products": "Waste-paper collection and recycled fibre (2026)", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MG', 'Madagascar', 'none',
   $cm$SPAH recycled tissue (Sipromad) and PAPMAD (historic 9-10 kt, status to confirm) - corrugated converters - Chaux Roca and Soalara limestone$cm$,
   $cm$Madagascar has two paper-making sites at Ambohimanambola: SPAH (Groupe Sipromad, integrated recycled tissue since 2012, over 1,200 t/yr waste paper, about 18 m rolls) and PAPMAD (1963, historic 9-10 kt printing, newsprint, packaging and tissue - running status to confirm). Converters: SEMBA (50 m m2 corrugated), NEWPACK (50 m boxes), MHPC, Cellupack (Softy), EPIC, EUROPLI. No paper PCC or GCC: Chaux Roca grinds 95.5 pct marble (agricultural), Soalara (Cassius Mining) holds very pure limestone near Toliara (exploration), Agro Industrie sells 99 pct 5 micron carbonate of unknown origin.$cm$,
   $cm${"fillers": "Ground carbonate: Chaux Roca. Limestone deposit: Soalara (Cassius). Supply: Agro Industrie / Ocean Trade. Not added: SCB, MBS (TN row).", "mills": "Tissue: SPAH. Multi-grade (status to confirm): PAPMAD. Context: GPM SA, SEMBA, NEWPACK, MHPC, Cellupack, EPIC, EUROPLI, Eco-Pulp.", "strategy": "SPAH recycled tissue trial first, then confirm PAPMAD. Soalara as a long-term export GCC source.", "risks": "Tiny volume, PAPMAD status unknown.", "next_steps": ["Contact SPAH for a tissue trial", "Confirm PAPMAD machine status"], "key_numbers": [{"label": "SPAH waste paper", "value": "over 1,200 t/yr"}, {"label": "PAPMAD (historic)", "value": "9-10 kt/yr"}], "files": ["seed_20261016zzzl_madagascar_mills_fillers"]}$cm$::jsonb,
   $cm$SPAH 재생 티슈(Sipromad)·PAPMAD(과거 9천~1만 t, 가동 확인) — 골판지 가공 — Chaux Roca·Soalara 석회석$cm$,
   $cm$마다가스카르 Ambohimanambola 에 제지 공장 2곳: SPAH(Sipromad 그룹, 2012~ 재생 티슈 일관, 폐지 연 1,200 t+, 약 1,800만 롤), PAPMAD(1963, 과거 9천~1만 t 인쇄·신문·포장·화장지 — 가동 확인 필요). 가공: SEMBA(골판지 5,000만 m²), NEWPACK(상자 5,000만 개), MHPC, Cellupack(Softy), EPIC, EUROPLI. 제지용 PCC·GCC 없음: Chaux Roca 95.5% 대리석 분쇄(농업용), Soalara(Cassius Mining) Toliara 인근 고순도 석회석(탐사 단계), Agro Industrie 99%·5 μm 탄산칼슘 판매(원산지 미상).$cm$,
   null, null,
   $cm$현재 생산량 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('\mspah\M|articles hygi[eé]niques', 'ambohimanambola', 'spah|sipromad'),
  ('papmad|papeteries de madagascar', 'ambohimanambola', 'papmad|papeteries'),
  ('g[eé]n[eé]rale de papeteries|\mgpm\M', null, 'g[eé]n[eé]rale de papeteries|\mgpm\M'),
  ('semba', null, 'semba'),
  ('newpack', null, 'newpack'),
  ('\mmhpc\M|madagascar hygienics', null, '\mmhpc\M|madagascar hygienics'),
  ('cellupack|softy', null, 'cellupack|softy'),
  ('epic international', null, 'epic international'),
  ('europli', null, 'europli'),
  ('eco.?pulp', null, 'eco.?pulp')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'madagascar_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'madagascar_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'chaux roca' or p.party_name ~* 'soalara|cassius' or p.party_name ~* 'agro industrie|ocean trade')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'MG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'MG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    