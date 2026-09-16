-- migration_20260916d_audit_slim.sql  (APPLIED 2026-09-16 via SQL Editor)
-- RUN: node --env-file=.env.local tools/run-sql.mjs sql\<this file>   (or SQL Editor: Ctrl+A then Run)
-- WHY: audit.log_change() stores to_jsonb(OLD/NEW) incl. full mail bodies -> change_log 985 MB.
-- WHAT: BEFORE INSERT trigger on audit.change_log replaces any single value > 2 KB inside
--       old_data/new_data with '[omitted N bytes]'. audit.log_change() itself is NOT modified.
-- IDEMPOTENT. Existing rows are not changed here (cleanup is a later step).

create or replace function audit.slim_jsonb(p jsonb, p_max_bytes int default 2000)
returns jsonb
language plpgsql
immutable
set search_path = pg_catalog
as $f$
declare
  k text;
  v jsonb;
  outj jsonb := p;
begin
  if p is null or jsonb_typeof(p) <> 'object' or pg_column_size(p) <= p_max_bytes then
    return p;
  end if;
  for k, v in select e.key, e.value from jsonb_each(p) as e loop
    if pg_column_size(v) > p_max_bytes then
      outj := jsonb_set(outj, array[k], to_jsonb('[omitted ' || octet_length(v::text) || ' bytes]'));
    end if;
  end loop;
  return outj;
end
$f$;

create or replace function audit.slim_change_log()
returns trigger
language plpgsql
set search_path = pg_catalog
as $f$
begin
  new.old_data := audit.slim_jsonb(new.old_data);
  new.new_data := audit.slim_jsonb(new.new_data);
  return new;
end
$f$;

drop trigger if exists trg_slim_change_log on audit.change_log;

create trigger trg_slim_change_log
  before insert on audit.change_log
  for each row execute function audit.slim_change_log();

select tgname, tgenabled
  from pg_trigger
 where tgrelid = 'audit.change_log'::regclass
   and tgname = 'trg_slim_change_log';