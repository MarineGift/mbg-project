-- ============================================================
-- fix_mill_supplier_dupe_detect.sql (2026-07-05) -- READ ONLY
-- Duplicate-candidate detection for Paper Mills / Paper Companies /
-- Filler Suppliers, reusing the frame proven by the investor dedupe
-- (fix_investor_dupe_detect_v2.sql -> 31-pair merge v9).
-- Nothing is modified. Export each result set as CSV and send back.
-- NOTE: "각 공장" per-plant standard means same-name rows in different
-- cities can be legitimate -- that is why cities are aggregated below.
-- ============================================================

-- (0) party_type census -- confirm the exact codes present before review
select pt.code, count(*) as parties
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
where p.deleted_at is null
group by pt.code
order by parties desc;

-- (A) EXACT duplicate (normalized name, legal suffixes stripped), grouped
--     per party_type so a mill and its parent company never collide
select party_type, key_name,
       count(*) as copies,
       array_agg(party_name order by created_at) as names,
       array_agg(id order by created_at) as ids,
       array_agg(distinct source) as sources,
       array_agg(distinct nullif(website,'')) filter (where nullif(website,'') is not null) as websites,
       array_agg(distinct nullif(city,''))    filter (where nullif(city,'')    is not null) as cities
from (
  select p.id, p.party_name, p.source, p.created_at, p.website, p.city,
         pt.code as party_type,
         regexp_replace(
           lower(btrim(coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name'))),
           '\s*(,?\s*(inc|llc|l\.?p\.?|ltd|limited|co|corp|corporation|company|gmbh|ag|sa|spa|oy|ab|kk|mill[s]?|paper[s]?|group|holdings?)\.?)+\s*$',
           '', 'g') as key_name
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id
   and pt.code in ('buyer','filler','paper_mill','mill','supplier','paper_company')
  where p.deleted_at is null
) s
group by party_type, key_name
having count(*) > 1
order by copies desc, party_type, key_name;

-- (B) SAME website domain, different rows (per party_type)
select party_type, domain,
       count(*) as copies,
       array_agg(party_name order by created_at) as names,
       array_agg(id order by created_at) as ids,
       array_agg(distinct nullif(city,'')) filter (where nullif(city,'') is not null) as cities
from (
  select p.id, p.party_name, p.created_at, p.city, pt.code as party_type,
         lower(regexp_replace(regexp_replace(coalesce(p.website,''),
           '^https?://(www\.)?', ''), '/.*$', '')) as domain
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id
   and pt.code in ('buyer','filler','paper_mill','mill','supplier','paper_company')
  where p.deleted_at is null and coalesce(p.website,'') <> ''
) s
group by party_type, domain
having count(*) > 1
order by copies desc, party_type, domain;

-- (C) SAME email on the party row, different rows
select email,
       count(*) as copies,
       array_agg(party_name order by created_at) as names,
       array_agg(id order by created_at) as ids,
       array_agg(distinct pt_code) as party_types
from (
  select p.id, p.party_name, p.created_at, lower(btrim(p.email)) as email,
         pt.code as pt_code
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id
   and pt.code in ('buyer','filler','paper_mill','mill','supplier','paper_company')
  where p.deleted_at is null and coalesce(p.email,'') <> ''
) s
group by email
having count(*) > 1
order by copies desc, email;

-- (D) plant_supply_links: duplicated mill<->filler pairs (would collapse
--     automatically on merge, but review first). NOTE the real table is
--     app.plant_supply_links with columns paper_mill_plant_id (NOT NULL) and
--     filler_plant_id (NULLABLE = "mill met, filler undecided"). A NULL
--     filler side is a legitimate state, NOT a dangling row.
select l.paper_mill_plant_id, l.filler_plant_id,
       count(*) as copies,
       array_agg(l.id) as link_ids
from app.plant_supply_links l
group by l.paper_mill_plant_id, l.filler_plant_id
having count(*) > 1
order by copies desc;

-- Dangling links: mill side missing/deleted is always a problem; filler side
-- only when it is set (non-NULL) but points to a missing/deleted party.
select l.id as link_id, l.paper_mill_plant_id, l.filler_plant_id,
       (pm.id is null or pm.deleted_at is not null) as mill_missing,
       (l.filler_plant_id is not null
         and (pf.id is null or pf.deleted_at is not null)) as filler_missing
from app.plant_supply_links l
left join app.parties pm on pm.id = l.paper_mill_plant_id
left join app.parties pf on pf.id = l.filler_plant_id
where pm.id is null or pm.deleted_at is not null
   or (l.filler_plant_id is not null
       and (pf.id is null or pf.deleted_at is not null));
