-- ==========================================================================
-- repair_20260927_delete_mail_before_2024.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   HARD delete every email in app.communications with occurred_at before
--   2024-01-01 00:00 UTC (active and soft-deleted rows alike).
--   Run diag_20260927_mail_before_2024.sql first and check the counts.
--
-- Steps
--   1  detach email_sequence_sends.communication_id         (set null)
--   2  detach consultations.source_communication_id         (set null)
--   3  detach engagement_email_details.source_communication_id (set null)
--   4  detach email_tracking.communication_id               (set null)
--   5  delete attachment rows of the target mail
--   6  delete the target mail rows
--   7  verification grid (the only grid the editor shows)
--
-- Safety
--   Whole file = one transaction. If any foreign key still blocks the
--   delete, nothing is changed. Supabase Pro daily backup exists.
--   Attachment FILES in Storage are not removed by SQL (Storage API only).
--   IMAP server mail is untouched. MailCarrier resumes from last_uid,
--   so deleted old mail is not re-imported.
--   Idempotent - a second run deletes 0 rows.
-- ==========================================================================


-- 1) email_sequence_sends ---------------------------------------------------
update app.email_sequence_sends s
   set communication_id = null
 where s.communication_id in (
         select c.id from app.communications c
          where c.channel = 'email'
            and c.occurred_at < timestamptz '2024-01-01 00:00:00+00');

-- 2) consultations ----------------------------------------------------------
update app.consultations x
   set source_communication_id = null
 where x.source_communication_id in (
         select c.id from app.communications c
          where c.channel = 'email'
            and c.occurred_at < timestamptz '2024-01-01 00:00:00+00');

-- 3) engagement_email_details -----------------------------------------------
update app.engagement_email_details e
   set source_communication_id = null
 where e.source_communication_id in (
         select c.id from app.communications c
          where c.channel = 'email'
            and c.occurred_at < timestamptz '2024-01-01 00:00:00+00');

-- 4) email_tracking ---------------------------------------------------------
update app.email_tracking k
   set communication_id = null
 where k.communication_id in (
         select c.id from app.communications c
          where c.channel = 'email'
            and c.occurred_at < timestamptz '2024-01-01 00:00:00+00');

-- 5) attachment rows --------------------------------------------------------
delete from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (
         select c.id from app.communications c
          where c.channel = 'email'
            and c.occurred_at < timestamptz '2024-01-01 00:00:00+00');

-- 6) the mail rows ----------------------------------------------------------
delete from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2024-01-01 00:00:00+00';

-- 7) verification -----------------------------------------------------------
select 'email before 2024 (expect 0)' as item, count(*)::bigint as n
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2024-01-01 00:00:00+00'
union all
select 'email 2024 and later (kept)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2024-01-01 00:00:00+00'
union all
select 'orphan attachment rows (expect 0)', count(*)::bigint
  from app.attachments a
 where a.entity_type = 'communication'
   and not exists (select 1 from app.communications c where c.id = a.entity_id)
union all
select 'oldest remaining email ' || coalesce(min(c.occurred_at)::text, 'none'), count(*)::bigint
  from app.communications c
 where c.channel = 'email'
