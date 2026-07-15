-- =====================================================================
-- migration_20260714235600_guard_get_due_enrollments.sql
--
-- !! THE CORE FIX OF THIS SESSION. Apply BEFORE the 7/20 Seed send. !!
--
-- Problem
--   public.get_due_enrollments() had NO do-not-send guard. Its WHERE was
--   only:  status = active AND next_send_at <= now()
--   Verified 2026-07-14:
--     pg_get_functiondef(oid) ILIKE the view name -> returned false
--     -> false
--   The sequence worker (src/lib/utils/sequence-processor.ts) sends whatever
--   this function returns, and sendOutboundEmail only enforces
--   app.email_blocklist. So app.v_email_do_not_send -- which is what records
--   form submissions, replies, rejections, unsubscribes and hard bounces --
--   was NOT applied to the sequence path at all. The 2026-07-14 PM handoff
--   asserted the opposite. That assertion was wrong.
--
--   Net effect: the 7/20 Seed send (67 active enrollments) would have gone
--   out unfiltered, including to firms that already submitted a form or
--   already replied/declined.
--
-- Fix
--   Add two NOT EXISTS guards against app.v_email_do_not_send, keyed the same
--   way the view is: by party_id AND by the RESOLVED send address. Everything
--   else in the function is byte-for-byte the prior definition.
--
-- Guard semantics (deliberate, note for review)
--   * party-level block is BROAD: any do-not-send row carrying a party_id
--     stops every enrollment for that party, not just the matching address.
--     For cold outreach this is the intent -- once a firm has submitted a
--     form or answered, no contact there should keep receiving the cold
--     sequence. It matches what bulk-mail.ts now does, so the two paths agree.
--   * resend_later rows leave the view once resend_not_before <= CURRENT_DATE,
--     so a cooldown auto-expires and the enrollment resumes. No manual undo.
--   * a NULL resolved address matches nothing and passes the guard. The
--     worker then marks it skipped, as before.
--
-- NOTE: the body deliberately contains NO semicolon. The Supabase SQL
-- Editor splits on semicolons even inside dollar quotes, which would
-- truncate the function. Run this file as a single statement.
--
-- Rollback: re-run the prior definition (drop the two NOT EXISTS blocks).
-- =====================================================================

CREATE OR REPLACE FUNCTION public.get_due_enrollments()
 RETURNS TABLE(enrollment_id uuid, organization_id uuid, sequence_id uuid, party_id uuid, contact_id uuid, step_id uuid, step_order integer, step_subject text, step_body text, contact_email text, contact_given_name text, contact_family_name text, party_name text, is_last_step boolean)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT
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
$function$
