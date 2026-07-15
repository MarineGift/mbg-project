-- =====================================================================
-- migration_20260714235500_v_enrollment_send_health.sql
--
-- Purpose: a STANDING preflight surface for every sequence enrollment,
--          replacing the per-sequence ad-hoc preflight SQL that has been
--          rewritten (and gotten wrong) every send.
--
-- Why this exists
--   The 2026-07-14 preflight judged "bad email" from app.contacts.email
--   alone. The real send address is resolved by public.get_due_enrollments()
--   as a THREE-level fallback:
--       COALESCE(NULLIF(recipient_email, empty), contact email, party email)
--   so the preflight both (a) missed enrollments that DO send via
--   recipient_email or parties.email, and (b) flagged ones that were fine.
--   The numbers it produced ("bad_email 1", "clean 67/67") were unsound.
--
-- This view REPLICATES that resolution exactly, so preflight and the worker
-- can never drift apart again. If get_due_enrollments changes, change this
-- view in the same commit.
--
-- Usage (single SELECT, no per-sequence rewriting):
--   SELECT * FROM app.v_enrollment_send_health
--   WHERE enrollment_status = active AND send_status <> ok
--
-- send_status vocabulary:
--   ok                 -> will send
--   no_email           -> all three fallbacks NULL, worker marks it skipped
--   malformed_email    -> resolved address fails a basic shape check
--   no_matching_step   -> no step row at next_step_order, silently never due
--   do_not_send_party  -> app.v_email_do_not_send has a row for this party
--   do_not_send_email  -> app.v_email_do_not_send has a row for this address
--   inactive           -> not active (informational)
--
-- Read-only view. Safe to re-run (CREATE OR REPLACE).
-- =====================================================================

CREATE OR REPLACE VIEW app.v_enrollment_send_health AS
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.organization_id,
    e.sequence_id,
    s.name                                                     AS sequence_name,
    e.party_id,
    p.party_name,
    e.status::text                                             AS enrollment_status,
    e.next_step_order,
    e.next_send_at,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS resolved_email,
    CASE
      WHEN NULLIF(e.recipient_email, '') IS NOT NULL THEN 'enrollment.recipient_email'
      WHEN ct.email IS NOT NULL                      THEN 'contacts.email'
      WHEN p.email IS NOT NULL                       THEN 'parties.email'
      ELSE 'none'
    END                                                        AS email_source,
    EXISTS (
      SELECT 1
      FROM app.email_sequence_steps st
      WHERE st.sequence_id = e.sequence_id
        AND st.step_order  = e.next_step_order
    )                                                          AS has_step
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequences s ON s.id = e.sequence_id
  JOIN app.parties p         ON p.id = e.party_id
  -- identical LATERAL to get_due_enrollments: same filters, same ORDER BY.
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
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
)
SELECT
  r.enrollment_id,
  r.organization_id,
  r.sequence_id,
  r.sequence_name,
  r.party_id,
  r.party_name,
  r.enrollment_status,
  r.next_step_order,
  r.next_send_at,
  r.resolved_email,
  r.email_source,
  CASE
    WHEN r.enrollment_status <> 'active' THEN 'inactive'
    WHEN NOT r.has_step                  THEN 'no_matching_step'
    WHEN r.resolved_email IS NULL        THEN 'no_email'
    WHEN r.resolved_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
                                         THEN 'malformed_email'
    WHEN EXISTS (
      SELECT 1 FROM app.v_email_do_not_send d
      WHERE d.party_id = r.party_id
    )                                    THEN 'do_not_send_party'
    WHEN EXISTS (
      SELECT 1 FROM app.v_email_do_not_send d
      WHERE d.email_lower = lower(r.resolved_email)
    )                                    THEN 'do_not_send_email'
    ELSE 'ok'
  END AS send_status
FROM resolved r;
