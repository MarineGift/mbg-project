-- ============================================================
-- scan_20261016zz_context_plant_overwrite.sql   (READ ONLY)
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Why: country seeds up to seed_20261016zy (first version) REPLACED the whole
-- paper_mill_profile.extra_data.plant block on "context" rows (existing
-- mills the seed only annotates). If such a row already had a richer plant
-- block (priority, capacity, fcc, grades...) from an older seed or import,
-- those keys were lost. gen.py now merges for context rows.
--
-- This lists mill rows whose current plant block looks like a bare context
-- block (only owner / products / approach / checked_at) on rows that the
-- context seed did NOT create. Rows that never had a plant block also show
-- up - judge by source and created_at.
-- ============================================================
select p.country_code,
       p.party_name,
       coalesce(p.source, '-')                         as row_source,
       p.created_at::date                              as row_created,
       mp.extra_data #>> '{plant,checked_at}'          as plant_checked,
       mp.extra_data #>> '{plant,approach}'            as plant_approach,
       (select string_agg(k, ', ' order by k)
          from jsonb_object_keys(mp.extra_data -> 'plant') k) as plant_keys,
       case when mp.extra_data ? 'plant_history' then 'has history' else '-' end as history,
       p.id
from app.parties p
join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2
  and p.deleted_at is null
  and mp.extra_data ? 'plant'
  and not exists (
        select 1 from jsonb_object_keys(mp.extra_data -> 'plant') k
        where k not in ('owner', 'products', 'approach', 'checked_at'))
  and coalesce(p.source, '') not like '%\_update\_2026101%' escape '\'
order by p.country_code, p.party_name;
