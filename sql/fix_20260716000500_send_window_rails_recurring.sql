-- =====================================================================
-- fix_20260716000500_send_window_rails_recurring.sql
--
-- Supersedes fix_20260715234500_asia_cohort_send_window.sql (one-shot,
-- 5 hard-coded ids). This one is set-based, re-runnable, and covers
-- every step -- not just 7/21.
--
-- WHY A SECOND PASS -- 7/28 has the same bug
--   The 07-15 dry run resolved the 40-vs-67 question:
--     active_total=67  due_tuesday=40  will_send=40
--     bucket WILL SEND ................................ 40
--     bucket not due Tuesday (later next_send_at) ..... 27
--     2026-07-21 16:00+00  step 2  40
--     2026-07-28 16:00+00  step 3  27
--   The 27 were never a landmine -- they are a step-3 cohort already
--   scheduled for 7/28. The plan's 40 was right.
--
--   But the verify after the one-shot fix showed this:
--     2026-07-21 01:00+00  step 2   5  CN KR SG
--     2026-07-21 16:00+00  step 2  35  AT BE CA DE FR GB SE US
--     2026-07-28 16:00+00  step 3  27  CH DE DK GB JP SG US
--                                          ^^^^^^^^
--   JP and SG sit in the 7/28 16:00 batch. 16:00+00 is midnight local for
--   them. The exact bug that was just fixed for 7/21, one week later.
--   Fixing five ids by hand does not fix a schedule.
--
-- STILL OPEN -- read §0 of the previous file before trusting this to last.
--   If advance_enrollment recomputes next_send_at as enrolled_at +
--   day_offset (absolute), the 5 rows moved to 01:00 snap back to 16:00
--   after Tuesday's send, and this file must be re-run after every step.
--   If it computes last_send + interval (relative), they stay on the rail.
--   This file is written to be re-run either way. Re-running is a no-op
--   when there is nothing to move.
--
-- THE RAILS
--   Asia    01:00+00  -> 10:00 KST/JST, 09:00 CST/SGT/HKT, 11:00 AEST
--   Europe  08:00+00  -> 10:00 CEST, 09:00 BST          (§3, OPTIONAL)
--   US      16:00+00  -> 09:00 PT, 12:00 ET             (unchanged, default)
--   IN is deliberately excluded from the Asia rail: 01:00+00 is 06:30 IST.
--   No IN rows exist in this sequence today. If any appear, give them
--   their own rail rather than folding them in here.
--
-- NOTE: app.email_sequences.quiet_hours holds ONE timezone for the whole
-- sequence (20260627040000), so it cannot express this. Per-recipient send
-- windows are not a feature that exists. These rails are the stand-in.
-- The durable fix is a real per-recipient window in the processor -- worth
-- filing, since this file has to be re-run otherwise.
--
-- Supabase SQL Editor safe: self-contained statements, no semicolons or
-- bare SQL keywords inside strings.
-- =====================================================================


-- ---------------------------------------------------------------------
-- §1. PREVIEW. Every active enrollment that would move, with the local
--     arrival time before and after. Read this before running §2.
--     Expect JP + SG rows on 2026-07-28, and nothing on 2026-07-21
--     (already moved by the one-shot file).
-- ---------------------------------------------------------------------
SELECT
  e.id,
  p.party_name,
  p.country_code,
  e.next_step_order,
  e.next_send_at                                       AS from_utc,
  date_trunc('day', e.next_send_at) + interval '1 hour' AS to_utc,
  to_char(
    e.next_send_at AT TIME ZONE
    CASE p.country_code
      WHEN 'KR' THEN 'Asia/Seoul'      WHEN 'JP' THEN 'Asia/Tokyo'
      WHEN 'CN' THEN 'Asia/Shanghai'   WHEN 'SG' THEN 'Asia/Singapore'
      WHEN 'TW' THEN 'Asia/Taipei'     WHEN 'HK' THEN 'Asia/Hong_Kong'
      WHEN 'AU' THEN 'Australia/Sydney' WHEN 'NZ' THEN 'Pacific/Auckland'
      ELSE 'UTC'
    END, 'Dy HH24:MI')                                 AS local_now,
  to_char(
    (date_trunc('day', e.next_send_at) + interval '1 hour') AT TIME ZONE
    CASE p.country_code
      WHEN 'KR' THEN 'Asia/Seoul'      WHEN 'JP' THEN 'Asia/Tokyo'
      WHEN 'CN' THEN 'Asia/Shanghai'   WHEN 'SG' THEN 'Asia/Singapore'
      WHEN 'TW' THEN 'Asia/Taipei'     WHEN 'HK' THEN 'Asia/Hong_Kong'
      WHEN 'AU' THEN 'Australia/Sydney' WHEN 'NZ' THEN 'Pacific/Auckland'
      ELSE 'UTC'
    END, 'Dy HH24:MI')                                 AS local_after
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
  AND p.country_code IN ('JP','KR','CN','SG','TW','HK','AU','NZ')
  AND e.next_send_at > now()
  AND e.next_send_at::time = time '16:00'
ORDER BY e.next_send_at, p.country_code, p.party_name;


