-- ============================================================
-- seed_20261015c_cambodia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Cambodia update (reports 2026-10). LOW PRIORITY. Introduction ->
-- intro_ko / intro_en (only when empty), detail -> notes once with
-- 'KH check 2026-10-15', plant data -> Mill profile card.
--
-- 1) Filler if missing: KPTT-Investment (industrial limestone powder).
--    No paper PCC or GCC plant in Cambodia.
-- 2) Mills if missing + plant blocks: 1 Rongwei (120 kt packaging project,
--    start-up unconfirmed)  2 Sary Paper  3 Dynith (tissue - own machines to
--    confirm). context, match only: CAM Paper Industries.
--    Oji / Harta box plants and Rongxing are converters - not added.
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
       v.party_name, 'KH', v.region, v.city, v.website, 'active', 'cambodia_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('KPTT-Investment', '%KPTT%', 'Phnom Penh', 'Phnom Penh', 'https://www.kptt-investment.com', '2017년 설립 프놈펜의 KPTT-Investment. 석회석 분쇄 탄산칼슘 분말(도료·플라스틱·건축·사료용), OEM.', 'KPTT-Investment (founded 2017), Phnom Penh - ground limestone calcium carbonate powder for paint, plastics, skim coat and feed, custom grades and OEM.', 'KH check 2026-10-15: plant location, capacity, purity, brightness, D50 and wet milling not public - no paper supply found. 116 Street 371, Boeung Tompon 3, Meanchey, +855 85 694 688. No paper PCC or GCC plant in Cambodia. Brenntag Cambodia (distributor) not added. Cement firms in Kampot and Battambang not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%KH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('KPTT-Investment', '%KPTT%', 'Phnom Penh', 'Phnom Penh', 'https://www.kptt-investment.com', '2017년 설립 프놈펜의 KPTT-Investment. 석회석 분쇄 탄산칼슘 분말(도료·플라스틱·건축·사료용), OEM.', 'KPTT-Investment (founded 2017), Phnom Penh - ground limestone calcium carbonate powder for paint, plastics, skim coat and feed, custom grades and OEM.', 'KH check 2026-10-15: plant location, capacity, purity, brightness, D50 and wet milling not public - no paper supply found. 116 Street 371, Boeung Tompon 3, Meanchey, +855 85 694 688. No paper PCC or GCC plant in Cambodia. Brenntag Cambodia (distributor) not added. Cement firms in Kampot and Battambang not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'cambodia_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('KPTT-Investment', 'GCC producer', 'Cambodia limestone powder - paper fit to confirm', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'cambodia_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'KH', v.region, v.city, v.website, 'active', 'cambodia_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Rongwei%', '%Rongwei Industrial%', 'Rongwei Industrial - Packaging Paper Project (Cambodia)', null, null, null, '캄보디아 Rongwei Industrial 의 연 12만 t 포장용지(크라프트라이너·테스트라이너·골심지) 프로젝트. 2025-05 Yunda 원료처리·어프로치 플로 설비 계약.', 'Rongwei Industrial, Cambodia - 120,000 t/yr packaging paper project (kraftliner, testliner, corrugating medium) on OCC and recovered office paper, Yunda stock-preparation and approach-flow contract 2025-05.', 'KH check 2026-10-15: site address, paper-machine supplier, start-up date and 2026 output not public. Reach the mill via Yunda Paper Machinery.'),
  ('%Sary Paper%', '%Champey%', 'Sary Paper Company (Sihanoukville)', 'Preah Sihanouk', 'Sihanoukville', null, '2006년 설립 시아누크빌의 Sary Paper(Champey Tissue). 화장지·미용티슈·핸드타월·냅킨·업소용 롤.', 'Sary Paper Company (founded 2006, Champey Tissue brand), Sihanoukville - toilet and facial tissue, hand towels, napkins, jumbo rolls.', 'KH check 2026-10-15: own tissue machine (Yankee) not confirmed - may convert imported parent rolls. sarypaper@gmail.com, +855 81 733 733.'),
  ('%Dynith%', '%Dynith Manufacturing%', 'Dynith Manufacturing Industrial (Phnom Penh)', 'Phnom Penh', 'Sen Sok', 'https://www.dynithmf.com', '프놈펜 센속의 Dynith Manufacturing Industrial. 미용티슈(Collen·Romdoul·Samnang).', 'Dynith Manufacturing Industrial, Plov Lum, Sen Sok, Phnom Penh - facial tissue (Collen, Romdoul, Samnang brands).', 'KH check 2026-10-15: paper machine and output not public. info@dynithmf.com, +855 88 933 88 99.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%KH check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Rongwei%', '%Rongwei Industrial%', '%Rongwei%', '캄보디아 Rongwei Industrial 의 연 12만 t 포장용지(크라프트라이너·테스트라이너·골심지) 프로젝트. 2025-05 Yunda 원료처리·어프로치 플로 설비 계약.', 'Rongwei Industrial, Cambodia - 120,000 t/yr packaging paper project (kraftliner, testliner, corrugating medium) on OCC and recovered office paper, Yunda stock-preparation and approach-flow contract 2025-05.', 'KH check 2026-10-15: site address, paper-machine supplier, start-up date and 2026 output not public. Reach the mill via Yunda Paper Machinery.'),
  ('%Sary Paper%', '%Champey%', '%Sary%', '2006년 설립 시아누크빌의 Sary Paper(Champey Tissue). 화장지·미용티슈·핸드타월·냅킨·업소용 롤.', 'Sary Paper Company (founded 2006, Champey Tissue brand), Sihanoukville - toilet and facial tissue, hand towels, napkins, jumbo rolls.', 'KH check 2026-10-15: own tissue machine (Yankee) not confirmed - may convert imported parent rolls. sarypaper@gmail.com, +855 81 733 733.'),
  ('%Dynith%', '%Dynith Manufacturing%', '%Dynith%', '프놈펜 센속의 Dynith Manufacturing Industrial. 미용티슈(Collen·Romdoul·Samnang).', 'Dynith Manufacturing Industrial, Plov Lum, Sen Sok, Phnom Penh - facial tissue (Collen, Romdoul, Samnang brands).', 'KH check 2026-10-15: paper machine and output not public. info@dynithmf.com, +855 88 933 88 99.'),
  ('%CAM Paper%', '%CAM Paper Industries%', '%CAM Paper%', '캄보디아 종이 관련 제조기업 CAM Paper Industries — 초지설비 미확인.', 'CAM Paper Industries, Cambodia - listed as paper products or paper mill in directories, machine not confirmed.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'cambodia_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Rongwei%', '%Rongwei Industrial%', '%Rongwei%'),
  ('%Sary Paper%', '%Champey%', '%Sary%'),
  ('%Dynith%', '%Dynith Manufacturing%', '%Dynith%'),
  ('%CAM Paper%', '%CAM Paper Industries%', '%CAM Paper%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Rongwei%', '%Rongwei Industrial%', '%Rongwei%',
   $pj${"owner": "Rongwei Industrial", "priority": 1, "products": "Kraftliner, testliner, corrugating medium (planned)", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "Design (Yunda contract)", "value_t": 120000}], "approach": "Confirm start-up first. Packaging grade - SCT, RCT, CMT must hold - printing-paper results do not transfer.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Sary Paper%', '%Champey%', '%Sary%',
   $pj${"owner": "Sary Paper Company", "priority": 2, "products": "Toilet and facial tissue, towels, napkins", "grades": ["Tissue"], "approach": "Confirm own base-paper making - otherwise trace its parent-roll supplier.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Dynith%', '%Dynith Manufacturing%', '%Dynith%',
   $pj${"owner": "Dynith Manufacturing Industrial", "priority": 3, "products": "Facial tissue", "grades": ["Tissue"], "approach": "Find its base-paper supplier - product test partner if a converter.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%CAM Paper%', '%CAM Paper Industries%', '%CAM Paper%',
   $pj${"owner": "CAM Paper Industries", "products": "To confirm", "approach": "Confirm pulper and paper machine before any estimate.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Rongwei%', '%Rongwei Industrial%', '%Rongwei%'),
  ('%Sary Paper%', '%Champey%', '%Sary%'),
  ('%Dynith%', '%Dynith Manufacturing%', '%Dynith%'),
  ('%CAM Paper%', '%CAM Paper Industries%', '%CAM Paper%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'cambodia_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KH'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'cambodia_update_20261015' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%KPTT%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'cambodia_update_20261015'
order by 1, 4, 2;
