-- =====================================================================
-- migration_20260715001100_guard_min_gap_get_due_enrollments.sql
--
-- Second layer against duplicate sends. Apply AFTER
-- migration_20260715001000_fix_advance_enrollment_anchor.sql.
--
-- Why a second layer
--   001000 removes the KNOWN cause (next_send_at anchored to enrolled_at).
--   This file makes the outcome impossible regardless of cause. On
--   2026-07-14 the same class of bug was found twice in one day, both times
--   because a guard lived somewhere other than the choke point. This is the
--   choke point: nothing reaches the mail server that this function does not
--   return.
--
-- Two additions on top of migration_20260714235600 (the do-not-send guard).
-- Everything else is byte-for-byte the prior definition.
--
--   [G1] min-gap guard
--        Never return an enrollment whose party already received a
--        sequence-sourced outbound within the last 2 days. Keyed on
--        app.communications.external_data->>'source' = 'sequence', which the
--        worker already stamps (sequence-processor.ts sets source,
--        sequence_id, step_id, enrollment_id, step_order).
--
--        2 days, not more: every real cadence in the DB is 3 days or wider
--        (High Priority 0/3/7, Intel Inside 0/5, Seed and Climate 0/7/14/21),
--        so a 48h floor cannot touch an intended send. It only catches the
--        same-day / next-day bunching that actually happened.
--
--        Verified safe for the 2026-07-20 Seed send: the last Seed step went
--        out 07-13, a 7 day gap.
--
--   [G2] one enrollment per party per run
--        DISTINCT ON (e.party_id), earliest due first. Two enrollments for
--        the same party that come due in the SAME batch are invisible to G1
--        -- neither has sent yet, so neither sees the other in
--        communications. G2 returns only the older one. The loser is not
--        dropped: it stays active with next_send_at in the past, is picked
--        up on the next run, and G1 then holds it for 2 days.
--
--        No-op today -- verified 2026-07-14 that no party sits in more than
--        one active sequence -- so this changes nothing on 07-20. It is
--        insurance against re-enrollment and against a duplicated sequence
--        being pointed at an overlapping list.
--
-- Cost note
--   G1 is a correlated NOT EXISTS over app.communications per candidate row.
--   The candidate set is small (order 100). If it ever gets slow, index:
--     CREATE INDEX ON app.communications (party_id, occurred_at)
--       WHERE direction = 'outbound'
--   Left out for now -- do not add an index nobody has measured a need for.
--
-- NOTE: language sql, body deliberately contains NO semicolon -- the
-- Supabase SQL Editor splits on semicolons even inside dollar quotes. Run
-- this file as a single statement.
--
-- Rollback: re-run migration_20260714235600_guard_get_due_enrollments.sql.
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
