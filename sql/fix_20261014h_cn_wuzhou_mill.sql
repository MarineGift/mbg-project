-- ============================================================
-- fix_20261014h_cn_wuzhou_mill.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- 20261014g reported Wuzhou Special Paper MISSING (priority 7).
-- Adds the mill row (HQ and base at Quzhou, Zhejiang - second base at
-- Jiujiang, Jiangxi) if no CN row matches, its paper_mill_profile and the
-- same plant block. Idempotent. Last statement verifies.
-- ============================================================

insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'CN'
                 order by x.created_at limit 1), 1)::smallint,
       'Wuzhou Special Paper (Quzhou)', 'CN', 'Zhejiang', 'Quzhou', null, 'active',
       'china_update_20261014',
       'Zhejiang Wuzhou Special Paper - glassine, digital transfer paper and printing and publishing paper. Bases at Quzhou (Zhejiang) and Jiujiang (Jiangxi).',
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CN'
    and p.party_name ilike '%Wuzhou%Special%'
);

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Specialty / printing',
       'Printing and publishing paper, glassine, digital transfer paper', 'Quzhou, Zhejiang',
       'medium', 'B', 'industry-research',
       jsonb_build_object('plant', $pj${"owner": "Wuzhou Special Paper", "priority": 7, "products": "Printing and publishing paper, glassine, digital transfer paper", "grades": ["Printing and publishing", "Glassine", "Transfer paper"], "capacity": {"value": 300000, "unit": "metric_t", "year": "2025 annual report - printing and publishing lines only", "source": "Wuzhou Special Paper"}, "capacity_split": [{"label": "Glassine", "value_t": 460000}, {"label": "Digital transfer paper", "value_t": 112000}, {"label": "Printing and publishing", "value_t": 300000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on the stated line capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Start on printing and publishing lines - glassine needs density and transparency, a separate test", "approach": "Specialty-paper test partner.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "Wuzhou Special Paper 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb), now(), now()
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CN'
  and p.party_name ilike '%Wuzhou%Special%'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

select p.party_name, p.city,
       case when p.source = 'china_update_20261014' then 'added now' else 'already there' end as row_status,
       mp.extra_data #>> '{plant,priority}' as priority,
       case when mp.extra_data #>> '{plant,checked_at}' = '2026-10-14' then 'written' else '-' end as plant_block
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CN'
  and p.party_name ilike '%Wuzhou%Special%';
