-- =============================================================================
-- 20260627000200_pangaea_deal_and_meeting_v2.sql
-- =============================================================================
-- Fix for v1: explicit enum casts.
-- Part 1 (is_primary UPDATE) ran successfully in v1 -- skipped here.
-- This re-runs Deal + Meeting + Attendees with proper enum casts.
-- =============================================================================

DO $migration$
DECLARE
  v_org_id        uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_party_id      uuid := '97d63e5e-5e8d-4719-b170-588f1d184d99';  -- Pangaea
  v_contact_id    uuid := '7b954ce5-17bc-4282-b50e-9180660651d8';  -- Andrew
  v_pipeline_id   uuid := 'de80525d-5537-4971-ad8f-d2080a8e65b0';  -- Investors
  v_stage_id      uuid := 'be415dbe-f07a-4869-9989-254f27e25b0c';  -- First meeting
  v_user_id       uuid;
  v_deal_id       uuid;
  v_meeting_id    uuid;
  v_meeting_start timestamptz := '2026-07-08 16:30:00+00';  -- 9:30 PDT = 16:30 UTC

  -- Discovered enum type names (dynamically resolved)
  v_role_type     text;
  v_resp_type     text;
BEGIN
  -- Resolve user_id
  SELECT enrolled_by INTO v_user_id
    FROM app.email_sequence_enrollments
   WHERE organization_id = v_org_id AND enrolled_by IS NOT NULL
   ORDER BY enrolled_at DESC LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Could not resolve user_id'; END IF;

  -- Discover attendee enum type names (e.g. app.meeting_attendee_role)
  SELECT atttypid::regtype::text INTO v_role_type
    FROM pg_attribute
   WHERE attrelid = 'app.meeting_attendees'::regclass
     AND attname = 'role';

  SELECT atttypid::regtype::text INTO v_resp_type
    FROM pg_attribute
   WHERE attrelid = 'app.meeting_attendees'::regclass
     AND attname = 'response';

  RAISE NOTICE 'role enum type: %, response enum type: %', v_role_type, v_resp_type;


  -- ---------------------------------------------------------------------------
  -- Part 2: Deal
  -- ---------------------------------------------------------------------------
  SELECT id INTO v_deal_id
    FROM app.deals
   WHERE party_id = v_party_id
     AND pipeline_id = v_pipeline_id
     AND deleted_at IS NULL
   LIMIT 1;

  IF v_deal_id IS NOT NULL THEN
    RAISE NOTICE 'Deal exists: %', v_deal_id;
  ELSE
    v_deal_id := gen_random_uuid();
    INSERT INTO app.deals (
      id, organization_id, party_id, primary_contact_id,
      pipeline_id, current_stage_id,
      deal_name, description, status, priority,
      probability_pct, value_currency,
      expected_close_date,
      owner_user_id, created_by, updated_by,
      next_step, next_step_date,
      stage_entered_at, last_activity_at,
      created_at, updated_at, extra_data
    ) VALUES (
      v_deal_id, v_org_id, v_party_id, v_contact_id,
      v_pipeline_id, v_stage_id,
      'Pangaea Ventures — FCC Seed',
      'Vancouver-based Advanced Materials VC. Andrew Haughian (Partner) led inbound after sequence reply. IR deck sent 6/25; intro call scheduled 7/8 09:30 PDT.',
      'active', 'high',
      20, 'USD',
      '2026-10-31',
      v_user_id, v_user_id, v_user_id,
      '7/8 09:30 PDT intro call with Andrew Haughian',
      '2026-07-08',
      NOW(), NOW(), NOW(), NOW(), '{}'::jsonb
    );
    RAISE NOTICE 'Created Deal: %', v_deal_id;
  END IF;


  -- ---------------------------------------------------------------------------
  -- Part 3: Meeting (with explicit ::app.meeting_status cast)
  -- ---------------------------------------------------------------------------
  SELECT id INTO v_meeting_id
    FROM app.meetings
   WHERE party_id = v_party_id
     AND occurred_at = v_meeting_start
     AND deleted_at IS NULL
   LIMIT 1;

  IF v_meeting_id IS NOT NULL THEN
    RAISE NOTICE 'Meeting exists: %', v_meeting_id;
  ELSE
    v_meeting_id := gen_random_uuid();
    INSERT INTO app.meetings (
      id, organization_id, user_id, party_id,
      title, agenda,
      occurred_at, scheduled_at, duration_min,
      meeting_type, meeting_mode,
      status, location, meeting_url,
      action_items, follow_up_task_ids,
      stage_id,
      created_by, updated_by,
      created_at, updated_at
    ) VALUES (
      v_meeting_id, v_org_id, v_user_id, v_party_id,
      'Pangaea Ventures — Intro Call (Andrew Haughian)',
      'Investor intro call following IR deck send. Discussion of FCC paper filler technology, licensing model, market sizing, and seed round.',
      v_meeting_start, v_meeting_start, 30,
      'intro_call', 'video',
      'scheduled'::app.meeting_status,           -- <<< explicit cast
      NULL, NULL,
      '[]'::jsonb, ARRAY[]::uuid[],
      v_stage_id,
      v_user_id, v_user_id,
      NOW(), NOW()
    );
    RAISE NOTICE 'Created Meeting: %', v_meeting_id;
  END IF;


  -- ---------------------------------------------------------------------------
  -- Part 4: Attendees (dynamic EXECUTE with format() to handle unknown enum types)
  -- ---------------------------------------------------------------------------

  -- Andrew = external organizer
  EXECUTE format($f$
    INSERT INTO app.meeting_attendees (
      id, organization_id, meeting_id, contact_id, person_party_id,
      email, name, role, response, is_internal, user_id, created_at
    )
    SELECT gen_random_uuid(), %L::uuid, %L::uuid, %L::uuid, %L::uuid,
           %L, %L,
           %L::%s, %L::%s,
           false, NULL, NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM app.meeting_attendees
       WHERE meeting_id = %L::uuid
         AND LOWER(email) = LOWER(%L)
    )$f$,
    v_org_id, v_meeting_id, v_contact_id, v_party_id,
    'andrew@pangaeaventures.com', 'Andrew Haughian',
    'organizer', v_role_type,
    'accepted',  v_resp_type,
    v_meeting_id, 'andrew@pangaeaventures.com'
  );

  -- Yun-Young = internal required
  EXECUTE format($f$
    INSERT INTO app.meeting_attendees (
      id, organization_id, meeting_id, contact_id, person_party_id,
      email, name, role, response, is_internal, user_id, created_at
    )
    SELECT gen_random_uuid(), %L::uuid, %L::uuid, NULL, NULL,
           %L, %L,
           %L::%s, %L::%s,
           true, %L::uuid, NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM app.meeting_attendees
       WHERE meeting_id = %L::uuid
         AND LOWER(email) = LOWER(%L)
    )$f$,
    v_org_id, v_meeting_id,
    'yunyoung.heo@marinebiogroup.com', 'Yun-Young Heo',
    'required', v_role_type,
    'accepted', v_resp_type,
    v_user_id,
    v_meeting_id, 'yunyoung.heo@marinebiogroup.com'
  );

  RAISE NOTICE 'Attendees inserted.';
END
$migration$;


-- -----------------------------------------------------------------------------
-- Verification
-- -----------------------------------------------------------------------------
SELECT
  d.deal_name, d.status, d.priority, d.probability_pct,
  s.name AS stage_name, d.next_step, d.next_step_date
FROM app.deals d
JOIN app.stages s ON s.id = d.current_stage_id
WHERE d.party_id = '97d63e5e-5e8d-4719-b170-588f1d184d99'
  AND d.deleted_at IS NULL;

SELECT
  m.title, m.occurred_at, m.duration_min, m.status,
  m.meeting_type, m.meeting_mode,
  COUNT(a.id) AS attendees,
  STRING_AGG(a.name, ', ' ORDER BY a.is_internal) AS attendee_names
FROM app.meetings m
LEFT JOIN app.meeting_attendees a ON a.meeting_id = m.id
WHERE m.party_id = '97d63e5e-5e8d-4719-b170-588f1d184d99'
  AND m.deleted_at IS NULL
GROUP BY m.id, m.title, m.occurred_at, m.duration_min, m.status,
         m.meeting_type, m.meeting_mode;
