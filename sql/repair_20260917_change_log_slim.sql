-- repair_20260917_change_log_slim.sql  (v4: resumable)
-- Shrinks existing audit.change_log rows: any single value > 2 KB -> '[omitted N bytes]'
-- (same rule as trg_slim_change_log). Only rows that really contain such a value are updated.
-- Progress is stored in audit._slim_progress, so every run continues where the last one stopped.
-- ids <= 58000 were already handled by the 2026-09-16 v2 runs (seed value below).
-- Each run stops after 10 minutes. Irreversible for the audit copies only.
-- Run: node --env-file=.env.local tools/run-sql.mjs sql\repair_20260917_change_log_slim.sql
do $do$
declare
  lo bigint;
  hi bigint;
  maxid bigint;
  n_batch int;
  n_total int := 0;
  t0 timestamptz := clock_timestamp();
begin
  create table if not exists audit._slim_progress (k text primary key, last_id bigint not null);
  insert into audit._slim_progress (k, last_id) values ('change_log', 58000) on conflict (k) do nothing;
  commit;

  select last_id + 1 into lo from audit._slim_progress where k = 'change_log';
  select max(id) into maxid from audit.change_log;

  while lo <= maxid loop
    if clock_timestamp() - t0 > interval '10 minutes' then
      raise notice 'time cap - next start id % of % (slimmed % this run)', lo, maxid, n_total;
      return;
    end if;
    hi := lo + 99;
    update audit.change_log c
       set old_data = audit.slim_jsonb(c.old_data),
           new_data = audit.slim_jsonb(c.new_data)
     where c.id between lo and hi
       and (
         (pg_column_size(c.old_data) > 2000
          and case when jsonb_typeof(c.old_data) = 'object'
                   then exists (select 1 from jsonb_each(c.old_data) e where pg_column_size(e.value) > 2000)
                   else false end)
         or
         (pg_column_size(c.new_data) > 2000
          and case when jsonb_typeof(c.new_data) = 'object'
                   then exists (select 1 from jsonb_each(c.new_data) e where pg_column_size(e.value) > 2000)
                   else false end)
       );
    get diagnostics n_batch = row_count;
    n_total := n_total + n_batch;
    update audit._slim_progress set last_id = hi where k = 'change_log';
    commit;
    if n_batch > 0 then
      raise notice 'ids % - %: slimmed % (total %)', lo, hi, n_batch, n_total;
      perform pg_sleep(2);
    end if;
    lo := hi + 1;
  end loop;
  raise notice 'done - all ids up to % processed (slimmed % this run)', maxid, n_total;
end
$do$;