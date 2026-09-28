-- ==========================================================================
-- repair_20260927b_delete_mail_before_2026.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   HARD delete every email in app.communications with occurred_at before
--   2026-01-01 00:00 UTC (2024 and 2025 mail, active and soft-deleted).
--   Run diag_20260927b_mail_before_2026.sql first and check the counts.
--
-- Steps
--   1  detach ai.drafts inbound_communication_id and sent_communication_id
--      (FK is NO ACTION - it would block the delete)
--   2  detach email_sequence_sends / consultations /
--      engagement_email_details / email_tracking                (set null)
--   3  delete attachment rows of the target mail
--   4  delete the target mail rows
--   5  verification grid (the only grid the editor shows)
--
-- Safety
--   Whole file = one transaction. Any failure = nothing changed.
--   Supabase Pro daily backup exists. Attachment FILES in Storage stay
--   (Storage API only). IMAP server untouched, no re-import (last_uid).
--   Idempotent - a second run deletes 0 rows.
-- ==========================================================================


-- 1) ai.drafts --------------------------------------------------------------
update ai.drafts d
   set inbound_communication_id = null
 where d.inbound_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

update ai.drafts d
   set sent_communication_id = null
 where d.sent_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

-- 2) app child tables -------------------------------------------------------
update app.email_sequence_sends s
   set communication_id = null
 where s.communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

update app.consultations x
   set source_communication_id = null
 where x.source_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

update app.engagement_email_details e
   set source_communication_id = null
 where e.source_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

update app.email_tracking k
   set communication_id = null
 where k.communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

-- 3) attachment rows --------------------------------------------------------
delete from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

-- 4) the mail rows ----------------------------------------------------------
delete from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2026-01-01 00:00:00+00';

-- 5) verification -----------------------------------------------------------
select 'email before 2026 (expect 0)' as item, count(*)::bigint as n
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2026-01-01 00:00:00+00'
union all
select 'email 2026 and later (kept)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2026-01-01 00:00:00+00'
union all
select 'orphan attachment rows (expect 0)', count(*)::bigint
  from app.attachments a
 where a.entity_type = 'communication'
   and not exists (select 1 from app.communications c where c.id = a.entity_id)
union all
select 'oldest remaining email ' || coalesce(min(c.occurred_at)::text, 'none'), count(*)::bigint
  from app.communications c
 where c.channel = 'email'
