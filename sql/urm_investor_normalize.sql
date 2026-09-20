-- ############################################################
-- HOW TO RUN: Ctrl+A (SELECT ALL), then Run the WHOLE file.
-- URM investor normalization / repair migration
-- Based on actual schema/reference CSV exported 2026-09-12.
-- Idempotent: safe to re-run.
-- Does NOT delete parties or overwrite descriptive company data.
-- ############################################################

begin;

-- ------------------------------------------------------------
-- 0. Guard rails: verify the reference codes used below exist.
-- ------------------------------------------------------------
do $guard$
begin
  if not exists (select 1 from app.party_types where code = 'investor') then
    raise exception 'Required party_type code investor does not exist';
  end if;

  if not exists (select 1 from app.interest_tags where code = 'greentown_labs') then
    raise exception 'Required interest_tag code greentown_labs does not exist';
  end if;

  if not exists (select 1 from app.sectors where code = 'advanced_materials') then
    raise exception 'Required sector code advanced_materials does not exist';
  end if;

  if not exists (select 1 from app.sectors where code = 'deep_tech') then
    raise exception 'Required sector code deep_tech does not exist';
  end if;

  if not exists (select 1 from app.sectors where code = 'climate') then
    raise exception 'Required sector code climate does not exist';
  end if;

  if not exists (select 1 from app.sectors where code = 'manufacturing') then
    raise exception 'Required sector code manufacturing does not exist';
  end if;

  if not exists (select 1 from app.sectors where code = 'resiliency_adaptation') then
    raise exception 'Required sector code resiliency_adaptation does not exist';
  end if;
end
$guard$;

-- ------------------------------------------------------------
-- 1. Ensure every active investor party has an investor_profile.
--    Actual schema: investor_profile.id has gen_random_uuid().
-- ------------------------------------------------------------
insert into app.investor_profile (
  party_id,
  organization_id,
  priority,
  sector_focus,
  investment_types,
  is_lead_investor,
  is_strategic,
  created_at,
  updated_at
)
select
  p.id,
  p.organization_id,
  'medium',
  '{}'::text[],
  '{}'::text[],
  false,
  false,
  now(),
  now()
from app.parties p
join app.party_types pt
  on pt.id = p.party_type_id
 and pt.code = 'investor'
where p.deleted_at is null
  and not exists (
    select 1
    from app.investor_profile ip
    where ip.party_id = p.id
  );

-- ------------------------------------------------------------
-- 2. Normalize investor_profile.sector_focus -> investor_sector_focus.
--    Only values matching REAL app.sectors.code are linked.
--    Existing links are preserved.
-- ------------------------------------------------------------
insert into app.investor_sector_focus (
  investor_profile_id,
  sector_id,
  organization_id,
  created_at
)
select distinct
  ip.id,
  s.id,
  ip.organization_id,
  now()
from app.investor_profile ip
join app.parties p
  on p.id = ip.party_id
 and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id
 and pt.code = 'investor'
cross join lateral unnest(coalesce(ip.sector_focus, '{}'::text[])) as sf(code)
join app.sectors s
  on s.code = sf.code
where not exists (
  select 1
  from app.investor_sector_focus isf
  where isf.investor_profile_id = ip.id
    and isf.sector_id = s.id
    and isf.organization_id = ip.organization_id
);

-- ------------------------------------------------------------
-- 3. Keep the text[] sector_focus synchronized from normalized links.
--    This only fills an EMPTY sector_focus array; it does not replace
--    existing user-entered text[].
-- ------------------------------------------------------------
update app.investor_profile ip
set
  sector_focus = x.codes,
  updated_at = now()
from (
  select
    isf.investor_profile_id,
    array_agg(distinct s.code order by s.code)::text[] as codes
  from app.investor_sector_focus isf
  join app.sectors s on s.id = isf.sector_id
  group by isf.investor_profile_id
) x
where x.investor_profile_id = ip.id
  and coalesce(cardinality(ip.sector_focus), 0) = 0
  and cardinality(x.codes) > 0;

-- ------------------------------------------------------------
-- 4. Priority rule from the URM handoff:
--    High if investor has any of:
--      advanced_materials, climate, deep_tech,
--      manufacturing, resiliency_adaptation
--
--    IMPORTANT: Apply only to investors already tagged Greentown Labs.
--    This avoids changing unrelated investors in the same DB.
-- ------------------------------------------------------------
update app.investor_profile ip
set
  priority = case
    when exists (
      select 1
      from app.investor_sector_focus isf
      join app.sectors s on s.id = isf.sector_id
      where isf.investor_profile_id = ip.id
        and s.code = any(array[
          'advanced_materials',
          'climate',
          'deep_tech',
          'manufacturing',
          'resiliency_adaptation'
        ]::text[])
    ) then 'high'
    else 'low'
  end,
  updated_at = now()
