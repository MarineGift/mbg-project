-- =============================================================================
-- 20260626009200_intel_inside_add_two_firms.sql
-- =============================================================================
-- Two-firm patch:
--   1) Set parties.email for G2 Venture Partners and Spring Lane Capital
--      (batch 8 SQL didn't run; these were missing email when the bulk enroll
--      filter `tp.email IS NOT NULL` ran).
--   2) Add both firms to the "Investor Cold Outreach -- Intel Inside" sequence.
--
-- KKR Tech Growth and KKR Global Impact Fund are intentionally excluded:
-- mega-fund ($50B+ AUM), no public general-pitch inbox, ticket-size mismatch
-- with a $5M seed. Use warm intros if approaching KKR.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Part 1: Backfill email for the two firms (COALESCE-guarded).
-- -----------------------------------------------------------------------------
UPDATE app.parties SET
  email = COALESCE(NULLIF(email,''), 'info@g2vp.com')
WHERE id = 'df44c86a-84fa-422f-929b-9f88ab159181';  -- G2 Venture Partners

UPDATE app.parties SET
  email = COALESCE(NULLIF(email,''), 'info@springlanecapital.com')
WHERE id = '8427e74a-e19e-48c3-b04c-707f0de7d2a5';  -- Spring Lane Capital


-- -----------------------------------------------------------------------------
-- Part 2: Enroll both firms in the existing Intel Inside sequence.
-- Same idempotent pattern as the v2 migration.
-- -----------------------------------------------------------------------------
DO $patch$
DECLARE
  v_org_id    uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_seq_id    uuid;
  v_user_id   uuid;
  v_enrolled  integer;
BEGIN
  -- Look up sequence id
  SELECT id INTO v_seq_id
    FROM app.email_sequences
   WHERE organization_id = v_org_id
     AND name = 'Investor Cold Outreach -- Intel Inside'
   LIMIT 1;

  IF v_seq_id IS NULL THEN
    RAISE EXCEPTION 'Intel Inside sequence not found. Run v2 migration first.';
  END IF;

  -- Look up user id (same fallback chain as v2)
  SELECT enrolled_by INTO v_user_id
    FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id
     AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC
   LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Could not resolve user_id.';
  END IF;

  -- Enroll
  INSERT INTO app.email_sequence_enrollments (
    id, organization_id, sequence_id, party_id, contact_id, enrolled_by,
    enrolled_at, status, next_step_order, next_send_at, recipient_email,
    created_at, updated_at
  )
  SELECT
    gen_random_uuid(),
    v_org_id,
    v_seq_id,
    p.id,
    NULL,
    v_user_id,
    NOW(),
    'active',
    1,
    NOW(),  -- send immediately (next worker cycle)
    LOWER(p.email),
    NOW(),
    NOW()
  FROM app.parties p
  WHERE p.id IN (
    'df44c86a-84fa-422f-929b-9f88ab159181',  -- G2 VP
    '8427e74a-e19e-48c3-b04c-707f0de7d2a5'   -- Spring Lane
  )
  AND p.email IS NOT NULL
  AND p.email <> ''
  AND NOT EXISTS (
    SELECT 1 FROM app.email_sequence_enrollments e2
     WHERE e2.sequence_id = v_seq_id
       AND e2.party_id    = p.id
       AND LOWER(e2.recipient_email) = LOWER(p.email)
       AND e2.status IN ('active','completed')
  );

  GET DIAGNOSTICS v_enrolled = ROW_COUNT;
  RAISE NOTICE 'Enrolled % new rows.', v_enrolled;
END
$patch$;


-- -----------------------------------------------------------------------------
-- Verification
-- -----------------------------------------------------------------------------
SELECT
  p.party_name,
  e.recipient_email,
  e.status,
  e.next_step_order,
  e.next_send_at,
  e.enrolled_at
FROM app.email_sequence_enrollments e
JOIN app.parties p          ON p.id = e.party_id
JOIN app.email_sequences s  ON s.id = e.sequence_id
WHERE s.name = 'Investor Cold Outreach -- Intel Inside'
ORDER BY e.enrolled_at, p.party_name;

-- Expected: 9 rows total (7 original + 2 new).
-- The 2 newest rows (G2 VP, Spring Lane) should have enrolled_at = today.
