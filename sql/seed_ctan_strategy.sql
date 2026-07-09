-- ============================================================
-- seed_ctan_strategy.sql
-- CTAN application on Dealum, step 8 of 9: Strategy
-- Six fields: achievements, go-to-market, milestones, risks,
-- exit strategy (multi-select), likely acquirers.
--
-- NDA BOUNDARY (critical):
--   * go_to_market names the partners ONLY as two global filler
--     producers engaged under NDA - never by name.
--   * likely_acquirers names Omya, Imerys, MTI, Kimberly-Clark
--     etc as market actors. That is public deck content.
--   * NEVER connect the two. No phrasing that implies any named
--     company is a current partner. Partner names in person only.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Fields 801-806
-- ------------------------------------------------------------
INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id, f.id, v.seq, v.label, v.field_type, NULL::integer,
  true, v.help_text, v.canonical_key, v.input_kind, 'css'
FROM app.application_forms f
JOIN (
  VALUES
    (801, 'What have you achieved so far - revenue, traction, major investments',
     'textarea', 'Summary for the short profile', 'traction', 'fill'),
    (802, 'Please describe your company go-to-market strategy',
     'textarea', 'Online or e-commerce, direct or inside sales, contracted outside sales, third party distribution, joint venture or co-marketing partner',
     'go_to_market', 'fill'),
    (803, 'What are your next milestones and when are you planning to reach them',
     'textarea', 'Product development, IP, customer traction. Include measurable milestones and approximate dates',
     'milestones', 'fill'),
    (804, 'What are the risks and what steps will you take to mitigate them',
     'textarea', NULL, 'risks_mitigations', 'fill'),
    (805, 'What is your exit strategy',
     'dropdown', 'Choose all that apply. Do not choose IPO - hard to defend for a royalty licensor',
     'exit_strategy', 'check'),
    (806, 'Which companies would be most likely to acquire you and why',
     'textarea', 'CAUTION: naming these companies as market actors is public deck content. Never imply any of them is a current NDA partner',
     'likely_acquirers', 'fill')
) AS v(seq, label, field_type, help_text, canonical_key, input_kind)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Answers
-- ------------------------------------------------------------

-- 2.1 traction
UPDATE app.answer_library
SET body_en = 'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and is executing now through a global top-3 filler producer in its existing plant, with royalties accruing automatically as they supply the mill - roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP: 5 granted patents and 7 applications across KR, PCT and US, plus 3 SCI papers - and in April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue itself was independently confirmed by a third-party mill trial. No outside capital has been raised to date.',
    target_length = 850, updated_at = now()
WHERE answer_key = 'traction' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'traction', 'Traction - achievements to date',
  'Technology validated at commercial mill scale on a mill production machine, in both GCC and PCC systems. A 9,000-ton order is confirmed at 350 USD per ton and is executing now through a global top-3 filler producer in its existing plant, with royalties accruing automatically as they supply the mill - roughly 10,000 additional tons are in motion. Price validation at 250-350 USD per ton was approved by a major mill, against wood pulp at 600-800. IP: 5 granted patents and 7 applications across KR, PCT and US, plus 3 SCI papers - and in April 2026 a competitor filing to patent FCC for tissue was rejected by the Korean patent office, citing our CTO peer-reviewed paper as prior art. Tissue itself was independently confirmed by a third-party mill trial. No outside capital has been raised to date.',
  '상업용 제지기 실기 규모에서 GCC, PCC 양쪽 시스템 검증 완료. 톤당 350달러로 확정된 9,000톤 주문이 글로벌 top-3 충전제 제조사의 기존 공장을 통해 집행 중이며 로열티가 자동 발생. 약 10,000톤 추가 진행 중. 주요 제지사가 톤당 250-350달러 가격 승인(펄프 600-800 대비). 등록특허 5건, 출원 7건(KR/PCT/US), SCI 논문 3편. 2026년 4월 경쟁사의 티슈용 FCC 특허 출원이 우리 CTO 논문을 선행기술로 인용하며 KIPO에서 거절됨. 외부 자본 조달 이력 없음',
  'public', ARRAY['investor','pitch_core'], 'short', 850,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'traction' AND a.variant = 'short');

