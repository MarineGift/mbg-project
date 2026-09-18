-- ============================================================
-- enrich_20260918d_greentown_grid_profiles.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Fourth batch. Source is the Greentown Grid investor profiles, which the
-- investors wrote themselves -- check sizes, stages, fund type, systems,
-- geography and website all come straight from there. That is better data
-- than the third-party databases used in batches 1 to 3.
--
-- Each note records: fund type, stages, check size, geography, systems
-- focus, the Grid match score, and the current Grid status (introduction
-- requested vs not yet contacted), so the pitch decision can be made from
-- the party record without reopening Grid.
--
-- Run after batch 3.
-- ============================================================


-- ------------------------------------------------------------
-- 1) 212 NexT -- BEST FIT FOUND SO FAR
--    Luxembourg-domiciled, founded 2023. Anchor LP Akkok Holding
--    (Istanbul chemicals and composites group). Advanced materials
--    specialist. Check USD 500K-1M, typical 750K.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://212next.fund'),
    city         = coalesce(p.city, 'Luxembourg'),
    region       = null,
    country_code = 'LU',
    founded_year = coalesce(p.founded_year, 2023),
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital, global. Stages pre-seed, seed, Series A, Series B. Check USD 500K-1M, typical 750K. Equity, convertible note, SAFE. Systems: energy and power, infrastructure and construction, manufacturing and processing. Grid match 55 pct, introduction already requested.'
      || ' Vertical deep-tech fund for ADVANCED MATERIALS, domiciled in Luxembourg, established 2023, anchor investor Akkok Next of Akkok Holding, also backed by 212 VC. Stated investment areas: sustainable polymers, biomaterials, composites, advanced chemicals, recycling, AI-driven materials development. Target industries explicitly include chemicals, plastics, PACKAGING, textiles and construction. Akkok owns Aksa Akrilik (largest acrylic fibre producer worldwide), Akkim (chemicals) and Aksa Carbon, and offers pilots, POCs and Turkish market entry.'
      || ' ASSESSMENT: closest thesis match in the whole Greentown set. A filler that replaces virgin pulp in papermaking sits inside their stated scope, and their anchor LP is an industrial chemicals group of the same kind as the licensees MBG already works with.'
where p.deleted_at is null
  and p.party_name = '212 NexT'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 2) LP Capital -- highest Grid match score (72 pct)
--    No website on the Grid profile, no geography specified.
-- ------------------------------------------------------------
update app.parties p
set notes = coalesce(p.notes, '') ||
      ' [Grid profile] Very broad mandate: venture capital, angel, accelerator, corporate CVC, impact, family office, government or sovereign wealth fund, university and startup. Stages pre-seed through growth. Equity, convertible note, SAFE. No geographic focus specified. Systems: food water and land, infrastructure and construction, energy and power, manufacturing and processing, transportation and logistics. Grid match 72 pct, the highest in the set, scoring 100 pct on stage, geography and development stage.'
      || ' No website and no check size on the Grid profile, so the entity behind this record is unclear. Confirm with Will McCallum what LP Capital actually is before acting on the score.'
where p.deleted_at is null
  and p.party_name = 'LP Capital'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 3) The Vyne Group -- raising a USD 120M first fund
--    HQ not stated; Climate Week presence in London, NYC,
--    Singapore and Sydney. Country left empty rather than guessed.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.thevynegroup.com'),
    region       = null,
    country_code = null,
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Accelerator or incubator, venture capital, philanthropic and impact investor. Stages pre-seed, seed, Series A. Check USD 250K-500K. Equity, convertible note, SAFE. Geography global. Systems: food water and land, infrastructure and construction, energy and power, manufacturing and processing, transportation and logistics. Grid match 52 pct, introduction already requested.'
      || ' Assembling an initial USD 120M fund and partnering with Planetary Guardians to launch an accelerator for early-stage climate tech, timed off Climate Week events in London, NYC, Singapore and Sydney. Has innovation partners in Europe and Australasia and is actively seeking North American partnerships. Their message mentions being in Boston and wanting to meet.'
      || ' HQ not stated on the profile; country left blank rather than assumed. TIME-SENSITIVE: they proposed meeting in Boston.'
where p.deleted_at is null
  and p.party_name = 'The Vyne Group'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 4) One World Investments -- family office, impact only
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://oneworld.investments'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Family office. Stages pre-seed and seed. Check USD 50K-250K, typical 100K. Equity, convertible note, SAFE and grants or non-dilutive. United States only. Systems: food water and land, infrastructure and construction, energy and power. Grid match 41 pct, introduction already requested.'
      || ' Impact investors: they invest only where scaling the company also scales its positive impact, and state that most climate startups meet that bar.'
