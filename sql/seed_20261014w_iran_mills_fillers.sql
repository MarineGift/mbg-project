-- ============================================================
-- seed_20261014w_iran_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Iran update (reports 2026-10). RECORD-ONLY, ON HOLD: US sanctions on Iran
-- (OFAC) - MBG is a US company. Every plant block says ON HOLD, no outreach
-- priority is set, and no contact e-mails are stored. Introduction ->
-- intro_ko / intro_en (only when empty), detail -> notes once with
-- 'IR check 2026-10-14'.
--
-- 1) Fillers if missing: Chemie Ma-Dani Hamadan (PCC, GCC), Pars Hasti Asia
--    (PCC, nano PCC), Arman Powder Lorestan, Arosha, MAD KOOHZAD, Farayand,
--    Arya Powder Pars. Skipped: Poudresazan, Iran Kaolin and Barite.
-- 2) Mills if missing + plant blocks (technical rank in the approach text):
--    Mazandaran, Pars Paper, Dibaye Shushtar, Zarrin Barg, Pars Hayat,
--    Latif, Harir Khuzestan, Golpoune Pars, Aryan Cellulose, Zagros Fars,
--    Chooka, Kaveh. Pars Tamin stone paper skipped (not cellulose paper).
--    No FCC scenarios, no supply links.
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
       v.party_name, 'IR', v.region, v.city, v.website, 'active', 'iran_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Chemie Ma-Dani Hamadan (CMHCO)', '%Ma-Dani%', 'Hamadan', 'Hamadan', null, '하마단의 Chemie Ma-Dani Hamadan(BARIN). PCC·GCC·생석회, 1998년 설비 정비, 제지 포함 적용 산업 명시.', 'Chemie Ma-Dani Hamadan (BARIN brand), Hamadan - PCC, GCC and quicklime, plant modernised 1998, paper named among markets.', 'IR check 2026-10-14: listed as an Iranian PCC producer in a 2005 PCC survey (historical). Current status and capacity unknown. US sanctions - no contact until cleared.'),
  ('Pars Hasti Asia', '%Pars Hasti%', 'Tehran', 'Tehran', 'https://www.parshastiasia.com', '테헤란 본사 Pars Hasti Asia. PCC·나노 PCC·석회, 2022년 석회·2024년 나노 PCC 생산 시작 주장, 공장 위치 미확인.', 'Pars Hasti Asia, Tehran head office - PCC, nano PCC, quick and hydrated lime, claims lime output since 2022 and nano PCC since 2024, plant location not public.', 'IR check 2026-10-14: paper-grade PCC, volumes and customers not confirmed. US sanctions - no contact until cleared.'),
  ('Arman Powder Lorestan', '%Arman Powder%', 'Lorestan', 'Aligudarz', 'https://www.armanpco.com', '로레스탄 Aligudarz 공장의 Arman Powder. 미분쇄 탄산칼슘, 제지용 1500·2500 mesh 명시.', 'Arman Powder Lorestan, plant at Aligudarz - micronised calcium carbonate, names 1,500 and 2,500 mesh grades for paper.', 'IR check 2026-10-14: US sanctions - no contact until cleared.'),
  ('Arosha Powder', '%Arosha%', null, null, 'https://www.aroshapowder.co', '2005년 설립 이란 GCC 제조사 Arosha Powder. 석회석 광산 4곳 주장, 비코팅·코팅 GCC(100~2500 mesh), 제지 포함.', 'Arosha Powder (founded 2005), Iran - uncoated and coated GCC (100-2,500 mesh), four claimed own limestone quarries, paper among uses.', 'IR check 2026-10-14: coated grades are for polymers - not wet-end filler. US sanctions - no contact until cleared.'),
  ('MAD KOOHZAD', '%KOOHZAD%', 'Tehran', 'Tehran', 'https://www.madkoohzad.com', '테헤란 Lavizan 본사 MAD KOOHZAD. 고순도 GCC(CaCO3 98~99.5%, 200~3500 mesh), 제지 충전·코팅 용도, 이라크·UAE·쿠웨이트 수출.', 'MAD KOOHZAD, Lavizan Tehran - high-purity GCC (CaCO3 98-99.5 pct, 200-3,500 mesh) for paper filling and coating, exports to Iraq, UAE, Kuwait.', 'IR check 2026-10-14: brightness method not stated, mesh is not a D50. US sanctions - no contact until cleared.'),
  ('Farayand Powder Alvan', '%Farayand%', null, null, null, '36년 이상 광물 분말 경력의 Farayand Powder Alvan. 코팅·비코팅 탄산칼슘, 2500 mesh+, 제지 포함, 다국 수출.', 'Farayand Powder Alvan - over 36 years of mineral powders, coated and uncoated calcium carbonate up to 2,500 mesh+, paper among uses, exports to India, Spain, Romania and the Gulf.', 'IR check 2026-10-14: US sanctions - no contact until cleared.'),
  ('Arya Powder Pars', '%Arya Powder%', 'Isfahan', 'Salafchegan', 'https://www.aryapowderpars.com', 'Salafchegan 산업단지의 Arya Powder Pars. 미분쇄·코팅 GCC, 탈크, 바라이트, 수출.', 'Arya Powder Pars, Salafchegan Industrial Zone - micronised and coated GCC, talc, barite, export.', 'IR check 2026-10-14: paper-grade GCC not confirmed. US sanctions - no contact until cleared.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%IR check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Chemie Ma-Dani Hamadan (CMHCO)', '%Ma-Dani%', 'Hamadan', 'Hamadan', null, '하마단의 Chemie Ma-Dani Hamadan(BARIN). PCC·GCC·생석회, 1998년 설비 정비, 제지 포함 적용 산업 명시.', 'Chemie Ma-Dani Hamadan (BARIN brand), Hamadan - PCC, GCC and quicklime, plant modernised 1998, paper named among markets.', 'IR check 2026-10-14: listed as an Iranian PCC producer in a 2005 PCC survey (historical). Current status and capacity unknown. US sanctions - no contact until cleared.'),
  ('Pars Hasti Asia', '%Pars Hasti%', 'Tehran', 'Tehran', 'https://www.parshastiasia.com', '테헤란 본사 Pars Hasti Asia. PCC·나노 PCC·석회, 2022년 석회·2024년 나노 PCC 생산 시작 주장, 공장 위치 미확인.', 'Pars Hasti Asia, Tehran head office - PCC, nano PCC, quick and hydrated lime, claims lime output since 2022 and nano PCC since 2024, plant location not public.', 'IR check 2026-10-14: paper-grade PCC, volumes and customers not confirmed. US sanctions - no contact until cleared.'),
  ('Arman Powder Lorestan', '%Arman Powder%', 'Lorestan', 'Aligudarz', 'https://www.armanpco.com', '로레스탄 Aligudarz 공장의 Arman Powder. 미분쇄 탄산칼슘, 제지용 1500·2500 mesh 명시.', 'Arman Powder Lorestan, plant at Aligudarz - micronised calcium carbonate, names 1,500 and 2,500 mesh grades for paper.', 'IR check 2026-10-14: US sanctions - no contact until cleared.'),
  ('Arosha Powder', '%Arosha%', null, null, 'https://www.aroshapowder.co', '2005년 설립 이란 GCC 제조사 Arosha Powder. 석회석 광산 4곳 주장, 비코팅·코팅 GCC(100~2500 mesh), 제지 포함.', 'Arosha Powder (founded 2005), Iran - uncoated and coated GCC (100-2,500 mesh), four claimed own limestone quarries, paper among uses.', 'IR check 2026-10-14: coated grades are for polymers - not wet-end filler. US sanctions - no contact until cleared.'),
  ('MAD KOOHZAD', '%KOOHZAD%', 'Tehran', 'Tehran', 'https://www.madkoohzad.com', '테헤란 Lavizan 본사 MAD KOOHZAD. 고순도 GCC(CaCO3 98~99.5%, 200~3500 mesh), 제지 충전·코팅 용도, 이라크·UAE·쿠웨이트 수출.', 'MAD KOOHZAD, Lavizan Tehran - high-purity GCC (CaCO3 98-99.5 pct, 200-3,500 mesh) for paper filling and coating, exports to Iraq, UAE, Kuwait.', 'IR check 2026-10-14: brightness method not stated, mesh is not a D50. US sanctions - no contact until cleared.'),
  ('Farayand Powder Alvan', '%Farayand%', null, null, null, '36년 이상 광물 분말 경력의 Farayand Powder Alvan. 코팅·비코팅 탄산칼슘, 2500 mesh+, 제지 포함, 다국 수출.', 'Farayand Powder Alvan - over 36 years of mineral powders, coated and uncoated calcium carbonate up to 2,500 mesh+, paper among uses, exports to India, Spain, Romania and the Gulf.', 'IR check 2026-10-14: US sanctions - no contact until cleared.'),
  ('Arya Powder Pars', '%Arya Powder%', 'Isfahan', 'Salafchegan', 'https://www.aryapowderpars.com', 'Salafchegan 산업단지의 Arya Powder Pars. 미분쇄·코팅 GCC, 탈크, 바라이트, 수출.', 'Arya Powder Pars, Salafchegan Industrial Zone - micronised and coated GCC, talc, barite, export.', 'IR check 2026-10-14: paper-grade GCC not confirmed. US sanctions - no contact until cleared.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'iran_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Chemie Ma-Dani Hamadan (CMHCO)', 'PCC producer', 'Iran PCC and GCC - on hold (sanctions)', 'merchant', 'C', 'pcc'),
  ('Pars Hasti Asia', 'PCC producer', 'Iran nano PCC - on hold (sanctions)', 'merchant', 'C', 'pcc'),
  ('Arman Powder Lorestan', 'GCC producer', 'Iran paper GCC - on hold (sanctions)', 'merchant', 'C', 'gcc'),
  ('Arosha Powder', 'GCC producer', 'Iran GCC - on hold (sanctions)', 'merchant', 'C', 'gcc'),
  ('MAD KOOHZAD', 'GCC producer', 'Iran high-purity GCC - on hold (sanctions)', 'merchant', 'C', 'gcc'),
  ('Farayand Powder Alvan', 'GCC producer', 'Iran GCC exporter - on hold (sanctions)', 'merchant', 'C', 'gcc'),
  ('Arya Powder Pars', 'GCC producer', 'Iran GCC - on hold (sanctions)', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'iran_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'IR', v.region, v.city, v.website, 'active', 'iran_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Mazandaran Wood%', '%Mazandaran Paper%', 'Mazandaran Wood and Paper Industries (Sari)', 'Mazandaran', 'Sari', 'https://www.mazpaper.com', '1997년 설립 이란 사리의 Mazandaran Wood and Paper Industries. 인쇄·필기용지·신문용지·골심지, 명목능력 연 17.5만~18.5만 t(필기용지 8.5만 t).', 'Mazandaran Wood and Paper Industries (founded 1997), Sari, Iran - printing and writing, newsprint and fluting, nameplate 175,000-185,000 t/yr (85,000 t writing paper).', 'IR check 2026-10-14: some printing lines stopped 2020 on logging limits, later restarted. Late 2025 talks for 35,000 t of textbook paper. Government priority mill for writing-paper self-sufficiency. US sanctions apply.'),
  ('%Pars Paper%', '%Haft Tappeh%Paper%', 'Pars Paper Industrial Group (Haft Tappeh)', 'Khuzestan', 'Haft Tappeh', null, '후제스탄 Haft Tappeh 의 Pars Paper. 사탕수수 바가스 펄프 기반 인쇄·필기용지·신문용지·위생용지.', 'Pars Paper Industrial Group, Haft Tappeh, Khuzestan - sugarcane bagasse pulp, printing and writing, newsprint, hygiene paper.', 'IR check 2026-10-14: capacity 40,000 t (2012 study) versus 100,000 t (directory) - not reconciled. 2023 output hit by foreign-currency allocation. US sanctions apply.'),
  ('%Dibaye Shushtar%', '%Shushtar%Paper%', 'Dibaye Shushtar Pulp and Paper (Shushtar)', 'Khuzestan', 'Shushtar', null, '후제스탄 Shushtar 의 Dibaye Shushtar Pulp & Paper. 바가스 섬유 백색지·인쇄·필기용지·크라프트·펄프.', 'Dibaye Shushtar Pulp and Paper, Shushtar, Khuzestan - bagasse-fibre white, printing and writing, kraft paper and pulp.', 'IR check 2026-10-14: joint 20,000 t writing-paper plan with Pars Paper (2023) - not its own capacity. US sanctions apply.'),
  ('%Zarrin Barg%', '%ZBP%', 'Zarrin Barg Persia (Saveh)', 'Markazi', 'Saveh', 'https://www.zbpco.com', '사베 Kaveh 산업도시의 Zarrin Barg Persia. Valmet DCT200TS 티슈기 2대, 연 12만 t, 탈묵설비 약 6만 t.', 'Zarrin Barg Persia, Kaveh Industrial City, Saveh - two Valmet DCT200TS tissue machines, 120,000 t/yr, deinking about 60,000 t/yr, virgin and deinked pulp.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Pars Hayat%', '%Hayat Kimya%Iran%', 'Pars Hayat (Iran)', null, null, null, '터키 Hayat Kimya 그룹 계열의 이란 티슈사업 Pars Hayat. 2013년 Valmet Advantage DCT 라인 가동, 연 약 7만 t.', 'Pars Hayat, Iranian tissue business of Turkey''s Hayat Kimya group - Valmet Advantage DCT line since 2013, about 70,000 t/yr.', 'IR check 2026-10-14: purchasing and R and D decisions may sit with Hayat Kimya in Turkey - but the Iranian site is still sanctions-exposed.'),
  ('%Latif Paper%', '%Latif%', 'Latif Paper Products (Hashtgerd)', 'Alborz', 'Hashtgerd', null, '1985년 설립 Hashtgerd 산업단지의 Latif Paper. 저평량지·티슈, 폭 2,860mm 초지기, 탈묵설비, 연 1.5만~1.8만 t.', 'Latif Paper Products (founded 1985), Hashtgerd Industrial Estate - tissue and low-grammage paper, 2,860 mm machine, deinking, 15,000-18,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Harir Khuzestan%', '%Harir%', 'Harir Khuzestan Tissue (Haft Tappeh)', 'Khuzestan', 'Haft Tappeh', null, '후제스탄 Haft Tappeh 의 초기 티슈 제조사 Harir Khuzestan(TASICO). Voith 설비 연 약 1.5만 t.', 'Harir Khuzestan, Haft Tappeh, Khuzestan - early Iranian tissue maker (TASICO holding), Voith line about 15,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Golpoune%', '%Golpoune Pars%', 'Golpoune Pars Tissue (Iran)', null, null, null, '이란 티슈원지 제조사 Golpoune Pars. 폭 2.75m, 2014년 가동, 연 약 1.8만 t.', 'Golpoune Pars - Iranian tissue base paper, 2.75 m machine started 2014, about 18,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Aryan Cellulose%', '%Aryan Cellulose Sanat%', 'Aryan Cellulose Sanat (Iran)', null, null, null, '이란 티슈원지 제조사 Aryan Cellulose Sanat. 폭 2.8m, 2014년 가동, 연 약 1만 t.', 'Aryan Cellulose Sanat - Iranian tissue base paper, 2.8 m machine started 2014, about 10,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%IR check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mazandaran Wood%', '%Mazandaran Paper%', '%Mazandaran%', '1997년 설립 이란 사리의 Mazandaran Wood and Paper Industries. 인쇄·필기용지·신문용지·골심지, 명목능력 연 17.5만~18.5만 t(필기용지 8.5만 t).', 'Mazandaran Wood and Paper Industries (founded 1997), Sari, Iran - printing and writing, newsprint and fluting, nameplate 175,000-185,000 t/yr (85,000 t writing paper).', 'IR check 2026-10-14: some printing lines stopped 2020 on logging limits, later restarted. Late 2025 talks for 35,000 t of textbook paper. Government priority mill for writing-paper self-sufficiency. US sanctions apply.'),
  ('%Pars Paper%', '%Haft Tappeh%Paper%', '%Pars Paper%', '후제스탄 Haft Tappeh 의 Pars Paper. 사탕수수 바가스 펄프 기반 인쇄·필기용지·신문용지·위생용지.', 'Pars Paper Industrial Group, Haft Tappeh, Khuzestan - sugarcane bagasse pulp, printing and writing, newsprint, hygiene paper.', 'IR check 2026-10-14: capacity 40,000 t (2012 study) versus 100,000 t (directory) - not reconciled. 2023 output hit by foreign-currency allocation. US sanctions apply.'),
  ('%Dibaye Shushtar%', '%Shushtar%Paper%', '%Dibaye%', '후제스탄 Shushtar 의 Dibaye Shushtar Pulp & Paper. 바가스 섬유 백색지·인쇄·필기용지·크라프트·펄프.', 'Dibaye Shushtar Pulp and Paper, Shushtar, Khuzestan - bagasse-fibre white, printing and writing, kraft paper and pulp.', 'IR check 2026-10-14: joint 20,000 t writing-paper plan with Pars Paper (2023) - not its own capacity. US sanctions apply.'),
  ('%Zarrin Barg%', '%ZBP%', '%Zarrin%', '사베 Kaveh 산업도시의 Zarrin Barg Persia. Valmet DCT200TS 티슈기 2대, 연 12만 t, 탈묵설비 약 6만 t.', 'Zarrin Barg Persia, Kaveh Industrial City, Saveh - two Valmet DCT200TS tissue machines, 120,000 t/yr, deinking about 60,000 t/yr, virgin and deinked pulp.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Pars Hayat%', '%Hayat Kimya%Iran%', '%Hayat%', '터키 Hayat Kimya 그룹 계열의 이란 티슈사업 Pars Hayat. 2013년 Valmet Advantage DCT 라인 가동, 연 약 7만 t.', 'Pars Hayat, Iranian tissue business of Turkey''s Hayat Kimya group - Valmet Advantage DCT line since 2013, about 70,000 t/yr.', 'IR check 2026-10-14: purchasing and R and D decisions may sit with Hayat Kimya in Turkey - but the Iranian site is still sanctions-exposed.'),
  ('%Latif Paper%', '%Latif%', '%Latif%', '1985년 설립 Hashtgerd 산업단지의 Latif Paper. 저평량지·티슈, 폭 2,860mm 초지기, 탈묵설비, 연 1.5만~1.8만 t.', 'Latif Paper Products (founded 1985), Hashtgerd Industrial Estate - tissue and low-grammage paper, 2,860 mm machine, deinking, 15,000-18,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Harir Khuzestan%', '%Harir%', '%Harir%', '후제스탄 Haft Tappeh 의 초기 티슈 제조사 Harir Khuzestan(TASICO). Voith 설비 연 약 1.5만 t.', 'Harir Khuzestan, Haft Tappeh, Khuzestan - early Iranian tissue maker (TASICO holding), Voith line about 15,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Golpoune%', '%Golpoune Pars%', '%Golpoune%', '이란 티슈원지 제조사 Golpoune Pars. 폭 2.75m, 2014년 가동, 연 약 1.8만 t.', 'Golpoune Pars - Iranian tissue base paper, 2.75 m machine started 2014, about 18,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Aryan Cellulose%', '%Aryan Cellulose Sanat%', '%Aryan%', '이란 티슈원지 제조사 Aryan Cellulose Sanat. 폭 2.8m, 2014년 가동, 연 약 1만 t.', 'Aryan Cellulose Sanat - Iranian tissue base paper, 2.8 m machine started 2014, about 10,000 t/yr.', 'IR check 2026-10-14: US sanctions apply.'),
  ('%Zagros Fars%', '%Zagros%Paper%', '%Zagros%', '파르스주 Zarqan 인근 인쇄·필기용지 프로젝트 Zagros Fars Paper. 전력·금융·설비 문제로 2026년 정상 가동 미확인.', 'Zagros Fars Paper, near Zarqan, Fars - printing and writing paper project, not in normal production as of 2026 (power, finance, equipment issues).', null),
  ('%Chooka%', '%Chouka%', '%Chooka%', '길란 Talesh 의 Chooka Wood and Paper. 크라프트·세미크라프트 포장용지, 명목 연 15만 t, 2026-09 정상화 추진 중.', 'Chooka Wood and Paper Industries, Talesh, Gilan - kraft and semi-kraft packaging, nameplate 150,000 t/yr, restart efforts reported 2026-09.', null),
  ('%Kaveh Paper%', '%Kaveh Paper Industries%', '%Kaveh%', '사베 Kaveh 산업단지의 재생 포장용지 제조사 Kaveh Paper. 테스트라이너·골심지, 연 2.5만 t.', 'Kaveh Paper Industries, Kaveh Industrial City, Saveh - recycled testliner, fluting and liner, 25,000 t/yr.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'iran_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mazandaran Wood%', '%Mazandaran Paper%', '%Mazandaran%'),
  ('%Pars Paper%', '%Haft Tappeh%Paper%', '%Pars Paper%'),
  ('%Dibaye Shushtar%', '%Shushtar%Paper%', '%Dibaye%'),
  ('%Zarrin Barg%', '%ZBP%', '%Zarrin%'),
  ('%Pars Hayat%', '%Hayat Kimya%Iran%', '%Hayat%'),
  ('%Latif Paper%', '%Latif%', '%Latif%'),
  ('%Harir Khuzestan%', '%Harir%', '%Harir%'),
  ('%Golpoune%', '%Golpoune Pars%', '%Golpoune%'),
  ('%Aryan Cellulose%', '%Aryan Cellulose Sanat%', '%Aryan%'),
  ('%Zagros Fars%', '%Zagros%Paper%', '%Zagros%'),
  ('%Chooka%', '%Chouka%', '%Chooka%'),
  ('%Kaveh Paper%', '%Kaveh Paper Industries%', '%Kaveh%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Mazandaran Wood%', '%Mazandaran Paper%', '%Mazandaran%',
   $pj${"owner": "Mazandaran Wood and Paper Industries", "products": "Printing and writing, newsprint, fluting", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 1 if cleared.", "checked_at": "2026-10-14", "grades": ["Writing and printing", "Newsprint"], "capacity_split": [{"label": "Nameplate (range by source)", "value_t": 185000}, {"label": "Writing paper", "value_t": 85000}]}$pj$::jsonb),
  ('%Pars Paper%', '%Haft Tappeh%Paper%', '%Pars Paper%',
   $pj${"owner": "Pars Paper Industrial Group", "products": "Bagasse pulp, printing and writing, newsprint, hygiene paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 2 if cleared. Bagasse sheet - FCC fibre-replacement research case.", "checked_at": "2026-10-14", "grades": ["Writing and printing"]}$pj$::jsonb),
  ('%Dibaye Shushtar%', '%Shushtar%Paper%', '%Dibaye%',
   $pj${"owner": "Dibaye Shushtar", "products": "Bagasse printing and writing, kraft, pulp", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 3 if cleared.", "checked_at": "2026-10-14", "grades": ["Writing and printing"]}$pj$::jsonb),
  ('%Zarrin Barg%', '%ZBP%', '%Zarrin%',
   $pj${"owner": "Zarrin Barg Persia", "products": "Tissue base paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 4 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "Two tissue machines", "value_t": 120000}]}$pj$::jsonb),
  ('%Pars Hayat%', '%Hayat Kimya%Iran%', '%Hayat%',
   $pj${"owner": "Hayat Kimya group", "products": "Tissue base paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 5 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "DCT line", "value_t": 70000}]}$pj$::jsonb),
  ('%Latif Paper%', '%Latif%', '%Latif%',
   $pj${"owner": "TASICO holding", "products": "Tissue and low-grammage paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 6 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "Range by source", "value_t": 18000}]}$pj$::jsonb),
  ('%Harir Khuzestan%', '%Harir%', '%Harir%',
   $pj${"owner": "TASICO holding", "products": "Tissue base paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 7 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "Voith line", "value_t": 15000}]}$pj$::jsonb),
  ('%Golpoune%', '%Golpoune Pars%', '%Golpoune%',
   $pj${"owner": "Golpoune Pars", "products": "Tissue base paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 8 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "Machine", "value_t": 18000}]}$pj$::jsonb),
  ('%Aryan Cellulose%', '%Aryan Cellulose Sanat%', '%Aryan%',
   $pj${"owner": "Aryan Cellulose Sanat", "products": "Tissue base paper", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 9 if cleared.", "checked_at": "2026-10-14", "grades": ["Tissue"], "capacity_split": [{"label": "Machine", "value_t": 10000}]}$pj$::jsonb),
  ('%Zagros Fars%', '%Zagros%Paper%', '%Zagros%',
   $pj${"owner": "Zagros Fars Paper", "products": "Printing and writing paper (planned)", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 10 if cleared. Re-evaluate only once running.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Chooka%', '%Chouka%', '%Chooka%',
   $pj${"owner": "Chooka Wood and Paper", "products": "Kraft and semi-kraft packaging", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 11 if cleared.", "checked_at": "2026-10-14", "capacity_split": [{"label": "Nameplate (not output)", "value_t": 150000}]}$pj$::jsonb),
  ('%Kaveh Paper%', '%Kaveh Paper Industries%', '%Kaveh%',
   $pj${"owner": "Kaveh Paper Industries", "products": "Testliner, fluting, liner", "approach": "ON HOLD - US sanctions on Iran (OFAC). MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it. Technical rank 12 if cleared.", "checked_at": "2026-10-14", "capacity_split": [{"label": "Company figure", "value_t": 25000}]}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Mazandaran Wood%', '%Mazandaran Paper%', '%Mazandaran%'),
  ('%Pars Paper%', '%Haft Tappeh%Paper%', '%Pars Paper%'),
  ('%Dibaye Shushtar%', '%Shushtar%Paper%', '%Dibaye%'),
  ('%Zarrin Barg%', '%ZBP%', '%Zarrin%'),
  ('%Pars Hayat%', '%Hayat Kimya%Iran%', '%Hayat%'),
  ('%Latif Paper%', '%Latif%', '%Latif%'),
  ('%Harir Khuzestan%', '%Harir%', '%Harir%'),
  ('%Golpoune%', '%Golpoune Pars%', '%Golpoune%'),
  ('%Aryan Cellulose%', '%Aryan Cellulose Sanat%', '%Aryan%'),
  ('%Zagros Fars%', '%Zagros%Paper%', '%Zagros%'),
  ('%Chooka%', '%Chouka%', '%Chooka%'),
  ('%Kaveh Paper%', '%Kaveh Paper Industries%', '%Kaveh%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'iran_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'iran_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Ma-Dani%' or p.party_name ilike '%Pars Hasti%' or p.party_name ilike '%Arman Powder%' or p.party_name ilike '%Arosha%' or p.party_name ilike '%KOOHZAD%' or p.party_name ilike '%Farayand%' or p.party_name ilike '%Arya Powder%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'iran_update_20261014'
order by 1, 4, 2;
