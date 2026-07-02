-- ============================================================================
-- 20260702000000_stage_automation_triggers.sql
-- Pipeline stage automation (all pipelines, data-driven via stage flags)
--
-- What this does:
--   1. Adds 3 automation flag columns to app.stages:
--        auto_on_outbound  -> target stage when an outbound email is sent
--        auto_on_inbound   -> target stage when an inbound reply arrives
--        auto_on_meeting   -> target stage when a meeting is scheduled
--   2. Investors pipeline: inserts `backlog` (sort 1) and `warm_intro`
--      (sort 3), resequences existing stages, sets flags:
--        backlog(1) -> cold_outreach(2, outbound) / warm_intro(3, manual)
--        -> reply_received(4, inbound) -> first_meeting(5, meeting)
--        -> due_diligence(6) -> followup_meeting(7) -> term_sheet(8)
--        -> contract(9)
--   3. Other pipelines (same mechanism, conservative seed):
--        crowdfunding.outreach      -> auto_on_outbound
--        filler_suppliers.contacted -> auto_on_outbound
--      (paper_mill / government_grant left unflagged; enable any time
--       with a one-line UPDATE, the triggers pick it up instantly.)
--   4. Creates AFTER INSERT triggers on app.communications and
--      app.meetings that advance matching deals FORWARD ONLY
--      (target sort_order must be greater than current; terminal and
--      deleted deals are never touched). Every move is logged to
--      app.deal_stage_history with notes = 'auto: ...'.
--   5. One-time backfill for this org: applies inbound-reply and
--      meeting rules to historical data (e.g. Pangaea -> first_meeting).
--
-- Multi-tenant safety: triggers scope every lookup/update by the
-- organization_id of the NEW row. No GRANT to anon anywhere.
-- Idempotent: re-running is a no-op.
-- New-deal default: campaigns pick min(sort_order) stage, so new deals
-- start in `backlog` automatically (no code change needed).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) Flag columns
-- ----------------------------------------------------------------------------
alter table app.stages add column if not exists auto_on_outbound boolean not null default false;
alter table app.stages add column if not exists auto_on_inbound  boolean not null default false;
alter table app.stages add column if not exists auto_on_meeting  boolean not null default false;

-- ----------------------------------------------------------------------------
-- 2) Investors pipeline: resequence + insert backlog / warm_intro
-- ----------------------------------------------------------------------------
do $$
declare
  v_org uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_pipeline uuid;
begin
  select id into v_pipeline
  from app.pipelines
  where organization_id = v_org and code = 'investors';

  if v_pipeline is null then
    raise notice 'investors pipeline not found - skipping stage seed';
    return;
  end if;

  -- resequence existing stages to their new slots (idempotent)
  update app.stages s
  set sort_order = v.new_sort
  from (values
    ('cold_outreach', 2),
    ('reply_received', 4),
    ('first_meeting', 5),
    ('due_diligence', 6),
    ('followup_meeting', 7),
    ('term_sheet', 8),
    ('contract', 9)
  ) as v(code, new_sort)
  where s.pipeline_id = v_pipeline
    and s.code = v.code
    and s.sort_order is distinct from v.new_sort;

  -- backlog (sort 1)
  insert into app.stages
    (organization_id, pipeline_id, code, name, description, sort_order,
     default_probability_pct, is_terminal, is_won, is_lost, color_hex, is_active)
  select v_org, v_pipeline, 'backlog', 'Backlog',
         'Registered (e.g. via campaign) but not yet contacted', 1,
         0, false, false, false, '#94A3B8', true
  where not exists (
    select 1 from app.stages
    where pipeline_id = v_pipeline and code = 'backlog'
  );

  -- warm_intro (sort 3, parallel entry path; manual placement only)
  insert into app.stages
    (organization_id, pipeline_id, code, name, description, sort_order,
     default_probability_pct, is_terminal, is_won, is_lost, color_hex, is_active)
  select v_org, v_pipeline, 'warm_intro', 'Warm intro',
         'Introduced through a warm connection (manual stage)', 3,
         15, false, false, false, '#F59E0B', true
  where not exists (
    select 1 from app.stages
    where pipeline_id = v_pipeline and code = 'warm_intro'
  );

  -- automation flags (investors)
  update app.stages set auto_on_outbound = true
  where pipeline_id = v_pipeline and code = 'cold_outreach' and auto_on_outbound = false;

  update app.stages set auto_on_inbound = true
  where pipeline_id = v_pipeline and code = 'reply_received' and auto_on_inbound = false;

  update app.stages set auto_on_meeting = true
  where pipeline_id = v_pipeline and code = 'first_meeting' and auto_on_meeting = false;
end $$;

-- ----------------------------------------------------------------------------
-- 3) Conservative flags for other pipelines (same mechanism)
-- ----------------------------------------------------------------------------
update app.stages s
set auto_on_outbound = true
from app.pipelines p
where s.pipeline_id = p.id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (
    (p.code = 'crowdfunding' and s.code = 'outreach')
    or (p.code = 'filler_suppliers' and s.code = 'contacted')
  )
  and s.auto_on_outbound = false;

-- ----------------------------------------------------------------------------
-- 4) Core advance function + triggers
-- ----------------------------------------------------------------------------
create or replace function app.fn_auto_advance_deals(
  p_org     uuid,
  p_deal_id uuid,
  p_party_id uuid,
  p_flag    text,   -- 'outbound' | 'inbound' | 'meeting'
  p_actor   uuid,
  p_note    text
) returns void
language plpgsql
security definer
set search_path = app, public
as $$
declare
  r        record;
  v_target record;
