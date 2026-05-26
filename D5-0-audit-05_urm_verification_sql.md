### Subdir: `05_urm_verification_sql`

#### `check_party_type_mapping.sql` (10328 bytes)

```sql
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
```

#### `cleanup_non_urm_data.sql` (14951 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · cleanup_non_urm_data.sql
-- ============================================================================
-- 목적: 사용자 명시 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 의 실행 SQL.
--       identify_non_urm_data.sql 로 위반 row 확인 후 본 파일의 statement 들을
--       하나씩 실행.
--
-- 실행 환경: Supabase SQL Editor (single statement only, no BEGIN/COMMIT)
--
-- ⚠️ 주의:
--   - 각 statement 는 독립 실행. 반드시 [PRE] / [DELETE] / [POST] 순서.
--   - [PRE] 로 영향 row 개수 확인 → 0 이면 [DELETE] skip 가능
--   - [POST] 로 결과 검증 → 0 이어야 정상
--   - 본 SQL 의 모든 DELETE 는 사용자 원칙으로 정당화됨. 별도 승인 불요.
-- ============================================================================


-- ============================================================================
-- §A. urm.parties.party_type_id IS NULL 또는 7 코드 외 — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Parties 는 반드시 7 정규 코드 중 하나.

-- [A-PRE] 영향 row 확인
SELECT 'A-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS null_count,
  (SELECT COUNT(*) FROM urm.parties p
   WHERE p.party_type_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.party_types pt
       WHERE pt.id = p.party_type_id
         AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
     )) AS invalid_code_count;

-- [A-DELETE-1] NULL party_type_id row 삭제
-- ⚠️ 실행 전 [A-PRE] 의 null_count 확인. 0 이면 skip.
DELETE FROM urm.parties
WHERE party_type_id IS NULL;

-- [A-DELETE-2] 7 정규 코드 외 row 삭제
DELETE FROM urm.parties
WHERE party_type_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM urm.party_types pt
    WHERE pt.id = urm.parties.party_type_id
      AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
  );

-- [A-POST] 검증
SELECT 'A-POST' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS null_count_after,
  (SELECT COUNT(*) FROM urm.parties p
   WHERE p.party_type_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.party_types pt
       WHERE pt.id = p.party_type_id
         AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
     )) AS invalid_code_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §B. app.parties.party_type IN ('fund', 'organization') — DELETE
-- ============================================================================
-- 위반: handoff §8 carry-forward — V2 미지원. ε hard-delete 후 잔재.
-- ⚠️ 단 3 HQ (Carmeuse / Schaefer Kalk / Sibelco) 의 urm.filler_supplier_profile 은
--    유지. app.parties 측만 삭제.

-- [B-PRE]
SELECT 'B-PRE' AS stage,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') AS fund_count,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') AS org_count;

-- [B-DELETE-1] fund
DELETE FROM app.parties WHERE party_type::text = 'fund';

-- [B-DELETE-2] organization
-- 단 3 HQ id 보존이 urm.filler_supplier_profile 에 있는지 확인 (FK CASCADE 없음 — single direction)
DELETE FROM app.parties WHERE party_type::text = 'organization';

-- [B-POST]
SELECT 'B-POST' AS stage,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') AS fund_count_after,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') AS org_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §C. urm.contacts.firm_party_id orphan — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Contacts → Parties FK 무결성.
-- FK constraint 가 있으면 정상 0. 만약 있다면 FK 가 deferred 였거나 누락된 상태.

-- [C-PRE]
SELECT 'C-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
   )) AS orphan_count;

-- [C-DELETE]
DELETE FROM urm.contacts
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.contacts.firm_party_id
);

-- [C-POST]
SELECT 'C-POST' AS stage,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
   )) AS orphan_count_after;
-- expect: 0


-- ============================================================================
-- §D. urm.contacts_history orphan — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Contact_history → Contacts FK + Parties FK 무결성.

-- [D-PRE]
SELECT 'D-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
   )) AS contact_orphan_count,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
   )) AS firm_orphan_count;

-- [D-DELETE-1] contact_id orphan
DELETE FROM urm.contacts_history
WHERE NOT EXISTS (
  SELECT 1 FROM urm.contacts c WHERE c.id = urm.contacts_history.contact_id
);

-- [D-DELETE-2] firm_party_id orphan
DELETE FROM urm.contacts_history
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.contacts_history.firm_party_id
);

-- [D-POST]
SELECT 'D-POST' AS stage,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
   )) AS contact_orphan_count_after,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
   )) AS firm_orphan_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §E. urm.party_supply_links orphan — DELETE
-- ============================================================================

-- [E-PRE]
SELECT 'E-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
   )) AS buyer_orphan,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
   )) AS supplier_orphan;

-- [E-DELETE-1]
DELETE FROM urm.party_supply_links
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.party_supply_links.buyer_party_id
);

