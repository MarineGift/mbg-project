-- ============================================================
-- seed_20261014v_afghanistan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Afghanistan update (reports 2026-10). Introduction -> intro_ko /
-- intro_en (only when empty), detail -> notes once with
-- 'AF check 2026-10-14', plant data -> Mill profile card.
--
-- 1) Filler if missing: Afghan Morvarid (Herat marble powder). No PCC maker
--    found. Not added: Natural Stone, Sahil, Mezan Sultani (stone only),
--    Zia Sahak (distributor).
-- 2) Mills if missing + plant blocks: 1 Baheer Group (own paper mill,
--    55 kt stated)  2 Paktia Paper  3 Rahim Gardizi (likely converters -
--    confirm). context: Wazirson (imports PaperOne rolls).
--    No FCC scenarios, no supply links. Long-term market only.
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
       v.party_name, 'AF', v.region, v.city, v.website, 'active', 'afghanistan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Afghan Morvarid Stone Mining', '%Morvarid%', 'Herat', 'Herat', 'https://www.afghanmorvarid.com', '2006년 설립 헤라트의 Afghan Morvarid Stone Mining. 대리석 채굴·가공, 공장 2곳(약 30,000 m2), 백색 대리석 미분말 제품.', 'Afghan Morvarid Stone Mining Company (founded 2006), Herat - marble quarrying and processing, two plants (about 30,000 m2), white marble powder products.', 'AF check 2026-10-14: company states 15,000 t/month marble - stone output, not GCC powder capacity. Paper-grade 1-3 um product, grinding and classifying lines not confirmed. Yasaman 7, Phase 1, Industrial Township, Herat, +93 728 000 030, inquiries@afghanmorvarid.com. Other marble firms (Natural Stone, Sahil, Mezan Sultani) make stone only - not added. No PCC maker found in Afghanistan.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%AF check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Afghan Morvarid Stone Mining', '%Morvarid%', 'Herat', 'Herat', 'https://www.afghanmorvarid.com', '2006년 설립 헤라트의 Afghan Morvarid Stone Mining. 대리석 채굴·가공, 공장 2곳(약 30,000 m2), 백색 대리석 미분말 제품.', 'Afghan Morvarid Stone Mining Company (founded 2006), Herat - marble quarrying and processing, two plants (about 30,000 m2), white marble powder products.', 'AF check 2026-10-14: company states 15,000 t/month marble - stone output, not GCC powder capacity. Paper-grade 1-3 um product, grinding and classifying lines not confirmed. Yasaman 7, Phase 1, Industrial Township, Herat, +93 728 000 030, inquiries@afghanmorvarid.com. Other marble firms (Natural Stone, Sahil, Mezan Sultani) make stone only - not added. No PCC maker found in Afghanistan.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'afghanistan_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Afghan Morvarid Stone Mining', 'GCC producer', 'Afghan marble powder - paper grade to confirm', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'afghanistan_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'AF', v.region, v.city, v.website, 'active', 'afghanistan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Baheer%', '%Baheer Group%', 'Baheer Group - Paper Mill (Kabul)', 'Kabul', 'Pul-e-Charkhi', 'https://www.baheergroup.com', '1997년부터 제지·포장·인쇄 사업을 하는 Baheer Group. 카불 Pul-e-Charkhi 산업단지, 자체 제지공장(A4·원지·티슈·골판지), 2022년 연 5.5만 t 생산능력 발표.', 'Baheer Group (paper, packaging and printing since 1997), Pul-e-Charkhi Industrial Park, Kabul - own paper mill making A4, base paper, tissue and corrugated, 55,000 t/yr capacity announced in 2022.', 'AF check 2026-10-14: first mill 120 t/day and about 200 staff (TOLOnews 2020), collected 15-20 t/day recovered paper and imported the rest. Packaging 300,000-350,000 boxes/day (2022). Executive at a government industry meeting 2026-08. Contact info@baheer.af, +93 78 222 6546.'),
  ('%Paktia Paper%', '%Paktia Paper%', 'Paktia Paper (Paktika)', 'Paktika', null, null, 'A4 복사용지를 생산·수출(중앙아시아·튀르키예)한다고 보도된 Paktia Paper. 실제 초지 여부 미확인.', 'Paktia Paper, reported in Paktika - A4 copy paper, exports to Central Asia and Turkey reported with Baheer. Own paper machine not confirmed.', 'AF check 2026-10-14: Baheer and Paktia exported over 1,800 t in two weeks (TOLOnews). Contact Mahbobullah Mahbob. Expansion phases 2 and 3 mentioned.'),
  ('%Gardizi%', '%Gardezi%', 'Rahim Gardizi Paper Factory (Paktia)', 'Paktia', 'Gardez', null, '팍티아 Gardez 의 Rahim Gardizi Paper Factory. A4 용지 하루 최대 8,000팩, 2023-10 산업통상부 방문.', 'Rahim Gardizi Paper Factory, Gardez, Paktia - A4 paper up to 8,000 packs/day (about 20 t at 80 gsm), visited by the Ministry of Industry and Commerce 2023-10.', 'AF check 2026-10-14: about 30 staff in 2023. Visit photos show sheeting and packing equipment - pulp and paper machine not seen.'),
  ('%Wazirson%', '%Wazirson Paper%', 'Wazirson Paper Industry (Kandahar)', 'Kandahar', 'Kandahar', 'https://www.wazirson.com', '2021년 칸다하르 Shurandam 산업단지에 설립된 Wazirson Paper Industry. A4·A3 복사용지·오프셋지·아트지, 수입 원지 가공 추정.', 'Wazirson Paper Industry (founded 2021), Shurandam Industrial Zone, Kandahar - A4, A3, A5, B5, F4 copy, offset and art paper, most likely converting imported base rolls.', 'AF check 2026-10-14: 2025-02 shipments show PaperOne uncoated copy-paper rolls imported (about 25-26 t per shipment). Contact info@wazirson.com, +93 202222223. Possible distribution partner via its UAE network.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AF'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AF check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AF'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Baheer%', '%Baheer Group%', '%Baheer%', '1997년부터 제지·포장·인쇄 사업을 하는 Baheer Group. 카불 Pul-e-Charkhi 산업단지, 자체 제지공장(A4·원지·티슈·골판지), 2022년 연 5.5만 t 생산능력 발표.', 'Baheer Group (paper, packaging and printing since 1997), Pul-e-Charkhi Industrial Park, Kabul - own paper mill making A4, base paper, tissue and corrugated, 55,000 t/yr capacity announced in 2022.', 'AF check 2026-10-14: first mill 120 t/day and about 200 staff (TOLOnews 2020), collected 15-20 t/day recovered paper and imported the rest. Packaging 300,000-350,000 boxes/day (2022). Executive at a government industry meeting 2026-08. Contact info@baheer.af, +93 78 222 6546.'),
  ('%Paktia Paper%', '%Paktia Paper%', '%Paktia%', 'A4 복사용지를 생산·수출(중앙아시아·튀르키예)한다고 보도된 Paktia Paper. 실제 초지 여부 미확인.', 'Paktia Paper, reported in Paktika - A4 copy paper, exports to Central Asia and Turkey reported with Baheer. Own paper machine not confirmed.', 'AF check 2026-10-14: Baheer and Paktia exported over 1,800 t in two weeks (TOLOnews). Contact Mahbobullah Mahbob. Expansion phases 2 and 3 mentioned.'),
  ('%Gardizi%', '%Gardezi%', '%Gardizi%', '팍티아 Gardez 의 Rahim Gardizi Paper Factory. A4 용지 하루 최대 8,000팩, 2023-10 산업통상부 방문.', 'Rahim Gardizi Paper Factory, Gardez, Paktia - A4 paper up to 8,000 packs/day (about 20 t at 80 gsm), visited by the Ministry of Industry and Commerce 2023-10.', 'AF check 2026-10-14: about 30 staff in 2023. Visit photos show sheeting and packing equipment - pulp and paper machine not seen.'),
  ('%Wazirson%', '%Wazirson Paper%', '%Wazirson%', '2021년 칸다하르 Shurandam 산업단지에 설립된 Wazirson Paper Industry. A4·A3 복사용지·오프셋지·아트지, 수입 원지 가공 추정.', 'Wazirson Paper Industry (founded 2021), Shurandam Industrial Zone, Kandahar - A4, A3, A5, B5, F4 copy, offset and art paper, most likely converting imported base rolls.', 'AF check 2026-10-14: 2025-02 shipments show PaperOne uncoated copy-paper rolls imported (about 25-26 t per shipment). Contact info@wazirson.com, +93 202222223. Possible distribution partner via its UAE network.')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'afghanistan_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AF'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Baheer%', '%Baheer Group%', '%Baheer%'),
  ('%Paktia Paper%', '%Paktia Paper%', '%Paktia%'),
  ('%Gardizi%', '%Gardezi%', '%Gardizi%'),
  ('%Wazirson%', '%Wazirson Paper%', '%Wazirson%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AF'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Baheer%', '%Baheer Group%', '%Baheer%',
   $pj${"owner": "Baheer Group", "priority": 1, "products": "A4 copy (70-80 gsm), base paper, tissue, corrugated packaging", "grades": ["Copy paper", "Base paper", "Tissue", "Corrugated"], "capacity_split": [{"label": "Announced 2022", "value_t": 55000}, {"label": "First mill 120 t/day x 300 days (2020)", "value_t": 36000}], "pitch": "Fibre saving and opacity in A4 - imported pulp is costly", "approach": "Only Afghan mill with a stated own paper machine. Confirm real output per grade and whether tissue and A4 use own base paper.", "to_collect": ["Machines actually making paper (not only sheeting and packing)", "Output per grade and utilization", "Virgin pulp versus recovered paper share", "Current filler (PCC / GCC) use and supplier", "Who approves a machine trial"], "sources": [{"label": "Pajhwok 2022, TOLOnews 2020"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Paktia Paper%', '%Paktia Paper%', '%Paktia%',
   $pj${"owner": "Paktia Paper", "priority": 2, "products": "A4 copy paper", "approach": "Confirm integrated papermaking versus sheeting imported jumbo rolls - a converter cannot use FCC.", "to_collect": ["Machines actually making paper (not only sheeting and packing)", "Output per grade and utilization", "Virgin pulp versus recovered paper share", "Current filler (PCC / GCC) use and supplier", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Gardizi%', '%Gardezi%', '%Gardizi%',
   $pj${"owner": "Rahim Gardizi", "priority": 3, "products": "A4 copy paper", "capacity_split": [{"label": "8,000 packs/day x 2.5 kg x 330 days (calculated)", "value_t": 6600}], "approach": "Likely a converter - confirm before treating as an FCC customer.", "to_collect": ["Machines actually making paper (not only sheeting and packing)", "Output per grade and utilization", "Virgin pulp versus recovered paper share", "Current filler (PCC / GCC) use and supplier", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Wazirson%', '%Wazirson Paper%', '%Wazirson%',
   $pj${"owner": "Wazirson Group", "products": "Copy, offset and art paper (sheeted)", "approach": "Not an FCC buyer - converts imported rolls. Possible sales channel only.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Baheer%', '%Baheer Group%', '%Baheer%'),
  ('%Paktia Paper%', '%Paktia Paper%', '%Paktia%'),
  ('%Gardizi%', '%Gardezi%', '%Gardizi%'),
  ('%Wazirson%', '%Wazirson Paper%', '%Wazirson%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'afghanistan_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AF'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'afghanistan_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Morvarid%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'afghanistan_update_20261014'
order by 1, 4, 2;
