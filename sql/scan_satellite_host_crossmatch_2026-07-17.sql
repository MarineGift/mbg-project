-- ============================================================
-- scan_satellite_host_crossmatch_2026-07-17.sql
--
-- TWO HALVES OF THIS DATABASE JUST TOUCHED, AND NEITHER KNEW ABOUT THE OTHER.
--
-- YESTERDAY, off artemyn.com's own global presence map, stored in
-- app.filler_supplier_profile.extra_data:
--     "calcium_carbonate_plants": ["Somerset, ME, US", "BENNETTSVILLE, SC, US",
--      "Ledesma, AR", "Capitan Bermudez, AR", "Limeira, BR", "Pirai, BR",
--      "Tunadal, SE", "Husum, SE", "Yueyang, CN", "Amritsar, IN",
--      "Balasore, IN", "Bhadrachalam, IN", "BHIGWAN, IN", "Silvassa, IN",
--      "Miyagi, JP", "Niigata, JP", "Kaohsiung, TW"]
-- and the read recorded alongside it:
--     "claim": "Artemyn is a satellite PCC operator, not only a merchant"
--     "basis": plant siting at paper mill towns
--     "confidence": "MEDIUM - inferred from plant siting, not from a statement
--                    that these are satellites. Confirm per site before relying
--                    on it."
--
-- TODAY, an hour ago, the mill roster answered a completely unrelated question
-- about Domtar and printed:
--     Domtar - Marlboro Mill (BENNETTSVILLE, SC)
--
-- Bennettsville is a South Carolina town of roughly eight thousand people. There
-- is one paper mill in it. ARTEMYN'S CARBONATE PLANT IS INSIDE DOMTAR'S MARLBORO
-- MILL. That is not inference from siting any more - it is two independent
-- sources in this database, gathered on different days for different reasons,
-- landing on the same town.
--
-- AND BHIGWAN. fix_bilt_wrong_website, written today, records that Sewa,
-- Ballarpur, BHIGWAN and Ashti sit under BILT Graphic Paper Products. Artemyn
-- lists a carbonate plant at Bhigwan. Same shape, second hit, found by accident.
--
-- ⭐ WHAT THIS MEANS, AND WHY IT IS BIGGER THAN THE FORM SWEEP.
-- The whole day has been spent asking which door to knock on. THE DEPLOYMENT UNIT
-- FOR FCC IS NOT A COMPANY - IT IS A PAIR. A satellite carbonate plant inside a
-- paper mill is where FCC would physically be made: the operator runs the
-- process, the mill consumes the output over the fence. Hansol Janghang plus
-- Taekyung BK is already that pair, and it is already in app.party_supply_links.
-- Artemyn has SEVENTEEN plants. If they sit inside mills that are already on this
-- 888-row roster, then seventeen more pairs are sitting here NAMED, and nobody
-- has to open a homepage to find them.
--
-- THIS IS A JOIN, NOT A SWEEP. Both sides of it are already in the database.
-- Today's list of 248 companies to visit may be the wrong project entirely.
--
-- READ-ONLY. Writes nothing. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 0) WHO HAS A PLANT FOOTPRINT RECORDED AT ALL ----------
select p.party_name,
       f.market_role,
       f.mineral_class,
       f.supply_model,
       jsonb_typeof(f.extra_data #> '{footprint,calcium_carbonate_plants}') as plants_type,
       coalesce(jsonb_array_length(
         case when jsonb_typeof(f.extra_data #> '{footprint,calcium_carbonate_plants}') = 'array'
              then f.extra_data #> '{footprint,calcium_carbonate_plants}' end), 0) as plants,
       f.extra_data #>> '{satellite_read,confidence}' as satellite_confidence
from app.filler_supplier_profile f
join app.parties p on p.id = f.party_id and p.deleted_at is null
where f.deleted_at is null
  and f.extra_data <> '{}'::jsonb
order by 6 desc, 1;
-- EXPECT Artemyn with 17. Anyone else with a plant array gets cross-matched too -
-- the blocks below are not Artemyn-specific, they read whatever is stored.
-- Yesterday's satellite operator list was Specialty Minerals, Taekyung BK,
-- Double A, Fimatec, Artemyn, Gulshan and Mississippi Lime - seven. If only
-- Artemyn has a footprint array, the other six are worth the same treatment and
-- that is a day of reading, not a day of guessing.


-- ---------- 1) ⭐ THE CROSS-MATCH - which mills host these plants ----------
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
       m.id           as mill_party_id,
       m.country_code,
       m.city,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = m.id) as filler_relevance,
       exists (select 1 from app.party_supply_links s
               where s.mill_party_id = m.id and s.filler_party_id = pl.filler_party_id) as link_exists
from plant pl
join app.parties m
  on m.party_type_id = 2
 and m.deleted_at is null
 and m.country_code = pl.cc
 and (m.city ilike pl.town or m.party_name ilike '%' || pl.town || '%')
order by pl.operator, pl.plant_raw, m.party_name;
-- THE COUNTRY CODE IS THE GUARD. Matching a town name alone would put Somerset UK
-- against Somerset Maine. Requiring country_code to equal the code in the plant
-- string kills most of that. It does NOT kill all of it - read every row before
-- believing it, because a town name inside party_name is a STRING MATCH, and
-- fix_saica_wrong_contact exists because a string match mailed a Spanish mill's
-- approach to an Italian competitor.
-- EXPECT AT MINIMUM: Bennettsville SC -> Domtar - Marlboro Mill. That one is
-- already confirmed by eye.
-- link_exists false on a real pair is a MISSING app.party_supply_links row, and
-- that table is the one that already holds Hansol Janghang plus Taekyung BK.
-- ⛔ THE ROWS THIS RETURNS ARE CANDIDATES, NOT LINKS. Do not write them in bulk.
-- A carbonate plant in a mill town is strong evidence and it is not proof of an
-- on-site satellite - the Artemyn record itself says medium confidence, and it
-- was right to.


-- ---------- 2) THE PLANTS WITH NO MILL IN THE ROSTER ----------
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
select pl.operator, pl.plant_raw, pl.town, pl.cc
from plant pl
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null
    and m.country_code = pl.cc
    and (m.city ilike pl.town or m.party_name ilike '%' || pl.town || '%'))