-- [E-DELETE-2]
DELETE FROM urm.party_supply_links
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.party_supply_links.supplier_party_id
);

-- [E-POST]
SELECT 'E-POST' AS stage,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
   )) AS buyer_orphan_after,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
   )) AS supplier_orphan_after;


-- ============================================================================
-- §F. urm.* profile.party_id orphan — DELETE
-- ============================================================================

-- [F-PRE]
SELECT 'F-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_orphan,
  (SELECT COUNT(*) FROM urm.paper_mill_profile pmp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id)) AS paper_mill_orphan,
  (SELECT COUNT(*) FROM urm.filler_supplier_profile fsp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id)) AS filler_orphan;

-- [F-DELETE-1] investor_profile orphan
DELETE FROM urm.investor_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.investor_profile.party_id
);

-- [F-DELETE-2] paper_mill_profile orphan
DELETE FROM urm.paper_mill_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.paper_mill_profile.party_id
);

-- [F-DELETE-3] filler_supplier_profile orphan
DELETE FROM urm.filler_supplier_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.filler_supplier_profile.party_id
);

-- [F-POST]
SELECT 'F-POST' AS stage,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_orphan_after,
  (SELECT COUNT(*) FROM urm.paper_mill_profile pmp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id)) AS paper_mill_orphan_after,
  (SELECT COUNT(*) FROM urm.filler_supplier_profile fsp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id)) AS filler_orphan_after;


-- ============================================================================
-- §G. urm.investor_portfolio_companies.investor_party_id orphan — DELETE
-- ============================================================================

-- [G-PRE]
SELECT 'G-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.investor_portfolio_companies ipc
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id)) AS orphan_count;

-- [G-DELETE]
DELETE FROM urm.investor_portfolio_companies
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.investor_portfolio_companies.investor_party_id
);

-- [G-POST]
SELECT 'G-POST' AS stage,
  (SELECT COUNT(*) FROM urm.investor_portfolio_companies ipc
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id)) AS orphan_count_after;


-- ============================================================================
-- §H. URM 흐름 orphan — Pipeline / Stage / Deal / Task / Engagement
-- ============================================================================
-- 정상 상태: 모두 0 row (handoff §7 α+β TRUNCATE).
-- caller cutover 후 신규 row 생성 시작. orphan 발생하면 즉시 정리.

-- [H-PRE]
SELECT 'H-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.stages s
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id)) AS stage_orphan,
  (SELECT COUNT(*) FROM urm.deals d
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id)) AS deal_orphan,
  (SELECT COUNT(*) FROM urm.tasks t
   WHERE t.deal_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id)) AS task_orphan,
  (SELECT COUNT(*) FROM urm.engagement_attendees ea
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id)) AS attendee_orphan,
  (SELECT COUNT(*) FROM urm.engagement_documents ed
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id)) AS document_orphan;

-- [H-DELETE-1] stage orphan
DELETE FROM urm.stages
WHERE NOT EXISTS (
  SELECT 1 FROM urm.pipelines p WHERE p.id = urm.stages.pipeline_id
);

-- [H-DELETE-2] deal orphan
DELETE FROM urm.deals
WHERE NOT EXISTS (
  SELECT 1 FROM urm.pipelines p WHERE p.id = urm.deals.pipeline_id
);

-- [H-DELETE-3] task orphan
DELETE FROM urm.tasks
WHERE deal_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM urm.deals d WHERE d.id = urm.tasks.deal_id
  );

-- [H-DELETE-4] engagement_attendees orphan
DELETE FROM urm.engagement_attendees
WHERE NOT EXISTS (
  SELECT 1 FROM urm.engagements e WHERE e.id = urm.engagement_attendees.engagement_id
);

-- [H-DELETE-5] engagement_documents orphan
DELETE FROM urm.engagement_documents
WHERE NOT EXISTS (
  SELECT 1 FROM urm.engagements e WHERE e.id = urm.engagement_documents.engagement_id
);

-- [H-POST]
SELECT 'H-POST' AS stage,
  (SELECT COUNT(*) FROM urm.stages s
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id)) AS stage_orphan_after,
  (SELECT COUNT(*) FROM urm.deals d
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id)) AS deal_orphan_after,
  (SELECT COUNT(*) FROM urm.tasks t
   WHERE t.deal_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id)) AS task_orphan_after,
  (SELECT COUNT(*) FROM urm.engagement_attendees ea
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id)) AS attendee_orphan_after,
  (SELECT COUNT(*) FROM urm.engagement_documents ed
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id)) AS document_orphan_after;


-- ============================================================================
-- §I. 최종 검증 — identify_non_urm_data.sql 재실행 권장
-- ============================================================================
-- 본 cleanup 완료 후 identify_non_urm_data.sql 통째 재실행.
-- 모든 카테고리의 sample_count = 0 인 것이 정상.

