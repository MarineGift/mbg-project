-- =============================================================================
-- 20260713190000_climate_sequence_enroll_targeted.sql
-- =============================================================================
-- Enrolls the RIGHT investors into "Climate Investor Cold Outreach -- FCC":
--
--   TARGET sectors : deep_tech, advanced_materials, industrial, climate
--   STAGE          : Series A and later (excludes pre-seed / seed-only funds)
--   EXCLUDE sectors: healthcare, life_science, consumer  (go to a different deck)
--   EXCLUDE        : form-only / portal-only investors   (handled separately)
--   EXCLUDE        : anyone already active/completed in ANY sequence (no dup send)
--   REQUIRE        : a usable email
--   SCHEDULE       : next Tuesday 09:00 America/Los_Angeles
--
-- FK-safe (INSERT-only). Idempotent. Run Part 0 (schema probe) + Part 1
-- (preview) FIRST, confirm the stage codes, then run Part 2 (enroll).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 0: SCHEMA PROBE (read-only). Confirm the real stage codes + form columns
--         before trusting the filters below.
-- -----------------------------------------------------------------------------

-- 0a) What stage codes actually exist, and how many investors per stage.
--     (Look for the code that means "Series A". Adjust Part 1/2 if it differs
--      from the assumed set {series_a, series_b, series_c, growth, late_stage}.)
SELECT sf.stage_code, COUNT(DISTINCT ip.party_id) AS investors
FROM app.investor_stage_focus sf
JOIN app.investor_profile ip ON ip.id = sf.investor_profile_id
GROUP BY sf.stage_code
ORDER BY sf.stage_code;

-- 0b) Form-only marking: distinct preferred_contact_method values in use.
SELECT preferred_contact_method, COUNT(*) AS n
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY preferred_contact_method
ORDER BY n DESC;


-- -----------------------------------------------------------------------------
-- Part 1: PREVIEW the target list (read-only).
--   NOTE: adjust the two IN (...) lists below if Part 0 shows different codes.
-- -----------------------------------------------------------------------------
WITH seq AS (
  SELECT id FROM app.email_sequences
  WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1
),
-- investors whose sector set INCLUDES a target sector
target_sector AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                  ON s.id = isf.sector_id
  WHERE s.code IN ('deep_tech','advanced_materials','industrial','climate')
),
-- investors whose sector set INCLUDES an excluded (other-deck) sector
excluded_sector AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
  JOIN app.sectors s                  ON s.id = isf.sector_id
  WHERE s.code IN ('healthcare','life_science','consumer')
),
-- investors that invest at Series A or later
series_a_plus AS (
  SELECT DISTINCT ip.party_id
  FROM app.investor_profile ip
  JOIN app.investor_stage_focus sf ON sf.investor_profile_id = ip.id
  WHERE sf.stage_code IN ('series_a','series_b','series_c','growth','late_stage')
),
already_enrolled AS (
  SELECT DISTINCT party_id FROM app.email_sequence_enrollments
  WHERE status IN ('active','completed')
)
SELECT p.party_name, LOWER(TRIM(p.email)) AS email,
       (SELECT string_agg(DISTINCT s2.code, ', ')
          FROM app.investor_profile ip2
          JOIN app.investor_sector_focus isf2 ON isf2.investor_profile_id = ip2.id
          JOIN app.sectors s2 ON s2.id = isf2.sector_id
         WHERE ip2.party_id = p.id) AS sectors
FROM app.parties p
JOIN app.investor_profile ip ON ip.party_id = p.id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND NULLIF(TRIM(p.email), '') IS NOT NULL
  AND p.id IN (SELECT party_id FROM target_sector)
  AND p.id IN (SELECT party_id FROM series_a_plus)
  AND p.id NOT IN (SELECT party_id FROM excluded_sector)
  AND p.id NOT IN (SELECT party_id FROM already_enrolled)
  -- exclude form-only / portal-only
  AND COALESCE(p.preferred_contact_method, '') NOT IN ('web_form','portal','form')
ORDER BY p.party_name;


-- -----------------------------------------------------------------------------
-- Part 2: ENROLL (writes). Same filter as Part 1.
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
  SELECT id INTO v_seq_id FROM app.email_sequences
   WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1;
  IF v_seq_id IS NULL THEN RAISE EXCEPTION 'Sequence not found.'; END IF;

  SELECT enrolled_by INTO v_user_id FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC LIMIT 1;
  IF v_user_id IS NULL THEN
    SELECT created_by INTO v_user_id FROM app.parties
     WHERE organization_id = v_org_id AND created_by IS NOT NULL
     ORDER BY created_at DESC LIMIT 1;
  END IF;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Could not resolve user_id.'; END IF;

  v_today_la := (now() AT TIME ZONE 'America/Los_Angeles')::date;
  v_next_tue_la := v_today_la + (((2 - EXTRACT(ISODOW FROM v_today_la)::int) + 7) % 7);
  IF v_next_tue_la <= v_today_la THEN v_next_tue_la := v_next_tue_la + 7; END IF;
  v_next_send := (v_next_tue_la::text || ' 09:00')::timestamp
                 AT TIME ZONE 'America/Los_Angeles';

  WITH target_sector AS (
    SELECT DISTINCT ip.party_id
    FROM app.investor_profile ip
    JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
    JOIN app.sectors s                  ON s.id = isf.sector_id
    WHERE s.code IN ('deep_tech','advanced_materials','industrial','climate')
  ),
  excluded_sector AS (
    SELECT DISTINCT ip.party_id
    FROM app.investor_profile ip
    JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
    JOIN app.sectors s                  ON s.id = isf.sector_id
    WHERE s.code IN ('healthcare','life_science','consumer')
  ),
  series_a_plus AS (
    SELECT DISTINCT ip.party_id
    FROM app.investor_profile ip
    JOIN app.investor_stage_focus sf ON sf.investor_profile_id = ip.id
    WHERE sf.stage_code IN ('series_a','series_b','series_c','growth','late_stage')
  ),
  already_enrolled AS (
    SELECT DISTINCT party_id FROM app.email_sequence_enrollments
    WHERE status IN ('active','completed')
  ),
  candidates AS (
    SELECT p.id, LOWER(TRIM(p.email)) AS email
    FROM app.parties p
    JOIN app.investor_profile ip ON ip.party_id = p.id
    WHERE p.organization_id = v_org_id
      AND p.deleted_at IS NULL
      AND NULLIF(TRIM(p.email), '') IS NOT NULL
      AND p.id IN (SELECT party_id FROM target_sector)
      AND p.id IN (SELECT party_id FROM series_a_plus)
      AND p.id NOT IN (SELECT party_id FROM excluded_sector)
      AND p.id NOT IN (SELECT party_id FROM already_enrolled)
      AND COALESCE(p.preferred_contact_method, '') NOT IN ('web_form','portal','form')
  )
  INSERT INTO app.email_sequence_enrollments (
    id, organization_id, sequence_id, party_id, contact_id, enrolled_by,
    enrolled_at, status, next_step_order, next_send_at, recipient_email,
    created_at, updated_at
  )
  SELECT gen_random_uuid(), v_org_id, v_seq_id, c.id, NULL, v_user_id,
         now(), 'active', 1, v_next_send, c.email, now(), now()
  FROM candidates c;

  GET DIAGNOSTICS v_added = ROW_COUNT;
  RAISE NOTICE 'Enrolled % targeted investors, scheduled for % (UTC).', v_added, v_next_send;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Part 3: VERIFY (read-only).
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
