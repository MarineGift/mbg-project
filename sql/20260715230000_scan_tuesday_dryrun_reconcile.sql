-- =====================================================================
-- 20260715230000_scan_tuesday_dryrun_reconcile.sql
--
-- READ-ONLY. Nothing is written.
--
-- WHY THIS EXISTS -- an unexplained 27.
--   The scan run on 2026-07-15 returned:
--     63737c08  Climate Investor Cold Outreach -- FCC  active
--     active_enrollments = 67   next_send_at = 2026-07-21 16:00:00+00
--   Every handoff since 07-13 has planned Tuesday as "40통".
--   67 - 40 = 27 unaccounted enrollments, six days before the send.
--
-- THE LIKELY ANSWER (must be confirmed, not assumed)
--   `active` is an enrollment state, NOT a prediction of a send.
--   public.get_due_enrollments() applies the do-not-send guards at SEND
--   time (migration_20260714235600), so form-submitters / repliers /
--   decliners / hard-bounces stay `active` in the table and are filtered
--   only as the worker picks them up. So 67 active can legitimately mean
--   40 sends. If that is what is happening, the plan is right and only the
--   vocabulary is wrong.
--   The other possibility is that 27 enrollments were added after the "40"
--   was computed, in which case Tuesday sends 67 and the plan is wrong.
--   These two look identical from the enrollment table. Q1/Q2 separate them.
--
-- METHOD
--   Q2 mirrors public.get_due_enrollments() exactly -- same joins, same
--   LATERAL contact resolution, same two NOT EXISTS guards -- with one
--   change: `next_send_at <= now()` becomes
--   `next_send_at <= timestamptz '2026-07-21 16:00:00+00'`.
--   That is a dry run of Tuesday, today.
--
-- Supabase SQL Editor safe: self-contained statements, CTE repeated per
-- statement, no semicolons inside strings, no bare `into` inside strings.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1. THE HEADLINE. How many messages actually leave on Tuesday?
--     Compare will_send against the 40 in the plan.
--       will_send = 40  -> plan correct, the 67 is just enrollment state
--       will_send = 67  -> 27 unplanned sends, stop and look at Q2
--       anything else   -> read Q2 before Tuesday
-- ---------------------------------------------------------------------
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.party_id,
    e.next_step_order,
    e.next_send_at,
    p.party_name,
    p.country_code,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS send_to
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
   AND st.step_order  = e.next_step_order
  JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,
      c.is_primary DESC NULLS LAST,
      c.created_at ASC
    LIMIT 1
  ) ct ON TRUE
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  count(*)                                                     AS active_total,
  count(*) FILTER (WHERE r.next_send_at <= timestamptz '2026-07-21 16:00:00+00')
                                                               AS due_tuesday,
  count(*) FILTER (
    WHERE r.next_send_at <= timestamptz '2026-07-21 16:00:00+00'
      AND r.send_to IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.party_id = r.party_id)
      AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.email_lower = lower(r.send_to))
  )                                                            AS will_send
FROM resolved r;


-- ---------------------------------------------------------------------
-- Q2. THE RECONCILIATION. Every active enrollment, bucketed by outcome.
--     The buckets sum to 67. This is the audit trail for the 27.
-- ---------------------------------------------------------------------
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.party_id,
    e.next_step_order,
    e.next_send_at,
    p.party_name,
    p.country_code,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS send_to
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
   AND st.step_order  = e.next_step_order
  JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,
      c.is_primary DESC NULLS LAST,
      c.created_at ASC
    LIMIT 1
  ) ct ON TRUE
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  CASE
    WHEN r.next_send_at > timestamptz '2026-07-21 16:00:00+00'
      THEN 'not due Tuesday (later next_send_at)'
    WHEN r.send_to IS NULL
      THEN 'no resolvable address -> worker marks skipped'
    WHEN EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.party_id = r.party_id)
      THEN 'blocked: do-not-send at PARTY level'
    WHEN EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.email_lower = lower(r.send_to))
      THEN 'blocked: do-not-send at ADDRESS level'
    ELSE 'WILL SEND'
  END                                                          AS bucket,
  count(*)                                                     AS n
FROM resolved r
GROUP BY 1
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q3. Spread of next_send_at across the 67. If every row is 07-21 16:00,
--     the "7/28 62통 (step3 22 + 40)" arithmetic in the handoff needs a
--     second look -- it implies staggered dates that would show up here.
-- ---------------------------------------------------------------------
SELECT
  e.next_send_at,
  e.next_step_order,
  count(*)                                                     AS n
FROM app.email_sequence_enrollments e
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
GROUP BY e.next_send_at, e.next_step_order
ORDER BY e.next_send_at, e.next_step_order;


-- ---------------------------------------------------------------------
-- Q4. Timezone exposure of the REAL cohort -- only what actually sends.
--     The earlier country scan measured all 67, which overstates it.
--     This re-measures after the guards.
-- ---------------------------------------------------------------------
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.party_id,
    e.next_send_at,
    p.party_name,
    p.country_code,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS send_to
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
   AND st.step_order  = e.next_step_order
  JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,
      c.is_primary DESC NULLS LAST,
      c.created_at ASC
    LIMIT 1
  ) ct ON TRUE
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  CASE
    WHEN r.country_code IS NULL THEN 'unknown'
    WHEN r.country_code IN ('US','CA','BR') THEN 'business hours'
    WHEN r.country_code IN ('GB','IE','DE','FR','NL','CH','SE','DK','NO','FI','ES','IT','BE','AT','IL')
      THEN 'EVENING (Europe 17-18h)'
    WHEN r.country_code IN ('JP','KR','CN','SG','AU','NZ','IN')
      THEN 'NIGHT (Asia 00-01h)'
    ELSE 'check by hand'
  END                                                          AS window,
  count(*)                                                     AS will_send
FROM resolved r
WHERE r.next_send_at <= timestamptz '2026-07-21 16:00:00+00'
  AND r.send_to IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.party_id = r.party_id)
  AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.email_lower = lower(r.send_to))
GROUP BY 1
ORDER BY will_send DESC;


-- ---------------------------------------------------------------------
-- Q5. Name the Asia cohort -- the ones who get a cold pitch at 00:00-01:00
--     local. Short list. Decide each by hand, or split the sequence.
-- ---------------------------------------------------------------------
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.party_id,
    e.next_send_at,
    p.party_name,
    p.country_code,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS send_to
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
   AND st.step_order  = e.next_step_order
  JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,
      c.is_primary DESC NULLS LAST,
      c.created_at ASC
    LIMIT 1
  ) ct ON TRUE
  WHERE e.sequence_id::text LIKE '63737c08%'
    AND e.status::text = 'active'
)
SELECT
  r.enrollment_id,
  r.party_name,
  r.country_code,
  r.send_to,
  r.next_send_at
FROM resolved r
WHERE r.country_code IN ('JP','KR','CN','SG','AU','NZ','IN')
  AND r.next_send_at <= timestamptz '2026-07-21 16:00:00+00'
  AND r.send_to IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.party_id = r.party_id)
  AND NOT EXISTS (SELECT 1 FROM app.v_email_do_not_send d WHERE d.email_lower = lower(r.send_to))
ORDER BY r.country_code, r.party_name;
