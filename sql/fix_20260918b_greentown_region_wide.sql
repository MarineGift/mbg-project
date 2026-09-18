-- ============================================================
-- fix_20260918b_greentown_region_wide.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- SUPERSEDES fix_20260918_greentown_intro_region.sql. Run this one instead;
-- running both is harmless but unnecessary.
-- Run AFTER enrich_20260918_greentown_intro_investors.sql.
--
-- Problem
--   The New Party form defaulted region to 'Texas' (fixed in the app as of
--   commit 33a4738). Every party typed in by hand on 2026-09-16, -17 and
--   -18 kept that default: 20 rows claim Texas while having no city at all,
--   including Africa Climate Accelerator, UMass Amherst and WGBH.
--
--   A real Texas investor almost always has a city recorded alongside, so
--   "region = Texas AND city IS NULL" is a reliable signature for the
--   default having been saved untouched.
--
-- What this does
--   1. Sets the correct region and country for the six researched firms.
--   2. Corrects James Fisher & Sons to the UK.
--   3. Clears the false 'Texas' on every hand-entered greentown row that
--      has no city. An empty field beats a wrong one.
--   4. Soft-deletes one corrupted row whose party_name holds a pasted web
--      page. A clean "Dresdner Group Consulting" row already exists, so no
--      information is lost.
--
-- Idempotent. Scoped to greentown-sourced rows created on or after
-- 2026-09-16, so nothing else in the directory is touched.
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
-- 2) James Fisher & Sons is a UK plc
-- ------------------------------------------------------------
update app.parties p
set region       = null,
    country_code = 'GB'
where p.deleted_at is null
  and p.party_name = 'James Fisher & Sons'
  and p.country_code is distinct from 'GB';


-- ------------------------------------------------------------
-- 3) clear the leftover form default across all three days
--    Signature: region = Texas with no city on a hand-entered
--    greentown row. Redstick Ventures is genuinely Texas and is
--    excluded.
-- ------------------------------------------------------------
update app.parties p
set region = null
where p.deleted_at is null
  and p.region = 'Texas'
  and (p.city is null or btrim(p.city) = '')
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
  and p.party_name <> 'Redstick Ventures';


-- ------------------------------------------------------------
-- 4) soft-delete the corrupted row (a pasted web page as the name)
--    Guarded twice: the name must contain the pasted marker AND a
--    clean row for the same company must already exist.
-- ------------------------------------------------------------
update app.parties p
set deleted_at = now(),
    notes = coalesce(p.notes, '') ||
      ' [removed 2026-09-18: party_name held a pasted web page; the clean Dresdner Group Consulting row supersedes it]'
where p.deleted_at is null
  and p.party_name like 'Back to Investors%'
  and p.party_name like '%dresdnergroup.com%'
  and exists (
    select 1 from app.parties q
    where q.deleted_at is null
      and q.party_name = 'Dresdner Group Consulting'
      and q.organization_id = p.organization_id
  );


-- ------------------------------------------------------------
-- 5) Verification -- anything still carrying the default
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.city, '-')         as city,
       coalesce(p.region, '-')       as region,
       coalesce(p.country_code, '-') as country,
       p.created_at::date            as created
from app.parties p
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
order by p.created_at, p.party_name;
