-- ============================================================
-- Campaign grouping for INDEPENDENT deals (Case 1)
-- Many deals progress on their own stage/amount, but roll up
-- under one campaign for reporting/filtering.
--   e.g. "2026-05 Filler sales", "2026 Series A fundraising"
-- ------------------------------------------------------------
-- CONFIRM 3 TOKENS BEFORE RUNNING (adjust if your schema differs):
--   1) deals table name      -> app.deals   (swap to app.engagements if that is canonical)
--   2) organization FK target -> app.organizations(id)
--   3) RLS org expression     -> must match your existing app.* policy style
-- ============================================================

-- 1) campaigns table -----------------------------------------
create table if not exists app.campaigns (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references app.organizations(id) on delete cascade,
  name            text not null,
  -- free text on purpose (no enum): 'filler_sales', 'fundraising', ...
  campaign_type   text,
  description     text,
  -- 'active' | 'closed' | 'archived' (plain text, extend freely)
  status          text not null default 'active',
  start_date      date,
  end_date        date,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_campaigns_org
  on app.campaigns (organization_id);

-- 2) link deals -> campaign (nullable) -----------------------
-- A deal may belong to no campaign; deleting a campaign just
-- detaches its deals (set null), it does NOT delete deals.
alter table app.deals
  add column if not exists campaign_id uuid
  references app.campaigns(id) on delete set null;

create index if not exists idx_deals_campaign
  on app.deals (campaign_id);

-- 3) updated_at trigger (self-contained, unique name) --------
create or replace function app.campaigns_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_campaigns_updated_at on app.campaigns;
create trigger trg_campaigns_updated_at
  before update on app.campaigns
  for each row execute function app.campaigns_set_updated_at();

-- 4) RLS: org isolation --------------------------------------
-- Adjust the expression to match your existing 100+ policies
-- (e.g. if you use a helper like app.current_org_id()).
alter table app.campaigns enable row level security;

drop policy if exists campaigns_org_isolation on app.campaigns;
create policy campaigns_org_isolation on app.campaigns
  for all
  using      (organization_id = (auth.jwt() ->> 'organization_id')::uuid)
  with check (organization_id = (auth.jwt() ->> 'organization_id')::uuid);
