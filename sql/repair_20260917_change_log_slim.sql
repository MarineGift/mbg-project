-- repair_20260917_change_log_slim.sql  (v3)
-- v3 fix: only rows that actually contain a single value > 2 KB are updated.
--   v2 selected rows whose TOTAL size was > 2 KB, so rows made of many medium
--   values were rewritten on every run without changing (heavy write IO).
-- Stops by itself after 10 minutes; re-run to continue (done rows are skipped).
-- Irreversible for the audit copies only (live tables are untouched).
-- Run at a quiet time: node --env-file=.env.local tools/run-sql.mjs sql\repair_20260917_change_log_slim.sql
do $do$
declare
  lo bigint;
  hi bigint;
  maxid bigint;
  n_batch int;
  n_total int := 0;
  t0 timestamptz := clock_timestamp();
begin
  select min(id), max(id) into lo, maxid from audit.change_log;
  while lo is not null and lo <= maxid loop
    if clock_timestamp() - t0 > interval '10 minutes' then
      raise notice 'time cap reached at id % - re-run to continue (slimmed % this run)', lo, n_total;
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
    commit;
    if n_batch > 0 then
      raise notice 'ids % - %: slimmed % (total %)', lo, hi, n_batch, n_total;
      perform pg_sleep(2);
    end if;
    lo := hi + 1;
  end loop;
  raise notice 'done - rows slimmed this run: %', n_total;
end
$do$;