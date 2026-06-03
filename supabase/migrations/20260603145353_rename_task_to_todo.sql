-- mbg_rename_task_to_todo.sql
-- Rename the standalone To-Do engine tables from task_* to todo_* (app schema).
-- KEEP app.tasks (Deal -> Checklist -> Task) and app.deal_checklists UNTOUCHED.
-- FKs, PKs, RLS policies and indexes follow the table automatically on RENAME;
-- the optional cleanup block also renames their *names* so nothing on the six
-- renamed tables keeps the old "task" prefix. app.tasks keeps its task_ names.
-- Run in Supabase SQL Editor (postgres role). Atomic: all-or-nothing.

begin;

-- 1) Core table renames (6). FK / PK / RLS / index objects follow automatically.
alter table app.task_boards          rename to todo_boards;
alter table app.task_groups          rename to todo_groups;
alter table app.task_items           rename to todo_items;
alter table app.task_status_options  rename to todo_status_options;
alter table app.task_updates         rename to todo_updates;
alter table app.task_dependencies    rename to todo_dependencies;

-- 2) OPTIONAL cosmetic cleanup: rename indexes / constraints / policies that still
--    carry the "task" token, but ONLY on the six renamed tables (app.tasks excluded
--    by the table-name filter). Functionality is identical with or without this.
--    Comment this DO block out to skip.
do $$
declare
  r record;
  tbls text[] := array[
    'todo_boards','todo_groups','todo_items',
    'todo_status_options','todo_updates','todo_dependencies'
  ];
begin
  -- indexes (idx_task_*, *_pkey indexes, unique indexes, etc.)
  for r in
    select indexname
    from pg_indexes
    where schemaname = 'app'
      and tablename = any (tbls)
      and indexname like '%task%'
  loop
    execute format('alter index app.%I rename to %I',
                   r.indexname, replace(r.indexname, 'task', 'todo'));
  end loop;

  -- constraints (pkey / fkey / unique / check)
  for r in
    select c.conname, t.relname
    from pg_constraint c
    join pg_class t      on t.oid = c.conrelid
    join pg_namespace n  on n.oid = t.relnamespace
    where n.nspname = 'app'
      and t.relname = any (tbls)
      and c.conname like '%task%'
  loop
    execute format('alter table app.%I rename constraint %I to %I',
                   r.relname, r.conname, replace(r.conname, 'task', 'todo'));
  end loop;

  -- RLS policies (4 per table x 6 = up to 24)
  for r in
    select policyname, tablename
    from pg_policies
    where schemaname = 'app'
      and tablename = any (tbls)
      and policyname like '%task%'
  loop
    execute format('alter policy %I on app.%I rename to %I',
                   r.policyname, r.tablename, replace(r.policyname, 'task', 'todo'));
  end loop;
end $$;

commit;

-- NOTE: these tables are assumed to use uuid PKs (no owned sequences). If any
-- serial/identity columns exist, their sequences keep task_* names harmlessly.
