-- ============================================================
-- fix_maaden_no_caco3_2026-07-17.sql
--
-- MAADEN - NO. Their own page settles it, and a third-party page disagrees, and
-- for the third time today the company was right and the summary was wrong.
--
-- maaden.com.sa/en/business/minerals:
--   "Ma'aden industrial minerals are produced by the Ma'aden Industrial Minerals
--    Company (MIMC), established in 2009 as a wholly-owned subsidiary of Ma'aden.
--    It specializes in extracting and adding value to the Kingdom's extensive
--    deposits of industrial minerals which include LOW-GRADE BAUXITE (LGB),
--    KAOLIN and CAUSTIC CALCINED MAGNESITE (CCM). Ma'aden industrial mineral
--    production is used TO MEET THE NEEDS OF MA'ADEN AFFILIATES, with the
--    remaining output supplied to Saudi and GCC customers."
--
-- No calcium carbonate. Three minerals, none of them ours, and output aimed
-- first at their own affiliates. The parent is a gold, phosphate and aluminium
-- company - SAR 26.7 billion revenue, 17 mines, Tadawul-listed, half owned by the
-- Public Investment Fund.
--
-- WHAT A DIRECTORY CLAIMED: that Ma'aden Industrial Minerals produces "Calcium
-- Carbonate - Used in construction materials, paints, plastics, and paper".
-- WHAT MA'ADEN SAYS: bauxite, kaolin, magnesite.
--
-- THIRD TIME TODAY. And the score is 3-0 to the company:
--   Artemyn - this database said kaolin merchant. Their site showed 17 carbonate
--     plants and a P&B lab.
--   Huber - a market report named them a PCC producer. Their own literature says
--     GROUND calcium carbonate, every time, and I repeated the report as fact.
--   Maaden - a directory says calcium carbonate for paper. Their business page
--     says bauxite, kaolin, magnesite.
-- Summaries are where this database's worst errors come from. The company's own
-- page has been right every single time it disagreed with one.
--
-- A 2013 legal note recorded Ma'aden EVALUATING THE POTENTIAL of pure limestone
-- for GCC and PCC products, among a list of things under investigation. Thirteen
-- years ago, and their current business page does not mention it. An evaluation
-- is not a business.
--
-- ------------------------------------------------------------
-- THE SAUDI BLOCK NEEDS A DECISION, NOT THREE MORE SEARCHES
--
-- The four Saudi rows are Arabian Cement, Maaden, Saudi Lime Industries, and
-- "Yamama Cement / Saudi Cement" - which is two separate listed companies in one
-- row and cannot be contacted at all. Every one carries a market_role that
-- ALREADY says limestone-based or lime upstream. This database wrote the answer
-- next to the question.
--
-- And the US Department of Commerce's Saudi mining brief lists, under
-- OPPORTUNITIES: "Limestone, WITH UPGRADES TO PRODUCE ground calcium carbonate
-- (GCC) and products such as lime, hydrated lime, and dolime."
--
-- "With upgrades to produce" is future tense. It is an invitation to build a GCC
-- industry, which means there is not one. Saudi Arabia has limestone and an
-- ambition. FCC is licensed to filler producers who serve paper mills, and the
-- Kingdom has neither in any quantity.
--
-- I am marking Maaden only, because Maaden is the only one I opened. The other
-- three are recorded as a block-level question rather than three verdicts I did
-- not earn. If you want them checked one by one, say so and I will - but the
-- honest read is that four cement and lime rows in a country with no paper filler
-- industry were never targets, and the roster's own market_role field says so.
--
-- No contact route recorded. Seventh non-target today whose published details
-- stay out of this database.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) MAADEN ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "NO CALCIUM CARBONATE. Their own business page states that Maaden industrial minerals are produced by Maaden Industrial Minerals Company, a wholly-owned subsidiary established 2009, specializing in LOW-GRADE BAUXITE, KAOLIN and CAUSTIC CALCINED MAGNESITE - and that production is used to meet the needs of MAADEN AFFILIATES first, with the remainder to Saudi and GCC customers. Three minerals, none of them ours, and output aimed at their own group. The parent is a gold, phosphate and aluminium company - SAR 26.7 billion revenue, 17 mines and sites, Tadawul-listed, half owned by the Public Investment Fund.", "checked_at": "2026-07-17", "source": "maaden.com.sa/en/business/minerals", "source_type": "disclosure"}, "third_party_contradiction": {"a_directory_claimed": "Maaden Industrial Minerals produces Calcium Carbonate used in construction materials, paints, plastics and paper.", "maaden_says": "low-grade bauxite, kaolin, caustic calcined magnesite.", "verdict": "The company page wins.", "pattern": "THIRD TIME TODAY, and the score is 3-0 to the company. Artemyn - this database said kaolin merchant, their site showed 17 carbonate plants. Huber - a market report named them a PCC producer, their own literature says GROUND every time and I repeated the report as fact. Maaden - a directory says calcium carbonate for paper, their business page says bauxite, kaolin, magnesite. Summaries are where this database worst errors come from.", "raised_at": "2026-07-17"}, "the_2013_evaluation": {"what": "A 2013 legal note recorded Maaden evaluating the potential of pure limestone for GCC and PCC products, among a list of minerals under investigation.", "why_it_does_not_count": "Thirteen years ago, and their current business page does not mention it. An evaluation is not a business.", "raised_at": "2026-07-17"}, "contactability": {"not_recorded": "Seventh non-target today whose published details stay out of this database - after Maruo, Nittetsu, Takehara, IMI Fabi, Carmeuse and Kaolin (Malaysia)."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET. Maaden Industrial Minerals produces low-grade bauxite, kaolin and caustic calcined magnesite, primarily for Maaden affiliates. No calcium carbonate on their own business page. The parent is gold, phosphate and aluminium. A directory claims they make CaCO3 for paper - their own page does not. Third time today a third-party summary contradicted a company page and lost.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'maaden|ma.?aden'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 2) THE BLOCK-LEVEL QUESTION, ON THE THREE I DID NOT OPEN ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"block_question_saudi": {"question": "Should the Saudi rows be in the filler roster at all?", "the_rows": "Arabian Cement, Maaden, Saudi Lime Industries, and Yamama Cement / Saudi Cement - which is two separate listed companies in one row and cannot be contacted at all.", "what_the_roster_already_says": "Every Saudi row carries a market_role of limestone-based upstream or lime upstream supply. The database wrote the answer next to the question.", "what_the_us_commerce_brief_says": "Under OPPORTUNITIES for Saudi mining - Limestone, WITH UPGRADES TO PRODUCE ground calcium carbonate and products such as lime, hydrated lime and dolime. With upgrades to produce is future tense. It is an invitation to build a GCC industry, which means there is not one.", "the_read": "Saudi Arabia has limestone and an ambition. FCC is licensed to filler producers who serve paper mills, and the Kingdom has neither in quantity. Maaden was opened and confirmed no. The other three were NOT opened - this is a question, not a verdict.", "status": "OPEN - not a verdict. Only Maaden was checked. Marking the rest would be claiming work I did not do.", "raised_at": "2026-07-17"}}'::jsonb,
    updated_at = now()
