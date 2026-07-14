-- migration_20260714120000_email_send_outcomes_page_access.sql
-- Purpose: guarantee the /mailing/outcomes page (authenticated role, RLS on)
-- can SELECT and INSERT app.email_send_outcomes. Additive and idempotent.
-- The MailCarrier worker uses service_role and bypasses RLS, so it is
-- unaffected either way.
--
-- Run in Supabase SQL Editor. Statements are self-contained (no do-blocks).

alter table app.email_send_outcomes enable row level security;

drop policy if exists pol_email_send_outcomes_select_org on app.email_send_outcomes;

create policy pol_email_send_outcomes_select_org
  on app.email_send_outcomes
  for select
  using (organization_id = app.current_organization_id());

drop policy if exists pol_email_send_outcomes_insert_org on app.email_send_outcomes;

create policy pol_email_send_outcomes_insert_org
  on app.email_send_outcomes
  for insert
  with check (organization_id = app.current_organization_id());

grant select, insert on app.email_send_outcomes to authenticated;

-- ---------------------------------------------------------------------------
-- VERIFY 1: column check. The page + worker code expects EXACTLY these names:
--   id, organization_id, party_id, recipient_email, outcome, reason,
--   next_action, resend_not_before, source, evidence_ref, created_at
-- If any name differs in the output below, adjust the TS files (grep the
-- differing name in src/lib/actions/email-outcomes.ts,
-- src/lib/email/outcome-recorder.ts) before deploying.
-- ---------------------------------------------------------------------------

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app'
  and table_name = 'email_send_outcomes'
order by ordinal_position;

-- VERIFY 2: the 5 rows recorded on 2026-07-14 must be visible to the page.

select recipient_email, outcome, next_action, resend_not_before, created_at
from app.email_send_outcomes
order by created_at desc
limit 20;
