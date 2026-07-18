-- ============================================================
-- fix_gulshan_host_links_2026-07-17.sql
--
-- TWO 'active' LINKS. A DIFFERENT ANIMAL FROM THIS MORNING'S EIGHT.
--
-- Artemyn published a map of TOWNS. Every pair off it went in as
-- 'potential' / 'medium' because a shared town is a siting inference.
-- GULSHAN NAMES ITS HOSTS ON ITS OWN SITE. That is a stated relationship, so
-- these are 'active'. The evidence class is the difference, not the company.
--
-- FOUR NAMED HOSTS. THE ROSTER HOLDS TWO.
--
--   ✅ Orient Paper Mills, Amlai MP        -> Orient Paper & Industries Ltd.
--      Gulshan: "This Onsite PCC plant was set up in 2015 at AMLAI, Madhya
--      Pradesh for Orient paper Mills (OPM), a Birla Group Company."
--      Roster: party_name Orient Paper & Industries Ltd., CITY = AMLAI, IN.
--      Name matches, city matches, and the company names the host. confidence
--      HIGH. This is the strongest single pair recorded today, stronger than any
--      of the eight Artemyn ones, and it took one page.
--
--   ✅ ITC Limited, Hooghly                -> ITC PSPD - Tribeni Unit
--      Gulshan: "Set up third On-site PCC plant for ITC Limited at HOOGHLY."
--      Roster: FOUR ITC rows. Bhadrachalam and Bollaram are Telangana, Kovai is
--      Coimbatore in Tamil Nadu, and TRIBENI is the only one in West Bengal -
--      Tribeni sits in Hooghly district. By elimination it is the Hooghly mill.
--      🔴 THAT IS AN IDENTIFICATION, NOT A QUOTE. Gulshan wrote the district and
--      the roster carries the town. confidence MEDIUM for exactly that reason.
--      THIS IS THE ROW THE VERIFY WARNED ABOUT. Picking the first ITC row -
--      Bhadrachalam - would have linked Gulshan to the mill that is ALREADY an
--      Artemyn candidate, in a different state, on a name match. That is the
--      Saica error with better manners, and the city column is the only thing
--      that stopped it.
--
--   ❌ Magnum Papers Ltd.       NOT IN THE ROSTER
--      Gulshan's FIRST on-site plant, the one recorded in the Limca Book of
--      Records 2010, the plant that made Gulshan the first company to do this in
--      India. 888 mill rows and it is not one of them.
--   ❌ Silvertone Pulp & Paper Mill Pvt. Ltd.   NOT IN THE ROSTER
--      Muzaffarnagar UP, 2013, named in full by Gulshan.
--
-- ⭐ AND ONE MORE HOLE THE PROBE FOUND WITHOUT BEING ASKED: TRIDENT IS NOT IN
-- THE ROSTER EITHER. Trident Limited runs large integrated wheat-straw paper at
-- Barnala, Punjab. It is one of India's larger paper businesses. 888 rows, 22 of
-- them Indian, and Trident is absent. India returned 6 of 6 on grade fit this
-- morning and 4 of 7 STRONG on the filler sweep yesterday - it is the sharpest
-- country on the roster and the roster is missing its companies.
-- FOUR named Indian mills probed today, THREE absent. That is not a filler
-- problem. It is a roster problem, and it is bigger than any form.
--
-- ⛔ NOT LINKED, ON PURPOSE: ITC Ltd, TNPL, BILT and Shree Krishna Paper Mills.
-- Gulshan's own page lists them under SUPPLYING PCC, separately from its on-site
-- plants. Merchant supply is not a satellite. The page draws the line and so does
-- this file. ITC appears on BOTH lists - it buys PCC from Gulshan AND hosts a
-- Gulshan plant at Hooghly - and only the Hooghly one is written here.
--
-- ⛔ NOT LINKED: Trident. A March 2026 news aggregator says Gulshan will build an
-- on-site plant at Barnala. It is on no Gulshan page read today, and the mill is
-- not in the roster anyway. It stays an unverified lead in extra_data.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The two pairs Gulshan states and the roster holds ----------
insert into app.party_supply_links
  (organization_id, filler_party_id, mill_party_id,
   link_type, confidence, active_since, product_grade, notes, extra_data)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       g.id,
       v.mill_party_id,
       'active',
       v.confidence,
       v.active_since,
       null,
       v.notes,
       jsonb_build_object(
         'source', 'gulshanindia.com',
         'source_type', 'company site',
         'evidence_class', 'NAMED HOST - the company states who the plant was built for. Not a siting inference.',
         'quote_basis', v.quote_basis,
         'checked_at', '2026-07-17')
