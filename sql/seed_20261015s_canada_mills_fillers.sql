-- ============================================================
-- seed_20261015s_canada_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Canada update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'CA check 2026-10-15',
-- plant data -> Mill profile card. Existing CA rows matched first
-- (name regex OR city + owner regex).
--
-- 1) Fillers if missing (3): Omya Canada Perth, Omya Canada Saint-Armand,
--    Specialty Minerals (Canada). Closed PCC sites (Cornwall, Dryden,
--    Prince Albert) in notes only. Lime companies not added.
-- 2) Mills if missing (14) + plant blocks, priority 1-7: Domtar Windsor,
--    Irving Paper, Kruger Wayagamack, Kruger Products x6, Cascades Tissue x3,
--    Irving Tissue, Sustana Saint-Jérôme (no priority).
--    Context, match only (13): Domtar Alma, Dolbeau, Kénogami, Clermont,
--    Gatineau, Port Alberni, Kruger Trois-Rivières, Corner Brook,
--    White Birch Stadacona, Masson, Soucy, Atlantic Whitby, New Forest.
-- 3) Supply links: SMI -> Windsor, SMI -> Sustana (historical, medium).
-- 4) app.country_markets CA row (priority high).
-- Verify also lists other existing CA mills ('other mill').
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
       v.party_name, 'CA', v.region, v.city, v.website, 'active', 'canada_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('omya.*perth', 'Omya Canada - Perth (Ontario)', 'Ontario', 'Perth', null, 'Omya Canada 의 Perth(온타리오) 탄산칼슘 가공공장. 원료는 Omya 가 운영하는 Tatlock Quarry, 관련 인원 94명(온타리오 광업협회 2025).', 'Omya Canada - calcium carbonate processing at Perth, Ontario, fed by the Omya-run Tatlock Quarry, 94 staff (Ontario Mining Association 2025).', 'CA check 2026-10-15: paper-grade GCC capacity, wet slurry line and paper customers not public. +1 613-267-5367. Historical: Omya (ex Huber) PCC at Prince Albert SK, 42,000 t/yr (2005) - host mill closed 2006. Royalty licensee at Omya HQ level.'),
  ('omya.*(saint|st\.?)[- ]?armand', 'Omya Canada - Saint-Armand (Quebec)', 'Quebec', 'Saint-Armand', null, 'Omya Canada 의 Saint-Armand(퀘벡) 광물 가공공장. 1500 chemin de la Carrière. BNQ 등록 제품은 농업용 돌로마이트 석회석(AGRODOL-SA).', 'Omya Canada - mineral processing at 1500 chemin de la Carrière, Saint-Armand, Quebec. The BNQ-listed product is agricultural dolomitic limestone (AGRODOL-SA).', 'CA check 2026-10-15: paper-grade output not confirmed - check CaCO3 purity, MgCO3, brightness. +1 450-248-2931.'),
  ('(specialty minerals|minerals technologies).*canada', 'Specialty Minerals (Canada)', null, null, null, 'Minerals Technologies(SMI) 캐나다 사업. 2025 10-K 에 캐나다 제조시설 4곳(Consumer & Specialties). 과거 위성 PCC: Windsor·Saint-Jérôme(QC), Cornwall·Dryden(ON).', 'Specialty Minerals, Minerals Technologies in Canada - the 2025 Form 10-K lists four Canadian Consumer and Specialties plants (names and capacities not given). Historical satellite PCC plants: Windsor QC (Domtar), Saint-Jérôme QC (Rolland), Cornwall ON (Domtar, mill closed 2006), Dryden ON (Weyerhaeuser, paper stopped 2008, about 30,000 t/yr).', 'CA check 2026-10-15: which of the four 2025 plants are paper PCC is not confirmed. Royalty licensee at MTI HQ level.')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%CA check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('omya.*perth', 'Omya Canada - Perth (Ontario)', 'Ontario', 'Perth', null, 'Omya Canada 의 Perth(온타리오) 탄산칼슘 가공공장. 원료는 Omya 가 운영하는 Tatlock Quarry, 관련 인원 94명(온타리오 광업협회 2025).', 'Omya Canada - calcium carbonate processing at Perth, Ontario, fed by the Omya-run Tatlock Quarry, 94 staff (Ontario Mining Association 2025).', 'CA check 2026-10-15: paper-grade GCC capacity, wet slurry line and paper customers not public. +1 613-267-5367. Historical: Omya (ex Huber) PCC at Prince Albert SK, 42,000 t/yr (2005) - host mill closed 2006. Royalty licensee at Omya HQ level.'),
  ('omya.*(saint|st\.?)[- ]?armand', 'Omya Canada - Saint-Armand (Quebec)', 'Quebec', 'Saint-Armand', null, 'Omya Canada 의 Saint-Armand(퀘벡) 광물 가공공장. 1500 chemin de la Carrière. BNQ 등록 제품은 농업용 돌로마이트 석회석(AGRODOL-SA).', 'Omya Canada - mineral processing at 1500 chemin de la Carrière, Saint-Armand, Quebec. The BNQ-listed product is agricultural dolomitic limestone (AGRODOL-SA).', 'CA check 2026-10-15: paper-grade output not confirmed - check CaCO3 purity, MgCO3, brightness. +1 450-248-2931.'),
  ('(specialty minerals|minerals technologies).*canada', 'Specialty Minerals (Canada)', null, null, null, 'Minerals Technologies(SMI) 캐나다 사업. 2025 10-K 에 캐나다 제조시설 4곳(Consumer & Specialties). 과거 위성 PCC: Windsor·Saint-Jérôme(QC), Cornwall·Dryden(ON).', 'Specialty Minerals, Minerals Technologies in Canada - the 2025 Form 10-K lists four Canadian Consumer and Specialties plants (names and capacities not given). Historical satellite PCC plants: Windsor QC (Domtar), Saint-Jérôme QC (Rolland), Cornwall ON (Domtar, mill closed 2006), Dryden ON (Weyerhaeuser, paper stopped 2008, about 30,000 t/yr).', 'CA check 2026-10-15: which of the four 2025 plants are paper PCC is not confirmed. Royalty licensee at MTI HQ level.')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
  and coalesce(p.source, '') <> 'canada_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya Canada - Perth (Ontario)', 'GCC producer', 'Omya Canada GCC - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Omya Canada - Saint-Armand (Quebec)', 'Carbonate processor', 'Omya Quebec site - paper grades unconfirmed', 'merchant', 'C', 'gcc'),
  ('Specialty Minerals (Canada)', 'PCC producer', 'Satellite PCC history at Windsor and Saint-Jérôme', 'satellite (on-site)', 'B', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'canada_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'CA', v.region, v.city, v.website, 'active', 'canada_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar', 'Domtar - Windsor Mill (Quebec)', 'Quebec', 'Windsor', null, 'Domtar Windsor(퀘벡) — 캐나다에 남은 마지막 통합형 고급 인쇄용지 공장. 초지기 2대, 연 64.2만 short t(약 58.2만 t). 복사·디지털 인쇄·봉투용 고백색 비도공지.', 'Domtar Windsor Mill, 609 Rang 12, Windsor, Quebec - the last fully integrated fine-paper mill in Canada, two paper machines, 642,000 short t/yr (about 582,400 t), copy, digital printing, envelope and high-white uncoated freesheet.', 'CA check 2026-10-15: SMI satellite PCC supplied this mill (2004 MTI SEC record) - current supplier not confirmed. +1 800-263-8366.'),
  ('irving paper|irving pulp.*saint john', null, 'irving', 'Irving Paper - Saint John (New Brunswick)', 'New Brunswick', 'Saint John', null, 'J.D. Irving 의 Irving Paper(Saint John, 435 Bayside Drive). SC-A·SC-A+·SC-A++ 슈퍼캘린더지, 오프셋·그라비어 42~74 g/m², 연 20.5만 t.', 'Irving Paper, 435 Bayside Drive, Saint John, New Brunswick (J.D. Irving) - supercalendered SC-A, SC-A+, SC-A++, offset and rotogravure grades 42-74 g/m2, 205,000 t/yr.', 'CA check 2026-10-15: filler supplier not public. Earlier news reported a 50 pct cut of papermaking operations - current running capacity to confirm.'),
  ('wayagamack', null, 'kruger', 'Kruger - Wayagamack Mill', 'Quebec', 'Trois-Rivières', null, 'Kruger Inc. Wayagamack(트루아리비에르) 초경량 코팅지·특수지 공장, 연 26만 t. 2026-05 인근 부직포 사업 3.33억 캐나다달러 투자(2028 가동).', 'Kruger Inc. Wayagamack Mill, Trois-Rivières, Quebec - ultra-lightweight coated and specialty papers, 260,000 t/yr. 2026-05: CAD 333 m nonwovens investment next to the mill (start 2028) - not added paper capacity. Carbon capture demonstration project.', 'CA check 2026-10-15: base-paper filler versus coating pigment supply chains to separate.'),
  ('kruger.*crabtree', 'crabtree', 'kruger products', 'Kruger Products - Crabtree', 'Quebec', 'Crabtree', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Crabtree. toilet tissue and towel on recycled fibre, 연 92,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Crabtree tissue mill, toilet tissue and towel on recycled fibre, 92,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger products.*gatineau|kruger.*gatineau.*tissu', 'gatineau', 'kruger products', 'Kruger Products - Gatineau', 'Quebec', 'Gatineau', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Gatineau. toilet tissue, facial, napkins, 연 97,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Gatineau tissue mill, toilet tissue, facial, napkins, 97,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*lennoxville', 'lennoxville', 'kruger products', 'Kruger Products - Lennoxville', 'Quebec', 'Lennoxville', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Lennoxville. tissue base paper, 연 24,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Lennoxville tissue mill, tissue base paper, 24,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*sherbrooke.*tad|kruger.*\mtad\M', null, 'kruger', 'Kruger Products - Sherbrooke TAD', 'Quebec', 'Sherbrooke', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Sherbrooke TAD. premium TAD toilet tissue and towel, 연 70,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Sherbrooke TAD tissue mill, premium TAD toilet tissue and towel, 70,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*sherbrooke.*ldc|kruger.*\mldc\M', null, 'kruger', 'Kruger Products - Sherbrooke LDC', 'Quebec', 'Sherbrooke', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Sherbrooke LDC. new LDC tissue plant (2025), 연 60,000 t (2024 지속가능성 보고서 / 2025 신규).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Sherbrooke LDC tissue mill, new LDC tissue plant (2025), 60,000 t/yr papermaking capacity (2025 start-up).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*new westminster', 'new westminster', 'kruger products', 'Kruger Products - New Westminster', 'British Columbia', 'New Westminster', null, 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 New Westminster. toilet tissue, facial, 연 67,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - New Westminster tissue mill, toilet tissue, facial, 67,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('cascades.*kingsey.*tissu|cascades tissue.*kingsey', null, 'cascades', 'Cascades Tissue - Kingsey Falls', 'Quebec', 'Kingsey Falls', null, 'Cascades 의 Kingsey Falls(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Kingsey Falls, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('cascades.*candiac', null, 'cascades', 'Cascades Tissue - Candiac', 'Quebec', 'Candiac', null, 'Cascades 의 Candiac(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Candiac, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('cascades.*lachute', null, 'cascades', 'Cascades Tissue - Lachute', 'Quebec', 'Lachute', null, 'Cascades 의 Lachute(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Lachute, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('irving tissue', null, 'irving', 'Irving Tissue - Saint John', 'New Brunswick', 'Saint John', null, 'Irving Tissue(Saint John, 486 Mill Street) 티슈 원지 생산 — Dieppe 가공공장으로 공급.', 'Irving Tissue, 486 Mill Street, Saint John, New Brunswick - tissue parent rolls supplying the Dieppe converting plant (Irving Consumer Products also runs Toronto and two US sites).', 'CA check 2026-10-15: +1 506-635-1525. Capacity not public.'),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland', 'Sustana - Saint-Jérôme (Rolland)', 'Quebec', 'Saint-Jérôme', null, 'Sustana 그룹의 Saint-Jérôme(퀘벡) 제지사업(구 Cascades Fine Papers / Rolland). 재생 인쇄지·특수지, 2025 PM7·PM8 설비 개선 보도.', 'Sustana - Saint-Jérôme, Quebec papermaking (ex Cascades Fine Papers / Rolland) - recycled printing and specialty papers, PM7 and PM8 upgrade reported 2025.', 'CA check 2026-10-15: SMI satellite PCC supplied Rolland here (2004) - whether it still runs is not confirmed. Current machine status to confirm.')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CA check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar', 'Domtar Windsor(퀘벡) — 캐나다에 남은 마지막 통합형 고급 인쇄용지 공장. 초지기 2대, 연 64.2만 short t(약 58.2만 t). 복사·디지털 인쇄·봉투용 고백색 비도공지.', 'Domtar Windsor Mill, 609 Rang 12, Windsor, Quebec - the last fully integrated fine-paper mill in Canada, two paper machines, 642,000 short t/yr (about 582,400 t), copy, digital printing, envelope and high-white uncoated freesheet.', 'CA check 2026-10-15: SMI satellite PCC supplied this mill (2004 MTI SEC record) - current supplier not confirmed. +1 800-263-8366.'),
  ('irving paper|irving pulp.*saint john', null, 'irving', 'J.D. Irving 의 Irving Paper(Saint John, 435 Bayside Drive). SC-A·SC-A+·SC-A++ 슈퍼캘린더지, 오프셋·그라비어 42~74 g/m², 연 20.5만 t.', 'Irving Paper, 435 Bayside Drive, Saint John, New Brunswick (J.D. Irving) - supercalendered SC-A, SC-A+, SC-A++, offset and rotogravure grades 42-74 g/m2, 205,000 t/yr.', 'CA check 2026-10-15: filler supplier not public. Earlier news reported a 50 pct cut of papermaking operations - current running capacity to confirm.'),
  ('wayagamack', null, 'kruger', 'Kruger Inc. Wayagamack(트루아리비에르) 초경량 코팅지·특수지 공장, 연 26만 t. 2026-05 인근 부직포 사업 3.33억 캐나다달러 투자(2028 가동).', 'Kruger Inc. Wayagamack Mill, Trois-Rivières, Quebec - ultra-lightweight coated and specialty papers, 260,000 t/yr. 2026-05: CAD 333 m nonwovens investment next to the mill (start 2028) - not added paper capacity. Carbon capture demonstration project.', 'CA check 2026-10-15: base-paper filler versus coating pigment supply chains to separate.'),
  ('kruger.*crabtree', 'crabtree', 'kruger products', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Crabtree. toilet tissue and towel on recycled fibre, 연 92,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Crabtree tissue mill, toilet tissue and towel on recycled fibre, 92,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger products.*gatineau|kruger.*gatineau.*tissu', 'gatineau', 'kruger products', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Gatineau. toilet tissue, facial, napkins, 연 97,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Gatineau tissue mill, toilet tissue, facial, napkins, 97,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*lennoxville', 'lennoxville', 'kruger products', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Lennoxville. tissue base paper, 연 24,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Lennoxville tissue mill, tissue base paper, 24,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*sherbrooke.*tad|kruger.*\mtad\M', null, 'kruger', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Sherbrooke TAD. premium TAD toilet tissue and towel, 연 70,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Sherbrooke TAD tissue mill, premium TAD toilet tissue and towel, 70,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*sherbrooke.*ldc|kruger.*\mldc\M', null, 'kruger', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 Sherbrooke LDC. new LDC tissue plant (2025), 연 60,000 t (2024 지속가능성 보고서 / 2025 신규).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - Sherbrooke LDC tissue mill, new LDC tissue plant (2025), 60,000 t/yr papermaking capacity (2025 start-up).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('kruger.*new westminster', 'new westminster', 'kruger products', 'Kruger Products(Cashmere·Purex·Scotties·SpongeTowels·White Swan) 티슈 공장 New Westminster. toilet tissue, facial, 연 67,000 t (2024 지속가능성 보고서).', 'Kruger Products (Cashmere, Purex, Scotties, SpongeTowels, White Swan) - New Westminster tissue mill, toilet tissue, facial, 67,000 t/yr papermaking capacity (2024 sustainability report).', 'CA check 2026-10-15: Kruger Products Canada total 350 kt (2024) + 60 kt LDC (2025) = 410 kt arithmetic sum.'),
  ('cascades.*kingsey.*tissu|cascades tissue.*kingsey', null, 'cascades', 'Cascades 의 Kingsey Falls(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Kingsey Falls, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('cascades.*candiac', null, 'cascades', 'Cascades 의 Candiac(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Candiac, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('cascades.*lachute', null, 'cascades', 'Cascades 의 Lachute(퀘벡) 티슈 원지 생산·가공 공장.', 'Cascades tissue mill at Lachute, Quebec - tissue base paper and converting (Cascades North America tissue about 445,000 short t/yr, incl. US).', 'CA check 2026-10-15: mill-level capacity not public. Granby is converting only (CAD 15 m new line 2026-06).'),
  ('irving tissue', null, 'irving', 'Irving Tissue(Saint John, 486 Mill Street) 티슈 원지 생산 — Dieppe 가공공장으로 공급.', 'Irving Tissue, 486 Mill Street, Saint John, New Brunswick - tissue parent rolls supplying the Dieppe converting plant (Irving Consumer Products also runs Toronto and two US sites).', 'CA check 2026-10-15: +1 506-635-1525. Capacity not public.'),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland', 'Sustana 그룹의 Saint-Jérôme(퀘벡) 제지사업(구 Cascades Fine Papers / Rolland). 재생 인쇄지·특수지, 2025 PM7·PM8 설비 개선 보도.', 'Sustana - Saint-Jérôme, Quebec papermaking (ex Cascades Fine Papers / Rolland) - recycled printing and specialty papers, PM7 and PM8 upgrade reported 2025.', 'CA check 2026-10-15: SMI satellite PCC supplied Rolland here (2004) - whether it still runs is not confirmed. Current machine status to confirm.'),
  ('(domtar|resolute).*alma', null, '(domtar|resolute).*alma', null, null, 'CA check 2026-10-15: Commercial printing paper on mechanical pulp - context only.'),
  ('(domtar|resolute).*dolbeau', null, '(domtar|resolute).*dolbeau', null, null, 'CA check 2026-10-15: Specialty printing papers - context only.'),
  ('(domtar|resolute).*k[eé]nogami', null, '(domtar|resolute).*k[eé]nogami', null, null, 'CA check 2026-10-15: Specialty publication and printing papers - context only.'),
  ('(domtar|resolute).*clermont', null, '(domtar|resolute).*clermont', null, null, 'CA check 2026-10-15: Newsprint, 1 machine, about 155 staff - context only.'),
  ('(domtar|resolute).*gatineau', null, '(domtar|resolute).*gatineau', null, null, 'CA check 2026-10-15: Newsprint grades - context only.'),
  ('(domtar|catalyst|paper excellence).*alberni', null, '(domtar|catalyst|paper excellence).*alberni', null, null, 'CA check 2026-10-15: Mechanical-pulp printing papers - status to confirm - context only.'),
  ('^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)', null, '^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)', null, null, 'CA check 2026-10-15: Recycled linerboard and medium 375 kt + newsprint, construction, book and high-white 145 kt - context only.'),
  ('corner brook', null, 'corner brook', null, null, 'CA check 2026-10-15: Newsprint - context only.'),
  ('stadacona', null, 'stadacona', null, null, 'CA check 2026-10-15: Newsprint, commercial and recycled kraft over 250 kt + chipboard 45 kt - context only.'),
  ('papier masson|masson', null, 'papier masson|masson', null, null, 'CA check 2026-10-15: Newsprint (240 kt at acquisition, historical) - context only.'),
  ('soucy', null, 'soucy', null, null, 'CA check 2026-10-15: Newsprint grades - status to confirm - context only.'),
  ('atlantic.*whitby', null, 'atlantic.*whitby', null, null, 'CA check 2026-10-15: Recycled linerboard and medium (converted newsprint line) - context only.'),
  ('new forest', null, 'new forest', null, null, 'CA check 2026-10-15: 100 pct recycled containerboard - context only.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'canada_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar'),
  ('irving paper|irving pulp.*saint john', null, 'irving'),
  ('wayagamack', null, 'kruger'),
  ('kruger.*crabtree', 'crabtree', 'kruger products'),
  ('kruger products.*gatineau|kruger.*gatineau.*tissu', 'gatineau', 'kruger products'),
  ('kruger.*lennoxville', 'lennoxville', 'kruger products'),
  ('kruger.*sherbrooke.*tad|kruger.*\mtad\M', null, 'kruger'),
  ('kruger.*sherbrooke.*ldc|kruger.*\mldc\M', null, 'kruger'),
  ('kruger.*new westminster', 'new westminster', 'kruger products'),
  ('cascades.*kingsey.*tissu|cascades tissue.*kingsey', null, 'cascades'),
  ('cascades.*candiac', null, 'cascades'),
  ('cascades.*lachute', null, 'cascades'),
  ('irving tissue', null, 'irving'),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland'),
  ('(domtar|resolute).*alma', null, '(domtar|resolute).*alma'),
  ('(domtar|resolute).*dolbeau', null, '(domtar|resolute).*dolbeau'),
  ('(domtar|resolute).*k[eé]nogami', null, '(domtar|resolute).*k[eé]nogami'),
  ('(domtar|resolute).*clermont', null, '(domtar|resolute).*clermont'),
  ('(domtar|resolute).*gatineau', null, '(domtar|resolute).*gatineau'),
  ('(domtar|catalyst|paper excellence).*alberni', null, '(domtar|catalyst|paper excellence).*alberni'),
  ('^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)', null, '^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)'),
  ('corner brook', null, 'corner brook'),
  ('stadacona', null, 'stadacona'),
  ('papier masson|masson', null, 'papier masson|masson'),
  ('soucy', null, 'soucy'),
  ('atlantic.*whitby', null, 'atlantic.*whitby'),
  ('new forest', null, 'new forest')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar',
   $pj${"owner": "Domtar", "priority": 1, "products": "Uncoated freesheet - copy, digital printing, envelope", "grades": ["UWF", "Copy paper"], "machines": 2, "capacity": {"value": 642000, "unit": "short_t", "year": "Domtar mill data", "source": "domtar.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct utilization x 5 pct FCC - planning only, not an order."}, "pitch": "FCC partial PCC replacement on UWF - fibre saving at equal strength and opacity", "approach": "Lead Canadian account. Confirm whether SMI still runs the satellite PCC - then trial through SMI (licensee).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "Domtar investment in Windsor (CAD 56.4 m, Quebec CAD 12 m support)", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('irving paper|irving pulp.*saint john', null, 'irving',
   $pj${"owner": "J.D. Irving", "priority": 2, "products": "Supercalendered SC-A paper, offset, rotogravure", "grades": ["SC paper"], "capacity": {"value": 205000, "unit": "metric_t", "year": "Company figure", "source": "jdirving.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - planning only."}, "pitch": "High-filler SC paper - FCC for bulk, opacity and smoothness balance", "approach": "Confirm machine status after the reported cut, then filler supplier.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('wayagamack', null, 'kruger',
   $pj${"owner": "Kruger Inc.", "priority": 3, "products": "Ultra-lightweight coated paper, specialty papers", "grades": ["LWC", "Specialty paper"], "capacity": {"value": 260000, "unit": "metric_t", "year": "Kruger 2025", "source": "kruger.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct, base-paper filler only - planning only."}, "pitch": "Base-paper fibre saving under the coating", "approach": "Internal filler first, not coating pigment.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger.*crabtree', 'crabtree', 'kruger products',
   $pj${"owner": "Kruger Products", "priority": 4, "products": "Tissue - toilet tissue and towel on recycled fibre", "grades": ["Tissue"], "capacity": {"value": 92000, "unit": "metric_t", "year": "2024 sustainability report", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Recycled-fibre tissue trial - softness, bulk, absorbency, dust", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger products.*gatineau|kruger.*gatineau.*tissu', 'gatineau', 'kruger products',
   $pj${"owner": "Kruger Products", "priority": 6, "products": "Tissue - toilet tissue, facial, napkins", "grades": ["Tissue"], "capacity": {"value": 97000, "unit": "metric_t", "year": "2024 sustainability report", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Tissue trial after Crabtree", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger.*lennoxville', 'lennoxville', 'kruger products',
   $pj${"owner": "Kruger Products", "priority": 6, "products": "Tissue - tissue base paper", "grades": ["Tissue"], "capacity": {"value": 24000, "unit": "metric_t", "year": "2024 sustainability report", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Tissue trial after Crabtree", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger.*sherbrooke.*tad|kruger.*\mtad\M', null, 'kruger',
   $pj${"owner": "Kruger Products", "priority": 7, "products": "Tissue - premium TAD toilet tissue and towel", "grades": ["Tissue", "TAD tissue"], "capacity": {"value": 70000, "unit": "metric_t", "year": "2024 sustainability report", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Tissue trial after Crabtree", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger.*sherbrooke.*ldc|kruger.*\mldc\M', null, 'kruger',
   $pj${"owner": "Kruger Products", "priority": 6, "products": "Tissue - new LDC tissue plant (2025)", "grades": ["Tissue"], "capacity": {"value": 60000, "unit": "metric_t", "year": "2025 start-up", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Tissue trial after Crabtree", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kruger.*new westminster', 'new westminster', 'kruger products',
   $pj${"owner": "Kruger Products", "priority": 6, "products": "Tissue - toilet tissue, facial", "grades": ["Tissue"], "capacity": {"value": 67000, "unit": "metric_t", "year": "2024 sustainability report", "source": "krugerproducts.ca"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 0.85, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 85 pct x 5 pct - 5 pct is unproven in tissue, trial at 1-5 pct."}, "pitch": "Tissue trial after Crabtree", "approach": "Trial order Crabtree (recycled) -> Gatineau -> Sherbrooke. TAD last.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cascades.*kingsey.*tissu|cascades tissue.*kingsey', null, 'cascades',
   $pj${"owner": "Cascades", "priority": 5, "products": "Tissue base paper and converting", "grades": ["Tissue"], "approach": "Recycled and virgin tissue FCC trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cascades.*candiac', null, 'cascades',
   $pj${"owner": "Cascades", "priority": 6, "products": "Tissue base paper and converting", "grades": ["Tissue"], "approach": "Recycled and virgin tissue FCC trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cascades.*lachute', null, 'cascades',
   $pj${"owner": "Cascades", "priority": 6, "products": "Tissue base paper and converting", "grades": ["Tissue"], "approach": "Recycled and virgin tissue FCC trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('irving tissue', null, 'irving',
   $pj${"owner": "J.D. Irving", "priority": 6, "products": "Tissue parent rolls", "grades": ["Tissue"], "approach": "Pair with the Irving Paper SC pitch.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland',
   $pj${"owner": "Sustana", "products": "Recycled printing and specialty papers", "grades": ["Printing and writing", "Specialty paper"], "approach": "Confirm running machines and the PCC plant before any pitch.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(domtar|resolute).*alma', null, '(domtar|resolute).*alma',
   $pj${"owner": "Domtar", "products": "Commercial printing paper on mechanical pulp", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(domtar|resolute).*dolbeau', null, '(domtar|resolute).*dolbeau',
   $pj${"owner": "Domtar", "products": "Specialty printing papers", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(domtar|resolute).*k[eé]nogami', null, '(domtar|resolute).*k[eé]nogami',
   $pj${"owner": "Domtar", "products": "Specialty publication and printing papers", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(domtar|resolute).*clermont', null, '(domtar|resolute).*clermont',
   $pj${"owner": "Domtar", "products": "Newsprint, 1 machine, about 155 staff", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15", "capacity_split": [{"label": "Reported", "value_t": 221000}]}$pj$::jsonb),
  ('(domtar|resolute).*gatineau', null, '(domtar|resolute).*gatineau',
   $pj${"owner": "Domtar", "products": "Newsprint grades", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(domtar|catalyst|paper excellence).*alberni', null, '(domtar|catalyst|paper excellence).*alberni',
   $pj${"owner": "Domtar", "products": "Mechanical-pulp printing papers - status to confirm", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)', null, '^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)',
   $pj${"owner": "Kruger Inc.", "products": "Recycled linerboard and medium 375 kt + newsprint, construction, book and high-white 145 kt", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15", "capacity_split": [{"label": "Reported", "value_t": 520000}]}$pj$::jsonb),
  ('corner brook', null, 'corner brook',
   $pj${"owner": "Kruger Inc.", "products": "Newsprint", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15", "capacity_split": [{"label": "Reported", "value_t": 250000}]}$pj$::jsonb),
  ('stadacona', null, 'stadacona',
   $pj${"owner": "White Birch Paper", "products": "Newsprint, commercial and recycled kraft over 250 kt + chipboard 45 kt", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15", "capacity_split": [{"label": "Reported", "value_t": 295000}]}$pj$::jsonb),
  ('papier masson|masson', null, 'papier masson|masson',
   $pj${"owner": "White Birch Paper", "products": "Newsprint (240 kt at acquisition, historical)", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('soucy', null, 'soucy',
   $pj${"owner": "White Birch Paper", "products": "Newsprint grades - status to confirm", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('atlantic.*whitby', null, 'atlantic.*whitby',
   $pj${"owner": "Atlantic Packaging", "products": "Recycled linerboard and medium (converted newsprint line)", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('new forest', null, 'new forest',
   $pj${"owner": "Atlantic Packaging", "products": "100 pct recycled containerboard", "approach": "Newsprint and recycled packaging - later, after a packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'canada_update_20261015', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar', '(specialty minerals|minerals technologies).*canada', 'historical', 'medium', null::date, null::date, null, 'satellite PCC at Windsor', 'MTI SEC filing 2004', 'SMI satellite PCC for Domtar Windsor (2004 record) - current supply not confirmed'),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland', '(specialty minerals|minerals technologies).*canada', 'historical', 'medium', null::date, null::date, null, 'satellite PCC at Saint-Jérôme', 'MTI SEC filing 2004', 'SMI satellite PCC for Cascades Fine Papers / Rolland Saint-Jérôme (2004 record) - current status not confirmed')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
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
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CA', 'Canada', 'high',
   $cm$Domtar Windsor UWF (SMI PCC history), Irving SC paper, Kruger Wayagamack and Kruger Products tissue$cm$,
   $cm$Both licensees are present - Omya with plants at Perth ON and Saint-Armand QC, SMI with four Canadian plants in its 2025 10-K and a satellite PCC history at Windsor and Saint-Jérôme. Lead mill is Domtar Windsor (642,000 short t UWF). Then Irving Paper SC (205 kt), Kruger Wayagamack (260 kt) and Kruger Products tissue (410 kt). Much Canadian capacity is newsprint, pulp or recycled packaging.$cm$,
   $cm${"fillers": "Licensees: Omya Canada (Perth ON GCC with Tatlock Quarry, Saint-Armand QC), Specialty Minerals (four Canadian plants in the 2025 10-K, satellite PCC history at Windsor, Saint-Jérôme, Cornwall and Dryden). Closed: Cornwall (2006), Dryden (2008), Omya ex-Huber Prince Albert PCC (mill closed 2006). Lime only, not added: Graymont, Carmeuse, Quebec quarries.", "mills": "UWF: Domtar Windsor. SC: Irving Paper Saint John. Coated: Kruger Wayagamack. Tissue: Kruger Products (Crabtree, Gatineau, Lennoxville, Sherbrooke TAD and LDC, New Westminster - 410 kt), Cascades (Kingsey Falls, Candiac, Lachute), Irving Tissue. Newsprint and packaging: Domtar Clermont and others, Kruger Trois-Rivières and Corner Brook, White Birch, Atlantic Packaging. Sustana Saint-Jérôme to confirm.", "strategy": "Windsor through SMI first, Irving SC and Wayagamack next, tissue trials at Kruger Products Crabtree and Cascades. Pursue Omya and SMI at HQ level as licensees.", "risks": "Many listed mills are newsprint or pulp only. Old PCC sites closed. Mill-level filler contracts not public.", "next_steps": ["Locate the four SMI Canadian plants in the 2025 10-K", "Confirm the Windsor PCC supplier", "Confirm Irving Paper running capacity"], "key_numbers": [{"label": "Domtar Windsor", "value": "642,000 short t (582 kt) UWF"}, {"label": "Kruger Products tissue", "value": "410 kt (2024 + 2025 LDC)"}, {"label": "Historical Canadian PCC", "value": "over 160 kt (about 2005)"}, {"label": "Report scenario", "value": "61,940 t FCC, USD 929,103 royalty"}], "files": ["seed_20261015s_canada_mills_fillers"]}$cm$::jsonb,
   $cm$Domtar Windsor 비도공지(SMI PCC 이력) + Irving SC지 + Kruger Wayagamack·Kruger Products 티슈$cm$,
   $cm$라이선시 Omya(Perth·Saint-Armand)·SMI(2025 10-K 캐나다 공장 4곳, Windsor·Saint-Jérôme 위성 PCC 이력) 모두 진출. 1순위 Domtar Windsor(64.2만 short t), 2 Irving Paper SC, 3 Kruger Wayagamack, 4 Kruger Products Crabtree 티슈. 신문용지·펄프·재생 포장 공장은 후순위.$cm$,
   44516, 61940,
   $cm$인쇄용지 3곳(Windsor·Irving·Wayagamack) 85%×5% = 44,516 t, Kruger Products 티슈 6라인 포함 61,940 t (보고서 시나리오, 티슈 5%는 미검증)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('domtar.*windsor|windsor.*domtar', 'windsor', 'domtar'),
  ('irving paper|irving pulp.*saint john', null, 'irving'),
  ('wayagamack', null, 'kruger'),
  ('kruger.*crabtree', 'crabtree', 'kruger products'),
  ('kruger products.*gatineau|kruger.*gatineau.*tissu', 'gatineau', 'kruger products'),
  ('kruger.*lennoxville', 'lennoxville', 'kruger products'),
  ('kruger.*sherbrooke.*tad|kruger.*\mtad\M', null, 'kruger'),
  ('kruger.*sherbrooke.*ldc|kruger.*\mldc\M', null, 'kruger'),
  ('kruger.*new westminster', 'new westminster', 'kruger products'),
  ('cascades.*kingsey.*tissu|cascades tissue.*kingsey', null, 'cascades'),
  ('cascades.*candiac', null, 'cascades'),
  ('cascades.*lachute', null, 'cascades'),
  ('irving tissue', null, 'irving'),
  ('sustana|rolland', 'saint-?j[eé]r[oô]me|st-?j[eé]r[oô]me', 'sustana|rolland'),
  ('(domtar|resolute).*alma', null, '(domtar|resolute).*alma'),
  ('(domtar|resolute).*dolbeau', null, '(domtar|resolute).*dolbeau'),
  ('(domtar|resolute).*k[eé]nogami', null, '(domtar|resolute).*k[eé]nogami'),
  ('(domtar|resolute).*clermont', null, '(domtar|resolute).*clermont'),
  ('(domtar|resolute).*gatineau', null, '(domtar|resolute).*gatineau'),
  ('(domtar|catalyst|paper excellence).*alberni', null, '(domtar|catalyst|paper excellence).*alberni'),
  ('^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)', null, '^(?!.*wayagamack).*kruger.*(trois-?rivi|liner|containerboard)'),
  ('corner brook', null, 'corner brook'),
  ('stadacona', null, 'stadacona'),
  ('papier masson|masson', null, 'papier masson|masson'),
  ('soucy', null, 'soucy'),
  ('atlantic.*whitby', null, 'atlantic.*whitby'),
  ('new forest', null, 'new forest')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'canada_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'canada_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*perth' or p.party_name ~* 'omya.*(saint|st\.?)[- ]?armand' or p.party_name ~* '(specialty minerals|minerals technologies).*canada')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'CA'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'CA'
union all
select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
       coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CA'
  and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
order by 1, 4, 2;
