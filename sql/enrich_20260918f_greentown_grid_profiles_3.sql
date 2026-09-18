-- ============================================================
-- enrich_20260918f_greentown_grid_profiles_3.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Final batch: the last four hand-entered greentown rows. All four have
-- Grid investor profiles, which settles the question raised in batches 1
-- to 3 about whether they were investors at all. They are.
--
-- Run after batch 5. After this, no row in the 2026-09-16 to -18 set is
-- left without a note.
-- ============================================================


-- ------------------------------------------------------------
-- 1) HTS/DXS New England -- an individual angel, HVAC background
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.hts.com'),
    region       = null,
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Angel investor. Stages pre-seed, seed, Series A, Series B. Equity only. Check USD 20K-250K, typical 50K. North America, Northeast. Systems: energy and power, infrastructure and construction. Grid match 45 pct. Introduction already requested. Second site listed on the profile: www.dxseng.com.'
      || ' Written by an individual: a mechanical engineer (University of Waterloo, 2011) whose career is commercial HVAC and building sales-engineering teams, focused on high-efficiency HVAC for building decarbonization. States they are NOT solely sector-focused and enjoy helping any business where their expertise applies, ESPECIALLY B2B COMMERCIALIZATION OF ANY SORT, and are interested in businesses targeting reindustrialization.'
      || ' ASSESSMENT: sector overlap is weak but the stated value-add -- B2B commercialization, explicitly sector-agnostic -- is exactly the phase MBG is in. Small cheque, so a supporting participant and an advisor rather than a round driver.'
where p.deleted_at is null
  and p.party_name = 'HTS/DXS New England'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 2) Softeq -- founder of an engineering firm investing, Houston
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://softeq.com'),
    city         = coalesce(p.city, 'Houston'),
    region       = coalesce(p.region, 'Texas'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital and angel investor. Stages pre-seed, seed, Series A. Equity, convertible note, SAFE. No geographic focus. Systems: energy and power, food water and land, transportation and logistics. Grid match 62 pct, 100 pct on stage and geography. No check size given. NOT YET CONTACTED -- the Grid button still reads Connect with Investor.'
      || ' Chris founded Softeq Development in 1997 for technical software development; the firm now covers firmware, hardware and embedded work alongside mobile, web and IoT engineering. Houston-based, so local to Greentown Labs Houston. This is the founder investing, with an engineering services firm attached.'
where p.deleted_at is null
  and p.party_name = 'Softeq'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 3) WGBH / GBH -- Grid match 62 pct, not contacted
-- ------------------------------------------------------------
update app.parties p
set city         = coalesce(p.city, 'Boston'),
    region       = coalesce(p.region, 'Massachusetts'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital and angel investor. Stages pre-seed and seed. Equity, convertible note, SAFE. No geographic focus. Systems: food water and land, infrastructure and construction, energy and power. Grid match 62 pct, 100 pct on stage and geography. No check size given. NOT YET CONTACTED.'
      || ' Registered under the Boston public broadcaster name, so this is almost certainly an individual investing personally rather than the station. Confirm who is behind the entry before reaching out.'
where p.deleted_at is null
  and p.party_name = 'WGBH / GBH'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 4) UMass Amherst / Institute for Applied Life Sciences
--    Non-dilutive only -- grants, not equity.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.umass.edu'),
    city         = coalesce(p.city, 'Amherst'),
    region       = coalesce(p.region, 'Massachusetts'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Philanthropic plus equipment financing and non-dilutive capital, listed as the Institute for Applied Life Sciences. Stages pre-seed and seed. Instrument: GRANTS AND NON-DILUTIVE ONLY -- no equity. No geographic focus. Systems: food water and land, infrastructure and construction, energy and power, manufacturing and processing, transportation and logistics. Grid match 62 pct, 100 pct on stage and geography. NOT YET CONTACTED.'
      || ' A university institute, so the route is grants, facilities access and research collaboration rather than a Seed cheque. Manufacturing and processing is in scope. Worth pursuing on a separate track from the equity round -- non-dilutive capital does not compete with it.'
where p.deleted_at is null
  and p.party_name = 'UMass Amherst'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 5) normalize domains for rows that just received a website
-- ------------------------------------------------------------
update app.parties p
set domain_normalized = app.normalize_domain(p.website)
where p.deleted_at is null
  and p.website is not null
  and p.domain_normalized is null;


-- ------------------------------------------------------------
-- 6) Verification -- nothing should come back EMPTY
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.website, '-')      as website,
       coalesce(p.city, '-')         as city,
       coalesce(p.country_code, '-') as country,
       case when p.notes like '%[Grid profile]%' then 'grid'
            when p.notes is not null then 'web'
            else 'EMPTY' end         as note_source
from app.parties p
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
order by note_source, p.party_name;
