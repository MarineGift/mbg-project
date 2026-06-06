-- ============================================================
-- stage_playbooks.sql   (Feature B: Stage -> Checklist + Tasks)
-- Define, per pipeline stage, a template of checklist items and tasks. When a
-- deal ENTERS a stage (insert or stage change), those templates are auto-created
-- on the deal as deal_checklists + tasks. So "which checklist / which tasks at
-- each stage" is decided once, centrally, and applied automatically.
--
-- Reuses what already exists: app.deal_checklists, app.tasks (status 'pending',
-- priority low/medium/high), and the deals stage-change path. The trigger is
-- exception-safe: a bad playbook can NEVER block a stage move.
--
-- Idempotent: each materialised row is tagged extra_data.pb_cl / pb_task with
-- its template id, so a deal re-entering a stage never duplicates items.
-- Run in the Supabase SQL editor.
-- ============================================================

begin;

-- ---------- template tables ----------
create table if not exists app.stage_checklist_templates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null default app.current_organization_id(),
  stage_id        uuid not null references app.stages(id) on delete cascade,
  title           text not null,
  sort_order      int not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists ix_sct_stage on app.stage_checklist_templates (stage_id) where is_active;

create table if not exists app.stage_task_templates (
  id                    uuid primary key default gen_random_uuid(),
  organization_id       uuid not null default app.current_organization_id(),
  stage_id              uuid not null references app.stages(id) on delete cascade,
  checklist_template_id uuid references app.stage_checklist_templates(id) on delete set null,
  title                 text not null,
  description           text,
  default_priority      text not null default 'medium',   -- low/medium/high
  due_in_days           int not null default 3,
  sort_order            int not null default 0,
  is_active             boolean not null default true,
  created_at            timestamptz not null default now()
);
create index if not exists ix_stt_stage on app.stage_task_templates (stage_id) where is_active;

alter table app.stage_checklist_templates enable row level security;
alter table app.stage_task_templates      enable row level security;
drop policy if exists pol_sct_all on app.stage_checklist_templates;
create policy pol_sct_all on app.stage_checklist_templates for all
  using ((organization_id = app.current_organization_id()) or app.is_member_of_organization(organization_id))
  with check (organization_id = app.current_organization_id());
drop policy if exists pol_stt_all on app.stage_task_templates;
create policy pol_stt_all on app.stage_task_templates for all
  using ((organization_id = app.current_organization_id()) or app.is_member_of_organization(organization_id))
  with check (organization_id = app.current_organization_id());
grant select, insert, update, delete on app.stage_checklist_templates to authenticated, service_role;
grant select, insert, update, delete on app.stage_task_templates      to authenticated, service_role;

-- ---------- apply a stage's playbook to one deal (idempotent) ----------
create or replace function app.apply_stage_playbook(p_deal_id uuid, p_stage_id uuid)
returns void
language plpgsql
security definer
set search_path = app, public
as $$
declare
  v_org     uuid;
  ct        record;
  tt        record;
  v_link_cl uuid;
begin
  select coalesce(d.organization_id,
                  (select organization_id from app.stages where id = p_stage_id))
    into v_org from app.deals d where d.id = p_deal_id;
  if v_org is null then v_org := 'b25de8f2-1020-482f-9012-183f63883169'; end if;

  -- checklist items
  for ct in
    select * from app.stage_checklist_templates
    where stage_id = p_stage_id and is_active
    order by sort_order, created_at
  loop
    if not exists (
      select 1 from app.deal_checklists dc
      where dc.deal_id = p_deal_id and (dc.extra_data->>'pb_cl') = ct.id::text
    ) then
      insert into app.deal_checklists (organization_id, deal_id, title, sort_order, extra_data)
      values (v_org, p_deal_id, ct.title, ct.sort_order,
              jsonb_build_object('pb_cl', ct.id::text));
    end if;
  end loop;

  -- tasks (optionally linked to a checklist item materialised above)
  for tt in
    select * from app.stage_task_templates
    where stage_id = p_stage_id and is_active
    order by sort_order, created_at
  loop
    if not exists (
      select 1 from app.tasks t
      where t.deal_id = p_deal_id and (t.extra_data->>'pb_task') = tt.id::text
    ) then
      v_link_cl := null;
      if tt.checklist_template_id is not null then
        select dc.id into v_link_cl from app.deal_checklists dc
        where dc.deal_id = p_deal_id
          and (dc.extra_data->>'pb_cl') = tt.checklist_template_id::text
        limit 1;
      end if;
      insert into app.tasks
        (organization_id, deal_id, title, description, status, priority, due_at, checklist_id, extra_data)
      values
        (v_org, p_deal_id, tt.title, tt.description, 'pending', tt.default_priority,
         now() + (tt.due_in_days || ' days')::interval, v_link_cl,
         jsonb_build_object('pb_task', tt.id::text));
    end if;
  end loop;
