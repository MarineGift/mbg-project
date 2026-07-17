-- ============================================================
-- fix_mlc_is_a_pcc_producer_2026-07-17.sql
--
-- MISSISSIPPI LIME - STRONG. And this file corrects TWO errors, one in the
-- database and one of mine from an hour ago.
--
-- ------------------------------------------------------------
-- ERROR 1 - THE DATABASE. market_role reads "US lime leader - GCC merchant + PCC
-- upstream (quicklime)". That is half right and the wrong half is load-bearing.
--
-- mlc.com/markets/paper/, their own words:
--   "CalCarb Calcium Carbonate can be used in both paper coating and as a paper
--    filler. MLC Quicklime and Hydrated Lime are essential raw materials used in
--    the PCC manufacturing process. MLC HAS MERCHANT PCC FACILITIES LOCATED AT
--    OUR STE. GENEVIEVE SITE. Precipitated calcium carbonates are also
--    manufactured in SATELLITE FACILITIES THAT ARE ON-SITE OR NEXT TO A PAPER
--    MAKING FACILITY."
--
-- And their company history:
--   "In the 1950s our VERTICAL PRECIPITATED CALCIUM CARBONATE PLANT was
--    completed... The ROTARY PRECIPITATED CALCIUM CARBONATE PLANT was completed
--    and a new Hydrator was installed."
--
-- MLC owns TWO PCC PLANTS and runs SATELLITE PCC AT PAPER MILLS. They are
-- upstream AND downstream. Reading them as upstream only puts them next to
-- Carmeuse and Nittetsu, where they do not belong.
--
-- SEVENTH SATELLITE OPERATOR: Specialty Minerals, Taekyung BK, Double A,
-- Fimatec, Artemyn, Gulshan Polyols, and now MLC. The ranking scan counted four.
-- Three more were found by reading websites today, and all three were already in
-- this database, described wrongly.
--
-- ------------------------------------------------------------
-- ERROR 2 - MINE. fix_in_filler_batch1 flagged MLC's mineral_class='pcc' as
-- suspect BECAUSE market_role said upstream. I named the wrong culprit.
-- mineral_class was right. market_role was wrong. The flag correctly spotted a
-- contradiction and then blamed the honest field.
--
-- The flag is not removed - the contradiction is real and someone should see it.
-- A correction is written next to it instead, because deleting the evidence of a
-- wrong call is worse than leaving it with the correction attached.
--
-- ------------------------------------------------------------
-- WHY THEY MATTER
--   Founded 1907. HQ St. Louis. Operates THE LARGEST LIME FACILITY IN THE
--   AMERICAS at Ste. Genevieve, Missouri, on some of the purest limestone
--   reserves anywhere, plus Calera AL, Verona KY, Vicksburg MS, Weirton WV,
--   Chester SC, Mobile AL, Prairie du Rocher IL and Bridgeville PA.
--   Independent market coverage names the PCC producers as Imerys, Omya, Minerals
--   Technologies, MISSISSIPPI LIME and J.M. Huber - MLC sits in the same
--   sentence as the incumbents.
--
--   MAGNUM FILL PCC, from their own brochure and product pages:
--     "an outstanding filler pigment for paper applications where it provides
--      good opacity as well as excellent retention and drainage properties"
--     "COST SAVINGS BY REDUCING OR EXTENDING TiO2 USE"
--   Magnum Fill 70% Slurry is sold for paper filling. Magnum Gloss PCC for
--   coating. VitaCal PCC for food.
--
--   FOURTH TIME a target's own marketing states our case before we do - Bihoku on
--   neutral papermaking and cost-down, 20 Microns on TiO2 replacement, Zantat's
--   cost-saving company concept, and now MLC selling TiO2 extension in paper
--   filling. These companies are not waiting to be convinced that filler
--   economics matter. They sell that argument for a living.
--
-- ------------------------------------------------------------
-- THE 13 CONTACTS. MLC is the only US filler row with any contacts at all, and it
-- has thirteen. That is now an asset rather than a puzzle - I went looking at
-- this row because upstream companies should not have thirteen contacts, and the
-- premise was wrong.
--   STILL WORTH CHECKING before anyone writes: yesterday a bulk derivation nearly
--   invented fourteen people out of email local-parts. These thirteen came from
--   enrich_mlc_us_filler_2026-07-16. Confirm they are real named people with real
--   addresses, not local-parts wearing names, before the first message.
--   Not touched here.
--
-- IDEMPOTENT. Name-targeted. No contacts inserted or altered.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set market_role  = 'US lime leader AND a real PCC producer - merchant PCC at Ste. Genevieve plus satellite PCC plants on-site at paper mills. Also quicklime and hydrated lime upstream to other PCC makers, and GCC merchant. Upstream AND downstream, not upstream only.',
    supply_model = 'Merchant PCC + on-site satellite PCC at paper mills + lime upstream to third-party PCC makers',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "A REAL PCC PRODUCER WITH SATELLITE PLANTS, not an upstream lime supplier. Their own paper page states MLC HAS MERCHANT PCC FACILITIES at Ste. Genevieve and that precipitated calcium carbonates are also manufactured in SATELLITE FACILITIES ON-SITE OR NEXT TO A PAPER MAKING FACILITY. Their company history records a Vertical PCC Plant completed in the 1950s and a Rotary PCC Plant later. Magnum Fill PCC is sold as an outstanding filler pigment for paper applications with excellent retention and drainage, and the brochure leads with COST SAVINGS BY REDUCING OR EXTENDING TiO2 USE. Independent market coverage names the PCC producers as Imerys, Omya, Minerals Technologies, Mississippi Lime and J.M. Huber - MLC is in the same sentence as the incumbents.", "checked_at": "2026-07-17", "source": "mlc.com/markets/paper/, mlc.com/about-us/company-history/, Magnum Fill brochure", "source_type": "marketing"}, "satellite_operator": {"claim": "SEVENTH satellite operator identified", "the_seven": ["Specialty Minerals", "Taekyung BK", "Double A Specialty Minerals", "Fimatec", "Artemyn", "Gulshan Polyols", "Mississippi Lime"], "evidence": "Their paper page states precipitated calcium carbonates are manufactured in satellite facilities that are on-site or next to a paper making facility.", "note": "scan_fcc_target_ranking counted four. Three more were found by reading websites today and all three were already in this database, described wrongly - Artemyn as a kaolin merchant, Gulshan with no supply_model, MLC as PCC upstream.", "checked_at": "2026-07-17"}, "corrections": {"database_was_wrong": {"old_market_role": "US lime leader - GCC merchant + PCC upstream (quicklime)", "why_wrong": "Half right, and the wrong half is load-bearing. Reading MLC as upstream-only files them next to Carmeuse and Nittetsu, where they do not belong. They own two PCC plants and run satellites at mills.", "fixed_at": "2026-07-17"}, "i_was_wrong": {"what": "fix_in_filler_batch1 flagged mineral_class=pcc as suspect BECAUSE market_role said upstream. I named the wrong culprit - mineral_class was right and market_role was wrong. The flag correctly spotted a contradiction and then blamed the honest field.", "why_the_flag_stays": "The contradiction was real and someone should see it. Deleting the evidence of a wrong call is worse than leaving it with the correction attached.", "raised_at": "2026-07-17"}}, "products": {"paper_filler": "Magnum Fill PCC powder and Magnum Fill 70% Slurry - filler pigment for paper, good opacity, excellent retention and drainage, sold for TiO2 extension in both filling and coating", "coating": "Magnum Gloss PCC", "gcc": "CalCarb Calcium Carbonate - paper coating and paper filler", "food": "VitaCal PCC, food grade, low lead"}, "company": {"founded": 1907, "hq": "St. Louis, Missouri", "flagship": "Ste. Genevieve, Missouri - the largest lime facility in the Americas, on some of the purest limestone reserves in the world", "sites": ["Ste. Genevieve MO", "Calera AL", "Verona KY", "Vicksburg MS", "Weirton WV", "Chester SC", "Mobile AL", "Prairie du Rocher IL", "Bridgeville PA"]}, "contacts_note": {"count_at_check": 13, "status": "The only US filler row with any contacts. VERIFY PROVENANCE BEFORE THE FIRST MESSAGE - yesterday a bulk derivation nearly invented fourteen people out of email local-parts. These thirteen came from enrich_mlc_us_filler_2026-07-16. Confirm they are real named people with real addresses, not local-parts wearing names. Not touched by this file.", "raised_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG - and the market_role was wrong. MLC is a REAL PCC PRODUCER: merchant PCC facilities at Ste. Genevieve plus SATELLITE PCC plants on-site at paper mills, with a Vertical PCC Plant since the 1950s and a Rotary PCC Plant after. Seventh satellite operator found. Magnum Fill PCC is sold as a paper filler pigment for TiO2 extension - they already sell our argument. Named alongside Imerys, Omya, MTI and Huber as a PCC producer. 13 contacts already exist here - verify their provenance against the local-part problem before writing.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'mississippi lime|\bmlc\b'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.country_code,
--        f.mineral_class,
--        left(f.market_role, 70)                              as market_role_now,
--        f.extra_data #>> '{fcc_fit,verdict}'                 as fcc_fit,
--        f.extra_data #>> '{satellite_operator,claim}'        as satellite,
--        f.extra_data #>> '{corrections,i_was_wrong,what}' is not null as my_correction,
--        (select count(*) from app.contacts c
--          where c.party_id = p.id and c.deleted_at is null)  as contacts
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'mississippi lime|\mmlc\M' and p.deleted_at is null;
-- EXPECT - 'strong', market_role now says upstream AND downstream, contacts 13.


-- ---------- THE US ROSTER ----------
--   Mississippi Lime   STRONG - PCC producer + satellite operator, 13 contacts
--   Huber Eng. Mat.    NEXT   - kaolin and PCC. Named alongside MLC in the same
--                               market coverage as a PCC producer. Real.
--   Thiele Kaolin      out    - kaolin, no CaCO3 line
--   Imerys USA         out    - Imerys exited paper in 2024
--
-- The US roster is four rows and two of them are already gone. The two that
-- remain are both named in independent coverage as PCC producers alongside Omya,
-- Imerys and Minerals Technologies. That is not a coincidence - the American
-- carbonate market is small and consolidated, and this database holds all of it.
--
-- ---------- THE SWEEP ----------
-- Eighteen opened. Nine worth contacting - Artemyn, Okutama, Gulshan, Bihoku,
-- Shiraishi, 20 Microns, Zantat, Wolkem, MLC. Q-min moderate. Fimatec and F.M.T.
-- Thailand were held on a partner-conflict argument that no longer applies now
-- that incumbents are customers rather than competitors - reconsider both.
-- Seven out: Maruo, Takehara, Nittetsu, IMI Fabi, Carmeuse, Kaolin (Malaysia),
-- Thiele.
