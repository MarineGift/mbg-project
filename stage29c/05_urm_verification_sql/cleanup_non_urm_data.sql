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
