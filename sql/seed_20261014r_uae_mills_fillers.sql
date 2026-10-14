-- ============================================================
-- seed_20261014r_uae_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- UAE update (reports "UAE PCC/GCC producers" + "UAE paper companies",
-- 2026-10).
--
-- NEW RULE (2026-10-14): company introduction goes in Introduction
-- (intro_ko / intro_en) or Memo (notes). This file:
--   - writes intro_ko / intro_en on new rows, and fills them on existing rows
--     ONLY when empty (an existing introduction is never overwritten)
--   - puts further company detail (machines, contacts, caveats) in notes,
--     appended once with marker 'UAE check 2026-10-14'
--   - keeps plant data (capacity, filler, priority, approach) on the Mill
--     profile card (paper_mill_profile.extra_data.plant)
--
-- 1) Fillers if missing + profiles: Omya (UAE) on-site PCC at Ittihad, GMI
--    (Ajman PCC 15 kt), ECCF, Gulf Lime, Apex Chemical (Fujairah 200 kt in
--    two phases, opened 2025-05-07), Wasit Group.
-- 2) Mills if missing: Ittihad, Crown, ADNPM, Star tissue, Al Nakheel,
--    Queenex, Star KEZAD containerboard, Gulf Paper Dubai, Arabian Kraft.
-- 3) Link Omya (UAE) -> Ittihad Paper Mill: active / medium (on-site PCC
--    stated by the mill, Omya role to confirm).
-- 4) Plant blocks, UAE priority 1-10: Ittihad, Crown, ADNPM, Star tissue,
--    Al Nakheel, Queenex, Star KEZAD, Union Paper Mills, Gulf Paper Dubai,
--    Arabian Kraft. context: Al Dhafra.
--    FCC scenario only for Ittihad (325 kt printing paper).
--
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
       v.party_name, 'AE', v.region, v.city, v.website, 'active', 'uae_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya (UAE)', 'Omya%UAE%', 'Abu Dhabi', 'ICAD II', 'https://www.omya.com', 'Ittihad Paper Mill(아부다비 ICAD II) 내부의 Omya 기술 현장 PCC 설비. 소유·운영 주체와 생산능력은 미공개.', 'Omya-technology on-site PCC plant inside Ittihad Paper Mill, ICAD II Abu Dhabi. Owner, operator and capacity not public.', 'UAE check 2026-10-14: stated on the Ittihad Paper Mill site, PCC plant tied to CO2 capture. Royalty licensee is Omya at HQ level.'),
  ('General Mineral Industries (GMI)', '%General Mineral Industries%', 'Ajman', 'Ajman', 'https://www.gmillc.com', '아지만의 PCC 제조사 General Mineral Industries(2001년 설립, EMICAL). 설계능력 연 1.5만 t, 소성·수화·탄산화 공정, 종이 포함 다용도.', 'General Mineral Industries (founded 2001, EMICAL brand), Ajman - PCC and coated PCC, 15,000 t/yr design capacity, calcining, slaking and carbonation, paper among uses.', 'UAE check 2026-10-14: National Paints Sharjah among shareholders, exports to Africa, Asia, Europe, says it can scale. Contact per report marketing@gmillc.com, +971-6-7480101.'),
  ('Emirates Calcium Carbonate Factory (ECCF)', '%Emirates Calcium Carbonate%', 'Ajman', 'Ajman', 'https://www.eccf.ae', '아지만·아부다비의 Emirates Calcium Carbonate Factory. 천연·표면처리 GCC(약 7~200 µm), 다수 라인·QC 연구실, 벌크 탱커 공급.', 'Emirates Calcium Carbonate Factory, Ajman and Abu Dhabi - natural and coated GCC (about 7-200 um), several lines, QC lab, bulk tanker and big-bag supply.', 'UAE check 2026-10-14: products aimed at paint, plastics, rubber, construction chemicals - paper-grade wet slurry not confirmed. Contact per report info@eccf.ae, +971-6-7436604.'),
  ('Gulf Lime Co.', '%Gulf Lime%', 'Abu Dhabi', 'Musaffah', 'https://www.gulflime.com', '아부다비 무사파 ICAD II 의 Gulf Lime(Al Nasser Industrial Enterprises 계열). GCC·코팅·초미립 GCC·탈크, PLC/SCADA 자동화.', 'Gulf Lime Co. (Al Nasser Industrial Enterprises), ICAD II Musaffah Abu Dhabi - GCC, coated and ultrafine GCC, talc, PLC/SCADA automated plant.', 'UAE check 2026-10-14: customers oil and gas, paint, adhesives, plastics, rubber - no paper supply found. Same industrial area as Ittihad. Contact per report sales.glime@anieuae.com, +971-2-5502448.'),
  ('Apex Chemical Industries', '%Apex Chemical%', 'Fujairah', 'Thoban', null, '푸자이라 토반의 Apex Chemical Industries GCC 공장(7,700 m2). 2단계 합계 연 20만 t 발표, 2025-05-07 개장(WAM).', 'Apex Chemical Industries GCC plant, Thoban Fujairah (7,700 m2) - 200,000 t/yr announced over two phases, opened 2025-05-07 (WAM).', 'UAE check 2026-10-14: electric production lines, domestic and export markets. Phase 1 installed capacity and paper grades not confirmed.'),
  ('Wasit Group', '%Wasit%', 'Ras Al Khaimah', 'Ras Al Khaimah', 'https://www.wasitgroup.com', '라스알카이마의 산업광물 채굴·가공·수출기업 Wasit Group. 탄산칼슘 400~3,500 mesh, 제지 충전제 용도 기재.', 'Wasit Group, Ras Al Khaimah - industrial mineral mining, processing, export and trading, calcium carbonate 400-3,500 mesh, paper filler listed among uses.', 'UAE check 2026-10-14: plant location, capacity and paper deliveries not public. Contact per report sales@wasitgroup.com, +971-7-2279792.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%UAE check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Omya (UAE)', 'Omya%UAE%', 'Abu Dhabi', 'ICAD II', 'https://www.omya.com', 'Ittihad Paper Mill(아부다비 ICAD II) 내부의 Omya 기술 현장 PCC 설비. 소유·운영 주체와 생산능력은 미공개.', 'Omya-technology on-site PCC plant inside Ittihad Paper Mill, ICAD II Abu Dhabi. Owner, operator and capacity not public.', 'UAE check 2026-10-14: stated on the Ittihad Paper Mill site, PCC plant tied to CO2 capture. Royalty licensee is Omya at HQ level.'),
  ('General Mineral Industries (GMI)', '%General Mineral Industries%', 'Ajman', 'Ajman', 'https://www.gmillc.com', '아지만의 PCC 제조사 General Mineral Industries(2001년 설립, EMICAL). 설계능력 연 1.5만 t, 소성·수화·탄산화 공정, 종이 포함 다용도.', 'General Mineral Industries (founded 2001, EMICAL brand), Ajman - PCC and coated PCC, 15,000 t/yr design capacity, calcining, slaking and carbonation, paper among uses.', 'UAE check 2026-10-14: National Paints Sharjah among shareholders, exports to Africa, Asia, Europe, says it can scale. Contact per report marketing@gmillc.com, +971-6-7480101.'),
  ('Emirates Calcium Carbonate Factory (ECCF)', '%Emirates Calcium Carbonate%', 'Ajman', 'Ajman', 'https://www.eccf.ae', '아지만·아부다비의 Emirates Calcium Carbonate Factory. 천연·표면처리 GCC(약 7~200 µm), 다수 라인·QC 연구실, 벌크 탱커 공급.', 'Emirates Calcium Carbonate Factory, Ajman and Abu Dhabi - natural and coated GCC (about 7-200 um), several lines, QC lab, bulk tanker and big-bag supply.', 'UAE check 2026-10-14: products aimed at paint, plastics, rubber, construction chemicals - paper-grade wet slurry not confirmed. Contact per report info@eccf.ae, +971-6-7436604.'),
  ('Gulf Lime Co.', '%Gulf Lime%', 'Abu Dhabi', 'Musaffah', 'https://www.gulflime.com', '아부다비 무사파 ICAD II 의 Gulf Lime(Al Nasser Industrial Enterprises 계열). GCC·코팅·초미립 GCC·탈크, PLC/SCADA 자동화.', 'Gulf Lime Co. (Al Nasser Industrial Enterprises), ICAD II Musaffah Abu Dhabi - GCC, coated and ultrafine GCC, talc, PLC/SCADA automated plant.', 'UAE check 2026-10-14: customers oil and gas, paint, adhesives, plastics, rubber - no paper supply found. Same industrial area as Ittihad. Contact per report sales.glime@anieuae.com, +971-2-5502448.'),
  ('Apex Chemical Industries', '%Apex Chemical%', 'Fujairah', 'Thoban', null, '푸자이라 토반의 Apex Chemical Industries GCC 공장(7,700 m2). 2단계 합계 연 20만 t 발표, 2025-05-07 개장(WAM).', 'Apex Chemical Industries GCC plant, Thoban Fujairah (7,700 m2) - 200,000 t/yr announced over two phases, opened 2025-05-07 (WAM).', 'UAE check 2026-10-14: electric production lines, domestic and export markets. Phase 1 installed capacity and paper grades not confirmed.'),
  ('Wasit Group', '%Wasit%', 'Ras Al Khaimah', 'Ras Al Khaimah', 'https://www.wasitgroup.com', '라스알카이마의 산업광물 채굴·가공·수출기업 Wasit Group. 탄산칼슘 400~3,500 mesh, 제지 충전제 용도 기재.', 'Wasit Group, Ras Al Khaimah - industrial mineral mining, processing, export and trading, calcium carbonate 400-3,500 mesh, paper filler listed among uses.', 'UAE check 2026-10-14: plant location, capacity and paper deliveries not public. Contact per report sales@wasitgroup.com, +971-7-2279792.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'uae_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya (UAE)', 'PCC producer', 'Omya on-site PCC at Ittihad', 'satellite (on-site)', 'B', 'pcc'),
  ('General Mineral Industries (GMI)', 'PCC producer', 'UAE independent PCC - FCC pilot candidate', 'merchant', 'B', 'pcc'),
  ('Emirates Calcium Carbonate Factory (ECCF)', 'GCC producer', 'UAE GCC - paper grade to confirm', 'merchant', 'C', 'gcc'),
  ('Gulf Lime Co.', 'GCC producer', 'ICAD GCC - raw material option', 'merchant', 'C', 'gcc'),
  ('Apex Chemical Industries', 'GCC producer', 'New Fujairah GCC plant', 'merchant', 'B', 'gcc'),
  ('Wasit Group', 'GCC producer', 'RAK carbonate supply and export', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'uae_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'AE', v.region, v.city, v.website, 'active', 'uae_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Ittihad Paper%', '%Ittihad%Paper Mill%', 'Ittihad Paper Mill (Abu Dhabi)', 'Abu Dhabi', 'ICAD II', 'https://www.ittihadpapermill.com', '아부다비 ICAD II 의 Ittihad Paper Mill(Ittihad International Investment 계열). 연산 32.5만 t 무도공 상질지·복사용지 공장으로 2020년 가동, 공장 내 Omya 기술 현장 PCC 설비 보유.', 'Ittihad Paper Mill (Ittihad International Investment), ICAD II Abu Dhabi - 325,000 t/yr uncoated woodfree and copy paper mill started 2020, with an on-site Omya-technology PCC plant.', 'UAE check 2026-10-14: Valmet machine, 1,700 m/min, 6,550 mm width, 45-120 gsm. BW Papersystems sheeting. Natural pulp and local limestone. On-site PCC plant with Omya (Switzerland) - also runs CO2 capture linked to the PCC. Whether Omya owns, operates or only supplied the PCC plant is not public, nor is PCC capacity.'),
  ('%Crown Paper%', '%Crown Paper Mill%', 'Crown Paper Mill (Abu Dhabi)', 'Abu Dhabi', 'ICAD III', 'https://www.crownpapermill.com', 'Ittihad International Investment 계열 티슈 원지 제조사 Crown Paper Mill(1996년~). 아부다비 ICAD III, 초지기 3대 연산 10만 t, 버진·재생 티슈.', 'Crown Paper Mill (Ittihad International Investment, since 1996), ICAD III Abu Dhabi - tissue base paper, three machines, 100,000 t/yr, virgin and recycled.', null),
  ('%Abu Dhabi National Paper%', '%ADNPM%', 'Abu Dhabi National Paper Mill (ADNPM)', 'Abu Dhabi', 'ICAD', 'https://www.adnpm.ae', '아부다비 ICAD 의 Abu Dhabi National Paper Mill(ADNPM, 2000년 설립). Crescent Former 티슈 초지기 3대(Valmet NTT 포함), 연 9만 t 이상, 사무용 폐지 탈묵설비 보유.', 'Abu Dhabi National Paper Mill (ADNPM, founded 2000), ICAD - three crescent-former tissue machines incl. a Valmet Advantage NTT line, over 90,000 t/yr, deinking of recovered office paper.', 'UAE check 2026-10-14: contact per report info@adnpm.ae, +971-2-5099200.'),
  ('%Star Paper%Tissue%', '%Star Paper Mill%', 'Star Paper Mill - Tissue (ICAD II)', 'Abu Dhabi', 'ICAD II', 'https://www.starpapermill.com', 'Star Paper Mill 의 아부다비 ICAD II 티슈 공장. Recard 크레센트 포머 초지기(폭 3.6m), 평량 12.5~45 gsm, 연산 4만 t.', 'Star Paper Mill tissue plant, ICAD II Abu Dhabi - Recard crescent-former machine, 3.6 m width, 12.5-45 gsm, 40,000 t/yr.', null),
  ('%Nakheel%', '%Fine Hygienic%', 'Al Nakheel Paper Mill - Fine Hygienic (Abu Dhabi)', 'Abu Dhabi', 'ICAD II', 'https://www.finehh.com', 'Fine Hygienic Holding 의 아부다비 ICAD II 티슈 공장 Al Nakheel Paper Mill. Valmet Advantage DCT 설비, 1단계 계획 연 6만 t. 요르단·이집트에도 공장.', 'Al Nakheel Paper Mill of Fine Hygienic Holding, ICAD II Abu Dhabi - Valmet Advantage DCT tissue line, phase 1 planned at 60,000 t/yr. Group also has mills in Jordan and Egypt.', null),
  ('%Queenex%', '%Queenex%', 'Queenex Hygiene Paper Manufacturing (Abu Dhabi)', 'Abu Dhabi', 'ICAD', 'https://www.qhpm.ae', '아부다비 ICAD 의 Queenex Hygiene Paper(2012년 가동). PM1 연 3.2만 t(2,100 m/min), 탈묵설비, PM2 6.5만 t 증설 추진.', 'Queenex Hygiene Paper Manufacturing, ICAD Abu Dhabi, running since 2012 - PM1 32,000 t/yr at 2,100 m/min, deinking plant, PM2 (65,000 t/yr) planned.', null),
  ('%Star Paper%KEZAD%', '%Star Paper%Container%', 'Star Paper Mill - Containerboard (KEZAD)', 'Abu Dhabi', 'KEZAD', 'https://www.starpapermill.com', 'Star Paper Mill 의 아부다비 KEZAD 재생 포장원지 공장. 약 AED 2억 투자, 연 13.5만 t, 2026-04 가동·2026-05-07 공식 개장.', 'Star Paper Mill recycled containerboard plant, KEZAD Abu Dhabi - about AED 200m, 135,000 t/yr, started 2026-04, officially opened 2026-05-07.', null),
  ('%Gulf Paper%Dubai%', '%Gulf Paper%Jebel%', 'Gulf Paper Manufacturing - Dubai Mill (Jebel Ali)', 'Dubai', 'Jebel Ali', 'https://www.gpmc.ae', '쿠웨이트 Gulf Paper Manufacturing 의 두바이 제벨알리 공장. 기존 설비를 인수·재건해 2005년 생산 시작, 포장원지.', 'Dubai Jebel Ali Free Zone mill of Kuwait''s Gulf Paper Manufacturing - rebuilt acquired line, producing packaging base paper since 2005.', null),
  ('%Arabian Kraft%', '%Arabian Kraft Paper%', 'Arabian Kraft Paper Manufacturing (Umm Al Quwain)', 'Umm Al Quwain', 'Umm Al Quwain', 'https://www.arabiankraftpaper.com', '움알쿠와인 산업도시의 Arabian Kraft Paper. MG 크라프트지·재생 크라프트지(봉투용), 연 2만 t.', 'Arabian Kraft Paper Manufacturing, Umm Al Quwain Industrial City - MG kraft and recycled kraft for paper bags, 20,000 t/yr.', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%UAE check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Ittihad Paper%', '%Ittihad%Paper Mill%', '%Ittihad%', '아부다비 ICAD II 의 Ittihad Paper Mill(Ittihad International Investment 계열). 연산 32.5만 t 무도공 상질지·복사용지 공장으로 2020년 가동, 공장 내 Omya 기술 현장 PCC 설비 보유.', 'Ittihad Paper Mill (Ittihad International Investment), ICAD II Abu Dhabi - 325,000 t/yr uncoated woodfree and copy paper mill started 2020, with an on-site Omya-technology PCC plant.', 'UAE check 2026-10-14: Valmet machine, 1,700 m/min, 6,550 mm width, 45-120 gsm. BW Papersystems sheeting. Natural pulp and local limestone. On-site PCC plant with Omya (Switzerland) - also runs CO2 capture linked to the PCC. Whether Omya owns, operates or only supplied the PCC plant is not public, nor is PCC capacity.'),
  ('%Crown Paper%', '%Crown Paper Mill%', '%Crown%', 'Ittihad International Investment 계열 티슈 원지 제조사 Crown Paper Mill(1996년~). 아부다비 ICAD III, 초지기 3대 연산 10만 t, 버진·재생 티슈.', 'Crown Paper Mill (Ittihad International Investment, since 1996), ICAD III Abu Dhabi - tissue base paper, three machines, 100,000 t/yr, virgin and recycled.', null),
  ('%Abu Dhabi National Paper%', '%ADNPM%', '%Abu Dhabi National%', '아부다비 ICAD 의 Abu Dhabi National Paper Mill(ADNPM, 2000년 설립). Crescent Former 티슈 초지기 3대(Valmet NTT 포함), 연 9만 t 이상, 사무용 폐지 탈묵설비 보유.', 'Abu Dhabi National Paper Mill (ADNPM, founded 2000), ICAD - three crescent-former tissue machines incl. a Valmet Advantage NTT line, over 90,000 t/yr, deinking of recovered office paper.', 'UAE check 2026-10-14: contact per report info@adnpm.ae, +971-2-5099200.'),
  ('%Star Paper%Tissue%', '%Star Paper Mill%', '%Star Paper%', 'Star Paper Mill 의 아부다비 ICAD II 티슈 공장. Recard 크레센트 포머 초지기(폭 3.6m), 평량 12.5~45 gsm, 연산 4만 t.', 'Star Paper Mill tissue plant, ICAD II Abu Dhabi - Recard crescent-former machine, 3.6 m width, 12.5-45 gsm, 40,000 t/yr.', null),
  ('%Nakheel%', '%Fine Hygienic%', '%Nakheel%', 'Fine Hygienic Holding 의 아부다비 ICAD II 티슈 공장 Al Nakheel Paper Mill. Valmet Advantage DCT 설비, 1단계 계획 연 6만 t. 요르단·이집트에도 공장.', 'Al Nakheel Paper Mill of Fine Hygienic Holding, ICAD II Abu Dhabi - Valmet Advantage DCT tissue line, phase 1 planned at 60,000 t/yr. Group also has mills in Jordan and Egypt.', null),
  ('%Queenex%', '%Queenex%', '%Queenex%', '아부다비 ICAD 의 Queenex Hygiene Paper(2012년 가동). PM1 연 3.2만 t(2,100 m/min), 탈묵설비, PM2 6.5만 t 증설 추진.', 'Queenex Hygiene Paper Manufacturing, ICAD Abu Dhabi, running since 2012 - PM1 32,000 t/yr at 2,100 m/min, deinking plant, PM2 (65,000 t/yr) planned.', null),
  ('%Star Paper%KEZAD%', '%Star Paper%Container%', '%Star Paper%', 'Star Paper Mill 의 아부다비 KEZAD 재생 포장원지 공장. 약 AED 2억 투자, 연 13.5만 t, 2026-04 가동·2026-05-07 공식 개장.', 'Star Paper Mill recycled containerboard plant, KEZAD Abu Dhabi - about AED 200m, 135,000 t/yr, started 2026-04, officially opened 2026-05-07.', null),
  ('%Union Paper%', '%UPM%UAE%', '%Union Paper%', 'M.A.H.Y. Khoory 그룹의 재생 포장원지 제조사 Union Paper Mills(두바이). 테스트라이너·골심지·코어보드.', 'Union Paper Mills (M.A.H.Y. Khoory Group), Dubai - recycled testliner, fluting and coreboard.', 'UAE check 2026-10-14: about 500 t/day at Dubai, sister mill Al Dhafra (Abu Dhabi) about 650 t/day. Testliner 90-200, fluting 90-175, coreboard 190-350 gsm. Contact per report info@upmuae.com.'),
  ('%Dhafra%', '%Al Dhafra Paper%', '%Dhafra%', 'M.A.H.Y. Khoory 그룹의 아부다비 재생 포장원지 공장 Al Dhafra Paper Manufacturing.', 'Al Dhafra Paper Manufacturing (M.A.H.Y. Khoory Group), Abu Dhabi - recycled packaging base paper.', null),
  ('%Gulf Paper%Dubai%', '%Gulf Paper%Jebel%', '%Gulf Paper%', '쿠웨이트 Gulf Paper Manufacturing 의 두바이 제벨알리 공장. 기존 설비를 인수·재건해 2005년 생산 시작, 포장원지.', 'Dubai Jebel Ali Free Zone mill of Kuwait''s Gulf Paper Manufacturing - rebuilt acquired line, producing packaging base paper since 2005.', null),
  ('%Arabian Kraft%', '%Arabian Kraft Paper%', '%Arabian Kraft%', '움알쿠와인 산업도시의 Arabian Kraft Paper. MG 크라프트지·재생 크라프트지(봉투용), 연 2만 t.', 'Arabian Kraft Paper Manufacturing, Umm Al Quwain Industrial City - MG kraft and recycled kraft for paper bags, 20,000 t/yr.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'uae_update_20261014';

-- ---------- 3) LINK Omya (UAE) -> Ittihad ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'active', 'PCC filler-grade', null, 'medium', '2020-01-01'::date, null,
       'Omya on-site PCC inside Ittihad Paper Mill, ICAD II | src: ittihadpapermill.com',
       jsonb_build_object('supply_structure', 'on-site PCC (Omya technology, owner / operator to confirm)',
                          'link_kind', 'pcc_onsite', 'source', 'Ittihad Paper Mill site',
                          'batch', 'uae_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values ('%Ittihad Paper%', '%Ittihad%Paper Mill%', '%Ittihad%')) as v(name_like, alt_like, owner_like)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ilike 'Omya%UAE%'
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Ittihad Paper%', '%Ittihad%Paper Mill%', '%Ittihad%'),
  ('%Crown Paper%', '%Crown Paper Mill%', '%Crown%'),
  ('%Abu Dhabi National Paper%', '%ADNPM%', '%Abu Dhabi National%'),
  ('%Star Paper%Tissue%', '%Star Paper Mill%', '%Star Paper%'),
  ('%Nakheel%', '%Fine Hygienic%', '%Nakheel%'),
  ('%Queenex%', '%Queenex%', '%Queenex%'),
  ('%Star Paper%KEZAD%', '%Star Paper%Container%', '%Star Paper%'),
  ('%Union Paper%', '%UPM%UAE%', '%Union Paper%'),
  ('%Dhafra%', '%Al Dhafra Paper%', '%Dhafra%'),
  ('%Gulf Paper%Dubai%', '%Gulf Paper%Jebel%', '%Gulf Paper%'),
  ('%Arabian Kraft%', '%Arabian Kraft Paper%', '%Arabian Kraft%')
  ) as v(name_like, alt_like, owner_like)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Ittihad Paper%', '%Ittihad%Paper Mill%', '%Ittihad%',
   $pj${"owner": "Ittihad International Investment", "priority": 1, "products": "Uncoated woodfree, A4 copy, printing and writing, label base paper", "grades": ["Copy paper", "Uncoated woodfree", "Label base"], "machines": 1, "capacity": {"value": 325000, "unit": "metric_t", "year": "Company site, started 2020", "source": "ittihadpapermill.com"}, "filler": [{"supplier": "Omya", "type": "On-site PCC plant inside the mill", "status": "Stated by the mill", "basis": "Owner / operator role and capacity not public"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "FCC through the existing Omya on-site PCC plant - copy and printing paper", "approach": "Top UAE account and the Middle East proof point. Confirm Omya's role at the PCC plant first - it decides the licence counterparty. Royalty licensee is Omya at HQ level. Group also owns Crown Paper Mill (tissue).", "to_collect": ["Current PCC grade and on-site plant output, owner and operator", "Filler loading per grade, retention aid, furnish", "Who approves a machine trial"], "sources": [{"label": "ittihadpapermill.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Crown Paper%', '%Crown Paper Mill%', '%Crown%',
   $pj${"owner": "Ittihad International Investment", "priority": 2, "products": "Toilet, facial, kitchen towel, napkin and hand towel base paper", "grades": ["Tissue", "Towel"], "machines": 3, "capacity_split": [{"label": "Three tissue machines", "value_t": 100000}], "pitch": "Tissue FCC as a separate program inside the Ittihad group", "approach": "Pick one or two grades for a small trial - virgin and recycled separately.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Abu Dhabi National Paper%', '%ADNPM%', '%Abu Dhabi National%',
   $pj${"owner": "Abu Dhabi National Paper Mill", "priority": 3, "products": "Tissue base paper - textured NTT, virgin and recycled", "grades": ["Tissue"], "machines": 3, "capacity_split": [{"label": "Company figure (over)", "value_t": 90000}], "pitch": "Compare virgin and recycled tissue with FCC", "approach": "Start on standard tissue - NTT premium grades risk softness and absorbency loss.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Star Paper%Tissue%', '%Star Paper Mill%', '%Star Paper%',
   $pj${"owner": "Star Paper Mill Paper Industry", "priority": 4, "products": "Facial, toilet, napkin, kitchen and high wet-strength towel base paper", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "Tissue", "value_t": 40000}], "pitch": "12.5-15 gsm grades match the MBG low-grammage tissue trial", "approach": "Low-grammage tissue trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nakheel%', '%Fine Hygienic%', '%Nakheel%',
   $pj${"owner": "Fine Hygienic Holding", "priority": 5, "products": "Fine-brand tissue base paper", "grades": ["Tissue"], "capacity_split": [{"label": "Phase 1 planned", "value_t": 60000}], "pitch": "A UAE tissue win can roll out to Fine mills in Jordan and Egypt", "approach": "Group-level tissue program.", "recent": [{"date": "2024", "text": "Valmet reported a 24-hour production record of about 255 t"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Queenex%', '%Queenex%', '%Queenex%',
   $pj${"owner": "Queenex Hygiene Paper Manufacturing", "priority": 6, "products": "Toilet and facial tissue, virgin and recycled", "grades": ["Tissue"], "capacity_split": [{"label": "PM1", "value_t": 32000}, {"label": "PM2 planned - not confirmed running", "value_t": 65000}], "approach": "Small joint trial comparing virgin and recycled tissue.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Star Paper%KEZAD%', '%Star Paper%Container%', '%Star Paper%',
   $pj${"owner": "Star Paper Mill Paper Industry", "priority": 7, "products": "Testliner, fluting, kraft top liner, bag paper", "grades": ["Testliner", "Fluting"], "capacity_split": [{"label": "Recycled containerboard", "value_t": 135000}], "approach": "Strength check first - compression and burst must hold.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Union Paper%', '%UPM%UAE%', '%Union Paper%',
   $pj${"owner": "M.A.H.Y. Khoory Group", "priority": 8, "products": "Testliner, fluting, coreboard", "grades": ["Testliner", "Fluting", "Coreboard"], "capacity_split": [{"label": "Dubai, about 500 t/day x 330 days (calculated)", "value_t": 165000}], "approach": "Optimise recycled fibre and cost together - not just more filler. SCT, RCT, CMT, burst and drainage first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Dhafra%', '%Al Dhafra Paper%', '%Dhafra%',
   $pj${"owner": "M.A.H.Y. Khoory Group", "products": "Testliner, fluting, coreboard", "capacity_split": [{"label": "About 650 t/day x 330 days (calculated)", "value_t": 214500}], "approach": "Valmet supplied wet-end dewatering parts in 2024 - drainage effects can be measured.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Gulf Paper%Dubai%', '%Gulf Paper%Jebel%', '%Gulf Paper%',
   $pj${"owner": "Gulf Paper Manufacturing (Kuwait)", "priority": 9, "products": "Packaging base paper", "capacity_split": [{"label": "2011-2016 output about 65,000-67,000 t, target", "value_t": 70000}], "approach": "Check whether filler and fibre furnish can change on the recycled line.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Arabian Kraft%', '%Arabian Kraft Paper%', '%Arabian Kraft%',
   $pj${"owner": "Arabian Kraft Paper Manufacturing", "priority": 10, "products": "MG kraft, virgin and recycled kraft for bags", "capacity_split": [{"label": "Company figure", "value_t": 20000}], "approach": "Bag kraft is tensile, tear and stretch led - filler may not help.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Ittihad Paper%', '%Ittihad%Paper Mill%', '%Ittihad%'),
  ('%Crown Paper%', '%Crown Paper Mill%', '%Crown%'),
  ('%Abu Dhabi National Paper%', '%ADNPM%', '%Abu Dhabi National%'),
  ('%Star Paper%Tissue%', '%Star Paper Mill%', '%Star Paper%'),
  ('%Nakheel%', '%Fine Hygienic%', '%Nakheel%'),
  ('%Queenex%', '%Queenex%', '%Queenex%'),
  ('%Star Paper%KEZAD%', '%Star Paper%Container%', '%Star Paper%'),
  ('%Union Paper%', '%UPM%UAE%', '%Union Paper%'),
  ('%Dhafra%', '%Al Dhafra Paper%', '%Dhafra%'),
  ('%Gulf Paper%Dubai%', '%Gulf Paper%Jebel%', '%Gulf Paper%'),
  ('%Arabian Kraft%', '%Arabian Kraft Paper%', '%Arabian Kraft%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'uae_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'uae_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike 'Omya%UAE%' or p.party_name ilike '%General Mineral Industries%' or p.party_name ilike '%Emirates Calcium Carbonate%' or p.party_name ilike '%Gulf Lime%' or p.party_name ilike '%Apex Chemical%' or p.party_name ilike '%Wasit%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'uae_update_20261014'
order by 1, 4, 2;
