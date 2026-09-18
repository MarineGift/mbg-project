-- ============================================================
-- enrich_20260918_greentown_intro_investors.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Web-researched enrichment for the investor parties created by hand on
-- 2026-09-18 from the Greentown Grid introductions.
--
-- Only 6 of the 18 are covered here -- the ones whose details could be
-- confirmed from more than one public source. Firms still to research are
-- listed at the bottom of this file.
--
-- Every column is written with COALESCE so existing values are never
-- overwritten: this only fills blanks. Re-running changes nothing.
--
-- Website values are only set where an official domain was confirmed. Where
-- it could not be confirmed the column is left alone rather than guessed.
-- ============================================================


-- ------------------------------------------------------------
-- 1) BetterWay Ventures
--    Charleston, SC. Founded 2023. Pre-seed / seed hard tech and green
--    tech. Advanced materials and recycling focus. Portfolio includes
--    DexMat (carbon nanotube materials) and Ravel (textile recycling).
-- ------------------------------------------------------------
update app.parties p
set website       = coalesce(p.website, 'https://betterway.vc'),
    city          = coalesce(p.city, 'Charleston'),
    region        = coalesce(p.region, 'South Carolina'),
    country_code  = coalesce(p.country_code, 'US'),
    founded_year  = coalesce(p.founded_year, 2023),
    notes         = coalesce(p.notes,
      'Boutique VC founded 2023 by Anthony Del Porto. Pre-seed and seed. Hard tech and green tech that reduces environmental footprint. Stated focus areas include advanced materials, recycling, textiles and waste. Portfolio includes DexMat and Ravel.')
where p.deleted_at is null
  and p.party_name = 'BetterWay Ventures';


-- ------------------------------------------------------------
-- 2) Cortado Ventures
--    Oklahoma City, OK. Founded 2020. Seed / early stage, USD 110M+ AUM.
--    Energy, manufacturing, logistics, life sciences. Checks 100K-750K.
--    Website not confirmed from a primary source -- left unset.
-- ------------------------------------------------------------
update app.parties p
set city          = coalesce(p.city, 'Oklahoma City'),
    region        = coalesce(p.region, 'Oklahoma'),
    country_code  = coalesce(p.country_code, 'US'),
    founded_year  = coalesce(p.founded_year, 2020),
    notes         = coalesce(p.notes,
      'Seed-stage VC founded 2020, Oklahoma City. AUM above USD 110M across Fund II (USD 80M) and a USD 10M angel fund. Invests in frontier technology transforming legacy industries: energy, manufacturing, logistics, life sciences. Midcontinent focus (OK, TX, AR, MO, KS, CO, NM). Typical check 100K-750K. Frequently leads seed rounds. Managing partner Nathaniel Harding.')
where p.deleted_at is null
  and p.party_name ilike 'cortado ventures';


-- ------------------------------------------------------------
-- 3) SustainVC
--    Radnor / Philadelphia, PA. Impact VC since 2007 (Patient Capital
--    Collaborative fund series). Early and expansion stage, USD 500K-5M.
-- ------------------------------------------------------------
update app.parties p
set city          = coalesce(p.city, 'Radnor'),
    region        = coalesce(p.region, 'Pennsylvania'),
    country_code  = coalesce(p.country_code, 'US'),
    founded_year  = coalesce(p.founded_year, 2007),
    notes         = coalesce(p.notes,
      'Impact VC manager, Philadelphia region, operating since 2007 through the Patient Capital Collaborative fund series. Early and expansion stage; companies typically seeking USD 500K to 5M. Interest areas include climate and sustainability, equality and empowerment, health and education. Managing principal Tom Balderston. Third fund anchored by the Pennsylvania State Small Business Credit Initiative.')
where p.deleted_at is null
  and p.party_name = 'SustainVC';


