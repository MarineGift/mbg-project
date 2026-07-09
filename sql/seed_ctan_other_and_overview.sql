-- ============================================================
-- seed_ctan_other_and_overview.sql
-- CTAN application on Dealum, step 9 of 9: Other
-- PLUS backfill of the Overview step (101-119) company facts,
-- sourced from the FinCEN BOIR filing and the stock certificates.
--
-- Sources for the Overview facts:
--   FinCEN BOIR #50000016414371, filed 2026-03-17
--     legal name MARINEBIO GROUP, INC. / Delaware / EIN 37-2222926
--     1108 Nueces St Unit 301, Austin, Texas 78701
--   Stock certificates C-1 and C-2, signed 2026-02-23
--
-- LEFT EMPTY ON PURPOSE (founder input or a file upload):
--   102 company logo, 108 registration date, 117 pitch deck,
--   118 video link, 119 images, 205 team invites,
--   901 IP list (ownership status must be confirmed first),
--   903 additional files, 904 how did you hear about us
--
-- IP OWNERSHIP WARNING: use of funds allocates 500K USD to
-- patent transfer, which implies the patents may not yet be
-- assigned to the Delaware entity. Field 901 must state the
-- true current assignee. Do not guess. Confirm, then bind.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Step 9 fields
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
    (901, 'List of all domestic and foreign patents, patent applications, copyrights, patent licenses and copyright licenses held',
     'textarea', true,
     'FOUNDER INPUT NEEDED - confirm the current assignee of each patent before answering. If patents are still held by founders or a Korean entity, say so plainly',
     'ip_portfolio', 'fill'),
    (902, 'Have you received investment by another angel group that conducted diligence in the past two years',
     'dropdown', true,
     'No. Syndication tag not available for this application',
     'angel_syndication', 'check'),
    (903, 'Additional files',
     'file', false,
     'Attach IR deck, cap table xlsx, patent certificates, ACS papers. NEVER attach NDA documents or anything naming partner companies',
     'additional_files', 'upload'),
    (904, 'How did you hear about us',
     'text', true,
     'FOUNDER INPUT NEEDED - answer truthfully. Capital Factory resident, web search, referral, etc',
     'referral_source', 'fill')
) AS v(seq, label, field_type, is_required, help_text, canonical_key, input_kind)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Answers - step 9
-- ------------------------------------------------------------

-- 2.1 angel_syndication
UPDATE app.answer_library SET body_en = 'No', target_length = 10, updated_at = now()
WHERE answer_key = 'angel_syndication' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'angel_syndication', 'Angel syndication - none',
  'No', '아니오 - 다른 엔젤 그룹의 실사를 받은 적 없음',
  'public', ARRAY['investor','finance'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'angel_syndication' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 3. Overview company facts - answer_library
-- ------------------------------------------------------------
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, v.k, v.t, v.en, v.ko,
  'public', ARRAY['investor','company_facts'], 'short', 80,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
JOIN (VALUES
  ('brand_name',        'Brand name',              'Marinebio Group',        '브랜드명'),
  ('primary_currency',  'Primary currency',        'USD (US Dollar)',        '기본 통화'),
  ('website',           'Website',                 'https://marinebiogroup.com', '웹사이트'),
  ('is_incorporated',   'Incorporated',            'Yes',                    '법인 설립 완료'),
  ('company_legal_name','Legal name',              'Marinebio Group, Inc.',  'BOIR 기준 법인명'),
  ('legal_entity_type', 'Legal entity type',       'C-Corporation',          'Delaware C-Corp'),
  ('hq_country',        'Country',                 'United States',          '국가'),
  ('hq_address_1',      'Address line 1',          '1108 Nueces St',         '주소 1'),
  ('hq_address_2',      'Address line 2',          'Unit 301',               '주소 2'),
  ('hq_city',           'City',                    'Austin',                 '도시'),
  ('hq_state',          'State',                   'Texas',                  '주'),
  ('hq_postal_code',    'Postal code',             '78701',                  '우편번호'),
  ('customer_focus',    'Customer focus',          'B2B',                    '고객 유형'),
  ('founder_role',      'Founder role in team',    'Founder, President and CEO', '창업자 역할'),
  ('team_headcount',    'Number of team members',  '3',                      'CEO, CTO, CPO'),
  ('employee_count',    'Number of employees',     '3',                      '확인 필요 - 급여 지급 기준이면 다를 수 있음'),
  ('team_family_relationships', 'Family relationships', 'No. There are no family relationships among the founders, board members or managers.', '가족관계 없음 - 사실 확인 필요')
) AS v(k, t, en, ko) ON true
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = v.k AND a.variant = 'short');


