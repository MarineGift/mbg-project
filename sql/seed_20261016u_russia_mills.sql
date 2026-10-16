-- ============================================================
-- seed_20261016u_russia_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Russia paper-company report (2026-10-16). Data only - market on_hold
-- pending a sanctions and export-control review, every memo says so.
-- 1) Mills if missing (10) + plant blocks, priority 1-8: Syktyvkar LPK,
--    Svetogorsk PPM, Ilim Koryazhma, KAMA, Hayat Alabuga, Syktyvkar Tissue
--    Group, Solikamskbumprom, Arkhangelsk PPM, plus Segezha PPM and Volga
--    (no priority). Context (8): Ilim Bratsk / Ust-Ilimsk, Sokol, Kondopoga,
--    Kamenskaya, Sukhonsky, Polotnyano-Zavodskaya, Balakhninskaya, Syassky.
-- 2) Supply links (historical, medium): Omya Syktyvkar PCC -> Syktyvkar LPK,
--    Omya Svetogorsk PCC -> Svetogorsk PPM (fillers from seed_20261016t).
-- 3) app.country_markets RU row refreshed (still on_hold).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'RU', v.region, v.city, v.website, 'active', 'russia_mills_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi', 'Syktyvkar LPK (ex Mondi Syktyvkar)', 'Komi Republic', 'Syktyvkar', null, '구 Mondi Syktyvkar — 복사용지·인쇄·필기용지·판지. 2023 러시아 투자자에 매각, 2025 매출 약 829억 루블(제지·판지 1위). 2003 Omya 위성 PCC(8만 t).', 'AO Syktyvkar LPK (ex Mondi Syktyvkar), Syktyvkar, Komi Republic - copy paper, printing and writing paper and board, sold by Mondi to Russian investors in 2023, 2025 revenue about RUB 82.9 bn (largest in Russian paper and board). Omya satellite PCC on site since 2003 (80 kt design).', 'RU check 2026-10-16: machine capacities not public - PCC plant operator to confirm. Acquired Syktyvkar Tissue Group (2024 report). Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper', 'Svetogorsk PPM (ex International Paper)', 'Leningrad Oblast', 'Svetogorsk', null, '구 International Paper Svetogorsk — SvetoCopy·Ballet 복사용지, 오프셋용지, 액체포장용 판지, CTMP. 2023 매각 후 러시아 독립 운영. 위성 PCC(구 Huber/Omya).', 'NPAO Svetogorsk Pulp and Paper Mill (ex International Paper Russia, sold 2023), 17 Zavodskaya St, Svetogorsk - SvetoCopy and Ballet copy paper, offset paper, liquid packaging board and CTMP. Satellite PCC on site (ex Huber, Omya since 2005).', 'RU check 2026-10-16: capacity not public. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('ilim.*koryazhma|koryazhma|коряжм', 'koryazhma', 'ilim|илим', 'Ilim Group - Koryazhma Mill', 'Arkhangelsk Oblast', 'Koryazhma', null, 'Ilim Group(2025 그룹 생산 400만 t, 약 1.6만 명) 의 Koryazhma 공장 — 복사용지·백색지·펄프·판지, 공장 전체 연 130만 t 이상(2026).', 'Ilim Group - Koryazhma Mill (Arkhangelsk Oblast): copy paper, white papers, pulp and board, over 1.3 Mt/yr all products (2026). Ilim produced about 4 Mt in 2025 across Koryazhma, Bratsk and Ust-Ilimsk (about 16,000 staff).', 'RU check 2026-10-16: the 1.3 Mt includes pulp - kept out of capacity. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('\mkama\M|кама|krasnokamsk', 'krasnokamsk', 'kama|кама|sveza', 'KAMA - Krasnokamsk', 'Perm Krai', 'Krasnokamsk', null, 'Sveza 계열 KAMA(Krasnokamsk) — LWC·오프셋용지 연 8.9만 t, FBB 연 24만 t(PM7·BM9). 2026-07 FBB 월 2.21만 t 최고 기록.', 'OOO KAMA (Sveza group), 11 Shosseynaya St, Krasnokamsk (Perm Krai) - LWC and offset paper 89,000 t/yr and FBB 240,000 t/yr on PM7 and BM9, record FBB month 22,100 t (2026-07).', 'RU check 2026-10-16: purchasing contact published (raw materials and chemicals). +7 342 270-00-21, info@cbk-kama.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('hayat.*(alabuga|russia|рус)', 'alabuga|yelabuga|елабуг', 'hayat', 'Hayat Russia - Alabuga', 'Tatarstan', 'Alabuga', null, '튀르키예 Hayat Kimya 의 러시아 티슈 공장(Alabuga 특구) 연 14만 t. 러시아 전체 약 28만 t(Kaluga 등), 주로 버진 펄프.', 'Hayat Kimya Russia - Alabuga SEZ (Tatarstan) tissue mill, about 140,000 t/yr (Tatarstan investment agency 2025), mainly virgin pulp. Hayat Russia total about 280,000 t/yr incl. Kaluga.', 'RU check 2026-10-16: only Alabuga created - Kaluga site to add when confirmed. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('syktyvkar tissue|сыктывкар тиссью|veiro', 'syktyvkar', 'tissue|тиссью|veiro', 'Syktyvkar Tissue Group (Veiro)', 'Komi Republic', 'Syktyvkar', null, 'Syktyvkar Tissue Group — Syktyvkar·Semibratovo(Yaroslavl) 티슈 원지 연 8.5만 t, 완제품 7만 t, 초지기 3대, 브랜드 Veiro. 2024 Syktyvkar LPK 인수 보도.', 'AO Syktyvkar Tissue Group - tissue base paper 85,000 t/yr and 70,000 t/yr finished products on three machines at Syktyvkar (Komi) and Semibratovo (Yaroslavl), pulp and recycled fibre, brands Veiro and Veiro Professional. Reported acquired by Syktyvkar LPK in 2024.', 'RU check 2026-10-16: both sites on this row. info@veiro.ru, +7 495 640-20-36. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('solikamsk|соликамск', 'solikamsk', 'solikamsk|соликамск', 'Solikamskbumprom - Solikamsk', 'Perm Krai', 'Solikamsk', null, 'Solikamsk(Perm) 제지사 — 신문용지·인쇄·필기용지·벌크 인쇄용지·포장용지. 구매부 공개.', 'AO Solikamskbumprom, 21 Kommunisticheskaya St, Solikamsk (Perm Krai) - newsprint, printing and writing, bulky book paper, packaging paper and interliner.', 'RU check 2026-10-16: purchasing head named on the site (Yuri Nadymov). pochta@solbum.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('arkhangelsk.*(ppm|pulp)|архангельский цбк|\mappm\M', 'novodvinsk', 'arkhangelsk|архангельск|appm', 'Arkhangelsk PPM - Novodvinsk', 'Arkhangelsk Oblast', 'Novodvinsk', null, 'Arkhangelsk PPM(Novodvinsk, 1940~) — 펄프 약 100만 t, Kraftliner·Fluting·오프셋·MG지.', 'AO Arkhangelsk Pulp and Paper Mill, 1 Melnikova St, Novodvinsk - in production since 1940: about 1 Mt/yr pulp, kraftliner, fluting, offset and MG papers.', 'RU check 2026-10-16: pulp figure kept out of capacity. info@appm.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('segezha.*(ppm|pulp|цбк)|сегежский', 'segezha', 'segezha|сегеж', 'Segezha PPM - Segezha', 'Karelia', 'Segezha', null, 'Segezha Group 의 Segezha 공장(1939~) — 고강도 sack kraft 최대 연 38.4만 t. 2025 백색지 15만 t 확대 계획 발표.', 'Segezha PPM (Segezha Group, since 1939), Segezha (Karelia) - sack kraft paper up to 384,000 t/yr. Segezha announced plans (2025-08) to raise white paper toward 150,000 t/yr.', 'RU check 2026-10-16: white-paper plan not completed. office_segcbk@segezha-group.com. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('\mvolga\M.*(balakhna|paper)|волга|balakhna.*(volga|paper mill)', 'balakhna', 'volga|волга', 'Volga - Balakhna', 'Nizhny Novgorod Oblast', 'Balakhna', null, 'Balakhna 의 Volga — 경량·초경량 컨테이너보드·포장용지·인쇄용지, 회사 소개 연 약 50만 t.', 'AO Volga, 1 Gorky St, Balakhna (Nizhny Novgorod Oblast) - former newsprint mill now making lightweight containerboard, packaging and printing paper, about 500,000 t/yr (company).', 'RU check 2026-10-16: info@volga-paper.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%RU check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi', '구 Mondi Syktyvkar — 복사용지·인쇄·필기용지·판지. 2023 러시아 투자자에 매각, 2025 매출 약 829억 루블(제지·판지 1위). 2003 Omya 위성 PCC(8만 t).', 'AO Syktyvkar LPK (ex Mondi Syktyvkar), Syktyvkar, Komi Republic - copy paper, printing and writing paper and board, sold by Mondi to Russian investors in 2023, 2025 revenue about RUB 82.9 bn (largest in Russian paper and board). Omya satellite PCC on site since 2003 (80 kt design).', 'RU check 2026-10-16: machine capacities not public - PCC plant operator to confirm. Acquired Syktyvkar Tissue Group (2024 report). Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper', '구 International Paper Svetogorsk — SvetoCopy·Ballet 복사용지, 오프셋용지, 액체포장용 판지, CTMP. 2023 매각 후 러시아 독립 운영. 위성 PCC(구 Huber/Omya).', 'NPAO Svetogorsk Pulp and Paper Mill (ex International Paper Russia, sold 2023), 17 Zavodskaya St, Svetogorsk - SvetoCopy and Ballet copy paper, offset paper, liquid packaging board and CTMP. Satellite PCC on site (ex Huber, Omya since 2005).', 'RU check 2026-10-16: capacity not public. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('ilim.*koryazhma|koryazhma|коряжм', 'koryazhma', 'ilim|илим', 'Ilim Group(2025 그룹 생산 400만 t, 약 1.6만 명) 의 Koryazhma 공장 — 복사용지·백색지·펄프·판지, 공장 전체 연 130만 t 이상(2026).', 'Ilim Group - Koryazhma Mill (Arkhangelsk Oblast): copy paper, white papers, pulp and board, over 1.3 Mt/yr all products (2026). Ilim produced about 4 Mt in 2025 across Koryazhma, Bratsk and Ust-Ilimsk (about 16,000 staff).', 'RU check 2026-10-16: the 1.3 Mt includes pulp - kept out of capacity. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('\mkama\M|кама|krasnokamsk', 'krasnokamsk', 'kama|кама|sveza', 'Sveza 계열 KAMA(Krasnokamsk) — LWC·오프셋용지 연 8.9만 t, FBB 연 24만 t(PM7·BM9). 2026-07 FBB 월 2.21만 t 최고 기록.', 'OOO KAMA (Sveza group), 11 Shosseynaya St, Krasnokamsk (Perm Krai) - LWC and offset paper 89,000 t/yr and FBB 240,000 t/yr on PM7 and BM9, record FBB month 22,100 t (2026-07).', 'RU check 2026-10-16: purchasing contact published (raw materials and chemicals). +7 342 270-00-21, info@cbk-kama.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('hayat.*(alabuga|russia|рус)', 'alabuga|yelabuga|елабуг', 'hayat', '튀르키예 Hayat Kimya 의 러시아 티슈 공장(Alabuga 특구) 연 14만 t. 러시아 전체 약 28만 t(Kaluga 등), 주로 버진 펄프.', 'Hayat Kimya Russia - Alabuga SEZ (Tatarstan) tissue mill, about 140,000 t/yr (Tatarstan investment agency 2025), mainly virgin pulp. Hayat Russia total about 280,000 t/yr incl. Kaluga.', 'RU check 2026-10-16: only Alabuga created - Kaluga site to add when confirmed. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('syktyvkar tissue|сыктывкар тиссью|veiro', 'syktyvkar', 'tissue|тиссью|veiro', 'Syktyvkar Tissue Group — Syktyvkar·Semibratovo(Yaroslavl) 티슈 원지 연 8.5만 t, 완제품 7만 t, 초지기 3대, 브랜드 Veiro. 2024 Syktyvkar LPK 인수 보도.', 'AO Syktyvkar Tissue Group - tissue base paper 85,000 t/yr and 70,000 t/yr finished products on three machines at Syktyvkar (Komi) and Semibratovo (Yaroslavl), pulp and recycled fibre, brands Veiro and Veiro Professional. Reported acquired by Syktyvkar LPK in 2024.', 'RU check 2026-10-16: both sites on this row. info@veiro.ru, +7 495 640-20-36. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('solikamsk|соликамск', 'solikamsk', 'solikamsk|соликамск', 'Solikamsk(Perm) 제지사 — 신문용지·인쇄·필기용지·벌크 인쇄용지·포장용지. 구매부 공개.', 'AO Solikamskbumprom, 21 Kommunisticheskaya St, Solikamsk (Perm Krai) - newsprint, printing and writing, bulky book paper, packaging paper and interliner.', 'RU check 2026-10-16: purchasing head named on the site (Yuri Nadymov). pochta@solbum.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('arkhangelsk.*(ppm|pulp)|архангельский цбк|\mappm\M', 'novodvinsk', 'arkhangelsk|архангельск|appm', 'Arkhangelsk PPM(Novodvinsk, 1940~) — 펄프 약 100만 t, Kraftliner·Fluting·오프셋·MG지.', 'AO Arkhangelsk Pulp and Paper Mill, 1 Melnikova St, Novodvinsk - in production since 1940: about 1 Mt/yr pulp, kraftliner, fluting, offset and MG papers.', 'RU check 2026-10-16: pulp figure kept out of capacity. info@appm.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('segezha.*(ppm|pulp|цбк)|сегежский', 'segezha', 'segezha|сегеж', 'Segezha Group 의 Segezha 공장(1939~) — 고강도 sack kraft 최대 연 38.4만 t. 2025 백색지 15만 t 확대 계획 발표.', 'Segezha PPM (Segezha Group, since 1939), Segezha (Karelia) - sack kraft paper up to 384,000 t/yr. Segezha announced plans (2025-08) to raise white paper toward 150,000 t/yr.', 'RU check 2026-10-16: white-paper plan not completed. office_segcbk@segezha-group.com. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('\mvolga\M.*(balakhna|paper)|волга|balakhna.*(volga|paper mill)', 'balakhna', 'volga|волга', 'Balakhna 의 Volga — 경량·초경량 컨테이너보드·포장용지·인쇄용지, 회사 소개 연 약 50만 t.', 'AO Volga, 1 Gorky St, Balakhna (Nizhny Novgorod Oblast) - former newsprint mill now making lightweight containerboard, packaging and printing paper, about 500,000 t/yr (company).', 'RU check 2026-10-16: info@volga-paper.ru. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('ilim.*(bratsk|ust-?ilimsk)', null, 'ilim.*(bratsk|ust-?ilimsk)', null, null, 'RU check 2026-10-16: Bratsk and Ust-Ilimsk - market pulp and packaging board - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('sokol|сокольск', null, 'sokol|сокольск', null, null, 'RU check 2026-10-16: Sokol PPM - greaseproof and sack paper, about 25,000 t/yr - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('kondopog|кондопог', null, 'kondopog|кондопог', null, null, 'RU check 2026-10-16: Newsprint and other grades - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('kamenskaya|каменская', null, 'kamenskaya|каменская', null, null, 'RU check 2026-10-16: Industrial paper and board, Kuvshinovo (2025 revenue about RUB 11.6 bn) - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('sukhon|сухонск', null, 'sukhon|сухонск', null, null, 'RU check 2026-10-16: Sukhonsky PPM, Sokol - testliner, fluting, board about 300 kt - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('polotnyano|полотняно', null, 'polotnyano|полотняно', null, null, 'RU check 2026-10-16: Polotnyano-Zavodskaya - containerboard over 70 kt - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('balakhninskaya|балахнинская', null, 'balakhninskaya|балахнинская', null, null, 'RU check 2026-10-16: Balakhninskaya Cardboard Factory - multi-ply board - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.'),
  ('syassk|сясьск', null, 'syassk|сясьск', null, null, 'RU check 2026-10-16: Tissue, napkins, towels, Syasstroy - capacity not verified - context only. Sanctions and export-control review (US, EU) required before any dealings or licence payments.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'russia_mills_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi'),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper'),
  ('ilim.*koryazhma|koryazhma|коряжм', 'koryazhma', 'ilim|илим'),
  ('\mkama\M|кама|krasnokamsk', 'krasnokamsk', 'kama|кама|sveza'),
  ('hayat.*(alabuga|russia|рус)', 'alabuga|yelabuga|елабуг', 'hayat'),
  ('syktyvkar tissue|сыктывкар тиссью|veiro', 'syktyvkar', 'tissue|тиссью|veiro'),
  ('solikamsk|соликамск', 'solikamsk', 'solikamsk|соликамск'),
  ('arkhangelsk.*(ppm|pulp)|архангельский цбк|\mappm\M', 'novodvinsk', 'arkhangelsk|архангельск|appm'),
  ('segezha.*(ppm|pulp|цбк)|сегежский', 'segezha', 'segezha|сегеж'),
  ('\mvolga\M.*(balakhna|paper)|волга|balakhna.*(volga|paper mill)', 'balakhna', 'volga|волга'),
  ('ilim.*(bratsk|ust-?ilimsk)', null, 'ilim.*(bratsk|ust-?ilimsk)'),
  ('sokol|сокольск', null, 'sokol|сокольск'),
  ('kondopog|кондопог', null, 'kondopog|кондопог'),
  ('kamenskaya|каменская', null, 'kamenskaya|каменская'),
  ('sukhon|сухонск', null, 'sukhon|сухонск'),
  ('polotnyano|полотняно', null, 'polotnyano|полотняно'),
  ('balakhninskaya|балахнинская', null, 'balakhninskaya|балахнинская'),
  ('syassk|сясьск', null, 'syassk|сясьск')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi',
   $pj${"owner": "Syktyvkar LPK (Russian owners since 2023)", "priority": 1, "products": "Copy paper, printing and writing, board", "grades": ["Copy paper", "UWF", "Board"], "approach": "On hold - sanctions review first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper',
   $pj${"owner": "Svetogorsk PPM (Russian owners since 2023)", "priority": 2, "products": "Copy paper, offset paper, liquid packaging board", "grades": ["Copy paper", "UWF", "LPB"], "approach": "On hold - sanctions review first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ilim.*koryazhma|koryazhma|коряжм', 'koryazhma', 'ilim|илим',
   $pj${"owner": "Ilim Group", "priority": 3, "products": "Copy paper, white papers, board, pulp", "grades": ["Copy paper", "UWF", "Board"], "approach": "On hold - white-paper lines only.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mkama\M|кама|krasnokamsk', 'krasnokamsk', 'kama|кама|sveza',
   $pj${"owner": "Sveza", "priority": 4, "products": "LWC, offset paper, FBB", "grades": ["LWC", "UWF", "FBB"], "machines": 2, "capacity": {"value": 329000, "unit": "metric_t", "year": "Company figure (board 240 + paper 89)", "source": "cbk-kama.ru"}, "capacity_split": [{"label": "FBB", "value_t": 240000}, {"label": "LWC and offset", "value_t": 89000}], "approach": "On hold - sanctions review first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hayat.*(alabuga|russia|рус)', 'alabuga|yelabuga|елабуг', 'hayat',
   $pj${"owner": "Hayat Kimya", "priority": 5, "products": "Toilet tissue, kitchen towel, facial", "grades": ["Tissue"], "capacity": {"value": 140000, "unit": "metric_t", "year": "Tatarstan agency 2025", "source": "tida.tatarstan.ru"}, "approach": "On hold - Turkish parent could be approached separately.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('syktyvkar tissue|сыктывкар тиссью|veiro', 'syktyvkar', 'tissue|тиссью|veiro',
   $pj${"owner": "Syktyvkar LPK (2024)", "priority": 6, "products": "Tissue base paper, toilet tissue, towels", "grades": ["Tissue"], "machines": 3, "capacity": {"value": 85000, "unit": "metric_t", "year": "Company figure (2 sites)", "source": "sgbi.ru"}, "approach": "On hold.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('solikamsk|соликамск', 'solikamsk', 'solikamsk|соликамск',
   $pj${"owner": "Solikamskbumprom", "priority": 7, "products": "Newsprint, printing and writing, packaging", "grades": ["Newsprint", "UWF"], "approach": "On hold.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('arkhangelsk.*(ppm|pulp)|архангельский цбк|\mappm\M', 'novodvinsk', 'arkhangelsk|архангельск|appm',
   $pj${"owner": "Arkhangelsk PPM", "priority": 8, "products": "Kraftliner, fluting, offset, MG paper, pulp", "grades": ["Kraftliner", "Medium", "UWF"], "approach": "On hold - white and specialty lines only.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('segezha.*(ppm|pulp|цбк)|сегежский', 'segezha', 'segezha|сегеж',
   $pj${"owner": "Segezha Group", "products": "Sack kraft paper (white paper planned)", "grades": ["Sack kraft"], "capacity": {"value": 384000, "unit": "metric_t", "year": "Company figure", "source": "segezha-group.com"}, "approach": "On hold - only a future white-paper line fits FCC.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mvolga\M.*(balakhna|paper)|волга|balakhna.*(volga|paper mill)', 'balakhna', 'volga|волга',
   $pj${"owner": "Volga", "products": "Lightweight containerboard, packaging, printing paper", "grades": ["Containerboard", "Newsprint"], "capacity": {"value": 500000, "unit": "metric_t", "year": "Company figure", "source": "volga-paper.ru"}, "approach": "On hold - low FCC fit.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ilim.*(bratsk|ust-?ilimsk)', null, 'ilim.*(bratsk|ust-?ilimsk)',
   $pj${"owner": "Ilim Group", "products": "Bratsk and Ust-Ilimsk - market pulp and packaging board", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sokol|сокольск', null, 'sokol|сокольск',
   $pj${"owner": "Segezha Group", "products": "Sokol PPM - greaseproof and sack paper, about 25,000 t/yr", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kondopog|кондопог', null, 'kondopog|кондопог',
   $pj${"owner": "Kondopoga PPM", "products": "Newsprint and other grades", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kamenskaya|каменская', null, 'kamenskaya|каменская',
   $pj${"owner": "Kamenskaya BKF", "products": "Industrial paper and board, Kuvshinovo (2025 revenue about RUB 11.6 bn)", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sukhon|сухонск', null, 'sukhon|сухонск',
   $pj${"owner": "United Paper Mills", "products": "Sukhonsky PPM, Sokol - testliner, fluting, board about 300 kt", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('polotnyano|полотняно', null, 'polotnyano|полотняно',
   $pj${"owner": "United Paper Mills", "products": "Polotnyano-Zavodskaya - containerboard over 70 kt", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('balakhninskaya|балахнинская', null, 'balakhninskaya|балахнинская',
   $pj${"owner": "United Paper Mills", "products": "Balakhninskaya Cardboard Factory - multi-ply board", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('syassk|сясьск', null, 'syassk|сясьск',
   $pj${"owner": "Syassky PPM", "products": "Tissue, napkins, towels, Syasstroy - capacity not verified", "approach": "On hold.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'russia_mills_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi', 'omya.*syktyvkar', 'historical', 'medium', null::date, null::date, '80,000 t/yr design (2003)', 'satellite PCC on the mill site', 'Industry report 2005', 'Omya satellite PCC at Syktyvkar since 2003-10 - current operator not confirmed'),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper', 'omya.*svetogorsk|huber.*svetogorsk', 'historical', 'medium', null::date, null::date, null, 'satellite PCC on the mill site', 'Industry report 2005', 'Huber then Omya satellite PCC at Svetogorsk since about 2004 - current operator not confirmed')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'RU', 'Russia', 'on_hold',
   $cm$On hold (sanctions review) - Syktyvkar LPK and Svetogorsk white paper with Omya satellite PCC history, KAMA FBB, Hayat tissue$cm$,
   $cm$On hold for a sanctions review. Russia has large white-paper mills with PCC history - Syktyvkar LPK (ex Mondi, Omya satellite PCC 2003) and Svetogorsk (ex International Paper, Huber/Omya PCC) - plus Ilim Koryazhma, KAMA (FBB 240 kt, LWC and offset 89 kt), Solikamskbumprom and Arkhangelsk. Tissue: Hayat Russia (about 280 kt, Alabuga 140 kt) and Syktyvkar Tissue Group (85 kt). GCC base: RIF-Micromramor, Koelgamramor, Roscarb (Chelyabinsk marble), Shebekino and Melstrom (Belgorod chalk).$cm$,
   $cm${"fillers": "PCC (historical): Omya Syktyvkar 80 kt, Omya ex-Huber Svetogorsk. Omya Algol Rus (Moscow). Marble GCC: RIF-Micromramor (Eleninka, Dzhabyk, Subutak 100 kt new), Koelgamramor, Roscarb, Ural Plant of Building Materials, Dancub. Chalk: Shebekinsky (MPNB-2, 85.3 brightness), Melstrom.", "mills": "White paper and board: Syktyvkar LPK, Svetogorsk PPM, Ilim Koryazhma, KAMA Krasnokamsk, Solikamskbumprom, Arkhangelsk PPM. Tissue: Hayat Russia Alabuga, Syktyvkar Tissue Group. Kraft and packaging: Segezha PPM (384 kt sack kraft), Volga Balakhna (500 kt). Context: Ilim Bratsk and Ust-Ilimsk, Sokol, Kondopoga, Kamenskaya, United Paper Mills sites, Syassky.", "strategy": "On hold until a sanctions and export-control review. Technically: existing PCC satellites and RIF-Micromramor GCC would be the production base.", "risks": "US and EU sanctions, export controls, payment routes, ownership changes of ex-foreign assets.", "next_steps": ["Sanctions review (pending item 3 - add RU?)", "Confirm PCC satellite operators at Syktyvkar and Svetogorsk"], "key_numbers": [{"label": "RIF-Micromramor", "value": "over 700 kt/yr finished products (all grades)"}, {"label": "Omya Syktyvkar PCC", "value": "80 kt/yr design (2003)"}], "files": ["seed_20261016t_russia_fillers", "seed_20261016u_russia_mills"]}$cm$::jsonb,
   $cm$보류(제재 검토) — Syktyvkar LPK·Svetogorsk 백색지(Omya 위성 PCC 이력), KAMA FBB, Hayat 티슈$cm$,
   $cm$제재 검토로 보류. 러시아에는 PCC 이력이 있는 대형 백색지 공장 — Syktyvkar LPK(구 Mondi, Omya 위성 PCC 2003)·Svetogorsk(구 IP, Huber/Omya PCC) — 과 Ilim Koryazhma, KAMA(FBB 24만·LWC/오프셋 8.9만 t), Solikamskbumprom, Arkhangelsk. 티슈 Hayat Russia(약 28만 t, Alabuga 14만)·Syktyvkar Tissue Group(8.5만 t). GCC: 첼랴빈스크 대리석(RIF-Micromramor 등)·벨고로드 백악.$cm$,
   null, null,
   $cm$보류 — 제재 검토 및 제지사 미입력$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('syktyvkar.*(lpk|лпк|pulp)|сыктывкарский лпк|mondi.*syktyvkar', 'syktyvkar', 'lpk|лпк|mondi'),
  ('svetogorsk|светогорск', 'svetogorsk', 'svetogorsk|светогорск|international paper'),
  ('ilim.*koryazhma|koryazhma|коряжм', 'koryazhma', 'ilim|илим'),
  ('\mkama\M|кама|krasnokamsk', 'krasnokamsk', 'kama|кама|sveza'),
  ('hayat.*(alabuga|russia|рус)', 'alabuga|yelabuga|елабуг', 'hayat'),
  ('syktyvkar tissue|сыктывкар тиссью|veiro', 'syktyvkar', 'tissue|тиссью|veiro'),
  ('solikamsk|соликамск', 'solikamsk', 'solikamsk|соликамск'),
  ('arkhangelsk.*(ppm|pulp)|архангельский цбк|\mappm\M', 'novodvinsk', 'arkhangelsk|архангельск|appm'),
  ('segezha.*(ppm|pulp|цбк)|сегежский', 'segezha', 'segezha|сегеж'),
  ('\mvolga\M.*(balakhna|paper)|волга|balakhna.*(volga|paper mill)', 'balakhna', 'volga|волга'),
  ('ilim.*(bratsk|ust-?ilimsk)', null, 'ilim.*(bratsk|ust-?ilimsk)'),
  ('sokol|сокольск', null, 'sokol|сокольск'),
  ('kondopog|кондопог', null, 'kondopog|кондопог'),
  ('kamenskaya|каменская', null, 'kamenskaya|каменская'),
  ('sukhon|сухонск', null, 'sukhon|сухонск'),
  ('polotnyano|полотняно', null, 'polotnyano|полотняно'),
  ('balakhninskaya|балахнинская', null, 'balakhninskaya|балахнинская'),
  ('syassk|сясьск', null, 'syassk|сясьск')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'russia_mills_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'russia_mills_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'RU'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'RU'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'RU'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'RU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    