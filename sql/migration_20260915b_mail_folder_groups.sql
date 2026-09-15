-- ===========================================================================
--  migration_20260915b_mail_folder_groups.sql
--  URM - Mail folders: one level of grouping (Partners / Investors / Business)
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires migration_20260915_mail_folders.sql to have run already.
--
--  WHAT CHANGES
--    app.mail_folders rows become one of two kinds:
--      is_group = true   -> a group header. party_id is null, label is the
--                           group name. Opening it shows the mail of every
--                           child folder combined.
--      is_group = false  -> a party folder, optionally nested under a group
--                           via parent_id.
--    Still a saved view: no mail is moved or copied.
--
--  SEEDS
--    Groups: Partners, Investors, Business
--    Greentown Labs Houston -> Partners
--    Omya, Specialty Minerals -> Business (only if those parties exist)
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

alter table app.mail_folders
  add column if not exists parent_id uuid references app.mail_folders(id) on delete set null;

alter table app.mail_folders
  add column if not exists is_group boolean not null default false;

-- groups carry no party
alter table app.mail_folders alter column party_id drop not null;

-- a row is either a named group with no party, or a party folder
alter table app.mail_folders drop constraint if exists mail_folders_kind_chk;
alter table app.mail_folders add constraint mail_folders_kind_chk check (
  (is_group = true  and party_id is null and label is not null)
  or
  (is_group = false and party_id is not null)
);

create index if not exists mail_folders_parent_idx
  on app.mail_folders (organization_id, parent_id, sort_order)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- SEED 1 - the three groups
-- ---------------------------------------------------------------------------
insert into app.mail_folders (organization_id, party_id, label, color, is_group, sort_order)
select org.id, null, g.label, g.color, true, g.sort_order
from (
  select coalesce(
    (select organization_id from app.mail_folders where deleted_at is null limit 1),
    (select id from app.organizations limit 1)
  ) as id
) org
cross join (
  values ('Partners',  '#10b981', 0),
         ('Investors', '#8b5cf6', 1),
         ('Business',  '#3b82f6', 2)
) as g(label, color, sort_order)
where org.id is not null
  and not exists (
    select 1 from app.mail_folders f
     where f.is_group
       and f.deleted_at is null
       and lower(f.label) = lower(g.label)
  );

-- ---------------------------------------------------------------------------
-- SEED 2 - Greentown Labs Houston lands under Partners
-- ---------------------------------------------------------------------------
update app.mail_folders f
   set parent_id = grp.id,
       updated_at = now()
  from app.mail_folders grp,
       app.parties p
 where grp.is_group
   and grp.deleted_at is null
   and lower(grp.label) = 'partners'
   and p.id = f.party_id
   and f.deleted_at is null
   and f.is_group = false
   and f.parent_id is null
   and p.party_name ilike 'Greentown Labs%';

-- ---------------------------------------------------------------------------
-- SEED 3 - Omya and Specialty Minerals under Business
--   Matches on party name. If nothing shows up in VERIFY 2 for these two,
--   the party names differ - add them by hand in /inbox/folders.
-- ---------------------------------------------------------------------------
insert into app.mail_folders
  (organization_id, party_id, parent_id, label, color, match_domains, is_group, sort_order)
select p.organization_id,
       p.id,
       grp.id,
       p.party_name,
       '#3b82f6',
       case
         when p.party_name ilike 'Omya%' then array['omya.com']
         else array['mineralstech.com']
       end,
       false,
       0
from app.parties p
cross join lateral (
  select id from app.mail_folders
   where is_group and deleted_at is null and lower(label) = 'business'
   limit 1
) grp
where p.deleted_at is null
  and (p.party_name ilike 'Omya%' or p.party_name ilike '%Specialty Minerals%')
  and not exists (
    select 1 from app.mail_folders f
     where f.party_id = p.id and f.deleted_at is null
  );

-- ---------------------------------------------------------------------------
-- VERIFY 1 - the tree. Groups first, each child indented under its parent.
-- ---------------------------------------------------------------------------
select case when f.is_group then f.label
            else '    ' || coalesce(f.label, p.party_name) end as folder,
       case when f.is_group then 'group' else 'party' end       as kind,
       coalesce(g.label, '-')                                   as parent,
       f.match_domains,
       f.sort_order
from app.mail_folders f
left join app.parties p      on p.id = f.party_id
left join app.mail_folders g on g.id = f.parent_id
where f.deleted_at is null
order by coalesce(g.sort_order, f.sort_order), f.is_group desc, f.sort_order, folder;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - mail volume per party folder.
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name) as folder,
       count(c.id) filter (where c.direction = 'inbound')                       as inbound,
       count(c.id) filter (where c.direction = 'inbound' and c.read_at is null) as unread
from app.mail_folders f
join app.parties p on p.id = f.party_id
left join app.communications c
       on c.party_id = f.party_id
      and c.deleted_at is null
where f.deleted_at is null and f.is_group = false
group by folder
order by folder;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - parties whose name contains Omya / Specialty / Minerals, so you
-- can see what the real names are if SEED 3 matched nothing.
-- ---------------------------------------------------------------------------
select id, party_name
from app.parties
where deleted_at is null
  and (party_name ilike '%omya%' or party_name ilike '%mineral%' or party_name ilike '%specialty%')
order by party_name;
