-- ============================================================
-- probe_seed_round_wiring_v2_2026-09-18.sql   *** READ ONLY ***
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- v2 changes vs v1:
--   - REMOVED every read of app.rounds. v1 died on it: the table does not
--     exist, and a single failing reference cancels the whole statement.
--   - Data reads are now limited to tables the running app proves exist
--     (pipelines, stages, deals, campaigns, parties). Everything else is
--     inspected through the catalog only, which cannot fail on a missing table.
--   - ADDED RLS policy inspection, to explain the campaigns insert failure
--     ("new row violates row-level security policy for table campaigns").
--   - ADDED row-count estimates for every app table.
--
-- Output: ONE result set -> "Download CSV" -> send the file back.
-- Nothing is created, altered or deleted by this file.
-- ============================================================

select z.section, z.ord, z.key, z.val, z.extra
from (

-- ---------- A. table existence (catalog only, always safe) ---------------
select
  'A_table'::text                                   as section,
  0                                                 as ord,
  t.name::text                                      as key,
  case when to_regclass('app.' || t.name) is null
       then 'MISSING' else 'EXISTS' end::text       as val,
  ''::text                                          as extra
from (values
  ('rounds'), ('deals'), ('deal_parties'), ('deal_stage_history'),
  ('deal_checklists'), ('pipelines'), ('stages'), ('campaigns'),
  ('stage_checklist_templates'), ('stage_task_templates'),
  ('tasks'), ('parties'), ('contacts'), ('engagements'), ('communications')
) as t(name)

union all

-- ---------- B. real columns ----------------------------------------------
select
  'B_column'::text,
  c.ordinal_position::int,
  (c.table_name || '.' || c.column_name)::text,
  c.data_type::text,
  ('nullable=' || c.is_nullable || ' default=' || coalesce(c.column_default, '-'))::text
from information_schema.columns c
where c.table_schema = 'app'
  and c.table_name in (
    'deals', 'deal_parties', 'campaigns', 'stages', 'pipelines',
    'deal_stage_history'
  )

union all

-- ---------- C. foreign keys ----------------------------------------------
select
  'C_fk'::text,
  0,
  (tc.table_name || '.' || kcu.column_name)::text,
  (ccu.table_name || '.' || ccu.column_name)::text,
  tc.constraint_name::text
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_name = tc.constraint_name
 and kcu.table_schema    = tc.table_schema
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
 and ccu.table_schema    = tc.table_schema
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'app'
  and tc.table_name in (
    'deals', 'deal_parties', 'deal_stage_history', 'stages', 'campaigns'
  )

union all

-- ---------- D1. RLS switch per table -------------------------------------
select
  'D1_rls_enabled'::text,
  0,
  cl.relname::text,
  case when cl.relrowsecurity then 'RLS ON' else 'RLS OFF' end::text,
  case when cl.relforcerowsecurity then 'FORCED' else '' end::text
from pg_class cl
join pg_namespace ns on ns.oid = cl.relnamespace
where ns.nspname = 'app'
  and cl.relkind = 'r'
  and cl.relname in ('campaigns', 'deals', 'deal_parties', 'stages', 'pipelines', 'parties')

union all

-- ---------- D2. RLS policies (why the campaigns insert was rejected) -----
select
  'D2_rls_policy'::text,
  0,
  (p.tablename || ' :: ' || p.policyname)::text,
  (p.cmd || ' for ' || array_to_string(p.roles, ',')
    || case when p.permissive = 'PERMISSIVE' then '' else ' (RESTRICTIVE)' end)::text,
  ('USING=' || left(coalesce(p.qual, '-'), 120)
    || ' || WITHCHECK=' || left(coalesce(p.with_check, '-'), 120))::text
from pg_policies p
where p.schemaname = 'app'
  and p.tablename in ('campaigns', 'deals', 'deal_parties')

union all

-- ---------- E. pipelines: the REAL code value ----------------------------
select
  'E_pipeline'::text,
  0,
  coalesce(to_jsonb(p) ->> 'code', '(no code column)')::text,
  coalesce(to_jsonb(p) ->> 'name', '')::text,
  ('is_active=' || coalesce(to_jsonb(p) ->> 'is_active', '-')
    || ' live_deals=' || (
      select count(*) from app.deals d
      where d.pipeline_id = p.id and d.deleted_at is null
    )::text)::text
from app.pipelines p

union all

-- ---------- F. stages + live deal load per stage -------------------------
select
  'F_stage'::text,
  coalesce((to_jsonb(s) ->> 'sort_order')::int, 999),
  (coalesce((select to_jsonb(p) ->> 'code' from app.pipelines p where p.id = s.pipeline_id), '?')
    || ' / ' || coalesce(to_jsonb(s) ->> 'code', '(no code)'))::text,
  coalesce(to_jsonb(s) ->> 'name', '')::text,
  ('sort=' || coalesce(to_jsonb(s) ->> 'sort_order', '-')
    || ' is_active=' || coalesce(to_jsonb(s) ->> 'is_active', '-')
    || ' live_deals=' || (
      select count(*) from app.deals d
      where d.current_stage_id = s.id and d.deleted_at is null
    )::text)::text
from app.stages s

union all

-- ---------- G. deals.round_id: present? ----------------------------------
select
  'G_round_link'::text,
  0,
  'deals.round_id column'::text,
  case when exists (
    select 1 from information_schema.columns
    where table_schema = 'app' and table_name = 'deals' and column_name = 'round_id'
  ) then 'PRESENT' else 'ABSENT' end::text,
  'app.rounds table itself is reported in section A'::text

union all

select
  'G_round_link'::text,
  1,
  'live deals total'::text,
  (select count(*) from app.deals d where d.deleted_at is null)::text,
  ''::text

union all

select
  'G_round_link'::text,
  2,
  'soft-deleted deals'::text,
  (select count(*) from app.deals d where d.deleted_at is not null)::text,
  ''::text

union all

-- ---------- H. campaigns currently in use --------------------------------
select
  'H_campaign'::text,
  0,
  coalesce(to_jsonb(c) ->> 'name', '(no name column)')::text,
  coalesce(to_jsonb(c) ->> 'status', '')::text,
  ('type=' || coalesce(to_jsonb(c) ->> 'campaign_type', '-')
    || ' live_deals=' || (
      select count(*) from app.deals d
      where d.deleted_at is null
        and to_jsonb(d) ->> 'campaign_id' = c.id::text
    )::text)::text
from app.campaigns c

union all

-- ---------- I. triggers on deal / stage tables ---------------------------
select
  'I_trigger'::text,
  0,
  (t.event_object_table || '.' || t.trigger_name)::text,
  (t.action_timing || ' ' || t.event_manipulation)::text,
  left(coalesce(t.action_statement, ''), 180)::text
from information_schema.triggers t
where t.trigger_schema = 'app'
  and t.event_object_table in (
    'deals', 'deal_stage_history', 'deal_parties', 'stages', 'campaigns'
  )

union all

-- ---------- J. row-count estimates for every app table (catalog only) ----
select
  'J_rowcount_est'::text,
  0,
  st.relname::text,
  st.n_live_tup::text,
  'estimate from pg_stat_user_tables'::text
from pg_stat_user_tables st
where st.schemaname = 'app'
  and st.relname in (
    'deals', 'deal_parties', 'deal_stage_history', 'deal_checklists',
    'stage_checklist_templates', 'stage_task_templates', 'tasks',
    'campaigns', 'parties', 'contacts', 'engagements', 'communications'
  )

union all

-- ---------- K. the 60 most advanced live deals ---------------------------
-- (ordered by stage sort_order descending, so Reply received / First meeting
--  style stages come first and the Backlog bulk is cut off)
(
select
  'K_deal'::text,
  coalesce((select (to_jsonb(s) ->> 'sort_order')::int
              from app.stages s where s.id = d.current_stage_id), 0),
  coalesce(to_jsonb(d) ->> 'deal_name', '')::text,
  coalesce((select to_jsonb(s) ->> 'code' from app.stages s where s.id = d.current_stage_id), '-')::text,
  ('party=' || coalesce((select pa.party_name from app.parties pa where pa.id = d.party_id), '-')
    || ' campaign=' || coalesce((select to_jsonb(c) ->> 'name' from app.campaigns c
                                   where c.id::text = to_jsonb(d) ->> 'campaign_id'), '-')
    || ' source=' || coalesce(to_jsonb(d) ->> 'source', '-')
    || ' last_activity=' || coalesce(left(to_jsonb(d) ->> 'last_activity_at', 10), '-'))::text
from app.deals d
where d.deleted_at is null
order by
  coalesce((select (to_jsonb(s) ->> 'sort_order')::int
              from app.stages s where s.id = d.current_stage_id), 0) desc
limit 60
)

) as z
order by z.section, z.ord desc, z.key;