where p.deleted_at is null
  and p.party_name = 'One World Investments'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 5) Harkavest LLC -- individual angel, small cheques
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.harkador.com'),
    country_code = 'US',
    notes        = coalesce(p.notes, '') ||
      ' [Grid profile] Angel investor. Stages pre-seed and seed. Check USD 0-100K, typical 25K. Equity, convertible note, SAFE. Northeast US specific. Systems: energy and power, infrastructure and construction, manufacturing and processing, transportation and logistics. Grid match 41 pct, introduction already requested.'
      || ' Self-described as investing in three verticals: energy, mobility and the built environment. Individual angel with a typical cheque of USD 25K, so useful as a supporting participant rather than a round driver.'
where p.deleted_at is null
  and p.party_name = 'Harkavest LLC'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 6) LGO Angels -- MIT LGO alumni group, confirmed
--    Replaces the unconfirmed placeholder note from batch 3.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://www.lgoangels.com'),
    country_code = 'US',
    notes = ' [Grid profile] Angel investor group, not a formal firm: the LGO alumni network invests as a group and is represented by a scout who facilitates connections. Stages seed and Series A. Check USD 100K-250K, typical 150K. Equity and convertible note. North America, covering Northeast, South, Midwest and West. Systems: energy and power, food water and land, infrastructure and construction, manufacturing and processing. Grid match 42 pct, introduction already requested.'
      || ' They back early-stage opportunities that ALREADY HAVE AN ESTABLISHED LEAD INVESTOR, and are particularly interested in hardware, operations and supply chain. Sequencing matters: secure a lead first, then bring them in.'
where p.deleted_at is null
  and p.party_name = 'LGO Angels';


-- ------------------------------------------------------------
-- 7) Paragraph -- confirmed non-fit
-- ------------------------------------------------------------
update app.parties p
set website = coalesce(p.website, 'https://paragraph.ventures'),
    notes   = coalesce(p.notes, '') ||
      ' [Grid profile] Accelerator or incubator and venture capital. Stages pre-seed and seed. Check USD 100K-250K. Equity, convertible note, SAFE. No geographic focus. Grid match 48 pct, not yet contacted.'
      || ' Focus is the Future of Work, from compliance to workflows to employee relationships, and they do B2B SOFTWARE ONLY, with most of the fund going to studio services covering software, brand, website and go-to-market. CONFIRMED NON-FIT for a materials licensing company; do not spend time here.'
where p.deleted_at is null
  and p.party_name = 'Paragraph'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 8) Apprentis Ventures -- Grid detail appended to batch 3 note
-- ------------------------------------------------------------
update app.parties p
set notes = coalesce(p.notes, '') ||
      ' [Grid profile] Venture capital. Stages pre-seed and seed. Check USD 100K-250K. Equity, convertible note, SAFE. United States only. Grid match 40 pct, not yet contacted. The Grid wording is narrower than the public profile: AI/ML and cyber solutions to modernize and protect legacy industries. Confirms the software-only read.'
where p.deleted_at is null
  and p.party_name = 'Apprentis Ventures'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 9) BetterWay -- Grid detail appended to batch 1 note
-- ------------------------------------------------------------
update app.parties p
set notes = coalesce(p.notes, '') ||
      ' [Grid profile] Stages pre-seed and seed. Equity, convertible note, SAFE. North America. Systems: food water and land, infrastructure and construction, energy and power, manufacturing and processing, transportation and logistics. Grid match 54 pct, introduction already requested. No check size given on the profile.'
where p.deleted_at is null
  and p.party_name = 'BetterWay Ventures'
  and (p.notes is null or p.notes not like '%[Grid profile]%');


-- ------------------------------------------------------------
-- 10) normalize domains for rows that just received a website
-- ------------------------------------------------------------
update app.parties p
set domain_normalized = app.normalize_domain(p.website)
where p.deleted_at is null
  and p.website is not null
  and p.domain_normalized is null;


-- ------------------------------------------------------------
-- 11) Verification
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.website, '-')      as website,
       coalesce(p.city, '-')         as city,
       coalesce(p.country_code, '-') as country,
       case when p.notes like '%[Grid profile]%' then 'grid'
            when p.notes is not null then 'web'
            else '-' end             as note_source
from app.parties p
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
order by note_source desc, p.party_name;
