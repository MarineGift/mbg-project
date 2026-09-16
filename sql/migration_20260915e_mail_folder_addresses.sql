-- ===========================================================================
--  migration_20260915e_mail_folder_addresses.sql
--  URM - Mail folders: pin exact sender addresses (not just domains)
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires the four earlier mail-folder migrations.
--
--  WHY
--    GreentownHTX@user.luma-mail.com is Greentown mail, but user.luma-mail.com
--    is Luma's shared relay - every event organiser on Luma sends from it.
--    Pinning that DOMAIN would drag unrelated organisers into the folder, and
--    adding it as a Greentown contact is worse: step [3] of
--    matchSenderToContactAndParty looks contacts up BY DOMAIN, so every future
--    @user.luma-mail.com sender would be stamped with the Greentown party_id
--    across the whole CRM.
--
--    So: pin the exact address on the folder instead.
--
--  WHAT THIS DOES
--    1. app.mail_folders.match_addresses text[] - exact from_address matches.
--    2. app.mail_folder_counts() also counts those addresses.
--    3. Pins GreentownHTX@user.luma-mail.com on the Greentown folder.
--    4. Backfills party_id on the mail already received from that ONE address,
--       so it shows on the party's Communications tab too, not only in the
--       folder.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

alter table app.mail_folders
  add column if not exists match_addresses text[] not null default '{}'::text[];

-- ---------------------------------------------------------------------------
-- counts: folder = its party OR a pinned domain OR a pinned exact address
-- ---------------------------------------------------------------------------
drop function if exists app.mail_folder_counts();

create function app.mail_folder_counts()
returns table (folder_id uuid, inbound bigint, unread bigint)
language sql
stable
security invoker
set search_path = app, public
as $fn$
  with recursive tree as (
    select f.id as root, f.id as node, 0 as depth
      from app.mail_folders f
     where f.deleted_at is null
    union all
    select t.root, c.id, t.depth + 1
      from tree t
      join app.mail_folders c
        on c.parent_id = t.node
       and c.deleted_at is null
     where t.depth < 5
  )
  select t.root,
         count(distinct c.id) filter (where c.direction = 'inbound') as inbound,
         count(distinct c.id) filter (
           where c.direction = 'inbound' and c.read_at is null
         ) as unread
    from tree t
    join app.mail_folders n on n.id = t.node
    left join app.communications c
           on c.deleted_at is null
          and c.organization_id = n.organization_id
          and (
                c.party_id = n.party_id
                or exists (
                     select 1 from unnest(n.match_domains) d
                      where lower(c.from_address) like '%@' || d
                   )
                or lower(c.from_address) = any (
                     select lower(a) from unnest(n.match_addresses) a
                   )
              )
   group by t.root;
$fn$;

grant execute on function app.mail_folder_counts() to authenticated;

-- ---------------------------------------------------------------------------
-- pin the Luma address on the Greentown folder
-- ---------------------------------------------------------------------------
update app.mail_folders f
   set match_addresses = (
         select array_agg(distinct x)
           from unnest(f.match_addresses || array['greentownhtx@user.luma-mail.com']) x
       ),
       updated_at = now()
  from app.parties p
 where f.deleted_at is null
   and f.is_group = false
   and p.id = f.party_id
   and p.party_name ilike 'Greentown Labs%'
   and not (
     'greentownhtx@user.luma-mail.com' = any (
       select lower(a) from unnest(f.match_addresses) a
     )
   );

-- ---------------------------------------------------------------------------
-- link the mail already received from that exact address to the party
-- ---------------------------------------------------------------------------
update app.communications c
   set party_id = f.party_id,
       updated_at = now()
  from app.mail_folders f
 where c.deleted_at is null
   and c.party_id is null
   and c.organization_id = f.organization_id
   and f.deleted_at is null
   and lower(c.from_address) = 'greentownhtx@user.luma-mail.com'
   and 'greentownhtx@user.luma-mail.com' = any (
     select lower(a) from unnest(f.match_addresses) a
   );

-- ---------------------------------------------------------------------------
-- VERIFY 1 - the pin landed
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name) as folder,
       f.match_domains,
       f.match_addresses
from app.mail_folders f
left join app.parties p on p.id = f.party_id
where f.deleted_at is null
  and (array_length(f.match_addresses, 1) > 0 or array_length(f.match_domains, 1) > 0)
order by folder;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - how much mail that address has sent, and whether it is linked now
-- ---------------------------------------------------------------------------
select count(*) filter (where party_id is not null) as linked,
       count(*) filter (where party_id is null)     as still_unlinked,
       count(*)                                     as total
from app.communications
where deleted_at is null
  and lower(from_address) = 'greentownhtx@user.luma-mail.com';

-- ---------------------------------------------------------------------------
-- VERIFY 3 - other senders on the same Luma relay. These belong to WHOEVER
-- ran that event, not to Greentown - which is exactly why the domain is not
-- pinned. Pin any of them individually if they turn out to be Greentown too.
-- ---------------------------------------------------------------------------
select lower(from_address) as sender, count(*) as messages
from app.communications
where deleted_at is null
  and lower(from_address) like '%@user.luma-mail.com'
group by sender
order by messages desc;
