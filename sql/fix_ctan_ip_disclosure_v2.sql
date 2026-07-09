-- ============================================================
-- fix_ctan_ip_disclosure_v2.sql
-- Supersedes the ownership language in fix_ctan_ip_disclosure.sql
-- after the founder clarified the position on 2026-07-09.
--
-- CORRECTED FACTS:
--   1. The recently filed patent applications have already been
--      assigned to Marinebio Group, Inc. The earlier granted
--      Korean patents remain registered to Marinepad, a Korean
--      affiliate under common ownership and control.
--      <-- VERIFY the exact split before submitting.
--   2. Consideration for the assignment has NOT been paid. That
--      payment is the 500,000 USD patent transfer in use of funds.
--   3. The NDA governing the pending license negotiation names
--      Marinebio Group, Inc. as the party to receive license and
--      royalty payments, and identifies Marinepad as an
--      affiliated company. The counterparty already recognises
--      the US entity as the licensor.
--
-- WHAT CHANGED VERSUS v1:
--   * Dropped the claim that no lien or security interest exists.
--     Unpaid consideration may give the affiliate a claim, so that
--     assertion cannot be made without counsel confirming it.
--   * Ownership is now described as a split, not a blanket
--     Korean registration.
--   * Added the NDA payee designation, which is a genuine strength.
--   * Risk answer now proposes an interim exclusive licence and a
--     closing condition as mitigations.
--
-- Run AFTER seed_ctan_other_and_overview.sql and
-- fix_ctan_ip_disclosure.sql.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. ip_portfolio - the true, split position
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'OWNERSHIP STATUS. The portfolio is mid-transition to the US entity and we state the position plainly. The recently filed patent applications, including the US and PCT filings, have been assigned to Marinebio Group, Inc. The earlier granted Korean patents remain registered to Marinepad, a Korean affiliate under common ownership and control - the same individual is the representative and principal shareholder of both companies. Consideration for the assignment has not yet been paid, and completing the transfer and paying that consideration is the largest single use of proceeds in this round at 500,000 USD. The NDA governing the pending license negotiation already designates Marinebio Group, Inc. as the party to receive license and royalty payments, and identifies Marinepad as an affiliated company, so the commercial counterparty recognises the US entity as the licensor.

GRANTED PATENTS - Korea, KIPO, 5 total, registered to Marinepad pending assignment.
KR 10-1510313 (2015) Preparation method of filler and the paper containing the filler thereby.
KR 10-1535522 (2015) Preparation method of surface-coated filler for paper manufacture and paper containing the same.
KR 10-1742962 (2017) Preparation method of filler using micro-cellulose and calcium compound and paper containing filler prepared by the same.
KR 10-1910649 (2018) Preparation method of filler containing cellulose and the paper containing the filler thereby.
KR 10-2790098 (2025) Method for preparing calcium carbonate filler using crustacea shell and paper containing the calcium carbonate filler.
Related granted: KR 10-2887327 chitin nanofiber.

PENDING APPLICATIONS - 7 total, assigned to Marinebio Group, Inc. Preparation method of paper filler using mixed solution of organic fiber and inorganic compound and use thereof.
KR 10-2023-0092212 Korea. KR 2024/009859 PCT. US 19/396,332 USPTO. National phase entries planned or filed in EU, Japan, China, India and Indonesia.

THIRD-PARTY SUBMISSIONS filed by us: USPTO 18/909,232 and the corresponding EPO application, both citing our own peer-reviewed prior art to block a competitor patent family.

PATENT LICENSES. No executed patent license has been granted to any third party to date. A license and royalty agreement covering the confirmed 9,000-ton order has been approved at executive level by the counterparty and is being documented. No inbound license is required to practice the technology.

COPYRIGHTS AND COPYRIGHT LICENSES. None held and none granted. Our two ACS journal articles are published under the publisher standard terms and function as prior art we can cite rather than as licensed assets.

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028.',
    target_length = 2400, updated_at = now()
WHERE answer_key = 'ip_portfolio' AND variant = 'short';


-- ------------------------------------------------------------
-- 2. risks_mitigations - IP assignment stated accurately,
--    with interim licence and closing condition as remedies
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'IP assignment is incomplete. The recently filed applications are already assigned to Marinebio Group, Inc., but the earlier granted Korean patents remain registered to Marinepad, an affiliate under common ownership, and the consideration for that assignment is unpaid. Mitigation: completing the transfer is the largest single use of proceeds at 500,000 USD, the same individual is representative and principal shareholder of both companies so there is no adverse counterparty, the license NDA already designates Marinebio Group, Inc. as the payee for license and royalty payments, and we are documenting an exclusive worldwide license granted by the affiliate as interim cover. We are prepared to make completion of the assignment a condition of closing. Contract documentation. The license and royalty agreement covering the 9,000-ton order has executive approval and is being documented. Mitigation: the order is already in physical supply and documentation is being executed now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA, the patents stay with us rather than any licensee, and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs, and the same conservatism protects us once FCC is specified at a mill. Design-around risk. Mitigation: 5 granted patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image. Key-person depth - the company is founder-led in the US. Mitigation: this round funds advisory seats and operating support.',
    target_length = 1900, updated_at = now()
WHERE answer_key = 'risks_mitigations' AND variant = 'short';


-- ------------------------------------------------------------
-- 3. valuation_rationale - correct the ownership sentence
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'We are not pricing the company in this round. We are raising on a post-money SAFE with a 10M USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US validation is complete. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalty terms approved at executive level and the definitive agreement under documentation, price validation at 250-350 USD per ton by a major mill, 5 granted patents plus 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. The pending applications are already assigned to Marinebio Group, Inc. The granted Korean patents remain with an affiliate under common ownership and their assignment, funded as the largest single use of proceeds in this round, completes the portfolio. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10M USD cap therefore prices early angels at a substantial discount to the value the validated track alone implies. Tissue, packaging and wallpaper revenue are excluded entirely.',
    updated_at = now()
WHERE answer_key = 'valuation_rationale' AND variant = 'short';


-- ------------------------------------------------------------
-- 4. Push corrected text to bound snapshots and reset is_copied
-- ------------------------------------------------------------
UPDATE app.application_field_answers fa
SET final_text = al.body_en,
    is_copied = false,
    updated_at = now()
FROM app.answer_library al
WHERE fa.answer_id = al.id
  AND al.variant = 'short'
  AND al.answer_key IN ('ip_portfolio','risks_mitigations','valuation_rationale');


-- Verify
SELECT seq, label, field_state, char_count, is_copied
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%'
  AND seq IN (714, 804, 901)
ORDER BY seq;
