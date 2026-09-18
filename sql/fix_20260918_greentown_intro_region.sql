-- ============================================================
-- fix_20260918_greentown_intro_region.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem
--   The New Party form defaults countryCode to 'US' and region to 'Texas'.
--   All 18 parties created by hand on 2026-09-18 kept those defaults, so
--   every row claims Texas -- including Earth VC (Vietnam), Halcyon
--   (Washington DC) and James Fisher & Sons (UK).
--
--   The earlier enrichment file wrapped every column in COALESCE, so it
--   only filled blanks and never corrected these. This file overwrites
--   them on purpose, scoped to those 18 rows only.
--
-- What this does
--   1. Sets the correct region and country for the researched firms.
--   2. Clears the false 'Texas' on the rest. An empty field is better than
--      a wrong one -- it will be filled as each firm is researched.
--   3. Country is left as 'US' on the unresearched rows except where it is
--      known wrong, since most of them are in fact US-based.
--
-- Idempotent. Scoped by created_at >= 2026-09-18, so no other row is
-- touched.
-- ============================================================


-- ------------------------------------------------------------
-- 1) researched firms: correct region + country
-- ------------------------------------------------------------
update app.parties p
set region       = v.region,
    country_code = v.country
from (values
  ('BetterWay Ventures',       'South Carolina',       'US'),
  ('CORTADO VENTURES',         'Oklahoma',             'US'),
  ('SustainVC',                'Pennsylvania',         'US'),
  ('Halcyon Venture Partners', 'District of Columbia', 'US'),
  ('Redstick Ventures',        'Texas',                'US'),
  ('Earth VC',                 null,                   'VN')
) as v(name, region, country)
where p.deleted_at is null
  and p.party_name = v.name
  and (p.region is distinct from v.region
       or p.country_code is distinct from v.country);


-- ------------------------------------------------------------
-- 2) James Fisher & Sons is a UK plc, not a Texas company
-- ------------------------------------------------------------
update app.parties p
set region       = null,
    country_code = 'GB'
where p.deleted_at is null
  and p.party_name = 'James Fisher & Sons'
  and p.country_code is distinct from 'GB';


-- ------------------------------------------------------------
-- 3) clear the false 'Texas' on every other row created that day
-- ------------------------------------------------------------
update app.parties p
set region = null
where p.deleted_at is null
  and p.created_at >= date '2026-09-18'
  and p.region = 'Texas'
  and p.party_name not in ('Redstick Ventures');


-- ------------------------------------------------------------
-- 4) Verification
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.website, '-')            as website,
       coalesce(p.city, '-')               as city,
       coalesce(p.region, '-')             as region,
       coalesce(p.country_code, '-')       as country,
       coalesce(p.founded_year::text, '-') as founded,
       case when p.notes is null then 'no' else 'yes' end as has_notes
from app.parties p
where p.deleted_at is null
  and p.created_at >= date '2026-09-18'
order by p.party_name;
