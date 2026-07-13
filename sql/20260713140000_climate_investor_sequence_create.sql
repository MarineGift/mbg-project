-- =============================================================================
-- 20260713140000_climate_investor_sequence_create.sql
-- =============================================================================
-- Creates the "Climate Investor Cold Outreach -- FCC" email sequence and
-- bulk-enrolls every climate-tagged investor party that has an email.
--
-- Pattern mirrors the working Intel-Inside create v2 (2026-06-26):
--   * dollar-quoted bodies  (dollar-tag delimited)  -- Supabase-safe, no ';' issues
--   * single DO block, self-contained
--   * IF NOT EXISTS guards on sequence + each step  -> idempotent, safe to re-run
--   * enroll only where email is set AND not already active/completed
--
-- Schema used (verified against repo):
--   app.email_sequences        (id, organization_id, name, description, status,
--                               from_account_id, created_by, updated_by)
--   app.email_sequence_steps   (id, sequence_id, step_order, day_offset,
--                               subject, body_plain, organization_id)
--   app.email_sequence_enrollments (id, organization_id, sequence_id, party_id,
--                               contact_id, enrolled_by, enrolled_at, status,
--                               next_step_order, next_send_at, recipient_email,
--                               created_at, updated_at)
--   Climate targeting path:
--     app.parties -> app.investor_profile(party_id)
--                 -> app.investor_sector_focus(investor_profile_id)
--                 -> app.sectors(code = 'climate')
--
-- Merge tokens (rendered by the sequence worker): {{contact.firstName}}
--
-- BEFORE RUNNING:
--   1) Confirm v_from_account_id below is the account you want to send FROM.
--      (Left as the same from-account used by prior sequences. Change if needed.)
--   2) If the deck cover date still says "June 2026", update it before sending.
--
-- HOW TO APPLY: paste into the Supabase SQL Editor and run. Read the NOTICEs.
-- =============================================================================

-- Audit columns (idempotent; no-op if already present).
ALTER TABLE app.email_sequences
  ADD COLUMN IF NOT EXISTS created_by uuid,
  ADD COLUMN IF NOT EXISTS updated_by uuid;


DO $migration$
DECLARE
  v_org_id          uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_from_account_id uuid := '4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2';
  v_user_id         uuid;
  v_seq_id          uuid;
  v_existing_id     uuid;
  v_enrolled        integer;
  v_seq_name        text := 'Climate Investor Cold Outreach -- FCC';
