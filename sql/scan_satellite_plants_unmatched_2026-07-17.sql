-- ============================================================
-- scan_satellite_plants_unmatched_2026-07-17.sql
--
-- ONE STATEMENT. The inverse of scan_satellite_host_match, and the last piece of
-- the Artemyn thread.
--
-- WHY IT IS A SEPARATE FILE. This query is block 2 of
-- scan_satellite_host_crossmatch and it is UNREACHABLE there - Supabase shows
-- only the last result set of a script, so running that file whole returns block
-- 3 and nothing else. That happened twice today. Rule 2 of the four set today:
-- for a scan file the last statement is THE QUESTION. This file has one.
--
-- WHAT IT ASKS. Eight of Artemyn's seventeen carbonate plants matched a mill on
-- town name plus country. NINE DID NOT:
--   Capitan Bermudez AR · Limeira BR · Pirai BR · Tunadal SE · Amritsar IN ·
--   Bhigwan IN · Silvassa IN · Miyagi JP · Kaohsiung TW
-- EVERY ROW THAT COMES BACK IS ONE OF TWO THINGS AND THEY ARE OPPOSITE:
--   (a) A MILL THIS ROSTER DOES NOT HAVE. Artemyn built a carbonate plant there,
--       so there is a paper mill there. 888 rows and it is missing. A roster hole
--       found with nothing opened.
--   (b) A MERCHANT PLANT THAT IS NOT AT A MILL. Which would mean the satellite
--       read is partly wrong - and Artemyn's own stored record predicted exactly
--       that when it said "confidence: medium - inferred from plant siting, not
--       from a statement that these are satellites."
-- The query cannot tell them apart. A person reading nine town names can.
--
-- 🔴 THREE HYPOTHESES WORTH CHECKING BY NAME, and they are hypotheses:
--   Bhigwan, IN  - fix_bilt_wrong_website, written today, places Sewa, Ballarpur,
--                  BHIGWAN and Ashti under BILT Graphic Paper Products. If the
--                  roster holds that mill under a name without the town in it,
--                  the ilike missed it and the pair is real.
--   Limeira, BR  - block 2 of scan_paper_mill_sweep_worklist put Sylvamo in BR,
--                  SE and US. If a Sylvamo Brazil row exists and is not named for
--                  its town, same miss, same fix.
--   Amritsar / Silvassa, IN - India returned 6 of 6 on grade fit this morning and
--                  every Indian company swept today turned out to already have an
--                  SMI satellite. Two more Indian towns with an Artemyn plant is
--                  not nothing.
-- ⛔ DO NOT WIDEN THE PATTERN TO CHASE THESE. A looser match is how bilt.com
-- became a New York fintech and how Saica's approach nearly went to an Italian
-- competitor. If a town should have matched, find the row by name and say so -
-- it gets its own statement.
--
-- READ-ONLY. Writes nothing.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

with plant as (
  select p.party_name   as operator,
         btrim(t.value) as plant_raw,
         btrim(split_part(t.value, ',', 1))      as town,
         btrim(substring(t.value from '[^,]+$')) as cc
  from app.filler_supplier_profile f
  join app.parties p on p.id = f.party_id and p.deleted_at is null
  cross join lateral jsonb_array_elements_text(
         case when jsonb_typeof(f.extra_data #> '{footprint,calcium_carbonate_plants}') = 'array'
              then f.extra_data #> '{footprint,calcium_carbonate_plants}'
              else '[]'::jsonb end) as t(value)
  where f.deleted_at is null
)
select pl.operator,
       pl.plant_raw,
       pl.town,
       pl.cc as plant_country,
       (select count(*) from app.parties m
        where m.party_type_id = 2 and m.deleted_at is null
          and m.country_code = pl.cc) as mills_in_that_country,
       (select count(*) from app.parties m
        where m.party_type_id = 2 and m.deleted_at is null
          and m.party_name ilike '%' || pl.town || '%') as name_hits_any_country,
       (select string_agg(m.party_name, ' | ')
        from app.parties m
        where m.party_type_id = 2 and m.deleted_at is null
          and m.party_name ilike '%' || pl.town || '%') as name_hits_who
from plant pl
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null
    and m.country_code = pl.cc
    and (m.city ilike pl.town or m.party_name ilike '%' || pl.town || '%'))
order by pl.operator, pl.cc, pl.town;

-- HOW TO READ IT.
--
-- name_hits_any_country > 0 IS THE INTERESTING COLUMN, and it is why this query
-- is not just the previous one with a NOT. It drops the country guard on purpose.
-- A row where the town matches a mill name in a DIFFERENT country is either the
-- country_code being wrong on our row, or a genuine coincidence like Somerset UK
-- against Somerset Maine. Read name_hits_who before deciding which.
--
-- mills_in_that_country = 0 means this roster has NO mills in that country at all.
-- Then the plant is not evidence of a roster hole in that town - it is evidence of
-- a roster hole in that COUNTRY, which is a bigger and cheaper thing to fix.
--
-- ZERO ROWS would mean all seventeen matched, which contradicts the eight that
-- came back an hour ago. If that happens the extra_data path changed - stop.
--
-- WHAT THIS DOES NOT ANSWER, and no query will: whether an Artemyn plant sitting
-- in a town with no mill is a merchant site. That needs one page read. And the
-- highest-value page read is still not this one - it is confirming ONE of the
-- eight pairs already found. Sappi Somerset or Domtar Marlboro. Both US, both
-- high grade, both with an operator whose homepage says its leadership team is
-- ready to talk. One confirmed satellite pair turns a siting inference into a
-- named configuration, and that is worth more than all nine of these.
