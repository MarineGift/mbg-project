-- ============================================================
-- SYNC: sector focus -> interest tags (both layers) (2026-07-04)
-- Problem: Sector filter reads investor_sector_focus (normalized) while the
-- TAGS column reads legacy parties.interest_tags (jsonb) -> investors shown
-- under "Advanced Materials" without an advanced_materials tag.
-- Fix: mirror each investor's sector focus into
--   (1) normalized app.investor_interest_tags  AND
--   (2) legacy parties.interest_tags jsonb (so the currently deployed UI is
--       coherent immediately, before the normalized-source UI patch ships).
-- Idempotent; safe to re-run after future sector changes.
-- ============================================================

-- sector code -> tag code mapping
-- (unknown/irrelevant sector codes are simply skipped by the join)
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

-- (1) normalized layer
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select ip.id, it.id, ip.organization_id
from app.investor_sector_focus isf
join app.investor_profile ip on ip.id = isf.investor_profile_id
join app.sectors s on s.id = isf.sector_id
join _sector_tag_map m on m.sector_code = s.code
join app.interest_tags it on it.code = m.tag_code
on conflict do nothing;

-- (2) legacy jsonb layer (append tag string if missing; array-guarded)
update app.parties p
set interest_tags =
      (case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
            then coalesce(p.interest_tags, '[]'::jsonb) else '[]'::jsonb end)
      || to_jsonb(x.tag_code),
    updated_at = now()
from (
  select distinct ip.party_id, m.tag_code
  from app.investor_sector_focus isf
  join app.investor_profile ip on ip.id = isf.investor_profile_id
  join app.sectors s on s.id = isf.sector_id
  join _sector_tag_map m on m.sector_code = s.code
) x
where p.id = x.party_id
  and p.deleted_at is null
  and not (
    (case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
          then coalesce(p.interest_tags, '[]'::jsonb) else '[]'::jsonb end)
    ? x.tag_code
  );

-- (3) verification: Advanced Materials sector investors MISSING the tag
--     (expected: 0 rows in BOTH checks)
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
