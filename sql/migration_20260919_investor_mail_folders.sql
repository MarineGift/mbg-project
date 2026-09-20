-- ============================================================
-- migration_20260919_investor_mail_folders.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Goal
--   One mail folder per investor, appearing in the sidebar under the
--   existing "Investors" group, created automatically the moment that
--   investor's first inbound message lands.
--
-- Why party_id rather than match_domains
--   app.mail_folder_counts() already matches a message to a folder three
--   ways -- folder.party_id = communication.party_id, match_domains, and
--   match_addresses -- and rolls child folders up into their parent
--   recursively. So a leaf folder that carries only party_id is enough:
--   no domain arrays to maintain, no array bloat, and it follows the
--   party link that the ingest path already resolves.
--
-- Why on first message rather than for every investor
--   There are hundreds of investor parties. Creating a folder for each
--   would fill the sidebar with entries that will never hold a message.
--   Creating one when mail actually arrives keeps the list to the firms
--   that are actually in conversation.
--
-- Sorting
--   New folders get sort_order 100 so they sit after the hand-curated
--   folders. The sidebar sorts by sort_order then created_at; a separate
--   UI change is needed to float unread folders to the top.
--
-- Idempotent: a folder is only created when none exists for that party.
-- ============================================================


-- ------------------------------------------------------------
-- 1) helper: the "Investors" group folder id for an organization
-- ------------------------------------------------------------
create or replace function app.fn_investor_folder_parent(p_org uuid)
returns uuid
language sql
stable
security definer
set search_path = app, public
as $fn$
  select f.id
  from app.mail_folders f
  where f.organization_id = p_org
    and f.deleted_at is null
    and f.is_group = true
    and lower(f.label) = 'investors'
  order by f.created_at
  limit 1;
$fn$;


-- ------------------------------------------------------------
-- 2) trigger: create the leaf folder on first inbound message
-- ------------------------------------------------------------
create or replace function app.fn_ensure_investor_mail_folder()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  v_parent uuid;
  v_name   text;
begin
  if new.party_id is null or new.direction <> 'inbound' then
    return new;
  end if;

  -- only investor parties
  if not exists (
    select 1
    from app.parties p
    join app.party_types pt on pt.id = p.party_type_id
    where p.id = new.party_id
      and p.deleted_at is null
      and pt.code in ('investor', 'investors')
  ) then
    return new;
  end if;

  -- already has a folder
  if exists (
    select 1 from app.mail_folders f
    where f.organization_id = new.organization_id
      and f.party_id = new.party_id
      and f.deleted_at is null
  ) then
    return new;
  end if;

  v_parent := app.fn_investor_folder_parent(new.organization_id);
  if v_parent is null then
    return new;   -- no Investors group folder: leave the sidebar alone
  end if;

  select p.party_name into v_name
  from app.parties p where p.id = new.party_id;

  insert into app.mail_folders
    (organization_id, parent_id, party_id, is_group, label, sort_order)
  values
    (new.organization_id, v_parent, new.party_id, false,
     coalesce(v_name, 'Investor'), 100);

  return new;
end;
$fn$;

drop trigger if exists trg_ensure_investor_mail_folder on app.communications;

create trigger trg_ensure_investor_mail_folder
  after insert on app.communications
  for each row
  execute function app.fn_ensure_investor_mail_folder();


-- ------------------------------------------------------------
-- 3) catch-up: every investor that already has inbound mail
-- ------------------------------------------------------------
insert into app.mail_folders
  (organization_id, parent_id, party_id, is_group, label, sort_order)
select distinct
       c.organization_id,
       app.fn_investor_folder_parent(c.organization_id),
       c.party_id,
       false,
       p.party_name,
       100
from app.communications c
join app.parties p       on p.id = c.party_id and p.deleted_at is null
join app.party_types pt  on pt.id = p.party_type_id
where c.deleted_at is null
  and c.direction = 'inbound'
  and c.party_id is not null
  and pt.code in ('investor', 'investors')
  and app.fn_investor_folder_parent(c.organization_id) is not null
  and not exists (
    select 1 from app.mail_folders f
    where f.organization_id = c.organization_id
      and f.party_id = c.party_id
      and f.deleted_at is null
  );


-- ------------------------------------------------------------
-- 4) Verification
-- ------------------------------------------------------------

-- 4a) the Investors group and its new children, with counts
select f.label,
       f.is_group,
       coalesce(mc.inbound, 0) as inbound,
       coalesce(mc.unread, 0)  as unread
from app.mail_folders f
left join app.mail_folder_counts() mc on mc.folder_id = f.id
where f.deleted_at is null
  and (lower(f.label) = 'investors'
       or f.parent_id = app.fn_investor_folder_parent(f.organization_id))
order by coalesce(mc.unread, 0) desc, f.label;

-- 4b) how many folders now exist in total
select count(*) filter (where is_group) as groups,
       count(*) filter (where not is_group) as leaves,
       count(*) as total
from app.mail_folders
where deleted_at is null;
