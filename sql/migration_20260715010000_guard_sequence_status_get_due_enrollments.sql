-- =====================================================================
-- migration_20260715010000_guard_sequence_status_get_due_enrollments.sql
--
-- PART E-2 of the 2026-07-15 handoff. Apply AFTER
-- migration_20260715001100_guard_min_gap_get_due_enrollments.sql.
--
-- !! RUN THE PREVIEW FIRST. See the handoff, section "Preview". !!
--    If P3 returns any enrollment you still expect to send, STOP.
--
-- Problem (verified 2026-07-15, both sides)
--   Nothing on the send path reads app.email_sequences.status.
--     * public.get_due_enrollments() does not join app.email_sequences at
--       all. Its only status test is the ENROLLMENT status:
--           WHERE e.status = 'active'::app.enrollment_status
--     * src/lib/utils/sequence-processor.ts selects
--           "id, from_account_id, quiet_hours"
--       from app.email_sequences -- status is not in the projection.
--   So an archived, paused or draft sequence keeps sending. Pausing a
--   sequence in the UI does nothing to the mail. This was found while
--   stopping the Seed sequence (handoff A-7): archiving it did not stop
--   the 7/20 batch -- cancelling the 67 enrollments did.
--
--   Same class as the three bugs found on 2026-07-14/15: the guard lived
--   somewhere other than the choke point. This function is the choke
--   point -- nothing reaches the mail server that it does not return.
--
-- Fix
--   Inner-join app.email_sequences with status = 'active'. Everything else
--   is byte-for-byte migration_20260715001100.
--
-- WHAT THIS BLOCKS -- all four enum values enumerated, per convention.
--   app.email_sequence_status = draft | active | paused | archived
--   (confirmed from src/types/database.ts:6999, the generated types)
--
--     active   -> unaffected. Climate was created with an explicit
--                 'active' (20260713140000_climate_investor_sequence_create
--                 .sql:101), so the 7/20 send of 40 is untouched. The
--                 preview re-confirms this against the live DB rather than
--                 against this file.
--     paused   -> now actually stops sending. This is the point of the file.
--     archived -> now actually stops sending. No change in practice today:
--                 the only archived sequence with a history is Seed
--                 (fix_20260715004000), whose enrollments are already
--                 cancelled, so they never reach this predicate.
--     draft    -> never sends. A sequence built but not launched cannot
--                 leak mail through a stray enrollment.
--
--   ⚠ src/types/phase21b.ts:4 declares
--         SequenceStatus = 'active' | 'paused' | 'archived'
--     which is MISSING 'draft'. The TS union is wrong, not the DB. Left
--     alone here -- it has no runtime effect (the UI only ever writes
--     active/paused/archived) and this commit is sql/docs only. Logged in
--     the handoff backlog.
--
-- Semantics to know before you use it
--   * NOT a substitute for cancelling enrollments. A silenced enrollment
--     stays active with next_send_at in the past. Flip status back to
--     'active' and the whole backlog goes out on the next worker run.
--     G1 holds each party for 48h, but that is per party -- different
--     parties all fire at once. Same caveat as the A-7 Seed reversal.
--     For a permanent stop, cancel the enrollments (belt and braces).
--   * Not retroactive and does not write. It only filters what is returned.
--   * The enum cast is deliberate: a typo in the label fails loudly at
--     CREATE time. `status::text = 'active'` would silently match nothing
--     and block every send.
--
-- Companion: migration_20260715010100_v_enrollment_send_health_sequence_
-- status.sql. The health view header requires that any change to
-- get_due_enrollments lands in the SAME commit as the view. Apply both.
--
-- NOTE: language sql, body deliberately contains NO semicolon -- the
-- Supabase SQL Editor splits on semicolons even inside dollar quotes. Run
-- this file as a single statement.
--
-- Rollback: re-run migration_20260715001100_guard_min_gap_get_due_
-- enrollments.sql.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.get_due_enrollments()
 RETURNS TABLE(enrollment_id uuid, organization_id uuid, sequence_id uuid, party_id uuid, contact_id uuid, step_id uuid, step_order integer, step_subject text, step_body text, contact_email text, contact_given_name text, contact_family_name text, party_name text, is_last_step boolean)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT DISTINCT ON (e.party_id)
    e.id                                                         AS enrollment_id,
    e.organization_id,
    e.sequence_id,
    e.party_id,
    COALESCE(e.contact_id, ct.id)                                AS contact_id,
    st.id                                                        AS step_id,
    st.step_order                                                AS step_order,
    st.subject                                                   AS step_subject,
    st.body_plain                                                AS step_body,
    -- Send precedence: pinned recipient_email wins (set at enroll time),
    -- then the resolved contact email, finally the party HQ email.
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email)   AS contact_email,
    ct.given_name                                                AS contact_given_name,
    ct.family_name                                               AS contact_family_name,
    p.party_name                                                 AS party_name,
    (st.step_order = (
      SELECT MAX(s2.step_order)
      FROM app.email_sequence_steps s2
      WHERE s2.sequence_id = e.sequence_id
    ))                                                           AS is_last_step
  FROM app.email_sequence_enrollments e
  -- [G3] sequence-status guard: a paused / archived / draft sequence sends
  -- nothing. sequence_id is the PK of app.email_sequences, so this inner
  -- join is strictly 1:1 and cannot fan out rows.
  JOIN app.email_sequences s
    ON s.id     = e.sequence_id
   AND s.status = 'active'::app.email_sequence_status
  JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
   AND st.step_order  = e.next_step_order
  JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN LATERAL (
    SELECT c.id, c.email, c.given_name, c.family_name
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
  WHERE e.status        = 'active'::app.enrollment_status
    AND e.next_send_at <= now()
    -- do-not-send guard, party level (form submitted / replied / declined).
    AND NOT EXISTS (
      SELECT 1
      FROM app.v_email_do_not_send d
      WHERE d.party_id = e.party_id
    )
    -- do-not-send guard, address level, on the RESOLVED address.
    AND NOT EXISTS (
      SELECT 1
      FROM app.v_email_do_not_send d
      WHERE d.email_lower = lower(COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email))
    )
    -- [G1] min-gap guard: no second sequence mail to the same party inside 48h.
    AND NOT EXISTS (
      SELECT 1
      FROM app.communications c2
      WHERE c2.party_id                    = e.party_id
        AND c2.channel::text               = 'email'
        AND c2.direction::text             = 'outbound'
        AND c2.external_data->>'source'    = 'sequence'
        AND c2.occurred_at                 > now() - INTERVAL '2 days'
    )
  -- [G2] at most one enrollment per party per run, earliest due first.
  ORDER BY e.party_id, e.next_send_at ASC, e.id
$function$
