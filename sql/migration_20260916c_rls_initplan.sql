-- migration_20260916c_rls_initplan.sql  (APPLIED 2026-09-16 via SQL Editor)
-- RUN: node --env-file=.env.local tools/run-sql.mjs sql\<this file>   (or SQL Editor: Ctrl+A then Run)
-- WHY: RLS policies called app.perm_scope()/has_perm()/current_organization_id()/auth.uid()
--      once PER ROW. perm_scope() is SECURITY DEFINER -> 6.4 million scans of app.role_permissions.
-- WHAT: every policy in app/ai wraps argument-free or constant-argument calls as (select fn(...)),
--      evaluated ONCE per statement (InitPlan). Same rules and security. Row-dependent calls untouched.
-- IDEMPOTENT: already-wrapped calls are detected, re-run changes nothing.

create or replace function pg_temp.rls_unwrap(t text)
returns text language plpgsql immutable as $w$
declare s text := t;
begin
  if s is null then return null; end if;
  s := regexp_replace(s, '\( SELECT (app\.current_organization_id\(\)) AS current_organization_id\)', '\1', 'g');
  s := regexp_replace(s, '\( SELECT (app\.current_user_id\(\)) AS current_user_id\)', '\1', 'g');
  s := regexp_replace(s, '\( SELECT (auth\.uid\(\)) AS uid\)', '\1', 'g');
  s := regexp_replace(s, '\( SELECT (app\.perm_scope\(''[a-z_]+''::text, ''[a-z_]+''::text\)) AS perm_scope\)', '\1', 'g');
  s := regexp_replace(s, '\( SELECT (app\.has_perm\(''[a-z_]+''::text, ''[a-z_]+''::text\)) AS has_perm\)', '\1', 'g');
  return s;
end $w$;

create or replace function pg_temp.rls_wrap(t text)
returns text language plpgsql immutable as $w$
declare s text := pg_temp.rls_unwrap(t);
begin
  if s is null then return null; end if;
  s := regexp_replace(s, 'app\.current_organization_id\(\)', '(select app.current_organization_id())', 'g');
  s := regexp_replace(s, 'app\.current_user_id\(\)', '(select app.current_user_id())', 'g');
  s := regexp_replace(s, 'auth\.uid\(\)', '(select auth.uid())', 'g');
  s := regexp_replace(s, '(app\.perm_scope\(''[a-z_]+''::text, ''[a-z_]+''::text\))', '(select \1)', 'g');
  s := regexp_replace(s, '(app\.has_perm\(''[a-z_]+''::text, ''[a-z_]+''::text\))', '(select \1)', 'g');
  return s;
end $w$;

create or replace function pg_temp.rls_bare(t text)
returns int language plpgsql immutable as $w$
declare
  pat_bare text := 'app\.current_organization_id\(\)|app\.current_user_id\(\)|auth\.uid\(\)|app\.perm_scope\(''[a-z_]+''::text, ''[a-z_]+''::text\)|app\.has_perm\(''[a-z_]+''::text, ''[a-z_]+''::text\)';
  pat_wrapped text := '\( SELECT (app\.current_organization_id\(\) AS current_organization_id|app\.current_user_id\(\) AS current_user_id|auth\.uid\(\) AS uid|app\.perm_scope\(''[a-z_]+''::text, ''[a-z_]+''::text\) AS perm_scope|app\.has_perm\(''[a-z_]+''::text, ''[a-z_]+''::text\) AS has_perm)\)';
begin
  if t is null then return 0; end if;
  return regexp_count(pg_temp.rls_unwrap(t), pat_bare) - regexp_count(t, pat_wrapped);
end $w$;

do $do$
declare
  r record;
  sql_text text;
  n int := 0;
begin
  for r in
    select schemaname, tablename, policyname, qual, with_check
      from pg_policies
     where schemaname in ('app', 'ai')
     order by schemaname, tablename, policyname
  loop
    if pg_temp.rls_bare(r.qual) + pg_temp.rls_bare(r.with_check) = 0 then
      continue;
    end if;
    sql_text := format('alter policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);
    if r.qual is not null then
      sql_text := sql_text || ' using (' || pg_temp.rls_wrap(r.qual) || ')';
    end if;
    if r.with_check is not null then
      sql_text := sql_text || ' with check (' || pg_temp.rls_wrap(r.with_check) || ')';
    end if;
    execute sql_text;
    n := n + 1;
  end loop;
  raise notice 'policies rewritten: %', n;
end
$do$;

select p.schemaname,
       count(*) as policies,
       sum(pg_temp.rls_bare(p.qual) + pg_temp.rls_bare(p.with_check)) as bare_calls_left,
       count(*) filter (where coalesce(p.qual, '') || coalesce(p.with_check, '') like '%( SELECT %') as wrapped_policies
  from pg_policies p
 where p.schemaname in ('app', 'ai')
 group by p.schemaname
 order by p.schemaname;