-- ============================================================
-- seed_ctan_finance.sql
-- CTAN application on Dealum, step 7 of 9: Finance
--
-- ROUND STRUCTURE DECISION (2026-07-09): capped post-money SAFE.
--   Reason: pricing the company before the US laboratory data
--   exists is the wrong order. The SAFE defers pricing until the
--   validation that justifies it is complete.
--   Capital seeking = 1,000,000 USD total round size
--   First close    = 100,000 USD, funds the US national-lab test
--   Valuation cap  = 10,000,000 USD  <- change here if renegotiated
--   Discount       = 20 percent
--   Pre and post money fields do not apply to a SAFE.
--
-- Fields whose values only the founder knows (completed-financials
-- month, revenue, burn, cash, prior contributions) are seeded WITHOUT
-- an answer on purpose. They will show as field_state = empty in the
-- UI until filled. Never guess financial figures for an investor form.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Fields 701-721
-- ------------------------------------------------------------
INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id, f.id, v.seq, v.label, v.field_type, NULL::integer,
  v.is_required, v.help_text, v.canonical_key, v.input_kind, 'css'
FROM app.application_forms f
JOIN (
  VALUES
    (701, 'What is the most recent month for which you have completed financials',
     'text', true, 'FOUNDER INPUT NEEDED - month of the last closed books', 'financials_month', 'fill'),
    (702, 'What is your total revenue over the past 12 months ($)',
     'number', true, 'FOUNDER INPUT NEEDED - cash actually received, not contracted', 'revenue_ttm', 'fill'),
    (703, 'What is your monthly recurring revenue MRR ($)',
     'number', true, 'Royalty income is recurring but not MRR in the SaaS sense', 'mrr', 'fill'),
    (704, 'What is your current monthly burn rate ($)',
     'number', true, 'FOUNDER INPUT NEEDED - revenue minus costs, 0 if cash-flow positive', 'burn_rate', 'fill'),
    (705, 'Last month total expenses as a negative number, comma, last month income as a positive number',
     'text', true, 'FOUNDER INPUT NEEDED - example -8000, 0', 'last_month_pl', 'fill'),
    (706, 'Current cash on hand ($)',
     'number', true, 'FOUNDER INPUT NEEDED', 'cash_on_hand', 'fill'),
    (707, 'Has the company received any funding or investments to date',
     'dropdown', true, 'No outside capital raised - founder shares only', 'has_prior_funding', 'select_option'),
    (708, 'How much funding and investment have you received so far in total ($)',
     'number', true, 'Include equity and quasi-equity', 'prior_funding_total', 'fill'),
    (709, 'Amounts invested by friends, family, founders, executives and arms-length investors prior to this round',
     'textarea', true, 'FOUNDER INPUT NEEDED - confirm whether any founder cash was contributed', 'prior_investors', 'fill'),
    (710, 'What type of investment instrument are you using for this raise',
     'dropdown', true, 'Post-money SAFE with a valuation cap', 'instrument_type', 'select_option'),
    (711, 'Capital seeking ($)',
     'number', true, 'Total round size, not the first close', 'capital_seeking', 'fill'),
    (712, 'What pre-money valuation are you expecting in the current funding round ($)',
     'text', false, 'Not applicable to a SAFE - enter N/A if the form allows', 'pre_money', 'fill'),
    (713, 'What post-money valuation are you expecting in the current funding round ($)',
     'text', false, 'Not applicable to a SAFE - enter N/A if the form allows', 'post_money', 'fill'),
    (714, 'Valuation calculation details - how did you calculate the valuation',
     'textarea', true, NULL, 'valuation_rationale', 'fill'),
    (715, 'Are you raising a pre-money SAFE or a post-money SAFE',
     'dropdown', true, 'Post-money SAFE', 'safe_type', 'select_option'),
    (716, 'Valuation cap ($)',
     'number', true, 'Change this number if the cap is renegotiated with a lead investor', 'valuation_cap', 'fill'),
    (717, 'Instrument discount rate (%)',
     'number', false, 'Investor receives the better of cap or discount', 'discount_rate', 'fill'),
    (718, 'How much of the current funding round have you already raised ($)',
     'number', true, 'Total commitments collected', 'already_raised', 'fill'),
    (719, 'What are your deal terms for investors',
     'textarea', true, 'Terms negotiable with a lead investor - not legal advice', 'deal_terms', 'fill'),
    (720, 'What will be accomplished with the investment and how it will be used',
     'textarea', true, 'Provide breakdown', 'use_of_funds', 'fill'),
    (721, 'Cap table (xlsx, csv)',
     'file', true, 'Attach Marinebio_Cap_Table_2026-07-09.xlsx - includes actual shareholder names', 'cap_table', 'upload')
) AS v(seq, label, field_type, is_required, help_text, canonical_key, input_kind)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Answers - only the ones that are known and defensible
-- ------------------------------------------------------------

