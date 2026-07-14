-- =====================================================================
-- 20260714220000_anonymize_ip_answers_v2.sql   (RE-RUN, 8 texts)
-- The first anonymization run (20260714210000) was ROLLED BACK when its
-- ON CONFLICT step failed, so NO public answer was actually anonymized.
-- This version:
--   * fixes that (UPDATEs only - nda_only preservation was already done
--     separately by 20260714210002),
--   * covers 8 distinct texts (the original 6 PLUS two more that only
--     surfaced when 'executive level' was added to the search:
--     CTAN advisory board + CTAN valuation details),
--   * each UPDATE is an independent statement (one failing cannot roll
--     back the others).
--
-- Anonymization: 'Marinepad' -> 'a Korean affiliate under common
-- ownership'; '500,000 USD' transfer figure -> deferred consideration
-- (figure removed); 'executive approval/level' -> 'being documented' /
-- removed. Facts kept. Matched by EXACT original text. Run each part.
-- =====================================================================

-- PART 0: preview - rows still carrying any sensitive marker (expect 11)
SELECT p.party_name, aff.label, af.status, afa.char_count
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (afa.final_text ILIKE '%Marinepad%'
    OR afa.final_text ILIKE '%500,000 USD%'
    OR afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%')
ORDER BY p.party_name, aff.label;

-- PART 1: Intellectual property / patent list (shared: 1955, 3M, Lowercarbon, CTAN)
UPDATE app.application_field_answers
SET final_text = 'OWNERSHIP STATUS, stated plainly. Marinebio Group, Inc. currently holds the US application US 19/396,332, which has been assigned to it. The 5 granted patents and the PCT and Korean applications are currently registered to a Korean affiliate under common ownership and control - the same individual is the representative and principal shareholder of both companies - and are being transferred to Marinebio Group, Inc. Korean patents are enforceable in Korea only. The NDA governing the license negotiation with the global filler producer was signed by Marinebio Group, Inc. and designates it as the party to receive license and royalty payments, so the commercial counterparty recognises the US entity as the licensor for the global business. An exclusive worldwide license from the affiliate to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover until the assignment completes. Assignment consideration is contractually deferred and payable within one year after this financing, and is not funded by this round.

GRANTED PATENTS - Korea, KIPO, 5 total, enforceable in Korea.
KR 10-1510313 (2015) Preparation method of filler and the paper containing the filler thereby.
KR 10-1535522 (2015) Preparation method of surface-coated filler for paper manufacture and paper containing the same.
KR 10-1742962 (2017) Preparation method of filler using micro-cellulose and calcium compound and paper containing filler prepared by the same.
KR 10-1910649 (2018) Preparation method of filler containing cellulose and the paper containing the filler thereby.
KR 10-2790098 (2025) Method for preparing calcium carbonate filler using crustacea shell and paper containing the calcium carbonate filler.
Related granted: KR 10-2887327 chitin nanofiber.

PENDING APPLICATIONS - 7 total. Preparation method of paper filler using mixed solution of organic fiber and inorganic compound and use thereof.
US 19/396,332 USPTO - assigned to Marinebio Group, Inc.
KR 10-2023-0092212 Korea.
KR 2024/009859 PCT.
National phase entries planned or filed in EU, Japan, China, India and Indonesia.

THIRD-PARTY SUBMISSIONS filed by us: USPTO 18/909,232 and the corresponding EPO application, both citing our own peer-reviewed prior art to block a competitor patent family.

PATENT LICENSES. No executed patent license has been granted to any third party to date. A license and royalty agreement covering the confirmed 9,000-ton order is being documented, naming Marinebio Group, Inc. as the payee.

COPYRIGHTS AND COPYRIGHT LICENSES. None held and none granted. Our two ACS journal articles are published under the publisher standard terms and function as prior art we can cite rather than as licensed assets.

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028.'
WHERE final_text = 'OWNERSHIP STATUS, stated plainly. Marinebio Group, Inc. currently holds one patent asset: the US application US 19/396,332, which has been assigned to it. Consideration for that assignment is unpaid and is contractually deferred, payable within one year after this financing is raised. The 5 granted patents are Korean patents registered to Marinepad, a Korean affiliate under common ownership and control - the same individual is the representative and principal shareholder of both companies. The PCT and Korean applications also remain with Marinepad. Korean patents are enforceable in Korea only. The NDA governing the license negotiation with the global filler producer was signed by Marinebio Group, Inc. and designates it as the party to receive license and royalty payments, with Marinepad identified as an affiliated company, so the commercial counterparty recognises the US entity as the licensor for the global business. The 500,000 USD consideration for assigning the remaining portfolio is not funded by this round, which is dedicated entirely to the US tissue validation. It will be met by royalty income or a subsequent round within the contractual one-year window. An exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover until assignment completes.

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

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028. Certificate holder to be confirmed.'
RETURNING id, char_count;

-- PART 2: CTAN business model
UPDATE app.application_field_answers
SET final_text = 'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - to be secured by 10-15 year supply contracts. A confirmed 9,000-ton order is executing at 350 USD per ton, and the definitive license agreement is being documented. Royalties are near-pure margin, so the business self-funds after launch.'
WHERE final_text = 'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - to be secured by 10-15 year supply contracts. A confirmed 9,000-ton order is executing at 350 USD per ton, royalty terms have executive approval by the counterparty, and the definitive license agreement is being documented. Royalties are near-pure margin, so the business self-funds after launch.'
RETURNING id, char_count;

-- PART 3: CTAN cost structure
UPDATE app.application_field_answers
SET final_text = 'We are asset-light: no plants, no inventory, no meaningful hosting - production and distribution run inside licensee plants at their cost. Our cost base is small and mostly fixed: independent testing and validation, patent prosecution and maintenance, and lean operations covering founder time, legal and business development travel. This round is allocated entirely to independent US validation, roughly 85 percent laboratory fees and analysis and 15 percent travel and technical support. Patent assignment consideration from an affiliate under common ownership is contractually deferred for one year after funding and is not a cost of these proceeds. Customer acquisition cost is business development and technical validation rather than paid marketing, and the variable cost of an incremental royalty dollar is near zero, which is why royalties are near-pure margin.'
WHERE final_text = 'We are asset-light: no plants, no inventory, no meaningful hosting - production and distribution run inside licensee plants at their cost. Our cost base is small and mostly fixed: independent testing and validation, patent prosecution and maintenance, and lean operations covering founder time, legal and business development travel. This round is allocated entirely to independent US validation, roughly 85 percent laboratory fees and analysis and 15 percent travel and technical support. The 500,000 USD assignment consideration for the remaining patents is contractually deferred for one year after funding and is not a cost of these proceeds. Customer acquisition cost is business development and technical validation rather than paid marketing, and the variable cost of an incremental royalty dollar is near zero, which is why royalties are near-pure margin.'
RETURNING id, char_count;

-- PART 4: CTAN investment use
UPDATE app.application_field_answers
SET final_text = 'The entire 100,000 USD funds one thing: an independent FCC validation for tissue at a US national paper laboratory. That single test converts our Korean commercial data to US data generated by a neutral American institution, and on completion the laboratory introduces us directly to the major US tissue manufacturers. Tissue is a category that has never used any filler, so this is the milestone that opens a new market rather than a share of an existing one. Breakdown: approximately 85,000 USD laboratory fees, sample preparation and shipping, and analysis. Approximately 15,000 USD travel and technical support during the trial. We are deliberately not raising more than the test requires. Patent assignment consideration from an affiliate under common ownership is contractually deferred, payable within one year after funding, and will be met by royalty income or a subsequent round rather than by these proceeds. After the tissue data exists, we expect to raise a larger priced round at a valuation the data supports.'
WHERE final_text = 'The entire 100,000 USD funds one thing: an independent FCC validation for tissue at a US national paper laboratory. That single test converts our Korean commercial data to US data generated by a neutral American institution, and on completion the laboratory introduces us directly to the major US tissue manufacturers. Tissue is a category that has never used any filler, so this is the milestone that opens a new market rather than a share of an existing one. Breakdown: approximately 85,000 USD laboratory fees, sample preparation and shipping, and analysis. Approximately 15,000 USD travel and technical support during the trial. We are deliberately not raising more than the test requires. The 500,000 USD consideration for assigning the remaining patents is contractually deferred, payable within one year after funding, and will be met by royalty income or a subsequent round rather than by these proceeds. After the tissue data exists, we expect to raise a larger priced round at a valuation the data supports.'
RETURNING id, char_count;

-- PART 5: CTAN achieved so far
UPDATE app.application_field_answers
SET final_text = 'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and a global top-3 filler producer is executing it in its existing plant. Royalty terms of 3-5 percent per ton and the definitive license agreement, naming Marinebio Group, Inc. as payee, are being documented now. Roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP across the group: 5 granted Korean patents and 7 applications across KR, PCT and US, plus 3 SCI papers. The US application is assigned to Marinebio Group, Inc. and the remainder are held by an affiliate under common ownership pending assignment. In April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue was independently confirmed by a third-party mill trial. No outside capital has been raised to date.'
WHERE final_text = 'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and a global top-3 filler producer is executing it in its existing plant. Royalty terms of 3-5 percent per ton have executive approval by that counterparty and the definitive license agreement, naming Marinebio Group, Inc. as payee, is being documented now. Roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP across the group: 5 granted Korean patents and 7 applications across KR, PCT and US, plus 3 SCI papers. The US application is assigned to Marinebio Group, Inc. and the remainder are held by an affiliate under common ownership pending assignment. In April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue was independently confirmed by a third-party mill trial. No outside capital has been raised to date.'
RETURNING id, char_count;

-- PART 6: CTAN risks
UPDATE app.application_field_answers
SET final_text = 'IP is held across two affiliated entities under common ownership. Marinebio Group, Inc. holds the US patent application. The 5 granted Korean patents and the PCT and Korean applications currently remain registered to a Korean affiliate under common ownership, and their assignment consideration is contractually deferred, payable within one year after funding. Because the confirmed 9,000-ton order is supplied in Korea, the patents underpinning that royalty are the Korean ones, so today the US entity is the contractual payee rather than the owner of those patents. Mitigation: the same individual is representative and principal shareholder of both companies, so there is no adverse counterparty. The NDA with the global filler producer was signed by Marinebio Group, Inc. and names it as payee. An exclusive worldwide license from the affiliate to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover, and we are prepared to make completion of the assignment a condition of a later priced round. The US application, which governs the US tissue track this round funds, is already assigned to the US entity. Contract documentation. The license and royalty agreement covering the 9,000-ton order is being documented. Mitigation: the order is already in physical supply and documentation is being executed now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs. Design-around risk. Mitigation: patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image. Key-person depth - the company is founder-led in the US. Mitigation: we are filling advisory seats through the Austin startup ecosystem rather than with cash, and the CTO and CPO anchor technical continuity.'
WHERE final_text = 'IP is held across two affiliated entities. Marinebio Group, Inc. holds the US patent application. The 5 granted Korean patents and the PCT and Korean applications remain registered to Marinepad, an affiliate under common ownership, and the assignment consideration of 500,000 USD is contractually deferred, payable within one year after funding. Because the confirmed 9,000-ton order is supplied in Korea, the patents underpinning that royalty are the Korean ones, so today the US entity is the contractual payee rather than the owner of those patents. Mitigation: the same individual is representative and principal shareholder of both companies, so there is no adverse counterparty. The NDA with the global filler producer was signed by Marinebio Group, Inc. and names it as payee. An exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, is being documented as interim cover, and we are prepared to make completion of the assignment a condition of a later priced round. The US application, which governs the US tissue track this round funds, is already assigned to the US entity. Contract documentation. The license and royalty agreement covering the 9,000-ton order has executive approval and is being documented. Mitigation: the order is already in physical supply and documentation is being executed now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs. Design-around risk. Mitigation: patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image. Key-person depth - the company is founder-led in the US. Mitigation: we are filling advisory seats through the Austin startup ecosystem rather than with cash, and the CTO and CPO anchor technical continuity.'
RETURNING id, char_count;

-- PART 7: CTAN advisory board (NEW)
UPDATE app.application_field_answers
SET final_text = 'We are formalizing our advisory board as part of this round. Today external guidance comes through three channels. A US national paper laboratory engaged under NDA will run independent FCC validation and, on completion, introduce us to major US tissue manufacturers. Senior technical and commercial counterparts at two global filler producers are engaged under NDA. The company is a resident member of the Capital Factory ecosystem in Austin. Partner names are disclosed in person under NDA. Filling two to three formal advisory seats covering US paper-industry commercial expertise and IP licensing is an explicit goal of this cycle.'
WHERE final_text = 'We are formalizing our advisory board as part of this round. Today external guidance comes through three channels. A US national paper laboratory engaged under NDA will run independent FCC validation and, on completion, introduce us to major US tissue manufacturers. Senior technical and commercial counterparts at two global filler producers are engaged under NDA at executive level. The company is a resident member of the Capital Factory ecosystem in Austin. Partner names are disclosed in person under NDA. Filling two to three formal advisory seats covering US paper-industry commercial expertise and IP licensing is an explicit goal of this cycle.'
RETURNING id, char_count;

-- PART 8: CTAN valuation details (NEW)
UPDATE app.application_field_answers
SET final_text = 'We are not pricing the company in this round. We are raising 100,000 USD on a post-money SAFE with a 10,000,000 USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US tissue validation is complete. Raising only what the test requires means investors are funding a specific milestone rather than a runway. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalty terms and the definitive agreement under documentation, price validation at 250-350 USD per ton by a major mill against wood pulp at 600-800, a portfolio of 5 granted Korean patents and 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. The US application is assigned to Marinebio Group, Inc. The granted Korean patents remain with an affiliate under common ownership, their assignment consideration is contractually deferred for one year after funding, and an exclusive worldwide license granted by the affiliate is being documented as interim cover. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10,000,000 USD cap therefore prices early angels at a substantial discount to what the validated track alone implies, which is the compensation owed to investors who move before the US data exists. Tissue, packaging and wallpaper revenue are excluded entirely.'
WHERE final_text = 'We are not pricing the company in this round. We are raising 100,000 USD on a post-money SAFE with a 10,000,000 USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US tissue validation is complete. Raising only what the test requires means investors are funding a specific milestone rather than a runway. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalty terms approved at executive level and the definitive agreement under documentation, price validation at 250-350 USD per ton by a major mill against wood pulp at 600-800, a portfolio of 5 granted Korean patents and 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. The US application is assigned to Marinebio Group, Inc. The granted Korean patents remain with an affiliate under common ownership, their assignment consideration is contractually deferred for one year after funding, and an exclusive worldwide license granted by the affiliate is being documented as interim cover. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10,000,000 USD cap therefore prices early angels at a substantial discount to what the validated track alone implies, which is the compensation owed to investors who move before the US data exists. Tissue, packaging and wallpaper revenue are excluded entirely.'
RETURNING id, char_count;

-- PART 9: FINAL verify - zero sensitive markers on any public answer.
-- Expect 0 rows.
SELECT p.party_name, aff.label, afa.char_count,
       (afa.final_text ILIKE '%Marinepad%')  AS affil,
       (afa.final_text ILIKE '%500,000 USD%') AS k500,
       (afa.final_text ILIKE '%executive approval%'
         OR afa.final_text ILIKE '%executive level%') AS cpstage
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND (afa.final_text ILIKE '%Marinepad%'
    OR afa.final_text ILIKE '%500,000 USD%'
    OR afa.final_text ILIKE '%executive approval%'
    OR afa.final_text ILIKE '%executive level%')
ORDER BY p.party_name, aff.label;
