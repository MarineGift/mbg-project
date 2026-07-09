-- ============================================================
-- fix_ctan_ip_disclosure.sql
-- Corrects three answers that overstated the current legal status,
-- and adds the IP portfolio answer for step 9 field 901.
--
-- FACTS CONFIRMED BY THE FOUNDER 2026-07-09:
--   1. All 5 granted patents and 7 pending applications are
--      registered to Marinepad, a Korean company under common
--      ownership and control. They are NOT yet assigned to
--      Marinebio Group, Inc.
--   2. The license and royalty agreement covering the 9,000-ton
--      order has executive approval by the counterparty but is
--      still being documented. No executed license exists yet.
--
-- WHY THIS MATTERS: royalties cannot accrue automatically without
-- an executed agreement, and an angel investing in the Delaware
-- entity today does not yet own the patents. Stating this plainly
-- is both accurate and strategically better than being found out
-- in diligence. The 500,000 USD patent transfer already in use of
-- funds is the remedy, so the disclosure reinforces the ask.
--
-- This file updates answer_library AND the already-bound
-- final_text snapshots in application_field_answers.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. traction - remove the automatic accrual claim
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and a global top-3 filler producer is executing it in its existing plant. Royalty terms of 3-5 percent per ton have executive approval by that counterparty and the definitive license agreement is being documented now. Roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP: 5 granted patents and 7 applications across KR, PCT and US, plus 3 SCI papers - and in April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue was independently confirmed by a third-party mill trial. No outside capital has been raised to date.',
    updated_at = now()
WHERE answer_key = 'traction' AND variant = 'short';


-- ------------------------------------------------------------
-- 2. business_model - same correction
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - to be secured by 10-15 year supply contracts. A confirmed 9,000-ton order is executing at 350 USD per ton, royalty terms have executive approval by the counterparty, and the definitive license agreement is being documented. Royalties are near-pure margin, so the business self-funds after launch.',
    updated_at = now()
WHERE answer_key = 'business_model' AND variant = 'short';


-- ------------------------------------------------------------
-- 3. valuation_rationale - same correction, plus IP status
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'We are not pricing the company in this round. We are raising on a post-money SAFE with a 10M USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US validation is complete. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalty terms approved at executive level and the definitive agreement under documentation, price validation at 250-350 USD per ton by a major mill, 5 granted patents plus 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. The patents are currently registered to a Korean company under common ownership and are being assigned to Marinebio Group, Inc. as the largest single use of proceeds in this round. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10M USD cap therefore prices early angels at a substantial discount to the value the validated track alone implies. Tissue, packaging and wallpaper revenue are excluded entirely.',
    updated_at = now()
WHERE answer_key = 'valuation_rationale' AND variant = 'short';


-- ------------------------------------------------------------
-- 4. risks_mitigations - add the IP assignment risk first
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'IP assignment. The patents are currently registered to Marinepad, a Korean company under common ownership and control, and are not yet assigned to Marinebio Group, Inc. Mitigation: the assignment is the largest single use of proceeds in this round at 500,000 USD, both entities share the same representative and principal shareholder so there is no adverse counterparty, and no lien or third-party license encumbers the portfolio. We will complete the assignment as a condition of closing if investors require it. Contract documentation. The license and royalty agreement covering the 9,000-ton order has executive approval and is being documented. Mitigation: the order is already in physical supply, and the founder is executing documentation now. Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - confirmed volume runs through one producer. Mitigation: a second global producer is engaged under NDA, the patents stay with us rather than any licensee, and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy, removing the two biggest switching costs, and the same conservatism protects us once FCC is specified at a mill. Design-around risk. Mitigation: 5 granted patents covering fiber size, structure and additives, our own published science as prior art, and an FCC network structure provable in finished paper under a standard SEM image, so infringement is detectable without factory access. Key-person depth - the company is founder-led in the US. Mitigation: this round funds advisory seats and operating support.',
    target_length = 1700, updated_at = now()
WHERE answer_key = 'risks_mitigations' AND variant = 'short';


-- ------------------------------------------------------------
-- 5. ip_portfolio - the step 9 answer, stated plainly
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'OWNERSHIP STATUS. All 5 granted patents and the 7 pending applications listed below are currently registered to Marinepad, a Korean company under common ownership and control with Marinebio Group, Inc. The same individual is the representative and principal shareholder of both entities. Assignment of the entire portfolio to Marinebio Group, Inc. is in progress and is the largest single use of proceeds in this round at 500,000 USD. No lien, security interest or third-party license encumbers the portfolio.

GRANTED PATENTS - Korea, KIPO, 5 total.
KR 10-1510313 (2015) Preparation method of filler and the paper containing the filler thereby.
KR 10-1535522 (2015) Preparation method of surface-coated filler for paper manufacture and paper containing the same.
KR 10-1742962 (2017) Preparation method of filler using micro-cellulose and calcium compound and paper containing filler prepared by the same.
KR 10-1910649 (2018) Preparation method of filler containing cellulose and the paper containing the filler thereby.
KR 10-2790098 (2025) Method for preparing calcium carbonate filler using crustacea shell and paper containing the calcium carbonate filler.
Related granted: KR 10-2887327 chitin nanofiber.

