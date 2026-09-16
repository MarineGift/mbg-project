-- ===========================================================================
--  migration_20260915f_gov_whitelist.sql
--  URM - accept every .gov sender, and give government mail its own folder
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Pairs with the whitelist.ts change in the same commit: a domain pattern
--  starting with a dot is now a SUFFIX match. Run the SQL AFTER that deploy,
--  or '.gov' sits inactive in the table doing nothing.
--
--  WHAT THIS DOES
--    1. Whitelists '.gov' (suffix) so uscis.dhs.gov, nist.gov, mail.house.gov
--       and every other subdomain is accepted on ingest.
--    2. Creates a 'Government' folder group and pins the agency domains that
--       already appear in the mailbox, so government mail is separated from
--       Partners / Investors / Business instead of being classified as a party.
--
--  NOTE ON HISTORY
--    The whitelist is an ingest gate: mail that was rejected earlier was never
--    written to app.communications, so there is nothing to backfill. Only mail
--    arriving from now on appears. If an old .gov message matters, forward it
--    into the mailbox again.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- 1) whitelist every .gov sender -------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select org.id, '.gov', 'domain',
       'Suffix rule: accept every US government domain and subdomain', true
from (
  select coalesce(
    (select organization_id from app.email_whitelist limit 1),
    (select organization_id from app.mail_folders where deleted_at is null limit 1),
    (select id from app.organizations limit 1)
  ) as id
) org
where org.id is not null
  and not exists (
    select 1 from app.email_whitelist w
     where w.organization_id = org.id
       and lower(w.pattern) = '.gov'
       and w.kind = 'domain'
  );

-- 2) a Government group, parallel to Partners / Investors / Business --------
insert into app.mail_folders (organization_id, party_id, label, color, is_group, sort_order)
select org.id, null, 'Government', '#64748b', true, 3
from (
  select coalesce(
    (select organization_id from app.mail_folders where deleted_at is null limit 1),
    (select id from app.organizations limit 1)
  ) as id
) org
where org.id is not null
  and not exists (
    select 1 from app.mail_folders f
     where f.is_group and f.deleted_at is null and lower(f.label) = 'government'
  );

-- 3) pin the .gov domains already seen in the mailbox onto that group -------
--    A group can carry domains itself - no party row needed, which is the
--    point: a regulator is not a party you do business with.
update app.mail_folders g
   set match_domains = coalesce(
         (select array_agg(distinct d)
            from (
              select split_part(lower(c.from_address), '@', 2) as d
                from app.communications c
               where c.deleted_at is null
                 and c.organization_id = g.organization_id
                 and split_part(lower(c.from_address), '@', 2) like '%.gov'
              union
              select unnest(g.match_domains)
            ) s
           where d is not null and d <> ''),
         '{}'::text[]
       ),
       updated_at = now()
 where g.is_group
   and g.deleted_at is null
   and lower(g.label) = 'government';

-- ---------------------------------------------------------------------------
-- VERIFY 1 - the whitelist as the worker now sees it
-- ---------------------------------------------------------------------------
select pattern, kind, is_active, notes
from app.email_whitelist
order by kind, pattern;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - .gov senders already in the mailbox, and which agency they are.
-- Whatever shows here is what the Government folder now holds.
-- ---------------------------------------------------------------------------
select split_part(lower(from_address), '@', 2) as agency_domain,
       count(*)                                as messages,
       max(occurred_at)                        as latest
from app.communications
where deleted_at is null
  and split_part(lower(from_address), '@', 2) like '%.gov'
group by agency_domain
order by messages desc;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - the folder tree, to confirm Government sits beside the others
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name) as folder,
       case when f.is_group then 'group' else 'party' end as kind,
       coalesce(g.label, '-') as parent,
       f.match_domains
from app.mail_folders f
left join app.parties p on p.id = f.party_id
left join app.mail_folders g on g.id = f.parent_id
where f.deleted_at is null and (f.is_group or f.parent_id is null)
order by f.sort_order, folder;