BEGIN
  -- ---------------------------------------------------------------------------
  -- Resolve acting user_id (same fallback chain as prior sequence migrations).
  -- ---------------------------------------------------------------------------
  SELECT enrolled_by INTO v_user_id
    FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC LIMIT 1;

  IF v_user_id IS NULL THEN
    SELECT created_by INTO v_user_id
      FROM app.parties
     WHERE organization_id = v_org_id AND created_by IS NOT NULL
     ORDER BY created_at DESC LIMIT 1;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION
      'Could not resolve user_id. Set v_user_id manually (auth.users.id for ceo@marinebiogroup.com).';
  END IF;

  RAISE NOTICE 'Resolved user_id: %', v_user_id;


  -- Backfill audit values on existing sequences.
  UPDATE app.email_sequences
     SET created_by = v_user_id, updated_by = v_user_id
   WHERE organization_id = v_org_id AND created_by IS NULL;


  -- ---------------------------------------------------------------------------
  -- Create (or reuse) the sequence.
  -- ---------------------------------------------------------------------------
  SELECT id INTO v_existing_id
    FROM app.email_sequences
   WHERE organization_id = v_org_id AND name = v_seq_name
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
      v_seq_id, v_org_id, v_seq_name,
      '4-step climate-investor outreach. Day 0 impact-led (negative abatement cost + 9k t confirmed); Day 4 the-math bump; Day 9 defensibility/moat; Day 15 short breakup. Tissue excluded per deck convention.',
      'active', v_from_account_id, v_user_id, v_user_id
    );
    RAISE NOTICE 'Created sequence: %', v_seq_id;
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 1 -- Day 0 : impact-led opener
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM app.email_sequence_steps
                  WHERE sequence_id = v_seq_id AND step_order = 1) THEN
    INSERT INTO app.email_sequence_steps
      (id, sequence_id, step_order, day_offset, subject, body_plain, organization_id)
    VALUES (
      gen_random_uuid(), v_seq_id, 1, 0,
      'Displacing wood pulp at negative abatement cost -- 9,000 t already confirmed',
$body1$Hi {{contact.firstName}},

I'm Yun-Young Heo, CEO of Marinebio Group. We've developed FCC -- a paper filler that replaces wood pulp, and unlike most climate tech, it's adopted because it's cheaper, not because of a subsidy or a carbon price.

Why it may fit your thesis:

- Negative abatement cost. Every ton of FCC replaces about one ton of wood pulp. On our 9,000-ton confirmed volume alone, that's roughly 3,700-4,600 t CO2 and about 270,000 m3 of water avoided per year -- a net figure, after accounting for inputs and the CO2 the mineral formation locks in.

- It scales because it's cheaper. FCC sells at $250-350/t vs pulp at $600-800/t. Adoption is driven by mill economics, so the impact compounds without depending on policy.

- Not a pilot. The world's top global filler maker already produces FCC and has signaled a global roll-out after testing. 9,000 t is confirmed, about 10,000 t more expected, validated in both GCC and PCC.

We're raising a $3M Series A ($27M pre / $30M post, $30M-cap SAFE) to fund an independent US validation and convert the validated track into a ~$33.6M/yr royalty stream by Year 3.

Would you be open to a 20-minute call? I can share the deck and, under NDA, the partner names, contracts, and lab data.

Best,
Yun-Young Heo
CEO, Marinebio Group Inc. -- marinebiogroup.com$body1$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 1 (Day 0).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 2 -- Day 4 : the-math bump
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM app.email_sequence_steps
                  WHERE sequence_id = v_seq_id AND step_order = 2) THEN
    INSERT INTO app.email_sequence_steps
      (id, sequence_id, step_order, day_offset, subject, body_plain, organization_id)
    VALUES (
      gen_random_uuid(), v_seq_id, 2, 4,
      'Re: FCC -- the market math behind the impact',
$body2$Hi {{contact.firstName}},

Following up with the one number that frames the opportunity.

Paper consumes about 25-30 million tons of calcium-carbonate filler a year. At least 25% of that can be pulp-replaced by FCC today -- roughly 6-7.5 million tons, a royalty pool of $93-112M/yr at over 80% gross margin. Our validated Year-3 track (2.24M t) already sits inside this, and every ton licensed is more pulp displaced.

The point for a climate portfolio: the decarbonization scales with the business, not with policy. No subsidy, no carbon price required.

Happy to send the deck -- would a short call this week or next work?

Best,
Yun-Young Heo
CEO, Marinebio Group Inc. -- marinebiogroup.com$body2$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 2 (Day 4).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 3 -- Day 9 : defensibility / why-us
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM app.email_sequence_steps
                  WHERE sequence_id = v_seq_id AND step_order = 3) THEN
    INSERT INTO app.email_sequence_steps
      (id, sequence_id, step_order, day_offset, subject, body_plain, organization_id)
    VALUES (
      gen_random_uuid(), v_seq_id, 3, 9,
      'Re: FCC -- why the incumbents can''t copy this',
$body3$Hi {{contact.firstName}},

One more note, on defensibility -- the question most investors ask next.

The two global filler giants physically mix minerals into pulp. FCC grows the calcium carbonate in-situ, bonded onto the fiber, so a single bond delivers strength, bulk, smoothness, and stiffness at once -- something the incumbents tried and could not solve. It's protected by 5 granted patents (7 more pending) across 7 countries, and validated in both GCC and PCC.

That moat is why two of those giants are engaged under NDA rather than competing.

If decarbonization that pays for itself fits what you back, I'd value 20 minutes.

Best,
Yun-Young Heo
CEO, Marinebio Group Inc. -- marinebiogroup.com$body3$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 3 (Day 9).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Step 4 -- Day 15 : short breakup
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM app.email_sequence_steps
                  WHERE sequence_id = v_seq_id AND step_order = 4) THEN
    INSERT INTO app.email_sequence_steps
      (id, sequence_id, step_order, day_offset, subject, body_plain, organization_id)
    VALUES (
      gen_random_uuid(), v_seq_id, 4, 15,
      'Re: FCC -- should I close the loop?',
$body4$Hi {{contact.firstName}},

I don't want to crowd your inbox, so this is my last note for now.

If replacing wood pulp at negative abatement cost -- with 9,000 t already confirmed -- is worth a look, just reply and I'll send the deck. If the timing isn't right, no problem, and I'll reach out again down the road.

Best,
Yun-Young Heo
CEO, Marinebio Group Inc. -- marinebiogroup.com$body4$,
      v_org_id
    );
    RAISE NOTICE 'Inserted Step 4 (Day 15).';
  END IF;


  -- ---------------------------------------------------------------------------
  -- Bulk enroll: every climate-sector investor party with an email.
  -- ---------------------------------------------------------------------------
  WITH climate_parties AS (
    SELECT DISTINCT p.id, p.party_name, p.email
      FROM app.parties p
      JOIN app.investor_profile ip        ON ip.party_id = p.id
      JOIN app.investor_sector_focus isf   ON isf.investor_profile_id = ip.id
      JOIN app.sectors s                    ON s.id = isf.sector_id
     WHERE p.organization_id = v_org_id
       AND s.code = 'climate'
       AND p.deleted_at IS NULL
  )
  INSERT INTO app.email_sequence_enrollments (
    id, organization_id, sequence_id, party_id, contact_id, enrolled_by,
    enrolled_at, status, next_step_order, next_send_at, recipient_email,
    created_at, updated_at
  )
  SELECT
    gen_random_uuid(), v_org_id, v_seq_id, cp.id, NULL, v_user_id,
    NOW(), 'active', 1, NOW(), LOWER(cp.email), NOW(), NOW()
  FROM climate_parties cp
  WHERE cp.email IS NOT NULL
    AND cp.email <> ''
    AND NOT EXISTS (
      SELECT 1 FROM app.email_sequence_enrollments e2
       WHERE e2.sequence_id = v_seq_id
         AND e2.party_id    = cp.id
         AND LOWER(e2.recipient_email) = LOWER(cp.email)
         AND e2.status IN ('active','completed')
    );

  GET DIAGNOSTICS v_enrolled = ROW_COUNT;
  RAISE NOTICE 'Bulk enroll inserted % climate-investor rows.', v_enrolled;
