-- ===========================================================================
--  migration_20260915d_mail_folder_short_labels.sql
--  URM - Mail folders: short labels, and a way to hide empty leaf folders
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Requires the three earlier mail-folder migrations.
--
--  WHY
--    "Specialty Minerals (USA - Lucerne Valley CA)" is far wider than the
--    sidebar, so every row truncated to "Specialty Minerals..." and the whole
--    list became unreadable.
--
--  WHAT THIS DOES
--    Group rows keep the company name (Omya, SMI). Their children drop the
--    company prefix, because the group above them already says it:
--       Specialty Minerals (USA - Lucerne Valley CA) -> USA - Lucerne Valley CA
--       Omya (Korea)                                 -> Korea
--       Specialty Minerals Inc.                      -> HQ
--    mail_folders.label is display only - party_id, and therefore which mail
--    lands in the folder, does not change. The full party name still shows in
--    the row tooltip and on /inbox/folders.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

-- 1) the Specialty Minerals group is labelled SMI --------------------------
update app.mail_folders
   set label = 'SMI', updated_at = now()
 where is_group
   and deleted_at is null
   and lower(label) = 'specialty minerals';

-- 2) children of the SMI group: strip the company prefix -------------------
update app.mail_folders f
   set label = nullif(
         btrim(
           regexp_replace(
             p.party_name,
             '^\s*Specialty\s+Minerals(\s+Inc\.?|,\s*Inc\.?)?\s*',
             '',
             'i'
           ),
           ' ().,-'
         ),
         ''
       ),
       updated_at = now()
  from app.mail_folders grp, app.parties p
 where grp.is_group and grp.deleted_at is null and grp.label = 'SMI'
   and f.parent_id = grp.id
   and f.is_group = false
   and f.deleted_at is null
   and p.id = f.party_id;

-- 3) children of the Omya group: same treatment ----------------------------
update app.mail_folders f
   set label = nullif(
         btrim(
           regexp_replace(p.party_name, '^\s*Omya\s*', '', 'i'),
           ' ().,-'
         ),
         ''
       ),
       updated_at = now()
  from app.mail_folders grp, app.parties p
 where grp.is_group and grp.deleted_at is null and lower(grp.label) = 'omya'
   and f.parent_id = grp.id
   and f.is_group = false
   and f.deleted_at is null
   and p.id = f.party_id;

-- 4) a folder whose name became empty is the head office -------------------
update app.mail_folders f
   set label = 'HQ', updated_at = now()
  from app.mail_folders grp
 where f.parent_id = grp.id
   and grp.is_group
   and f.is_group = false
   and f.deleted_at is null
   and f.label is null;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - what the sidebar will show, with the full party name alongside.
-- ---------------------------------------------------------------------------
select coalesce(g.label, '(top)')            as group_row,
       coalesce(f.label, p.party_name)       as sidebar_label,
       p.party_name                          as full_party_name,
       length(coalesce(f.label, p.party_name)) as label_len
from app.mail_folders f
left join app.mail_folders g on g.id = f.parent_id
left join app.parties p on p.id = f.party_id
where f.deleted_at is null and f.is_group = false
order by group_row, sidebar_label;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - leaf folders holding no mail at all. These are the rows making
-- the sidebar long for no benefit (a party with no contact email and no
-- domain of its own never receives anything).
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name) as folder, c.inbound
from app.mail_folder_counts() c
join app.mail_folders f on f.id = c.folder_id
left join app.parties p on p.id = f.party_id
where f.deleted_at is null and f.is_group = false and c.inbound = 0
order by folder;

-- ---------------------------------------------------------------------------
-- OPTIONAL - hide the empty ones. Read VERIFY 2 first, then run this block on
-- its own. It is a soft delete: nothing happens to the mail or to the party,
-- and you can re-add any folder from /inbox/folders at any time.
-- ---------------------------------------------------------------------------
-- update app.mail_folders f
--    set deleted_at = now(), updated_at = now()
--   from app.mail_folder_counts() c
--  where c.folder_id = f.id
--    and f.deleted_at is null
--    and f.is_group = false
--    and c.inbound = 0;
