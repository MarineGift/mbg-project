-- =====================================================================
-- fix_20260715004000_stop_seed_sequence.sql
--
-- Stop all remaining sends on 'Investor Cold Outreach - FCC Seed'.
-- The raise moved to Series A, so the Seed framing is obsolete and the
-- 57 enrollments queued for 2026-07-20 must not go out.
--
-- !! WHY WE CANCEL ENROLLMENTS AND NOT THE SEQUENCE !!
--   Pausing or archiving app.email_sequences does NOTHING. Verified
--   2026-07-15 from both sides:
--
--     public.get_due_enrollments()  -- no join to app.email_sequences at all
--       WHERE e.status = 'active'::app.enrollment_status
--         AND e.next_send_at <= now()
--
--     src/lib/utils/sequence-processor.ts
--       .select("id, from_account_id, quiet_hours")   -- status never read
--       .in("id", distinctSeqIds)
--
--   Nothing in the send path reads email_sequences.status. An archived
--   sequence keeps mailing. Only the ENROLLMENT status stops it. Setting the
--   sequence status below is a LABEL for humans, not a guard -- see the
--   handoff backlog item for the missing guard.
--
-- 'cancelled' is a confirmed value of app.enrollment_status -- observed in
-- live data (the '15 min...' sequence shows cancelled 2 / completed 29), not
-- guessed.
--
-- Effect: 7/20 drops from 97 to 40 (Climate only). Climate is untouched --
-- it keeps 40 on 07-20 and 22 on 07-27.
--
-- Reversible: set status back to 'active' and clear cancelled_at. The
-- enrollments keep their next_step_order and next_send_at, so a resume would
-- pick up where it left off. next_send_at will be in the past by then, so
-- G1 (the 2-day min-gap guard) is what stops a resumed batch from stacking
-- on top of a recent Climate touch.
--
-- PREVIEW FIRST. Run the SELECT in the handoff before this file.
-- Each statement is self-contained. No do-block.
-- =====================================================================

-- 1) Cancel every active enrollment on the Seed sequence.
UPDATE app.email_sequence_enrollments e
SET status       = 'cancelled'::app.enrollment_status,
    cancelled_at = now(),
    updated_at   = now()
FROM app.email_sequences s
WHERE s.id       = e.sequence_id
  AND s.name     = 'Investor Cold Outreach - FCC Seed'
  AND e.status   = 'active'::app.enrollment_status;

-- 2) Label the sequence archived. Cosmetic only -- the send path ignores
--    this column. Statement 1 is what actually stops the mail.
UPDATE app.email_sequences
SET status     = 'archived'::app.email_sequence_status,
    updated_at = now()
WHERE name     = 'Investor Cold Outreach - FCC Seed'
  AND status  <> 'archived'::app.email_sequence_status;
