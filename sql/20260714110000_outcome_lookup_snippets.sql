-- =====================================================================
-- 20260714110000_outcome_lookup_snippets.sql
--
-- Daily lookup snippets Q1-Q5 for the send-outcome log. Read-only,
-- safe to run anytime. Save each block as a Supabase SQL Editor snippet
-- for one-click use. (Reconstructed copy for repo history, 2026-07-14 -
-- Q1 rebuilt from the view definition, Q2-Q5 recovered verbatim.)
--
-- Q3 + Q5 are also visualized at urm.marinebiogroup.com/mailing/outcomes.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. 재발송 금지 전체 리스트 (v_email_do_not_send 뷰 그대로)
-- hard bounce + unsubscribe + suppress + resend_later 쿨다운 중
-- ---------------------------------------------------------------------
SELECT email_lower, last_event_at, outcomes
FROM app.v_email_do_not_send
ORDER BY last_event_at DESC;

-- ---------------------------------------------------------------------
-- Q2. 특정 주소/회사에 보내도 되는지 발송 전 확인 (이름/주소 바꿔서 사용)
-- 결과 0행 = 발송 가능. 행이 나오면 사유가 표시됨.
-- ---------------------------------------------------------------------
SELECT o.recipient_email, p.party_name, o.outcome, o.reason,
       o.next_action, o.resend_not_before, o.occurred_at
FROM app.email_send_outcomes o
LEFT JOIN app.parties p ON p.id = o.party_id
WHERE lower(o.recipient_email) = lower('someone@firm.com')
   OR p.party_name ILIKE '%firm name%'
ORDER BY o.occurred_at DESC;

-- ---------------------------------------------------------------------
-- Q3. 거절 사유별 현황판 (거절/바운스가 어디서 왜 발생하는지)
-- ---------------------------------------------------------------------
SELECT outcome, COUNT(*) AS cnt,
       STRING_AGG(DISTINCT COALESCE(p.party_name, o.recipient_email), ', ') AS who
FROM app.email_send_outcomes o
LEFT JOIN app.parties p ON p.id = o.party_id
GROUP BY outcome
ORDER BY cnt DESC;

-- ---------------------------------------------------------------------
-- Q4. 재접근 대기 리스트 (resend_later 쿨다운이 곧 풀리는 순서)
-- 예: Extantia 2027-01-15 - 미국 검증/로열티 증빙과 함께 재접근
-- ---------------------------------------------------------------------
SELECT p.party_name, o.recipient_email, o.reason,
       o.resend_not_before,
       o.resend_not_before - CURRENT_DATE AS days_until_ok
FROM app.email_send_outcomes o
LEFT JOIN app.parties p ON p.id = o.party_id
WHERE o.next_action = 'resend_later'
ORDER BY o.resend_not_before;

-- ---------------------------------------------------------------------
-- Q5. 후속작업 목록 (사람이 해야 할 일: 대체 컨택 발굴 / 폼 전환 / 팔로업)
-- ---------------------------------------------------------------------
SELECT p.party_name, o.recipient_email, o.next_action, o.reason, o.occurred_at::date AS day
FROM app.email_send_outcomes o
LEFT JOIN app.parties p ON p.id = o.party_id
WHERE o.next_action IN ('switch_contact', 'switch_deck', 'follow_up')
ORDER BY o.occurred_at DESC;
