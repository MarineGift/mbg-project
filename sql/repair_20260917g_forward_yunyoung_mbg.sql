-- repair_20260917g_forward_yunyoung_mbg.sql
-- Move the yunyoung.heo@marinebiogroup.com cursor forward to 1495 again.
-- uids 418-1495 were already read once after the DB recovered (cursor reached 1495 at
-- 20:21 UTC) and 418-628 were re-read by the rewind, so nothing is lost; the newest mail
-- (BASF reply) sits above 1495. Holds the value for 2 minutes so a worker restart during
-- that window starts from 1496 even if the old container saves a lower uid on its way out.
do $do$
declare
  n int;
  t0 timestamptz := clock_timestamp();
begin
  while clock_timestamp() - t0 < interval '2 minutes' loop
    update app.mailcarrier_state
       set last_processed_uid = 1495,
           updated_at = now()
     where username = 'yunyoung.heo@marinebiogroup.com'
       and last_processed_uid < 1495;
    get diagnostics n = row_count;
    commit;
    if n > 0 then
      raise notice 'cursor set to 1495 at %', to_char(clock_timestamp(), 'HH24:MI:SS');
    end if;
    perform pg_sleep(2);
  end loop;
  raise notice 'done - hold window finished';
end
$do$;