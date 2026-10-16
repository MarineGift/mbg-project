-- ============================================================
-- seed_20261015o_thailand_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Thailand update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'TH check 2026-10-15',
-- plant data -> Mill profile card. Existing TH rows are matched first
-- (name regex OR city + owner regex) - same guard as the Mexico seed.
--
-- 1) Fillers if missing (5): Specialty Minerals (Thailand), Surint Omya,
--    F.M.T. (Thailand), Quality Minerals QMIN, MCS Mining.
-- 2) Mills if missing (7) + plant blocks, priority 1-6: Double A, BJC Cellox,
--    RiverPRO, Kimberly-Clark Thailand, Thai Paper (SCGP), United Paper,
--    plus Phoenix Pulp and Paper (no priority). Context, match only:
--    Siam Kraft, Thai Cane Paper, Thai Paper Mill.
-- 3) Supply links: SMI -> Double A (active, medium), SMI -> Phoenix
--    (historical, medium).
-- 4) app.country_markets TH row (priority high).
-- Verify also lists other existing TH mills ('other mill').
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
       v.party_name, 'TH', v.region, v.city, v.website, 'active', 'thailand_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('(specialty minerals|minerals technologies).*thai', 'Specialty Minerals (Thailand)', null, null, null, 'Minerals Technologies(SMI)의 태국 법인. Double A Tha Toom 제지공장 내 위성 PCC 2기(7만+8만 t, 2011~2013 발표), Phoenix Nam Phong 위성 PCC(2007 계약, 연 5만~7만 t 계획).', 'Specialty Minerals (Thailand), Minerals Technologies - two satellite PCC plants at the Double A Tha Toom mill (70,000 + 80,000 t/yr announced 2011-2013) and a satellite PCC at Phoenix Pulp and Paper, Nam Phong, Khon Kaen (2007 contract, 50,000-70,000 t/yr in two units).', 'TH check 2026-10-15: nameplates are 2007-2013 announcements - current output not confirmed. MTI FulFill E-325 commercial agreement with Double A announced earlier. Royalty licensee at MTI HQ level.'),
  ('surint|omya.*thai', 'Surint Omya Chemicals (Thailand)', 'Bangkok', 'Bangkok', null, 'Omya 계열 태국 사업회사. 제지용 GCC·PCC 충전제, GCC 코팅안료, 특수안료 공급. 과거 Omya 기술자료에 Lopburi 공장 생산 명시.', 'Surint Omya Chemicals (Thailand) - Omya group business in Thailand, GCC and PCC fillers, GCC coating pigments and specialty pigments for paper and board. Older Omya data sheets name a Lopburi plant.', 'TH check 2026-10-15: current Lopburi operator, capacity and mill customers not public. Royalty licensee at Omya HQ level.'),
  ('^f\.?\s?m\.?\s?t\.?\s.*thai', 'F.M.T. (Thailand) Co., Ltd.', 'Sing Buri', 'Sing Buri', null, '일본 Fimatec 계열(1995년 태국·일본·인도네시아 투자) 습식 분쇄 탄산칼슘(WGCC) 제조사. Sing Buri 생산, 제지·고무·페인트 공급. ISO 9001·14001.', 'F.M.T. (Thailand) Co., Ltd. - Fimatec (Japan) group, founded 1995 by Thai, Japanese and Indonesian investors - wet ground calcium carbonate (WGCC) made in Sing Buri, filler and coating grades for paper, also rubber and paint. ISO 9001, ISO 14001.', 'TH check 2026-10-15: Bangkok office Vanissa Building Tower B 15F, Soi Chidlom, +66 2 650 5020, fmtt@fmtthai.co.th. Slurry capacity and paper customers not public. Licence talk may run through Fimatec Japan.'),
  ('quality minerals|\mqmin\M', 'Quality Minerals PCL (QMIN)', 'Lopburi', 'Lopburi', null, '1995년 설립 Lopburi 의 GCC 제조사(상장). 방해석 원료 코팅·비코팅 GCC, 전체 연 18만 t. 인쇄·필기용지·듀플렉스 판지 용도.', 'Quality Minerals Public Co., Ltd. (QMIN), founded 1995 - coated and uncoated calcite-based GCC at its Lopburi plant, 180,000 t/yr total, paper uses printing and writing paper and duplex board.', 'TH check 2026-10-15: 180 kt is total GCC, not paper only. Dry powder - slurry line would be new. montri@qmin.co.th, +66 63 202 5348.'),
  ('mcs mining', 'MCS Mining Industry', null, null, null, '석회석 채굴·분쇄 GCC 분말, 생석회·소석회 생산업체.', 'MCS Mining Industry - limestone quarrying and grinding, GCC powder, quicklime and hydrated lime.', 'TH check 2026-10-15: raw-material source only - paper slurry and capacity not confirmed. Not added: Thai Poly Chemicals (Samut Sakhon, old listings only), Dusit Chemicals (no plant located).')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%TH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('(specialty minerals|minerals technologies).*thai', 'Specialty Minerals (Thailand)', null, null, null, 'Minerals Technologies(SMI)의 태국 법인. Double A Tha Toom 제지공장 내 위성 PCC 2기(7만+8만 t, 2011~2013 발표), Phoenix Nam Phong 위성 PCC(2007 계약, 연 5만~7만 t 계획).', 'Specialty Minerals (Thailand), Minerals Technologies - two satellite PCC plants at the Double A Tha Toom mill (70,000 + 80,000 t/yr announced 2011-2013) and a satellite PCC at Phoenix Pulp and Paper, Nam Phong, Khon Kaen (2007 contract, 50,000-70,000 t/yr in two units).', 'TH check 2026-10-15: nameplates are 2007-2013 announcements - current output not confirmed. MTI FulFill E-325 commercial agreement with Double A announced earlier. Royalty licensee at MTI HQ level.'),
  ('surint|omya.*thai', 'Surint Omya Chemicals (Thailand)', 'Bangkok', 'Bangkok', null, 'Omya 계열 태국 사업회사. 제지용 GCC·PCC 충전제, GCC 코팅안료, 특수안료 공급. 과거 Omya 기술자료에 Lopburi 공장 생산 명시.', 'Surint Omya Chemicals (Thailand) - Omya group business in Thailand, GCC and PCC fillers, GCC coating pigments and specialty pigments for paper and board. Older Omya data sheets name a Lopburi plant.', 'TH check 2026-10-15: current Lopburi operator, capacity and mill customers not public. Royalty licensee at Omya HQ level.'),
  ('^f\.?\s?m\.?\s?t\.?\s.*thai', 'F.M.T. (Thailand) Co., Ltd.', 'Sing Buri', 'Sing Buri', null, '일본 Fimatec 계열(1995년 태국·일본·인도네시아 투자) 습식 분쇄 탄산칼슘(WGCC) 제조사. Sing Buri 생산, 제지·고무·페인트 공급. ISO 9001·14001.', 'F.M.T. (Thailand) Co., Ltd. - Fimatec (Japan) group, founded 1995 by Thai, Japanese and Indonesian investors - wet ground calcium carbonate (WGCC) made in Sing Buri, filler and coating grades for paper, also rubber and paint. ISO 9001, ISO 14001.', 'TH check 2026-10-15: Bangkok office Vanissa Building Tower B 15F, Soi Chidlom, +66 2 650 5020, fmtt@fmtthai.co.th. Slurry capacity and paper customers not public. Licence talk may run through Fimatec Japan.'),
  ('quality minerals|\mqmin\M', 'Quality Minerals PCL (QMIN)', 'Lopburi', 'Lopburi', null, '1995년 설립 Lopburi 의 GCC 제조사(상장). 방해석 원료 코팅·비코팅 GCC, 전체 연 18만 t. 인쇄·필기용지·듀플렉스 판지 용도.', 'Quality Minerals Public Co., Ltd. (QMIN), founded 1995 - coated and uncoated calcite-based GCC at its Lopburi plant, 180,000 t/yr total, paper uses printing and writing paper and duplex board.', 'TH check 2026-10-15: 180 kt is total GCC, not paper only. Dry powder - slurry line would be new. montri@qmin.co.th, +66 63 202 5348.'),
  ('mcs mining', 'MCS Mining Industry', null, null, null, '석회석 채굴·분쇄 GCC 분말, 생석회·소석회 생산업체.', 'MCS Mining Industry - limestone quarrying and grinding, GCC powder, quicklime and hydrated lime.', 'TH check 2026-10-15: raw-material source only - paper slurry and capacity not confirmed. Not added: Thai Poly Chemicals (Samut Sakhon, old listings only), Dusit Chemicals (no plant located).')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
  and coalesce(p.source, '') <> 'thailand_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Specialty Minerals (Thailand)', 'PCC producer', 'Satellite PCC at Double A and Phoenix', 'satellite (on-site)', 'B', 'pcc'),
  ('Surint Omya Chemicals (Thailand)', 'GCC and PCC supplier', 'Omya Thailand - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('F.M.T. (Thailand) Co., Ltd.', 'WGCC producer', 'Wet GCC for paper - licensed producer candidate', 'merchant', 'B', 'gcc'),
  ('Quality Minerals PCL (QMIN)', 'GCC producer', 'Dry GCC 180 kt - paper grades', 'merchant', 'B', 'gcc'),
  ('MCS Mining Industry', 'GCC and lime producer', 'Raw material - limestone GCC', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'thailand_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'TH', v.region, v.city, v.website, 'active', 'thailand_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double', 'Double A - 304 Industrial Park (Prachinburi)', 'Prachinburi', 'Prachinburi', 'https://www.doubleapaper.com', 'Double A (1991) PCL — Prachinburi 304 Industrial Park 의 펄프·제지 통합공장. 제지 4기 연 74.5만 t, 펄프 2기 59만 t (2026 회사 자료). 복사·인쇄용지.', 'Double A (1991) PCL - integrated pulp and paper at 304 Industrial Park, Prachinburi: four paper mills 745,000 t/yr and two pulp mills 590,000 t/yr (company 2026). Copy, printing and writing paper.', 'TH check 2026-10-15: older company material showed three mills and 600,000 t. SMI runs two satellite PCC plants at Tha Toom (150 kt announced). MTI FulFill E-325 agreement announced earlier.'),
  ('cellox|berli jucker', 'prachin', 'cellox|berli|\mbjc\M', 'BJC Cellox (Prachinburi)', 'Prachinburi', 'Prachinburi', null, 'Berli Jucker Cellox(Cellox·Zilk·Belle) 티슈 제조사. 태국 티슈 연 약 7.5만 t(2022), Prachinburi ANDRITZ PrimeLineCOMPACT(1,900 m/분, 2.8 m) 2021-03 가동.', 'Berli Jucker Cellox (Cellox, Zilk, Belle) - about 75,000 t/yr tissue in Thailand (2022), ANDRITZ PrimeLineCOMPACT at Prachinburi (1,900 m/min, 2.8 m, steel Yankee) started 2021-03.', 'TH check 2026-10-15: machine-level split and filler use not public.'),
  ('river ?pro', null, 'river', 'RiverPRO Pulp & Paper', null, null, null, '태국 초기 티슈 제조사. 천연·재생 펄프 티슈, 티슈기 5대 합계 일 100 t.', 'RiverPRO Pulp and Paper - long-running Thai tissue maker, virgin and recycled fibre, five tissue machines totalling 100 t/day.', 'TH check 2026-10-15: 33,000 t/yr is 100 t/day x 330 days (calculated).'),
  ('kimberly.*thai|thai.*kimberly', null, 'kimberly', 'Kimberly-Clark Thailand', null, null, null, 'Kimberly-Clark 태국 사업(Scott·Kleenex). 2025년 소매 티슈 매출 점유율 약 37%(Euromonitor).', 'Kimberly-Clark Thailand (Scott, Kleenex) - about 37 pct of Thai retail tissue sales value in 2025 (Euromonitor, retail share, not mill output).', 'TH check 2026-10-15: local mill and machine capacity not confirmed. Check whether the Thai business is now part of Arbex (Suzano 51 / Kimberly-Clark 49, 2026-07).'),
  ('thai paper co|thai paper \(scgp\)|^thai paper$', null, 'thai paper', 'Thai Paper (SCGP)', 'Ratchaburi', null, null, 'SCG Packaging 계열 Thai Paper. Ratchaburi·Kanchanaburi·Khon Kaen·Samut Sakhon 생산, 펄프 60.2만 t + 종이 57.2만 t.', 'Thai Paper (SCG Packaging group) - sites in Ratchaburi, Kanchanaburi, Khon Kaen and Samut Sakhon, 602,400 t pulp and 572,000 t paper per year, incl. food packaging materials.', 'TH check 2026-10-15: grade split by site not public. Other SCGP companies: Siam Kraft Industry (kraft liner), Thai Cane Paper (recycled packaging), Phoenix Pulp and Paper (chemical pulp).'),
  ('phoenix pulp', 'nam phong', 'phoenix', 'Phoenix Pulp & Paper (Nam Phong)', 'Khon Kaen', 'Nam Phong', null, 'SCGP 계열 Khon Kaen Nam Phong 화학펄프 공장. 2007년 SMI 위성 PCC 계약(연 5만~7만 t 계획).', 'Phoenix Pulp and Paper, Nam Phong, Khon Kaen (SCGP group) - chemical pulp mill, SMI satellite PCC contract 2007 (50,000-70,000 t/yr in two units).', 'TH check 2026-10-15: which paper line uses the PCC and whether it still runs is not confirmed.'),
  ('united paper', 'prachin', 'united', 'United Paper PCL (Prachinburi)', 'Prachinburi', 'Prachinburi', null, '태국 상장사 United Paper — Prachinburi 크라프트 라이너·골심지 공장(재생펄프, ANDRITZ OCC 라인). 증설 후 연 26.4만 t, 2025 종이 매출 약 37.1억 바트.', 'United Paper PCL, 61 Moo 8, Wat Bot, Mueang Prachinburi - kraft liner board and corrugating medium on recycled fibre (ANDRITZ OCC line), 264,000 t/yr after expansion, 2025 paper sales about THB 3.71 bn.', 'TH check 2026-10-15: 264 kt is the expansion figure - current nameplate to confirm. Independent of SCGP.')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double', 'Double A (1991) PCL — Prachinburi 304 Industrial Park 의 펄프·제지 통합공장. 제지 4기 연 74.5만 t, 펄프 2기 59만 t (2026 회사 자료). 복사·인쇄용지.', 'Double A (1991) PCL - integrated pulp and paper at 304 Industrial Park, Prachinburi: four paper mills 745,000 t/yr and two pulp mills 590,000 t/yr (company 2026). Copy, printing and writing paper.', 'TH check 2026-10-15: older company material showed three mills and 600,000 t. SMI runs two satellite PCC plants at Tha Toom (150 kt announced). MTI FulFill E-325 agreement announced earlier.'),
  ('cellox|berli jucker', 'prachin', 'cellox|berli|\mbjc\M', 'Berli Jucker Cellox(Cellox·Zilk·Belle) 티슈 제조사. 태국 티슈 연 약 7.5만 t(2022), Prachinburi ANDRITZ PrimeLineCOMPACT(1,900 m/분, 2.8 m) 2021-03 가동.', 'Berli Jucker Cellox (Cellox, Zilk, Belle) - about 75,000 t/yr tissue in Thailand (2022), ANDRITZ PrimeLineCOMPACT at Prachinburi (1,900 m/min, 2.8 m, steel Yankee) started 2021-03.', 'TH check 2026-10-15: machine-level split and filler use not public.'),
  ('river ?pro', null, 'river', '태국 초기 티슈 제조사. 천연·재생 펄프 티슈, 티슈기 5대 합계 일 100 t.', 'RiverPRO Pulp and Paper - long-running Thai tissue maker, virgin and recycled fibre, five tissue machines totalling 100 t/day.', 'TH check 2026-10-15: 33,000 t/yr is 100 t/day x 330 days (calculated).'),
  ('kimberly.*thai|thai.*kimberly', null, 'kimberly', 'Kimberly-Clark 태국 사업(Scott·Kleenex). 2025년 소매 티슈 매출 점유율 약 37%(Euromonitor).', 'Kimberly-Clark Thailand (Scott, Kleenex) - about 37 pct of Thai retail tissue sales value in 2025 (Euromonitor, retail share, not mill output).', 'TH check 2026-10-15: local mill and machine capacity not confirmed. Check whether the Thai business is now part of Arbex (Suzano 51 / Kimberly-Clark 49, 2026-07).'),
  ('thai paper co|thai paper \(scgp\)|^thai paper$', null, 'thai paper', 'SCG Packaging 계열 Thai Paper. Ratchaburi·Kanchanaburi·Khon Kaen·Samut Sakhon 생산, 펄프 60.2만 t + 종이 57.2만 t.', 'Thai Paper (SCG Packaging group) - sites in Ratchaburi, Kanchanaburi, Khon Kaen and Samut Sakhon, 602,400 t pulp and 572,000 t paper per year, incl. food packaging materials.', 'TH check 2026-10-15: grade split by site not public. Other SCGP companies: Siam Kraft Industry (kraft liner), Thai Cane Paper (recycled packaging), Phoenix Pulp and Paper (chemical pulp).'),
  ('phoenix pulp', 'nam phong', 'phoenix', 'SCGP 계열 Khon Kaen Nam Phong 화학펄프 공장. 2007년 SMI 위성 PCC 계약(연 5만~7만 t 계획).', 'Phoenix Pulp and Paper, Nam Phong, Khon Kaen (SCGP group) - chemical pulp mill, SMI satellite PCC contract 2007 (50,000-70,000 t/yr in two units).', 'TH check 2026-10-15: which paper line uses the PCC and whether it still runs is not confirmed.'),
  ('united paper', 'prachin', 'united', '태국 상장사 United Paper — Prachinburi 크라프트 라이너·골심지 공장(재생펄프, ANDRITZ OCC 라인). 증설 후 연 26.4만 t, 2025 종이 매출 약 37.1억 바트.', 'United Paper PCL, 61 Moo 8, Wat Bot, Mueang Prachinburi - kraft liner board and corrugating medium on recycled fibre (ANDRITZ OCC line), 264,000 t/yr after expansion, 2025 paper sales about THB 3.71 bn.', 'TH check 2026-10-15: 264 kt is the expansion figure - current nameplate to confirm. Independent of SCGP.'),
  ('siam kraft', null, 'siam kraft', null, null, 'TH check 2026-10-15: Kraft liner, corrugating medium - no capacity data, context only.'),
  ('thai cane', null, 'thai cane', null, null, 'TH check 2026-10-15: Recycled packaging paper - no capacity data, context only.'),
  ('thai paper mill', null, 'thai paper mill', null, null, 'TH check 2026-10-15: Kraft and packaging paper - no capacity data, context only.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'thailand_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double'),
  ('cellox|berli jucker', 'prachin', 'cellox|berli|\mbjc\M'),
  ('river ?pro', null, 'river'),
  ('kimberly.*thai|thai.*kimberly', null, 'kimberly'),
  ('thai paper co|thai paper \(scgp\)|^thai paper$', null, 'thai paper'),
  ('phoenix pulp', 'nam phong', 'phoenix'),
  ('united paper', 'prachin', 'united'),
  ('siam kraft', null, 'siam kraft'),
  ('thai cane', null, 'thai cane'),
  ('thai paper mill', null, 'thai paper mill')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double',
   $pj${"owner": "Double A", "priority": 1, "products": "Copy paper, printing and writing paper", "grades": ["Copy paper", "Printing and writing"], "machines": 4, "capacity": {"value": 745000, "unit": "metric_t", "year": "Company 2026 (4 paper mills)", "source": "doubleapaper.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct of 745 kt at full output - planning scenario, not an order. Partly overlaps the existing SMI PCC volume - do not add both."}, "pitch": "FCC against the existing SMI PCC - fibre saving with Korean commercial data", "approach": "Lead Thai account. Run it through SMI (licensee) at Tha Toom - compare FCC with PCC and FulFill on strength, opacity, drainage.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "SMI satellite PCC x2, FulFill E-325 agreement", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cellox|berli jucker', 'prachin', 'cellox|berli|\mbjc\M',
   $pj${"owner": "Berli Jucker (BJC)", "priority": 2, "products": "Toilet tissue, facial, towels", "grades": ["Tissue"], "capacity": {"value": 75000, "unit": "metric_t", "year": "ITA 2022", "source": "ice.it"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report example 3 pct tissue at full output - trial assumption, not a proven rate."}, "pitch": "15 gsm tissue trial data - fibre saving on a known modern machine", "approach": "Known machine specs make drainage and drying-energy checks easy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('river ?pro', null, 'river',
   $pj${"owner": "RiverPRO", "priority": 3, "products": "Tissue (virgin and recycled)", "grades": ["Tissue"], "machines": 5, "capacity": {"value": 33000, "unit": "metric_t", "year": "100 t/day x 330 (calculated)", "source": "company site"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report example 3 pct tissue at full output - trial assumption."}, "pitch": "Early trial - compare FCC on virgin and recycled furnish", "approach": "Smaller company - faster trial decision.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*thai|thai.*kimberly', null, 'kimberly',
   $pj${"owner": "Kimberly-Clark", "priority": 4, "products": "Toilet tissue, facial", "grades": ["Tissue"], "approach": "Confirm the local machine first. Start with toilet tissue - tensile, softness, dust, absorbency, runnability.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('thai paper co|thai paper \(scgp\)|^thai paper$', null, 'thai paper',
   $pj${"owner": "SCG Packaging", "priority": 5, "products": "Paper and pulp, food packaging materials", "grades": ["White board", "Packaging"], "capacity_split": [{"label": "Paper", "value_t": 572000}, {"label": "Pulp", "value_t": 602400}], "pitch": "White board and inner plies of multi-ply board first", "approach": "Grade by grade - FCC 3-10 pct trial on white board or an inner ply, not group-wide. Check SMI and Omya roles.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('phoenix pulp', 'nam phong', 'phoenix',
   $pj${"owner": "SCG Packaging", "products": "Chemical pulp (paper line to confirm)", "grades": ["Pulp"], "approach": "Map the PCC use inside SCGP before any pitch.", "to_collect": ["Which paper line takes the Nam Phong PCC", "Current PCC output"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('united paper', 'prachin', 'united',
   $pj${"owner": "United Paper", "priority": 6, "products": "Kraft liner board, corrugating medium", "grades": ["Kraftliner", "Medium"], "capacity": {"value": 264000, "unit": "metric_t", "year": "After expansion (company)", "source": "utp.co.th"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct at full output - strength must be proven first."}, "approach": "Packaging-grade FCC only - strength and drainage trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('siam kraft', null, 'siam kraft',
   $pj${"owner": "Siam Kraft Industry (SCGP)", "products": "Kraft liner, corrugating medium", "approach": "Strength-critical packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('thai cane', null, 'thai cane',
   $pj${"owner": "Thai Cane Paper (SCGP)", "products": "Recycled packaging paper", "approach": "Strength-critical packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('thai paper mill', null, 'thai paper mill',
   $pj${"owner": "Thai Paper Mill", "products": "Kraft and packaging paper", "approach": "Strength-critical packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'thailand_update_20261015', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double', '(specialty minerals|minerals technologies).*thai', 'active', 'medium', null::date, null::date, '150,000 t/yr nameplate (70 kt + 80 kt, 2011-2013)', 'satellite PCC x2 at Tha Toom', 'MTI press releases 2011-2013', 'SMI satellite PCC at Double A Tha Toom - unit 1 expanded to 70 kt (2011), unit 2 80 kt started Q4 2012 - current output not confirmed'),
  ('phoenix pulp', 'nam phong', 'phoenix', '(specialty minerals|minerals technologies).*thai', 'historical', 'medium', null::date, null::date, '50,000-70,000 t/yr planned (2007)', 'satellite PCC at Nam Phong', 'MTI press release 2007', 'SMI satellite PCC contract with Phoenix Pulp and Paper 2007 - current operation not confirmed')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TH', 'Thailand', 'high',
   $cm$Double A copy paper on SMI satellite PCC, tissue (BJC Cellox, RiverPRO) and local wet GCC (F.M.T.)$cm$,
   $cm$Both licensees are present - SMI with satellite PCC at Double A Tha Toom (150 kt announced) and Phoenix Nam Phong, Omya through Surint Omya. Double A (745 kt, four paper mills) is the lead account. Tissue: BJC Cellox (75 kt), RiverPRO (33 kt), Kimberly-Clark. SCGP and United Paper are mostly strength-critical packaging. National capacity about 5.67 Mt (2026F), 3.8 Mt of it kraft.$cm$,
   $cm${"fillers": "Licensees: Specialty Minerals (Thailand) - satellite PCC at Double A Tha Toom and Phoenix Nam Phong, and Surint Omya (GCC, PCC, coating, older Lopburi plant). Local: F.M.T. (Fimatec group, wet GCC, Sing Buri), Quality Minerals QMIN (Lopburi, 180 kt dry GCC), MCS Mining. Thai Poly Chemicals and Dusit Chemicals not added - no plant confirmed.", "mills": "Printing and writing: Double A 745 kt. Tissue: BJC Cellox 75 kt (Prachinburi, ANDRITZ 2021), RiverPRO 100 t/day, Kimberly-Clark Thailand. SCGP group: Thai Paper 572 kt paper, Siam Kraft, Thai Cane Paper, Phoenix (pulp). Independent packaging: United Paper 264 kt.", "strategy": "Double A through SMI first (FCC versus existing PCC), then tissue trials at BJC Cellox and RiverPRO with the 15 gsm data. SCGP grade by grade later. F.M.T. and QMIN only as additional licensed producers.", "risks": "Most capacity is kraft and recycled packaging. SMI PCC and FulFill already in use at Double A - FCC must beat them. Nameplates are 2007-2013 data.", "next_steps": ["Confirm current SMI PCC output at Tha Toom and Nam Phong", "Get Double A filler loading per grade", "Propose a tissue trial to BJC Cellox"], "key_numbers": [{"label": "Paper and board capacity 2026F", "value": "about 5.67 Mt (United Paper data), kraft about 3.8 Mt"}, {"label": "Domestic consumption 2026F", "value": "about 5.2 Mt"}, {"label": "SMI PCC nameplates (historical)", "value": "200-220 kt"}, {"label": "Kimberly-Clark retail tissue share 2025", "value": "about 37 pct"}, {"label": "Report scenario", "value": "40,490 t FCC, USD 607,350 royalty"}], "files": ["seed_20261015o_thailand_mills_fillers"]}$cm$::jsonb,
   $cm$Double A 복사용지(SMI 위성 PCC) + BJC Cellox·RiverPRO 티슈 + 현지 습식 GCC(F.M.T.)$cm$,
   $cm$라이선시 SMI(Double A Tha Toom 위성 PCC 15만 t 발표·Phoenix Nam Phong)와 Omya(Surint Omya) 모두 진출. 1순위 Double A(74.5만 t), 티슈는 BJC Cellox·RiverPRO·Kimberly-Clark 3% 시험. SCGP·United Paper 는 강도 중심 포장용지라 지종별 후순위.$cm$,
   40490, 53690,
   $cm$Double A 74.5만 t 5% + BJC Cellox·RiverPRO 티슈 3% = 40,490 t, United Paper 5% 포함 시 53,690 t (가동 100% 가정, 보고서 예시)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('double ?a', 'prachin|tha toom|si maha phot', 'double'),
  ('cellox|berli jucker', 'prachin', 'cellox|berli|\mbjc\M'),
  ('river ?pro', null, 'river'),
  ('kimberly.*thai|thai.*kimberly', null, 'kimberly'),
  ('thai paper co|thai paper \(scgp\)|^thai paper$', null, 'thai paper'),
  ('phoenix pulp', 'nam phong', 'phoenix'),
  ('united paper', 'prachin', 'united'),
  ('siam kraft', null, 'siam kraft'),
  ('thai cane', null, 'thai cane'),
  ('thai paper mill', null, 'thai paper mill')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'thailand_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'thailand_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*thai' or p.party_name ~* 'surint|omya.*thai' or p.party_name ~* '^f\.?\s?m\.?\s?t\.?\s.*thai' or p.party_name ~* 'quality minerals|\mqmin\M' or p.party_name ~* 'mcs mining')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'TH'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'TH'
union all
select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
       coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TH'
  and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
order by 1, 4, 2;
