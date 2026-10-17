-- ============================================================
-- seed_20261016zl_serbia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Serbia update (reports 2026-10-16).
-- 1) Fillers if missing (5): Beaz Plus, ABM International, DNV-Micron,
--    Novkal, Omya Venčac / Omya Specialty Materials (also the contact for
--    Montenegro and Bosnia).
-- 2) Mills if missing (3) + plant blocks: Drenik ND (1), Umka (2),
--    Smurfit Westrock Beograd (3). Context (7): Veropapir, Swiss Papier,
--    Inter-Papir, Litopapir, Intertron, Papircoop, Avala Ada.
-- 3) app.country_markets RS row (priority medium).
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
           v.party_name, 'RS', v.region, v.city, v.website, 'active', 'serbia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('beaz', 'Beaz Plus - Aranđelovac', 'Šumadija', 'Aranđelovac', null, '2001년 생산 시작 Aranđelovac 대리석 GCC — 자체 광산, 2014 미분쇄·표면처리 설비, 품질실험실. 5 μm 등급 D50 1.7·D98 5 μm, 10 μm 등급 D50 2.0, 제지 용도 명시.', 'Beaz Plus d.o.o. (production since 2001), Risovački put bb, Aranđelovac - ground marble and micronised GCC of its own quarry, fine grinding and surface treatment added 2014, QC lab. Grades: 5 micron (D50 1.7, D98 5), 10 micron (D50 2.0), 20, 40, 60, 90 micron, paper named.', 'RS check 2026-10-16: wet slurry not confirmed. +381 34 727 172. FCC pilot partner candidate 1.'),
  ('abm international|ducalcit', 'ABM International - Palić and Kučevo', 'North Bačka', 'Palić', null, 'ABM International(Dukat 합병) — Palić 미분 석회석 6만 t+, Kučevo 처리 20만 t, CaCO3 98%+, 매장량 2,300만 t+, 철도. Ducalcit 1(D50 1.8~2.2)·Ducalcit 2·A-20·A-60.', 'ABM International d.o.o. (merged with Dukat), Horgoški put 158, Palić and Bože Dimitrijevića 4, Kučevo - limestone over 98 pct CaCO3, reserves over 23 Mt: Palić micronised over 60,000 t/yr, Kučevo 200,000 t/yr processing with rail siding. Grades Ducalcit 1 (D50 1.8-2.2, D98 5.7-7.5), Ducalcit 2 (D50 2.6-3.2), A-20, A-60, mainly paint, plastics, building.', 'RS check 2026-10-16: paper approvals not confirmed. office@abm.co.rs, +381 24 522 899. Scale partner for FCC toll production.'),
  ('dnv-?micron', 'DNV-Micron - Raška', 'Raška', 'Raška', null, '2006년 설립, 2010 미분쇄 설비 — 고품질 대리석화 석회석 5~315 μm, 제지·플라스틱·도료·제약·화장품 명시.', 'DNV-Micron d.o.o. (2006, micronising since 2010), Raška - high-white marbleised limestone ground to about 5-315 micron for paper, plastics, paint, pharma and cosmetics.', 'RS check 2026-10-16: grade PSD to confirm.'),
  ('novkal', 'Novkal - Aranđelovac', 'Šumadija', 'Aranđelovac', null, 'Venčac 방해석 대리석 광산 보유, 분쇄·미분화 연 3.5만 t+, 플라스틱·고무·접착제·건축.', 'Novkal d.o.o., Risovački put bb, Aranđelovac - calcite marble quarry on Mt Venčac, crushing and micronising over 35,000 t/yr for plastics, rubber, adhesives and building.', 'RS check 2026-10-16: paper sales not confirmed. office@novkal.rs.'),
  ('omya.*(ven[cč]ac|serbia|srbij|aran)', 'Omya Venčac / Omya Specialty Materials - Aranđelovac', 'Šumadija', 'Aranđelovac', null, 'Omya 세르비아 거점 — Omya Venčac(Venčački put bb, Aranđelovac) 탄산칼슘 채굴·가공·공급, Omya Specialty Materials d.o.o.(Banja-Aranđelovac) 제지·펄프 명시. 몬테네그로·보스니아 공급 연락처.', 'Omya in Serbia - Omya Venčac d.o.o., Venčački put bb, Aranđelovac (calcium carbonate quarrying, processing and supply, listed as the contact for Bosnia) and Omya Specialty Materials d.o.o., Kralja Petra Prvog 84, Banja-Aranđelovac (pulp and paper named, also serves Montenegro).', 'RS check 2026-10-16: local PCC not confirmed (Serbian Omya PCC patents are not a plant). lazar.karadzic@omya.com, +381 65 8989 260. Royalty licensee at Omya HQ level. Not added: Nutra (GCC and PCC distributor).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%RS check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('beaz', 'Beaz Plus - Aranđelovac', 'Šumadija', 'Aranđelovac', null, '2001년 생산 시작 Aranđelovac 대리석 GCC — 자체 광산, 2014 미분쇄·표면처리 설비, 품질실험실. 5 μm 등급 D50 1.7·D98 5 μm, 10 μm 등급 D50 2.0, 제지 용도 명시.', 'Beaz Plus d.o.o. (production since 2001), Risovački put bb, Aranđelovac - ground marble and micronised GCC of its own quarry, fine grinding and surface treatment added 2014, QC lab. Grades: 5 micron (D50 1.7, D98 5), 10 micron (D50 2.0), 20, 40, 60, 90 micron, paper named.', 'RS check 2026-10-16: wet slurry not confirmed. +381 34 727 172. FCC pilot partner candidate 1.'),
  ('abm international|ducalcit', 'ABM International - Palić and Kučevo', 'North Bačka', 'Palić', null, 'ABM International(Dukat 합병) — Palić 미분 석회석 6만 t+, Kučevo 처리 20만 t, CaCO3 98%+, 매장량 2,300만 t+, 철도. Ducalcit 1(D50 1.8~2.2)·Ducalcit 2·A-20·A-60.', 'ABM International d.o.o. (merged with Dukat), Horgoški put 158, Palić and Bože Dimitrijevića 4, Kučevo - limestone over 98 pct CaCO3, reserves over 23 Mt: Palić micronised over 60,000 t/yr, Kučevo 200,000 t/yr processing with rail siding. Grades Ducalcit 1 (D50 1.8-2.2, D98 5.7-7.5), Ducalcit 2 (D50 2.6-3.2), A-20, A-60, mainly paint, plastics, building.', 'RS check 2026-10-16: paper approvals not confirmed. office@abm.co.rs, +381 24 522 899. Scale partner for FCC toll production.'),
  ('dnv-?micron', 'DNV-Micron - Raška', 'Raška', 'Raška', null, '2006년 설립, 2010 미분쇄 설비 — 고품질 대리석화 석회석 5~315 μm, 제지·플라스틱·도료·제약·화장품 명시.', 'DNV-Micron d.o.o. (2006, micronising since 2010), Raška - high-white marbleised limestone ground to about 5-315 micron for paper, plastics, paint, pharma and cosmetics.', 'RS check 2026-10-16: grade PSD to confirm.'),
  ('novkal', 'Novkal - Aranđelovac', 'Šumadija', 'Aranđelovac', null, 'Venčac 방해석 대리석 광산 보유, 분쇄·미분화 연 3.5만 t+, 플라스틱·고무·접착제·건축.', 'Novkal d.o.o., Risovački put bb, Aranđelovac - calcite marble quarry on Mt Venčac, crushing and micronising over 35,000 t/yr for plastics, rubber, adhesives and building.', 'RS check 2026-10-16: paper sales not confirmed. office@novkal.rs.'),
  ('omya.*(ven[cč]ac|serbia|srbij|aran)', 'Omya Venčac / Omya Specialty Materials - Aranđelovac', 'Šumadija', 'Aranđelovac', null, 'Omya 세르비아 거점 — Omya Venčac(Venčački put bb, Aranđelovac) 탄산칼슘 채굴·가공·공급, Omya Specialty Materials d.o.o.(Banja-Aranđelovac) 제지·펄프 명시. 몬테네그로·보스니아 공급 연락처.', 'Omya in Serbia - Omya Venčac d.o.o., Venčački put bb, Aranđelovac (calcium carbonate quarrying, processing and supply, listed as the contact for Bosnia) and Omya Specialty Materials d.o.o., Kralja Petra Prvog 84, Banja-Aranđelovac (pulp and paper named, also serves Montenegro).', 'RS check 2026-10-16: local PCC not confirmed (Serbian Omya PCC patents are not a plant). lazar.karadzic@omya.com, +381 65 8989 260. Royalty licensee at Omya HQ level. Not added: Nutra (GCC and PCC distributor).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'serbia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Beaz Plus - Aranđelovac', 'GCC producer', 'Paper-named fine GCC (D50 1.7) - candidate 1', 'merchant', 'B', 'gcc'),
  ('ABM International - Palić and Kučevo', 'GCC producer', 'Large GCC producer - FCC toll or licence candidate', 'merchant', 'B', 'gcc'),
  ('DNV-Micron - Raška', 'GCC producer', 'Paper-named micronised carbonate', 'merchant', 'C', 'gcc'),
  ('Novkal - Aranđelovac', 'GCC producer', 'Calcite GCC - OEM candidate', 'merchant', 'C', 'gcc'),
  ('Omya Venčac / Omya Specialty Materials - Aranđelovac', 'GCC and PCC supplier', 'Omya Balkans base - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'serbia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'RS', v.region, v.city, v.website, 'active', 'serbia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('drenik', 'beograd|belgrade|pan[cč]eva', 'drenik', 'Drenik ND - Belgrade', 'Belgrade', 'Belgrade', null, '1995년 설립 서부 발칸 최대 티슈 제조사(Perfex·Boni) — 베오그라드 티슈 원지 3라인·가공 8라인 + 헝가리 Szolnok, 그룹 연 11만 t+, 50개국+. 2024 IFC 1.06억 유로(바이오매스 열병합 8 MW).', 'Drenik ND (1995, family-owned), mill at Pančevački put 69, Belgrade - three tissue machines and eight converting lines (plus a mill at Szolnok, Hungary), group capacity over 110,000 t/yr, brands Perfex and Boni, sales in over 50 countries. IFC financing package EUR 106 m (2024-02) incl. an 8 MW biomass CHP.', 'RS check 2026-10-16: group figure includes Hungary - kept in split. 2025 sales largest in Serbian paper and board (APR). drenik.srbija@dreniknd.com, +381 11 2072 000.'),
  ('\mumka\M', 'umka', 'umka|kappa star', 'Umka Cardboard Mill - Umka', 'Belgrade', 'Umka', null, '1939년 설립 재생 코팅 백판지(Kappa Star Group) — 연 22만 t(목표 25만 t), 지폭 3.2 m, Umka Color·Pak·Special·Liner·Brown Back(180~450 g/m²), 40개국+.', 'Fabrika kartona Umka (1939, Kappa Star Group), 13. oktobra 1, Umka (Belgrade) - recycled coated white-lined board 220,000 t/yr (250,000 t target) on a 3.2 m machine, rebuilt three times by Valmet (about +70 pct): Umka Color GD2, Pak GD3, Special GT2, Liner GD2, Brown Back (180-450 g/m2), sold in over 40 countries.', 'RS check 2026-10-16: umka@umka.rs, +381 11 3602 600.'),
  ('smurfit.*(beograd|belgrade)|fabrika hartije', 'beograd|belgrade|ada huj', 'smurfit|westrock|hartije', 'Smurfit Westrock Beograd (ex Fabrika Hartije)', 'Belgrade', 'Belgrade', null, '1921년부터 제지(구 Fabrika Hartije Beograd, 2018 Smurfit Kappa 인수) — 100% 재생고지 Schrenz·Fluting·Testliner 3, 연 12만 t, 지폭 약 5 m.', 'Smurfit Westrock Beograd (paper since 1921, formerly Fabrika Hartije Beograd, bought by Smurfit Kappa 2018), Put za Ada Huju 9, Belgrade - 100 pct recycled Schrenz, fluting and Testliner 3, 90-200 g/m2, 120,000 t/yr on a 5 m machine.', 'RS check 2026-10-16: paper mill, not the Avala Ada box plant. swb@smurfitwestrock.rs.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%RS check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('drenik', 'beograd|belgrade|pan[cč]eva', 'drenik', '1995년 설립 서부 발칸 최대 티슈 제조사(Perfex·Boni) — 베오그라드 티슈 원지 3라인·가공 8라인 + 헝가리 Szolnok, 그룹 연 11만 t+, 50개국+. 2024 IFC 1.06억 유로(바이오매스 열병합 8 MW).', 'Drenik ND (1995, family-owned), mill at Pančevački put 69, Belgrade - three tissue machines and eight converting lines (plus a mill at Szolnok, Hungary), group capacity over 110,000 t/yr, brands Perfex and Boni, sales in over 50 countries. IFC financing package EUR 106 m (2024-02) incl. an 8 MW biomass CHP.', 'RS check 2026-10-16: group figure includes Hungary - kept in split. 2025 sales largest in Serbian paper and board (APR). drenik.srbija@dreniknd.com, +381 11 2072 000.'),
  ('\mumka\M', 'umka', 'umka|kappa star', '1939년 설립 재생 코팅 백판지(Kappa Star Group) — 연 22만 t(목표 25만 t), 지폭 3.2 m, Umka Color·Pak·Special·Liner·Brown Back(180~450 g/m²), 40개국+.', 'Fabrika kartona Umka (1939, Kappa Star Group), 13. oktobra 1, Umka (Belgrade) - recycled coated white-lined board 220,000 t/yr (250,000 t target) on a 3.2 m machine, rebuilt three times by Valmet (about +70 pct): Umka Color GD2, Pak GD3, Special GT2, Liner GD2, Brown Back (180-450 g/m2), sold in over 40 countries.', 'RS check 2026-10-16: umka@umka.rs, +381 11 3602 600.'),
  ('smurfit.*(beograd|belgrade)|fabrika hartije', 'beograd|belgrade|ada huj', 'smurfit|westrock|hartije', '1921년부터 제지(구 Fabrika Hartije Beograd, 2018 Smurfit Kappa 인수) — 100% 재생고지 Schrenz·Fluting·Testliner 3, 연 12만 t, 지폭 약 5 m.', 'Smurfit Westrock Beograd (paper since 1921, formerly Fabrika Hartije Beograd, bought by Smurfit Kappa 2018), Put za Ada Huju 9, Belgrade - 100 pct recycled Schrenz, fluting and Testliner 3, 90-200 g/m2, 120,000 t/yr on a 5 m machine.', 'RS check 2026-10-16: paper mill, not the Avala Ada box plant. swb@smurfitwestrock.rs.'),
  ('veropapir', null, 'veropapir', null, null, 'RS check 2026-10-16: Registered paper and board maker, Čačak (2025 sales RSD 363 m) - machine not confirmed - context only.'),
  ('swiss papier', null, 'swiss papier', null, null, 'RS check 2026-10-16: Registered paper and board, Novi Beograd - machine not confirmed - context only.'),
  ('inter-?papir', null, 'inter-?papir', null, null, 'RS check 2026-10-16: Paper trade and converting, Zemun - context only.'),
  ('litopapir', null, 'litopapir', null, null, 'RS check 2026-10-16: Paper bags, tubes, e-commerce packaging, Čačak - converter - context only.'),
  ('intertron', null, 'intertron', null, null, 'RS check 2026-10-16: Paper bags (about 25 kt/yr paper use), tissue jumbo-roll trade - context only.'),
  ('papircoop', null, 'papircoop', null, null, 'RS check 2026-10-16: Greyboard and corrugated, imports printing paper - context only.'),
  ('avala ada', null, 'avala ada', null, null, 'RS check 2026-10-16: Corrugated box plant, Belgrade - converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'serbia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('drenik', 'beograd|belgrade|pan[cč]eva', 'drenik'),
  ('\mumka\M', 'umka', 'umka|kappa star'),
  ('smurfit.*(beograd|belgrade)|fabrika hartije', 'beograd|belgrade|ada huj', 'smurfit|westrock|hartije'),
  ('veropapir', null, 'veropapir'),
  ('swiss papier', null, 'swiss papier'),
  ('inter-?papir', null, 'inter-?papir'),
  ('litopapir', null, 'litopapir'),
  ('intertron', null, 'intertron'),
  ('papircoop', null, 'papircoop'),
  ('avala ada', null, 'avala ada')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('drenik', 'beograd|belgrade|pan[cč]eva', 'drenik',
   $pj${"owner": "Drenik", "priority": 1, "products": "Toilet tissue, kitchen towel, napkins, facial, jumbo rolls", "grades": ["Tissue"], "machines": 3, "capacity_split": [{"label": "Group total (Belgrade + Szolnok HU)", "value_t": 110000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 80 pct x 5 pct on group figure - planning only."}, "pitch": "Tissue FCC 3-5-7 pct - Korean tissue data", "approach": "Lead Serbian account - Beaz Plus or Omya Venčac as producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mumka\M', 'umka', 'umka|kappa star',
   $pj${"owner": "Kappa Star Group", "priority": 2, "products": "Recycled coated board (GD2, GD3, GT2)", "grades": ["Coated board"], "capacity": {"value": 220000, "unit": "metric_t", "year": "Company figure", "source": "umka.rs"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Ply-level only - report scenario."}, "approach": "Middle-ply FCC trial with Beaz Plus or ABM GCC.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(beograd|belgrade)|fabrika hartije', 'beograd|belgrade|ada huj', 'smurfit|westrock|hartije',
   $pj${"owner": "Smurfit Westrock", "priority": 3, "products": "Schrenz, fluting, testliner", "grades": ["Medium", "Testliner"], "capacity": {"value": 120000, "unit": "metric_t", "year": "Company figure", "source": "smurfitwestrock.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.025}, {"label": "Base", "utilization": 0.8, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario - strength must hold."}, "approach": "SCT, RCT, CMT trial - group-wide upside.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('veropapir', null, 'veropapir',
   $pj${"owner": "Veropapir", "products": "Registered paper and board maker, Čačak (2025 sales RSD 363 m) - machine not confirmed", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('swiss papier', null, 'swiss papier',
   $pj${"owner": "Swiss Papier", "products": "Registered paper and board, Novi Beograd - machine not confirmed", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('inter-?papir', null, 'inter-?papir',
   $pj${"owner": "Inter-Papir", "products": "Paper trade and converting, Zemun", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('litopapir', null, 'litopapir',
   $pj${"owner": "Litopapir", "products": "Paper bags, tubes, e-commerce packaging, Čačak - converter", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('intertron', null, 'intertron',
   $pj${"owner": "Intertron", "products": "Paper bags (about 25 kt/yr paper use), tissue jumbo-roll trade", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papircoop', null, 'papircoop',
   $pj${"owner": "Papircoop", "products": "Greyboard and corrugated, imports printing paper", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('avala ada', null, 'avala ada',
   $pj${"owner": "Smurfit Westrock Avala Ada", "products": "Corrugated box plant, Belgrade - converter", "approach": "Converter or unconfirmed machine.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'RS', 'Serbia', 'medium',
   $cm$Drenik tissue (110 kt group), Umka recycled board (220 kt), Smurfit Westrock Beograd liner (120 kt) - Aranđelovac GCC cluster with Omya Venčac$cm$,
   $cm$Serbia's base-paper output is concentrated in three mills: Drenik ND (Belgrade tissue, three machines, 110 kt group incl. Hungary), Umka (recycled coated board, 220 kt) and Smurfit Westrock Beograd (recycled liner and fluting, 120 kt). GCC cluster at Aranđelovac: Beaz Plus (D50 1.7, paper named), Novkal, Omya Venčac and Omya Specialty Materials (licensee, Balkans base for Montenegro and Bosnia), plus ABM International (Palić 60 kt, Kučevo 200 kt) and DNV-Micron (Raška). No paper PCC plant.$cm$,
   $cm${"fillers": "GCC: Beaz Plus, ABM International, DNV-Micron, Novkal, Omya Venčac / Specialty Materials (licensee). Not added: Nutra (distributor). No PCC.", "mills": "Tissue: Drenik ND Belgrade. Coated board: Umka. Recycled liner: Smurfit Westrock Beograd. Context: Veropapir, Swiss Papier, Inter-Papir, Litopapir, Intertron, Papircoop, Avala Ada.", "strategy": "Drenik tissue trial first, Umka middle-ply second, with Beaz Plus or Omya Venčac as producer and ABM for scale. Serbia as Balkan hub (Montenegro, Bosnia).", "risks": "Drenik figure includes Hungary, board and liner strength limits.", "next_steps": ["Propose a tissue trial to Drenik", "Ask Beaz Plus about wet slurry capability"], "key_numbers": [{"label": "Drenik group", "value": "over 110 kt/yr (RS + HU)"}, {"label": "Umka", "value": "220 kt/yr (250 kt target)"}, {"label": "Report scenario", "value": "18,000 t FCC (80 pct x 5 pct of 450 kt)"}], "files": ["seed_20261016zl_serbia_mills_fillers"]}$cm$::jsonb,
   $cm$Drenik 티슈(그룹 11만 t)·Umka 재생 백판지(22만 t)·Smurfit Westrock Beograd 라이너(12만 t) — Aranđelovac GCC 클러스터·Omya Venčac$cm$,
   $cm$세르비아 원지 생산은 3곳에 집중: Drenik ND(베오그라드 티슈 3라인, 헝가리 포함 그룹 11만 t), Umka(재생 코팅 백판지 22만 t), Smurfit Westrock Beograd(재생 라이너·플루팅 12만 t). Aranđelovac GCC 클러스터: Beaz Plus(D50 1.7, 제지 명시)·Novkal·Omya Venčac/Specialty Materials(라이선시, 몬테네그로·보스니아 공급 거점), ABM International(Palić 6만·Kučevo 20만 t), DNV-Micron. 제지용 PCC 없음.$cm$,
   9000, 18000,
   $cm$Drenik·Umka·Smurfit 45만 t × 가동 80% × FCC 2.5~5% (보고서 시나리오, Drenik 은 헝가리 포함)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('drenik', 'beograd|belgrade|pan[cč]eva', 'drenik'),
  ('\mumka\M', 'umka', 'umka|kappa star'),
  ('smurfit.*(beograd|belgrade)|fabrika hartije', 'beograd|belgrade|ada huj', 'smurfit|westrock|hartije'),
  ('veropapir', null, 'veropapir'),
  ('swiss papier', null, 'swiss papier'),
  ('inter-?papir', null, 'inter-?papir'),
  ('litopapir', null, 'litopapir'),
  ('intertron', null, 'intertron'),
  ('papircoop', null, 'papircoop'),
  ('avala ada', null, 'avala ada')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'serbia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'serbia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'beaz' or p.party_name ~* 'abm international|ducalcit' or p.party_name ~* 'dnv-?micron' or p.party_name ~* 'novkal' or p.party_name ~* 'omya.*(ven[cč]ac|serbia|srbij|aran)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'RS'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'RS'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'RS'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RS'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    