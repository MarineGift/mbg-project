-- ===========================================================================
--  repair_20260915_basf_vc_inbound.sql
--  URM - let BASF Venture Capital mail in, and make it replyable
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
--  Run the steps in order. STEP 5 is the one that actually pulls the mail in.
-- ---------------------------------------------------------------------------
--  THE PROBLEM, RESTATED
--    Joshua Speros wrote from joshua.speros@basf.com. The party record has
--    website basf-vc.com and the whitelist had basf-vc.com. basf.com is not a
--    subdomain of basf-vc.com, so the gate dropped the message before it was
--    stored - which is also why you cannot reply to it: there is nothing in
--    app.communications to reply to.
--
--    A corporate VC arm sending from the parent domain is the normal case, not
--    the exception. Greentown GRID introductions will keep producing it.
--
--  WHAT THIS DOES
--    1. whitelists basf.com
--    2. finds the BASF party
--    3. registers Joshua as a contact on it, so future mail links to the party
--       automatically (contacts.email is the FIRST thing the sender matcher
--       checks) and the reply composer has a recipient
--    4. pins basf.com on a mail folder if you keep one for investors
--    5. rewinds the mailbox cursor so the worker re-reads and stores the mail
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 - whitelist the sending domain
-- ---------------------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select p.organization_id, 'basf.com', 'domain',
       'BASF Venture Capital sends from the parent corporate domain', true
from app.parties p
where p.deleted_at is null
  and (p.website ilike '%basf%' or p.party_name ilike '%BASF%')
limit 1
on conflict (organization_id, pattern, kind) do nothing;

-- ---------------------------------------------------------------------------
-- STEP 2 - which party is BASF? Note the id for STEP 3 if more than one shows.
-- ---------------------------------------------------------------------------
select p.id, p.party_name, t.code as party_type, p.website, p.email
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and (p.party_name ilike '%BASF%' or p.website ilike '%basf%')
order by p.party_name;

-- ---------------------------------------------------------------------------
-- STEP 3 - register Joshua as a contact on that party.
-- This is what makes future mail land on the party by itself: the sender
-- matcher checks contacts.email exactly before anything else.
-- ---------------------------------------------------------------------------
insert into app.contacts (
  organization_id, party_id, contact_type_id,
  full_name, given_name, family_name,
  email, title_text, is_decision_maker, is_primary, is_active, source
)
select p.organization_id,
       p.id,
       (select id from app.contact_types order by id limit 1),
       'Joshua Speros', 'Joshua', 'Speros',
       'joshua.speros@basf.com',
       'Investment Manager, BASF Venture Capital',
       true, true, true,
       'greentown_grid_intro'
from app.parties p
where p.deleted_at is null
  and (p.party_name ilike '%BASF%' or p.website ilike '%basf%')
  and not exists (
    select 1 from app.contacts c
     where c.email = 'joshua.speros@basf.com'
       and c.deleted_at is null
  )
limit 1;

-- ---------------------------------------------------------------------------
-- STEP 4 - optional: pin basf.com on the Investors mail folder, if you keep
-- one. Skipped silently when no such folder exists.
-- ---------------------------------------------------------------------------
update app.mail_folders f
   set match_domains = (
         select array_agg(distinct x)
           from unnest(f.match_domains || array['basf.com']) x
       ),
       updated_at = now()
 where f.deleted_at is null
   and f.is_group
   and lower(f.label) = 'investors'
   and not ('basf.com' = any (select lower(d) from unnest(f.match_domains) d));

-- ---------------------------------------------------------------------------
-- STEP 5 - rewind the mailbox cursor so the worker re-reads recent messages.
-- Already-stored mail is skipped by the message_id duplicate check, so this
-- cannot create duplicates. Run STEP 5a first and use the username it shows.
-- ---------------------------------------------------------------------------
-- 5a (read-only)
select organization_id, kind, username, last_processed_uid, updated_at
from app.mailcarrier_state
order by kind, username;

-- 5b - uncomment, fill in the username, run
-- update app.mailcarrier_state
--    set last_processed_uid = greatest(last_processed_uid - 400, 0),
--        updated_at = now()
--  where username = 'PASTE-USERNAME-FROM-5a';

-- ---------------------------------------------------------------------------
-- STEP 6 - a few minutes after the worker's next tick, confirm it landed and
-- that it is attached to the party (that is what makes Reply work in URM).
-- ---------------------------------------------------------------------------
select c.id,
       c.occurred_at,
       c.from_address,
       c.subject,
       c.thread_id,
       p.party_name,
       ct.full_name as matched_contact
from app.communications c
left join app.parties p on p.id = c.party_id
left join app.contacts ct on ct.id = c.contact_id
where c.deleted_at is null
  and lower(c.from_address) like '%@basf.com'
order by c.occurred_at desc;

-- ---------------------------------------------------------------------------
-- STEP 7 - the wider pattern. Greentown GRID keeps introducing corporate VCs
-- that write from the parent domain. These are parties whose website domain
-- has never sent us anything, while a LOOKALIKE domain has. Worth a skim
-- every few weeks.
-- ---------------------------------------------------------------------------
select split_part(lower(c.from_address), '@', 2) as sender_domain,
       count(*)                                   as messages,
       max(c.occurred_at)                         as latest
from app.communications c
where c.deleted_at is null
  and c.direction = 'inbound'
  and c.party_id is null
  and exists (
    select 1 from app.parties p
     where p.deleted_at is null
       and coalesce(p.website, '') <> ''
       and split_part(lower(c.from_address), '@', 2) like
           '%' || split_part(regexp_replace(lower(p.website), '^https?://(www\.)?', ''), '.', 1) || '%'
  )
group by sender_domain
order by messages desc
limit 30;
