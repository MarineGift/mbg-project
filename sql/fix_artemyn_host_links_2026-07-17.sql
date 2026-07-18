-- ============================================================
-- fix_artemyn_host_links_2026-07-17.sql
--
-- EIGHT PAIRS, FOUND BY A JOIN, WITH NO HOMEPAGE OPENED.
--
-- Yesterday artemyn.com's own presence map was read and stored in
-- filler_supplier_profile.extra_data. Today the mill roster was queried for
-- unrelated reasons. Matching the two on town name and country returns eight
-- paper mills standing where Artemyn has a calcium carbonate plant. SIX OF THE
-- EIGHT MAKE HIGH-FILLER GRADES. NONE of the eight is in app.party_supply_links.
--
--   Bennettsville, SC, US  ->  Domtar - Marlboro Mill              high
--   Somerset, ME, US       ->  Sappi - Somerset Mill (Skowhegan)   high / medium
--   Bhadrachalam, IN       ->  ITC Paperboards & Specialty Papers  high / medium
--   Niigata, JP            ->  Hokuetsu Corporation                high
--   Ledesma, AR            ->  Ledesma                             high
--   Balasore, IN           ->  Emami Paper Mills Ltd.              high / low / medium
--   Husum, SE              ->  Metsä Board Husum                   low / medium
--   Yueyang, CN            ->  Yueyang Forest & Paper Co.          no grade link
--
-- THE CONTROL PASSED. Bennettsville was matched by eye before the query was
-- written, and the query returned it. That is the only reason the other seven are
-- worth reading rather than re-deriving.
--
-- 🔴 THESE ARE RECORDED AS 'potential', NOT AS FACTS, AND THE DISTINCTION IS THE
-- POINT. The evidence is that a carbonate plant and a paper mill share a town.
-- That is strong - Bennettsville SC has roughly eight thousand people and one
-- paper mill, and Bhadrachalam is a town that exists because of the mill - and it
-- is NOT proof that the plant is inside the fence. Artemyn's own stored record
-- says so: "confidence: medium - inferred from plant siting, not from a statement
-- that these are satellites. Confirm per site before relying on it." That
-- sentence was right yesterday and it is still right.
-- link_type 'potential' and confidence 'medium' is exactly what this is. The
-- vocabulary was read off block 0 of scan_mill_filler_pairs before being used -
-- potential / active / filler_supply / historical, and high / medium - because
-- guessing a vocabulary has already gone wrong twice today.
-- NOTE WHAT THIS ADDS: all 85 existing 'potential' links carry NULL confidence
-- and no stated basis. Somebody guessed and left no reason. These eight are the
-- first potential links in this database that say why they exist.
--
-- ⛔ product_grade IS LEFT NULL. Its vocabulary has never been read. Artemyn's
-- plants are calcium carbonate and it would be easy to write 'PCC' - and easy is
-- how market_role got believed three times yesterday. A merchant GCC plant and an
-- on-site PCC satellite are different animals and the town name does not say
-- which. Leave it empty rather than tidy.
--
-- ⛔ active_since IS LEFT NULL for the same reason. The map has no dates.
--
-- WHY THIS MATTERS MORE THAN ANYTHING ELSE BUILT TODAY. Nine mill homepages were
-- opened to find contact forms, and four forms were built. This one query found
-- eight named pairs with the FILLER COMPANY RANKED FIRST ON THE ROSTER - a
-- company whose own homepage says its leadership team is ready to talk to
-- partners. A satellite pair is a mill that already lets a carbonate producer run
-- a plant inside its fence. The years-long part is done. FCC changes what that
-- plant makes.
-- The one pair with that exact shape already in this database is Hansol Janghang
-- plus Taekyung BK, and it was flagged do_not_contact at 03:42 today because
-- Taekyung co-filed EP4579034. These eight are the same configuration on the
-- reachable side.
--
-- WHAT IS STILL MISSING: nine of Artemyn's seventeen plants matched no mill -
-- Capitan Bermudez AR, Limeira BR, Pirai BR, Tunadal SE, Amritsar IN, Bhigwan IN,
-- Silvassa IN, Miyagi JP, Kaohsiung TW. Each is either a mill this roster does not
-- have or a merchant site that is not a satellite at all. Block 2 of
-- scan_satellite_host_crossmatch asks that and has not been run.
-- Bhigwan is the interesting one - fix_bilt_wrong_website places BILT Graphic
-- Paper Products there, so the roster may hold it under a name the town match
-- missed.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The eight candidate pairs ----------
insert into app.party_supply_links
  (organization_id, filler_party_id, mill_party_id,
   link_type, confidence, product_grade, notes, extra_data)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       a.id,
       v.mill_party_id,
       'potential',
       'medium',
       null,
       'Artemyn calcium carbonate plant at ' || v.plant || '. TOWN MATCH against the mill roster, not a stated relationship. Basis: artemyn.com own global presence map, read 2026-07-16 and stored in filler_supplier_profile.extra_data. Artemyn own record on that read says confidence medium - a siting inference only, with no statement by the company that these are satellites, and it says to confirm per site before relying on it. That caveat carries over here unchanged. ' || v.note,
       jsonb_build_object(
         'source', 'artemyn.com global presence map',
         'source_type', 'marketing',
         'stored_in', 'filler_supplier_profile.extra_data footprint calcium_carbonate_plants',
         'plant', v.plant,
         'matched_on', v.matched_on,
         'method', 'town name plus country_code equality',
         'control', 'Bennettsville SC to Domtar Marlboro Mill, confirmed by eye before the query ran',
         'checked_at', '2026-07-17',
         'confidence_note', 'siting inference only - a shared town is not proof of an on-site satellite')
