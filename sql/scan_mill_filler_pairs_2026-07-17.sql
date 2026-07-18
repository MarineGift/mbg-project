-- ============================================================
-- scan_mill_filler_pairs_2026-07-17.sql
--
-- I PUT A PREDICTION IN A FILE AND THE QUERY KILLED IT. AGAIN.
-- scan_satellite_host_crossmatch block 3 said, in its own comment: "If almost no
-- mill has a filler link, then app.party_supply_links holds a handful of rows and
-- the Hansol-Taekyung pair is nearly the only one."
--     has a filler link   109 mills   52 high grade
--     no filler link      779 mills  135 high grade
-- 109, not a handful. And FIFTY-TWO of them are high-filler grades - 48 percent
-- of the linked set against 17 percent of the unlinked one. The pairs are not a
-- thing to go build. They are already here.
--
-- 🔴 THAT IS FIVE FOR FIVE TODAY, AND THE PATTERN IS MINE, NOT THE DATA'S.
--     cohort 63          -> 757
--     reachable 97.7%    -> ~15%
--     wrong-grade 56     -> at least 306
--     "collapses to dozens" -> 612 brands
--     "a handful of links"  -> 109
-- Every one was a magnitude I asserted before running the query that was already
-- written. Every one was wrong. Four of the five were wrong in the direction that
-- made the plan look tidier. THE RULE THAT FOLLOWS: state what the query will
-- decide, not what it will say.
--
-- ⭐ AND THE PROJECT MAY HAVE BEEN POINTED AT THE WRONG THING ALL DAY.
-- The form sweep is 248 companies whose doors we do not know. Meanwhile 52
-- high-grade mills are ALREADY PAIRED with a named filler supplier in this
-- database. A pair is not a door - it is a commercial relationship that already
-- exists, and for FCC the pair IS the deployment unit: the filler supplier is the
-- licensee, the mill is the customer, and the fence between them is already open.
-- Nobody looked at this table today.
--
-- WHICH PAIRS ARE WARM AND WHICH ARE HOSTILE IS THE WHOLE QUESTION.
-- seed_filler_form_answers recorded why: filler producers are potential licensees
-- AND potential competitors. Omya and Imerys co-own FiberLean. SMI sells FulFill.
-- Taekyung BK co-filed EP4579034 against us and is flagged do_not_contact. A
-- high-grade mill paired with FiberLean's owner is a pair we cannot enter. A
-- high-grade mill paired with Artemyn - target one on the filler list, whose
-- homepage says its leadership team is ready to talk - is a pair we can.
-- Block 2 sorts them.
--
-- READ-ONLY. Writes nothing. Run each block SEPARATELY.
-- Block 0 first. Do NOT filter on link_type until its vocabulary is on screen -
-- that mistake has already been made twice today.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 0) THE VOCABULARY, before any filter ----------
select coalesce(s.link_type, '(null)')  as link_type,
       coalesce(s.confidence, '(null)') as confidence,
       count(*) as links,
       count(distinct s.mill_party_id)   as mills,
       count(distinct s.filler_party_id) as fillers
from app.party_supply_links s
group by 1, 2
order by 3 desc;
-- link_type is what separates an ON-SITE SATELLITE from a merchant supply
-- contract, and the difference is the whole thesis. A satellite means a carbonate
-- plant already stands inside the mill fence - the years-long part is DONE and FCC
-- changes what that plant makes. A merchant link is a purchase order.
-- Read the values. Do not assume 'satellite' is one of them.


