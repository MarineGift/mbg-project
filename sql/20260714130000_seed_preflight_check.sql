-- =====================================================================
-- 20260714130000_seed_preflight_check.sql
-- Purpose: PRE-SEND audit for the 7/20 Seed sequence
--          ('Investor Cold Outreach - FCC Seed', 68 active enrollments).
-- Read-only diagnostics: no UPDATE/INSERT. Run each part separately,
-- review the rows, then decide whether to cancel/fix any before 7/20.
--
-- Schema facts (confirmed 2026-07-14):
--   * app.email_sequences has NO org column -> match by name.
--   * enrollments carry contact_id/party_id, not recipient_email ->
--     resolve the address through app.contacts.email.
--   * do-not-send view = app.v_email_do_not_send (email_lower key).
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 0: sanity - the sequence exists and how many are active
-- ---------------------------------------------------------------------
SELECT s.id AS sequence_id, s.name,
       COUNT(*) FILTER (WHERE e.status = 'active'::app.enrollment_status) AS active_cnt,
       COUNT(*) AS total_cnt
FROM app.email_sequences s
JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
WHERE s.name = 'Investor Cold Outreach - FCC Seed'
GROUP BY s.id, s.name;

-- ---------------------------------------------------------------------
-- PART 1: NULL / empty / malformed recipient email among active Seed
--         enrollments. These would silently skip (or error) at send.
-- Expect: ideally 0 rows. Any row here needs a contact-email fix or a
--         cancel before 7/20.
-- ---------------------------------------------------------------------
SELECT e.id AS enrollment_id, e.status, p.party_name,
       c.id AS contact_id, c.full_name, c.email,
       CASE
         WHEN c.id IS NULL THEN 'no contact linked'
         WHEN c.email IS NULL OR btrim(c.email) = '' THEN 'empty email'
         WHEN c.email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN 'malformed email'
         ELSE 'ok'
       END AS email_status
FROM app.email_sequences s
JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
LEFT JOIN app.contacts c ON c.id = e.contact_id
LEFT JOIN app.parties  p ON p.id = e.party_id
WHERE s.name = 'Investor Cold Outreach - FCC Seed'
  AND e.status = 'active'::app.enrollment_status
  AND (
    c.id IS NULL
    OR c.email IS NULL
    OR btrim(c.email) = ''
    OR c.email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  )
ORDER BY email_status, p.party_name;

-- ---------------------------------------------------------------------
-- PART 2: do-not-send cross-check. Active Seed enrollments whose
--         recipient address is on the do-not-send view (hard bounce,
--         unsubscribe, suppress, or resend_later cooldown).
-- Expect: the 5 recorded 7/14 addresses only if they are also Seed
--         contacts. Any hit = must cancel before 7/20 (they got a
--         reject/bounce on the Climate send, do not re-hit on Seed).
-- ---------------------------------------------------------------------
SELECT e.id AS enrollment_id, p.party_name, c.email AS recipient_email,
       dns.outcomes AS why_blocked, dns.last_event_at
FROM app.email_sequences s
JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
JOIN app.contacts c ON c.id = e.contact_id
LEFT JOIN app.parties p ON p.id = e.party_id
JOIN app.v_email_do_not_send dns ON dns.email_lower = lower(c.email)
WHERE s.name = 'Investor Cold Outreach - FCC Seed'
  AND e.status = 'active'::app.enrollment_status
ORDER BY dns.last_event_at DESC;

-- ---------------------------------------------------------------------
-- PART 3: duplicate guard re-check. Any Seed contact that ALSO has an
--         active enrollment in the Climate sequence (would be double-
--         emailed). Dedup on 7/13 handled overlaps; this reconfirms.
-- Expect: 0 rows.
-- ---------------------------------------------------------------------
WITH seed AS (
  SELECT e.contact_id
  FROM app.email_sequences s
  JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
  WHERE s.name = 'Investor Cold Outreach - FCC Seed'
    AND e.status = 'active'::app.enrollment_status
    AND e.contact_id IS NOT NULL
),
climate AS (
  SELECT e.contact_id
  FROM app.email_sequences s
  JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
  WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
    AND e.status = 'active'::app.enrollment_status
    AND e.contact_id IS NOT NULL
)
SELECT c.id AS contact_id, c.full_name, c.email, p.party_name
FROM seed
JOIN climate USING (contact_id)
JOIN app.contacts c ON c.id = seed.contact_id
LEFT JOIN app.parties p ON p.id = c.party_id
ORDER BY p.party_name;

-- ---------------------------------------------------------------------
-- PART 4: summary counts (one-glance go/no-go)
--   clean_active = active - null/bad email - do-not-send hits
-- ---------------------------------------------------------------------
WITH active AS (
  SELECT e.id, c.email, c.id AS contact_id
  FROM app.email_sequences s
  JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
  LEFT JOIN app.contacts c ON c.id = e.contact_id
  WHERE s.name = 'Investor Cold Outreach - FCC Seed'
    AND e.status = 'active'::app.enrollment_status
),
bad_email AS (
  SELECT id FROM active
  WHERE contact_id IS NULL OR email IS NULL OR btrim(email) = ''
     OR email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
),
blocked AS (
  SELECT a.id FROM active a
  JOIN app.v_email_do_not_send dns ON dns.email_lower = lower(a.email)
)
SELECT
  (SELECT COUNT(*) FROM active)                                   AS active_total,
  (SELECT COUNT(*) FROM bad_email)                               AS bad_email_cnt,
  (SELECT COUNT(*) FROM blocked)                                 AS do_not_send_cnt,
  (SELECT COUNT(*) FROM active)
    - (SELECT COUNT(DISTINCT id) FROM (
         SELECT id FROM bad_email UNION SELECT id FROM blocked
       ) x)                                                       AS clean_active;
