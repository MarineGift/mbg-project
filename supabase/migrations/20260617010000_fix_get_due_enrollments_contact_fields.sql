-- 20260617010000_fix_get_due_enrollments_contact_fields.sql
-- get_due_enrollments returned only step + enrollment columns, but
-- sequence-processor.ts (DueEnrollment) also needs:
--   contact_email, contact_given_name, contact_family_name,
--   party_name, step_body_html, step_template_id
-- Because contact_email was never selected, it arrived NULL and the processor
-- skipped every enrollment ("processed:1, sent:0, skipped:1").
--
-- This version resolves the contact for each enrollment:
--   - if e.contact_id is set, use that contact
--   - otherwise fall back to the party's primary contact (is_primary=true),
--     then to the first contact that has an email.
-- and joins app.parties for party_name. step_body_html is selected if the
-- column exists on a step (it is text/nullable); template_id likewise.
--
-- Due-selection logic (status=active AND next_send_at <= now()) is unchanged.

DROP FUNCTION IF EXISTS public.get_due_enrollments();

CREATE OR REPLACE FUNCTION public.get_due_enrollments()
 RETURNS TABLE(
   enrollment_id        uuid,
   organization_id      uuid,
   sequence_id          uuid,
   party_id             uuid,
   contact_id           uuid,
   step_id              uuid,
   step_order           integer,
   step_subject         text,
   step_body            text,
   step_body_html       text,
   step_template_id     uuid,
   contact_email        text,
   contact_given_name   text,
   contact_family_name  text,
   party_name           text,
   is_last_step         boolean
 )
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
    st.body_html                                                 AS step_body_html,
    st.template_id                                               AS step_template_id,
    ct.email                                                     AS contact_email,
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
  -- resolve the recipient contact for this enrollment:
  LEFT JOIN LATERAL (
    SELECT c.id, c.email, c.given_name, c.family_name
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,  -- exact enrollment contact first
      c.is_primary DESC NULLS LAST,           -- then the primary contact
      c.created_at ASC                        -- then the oldest contact
    LIMIT 1
  ) ct ON TRUE
  WHERE e.status        = 'active'::app.enrollment_status
    AND e.next_send_at <= now()
  ORDER BY e.next_send_at;
$function$;

-- Verify: contact_email should now be populated (not null) for MBG Mailing Test.
-- select enrollment_id, contact_email, party_name, step_subject
-- from public.get_due_enrollments();
