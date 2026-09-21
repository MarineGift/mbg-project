-- ============================================================
-- migration_ipo_todo_cron.sql   (optional, run AFTER migration_ipo_todo_calendar.sql)
-- !! Ctrl+A (select ALL) then Run !!
-- Daily 06:10 UTC re-sync so each new month's IPO items and the
-- "IPO plan" summary appear on /todo and /calendar without manual runs.
-- If CREATE EXTENSION fails: Supabase Dashboard > Database > Extensions > pg_cron > enable, then rerun.
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule('ipo-todo-sync', '10 6 * * *', $cron$SELECT app.ipo_sync_todo()$cron$);

SELECT jobid, jobname, schedule, command, active FROM cron.job WHERE jobname = 'ipo-todo-sync';