-- ------------------------------------------------------------
-- 4. Overview narrative answers (longer text)
-- ------------------------------------------------------------

-- 4.1 founder_experience
UPDATE app.answer_library
SET body_en = 'Founder and CEO of Marinebio Group, based in Austin, Texas. Engineering degree, with management experience at Samsung Group, and full responsibility for the commercial strategy, licensing negotiations and US market entry of FCC technology. Deep operating knowledge of the global paper industry - mill hierarchies, calcium carbonate filler markets and the filler supplier ecosystem. Led the commercial validation that produced a confirmed 9,000-ton order at 350 USD per ton, negotiated engagements with two global filler producers under NDA, and built the company intellectual property position of 5 granted patents and 7 applications together with the CTO.',
    target_length = 650, updated_at = now()
WHERE answer_key = 'founder_experience' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'founder_experience', 'Founder relevant experience',
  'Founder and CEO of Marinebio Group, based in Austin, Texas. Engineering degree, with management experience at Samsung Group, and full responsibility for the commercial strategy, licensing negotiations and US market entry of FCC technology. Deep operating knowledge of the global paper industry - mill hierarchies, calcium carbonate filler markets and the filler supplier ecosystem. Led the commercial validation that produced a confirmed 9,000-ton order at 350 USD per ton, negotiated engagements with two global filler producers under NDA, and built the company intellectual property position of 5 granted patents and 7 applications together with the CTO.',
  '창업자 경력 - 파트너 실명 배제. 익명 표기 유지',
  'public', ARRAY['investor','team'], 'short', 650,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'founder_experience' AND a.variant = 'short');

-- 4.2 team_management
UPDATE app.answer_library
SET body_en = 'A three-person executive team covering commercial, R and D, and production. CEO Yun Young Heo (Austin, Texas) leads marketing, product and overall business operations - engineering degree, management experience at Samsung Group. CTO Yung Bum Seo is the original developer of FCC - PhD and postdoctoral research at the State University of New York, professor of paper engineering at Chungnam National University in Korea, more than 50 patents, and co-author of the peer-reviewed ACS papers that established the FCC mechanism. CPO Yun Woo Lee leads production - MS in paper engineering at Chungnam National University, former researcher at a Korean government pulp research institute, co-developer of the technology with more than 30 patents. The CEO drives US commercialization, while the CTO and CPO anchor R and D and production scale-up.',
    target_length = 900, updated_at = now()
WHERE answer_key = 'team_management' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'team_management', 'Management team makeup',
  'A three-person executive team covering commercial, R and D, and production. CEO Yun Young Heo (Austin, Texas) leads marketing, product and overall business operations - engineering degree, management experience at Samsung Group. CTO Yung Bum Seo is the original developer of FCC - PhD and postdoctoral research at the State University of New York, professor of paper engineering at Chungnam National University in Korea, more than 50 patents, and co-author of the peer-reviewed ACS papers that established the FCC mechanism. CPO Yun Woo Lee leads production - MS in paper engineering at Chungnam National University, former researcher at a Korean government pulp research institute, co-developer of the technology with more than 30 patents. The CEO drives US commercialization, while the CTO and CPO anchor R and D and production scale-up.',
  '경영진 3인 구성',
  'public', ARRAY['investor','team'], 'short', 900,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'team_management' AND a.variant = 'short');

-- 4.3 advisory_board
UPDATE app.answer_library
SET body_en = 'We are formalizing our advisory board as part of this round. Today external guidance comes through three channels. A US national paper laboratory engaged under NDA will run independent FCC validation and, on completion, introduce us to major US tissue manufacturers. Senior technical and commercial counterparts at two global filler producers are engaged under NDA at executive level. The company is a resident member of the Capital Factory ecosystem in Austin. Partner names are disclosed in person under NDA. Filling two to three formal advisory seats covering US paper-industry commercial expertise and IP licensing is an explicit goal of this cycle.',
    target_length = 700, updated_at = now()
