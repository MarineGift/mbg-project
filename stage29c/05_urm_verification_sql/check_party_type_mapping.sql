-- ============================================================================
-- Stage 29-c · 05 · check_party_type_mapping.sql
-- ============================================================================
-- 목적: app.parties.party_type (enum) 에서 urm.parties.party_type_id (FK) 로의
--       매핑 분포 분석 및 누락/불일치 식별.
--
-- 배경:
--   app.parties.party_type enum 값: company | organization | individual | fund | government
--   urm.party_types 7 코드: investor | paper_mill | filler_supplier | buyer |
--                             customer | partner | government_grant
--
--   매핑 logic (Stage 29-b 의 ε / 일반 migration):
--     - fund            → 삭제 (V2 미지원)
--     - organization    → 삭제 (단 3 HQ 는 filler_supplier 로)
--     - individual      → 미이전 (contacts 로 분리)
--     - government      → government_grant
--     - company         → 6 sub-type (profile 테이블 존재 여부로 결정):
--         * investor_profile  있음 → investor
--         * paper_mill_profile 있음 → paper_mill
--         * filler_supplier_profile 있음 → filler_supplier
--         * 그 외 → buyer / customer / partner (module_data 로 판단)
--
-- 실행 환경: Supabase SQL Editor (single SELECT)
--
-- 출력: 4개 섹션 (Q1-Q4) 의 UNION ALL 결과셋
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Q1: app.parties enum 분포 (handoff §7 D group 확인)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'Q1-APP-DIST'::text AS section,
  COALESCE(party_type::text, 'NULL') AS key,
  COUNT(*)::int AS active_cnt,
  SUM(CASE WHEN deleted_at IS NULL THEN 0 ELSE 1 END)::int AS soft_deleted_cnt,
  ''::text AS note
FROM app.parties
GROUP BY party_type
HAVING TRUE  -- placeholder, all groups

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q2: urm.parties → party_types code 분포 (현재 매핑 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'Q2-URM-DIST'::text AS section,
  COALESCE(pt.code, '<NULL party_type_id>') AS key,
  COUNT(*)::int AS active_cnt,
  0::int AS soft_deleted_cnt,
  CASE
    WHEN pt.code IS NULL THEN 'URM 원칙 위반 — DELETE 후보'
    ELSE 'OK — 7 정규 코드'
  END AS note
FROM urm.parties p
LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
WHERE p.deleted_at IS NULL
GROUP BY pt.code

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q3: cross-tab — app enum × urm code 매핑 매트릭스
-- ────────────────────────────────────────────────────────────────────────
-- app.party_type 별로 urm 측에 어떤 code 로 매핑되었는지 (id 기준 JOIN)
SELECT
  'Q3-CROSS-MAP'::text AS section,
  (COALESCE(ap.party_type::text, 'NULL_app') || ' → ' || COALESCE(pt.code, 'NULL_urm'))::text AS key,
  COUNT(*)::int AS active_cnt,
  0::int AS soft_deleted_cnt,
  CASE
    WHEN ap.party_type::text = 'company' AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner')
      THEN 'OK — company sub-type 매핑'
    WHEN ap.party_type::text = 'government' AND pt.code = 'government_grant'
      THEN 'OK — government → government_grant'
    WHEN ap.party_type::text = 'individual'
      THEN 'INVESTIGATE — individual 은 urm 이전 안 됐어야 함'
    WHEN pt.code IS NULL
      THEN 'INVALID — URM 원칙 위반'
    ELSE 'UNUSUAL — 매핑 규칙 외'
  END AS note
FROM app.parties ap
JOIN urm.parties up ON up.id = ap.id
LEFT JOIN urm.party_types pt ON pt.id = up.party_type_id
WHERE ap.deleted_at IS NULL
  AND up.deleted_at IS NULL
GROUP BY ap.party_type, pt.code

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q4: profile 테이블 존재 여부로 검증 — urm.parties 의 sub-type 정합성
-- ────────────────────────────────────────────────────────────────────────
-- party_type=investor 이지만 investor_profile 없음
SELECT
  'Q4-PROFILE-CHECK'::text,
  'investor 인데 investor_profile 없음'::text,
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'investor'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.investor_profile ip WHERE ip.party_id = p.id
     )),
  0,
  'DATA QUALITY — investor 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'investor_profile 있는데 party_type ≠ investor',
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
   JOIN urm.parties p ON p.id = ip.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'investor'),
  0,
  'DATA QUALITY — 역방향 mismatch'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'paper_mill 인데 paper_mill_profile 없음',
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'paper_mill'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.paper_mill_profile pmp WHERE pmp.party_id = p.id
     )),
  0,
  'DATA QUALITY — paper_mill 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'paper_mill_profile 있는데 party_type ≠ paper_mill',
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
   JOIN urm.parties p ON p.id = pmp.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'paper_mill'),
  0,
  'DATA QUALITY — 역방향 mismatch'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'filler_supplier 인데 filler_supplier_profile 없음',
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'filler_supplier'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.filler_supplier_profile fsp WHERE fsp.party_id = p.id
     )),
  0,
  'DATA QUALITY — filler_supplier 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'filler_supplier_profile 있는데 party_type ≠ filler_supplier',
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
   JOIN urm.parties p ON p.id = fsp.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'filler_supplier'),
  0,
  'INFO — 3 HQ 예외 가능 (handoff §5 ε)'

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q5: handoff §7 의 expected 7 코드별 카운트 (참조 자료)
-- ────────────────────────────────────────────────────────────────────────
-- urm.investor_profile 101  → investor 코드 약 101
-- urm.paper_mill_profile 1074 → paper_mill 코드 약 1074
-- urm.filler_supplier_profile 232 → filler_supplier 코드 약 232
-- buyer / customer / partner / government_grant → 잔여 분배
-- total active 1532 = 101 + 1074 + 232 + (buyer/customer/partner/govt 합 ≈ 125)

SELECT
  'Q5-EXPECTED'::text,
  pt.code,
  (SELECT COUNT(*)::int FROM urm.parties p
    WHERE p.party_type_id = pt.id
      AND p.deleted_at IS NULL),
  0,
  CASE pt.code
    WHEN 'investor' THEN 'expect ~101 (investor_profile 카운트와 일치)'
    WHEN 'paper_mill' THEN 'expect ~1074 (paper_mill_profile 카운트와 일치)'
    WHEN 'filler_supplier' THEN 'expect ~232 (filler_supplier_profile 카운트와 일치)'
    WHEN 'buyer' THEN 'expect — 분포 분석 필요'
    WHEN 'customer' THEN 'expect — 분포 분석 필요'
    WHEN 'partner' THEN 'expect — 분포 분석 필요'
    WHEN 'government_grant' THEN 'expect — government enum migration 결과'
    ELSE ''
  END
FROM urm.party_types pt
WHERE pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')

) results
ORDER BY section, key;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. Q1 — app.parties enum 분포 (handoff §7 와 대조)
--    - fund / organization 행 발견 시 정리 미완료 → 즉시 정리
-- 3. Q2 — urm.parties code 분포 (7 코드 외 0 기대)
-- 4. Q3 — app × urm 매핑 cross-tab. note 가 OK 아닌 row 모두 검토.
-- 5. Q4 — profile 무결성 (party_type ↔ profile 테이블 양방향 검증)
-- 6. Q5 — handoff §7 expected 카운트와 대조
--
-- ⚠️  caller code 의 party_type 참조는 모두 JOIN to urm.party_types 패턴 필요.
--     04_column_rename/party_type_join_pattern.ts 참조.
-- ============================================================================
