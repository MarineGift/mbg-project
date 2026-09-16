-- ===========================================================================
--  migration_20260915h_nist_nsf_folders.sql
--  URM - NIST and NSF folders inside Government
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires the mail-folder migrations through ..._20260915g_uscis_folder.sql.
--
--  WHAT THIS DOES
--    Adds NIST and NSF beside USCIS under Government, and moves their sender
--    domains down onto them. Group rows again - no app.parties row, because
--    these are agencies we receive from, not counterparties.
--
--      Government
--        USCIS   uscis.dhs.gov, dhs.gov
--        NIST    announcements.nist.gov, nist.gov
--        NSF     govdelivery.nsf.gov, nsf.gov
--
--    The bare nist.gov / nsf.gov domains are included so a direct message from
--    a programme officer lands in the right folder, not only the newsletter
--    relays that are in the mailbox today.
--
--    mail.house.gov and austintexas.gov stay directly on Government. Split
--    them off the same way if they ever grow enough to be worth their own row.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- 1) create the two groups --------------------------------------------------
insert into app.mail_folders
  (organization_id, party_id, parent_id, label, color, match_domains, is_group, sort_order)
select gov.organization_id, null, gov.id, g.label, '#64748b', g.domains, true, g.ord
from (
  select id, organization_id
    from app.mail_folders
   where is_group and deleted_at is null and lower(label) = 'government'
   limit 1
) gov
cross join (
  values ('NIST', array['announcements.nist.gov', 'nist.gov'], 1),
         ('NSF',  array['govdelivery.nsf.gov', 'nsf.gov'],     2)
) as g(label, domains, ord)
where not exists (
  select 1 from app.mail_folders f
   where f.is_group
     and f.deleted_at is null
     and f.parent_id = gov.id
     and lower(f.label) = lower(g.label)
);

-- 2) revive + top up the domains if either group existed already ------------
update app.mail_folders f
   set deleted_at = null,
       match_domains = (
         select array_agg(distinct x)
           from unnest(
             f.match_domains ||
             case lower(f.label)
               when 'nist' then array['announcements.nist.gov', 'nist.gov']
               else array['govdelivery.nsf.gov', 'nsf.gov']
             end
           ) x
       ),
       updated_at = now()
  from app.mail_folders gov
 where gov.is_group
   and gov.deleted_at is null
   and lower(gov.label) = 'government'
   and f.parent_id = gov.id
   and lower(f.label) in ('nist', 'nsf');

-- 3) take those domains off the Government parent ---------------------------
update app.mail_folders g
   set match_domains = coalesce(
         (select array_agg(d)
            from unnest(g.match_domains) d
           where d not in (
             'announcements.nist.gov', 'nist.gov',
             'govdelivery.nsf.gov', 'nsf.gov'
           )),
         '{}'::text[]
       ),
       updated_at = now()
 where g.is_group
   and g.deleted_at is null
   and lower(g.label) = 'government';

-- ---------------------------------------------------------------------------
-- VERIFY 1 - Government and its children
-- ---------------------------------------------------------------------------
select coalesce(g.label, '(top)') as parent,
       f.label                    as folder,
       f.match_domains
from app.mail_folders f
left join app.mail_folders g on g.id = f.parent_id
where f.deleted_at is null
  and (lower(coalesce(g.label, '')) = 'government' or lower(coalesce(f.label, '')) = 'government')
order by parent, f.sort_order, folder;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - counts per group. Government should equal the union of its
-- children plus whatever domains are still pinned directly on it.
-- ---------------------------------------------------------------------------
select f.label as folder, c.inbound, c.unread
from app.mail_folder_counts() c
join app.mail_folders f on f.id = c.folder_id
where f.deleted_at is null and f.is_group
order by c.inbound desc;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - .gov senders that no folder claims yet. Anything listed here is
-- sitting in Government's catch-all (or nowhere, if its domain was moved).
-- ---------------------------------------------------------------------------
select split_part(lower(c.from_address), '@', 2) as domain, count(*) as messages
from app.communications c
where c.deleted_at is null
  and split_part(lower(c.from_address), '@', 2) like '%.gov'
  and not exists (
    select 1
      from app.mail_folders f, unnest(f.match_domains) d
     where f.deleted_at is null
       and d = split_part(lower(c.from_address), '@', 2)
  )
group by domain
order by messages desc;
