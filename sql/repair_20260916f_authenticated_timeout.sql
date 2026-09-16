-- repair_20260916f_authenticated_timeout.sql
-- Temporary: give logged-in API queries 30s instead of the default 8s while the DB
-- works through its IO backlog (inbox list hit 57014 statement timeout).
-- Revert later with:  alter role authenticated set statement_timeout = '8s'; notify pgrst, 'reload config';
alter role authenticated set statement_timeout = '30s';
notify pgrst, 'reload config';
select rolname, array_to_string(rolconfig, ', ') as config
  from pg_roles
 where rolname in ('authenticated', 'anon');