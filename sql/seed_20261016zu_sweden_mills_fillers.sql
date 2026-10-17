-- ============================================================
-- seed_20261016zu_sweden_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Sweden update (reports 2026-10-16). Existing SE rows likely.
-- Norrköping has Holmen Braviken and Fiskeby - owner regex keeps them apart.
-- 1) Fillers if missing (4): Omya Sweden (historical), Imerys Husum and
--    Tunadal (historical), Imerys Köping GCC (historical), Nordkalk Köping.
-- 2) Mills if missing (13) + plant blocks, priority 1-10: Arctic Paper
--    Munkedals and Grycksbo, Holmen Braviken and Hallsta, Metsä Tissue,
--    Essity Lilla Edet, Stora Enso Fors, Fiskeby, SCA Munksund, Nordic Paper
--    Bäckhammar. No priority: Skoghall, Obbola, Iggesund. Context (11).
-- 3) app.country_markets SE row (priority high).
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
           v.party_name, 'SE', v.region, v.city, v.website, 'active', 'sweden_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(nym[oö]lla|sweden|sverige|persberg)', 'Omya Sweden - Nymölla and Persberg (historical)', 'Skåne', 'Nymölla', null, 'Omya 스웨덴 과거 거점 — Nymölla 위성 PCC(1992, Stora Enso 제지공장 공급), Persberg GCC 슬러리, Lessebo PCC(연 약 6,000 t, 2000년대 초 비가동).', 'Omya in Sweden (2004-2006 records) - satellite PCC at Nymölla opened 1992 for the then Stora Enso mill, GCC slurry plant at Persberg, small PCC unit at Lessebo (about 6,000 t/yr, idle in the early 2000s). Omya announced European carbonate capacity consolidation in 2023.', 'SE check 2026-10-16: all historical - 2026 status of each site to confirm. Royalty licensee at Omya HQ level.'),
  ('imerys.*(husum|tunadal|sweden)', 'Imerys Sweden - Husum and Tunadal (historical)', 'Västernorrland', 'Husum', null, 'Imerys 2004 투자(약 3,500만 유로) — Husum 위성 PCC(M-real 제지공장)·Tunadal GCC 확장, 2005 가동.', 'Imerys investments announced 2004 (about EUR 35 m): satellite PCC at Husum for the then M-real mill and GCC expansion at Tunadal (Sundsvall), both started 2005.', 'SE check 2026-10-16: Imerys sold its paper minerals to Flacks Group in 2024 - current owner and status to confirm.'),
  ('imerys.*k[oö]ping', 'Imerys - Köping GCC (historical)', 'Västmanland', 'Köping', null, 'Imerys Köping GCC 분쇄 — 수입 대리석(Carrara·노르웨이), 2005 무렵 연 약 12만 t.', 'Imerys GCC grinding plant at Köping using imported Carrara and Norwegian marble, about 120,000 t/yr around 2005.', 'SE check 2026-10-16: historical figure, owner after the 2024 Flacks sale to confirm.'),
  ('nordkalk.*(k[oö]ping|sweden)', 'Nordkalk - Köping', 'Västmanland', 'Köping', null, 'Nordkalk 스웨덴 Köping(Kungsängsvägen 22) — 채석장·분쇄·석회로·소석회·항만, 철강·제지 고객. 제지용 GCC 는 핀란드 Lappeenranta(Suomen Karbonaatti).', 'Nordkalk Köping, Kungsängsvägen 22 - quarry, grinding, lime kilns, hydrated lime and port, customers in steel and paper. Paper-grade GCC is made in Finland (Lappeenranta, Suomen Karbonaatti).', 'SE check 2026-10-16: ground limestone, not paper GCC slurry. +46 10 47 62 500. Not added: Minerals Technologies (no Swedish plant identified).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(nym[oö]lla|sweden|sverige|persberg)', 'Omya Sweden - Nymölla and Persberg (historical)', 'Skåne', 'Nymölla', null, 'Omya 스웨덴 과거 거점 — Nymölla 위성 PCC(1992, Stora Enso 제지공장 공급), Persberg GCC 슬러리, Lessebo PCC(연 약 6,000 t, 2000년대 초 비가동).', 'Omya in Sweden (2004-2006 records) - satellite PCC at Nymölla opened 1992 for the then Stora Enso mill, GCC slurry plant at Persberg, small PCC unit at Lessebo (about 6,000 t/yr, idle in the early 2000s). Omya announced European carbonate capacity consolidation in 2023.', 'SE check 2026-10-16: all historical - 2026 status of each site to confirm. Royalty licensee at Omya HQ level.'),
  ('imerys.*(husum|tunadal|sweden)', 'Imerys Sweden - Husum and Tunadal (historical)', 'Västernorrland', 'Husum', null, 'Imerys 2004 투자(약 3,500만 유로) — Husum 위성 PCC(M-real 제지공장)·Tunadal GCC 확장, 2005 가동.', 'Imerys investments announced 2004 (about EUR 35 m): satellite PCC at Husum for the then M-real mill and GCC expansion at Tunadal (Sundsvall), both started 2005.', 'SE check 2026-10-16: Imerys sold its paper minerals to Flacks Group in 2024 - current owner and status to confirm.'),
  ('imerys.*k[oö]ping', 'Imerys - Köping GCC (historical)', 'Västmanland', 'Köping', null, 'Imerys Köping GCC 분쇄 — 수입 대리석(Carrara·노르웨이), 2005 무렵 연 약 12만 t.', 'Imerys GCC grinding plant at Köping using imported Carrara and Norwegian marble, about 120,000 t/yr around 2005.', 'SE check 2026-10-16: historical figure, owner after the 2024 Flacks sale to confirm.'),
  ('nordkalk.*(k[oö]ping|sweden)', 'Nordkalk - Köping', 'Västmanland', 'Köping', null, 'Nordkalk 스웨덴 Köping(Kungsängsvägen 22) — 채석장·분쇄·석회로·소석회·항만, 철강·제지 고객. 제지용 GCC 는 핀란드 Lappeenranta(Suomen Karbonaatti).', 'Nordkalk Köping, Kungsängsvägen 22 - quarry, grinding, lime kilns, hydrated lime and port, customers in steel and paper. Paper-grade GCC is made in Finland (Lappeenranta, Suomen Karbonaatti).', 'SE check 2026-10-16: ground limestone, not paper GCC slurry. +46 10 47 62 500. Not added: Minerals Technologies (no Swedish plant identified).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'sweden_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Sweden - Nymölla and Persberg (historical)', 'GCC and PCC supplier', 'Omya Sweden - historical sites, licensee group', 'satellite', 'C', 'pcc'),
  ('Imerys Sweden - Husum and Tunadal (historical)', 'PCC and GCC producer', 'Ex-Imerys satellite PCC and GCC - owner to confirm', 'satellite', 'C', 'pcc'),
  ('Imerys - Köping GCC (historical)', 'GCC producer', 'Ex-Imerys GCC Köping - owner to confirm', 'merchant', 'C', 'gcc'),
  ('Nordkalk - Köping', 'Lime and limestone producer', 'Limestone and lime - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'sweden_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'SE', v.region, v.city, v.website, 'active', 'sweden_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('munkedal', 'munkedal', 'arctic paper', 'Arctic Paper Munkedals - Munkedal', 'Västra Götaland', 'Munkedal', null, 'Arctic Paper Munkedals — Munken·Amber 고급 비코팅 인쇄용지, 2대, 연 약 14.5만 t, 수출 88%(2024).', 'Arctic Paper Munkedals, Munkedal (north of Gothenburg) - premium uncoated printing papers Munken and Amber on two machines, about 145,000 t/yr, 88 pct exported (2024).', 'SE check 2026-10-16: technical and quality contacts listed on the company site.'),
  ('grycksbo', 'grycksbo', 'arctic paper', 'Arctic Paper Grycksbo - Grycksbo', 'Dalarna', 'Grycksbo', null, 'Arctic Paper Grycksbo — G-Silk·G-Print 코팅 인쇄용지, 2대, 연 약 20만 t, 수출 92%(2024).', 'Arctic Paper Grycksbo (Dalarna) - coated printing papers G-Silk and G-Print on two machines, about 200,000 t/yr, 92 pct exported (2024).', 'SE check 2026-10-16: base-paper filler and coating are separate trials.'),
  ('braviken', 'braviken|norrk[oö]ping', 'holmen', 'Holmen Braviken - Norrköping', 'Östergötland', 'Norrköping', null, 'Holmen Braviken — 서적·잡지·상업 인쇄용지.', 'Holmen Braviken paper mill near Norrköping - book, magazine and commercial printing papers.', 'SE check 2026-10-16: capacity not public here. Same group as Holmen Workington (UK).'),
  ('hallsta', 'hallstavik', 'holmen', 'Holmen Hallsta - Hallstavik', 'Stockholm', 'Hallstavik', null, 'Holmen Hallsta — 인쇄·출판용지.', 'Holmen Hallsta paper mill, Hallstavik - printing and publishing papers.', 'SE check 2026-10-16: capacity not public here.'),
  ('katrinefors|mets[aä] tissue.*mariestad', 'mariestad', 'mets[aä]', 'Metsä Tissue Katrinefors - Mariestad', 'Västra Götaland', 'Mariestad', null, 'Metsä Tissue 스웨덴 — Katrinefors(Mariestad, Lambi·Serla·Katrin), Pauliström·Nyboholm(Småland).', 'Metsä Tissue in Sweden - Katrinefors mill at Mariestad (Lambi, Serla, Katrin) plus Pauliström and Nyboholm (Småland) for Lambi and private labels.', 'SE check 2026-10-16: one row for the three Swedish mills - capacity not public here.'),
  ('lilla edet', 'lilla edet', 'essity', 'Essity - Lilla Edet', 'Västra Götaland', 'Lilla Edet', null, 'Essity Lilla Edet 가정용·업무용 티슈.', 'Essity Lilla Edet (near Gothenburg) - consumer and AfH tissue.', 'SE check 2026-10-16: capacity not public here.'),
  ('stora enso.*fors|\mfors\M', 'fors|avesta', 'stora enso', 'Stora Enso Fors', 'Dalarna', 'Fors', null, 'Stora Enso Fors 고급 폴딩박스 판지 연 약 45.5만 t(펄프 22만 t 별도).', 'Stora Enso Fors mill - premium folding boxboard about 455,000 t/yr (pulp about 220,000 t/yr, not added).', 'SE check 2026-10-16: ply-level fit only.'),
  ('fiskeby', 'norrk[oö]ping', 'fiskeby', 'Fiskeby Board - Norrköping', 'Östergötland', 'Norrköping', null, 'Fiskeby Board 재생섬유 판지 KM1 연 약 17만 t(280~500 g/m², 코팅 2기).', 'Fiskeby Board, Norrköping - recycled-fibre cartonboard on KM1, about 170,000 t/yr, 280-500 g/m2, two coaters.', 'SE check 2026-10-16: check furnish ash first.'),
  ('munksund', 'munksund|pite', '\msca\M|svenska cellulosa', 'SCA Munksund - Piteå', 'Norrbotten', 'Piteå', null, 'SCA Munksund 백색·갈색 크라프트라이너 연 약 40만 t.', 'SCA Munksund (Piteå) - white-top and brown kraftliner, about 400,000 t/yr.', 'SE check 2026-10-16: white-top ply is the only fit.'),
  ('b[aä]ckhammar', 'b[aä]ckhammar', 'nordic paper', 'Nordic Paper Bäckhammar', 'Värmland', 'Bäckhammar', null, 'Nordic Paper Bäckhammar 고강도 크라프트지 연 15.9만 t(펄프 23만 t 별도).', 'Nordic Paper Bäckhammar (Värmland) - high-strength kraft paper 159,000 t/yr (pulp 230,000 t/yr, not added). Sister mills Åmotfors (50,000 t/yr kraft and absorbent) and Säffle (greaseproof).', 'SE check 2026-10-16: strength and porosity critical.'),
  ('skoghall', 'skoghall', 'stora enso', 'Stora Enso Skoghall', 'Värmland', 'Skoghall', null, 'Stora Enso Skoghall 액체·식품 포장용 판지 연 약 100만 t(펄프 70만 t 별도).', 'Stora Enso Skoghall - liquid and food packaging board about 1,000,000 t/yr (pulp about 700,000 t/yr, not added).', 'SE check 2026-10-16: food-contact rules - later.'),
  ('obbola', 'obbola', '\msca\M|svenska cellulosa', 'SCA Obbola', 'Västerbotten', 'Obbola', null, 'SCA Obbola 크라프트라이너 연 약 72.5만 t(2022 말 신규 대형 초지기).', 'SCA Obbola (Umeå) - kraftliner about 725,000 t/yr on the large machine started late 2022.', 'SE check 2026-10-16: strength-led.'),
  ('iggesund', 'iggesund', 'holmen', 'Holmen Iggesund', 'Gävleborg', 'Iggesund', null, 'Holmen Iggesund 고급 SBS·백판지(Invercote).', 'Holmen Iggesund mill - premium solid bleached board (Invercote).', 'SE check 2026-10-16: capacity not public here.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('munkedal', 'munkedal', 'arctic paper', 'Arctic Paper Munkedals — Munken·Amber 고급 비코팅 인쇄용지, 2대, 연 약 14.5만 t, 수출 88%(2024).', 'Arctic Paper Munkedals, Munkedal (north of Gothenburg) - premium uncoated printing papers Munken and Amber on two machines, about 145,000 t/yr, 88 pct exported (2024).', 'SE check 2026-10-16: technical and quality contacts listed on the company site.'),
  ('grycksbo', 'grycksbo', 'arctic paper', 'Arctic Paper Grycksbo — G-Silk·G-Print 코팅 인쇄용지, 2대, 연 약 20만 t, 수출 92%(2024).', 'Arctic Paper Grycksbo (Dalarna) - coated printing papers G-Silk and G-Print on two machines, about 200,000 t/yr, 92 pct exported (2024).', 'SE check 2026-10-16: base-paper filler and coating are separate trials.'),
  ('braviken', 'braviken|norrk[oö]ping', 'holmen', 'Holmen Braviken — 서적·잡지·상업 인쇄용지.', 'Holmen Braviken paper mill near Norrköping - book, magazine and commercial printing papers.', 'SE check 2026-10-16: capacity not public here. Same group as Holmen Workington (UK).'),
  ('hallsta', 'hallstavik', 'holmen', 'Holmen Hallsta — 인쇄·출판용지.', 'Holmen Hallsta paper mill, Hallstavik - printing and publishing papers.', 'SE check 2026-10-16: capacity not public here.'),
  ('katrinefors|mets[aä] tissue.*mariestad', 'mariestad', 'mets[aä]', 'Metsä Tissue 스웨덴 — Katrinefors(Mariestad, Lambi·Serla·Katrin), Pauliström·Nyboholm(Småland).', 'Metsä Tissue in Sweden - Katrinefors mill at Mariestad (Lambi, Serla, Katrin) plus Pauliström and Nyboholm (Småland) for Lambi and private labels.', 'SE check 2026-10-16: one row for the three Swedish mills - capacity not public here.'),
  ('lilla edet', 'lilla edet', 'essity', 'Essity Lilla Edet 가정용·업무용 티슈.', 'Essity Lilla Edet (near Gothenburg) - consumer and AfH tissue.', 'SE check 2026-10-16: capacity not public here.'),
  ('stora enso.*fors|\mfors\M', 'fors|avesta', 'stora enso', 'Stora Enso Fors 고급 폴딩박스 판지 연 약 45.5만 t(펄프 22만 t 별도).', 'Stora Enso Fors mill - premium folding boxboard about 455,000 t/yr (pulp about 220,000 t/yr, not added).', 'SE check 2026-10-16: ply-level fit only.'),
  ('fiskeby', 'norrk[oö]ping', 'fiskeby', 'Fiskeby Board 재생섬유 판지 KM1 연 약 17만 t(280~500 g/m², 코팅 2기).', 'Fiskeby Board, Norrköping - recycled-fibre cartonboard on KM1, about 170,000 t/yr, 280-500 g/m2, two coaters.', 'SE check 2026-10-16: check furnish ash first.'),
  ('munksund', 'munksund|pite', '\msca\M|svenska cellulosa', 'SCA Munksund 백색·갈색 크라프트라이너 연 약 40만 t.', 'SCA Munksund (Piteå) - white-top and brown kraftliner, about 400,000 t/yr.', 'SE check 2026-10-16: white-top ply is the only fit.'),
  ('b[aä]ckhammar', 'b[aä]ckhammar', 'nordic paper', 'Nordic Paper Bäckhammar 고강도 크라프트지 연 15.9만 t(펄프 23만 t 별도).', 'Nordic Paper Bäckhammar (Värmland) - high-strength kraft paper 159,000 t/yr (pulp 230,000 t/yr, not added). Sister mills Åmotfors (50,000 t/yr kraft and absorbent) and Säffle (greaseproof).', 'SE check 2026-10-16: strength and porosity critical.'),
  ('skoghall', 'skoghall', 'stora enso', 'Stora Enso Skoghall 액체·식품 포장용 판지 연 약 100만 t(펄프 70만 t 별도).', 'Stora Enso Skoghall - liquid and food packaging board about 1,000,000 t/yr (pulp about 700,000 t/yr, not added).', 'SE check 2026-10-16: food-contact rules - later.'),
  ('obbola', 'obbola', '\msca\M|svenska cellulosa', 'SCA Obbola 크라프트라이너 연 약 72.5만 t(2022 말 신규 대형 초지기).', 'SCA Obbola (Umeå) - kraftliner about 725,000 t/yr on the large machine started late 2022.', 'SE check 2026-10-16: strength-led.'),
  ('iggesund', 'iggesund', 'holmen', 'Holmen Iggesund 고급 SBS·백판지(Invercote).', 'Holmen Iggesund mill - premium solid bleached board (Invercote).', 'SE check 2026-10-16: capacity not public here.'),
  ('gruv[oö]n', null, 'gruv[oö]n', null, null, 'SE check 2026-10-16: Gruvön liner, fluting, liquid packaging board - context only.'),
  ('fr[oö]vi|rockhammar', null, 'fr[oö]vi|rockhammar', null, null, 'SE check 2026-10-16: Frövi / Rockhammar packaging and liquid board - context only.'),
  ('billerud.*g[aä]vle|g[aä]vle.*billerud', null, 'billerud.*g[aä]vle|g[aä]vle.*billerud', null, null, 'SE check 2026-10-16: Gävle liquid packaging board, liner - context only.'),
  ('sk[aä]rblacka', null, 'sk[aä]rblacka', null, null, 'SE check 2026-10-16: Skärblacka white MG kraft, sack, fluting - context only.'),
  ('karlsborg', null, 'karlsborg', null, null, 'SE check 2026-10-16: Karlsborg FibreForm, kraft, sack, pulp - context only.'),
  ('[aå]motfors', null, '[aå]motfors', null, null, 'SE check 2026-10-16: Åmotfors kraft and absorbent paper 50 kt - context only.'),
  ('s[aä]ffle', null, 's[aä]ffle', null, null, 'SE check 2026-10-16: Säffle greaseproof paper - context only.'),
  ('nym[oö]lla', null, 'nym[oö]lla', null, null, 'SE check 2026-10-16: Nymölla paper mill - ex Stora Enso, Omya satellite PCC history - context only.'),
  ('hylte', null, 'hylte', null, null, 'SE check 2026-10-16: Hylte paper mill - sold by Stora Enso - context only.'),
  ('ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors', null, 'ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors', null, null, 'SE check 2026-10-16: Specialty and filter papers, Billingsfors and Jönköping - context only.'),
  ('rottneros|vallvik', null, 'rottneros|vallvik', null, null, 'SE check 2026-10-16: Market pulp 331 kt (2025), Vallvik filter pulp - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'sweden_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('munkedal', 'munkedal', 'arctic paper'),
  ('grycksbo', 'grycksbo', 'arctic paper'),
  ('braviken', 'braviken|norrk[oö]ping', 'holmen'),
  ('hallsta', 'hallstavik', 'holmen'),
  ('katrinefors|mets[aä] tissue.*mariestad', 'mariestad', 'mets[aä]'),
  ('lilla edet', 'lilla edet', 'essity'),
  ('stora enso.*fors|\mfors\M', 'fors|avesta', 'stora enso'),
  ('fiskeby', 'norrk[oö]ping', 'fiskeby'),
  ('munksund', 'munksund|pite', '\msca\M|svenska cellulosa'),
  ('b[aä]ckhammar', 'b[aä]ckhammar', 'nordic paper'),
  ('skoghall', 'skoghall', 'stora enso'),
  ('obbola', 'obbola', '\msca\M|svenska cellulosa'),
  ('iggesund', 'iggesund', 'holmen'),
  ('gruv[oö]n', null, 'gruv[oö]n'),
  ('fr[oö]vi|rockhammar', null, 'fr[oö]vi|rockhammar'),
  ('billerud.*g[aä]vle|g[aä]vle.*billerud', null, 'billerud.*g[aä]vle|g[aä]vle.*billerud'),
  ('sk[aä]rblacka', null, 'sk[aä]rblacka'),
  ('karlsborg', null, 'karlsborg'),
  ('[aå]motfors', null, '[aå]motfors'),
  ('s[aä]ffle', null, 's[aä]ffle'),
  ('nym[oö]lla', null, 'nym[oö]lla'),
  ('hylte', null, 'hylte'),
  ('ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors', null, 'ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors'),
  ('rottneros|vallvik', null, 'rottneros|vallvik')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('munkedal', 'munkedal', 'arctic paper',
   $pj${"owner": "Arctic Paper", "priority": 1, "products": "Premium uncoated printing paper (Munken, Amber)", "grades": ["UWF"], "machines": 2, "capacity": {"value": 145000, "unit": "metric_t", "year": "Company figure", "source": "arcticpaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 10 pct of output at 10 pct, up to 5 pct of all."}, "pitch": "Pulp saving with opacity and print kept", "approach": "Lead Swedish account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('grycksbo', 'grycksbo', 'arctic paper',
   $pj${"owner": "Arctic Paper", "priority": 2, "products": "Coated printing paper", "grades": ["Coated paper"], "machines": 2, "capacity": {"value": 200000, "unit": "metric_t", "year": "Company figure", "source": "arcticpaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Base paper only."}, "approach": "Base-paper filler increase.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('braviken', 'braviken|norrk[oö]ping', 'holmen',
   $pj${"owner": "Holmen", "priority": 3, "products": "Book, magazine and printing paper", "grades": ["Printing paper"], "approach": "Mechanical-pulp grades - filler fit by grade.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hallsta', 'hallstavik', 'holmen',
   $pj${"owner": "Holmen", "priority": 4, "products": "Printing and publishing paper", "grades": ["Printing paper"], "approach": "After Braviken.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('katrinefors|mets[aä] tissue.*mariestad', 'mariestad', 'mets[aä]',
   $pj${"owner": "Metsä Group", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "approach": "Low-dose tissue trial - link with Metsä Finland.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lilla edet', 'lilla edet', 'essity',
   $pj${"owner": "Essity", "priority": 6, "products": "Tissue", "grades": ["Tissue"], "approach": "Co-development with Essity R&D (see Kunheim FR).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('stora enso.*fors|\mfors\M', 'fors|avesta', 'stora enso',
   $pj${"owner": "Stora Enso", "priority": 7, "products": "Folding boxboard", "grades": ["FBB"], "capacity": {"value": 455000, "unit": "metric_t", "year": "Company figure (board)", "source": "storaenso.com"}, "approach": "Non-food-contact ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fiskeby', 'norrk[oö]ping', 'fiskeby',
   $pj${"owner": "Fiskeby Board", "priority": 8, "products": "Recycled cartonboard", "grades": ["Coated board"], "capacity": {"value": 170000, "unit": "metric_t", "year": "Company figure", "source": "fiskeby.com"}, "approach": "Ash and retention review first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('munksund', 'munksund|pite', '\msca\M|svenska cellulosa',
   $pj${"owner": "SCA", "priority": 9, "products": "White-top and brown kraftliner", "grades": ["Kraftliner", "White-top liner"], "capacity": {"value": 400000, "unit": "metric_t", "year": "Company figure", "source": "sca.com"}, "approach": "White-top surface ply.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('b[aä]ckhammar', 'b[aä]ckhammar', 'nordic paper',
   $pj${"owner": "Nordic Paper", "priority": 10, "products": "Kraft paper", "grades": ["Kraft paper"], "capacity": {"value": 159000, "unit": "metric_t", "year": "Company figure", "source": "nordic-paper.com"}, "approach": "Selective - specialty only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('skoghall', 'skoghall', 'stora enso',
   $pj${"owner": "Stora Enso", "products": "Liquid packaging board", "grades": ["LPB"], "capacity": {"value": 1000000, "unit": "metric_t", "year": "Company figure (board)", "source": "storaenso.com"}, "approach": "Later - food contact.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('obbola', 'obbola', '\msca\M|svenska cellulosa',
   $pj${"owner": "SCA", "products": "Kraftliner", "grades": ["Kraftliner"], "capacity": {"value": 725000, "unit": "metric_t", "year": "Company figure", "source": "sca.com"}, "approach": "Strength-led - later.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('iggesund', 'iggesund', 'holmen',
   $pj${"owner": "Holmen", "products": "Solid bleached board", "grades": ["SBS"], "approach": "Surface-ply trial later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gruv[oö]n', null, 'gruv[oö]n',
   $pj${"owner": "Billerud", "products": "Gruvön liner, fluting, liquid packaging board", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fr[oö]vi|rockhammar', null, 'fr[oö]vi|rockhammar',
   $pj${"owner": "Billerud", "products": "Frövi / Rockhammar packaging and liquid board", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('billerud.*g[aä]vle|g[aä]vle.*billerud', null, 'billerud.*g[aä]vle|g[aä]vle.*billerud',
   $pj${"owner": "Billerud", "products": "Gävle liquid packaging board, liner", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sk[aä]rblacka', null, 'sk[aä]rblacka',
   $pj${"owner": "Billerud", "products": "Skärblacka white MG kraft, sack, fluting", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('karlsborg', null, 'karlsborg',
   $pj${"owner": "Billerud", "products": "Karlsborg FibreForm, kraft, sack, pulp", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('[aå]motfors', null, '[aå]motfors',
   $pj${"owner": "Nordic Paper", "products": "Åmotfors kraft and absorbent paper 50 kt", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('s[aä]ffle', null, 's[aä]ffle',
   $pj${"owner": "Nordic Paper", "products": "Säffle greaseproof paper", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nym[oö]lla', null, 'nym[oö]lla',
   $pj${"owner": "(sold by Stora Enso)", "products": "Nymölla paper mill - ex Stora Enso, Omya satellite PCC history", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hylte', null, 'hylte',
   $pj${"owner": "(sold by Stora Enso)", "products": "Hylte paper mill - sold by Stora Enso", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors', null, 'ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors',
   $pj${"owner": "Ahlstrom", "products": "Specialty and filter papers, Billingsfors and Jönköping", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rottneros|vallvik', null, 'rottneros|vallvik',
   $pj${"owner": "Rottneros", "products": "Market pulp 331 kt (2025), Vallvik filter pulp", "approach": "Packaging, pulp or sold mill.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SE', 'Sweden', 'high',
   $cm$Arctic Paper (Munkedals 145 kt, Grycksbo 200 kt), Holmen printing, Metsä and Essity tissue - large board and kraftliner - historical Omya and Imerys satellite PCC$cm$,
   $cm$Sweden is a core European pulp and paper producer. FCC-fit: Arctic Paper Munkedals (premium uncoated, 145 kt) and Grycksbo (coated, 200 kt), Holmen Braviken and Hallsta printing, Metsä Tissue (Katrinefors, Pauliström, Nyboholm) and Essity Lilla Edet tissue. Board and packaging: Stora Enso Fors (455 kt) and Skoghall (1 Mt), Billerud (five mills), SCA Munksund (400 kt) and Obbola (725 kt), Fiskeby (170 kt), Nordic Paper, Holmen Iggesund. Fillers in Sweden are mostly historical: Omya Nymölla satellite PCC (1992) and Persberg GCC, Imerys Husum PCC and Tunadal and Köping GCC (2005, sold to Flacks 2024), Nordkalk Köping limestone.$cm$,
   $cm${"fillers": "Historical: Omya Nymölla PCC, Persberg GCC, Lessebo PCC. Ex-Imerys: Husum PCC, Tunadal GCC, Köping GCC (Flacks since 2024). Limestone and lime: Nordkalk Köping. Not added: MTI (no Swedish plant).", "mills": "Printing: Arctic Paper Munkedals and Grycksbo, Holmen Braviken and Hallsta. Tissue: Metsä Tissue, Essity Lilla Edet. Board: Stora Enso Fors and Skoghall, Fiskeby, Holmen Iggesund. Kraftliner and kraft: SCA Munksund and Obbola, Nordic Paper Bäckhammar. Context: Billerud (5), Åmotfors, Säffle, Nymölla, Hylte, Ahlstrom, Rottneros.", "strategy": "Arctic Paper first (two clear grades, open technical contacts), then Holmen printing and Metsä / Essity tissue. Identify the current filler suppliers - Omya or the Flacks-owned ex-Imerys sites - for three-way trials.", "risks": "Filler supply sites mostly historical, Omya consolidation since 2023.", "next_steps": ["Contact Arctic Paper Munkedals technical", "Confirm who runs Husum and Nymölla PCC today"], "key_numbers": [{"label": "Arctic Paper Sweden", "value": "345 kt/yr (Munkedals 145 + Grycksbo 200)"}, {"label": "Imerys 2004 investment", "value": "EUR 35 m Husum PCC + Tunadal GCC"}], "files": ["seed_20261016zu_sweden_mills_fillers"]}$cm$::jsonb,
   $cm$Arctic Paper(Munkedals 14.5만·Grycksbo 20만 t), Holmen 인쇄용지, Metsä·Essity 티슈 — 대형 판지·크라프트라이너 — Omya·Imerys 위성 PCC 는 과거 이력$cm$,
   $cm$스웨덴은 유럽 핵심 펄프·제지국. FCC 적합: Arctic Paper Munkedals(고급 비코팅 14.5만 t)·Grycksbo(코팅 20만 t), Holmen Braviken·Hallsta 인쇄용지, Metsä Tissue 3곳·Essity Lilla Edet 티슈. 판지·포장: Stora Enso Fors(45.5만)·Skoghall(100만), Billerud 5곳, SCA Munksund(40만)·Obbola(72.5만), Fiskeby(17만), Nordic Paper, Iggesund. 충전제는 대부분 과거 이력: Omya Nymölla 위성 PCC(1992)·Persberg GCC, Imerys Husum PCC·Tunadal·Köping GCC(2005, 2024 Flacks 매각), Nordkalk Köping 석회석.$cm$,
   3450, 17250,
   $cm$Arctic Paper 34.5만 t × (적용 10% × FCC 10%) ~ (전량 × 5%)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('munkedal', 'munkedal', 'arctic paper'),
  ('grycksbo', 'grycksbo', 'arctic paper'),
  ('braviken', 'braviken|norrk[oö]ping', 'holmen'),
  ('hallsta', 'hallstavik', 'holmen'),
  ('katrinefors|mets[aä] tissue.*mariestad', 'mariestad', 'mets[aä]'),
  ('lilla edet', 'lilla edet', 'essity'),
  ('stora enso.*fors|\mfors\M', 'fors|avesta', 'stora enso'),
  ('fiskeby', 'norrk[oö]ping', 'fiskeby'),
  ('munksund', 'munksund|pite', '\msca\M|svenska cellulosa'),
  ('b[aä]ckhammar', 'b[aä]ckhammar', 'nordic paper'),
  ('skoghall', 'skoghall', 'stora enso'),
  ('obbola', 'obbola', '\msca\M|svenska cellulosa'),
  ('iggesund', 'iggesund', 'holmen'),
  ('gruv[oö]n', null, 'gruv[oö]n'),
  ('fr[oö]vi|rockhammar', null, 'fr[oö]vi|rockhammar'),
  ('billerud.*g[aä]vle|g[aä]vle.*billerud', null, 'billerud.*g[aä]vle|g[aä]vle.*billerud'),
  ('sk[aä]rblacka', null, 'sk[aä]rblacka'),
  ('karlsborg', null, 'karlsborg'),
  ('[aå]motfors', null, '[aå]motfors'),
  ('s[aä]ffle', null, 's[aä]ffle'),
  ('nym[oö]lla', null, 'nym[oö]lla'),
  ('hylte', null, 'hylte'),
  ('ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors', null, 'ahlstrom.*(billingsfors|j[oö]nk[oö]ping)|billingsfors'),
  ('rottneros|vallvik', null, 'rottneros|vallvik')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'sweden_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'sweden_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(nym[oö]lla|sweden|sverige|persberg)' or p.party_name ~* 'imerys.*(husum|tunadal|sweden)' or p.party_name ~* 'imerys.*k[oö]ping' or p.party_name ~* 'nordkalk.*(k[oö]ping|sweden)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SE'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SE'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SE'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SE'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    