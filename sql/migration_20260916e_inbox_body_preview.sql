-- migration_20260916e_inbox_body_preview.sql
-- Inbox list read the FULL body_plain of up to 1000 mails (large TOAST reads) only to show
-- a 120-char preview. This PostgREST computed field returns just the first 500 chars;
-- Postgres inlines it to left(body_plain, 500), which reads only the start of the value.
-- The list query selects it as  body_plain:body_preview  (same shape for the app).
-- RLS unchanged (the function runs as the caller, table policies still apply). Idempotent.
create or replace function app.body_preview(app.communications)
returns text
language sql
stable
as $fn$
  select left($1.body_plain, 500)
$fn$;

grant execute on function app.body_preview(app.communications) to authenticated, service_role;

notify pgrst, 'reload schema';

select 'app.body_preview ready' as status;