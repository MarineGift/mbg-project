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
