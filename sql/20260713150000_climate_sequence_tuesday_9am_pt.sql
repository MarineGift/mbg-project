-- =============================================================================
-- 20260713150000_climate_sequence_tuesday_9am_pt.sql
-- =============================================================================
-- Reschedules the "Climate Investor Cold Outreach -- FCC" sequence to send on
-- TUESDAYS at 09:00 America/Los_Angeles (US Pacific), every step.
--
-- What it does (all FK-safe -- no step delete/insert, so no
-- email_sequence_sends_step_id_fkey violation):
--   1) Sets weekly step offsets (Day 0 / 7 / 14 / 21) via in-place UPDATE.
--   2) Sets quiet_hours so the worker only fires Tue-window sends at 9am PT
--      and holds anything else to the next allowed time.
--   3) Moves every NOT-yet-sent enrollment's next_send_at to the next
--      Tuesday 09:00 PT. Already-sent Day-0 rows keep their history; their
--      pending next_send_at is snapped to the following Tuesday 9am too.
--
-- SAFE TO RE-RUN. Read the SELECTs first (Part 0), then the UPDATEs.
--
-- Timezone note: next_send_at is stored in UTC. 09:00 PT = 16:00 UTC during
-- PDT (Mar-Nov) or 17:00 UTC during PST (Nov-Mar). This script computes the
-- correct UTC instant from the America/Los_Angeles wall-clock, so DST is handled.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 0: INSPECT FIRST (read-only). Run these, eyeball, then run Part 1+.
-- -----------------------------------------------------------------------------

-- 0a) The sequence + current step offsets.
SELECT s.id, s.name, s.status, s.quiet_hours,
       st.step_order, st.day_offset, st.subject
FROM app.email_sequences s
JOIN app.email_sequence_steps st ON st.sequence_id = s.id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
ORDER BY st.step_order;

-- 0b) Enrollment status snapshot (how many already sent vs pending).
SELECT e.status,
       COUNT(*)                                          AS n,
       COUNT(*) FILTER (WHERE e.next_send_at IS NOT NULL) AS with_next_send,
       MIN(e.next_send_at) AS earliest_next,
       MAX(e.next_send_at) AS latest_next
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
GROUP BY e.status
ORDER BY e.status;


-- -----------------------------------------------------------------------------
-- Part 1: Weekly offsets + quiet_hours (Tuesday 9am PT window).
-- -----------------------------------------------------------------------------
DO $migration$
DECLARE
  v_seq_id uuid;
BEGIN
  SELECT id INTO v_seq_id
    FROM app.email_sequences
   WHERE name = 'Climate Investor Cold Outreach -- FCC'
   LIMIT 1;

  IF v_seq_id IS NULL THEN
    RAISE EXCEPTION 'Sequence not found.';
  END IF;

  -- 1) Weekly cadence: in-place UPDATE (keeps step ids -> FK to sends intact).
  UPDATE app.email_sequence_steps SET day_offset = 0  WHERE sequence_id = v_seq_id AND step_order = 1;
  UPDATE app.email_sequence_steps SET day_offset = 7  WHERE sequence_id = v_seq_id AND step_order = 2;
  UPDATE app.email_sequence_steps SET day_offset = 14 WHERE sequence_id = v_seq_id AND step_order = 3;
  UPDATE app.email_sequence_steps SET day_offset = 21 WHERE sequence_id = v_seq_id AND step_order = 4;

  -- 2) Quiet hours: allow only a narrow Tuesday-9am window; block weekends.
  --    Worker holds any due step outside [09:00,10:00) PT to the next allowed time.
  UPDATE app.email_sequences
     SET quiet_hours = jsonb_build_object(
           'timezone', 'America/Los_Angeles',
           'start', '10:00',            -- quiet begins 10:00 (i.e. allowed 09:00-10:00)
           'end',   '09:00',            -- quiet ends 09:00 next allowed morning
           'weekends_blocked', true
         )
   WHERE id = v_seq_id;

  RAISE NOTICE 'Weekly offsets + quiet_hours set for sequence %', v_seq_id;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 2: Move all pending sends to the next Tuesday 09:00 PT.
--   - "pending" = status 'active' AND next_send_at IS NOT NULL.
--   - Computes the next Tuesday >= today in America/Los_Angeles, at 09:00 local,
--     then stores the correct UTC instant.
-- -----------------------------------------------------------------------------
DO $migration$
DECLARE
  v_seq_id       uuid;
  v_today_la     date;
  v_next_tue_la  date;
  v_next_send    timestamptz;
  v_moved        integer;
BEGIN
  SELECT id INTO v_seq_id
    FROM app.email_sequences
   WHERE name = 'Climate Investor Cold Outreach -- FCC'
   LIMIT 1;

  -- Today's date in LA.
  v_today_la := (now() AT TIME ZONE 'America/Los_Angeles')::date;

  -- Next Tuesday (ISO dow: Mon=1..Sun=7; Tue=2). If today is Tue, use next week.
  v_next_tue_la := v_today_la
     + (((2 - EXTRACT(ISODOW FROM v_today_la)::int) + 7) % 7);
  IF v_next_tue_la <= v_today_la THEN
    v_next_tue_la := v_next_tue_la + 7;
  END IF;

  -- 09:00 LA wall-clock on that date -> correct UTC instant (DST-safe).
  v_next_send := (v_next_tue_la::text || ' 09:00')::timestamp
                 AT TIME ZONE 'America/Los_Angeles';

  UPDATE app.email_sequence_enrollments e
     SET next_send_at = v_next_send,
         updated_at   = now()
   WHERE e.sequence_id = v_seq_id
     AND e.status = 'active'
     AND e.next_send_at IS NOT NULL;

  GET DIAGNOSTICS v_moved = ROW_COUNT;
  RAISE NOTICE 'Moved % pending enrollments to % (UTC).', v_moved, v_next_send;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 3: VERIFY (read-only).
-- -----------------------------------------------------------------------------
SELECT st.step_order, st.day_offset, st.subject
FROM app.email_sequence_steps st
JOIN app.email_sequences s ON s.id = st.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
ORDER BY st.step_order;

SELECT s.quiet_hours
FROM app.email_sequences s
WHERE s.name = 'Climate Investor Cold Outreach -- FCC';

SELECT p.party_name, e.status, e.next_step_order,
       e.next_send_at,
       e.next_send_at AT TIME ZONE 'America/Los_Angeles' AS next_send_pt
FROM app.email_sequence_enrollments e
JOIN app.parties p         ON p.id = e.party_id
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
ORDER BY e.next_send_at NULLS LAST, p.party_name;
