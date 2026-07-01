-- ============================================================
-- 20260701160000_capital_factory_network.sql
-- Capture the Capital Factory relationship in URM (option 1: no Slack sync).
--
-- What it does (idempotent, one transaction, run in Supabase SQL Editor):
--   1) Creates a "Capital Factory (network)" CAMPAIGN (container), mirroring the
--      Pangaea seed campaign pattern (app.campaigns + app.campaign_materials).
--   2) Seeds a CF playbook CHECKLIST (app.campaign_materials): membership,
--      deck submission, All Access Fund, mentors, referrals, events.
--   3) Seeds the CF people as CONTACTS under the EXISTING "Capital Factory"
--      party (already in app.parties as a 'partner' from texas_startup_resources).
--      No duplicate party is created.
--
-- SaaS / multi-tenant standard: organization_id + created_by set explicitly
-- (the SQL Editor has no JWT, so auth.uid() would be null). Contacts are seeded
-- with email = NULL and is_primary = false so they NEVER enter any mailing pool;
-- if app.contacts.email is NOT NULL in this DB, the contact step self-skips and
-- prints a NOTICE (the campaign + checklist still apply). Fill emails later.
--
-- Idempotent: campaign uses a fixed id + ON CONFLICT DO NOTHING; checklist uses
-- ON CONFLICT (campaign_id, item_key) DO NOTHING; contacts use NOT EXISTS.
-- Safe to re-run. Railway does NOT auto-run this - APPLY IT IN THE SQL EDITOR.
-- ============================================================

begin;

-- ---------- 1) campaign (fixed id: ...fd, after Pangaea ...fe / General ...ff) ----------
insert into app.campaigns (id, organization_id, created_by, name, campaign_type, description, status) values
 ('d0000000-0000-4000-8000-0000000000fd',
  'b25de8f2-1020-482f-9012-183f63883169',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  'Capital Factory (network)',
  'network',
  'Austin resident member. Use CF for mentors + investor intros to support the seed round. All Access Fund ($100K / <=1%) + Ventures deck submission via capitalfactory.com/investors. Contact people are seeded under the existing Capital Factory party.',
  'active')
on conflict (id) do nothing;

-- ---------- 2) checklist (CF playbook) ----------
insert into app.campaign_materials (campaign_id, section, item_key, label, detail, status, sort_order) values
 ('d0000000-0000-4000-8000-0000000000fd','Membership','mem_247','Upgrade to 24/7 access','Dedicated-desk tier ($500/mo) with 24/7 keycard - requested via Caroline','in_progress',10),
 ('d0000000-0000-4000-8000-0000000000fd','Membership','onboarding','Onboarding with Caroline Vannuis','Community/onboarding contact - ask to be routed to Ventures + mentors','in_progress',20),
 ('d0000000-0000-4000-8000-0000000000fd','Deck & Investment','deck_submit','Submit deck to Ventures (capitalfactory.com/investors)','Share the Drive PDF link (Ver3_3_Share), NOT a Slides link. Subject like "Advanced Materials - 2 orders + top filler maker - US - Seed". Avoid the words pitch/deck/intro/opportunity.','not_started',110),
 ('d0000000-0000-4000-8000-0000000000fd','Deck & Investment','all_access_fund','All Access Fund - Nick Spiller','Model: $100K for max 1%. Get on his radar for the fund.','not_started',120),
 ('d0000000-0000-4000-8000-0000000000fd','Deck & Investment','texas_fund','Texas Fund (optional)','Frontier low-carbon materials framing; DexMat precedent. Ventures team.','not_started',130),
 ('d0000000-0000-4000-8000-0000000000fd','Mentors & Referrals','mentor_req','Post in #request-for-mentor','Fundraising/materials mentor before Jul 8; Gordon Daugherty fits.','not_started',210),
 ('d0000000-0000-4000-8000-0000000000fd','Mentors & Referrals','referrals','Post in #request-for-referrals','Warm intros: advanced materials / energy / sustainability investors.','not_started',220),
 ('d0000000-0000-4000-8000-0000000000fd','Events','cup_of_capital','Register: Cup of Capital (Jul 14)','w/ Antler, Tue 1:30PM - investor exposure right after Pangaea (Jul 8).','not_started',310)
on conflict (campaign_id, item_key) do nothing;

-- ---------- 3) CF people as contacts under the EXISTING Capital Factory party ----------
do $$
declare
  org   constant uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  owner constant uuid := '551fc4a0-b365-47eb-bf2f-0c3f594001c0';
  cf    uuid;
  ctype bigint;
  email_nullable boolean;
  has_title      boolean;
  r record;
begin
  -- existing Capital Factory party (do not duplicate)
  select id into cf
  from app.parties
  where party_name = 'Capital Factory'
    and organization_id = org
    and deleted_at is null
  order by id
  limit 1;

  if cf is null then
    raise notice 'Capital Factory party not found - skipped contacts (campaign + checklist still applied).';
    return;
  end if;

  -- safe contact_type_id (same coalesce pattern as the investor contact batches)
  select coalesce(
    (select id from app.contact_types
       where code in ('general','other','company','main','primary')
       order by sort_order limit 1),
    (select min(id) from app.contact_types)
  ) into ctype;

  select (is_nullable = 'YES') into email_nullable
  from information_schema.columns
  where table_schema='app' and table_name='contacts' and column_name='email';

  select exists(
    select 1 from information_schema.columns
    where table_schema='app' and table_name='contacts' and column_name='title'
  ) into has_title;

  if email_nullable is distinct from true then
    raise notice 'app.contacts.email is NOT NULL in this DB - CF contacts skipped. Provide emails and re-run to seed them (campaign + checklist already applied).';
    return;
  end if;

  for r in (
    values
      ('Caroline Vannuis','Community / Onboarding'),
      ('Nick Spiller','Managing Director, All Access Fund'),
      ('Jamie Serio','VP, Ventures'),
      ('Morgan Odell','Director of Ventures'),
      ('Luis Martinez','Venture Principal (deep-tech / science)'),
      ('Gordon Daugherty','Co-Founder & Chairman (fundraising mentor)')
  ) as t(nm, role)
  loop
    if not exists (
      select 1 from app.contacts c
      where c.party_id = cf and c.full_name = r.nm and c.deleted_at is null
    ) then
      if has_title then
        insert into app.contacts
          (party_id, organization_id, contact_type_id, full_name, title, email, is_primary, is_active, source, created_by)
        values
          (cf, org, ctype, r.nm, r.role, null, false, true, 'capital_factory_slack_2026', owner);
      else
        insert into app.contacts
          (party_id, organization_id, contact_type_id, full_name, email, is_primary, is_active, source, created_by)
        values
          (cf, org, ctype, r.nm, null, false, true, 'capital_factory_slack_2026', owner);
      end if;
    end if;
  end loop;
end $$;

commit;

-- ---------- verify ----------
select 'campaign' as kind, name as detail
from app.campaigns where id='d0000000-0000-4000-8000-0000000000fd'
union all
select 'checklist items', count(*)::text
from app.campaign_materials where campaign_id='d0000000-0000-4000-8000-0000000000fd'
union all
select 'CF contacts', count(*)::text
from app.contacts c
join app.parties p on p.id=c.party_id
where p.party_name='Capital Factory' and c.deleted_at is null;