PENDING APPLICATIONS - 7 total, Preparation method of paper filler using mixed solution of organic fiber and inorganic compound and use thereof.
KR 10-2023-0092212 Korea. KR 2024/009859 PCT. US 19/396,332 USPTO. National phase entries planned or filed in EU, Japan, China, India and Indonesia.

THIRD-PARTY SUBMISSIONS filed by us: USPTO 18/909,232 and the corresponding EPO application, both citing our own peer-reviewed prior art to block a competitor patent family.

PATENT LICENSES. No executed patent license has been granted to any third party to date. A license and royalty agreement covering the confirmed 9,000-ton order has been approved at executive level by the counterparty and is being documented. No inbound license is required to practice the technology.

COPYRIGHTS AND COPYRIGHT LICENSES. None held and none granted. Our two ACS journal articles are published under the publisher standard terms and function as prior art we can cite rather than as licensed assets.

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028.',
    target_length = 2200, updated_at = now()
WHERE answer_key = 'ip_portfolio' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'ip_portfolio', 'IP portfolio with true assignee status',
  'OWNERSHIP STATUS. All 5 granted patents and the 7 pending applications listed below are currently registered to Marinepad, a Korean company under common ownership and control with Marinebio Group, Inc. The same individual is the representative and principal shareholder of both entities. Assignment of the entire portfolio to Marinebio Group, Inc. is in progress and is the largest single use of proceeds in this round at 500,000 USD. No lien, security interest or third-party license encumbers the portfolio.

GRANTED PATENTS - Korea, KIPO, 5 total.
KR 10-1510313 (2015) Preparation method of filler and the paper containing the filler thereby.
KR 10-1535522 (2015) Preparation method of surface-coated filler for paper manufacture and paper containing the same.
KR 10-1742962 (2017) Preparation method of filler using micro-cellulose and calcium compound and paper containing filler prepared by the same.
KR 10-1910649 (2018) Preparation method of filler containing cellulose and the paper containing the filler thereby.
KR 10-2790098 (2025) Method for preparing calcium carbonate filler using crustacea shell and paper containing the calcium carbonate filler.
Related granted: KR 10-2887327 chitin nanofiber.

PENDING APPLICATIONS - 7 total, Preparation method of paper filler using mixed solution of organic fiber and inorganic compound and use thereof.
KR 10-2023-0092212 Korea. KR 2024/009859 PCT. US 19/396,332 USPTO. National phase entries planned or filed in EU, Japan, China, India and Indonesia.

THIRD-PARTY SUBMISSIONS filed by us: USPTO 18/909,232 and the corresponding EPO application, both citing our own peer-reviewed prior art to block a competitor patent family.

PATENT LICENSES. No executed patent license has been granted to any third party to date. A license and royalty agreement covering the confirmed 9,000-ton order has been approved at executive level by the counterparty and is being documented. No inbound license is required to practice the technology.

COPYRIGHTS AND COPYRIGHT LICENSES. None held and none granted. Our two ACS journal articles are published under the publisher standard terms and function as prior art we can cite rather than as licensed assets.

CERTIFICATION. Korea NET New Excellent Technology certificate 2023-0010, valid 2023 to 2028.',
  '특허 등록권자는 한국 Marinepad. 이번 라운드 자금 50만 달러로 Marinebio Group, Inc. 에 이전 예정. Korea NET 인증서 명의도 확인 필요',
  'public', ARRAY['investor','ip'], 'short', 2200,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'ip_portfolio' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 6. Push the corrected text to the bound final_text snapshots.
--    Only for answers not yet copied to the portal.
-- ------------------------------------------------------------
UPDATE app.application_field_answers fa
SET final_text = al.body_en,
    is_copied = false,
    updated_at = now()
FROM app.answer_library al
WHERE fa.answer_id = al.id
  AND al.variant = 'short'
  AND al.answer_key IN ('traction','business_model','valuation_rationale','risks_mitigations');


-- ------------------------------------------------------------
-- 7. Bind ip_portfolio to field 901
-- ------------------------------------------------------------
INSERT INTO app.application_field_answers
  (organization_id, field_id, answer_id, final_text)
SELECT
  ff.organization_id, ff.id, al.id, al.body_en
FROM app.application_form_fields ff
JOIN app.application_forms f ON f.id = ff.form_id
JOIN app.answer_library al
  ON al.organization_id = ff.organization_id
 AND al.answer_key = 'ip_portfolio' AND al.variant = 'short'
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq = 901
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify
SELECT seq, label, field_state, char_count
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%'
  AND seq IN (601, 714, 801, 804, 901)
ORDER BY seq;

SELECT field_state, count(*) AS fields
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND field_id IS NOT NULL
GROUP BY field_state
ORDER BY field_state;
