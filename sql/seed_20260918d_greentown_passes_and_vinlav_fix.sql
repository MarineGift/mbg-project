-- ============================================================
-- seed_20260918d_greentown_passes_and_vinlav_fix.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Two things, both from Will McCallum's 2026-09-18 update.
--
-- A) Fifteen investors passed on the Greentown GRID requests. Recording
--    them as Seed deals at the `passed` stage, with the stated reason,
--    does three things: it stops anyone re-contacting them, it keeps the
--    reasons where they are read, and it makes the round's conversion
--    rate real rather than a guess.
--    `passed` is terminal, so the inbound automation can never drag these
--    back to Engaged on an auto-reply.
--
-- B) Vinlav Group LLC is a new introduction that arrived the same day.
--    Venkat Madabusi writes from a gmail address, which the inbound
--    matcher skips as a generic domain, so an exact-address contact and a
--    kind='address' whitelist entry are the only way his mail attaches to
--    the party.
--
-- Replaces seed_20260918c_..., which failed on
--   null value in column organization_id of relation deal_parties
-- app.deal_parties.organization_id defaults to app.current_organization_id(),
-- and that function returns NULL in the Supabase SQL editor, which runs as
-- postgres with no auth.uid(). Every insert in this file now sets the
-- organization explicitly. The editor wraps the file in one transaction, so
-- the earlier attempt left nothing behind; this redoes all of it.
--
-- Idempotent throughout.
-- ============================================================


-- ------------------------------------------------------------
-- A1) Seed deals at `passed` for the fifteen
--     TDK is matched on the exact name -- there are two TDK rows and
--     only one should receive the deal.
-- ------------------------------------------------------------
insert into app.deals
  (organization_id, party_id, pipeline_id, current_stage_id,
   deal_name, campaign_id, round_id, source, won_lost_reason)
select p.organization_id,
       p.id,
       (select pl.id from app.pipelines pl where pl.code = 'investors'),
       (select s.id from app.stages s
         join app.pipelines pl2 on pl2.id = s.pipeline_id
        where pl2.code = 'investors' and s.code = 'passed'),
       p.party_name || ' - Seed 2026',
       (select c.id from app.campaigns c
         where c.name = 'Seed 2026 - Greentown Warm Intro'
           and c.organization_id = p.organization_id),
       (select r.id from app.rounds r
         where r.name = 'MarineBio Group, Inc. 2026 Seed Round'
           and r.organization_id = p.organization_id),
       'greentown_grid_request',
       v.reason
from (values
  ('Energy Transition Ventures', 'Not an area of focus for them.'),
  ('Streetlife Ventures',        'Focus on urban applications; the paper value chain does not fit their mandate.'),
  ('Transition VC',              'Not a fit at this time.'),
  ('TerraForge Capital',         'Not a fit.'),
  ('Clean Energy Venture Group', 'Not a fit for their energy and GHG focused thesis. Suggested trying Chemical Angels instead -- already in progress.'),
  ('Impact Engine',              'Focused on co-investing in their existing portfolio right now.'),
  ('Avila VC',                   'Too narrow a use case for their mandate.'),
  ('GVP Climate',                'Too early stage for them right now. Worth revisiting at Series A.'),
  ('TDK Ventures',               'Only invests in semiconductor and electronics materials.'),
  ('Reuseful Ventures',          'Focused on a handful of existing projects at the moment.'),
  ('Myriad Venture Partners',    'Not a fit.'),
  ('TechU Ventures',             'Not investing in this space.'),
  ('Eunike Ventures',            'Currently focused on AI, power generation and CCS.'),
  ('Tyson Associates',           'Passing, but suggested reaching out to Clean Energy Ventures Group -- who also passed. Circular referral.'),
  ('Convergent Ventures',        'Thesis fit not strong enough; they focus on AI applied to fundamental sciences.')
) as v(name, reason)
join app.parties p
  on p.deleted_at is null
 and p.party_name = v.name
where not exists (
  select 1 from app.deals d
  where d.deleted_at is null
    and d.party_id = p.id
    and d.round_id = (select r.id from app.rounds r
                       where r.name = 'MarineBio Group, Inc. 2026 Seed Round'
                         and r.organization_id = p.organization_id)
);


-- ------------------------------------------------------------
-- A2) link each new deal to its company
-- ------------------------------------------------------------
insert into app.deal_parties (organization_id, deal_id, party_id, role)
select d.organization_id, d.id, d.party_id, 'lead'
from app.deals d
where d.deleted_at is null
  and d.source = 'greentown_grid_request'
  and not exists (
    select 1 from app.deal_parties dp
    where dp.deal_id = d.id and dp.party_id = d.party_id
  );


