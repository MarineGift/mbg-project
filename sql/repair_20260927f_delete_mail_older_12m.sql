-- ==========================================================================
-- repair_20260927f_delete_mail_older_12m.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   Keep only email from the last 12 months. HARD delete every email in
--   app.communications with occurred_at older than now() minus 12 months
--   (active and soft-deleted). now() is fixed per transaction, so every
--   statement in one run uses the same cutoff. Rolling - safe to rerun
--   any time later to trim again.
--
--   Same method that worked in repair_20260927e: user triggers off inside
--   this transaction only, up to 1000 rows per run, triggers back on.
--   RUN AGAIN until "remaining (run again if > 0)" = 0.
--
-- Side effects
--   No audit rows and no engagement recount for these deletes.
--   Attachment FILES in Storage stay. IMAP server untouched.
-- ==========================================================================

-- 1) detach references ------------------------------------------------------
update ai.drafts d
   set inbound_communication_id = null
 where d.inbound_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

update ai.drafts d
   set sent_communication_id = null
 where d.sent_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

update app.email_sequence_sends s
   set communication_id = null
 where s.communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

update app.consultations x
   set source_communication_id = null
 where x.source_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

update app.engagement_email_details e
   set source_communication_id = null
 where e.source_communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

update app.email_tracking k
   set communication_id = null
 where k.communication_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

-- 2) attachment rows --------------------------------------------------------
delete from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (select c.id from app.communications c where c.channel = 'email' and c.occurred_at < now() - interval '12 months');

-- 3) triggers off (this transaction only) -----------------------------------
alter table app.communications disable trigger user;

-- 4) one batch of mail rows -------------------------------------------------
delete from app.communications c
 where c.id in (
         select c2.id
           from app.communications c2
          where c2.channel = 'email'
            and c2.occurred_at < now() - interval '12 months'
          order by c2.occurred_at
          limit 1000);

-- 5) triggers back on -------------------------------------------------------
alter table app.communications enable trigger user;

-- 6) progress ---------------------------------------------------------------
select 'cutoff ' || (now() - interval '12 months')::text as item, null::bigint as n
union all
select 'remaining (run again if > 0)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at < now() - interval '12 months'
union all
select 'email last 12 months (kept)', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= now() - interval '12 months'
union all
select 'oldest remaining email ' || coalesce(min(c.occurred_at)::text, 'none'), count(*)::bigint
  from app.communications c
 where c.channel = 'email'
union all
select 'disabled triggers (expect 0)', count(*)::bigint
  from pg_trigger t
 where t.tgrelid = 'app.communications'::regclass
   and not t.tgisinternal
   and t.tgenabled = 'D'
