-- ===========================================================================
--  migration_20260915c_mail_folder_subgroups.sql
--  URM - Mail folders: nested groups + de-duplicated counts
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires migration_20260915_mail_folders.sql and ..._20260915b_... first.
--
--  WHY
--    SEED 3 of the previous migration matched every Omya subsidiary party
--    (Omya (Korea), Omya (Egypt), ...) and several Specialty Minerals rows,
--    so Business ended up with ~30 sibling folders and no way to tell the two
--    companies apart. It also pinned omya.com on EVERY Omya folder, so the
--    same 42 messages were counted once per folder - that is where Business
--    3330/5094 came from.
--
--  WHAT THIS DOES
--    1. Groups may now nest:  Business > Omya > Omya (Korea)
--    2. Creates the Omya and Specialty Minerals groups under Business and
--       moves the matching folders into them.
--    3. Moves the shared sender domain UP to the group and clears it from the
--       leaves, so a leaf counts its own party only.
--    4. Adds app.mail_folder_counts(): one call returns inbound/unread per
--       folder, counting each message ONCE per folder (count distinct over the
--       folder and all of its descendants). Replaces the per-folder head
--       requests the sidebar was firing.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- 1) a group may sit inside another group ----------------------------------
create index if not exists mail_folders_group_parent_idx
  on app.mail_folders (organization_id, is_group, parent_id)
  where deleted_at is null;

-- 2) Omya / Specialty Minerals groups under Business ------------------------
insert into app.mail_folders (organization_id, party_id, parent_id, label, color, match_domains, is_group, sort_order)
select biz.organization_id, null, biz.id, g.label, g.color, g.domains, true, g.sort_order
from (
  select id, organization_id from app.mail_folders
   where is_group and deleted_at is null and lower(label) = 'business'
   limit 1
) biz
cross join (
  values ('Omya',               '#3b82f6', array['omya.com'],         0),
         ('Specialty Minerals', '#8b5cf6', array['mineralstech.com'], 1)
) as g(label, color, domains, sort_order)
where not exists (
  select 1 from app.mail_folders f
   where f.is_group and f.deleted_at is null
     and f.parent_id = biz.id
     and lower(f.label) = lower(g.label)
);

-- 3) move the party folders into their company group ------------------------
update app.mail_folders f
   set parent_id = grp.id,
       match_domains = '{}'::text[],   -- the domain now lives on the group
       color = '#3b82f6',
       updated_at = now()
  from app.mail_folders grp,
       app.mail_folders biz,
       app.parties p
 where biz.is_group and biz.deleted_at is null and lower(biz.label) = 'business'
   and grp.is_group and grp.deleted_at is null and grp.parent_id = biz.id
   and lower(grp.label) = 'omya'
   and f.deleted_at is null
   and f.is_group = false
   and p.id = f.party_id
   and p.party_name ilike 'Omya%'
   and f.parent_id is distinct from grp.id;

update app.mail_folders f
   set parent_id = grp.id,
       match_domains = '{}'::text[],
       color = '#8b5cf6',
       updated_at = now()
  from app.mail_folders grp,
       app.mail_folders biz,
       app.parties p
 where biz.is_group and biz.deleted_at is null and lower(biz.label) = 'business'
   and grp.is_group and grp.deleted_at is null and grp.parent_id = biz.id
   and lower(grp.label) = 'specialty minerals'
   and f.deleted_at is null
   and f.is_group = false
   and p.id = f.party_id
   and p.party_name ilike '%Specialty Minerals%'
   and f.parent_id is distinct from grp.id;

-- 4) counts in one round trip, each message counted once per folder ---------
drop function if exists app.mail_folder_counts();

create function app.mail_folder_counts()
returns table (folder_id uuid, inbound bigint, unread bigint)
language sql
stable
security invoker
set search_path = app, public
as $fn$
  with recursive tree as (
    -- every folder is the root of its own subtree
    select f.id as root, f.id as node, 0 as depth
      from app.mail_folders f
     where f.deleted_at is null
    union all
    -- ... plus its descendants, depth-capped so a bad parent_id cannot loop
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
              )
   group by t.root;
$fn$;

grant execute on function app.mail_folder_counts() to authenticated;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - the tree, three levels deep.
-- ---------------------------------------------------------------------------
with recursive t as (
  select f.id, f.parent_id, coalesce(f.label, '') as label, f.party_id,
         f.is_group, f.sort_order, 0 as depth,
         coalesce(f.label, '') as path
    from app.mail_folders f
   where f.deleted_at is null and f.parent_id is null
  union all
  select c.id, c.parent_id, coalesce(c.label, ''), c.party_id,
         c.is_group, c.sort_order, t.depth + 1,
         t.path || ' / ' || coalesce(c.label, '')
    from app.mail_folders c
    join t on c.parent_id = t.id
   where c.deleted_at is null and t.depth < 5
)
select repeat('    ', t.depth) || coalesce(t.label, p.party_name) as folder,
       case when t.is_group then 'group' else 'party' end          as kind,
       t.depth
from t
left join app.parties p on p.id = t.party_id
order by t.path, t.is_group desc, t.sort_order;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - counts straight from the new function. Business should now be
-- roughly (Omya union SMI), NOT the sum of every subsidiary folder.
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name) as folder,
       case when f.is_group then 'group' else 'party' end as kind,
       c.inbound,
       c.unread
from app.mail_folder_counts() c
join app.mail_folders f on f.id = c.folder_id
left join app.parties p on p.id = f.party_id
where f.deleted_at is null
order by f.is_group desc, c.inbound desc;
