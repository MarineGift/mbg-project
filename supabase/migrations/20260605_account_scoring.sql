-- ============================================================
-- account_scoring.sql   (Feature A: ABM account scoring)
-- Scores EVERY known account (app.parties) 0..100 from signals we already
-- have, and assigns an A/B/C tier so you can prioritise outreach by score.
-- This is account-based (your customers are already known) - NOT inbound lead
-- capture. Fit/ICP points let a COLD-but-good-fit account still rank above an
-- empty one, which is the whole point of "attack by tier".
--
-- Model (0..100):
--   Fit/ICP        0..30   profile row exists (+15), website (+8), country (+7)
--   Recency        0..25   days since last engagement/meeting
--   Frequency      0..15   engagements in last 90d
--   Meetings       0..15   meetings in last 90d
--   Deal momentum  0..15   in an open (non-terminal) deal + stage probability
--   Tier:  A >= 60   B 30..59   C < 30
--
-- Run in the Supabase SQL editor. Idempotent. Re-run any time to recompute.
-- ============================================================

begin;

-- ---------- storage (one current score per account) ----------
create table if not exists app.account_scores (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null default app.current_organization_id(),
  party_id        uuid not null references app.parties(id) on delete cascade,
  score           numeric not null default 0,     -- 0..100
  tier            text not null default 'C',       -- A / B / C
  recency_pts     numeric not null default 0,
  frequency_pts   numeric not null default 0,
  meeting_pts     numeric not null default 0,
  deal_pts        numeric not null default 0,
  fit_pts         numeric not null default 0,
  factors         jsonb not null default '{}'::jsonb,
  computed_at     timestamptz not null default now(),
  unique (organization_id, party_id)
);
create index if not exists ix_account_scores_org_score
  on app.account_scores (organization_id, score desc);

alter table app.account_scores enable row level security;
drop policy if exists pol_account_scores_all on app.account_scores;
create policy pol_account_scores_all on app.account_scores
  for all
  using ((organization_id = app.current_organization_id())
         or app.is_member_of_organization(organization_id))
  with check (organization_id = app.current_organization_id());
grant select, insert, update, delete on app.account_scores to authenticated, service_role;

-- ---------- per-account scorer (also usable on-demand) ----------
create or replace function app.recompute_account_score(p_party_id uuid)
returns numeric
language plpgsql
security definer
set search_path = app, public
as $$
declare
  v_org      uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  p          record;
  v_last_eng timestamptz;
  v_last_mtg timestamptz;
  v_last     timestamptz;
  v_days     numeric;
  v_eng90    int := 0;
  v_mtg90    int := 0;
  v_has_open boolean := false;
  v_maxprob  numeric := 0;
  v_recency  numeric := 0;
  v_freq     numeric := 0;
  v_mtg      numeric := 0;
  v_deal     numeric := 0;
  v_fit      numeric := 0;
  v_total    numeric := 0;
  v_tier     text;
begin
  select id, coalesce(organization_id, v_org) as org, country_code, website
    into p from app.parties where id = p_party_id and deleted_at is null;
  if not found then return null; end if;
  v_org := p.org;

  select max(occurred_at) into v_last_eng
    from app.engagements where party_id = p_party_id and deleted_at is null;
  select max(scheduled_at) into v_last_mtg
    from app.meetings where party_id = p_party_id;
  v_last := greatest(v_last_eng, v_last_mtg);
  if v_last is not null then
    v_days := extract(epoch from (now() - v_last)) / 86400.0;
    v_recency := case when v_days <= 7 then 25 when v_days <= 30 then 17
                      when v_days <= 90 then 8 else 0 end;
  end if;

  select count(*) into v_eng90 from app.engagements
    where party_id = p_party_id and deleted_at is null
      and occurred_at >= now() - interval '90 days';
  v_freq := least(v_eng90 * 3, 15);

  select count(*) into v_mtg90 from app.meetings
    where party_id = p_party_id and scheduled_at >= now() - interval '90 days';
  v_mtg := least(v_mtg90 * 8, 15);

  select bool_or(not s.is_terminal), coalesce(max(s.default_probability_pct), 0)
    into v_has_open, v_maxprob
  from app.deal_parties dp
  join app.deals  d on d.id = dp.deal_id and d.deleted_at is null
  join app.stages s on s.id = d.current_stage_id
  where dp.party_id = p_party_id;
  if coalesce(v_has_open, false) then
    v_deal := least(7 + round(coalesce(v_maxprob, 0) * 0.08), 15);
  end if;

  if exists (select 1 from app.investor_profile        x where x.party_id = p_party_id)
   or exists (select 1 from app.paper_mill_profile      x where x.party_id = p_party_id)
   or exists (select 1 from app.filler_supplier_profile x where x.party_id = p_party_id)
  then v_fit := v_fit + 15; end if;
  if p.website is not null and length(trim(p.website)) > 0 then v_fit := v_fit + 8; end if;
  if p.country_code is not null then v_fit := v_fit + 7; end if;

  v_total := least(v_recency + v_freq + v_mtg + v_deal + v_fit, 100);
  v_tier  := case when v_total >= 60 then 'A' when v_total >= 30 then 'B' else 'C' end;

  insert into app.account_scores
    (organization_id, party_id, score, tier, recency_pts, frequency_pts,
     meeting_pts, deal_pts, fit_pts, factors, computed_at)
  values
    (v_org, p_party_id, v_total, v_tier, v_recency, v_freq, v_mtg, v_deal, v_fit,
     jsonb_build_object('fit', v_fit, 'recency', v_recency, 'frequency', v_freq,
       'meetings', v_mtg, 'deal', v_deal, 'eng90', v_eng90, 'mtg90', v_mtg90,
       'days_since_last', round(coalesce(v_days, 9999))),
     now())
  on conflict (organization_id, party_id) do update set
    score = excluded.score, tier = excluded.tier,
    recency_pts = excluded.recency_pts, frequency_pts = excluded.frequency_pts,
    meeting_pts = excluded.meeting_pts, deal_pts = excluded.deal_pts,
    fit_pts = excluded.fit_pts, factors = excluded.factors, computed_at = excluded.computed_at;

  return v_total;
end $$;

-- ---------- bulk recompute (optionally one party_type at a time) ----------
create or replace function app.recompute_all_account_scores(p_type text default null)
returns int
language plpgsql
security definer
set search_path = app, public
as $$
declare r record; n int := 0;
begin
  for r in
    select pp.id
    from app.parties pp
    join app.party_types pt on pt.id = pp.party_type_id
    where pp.deleted_at is null
      and (p_type is null or pt.code = p_type)
  loop
    perform app.recompute_account_score(r.id);
    n := n + 1;
  end loop;
  return n;
end $$;

-- ---------- read model for the UI (party + score + tier) ----------
create or replace view app.v_account_scores as
select s.party_id, p.party_name, pt.code as party_type, p.country_code,
       s.score, s.tier, s.fit_pts, s.recency_pts, s.frequency_pts,
       s.meeting_pts, s.deal_pts, s.factors, s.computed_at, s.organization_id
from app.account_scores s
join app.parties p     on p.id = s.party_id
join app.party_types pt on pt.id = p.party_type_id;

commit;

-- ---------- run it now (all known accounts) ----------
select app.recompute_all_account_scores() as accounts_scored;

-- ---------- verify: tier distribution per type ----------
select party_type, tier, count(*) as n, round(avg(score),1) as avg_score
from app.v_account_scores
group by party_type, tier
order by party_type, tier;
