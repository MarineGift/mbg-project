-- ============================================================
-- seed_20261014t_bangladesh_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bangladesh update (reports "Bangladesh PCC/GCC producers" + "Bangladesh
-- paper companies", 2026-10). Introduction -> intro_ko / intro_en (only when
-- empty), extra detail -> notes once with 'BD check 2026-10-14', plant data
-- -> Mill profile card.
--
-- 1) Fillers if missing: BBCL (PCC), Crescent Chemical (PCC, GCC), ASM
--    Chemical (GCC), Unirex (PCC plant planned 2027). Uni Lube, Quality
--    Mineral, NRJ skipped (unverified or plastics masterbatch).
-- 2) Link SMI -> Bashundhara Paper Mills (Meghnaghat satellite, MTI 2007
--    agreement), active / medium, only if no SMI link exists for that mill.
-- 3) Mills if missing + plant blocks, priority 1-8:
--      1 Bashundhara Multi-Paper (own PCC + WGCC)  2 Meghna (imported pulp)
--      3 Partex Tissue  4 Lipy (60 kt)  5 Pearl Paper (40 kt)  6 Sonali
--      7 Akij  8 Partex Paper
--    context: Bashundhara Paper Mills, Hakkani, Karnaphuli, Magura Paper.
--    FCC scenarios: Meghna W and P (99 kt calc), Lipy, Pearl, Sonali.
--    BMPIL's stated 2.1 Mt/yr is not used.
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
       v.party_name, 'BD', v.region, v.city, v.website, 'active', 'bangladesh_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('British Bangla Chemical (BBCL)', '%British Bangla%', 'Moulvibazar', 'Sreemangal', 'https://www.bbchemicalbd.com', '1997년 설립 방글라데시 PCC·생석회 제조사 British Bangla Chemical(BBCL). Moulvibazar Sreemangal 공장, 제지용 PCC 명시.', 'British Bangla Chemical (BBCL, founded 1997) - PCC and active lime maker, plant at Kalapur, Sreemangal, Moulvibazar, paper among stated uses.', 'BD check 2026-10-14: PCC spec per company - CaCO3 98.5 pct, whiteness 98, pH 8.5-9.5 (20 pct slurry), Fe2O3 0.02, SiO2 0.02, no D50. Named customers are pharma, chemicals, plastics, paint. Capacity and wet process not public. Contact sales@bbchemicalbd.com, +880 1303 758502.'),
  ('Crescent Chemical', '%Crescent Chemical%', 'Gazipur', 'Pubail', 'https://www.crescentchemical.net', '2005년 사업 개시 Crescent Chemical. 가지푸르 Pubail 석회 설비, PCC·GCC·수산화칼슘·황산 제조.', 'Crescent Chemical (since 2005), Karamtala, Pubail, Gazipur - lime plant, PCC, GCC, calcium hydroxide, sulphuric acid and surfactants.', 'BD check 2026-10-14: equipment, capacity, paper specs and customers not public - check slurry versus powder. Tel +880 9611 686195.'),
  ('ASM Chemical Industries', '%ASM Chemical%', 'Gazipur', 'Sreepur', 'https://www.asmchemical.com', '2006년 설립 ASM Chemical Industries. 가지푸르 Sreepur 공장, 코팅·비코팅 GCC(D50 1.5~6.0 µm), 제지 용도 명시.', 'ASM Chemical Industries (founded 2006), Tepir Bari, Bormi Road, Sreepur, Gazipur - coated and uncoated GCC (D50 1.5-6.0 um), paper among uses.', 'BD check 2026-10-14: TDS - purity 98 pct+, whiteness 98, brightness 96, D97 8-30 um, moisture 0.2 pct. Confirm with current TDS and COA. Output, customers and slurry plant not known. Tel +880 2 48811501.'),
  ('Unirex Industries', '%Unirex%', 'Habiganj', 'Madhabpur', 'https://www.unirexltd.com', 'Habiganj Madhabpur 에 PCC 공장을 건설 중인 Unirex Industries. 유럽·중국 설비, 2027년 가동 목표, 제지·플라스틱·도료 시장.', 'Unirex Industries - PCC plant under development at Haluapara, Madhabpur, Habiganj with European-Chinese equipment, start-up targeted 2027, for paper, plastics, paint.', 'BD check 2026-10-14: not yet producing - progress, EPC and financing unverified. Company claim of 1.1 Mt/yr Bangladesh PCC demand is promotional, not verified. Tel +880 1705 478753.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%BD check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('British Bangla Chemical (BBCL)', '%British Bangla%', 'Moulvibazar', 'Sreemangal', 'https://www.bbchemicalbd.com', '1997년 설립 방글라데시 PCC·생석회 제조사 British Bangla Chemical(BBCL). Moulvibazar Sreemangal 공장, 제지용 PCC 명시.', 'British Bangla Chemical (BBCL, founded 1997) - PCC and active lime maker, plant at Kalapur, Sreemangal, Moulvibazar, paper among stated uses.', 'BD check 2026-10-14: PCC spec per company - CaCO3 98.5 pct, whiteness 98, pH 8.5-9.5 (20 pct slurry), Fe2O3 0.02, SiO2 0.02, no D50. Named customers are pharma, chemicals, plastics, paint. Capacity and wet process not public. Contact sales@bbchemicalbd.com, +880 1303 758502.'),
  ('Crescent Chemical', '%Crescent Chemical%', 'Gazipur', 'Pubail', 'https://www.crescentchemical.net', '2005년 사업 개시 Crescent Chemical. 가지푸르 Pubail 석회 설비, PCC·GCC·수산화칼슘·황산 제조.', 'Crescent Chemical (since 2005), Karamtala, Pubail, Gazipur - lime plant, PCC, GCC, calcium hydroxide, sulphuric acid and surfactants.', 'BD check 2026-10-14: equipment, capacity, paper specs and customers not public - check slurry versus powder. Tel +880 9611 686195.'),
  ('ASM Chemical Industries', '%ASM Chemical%', 'Gazipur', 'Sreepur', 'https://www.asmchemical.com', '2006년 설립 ASM Chemical Industries. 가지푸르 Sreepur 공장, 코팅·비코팅 GCC(D50 1.5~6.0 µm), 제지 용도 명시.', 'ASM Chemical Industries (founded 2006), Tepir Bari, Bormi Road, Sreepur, Gazipur - coated and uncoated GCC (D50 1.5-6.0 um), paper among uses.', 'BD check 2026-10-14: TDS - purity 98 pct+, whiteness 98, brightness 96, D97 8-30 um, moisture 0.2 pct. Confirm with current TDS and COA. Output, customers and slurry plant not known. Tel +880 2 48811501.'),
  ('Unirex Industries', '%Unirex%', 'Habiganj', 'Madhabpur', 'https://www.unirexltd.com', 'Habiganj Madhabpur 에 PCC 공장을 건설 중인 Unirex Industries. 유럽·중국 설비, 2027년 가동 목표, 제지·플라스틱·도료 시장.', 'Unirex Industries - PCC plant under development at Haluapara, Madhabpur, Habiganj with European-Chinese equipment, start-up targeted 2027, for paper, plastics, paint.', 'BD check 2026-10-14: not yet producing - progress, EPC and financing unverified. Company claim of 1.1 Mt/yr Bangladesh PCC demand is promotional, not verified. Tel +880 1705 478753.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'bangladesh_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('British Bangla Chemical (BBCL)', 'PCC producer', 'Bangladesh independent PCC - licence candidate', 'merchant', 'B', 'pcc'),
  ('Crescent Chemical', 'PCC producer', 'Bangladesh PCC and GCC', 'merchant', 'C', 'pcc'),
  ('ASM Chemical Industries', 'GCC producer', 'Bangladesh GCC with published paper spec', 'merchant', 'B', 'gcc'),
  ('Unirex Industries', 'PCC producer', 'Planned PCC plant - design-in FCC', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bangladesh_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'BD', v.region, v.city, v.website, 'active', 'bangladesh_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Multi-Paper%', '%BMPIL%', 'Bashundhara Multi-Paper Industries (Narayanganj)', 'Narayanganj', 'Narayanganj', 'https://www.bmpil.com', 'Bashundhara 그룹의 Bashundhara Multi-Paper Industries(BMPIL, 2015-07 상업생산). 초지기 2대, 공장 내 PCC·습식 GCC 설비 자체 운영, A4·백상지·코팅지·LWC 생산.', 'Bashundhara Multi-Paper Industries (BMPIL, Bashundhara Group, commercial since 2015-07), Narayanganj - two paper machines and its own PCC and wet GCC plants, making A4, woodfree, coated and LWC papers.', 'BD check 2026-10-14: company site states 2.1 Mt/yr for the two machines - not used until machine-level capacity and utilization are confirmed. Contact per report info.paper@bg.com.bd, +880 2 8432289-93.'),
  ('%Meghna Pulp%', '%Meghna Group%', 'Meghna Pulp & Paper Mills (Meghna Group)', 'Narayanganj', null, 'https://www.mgi.org', 'Fresh 브랜드의 Meghna Group of Industries 제지사업. 제지공장 5곳, 인쇄·필기용지 300톤/일·티슈 100톤/일(수입 버진펄프)·산업용지 800톤/일(재생 폐지).', 'Meghna Group of Industries (Fresh brand) paper business - five mills, printing and writing 300 t/day and tissue 100 t/day on imported virgin pulp, industrial paper 800 t/day on recycled fibre.', 'BD check 2026-10-14: figures per a 2023 Paper Mart interview - capacities, not 2026 output.'),
  ('%Partex Tissue%', '%Partex Tissue%', 'Partex Tissue (Rupganj)', 'Narayanganj', 'Rupganj', 'https://www.partextissue.com', 'Partex Star 그룹의 Partex Tissue. 나라양간지 Rupganj, A.Celli 티슈 초지기(폭 2,800mm, 1,800m/min, 2021년 말 가동), 100톤/일, 버진 셀룰로오스 기반.', 'Partex Tissue (Partex Star Group), Rupganj, Narayanganj - A.Celli tissue machine (2,800 mm, 1,800 m/min, started late 2021), 100 t/day on virgin cellulose.', null),
  ('%Lipy%', '%Lipy Paper%', 'Lipy Paper Mills (Bangladesh)', null, null, null, '인쇄·필기용지 제조사 Lipy Paper Mills. 이탈리아 OverMade 초지기(폭 3,850mm, 700m/min), 설계능력 연 6만 톤.', 'Lipy Paper Mills - writing and printing paper on an OverMade (Italy) machine, 3,850 mm wire, 700 m/min, 60,000 t/yr design.', null),
  ('%Pearl Paper%', '%Pearl Paper%', 'Pearl Paper and Board Mills (Dhamrai)', 'Dhaka', 'Dhamrai', null, 'Magura Group 계열 Pearl Paper and Board Mills. 다카 인근 Dhamrai Sreerampur, 인쇄·필기용지·오프셋지·아트지, 연 4만 톤.', 'Pearl Paper and Board Mills (Magura Group), Sreerampur, Dhamrai near Dhaka - printing and writing, offset and art paper, 40,000 t/yr.', null),
  ('%Sonali Paper%', '%Sonali%', 'Sonali Paper & Board Mills (Narayanganj)', 'Narayanganj', 'Rupganj', 'https://www.spbmlbd.com', 'Younus Group 계열 상장 제지사 Sonali Paper & Board Mills. 나라양간지 Tarabo, 초지기 2대 45톤/일, 백상 인쇄·필기용지.', 'Sonali Paper and Board Mills (Younus Group, listed), Jatramura, Tarabo, Rupganj, Narayanganj - two machines, 45 t/day, white printing and writing paper.', 'BD check 2026-10-14: FY2024-25 revenue about BDT 2,826.7m, net profit about BDT 236.1m. Contact spshare@younusgroup.com.'),
  ('%Akij Paper%', '%Akij Paper%', 'Akij Paper Mills (Munshiganj)', 'Munshiganj', 'Gazaria', null, 'Akij 그룹의 Akij Paper Mills. 문시간지 Gazaria 에 등록된 제지공장(등록 근로자 230명), 인쇄·필기용지·포장지·티슈 소개.', 'Akij Paper Mills (Akij Group), Anarpura, Bhaberchar, Gazaria, Munshiganj - registered paper factory (230 workers), printing and writing, packaging, tissue and specialty papers listed.', null),
  ('%Partex Paper%', '%Partex Paper%', 'Partex Paper Mills (Rupganj)', 'Narayanganj', 'Rupganj', null, 'Partex Paper Mills(Partex Tissue 와 별개). 나라양간지 Rupganj, 필기·인쇄용 비도공지.', 'Partex Paper Mills (separate company to Partex Tissue), Rupganj, Narayanganj - uncoated writing and printing paper (HS 4802).', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BD check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Multi-Paper%', '%BMPIL%', '%Bashundhara%', 'Bashundhara 그룹의 Bashundhara Multi-Paper Industries(BMPIL, 2015-07 상업생산). 초지기 2대, 공장 내 PCC·습식 GCC 설비 자체 운영, A4·백상지·코팅지·LWC 생산.', 'Bashundhara Multi-Paper Industries (BMPIL, Bashundhara Group, commercial since 2015-07), Narayanganj - two paper machines and its own PCC and wet GCC plants, making A4, woodfree, coated and LWC papers.', 'BD check 2026-10-14: company site states 2.1 Mt/yr for the two machines - not used until machine-level capacity and utilization are confirmed. Contact per report info.paper@bg.com.bd, +880 2 8432289-93.'),
  ('%Meghna Pulp%', '%Meghna Group%', '%Meghna%', 'Fresh 브랜드의 Meghna Group of Industries 제지사업. 제지공장 5곳, 인쇄·필기용지 300톤/일·티슈 100톤/일(수입 버진펄프)·산업용지 800톤/일(재생 폐지).', 'Meghna Group of Industries (Fresh brand) paper business - five mills, printing and writing 300 t/day and tissue 100 t/day on imported virgin pulp, industrial paper 800 t/day on recycled fibre.', 'BD check 2026-10-14: figures per a 2023 Paper Mart interview - capacities, not 2026 output.'),
  ('%Partex Tissue%', '%Partex Tissue%', '%Partex%', 'Partex Star 그룹의 Partex Tissue. 나라양간지 Rupganj, A.Celli 티슈 초지기(폭 2,800mm, 1,800m/min, 2021년 말 가동), 100톤/일, 버진 셀룰로오스 기반.', 'Partex Tissue (Partex Star Group), Rupganj, Narayanganj - A.Celli tissue machine (2,800 mm, 1,800 m/min, started late 2021), 100 t/day on virgin cellulose.', null),
  ('%Lipy%', '%Lipy Paper%', '%Lipy%', '인쇄·필기용지 제조사 Lipy Paper Mills. 이탈리아 OverMade 초지기(폭 3,850mm, 700m/min), 설계능력 연 6만 톤.', 'Lipy Paper Mills - writing and printing paper on an OverMade (Italy) machine, 3,850 mm wire, 700 m/min, 60,000 t/yr design.', null),
  ('%Pearl Paper%', '%Pearl Paper%', '%Pearl%', 'Magura Group 계열 Pearl Paper and Board Mills. 다카 인근 Dhamrai Sreerampur, 인쇄·필기용지·오프셋지·아트지, 연 4만 톤.', 'Pearl Paper and Board Mills (Magura Group), Sreerampur, Dhamrai near Dhaka - printing and writing, offset and art paper, 40,000 t/yr.', null),
  ('%Sonali Paper%', '%Sonali%', '%Sonali%', 'Younus Group 계열 상장 제지사 Sonali Paper & Board Mills. 나라양간지 Tarabo, 초지기 2대 45톤/일, 백상 인쇄·필기용지.', 'Sonali Paper and Board Mills (Younus Group, listed), Jatramura, Tarabo, Rupganj, Narayanganj - two machines, 45 t/day, white printing and writing paper.', 'BD check 2026-10-14: FY2024-25 revenue about BDT 2,826.7m, net profit about BDT 236.1m. Contact spshare@younusgroup.com.'),
  ('%Akij Paper%', '%Akij Paper%', '%Akij%', 'Akij 그룹의 Akij Paper Mills. 문시간지 Gazaria 에 등록된 제지공장(등록 근로자 230명), 인쇄·필기용지·포장지·티슈 소개.', 'Akij Paper Mills (Akij Group), Anarpura, Bhaberchar, Gazaria, Munshiganj - registered paper factory (230 workers), printing and writing, packaging, tissue and specialty papers listed.', null),
  ('%Partex Paper%', '%Partex Paper%', '%Partex%', 'Partex Paper Mills(Partex Tissue 와 별개). 나라양간지 Rupganj, 필기·인쇄용 비도공지.', 'Partex Paper Mills (separate company to Partex Tissue), Rupganj, Narayanganj - uncoated writing and printing paper (HS 4802).', null),
  ('%Bashundhara Paper%', '%Bashundhara Paper Mills%', '%Bashundhara%', 'Bashundhara 그룹 제지사업 Bashundhara Paper Mills. 인쇄용지·티슈·위생용지 사업장(Unit-1, Unit-3 등).', 'Bashundhara Paper Mills (Bashundhara Group) - printing paper, tissue and hygiene sites (Unit-1, Unit-3 and others).', 'BD check 2026-10-14: MTI agreed in 2007 to build and run a satellite PCC plant at Bashundhara''s Meghnaghat mill (MTI history).'),
  ('%Hakkani%', '%Hakkani%', '%Hakkani%', 'Chattogram 의 상장 제지사 Hakkani Pulp & Paper Mills. 필기·인쇄·신문용지·크라프트지·티슈.', 'Hakkani Pulp and Paper Mills (listed, Chattogram) - writing, printing, newsprint, kraft and tissue.', 'BD check 2026-10-14: FY2024-25 revenue about BDT 1,041.5m, net profit about BDT 1.4m.'),
  ('%Karnaphuli%', '%Karnaphuli%', '%Karnaphuli%', 'BCIC 산하 국영 제지사 Karnaphuli Paper Mills(Chandraghona). 과거 설계능력 연 3만 톤, 노후 설비.', 'Karnaphuli Paper Mills (state, BCIC), Chandraghona - old design capacity about 30,000 t/yr, ageing equipment.', null),
  ('%Magura Paper%', '%Magura Paper%', '%Magura%', 'Magura Group 의 산업용 포장원지 제조사 Magura Paper Mills(Meghnaghat). 크라프트라이너·골심지 연 2.2만 톤.', 'Magura Paper Mills (Magura Group), Meghnaghat, Narayanganj - kraft liner and fluting medium, 22,000 t/yr.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'bangladesh_update_20261014';

-- ---------- 3) LINK SMI -> Bashundhara Paper Mills ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'active', 'PCC filler-grade', null, 'medium', null, null,
       'SMI satellite PCC at Bashundhara Meghnaghat - MTI agreement 2007, current status to confirm',
       jsonb_build_object('supply_structure', 'on-site satellite PCC', 'link_kind', 'pcc_satellite',
                          'source', 'MTI company history (2007 agreement)', 'batch', 'bangladesh_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values ('%Bashundhara Paper%', '%Bashundhara Paper Mills%', '%Bashundhara%')) as v(name_like, alt_like, owner_like)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ilike 'Specialty Minerals%'
  order by (x.party_name ilike '%Bangladesh%') desc, (x.party_name = 'Specialty Minerals Inc.') desc, x.created_at
  limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  join app.parties lf on lf.id = l.filler_party_id
                  where l.mill_party_id = m.id and l.deleted_at is null and lf.party_name ilike 'Specialty Minerals%');

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Multi-Paper%', '%BMPIL%', '%Bashundhara%'),
  ('%Meghna Pulp%', '%Meghna Group%', '%Meghna%'),
  ('%Partex Tissue%', '%Partex Tissue%', '%Partex%'),
  ('%Lipy%', '%Lipy Paper%', '%Lipy%'),
  ('%Pearl Paper%', '%Pearl Paper%', '%Pearl%'),
  ('%Sonali Paper%', '%Sonali%', '%Sonali%'),
  ('%Akij Paper%', '%Akij Paper%', '%Akij%'),
  ('%Partex Paper%', '%Partex Paper%', '%Partex%'),
  ('%Bashundhara Paper%', '%Bashundhara Paper Mills%', '%Bashundhara%'),
  ('%Hakkani%', '%Hakkani%', '%Hakkani%'),
  ('%Karnaphuli%', '%Karnaphuli%', '%Karnaphuli%'),
  ('%Magura Paper%', '%Magura Paper%', '%Magura%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Multi-Paper%', '%BMPIL%', '%Bashundhara%',
   $pj${"owner": "Bashundhara Group", "priority": 1, "products": "A4 copy, woodfree printing, coated, LWC", "grades": ["Copy paper", "Woodfree", "Coated", "LWC"], "machines": 2, "filler": [{"supplier": "Own plants", "type": "PCC and wet GCC made on site", "status": "Stated by the company", "basis": "bmpil.com - capacity and self-use share not public"}], "pitch": "Make FCC on the existing PCC / WGCC lines and trial on the same site's machines", "approach": "Top Bangladesh account - production and use in one company, so licence and trial can run together. Check whether the 2007 MTI satellite at Meghnaghat is the PCC plant now used.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "sources": [{"label": "bmpil.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Meghna Pulp%', '%Meghna Group%', '%Meghna%',
   $pj${"owner": "Meghna Group of Industries", "priority": 2, "products": "Printing and writing paper, tissue, liner and fluting", "grades": ["Writing and printing", "Tissue", "Liner"], "capacity": {"value": 99000, "unit": "metric_t", "year": "Printing and writing 300 t/day x 330 days (calculated, 2023 interview)", "source": "Paper Mart 2023"}, "capacity_split": [{"label": "Tissue 100 t/day x 330", "value_t": 33000}, {"label": "Industrial paper 800 t/day x 330 (recycled)", "value_t": 264000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "All printing and tissue pulp is imported - FCC cuts imported pulp cost", "approach": "Lead with the printing and writing lines. Keep the 800 t/day recycled packaging out of the FCC sizing.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "sources": [{"label": "Paper Mart 2023 interview"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Partex Tissue%', '%Partex Tissue%', '%Partex%',
   $pj${"owner": "Partex Star Group", "priority": 3, "products": "Hygiene tissue", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "100 t/day x 330 (calculated)", "value_t": 33000}], "pitch": "Already invests in fibre saving - FCC as the next step", "approach": "Start with the MBG 5 pct FCC tissue data. Check overlap with the AFT refining gains.", "recent": [{"date": "2026-04", "text": "AFT reported strength and fibre savings by refining optimisation at this mill"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lipy%', '%Lipy Paper%', '%Lipy%',
   $pj${"owner": "Lipy Paper Mills", "priority": 4, "products": "Writing and printing paper", "grades": ["Writing and printing"], "machines": 1, "capacity": {"value": 60000, "unit": "metric_t", "year": "Machine design (OverMade)", "source": "OverMade"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Hold strength and opacity with less pulp", "approach": "Find the current filler and loading first.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "sources": [{"label": "OverMade reference"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Pearl Paper%', '%Pearl Paper%', '%Pearl%',
   $pj${"owner": "Magura Group", "priority": 5, "products": "Printing and writing, offset, art paper", "grades": ["Writing and printing", "Offset"], "capacity": {"value": 40000, "unit": "metric_t", "year": "Company figure", "source": "maguragroup.com.bd"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "approach": "Approach Magura through Pearl, not the packaging mill.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Sonali Paper%', '%Sonali%', '%Sonali%',
   $pj${"owner": "Younus Group", "priority": 6, "products": "White printing and writing paper", "grades": ["Writing and printing"], "machines": 2, "capacity": {"value": 14850, "unit": "metric_t", "year": "45 t/day x 330 days (calculated)", "source": "Younus Group"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Small mill - fast first commercial reference", "approach": "Good for a first trial and supply record.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Akij Paper%', '%Akij Paper%', '%Akij%',
   $pj${"owner": "Akij Group", "priority": 7, "products": "Printing and writing, packaging, tissue, specialty", "approach": "Confirm which lines run and machine capacities.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Partex Paper%', '%Partex Paper%', '%Partex%',
   $pj${"owner": "Partex Star Group", "priority": 8, "products": "Uncoated writing and printing paper", "approach": "Capacity and running status unknown.", "to_collect": ["Current PCC / GCC supplier or own plant, and output", "Pulp purchases (t/yr), long and short fibre split, landed cost", "Filler loading per grade, retention, drainage", "Machines actually running and utilization", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Bashundhara Paper%', '%Bashundhara Paper Mills%', '%Bashundhara%',
   $pj${"owner": "Bashundhara Group", "products": "Printing paper, tissue and hygiene paper", "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC at Meghnaghat", "status": "Agreement 2007 - current status to confirm", "basis": "MTI history"}], "approach": "Group sister of BMPIL - tissue units for the tissue track.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hakkani%', '%Hakkani%', '%Hakkani%',
   $pj${"owner": "Hakkani Group", "products": "Writing, printing, newsprint, kraft, tissue", "approach": "Thin margins - FCC must need no capex and show savings fast.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Karnaphuli%', '%Karnaphuli%', '%Karnaphuli%',
   $pj${"owner": "Bangladesh Chemical Industries Corporation", "products": "Printing paper", "approach": "State procurement is slow - after the private mills.", "recent": [{"date": "2025-12", "text": "Temporary stop on water shortage (Dhaka Tribune)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Magura Paper%', '%Magura Paper%', '%Magura%',
   $pj${"owner": "Magura Group", "products": "Kraft liner, fluting medium", "approach": "Low FCC fit - Pearl Paper is the Magura entry.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Multi-Paper%', '%BMPIL%', '%Bashundhara%'),
  ('%Meghna Pulp%', '%Meghna Group%', '%Meghna%'),
  ('%Partex Tissue%', '%Partex Tissue%', '%Partex%'),
  ('%Lipy%', '%Lipy Paper%', '%Lipy%'),
  ('%Pearl Paper%', '%Pearl Paper%', '%Pearl%'),
  ('%Sonali Paper%', '%Sonali%', '%Sonali%'),
  ('%Akij Paper%', '%Akij Paper%', '%Akij%'),
  ('%Partex Paper%', '%Partex Paper%', '%Partex%'),
  ('%Bashundhara Paper%', '%Bashundhara Paper Mills%', '%Bashundhara%'),
  ('%Hakkani%', '%Hakkani%', '%Hakkani%'),
  ('%Karnaphuli%', '%Karnaphuli%', '%Karnaphuli%'),
  ('%Magura Paper%', '%Magura Paper%', '%Magura%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'bangladesh_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BD'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'bangladesh_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%British Bangla%' or p.party_name ilike '%Crescent Chemical%' or p.party_name ilike '%ASM Chemical%' or p.party_name ilike '%Unirex%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'bangladesh_update_20261014'
order by 1, 4, 2;
