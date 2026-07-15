-- =====================================================================
-- fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql
--
-- !! RUN THE PREVIEW IN THE HANDOFF FIRST. !!
--    docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md
--    Decision rule: every row moves_forward = true AND gap_days >= 7.
--    One row failing either -> do NOT run this file.
--
-- Problem (measured 2026-07-15, not inferred)
--   app.email_sequence_enrollments.next_send_at, PT wall clock:
--     step 2   40 rows   2026-07-20 Mon 15:27 -- 15:56
--     step 3   27 rows   2026-07-27 Mon 14:06
--   The Climate quiet_hours policy is
--     {timezone: America/Los_Angeles, start: 10:00, end: 09:00,
--      weekends_blocked: true}
--   i.e. the ONLY allowed window is weekdays 09:00-10:00 PT. Both groups
--   sit outside it, on a Monday.
--
--   There is no "Tuesday" anywhere in the schema. quiet_hours knows hours
--   and weekends -- not weekdays. The Tuesday cadence came only from a
--   one-shot UPDATE (20260713150000 Part 2, and the enroll scripts
--   20260713160000 / 180000 / 190000, which each set next_send_at to the
--   next Tuesday 09:00 PT explicitly). advance_enrollment then re-anchored
--   to enrolled_at + day_offset on the first send and the alignment was
--   lost:
--     cohort A enrolled 07-13 21:06:34 UTC = Mon 14:06 PT -> +14d = Mon
--     cohort B enrolled 07-13 22:27:21 UTC = Mon 15:27 PT -> +7d  = Mon
--
--   Consequence (simulated against quiet-hours.ts, both cohorts):
--     Mon 15:27 blocked -> Tue 15:57 -> Wed 16:27 -> ... +30 min/day
--     -> Sat -> weekend branch snaps to Mon 09:00 UTC = Mon 02:00 PT
--     -> +30 min per worker run -> sends Mon 09:00 PT, six days late.
--   So 07-20 sends NOTHING. The 40 land 07-27 Mon 09:00 PT and the 27
--   land 08-03 Mon 09:00 PT. Not a duplicate-send incident -- a silent
--   week-long slip onto the wrong weekday.
--
-- Fix
--   Snap next_send_at to the FIRST Tuesday 09:00 PT at or after the value
--   it already holds. Forward-only by construction.
--
-- Why this is not a repeat of 20260713150000 Part 2 (the incident)
--   Part 2 was  SET next_send_at = v_next_send  -- unconditional. It pulled
--   28 enrollments six days EARLIER and put two cold mails 19 hours apart
--   in front of an investor. Four independent things stop that here:
--     1. the target is computed per row as "next Tuesday >= this row's own
--        next_send_at", so it can only move forward
--     2. GREATEST(next_send_at, snap_at) on top of that -- belt and braces
--     3. WHERE snap_at > next_send_at -- rows that would not move are not
--        touched at all, so the ledger shows only real changes
--     4. the preview prints gap_days from each party's LAST ACTUAL sequence
--        send. That is the number Part 2 destroyed. It must stay >= 7.
--   [G1] (48h min-gap in get_due_enrollments) remains the backstop that
--   makes the bad outcome impossible regardless of this file.
--
-- Why one snap is enough -- this does NOT need re-running every week
--   migration_20260715001000 already changed advance_enrollment to
--       next_send_at = GREATEST(enrolled_at + next_offset, now() + gap)
--   Every Climate gap is exactly 7 days. Once a step lands inside the
--   09:00-10:00 PT Tuesday window, now() + 7d is the same weekday at the
--   same time of day, and it is always LATER than the stale
--   enrolled_at + offset (a Monday afternoon), so GREATEST keeps picking
--   the aligned arm. The cadence self-sustains from here:
--     cohort B  step 2 Tue 07-21 -> step 3 Tue 07-28 -> step 4 Tue 08-04
--     cohort A  step 3 Tue 07-28 -> step 4 Tue 08-04
--   The anchor fix was filed as "robustness, not the cause of the
--   incident" -- correct on both counts, and it is also the thing that
--   makes this one-shot durable instead of weekly toil.
--
-- Scope: Climate only. Deliberately not generalised -- no other sequence
-- has a live weekday/window intent (Seed is stopped, the rest are dormant).
--
-- Expected effect
--   step 2  40 rows  2026-07-20 Mon 15:27--15:56 -> 2026-07-21 Tue 09:00
--   step 3  27 rows  2026-07-27 Mon 14:06        -> 2026-07-28 Tue 09:00
--   (5 of the 27 are do_not_send_party and will be dropped at send time by
--   the guard, not here. 22 actually mail. Blocking is the view's job.)
--
-- IDEMPOTENT. After a successful run snap_at = next_send_at, so the WHERE
-- matches zero rows and a re-run is a no-op.
--
-- Single statement, no DO block, no temp table -- the Supabase SQL Editor
-- mis-splits those. The CTE is inline. Run the whole file at once.
--
-- Rollback: none needed (forward-only, and the old values were unsendable).
-- To undo anyway, next_send_at for the 40 was enrolled_at + 7d and for the
-- 27 was enrolled_at + 14d.
-- =====================================================================

WITH tgt AS (
  SELECT e.id,
         e.next_send_at,
         (
           (e.next_send_at AT TIME ZONE 'America/Los_Angeles')::date
           + (
               (
                 2 - EXTRACT(
                       ISODOW FROM (e.next_send_at AT TIME ZONE 'America/Los_Angeles')::date
                     )::int
               ) + 7
             ) % 7
         ) AS tue_date
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequences s
    ON s.id = e.sequence_id
  WHERE s.name          = 'Climate Investor Cold Outreach -- FCC'
    AND e.status        = 'active'::app.enrollment_status
    AND e.next_send_at IS NOT NULL
), snapped AS (
  -- First Tuesday 09:00 PT at or after this row's own next_send_at.
  -- The +7 is applied to the DATE, then converted, so DST is handled.
  SELECT t.id,
         CASE
           WHEN ((t.tue_date::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles')
                >= t.next_send_at
             THEN ((t.tue_date::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles')
           ELSE (((t.tue_date + 7)::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles')
         END AS snap_at
  FROM tgt t
)
UPDATE app.email_sequence_enrollments e
   SET next_send_at = GREATEST(e.next_send_at, sn.snap_at),
       updated_at   = now()
  FROM snapped sn
 WHERE e.id         = sn.id
   AND sn.snap_at   > e.next_send_at