begin
  if p_org is null then return; end if;
  if p_deal_id is null and p_party_id is null then return; end if;

  for r in
    select d.id, d.pipeline_id, d.current_stage_id, s.sort_order as cur_sort
    from app.deals d
    join app.stages s on s.id = d.current_stage_id
    where d.organization_id = p_org
      and d.deleted_at is null
      and s.is_terminal = false
      and (
        d.id = p_deal_id
        or (
          p_deal_id is null
          and p_party_id is not null
          and (
            d.party_id = p_party_id
            or exists (
              select 1 from app.deal_parties dp
              where dp.deal_id = d.id and dp.party_id = p_party_id
            )
          )
        )
      )
  loop
    select s2.id, s2.sort_order
      into v_target
    from app.stages s2
    where s2.pipeline_id = r.pipeline_id
      and s2.is_active = true
      and (
        (p_flag = 'outbound' and s2.auto_on_outbound)
        or (p_flag = 'inbound' and s2.auto_on_inbound)
        or (p_flag = 'meeting' and s2.auto_on_meeting)
      )
    order by s2.sort_order asc
    limit 1;

    -- forward-only: never move a deal backwards or sideways
    if v_target.id is not null and v_target.sort_order > r.cur_sort then
      update app.deals
      set current_stage_id = v_target.id,
          stage_entered_at = now(),
          last_activity_at = now(),
          updated_at       = now()
      where id = r.id;

      insert into app.deal_stage_history
        (deal_id, from_stage_id, to_stage_id, changed_at, changed_by, notes, organization_id)
      values
        (r.id, r.current_stage_id, v_target.id, now(), p_actor, p_note, p_org);
    end if;
  end loop;
end;
$$;

-- communications -> outbound / inbound rules
create or replace function app.trg_comm_auto_stage()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $$
begin
  if new.deleted_at is not null then return new; end if;

  if new.direction::text = 'outbound' then
    perform app.fn_auto_advance_deals(
      new.organization_id, new.deal_id, new.party_id,
      'outbound', coalesce(new.sent_by_user_id, new.created_by),
      'auto: outbound email sent');
  elsif new.direction::text = 'inbound' then
    perform app.fn_auto_advance_deals(
      new.organization_id, new.deal_id, new.party_id,
      'inbound', new.created_by,
      'auto: reply received');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_communications_auto_stage on app.communications;
create trigger trg_communications_auto_stage
after insert on app.communications
for each row execute function app.trg_comm_auto_stage();

-- meetings -> meeting rule
create or replace function app.trg_meeting_auto_stage()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $$
begin
  if new.deleted_at is not null then return new; end if;
  if new.status::text in ('cancelled', 'canceled') then return new; end if;

  perform app.fn_auto_advance_deals(
    new.organization_id, new.engagement_id, new.party_id,
    'meeting', coalesce(new.created_by, new.user_id),
    'auto: meeting scheduled');

  return new;
end;
$$;

drop trigger if exists trg_meetings_auto_stage on app.meetings;
create trigger trg_meetings_auto_stage
after insert on app.meetings
for each row execute function app.trg_meeting_auto_stage();

-- ----------------------------------------------------------------------------
-- 5) One-time backfill (this org): apply inbound + meeting rules to history
--    (forward-only guard makes this safe to re-run)
-- ----------------------------------------------------------------------------
do $$
declare
  v_org uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  c record;
begin
  for c in
    select distinct organization_id, deal_id, party_id
    from app.communications
    where organization_id = v_org
      and direction::text = 'inbound'
      and deleted_at is null
      and (deal_id is not null or party_id is not null)
  loop
    perform app.fn_auto_advance_deals(
      c.organization_id, c.deal_id, c.party_id,
      'inbound', null, 'backfill: reply received');
  end loop;

  for c in
    select organization_id, engagement_id, party_id
    from app.meetings
    where organization_id = v_org
      and deleted_at is null
      and status::text not in ('cancelled', 'canceled')
  loop
    perform app.fn_auto_advance_deals(
      c.organization_id, c.engagement_id, c.party_id,
      'meeting', null, 'backfill: meeting scheduled');
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- Verify
-- ----------------------------------------------------------------------------
-- select p.code, s.sort_order, s.code, s.name,
--        s.auto_on_outbound, s.auto_on_inbound, s.auto_on_meeting,
--        count(d.id) as deals
-- from app.pipelines p
-- join app.stages s on s.pipeline_id = p.id
-- left join app.deals d on d.current_stage_id = s.id and d.deleted_at is null
-- where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
-- group by p.code, p.sort_order, s.sort_order, s.code, s.name,
--          s.auto_on_outbound, s.auto_on_inbound, s.auto_on_meeting
-- order by p.sort_order, s.sort_order;
--
-- select h.changed_at, d.deal_name, sf.name as from_stage, st.name as to_stage, h.notes
-- from app.deal_stage_history h
-- join app.deals d on d.id = h.deal_id
-- left join app.stages sf on sf.id = h.from_stage_id
-- join app.stages st on st.id = h.to_stage_id
-- where h.notes like 'backfill:%' or h.notes like 'auto:%'
-- order by h.changed_at desc limit 30;
