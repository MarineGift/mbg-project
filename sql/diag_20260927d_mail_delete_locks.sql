-- ==========================================================================
-- diag_20260927d_mail_delete_locks.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- Purpose
--   Read-only. The batch delete also hit "Failed to fetch". Triggers on
--   app.communications are insert-only (repo checked), so the most likely
--   cause is the FIRST timed-out delete still running on the server and
--   holding row locks, making every later run wait.
--   Shows running sessions, who blocks whom, and whether the indexes from
--   fix_20260927c exist. Touches only catalog views - returns instantly.
-- ==========================================================================

select '1_session' as section,
       'pid=' || a.pid
         || '  state=' || coalesce(a.state, '-')
         || '  secs=' || coalesce(extract(epoch from now() - a.query_start)::int::text, '-')
         || '  wait=' || coalesce(a.wait_event_type || '/' || a.wait_event, '-')
         || '  blocked_by=' || coalesce(array_to_string(pg_blocking_pids(a.pid), ','), '')
         || '  q=' || left(regexp_replace(a.query, '\s+', ' ', 'g'), 90) as item
  from pg_stat_activity a
 where a.datname = current_database()
   and a.pid <> pg_backend_pid()
   and a.state is distinct from 'idle'
   and a.backend_type = 'client backend'
union all
select '2_index',
       i.indexname || '  on ' || i.schemaname || '.' || i.tablename
  from pg_indexes i
 where i.indexname in ('idx_ai_drafts_inbound_comm', 'idx_ai_drafts_sent_comm',
                       'idx_consultations_source_comm', 'idx_eed_source_comm',
                       'idx_ess_comm', 'idx_attachments_entity',
                       'idx_comm_channel_occurred')
union all
select '3_trigger',
       t.tgname || '  enabled=' || t.tgenabled::text
  from pg_trigger t
 where t.tgrelid = 'app.communications'::regclass
   and not t.tgisinternal
 order by 1, 2