from app.parties p
where f.party_id = p.id
  and p.party_type_id = 3 and p.country_code = 'SA'
  and p.deleted_at is null and f.deleted_at is null
  and p.party_name !~* 'maaden|ma.?aden'
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'block_question_saudi');


-- ---------- 3) VERIFY ----------
-- select p.party_name, p.country_code,
--        left(coalesce(f.market_role, ''), 45)                as market_role,
--        f.extra_data #>> '{fcc_fit,verdict}'                 as fcc_fit,
--        f.extra_data #>> '{block_question_saudi,status}'      as block_q
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.country_code = 'SA' and p.party_type_id = 3 and p.deleted_at is null
-- order by p.party_name;
-- EXPECT - Maaden 'no'. The other three carry an OPEN question and no verdict.


-- ---------- TWENTY OPENED ----------
--   Artemyn TOP. Okutama, Gulshan, Bihoku, Shiraishi, 20 Microns, Zantat, Wolkem,
--   MLC STRONG. Q-min, Huber moderate. Fimatec and F.M.T. Thailand held on an
--   argument that no longer applies - reconsider.
--   OUT: Maruo, Takehara, Nittetsu, IMI Fabi, Carmeuse, Kaolin (Malaysia),
--   Thiele, Imerys x3, Maaden.
--
-- NEXT: Mexico three - Calidra (lime, expect the Carmeuse position), Mexalit /
-- Cemex Minerals (two companies in one row, cannot be contacted), Imerys Mexico
-- (already out). Mexico is likely to look like Saudi: lime and cement in a
-- country whose carbonate industry is not aimed at paper.
--
-- Then India six - Ashapura x2 (both flagged, same website), Kunal Calcium,
-- Mumal Microns, Shikhar Microns, Yamuna Calcium. India is where the remaining
-- upside is: 20 Microns, Gulshan and Wolkem all came back STRONG, three for
-- three, and these six are the same kind of company.
