-- =============================================================================
-- 20260713160000_climate_sequence_enroll_more.sql
-- =============================================================================
-- Adds MORE investors to "Climate Investor Cold Outreach -- FCC" and schedules
-- them for the next Tuesday 09:00 America/Los_Angeles.
--
-- SAFETY BUILT IN:
--   * Enrolls only parties WITH an email.
--   * Skips anyone already active/completed IN THIS sequence (idempotent).
--   * Skips anyone currently ACTIVE in ANY OTHER sequence -> prevents the
--     double-send risk from overlapping campaigns (e.g. "FCC Climate Tech").
--   * next_send_at = next Tuesday 09:00 PT (DST-safe UTC instant).
--
-- >>> CHOOSE YOUR TARGET SEGMENT in Part 1 (three options, commented). <<<
--     Default enabled = Option A (energy + industrial sectors, the natural
--     climate-adjacent expansion). Comment/uncomment to change.
--
-- Run Part 0 first to preview WHO would be added, before running Part 1.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 0: PREVIEW the candidate list (read-only). Adjust the sector filter to
--         match whichever option you plan to enable in Part 1.
-- -----------------------------------------------------------------------------
WITH seq AS (
  SELECT id FROM app.email_sequences
  WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1
),
candidates AS (
  SELECT DISTINCT p.id, p.party_name, LOWER(p.email) AS email
  FROM app.parties p
  JOIN app.investor_profile ip        ON ip.party_id = p.id
  JOIN app.investor_sector_focus isf   ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                    ON s.id = isf.sector_id
  WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND p.deleted_at IS NULL
    AND p.email IS NOT NULL AND p.email <> ''
    -- ==== TARGET FILTER (match Part 1) ====
    AND s.code IN ('energy','industrial')          -- Option A (default)
    -- AND s.code IN ('advanced_materials','deep_tech')  -- Option B
    -- (Option C: remove the sector filter entirely = all investors with email)
)
SELECT c.party_name, c.email,
       -- flag anyone already busy elsewhere (will be skipped in Part 1)
       EXISTS (
         SELECT 1 FROM app.email_sequence_enrollments e
         WHERE e.party_id = c.id AND e.status = 'active'
       ) AS already_active_somewhere
FROM candidates c
ORDER BY already_active_somewhere DESC, c.party_name;


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

  -- Acting user (same fallback chain as create migration).
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
    SELECT DISTINCT p.id, LOWER(p.email) AS email
    FROM app.parties p
    JOIN app.investor_profile ip        ON ip.party_id = p.id
    JOIN app.investor_sector_focus isf   ON isf.investor_profile_id = ip.id
    JOIN app.sectors s                    ON s.id = isf.sector_id
    WHERE p.organization_id = v_org_id
      AND p.deleted_at IS NULL
      AND p.email IS NOT NULL AND p.email <> ''
      -- ==== TARGET FILTER (match Part 0) ====
      AND s.code IN ('energy','industrial')          -- Option A (default)
      -- AND s.code IN ('advanced_materials','deep_tech')  -- Option B
      -- (Option C: remove this AND line = all investors with email)
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
  WHERE
    -- not already in THIS sequence (active/completed)
    NOT EXISTS (
      SELECT 1 FROM app.email_sequence_enrollments e2
      WHERE e2.sequence_id = v_seq_id
        AND e2.party_id = c.id
        AND e2.status IN ('active','completed')
    )
    -- and not ACTIVE in ANY other sequence (avoid double-send)
    AND NOT EXISTS (
      SELECT 1 FROM app.email_sequence_enrollments e3
      WHERE e3.party_id = c.id
        AND e3.status = 'active'
    );

  GET DIAGNOSTICS v_added = ROW_COUNT;
  RAISE NOTICE 'Enrolled % new investors, scheduled for % (UTC).', v_added, v_next_send;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 2: VERIFY newly-scheduled roster (read-only).
-- -----------------------------------------------------------------------------
SELECT p.party_name, e.recipient_email, e.status, e.next_step_order,
       e.next_send_at AT TIME ZONE 'America/Los_Angeles' AS next_send_pt
FROM app.email_sequence_enrollments e
JOIN app.parties p         ON p.id = e.party_id
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
ORDER BY e.enrolled_at DESC, p.party_name;
