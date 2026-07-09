-- ============================================================
-- fix_ctan_ip_disclosure_v3.sql
-- Supersedes v1 and v2. Founder clarified the exact position
-- on 2026-07-09.
--
-- PRECISE FACTS:
--   * Marinebio Group, Inc. holds exactly ONE patent asset:
--     the US application US 19/396,332, assigned to it.
--     Consideration is unpaid and is contractually deferred,
--     payable within one year after funding is raised.
--   * The 5 granted patents are Korean, registered to Marinepad,
--     a Korean affiliate under common ownership. Korean patents
--     are enforceable in Korea only.
--   * The PCT and Korean applications also remain with Marinepad.
--   * The NDA for the pending license negotiation designates
--     Marinebio Group, Inc. as the party to receive license and
--     royalty payments, and names Marinepad as an affiliate.
--
-- THE GAP INVESTORS WILL FIND: the 9,000-ton order is supplied
-- in Korea, so the patents that underpin that royalty are the
-- Korean granted patents - which the US entity does not own.
-- The US entity is the contractual payee, not the owner. That is
-- a contract right, not a property right. Disclose it plainly.
--
-- RECOMMENDED REMEDY BEFORE SUBMISSION: execute an exclusive
-- worldwide license granted by Marinepad to Marinebio Group, Inc.
-- covering the granted patents and remaining applications, with
-- sublicensing rights. If that is executed, update the answers
-- below to say so - it materially changes the investment case.
--
-- Run AFTER seed_ctan_other_and_overview.sql, then v1, then v2.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. ip_portfolio - exact position, no overstatement
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'OWNERSHIP STATUS, stated plainly. Marinebio Group, Inc. currently holds one patent asset: the US application US 19/396,332, which has been assigned to it. Consideration for that assignment is unpaid and is contractually deferred, payable within one year after this financing is raised. The 5 granted patents are Korean patents registered to Marinepad, a Korean affiliate under common ownership and control - the same individual is the representative and principal shareholder of both companies. The PCT and Korean applications also remain with Marinepad. Korean patents are enforceable in Korea only. The NDA governing the pending license negotiation designates Marinebio Group, Inc. as the party to receive license and royalty payments and identifies Marinepad as an affiliated company, so the commercial counterparty recognises the US entity as the licensor. Completing the assignment of the remaining portfolio to Marinebio Group, Inc. is the largest single use of proceeds in this round at 500,000 USD. We are documenting an exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, as interim cover until the assignment completes.

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
    target_length = 2800, updated_at = now()
WHERE answer_key = 'ip_portfolio' AND variant = 'short';


-- ------------------------------------------------------------
-- 2. risks_mitigations - lead with the real gap
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'IP is held across two affiliated entities. Marinebio Group, Inc. holds the US patent application. The 5 granted Korean patents and the PCT and Korean applications remain registered to Marinepad, an affiliate under common ownership, and the consideration for transfer is deferred, payable within one year after funding. Because the confirmed 9,000-ton order is supplied in Korea, the patents underpinning that royalty are the Korean ones, so today the US entity is the contractual payee rather than the owner of those patents. Mitigation: the same individual is representative and principal shareholder of both companies, so there is no adverse counterparty. The license NDA already designates Marinebio Group, Inc. as the payee. We are documenting an exclusive worldwide license granted by Marinepad to Marinebio Group, Inc., with sublicensing rights, as interim cover, and we are prepared to make completion of the assignment a condition of closing. The US application, which governs the US tissue track this round funds, is already assigned to the US entity. Contract documentation. The license and royalty agreement covering the 9,000-ton order has executive approval and is being documented. Mitigation: the order is already in physical supply and documentation is being executed now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs. Design-around risk. Mitigation: patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image. Key-person depth - the company is founder-led in the US. Mitigation: this round funds advisory seats and operating support.',
    target_length = 2200, updated_at = now()
WHERE answer_key = 'risks_mitigations' AND variant = 'short';


-- ------------------------------------------------------------
-- 3. traction - qualify the patent count by holder
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and a global top-3 filler producer is executing it in its existing plant. Royalty terms of 3-5 percent per ton have executive approval by that counterparty and the definitive license agreement, naming Marinebio Group, Inc. as payee, is being documented now. Roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP across the group: 5 granted Korean patents and 7 applications across KR, PCT and US, plus 3 SCI papers. The US application is assigned to Marinebio Group, Inc. and the remainder are held by an affiliate under common ownership pending assignment. In April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue was independently confirmed by a third-party mill trial. No outside capital has been raised to date.',
    target_length = 1100, updated_at = now()
WHERE answer_key = 'traction' AND variant = 'short';


-- ------------------------------------------------------------
-- 4. valuation_rationale - correct the ownership sentence again
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'We are not pricing the company in this round. We are raising on a post-money SAFE with a 10M USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US validation is complete. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalty terms approved at executive level and the definitive agreement under documentation, price validation at 250-350 USD per ton by a major mill, a portfolio of 5 granted Korean patents and 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. The US application is assigned to Marinebio Group, Inc. The granted Korean patents remain with an affiliate under common ownership and their assignment, funded as the largest single use of proceeds in this round, completes the portfolio. An exclusive worldwide license granted by the affiliate is being documented as interim cover. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10M USD cap therefore prices early angels at a substantial discount to the value the validated track alone implies. Tissue, packaging and wallpaper revenue are excluded entirely.',
    updated_at = now()
WHERE answer_key = 'valuation_rationale' AND variant = 'short';


-- ------------------------------------------------------------
-- 5. Push corrected text to bound snapshots and reset is_copied
-- ------------------------------------------------------------
UPDATE app.application_field_answers fa
SET final_text = al.body_en,
    is_copied = false,
    updated_at = now()
FROM app.answer_library al
WHERE fa.answer_id = al.id
  AND al.variant = 'short'
  AND al.answer_key IN ('ip_portfolio','risks_mitigations','traction','valuation_rationale');


-- Verify
SELECT seq, label, field_state, char_count, is_copied
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%'
  AND seq IN (714, 801, 804, 901)
ORDER BY seq;