END
$migration$;


-- =============================================================================
-- Verification (read-only).
-- =============================================================================

-- A) Sequence + step + enrolled counts (expect 4 steps).
SELECT
  s.id, s.name, s.status, s.from_account_id, s.created_by,
  (SELECT COUNT(*) FROM app.email_sequence_steps       WHERE sequence_id = s.id) AS step_count,
  (SELECT COUNT(*) FROM app.email_sequence_enrollments WHERE sequence_id = s.id) AS enrolled_count,
  s.created_at
FROM app.email_sequences s
WHERE s.name = 'Climate Investor Cold Outreach -- FCC';

-- B) Enrolled firm details.
SELECT p.party_name, e.recipient_email, e.status, e.next_step_order, e.next_send_at
FROM app.email_sequence_enrollments e
JOIN app.parties p         ON p.id = e.party_id
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
ORDER BY p.party_name;

-- C) Step bodies sanity-check.
SELECT step_order, day_offset, subject,
       LEFT(body_plain, 90) AS body_preview, LENGTH(body_plain) AS body_length
FROM app.email_sequence_steps
WHERE sequence_id = (
  SELECT id FROM app.email_sequences
  WHERE name = 'Climate Investor Cold Outreach -- FCC' LIMIT 1
)
ORDER BY step_order;

-- D) Coverage check -- climate investors WITHOUT an email (won't be enrolled; fix these).
SELECT p.party_name, p.email
FROM app.parties p
JOIN app.investor_profile ip      ON ip.party_id = p.id
JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
JOIN app.sectors s                 ON s.id = isf.sector_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND s.code = 'climate'
  AND p.deleted_at IS NULL
  AND (p.email IS NULL OR p.email = '')
ORDER BY p.party_name;
