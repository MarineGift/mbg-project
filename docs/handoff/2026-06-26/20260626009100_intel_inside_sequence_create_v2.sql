-- =============================================================================
-- 20260626009100_intel_inside_sequence_create_v2.sql
-- =============================================================================
-- Replaces v1 (20260626009000) -- two fixes:
--   1) Email bodies now use $body$ ... $body$ dollar-quoting
--      (the prior E'...' E'...' concatenation didn't parse in Supabase).
--   2) KKR matching now uses ILIKE 'KKR%' to catch both
--      "KKR Tech Growth" and "KKR Global Impact Fund".
--
-- Part 1 (ALTER TABLE) is left in for idempotency -- columns already exist
-- from the v1 run, so ADD COLUMN IF NOT EXISTS is a no-op.
--
-- Run in Supabase SQL Editor.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Part 1: Audit columns (idempotent; no-op if already added by v1).
-- -----------------------------------------------------------------------------
ALTER TABLE app.email_sequences
  ADD COLUMN IF NOT EXISTS created_by uuid,
  ADD COLUMN IF NOT EXISTS updated_by uuid;


-- -----------------------------------------------------------------------------
-- Part 2-5: Atomic block.
-- -----------------------------------------------------------------------------
DO $migration$
DECLARE
  v_org_id        uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_from_acct_id  uuid := '4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2';
  v_user_id       uuid;
  v_seq_id        uuid;
  v_existing_id   uuid;
  v_enrolled      integer;
