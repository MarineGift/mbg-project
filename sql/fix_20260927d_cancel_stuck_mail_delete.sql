-- ==========================================================================
-- fix_20260927d_cancel_stuck_mail_delete.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   Stops every still-running session (older than 30 seconds) whose query
--   touches app.communications, app.attachments or ai.drafts - the earlier
--   timed-out delete runs. A stopped delete rolls back completely, so no
--   data is half-deleted. Normal app traffic finishes in well under 30 s.
--   Returns one row per stopped session (terminated = true).
-- ==========================================================================

select a.pid,
       extract(epoch from now() - a.query_start)::int as secs,
       left(regexp_replace(a.query, '\s+', ' ', 'g'), 90) as q,
       pg_terminate_backend(a.pid) as terminated
  from pg_stat_activity a
 where a.datname = current_database()
   and a.pid <> pg_backend_pid()
   and a.backend_type = 'client backend'
   and a.state is distinct from 'idle'
   and a.query_start < now() - interval '30 seconds'
   and (a.query ilike '%app.communications%'
        or a.query ilike '%app.attachments%'
        or a.query ilike '%ai.drafts%')
