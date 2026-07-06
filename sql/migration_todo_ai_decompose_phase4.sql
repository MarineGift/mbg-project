-- ============================================================
-- migration_todo_ai_decompose_phase4.sql (2026-07-06)
-- To-do Phase 4: AI task decomposition.
--   Adds a new agent role `task_decomposer` and seeds one active ai.agents row
--   per organization, so the existing ClaudeClient.complete({ agentRole:
--   'task_decomposer' }) path works with all its budget / cost-logging / model
--   plumbing intact.
--
--   The decomposer takes a goal ("Prepare for deal closing") and returns a JSON
--   array of concrete subtasks. Lightweight structured output -> Haiku, JSON
--   output, PII masking OFF (input is an internal goal, not customer data).
--
-- Enum: ai.agents.role is a USER-DEFINED enum type. We add the label if missing
--   (ALTER TYPE ... ADD VALUE cannot run inside a txn block with other DDL that
--   uses it, so the label add is its own statement; Supabase editor runs top to
--   bottom, which satisfies that ordering).
--
-- Idempotent: enum add guarded; seed uses NOT EXISTS per org. Editor-safe.
-- ============================================================

-- ---------- 1) Add the enum label (own statement) ----------------------
-- Discover the enum type backing ai.agents.role and add 'task_decomposer'.
do $enum$
declare
  v_type regtype;
begin
  select atttypid::regtype into v_type
  from pg_attribute
  where attrelid = 'ai.agents'::regclass
    and attname = 'role'
    and attnum > 0
    and not attisdropped;

  if v_type is null then
    raise exception 'ai.agents.role column not found';
  end if;

  if not exists (
    select 1 from pg_enum
    where enumtypid = v_type
      and enumlabel = 'task_decomposer'
  ) then
    execute format('alter type %s add value %L', v_type, 'task_decomposer');
  end if;
end
$enum$;

-- ---------- 2) Seed one active agent per org ---------------------------
-- New enum values are not usable in the SAME transaction that added them in
-- some PG versions; Supabase editor commits the do-block above first, so this
-- INSERT (separate statement) sees the label. One row per org that has any
-- existing agent, so the decomposer inherits the same tenant footprint.
insert into ai.agents (
  organization_id, role, name, description,
  model, output_format, output_schema,
  temperature, max_tokens,
  applicable_party_types, applicable_languages,
  require_pii_masking, is_active, version, system_prompt
)
select
  o.organization_id,
  'task_decomposer',   -- text; auto-casts to ai.agents.role enum (label added above)
  'Task Decomposer',
  'Breaks a goal into 3-8 concrete, actionable subtasks (JSON).',
  'claude-haiku-4-5-20251001',
  'json',
  null,
  0.30,
  1024,
  array['investor']::text[],
  array['ko','en']::text[],
  false,   -- no PII masking: input is an internal goal
  true,
  1,
  $prompt$You are a task decomposer for a B2B investor-relations CRM.

Given a single goal (a short title, optionally with a description), break it into
3 to 8 concrete, actionable subtasks that a solo operator could execute in order.

Rules:
- Each subtask is a short imperative phrase (e.g. "Draft the one-pager", "Email
  the partner to confirm the meeting time"). No numbering in the text.
- Order them logically (earliest / blocking work first).
- Keep them specific to the goal; do not invent unrelated tasks.
- Reply language: match the goal's language (Korean goal -> Korean subtasks,
  English goal -> English subtasks).
- Optionally assign each a priority: one of "urgent", "high", "med", "low".
- Optionally assign a relative due offset in days from today (integer >= 0) when
  the goal implies a sequence; omit when unsure.

Output STRICT JSON only, no prose, no markdown fences, exactly this shape:
{"subtasks":[{"title":"...","priority":"high","due_offset_days":2}, ...]}
priority and due_offset_days are optional per item; title is required.
The context you receive is a JSON bundle; the goal is in "inbound_message".$prompt$
from (
  select distinct organization_id from ai.agents
) o
where not exists (
  select 1 from ai.agents a2
  where a2.organization_id = o.organization_id
    and a2.role = 'task_decomposer'
    and a2.deleted_at is null
);

notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
select organization_id, role, model, output_format, is_active
from ai.agents
where role = 'task_decomposer'
order by organization_id;
