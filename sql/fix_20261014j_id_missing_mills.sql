-- ============================================================
-- fix_20261014j_id_missing_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- 20261014i reported two Indonesian mills MISSING:
--   PT Pura Barutama - Kudus (priority 5)   PT Adiprima Suraprinta - Gresik
-- Adds each mill row if no ID row matches, its paper_mill_profile and the
-- same plant block. Idempotent. Last statement verifies.
-- ============================================================

insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'ID'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'ID', v.region, v.city, v.website, 'active', 'indonesia_update_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('PT Pura Barutama - Kudus Mill (Kudus)', 'Central Java', 'Kudus', 'https://www.puragroup.com', '%Pura%Barutama%', 'Pura Group integrated paper, printing, coating and converting site at Kudus, Central Java - specialty, security, food and cigarette papers.'),
  ('PT Adiprima Suraprinta - Gresik Mill (Gresik)', 'East Java', 'Gresik', 'https://www.adiprima.com', '%Adiprima%', 'Recycled-fibre mill at Gresik, East Java - newsprint, recycled printing and white base paper, three machines.')
) as v(party_name, region, city, website, name_like, notes)
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null and m.country_code = 'ID'
    and m.party_name ilike v.name_like
);

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.cat, d.plant ->> 'products', d.hq,
       d.intensity, 'B', 'industry-research', jsonb_build_object('plant', d.plant), now(), now()
from (values
  ('%Pura%Barutama%', 'Specialty', 'Kudus, Central Java', 'medium',
   $pj${"owner": "Pura Group - PT Pura Barutama", "priority": 5, "products": "Specialty, security, food and cigarette papers - integrated site over 100 ha at Kudus", "grades": ["Specialty", "Security paper"], "pitch": "Bulk, stiffness and smoothness gains in functional papers", "approach": "Security and cigarette papers carry certification - start on general specialty grades.", "sources": [{"label": "puragroup.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Adiprima%', 'Printing and writing / newsprint', 'Gresik, East Java', 'medium',
   $pj${"owner": "PT Adiprima Suraprinta", "products": "Newsprint, recycled printing paper, white base paper - 100 pct recycled fibre", "machines": 3, "capacity_split": [{"label": "Three machines 150 + 220 + 110 t/day, about 168,000 t/yr at 350 days (calculated)", "value_t": 168000}], "approach": "Recycled printing and white base paper only - fibre quality, ash and retention vary.", "checked_at": "2026-10-14"}$pj$::jsonb)
) as d(name_like, cat, hq, intensity, plant)
join app.parties p
  on p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ID'
 and p.party_name ilike d.name_like
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

select p.party_name, p.city,
       case when p.source = 'indonesia_update_20261014' then 'added now' else 'already there' end as row_status,
       mp.extra_data #>> '{plant,priority}' as priority,
       case when mp.extra_data #>> '{plant,checked_at}' = '2026-10-14' then 'written' else '-' end as plant_block
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'ID'
  and (p.party_name ilike '%Pura%Barutama%' or p.party_name ilike '%Adiprima%')
order by p.party_name;
