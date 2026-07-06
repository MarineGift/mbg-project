-- ============================================================
-- migration_ai_agent_role_to_table.sql (2026-07-06)
-- Convert ai.agents.role from a Postgres ENUM (ai.agent_role) to a text column
-- backed by a lookup TABLE (ai.agent_roles). Removes the enum entirely.
--
-- Why: adding a new role to an enum triggers "55P04 unsafe use of new value ...
-- must be committed before use" whenever the same script also inserts a row
-- using it (Supabase editor wraps a script in one txn). A lookup table has no
-- such restriction — a new role is just an INSERT, usable immediately.
--
-- Safety:
--   * ai.agent_role is used by exactly ONE column (ai.agents.role) — verified.
--   * All existing role values are preserved (enum label text == new text).
--   * FK is added as NOT VALID first, then VALIDATE, so a surprise value can't
--     abort the whole migration silently.
--
-- Idempotent-ish: guarded so re-running after partial success is safe. The enum
-- DROP is conditional on the column no longer depending on it.
-- Editor-safe: each DDL is its own top-level statement (no bare keywords in
-- strings; the agent seed with its JSON-heavy prompt is split out to a separate
-- file to avoid the editor's dollar-quote/`{...}` parsing quirks).
-- ============================================================

-- ---------- 1) Lookup table + seed the known roles ----------------------
create table if not exists ai.agent_roles (
  key         text primary key,
  label       text not null,
  description text,
  sort_order  integer not null default 100,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

comment on table ai.agent_roles is
  'Lookup for ai.agents.role. Replaces the former ai.agent_role enum; add a new role with a plain INSERT (no enum ALTER, no 55P04).';

-- Seed every label that existed on the enum, plus task_decomposer. ON CONFLICT
-- keeps re-runs safe and lets us backfill labels without duplicating rows.
insert into ai.agent_roles (key, label, description, sort_order) values
  ('classifier',       'Classifier',        'Mail classifier (Haiku).',                 10),
  ('reply_drafter',    'Reply Drafter',     'Reply-draft writer (Opus).',               20),
  ('strategy_advisor', 'Strategy Advisor',  'Strategy advisor (Opus).',                 30),
  ('summarizer',       'Summarizer',        'Body summarizer (Haiku).',                 40),
  ('extractor',        'Extractor',         'Scraping-result normalizer (Haiku).',      50),
  ('translator',       'Translator',        'Translator (Haiku).',                      60),
  ('task_decomposer',  'Task Decomposer',   'Breaks a goal into 3-8 subtasks (JSON).',  70)
on conflict (key) do update
  set label       = excluded.label,
      description  = excluded.description,
      sort_order   = excluded.sort_order;

-- ---------- 2) Convert ai.agents.role  enum -> text ---------------------
-- Only convert if it is still the enum type; skip if already text (re-run).
do $conv$
declare
  v_typename text;
begin
  select atttypid::regtype::text into v_typename
  from pg_attribute
  where attrelid = 'ai.agents'::regclass and attname = 'role';

  if v_typename = 'ai.agent_role' then
    -- USING enum::text preserves every existing value verbatim.
    alter table ai.agents
      alter column role type text using role::text;
  end if;
end
$conv$;

-- ---------- 3) FK: ai.agents.role -> ai.agent_roles(key) ----------------
-- Any role currently in ai.agents must exist in the lookup (seeded above).
-- Add NOT VALID then VALIDATE so a mismatch surfaces loudly rather than
-- silently blocking. Guard against re-run duplicate-constraint error.
do $fk$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'agents_role_fkey'
  ) then
    alter table ai.agents
      add constraint agents_role_fkey
      foreign key (role) references ai.agent_roles(key)
      not valid;
    alter table ai.agents validate constraint agents_role_fkey;
  end if;
end
$fk$;

-- Helpful index for role filtering (the client loadAgent filters by role).
create index if not exists ix_agents_role on ai.agents (organization_id, role);

-- ---------- 4) Drop the now-unused enum type ----------------------------
-- Safe: step 2 changed the only column off it. Guarded so re-run won't error.
-- We reference the type by name (pg_type lookup), never via ::regtype, so this
-- block does not throw once the type is already gone.
do $drop$
declare
  v_oid oid;
begin
  select t.oid into v_oid
  from pg_type t
  join pg_namespace n on n.oid = t.typnamespace
  where t.typname = 'agent_role' and n.nspname = 'ai';

  if v_oid is null then
    return;  -- already dropped (re-run)
  end if;

  -- Only drop if nothing still depends on the type.
  if not exists (
    select 1 from pg_attribute a
    where a.atttypid = v_oid and a.attnum > 0 and not a.attisdropped
  ) then
    drop type ai.agent_role;
  end if;
end
$drop$;

notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- (a) role column is now text
select data_type from information_schema.columns
where table_schema='ai' and table_name='agents' and column_name='role';

-- (b) all existing agents still have their role (counts unchanged)
select role, count(*) from ai.agents group by role order by role;

-- (c) lookup + FK present
select conname from pg_constraint where conname='agents_role_fkey';

-- (d) enum type gone
select count(*) as enum_still_exists
from pg_type t join pg_namespace n on n.oid=t.typnamespace
where t.typname='agent_role' and n.nspname='ai';
