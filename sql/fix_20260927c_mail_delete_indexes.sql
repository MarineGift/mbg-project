-- ==========================================================================
-- fix_20260927c_mail_delete_indexes.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   The previous delete file hit "Failed to fetch (api.supabase.com)" -
--   the dashboard request timed out. Likely cause: every deleted mail row
--   makes Postgres check each referencing FK column, and those columns
--   have no index, so each check is a full table scan.
--   This file adds the missing indexes (idempotent, additive only) and
--   reports whether the earlier delete committed anyway.
--
--   If this file itself hangs, the earlier delete is still running and
--   holding locks - wait a few minutes and run it again.
-- ==========================================================================

create index if not exists idx_ai_drafts_inbound_comm
  on ai.drafts (inbound_communication_id);

create index if not exists idx_ai_drafts_sent_comm
  on ai.drafts (sent_communication_id);

create index if not exists idx_consultations_source_comm
  on app.consultations (source_communication_id);

create index if not exists idx_eed_source_comm
  on app.engagement_email_details (source_communication_id);

create index if not exists idx_ess_comm
  on app.email_sequence_sends (communication_id);

create index if not exists idx_attachments_entity
  on app.attachments (entity_type, entity_id);

create index if not exists idx_comm_channel_occurred
  on app.communications (channel, occurred_at);

-- status grid ---------------------------------------------------------------
select 'email before 2026 still present' as item, count(*)::bigint as n
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2026-01-01 00:00:00+00'
union all
select 'email 2026 and later', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2026-01-01 00:00:00+00'
union all
select 'trigger on communications  ' || t.tgname, null::bigint
  from pg_trigger t
 where t.tgrelid = 'app.communications'::regclass
   and not t.tgisinternal
