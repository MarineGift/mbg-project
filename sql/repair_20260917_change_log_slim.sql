-- repair_20260917_change_log_slim.sql
-- One-time cleanup: shrink existing audit.change_log rows (values > 2 KB -> marker),
-- same rule as trg_slim_change_log. Batches of 100 rows, commit + 1s pause per batch.
-- Irreversible for the audit copies only (live tables are untouched).
-- Run: node --env-file=.env.local tools/run-sql.mjs sql\repair_20260917_change_log_slim.sql
do $do$
declare
  n_batch int;
  n_total int := 0;
begin
  loop
    with pick as (
      select c.id
        from audit.change_log c
       where pg_column_size(c.old_data) > 2000
          or pg_column_size(c.new_data) > 2000
       order by c.id
       limit 100
    )
    update audit.change_log c
       set old_data = audit.slim_jsonb(c.old_data),
           new_data = audit.slim_jsonb(c.new_data)
      from pick
     where c.id = pick.id;
    get diagnostics n_batch = row_count;
    exit when n_batch = 0;
    n_total := n_total + n_batch;
    commit;
    perform pg_sleep(1);
  end loop;
  raise notice 'rows slimmed: %', n_total;
end
$do$;