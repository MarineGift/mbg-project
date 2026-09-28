-- ==========================================================================
-- repair_20260927c_delete_mail_before_2026_batch.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   Batch version of the pre-2026 email delete. Each run deletes at most
--   1000 of the oldest email rows before 2026-01-01 UTC, after detaching
--   their references. RUN AGAIN until "remaining (run again if > 0)" = 0.
--   Run fix_20260927c_mail_delete_indexes.sql first.
--
-- Safety
--   Each run = one transaction. Idempotent. Storage files stay.
-- ==========================================================================

-- 1) detach references (fast with the new indexes, 0 rows after first run)
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

-- 3) one batch of mail rows -------------------------------------------------
delete from app.communications c
 where c.id in (
         select c2.id
           from app.communications c2
          where c2.channel = 'email'
            and c2.occurred_at < timestamptz '2026-01-01 00:00:00+00'
          order by c2.occurred_at
          limit 1000);

-- 4) progress ---------------------------------------------------------------
select 'remaining (run again if > 0)' as item, count(*)::bigint as n
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < timestamptz '2026-01-01 00:00:00+00'
union all
select 'email 2026 and later (kept)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2026-01-01 00:00:00+00'