WHERE answer_key = 'advisory_board' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'advisory_board', 'Advisory board makeup',
  'We are formalizing our advisory board as part of this round. Today external guidance comes through three channels. A US national paper laboratory engaged under NDA will run independent FCC validation and, on completion, introduce us to major US tissue manufacturers. Senior technical and commercial counterparts at two global filler producers are engaged under NDA at executive level. The company is a resident member of the Capital Factory ecosystem in Austin. Partner names are disclosed in person under NDA. Filling two to three formal advisory seats covering US paper-industry commercial expertise and IP licensing is an explicit goal of this cycle.',
  '자문단 구성 중 - 파트너 실명 배제',
  'public', ARRAY['investor','team'], 'short', 700,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'advisory_board' AND a.variant = 'short');

-- 4.4 advisory_board_breakdown
UPDATE app.answer_library
SET body_en = 'Formal advisory seats are in formation, so counts today are as follows. Industry and product technical experts 0 - deep technical expertise sits on the executive team with a professor-level CTO holding more than 50 patents. Industry sales connectors 0. Strategic acquisition connectors 0. IP, regulatory, legal and business experts 0. Investors with sector experience 0. Family members or friends 0. Vacancies 3. Our laboratory and industry relationships perform several of these functions informally, and converting them to formal advisory seats is a near-term priority.',
    target_length = 620, updated_at = now()
WHERE answer_key = 'advisory_board_breakdown' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'advisory_board_breakdown', 'Advisory board breakdown by role',
  'Formal advisory seats are in formation, so counts today are as follows. Industry and product technical experts 0 - deep technical expertise sits on the executive team with a professor-level CTO holding more than 50 patents. Industry sales connectors 0. Strategic acquisition connectors 0. IP, regulatory, legal and business experts 0. Investors with sector experience 0. Family members or friends 0. Vacancies 3. Our laboratory and industry relationships perform several of these functions informally, and converting them to formal advisory seats is a near-term priority.',
  '자문단 유형별 인원 - 실제 자문 확보 시 0 을 갱신할 것',
  'public', ARRAY['investor','team'], 'short', 620,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'advisory_board_breakdown' AND a.variant = 'short');

-- 4.5 team_commitments
UPDATE app.answer_library
SET body_en = 'The CEO is full-time on Marinebio Group. The CTO holds a professorship at Chungnam National University in Korea. Rather than limiting involvement, this anchors company R and D - FCC originated in his university laboratory, and his ongoing academic position underpins our peer-reviewed publications and the prior-art position that recently blocked a competitor patent filing. The CPO is dedicated to production scale-up. We do not anticipate commitments that would limit execution of the plan funded by this round.',
    target_length = 550, updated_at = now()
WHERE answer_key = 'team_commitments' AND variant = 'short';
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'team_commitments', 'Other commitments of key team members',
  'The CEO is full-time on Marinebio Group. The CTO holds a professorship at Chungnam National University in Korea. Rather than limiting involvement, this anchors company R and D - FCC originated in his university laboratory, and his ongoing academic position underpins our peer-reviewed publications and the prior-art position that recently blocked a competitor patent filing. The CPO is dedicated to production scale-up. We do not anticipate commitments that would limit execution of the plan funded by this round.',
  'CPO 풀타임 여부 확인 필요',
  'public', ARRAY['investor','team'], 'short', 550,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id AND a.answer_key = 'team_commitments' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 5. Bindings - every field whose canonical_key now has an answer
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
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- ------------------------------------------------------------
-- 6. Verify: whole application. Remaining empty rows are the
--    founder-input and file-upload fields listed in the header.
-- ------------------------------------------------------------
SELECT seq, label, field_state, char_count
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%'
ORDER BY seq;

SELECT field_state, count(*) AS fields
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND field_id IS NOT NULL
GROUP BY field_state
ORDER BY field_state;