from app.parties g
cross join (values
  ('cce0b453-be0d-4ff0-84f9-124277fe5af7'::uuid, 'high', '2015-01-01'::date,
   'Gulshan on-site PCC plant at Orient Paper Mills, Amlai, Madhya Pradesh, 2015. Birla Group. NAMED BY GULSHAN on manufacturing_unit.html and again on milestones.html. The roster row carries city Amlai, so the host name and the location both agree with what the company published. Strongest pair recorded on 2026-07-17 - the eight Artemyn pairs are town-siting inferences and this one is a stated fact.',
   'manufacturing_unit.html - This Onsite PCC plant was set up in 2015 at Amlai, Madhya Pradesh for Orient paper Mills (OPM), a Birla Group Company'),
  ('05ae9f31-a23f-4b12-bf37-9d1403ac201d'::uuid, 'medium', null::date,
   'Gulshan on-site PCC plant for ITC Limited at Hooghly - milestones.html calls it the third on-site PCC plant. 🔴 IDENTIFICATION, NOT A QUOTE: Gulshan wrote the DISTRICT (Hooghly) and this roster carries the TOWN (Tribeni). Tribeni sits in Hooghly district, West Bengal. The other three ITC rows are Bhadrachalam and Bollaram in Telangana and Kovai in Tamil Nadu - none is near Hooghly - so Tribeni is the only candidate. Confidence medium for that gap, not for doubt about the plant. SEPARATELY and do not merge them: ITC also appears on Gulshan merchant supply list, which is a different relationship. ITC Bhadrachalam is an Artemyn candidate and a different mill.',
   'milestones.html - Set up third On-site PCC plant for ITC Limited at Hooghly')
) as v(mill_party_id, confidence, active_since, notes, quote_basis)
where g.party_name ~* '^gulshan'
  and g.party_type_id = 3
  and g.deleted_at is null
  and g.do_not_contact is false
  and exists (select 1 from app.parties m
              where m.id = v.mill_party_id
                and m.party_type_id = 2
                and m.deleted_at is null
                and m.do_not_contact is false)
  and not exists (select 1 from app.party_supply_links s
                  where s.filler_party_id = g.id and s.mill_party_id = v.mill_party_id);


-- ---------- 2) VERIFY - uncommented, on purpose ----------
select fp.party_name as operator,
       mp.party_name as host_mill,
       mp.city,
       mp.country_code,
       s.link_type,
       s.confidence,
       s.active_since,
       s.product_grade,
       s.extra_data ->> 'evidence_class' as evidence_class,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types x
        join app.paper_types pt on pt.id = x.paper_type_id
        where x.mill_party_id = mp.id) as filler_relevance
from app.party_supply_links s
join app.parties fp on fp.id = s.filler_party_id
join app.parties mp on mp.id = s.mill_party_id
where fp.party_name ~* '^gulshan'
order by s.confidence, mp.party_name;

-- EXPECT exactly TWO rows, both link_type 'active', product_grade null.
--   Orient Paper & Industries Ltd.  Amlai    high    filler_relevance high / none
--   ITC PSPD - Tribeni Unit         Tribeni  medium  filler_relevance high / medium
-- Gulshan held ZERO links before this file - block 1 of scan_mill_filler_pairs
-- showed it absent from the holder list entirely.
--
-- ⛔ product_grade MUST read null on both. Gulshan's plants are PCC and its own
-- page says so, which makes 'PCC' tempting and makes it exactly the kind of tidy
-- guess that got market_role believed three times yesterday. The vocabulary of
-- that column has still never been read.
--
-- IF ZERO ROWS: the Gulshan profile row is not named with a leading 'gulshan'.
-- The write in fix_gulshan_footprint reported 4 hosts written against the same
-- pattern an hour ago, so this should not happen - but say so rather than
-- widening the pattern.
--
-- WHAT THIS LEAVES, and it is the last honest item of the day:
--   Magnum Papers Ltd., Silvertone Pulp & Paper Mill and Trident Limited are all
--   real Indian paper companies, all named on a company page or a filing, and
--   NONE of them is in an 888-row mill roster. Three holes found by probing four
--   names. India is the sharpest country on this roster by every measure taken in
--   two days, and the roster does not have its companies. THAT is the next job,
--   and it is not a form sweep.