-- ---------------------------------------------------------------------
-- §2. THE ASIA RAIL. Moves 16:00+00 -> 01:00+00 on the SAME UTC date,
--     for future sends only. Idempotent: rows already at 01:00 do not
--     match. Safe to re-run after every step.
--     Expect UPDATE 2 today (the JP and SG rows on 7/28).
-- ---------------------------------------------------------------------
UPDATE app.email_sequence_enrollments e
SET next_send_at = date_trunc('day', e.next_send_at) + interval '1 hour',
    updated_at   = now()
FROM app.parties p
WHERE p.id = e.party_id
  AND e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
  AND p.country_code IN ('JP','KR','CN','SG','TW','HK','AU','NZ')
  AND e.next_send_at > now()
  AND e.next_send_at::time = time '16:00';


-- ---------------------------------------------------------------------
-- §3. THE EUROPE RAIL -- OPTIONAL. Uncomment to run.
--
--     16:00+00 is 17:00 BST / 18:00 CEST. That is after-hours, not
--     midnight, so it is a judgement call rather than a defect. 9 of the
--     40 on 7/21 land there, plus CH/DE/DK/GB in the 7/28 batch.
--     08:00+00 puts them at 09:00 BST / 10:00 CEST instead.
--
--     The tradeoff: 09:00 PT is the current anchor and moving Europe off
--     it means step 2 no longer goes out as one batch. If the Tuesday
--     send is being watched live, one batch is easier to watch. Decide,
--     do not default.
-- ---------------------------------------------------------------------
-- UPDATE app.email_sequence_enrollments e
-- SET next_send_at = date_trunc('day', e.next_send_at) + interval '8 hours',
--     updated_at   = now()
-- FROM app.parties p
-- WHERE p.id = e.party_id
--   AND e.sequence_id::text LIKE '63737c08%'
--   AND e.status::text = 'active'
--   AND p.country_code IN ('GB','IE','DE','FR','NL','CH','SE','DK','NO','FI','ES','IT','BE','AT')
--   AND e.next_send_at > now()
--   AND e.next_send_at::time = time '16:00';


-- ---------------------------------------------------------------------
-- §4. VERIFY. The whole sequence by send instant.
--     Expect, if §3 was NOT run:
--       2026-07-21 01:00+00  step 2   5  CN KR SG
--       2026-07-21 16:00+00  step 2  35  AT BE CA DE FR GB SE US
--       2026-07-28 01:00+00  step 3   2  JP SG
--       2026-07-28 16:00+00  step 3  25  CH DE DK GB US
--     5 + 35 = 40 on Tuesday. 2 + 25 = 27 the week after. Totals hold.
--     Any country in the Asia list still sitting on a 16:00 row means §2
--     did not match it -- investigate rather than hand-patching.
-- ---------------------------------------------------------------------
SELECT
  e.next_send_at,
  e.next_step_order,
  count(*)                                             AS n,
  string_agg(DISTINCT coalesce(p.country_code, '??'), ' ' ORDER BY coalesce(p.country_code, '??'))
                                                       AS countries
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
GROUP BY e.next_send_at, e.next_step_order
ORDER BY e.next_send_at, e.next_step_order;


-- ---------------------------------------------------------------------
-- §5. STANDING CHECK. Run this after every step send, before the next.
--     Returns rows only when something is scheduled into a recipient's
--     night. Zero rows = nothing to do. If advance_enrollment turns out
--     to be absolute (see the header), this will keep returning the same
--     Asia rows every week -- that is the signal to re-run §2, and the
--     argument for building a real per-recipient window.
-- ---------------------------------------------------------------------
SELECT
  e.next_send_at,
  p.party_name,
  p.country_code,
  to_char(
    e.next_send_at AT TIME ZONE
    CASE p.country_code
      WHEN 'KR' THEN 'Asia/Seoul'      WHEN 'JP' THEN 'Asia/Tokyo'
      WHEN 'CN' THEN 'Asia/Shanghai'   WHEN 'SG' THEN 'Asia/Singapore'
      WHEN 'TW' THEN 'Asia/Taipei'     WHEN 'HK' THEN 'Asia/Hong_Kong'
      WHEN 'AU' THEN 'Australia/Sydney' WHEN 'NZ' THEN 'Pacific/Auckland'
      WHEN 'IN' THEN 'Asia/Kolkata'
      ELSE 'UTC'
    END, 'Dy HH24:MI')                                 AS local_arrival
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.status::text = 'active'
  AND e.next_send_at > now()
  AND p.country_code IN ('JP','KR','CN','SG','TW','HK','AU','NZ','IN')
  AND extract(hour FROM (
        e.next_send_at AT TIME ZONE
        CASE p.country_code
          WHEN 'KR' THEN 'Asia/Seoul'      WHEN 'JP' THEN 'Asia/Tokyo'
          WHEN 'CN' THEN 'Asia/Shanghai'   WHEN 'SG' THEN 'Asia/Singapore'
          WHEN 'TW' THEN 'Asia/Taipei'     WHEN 'HK' THEN 'Asia/Hong_Kong'
          WHEN 'AU' THEN 'Australia/Sydney' WHEN 'NZ' THEN 'Pacific/Auckland'
          WHEN 'IN' THEN 'Asia/Kolkata'
          ELSE 'UTC'
        END
      )) NOT BETWEEN 8 AND 18
ORDER BY e.next_send_at, p.country_code;