BEGIN
  -- Resolve user_id (most recent enrollment user is the best signal).
  SELECT enrolled_by INTO v_user_id
    FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id
     AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC
   LIMIT 1;

  IF v_user_id IS NULL THEN
    SELECT created_by INTO v_user_id
      FROM app.parties
     WHERE organization_id = v_org_id
       AND created_by IS NOT NULL
     ORDER BY created_at DESC
     LIMIT 1;
  END IF;

  IF v_user_id IS NULL THEN
    SELECT recorded_by_user_id INTO v_user_id
      FROM app.engagements
     WHERE organization_id = v_org_id
       AND recorded_by_user_id IS NOT NULL
     ORDER BY occurred_at DESC
     LIMIT 1;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION
      'Could not resolve user_id. Set v_user_id manually (paste the auth.users.id for ceo@marinebiogroup.com).';
  END IF;

  RAISE NOTICE 'Resolved user_id: %', v_user_id;


  -- ---------------------------------------------------------------------------
  -- Backfill existing sequences with audit values.
  -- ---------------------------------------------------------------------------
  UPDATE app.email_sequences
     SET created_by = v_user_id,
         updated_by = v_user_id
   WHERE organization_id = v_org_id
     AND created_by IS NULL;


  -- ---------------------------------------------------------------------------
  -- Create (or reuse) the sequence.
  -- ---------------------------------------------------------------------------
  SELECT id INTO v_existing_id
    FROM app.email_sequences
   WHERE organization_id = v_org_id
     AND name = 'Investor Cold Outreach -- Intel Inside'
   LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    v_seq_id := v_existing_id;
    RAISE NOTICE 'Sequence already exists: % -- reusing.', v_seq_id;
  ELSE
    v_seq_id := gen_random_uuid();
    INSERT INTO app.email_sequences (
      id, organization_id, name, description, status,
      from_account_id, created_by, updated_by
    ) VALUES (
      v_seq_id,
      v_org_id,
      'Investor Cold Outreach -- Intel Inside',
      '2-step concise outreach. Day 0: "Intel Inside" framing with 9k/10k ton order hook. Day 5: short bump.',
      'active',
      v_from_acct_id,
      v_user_id,
      v_user_id
    );
    RAISE NOTICE 'Created sequence: %', v_seq_id;
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 1 -- Day 0 (dollar-quoted body)
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (
    SELECT 1 FROM app.email_sequence_steps
     WHERE sequence_id = v_seq_id AND step_order = 1
  ) THEN
    INSERT INTO app.email_sequence_steps (
      id, sequence_id, step_order, day_offset,
      subject, body_plain, organization_id
    ) VALUES (
      gen_random_uuid(), v_seq_id, 1, 0,
      'Intel Inside for paper - 9,000 ton order + 10,000 ton commitment',
$body$Hi {{contact.firstName}},

Quick pitch from Yun-young Heo, CEO of MarineBio Group:

- 9,000 tons confirmed order from a top-tier global mill.
- 10,000 tons committed by a second.
- Our goal: become the "Intel Inside" of every paper mill, cutting cost and lifting quality at the same time.
- The category: the leading scalable plastic alternative - paper - used at hundreds of millions of tons per year.

Interested in the core material tech behind it? I'll send the IR deck.

Best regards,
Yun-young Heo$body$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 1 (Day 0).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 2 -- Day 5 (dollar-quoted body)
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (
    SELECT 1 FROM app.email_sequence_steps
     WHERE sequence_id = v_seq_id AND step_order = 2
  ) THEN
    INSERT INTO app.email_sequence_steps (
      id, sequence_id, step_order, day_offset,
      subject, body_plain, organization_id
    ) VALUES (
      gen_random_uuid(), v_seq_id, 2, 5,
      'Re: Intel Inside for paper - 9,000 ton order + 10,000 ton commitment',
$body$Hi {{contact.firstName}},

Did the previous note make it through? Happy to send the IR deck if useful.

Best regards,
Yun-young Heo$body$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 2 (Day 5).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Bulk enroll: 9 firms by UUID + all parties whose name starts with "KKR"
  -- (catches both "KKR Tech Growth" and "KKR Global Impact Fund").
  -- ---------------------------------------------------------------------------
  WITH target_parties AS (
    SELECT p.id, p.party_name, p.email
      FROM app.parties p
     WHERE p.id IN (
       'bd7d653f-6080-4c69-a8c2-4114640a1546',  -- Phoenix Venture Partners
       'dcec2122-064b-4f32-9fb0-bea17c7517fb',  -- SOSV
       '7de513f3-4043-406c-ac86-916120efc6d2',  -- Playground Global
       '72204d39-9de7-4c79-a9bf-c754b70e69fe',  -- Voyager Ventures
       '12be89c6-0cc7-4549-a626-7baed4baa256',  -- Prelude Ventures
       '1bafe5b3-78c3-4d23-afa2-05be91ce369e',  -- Generate Capital
       '5acf0405-9888-460b-a7cd-594c159b2ec4',  -- Founder Collective
       'df44c86a-84fa-422f-929b-9f88ab159181',  -- G2 Venture Partners
       '8427e74a-e19e-48c3-b04c-707f0de7d2a5'   -- Spring Lane Capital
     )
    UNION
    SELECT p.id, p.party_name, p.email
      FROM app.parties p
     WHERE p.party_name ILIKE 'KKR%'
       AND p.organization_id = v_org_id
  )
  INSERT INTO app.email_sequence_enrollments (
    id, organization_id, sequence_id, party_id, contact_id, enrolled_by,
    enrolled_at, status, next_step_order, next_send_at, recipient_email,
    created_at, updated_at
  )
  SELECT
    gen_random_uuid(),
    v_org_id,
    v_seq_id,
    tp.id,
    NULL,
    v_user_id,
    NOW(),
    'active',
    1,
    NOW(),
    LOWER(tp.email),
    NOW(),
    NOW()
  FROM target_parties tp
  WHERE tp.email IS NOT NULL
    AND tp.email <> ''
    AND NOT EXISTS (
      SELECT 1 FROM app.email_sequence_enrollments e2
       WHERE e2.sequence_id = v_seq_id
         AND e2.party_id    = tp.id
         AND LOWER(e2.recipient_email) = LOWER(tp.email)
         AND e2.status IN ('active','completed')
    );

  GET DIAGNOSTICS v_enrolled = ROW_COUNT;
  RAISE NOTICE 'Bulk enroll inserted % rows.', v_enrolled;
END
$migration$;


-- -----------------------------------------------------------------------------
-- Verification (read-only).
-- -----------------------------------------------------------------------------

-- A) Sequence + step + enrolled counts
SELECT
  s.id,
  s.name,
  s.status,
  s.created_by,
  (SELECT COUNT(*) FROM app.email_sequence_steps WHERE sequence_id = s.id)       AS step_count,
  (SELECT COUNT(*) FROM app.email_sequence_enrollments WHERE sequence_id = s.id) AS enrolled_count,
  s.created_at
FROM app.email_sequences s
WHERE s.name = 'Investor Cold Outreach -- Intel Inside';

-- B) Enrolled firm details (expect 11 rows: 9 by UUID + KKR Tech Growth + KKR Global Impact Fund,
--    assuming both have email set; if not, fewer rows).
SELECT
  p.party_name,
  e.recipient_email,
  e.status,
  e.next_step_order,
  e.next_send_at
FROM app.email_sequence_enrollments e
JOIN app.parties p          ON p.id = e.party_id
JOIN app.email_sequences s  ON s.id = e.sequence_id
WHERE s.name = 'Investor Cold Outreach -- Intel Inside'
ORDER BY p.party_name;

-- C) Step bodies sanity-check
SELECT
  step_order,
  day_offset,
  subject,
  LEFT(body_plain, 100) AS body_preview,
  LENGTH(body_plain)    AS body_length
FROM app.email_sequence_steps
WHERE sequence_id = (
  SELECT id FROM app.email_sequences
  WHERE name = 'Investor Cold Outreach -- Intel Inside'
  LIMIT 1
)
ORDER BY step_order;

-- D) Audit columns coverage on all sequences
SELECT
  COUNT(*) FILTER (WHERE created_by IS NULL) AS missing_created_by,
  COUNT(*) FILTER (WHERE updated_by IS NULL) AS missing_updated_by,
  COUNT(*)                                    AS total_sequences
FROM app.email_sequences
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169';
