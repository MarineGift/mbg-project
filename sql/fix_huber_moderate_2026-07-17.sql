-- ============================================================
-- fix_huber_moderate_2026-07-17.sql
--
-- HUBER ENGINEERED MATERIALS - MODERATE, not strong. And this file corrects an
-- overclaim I made one file ago.
--
-- ------------------------------------------------------------
-- MY ERROR, FIRST, BECAUSE IT SHAPED THE EXPECTATION
--
-- fix_mlc_is_a_pcc_producer closed with: "Huber Eng. Mat. NEXT - kaolin and PCC.
-- Named alongside MLC in the same market coverage as a PCC producer. Real."
--
-- That rested on ONE market-research report listing J.M. Huber Corporation among
-- PCC players. Huber's own materials say GROUND, every time:
--   "The Hubercarb product line of GROUND CALCIUM CARBONATES is one of the
--    broadest lines in the world."
--   HuberCal calcium carbonate is "NATURALLY MINED", food and USP grades.
--
-- I put a market report above the company's own product literature. That is the
-- Artemyn error running backwards - there, a stale label ("kaolin merchant")
-- buried 17 carbonate plants. Here, a third-party list invented a PCC line that
-- their own pages do not mention. Same failure: trusting a summary over a source.
--
-- The database's market_role says "Specialty minerals (kaolin, PCC)" and
-- mineral_class says "Kaolin / CaCO3". The PCC half is UNCONFIRMED by anything
-- Huber publishes. Not corrected here, because absence of evidence on three
-- product pages is not proof - but flagged, and nobody should plan around a Huber
-- PCC line until someone finds it on huberspecialtyminerals.com.
--
-- ------------------------------------------------------------
-- WHAT IS ACTUALLY THERE
--
-- CONFIRMED - a serious GCC producer with real ultrafine capability:
--   Hubercarb Q Series - Quincy, Illinois. Ultra-fine through granular, several
--     surface-modified.
--   Hubercarb M Series - Marble Falls, Texas. Sold as bridging and weighting
--     agents for oil and gas DRILLING FLUIDS - sited near the US drilling basins.
--   Hubercarb W Series - Quincy. 99.3 percent purity, ultra-fine and fine, silica
--     below detectable levels, low moisture pickup.
--   HuberCal - mined, food and USP grade.
--   Air-float kaolin, sodium bicarbonate, attapulgite clay alongside.
--
-- PAPER IS THIN, AND THE EVIDENCE POINTS BOTH WAYS:
--   FOR - Huber's own tagline says they serve "industrial, PAPER and consumer
--     markets", and a Huber Calcium Carbonates document repeats it.
--   AGAINST - their distributor's end-use list for Huber carbonates reads films
--     and plastic packaging, plastics, building and construction, coatings,
--     adhesives, caulks and sealants, rubber, nonwovens and fiber. NO PAPER.
--
-- AND THE ONE SPEC THAT SOUNDS LIKE OURS IS AIMED ELSEWHERE:
--   W Series is marketed for "applications that require HIGH-FILLER LOADINGS".
--   That is FCC's exact territory - until the next line, which explains the
--   series is "low in trace metals like iron, which can promote undesirable
--   degradation in some POLYMER SYSTEMS". High loading, for polymers.
--   The words matched. The market did not. Reading only the phrase that sounded
--   familiar would have produced a false strong.
--
-- ------------------------------------------------------------
-- VERDICT: moderate. A large, capable, ultrafine GCC house that names paper as a
-- market and shows no paper product. Worth one more look at
-- huberspecialtyminerals.com rather than a message - and worth remembering that
-- Maruo also had every ingredient of a filler house pointed at resins.
--
-- No contact route recorded. The row is not resolved enough to hold one.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "moderate - unresolved", "reason": "A serious ultrafine GCC producer that NAMES paper as a market and SHOWS no paper product. Hubercarb is described in their own literature as a line of GROUND calcium carbonates - Q Series from Quincy Illinois (ultra-fine through granular, several surface-modified), M Series from Marble Falls Texas (sold as bridging and weighting agents for oil and gas drilling fluids), W Series from Quincy at 99.3 percent purity with silica below detectable levels. HuberCal is naturally mined, food and USP grade. Their tagline claims industrial, PAPER and consumer markets, but their distributor end-use list for Huber carbonates names films and plastic packaging, plastics, construction, coatings, adhesives, CASE, rubber and nonwovens - no paper. Needs one look at huberspecialtyminerals.com before a message. Remember Maruo had every ingredient of a filler house pointed at resins.", "checked_at": "2026-07-17", "source": "hubermaterials.com, huber.com, Hubercarb Q Series brochure, distributor listings", "source_type": "marketing"}, "the_spec_that_sounded_like_ours": {"what": "Hubercarb W Series is marketed for applications that require HIGH-FILLER LOADINGS - FCC exact territory.", "but": "The same passage explains the series is low in trace metals like iron, which can promote undesirable degradation in some POLYMER SYSTEMS. High loading, for polymers.", "lesson": "The words matched and the market did not. Reading only the phrase that sounded familiar would have produced a false strong.", "raised_at": "2026-07-17"}, "pcc_claim_unconfirmed": {"database_says": "market_role - Specialty minerals (kaolin, PCC). mineral_class - Kaolin / CaCO3.", "evidence_for_pcc": "ONE market-research report lists J.M. Huber Corporation among PCC players, alongside Imerys, Omya, Minerals Technologies and Mississippi Lime.", "evidence_against": "Every Huber source found says GROUND or MINED. Hubercarb is explicitly a ground calcium carbonate line. HuberCal is naturally mined. No PCC appears on any Huber page found.", "status": "UNCONFIRMED. Not corrected - absence on three product pages is not proof. But nobody should plan around a Huber PCC line until someone finds it on huberspecialtyminerals.com.", "raised_at": "2026-07-17"}, "my_error": {"what": "fix_mlc_is_a_pcc_producer closed by calling Huber kaolin and PCC, Named alongside MLC in the same market coverage as a PCC producer, Real. That rested on one market-research report. Huber own literature says GROUND, every time.", "why_it_matters": "I put a market summary above the company own product pages. That is the Artemyn error running backwards - there a stale label buried 17 carbonate plants, here a third-party list invented a PCC line. Same failure: trusting a summary over a source.", "raised_at": "2026-07-17"}, "confirmed_products": {"gcc": ["Hubercarb Q Series - Quincy, Illinois. Ultra-fine, fine, medium-fine, granular. Several surface-modified.", "Hubercarb M Series - Marble Falls, Texas. Bridging and weighting agents for water- and oil-based drilling fluids, sited near US drilling basins.", "Hubercarb W Series - Quincy, Illinois. 99.3 percent purity, ultra-fine and fine, silica below detectable levels, low moisture pickup, low iron.", "HuberCal - naturally mined, food and USP grades", "Geotex - drilling fluids"], "other_minerals": "air-float kaolin, sodium bicarbonate, attapulgite clay, alumina trihydrate, magnesium hydroxide, specialty aluminas"}, "contactability": {"not_recorded": "The row is not resolved enough to hold a contact route."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] MODERATE - UNRESOLVED, downgraded from my own overclaim. Hubercarb is a GROUND calcium carbonate line per Huber own literature - Q, M and W series, all mined and ground, with the M series aimed at oil and gas drilling fluids. The PCC in this row market_role is unconfirmed by anything Huber publishes - it came from one market-research report, and I repeated it as fact one file ago. Paper is in their tagline and absent from their distributor end-use list. The W Series high-filler-loading claim reads like ours until the next line says it is for polymer systems. One look at huberspecialtyminerals.com before any message.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'huber'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.country_code,
--        f.mineral_class,
--        f.extra_data #>> '{fcc_fit,verdict}'              as fcc_fit,
--        f.extra_data #>> '{pcc_claim_unconfirmed,status}' as pcc_status,
--        f.extra_data #>> '{my_error,what}' is not null    as correction_recorded
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'huber' and p.deleted_at is null;


