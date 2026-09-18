-- ============================================================
-- enrich_20260918e_greentown_grid_profiles_2.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Fifth and final batch. Source is the Greentown Grid investor profiles.
--
-- CORRECTION: batches 1 to 3 wrote that several of these rows were "not
-- investors" -- a manufacturer, a broadcaster, a consultancy. That was
-- wrong. Every one of them has a Grid investor profile with a fund type,
-- stages and in most cases a cheque size. Corporate venture arms and
-- individual angels registered under their employer's name look like
-- operating companies from the outside. The notes below replace that
-- judgement.
--
-- Run after batch 4.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Caterpillar -- Grid match 72 pct, joint highest
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.caterpillar.com'),
    city         = coalesce(p.city, 'Irving'),
    region       = coalesce(p.region, 'Texas'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital plus equipment financing and non-dilutive capital. Stages seed, Series A, B and C. Equity, convertible note, SAFE, project finance, venture debt. No geographic focus. Systems: energy and power, manufacturing and processing, transportation and logistics. Grid match 72 pct (strong fit), 100 pct on stage, geography and development stage. Introduction already requested.'
      || ' Corporate venture arm of the equipment manufacturer. Equipment financing and project finance alongside equity is unusual and worth noting: it is a route to non-dilutive capital that does not compete with the Seed equity round.'
where p.deleted_at is null
  and p.party_name ilike 'caterpillar%'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 2) Woodside Energy -- Grid match 72 pct, joint highest
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.woodside.com'),
    city         = coalesce(p.city, 'Perth'),
    region       = null,
    country_code = 'AU',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Very broad mandate: venture capital, angel, accelerator, corporate CVC, impact, family office, government or sovereign wealth fund and private equity. Stages seed, Series A, B, C and growth. Equity, convertible note, SAFE. No geographic focus. Systems: manufacturing and processing, food water and land, transportation and logistics, energy and power. Grid match 72 pct (strong fit). Introduction already requested.'
      || ' Australian energy company; the 2022 merger with BHP petroleum broadened its portfolio across Australia, the Americas, the Caribbean, Senegal and Timor-Leste. Oil and gas operator investing through a corporate vehicle, so the fit rests on decarbonization of industrial processes rather than on papermaking.'
where p.deleted_at is null
  and p.party_name = 'Woodside Energy'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 3) Oxy -- Grid match 66 pct
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.oxy.com'),
    city         = coalesce(p.city, 'Houston'),
    region       = coalesce(p.region, 'Texas'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital and angel investor. Stages seed, Series A and B. Equity, convertible note, SAFE. No geographic focus. Systems: manufacturing and processing ONLY -- the narrowest scope in the set, and it is the one category MBG sits in. Grid match 66 pct (strong fit). Introduction already requested.'
      || ' Occidental Petroleum, headquartered in Houston. Known for carbon capture and low-carbon ventures. Local to Greentown Labs Houston.'
where p.deleted_at is null
  and p.party_name = 'Oxy'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 4) Engelhart Commodities -- an individual angel, Houston
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.ectp.com'),
    city         = coalesce(p.city, 'Houston'),
    region       = coalesce(p.region, 'Texas'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Angel investor, venture capital and energy trader. Stages pre-seed, seed, Series A. Check USD 20K-200K, typical 75K. Global. Systems: energy and power only. Grid match 50 pct. Introduction already requested.'
      || ' The profile is written by an individual, not the firm: a Houston-based energy executive with 25 years in North American power and gas who runs the North America Power and Gas business at Engelhart Commodities, previously at Goldman Sachs, Trafigura and Constellation. Their stated value-add is market structure -- how power is priced, dispatched and contracted -- which is not where MBG needs help. Houston-local, so useful as a network contact.'
where p.deleted_at is null
  and p.party_name = 'Engelhart Commodities'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 5) James Fisher & Sons -- Series A and later only
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.james-fisher.com'),
    region       = null,
    country_code = 'GB',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Corporate CVC. Stages Series A, B and C -- NOT seed. Equity only. Check USD 500K-1M, ticket up to 1.5M. Global. Systems: food water and land, energy and power. Grid match 53 pct, scoring only 60 pct on stage. Introduction already requested.'
      || ' UK marine and engineering services group. Their stated preference is opportunities carrying COMMERCIAL risk at HIGH TRL rather than technological risk at low TRL, which describes MBG accurately -- the technology is validated and a 9,000-ton order is in preparation. The obstacle is stage, not thesis: revisit at Series A rather than for this Seed round.'
where p.deleted_at is null
  and p.party_name = 'James Fisher & Sons'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 6) Shield AI -- an individual angel under the employer name
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://shield.ai'),
    city         = coalesce(p.city, 'San Diego'),
    region       = coalesce(p.region, 'California'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Angel investor and impact investor, tagged climate tech. Stages pre-seed, seed, Series A. Check USD 0-100K. North America. Systems: food water and land, infrastructure and construction, energy and power, manufacturing and processing, transportation and logistics. Grid match 44 pct. Introduction already requested.'
      || ' Registered under the employer name; Shield AI itself is a defense autonomy company, so this is an individual investing personally rather than a corporate fund. Small cheque, supporting participant at most.'
where p.deleted_at is null
  and p.party_name = 'Shield AI'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 7) Dresdner Group Consulting -- Grid match 66 pct, Series A+