-- ------------------------------------------------------------
-- B1) Vinlav Group LLC
-- ------------------------------------------------------------
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id,
   country_code, status, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169',
       'Vinlav Group LLC',
       (select id from app.party_types where code in ('investor', 'investors') limit 1),
       (select min(id) from app.entity_types),
       'US',
       'active',
       'greentown_climatetech_2026',
       'Introduced by Will McCallum at Greentown on 2026-09-18. Venkat Madabusi reached out after reviewing the MarineBio profile and asked for time slots for an introductory call. No Grid investment profile captured yet -- fund type, stage and cheque size unknown.'
where not exists (
  select 1 from app.parties
  where deleted_at is null and party_name = 'Vinlav Group LLC'
);


-- ------------------------------------------------------------
-- B2) Venkat Madabusi -- gmail, so the exact address is what matters
-- ------------------------------------------------------------
insert into app.contacts
  (organization_id, party_id, contact_type_id,
   full_name, given_name, family_name, email,
   is_primary, is_active, source, notes)
select p.organization_id,
       p.id,
       coalesce(
         (select ct.id from app.contact_types ct
           where ct.code in ('primary', 'contact', 'general') limit 1),
         (select min(ct.id) from app.contact_types ct)
       ),
       'Venkat Madabusi', 'Venkat', 'Madabusi',
       'venkat.madabusi@gmail.com',
       true, true,
       'greentown_warm_intro_2026',
       'Asked on 2026-09-18 for a few available time slots for a brief introductory call. Writes from a personal gmail address, so party matching depends on this exact-address contact row.'
from app.parties p
where p.deleted_at is null
  and p.party_name = 'Vinlav Group LLC'
  and not exists (
    select 1 from app.contacts c
    where c.organization_id = p.organization_id
      and lower(c.email) = 'venkat.madabusi@gmail.com'
      and c.deleted_at is null
  );


-- ------------------------------------------------------------
-- B3) whitelist that one address (kind 'address', not the gmail domain)
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169',
       'venkat.madabusi@gmail.com',
       'address',
       'auto: investor contact address (Vinlav Group)',
       true
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and lower(w.pattern) = 'venkat.madabusi@gmail.com'
);


-- ------------------------------------------------------------
-- B4) Seed deal for Vinlav, at Engaged -- they replied
-- ------------------------------------------------------------
insert into app.deals
  (organization_id, party_id, pipeline_id, current_stage_id,
   deal_name, campaign_id, round_id, source)
select p.organization_id,
       p.id,
       (select pl.id from app.pipelines pl where pl.code = 'investors'),
       (select s.id from app.stages s
         join app.pipelines pl2 on pl2.id = s.pipeline_id
        where pl2.code = 'investors' and s.code = 'reply_received'),
       'Vinlav Group - Seed 2026',
       (select c.id from app.campaigns c
         where c.name = 'Seed 2026 - Greentown Warm Intro'
           and c.organization_id = p.organization_id),
       (select r.id from app.rounds r
         where r.name = 'MarineBio Group, Inc. 2026 Seed Round'
           and r.organization_id = p.organization_id),
       'greentown_warm_intro'
from app.parties p
where p.deleted_at is null
  and p.party_name = 'Vinlav Group LLC'
  and not exists (
    select 1 from app.deals d
    where d.deleted_at is null
      and d.party_id = p.id
      and d.deal_name = 'Vinlav Group - Seed 2026'
  );

insert into app.deal_parties (organization_id, deal_id, party_id, role)
select d.organization_id, d.id, d.party_id, 'lead'
from app.deals d
where d.deleted_at is null
  and d.deal_name = 'Vinlav Group - Seed 2026'
  and not exists (
    select 1 from app.deal_parties dp
    where dp.deal_id = d.id and dp.party_id = d.party_id
  );


-- ------------------------------------------------------------
-- Verification -- the Seed round funnel
-- ------------------------------------------------------------
select s.name as stage,
       count(*) as deals,
       string_agg(pa.party_name, ', ' order by pa.party_name) as parties
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.parties pa on pa.id = d.party_id
where d.deleted_at is null
  and d.round_id = (select r.id from app.rounds r
                     where r.name = 'MarineBio Group, Inc. 2026 Seed Round')
group by s.name, s.sort_order
order by s.sort_order;
