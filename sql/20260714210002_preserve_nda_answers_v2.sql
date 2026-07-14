-- =====================================================================
-- 20260714210002_preserve_nda_answers_v2.sql
-- Fix for 23502: app.answer_library.created_by is NOT NULL without a
-- working default (auth.uid() is null in the SQL Editor). This version
-- fills created_by from an EXISTING answer_library row (the 7/10 seed),
-- so no auth context is needed. Still idempotent (NOT EXISTS guard).
--
-- The DB also has extra columns not in migration_025 (e.g. a 'medium'
-- column with its own default); we only supply the columns we know, and
-- rely on their DB defaults. If any other NOT-NULL-without-default column
-- exists, PART 0 will reveal it.
-- =====================================================================

-- PART 0: DIAGNOSE - list every column with NOT NULL + no default, so we
-- know exactly what must be supplied. Ideally created_by is the only one.
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'app' AND table_name = 'answer_library'
ORDER BY ordinal_position;

-- PART 0b: a usable created_by (any existing row's author for this org)
SELECT created_by, COUNT(*) AS rows_using
FROM app.answer_library
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND created_by IS NOT NULL
GROUP BY created_by
ORDER BY rows_using DESC
LIMIT 5;

-- PART 1: preserve 'nda_ip_ownership_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_ip_ownership_full',
  'IP ownership + patent list (full, NDA only)',
  'OWNERSHIP STATUS, stated plainly. Marinebio Group, Inc. currently holds one patent asset: the US application US 19/396,332, which has been assigned to it. Consideration for that assignment is unpaid and is contractually deferred, payable within one year after this financing is raised. The 5 granted patents are Korean patents registered to Marinepad, a Korean affiliate under common ownership and control - the same individual is the representative and principal shareholder of both companies. The PCT and Korean applications also remain with Marinepad. Korean patents are enforceable in Korea only. The NDA governing the license negotiation with the global filler producer was signed by Marinebio Group, Inc. and designates it as the party to receive license and royalty payments, with Marinepad identified as an affiliated company, so the commercial counterparty recognises the US entity as the licensor for the global business. The 500,000 USD consideration for assigning the remaining portfolio is not funded by this round, which is dedicated entirely to the US tissue validation. It will be met by royalty income or a subsequent round within the contractual one-year window. An exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover until assignment completes.

GRANTED PATENTS - Korea, KIPO, 5 total, registered to Marinepad, enforceable in Korea.
KR 10-1510313 (2015) Preparation method of filler and the paper containing the filler thereby.
KR 10-1535522 (2015) Preparation method of surface-coated filler for paper manufacture and paper containing the same.
KR 10-1742962 (2017) Preparation method of filler using micro-cellulose and calcium compound and paper containing filler prepared by the same.
KR 10-1910649 (2018) Preparation method of filler containing cellulose and the paper containing the filler thereby.
KR 10-2790098 (2025) Method for preparing calcium carbonate filler using crustacea shell and paper containing the calcium carbonate filler.
Related granted: KR 10-2887327 chitin nanofiber, registered to Marinepad.

PENDING APPLICATIONS - 7 total. Preparation method of paper filler using mixed solution of organic fiber and inorganic compound and use thereof.
US 19/396,332 USPTO - assigned to Marinebio Group, Inc.
KR 10-2023-0092212 Korea - Marinepad.
KR 2024/009859 PCT - Marinepad.
National phase entries planned or filed in EU, Japan, China, India and Indonesia.

THIRD-PARTY SUBMISSIONS filed by us: USPTO 18/909,232 and the corresponding EPO application, both citing our own peer-reviewed prior art to block a competitor patent family.

PATENT LICENSES. No executed patent license has been granted to any third party to date. A license and royalty agreement covering the confirmed 9,000-ton order has been approved at executive level by the counterparty and is being documented, naming Marinebio Group, Inc. as the payee.

COPYRIGHTS AND COPYRIGHT LICENSES. None held and none granted. Our two ACS journal articles are published under the publisher standard terms and function as prior art we can cite rather than as licensed assets.

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028. Certificate holder to be confirmed.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_ip_ownership_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 2: preserve 'nda_business_model_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_business_model_full',
  'Business model (full, NDA only)',
  'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - to be secured by 10-15 year supply contracts. A confirmed 9,000-ton order is executing at 350 USD per ton, royalty terms have executive approval by the counterparty, and the definitive license agreement is being documented. Royalties are near-pure margin, so the business self-funds after launch.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_business_model_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 3: preserve 'nda_cost_structure_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_cost_structure_full',
  'Cost structure (full, NDA only)',
  'We are asset-light: no plants, no inventory, no meaningful hosting - production and distribution run inside licensee plants at their cost. Our cost base is small and mostly fixed: independent testing and validation, patent prosecution and maintenance, and lean operations covering founder time, legal and business development travel. This round is allocated entirely to independent US validation, roughly 85 percent laboratory fees and analysis and 15 percent travel and technical support. The 500,000 USD assignment consideration for the remaining patents is contractually deferred for one year after funding and is not a cost of these proceeds. Customer acquisition cost is business development and technical validation rather than paid marketing, and the variable cost of an incremental royalty dollar is near zero, which is why royalties are near-pure margin.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_cost_structure_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 4: preserve 'nda_investment_use_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_investment_use_full',
  'Investment use (full, NDA only)',
  'The entire 100,000 USD funds one thing: an independent FCC validation for tissue at a US national paper laboratory. That single test converts our Korean commercial data to US data generated by a neutral American institution, and on completion the laboratory introduces us directly to the major US tissue manufacturers. Tissue is a category that has never used any filler, so this is the milestone that opens a new market rather than a share of an existing one. Breakdown: approximately 85,000 USD laboratory fees, sample preparation and shipping, and analysis. Approximately 15,000 USD travel and technical support during the trial. We are deliberately not raising more than the test requires. The 500,000 USD consideration for assigning the remaining patents is contractually deferred, payable within one year after funding, and will be met by royalty income or a subsequent round rather than by these proceeds. After the tissue data exists, we expect to raise a larger priced round at a valuation the data supports.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_investment_use_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 5: preserve 'nda_achieved_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_achieved_full',
  'Achieved so far (full, NDA only)',
  'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and a global top-3 filler producer is executing it in its existing plant. Royalty terms of 3-5 percent per ton have executive approval by that counterparty and the definitive license agreement, naming Marinebio Group, Inc. as payee, is being documented now. Roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP across the group: 5 granted Korean patents and 7 applications across KR, PCT and US, plus 3 SCI papers. The US application is assigned to Marinebio Group, Inc. and the remainder are held by an affiliate under common ownership pending assignment. In April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue was independently confirmed by a third-party mill trial. No outside capital has been raised to date.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_achieved_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 6: preserve 'nda_risks_full' (created_by copied from an existing row)
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, disclosure_level, tags, created_by)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169', 'nda_risks_full',
  'Risks (full, NDA only)',
  'IP is held across two affiliated entities. Marinebio Group, Inc. holds the US patent application. The 5 granted Korean patents and the PCT and Korean applications remain registered to Marinepad, an affiliate under common ownership, and the assignment consideration of 500,000 USD is contractually deferred, payable within one year after funding. Because the confirmed 9,000-ton order is supplied in Korea, the patents underpinning that royalty are the Korean ones, so today the US entity is the contractual payee rather than the owner of those patents. Mitigation: the same individual is representative and principal shareholder of both companies, so there is no adverse counterparty. The NDA with the global filler producer was signed by Marinebio Group, Inc. and names it as payee. An exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover, and we are prepared to make completion of the assignment a condition of a later priced round. The US application, which governs the US tissue track this round funds, is already assigned to the US entity. Contract documentation. The license and royalty agreement covering the 9,000-ton order has executive approval and is being documented. Mitigation: the order is already in physical supply and documentation is being executed now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs. Design-around risk. Mitigation: patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image. Key-person depth - the company is founder-led in the US. Mitigation: we are filling advisory seats through the Austin startup ecosystem rather than with cash, and the CTO and CPO anchor technical continuity.',
  'nda_only', ARRAY['ip','nda','data_room'],
  (SELECT created_by FROM app.answer_library
    WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND created_by IS NOT NULL
    ORDER BY created_at LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND answer_key = 'nda_risks_full'
)
RETURNING answer_key, length(body_en) AS len, created_by;

-- PART 7: confirm the 6 nda_only rows now exist
SELECT answer_key, title, disclosure_level, length(body_en) AS len
FROM app.answer_library
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND disclosure_level = 'nda_only'
ORDER BY answer_key;
