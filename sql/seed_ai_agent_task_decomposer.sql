-- ============================================================
-- seed_ai_agent_task_decomposer.sql (2026-07-06)
-- Seed one active `task_decomposer` agent per org.
--
-- Run AFTER migration_ai_agent_role_to_table.sql (which makes role a text FK to
-- ai.agent_roles and pre-seeds the 'task_decomposer' lookup row).
--
-- PARSER-SAFETY (Supabase SQL editor quirks — see project notes):
--   * The editor mis-parses `{ ... }` and stray digits inside a string, and it
--     splits on ';' even inside dollar-quoted bodies in some cases. The earlier
--     attempt failed with 42P01 relation "3" because the JSON example
--     {"subtasks":[{...}, ...]} tripped that parser.
--   * This version keeps the system prompt FREE of braces, semicolons, and the
--     word `into`. The JSON shape is described in words + square-bracket-free
--     notation, and the whole prompt is a normal single-quoted string with ''
--     doubling (no dollar-quoting), so the editor cannot mis-split it.
--
-- Idempotent: one row per org via NOT EXISTS.
-- ============================================================

insert into ai.agents (
  organization_id, role, name, description,
  model, output_format,
  temperature, max_tokens,
  applicable_party_types, applicable_languages,
  require_pii_masking, is_active, version, system_prompt
)
select
  o.organization_id,
  'task_decomposer',
  'Task Decomposer',
  'Breaks a goal down to 3-8 concrete actionable subtasks as JSON.',
  'claude-haiku-4-5-20251001',
  'json',
  0.30,
  1024,
  array['investor']::text[],
  array['ko','en']::text[],
  false,
  true,
  1,
  'You are a task decomposer for a B2B investor-relations CRM. '
  || 'Given a single goal, a short title optionally with a description, break it down to 3 to 8 concrete actionable subtasks that a solo operator could execute in order. '
  || 'Rules. '
  || 'Each subtask is a short imperative phrase, for example Draft the one-pager or Email the partner to confirm the meeting time. Do not number them. '
  || 'Order them logically with the earliest or blocking work first. '
  || 'Keep them specific to the goal and do not invent unrelated tasks. '
  || 'Match the goal language, so a Korean goal yields Korean subtasks and an English goal yields English subtasks. '
  || 'Optionally give each item a priority chosen from urgent, high, med, or low. '
  || 'Optionally give each item a due offset in whole days from today as a non-negative integer, and omit it when unsure. '
  || 'Output strict JSON only with no prose and no markdown code fences. '
  || 'The JSON is an object whose only key is subtasks, an array of objects. '
  || 'Each object has a required title string and an optional priority string and an optional due_offset_days integer. '
  || 'The context you receive is a JSON bundle and the goal text is under the key inbound_message.'
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

-- VERIFY: one task_decomposer per org
select organization_id, role, model, output_format, is_active
from ai.agents
where role = 'task_decomposer'
order by organization_id;
