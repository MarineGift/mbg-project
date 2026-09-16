-- ===========================================================================
--  migration_20260915l_normalize_websites.sql
--  URM - one website format, and a look at the duplicate party records it
--        exposes
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
--  STEP 1 rewrites data. STEPS 2-4 are read-only.
-- ---------------------------------------------------------------------------
--  WHY
--    app.parties.website holds a mix of formats:
--        https://www.oxy.com/      (older records)
--        oxy.com                   (rows filled this week)
--    Both work for the whitelist migration, which strips the scheme itself,
--    but any grouping by website under-reports: the duplicate check only
--    caught the pairs that happened to share the exact same string.
--
--    Normalising to the bare domain makes duplicates visible and keeps the
--    directory consistent.
--
--  WHAT THIS DOES NOT DO
--    It does not merge anything. Merging parties moves communications, deals,
--    contacts and meetings, and picking the survivor is a judgement call -
--    STEP 3 gives you the evidence to make it.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 - one format: lower case, no scheme, no www, no path
-- ---------------------------------------------------------------------------
update app.parties
   set website = nullif(
         split_part(
           split_part(
             regexp_replace(
               regexp_replace(lower(trim(website)), '^https?://', '', 'i'),
               '^www\.', '', 'i'
             ),
             '/', 1
           ),
           '?', 1
         ),
         ''
       ),
       updated_at = now()
 where deleted_at is null
   and coalesce(website, '') <> ''
   and website <> nullif(
         split_part(
           split_part(
             regexp_replace(
               regexp_replace(lower(trim(website)), '^https?://', '', 'i'),
               '^www\.', '', 'i'
             ),
             '/', 1
           ),
           '?', 1
         ),
         ''
       );

-- ---------------------------------------------------------------------------
-- STEP 2 - the real duplicate list, now that the format is uniform.
-- Expect MORE rows than before. Some are legitimate (DCVC / DCVC Bio,
-- TMC Innovation / TMC Venture Fund, the two UT Dallas centres) - different
-- organisations really do share a domain.
-- ---------------------------------------------------------------------------
select lower(p.website)                as domain,
       count(*)                        as parties,
       string_agg(p.party_name, ' | ' order by p.party_name) as names
from app.parties p
where p.deleted_at is null
  and coalesce(p.website, '') <> ''
group by domain
having count(*) > 1
order by parties desc, domain;

-- ---------------------------------------------------------------------------
-- STEP 3 - evidence for deciding which record survives a merge. For every
-- party sharing a domain: how much history hangs off it. Keep the row with the
-- mail and the deals; the empty twin is the one to retire.
-- ---------------------------------------------------------------------------
with dupes as (
  select lower(website) as domain
  from app.parties
  where deleted_at is null and coalesce(website, '') <> ''
  group by 1 having count(*) > 1
)
select lower(p.website) as domain,
       p.party_name,
       t.code                                   as party_type,
       p.id                                     as party_id,
       (select count(*) from app.communications c
         where c.party_id = p.id and c.deleted_at is null)      as messages,
       (select count(*) from app.contacts ct
         where ct.party_id = p.id)                              as contacts,
       (select count(*) from app.meetings m
         where m.party_id = p.id and m.deleted_at is null)      as meetings,
       p.created_at
from app.parties p
join dupes d on d.domain = lower(p.website)
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
order by domain, messages desc, contacts desc, p.created_at;

-- ---------------------------------------------------------------------------
-- STEP 4 - near-duplicate names that the domain check cannot catch, because
-- one of the two has no website at all. Case and spacing are ignored.
-- ---------------------------------------------------------------------------
select a.party_name as name_a,
       b.party_name as name_b,
       a.id         as id_a,
       b.id         as id_b,
       coalesce(a.website, '(none)') as website_a,
       coalesce(b.website, '(none)') as website_b
from app.parties a
join app.parties b
  on a.id < b.id
 and lower(regexp_replace(a.party_name, '[^a-zA-Z0-9]', '', 'g'))
   = lower(regexp_replace(b.party_name, '[^a-zA-Z0-9]', '', 'g'))
where a.deleted_at is null
  and b.deleted_at is null
order by name_a;

-- ---------------------------------------------------------------------------
-- MERGING, when you decide to. Do it in this order, in one go, per pair.
-- Replace KEEP and DROP with the two party_id values from STEP 3.
-- ---------------------------------------------------------------------------
-- update app.communications set party_id = 'KEEP' where party_id = 'DROP';
-- update app.contacts        set party_id = 'KEEP' where party_id = 'DROP';
-- update app.meetings        set party_id = 'KEEP' where party_id = 'DROP';
-- update app.mail_folders    set party_id = 'KEEP' where party_id = 'DROP';
-- update app.parties set deleted_at = now(), updated_at = now() where id = 'DROP';
--
-- Check for other tables pointing at the dropped party BEFORE running the
-- delete - deals, tasks and notes may reference it too:
-- select c.table_name, c.column_name
--   from information_schema.columns c
--  where c.table_schema = 'app' and c.column_name = 'party_id'
--  order by c.table_name;
