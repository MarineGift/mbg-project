-- =====================================================================
-- fix_20260714235700_world_fund_auto_reply_cooldown.sql
--
-- Context
--   The 2026-07-14 PM handoff listed a "Brightfuture reply" to classify.
--   Brightfuture is not a firm. brightfuture@worldfund.vc is the World Fund
--   intake address, and the reply came from brightfuture+noreply@worldfund.vc
--   (plus-addressing) -- a canned automated acknowledgement, received TWICE
--   (2026-07-13 21:08 and 2026-07-14 16:01). No human has assessed us.
--
-- Why not record it as a reply
--   Logging it as reply_* or rejected_* would put World Fund in
--   app.v_email_do_not_send permanently, killing the lead over a robot.
--   The correct vocabulary already exists in the outcome CHECK constraint:
--     outcome     = auto_reply      (OOO / automated acknowledgement)
--     next_action = resend_later    (retry after resend_not_before)
--   The view only blocks a resend_later row while
--   resend_not_before > CURRENT_DATE, so this is a self-expiring cooldown.
--
-- Why a cooldown is needed at all
--   Enrollment 2975addb (Climate Investor Cold Outreach) is ACTIVE with
--   recipient_email = brightfuture@worldfund.vc and next_send_at 2026-07-27
--   (step 3). Without this row that is a third touch in two weeks on an
--   address that has only ever answered with a robot. Cooling to 2026-08-04
--   pushes step 3 past the window and lets it resume by itself afterwards.
--
-- Depends on: migration_20260714235600_guard_get_due_enrollments.sql
--   Without that guard this row has NO effect on the sequence path, because
--   get_due_enrollments does not consult the view. Apply the guard first.
--
-- Idempotent: NOT EXISTS on (address, outcome). Safe to re-run.
-- =====================================================================

INSERT INTO app.email_send_outcomes (
  organization_id, party_id, recipient_email, sequence_id, step_order,
  outcome, reason, evidence_ref, next_action, resend_not_before, source, occurred_at
)
SELECT
  e.organization_id,
  e.party_id,
  'brightfuture@worldfund.vc',
  e.sequence_id,
  2,
  'auto_reply',
  'Canned acknowledgement from the World Fund intake inbox, identical body received twice (2026-07-13 and 2026-07-14) from brightfuture+noreply@worldfund.vc. Robot, not a human assessment. Cooling off so step 3 does not become a third touch in two weeks. Resumes automatically after resend_not_before.',
  'communications:e738de73-8527-4275-a569-dd5c68b37792',
  'resend_later',
  DATE '2026-08-04',
  'manual',
  now()
FROM app.email_sequence_enrollments e
WHERE e.id = '2975addb-4a49-4c14-ba20-db55d4bbf0fd'
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_send_outcomes o
    WHERE lower(o.recipient_email) = 'brightfuture@worldfund.vc'
      AND o.outcome = 'auto_reply'
  );
