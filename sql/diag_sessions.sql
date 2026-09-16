-- diag_sessions.sql (READ ONLY) - who holds database connections
select pid, usename, application_name, state,
       date_trunc('second', now() - backend_start) as conn_age,
       date_trunc('second', now() - state_change) as state_age,
       left(regexp_replace(coalesce(query, ''), '\s+', ' ', 'g'), 80) as query
  from pg_stat_activity
 where datname = current_database()
 order by backend_start;