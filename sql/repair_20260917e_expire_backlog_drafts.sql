-- repair_20260917e_expire_backlog_drafts.sql
-- The 2026-09-16 outage catch-up generated AI drafts for mails that are weeks/months old
-- (266 of 279 drafts created that day). Mark those as expired, exactly like
-- draft-expiry-worker does (status='expired', expired_handled=true). Drafts are kept, not deleted.
-- Scope: pending_review drafts created on/after 2026-09-16 00:00 UTC whose source mail
-- is older than 14 days. Recent-mail drafts and drafts without a source mail are untouched.
with target as (
  select d.id
    from ai.drafts d
    join app.communications c on c.id = d.inbound_communication_id
   where d.status = 'pending_review'
     and d.created_at >= timestamptz '2026-09-16 00:00:00+00'
     and c.occurred_at < now() - interval '14 days'
),
upd as (
  update ai.drafts d
     set status = 'expired',
         expired_handled = true,
         review_notes = coalesce(d.review_notes || E'\n', '')
                        || '2026-09-16 bulk-expired: backlog draft for mail older than 14 days (outage catch-up)',
         updated_at = now()
    from target t
   where d.id = t.id
  returning d.id
)
select count(*) as drafts_expired from upd;