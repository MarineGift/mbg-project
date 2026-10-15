-- ============================================================
-- seed_20261014ag_nepal_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Nepal update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'NP check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Filler if missing: Shakti Minerals (feed-grade limestone powder).
--    Nepal Pulp and Paper's own PCC plant is recorded on its mill card.
-- 2) Mills if missing + plant blocks, priority 1-4: Nepal Pulp and Paper
--    (IME, 21 kt, in-house PCC), Durga Pulps (100 t/day), Reliance Paper
--    (printing line 7.5 kt), Everest Paper (30 t/day). context, match only:
--    Baba Paper, Bhrikuti (closed 2011).
--    FCC scenarios on the printing-paper capacities (all four).
--    No supply links.
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
       v.party_name, 'NP', v.region, v.city, v.website, 'active', 'nepal_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Shakti Minerals (Nepal)', '%Shakti Mineral%', 'Bagmati', 'Kathmandu', 'https://www.shaktimineral.com', '2007년 설립 Shakti Minerals. 카트만두 본사, Bhairahawa 경제특구 광물 가공시설, 석회석 탐사·채굴·분말.', 'Shakti Minerals (founded 2007), SG Tower, Thapathali, Kathmandu - limestone exploration, quarrying and powder, processing plant in Bhairahawa SEZ.', 'NP check 2026-10-14: current powder is feed grade (under 250 um, Ca over 30 pct, off-white) - not paper GCC. Raw material and grinding partner only. info@shaktimineral.com. Sarswati Polymer (masterbatch) and Indian suppliers serving Nepal not added. No Omya, MTI or Artemyn plant in Nepal.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%NP check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Shakti Minerals (Nepal)', '%Shakti Mineral%', 'Bagmati', 'Kathmandu', 'https://www.shaktimineral.com', '2007년 설립 Shakti Minerals. 카트만두 본사, Bhairahawa 경제특구 광물 가공시설, 석회석 탐사·채굴·분말.', 'Shakti Minerals (founded 2007), SG Tower, Thapathali, Kathmandu - limestone exploration, quarrying and powder, processing plant in Bhairahawa SEZ.', 'NP check 2026-10-14: current powder is feed grade (under 250 um, Ca over 30 pct, off-white) - not paper GCC. Raw material and grinding partner only. info@shaktimineral.com. Sarswati Polymer (masterbatch) and Indian suppliers serving Nepal not added. No Omya, MTI or Artemyn plant in Nepal.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'nepal_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Shakti Minerals (Nepal)', 'GCC producer', 'Nepal limestone powder - raw material', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'nepal_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'NP', v.region, v.city, v.website, 'active', 'nepal_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Nepal Pulp%', '%Nepal Pulp and Paper%', 'Nepal Pulp and Paper Industries - IME (Mahottari)', 'Madhesh', 'Gaushala', 'https://www.imegroup.com.np', 'IME Group 의 Nepal Pulp and Paper Industries(마호타리 Gaushala Ramnagar). 2025-03 상업생산, 복사·필기·인쇄용지 약 75 t/일, 공장 내 PCC 설비.', 'Nepal Pulp and Paper Industries (IME Group), Ramnagar, Gaushala, Mahottari - commercial since 2025-03, writing, printing and A4 copy paper about 75 t/day (about 21,000 t/yr), PCC plant inside the mill, mainly recycled fibre.', 'NP check 2026-10-14: about 12,000-13,000 t produced and 10,000 t sold in the first year, plans 150 t/day. Investment about NPR 2.6bn incl. working capital. CEO Arun Kumar Bhandari. PCC capacity and operator not public - find who designed and supplied the PCC plant. Nepal imports about 50,000 t/yr of writing and printing paper.'),
  ('%Durga Pulp%', '%Quest Infra%Durga%', 'Durga Pulps (Birgunj)', 'Madhesh', 'Birgunj', null, '비르간즈의 Durga Pulps. 필기·인쇄·서적·신문용지, 100 t/일(기업 소개).', 'Durga Pulps, Birgunj, Parsa - writing, printing, book paper and newsprint, 100 t/day (company profile).', 'NP check 2026-10-14: a 2021 job ad said 70 t/day expanding to 150 t/day - current capacity to confirm.'),
  ('%Reliance Paper%', '%Reliance%Bhairahawa%', 'Reliance Paper Mills (Bhairahawa)', 'Lumbini', 'Bhairahawa', null, '1995년 설립 Reliance Paper Mills(Bhairahawa Semari). 크라프트지 3만 t + 필기·인쇄용지 7,500 t, 폐지·농업부산물·버개스.', 'Reliance Paper Mills (founded 1995), Semari, Bhairahawa - kraft paper 30,000 t/yr and writing and printing paper 7,500 t/yr, waste paper, wheat and rice straw and bagasse, Nepal and India markets.', null),
  ('%Everest Paper%', '%Everest Paper Mills%', 'Everest Paper Mills (Dhanusha)', 'Madhesh', 'Mahendranagar', null, '1982년 설립 Everest Group 의 Everest Paper Mills(다누샤 Mahendranagar). 농업부산물 섬유 필기·인쇄용지 30 t/일.', 'Everest Paper Mills (Everest Group, founded 1982), Mahendranagar, Dhanusha - writing and printing paper on wheat and rice straw, bagasse, jute and waste paper, 30 t/day (company site).', 'NP check 2026-10-14: one directory says 60 t/day - company figure used. epmktm@gmail.com (FNCCI listing).')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NP'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NP check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NP'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Nepal Pulp%', '%Nepal Pulp and Paper%', '%Nepal Pulp%', 'IME Group 의 Nepal Pulp and Paper Industries(마호타리 Gaushala Ramnagar). 2025-03 상업생산, 복사·필기·인쇄용지 약 75 t/일, 공장 내 PCC 설비.', 'Nepal Pulp and Paper Industries (IME Group), Ramnagar, Gaushala, Mahottari - commercial since 2025-03, writing, printing and A4 copy paper about 75 t/day (about 21,000 t/yr), PCC plant inside the mill, mainly recycled fibre.', 'NP check 2026-10-14: about 12,000-13,000 t produced and 10,000 t sold in the first year, plans 150 t/day. Investment about NPR 2.6bn incl. working capital. CEO Arun Kumar Bhandari. PCC capacity and operator not public - find who designed and supplied the PCC plant. Nepal imports about 50,000 t/yr of writing and printing paper.'),
  ('%Durga Pulp%', '%Quest Infra%Durga%', '%Durga%', '비르간즈의 Durga Pulps. 필기·인쇄·서적·신문용지, 100 t/일(기업 소개).', 'Durga Pulps, Birgunj, Parsa - writing, printing, book paper and newsprint, 100 t/day (company profile).', 'NP check 2026-10-14: a 2021 job ad said 70 t/day expanding to 150 t/day - current capacity to confirm.'),
  ('%Reliance Paper%', '%Reliance%Bhairahawa%', '%Reliance%', '1995년 설립 Reliance Paper Mills(Bhairahawa Semari). 크라프트지 3만 t + 필기·인쇄용지 7,500 t, 폐지·농업부산물·버개스.', 'Reliance Paper Mills (founded 1995), Semari, Bhairahawa - kraft paper 30,000 t/yr and writing and printing paper 7,500 t/yr, waste paper, wheat and rice straw and bagasse, Nepal and India markets.', null),
  ('%Everest Paper%', '%Everest Paper Mills%', '%Everest%', '1982년 설립 Everest Group 의 Everest Paper Mills(다누샤 Mahendranagar). 농업부산물 섬유 필기·인쇄용지 30 t/일.', 'Everest Paper Mills (Everest Group, founded 1982), Mahendranagar, Dhanusha - writing and printing paper on wheat and rice straw, bagasse, jute and waste paper, 30 t/day (company site).', 'NP check 2026-10-14: one directory says 60 t/day - company figure used. epmktm@gmail.com (FNCCI listing).'),
  ('%Baba Paper%', '%Baba Paper Mills%', '%Baba%', '선사리의 Baba Paper Mills. 필기·인쇄용지 관련 국내 생산기업(2026-09 보도 언급).', 'Baba Paper Mills, Sunsari - domestic paper maker named in 2026-09 press.', null),
  ('%Bhrikuti%', '%Bhrikuti Pulp%', '%Bhrikuti%', '가인다코트의 Bhrikuti Pulp & Paper. 2011년 가동 중단, 장기 폐쇄.', 'Bhrikuti Pulp and Paper, Gaindakot - stopped in 2011, still closed (2026-07 press).', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'nepal_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NP'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Nepal Pulp%', '%Nepal Pulp and Paper%', '%Nepal Pulp%'),
  ('%Durga Pulp%', '%Quest Infra%Durga%', '%Durga%'),
  ('%Reliance Paper%', '%Reliance%Bhairahawa%', '%Reliance%'),
  ('%Everest Paper%', '%Everest Paper Mills%', '%Everest%'),
  ('%Baba Paper%', '%Baba Paper Mills%', '%Baba%'),
  ('%Bhrikuti%', '%Bhrikuti Pulp%', '%Bhrikuti%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NP'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Nepal Pulp%', '%Nepal Pulp and Paper%', '%Nepal Pulp%',
   $pj${"owner": "IME Group", "priority": 1, "products": "Writing, printing and A4 copy paper", "grades": ["Copy paper", "Writing and printing"], "capacity": {"value": 21000, "unit": "metric_t", "year": "75 t/day (2025-26), 150 t/day planned", "source": "IME Group, Clickmandu 2026-09"}, "filler": [{"supplier": "In-house PCC plant", "type": "PCC plant inside the mill", "status": "Reported at opening 2025-03", "basis": "Press - capacity, designer and operator unknown"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate printing-paper capacity, not orders. Recycled or agro fibre - FCC effect must be proven on the machine."}, "pitch": "Link FCC to the mill's own PCC plant - cut costly imported fibre", "approach": "Top Nepal account. Ask who built the PCC plant - that supplier may open other countries.", "to_collect": ["PCC / GCC supplier or own plant - who designed and runs it", "Filler loading, ash in recycled fibre, retention", "Fibre cost - imported waste paper and pulp", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Durga Pulp%', '%Quest Infra%Durga%', '%Durga%',
   $pj${"owner": "Quest Infra group", "priority": 2, "products": "Writing, printing, book paper, newsprint", "grades": ["Writing and printing"], "capacity": {"value": 30000, "unit": "metric_t", "year": "100 t/day x 300 days (calculated)", "source": "Quest Infra"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate printing-paper capacity, not orders. Recycled or agro fibre - FCC effect must be proven on the machine."}, "pitch": "Copy and book paper - fibre saving with printability held", "to_collect": ["PCC / GCC supplier or own plant - who designed and runs it", "Filler loading, ash in recycled fibre, retention", "Fibre cost - imported waste paper and pulp", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Reliance Paper%', '%Reliance%Bhairahawa%', '%Reliance%',
   $pj${"owner": "Reliance Group Nepal", "priority": 3, "products": "Kraft paper, writing and printing paper", "grades": ["Writing and printing", "Kraft"], "capacity": {"value": 7500, "unit": "metric_t", "year": "Writing and printing line only", "source": "Company profile"}, "capacity_split": [{"label": "Kraft line", "value_t": 30000}, {"label": "Writing and printing line", "value_t": 7500}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate printing-paper capacity, not orders. Recycled or agro fibre - FCC effect must be proven on the machine."}, "approach": "Start on the printing line - kraft needs strength and drainage held.", "to_collect": ["PCC / GCC supplier or own plant - who designed and runs it", "Filler loading, ash in recycled fibre, retention", "Fibre cost - imported waste paper and pulp", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Everest Paper%', '%Everest Paper Mills%', '%Everest%',
   $pj${"owner": "Everest Group", "priority": 4, "products": "Writing and printing paper (agro fibre)", "grades": ["Writing and printing"], "capacity": {"value": 9000, "unit": "metric_t", "year": "30 t/day x 300 days (calculated)", "source": "Everest Group"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate printing-paper capacity, not orders. Recycled or agro fibre - FCC effect must be proven on the machine."}, "approach": "Agro-fibre sheet - separate trial for drainage and strength.", "to_collect": ["PCC / GCC supplier or own plant - who designed and runs it", "Filler loading, ash in recycled fibre, retention", "Fibre cost - imported waste paper and pulp", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Baba Paper%', '%Baba Paper Mills%', '%Baba%',
   $pj${"owner": "Baba Paper Mills", "products": "Paper (grades to confirm)", "approach": "Confirm capacity and filler supplier.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Bhrikuti%', '%Bhrikuti Pulp%', '%Bhrikuti%',
   $pj${"owner": "Bhrikuti Pulp and Paper", "products": "Formerly writing and printing paper (about 42 t/day)", "approach": "Excluded - closed since 2011.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Nepal Pulp%', '%Nepal Pulp and Paper%', '%Nepal Pulp%'),
  ('%Durga Pulp%', '%Quest Infra%Durga%', '%Durga%'),
  ('%Reliance Paper%', '%Reliance%Bhairahawa%', '%Reliance%'),
  ('%Everest Paper%', '%Everest Paper Mills%', '%Everest%'),
  ('%Baba Paper%', '%Baba Paper Mills%', '%Baba%'),
  ('%Bhrikuti%', '%Bhrikuti Pulp%', '%Bhrikuti%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'nepal_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NP'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'nepal_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Shakti Mineral%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'nepal_update_20261014'
order by 1, 4, 2;
