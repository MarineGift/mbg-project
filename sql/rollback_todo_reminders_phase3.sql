-- ============================================================
-- rollback_todo_reminders_phase3.sql (2026-07-06)
-- ROLLBACK of the duplicate task-reminder DB objects.
--
-- Reason: a complete reminder system already existed before this work —
--   src/lib/reminders/process.ts + src/workers/reminder-worker.ts ("todo_v2
--   Phase 1"), already wired into all-workers.ts and running in production.
--   It covers todo_items + deal tasks + deal milestones with a per-assignee
--   daily digest, idempotent via app.reminder_log. The Phase 3 objects below
--   duplicated a subset of that, so they are removed.
--
-- Drops ONLY what Phase 3 added:
--   * function app.get_due_task_reminders(date)
--   * function app.mark_task_reminders_sent(uuid[], date)
--   * index   app.ix_todo_items_due_reminder
--   * column  app.todo_items.reminded_at
--
-- Verified safe: the pre-existing reminder system (process.ts / reminder-worker
-- in src/workers) references NONE of these — it uses app.reminder_log and the
-- todo_items columns that remain. Only the deleted app-side file
-- (src/lib/tasks/reminder-worker.ts) used these, and it is removed in the same
-- change. All other todo_items columns, the recurrence trigger, and
-- todo_status_options are untouched.
--
-- Idempotent (IF EXISTS everywhere). Editor-safe.
-- ============================================================

-- 1) RPCs (the reminder route/worker that called these are being deleted)
drop function if exists app.get_due_task_reminders(date);
drop function if exists app.mark_task_reminders_sent(uuid[], date);

-- 2) Index that only supported the Phase 3 reminder query
drop index if exists app.ix_todo_items_due_reminder;

-- 3) The once-per-day dedupe column (existing system uses app.reminder_log)
alter table app.todo_items drop column if exists reminded_at;

notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- (a) both functions gone
select count(*) as phase3_functions_left
from pg_proc
where proname in ('get_due_task_reminders', 'mark_task_reminders_sent');

-- (b) column gone
select count(*) as reminded_at_left
from information_schema.columns
where table_schema = 'app' and table_name = 'todo_items' and column_name = 'reminded_at';

-- (c) sanity: the recurrence column added in Phase 2 is STILL there (we didn't
--     over-drop). Should return 1.
select count(*) as recurrence_still_present
from information_schema.columns
where table_schema = 'app' and table_name = 'todo_items' and column_name = 'recurrence';