-- ------------------------------------------------------------
-- 4) Earth VC (Earth Venture Capital)
--    Ho Chi Minh City, Vietnam. Founded 2021. Pre-seed to Series A,
--    checks around USD 500K-1M. Climate deep tech, new materials.
-- ------------------------------------------------------------
update app.parties p
set website       = coalesce(p.website, 'https://earth.vc'),
    city          = coalesce(p.city, 'Ho Chi Minh City'),
    country_code  = coalesce(p.country_code, 'VN'),
    founded_year  = coalesce(p.founded_year, 2021),
    notes         = coalesce(p.notes,
      'Global climate deep-tech VC founded 2021, based in Ho Chi Minh City, decarbonization focus on Emerging Asia. Pre-seed to Series A, typical check USD 500K-1M, often leads. Sectors include new materials, new energy, industrial decarbonization. Invests into the US, Singapore, UK, Germany and Sweden. Founding partner Tien Nguyen.')
where p.deleted_at is null
  and p.party_name ilike 'earth vc';


-- ------------------------------------------------------------
-- 5) Halcyon Venture Partners
--    Washington, DC. Founded 2024, spun out of the Halcyon incubator.
--    Pre-seed / seed / Series A. Climate, health, equity tech.
--    Website not confirmed from a primary source -- left unset.
-- ------------------------------------------------------------
update app.parties p
set city          = coalesce(p.city, 'Washington'),
    region         = coalesce(p.region, 'District of Columbia'),
    country_code  = coalesce(p.country_code, 'US'),
    founded_year  = coalesce(p.founded_year, 2024),
    notes         = coalesce(p.notes,
      'Seed-stage VC spun out of the Halcyon incubator in 2024, Washington DC. Pre-seed, seed and Series A across three verticals: climate, health and equity tech. Climate scope covers renewable energy, green building technologies and climate data. Woman-led. Founder and managing partner Kate Goodall.')
where p.deleted_at is null
  and p.party_name = 'Halcyon Venture Partners';


-- ------------------------------------------------------------
-- 6) Redstick Ventures
--    Texas. Founded 2022. Pre-seed / seed, checks 350K-700K.
--    FOOD TECH ONLY -- flagged as a likely non-fit for FCC.
-- ------------------------------------------------------------
update app.parties p
set website       = coalesce(p.website, 'https://redstickvc.com'),
    region        = coalesce(p.region, 'Texas'),
    country_code  = coalesce(p.country_code, 'US'),
    founded_year  = coalesce(p.founded_year, 2022),
    notes         = coalesce(p.notes,
      'Early-stage food tech investor founded 2022. Pre-seed and seed across North America, check size USD 350K-700K. Scope is ag tech, food preservation, retail and distribution, restaurant tech and food as medicine. LIKELY NON-FIT for the FCC paper filler thesis; confirm before spending time on it. Public sources disagree on the office location (Lake Dallas TX, Dallas TX, St. Louis MO).')
where p.deleted_at is null
  and p.party_name = 'Redstick Ventures';


-- ------------------------------------------------------------
-- 7) normalize the domain for any row that just received a website
-- ------------------------------------------------------------
update app.parties p
set domain_normalized = app.normalize_domain(p.website)
where p.deleted_at is null
  and p.website is not null
  and p.domain_normalized is null;


-- ------------------------------------------------------------
-- 8) Verification -- the 18 parties created on 2026-09-18
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.website, '-')      as website,
       coalesce(p.city, '-')         as city,
       coalesce(p.region, '-')       as region,
       coalesce(p.country_code, '-') as country,
       coalesce(p.founded_year::text, '-') as founded,
       case when p.notes is null then 'no' else 'yes' end as has_notes
from app.parties p
where p.deleted_at is null
  and p.created_at >= date '2026-09-18'
order by p.party_name;


-- ============================================================
-- STILL TO RESEARCH (12)
--
--   Apprentis Ventures
--   Harkavest LLC
--   Home Technology Ventures
--   LGO Angels
--   One World Investments
--   Paragraph
--   The Vyne Group
--
-- Probably NOT investment firms -- these look like the employer field
-- from a Greentown Grid contact rather than a fund. Confirm what each
-- row is meant to represent before enriching:
--
--   Engelhart Commodities   (commodity trading house)
--   HTS/DXS New England     (HVAC distribution)
--   James Fisher & Sons     (UK marine engineering plc)
--   Shield AI               (defense autonomy company)
--   Personal                (placeholder, not a company)
-- ============================================================
