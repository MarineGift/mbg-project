-- ============================================================
-- 20260616190000_fix_get_sequence_with_steps_body_plain.sql
-- Fix get_sequence_with_steps so Edit works.
--
-- Bug (verified 2026-06-16): the function builds each step JSON with
--   'body_text', st.body_text
-- but app.email_sequence_steps has NO body_text column (it is
-- body_plain). The missing-column error makes get_sequence_with_steps
-- throw, so getSequenceForEdit() returns an error, the edit dialog
-- never opens, and the Edit button appears to "do nothing".
--
-- Fix: read st.body_plain and emit the JSON key as 'body_plain' (the
-- edit dialog expects steps[].body_plain). Same body_text->body_plain
-- cleanup already applied earlier to create_sequence / update_sequence;
-- this is the read-side function that was missed.
--
-- Signature, return type (jsonb), and SECURITY DEFINER are preserved
-- (CREATE OR REPLACE), so grants and the RPC binding are unaffected.
--
-- HOW TO APPLY (live): run in the Supabase SQL Editor. After it
-- succeeds, the Edit button opens the dialog pre-filled with each
-- step's subject and body.
-- ============================================================

create or replace function public.get_sequence_with_steps(p_sequence_id uuid)
returns jsonb
language plpgsql
security definer
as $fn$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'id',              s.id,
    'organization_id', s.organization_id,
    'name',            s.name,
    'description',     s.description,
    'status',          s.status,
    'created_at',      s.created_at,
    'steps', coalesce(
      (select jsonb_agg(
        jsonb_build_object(
          'id',         st.id,
          'step_order', st.step_order,
          'day_offset', st.day_offset,
          'subject',    st.subject,
          'body_plain', st.body_plain
        ) order by st.step_order
      ) from app.email_sequence_steps st
        where st.sequence_id = s.id),
      '[]'::jsonb
    )
  )
  into v_result
  from app.email_sequences s
  where s.id = p_sequence_id;

  return v_result;
end;
$fn$;
