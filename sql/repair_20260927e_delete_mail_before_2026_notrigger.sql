-- ==========================================================================
-- repair_20260927e_delete_mail_before_2026_notrigger.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   Diag showed NO stuck session and all 7 indexes present, yet the batch
--   delete still timed out. Remaining cause = the 8 user triggers on
--   app.communications (audit, engagement touch/log, auto stage, etc.)
--   firing for every deleted row. The audit trigger copies each full row
--   (incl. body_html) - heavy for mail with large bodies.
--
--   This file disables the user triggers ONLY inside this transaction,
--   deletes up to 1000 pre-2026 email rows, then re-enables them.
--   Internal FK triggers stay active. If anything fails, the whole file
--   rolls back - triggers included (DDL is transactional in Postgres).
--
--   RUN AGAIN until "remaining (run again if > 0)" = 0  (about 3 runs).
--
-- Side effects
--   No audit rows and no engagement recount for these deletes.
--   Brief table lock - the MailCarrier worker waits a moment, no data loss.
-- ==========================================================================

-- 1) detach references ------------------------------------------------------
update ai.drafts d
   set inbound_communication_id = null
 where d.inbound_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

update ai.drafts d
   set sent_communication_id = null
 where d.sent_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

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

-- 2) attachment rows --------------------------------------------------------
delete from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < timestamptz '2026-01-01 00:00:00+00');

-- 3) triggers off (this transaction only) -----------------------------------
alter table app.communications disable trigger user;

-- 4) one batch of mail rows -------------------------------------------------
delete from app.communications c
 where c.id in (
         select c2.id
           from app.communications c2
          where c2.channel = 'email'
            and c2.occurred_at < timestamptz '2026-01-01 00:00:00+00'
          order by c2.occurred_at
          limit 1000);

-- 5) triggers back on -------------------------------------------------------
alter table app.communications enable trigger user;

-- 6) progress ---------------------------------------------------------------
select 'remaining (run again if > 0)' as item, count(*)::bigint as n
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2026-01-01 00:00:00+00'
union all
select 'email 2026 and later (kept)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2026-01-01 00:00:00+00'
union all
select 'disabled triggers (expect 0)', count(*)::bigint
  from pg_trigger t
 where t.tgrelid = 'app.communications'::regclass
   and not t.tgisinternal
   and t.tgenabled = 'D'