-- 빠른 요약 query:
SELECT 'I-SUMMARY' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS urm_parties_null_type,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text IN ('fund','organization')) AS app_deprecated_enum,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id)) AS contact_orphan,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id)
      OR NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id)) AS history_orphan,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_profile_orphan;
-- expect: 모두 0

-- ============================================================================
-- 실행 순서:
--   1. §A-PRE 실행 → null_count + invalid_code_count 확인
--   2. 두 값 모두 0 이면 §A skip. 1 이상이면 §A-DELETE 실행
--   3. §A-POST 로 검증 (모두 0 확인)
--   4. §B, §C, ..., §H 동일 패턴 반복
--   5. §I 로 전체 요약 확인
--
-- ⚠️ 모든 DELETE 는 사용자 명시 원칙으로 정당화됨:
--    "URM 구조에 맞지 않는 데이터는 삭제 OK"
--
-- ⚠️ 본 SQL 실행 전 verify_carry_forward_counts.sql 결과를 기록해 두면
--    삭제 영향 추적에 유리.
-- ============================================================================
```

#### `identify_non_urm_data.sql` (18087 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · identify_non_urm_data.sql
-- ============================================================================
-- 목적: 사용자 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 에 따라
--       URM V2 구조와 정합하지 않는 잔존 데이터 탐지.
--
-- URM 기본원칙 (사용자 명시):
--   Pipeline → Stages → Deals → Deals_Checklist → Tasks → Engagements
--   Parties → Contacts → Contact_history → Filler_Suppliers_profile (+investor/paper_mill)
--
-- 실행 환경: Supabase SQL Editor (single SELECT, no BEGIN/COMMIT)
--
-- 출력: (category, finding, table_fqdn, sample_count, action_hint)
--       이 query 는 READ-ONLY. 실제 DELETE 는 caller cutover 종결 후 별도 실행.
--
-- ⚠️  Stage 29-d (app.* drop) 의 사전 분석 자료로도 활용.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- 1. urm.parties 잔존 fund/organization (handoff §5 ε hard-delete 후 잔재)
-- ────────────────────────────────────────────────────────────────────────
-- urm.party_types 에는 fund/organization 코드 없음 → party_type_id NULL 인 row 가
-- URM 원칙 위반. 이런 row 발견되면 삭제 후보.

SELECT
  'PARTY_TYPE_VIOLATION'::text AS category,
  'urm.parties.party_type_id IS NULL (URM 원칙 위반)'::text AS finding,
  'urm.parties'::text AS table_fqdn,
  (SELECT COUNT(*)::int FROM urm.parties WHERE party_type_id IS NULL) AS sample_count,
  'DELETE 후보 — URM 7 코드 (investor/paper_mill/filler_supplier/buyer/customer/partner/government_grant) 외'::text AS action_hint

UNION ALL

-- 2. urm.parties 가 7 코드 중 하나에도 매핑되지 않은 row
SELECT
  'PARTY_TYPE_VIOLATION'::text,
  'urm.parties 가 7 정규 코드 외 party_type_id 참조'::text,
  'urm.parties'::text,
  (SELECT COUNT(*)::int FROM urm.parties p
    WHERE p.party_type_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.party_types pt
        WHERE pt.id = p.party_type_id
          AND pt.code IN ('investor','paper_mill','filler_supplier',
                          'buyer','customer','partner','government_grant')
      ))::int,
  'DELETE 후보 — FK 무효값 또는 deprecated code 참조'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 3. urm.contacts 의 firm_party_id orphan (URM Parties-Contacts 원칙 위반)
-- ────────────────────────────────────────────────────────────────────────
-- URM 원칙: Contacts 는 Parties 에 종속. firm_party_id 가 가리키는 parties 가
-- 부재하면 URM 원칙 위반.

SELECT
  'CONTACT_ORPHAN'::text,
  'urm.contacts.firm_party_id orphan (Parties 부재)'::text,
  'urm.contacts'::text,
  (SELECT COUNT(*)::int FROM urm.contacts c
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
    ))::int,
  'DELETE 후보 — FK constraint 으로 막혀있어야 정상 (0 기대)'::text

UNION ALL

-- 4. urm.contacts_history orphan (URM Contacts-Contact_history 원칙)
SELECT
  'HISTORY_ORPHAN'::text,
  'urm.contacts_history.contact_id orphan'::text,
  'urm.contacts_history'::text,
  (SELECT COUNT(*)::int FROM urm.contacts_history ch
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
    ))::int,
  'DELETE 후보 — Contact 삭제 시 history 도 동행 (CASCADE 기대)'::text

UNION ALL

SELECT
  'HISTORY_ORPHAN'::text,
  'urm.contacts_history.firm_party_id orphan'::text,
  'urm.contacts_history'::text,
  (SELECT COUNT(*)::int FROM urm.contacts_history ch
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
    ))::int,
  'DELETE 후보 — firm party 가 사라진 history'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 5. urm.party_supply_links orphan
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'SUPPLY_ORPHAN'::text,
  'urm.party_supply_links.buyer_party_id orphan'::text,
  'urm.party_supply_links'::text,
  (SELECT COUNT(*)::int FROM urm.party_supply_links psl
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
    ))::int,
  'DELETE 후보 — buyer party 부재'::text

UNION ALL

SELECT
  'SUPPLY_ORPHAN'::text,
  'urm.party_supply_links.supplier_party_id orphan'::text,
  'urm.party_supply_links'::text,
  (SELECT COUNT(*)::int FROM urm.party_supply_links psl
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
    ))::int,
  'DELETE 후보 — supplier party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 6. urm.* profile 의 party_id orphan (Parties-Profile 원칙)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'PROFILE_ORPHAN'::text,
  'urm.investor_profile.party_id orphan'::text,
  'urm.investor_profile'::text,
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id
    ))::int,
  'DELETE 후보 — investor party 부재'::text

UNION ALL

SELECT
  'PROFILE_ORPHAN'::text,
  'urm.paper_mill_profile.party_id orphan'::text,
  'urm.paper_mill_profile'::text,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id
    ))::int,
  'DELETE 후보 — paper mill party 부재'::text

UNION ALL

SELECT
  'PROFILE_ORPHAN'::text,
  'urm.filler_supplier_profile.party_id orphan'::text,
  'urm.filler_supplier_profile'::text,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id
    ))::int,
  'DELETE 후보 — filler supplier party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 7. profile type mismatch (Parties-Profile 무결성)
-- ────────────────────────────────────────────────────────────────────────
-- urm.investor_profile.party_id 가 가리키는 party 의 party_type_id 가 'investor' 아님
SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.investor_profile party_type ≠ investor'::text,
  'urm.investor_profile'::text,
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
   JOIN urm.parties p ON p.id = ip.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'investor')::int,
  'DATA QUALITY — investor_profile 인데 party_type 이 investor 아님'::text

UNION ALL

SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.paper_mill_profile party_type ≠ paper_mill'::text,
  'urm.paper_mill_profile'::text,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
   JOIN urm.parties p ON p.id = pmp.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'paper_mill')::int,
  'DATA QUALITY — paper_mill_profile 인데 party_type 이 paper_mill 아님'::text

UNION ALL

SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.filler_supplier_profile party_type ≠ filler_supplier'::text,
  'urm.filler_supplier_profile'::text,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
   JOIN urm.parties p ON p.id = fsp.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'filler_supplier')::int,
  'DATA QUALITY — filler_supplier_profile 인데 party_type 이 filler_supplier 아님. 단 3 HQ 보존은 예외'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 8. urm.investor_portfolio_companies orphan
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'IPC_ORPHAN'::text,
  'urm.investor_portfolio_companies.investor_party_id orphan'::text,
  'urm.investor_portfolio_companies'::text,
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies ipc
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id
    ))::int,
  'DELETE 후보 — investor party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 9. app.parties 의 사라진 V2 enum 값 잔재 (반드시 0 — ε 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'APP_ENUM_REMNANT'::text,
  'app.parties.party_type=fund (deprecated)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund')::int,
  'DELETE 즉시 — fund V2 미지원 (handoff §8)'::text

UNION ALL

SELECT
  'APP_ENUM_REMNANT'::text,
  'app.parties.party_type=organization (deprecated)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization')::int,
  'DELETE 즉시 — organization V2 미지원 (단 3 HQ 는 urm.filler_supplier_profile 보존)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 10. app.parties 가 urm.parties 로 이전 안 된 row (cutover 누락)
-- ────────────────────────────────────────────────────────────────────────
-- 사용자 원칙: URM 에 없는 데이터는 삭제 OK. 단 company/individual 보존 의도 확인
SELECT
  'APP_NOT_IN_URM'::text,
  'app.parties.party_type=company 가 urm.parties 에 없음'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties ap
    WHERE ap.deleted_at IS NULL
      AND ap.party_type::text = 'company'
      AND NOT EXISTS (
        SELECT 1 FROM urm.parties up WHERE up.id = ap.id
      ))::int,
  'INVESTIGATE — Stage 29-b 의 매핑 누락? (id 보존 원칙)'::text

UNION ALL

SELECT
  'APP_NOT_IN_URM'::text,
  'app.parties.party_type=individual 활성 (모두 soft-deleted 기대)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties
    WHERE deleted_at IS NULL AND party_type::text = 'individual')::int,
  'EXPECT 0 — handoff §7 D group: 0/118 (모두 soft-deleted)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 11. urm.parties 가 app.parties 에 없는 row (역방향 — 신규 추가 의심)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'URM_NOT_IN_APP'::text,
  'urm.parties 가 app.parties 에 없음 (신규 row 의심)'::text,
  'urm.parties'::text,
  (SELECT COUNT(*)::int FROM urm.parties up
    WHERE NOT EXISTS (
      SELECT 1 FROM app.parties ap WHERE ap.id = up.id
    ))::int,
  'INVESTIGATE — Stage 29-b 후 신규 insert? caller writer 추적'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 12. URM 핵심 흐름 (Pipeline → Stages → Deals → Tasks) 의 무결성
-- ────────────────────────────────────────────────────────────────────────
-- 모두 0 expected. row 발견 시 = α+β TRUNCATE 후 신규 traffic 발생
SELECT
  'URM_FLOW_NEW_TRAFFIC'::text,
  'urm.pipelines 에 row 발생'::text,
  'urm.pipelines'::text,
  (SELECT COUNT(*)::int FROM urm.pipelines),
  'INFO — 0 이면 OK. row 있으면 caller cutover 시 의도된 신규 작성 확인'::text

UNION ALL

SELECT
  'URM_FLOW_NEW_TRAFFIC'::text,
  'urm.stages 에 row 발생'::text,
  'urm.stages'::text,
  (SELECT COUNT(*)::int FROM urm.stages),
  'INFO — pipeline_id 가 부재한 stage 가 있으면 orphan'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.stages.pipeline_id orphan'::text,
  'urm.stages'::text,
  (SELECT COUNT(*)::int FROM urm.stages s
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id
    )),
  'DELETE 후보 — orphan stage'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.deals.pipeline_id orphan'::text,
  'urm.deals'::text,
  (SELECT COUNT(*)::int FROM urm.deals d
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id
    )),
  'DELETE 후보 — orphan deal'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.tasks.deal_id orphan (있으면)'::text,
  'urm.tasks'::text,
  (SELECT COUNT(*)::int FROM urm.tasks t
    WHERE t.deal_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id
      )),
  'DELETE 후보 — deal 부재 task'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.tasks.checklist_id orphan (있으면)'::text,
  'urm.tasks'::text,
  (SELECT COUNT(*)::int FROM urm.tasks t
    WHERE t.checklist_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.deal_checklists dc WHERE dc.id = t.checklist_id
      )),
  'INFO — checklist FK 는 ON DELETE SET NULL. 정상이면 항상 0'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 13. urm.engagements 흐름 (Engagements → attendees / documents)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.engagement_attendees.engagement_id orphan'::text,
  'urm.engagement_attendees'::text,
  (SELECT COUNT(*)::int FROM urm.engagement_attendees ea
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id
    )),
  'DELETE 후보'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.engagement_documents.engagement_id orphan'::text,
  'urm.engagement_documents'::text,
  (SELECT COUNT(*)::int FROM urm.engagement_documents ed
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id
    )),
  'DELETE 후보'::text

) results
ORDER BY category, finding;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. sample_count 컬럼 = 위반 row 개수
-- 3. action_hint 가 'DELETE 즉시' → 정리 SQL 즉시 실행
-- 4. action_hint 가 'DELETE 후보' → 표본 SELECT 로 확인 후 정리
-- 5. action_hint 가 'INVESTIGATE' → 원인 조사 후 결정
-- 6. action_hint 가 'INFO' → 정보성, 0 정상
--
-- ⚠️  이 query 는 READ-ONLY. 실제 DELETE 는 별도 cleanup script 작성 필요.
--     사용자 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 에 따라
--     PARTY_TYPE_VIOLATION, *_ORPHAN, APP_ENUM_REMNANT 카테고리 모두 정리 대상.
-- ============================================================================
```