-- 2.1 mrr
UPDATE app.answer_library SET body_en = '0', target_length = 10, updated_at = now()
WHERE answer_key = 'mrr' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'mrr', 'MRR - not applicable to a royalty licensor',
  '0',
  '0 - 로열티는 반복 수익이지만 SaaS식 MRR 개념이 아님. 0으로 두고 business model 답변에서 설명',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'mrr' AND a.variant = 'short');

-- 2.2 has_prior_funding
UPDATE app.answer_library SET body_en = 'No', target_length = 10, updated_at = now()
WHERE answer_key = 'has_prior_funding' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'has_prior_funding', 'Prior funding - none',
  'No', '아니오 - 외부 자본 조달 이력 없음. 창업자 보통주만 발행',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'has_prior_funding' AND a.variant = 'short');

-- 2.3 prior_funding_total
UPDATE app.answer_library SET body_en = '0', target_length = 10, updated_at = now()
WHERE answer_key = 'prior_funding_total' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'prior_funding_total', 'Prior funding total - zero',
  '0', '0 - 외부 자본 없음',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'prior_funding_total' AND a.variant = 'short');

-- 2.4 instrument_type
UPDATE app.answer_library SET body_en = 'Post-money SAFE with a valuation cap', target_length = 60, updated_at = now()
WHERE answer_key = 'instrument_type' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'instrument_type', 'Instrument - capped post-money SAFE',
  'Post-money SAFE with a valuation cap',
  '밸류에이션 캡이 있는 post-money SAFE',
  'public', ARRAY['investor','finance'], 'short', 60,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'instrument_type' AND a.variant = 'short');

-- 2.5 capital_seeking
UPDATE app.answer_library SET body_en = '1000000', target_length = 10, updated_at = now()
WHERE answer_key = 'capital_seeking' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'capital_seeking', 'Capital seeking - total round size',
  '1000000',
  '1000000 - Dealum 필드 설명이 total round size 이므로 라운드 전체 규모. 100K 는 first close',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'capital_seeking' AND a.variant = 'short');

-- 2.6 pre_money / post_money (not applicable to a SAFE)
UPDATE app.answer_library SET body_en = 'N/A', target_length = 10, updated_at = now()
WHERE answer_key IN ('pre_money','post_money') AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, v.k, v.t, 'N/A',
  'SAFE 이므로 해당 없음. 0 을 넣지 말 것 - 0 달러 밸류로 읽힘',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
JOIN (VALUES
  ('pre_money',  'Pre-money valuation - N/A for a SAFE'),
  ('post_money', 'Post-money valuation - N/A for a SAFE')
) AS v(k, t) ON true
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = v.k AND a.variant = 'short');

-- 2.7 safe_type
UPDATE app.answer_library SET body_en = 'Post-money SAFE', target_length = 30, updated_at = now()
WHERE answer_key = 'safe_type' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'safe_type', 'SAFE type - post-money',
  'Post-money SAFE', 'Post-money SAFE',
  'public', ARRAY['investor','finance'], 'short', 30,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'safe_type' AND a.variant = 'short');

