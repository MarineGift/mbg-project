-- =============================================================================
-- 20260713180000_climate_sequence_enroll_all_remaining.sql
-- =============================================================================
-- Enrolls EVERY remaining investor that has an email (ANY sector) into
-- "Climate Investor Cold Outreach -- FCC", scheduled for the next Tuesday
-- 09:00 America/Los_Angeles.
--
-- This is the "send to everyone else we can reach" step.
--
-- SAFETY (idempotent + no double-send):
--   * email required (NULL/'' skipped).
--   * skipped if already active/completed IN THIS sequence.
--   * skipped if ACTIVE in ANY OTHER sequence.
--   * FK-safe: only INSERTs enrollments, never touches steps/sends.
--
-- Run Part 0 (preview) first. If the count looks right, run Part 1.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 0: PREVIEW — exactly who will be added (read-only).
-- -----------------------------------------------------------------------------
WITH seq AS (
  SELECT id FROM app.email_sequences
  WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1
),
candidates AS (
  SELECT DISTINCT p.id, p.party_name, LOWER(TRIM(p.email)) AS email
  FROM app.parties p
  JOIN app.investor_profile ip ON ip.party_id = p.id
  WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND p.deleted_at IS NULL
    AND NULLIF(TRIM(p.email), '') IS NOT NULL
)
SELECT c.party_name, c.email
FROM candidates c
WHERE NOT EXISTS (
        SELECT 1 FROM app.email_sequence_enrollments e2, seq
        WHERE e2.sequence_id = seq.id
          AND e2.party_id = c.id
          AND e2.status IN ('active','completed')
      )
  AND NOT EXISTS (
        SELECT 1 FROM app.email_sequence_enrollments e3
        WHERE e3.party_id = c.id
          AND e3.status = 'active'
      )
ORDER BY c.party_name;


-- -----------------------------------------------------------------------------
-- Part 1: ENROLL + schedule for next Tuesday 09:00 PT.
-- -----------------------------------------------------------------------------
DO $migration$
DECLARE
  v_org_id      uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_seq_id      uuid;
  v_user_id     uuid;
  v_today_la    date;
  v_next_tue_la date;
  v_next_send   timestamptz;
  v_added       integer;
BEGIN
  SELECT id INTO v_seq_id
    FROM app.email_sequences
   WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1;
  IF v_seq_id IS NULL THEN RAISE EXCEPTION 'Sequence not found.'; END IF;

  SELECT enrolled_by INTO v_user_id
    FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC LIMIT 1;
  IF v_user_id IS NULL THEN
    SELECT created_by INTO v_user_id FROM app.parties
     WHERE organization_id = v_org_id AND created_by IS NOT NULL
     ORDER BY created_at DESC LIMIT 1;
  END IF;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Could not resolve user_id.'; END IF;

  -- Next Tuesday 09:00 PT (DST-safe).
  v_today_la := (now() AT TIME ZONE 'America/Los_Angeles')::date;
  v_next_tue_la := v_today_la + (((2 - EXTRACT(ISODOW FROM v_today_la)::int) + 7) % 7);
  IF v_next_tue_la <= v_today_la THEN v_next_tue_la := v_next_tue_la + 7; END IF;
  v_next_send := (v_next_tue_la::text || ' 09:00')::timestamp
                 AT TIME ZONE 'America/Los_Angeles';

  WITH candidates AS (
    SELECT DISTINCT p.id, LOWER(TRIM(p.email)) AS email
    FROM app.parties p
    JOIN app.investor_profile ip ON ip.party_id = p.id
    WHERE p.organization_id = v_org_id
      AND p.deleted_at IS NULL
      AND NULLIF(TRIM(p.email), '') IS NOT NULL
  )
  INSERT INTO app.email_sequence_enrollments (
    id, organization_id, sequence_id, party_id, contact_id, enrolled_by,
    enrolled_at, status, next_step_order, next_send_at, recipient_email,
    created_at, updated_at
  )
  SELECT
    gen_random_uuid(), v_org_id, v_seq_id, c.id, NULL, v_user_id,
    now(), 'active', 1, v_next_send, c.email, now(), now()
  FROM candidates c
  WHERE NOT EXISTS (
          SELECT 1 FROM app.email_sequence_enrollments e2
          WHERE e2.sequence_id = v_seq_id
            AND e2.party_id = c.id
            AND e2.status IN ('active','completed')
        )
    AND NOT EXISTS (
          SELECT 1 FROM app.email_sequence_enrollments e3
          WHERE e3.party_id = c.id
            AND e3.status = 'active'
        );

  GET DIAGNOSTICS v_added = ROW_COUNT;
  RAISE NOTICE 'Enrolled % remaining investors, scheduled for % (UTC).', v_added, v_next_send;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 2: VERIFY — full roster with send time (read-only).
-- -----------------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM app.email_sequence_enrollments e
     JOIN app.email_sequences s ON s.id = e.sequence_id
    WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
      AND e.status = 'active') AS total_active;

SELECT p.party_name, e.recipient_email, e.next_step_order,
       e.next_send_at AT TIME ZONE 'America/Los_Angeles' AS next_send_pt
FROM app.email_sequence_enrollments e
JOIN app.parties p         ON p.id = e.party_id
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
  AND e.status = 'active'
ORDER BY e.next_step_order, p.party_name;
