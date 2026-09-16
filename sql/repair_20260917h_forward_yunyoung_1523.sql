-- repair_20260917h_forward_yunyoung_1523.sql
-- The BASF reply is uid 1524 (found with tools/imap-find.mjs). The cursor has been stuck
-- at 1495, so jump to 1523 to take 1524 first. uids 1496-1523 are handled separately.
-- Holds the value for 2 minutes so a worker restart in that window starts from 1524.
do $do$
declare
  n int;
  t0 timestamptz := clock_timestamp();
begin
  while clock_timestamp() - t0 < interval '2 minutes' loop
    update app.mailcarrier_state
       set last_processed_uid = 1523,
           updated_at = now()
     where username = 'yunyoung.heo@marinebiogroup.com'
       and last_processed_uid < 1523;
    get diagnostics n = row_count;
    commit;
    if n > 0 then
      raise notice 'cursor set to 1523 at %', to_char(clock_timestamp(), 'HH24:MI:SS');
    end if;
    perform pg_sleep(2);
  end loop;
  raise notice 'done - hold window finished';
end
$do$;