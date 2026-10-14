-- ============================================================
-- fix_20261014e_jp_missing_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- The two JP mills that 20261014d reported MISSING:
--   Mitsubishi Paper Mills - Hachinohe (priority 6)
--   Hokuetsu Corporation - Kishu (context row)
-- Creates each mill row only if no JP mill row matches the town, adds the
-- paper_mill_profile row and the same extra_data.plant block as 20261014d.
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'JP'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'JP', v.region, v.city, v.website, 'active', 'jp_mill_gap_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Mitsubishi Paper Mills - Hachinohe Mill (Hachinohe)', 'Aomori', 'Hachinohe', '%Hachinohe%', 'https://www.mpm.co.jp', 'Mitsubishi Paper Mills main integrated mill at Hachinohe, Aomori - pulp plus coated and fine printing papers.'),
  ('Hokuetsu Corporation - Kishu Mill (Kishu)', 'Mie', 'Mihama', '%Kishu%', 'https://www.hokuetsucorp.com', 'Hokuetsu Kishu mill in Mie prefecture - copy, colour and information papers.')
) as v(party_name, region, city, name_like, website, notes)
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null and m.country_code = 'JP'
    and m.party_name ilike v.name_like
);

-- ---------- 2) PROFILE + PLANT BLOCK ----------
insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.cat, d.plant ->> 'products', d.hq,
       d.intensity, 'B', 'industry-research', jsonb_build_object('plant', d.plant), now(), now()
from app.parties p
join (values
  ('Mitsubishi Paper Mills - Hachinohe Mill (Hachinohe)', 'Printing and writing', 'Tokyo, Japan', 'high',
   $pj${"owner": "Mitsubishi Paper Mills", "priority": 6, "products": "Fine and coated printing papers", "grades": ["Coated printing", "Fine paper"], "pitch": "Strength, opacity and smoothness together with pulp saving", "approach": "Base-paper trials per grade - thermal and specialty sheets need their own validation.", "recent": [{"date": "2025-12", "text": "Mitsubishi Paper shut a Takasago machine for information base and specialty papers, and a Takasago coater 2025-09 - output consolidated on newer lines"}], "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Mitsubishi Paper integrated report, Newswitch 2024"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('Hokuetsu Corporation - Kishu Mill (Kishu)', 'Printing and writing', 'Tokyo, Japan', 'high',
   $pj${"owner": "Hokuetsu Corporation", "products": "Copy, colour and information papers", "grades": ["Copy paper", "Colour paper"], "approach": "Second Hokuetsu candidate after Niigata.", "checked_at": "2026-10-14"}$pj$::jsonb)
) as d(party_name, cat, hq, intensity, plant)
  on p.party_name = d.party_name
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'JP'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

-- ---------- 3) VERIFY ----------
select p.party_name, p.city,
       case when p.source = 'jp_mill_gap_20261014' then 'added now' else 'already there' end as row_status,
       mp.extra_data #>> '{plant,priority}' as priority,
       case when mp.extra_data #>> '{plant,checked_at}' = '2026-10-14' then 'written' else '-' end as plant_block
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'JP'
  and (p.party_name ilike '%Hachinohe%' or p.party_name ilike '%Kishu%')
order by p.party_name;