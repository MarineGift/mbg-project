-- ============================================================
-- enrich_20260918c_greentown_investors_batch3.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Third web-research batch. Run after batch 2.
--
-- Both firms in this batch are confirmed but flagged as thesis non-fits:
-- one backs B2B software, the other backs housing. Neither matches a
-- materials licensing company. Recording that is the point -- it saves the
-- time that would otherwise go into pitching them.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Apprentis Ventures
--    Dover, NH. Founded 2024, Fund I USD 25M. Pre-seed / seed.
--    B2B SOFTWARE for legacy industries -- not a materials investor.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://apprentis.vc'),
    city         = coalesce(p.city, 'Dover'),
    region       = 'New Hampshire',
    country_code = 'US',
    founded_year = coalesce(p.founded_year, 2024),
    notes        = coalesce(p.notes,
      'Early-stage fund founded 2024, Fund I of USD 25M, based in Dover, New Hampshire. Managing partner Holly Neiweem, previously co-founder of Eight Bar Partners. Pre-seed and seed into B2B software founders digitally transforming and protecting legacy industries: construction, insurance, public safety, industrial tech. NOTE: the stated thesis is software applied to physical industries, explicitly not hardware or materials, so a poor match for an FCC licensing pitch.')
where p.deleted_at is null
  and p.party_name = 'Apprentis Ventures';


-- ------------------------------------------------------------
-- 2) Home Technology Ventures
--    Charlotte, NC. Founded 2019 as a Lowe's spinout. Seed only,
--    post-money cap USD 50M. HOUSING sector.
-- ------------------------------------------------------------
update app.parties p
set website      = coalesce(p.website, 'https://htv.vc'),
    city         = coalesce(p.city, 'Charlotte'),
    region       = 'North Carolina',
    country_code = 'US',
    founded_year = coalesce(p.founded_year, 2019),
    notes        = coalesce(p.notes,
      'Seed-stage fund founded 2019 in Charlotte, North Carolina, as a spinout from Lowe''s. Managing partner Christopher Langford. Strict seed focus with a post-money valuation cap of USD 50M, investing across the US and Canada. Scope is the housing sector: home building, transactions, financing, maintenance and consumption, with construction and architecture among its focus areas. NOTE: tangential to FCC at best; the overlap would be building materials, not papermaking.')
where p.deleted_at is null
  and p.party_name = 'Home Technology Ventures';


-- ------------------------------------------------------------
-- 3) LGO Angels -- could not be confirmed
--    Records a question rather than a guess. No website, city or
--    founding year is written, because none was verified.
-- ------------------------------------------------------------
update app.parties p
set notes = coalesce(p.notes,
      'UNCONFIRMED: no public profile found for an investor by this name. The most likely reading is an angel group of MIT Leaders for Global Operations alumni, which would fit the Boston and MIT ecosystem around Greentown Labs, but this was not verified. Ask Will McCallum at Greentown what this entry refers to before spending time on it.')
where p.deleted_at is null
  and p.party_name = 'LGO Angels';


-- ------------------------------------------------------------
-- 4) normalize domains for rows that just received a website
-- ------------------------------------------------------------
update app.parties p
set domain_normalized = app.normalize_domain(p.website)
where p.deleted_at is null
  and p.website is not null
  and p.domain_normalized is null;


-- ------------------------------------------------------------
-- 5) Verification -- what is left without notes
-- ------------------------------------------------------------
select p.party_name,
       coalesce(p.website, '-')      as website,
       coalesce(p.city, '-')         as city,
       coalesce(p.region, '-')       as region,
       coalesce(p.country_code, '-') as country
from app.parties p
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
  and p.notes is null
order by p.party_name;
