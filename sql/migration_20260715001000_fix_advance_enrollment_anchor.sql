-- =====================================================================
-- migration_20260715001000_fix_advance_enrollment_anchor.sql
--
-- !! ROOT CAUSE of the duplicate sends that cost us an investor. !!
--
-- Problem (confirmed from pg_get_functiondef on 2026-07-14)
--   The prior body scheduled the next step off the ENROLLMENT date:
--
--       next_send_at = v_enrolled_at + (v_next_day_offset || ' days')
--
--   day_offset is therefore an absolute calendar plan fixed at enroll time,
--   not a gap between mails. If step N goes out LATE, step N+1 is already
--   due -- or overdue -- the moment step N lands, so the worker fires it on
--   the very next run.
--
--   Measured on Climate Investor Cold Outreach -- FCC:
--     step 1  68 sends  2026-07-13 21:07 -> 2026-07-14 16:02
--     step 2  27 sends  2026-07-14 16:00 -> 2026-07-14 16:01
--   27 parties got two cold mails 19 hours apart. Those enrollments were
--   created around 07-07, step 1 did not go out until 07-13 (6 days late),
--   and step 2 was due at enrolled_at + 7 = 07-14. It fired immediately.
--
--   Investor Cold Outreach - FCC Seed was unaffected only because its step 0
--   went out on time: 06-30 -> 07-06 -> 07-13, a clean weekly cadence.
--
-- Fix
--   Schedule relative to the ACTUAL send, keeping the intended gap:
--
--       gap          = next_offset - current_offset      (floor 1 day)
--       next_send_at = GREATEST( enrolled_at + next_offset,
--                                now()       + gap )
--
--   On-time sequences are unchanged: when step N lands on plan, the two
--   arms are equal and GREATEST picks the same instant as before. Only a
--   LATE step moves -- it pushes the remainder of the sequence out by the
--   delay instead of collapsing it.
--
--   The floor of 1 day is a safety net for a step authored with a gap of 0.
--   One such sequence exists (Investor Cold Outreach - FCC Climate Tech,
--   step_order 0 and 1 both day_offset 0). It is dormant -- 0 sends, 0
--   enrollments -- but if it is ever enrolled the floor stops it from firing
--   two mails on the same run. Fix its day_offset separately -- do not rely
--   on the floor.
--
-- Preserved exactly
--   * the email_sequence_sends log insert
--   * the is_last_step -> completed branch
--   * the missing-next-step case still leaves next_send_at NULL. Do NOT let
--     GREATEST see a NULL here: GREATEST IGNORES nulls in Postgres, so
--     GREATEST(NULL, now() + gap) would return a real timestamp and schedule
--     a send for a step that does not exist. The explicit IS NULL branch
--     below keeps the old semantics.
--
-- This is plpgsql, so the body MUST contain semicolons. Paste this file into
-- the Supabase SQL Editor ON ITS OWN and run it as a single statement. A
-- naive split fails loudly with a syntax error rather than silently creating
-- a truncated function, but verify anyway with the pg_get_functiondef query
-- in the handoff.
--
-- Rollback: re-run the prior definition (replace the GREATEST expression
-- with v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL).
-- =====================================================================

CREATE OR REPLACE FUNCTION public.advance_enrollment(
  p_enrollment_id uuid,
  p_step_id uuid,
  p_step_order integer,
  p_communication_id uuid,
  p_is_last_step boolean,
  p_status app.send_status DEFAULT 'sent'::app.send_status
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_sequence_id      UUID;
  v_enrolled_at      TIMESTAMPTZ;
  v_cur_day_offset   INT;
  v_next_day_offset  INT;
  v_gap_days         INT;
BEGIN
  -- send log
  INSERT INTO app.email_sequence_sends
    (enrollment_id, step_id, step_order, communication_id, status)
  VALUES
    (p_enrollment_id, p_step_id, p_step_order, p_communication_id, p_status);

  IF p_is_last_step THEN
    UPDATE app.email_sequence_enrollments
    SET status       = 'completed'::app.enrollment_status,
        completed_at = now(),
        updated_at   = now()
    WHERE id = p_enrollment_id;
    RETURN;
  END IF;

  SELECT sequence_id, enrolled_at
    INTO v_sequence_id, v_enrolled_at
  FROM app.email_sequence_enrollments
  WHERE id = p_enrollment_id;

  SELECT day_offset
    INTO v_cur_day_offset
  FROM app.email_sequence_steps
  WHERE sequence_id = v_sequence_id
    AND step_order  = p_step_order;

  SELECT day_offset
    INTO v_next_day_offset
  FROM app.email_sequence_steps
  WHERE sequence_id = v_sequence_id
    AND step_order  = p_step_order + 1;

  -- No next step defined. Keep the prior behaviour exactly: park the
  -- enrollment with a NULL next_send_at so it is never due.
  IF v_next_day_offset IS NULL THEN
    UPDATE app.email_sequence_enrollments
    SET next_step_order = p_step_order + 1,
        next_send_at    = NULL,
        updated_at      = now()
    WHERE id = p_enrollment_id;
    RETURN;
  END IF;

  -- Intended gap between this step and the next, floored at 1 day.
  v_gap_days := GREATEST(v_next_day_offset - COALESCE(v_cur_day_offset, 0), 1);

  UPDATE app.email_sequence_enrollments
  SET next_step_order = p_step_order + 1,
      next_send_at    = GREATEST(
                          v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL,
                          now()         + (v_gap_days        || ' days')::INTERVAL
                        ),
      updated_at      = now()
  WHERE id = p_enrollment_id;
END;
$function$
