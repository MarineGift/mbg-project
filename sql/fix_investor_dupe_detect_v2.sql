-- ============================================================
-- DETECT v2: investor duplicate candidates (2026-07-04) -- READ ONLY
-- Fixes 42803 (party_name not in GROUP BY): every non-aggregated column is
-- now either grouped-on or wrapped in array_agg. Groups on a computed key via
-- a subquery so the key is reusable in SELECT + GROUP BY.
-- Nothing is modified. Export each result set and send back for review.
-- ============================================================

-- (A) EXACT duplicate (normalized name, legal suffixes stripped) -- top confidence
select key_name,
       count(*) as copies,
       array_agg(party_name order by has_profile desc, created_at) as names,
       array_agg(id order by has_profile desc, created_at) as ids,
       array_agg(distinct source) as sources,
       array_agg(distinct nullif(website,'')) filter (where nullif(website,'') is not null) as websites,
       array_agg(distinct nullif(city,''))    filter (where nullif(city,'')    is not null) as cities
from (
  select p.id, p.party_name, p.source, p.created_at, p.website, p.city,
         (ip.id is not null) as has_profile,
         regexp_replace(
           lower(btrim(coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name'))),
           '\s*(,?\s*(inc|llc|l\.?p\.?|ltd|limited|co|corp|corporation|company|ventures?|capital|partners?|management|group|holdings?|fund[s]?)\.?)+\s*$',
           '', 'g') as key_name
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  left join app.investor_profile ip on ip.party_id = p.id
  where p.deleted_at is null
) s
group by key_name
having count(*) > 1
order by copies desc, key_name;

-- (B) SAME website domain, different names
select domain,
       count(*) as copies,
       array_agg(party_name order by has_profile desc, created_at) as names,
       array_agg(id order by has_profile desc, created_at) as ids,
       array_agg(distinct source) as sources
from (
  select p.id, p.party_name, p.source, p.created_at,
         (ip.id is not null) as has_profile,
         lower(regexp_replace(regexp_replace(coalesce(p.website,''),
           '^https?://(www\.)?', ''), '/.*$', '')) as domain
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  left join app.investor_profile ip on ip.party_id = p.id
  where p.deleted_at is null and coalesce(p.website,'') <> ''
) s
group by domain
having count(*) > 1
order by copies desc, domain;

-- (C) SAME email, different names
select email,
       count(*) as copies,
       array_agg(party_name order by has_profile desc, created_at) as names,
       array_agg(id order by has_profile desc, created_at) as ids
from (
  select p.id, p.party_name, p.created_at, lower(btrim(p.email)) as email,
         (ip.id is not null) as has_profile
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  left join app.investor_profile ip on ip.party_id = p.id
  where p.deleted_at is null and coalesce(p.email,'') <> ''
) s
group by email
having count(*) > 1
order by copies desc;

-- (D) SAME base name (also strips roman numerals / trailing fund numbers)
--     REVIEW manually: may be distinct funds (e.g. "X Ventures" vs "X Ventures II").
--     websites/cities columns help decide same-vs-distinct.
select base,
       count(*) as copies,
       array_agg(party_name order by has_profile desc, created_at) as names,
       array_agg(id order by has_profile desc, created_at) as ids,
       array_agg(distinct nullif(website,'')) filter (where nullif(website,'') is not null) as websites,
       array_agg(distinct nullif(city,''))    filter (where nullif(city,'')    is not null) as cities
from (
  select p.id, p.party_name, p.created_at, p.website, p.city,
         (ip.id is not null) as has_profile,
         regexp_replace(
           regexp_replace(
             lower(btrim(coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name'))),
             '\s+(ii|iii|iv|v|vi|vii|viii|ix|x|[0-9]+)\s*$', '', 'g'),
           '\s*(,?\s*(inc|llc|l\.?p\.?|ltd|limited|co|corp|corporation|company|ventures?|capital|partners?|management|group|holdings?|fund[s]?)\.?)+\s*$',
           '', 'g') as base
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  left join app.investor_profile ip on ip.party_id = p.id
  where p.deleted_at is null
) s
where length(base) >= 3
group by base
having count(*) > 1
order by copies desc, base;
