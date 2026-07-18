-- ============================================================
-- scan_satellite_host_match_2026-07-17.sql
--
-- ONE STATEMENT. Nothing else in the file. Run it whole and the answer appears -
-- there is no other result set for Supabase to show instead.
--
-- WHY THIS FILE EXISTS. scan_satellite_host_crossmatch was run twice and both
-- times it returned block 3, the scale check. That is MY design error, not a
-- misrun: Supabase displays only the LAST result set of a script, so a scan with
-- five blocks shows the fifth. I put the payoff in block 1 and a footnote at the
-- end.
-- TODAY'S RULE, CORRECTED. For a FIX file the last statement is the verify. For a
-- SCAN file the last statement is THE QUESTION. Same reason, opposite end of the
-- file, and I had it backwards for five scans today.
--
-- WHAT IT ASKS. artemyn.com's own presence map, stored in
-- filler_supplier_profile.extra_data yesterday, lists 17 calcium carbonate plants
-- by town. The mill roster holds 888 parties whose names carry their town. Match
-- them. Where a carbonate plant and a paper mill share a town, the plant is
-- almost certainly inside the mill.
--
-- ALREADY CONFIRMED BY EYE, so it is the control - if this row does not come
-- back, the query is broken rather than the data:
--     Bennettsville, SC, US  ->  Domtar - Marlboro Mill (Bennettsville, SC)
--
-- ⛔ EVERY ROW IS A CANDIDATE. A town name inside party_name is a STRING MATCH.
-- fix_saica_wrong_contact exists because a string match put an Italian
-- competitor's inbox on a Spanish mill, and bilt.com turned out to be a New York
-- fintech. country_code must agree, which kills Somerset UK against Somerset
-- Maine, and it does not kill everything. Read every row. Do not bulk-write.
-- Artemyn's own record says confidence medium and it was right to.
--
-- link_exists = false on a real pair is a MISSING app.party_supply_links row -
-- the table that already holds Hansol Janghang plus Taekyung BK, the one pair we
-- cannot enter.
--
-- READ-ONLY. Writes nothing.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

with plant as (
  select p.id            as filler_party_id,
         p.party_name    as operator,
         btrim(t.value)  as plant_raw,
         btrim(split_part(t.value, ',', 1))            as town,
         btrim(substring(t.value from '[^,]+$'))       as cc
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
       pl.cc          as plant_country,
       m.party_name   as host_mill_candidate,
       m.country_code,
       m.city,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = m.id) as filler_relevance,
       exists (select 1 from app.party_supply_links s
               where s.mill_party_id = m.id and s.filler_party_id = pl.filler_party_id) as link_exists,
       m.do_not_contact as mill_is_adverse,
       m.id           as mill_party_id
from plant pl
join app.parties m
  on m.party_type_id = 2
 and m.deleted_at is null
 and m.country_code = pl.cc
 and (m.city ilike pl.town or m.party_name ilike '%' || pl.town || '%')
order by pl.operator, pl.plant_raw, m.party_name;

-- HOW TO READ WHAT COMES BACK.
--
-- ✅ A row with link_exists FALSE and filler_relevance carrying 'high' is the
--    prize: a carbonate plant standing inside a mill that makes filler-loaded
--    grades, and this database does not know they are connected. That is a pair,
--    named, with no homepage opened.
--
-- ⚠️ A row with link_exists TRUE means the link is already recorded. Fine - it is
--    the control working.
--
-- ⚠️ mill_is_adverse TRUE stops that row dead. Kleannara, Taekyung Industrial and
--    Taekyung BK were flagged at 03:42 today.
--
-- ❌ ZERO ROWS means one of two things and they are opposite:
--      the extra_data path is wrong - check that
--      filler_supplier_profile.extra_data #> '{footprint,calcium_carbonate_plants}'
--      is an array on the Artemyn row, or
--      no town matches, which would be its own finding.
--    If Bennettsville does not come back, it is the query. That pair is confirmed
--    by eye.
--
-- ❌ A ROW THAT IS OBVIOUSLY WRONG - a town matching a mill in a different
--    industry, or a plant matching six mills - is the string match failing. Say
--    so and the town gets handled by name, not by a looser pattern.
--
-- WHAT IS NOT IN THIS FILE: the inverse. Plants with NO mill in the roster are
-- block 2 of scan_satellite_host_crossmatch, and each one is either a mill this
-- database is missing or proof that Artemyn's plant is a merchant site rather
-- than a satellite. Worth running after this one, on its own, for the same reason
-- this file exists.