-- ---------- 1) ⭐ WHO HOLDS THE 109 - and can we talk to them ----------
select fp.party_name as filler_supplier,
       fp.country_code,
       fp.do_not_contact,
       count(*) as mills_linked,
       count(*) filter (where exists (
         select 1 from app.paper_mill_paper_types lk
         join app.paper_types pt on pt.id = lk.paper_type_id
         where lk.mill_party_id = s.mill_party_id and pt.filler_relevance = 'high')) as high_grade_mills,
       string_agg(distinct coalesce(s.link_type, '(null)'), ' / ') as link_types,
       f.market_role,
       f.mineral_class,
       f.supply_model,
       fp.contact_form_url,
       (select count(*) from app.contacts c
        where c.party_id = fp.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails
from app.party_supply_links s
join app.parties fp on fp.id = s.filler_party_id and fp.deleted_at is null
left join app.filler_supplier_profile f on f.party_id = fp.id and f.deleted_at is null
group by fp.id, fp.party_name, fp.country_code, fp.do_not_contact,
         f.market_role, f.mineral_class, f.supply_model, fp.contact_form_url
order by 5 desc, 4 desc;
-- THE COLUMN TO READ FIRST IS high_grade_mills. Whoever holds the most
-- high-filler mills holds the most of what FCC is for.
-- THE COLUMN TO READ SECOND IS do_not_contact. Taekyung BK must show TRUE - it
-- co-filed EP4579034 and fix_adverse_parties_dnc flagged it. Every mill it holds
-- is a pair we cannot enter, and Hansol Janghang is one of them.
-- ⛔ DO NOT TRUST market_role. It was wrong three times out of three yesterday -
-- Mississippi Lime read "PCC upstream" and runs two PCC plants and a satellite.
-- mineral_class was right three of three and still wrong on Calidra. Both fields
-- are printed here to be COMPARED against link_types, not believed.
-- WATCH FOR: Omya and Imerys co-own FiberLean. SMI sells FulFill. Any high-grade
-- mill they hold is paired with a competing fibre-replacement technology already.
-- That is not a reason to skip the mill - it is a reason to know the incumbent
-- before writing a word to it.


-- ---------- 2) THE 52 - high-grade mills that already have a supplier ----------
select mp.country_code,
       mp.party_name as mill,
       fp.party_name as filler_supplier,
       fp.do_not_contact as supplier_is_adverse,
       s.link_type,
       s.confidence,
       s.active_since,
       (select string_agg(pt.label_en, ' | ' order by pt.label_en)
        from app.paper_mill_paper_types x
        join app.paper_types pt on pt.id = x.paper_type_id
        where x.mill_party_id = mp.id and pt.filler_relevance = 'high') as high_grades,
       mp.contact_form_url,
       (select count(*) from app.contacts c
        where c.party_id = mp.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as mill_emails
from app.party_supply_links s
join app.parties mp on mp.id = s.mill_party_id and mp.deleted_at is null and mp.party_type_id = 2
join app.parties fp on fp.id = s.filler_party_id and fp.deleted_at is null
where exists (
  select 1 from app.paper_mill_paper_types x
  join app.paper_types pt on pt.id = x.paper_type_id
  where x.mill_party_id = mp.id and pt.filler_relevance = 'high')
order by fp.do_not_contact, fp.party_name, mp.country_code, mp.party_name;
-- SEND THIS ONE BACK. It is the shortest list on this roster that is entirely
-- made of things FCC is actually for: a mill making high-filler grades, and a
-- filler producer that already supplies it.
-- Sorted so the adverse suppliers land last. Everything above them is reachable.
-- Hansol Janghang plus Taekyung BK should appear near the bottom - that pair is
-- the perfect configuration and the one we cannot touch.
-- COMPARE against today's work: 248 companies whose doors are unknown, versus
-- this. If this list has fifty usable rows, the form sweep was the second-best
-- use of the day.


-- ---------- 3) THE 135 - high grade, no supplier known ----------
select mp.country_code,
       count(*) as mills,
       count(*) filter (where mp.contact_form_url is not null) as with_form_url,
       count(*) filter (where exists (
         select 1 from app.contacts c where c.party_id = mp.id and c.deleted_at is null
           and nullif(btrim(c.email), '') is not null)) as with_email
from app.parties mp
where mp.party_type_id = 2
  and mp.deleted_at is null
  and exists (select 1 from app.paper_mill_paper_types x
              join app.paper_types pt on pt.id = x.paper_type_id
              where x.mill_party_id = mp.id and pt.filler_relevance = 'high')
  and not exists (select 1 from app.party_supply_links s where s.mill_party_id = mp.id)
group by 1
order by 2 desc;
-- 135 high-grade mills with no known filler supplier. EVERY ONE OF THEM BUYS
-- FILLER FROM SOMEBODY - a mill making high-filler grades without a carbonate
-- supplier does not exist. So this is 135 missing links, not 135 mills without
-- suppliers.
-- The Artemyn cross-match in scan_satellite_host_crossmatch block 1 fills some of
-- these from data already stored, with no homepage opened. Blocks 0, 1 and 2 of
-- that file have still not been run.
