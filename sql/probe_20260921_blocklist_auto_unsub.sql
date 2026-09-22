-- ============================================================
-- Ctrl+A (SELECT ALL) then Run
-- probe_20260921_blocklist_auto_unsub.sql  (READ ONLY)
-- Lists active do-not-send rows created automatically by the inbound
-- unsubscribe detector, newest first, for a manual false-positive review.
-- ============================================================
select b.pattern,
       b.kind,
       b.reason,
       b.notes,
       b.created_at,
       (select count(*) from app.contacts c
         where lower(c.email) = b.pattern and c.deleted_at is null) as contact_rows
  from app.email_blocklist b
 where b.is_active = true
   and b.reason = 'unsubscribe'
   and b.notes like 'auto:%'
 order by b.created_at desc
