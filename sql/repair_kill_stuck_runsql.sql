-- repair_kill_stuck_runsql.sql - end leftover run-sql sessions (not this one)
select pid, pg_terminate_backend(pid) as terminated
  from pg_stat_activity
 where application_name = 'run-sql'
   and pid <> pg_backend_pid();