-- 2.8 valuation_cap   <-- CHANGE THIS NUMBER IF THE CAP IS RENEGOTIATED
UPDATE app.answer_library SET body_en = '10000000', target_length = 10, updated_at = now()
WHERE answer_key = 'valuation_cap' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'valuation_cap', 'Valuation cap - 10M USD post-money',
  '10000000',
  '10000000 - 리드 엔젤 협상으로 변경 가능. 변호사 검토 필요',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'valuation_cap' AND a.variant = 'short');

-- 2.9 discount_rate
UPDATE app.answer_library SET body_en = '20', target_length = 10, updated_at = now()
WHERE answer_key = 'discount_rate' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'discount_rate', 'Discount rate - 20 percent',
  '20', '20 - 캡과 할인 중 투자자에게 유리한 쪽 적용',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'discount_rate' AND a.variant = 'short');

-- 2.10 already_raised
UPDATE app.answer_library SET body_en = '0', target_length = 10, updated_at = now()
WHERE answer_key = 'already_raised' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'already_raised', 'Already raised this round - zero',
  '0', '0 - 확보된 커밋이 생기면 즉시 갱신할 것',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'already_raised' AND a.variant = 'short');

-- 2.11 valuation_rationale
UPDATE app.answer_library
SET body_en = 'We are not pricing the company in this round. We are raising on a post-money SAFE with a 10M USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US validation is complete. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalties accruing automatically, price validation at 250-350 USD per ton by a major mill, 5 granted patents plus 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10M USD cap therefore prices early angels at a substantial discount to the value the validated track alone implies, which is the compensation we owe the investors who move before the US data exists. Tissue, packaging and wallpaper revenue are excluded entirely.',
    target_length = 1100, updated_at = now()
WHERE answer_key = 'valuation_rationale' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'valuation_rationale', 'Valuation rationale - SAFE cap basis',
  'We are not pricing the company in this round. We are raising on a post-money SAFE with a 10M USD valuation cap and a 20 percent discount, so the price is set at the next priced round once the independent US validation is complete. The cap is anchored on assets already in hand: a confirmed 9,000-ton order executing at 350 USD per ton with royalties accruing automatically, price validation at 250-350 USD per ton by a major mill, 5 granted patents plus 7 applications across KR, PCT and US, and two peer-reviewed ACS papers co-authored by our CTO that recently served as the blocking prior art that defeated a competitor patent filing. Our validated royalty track projects 22.4M USD of Year-3 royalty, and royalty streams are near-pure margin, typically trading at 5-15x. A 10M USD cap therefore prices early angels at a substantial discount to the value the validated track alone implies, which is the compensation we owe the investors who move before the US data exists. Tissue, packaging and wallpaper revenue are excluded entirely.',
  '이번 라운드에서는 회사 가격을 확정하지 않습니다. 1000만 달러 밸류에이션 캡과 20퍼센트 할인의 post-money SAFE로 조달하며, 미국 독립 검증 완료 후 다음 가격 라운드에서 가격이 결정됩니다. 캡의 근거는 이미 보유한 자산입니다. 톤당 350달러로 집행 중인 확정 9,000톤 주문, 주요 제지사의 톤당 250-350달러 가격 검증, 등록 특허 5건과 KR/PCT/US 출원 7건, 그리고 최근 경쟁사 특허 출원을 무력화한 선행기술로 인용된 CTO 공저 ACS 논문 2편입니다.',
  'public', ARRAY['investor','finance'], 'short', 1100,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'valuation_rationale' AND a.variant = 'short');

