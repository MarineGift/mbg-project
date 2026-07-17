-- ============================================================
-- fix_ashapura_two_rows_one_company_2026-07-17.sql
--
-- ASHAPURA - MODERATE. And the two rows are one company, and the name belongs to
-- three companies, and only one of them is at the website both rows point to.
--
-- ------------------------------------------------------------
-- THE ENTITY MESS, UNTANGLED
--
-- THREE DIFFERENT BUSINESSES CARRY THIS NAME:
--   1. ASHAPURA MINECHEM LIMITED - ashapura.com. The group. "a legacy of more
--      than 60 years... a leading multi-mineral solutions provider with a global
--      footprint". Has a White Performance Minerals kaolin business, a Kaolin
--      Division at kaolin.ashapura.com, AND a calcium carbonate complex.
--   2. ASHAPURA MICRONS LLP - ashapuramicrons.in. A DIFFERENT company, Dadar,
--      Mumbai. Kaolin-focused, also talc, bentonite, dolomite, barytes and
--      micronized calcium carbonate from white marble. A second site,
--      ashapuramicronsllp.in, describes it as a TRADER-RETAILER. Facilities at
--      Bhuj, Udaipur and Chotta Udaipur.
--   3. ASHAPURA CHINA CLAY CO. LLP - ashapurachinaclay.co.in. A THIRD company,
--      established 1993, promoter business since 1984. China clay, bentonite,
--      silica sand, pyrophyllite, dolomite, calcite, talc.
--
-- WHAT THIS DATABASE HAS:
--   Row A: "Ashapura Group / Ashapura Microns"        website ashapura.com
--   Row B: "Ashapura Kaolin / White Performance Min." website ashapura.com
--
-- BOTH POINT AT MINECHEM. So:
--   - Row A and Row B ARE THE SAME COMPANY. Confirmed duplicate.
--   - Row A's name mixes TWO UNRELATED COMPANIES - Ashapura Minechem and
--     Ashapura Microns LLP - and its website is only one of them.
--   - Row B's name is fine: Ashapura Kaolin and White Performance Minerals are
--     both Minechem divisions.
--
-- NOT MERGED HERE. Merging is a data decision with real risk, and the Omya Korea
-- and Taekyung merges this week both needed a human. Flagged with the evidence
-- attached so the decision can be made once, properly.
--
-- ------------------------------------------------------------
-- WHAT MINECHEM ACTUALLY IS - and it is a carbonate producer
--
--   ashapura.com/products.php:
--     "Ashapura is INDIA'S LEADING PRODUCER OF PROCESSED CALCIUM CARBONATE. It's
--      PLC based state-of-the art processing complex manufactures both COATED AND
--      UNCOATED grades of calcium carbonate. Access to the purest and brightest
--      raw material along with an avant garde multi-stage processing technique
--      guarantees perfect particle size distribution, brightness and dispersion."
--     "Both Coated (with Stearic acid) and Uncoated Calcium Carbonate powders are
--      widely used in different industries mainly as fillers in manufacturing
--      plastics, paints, adhesives, PVC and PAPER."
--
--   PROCESSED, not precipitated. This is GCC - so mineral_class='gcc' IS RIGHT
--   and my flag in fix_in_filler_batch1 was wrong about this row too. THIRD TIME
--   TODAY I trusted market_role over mineral_class and lost - MLC, Mumal, and now
--   Ashapura. The flag stays, the correction sits beside it.
--
--   White Performance Minerals - calcined, hydrous, specialty and meta kaolin.
--   40+ export markets. Serves cosmetics, ink, paints, fibreglass, ceramics,
--   PAPER, construction, polymers, plastics, rubber.
--
-- ------------------------------------------------------------
-- THE ONE THING THAT MAKES THIS ROW WORTH KEEPING
--
--   kaolin.ashapura.com:
--     "IKC is spread across 12000 Sq.ft working area with all key facilities,
--      modern instruments with PILOT PLANTS. Our Knowledge and Innovation Centre
--      in Gujarat houses one of the best GEO-MINERAL LABORATORIES and talent for
--      APPLIED RESEARCH in Asia."
--
--   Pilot plants and an applied research laboratory. That is where a licence gets
--   tested. It is the same asset that makes Shiraishi strong - an open testing
--   laboratory and a publication record - and it is exactly the kind of
--   company-specific, uncopyable fact the Mumal lesson says to weigh.
--
-- VERDICT MODERATE: a real GCC producer with a genuine R&D capability and paper
-- on the list, but paper sits among ten industries and the carbonate is aimed at
-- plastics, paints, adhesives and PVC first. Not Wolkem, whose slurry goes to
-- mills. Not Maruo, who has no paper at all.
--
-- No contact route recorded - the entity question must be settled first. Writing
-- to "Ashapura" without knowing which of three companies is being addressed is
-- how a message lands nowhere.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted, nothing merged.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "moderate", "reason": "A REAL GCC PRODUCER WITH REAL R&D, and paper among ten industries. Their products page claims Ashapura is INDIA LEADING PRODUCER OF PROCESSED CALCIUM CARBONATE, with a PLC-based processing complex making both coated (stearic acid) and uncoated grades, used as fillers in plastics, paints, adhesives, PVC and PAPER. PROCESSED, not precipitated - this is GCC. The White Performance Minerals business covers calcined, hydrous, specialty and meta kaolin across 40+ export markets serving cosmetics, ink, paints, fibreglass, ceramics, paper, construction, polymers, plastics and rubber. Carbonate is aimed at plastics and paints first. Not Wolkem, whose slurry goes to mills. Not Maruo, who has no paper at all.", "checked_at": "2026-07-17", "source": "ashapura.com, kaolin.ashapura.com", "source_type": "marketing"}, "why_worth_keeping": {"the_innovation_centre": "kaolin.ashapura.com states the IKC spans 12000 sq ft with modern instruments and PILOT PLANTS, and that their Knowledge and Innovation Centre in Gujarat houses one of the best geo-mineral laboratories and applied research talent in Asia.", "why_it_matters": "Pilot plants and an applied research laboratory are where a licence gets tested. Same asset that makes Shiraishi strong - an open testing laboratory and a publication record. And it is a company-specific, uncopyable fact, which is exactly what the Mumal lesson says to weigh.", "raised_at": "2026-07-17"}, "entity_mess": {"three_companies_share_this_name": [{"name": "Ashapura Minechem Limited", "site": "ashapura.com", "what": "The group. Over 60 years. Multi-mineral, global footprint. Owns the White Performance Minerals kaolin business, the Kaolin Division at kaolin.ashapura.com, and the calcium carbonate complex. THIS IS THE COMPANY BOTH DATABASE ROWS POINT AT."}, {"name": "Ashapura Microns LLP", "site": "ashapuramicrons.in", "what": "A DIFFERENT company, Dadar, Mumbai. Kaolin-focused, plus talc, bentonite, dolomite, barytes and micronized calcium carbonate from white marble. A second site, ashapuramicronsllp.in, calls it a TRADER-RETAILER. Facilities at Bhuj, Udaipur, Chotta Udaipur."}, {"name": "Ashapura China Clay Co. LLP", "site": "ashapurachinaclay.co.in", "what": "A THIRD company. Established 1993, promoter business since 1984. China clay, bentonite, silica sand, pyrophyllite, dolomite, calcite, talc."}], "what_this_database_has": {"row_A": "Ashapura Group / Ashapura Microns - website ashapura.com. THE NAME MIXES TWO UNRELATED COMPANIES and the website is only one of them.", "row_B": "Ashapura Kaolin / White Performance Minerals - website ashapura.com. This name is fine - both are Minechem divisions.", "verdict": "ROW A AND ROW B ARE THE SAME COMPANY. Confirmed duplicate, both Ashapura Minechem."}, "not_merged": "Merging is a data decision with real risk. The Omya Korea and Taekyung merges this week both needed a human. Flagged with evidence attached so the decision is made once, properly.", "raised_at": "2026-07-17"}, "my_flag_was_wrong_again": {"what": "fix_in_filler_batch1 flagged this row mineral_class=gcc as suspect BECAUSE market_role said paper/specialty kaolin. But the carbonate business IS ground - processed, coated and uncoated. mineral_class was right.", "the_tally": "THIRD TIME TODAY. Mississippi Lime, Mumal Microns, and now Ashapura. Every time I trusted market_role over mineral_class, market_role was the liar.", "flag_stays": "The contradiction is real. The correction sits beside it.", "raised_at": "2026-07-17"}, "contactability": {"not_recorded": "The entity question must be settled first. Writing to Ashapura without knowing which of three companies is being addressed is how a message lands nowhere."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] MODERATE, and the two Ashapura rows are ONE COMPANY - both point at ashapura.com, which is Ashapura Minechem Limited. THREE businesses share this name: Minechem (the group, ashapura.com), Ashapura Microns LLP (a different Mumbai company, ashapuramicrons.in), and Ashapura China Clay Co. LLP (a third). Row A name mixes Minechem and Microns LLP, which are unrelated. Minechem IS a carbonate producer - India leading producer of PROCESSED (ground) calcium carbonate, coated and uncoated, for plastics, paints, adhesives, PVC and paper - plus a kaolin business across 40+ markets. Worth keeping for its Knowledge and Innovation Centre in Gujarat with PILOT PLANTS and an applied research lab. Not merged - that is a human decision. No contact recorded until the entity is settled.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'ashapura'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.website, f.mineral_class,
--        f.extra_data #>> '{fcc_fit,verdict}'                     as fcc_fit,
--        f.extra_data #>> '{entity_mess,what_this_database_has,verdict}' as dupe,
--        f.extra_data #>> '{data_defect,kind}'                    as slash_flag
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'ashapura' and p.deleted_at is null;
-- EXPECT - two rows, both 'moderate', both carrying the duplicate finding and the
-- earlier slash flag.


-- ---------- INDIA: TWO LEFT ----------
--   20 Microns       STRONG   - done
--   Gulshan Polyols  STRONG   - done, sixth satellite operator
--   Wolkem           STRONG   - done, WGCC slurry
--   Imerys India     no       - done
--   Mumal Microns    weak     - done, copied PCC copy
--   Ashapura x2      moderate - THIS FILE, and they are one company
--   Kunal Calcium    role "Domestic carbonate producer", class pcc
--   Shikhar Microns  role "GCC producer"
--
-- India's real count is not ten. It is 20 Microns, Gulshan, Wolkem, Imerys,
-- Mumal, ONE Ashapura, Kunal and Shikhar - EIGHT companies in nine rows.
-- The roster has been counting rows and calling them companies all week.
