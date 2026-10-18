-- ============================================================
-- seed_20261016zzr_algeria_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Algeria update (reports 2026-10-16). Fixed generator. First African seed.
-- 1) Fillers if missing (5): ENOF Oggaz (SONAREM), BEXCAR, Golden Poudre,
--    Baslimane Chaux Berriane, Frères DIB.
-- 2) Mills if missing (6) + plant blocks, priority 1-5: Africaine Paper
--    Mills, Warak / Faderco, Tonic Industrie, Wafa Doux (new), Général
--    Emballage (Naâma plan in split). GIPEC no priority. Context (1).
-- 3) app.country_markets DZ row (priority medium).
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
           v.party_name, 'DZ', v.region, v.city, v.website, 'active', 'algeria_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('\menof\M|sonarem', 'ENOF (SONAREM) - Oggaz', 'Mascara', 'Oggaz', null, 'SONAREM 산하 산업광물 ENOF — Oggaz(Sig, Mascara) 탄산칼슘 공장 2023-09 준공, 설계 연 10만 t(매장 4,900만 t+), 제지·잉크·화장품·도료 명시. Mellal(Beni Snous, Tlemcen) 연 7만 t(40·74 μm, 0~6 mm).', 'ENOF (SONAREM state mining group) - industrial minerals incl. calcium carbonate, kaolin, feldspar, silica, barite. Oggaz GCC plant (Sig, Mascara) opened 2023-09, design 100,000 t/yr, reserves over 49 Mt, paper, ink, cosmetics and paint named. Mellal plant (Khmise, Beni Snous, Tlemcen) about 70,000 t/yr nominal (40 and 74 micron, 0-6 mm) of Beni Saf limestone.', 'DZ check 2026-10-16: wet slurry and paper sales not confirmed. 28 Mustapha Ait El Hadi, El Harrach, Algiers, sec_dg@enof.dz, +213 23 82 71 73. FCC co-production candidate 1.'),
  ('bexcar', 'SNC BEXCAR (Benbrahim) - Constantine', 'Constantine', 'Constantine', null, 'BENBRAHIM 그룹 BEXCAR(Ben Baddis 산업단지) 백색 방해석 — 5 mm~10 μm 미만, Bexcarb 10N: CaCO3 98%+, D50 6.7 μm, D98 45 μm, 2 μm 이하 22%, L* 96.6, Fe2O3 0.18%(2017).', 'SNC BEXCAR Benbrahim et Cie (Benbrahim group), Zone Industrielle Ben Baddis, Constantine - white calcite deposit, products 5 mm down to under 10 micron. Bexcarb 10N (2017 data): over 98 pct CaCO3, D50 6.7 micron, D98 45 micron, 22 pct under 2 micron, L* 96.6, Fe2O3 0.18, SiO2 0.13 pct.', 'DZ check 2026-10-16: too coarse for paper as is, no mill supply shown (paint, plastics, adhesives). bexcar.dz@gmail.com, +213 550 91 05 44. Technical GCC partner.'),
  ('golden poudre', 'Golden Poudre Industrielle - Sétif', 'Sétif', 'Sétif', null, 'GPI(2017, SARL, 10~19명) 다양한 입도 탄산칼슘 생산·판매(Sétif).', 'Golden Poudre Industrielle SARL (2017), Sétif - production and sale of calcium carbonate in several particle sizes, 10-19 staff.', 'DZ check 2026-10-16: own mill scale unclear. Small OEM option.'),
  ('baslimane|chaux berriane', 'Baslimane Chaux Berriane - Berriane', 'Ghardaïa', 'Berriane', null, 'Berriane 산업용 석회·탄산칼슘·생석회·돌로마이트 석회.', 'Baslimane Chaux Berriane (BCB), Berriane (Ghardaïa) - industrial lime, calcium carbonate, quicklime and dolomitic lime.', 'DZ check 2026-10-16: PCC raw-material route, no PCC reactor known.'),
  ('fr[eè]res dib|\msfdm\M', 'Frères DIB Métaux (SFDM) - El Khroub', 'Constantine', 'El Khroub', null, 'El Khroub 산업용 다입도 탄산칼슘.', 'Frères DIB Métaux (SFDM), El Khroub (Constantine) - calcium carbonate in several sizes for industry. Constantine also has MBLS.', 'DZ check 2026-10-16: capacity and paper grade unknown. Not added: Vita Plast, Brenntag Algeria (distributors). No Algerian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%DZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('\menof\M|sonarem', 'ENOF (SONAREM) - Oggaz', 'Mascara', 'Oggaz', null, 'SONAREM 산하 산업광물 ENOF — Oggaz(Sig, Mascara) 탄산칼슘 공장 2023-09 준공, 설계 연 10만 t(매장 4,900만 t+), 제지·잉크·화장품·도료 명시. Mellal(Beni Snous, Tlemcen) 연 7만 t(40·74 μm, 0~6 mm).', 'ENOF (SONAREM state mining group) - industrial minerals incl. calcium carbonate, kaolin, feldspar, silica, barite. Oggaz GCC plant (Sig, Mascara) opened 2023-09, design 100,000 t/yr, reserves over 49 Mt, paper, ink, cosmetics and paint named. Mellal plant (Khmise, Beni Snous, Tlemcen) about 70,000 t/yr nominal (40 and 74 micron, 0-6 mm) of Beni Saf limestone.', 'DZ check 2026-10-16: wet slurry and paper sales not confirmed. 28 Mustapha Ait El Hadi, El Harrach, Algiers, sec_dg@enof.dz, +213 23 82 71 73. FCC co-production candidate 1.'),
  ('bexcar', 'SNC BEXCAR (Benbrahim) - Constantine', 'Constantine', 'Constantine', null, 'BENBRAHIM 그룹 BEXCAR(Ben Baddis 산업단지) 백색 방해석 — 5 mm~10 μm 미만, Bexcarb 10N: CaCO3 98%+, D50 6.7 μm, D98 45 μm, 2 μm 이하 22%, L* 96.6, Fe2O3 0.18%(2017).', 'SNC BEXCAR Benbrahim et Cie (Benbrahim group), Zone Industrielle Ben Baddis, Constantine - white calcite deposit, products 5 mm down to under 10 micron. Bexcarb 10N (2017 data): over 98 pct CaCO3, D50 6.7 micron, D98 45 micron, 22 pct under 2 micron, L* 96.6, Fe2O3 0.18, SiO2 0.13 pct.', 'DZ check 2026-10-16: too coarse for paper as is, no mill supply shown (paint, plastics, adhesives). bexcar.dz@gmail.com, +213 550 91 05 44. Technical GCC partner.'),
  ('golden poudre', 'Golden Poudre Industrielle - Sétif', 'Sétif', 'Sétif', null, 'GPI(2017, SARL, 10~19명) 다양한 입도 탄산칼슘 생산·판매(Sétif).', 'Golden Poudre Industrielle SARL (2017), Sétif - production and sale of calcium carbonate in several particle sizes, 10-19 staff.', 'DZ check 2026-10-16: own mill scale unclear. Small OEM option.'),
  ('baslimane|chaux berriane', 'Baslimane Chaux Berriane - Berriane', 'Ghardaïa', 'Berriane', null, 'Berriane 산업용 석회·탄산칼슘·생석회·돌로마이트 석회.', 'Baslimane Chaux Berriane (BCB), Berriane (Ghardaïa) - industrial lime, calcium carbonate, quicklime and dolomitic lime.', 'DZ check 2026-10-16: PCC raw-material route, no PCC reactor known.'),
  ('fr[eè]res dib|\msfdm\M', 'Frères DIB Métaux (SFDM) - El Khroub', 'Constantine', 'El Khroub', null, 'El Khroub 산업용 다입도 탄산칼슘.', 'Frères DIB Métaux (SFDM), El Khroub (Constantine) - calcium carbonate in several sizes for industry. Constantine also has MBLS.', 'DZ check 2026-10-16: capacity and paper grade unknown. Not added: Vita Plast, Brenntag Algeria (distributors). No Algerian paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'algeria_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('ENOF (SONAREM) - Oggaz', 'GCC producer', 'State GCC producer 100 kt (paper named) - candidate 1', 'merchant', 'B', 'gcc'),
  ('SNC BEXCAR (Benbrahim) - Constantine', 'GCC producer', 'White calcite GCC with data - technical partner', 'merchant', 'C', 'gcc'),
  ('Golden Poudre Industrielle - Sétif', 'GCC producer', 'Small carbonate maker - OEM option', 'merchant', 'C', 'gcc'),
  ('Baslimane Chaux Berriane - Berriane', 'Lime and carbonate producer', 'Lime for PCC - raw material', 'merchant', 'C', 'pcc'),
  ('Frères DIB Métaux (SFDM) - El Khroub', 'GCC producer', 'Carbonate maker - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'algeria_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'DZ', v.region, v.city, v.website, 'active', 'algeria_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('africaine paper|\mapm\M', 'rou[iï]ba', 'africaine|apm', 'Africaine Paper Mills - Rouïba', 'Algiers', 'Rouïba', null, 'APM Rouïba(약 5만 m²) 티슈 점보롤 — MENA 주요 제조사(Tissue World 2025-06), 연 3만 t 추가 라인 계획.', 'Africaine Paper Mills (APM), Rouïba (Algiers) - tissue jumbo rolls on a site of about 50,000 m2, named a leading MENA jumbo-roll maker (Tissue World, 2025-06), new line of about 30,000 t/yr planned.', 'DZ check 2026-10-16: current capacity not public. Contact Belkacem Becharef (2024 interview).'),
  ('warak|faderco', 's[eé]tif', 'warak|faderco', 'Warak (Faderco) - Sétif', 'Sétif', 'Sétif', null, 'Faderco 그룹 Warak(Sétif, 5.5만 m², 7,000만 달러+) 목재펄프 티슈 원지 연 3만 t+(약 100 t/일, Valmet).', 'Warak (Faderco Group), Sétif - virgin-pulp tissue jumbo rolls, over 30,000 t/yr (about 100 t/day, Valmet machine), over USD 70 m, 55,000 m2 site.', 'DZ check 2026-10-16: '),
  ('tonic', 'bou isma[iï]l', 'tonic', 'Tonic Industrie - Bou Ismaïl', 'Tipaza', 'Bou Ismaïl', null, '공공 제지·포장 Tonic Industrie(Bou Ismaïl) — 티슈 원지·Liner·Fluting·MG지·재생지, 폐지 회수.', 'Tonic Industrie (public), Bou Ismaïl (Tipaza) - tissue base paper, liner, fluting, MG paper and recycled papers, with waste-paper recovery.', 'DZ check 2026-10-16: 2026 running rate unknown.'),
  ('wafa doux', 'a[iï]n oussera|djelfa', 'wafa', 'Wafa Doux - Aïn Oussera', 'Djelfa', 'Aïn Oussera', null, 'Wafa Doux 신규 통합 공장(Aïn Oussera, 2025-04-30 착공) — 펄프·위생지·판지 계획.', 'Wafa Doux, Aïn Oussera (Djelfa) - new integrated mill for pulp, hygiene paper and board, ground-breaking announced by AAPI 2025-04-30.', 'DZ check 2026-10-16: not running yet - design-stage talks.'),
  ('g[eé]n[eé]ral emballage', 'akbou|na[aâ]ma', 'g[eé]n[eé]ral emballage', 'Général Emballage - Akbou', 'Béjaïa', 'Akbou', null, 'Général Emballage(2002, Akbou 본사·Oran·Sétif 가공 3곳 약 26만 t, 1,300명+) — Naâma 신규 RCCM 원지공장 연 35만 t(400억 DZD, Andritz, 2025-04 착공·30개월).', 'Général Emballage (2002), HQ Akbou (Béjaïa) - largest Algerian corrugated maker, three converting plants (Akbou, Oran, Sétif) about 260,000 t/yr, over 1,300 staff. New recycled containerboard mill at Naâma: 350,000 t/yr, DZD 40 bn, 30 ha, Andritz line ordered (reported 2026-04), started 2025-04 with a 30-month build.', 'DZ check 2026-10-16: converting is not base paper - Naâma plan only in split.'),
  ('gipec', 'baba ali', 'gipec', 'GIPEC - Baba Ali', 'Algiers', 'Baba Ali', null, 'GIPEC(1998 CELPAP+ENEPAC, SONIC 계보) 종이·판지·포장재·폐지 회수.', 'GIPEC (Groupe Industriel du Papier et de la Cellulose, formed 1998 of CELPAP and ENEPAC, SONIC lineage), Route de la Gare, Baba Ali - corrugated boxes, industrial packaging and waste-paper recovery.', 'DZ check 2026-10-16: paper machines and output to confirm. infogipec@gipec.dz.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%DZ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('africaine paper|\mapm\M', 'rou[iï]ba', 'africaine|apm', 'APM Rouïba(약 5만 m²) 티슈 점보롤 — MENA 주요 제조사(Tissue World 2025-06), 연 3만 t 추가 라인 계획.', 'Africaine Paper Mills (APM), Rouïba (Algiers) - tissue jumbo rolls on a site of about 50,000 m2, named a leading MENA jumbo-roll maker (Tissue World, 2025-06), new line of about 30,000 t/yr planned.', 'DZ check 2026-10-16: current capacity not public. Contact Belkacem Becharef (2024 interview).'),
  ('warak|faderco', 's[eé]tif', 'warak|faderco', 'Faderco 그룹 Warak(Sétif, 5.5만 m², 7,000만 달러+) 목재펄프 티슈 원지 연 3만 t+(약 100 t/일, Valmet).', 'Warak (Faderco Group), Sétif - virgin-pulp tissue jumbo rolls, over 30,000 t/yr (about 100 t/day, Valmet machine), over USD 70 m, 55,000 m2 site.', 'DZ check 2026-10-16: '),
  ('tonic', 'bou isma[iï]l', 'tonic', '공공 제지·포장 Tonic Industrie(Bou Ismaïl) — 티슈 원지·Liner·Fluting·MG지·재생지, 폐지 회수.', 'Tonic Industrie (public), Bou Ismaïl (Tipaza) - tissue base paper, liner, fluting, MG paper and recycled papers, with waste-paper recovery.', 'DZ check 2026-10-16: 2026 running rate unknown.'),
  ('wafa doux', 'a[iï]n oussera|djelfa', 'wafa', 'Wafa Doux 신규 통합 공장(Aïn Oussera, 2025-04-30 착공) — 펄프·위생지·판지 계획.', 'Wafa Doux, Aïn Oussera (Djelfa) - new integrated mill for pulp, hygiene paper and board, ground-breaking announced by AAPI 2025-04-30.', 'DZ check 2026-10-16: not running yet - design-stage talks.'),
  ('g[eé]n[eé]ral emballage', 'akbou|na[aâ]ma', 'g[eé]n[eé]ral emballage', 'Général Emballage(2002, Akbou 본사·Oran·Sétif 가공 3곳 약 26만 t, 1,300명+) — Naâma 신규 RCCM 원지공장 연 35만 t(400억 DZD, Andritz, 2025-04 착공·30개월).', 'Général Emballage (2002), HQ Akbou (Béjaïa) - largest Algerian corrugated maker, three converting plants (Akbou, Oran, Sétif) about 260,000 t/yr, over 1,300 staff. New recycled containerboard mill at Naâma: 350,000 t/yr, DZD 40 bn, 30 ha, Andritz line ordered (reported 2026-04), started 2025-04 with a 30-month build.', 'DZ check 2026-10-16: converting is not base paper - Naâma plan only in split.'),
  ('gipec', 'baba ali', 'gipec', 'GIPEC(1998 CELPAP+ENEPAC, SONIC 계보) 종이·판지·포장재·폐지 회수.', 'GIPEC (Groupe Industriel du Papier et de la Cellulose, formed 1998 of CELPAP and ENEPAC, SONIC lineage), Route de la Gare, Baba Ali - corrugated boxes, industrial packaging and waste-paper recovery.', 'DZ check 2026-10-16: paper machines and output to confirm. infogipec@gipec.dz.'),
  ('maghreb emballage', null, 'maghreb emballage', null, null, 'DZ check 2026-10-16: Corrugated packaging, Oran - base paper not confirmed - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'algeria_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('africaine paper|\mapm\M', 'rou[iï]ba', 'africaine|apm'),
  ('warak|faderco', 's[eé]tif', 'warak|faderco'),
  ('tonic', 'bou isma[iï]l', 'tonic'),
  ('wafa doux', 'a[iï]n oussera|djelfa', 'wafa'),
  ('g[eé]n[eé]ral emballage', 'akbou|na[aâ]ma', 'g[eé]n[eé]ral emballage'),
  ('gipec', 'baba ali', 'gipec'),
  ('maghreb emballage', null, 'maghreb emballage')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('africaine paper|\mapm\M', 'rou[iï]ba', 'africaine|apm', false,
   $pj${"owner": "APM", "priority": 1, "products": "Tissue jumbo rolls", "grades": ["Tissue"], "capacity_split": [{"label": "New line plan", "value_t": 30000}], "approach": "Pulp-saving tissue trial with ENOF GCC.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('warak|faderco', 's[eé]tif', 'warak|faderco', false,
   $pj${"owner": "Faderco Group", "priority": 2, "products": "Tissue jumbo rolls", "grades": ["Tissue"], "capacity": {"value": 30000, "unit": "metric_t", "year": "Company figure", "source": "faderco.dz"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Trial 1-3-5 pct."}, "approach": "FCC 1-5 pct stepwise trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tonic', 'bou isma[iï]l', 'tonic', false,
   $pj${"owner": "State", "priority": 3, "products": "Tissue base, liner, fluting, MG", "grades": ["Tissue", "Testliner", "MG paper"], "approach": "Check running lines, then trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wafa doux', 'a[iï]n oussera|djelfa', 'wafa', false,
   $pj${"owner": "Wafa Doux", "priority": 4, "products": "Hygiene paper, board (planned)", "grades": ["Tissue", "Board"], "approach": "Design-stage FCC proposal.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('g[eé]n[eé]ral emballage', 'akbou|na[aâ]ma', 'g[eé]n[eé]ral emballage', false,
   $pj${"owner": "Général Emballage", "priority": 5, "products": "Corrugated (converting), recycled containerboard (planned)", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "Naâma mill plan", "value_t": 350000}], "approach": "Strength-hold FCC for the Naâma design.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gipec', 'baba ali', 'gipec', false,
   $pj${"owner": "State", "products": "Paper, board, packaging", "grades": [], "approach": "Confirm machines first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('maghreb emballage', null, 'maghreb emballage', true,
   $pj${"owner": "Maghreb Emballage", "products": "Corrugated packaging, Oran - base paper not confirmed", "approach": "Converter.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'DZ', 'Algeria', 'medium',
   $cm$ENOF Oggaz GCC (100 kt, 2023) and BEXCAR calcite - tissue at APM Rouïba and Warak Sétif (30 kt), Tonic Industrie - Général Emballage 350 kt Naâma mill under construction$cm$,
   $cm$Algeria has real GCC capacity: state ENOF (SONAREM) opened a 100 kt/yr calcium carbonate plant at Oggaz in 2023 naming paper among uses, plus Mellal (70 kt), and BEXCAR grinds white calcite at Constantine (published PSD, too coarse for paper as is). No paper PCC. Mills: tissue at Africaine Paper Mills Rouïba (30 kt line planned) and Warak / Faderco Sétif (over 30 kt), Tonic Industrie Bou Ismaïl (tissue, liner, MG), new Wafa Doux integrated mill (Djelfa, 2025). Général Emballage converts about 260 kt corrugated and is building a 350 kt recycled containerboard mill at Naâma (Andritz). GIPEC and Maghreb Emballage mainly convert.$cm$,
   $cm${"fillers": "GCC: ENOF Oggaz and Mellal, BEXCAR, GPI, Frères DIB. Lime: Baslimane Chaux Berriane. No PCC.", "mills": "Tissue: APM, Warak / Faderco, Tonic Industrie. New: Wafa Doux, Général Emballage Naâma. Other: GIPEC. Context: Maghreb Emballage.", "strategy": "Local model: ENOF or BEXCAR GCC + MBG FCC process, trials at APM and Warak tissue lines, design-stage proposals to Naâma and Wafa Doux.", "risks": "Paper-grade fineness and wet slurry not confirmed, state-company processes.", "next_steps": ["Request ENOF Oggaz GCC samples and PSD", "Propose tissue trials to APM and Warak"], "key_numbers": [{"label": "ENOF Oggaz", "value": "100 kt/yr design (2023)"}, {"label": "Warak", "value": "over 30 kt tissue"}, {"label": "Naâma plan", "value": "350 kt containerboard"}], "files": ["seed_20261016zzr_algeria_mills_fillers"]}$cm$::jsonb,
   $cm$ENOF Oggaz GCC(10만 t, 2023)·BEXCAR 방해석 — APM Rouïba·Warak Sétif(3만 t) 티슈, Tonic Industrie — Général Emballage Naâma 35만 t 건설 중$cm$,
   $cm$알제리에는 실제 GCC 설비: 국영 ENOF(SONAREM) 2023 Oggaz 탄산칼슘 연 10만 t(제지 용도 명시)·Mellal 7만 t, BEXCAR Constantine 백색 방해석(입도 공개, 제지용으론 굵음). 제지용 PCC 없음. 제지: APM Rouïba 티슈(3만 t 라인 계획), Warak/Faderco Sétif(3만 t+), Tonic Industrie(티슈·라이너·MG), 신규 Wafa Doux(Djelfa, 2025). Général Emballage 골판지 가공 약 26만 t, Naâma 재생 골판지원지 35만 t 공장 건설 중(Andritz). GIPEC·Maghreb Emballage 는 주로 가공.$cm$,
   900, 13500,
   $cm$하한 Warak 3만 t × 3%, 상한 Warak + APM 신규 6만 t × 5% + Naâma 35만 t × 3% (계획 포함)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('africaine paper|\mapm\M', 'rou[iï]ba', 'africaine|apm'),
  ('warak|faderco', 's[eé]tif', 'warak|faderco'),
  ('tonic', 'bou isma[iï]l', 'tonic'),
  ('wafa doux', 'a[iï]n oussera|djelfa', 'wafa'),
  ('g[eé]n[eé]ral emballage', 'akbou|na[aâ]ma', 'g[eé]n[eé]ral emballage'),
  ('gipec', 'baba ali', 'gipec'),
  ('maghreb emballage', null, 'maghreb emballage')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'algeria_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'algeria_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '\menof\M|sonarem' or p.party_name ~* 'bexcar' or p.party_name ~* 'golden poudre' or p.party_name ~* 'baslimane|chaux berriane' or p.party_name ~* 'fr[eè]res dib|\msfdm\M')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'DZ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'DZ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'DZ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'DZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    