where exists (
  select 1
  from app.investor_interest_tags iit
  join app.interest_tags it on it.id = iit.interest_tag_id
  where iit.investor_profile_id = ip.id
    and it.code = 'greentown_labs'
);

-- ------------------------------------------------------------
-- 5. Optional repair: ensure Greentown-curated investor relationships
--    also have the normalized Greentown Labs interest tag.
--
--    Uses the relationship table directly so it does not depend on a view.
--    Relationship type per handoff: sources_investor.
-- ------------------------------------------------------------
insert into app.investor_interest_tags (
  investor_profile_id,
  interest_tag_id,
  organization_id,
  created_at
)
select distinct
  ip.id,
  it.id,
  ip.organization_id,
  now()
from app.party_relationships pr
join app.parties gp
  on gp.id = pr.from_party_id
 and gp.deleted_at is null
join app.parties p
  on p.id = pr.to_party_id
 and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id
 and pt.code = 'investor'
join app.investor_profile ip
  on ip.party_id = p.id
join app.interest_tags it
  on it.code = 'greentown_labs'
where pr.relationship_type = 'sources_investor'
  and lower(gp.party_name) like 'greentown labs%'
  and not exists (
    select 1
    from app.investor_interest_tags existing
    where existing.investor_profile_id = ip.id
      and existing.interest_tag_id = it.id
      and existing.organization_id = ip.organization_id
  );

-- ------------------------------------------------------------
-- 6. Repair JSON interest_tags on app.parties for Greentown investors.
--    The canonical normalized table remains investor_interest_tags.
--    We only add the string when missing; existing JSON content is kept.
-- ------------------------------------------------------------
update app.parties p
set
  interest_tags = coalesce(p.interest_tags, '[]'::jsonb) || '["greentown_labs"]'::jsonb,
  updated_at = now()
where p.deleted_at is null
  and exists (
    select 1
    from app.investor_profile ip
    join app.investor_interest_tags iit on iit.investor_profile_id = ip.id
    join app.interest_tags it on it.id = iit.interest_tag_id
    where ip.party_id = p.id
      and it.code = 'greentown_labs'
  )
  and not coalesce(p.interest_tags, '[]'::jsonb) @> '["greentown_labs"]'::jsonb;

commit;

-- PostgREST schema cache refresh (safe even though no schema objects changed).
notify pgrst, 'reload schema';

-- ############################################################
-- VERIFY — copy these result grids if anything looks unexpected.
-- ############################################################

-- A. Counts: active investors and profiles
select
  count(*) filter (where pt.code = 'investor' and p.deleted_at is null) as active_investor_parties,
  count(ip.id) filter (where pt.code = 'investor' and p.deleted_at is null) as investor_profiles
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
left join app.investor_profile ip on ip.party_id = p.id;

-- B. Greentown tagged investor priority distribution
select
  coalesce(ip.priority, '(null)') as priority,
  count(*) as investor_count
from app.investor_profile ip
where exists (
  select 1
  from app.investor_interest_tags iit
  join app.interest_tags it on it.id = iit.interest_tag_id
  where iit.investor_profile_id = ip.id
    and it.code = 'greentown_labs'
)
group by ip.priority
order by ip.priority;

-- C. Sector-link counts by valid sector code
select
  s.code,
  s.label_en,
  count(distinct isf.investor_profile_id) as investor_count
from app.investor_sector_focus isf
join app.sectors s on s.id = isf.sector_id
group by s.id, s.code, s.label_en
order by investor_count desc, s.code;

-- D. Find invalid free-text sector_focus values that cannot map to app.sectors.code
select distinct sf.code as unmapped_sector_focus
from app.investor_profile ip
cross join lateral unnest(coalesce(ip.sector_focus, '{}'::text[])) as sf(code)
left join app.sectors s on s.code = sf.code
where s.id is null
order by sf.code;

-- E. Check Greentown relationship -> tag consistency
select
  count(distinct pr.to_party_id) as greentown_relationship_investors,
  count(distinct case when it.code = 'greentown_labs' then pr.to_party_id end) as tagged_greentown_investors
from app.party_relationships pr
join app.parties gp on gp.id = pr.from_party_id
join app.parties p on p.id = pr.to_party_id
join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
left join app.investor_profile ip on ip.party_id = p.id
left join app.investor_interest_tags iit on iit.investor_profile_id = ip.id
left join app.interest_tags it on it.id = iit.interest_tag_id
where pr.relationship_type = 'sources_investor'
  and lower(gp.party_name) like 'greentown labs%'
  and gp.deleted_at is null
  and p.deleted_at is null;
