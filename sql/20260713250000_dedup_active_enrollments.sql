-- =============================================================================
-- 20260713250000_dedup_active_enrollments.sql
-- =============================================================================
-- Fixes cross-sequence double-sends found in the roster audit:
--   * 8 investors are ACTIVE in BOTH "Climate Investor Cold Outreach -- FCC"
--     (sends Tue 7/14) AND "Investor Cold Outreach - FCC Seed" (sends 7/20).
--     -> Same week, two different FCC cold emails = looks like spam.
--   * Test records (test / "test" / MBG Mailing Test) are ACTIVE in FCC Seed
--     and must never actually send.
--
-- POLICY:
--   * For the 8 climate/energy overlaps, KEEP the Climate sequence (better
--     targeted) and STOP the FCC Seed enrollment.
--   * STOP all test-record enrollments everywhere.
--
-- "Stop" = set status to 'unsubscribed' (a terminal state the worker skips)
--   and clear next_send_at so it can never fire. FK-safe (no deletes).
--   If your schema uses a different terminal status than 'unsubscribed',
--   change v_stop_status below (run Part 0 to see valid values).
--
-- Run Part 0 (preview) first. Confirm the rows. Then run Part 1.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 0a: status is an ENUM (app.enrollment_status). List its VALID values,
--          then the current distribution. Pick a terminal value that EXISTS.
-- -----------------------------------------------------------------------------
-- Valid enum values:
SELECT e.enumlabel AS valid_status
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.typname = 'enrollment_status'
ORDER BY e.enumsortorder;

-- Current distribution:
SELECT status, COUNT(*) AS n
FROM app.email_sequence_enrollments
GROUP BY status
ORDER BY n DESC;

-- -----------------------------------------------------------------------------
-- Part 0b: PREVIEW — the FCC Seed enrollments that will be stopped
--          (the 8 overlaps + any test records).
-- -----------------------------------------------------------------------------
WITH climate AS (
  SELECT id FROM app.email_sequences
  WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1
),
seed AS (
  SELECT id FROM app.email_sequences
  WHERE name = 'Investor Cold Outreach - FCC Seed' LIMIT 1
),
climate_active AS (
  SELECT DISTINCT party_id
  FROM app.email_sequence_enrollments
  WHERE sequence_id = (SELECT id FROM climate) AND status = 'active'
)
SELECT p.party_name, e.recipient_email, e.status,
       e.next_send_at AT TIME ZONE 'America/Los_Angeles' AS next_send_pt,
       CASE
         WHEN p.party_name ILIKE '%test%' OR p.party_name = 'test'
           THEN 'TEST RECORD'
         ELSE 'OVERLAP -> keep Climate'
       END AS reason
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id = (SELECT id FROM seed)
  AND e.status = 'active'
  AND (
        e.party_id IN (SELECT party_id FROM climate_active)   -- the 8 overlaps
     OR p.party_name ILIKE '%test%'                            -- test rows
     OR p.party_name = 'test'
      )
ORDER BY reason, p.party_name;


-- -----------------------------------------------------------------------------
-- Part 1: STOP those enrollments.
-- -----------------------------------------------------------------------------
DO $migration$
DECLARE
  v_stop_status text := 'unsubscribed';   -- MUST be one of the enum values from Part 0a
  v_climate_id  uuid;
  v_seed_id     uuid;
  v_stopped     integer;
BEGIN
  SELECT id INTO v_climate_id FROM app.email_sequences
   WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1;
  SELECT id INTO v_seed_id FROM app.email_sequences
   WHERE name = 'Investor Cold Outreach - FCC Seed' LIMIT 1;

  UPDATE app.email_sequence_enrollments e
     SET status       = v_stop_status::app.enrollment_status,
         next_send_at = NULL,
         updated_at   = now()
  FROM app.parties p
  WHERE p.id = e.party_id
    AND e.sequence_id = v_seed_id
    AND e.status = 'active'
    AND (
          e.party_id IN (
            SELECT party_id FROM app.email_sequence_enrollments
            WHERE sequence_id = v_climate_id AND status = 'active'
          )
       OR p.party_name ILIKE '%test%'
       OR p.party_name = 'test'
        );

  GET DIAGNOSTICS v_stopped = ROW_COUNT;
  RAISE NOTICE 'Stopped % FCC-Seed enrollments (overlaps + test records).', v_stopped;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 2: VERIFY — no party should be active in 2+ sequences now.
-- -----------------------------------------------------------------------------
SELECT p.party_name, COUNT(*) AS active_sequences,
       string_agg(s.name, ' | ') AS sequences
FROM app.email_sequence_enrollments e
JOIN app.parties p          ON p.id = e.party_id
JOIN app.email_sequences s  ON s.id = e.sequence_id
WHERE e.status = 'active'
GROUP BY p.party_name
HAVING COUNT(*) >= 2
ORDER BY active_sequences DESC, p.party_name;
-- Expect: 0 rows (or only intentional multi-sequence parties).
