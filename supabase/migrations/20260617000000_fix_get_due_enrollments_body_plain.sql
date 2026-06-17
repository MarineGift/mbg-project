-- 20260617000000_fix_get_due_enrollments_body_plain.sql
-- Fix public.get_due_enrollments(): the sequence-processor send trigger.
--
-- Two problems in the live function:
--   1) it selects st.body_text, but the real column is st.body_plain
--      -> "column st.body_text does not exist" -> processor sends 0, silently.
--   2) it aliases the body column as step_body_text, but sequence-processor.ts
--      reads e.step_body. So even after the column fix, the body would arrive
--      empty. Rename the alias (and the RETURNS TABLE column) to step_body.
--
-- Everything else (LANGUAGE sql, SECURITY DEFINER, due-selection logic) is
-- preserved exactly.

CREATE OR REPLACE FUNCTION public.get_due_enrollments()
 RETURNS TABLE(
   enrollment_id    uuid,
   organization_id  uuid,
   sequence_id      uuid,
   party_id         uuid,
   contact_id       uuid,
   enrolled_by      uuid,
   enrolled_at      timestamp with time zone,
   next_step_order  integer,
   step_id          uuid,
   step_day_offset  integer,
   step_subject     text,
   step_body        text,
   is_last_step     boolean
 )
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT
    e.id                                                         AS enrollment_id,
    e.organization_id,
    e.sequence_id,
    e.party_id,
    e.contact_id,
    e.enrolled_by,
    e.enrolled_at,
    e.next_step_order,
    st.id                                                        AS step_id,
    st.day_offset                                                AS step_day_offset,
    st.subject                                                   AS step_subject,
    st.body_plain                                                AS step_body,
    (st.step_order = (
      SELECT MAX(s2.step_order)
      FROM app.email_sequence_steps s2
      WHERE s2.sequence_id = e.sequence_id
    ))                                                           AS is_last_step
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id   = e.sequence_id
   AND st.step_order    = e.next_step_order
  WHERE e.status        = 'active'::app.enrollment_status
    AND e.next_send_at <= now()
  ORDER BY e.next_send_at;
$function$;

-- Verify: should now run without error and return the due MBG Mailing Test row.
-- select * from public.get_due_enrollments();
