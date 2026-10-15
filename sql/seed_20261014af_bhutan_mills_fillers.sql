-- ============================================================
-- seed_20261014af_bhutan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bhutan update (reports 2026-10). LOW PRIORITY. Introduction -> intro_ko /
-- intro_en (only when empty), detail -> notes once with
-- 'BT check 2026-10-14', plant data -> Mill profile card.
--
-- 1) Fillers if missing: Nortak, RSA Limestone Unit, Jigme Flux (Lhaki).
--    No paper-grade PCC or GCC producer in Bhutan.
-- 2) Mill if missing + plant block: Eco-Tech Bhutan (recycled kraft
--    50 t/day, short of waste paper). Handmade-paper makers (Jungshi,
--    Tagma, Mangala) not added - no filler use.
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
       v.party_name, 'BT', v.region, v.city, v.website, 'active', 'bhutan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Nortak Mines & Minerals', '%Nortak%', null, null, null, '부탄 석회석·대리석 채굴·분쇄 기업 Nortak Mines & Minerals. 240·300 mesh 석회석 분말 인도 수출, Gidaphug Top Marble Mine 운영.', 'Nortak Mines and Minerals, Bhutan - limestone and marble quarrying and grinding, 240 and 300 mesh limestone powder exported to India, operator of Gidaphug Top Marble Mine (JICA survey).', 'BT check 2026-10-14: about 1,400 export shipments recorded (Volza), e.g. 34.54 t of 300 mesh in 2025-07. No paper-grade (1-5 um) product, slurry plant or paper customer found. Check CaCO3, MgO, SiO2 and brightness first.'),
  ('RSA Pvt. Ltd. - Limestone Unit', '%RSA%Limestone%', 'Chhukha', 'Phuentsholing', null, '푼촐링의 RSA Pvt. Ltd. 석회석 사업부. 석회석 원석·80/250 mesh 분말·0~1mm 쇄석 수출.', 'RSA Pvt. Ltd. - Limestone Unit, 101 Samdrup Lam, Phuentsholing - limestone lumps, 80 and 250 mesh powder and 0-1 mm crushed limestone, exported to India.', 'BT check 2026-10-14: e.g. 25 t of 250 mesh exported 2025-07. Tel +975-17112220 (company). Raw material and grinding partner only. Tamang Enterprise (dolomite, not CaCO3) and De-Keeling (old listing) not added.'),
  ('Jigme Flux & Refractories (Lhaki Group)', '%Jigme Flux%', null, null, null, 'Lhaki Group 의 Jigme Flux & Refractories. 이탈리아 기술 백운석 소성공장.', 'Jigme Flux and Refractories (Lhaki Group), Bhutan - calcined dolomite plant with Italian technology.', 'BT check 2026-10-14: dolomite contains magnesium - a dolomite kiln is not a high-purity PCC line. Long-term PCC process partner only. No PCC plant found in Bhutan.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%BT check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Nortak Mines & Minerals', '%Nortak%', null, null, null, '부탄 석회석·대리석 채굴·분쇄 기업 Nortak Mines & Minerals. 240·300 mesh 석회석 분말 인도 수출, Gidaphug Top Marble Mine 운영.', 'Nortak Mines and Minerals, Bhutan - limestone and marble quarrying and grinding, 240 and 300 mesh limestone powder exported to India, operator of Gidaphug Top Marble Mine (JICA survey).', 'BT check 2026-10-14: about 1,400 export shipments recorded (Volza), e.g. 34.54 t of 300 mesh in 2025-07. No paper-grade (1-5 um) product, slurry plant or paper customer found. Check CaCO3, MgO, SiO2 and brightness first.'),
  ('RSA Pvt. Ltd. - Limestone Unit', '%RSA%Limestone%', 'Chhukha', 'Phuentsholing', null, '푼촐링의 RSA Pvt. Ltd. 석회석 사업부. 석회석 원석·80/250 mesh 분말·0~1mm 쇄석 수출.', 'RSA Pvt. Ltd. - Limestone Unit, 101 Samdrup Lam, Phuentsholing - limestone lumps, 80 and 250 mesh powder and 0-1 mm crushed limestone, exported to India.', 'BT check 2026-10-14: e.g. 25 t of 250 mesh exported 2025-07. Tel +975-17112220 (company). Raw material and grinding partner only. Tamang Enterprise (dolomite, not CaCO3) and De-Keeling (old listing) not added.'),
  ('Jigme Flux & Refractories (Lhaki Group)', '%Jigme Flux%', null, null, null, 'Lhaki Group 의 Jigme Flux & Refractories. 이탈리아 기술 백운석 소성공장.', 'Jigme Flux and Refractories (Lhaki Group), Bhutan - calcined dolomite plant with Italian technology.', 'BT check 2026-10-14: dolomite contains magnesium - a dolomite kiln is not a high-purity PCC line. Long-term PCC process partner only. No PCC plant found in Bhutan.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'bhutan_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Nortak Mines & Minerals', 'GCC producer', 'Bhutan limestone powder - GCC upgrade candidate', 'merchant', 'C', 'gcc'),
  ('RSA Pvt. Ltd. - Limestone Unit', 'GCC producer', 'Bhutan limestone supply', 'merchant', 'C', 'gcc'),
  ('Jigme Flux & Refractories (Lhaki Group)', 'Lime producer', 'Bhutan calcination know-how', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bhutan_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'BT', v.region, v.city, v.website, 'active', 'bhutan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Eco-Tech Bhutan%', '%Eco Tech Bhutan%', 'Eco-Tech Bhutan Kraft Paper Industry (Jigmeling)', 'Sarpang', 'Jigmeling', null, '사르팡 Jigmeling 산업단지의 Eco-Tech Bhutan Kraft Paper Industry. 부탄 최초 크라프트지 공장, 폐지 재생 크라프트지 50 t/일(확장 구상 100 t/일).', 'Eco-Tech Bhutan Kraft Paper Industry, Jigmeling Industrial Estate, Sarpang (near Gelephu) - Bhutan''s first kraft paper mill, recycled kraft for packaging, 50 t/day (100 t/day expansion idea), about Nu 300m.', 'BT check 2026-10-14: running below capacity - waste paper shortage (Bhutanese waste paper goes to India). Cumulative about 300 t produced, about 250 t exported to India at the time of reporting (BBS). Not the same company as Eco Tech Papers, Kamalpur, Assam (84,000 t/yr).')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BT'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BT check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BT'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Eco-Tech Bhutan%', '%Eco Tech Bhutan%', '%Eco-Tech%', '사르팡 Jigmeling 산업단지의 Eco-Tech Bhutan Kraft Paper Industry. 부탄 최초 크라프트지 공장, 폐지 재생 크라프트지 50 t/일(확장 구상 100 t/일).', 'Eco-Tech Bhutan Kraft Paper Industry, Jigmeling Industrial Estate, Sarpang (near Gelephu) - Bhutan''s first kraft paper mill, recycled kraft for packaging, 50 t/day (100 t/day expansion idea), about Nu 300m.', 'BT check 2026-10-14: running below capacity - waste paper shortage (Bhutanese waste paper goes to India). Cumulative about 300 t produced, about 250 t exported to India at the time of reporting (BBS). Not the same company as Eco Tech Papers, Kamalpur, Assam (84,000 t/yr).')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'bhutan_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BT'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Eco-Tech Bhutan%', '%Eco Tech Bhutan%', '%Eco-Tech%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BT'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Eco-Tech Bhutan%', '%Eco Tech Bhutan%', '%Eco-Tech%',
   $pj${"owner": "Eco-Tech Bhutan Kraft Paper Industry", "priority": 1, "products": "Recycled kraft paper for packaging", "grades": ["Kraft"], "capacity_split": [{"label": "50 t/day x 330 (calculated design)", "value_t": 16500}], "approach": "Low priority - trial candidate only. Recycled kraft needs strength data before any FCC dose. India (Assam, West Bengal) is the bigger nearby market.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Eco-Tech Bhutan%', '%Eco Tech Bhutan%', '%Eco-Tech%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'bhutan_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BT'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'bhutan_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Nortak%' or p.party_name ilike '%RSA%Limestone%' or p.party_name ilike '%Jigme Flux%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'bhutan_update_20261014'
order by 1, 4, 2;
