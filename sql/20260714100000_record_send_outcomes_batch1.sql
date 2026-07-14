-- =====================================================================
-- 20260714100000_record_send_outcomes_batch1.sql
--
-- !! ALREADY APPLIED to production DB on 2026-07-14 - DO NOT RE-RUN !!
-- Plain UPDATE/INSERT statements (no idempotence guards): re-running
-- would duplicate the Part 2 rows. Reconstructed from the session
-- transcript after the original download was lost; committed for
-- history. Part 3 was reconstructed from the documented sync rule
-- (bounce/suppress -> 'failed', rejected/unsubscribe -> 'cancelled');
-- the DB end-state matches either way (verified via VERIFY 2 on 7/14).
--
-- Purpose: correct 2 rows + insert 3 new outcomes from 7/14 mailbox,
--          then re-sync enrollments so steps 2-4 do not fire.
-- Run each part separately.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 0: confirm party_name spellings (adjust patterns in Part 2 if needed)
-- ---------------------------------------------------------------------
SELECT id, party_name, email
FROM app.parties
WHERE party_name ILIKE '%planet a%'
   OR party_name ILIKE '%eclipse%'
   OR party_name ILIKE '%extantia%'
   OR party_name ILIKE '%energy transition%'
   OR party_name ILIKE '%first bight%'
ORDER BY party_name;

-- ---------------------------------------------------------------------
-- PART 1: corrections to existing rows
-- ---------------------------------------------------------------------

-- 1a. Eclipse: real recipient was admin@eclipse.capital,
--     blocked by recipient mail-flow rule (not a bad address).
UPDATE app.email_send_outcomes
SET recipient_email = 'admin@eclipse.capital',
    reason = 'Blocked by Eclipse IT mail-flow rule - unauthorized external domain. Cold email will never land. Use form or warm intro.',
    next_action = 'switch_contact'
WHERE recipient_email = '[BOUNCED ADDRESS]'   -- the placeholder/old address from the migration template row
RETURNING recipient_email, outcome, next_action;

-- 1b. Extantia: reply was a polite PASS, not positive.
--     "decided not to move forward... not the right fit at this stage"
--     but "look forward to following your progress" -> re-approach after
--     US validation / first royalties.
UPDATE app.email_send_outcomes
SET outcome = 'rejected_other',
    reason = 'Polite pass - could not get comfortable with fit for their strategy at this stage. Door open: following our progress. Re-approach with US validation + royalty proof.',
    next_action = 'resend_later',
    resend_not_before = '2027-01-15'
WHERE recipient_email = 'jo@extantia.com'
  AND outcome = 'reply_positive'
RETURNING recipient_email, outcome, next_action, resend_not_before;

-- ---------------------------------------------------------------------
-- PART 2: new outcomes (LEFT JOIN LATERAL: row inserts even if party
-- name does not match; party_id just stays null - fix later via Part 0)
-- ---------------------------------------------------------------------

-- 2a. Planet A Ventures - hard bounce, account inactive (gsmtp DisabledUser)
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source)
SELECT p.organization_id, p.id, 'startups@planet-a.com', 'bounce_hard',
       '550 5.2.1 account inactive (DisabledUser). Find alternate Planet A contact address.',
       '전송 실패: Displacing wood pulp at negative abatement cost',
       'switch_contact', 'mailcarrier'
FROM (VALUES (1)) v(x)
LEFT JOIN LATERAL (
  SELECT id, organization_id FROM app.parties
  WHERE party_name ILIKE '%planet a%' AND deleted_at IS NULL
  ORDER BY party_name LIMIT 1
) p ON true;

-- 2b. Energy Transition Ventures (Craig Lawrence) - sector mismatch
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source)
SELECT p.organization_id, p.id, 'craig@energytransitionvc.com', 'rejected_sector',
       'Not an area of focus for us, won''t be a fit for our fund. Energy-transition thesis - no adjacent deck applies.',
       'Re: Displacing wood pulp at negative abatement cost',
       'none', 'manual'
FROM (VALUES (1)) v(x)
LEFT JOIN LATERAL (
  SELECT id, organization_id FROM app.parties
  WHERE party_name ILIKE '%energy transition%' AND deleted_at IS NULL
  ORDER BY party_name LIMIT 1
) p ON true;

-- 2c. First Bight Ventures (Collin McColl, 7/11) - stage mismatch
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source)
SELECT p.organization_id, p.id, 'collin@firstbight.com', 'rejected_stage',
       'Series A is too advanced for us to invest (they are earlier-stage). Positive on concept. Do NOT submit their web form.',
       'Re: Displacing wood pulp at negative abatement cost',
       'none', 'manual'
FROM (VALUES (1)) v(x)
LEFT JOIN LATERAL (
  SELECT id, organization_id FROM app.parties
  WHERE party_name ILIKE '%first bight%' AND deleted_at IS NULL
  ORDER BY party_name LIMIT 1
) p ON true;

-- ---------------------------------------------------------------------
-- PART 3 (reconstructed): enrollment sync so steps 2-4 do not fire.
-- Rule: bounce/suppress -> 'failed', rejected/unsubscribe -> 'cancelled'.
-- Matches enrollments via contacts email (schema fact: enrollments carry
-- contact_id/party_id, not a recipient_email column).
-- ---------------------------------------------------------------------

-- 3a. bounced addresses -> 'failed'
UPDATE app.email_sequence_enrollments e
SET status = 'failed'::app.enrollment_status,
    updated_at = now()
FROM app.contacts c
WHERE c.id = e.contact_id
  AND e.status = 'active'::app.enrollment_status
  AND lower(c.email) IN ('startups@planet-a.com', 'admin@eclipse.capital')
RETURNING e.id, lower(c.email) AS email, e.status;

-- 3b. rejected addresses -> 'cancelled'
UPDATE app.email_sequence_enrollments e
SET status = 'cancelled'::app.enrollment_status,
    cancelled_at = now(),
    updated_at = now()
FROM app.contacts c
WHERE c.id = e.contact_id
  AND e.status = 'active'::app.enrollment_status
  AND lower(c.email) IN ('jo@extantia.com', 'craig@energytransitionvc.com', 'collin@firstbight.com')
RETURNING e.id, lower(c.email) AS email, e.status;

-- ---------------------------------------------------------------------
-- PART 4: verify - the 5 rows and the do-not-send view
-- ---------------------------------------------------------------------
SELECT recipient_email, outcome, next_action, resend_not_before, occurred_at
FROM app.email_send_outcomes
ORDER BY occurred_at DESC;

SELECT * FROM app.v_email_do_not_send ORDER BY last_event_at DESC;