order by pl.operator, pl.cc, pl.town;
-- EVERY ROW HERE IS ONE OF TWO THINGS AND THEY ARE OPPOSITE.
--   (a) a mill that is MISSING from an 888-row roster - Artemyn built a carbonate
--       plant there, so there is a mill there, and we do not have it. That is a
--       roster hole found without opening anything.
--   (b) a merchant plant that is NOT at a mill - which would mean the satellite
--       read is partly wrong, and the Artemyn record predicted that too.
-- Somerset ME should MATCH something. If it does not, the roster is missing
-- Sappi's Somerset mill, and that is worth knowing on its own.


-- ---------- 3) HOW MANY MILLS CARRY A FILLER LINK AT ALL ----------
select case when exists (select 1 from app.party_supply_links s where s.mill_party_id = m.id)
            then 'has a filler link' else 'no filler link' end as state,
       count(*) as mills,
       count(*) filter (where exists (
         select 1 from app.paper_mill_paper_types mp
         join app.paper_types pt on pt.id = mp.paper_type_id
         where mp.mill_party_id = m.id and pt.filler_relevance = 'high')) as high_grade
from app.parties m
where m.party_type_id = 2 and m.deleted_at is null
group by 1
order by 1;
-- The scale check. If almost no mill has a filler link, then app.party_supply_links
-- holds a handful of rows and the Hansol-Taekyung pair is nearly the only one -
-- and block 1 could multiply that by seventeen in an afternoon, for one operator,
-- with no homepage opened.
-- WHY THIS OUTRANKS THE FORM SWEEP. A form reaches a mill that has no reason to
-- answer. A satellite pair is a mill that already lets a carbonate producer run a
-- plant inside its fence - the hard part, the part that takes years, is DONE. FCC
-- changes what that plant makes. Hansol Janghang plus Taekyung BK is that
-- configuration and it is the one we cannot approach, because Taekyung co-filed
-- EP4579034 against us. Artemyn is target number one on the filler list AND it
-- publicly invites partner approaches - its own homepage says its leadership team
-- is ready to talk. If Artemyn hosts sit on this roster, the pair is reachable
-- from the side we already ranked TOP.
