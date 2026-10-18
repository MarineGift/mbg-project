-- ============================================================
-- seed_20261016zzz_south_africa_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- South Africa update (reports 2026-10-16). Fixed generator.
-- Idwala and Omya Idwala guards are kept apart.
-- 1) Fillers if missing (3): Idwala Carbonates (Kulubrite), Omya Idwala SA,
--    Kalkor.
-- 2) Mills if missing (10) + plant blocks, priority 1-6: Mondi Merebank,
--    Sappi Stanger, Twinsaver, Mpact Springs, Mondi Richards Bay, Neopak.
--    No priority: Sappi Ngodwana and Tugela, Mpact Felixton, Kimberly-Clark.
--    Context (2): Saiccor (pulp), Piet Retief.
-- 3) app.country_markets ZA row (priority medium).
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
           v.party_name, 'ZA', v.region, v.city, v.website, 'active', 'south_africa_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('idwala.*(industrial|carbonate|holding)|kulubrite', 'Idwala Carbonates (Kulubrite)', 'Gauteng', 'Randpark Ridge', null, 'Idwala Industrial Holdings(본사 Randpark Ridge) 탄산칼슘 사업 — 석회석 채굴·정제·분쇄, Kulubrite Extra·PFG·2·5·10·15·45(약 0.6~45 μm), Kulucote 표면처리, 제지 용도 명시.', 'Idwala Industrial Holdings (HQ Randpark Ridge, Gauteng), Idwala Carbonates - limestone mining, refining and grinding to high-brightness GCC: Kulubrite Extra, PFG, 2, 5, 10, 15, 45 (about 0.6-45 micron) and coated Kulucote, paper named.', 'ZA check 2026-10-16: grade numbers are not D50 - get PSD per grade. Plant sites and wet slurry to confirm. Also Idwala Lime (PCC raw-material route). FCC co-production candidate 1.'),
  ('omya.?idwala|omya.*south africa', 'Omya Idwala SA - Johannesburg', 'Gauteng', 'Johannesburg', null, 'Omya International·Idwala 2020 합작 유통 — Johannesburg·Durban·Cape Town, 인쇄·필기·포장 시장. 현지 Kulubrite·Kulucote, 수입 SC PCC 10L/10/20·Omyabrite 1300X.', 'Omya Idwala SA (2020 JV of Omya International and Idwala) - carbonate and specialty chemicals distribution at Johannesburg, Durban and Cape Town, serving printing and writing and packaging. Local Kulubrite and Kulucote GCC plus imported SC PCC 10L, 10, 20 and Omyabrite 1300X-OM.', 'ZA check 2026-10-16: PCC is imported - no South African PCC plant found. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('kalkor', 'Kalkor - Johannesburg', 'Gauteng', 'Johannesburg', null, 'Kalkor(50년+) GCC·PCC·농업용 석회·맞춤 광물, 제지·플라스틱·도료·화학, 벌크·포장.', 'Kalkor (Pty) Ltd, Johannesburg (over 50 years) - GCC, PCC, agricultural lime and custom mineral blends for paper, plastics, paint, chemicals, bulk and bagged.', 'ZA check 2026-10-16: own manufacturing and paper PCC plant not confirmed - small OEM or distribution option.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%ZA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('idwala.*(industrial|carbonate|holding)|kulubrite', 'Idwala Carbonates (Kulubrite)', 'Gauteng', 'Randpark Ridge', null, 'Idwala Industrial Holdings(본사 Randpark Ridge) 탄산칼슘 사업 — 석회석 채굴·정제·분쇄, Kulubrite Extra·PFG·2·5·10·15·45(약 0.6~45 μm), Kulucote 표면처리, 제지 용도 명시.', 'Idwala Industrial Holdings (HQ Randpark Ridge, Gauteng), Idwala Carbonates - limestone mining, refining and grinding to high-brightness GCC: Kulubrite Extra, PFG, 2, 5, 10, 15, 45 (about 0.6-45 micron) and coated Kulucote, paper named.', 'ZA check 2026-10-16: grade numbers are not D50 - get PSD per grade. Plant sites and wet slurry to confirm. Also Idwala Lime (PCC raw-material route). FCC co-production candidate 1.'),
  ('omya.?idwala|omya.*south africa', 'Omya Idwala SA - Johannesburg', 'Gauteng', 'Johannesburg', null, 'Omya International·Idwala 2020 합작 유통 — Johannesburg·Durban·Cape Town, 인쇄·필기·포장 시장. 현지 Kulubrite·Kulucote, 수입 SC PCC 10L/10/20·Omyabrite 1300X.', 'Omya Idwala SA (2020 JV of Omya International and Idwala) - carbonate and specialty chemicals distribution at Johannesburg, Durban and Cape Town, serving printing and writing and packaging. Local Kulubrite and Kulucote GCC plus imported SC PCC 10L, 10, 20 and Omyabrite 1300X-OM.', 'ZA check 2026-10-16: PCC is imported - no South African PCC plant found. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('kalkor', 'Kalkor - Johannesburg', 'Gauteng', 'Johannesburg', null, 'Kalkor(50년+) GCC·PCC·농업용 석회·맞춤 광물, 제지·플라스틱·도료·화학, 벌크·포장.', 'Kalkor (Pty) Ltd, Johannesburg (over 50 years) - GCC, PCC, agricultural lime and custom mineral blends for paper, plastics, paint, chemicals, bulk and bagged.', 'ZA check 2026-10-16: own manufacturing and paper PCC plant not confirmed - small OEM or distribution option.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'south_africa_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Idwala Carbonates (Kulubrite)', 'GCC producer', 'Local paper GCC (Kulubrite) - candidate 1', 'merchant', 'B', 'gcc'),
  ('Omya Idwala SA - Johannesburg', 'GCC and PCC distributor', 'Omya JV - licensee group, imported PCC', 'merchant', 'B', 'pcc'),
  ('Kalkor - Johannesburg', 'GCC and PCC supplier', 'Mineral supplier - OEM option', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'south_africa_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'ZA', v.region, v.city, v.website, 'active', 'south_africa_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('merebank', 'merebank|durban', 'mondi', 'Mondi Merebank - Durban', 'KwaZulu-Natal', 'Durban', null, 'Mondi Merebank(Durban) 비도공 인쇄·필기용지·Rotatrim 복사용지, 초지기 1대 연 27만 t, 2025 Cradle to Cradle Bronze.', 'Mondi Merebank Mill, Durban - uncoated woodfree printing and writing paper and Mondi Rotatrim copy paper, one machine, 270,000 t/yr, Cradle to Cradle Certified Bronze (2025).', 'ZA check 2026-10-16: filler supplier and loading to confirm.'),
  ('sappi.*stanger|stanger', 'stanger|kwadukuza', 'sappi', 'Sappi Stanger - KwaDukuza', 'KwaZulu-Natal', 'KwaDukuza', null, 'Sappi Stanger(KwaDukuza) 바가스 기반 — 인쇄·필기 약 8.2만 t + 티슈 등 2.8만 t = 11만 t(2025), 자체 바가스 펄프 6만 t.', 'Sappi Stanger Mill, KwaDukuza (KwaZulu-Natal) - bagasse-based, printing and writing paper about 82,000 t plus tissue and other about 28,000 t, 110,000 t/yr (2025 report), own bleached bagasse pulp 60,000 t (not added).', 'ZA check 2026-10-16: office paper and tissue need separate trials.'),
  ('twinsaver', 'kliprivier|bellville', 'twinsaver', 'Twinsaver - Kliprivier', 'Gauteng', 'Kliprivier', null, 'Twinsaver(구 Nampak Tissue, 본사 Bryanston) — Kliprivier·Bellville 제조, Pretoria West 가공, 화장지·미용티슈·타월, 100% 재생 Econo 1-Ply.', 'Twinsaver Group (formerly Nampak Tissue, HQ Bryanston) - manufacturing at Kliprivier and Bellville, converting at Pretoria West, toilet, facial, kitchen and hand towels, incl. 100 pct recycled Econo 1-Ply.', 'ZA check 2026-10-16: confirm which sites run tissue machines.'),
  ('mpact.*springs|springs', 'springs', 'mpact', 'Mpact Springs', 'Gauteng', 'Springs', null, 'Mpact Springs 재생섬유 백색 코팅 판지·특수 판지 연 13.7만 t.', 'Mpact Springs Mill (Gauteng) - recycled-fibre white-lined coated board and specialty board, 137,000 t/yr.', 'ZA check 2026-10-16: check ply furnish and coating set-up first.'),
  ('richards bay', 'richards bay', 'mondi', 'Mondi Richards Bay', 'KwaZulu-Natal', 'Richards Bay', null, 'Mondi Richards Bay(1984) — Baycel 유칼립투스 표백 펄프, Baywhite 백색 표면 크라프트 라이너.', 'Mondi Richards Bay Mill (1984) - Baycel bleached eucalyptus pulp and Baywhite white-top kraftliner.', 'ZA check 2026-10-16: white-top ply only.'),
  ('neopak|rosslyn', 'rosslyn|pretoria', 'neopak', 'Neopak - Rosslyn', 'Gauteng', 'Rosslyn', null, 'Neopak(1969~, Rosslyn Pretoria) 재생 라이너·골심지·코어보드·석고보드 원지 — PM3 약 8.5만 t(2024 ABB).', 'Neopak, Rosslyn (Pretoria) - recycled fibre since 1969, liner, fluting, coreboard and gypsum-board liner, PM3 about 85,000 t/yr (ABB, 2024).', 'ZA check 2026-10-16: PM3 figure is not the site total.'),
  ('sappi.*ngodwana|ngodwana', 'ngodwana', 'sappi', 'Sappi Ngodwana', 'Mpumalanga', 'Ngodwana', null, 'Sappi Ngodwana 라이너보드·신문용지·크라프트 연 35만 t.', 'Sappi Ngodwana Mill - linerboard, newsprint and kraft paper, 350,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('sappi.*tugela|tugela', 'tugela|mandeni', 'sappi', 'Sappi Tugela', 'KwaZulu-Natal', 'Mandeni', null, 'Sappi Tugela 골심지 연 20만 t.', 'Sappi Tugela Mill (Mandeni) - corrugating medium, 200,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('mpact.*felixton|felixton', 'felixton', 'mpact', 'Mpact Felixton', 'KwaZulu-Natal', 'Felixton', null, 'Mpact Felixton 재생 라이너·골심지 연 21.5만 t.', 'Mpact Felixton Mill - recycled linerboard and fluting, 215,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('kimberly.*(south africa|enstra|springs)', 'enstra|springs', 'kimberly', 'Kimberly-Clark South Africa', null, null, null, 'Kimberly-Clark 남아공 티슈·위생지.', 'Kimberly-Clark South Africa - tissue and hygiene products.', 'ZA check 2026-10-16: sites and machines to collect.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%ZA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('merebank', 'merebank|durban', 'mondi', 'Mondi Merebank(Durban) 비도공 인쇄·필기용지·Rotatrim 복사용지, 초지기 1대 연 27만 t, 2025 Cradle to Cradle Bronze.', 'Mondi Merebank Mill, Durban - uncoated woodfree printing and writing paper and Mondi Rotatrim copy paper, one machine, 270,000 t/yr, Cradle to Cradle Certified Bronze (2025).', 'ZA check 2026-10-16: filler supplier and loading to confirm.'),
  ('sappi.*stanger|stanger', 'stanger|kwadukuza', 'sappi', 'Sappi Stanger(KwaDukuza) 바가스 기반 — 인쇄·필기 약 8.2만 t + 티슈 등 2.8만 t = 11만 t(2025), 자체 바가스 펄프 6만 t.', 'Sappi Stanger Mill, KwaDukuza (KwaZulu-Natal) - bagasse-based, printing and writing paper about 82,000 t plus tissue and other about 28,000 t, 110,000 t/yr (2025 report), own bleached bagasse pulp 60,000 t (not added).', 'ZA check 2026-10-16: office paper and tissue need separate trials.'),
  ('twinsaver', 'kliprivier|bellville', 'twinsaver', 'Twinsaver(구 Nampak Tissue, 본사 Bryanston) — Kliprivier·Bellville 제조, Pretoria West 가공, 화장지·미용티슈·타월, 100% 재생 Econo 1-Ply.', 'Twinsaver Group (formerly Nampak Tissue, HQ Bryanston) - manufacturing at Kliprivier and Bellville, converting at Pretoria West, toilet, facial, kitchen and hand towels, incl. 100 pct recycled Econo 1-Ply.', 'ZA check 2026-10-16: confirm which sites run tissue machines.'),
  ('mpact.*springs|springs', 'springs', 'mpact', 'Mpact Springs 재생섬유 백색 코팅 판지·특수 판지 연 13.7만 t.', 'Mpact Springs Mill (Gauteng) - recycled-fibre white-lined coated board and specialty board, 137,000 t/yr.', 'ZA check 2026-10-16: check ply furnish and coating set-up first.'),
  ('richards bay', 'richards bay', 'mondi', 'Mondi Richards Bay(1984) — Baycel 유칼립투스 표백 펄프, Baywhite 백색 표면 크라프트 라이너.', 'Mondi Richards Bay Mill (1984) - Baycel bleached eucalyptus pulp and Baywhite white-top kraftliner.', 'ZA check 2026-10-16: white-top ply only.'),
  ('neopak|rosslyn', 'rosslyn|pretoria', 'neopak', 'Neopak(1969~, Rosslyn Pretoria) 재생 라이너·골심지·코어보드·석고보드 원지 — PM3 약 8.5만 t(2024 ABB).', 'Neopak, Rosslyn (Pretoria) - recycled fibre since 1969, liner, fluting, coreboard and gypsum-board liner, PM3 about 85,000 t/yr (ABB, 2024).', 'ZA check 2026-10-16: PM3 figure is not the site total.'),
  ('sappi.*ngodwana|ngodwana', 'ngodwana', 'sappi', 'Sappi Ngodwana 라이너보드·신문용지·크라프트 연 35만 t.', 'Sappi Ngodwana Mill - linerboard, newsprint and kraft paper, 350,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('sappi.*tugela|tugela', 'tugela|mandeni', 'sappi', 'Sappi Tugela 골심지 연 20만 t.', 'Sappi Tugela Mill (Mandeni) - corrugating medium, 200,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('mpact.*felixton|felixton', 'felixton', 'mpact', 'Mpact Felixton 재생 라이너·골심지 연 21.5만 t.', 'Mpact Felixton Mill - recycled linerboard and fluting, 215,000 t/yr.', 'ZA check 2026-10-16: strength-led.'),
  ('kimberly.*(south africa|enstra|springs)', 'enstra|springs', 'kimberly', 'Kimberly-Clark 남아공 티슈·위생지.', 'Kimberly-Clark South Africa - tissue and hygiene products.', 'ZA check 2026-10-16: sites and machines to collect.'),
  ('saiccor|umkomaas', null, 'saiccor|umkomaas', null, null, 'ZA check 2026-10-16: Saiccor dissolving pulp 890 kt - no paper machine - context only.'),
  ('piet retief|mkhondo', null, 'piet retief|mkhondo', null, null, 'ZA check 2026-10-16: Piet Retief / Mkhondo liner and fluting - capacity to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'south_africa_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('merebank', 'merebank|durban', 'mondi'),
  ('sappi.*stanger|stanger', 'stanger|kwadukuza', 'sappi'),
  ('twinsaver', 'kliprivier|bellville', 'twinsaver'),
  ('mpact.*springs|springs', 'springs', 'mpact'),
  ('richards bay', 'richards bay', 'mondi'),
  ('neopak|rosslyn', 'rosslyn|pretoria', 'neopak'),
  ('sappi.*ngodwana|ngodwana', 'ngodwana', 'sappi'),
  ('sappi.*tugela|tugela', 'tugela|mandeni', 'sappi'),
  ('mpact.*felixton|felixton', 'felixton', 'mpact'),
  ('kimberly.*(south africa|enstra|springs)', 'enstra|springs', 'kimberly'),
  ('saiccor|umkomaas', null, 'saiccor|umkomaas'),
  ('piet retief|mkhondo', null, 'piet retief|mkhondo')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('merebank', 'merebank|durban', 'mondi', false,
   $pj${"owner": "Mondi", "priority": 1, "products": "UWF, copy paper (Rotatrim)", "grades": ["UWF", "Copy paper"], "machines": 1, "capacity": {"value": 270000, "unit": "metric_t", "year": "Company figure", "source": "mondigroup.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct running, 5 pct."}, "pitch": "Mondi + Idwala GCC + MBG UWF trial", "approach": "Lead South African account - Mondi group link (Neusiedler, SCP, Štětí).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*stanger|stanger', 'stanger|kwadukuza', 'sappi', false,
   $pj${"owner": "Sappi", "priority": 2, "products": "Bagasse office paper and tissue", "grades": ["UWF", "Tissue"], "capacity": {"value": 110000, "unit": "metric_t", "year": "Sappi 2025 report", "source": "sappi.com"}, "capacity_split": [{"label": "Printing and writing", "value_t": 82000}, {"label": "Tissue and other", "value_t": 28000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Bagasse UWF plus tissue."}, "approach": "Two trials (UWF and tissue) - link with QPIC (EG) bagasse.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('twinsaver', 'kliprivier|bellville', 'twinsaver', false,
   $pj${"owner": "Twinsaver", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "approach": "Economy recycled tissue trial first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mpact.*springs|springs', 'springs', 'mpact', false,
   $pj${"owner": "Mpact", "priority": 4, "products": "White-lined coated board", "grades": ["WLC"], "capacity": {"value": 137000, "unit": "metric_t", "year": "Company figure", "source": "mpact.co.za"}, "approach": "Top or middle ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('richards bay', 'richards bay', 'mondi', false,
   $pj${"owner": "Mondi", "priority": 5, "products": "White-top kraftliner, pulp", "grades": ["White-top liner"], "approach": "White-top ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('neopak|rosslyn', 'rosslyn|pretoria', 'neopak', false,
   $pj${"owner": "Neopak", "priority": 6, "products": "Recycled liner, fluting, coreboard", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "PM3", "value_t": 85000}], "approach": "Drainage and cost-saving trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*ngodwana|ngodwana', 'ngodwana', 'sappi', false,
   $pj${"owner": "Sappi", "products": "Linerboard, newsprint, kraft", "grades": ["Kraftliner", "Newsprint"], "capacity": {"value": 350000, "unit": "metric_t", "year": "Sappi 2025 report", "source": "sappi.com"}, "approach": "Later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sappi.*tugela|tugela', 'tugela|mandeni', 'sappi', false,
   $pj${"owner": "Sappi", "products": "Corrugating medium", "grades": ["Medium"], "capacity": {"value": 200000, "unit": "metric_t", "year": "Sappi 2025 report", "source": "sappi.com"}, "approach": "Later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mpact.*felixton|felixton', 'felixton', 'mpact', false,
   $pj${"owner": "Mpact", "products": "Recycled liner, fluting", "grades": ["Testliner", "Medium"], "capacity": {"value": 215000, "unit": "metric_t", "year": "Company figure", "source": "mpact.co.za"}, "approach": "Later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kimberly.*(south africa|enstra|springs)', 'enstra|springs', 'kimberly', false,
   $pj${"owner": "Kimberly-Clark", "products": "Tissue", "grades": ["Tissue"], "approach": "Details first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saiccor|umkomaas', null, 'saiccor|umkomaas', true,
   $pj${"owner": "Sappi", "products": "Saiccor dissolving pulp 890 kt - no paper machine", "approach": "Pulp or liner.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('piet retief|mkhondo', null, 'piet retief|mkhondo', true,
   $pj${"owner": "Mpact", "products": "Piet Retief / Mkhondo liner and fluting - capacity to confirm", "approach": "Pulp or liner.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'ZA', 'South Africa', 'medium',
   $cm$Mondi Merebank UWF (270 kt) and Sappi Stanger bagasse UWF and tissue (110 kt) - Twinsaver tissue - Idwala Kulubrite GCC, Omya Idwala JV (imported PCC)$cm$,
   $cm$South Africa has Africa's deepest paper base. FCC-fit: Mondi Merebank (UWF and Rotatrim copy, 270 kt), Sappi Stanger (bagasse office paper 82 kt and tissue 28 kt), Twinsaver tissue (Kliprivier, Bellville), Mpact Springs white-lined board (137 kt), Mondi Richards Bay white-top liner. Strength-led: Sappi Ngodwana (350 kt) and Tugela (200 kt), Mpact Felixton (215 kt), Neopak Rosslyn. Sappi SA paper capacity about 660 kt. Fillers: Idwala Carbonates (Kulubrite paper GCC, local), Omya Idwala SA JV (2020, imported SC PCC), Kalkor. No local paper PCC plant.$cm$,
   $cm${"fillers": "GCC: Idwala Carbonates (Kulubrite). Distribution and imported PCC: Omya Idwala SA. Other: Kalkor.", "mills": "UWF: Mondi Merebank, Sappi Stanger. Tissue: Sappi Stanger, Twinsaver, Kimberly-Clark. Board: Mpact Springs, Mondi Richards Bay. Liner: Sappi Ngodwana and Tugela, Mpact Felixton, Neopak. Context: Saiccor (pulp), Piet Retief.", "strategy": "KwaZulu-Natal cluster: Idwala GCC + MBG FCC, trials at Mondi Merebank (UWF) and Sappi Stanger (bagasse UWF and tissue), then Twinsaver tissue. Omya Idwala involves Omya - NDA and IP scope first.", "risks": "Omya competing tech via the JV, unknown filler contracts.", "next_steps": ["Request Kulubrite paper-grade PSD of Idwala", "Propose a UWF trial to Mondi Merebank"], "key_numbers": [{"label": "Mondi Merebank", "value": "270 kt UWF"}, {"label": "Sappi Stanger", "value": "110 kt (82 UWF + 28 tissue)"}, {"label": "Sappi SA paper", "value": "about 660 kt"}], "files": ["seed_20261016zzz_south_africa_mills_fillers"]}$cm$::jsonb,
   $cm$Mondi Merebank UWF(27만 t)·Sappi Stanger 바가스 UWF·티슈(11만 t) — Twinsaver 티슈 — Idwala Kulubrite GCC, Omya Idwala 합작(수입 PCC)$cm$,
   $cm$남아공은 아프리카 최대 제지 기반. FCC 적합: Mondi Merebank(UWF·Rotatrim 복사 27만 t), Sappi Stanger(바가스 사무용지 8.2만 + 티슈 2.8만 t), Twinsaver 티슈(Kliprivier·Bellville), Mpact Springs 백색 코팅 판지(13.7만 t), Mondi Richards Bay 백색 라이너. 강도 위주: Sappi Ngodwana(35만)·Tugela(20만), Mpact Felixton(21.5만), Neopak Rosslyn. 충전제: Idwala Carbonates(Kulubrite 현지 GCC), Omya Idwala SA 합작(2020, 수입 SC PCC), Kalkor. 현지 제지용 PCC 공장 없음.$cm$,
   10560, 19000,
   $cm$Merebank 27만 + Stanger P&W 8.2만 t × 3% ~ + Stanger 티슈 2.8만 t, × 5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('merebank', 'merebank|durban', 'mondi'),
  ('sappi.*stanger|stanger', 'stanger|kwadukuza', 'sappi'),
  ('twinsaver', 'kliprivier|bellville', 'twinsaver'),
  ('mpact.*springs|springs', 'springs', 'mpact'),
  ('richards bay', 'richards bay', 'mondi'),
  ('neopak|rosslyn', 'rosslyn|pretoria', 'neopak'),
  ('sappi.*ngodwana|ngodwana', 'ngodwana', 'sappi'),
  ('sappi.*tugela|tugela', 'tugela|mandeni', 'sappi'),
  ('mpact.*felixton|felixton', 'felixton', 'mpact'),
  ('kimberly.*(south africa|enstra|springs)', 'enstra|springs', 'kimberly'),
  ('saiccor|umkomaas', null, 'saiccor|umkomaas'),
  ('piet retief|mkhondo', null, 'piet retief|mkhondo')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'south_africa_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'south_africa_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'idwala.*(industrial|carbonate|holding)|kulubrite' or p.party_name ~* 'omya.?idwala|omya.*south africa' or p.party_name ~* 'kalkor')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'ZA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'ZA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ZA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ZA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    