-- 2.2 go_to_market
UPDATE app.answer_library
SET body_en = 'Third-party distribution through technology licensing. We do not manufacture or sell filler. Filler producers who already supply the mills license FCC, make it in their existing plants with no new capex, and pay a royalty on every ton sold - so their sales force becomes ours, and one licensee brings dozens of mill customers. Founder-led direct business development opens each licensee and anchor mill relationship, and technical validation at national laboratories plus industry conferences is our demand-generation channel. Two global filler producers are engaged under NDA, one of which is already supplying the confirmed order. Once the US laboratory validation is complete, the laboratory introduces us directly to major US tissue manufacturers, opening the second track.',
    target_length = 800, updated_at = now()
WHERE answer_key = 'go_to_market' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'go_to_market', 'Go-to-market - licensing via third-party distribution',
  'Third-party distribution through technology licensing. We do not manufacture or sell filler. Filler producers who already supply the mills license FCC, make it in their existing plants with no new capex, and pay a royalty on every ton sold - so their sales force becomes ours, and one licensee brings dozens of mill customers. Founder-led direct business development opens each licensee and anchor mill relationship, and technical validation at national laboratories plus industry conferences is our demand-generation channel. Two global filler producers are engaged under NDA, one of which is already supplying the confirmed order. Once the US laboratory validation is complete, the laboratory introduces us directly to major US tissue manufacturers, opening the second track.',
  '기술 라이선스를 통한 제3자 유통. 제조나 판매를 직접 하지 않음. 파트너는 익명 표기 유지할 것',
  'public', ARRAY['investor','pitch_core'], 'short', 800,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'go_to_market' AND a.variant = 'short');

-- 2.3 milestones
UPDATE app.answer_library
SET body_en = 'Q3 2026 - close the first 100,000 USD and start independent FCC validation at a US national paper laboratory. Q4 2026 - complete that testing and receive the laboratory introductions to major US tissue manufacturers. Q4 2026 - first royalty revenue recognized on the 9,000-ton order as supply ramps. Q4 2026 - complete the patent transfer to the US entity and advance the USPTO application. H1 2027 - convert approximately 10,000 tons in motion to a second confirmed order, and sign the first tissue trial with a US manufacturer. 2027 - reach the 0.29M-ton Year-1 royalty volume on the validated track. Measurable gates: laboratory report issued, first royalty payment received, tissue trial agreement signed.',
    target_length = 750, updated_at = now()
WHERE answer_key = 'milestones' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'milestones', 'Next milestones with dates and gates',
  'Q3 2026 - close the first 100,000 USD and start independent FCC validation at a US national paper laboratory. Q4 2026 - complete that testing and receive the laboratory introductions to major US tissue manufacturers. Q4 2026 - first royalty revenue recognized on the 9,000-ton order as supply ramps. Q4 2026 - complete the patent transfer to the US entity and advance the USPTO application. H1 2027 - convert approximately 10,000 tons in motion to a second confirmed order, and sign the first tissue trial with a US manufacturer. 2027 - reach the 0.29M-ton Year-1 royalty volume on the validated track. Measurable gates: laboratory report issued, first royalty payment received, tissue trial agreement signed.',
  '2026 Q3 첫 10만 달러 클로징과 미국 국립 제지연구소 검증 착수. Q4 테스트 완료 및 티슈 제조사 소개, 9,000톤 주문 첫 로열티 인식, 특허 이전 완료. 2027 상반기 두 번째 확정 주문과 첫 티슈 트라이얼 계약. 날짜는 실제 계획에 맞게 조정할 것',
  'public', ARRAY['investor','pitch_core'], 'short', 750,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'milestones' AND a.variant = 'short');

-- 2.4 risks_mitigations
UPDATE app.answer_library
SET body_en = 'Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - our confirmed revenue runs through one producer. Mitigation: a second global producer is engaged under NDA, the patents are held by us and not by any licensee, and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy from, which removes the two biggest switching costs, and the same conservatism protects us once FCC is specified at a mill. IP challenge or design-around. Mitigation: 5 granted patents covering fiber size, structure and additives, our own published science as prior art, and the fact that the FCC network structure is provable in the finished paper under a standard SEM image, so infringement is detectable without factory access. Key-person and team depth - the company is founder-led in the US. Mitigation: this round funds advisory seats and operating support.',
    target_length = 1150, updated_at = now()