-- ---------- THE US ROSTER, FINISHED ----------
--   Mississippi Lime   STRONG    - PCC producer + satellite operator, 13 contacts
--   Huber Eng. Mat.    moderate  - ultrafine GCC, paper claimed but not shown
--   Thiele Kaolin      no        - kaolin, no CaCO3 line
--   Imerys USA         no        - Imerys exited paper in 2024
--
-- FOUR US ROWS. ONE STRONG. And the one strong row was described in this database
-- as PCC upstream, which is the description that would have kept anyone from
-- opening it.
--
-- ---------- NINETEEN OPENED ----------
--   Artemyn TOP. Okutama, Gulshan, Bihoku, Shiraishi, 20 Microns, Zantat, Wolkem,
--   MLC all STRONG. Q-min and Huber moderate. Fimatec and F.M.T. Thailand held on
--   an argument that no longer applies - reconsider. Seven out: Maruo, Takehara,
--   Nittetsu, IMI Fabi, Carmeuse, Kaolin (Malaysia), Thiele.
--
-- NEXT: Saudi four - Arabian Cement, Maaden, Saudi Lime Industries, Yamama/Saudi
-- Cement. All four carry a market_role that already says limestone-based upstream,
-- and one of them is two companies in one row. Expect the Carmeuse position.
-- Then Mexico three - Calidra (lime), Mexalit/Cemex (two companies), Imerys
-- Mexico (out).
-- Then India six - Ashapura x2 (both flagged), Kunal Calcium, Mumal Microns,
-- Shikhar Microns, Yamuna Calcium.
