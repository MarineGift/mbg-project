-- ===========================================================================
--  migration_20260915g_uscis_folder.sql
--  URM - a USCIS folder inside Government
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires the mail-folder migrations up to ..._20260915f_gov_whitelist.sql.
--
--  WHAT THIS DOES
--    Creates a USCIS folder under Government and moves the DHS sender domains
--    onto it. It is a GROUP row, not a party folder: USCIS is a regulator, not
--    someone we do business with, so it gets no app.parties row, no pipeline
--    and no lead score - just its own mail folder.
--
--    The domains move DOWN from Government to USCIS. Opening Government still
--    shows everything underneath it (the scope walks the whole subtree), so
--    nothing disappears.
--
--  CAVEAT
--    USCIS mail arrives from dhs.gov, not uscis.dhs.gov (see VERIFY 2 of the
--    previous migration). dhs.gov covers all of Homeland Security, so other
--    DHS mail would land here too. VERIFY 2 below lists the actual sender
--    addresses - if you want it narrower, drop dhs.gov from match_domains and
--    put those exact addresses in match_addresses instead (the "exact
--    addresses" box on /inbox/folders).
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- 1) the USCIS group under Government --------------------------------------
insert into app.mail_folders
  (organization_id, party_id, parent_id, label, color, match_domains, is_group, sort_order)
select gov.organization_id,
       null,
       gov.id,
       'USCIS',
       '#64748b',
       array['uscis.dhs.gov', 'dhs.gov'],
       true,
       0
from (
  select id, organization_id
    from app.mail_folders
   where is_group and deleted_at is null and lower(label) = 'government'
   limit 1
) gov
where not exists (
  select 1 from app.mail_folders f
   where f.is_group
     and f.deleted_at is null
     and f.parent_id = gov.id
     and lower(f.label) = 'uscis'
);

-- 2) revive it if it was removed earlier, and make sure the domains are on it
update app.mail_folders f
   set deleted_at = null,
       match_domains = (
         select array_agg(distinct x)
           from unnest(f.match_domains || array['uscis.dhs.gov', 'dhs.gov']) x
       ),
       updated_at = now()
  from app.mail_folders gov
 where gov.is_group
   and gov.deleted_at is null
   and lower(gov.label) = 'government'
   and f.parent_id = gov.id
   and lower(f.label) = 'uscis';

-- 3) take the DHS domains off the Government parent -------------------------
--    (they now live on USCIS; the parent aggregates its children anyway)
update app.mail_folders g
   set match_domains = coalesce(
         (select array_agg(d)
            from unnest(g.match_domains) d
           where d not in ('dhs.gov', 'uscis.dhs.gov')),
         '{}'::text[]
       ),
       updated_at = now()
 where g.is_group
   and g.deleted_at is null
   and lower(g.label) = 'government';

-- ---------------------------------------------------------------------------
-- VERIFY 1 - Government and everything under it
-- ---------------------------------------------------------------------------
select coalesce(g.label, '(top)') as parent,
       f.label                    as folder,
       f.match_domains,
       f.match_addresses
from app.mail_folders f
left join app.mail_folders g on g.id = f.parent_id
where f.deleted_at is null
  and (lower(coalesce(g.label, '')) = 'government' or lower(coalesce(f.label, '')) = 'government')
order by parent, folder;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - who actually writes from dhs.gov. Use this to decide whether
-- dhs.gov is right, or whether to pin exact addresses instead.
-- ---------------------------------------------------------------------------
select lower(from_address) as sender,
       count(*)            as messages,
       max(occurred_at)    as latest
from app.communications
where deleted_at is null
  and lower(from_address) like '%@%dhs.gov'
group by sender
order by messages desc;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - counts per folder, straight from the counting function
-- ---------------------------------------------------------------------------
select f.label as folder, c.inbound, c.unread
from app.mail_folder_counts() c
join app.mail_folders f on f.id = c.folder_id
where f.deleted_at is null and f.is_group
order by c.inbound desc;
