-- diag_20260916b_rls_audit.sql   (READ ONLY - changes nothing)
-- Run: node --env-file=.env.local tools/run-sql.mjs sql\diag_20260916b_rls_audit.sql
-- Lists RLS policies, permission functions, audit triggers and change_log stats.

with pol (section, name, detail) as (
  select 'a_policy',
         p.schemaname || '.' || p.tablename || ' / ' || p.policyname || ' [' || p.cmd || ']',
         left(regexp_replace(coalesce(p.qual, '-') || ' || CHECK ' || coalesce(p.with_check, '-'), '\s+', ' ', 'g'), 400)
    from pg_policies p
   where p.schemaname in ('app', 'ai')
     and p.tablename in ('parties', 'communications', 'mail_folders', 'contacts',
                         'email_whitelist', 'tasks', 'drafts', 'runs', 'role_permissions',
                         'investor_profile', 'investor_sector_focus')
),
fn (section, name, detail) as (
  select 'b_function',
         n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
         'volatile=' || p.provolatile::text || ' secdef=' || p.prosecdef::text || ' lang=' || l.lanname
           || ' config=' || coalesce(array_to_string(p.proconfig, ','), '-')
           || ' body=' || left(regexp_replace(p.prosrc, '\s+', ' ', 'g'), 500)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    join pg_language l on l.oid = p.prolang
   where n.nspname in ('app', 'ai', 'public', 'audit')
     and (p.prosrc ilike '%role_permissions%'
          or p.prosrc ilike '%change_log%'
          or p.proname in ('current_organization_id', 'has_permission', 'current_role', 'is_admin'))
),
trg (section, name, detail) as (
  select 'c_trigger',
         c.relnamespace::regnamespace::text || '.' || c.relname || ' / ' || t.tgname,
         pg_get_triggerdef(t.oid)
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
   where not t.tgisinternal
     and c.relnamespace::regnamespace::text in ('app', 'ai')
     and pg_get_triggerdef(t.oid) ilike '%audit%'
),
rpi (section, name, detail) as (
  select 'd_role_perm_index',
         x.indexrelid::regclass::text,
         pg_get_indexdef(x.indexrelid)
    from pg_index x
   where x.indrelid = 'app.role_permissions'::regclass
),
rpc (section, name, detail) as (
  select 'd_role_perm_rows',
         'app.role_permissions',
         (select count(*) from app.role_permissions)::text || ' rows'
),
clc (section, name, detail) as (
  select 'e_change_log_cols',
         'audit.change_log',
         string_agg(column_name || ':' || data_type, ', ' order by ordinal_position)
    from information_schema.columns
   where table_schema = 'audit' and table_name = 'change_log'
),
cls (section, name, detail) as (
  select 'e_change_log_stats',
         'audit.change_log',
         'live ' || n_live_tup || ' dead ' || n_dead_tup || ' ins ' || n_tup_ins
           || ' upd ' || n_tup_upd || ' del ' || n_tup_del
           || ' heap ' || pg_size_pretty(pg_relation_size(relid))
           || ' total ' || pg_size_pretty(pg_total_relation_size(relid))
           || ' autovac ' || coalesce(last_autovacuum::text, '-')
    from pg_stat_all_tables
   where schemaname = 'audit' and relname = 'change_log'
),
st (section, name, detail) as (
  select 'f_stats_reset',
         'pg_stat_database',
         coalesce(stats_reset::text, 'never')
    from pg_stat_database
   where datname = current_database()
)
select section, name, detail from pol
union all select section, name, detail from fn
union all select section, name, detail from trg
union all select section, name, detail from rpi
union all select section, name, detail from rpc
union all select section, name, detail from clc
union all select section, name, detail from cls
union all select section, name, detail from st
order by section, name;