-- 2.12 deal_terms
UPDATE app.answer_library
SET body_en = 'Post-money SAFE, 1,000,000 USD total round size with rolling closes. A first close of 100,000 USD funds the independent US national-laboratory validation immediately. Valuation cap 10,000,000 USD post-money, 20 percent discount, investor receives whichever is more favorable. Most favored nation clause for early investors. Terms are negotiable with a lead investor. The cap table is clean: 8,500,000 founder common shares issued and no preferred stock, options, warrants, notes or other convertible securities outstanding, with 15 percent of the fully diluted equity authorized and unissued for this financing. After launch, royalty income is expected to self-fund operations, so no further dilutive round is planned.',
    target_length = 750, updated_at = now()
WHERE answer_key = 'deal_terms' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'deal_terms', 'Deal terms - capped post-money SAFE',
  'Post-money SAFE, 1,000,000 USD total round size with rolling closes. A first close of 100,000 USD funds the independent US national-laboratory validation immediately. Valuation cap 10,000,000 USD post-money, 20 percent discount, investor receives whichever is more favorable. Most favored nation clause for early investors. Terms are negotiable with a lead investor. The cap table is clean: 8,500,000 founder common shares issued and no preferred stock, options, warrants, notes or other convertible securities outstanding, with 15 percent of the fully diluted equity authorized and unissued for this financing. After launch, royalty income is expected to self-fund operations, so no further dilutive round is planned.',
  'post-money SAFE, 총 라운드 100만 달러, 순차 클로징. 첫 10만 달러 클로징으로 미국 국립연구소 독립 검증 즉시 착수. 캡 1000만 달러, 할인 20퍼센트, 투자자에게 유리한 쪽 적용. 초기 투자자 MFN 조항. 리드 투자자와 협상 가능. 주의: 법률 자문 아님. 실제 문서는 변호사 검토 필요',
  'public', ARRAY['investor','finance'], 'short', 750,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'deal_terms' AND a.variant = 'short');

-- 2.13 use_of_funds
UPDATE app.answer_library
SET body_en = 'Total round 1,000,000 USD. 500,000 USD - patent transfer and global IP prosecution and defense, the core asset of a licensing business. 200,000 USD - independent validation at a US national paper laboratory, which converts our Korean commercial data to US data and, on completion, the laboratory introduces us directly to the major US tissue manufacturers. 300,000 USD - operations: a lean US commercial team, legal, and licensee and mill business development. Sequencing matters: the first 100,000 USD closed goes straight to the US laboratory test, so the tissue track unlocks before the full round completes. That test is the single milestone that converts our technology proof to US buyer proof. After launch, royalties are near-pure margin and are expected to self-fund the business.',
    target_length = 850, updated_at = now()
WHERE answer_key = 'use_of_funds' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'use_of_funds', 'Use of funds - 500K IP, 200K testing, 300K ops',
  'Total round 1,000,000 USD. 500,000 USD - patent transfer and global IP prosecution and defense, the core asset of a licensing business. 200,000 USD - independent validation at a US national paper laboratory, which converts our Korean commercial data to US data and, on completion, the laboratory introduces us directly to the major US tissue manufacturers. 300,000 USD - operations: a lean US commercial team, legal, and licensee and mill business development. Sequencing matters: the first 100,000 USD closed goes straight to the US laboratory test, so the tissue track unlocks before the full round completes. That test is the single milestone that converts our technology proof to US buyer proof. After launch, royalties are near-pure margin and are expected to self-fund the business.',
  '총 100만 달러. 50만 - 특허 이전 및 글로벌 IP 출원과 방어. 20만 - 미국 국립 제지연구소 독립 검증. 30만 - 운영. 첫 10만 클로징은 곧바로 미국 랩 테스트에 투입되어 전체 라운드 완료 전에 티슈 트랙이 열림',
  'public', ARRAY['investor','finance'], 'short', 850,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'use_of_funds' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 3. Bindings - only fields whose canonical_key has an answer.
--    701, 702, 704, 705, 706, 709, 721 stay empty on purpose.
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
  AND ff.seq BETWEEN 701 AND 721
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify: finance block, empty rows are the founder-input fields
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq BETWEEN 701 AND 799
ORDER BY seq;
