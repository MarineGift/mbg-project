-- ============================================================
-- 20260616150000_fix_sequence_step_columns.sql
-- Fix create_sequence / update_sequence so they write to the real
-- app.email_sequence_steps schema.
--
-- Bugs in the live functions (verified 2026-06-16):
--   1) INSERT targeted column "body_text" -> table column is "body_plain".
--      (This is the error seen on Create Sequence.)
--   2) Read step->>'body_text' from the JSON -> the app sends key
--      "body_plain", so even after (1) the body would be empty.
--   3) Did NOT set organization_id, which is NOT NULL on the table.
--      create_sequence has p_organization_id; update_sequence derives
--      it from the parent sequence row.
--
-- Signatures are preserved (CREATE OR REPLACE), so existing grants and
-- the PostgREST RPC bindings are unaffected. SECURITY DEFINER kept.
--
-- HOW TO APPLY (live): run this in the Supabase SQL Editor.
-- After it succeeds, re-enter the sequence and click Create Sequence.
-- ============================================================

-- ---- create_sequence ----
create or replace function public.create_sequence(
  p_organization_id uuid,
  p_name            text,
  p_description     text,
  p_steps           jsonb
)
returns uuid
language plpgsql
security definer
as $fn$
declare
  v_seq_id uuid;
begin
  insert into app.email_sequences (organization_id, name, description, status)
  values (p_organization_id, p_name, nullif(p_description, ''),
          'active'::app.email_sequence_status)
  returning id into v_seq_id;

  if jsonb_array_length(p_steps) > 0 then
    insert into app.email_sequence_steps
      (sequence_id, organization_id, step_order, day_offset, subject, body_plain)
    select
      v_seq_id,
      p_organization_id,
      (step->>'step_order')::int,
      (step->>'day_offset')::int,
      step->>'subject',
      step->>'body_plain'
    from jsonb_array_elements(p_steps) step;
  end if;

  return v_seq_id;
end;
$fn$;

-- ---- update_sequence ----
create or replace function public.update_sequence(
  p_sequence_id uuid,
  p_name        text,
  p_description text,
  p_steps       jsonb
)
returns void
language plpgsql
security definer
as $fn$
declare
  v_org uuid;
begin
  update app.email_sequences
  set name        = p_name,
      description = nullif(p_description, ''),
      updated_at  = now()
  where id = p_sequence_id
  returning organization_id into v_org;

  delete from app.email_sequence_steps where sequence_id = p_sequence_id;

  if jsonb_array_length(p_steps) > 0 then
    insert into app.email_sequence_steps
      (sequence_id, organization_id, step_order, day_offset, subject, body_plain)
    select
      p_sequence_id,
      v_org,
      (step->>'step_order')::int,
      (step->>'day_offset')::int,
      step->>'subject',
      step->>'body_plain'
    from jsonb_array_elements(p_steps) step;
  end if;
end;
$fn$;