end $$;

-- ---------- trigger: apply on stage entry (exception-safe) ----------
create or replace function app.fn_apply_stage_playbook()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $$
begin
  begin
    if (tg_op = 'INSERT') then
      perform app.apply_stage_playbook(new.id, new.current_stage_id);
    elsif (tg_op = 'UPDATE' and new.current_stage_id is distinct from old.current_stage_id) then
      perform app.apply_stage_playbook(new.id, new.current_stage_id);
    end if;
  exception when others then
    null;  -- a broken playbook must never block a stage change
  end;
  return null;
end $$;

drop trigger if exists trg_apply_stage_playbook on app.deals;
create trigger trg_apply_stage_playbook
  after insert or update on app.deals
  for each row execute function app.fn_apply_stage_playbook();

commit;

-- ============================================================
-- SEED: a sensible default playbook for every OPEN (non-terminal) stage,
-- across all pipelines. Idempotent (guarded by stage_id + title).
-- ============================================================

-- 2 checklist items per open stage
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select s.organization_id, s.id, v.title, v.ord
from app.stages s
cross join (values
  ('Confirm exit criteria for this stage', 1),
  ('Log latest notes and agree the next step', 2)
) as v(title, ord)
where s.is_active and not s.is_terminal
  and not exists (
    select 1 from app.stage_checklist_templates t where t.stage_id = s.id and t.title = v.title
  );

-- "Prepare for <stage>" task (high, due in 1 day)
insert into app.stage_task_templates (organization_id, stage_id, title, description, default_priority, due_in_days, sort_order)
select s.organization_id, s.id, 'Prepare for ' || s.name,
       'Get everything ready for the ' || s.name || ' stage.', 'high', 1, 1
from app.stages s
where s.is_active and not s.is_terminal
  and not exists (
    select 1 from app.stage_task_templates t where t.stage_id = s.id and t.title = 'Prepare for ' || s.name
  );

-- "Follow up - <stage>" task (medium, due in 3 days)
insert into app.stage_task_templates (organization_id, stage_id, title, description, default_priority, due_in_days, sort_order)
select s.organization_id, s.id, 'Follow up - ' || s.name,
       'Follow up to keep momentum in the ' || s.name || ' stage.', 'medium', 3, 2
from app.stages s
where s.is_active and not s.is_terminal
  and not exists (
    select 1 from app.stage_task_templates t where t.stage_id = s.id and t.title = 'Follow up - ' || s.name
  );

-- Tailored extras for the investor pipeline (best-effort match by stage name;
-- if your stage names differ these simply insert nothing - harmless).
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select s.organization_id, s.id, v.title, v.ord
from app.stages s
join app.pipelines p on p.id = s.pipeline_id and p.code = 'investors'
cross join lateral (
  select * from (values
    ('Due diligence', 'Share data room access',           3),
    ('Due diligence', 'Collect & answer DD question list', 4),
    ('Term sheet',    'Draft term sheet',                  3),
    ('Term sheet',    'Internal legal review',             4)
  ) as x(stage_match, title, ord)
  where s.name ilike '%' || x.stage_match || '%'
) v(stage_match, title, ord)
where s.is_active
  and not exists (select 1 from app.stage_checklist_templates t where t.stage_id = s.id and t.title = v.title);

-- ---------- one-time backfill: apply playbooks to existing deals ----------
do $$
declare d record;
begin
  for d in select id, current_stage_id from app.deals where deleted_at is null loop
    perform app.apply_stage_playbook(d.id, d.current_stage_id);
  end loop;
end $$;

-- ---------- verify ----------
select p.code as pipeline,
       count(distinct sct.id) as checklist_templates,
       count(distinct stt.id) as task_templates
from app.stages s
join app.pipelines p on p.id = s.pipeline_id
left join app.stage_checklist_templates sct on sct.stage_id = s.id
left join app.stage_task_templates      stt on stt.stage_id = s.id
group by p.code
order by p.code;
