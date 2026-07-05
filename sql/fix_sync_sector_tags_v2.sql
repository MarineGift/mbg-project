-- ============================================================
-- SYNC v2: sector focus -> interest tags, MULTI-TAG SAFE (2026-07-04)
-- Supersedes fix_sync_sector_tags.sql.
-- Bug in v1: UPDATE ... FROM applies only ONE arbitrary matching source row
-- per target -> investors with 2+ mapped sectors got a single tag appended
-- (verification 2026-07-05: normalized layer 0 missing, legacy jsonb layer
-- 17 missing, e.g. Coca-Cola got climate_tech but not advanced_materials).
-- v2 aggregates ALL missing tags per party and appends them in one update.
-- Idempotent; safe to re-run after any sector change.
-- ============================================================

create temporary table if not exists _sector_tag_map (sector_code text, tag_code text);
truncate _sector_tag_map;
insert into _sector_tag_map values
  ('advanced_materials', 'advanced_materials'),
  ('industrial',         'industrial'),
  ('climate',            'climate_tech'),
  ('deep_tech',          'deep_tech'),
  ('life_science',       'life_science'),
  ('healthcare',         'healthcare'),
  ('consumer',           'consumer');

-- (1) normalized layer (already complete per verification; kept for re-runs)
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select ip.id, it.id, ip.organization_id
from app.investor_sector_focus isf
join app.investor_profile ip on ip.id = isf.investor_profile_id
join app.sectors s on s.id = isf.sector_id
join _sector_tag_map m on m.sector_code = s.code
join app.interest_tags it on it.code = m.tag_code
on conflict do nothing;

-- (2) legacy jsonb layer -- aggregate ALL missing tags per party, append once
update app.parties p
set interest_tags =
      (case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
            then coalesce(p.interest_tags, '[]'::jsonb) else '[]'::jsonb end)
      || x.missing_tags,
    updated_at = now()
from (
  select p2.id as party_id,
         jsonb_agg(distinct m.tag_code) as missing_tags
  from app.parties p2
  join app.investor_profile ip on ip.party_id = p2.id
  join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
  join app.sectors s on s.id = isf.sector_id
  join _sector_tag_map m on m.sector_code = s.code
  where p2.deleted_at is null
    and not (
      (case when jsonb_typeof(coalesce(p2.interest_tags, '[]'::jsonb)) = 'array'
            then coalesce(p2.interest_tags, '[]'::jsonb) else '[]'::jsonb end)
      ? m.tag_code
    )
  group by p2.id
) x
where p.id = x.party_id;

-- (3) verification: expected 0 rows in BOTH layers
select p.party_name, 'normalized' as layer
from app.investor_sector_focus isf
join app.investor_profile ip on ip.id = isf.investor_profile_id
join app.sectors s on s.id = isf.sector_id and s.code = 'advanced_materials'
join app.parties p on p.id = ip.party_id and p.deleted_at is null
where not exists (
  select 1 from app.investor_interest_tags iit
  join app.interest_tags it on it.id = iit.interest_tag_id and it.code = 'advanced_materials'
  where iit.investor_profile_id = ip.id)
union all
select p.party_name, 'legacy_jsonb'
from app.investor_sector_focus isf
join app.investor_profile ip on ip.id = isf.investor_profile_id
join app.sectors s on s.id = isf.sector_id and s.code = 'advanced_materials'
join app.parties p on p.id = ip.party_id and p.deleted_at is null
where not (
  (case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
        then coalesce(p.interest_tags, '[]'::jsonb) else '[]'::jsonb end)
  ? 'advanced_materials')
order by layer, party_name;