from app.parties a
cross join (values
  ('39882e3c-84eb-4adb-a42d-289bc93edec1'::uuid, 'Bennettsville, SC, US', 'city',
   'THE CONTROL. Matched by eye before this query existed. Bennettsville is a town of roughly eight thousand with one paper mill. Domtar Marlboro makes high-filler grades and Domtar was swept today - its contact page is an email directory, sixteen addresses, no readable form.'),
  ('bdfcee66-2a8c-4abb-b505-4b3437e124c7'::uuid, 'Somerset, ME, US', 'party_name',
   'MATCHED ON NAME, NOT CITY - the mill city reads Skowhegan, ME and the mill is named for Somerset county. A city-only match would have missed this pair entirely. Sappi Somerset is one of the largest coated fine paper mills in North America.'),
  ('a97bebdc-fc41-42ea-b380-07b262e86971'::uuid, 'Bhadrachalam, IN', 'city',
   'ITC Bhadrachalam. The town exists because of the mill. NOT on the 248-company sweep list and never opened today - India had a seventh major company that the form filter never surfaced.'),
  ('917824a0-3f42-4817-a155-099fbbe26af8'::uuid, 'Niigata, JP', 'city',
   'Hokuetsu, high grade. Japan holds 17 high-grade mills with no filler link at all - the largest untouched pool on the roster, and only one of the 17 has an email.'),
  ('7b8b830e-2959-4298-a758-c8a859d0933c'::uuid, 'Ledesma, AR', 'party_name',
   'Ledesma is both the company name and the plant location string. The mill city reads Libertador General San Martin, Jujuy. Bagasse-based, like TNPL.'),
  ('9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid, 'Balasore, IN', 'city',
   'Emami Paper Mills. Grade link reads high / low / medium, so only part of the site is in the target band.'),
  ('48a8cd1d-029e-487d-a6c9-de8efd07d7cb'::uuid, 'Husum, SE', 'party_name',
   'Metsa Board Husum. Mill city reads Ornskoldsvik. Grade link is low / medium - a board mill, so the pair is real and the FCC fit is weak. Recorded because the link is a fact about who supplies whom, not about our targeting.'),
  ('a1a8ac1b-c0bb-49fc-91d2-f230e8b388b4'::uuid, 'Yueyang, CN', 'city',
   'Yueyang Forest and Paper. NO grade link exists on this mill, so its filler relevance is unknown rather than low - it is one of the 238 rows with no paper_type link at all.')
) as v(mill_party_id, plant, matched_on, note)
where a.party_name = 'Artemyn'
  and a.party_type_id = 3
  and a.deleted_at is null
  and a.do_not_contact is false
  and exists (select 1 from app.parties m
              where m.id = v.mill_party_id
                and m.party_type_id = 2
                and m.deleted_at is null
                and m.do_not_contact is false)
  and not exists (select 1 from app.party_supply_links s
                  where s.filler_party_id = a.id and s.mill_party_id = v.mill_party_id);


-- ---------- 2) VERIFY - uncommented, on purpose ----------
select fp.party_name as operator,
       s.extra_data ->> 'plant' as plant,
       mp.party_name as host_mill,
       mp.country_code,
       s.link_type,
       s.confidence,
       s.product_grade,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types x
        join app.paper_types pt on pt.id = x.paper_type_id
        where x.mill_party_id = mp.id) as filler_relevance,
       mp.do_not_contact as mill_adverse
from app.party_supply_links s
join app.parties fp on fp.id = s.filler_party_id
join app.parties mp on mp.id = s.mill_party_id
where fp.party_name = 'Artemyn'
order by s.link_type, mp.country_code, mp.party_name;

-- EXPECT twelve rows: the EIGHT new 'potential' ones plus the FOUR Artemyn links
-- that already existed - block 1 of scan_mill_filler_pairs showed Artemyn holding
-- 4 mills, 0 of them high grade. Those four are different mills and this file
-- does not touch them. Seeing all twelve together is the point: Artemyn's known
-- footprint in this database just went from four mills with no high-grade fit to
-- twelve with six.
--
-- IF EIGHT DO NOT APPEAR, the filler row is not named exactly 'Artemyn'. Send the
-- name back - the guard is an equality on purpose, because 'artemyn' as a pattern
-- is short enough to catch something else, and bilt.com already taught that
-- lesson today.
--
-- ⛔ product_grade MUST read null on the eight. If it says PCC, someone tidied it.
-- The town name does not say whether the plant is a merchant GCC site or an
-- on-site PCC satellite, and that difference is the entire thesis.
--
-- NEXT, and it is a person's job not a query's: confirm ONE pair per site. Start
-- with Sappi Somerset or Domtar Marlboro - both US, both high grade, both with an
-- operator that publicly invites partner approaches. One confirmed satellite pair
-- is worth more than the other seven combined, because it turns a siting
-- inference into a named configuration.
