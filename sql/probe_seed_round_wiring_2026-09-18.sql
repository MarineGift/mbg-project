-- ============================================================
-- probe_seed_round_wiring_2026-09-18.sql   *** READ ONLY ***
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
-- The editor executes ONLY the highlighted text when a selection exists.
-- Select all, or you will get "relation X does not exist" errors.
--
-- Output: ONE result set -> use "Download CSV" and send the file back.
-- Nothing is created, altered or deleted by this file.
--
-- Purpose: confirm the real wiring before writing any Step 1-2 migration.
--   A  which tables actually exist
--   B  real columns of rounds / deals / deal_parties / campaigns / stages / pipelines
--   C  foreign keys (does deals.round_id have an FK to rounds?)
--   D  pipelines: the real code value (investor vs investors) + deal counts
--   E  stages: real code, sort order, and how many live deals sit on each
--   F  deals.round_id presence + how many deals already carry one
--   G  campaigns <-> deals linkage and current campaign names
--   H  triggers on the deal / stage tables (playbook, history)
--   I  playbook template counts per stage
--   J  existing rounds rows
--   K  live investor deals (what would be touched by a stage rework)
--
-- If section A reports MISSING for any table, tell me which one and I will
-- reissue this file without that table's block. Everything else is safe.
-- ============================================================

select z.section, z.ord, z.key, z.val, z.extra
from (

-- ---------- A. table existence -------------------------------------------
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
  ('tasks'), ('parties'), ('contacts')
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
    'rounds', 'deals', 'deal_parties', 'campaigns',
    'stages', 'pipelines', 'deal_stage_history'
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
    'deals', 'deal_parties', 'deal_stage_history', 'stages',
    'campaigns', 'rounds', 'stage_checklist_templates', 'stage_task_templates'
  )

union all

-- ---------- D. pipelines (real code value) -------------------------------
select
  'D_pipeline'::text,
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

-- ---------- E. stages + live deal load per stage -------------------------
select
  'E_stage'::text,
  coalesce((to_jsonb(s) ->> 'sort_order')::int, 999),
  (coalesce((select to_jsonb(p) ->> 'code' from app.pipelines p where p.id = s.pipeline_id), '?')
    || ' / ' || coalesce(to_jsonb(s) ->> 'code', '(no code)'))::text,
  coalesce(to_jsonb(s) ->> 'name', '')::text,
  ('sort=' || coalesce(to_jsonb(s) ->> 'sort_order', '-')
    || ' is_active=' || coalesce(to_jsonb(s) ->> 'is_active', '-')
    || ' live_deals=' || (
      select count(*) from app.deals d
      where d.current_stage_id = s.id and d.deleted_at is null
    )::text
    || ' history_rows=' || (
      select count(*) from app.deal_stage_history h
      where h.to_stage_id = s.id or h.from_stage_id = s.id
    )::text)::text
from app.stages s

union all

-- ---------- F. deals.round_id: present? populated? -----------------------
select
  'F_round_link'::text,
  0,
  'deals.round_id column'::text,
  case when exists (
    select 1 from information_schema.columns
    where table_schema = 'app' and table_name = 'deals' and column_name = 'round_id'
  ) then 'PRESENT' else 'ABSENT' end::text,
  'if ABSENT this is the single missing wire'::text

union all

select
  'F_round_link'::text,
  1,
  'live deals carrying a round_id'::text,
  (select count(*) from app.deals d
    where d.deleted_at is null and to_jsonb(d) ->> 'round_id' is not null)::text,
  ''::text

union all

select
  'F_round_link'::text,
  2,
  'live deals total'::text,
  (select count(*) from app.deals d where d.deleted_at is null)::text,
  ''::text

union all

-- ---------- G. campaigns <-> deals ---------------------------------------
select
  'G_campaign'::text,
  0,
  coalesce(to_jsonb(c) ->> 'name', '(no name column)')::text,
  coalesce(to_jsonb(c) ->> 'status', '')::text,
  ('live_deals=' || (
    select count(*) from app.deals d
    where d.deleted_at is null
      and to_jsonb(d) ->> 'campaign_id' = c.id::text
  )::text)::text
from app.campaigns c

union all

-- ---------- H. triggers on the deal / stage tables -----------------------
select
  'H_trigger'::text,
  0,
  (t.event_object_table || '.' || t.trigger_name)::text,
  (t.action_timing || ' ' || t.event_manipulation)::text,
  left(coalesce(t.action_statement, ''), 200)::text
from information_schema.triggers t
where t.trigger_schema = 'app'
  and t.event_object_table in (
    'deals', 'deal_stage_history', 'deal_parties', 'stages', 'rounds', 'campaigns'
  )

union all

-- ---------- I. playbook templates per stage ------------------------------
select
  'I_playbook'::text,
  coalesce((to_jsonb(s) ->> 'sort_order')::int, 999),
  (coalesce((select to_jsonb(p) ->> 'code' from app.pipelines p where p.id = s.pipeline_id), '?')
    || ' / ' || coalesce(to_jsonb(s) ->> 'code', '(no code)'))::text,
  ('checklist_templates=' || (
    select count(*) from app.stage_checklist_templates ct where ct.stage_id = s.id
  )::text)::text,
  ('task_templates=' || (
    select count(*) from app.stage_task_templates tt where tt.stage_id = s.id
  )::text)::text
from app.stages s

union all

-- ---------- J. existing rounds -------------------------------------------
select
  'J_round'::text,
  0,
  coalesce(to_jsonb(r) ->> 'name', '(no name column)')::text,
  coalesce(to_jsonb(r) ->> 'status', '')::text,
  ('type=' || coalesce(to_jsonb(r) ->> 'round_type', '-')
    || ' target=' || coalesce(to_jsonb(r) ->> 'target_amount', '-')
    || ' currency=' || coalesce(to_jsonb(r) ->> 'currency', '-')
    || ' opened=' || coalesce(to_jsonb(r) ->> 'opened_at', '-'))::text
from app.rounds r

union all

-- ---------- K. live deals on the investor-side pipeline ------------------
select
  'K_deal'::text,
  0,
  coalesce(to_jsonb(d) ->> 'deal_name', '')::text,
  coalesce((select to_jsonb(s) ->> 'code' from app.stages s where s.id = d.current_stage_id), '-')::text,
  ('party=' || coalesce((select pa.party_name from app.parties pa where pa.id = d.party_id), '-')
    || ' pipeline=' || coalesce((select to_jsonb(p) ->> 'code' from app.pipelines p where p.id = d.pipeline_id), '-')
    || ' round_id=' || case when to_jsonb(d) ->> 'round_id' is null then 'null' else 'set' end
    || ' campaign=' || coalesce((select to_jsonb(c) ->> 'name' from app.campaigns c
                                  where c.id::text = to_jsonb(d) ->> 'campaign_id'), '-')
    || ' status=' || coalesce(to_jsonb(d) ->> 'status', '-'))::text
from app.deals d
where d.deleted_at is null
  and coalesce((select to_jsonb(p) ->> 'code' from app.pipelines p where p.id = d.pipeline_id), '')
      in ('investor', 'investors')

union all

-- ---------- L. deal_parties shape check ----------------------------------
select
  'L_deal_parties'::text,
  0,
  'row count'::text,
  (select count(*) from app.deal_parties)::text,
  ('rows with a commitment amount = ' || (
    select count(*) from app.deal_parties dp
    where to_jsonb(dp) ->> 'commitment_amount' is not null
  )::text)::text

) as z
order by z.section, z.ord, z.key;
