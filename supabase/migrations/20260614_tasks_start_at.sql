-- ============================================================
-- 20260614_tasks_start_at.sql
-- Add a planned START date to tasks. With the existing due_at (the END), a
-- task now has a date range, enabling duration analysis in reports/Gantt.
--   duration = due_at - start_at
-- Nullable + idempotent. Run in Supabase SQL Editor.
-- ============================================================

alter table app.tasks
  add column if not exists start_at timestamptz;

comment on column app.tasks.start_at is
  'Planned start. With due_at (the end) this forms a date range; duration = due_at - start_at. Used for reports/Gantt.';

-- refresh PostgREST schema cache so the new column is selectable immediately
notify pgrst, 'reload schema';
