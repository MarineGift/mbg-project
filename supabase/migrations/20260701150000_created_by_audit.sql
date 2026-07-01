-- created_by_audit.sql
-- Adds creator tracking (created_by) to ENTITY tables in the app / ai schemas.
-- Self-inspecting + idempotent + atomic. Prints a result grid of what changed.
--
-- Rules:
--   * skip tables that already have created_by
--   * skip non-entities by name: *_history (audit), *_types (lookup),
--     *_parties / *_links / *_map (join tables)
--   * everything else: add created_by (instant) + default auth.uid()
--     (future inserts) + backfill existing rows to the org owner
--   * industry.* is intentionally excluded (shared reference data)
--
-- Safe to re-run. If it times out on a large table's backfill, the whole thing
-- rolls back (atomic) - tell me the last "added" table and I will batch it.

create temp table if not exists _cb_audit(sch text, tbl text, action text, note text);
truncate _cb_audit;

do $$
declare
  r   record;
  owner constant uuid := '551fc4a0-b365-47eb-bf2f-0c3f594001c0';
  cnt bigint;
begin
  for r in
    select table_schema as sch, table_name as tbl
    from information_schema.tables
    where table_schema in ('app','ai') and table_type='BASE TABLE'
    order by 1,2
  loop
    if exists (select 1 from information_schema.columns
               where table_schema=r.sch and table_name=r.tbl and column_name='created_by') then
      insert into _cb_audit values (r.sch, r.tbl, 'skip', 'already has created_by'); continue;
    end if;
    if  r.tbl ilike '%\_history' escape '\'
     or r.tbl ilike '%\_types'   escape '\'
     or r.tbl ilike '%\_parties' escape '\'
     or r.tbl ilike '%\_links'   escape '\'
     or r.tbl ilike '%\_map'     escape '\' then
      insert into _cb_audit values (r.sch, r.tbl, 'skip', 'non-entity (join/history/lookup)'); continue;
    end if;
    execute format('alter table %I.%I add column if not exists created_by uuid', r.sch, r.tbl);
    execute format('alter table %I.%I alter column created_by set default auth.uid()', r.sch, r.tbl);
    execute format('update %I.%I set created_by=%L where created_by is null', r.sch, r.tbl, owner);
    get diagnostics cnt = row_count;
    insert into _cb_audit values (r.sch, r.tbl, 'added', format('backfilled %s rows', cnt));
  end loop;
end $$;

select action, sch, tbl, note from _cb_audit order by action desc, sch, tbl;