#### `verify_carry_forward_counts.sql` (12850 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · verify_carry_forward_counts.sql
-- ============================================================================
-- 목적: handoff §7 의 "Stage 29-b 종결 시점 데이터 snapshot" 과 실제 DB 의
--       row count 일치 여부 검증.
--
-- 실행 환경: Supabase SQL Editor (single SELECT, no BEGIN/COMMIT)
--
-- 출력: (group, table_fqdn, expected, actual, delta, status)
--       status: OK / MISMATCH / TABLE_MISSING
--
-- ⚠️  delta ≠ 0 인 row 발견 시 → handoff §7 와 실제 DB drift. 원인 조사.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Group A: urm.* 핵심 master (handoff §7)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'A'::text AS grp,
  'urm.parties (active)'::text AS table_fqdn,
  1532::int AS expected,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) AS actual,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) - 1532 AS delta,
  CASE WHEN (SELECT COUNT(*) FROM urm.parties WHERE deleted_at IS NULL) = 1532
       THEN 'OK' ELSE 'MISMATCH' END AS status

UNION ALL

SELECT 'A', 'urm.parties (total inc. soft-deleted)', NULL,
  (SELECT COUNT(*)::int FROM urm.parties),
  NULL, 'INFO'

UNION ALL

SELECT 'A', 'urm.contacts (active)', 217,
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL) - 217,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts WHERE deleted_at IS NULL) = 217
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.contacts_history', 109,
  (SELECT COUNT(*)::int FROM urm.contacts_history),
  (SELECT COUNT(*)::int FROM urm.contacts_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.party_supply_links', 117,
  (SELECT COUNT(*)::int FROM urm.party_supply_links),
  (SELECT COUNT(*)::int FROM urm.party_supply_links) - 117,
  CASE WHEN (SELECT COUNT(*) FROM urm.party_supply_links) = 117
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.plant_supply_links', 0,
  (SELECT COUNT(*)::int FROM urm.plant_supply_links),
  (SELECT COUNT(*)::int FROM urm.plant_supply_links) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.plant_supply_links) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group B: urm.* profile tables