WHERE answer_key = 'risks_mitigations' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'risks_mitigations', 'Risks with mitigations',
  'Validation is Korean, buyers are American. Mitigation: the US national-laboratory test funded by this round produces US data and ends in direct introductions to US tissue makers. Licensee concentration - our confirmed revenue runs through one producer. Mitigation: a second global producer is engaged under NDA, the patents are held by us and not by any licensee, and supply contracts run 10-15 years. Adoption pace - the paper industry is conservative and mills qualify materials slowly. Mitigation: FCC requires no new equipment and is sold by suppliers the mills already buy from, which removes the two biggest switching costs, and the same conservatism protects us once FCC is specified at a mill. IP challenge or design-around. Mitigation: 5 granted patents covering fiber size, structure and additives, our own published science as prior art, and the fact that the FCC network structure is provable in the finished paper under a standard SEM image, so infringement is detectable without factory access. Key-person and team depth - the company is founder-led in the US. Mitigation: this round funds advisory seats and operating support.',
  '리스크 5가지와 완화책: 검증의 현지화, 라이선시 집중, 도입 속도, IP 우회, 핵심인력 의존',
  'public', ARRAY['investor','pitch_core'], 'short', 1150,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'risks_mitigations' AND a.variant = 'short');

-- 2.5 exit_strategy (multi-select on the portal - tick these)
UPDATE app.answer_library
SET body_en = 'Strategic acquisition (primary). Secondary sale to a later-stage investor. Royalty and licensing income distributed to shareholders. Do not select IPO.',
    target_length = 200, updated_at = now()
WHERE answer_key = 'exit_strategy' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'exit_strategy', 'Exit strategy - tick these options',
  'Strategic acquisition (primary). Secondary sale to a later-stage investor. Royalty and licensing income distributed to shareholders. Do not select IPO.',
  '전략적 인수(주), 후기 투자자 대상 세컨더리, 로열티 수익 배분. IPO 는 선택하지 말 것 - 로열티 라이선서 모델과 불일치',
  'public', ARRAY['investor','finance'], 'short', 200,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'exit_strategy' AND a.variant = 'short');

-- 2.6 likely_acquirers
UPDATE app.answer_library
SET body_en = 'The most likely acquirers are the industrial mineral producers whose core business FCC upgrades: Omya, Imerys, Minerals Technologies (Specialty Minerals), and regional producers such as Mississippi Lime. For them FCC converts a commodity mineral sold at 100-300 USD per ton to a pulp-replacement product sold at 250-350, defends their filler position against a technology they cannot design around, and eliminates the royalty they would otherwise pay in perpetuity - acquiring the patents is cheaper than licensing them at scale. A second class of acquirer is the large tissue and hygiene manufacturers - Kimberly-Clark, Procter and Gamble, Georgia-Pacific - for whom FCC creates a cost and sustainability advantage in a category that has never used filler, and exclusivity there would be worth more than the license fee. Specialty chemical groups serving papermaking are a third path. All of these buy patents rather than plants, which suits an asset-light licensor.',
    target_length = 1000, updated_at = now()
WHERE answer_key = 'likely_acquirers' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'likely_acquirers', 'Likely acquirers - public market actors only',
  'The most likely acquirers are the industrial mineral producers whose core business FCC upgrades: Omya, Imerys, Minerals Technologies (Specialty Minerals), and regional producers such as Mississippi Lime. For them FCC converts a commodity mineral sold at 100-300 USD per ton to a pulp-replacement product sold at 250-350, defends their filler position against a technology they cannot design around, and eliminates the royalty they would otherwise pay in perpetuity - acquiring the patents is cheaper than licensing them at scale. A second class of acquirer is the large tissue and hygiene manufacturers - Kimberly-Clark, Procter and Gamble, Georgia-Pacific - for whom FCC creates a cost and sustainability advantage in a category that has never used filler, and exclusivity there would be worth more than the license fee. Specialty chemical groups serving papermaking are a third path. All of these buy patents rather than plants, which suits an asset-light licensor.',
  '인수 후보를 시장 참여자로서 실명 언급하는 것은 덱 9p, 28-29p 공개 내용이라 안전. 단 이들 중 누구도 현재 NDA 파트너라는 암시를 절대 하지 말 것',
  'public', ARRAY['investor','pitch_core'], 'short', 1000,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'likely_acquirers' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 3. Bindings 801-806
-- ------------------------------------------------------------
INSERT INTO app.application_field_answers
  (organization_id, field_id, answer_id, final_text)
SELECT
  ff.organization_id, ff.id, al.id, al.body_en
FROM app.application_form_fields ff
JOIN app.application_forms f ON f.id = ff.form_id
JOIN app.answer_library al
  ON al.organization_id = ff.organization_id
 AND al.answer_key = ff.canonical_key AND al.variant = 'short'
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq BETWEEN 801 AND 806
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify: whole application, ordered. empty rows are founder-input only.
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq >= 300
ORDER BY seq;
