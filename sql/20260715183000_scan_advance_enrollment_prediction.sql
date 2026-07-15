-- =====================================================================
-- 20260715183000_scan_advance_enrollment_prediction.sql
--
-- READ-ONLY. Nothing is written.
--
-- WHY -- §0 came back, and the answer was neither option.
--   public.advance_enrollment does NOT choose absolute or relative.
--   It takes the max of both:
--
--     v_gap_days := GREATEST(v_next_day_offset - COALESCE(v_cur_day_offset,0), 1)
--
--     next_send_at = GREATEST(
--         v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL,   -- absolute
--         now()         + (v_gap_days        || ' days')::INTERVAL    -- relative
--     )
--
--   The relative term is a floor: it stops two steps landing in the same
--   instant when a schedule has slipped into the past. When the absolute
--   term is later, the absolute term wins.
--
-- WHAT IS AT STAKE
--   The 01:00+00 Asia rail survives Tuesday only if the RELATIVE branch
--   wins. Worked for the Asia cohort:
--     relative = 2026-07-21 01:00 + 7d = 2026-07-28 01:00
--     absolute = enrolled_at + 14d
--   So the rail holds iff enrolled_at <= 2026-07-14 01:00.
--
--   If the absolute branch wins instead, next_send_at inherits
--   enrolled_at's TIME OF DAY. The sequence was created 2026-07-13
--   21:06+00. 21:06+00 is 06:06 KST and 14:06 PT -- a time nobody chose,
--   for everyone, and the 09:00 PT anchor breaks along with the rail.
--
--   The current values (2026-07-28 16:00:00+00, exactly on the hour) were
--   SET BY HAND by fix_20260715020000_climate_snap_next_send_to_tuesday_9am.
--   They are not advance_enrollment output and prove nothing about it.
--   Only enrolled_at settles this.
--
-- METHOD
--   Reproduces the function's arithmetic per enrollment, using
--   next_send_at as the send moment (the worker polls at 60s, so real
--   now() lands within a minute of it -- immaterial at 7-day granularity).
--
-- Supabase SQL Editor safe: self-contained statements, CTE repeated per
-- statement, no semicolons or bare SQL keywords inside strings.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1. THE HEADLINE. Which branch wins, and does the rail survive?
--       relative for all -> rails hold through step 3 and 4. Nothing to do.
--       absolute anywhere -> that row's schedule is set by enrolled_at's
--                            clock time. Read Q3 before Tuesday.
-- ---------------------------------------------------------------------
WITH sim AS (
  SELECT
    e.id,
    p.party_name,
    p.country_code,
    e.enrolled_at,
    e.next_step_order,
    e.next_send_at                                             AS fires_at,
    cur.day_offset                                             AS cur_day_offset,
    nxt.day_offset                                             AS next_day_offset
  FROM app.email_sequence_enrollments e
  JOIN app.parties p ON p.id = e.party_id
  LEFT JOIN app.email_sequence_steps cur
    ON cur.sequence_id = e.sequence_id AND cur.step_order = e.next_step_order
  LEFT JOIN app.email_sequence_steps nxt
    ON nxt.sequence_id = e.sequence_id AND nxt.step_order = e.next_step_order + 1
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  CASE
    WHEN s.next_day_offset IS NULL THEN 'last step -> completed, no next_send_at'
    WHEN s.enrolled_at + (s.next_day_offset || ' days')::interval
       > s.fires_at + (GREATEST(s.next_day_offset - COALESCE(s.cur_day_offset, 0), 1) || ' days')::interval
      THEN 'ABSOLUTE wins -> rail breaks'
    ELSE 'relative wins -> rail holds'
  END                                                          AS branch,
  count(*)                                                     AS n,
  min(s.enrolled_at)                                           AS earliest_enrolled_at,
  max(s.enrolled_at)                                           AS latest_enrolled_at
FROM sim s
GROUP BY 1
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q2. The schedule AFTER Tuesday's send, as advance_enrollment will set it.
--     Compare against the intended rails:
--       Asia  -> 2026-07-28 01:00+00
--       US/EU -> 2026-07-28 16:00+00
--     Ragged minutes here mean the absolute branch is driving.
-- ---------------------------------------------------------------------
WITH sim AS (
  SELECT
    e.id,
    p.country_code,
    e.enrolled_at,
    e.next_step_order,
    e.next_send_at                                             AS fires_at,
    cur.day_offset                                             AS cur_day_offset,
    nxt.day_offset                                             AS next_day_offset
  FROM app.email_sequence_enrollments e
  JOIN app.parties p ON p.id = e.party_id
  LEFT JOIN app.email_sequence_steps cur
    ON cur.sequence_id = e.sequence_id AND cur.step_order = e.next_step_order
  LEFT JOIN app.email_sequence_steps nxt
    ON nxt.sequence_id = e.sequence_id AND nxt.step_order = e.next_step_order + 1
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  s.fires_at                                                   AS this_send,
  s.next_step_order + 1                                        AS becomes_step,
  GREATEST(
    s.enrolled_at + (s.next_day_offset || ' days')::interval,
    s.fires_at + (GREATEST(s.next_day_offset - COALESCE(s.cur_day_offset, 0), 1) || ' days')::interval
  )                                                            AS predicted_next_send_at,
  count(*)                                                     AS n,
  string_agg(DISTINCT coalesce(s.country_code, '??'), ' ' ORDER BY coalesce(s.country_code, '??'))
                                                               AS countries
FROM sim s
WHERE s.next_day_offset IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 3, 1;


-- ---------------------------------------------------------------------
-- Q3. THE ACTUAL QUESTION. After Tuesday, what local time does each Asia
--     recipient get step 3? This is the rail, measured rather than hoped.
--     Want 08:00-18:00 local. Anything outside means re-run
--     fix_20260716000500 §2 after Tuesday -- and file the per-recipient
--     window as real work, because hand-nudging every week will miss once.
-- ---------------------------------------------------------------------
WITH sim AS (
  SELECT
    e.id,
    p.party_name,
    p.country_code,
    e.enrolled_at,
    e.next_step_order,
    e.next_send_at                                             AS fires_at,
    cur.day_offset                                             AS cur_day_offset,
    nxt.day_offset                                             AS next_day_offset
  FROM app.email_sequence_enrollments e
  JOIN app.parties p ON p.id = e.party_id
  LEFT JOIN app.email_sequence_steps cur
    ON cur.sequence_id = e.sequence_id AND cur.step_order = e.next_step_order
  LEFT JOIN app.email_sequence_steps nxt
    ON nxt.sequence_id = e.sequence_id AND nxt.step_order = e.next_step_order + 1
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
    AND p.country_code IN ('JP','KR','CN','SG','TW','HK','AU','NZ')
)
SELECT
  s.party_name,
  s.country_code,
  s.enrolled_at,
  s.fires_at                                                   AS step2_at,
  GREATEST(
    s.enrolled_at + (s.next_day_offset || ' days')::interval,
    s.fires_at + (GREATEST(s.next_day_offset - COALESCE(s.cur_day_offset, 0), 1) || ' days')::interval
  )                                                            AS step3_at_utc,
  to_char(
    GREATEST(
      s.enrolled_at + (s.next_day_offset || ' days')::interval,
      s.fires_at + (GREATEST(s.next_day_offset - COALESCE(s.cur_day_offset, 0), 1) || ' days')::interval
    ) AT TIME ZONE
    CASE s.country_code
      WHEN 'KR' THEN 'Asia/Seoul'       WHEN 'JP' THEN 'Asia/Tokyo'
      WHEN 'CN' THEN 'Asia/Shanghai'    WHEN 'SG' THEN 'Asia/Singapore'
      WHEN 'TW' THEN 'Asia/Taipei'      WHEN 'HK' THEN 'Asia/Hong_Kong'
      WHEN 'AU' THEN 'Australia/Sydney' WHEN 'NZ' THEN 'Pacific/Auckland'
      ELSE 'UTC'
    END, 'Dy HH24:MI')                                         AS step3_local,
  CASE
    WHEN s.enrolled_at + (s.next_day_offset || ' days')::interval
       > s.fires_at + (GREATEST(s.next_day_offset - COALESCE(s.cur_day_offset, 0), 1) || ' days')::interval
      THEN 'ABSOLUTE'
    ELSE 'relative'
  END                                                          AS branch
FROM sim s
WHERE s.next_day_offset IS NOT NULL
ORDER BY s.country_code, s.party_name;


-- ---------------------------------------------------------------------
-- Q4. Diagnostic: the enrolled_at spread. The whole question reduces to
--     whether these sit before or after 2026-07-14 01:00+00.
-- ---------------------------------------------------------------------
SELECT
  date_trunc('hour', e.enrolled_at)                            AS enrolled_hour,
  count(*)                                                     AS n,
  min(e.next_step_order)                                       AS min_step,
  max(e.next_step_order)                                       AS max_step
FROM app.email_sequence_enrollments e
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- Q5. The steps themselves. Confirms 0/7/14/21 and the 1-based ordering,
--     which everything above assumes.
-- ---------------------------------------------------------------------
SELECT
  st.step_order,
  st.day_offset,
  left(st.subject, 60)                                         AS subject_head,
  st.day_offset - lag(st.day_offset) OVER (ORDER BY st.step_order) AS gap_from_prev
FROM app.email_sequence_steps st
WHERE st.sequence_id::text LIKE '63737c08%'
ORDER BY st.step_order;