-- ────────────────────────────────────────────────────────────────────────
SELECT 'B', 'urm.investor_profile', 101,
  (SELECT COUNT(*)::int FROM urm.investor_profile),
  (SELECT COUNT(*)::int FROM urm.investor_profile) - 101,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_profile) = 101
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.paper_mill_profile', 1074,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile),
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile) - 1074,
  CASE WHEN (SELECT COUNT(*) FROM urm.paper_mill_profile) = 1074
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.filler_supplier_profile', 232,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile),
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile) - 232,
  CASE WHEN (SELECT COUNT(*) FROM urm.filler_supplier_profile) = 232
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.investor_portfolio_companies', 422,
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group C: urm.* pipeline/deal/task/engagement (모두 0 — α+β TRUNCATE)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'C', 'urm.pipelines', 0,
  (SELECT COUNT(*)::int FROM urm.pipelines),
  (SELECT COUNT(*)::int FROM urm.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.stages', 0,
  (SELECT COUNT(*)::int FROM urm.stages),
  (SELECT COUNT(*)::int FROM urm.stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deals', 0,
  (SELECT COUNT(*)::int FROM urm.deals),
  (SELECT COUNT(*)::int FROM urm.deals) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deals) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_stage_history', 0,
  (SELECT COUNT(*)::int FROM urm.deal_stage_history),
  (SELECT COUNT(*)::int FROM urm.deal_stage_history) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_stage_history) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_checklists', 0,
  (SELECT COUNT(*)::int FROM urm.deal_checklists),
  (SELECT COUNT(*)::int FROM urm.deal_checklists) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_checklists) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.tasks', 0,
  (SELECT COUNT(*)::int FROM urm.tasks),
  (SELECT COUNT(*)::int FROM urm.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagements', 0,
  (SELECT COUNT(*)::int FROM urm.engagements),
  (SELECT COUNT(*)::int FROM urm.engagements) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagements) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_attendees', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_attendees),
  (SELECT COUNT(*)::int FROM urm.engagement_attendees) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_attendees) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_documents', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_documents),
  (SELECT COUNT(*)::int FROM urm.engagement_documents) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_documents) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group D: app.* 잔존 (handoff §7 carry — Stage 29-d 까지 보존)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'D', 'app.parties (active)', 1738,
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL) - 1738,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE deleted_at IS NULL) = 1738
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=company (active)', 1413,
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company'),
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company') - 1413,
  CASE WHEN (SELECT COUNT(*) FROM app.parties
             WHERE deleted_at IS NULL AND party_type::text = 'company') = 1413
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=fund (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=organization (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group E: ε 잔재 (Stage 29-d 자동 drop)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'E', 'app.investor_partner_profile (ε 잔재)', 108,
  (SELECT COUNT(*)::int FROM app.investor_partner_profile),
  (SELECT COUNT(*)::int FROM app.investor_partner_profile) - 108,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_partner_profile) = 108
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.person_firm_history (ε 잔재)', 109,
  (SELECT COUNT(*)::int FROM app.person_firm_history),
  (SELECT COUNT(*)::int FROM app.person_firm_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM app.person_firm_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.investor_portfolio_companies (ε 잔재)', 422,
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group F: app.* TRUNCATE 확인 (handoff §5 α+β)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'F', 'app.pipelines (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipelines),
  (SELECT COUNT(*)::int FROM app.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.pipeline_stages (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipeline_stages),
  (SELECT COUNT(*)::int FROM app.pipeline_stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipeline_stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.tasks (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.tasks),
  (SELECT COUNT(*)::int FROM app.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

) results
ORDER BY grp, table_fqdn;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. status = OK 모두 → handoff §7 snapshot 과 일치, Stage 29-c 진입 안전
-- 3. MISMATCH 1건이라도 → STOP. delta 컬럼으로 drift 방향 파악
--    - delta > 0 : Stage 29-b 종결 후 신규 row 추가됨 (불법 writer 의심)
--    - delta < 0 : 누군가 row 삭제함 (사고? 정상?)
-- 4. TABLE_MISSING → 테이블 자체 부재 (verify_urm_schema.sql 우선 실행)
--
-- ⚠️  운영 traffic 진행 중이면 작은 drift 발생 가능. ±5 row 이내는 WARN.
--     단 fund/organization 카운트는 절대 0 여야 함 (D group).
-- ============================================================================
```

#### `verify_urm_schema.sql` (16234 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · verify_urm_schema.sql
-- ============================================================================
-- 목적: Stage 29-b 종결 시점의 urm.* 스키마 구조가 caller cutover 기대치와
--       일치하는지 확인. handoff §3 / §6 / §8 의 모든 carry-forward 컬럼명을
--       information_schema 로 검증.
--
-- 실행 환경: Supabase SQL Editor (single statement, no BEGIN/COMMIT)
--
-- 출력: 1개 SELECT 결과셋. 각 row 는 (check_id, check_name, status, detail).
--       status 'OK' / 'FAIL' / 'WARN' / 'INFO'
--
-- ⚠️  caller cutover 진입 전 반드시 실행. FAIL 1건이라도 있으면 stop.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Block 1: urm schema 존재
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S01'::text AS check_id,
  'urm schema 존재'::text AS check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'urm'
  ) THEN 'OK' ELSE 'FAIL' END AS status,
  'expected: urm schema 정의됨'::text AS detail

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 2: 19개 urm 핵심 테이블 존재 검증
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S02-' || lpad(rn::text, 2, '0'))::text,
  ('urm.' || tname || ' 존재')::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'urm' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 V2 schema'::text
FROM (
  VALUES
    (1, 'parties'),
    (2, 'contacts'),
    (3, 'contacts_history'),
    (4, 'party_types'),
    (5, 'party_supply_links'),
    (6, 'plant_supply_links'),
    (7, 'investor_profile'),
    (8, 'paper_mill_profile'),
    (9, 'filler_supplier_profile'),
    (10, 'investor_portfolio_companies'),
    (11, 'pipelines'),
    (12, 'stages'),
    (13, 'deals'),
    (14, 'deal_stage_history'),
    (15, 'deal_checklists'),
    (16, 'tasks'),
    (17, 'engagements'),
    (18, 'engagement_attendees'),
    (19, 'engagement_documents')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 3: 핵심 컬럼명 검증 (handoff §3 rename 표)
-- ────────────────────────────────────────────────────────────────────────

-- S03-01: urm.parties.party_type_id 존재 (FK, NOT party_type column)
SELECT
  'S03-01'::text,
  'urm.parties.party_type_id 존재 (FK)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'caller code 가 party_type 직접 컬럼 참조하면 fail. JOIN to urm.party_types 필요'::text

UNION ALL

-- S03-02: urm.parties.party_type 직접 컬럼 부재 (반대 검증)
SELECT
  'S03-02'::text,
  'urm.parties.party_type 직접 컬럼 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: party_type 컬럼 없음 (FK lookup 으로 대체)'::text

UNION ALL

-- S03-03: urm.stages.sort_order (NOT stage_position)
SELECT
  'S03-03'::text,
  'urm.stages.sort_order 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'sort_order'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §3 rename: stage_position → sort_order'::text

UNION ALL

-- S03-04: urm.stages.stage_position 부재
SELECT
  'S03-04'::text,
  'urm.stages.stage_position 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'stage_position'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 이전 컬럼명 부재'::text

UNION ALL

-- S03-05: urm.contacts.firm_party_id NOT NULL
SELECT
  'S03-05'::text,
  'urm.contacts.firm_party_id NOT NULL'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts'
      AND column_name = 'firm_party_id'
      AND is_nullable = 'NO'
  ) THEN 'OK' ELSE 'FAIL' END,
  'R3 결정: NOT NULL 유지 (handoff §5 ε)'::text

UNION ALL

-- S03-06: urm.contacts_history (1:1 from app.person_firm_history)
SELECT
  'S03-06'::text,
  'urm.contacts_history.contact_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'contact_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: person_party_id → contact_id'::text

UNION ALL

-- S03-07: urm.contacts_history.started_at (date, NOT joined_at timestamptz)
SELECT
  'S03-07'::text,
  'urm.contacts_history.started_at (date)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'started_at'
      AND data_type = 'date'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: joined_at::date → started_at'::text

UNION ALL

-- S03-08: urm.party_supply_links.link_type (NOT supply_type)
SELECT
  'S03-08'::text,
  'urm.party_supply_links.link_type 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'link_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: supply_type → link_type (text)'::text

UNION ALL

-- S03-09: urm.party_supply_links.volume_estimate (text, NOT volume_tpy)
SELECT
  'S03-09'::text,
  'urm.party_supply_links.volume_estimate (text)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'volume_estimate'
      AND data_type = 'text'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: volume_tpy::text || tpy → volume_estimate'::text

UNION ALL

-- S03-10: urm.tasks.checklist_id (handoff §6 신설 컬럼)
SELECT
  'S03-10'::text,
  'urm.tasks.checklist_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'tasks'
      AND column_name = 'checklist_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §6 신설: FK to deal_checklists ON DELETE SET NULL'::text

UNION ALL

-- S03-11: urm.investor_portfolio_companies.portfolio_company_name_normalized
SELECT
  'S03-11'::text,
  'urm.ipc.portfolio_company_name_normalized 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'investor_portfolio_companies'
      AND column_name = 'portfolio_company_name_normalized'
  ) THEN 'OK' ELSE 'FAIL' END,
  'δ Port-1: portfolio_companies 의 name_normalized 보존 컬럼'::text

UNION ALL

-- S03-12: urm.parties 의 organization_id 컬럼 부재 (single-tenant 검증)
SELECT
  'S03-12'::text,
  'urm.parties.organization_id 부재 (single-tenant)'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'organization_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: urm = single-tenant'::text

UNION ALL

-- S03-13: urm.parties.module_data jsonb 존재 (legacy 보존)
SELECT
  'S03-13'::text,
  'urm.parties.module_data (jsonb) 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'module_data'
      AND data_type = 'jsonb'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8: _app_* legacy 필드 jsonb 보존소'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 4: party_types lookup 7개 코드 확인
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S04-01'::text,
  'urm.party_types 7개 코드 존재'::text,
  CASE WHEN (
    SELECT COUNT(*) FROM urm.party_types
    WHERE code IN (
      'investor','paper_mill','filler_supplier',
      'buyer','customer','partner','government_grant'
    )
  ) = 7 THEN 'OK' ELSE 'FAIL' END,
  ('handoff §5 ε: 7개 코드 (' ||
   (SELECT string_agg(code, ',' ORDER BY id) FROM urm.party_types)
   || ')')::text

UNION ALL

SELECT
  'S04-02'::text,
  'urm.party_types 에 fund 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'fund'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: fund V2 미지원'::text

UNION ALL

SELECT
  'S04-03'::text,
  'urm.party_types 에 organization 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'organization'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: organization V2 미지원'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 5: FK 무결성 (party_type_id FK 가 urm.party_types.id 참조)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S05-01'::text,
  'urm.parties.party_type_id FK → urm.party_types.id'::text,
  CASE WHEN EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'urm'
      AND tc.table_name = 'parties'
      AND kcu.column_name = 'party_type_id'
      AND ccu.table_schema = 'urm'
      AND ccu.table_name = 'party_types'
      AND ccu.column_name = 'id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'FK 강제: party_type_id 무효값 차단'::text

UNION ALL

-- S05-02: orphan party_type_id 검증
SELECT
  'S05-02'::text,
  'urm.parties.party_type_id orphan row 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.parties p
    WHERE p.party_type_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.party_types pt WHERE pt.id = p.party_type_id
      )
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 0 orphan (FK constraint 으로 보장)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 6: urm.parties.name 컬럼 확인 (handoff §13 의 ε ERROR 자취)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S06-01'::text,
  ('urm.parties name 컬럼 = ' ||
    COALESCE(
      (SELECT string_agg(column_name, ', ')
       FROM information_schema.columns
       WHERE table_schema = 'urm' AND table_name = 'parties'
         AND column_name IN ('name','display_name','party_name','legal_name')
      ), 'NONE'
    ))::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name IN ('name','display_name','party_name','legal_name')
  ) THEN 'INFO' ELSE 'WARN' END,
  'handoff §13: 실제 컬럼명 확인 필요. caller code 의 이름 참조 일관성 검증'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 7: 9개 deprecation profile 부재 확인 (Stage 29-b δ 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S07-' || lpad(rn::text, 2, '0'))::text,
  ('app.' || tname || ' DROP 확인')::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ: 9 deprecation profile DROP 완료'::text
FROM (
  VALUES
    (1, 'buyer_profile'),
    (2, 'buyer_partner_profile'),
    (3, 'customer_profile'),
    (4, 'govt_grant_profile'),
    (5, 'govt_grant_contact_profile'),
    (6, 'partner_profile'),
    (7, 'partner_audits'),
    (8, 'partner_capabilities'),
    (9, 'filler_supplier_contact_profile')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 8: app.portfolio_companies DROP 확인 (δ Port-1 cleanup)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S08-01'::text,
  'app.portfolio_companies DROP 확인'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = 'portfolio_companies'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ Port-1: 342 row → ipc.portfolio_company_name_normalized 보존 후 DROP'::text

) results
ORDER BY check_id;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 에 통째로 붙여넣기 → Run
-- 2. 모든 row 의 status = 'OK' 또는 'INFO' 인지 확인
-- 3. FAIL 1건이라도 있으면 → caller cutover STOP, handoff 재점검
-- 4. WARN 은 정보성. detail 컬럼 읽고 caller cutover 시 주의
-- ============================================================================
```