-- ------------------------------------------------------------
update app.parties p
set website = coalesce(p.website, 'https://dresdnergroup.com'),
    notes   = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital, angel, private equity, corporate CVC, family office and government or sovereign wealth fund. Stages Series A, B and C -- NOT seed. Equity only. No geographic focus. Systems: energy and power, manufacturing and processing. Grid match 66 pct (strong fit) but only 60 pct on stage. Not yet contacted.'
      || ' Manufacturing and processing is in scope and the score is high, but the stage does not match a Seed round. Park for Series A.'
where p.deleted_at is null
  and p.party_name = 'Dresdner Group Consulting'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 8) Africa Climate Accelerator -- Grid match 62 pct, not contacted
-- ------------------------------------------------------------
update app.parties p
set notes = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital and angel investor. Stages pre-seed and seed. Equity, convertible note, SAFE. No geographic focus specified. Systems: energy and power, food water and land, transportation and logistics. Grid match 62 pct, 100 pct on stage and geography. No website on the profile. NOT YET CONTACTED -- the Grid button still reads Connect with Investor.'
where p.deleted_at is null
  and p.party_name = 'Africa Climate Accelerator'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 9) Baltimore Aircoil Company -- grants only, pre-seed only
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://baltimoreaircoil.com'),
    city         = coalesce(p.city, 'Jessup'),
    region       = coalesce(p.region, 'Maryland'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Philanthropic plus equipment financing and non-dilutive capital. Stage pre-seed only. Instrument: grants and non-dilutive only -- no equity. Systems: infrastructure and construction, manufacturing and processing, food water and land. Grid match 62 pct. Not yet contacted.'
      || ' Manufacturer of cooling towers, evaporative condensers and immersion coolers. Not a Seed equity source, but a possible non-dilutive route. Worth a look only once the equity round is settled.'
where p.deleted_at is null
  and p.party_name = 'Baltimore Aircoil'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 10) Next Act Advisors -- Grid match 61 pct, not contacted
-- ------------------------------------------------------------
update app.parties p
set website = coalesce(p.website, 'https://nextactadvisors.com'),
    notes   = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital, angel, accelerator, corporate CVC, impact, family office and government or sovereign wealth fund. Stages pre-seed and seed. Equity, convertible note, SAFE. No geographic focus. Systems: energy and power, food water and land. Grid match 61 pct, 100 pct on stage and geography. No check size given. Not yet contacted.'
where p.deleted_at is null
  and p.party_name = 'Next Act Advisors'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 11) FinancExecutives -- Grid match 61 pct, not contacted
-- ------------------------------------------------------------
update app.parties p
set website = coalesce(p.website, 'https://financexecutives.com'),
    notes   = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital, angel investor and accelerator or incubator. Stages pre-seed and seed. Equity, convertible note, SAFE. No geographic focus. Systems: food water and land, infrastructure and construction, energy and power, transportation and logistics. Grid match 61 pct, 100 pct on stage and geography. No check size given. Not yet contacted.'
where p.deleted_at is null
  and p.party_name = 'FinancExecutives'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 12) Personal -- an individual angel, clean energy hardware
--     The row name is the Grid placeholder; rename only if the
--     individual's name becomes known.
-- ------------------------------------------------------------
update app.parties p
set region = null,
    notes  = coalesce(p.notes, '') ||
      ' [Grid profile] Individual angel investor and industry expert. Stages pre-seed to seed. Check USD 100K-500K per deal (the Grid summary shows 250K-500K). Global. No systems specified. Grid match 46 pct. Introduction already requested.'
      || ' Focus is the hardware-software nexus of CLEAN ENERGY: EV charging and power modules, commercial and residential battery storage, microgrids and distributed energy, PV optimization, hydrogen electrolyzers. Most comfortable at prototype or pilot TRL where technical risk is understood and scaling is the challenge. Built and exited a power electronics firm to ABB; offers mentorship on supply chain localization and R and D team scaling. Open to syndicates and occasionally leads pre-seed rounds for high-conviction hardware.'
      || ' NON-FIT on sector: the stated scope is energy hardware, not materials. The row name is a Grid placeholder, not a company; rename it once the individual is identified.'
where p.deleted_at is null
  and p.party_name = 'Personal'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 13) normalize domains for rows that just received a website
-- ------------------------------------------------------------
update app.parties p
set domain_normalized = app.normalize_domain(p.website)
where p.deleted_at is null
  and p.website is not null
  and p.domain_normalized is null;


-- ------------------------------------------------------------
-- 14) Verification -- anything still without a Grid note
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
