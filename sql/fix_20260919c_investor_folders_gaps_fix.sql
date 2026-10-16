-- ============================================================
-- fix_20260919c_investor_folders_gaps_fix.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Why folders are missing for some investors
--
--   a) The trigger fires on INSERT only. Yesterday's relink pass set
--      party_id on existing rows with UPDATE, so those messages never ran
--      it. The catch-up in the first migration covered what existed at
--      that moment, but anything relinked afterwards is missed. Fixed
--      here by extending the trigger to UPDATE OF party_id.
--
--   b) The message still has party_id NULL -- no contact, no matching
--      party domain. No party means no folder. Section 4 lists these by
--      sender domain so the gaps are visible.
--
--   c) The message never reached URM at all. AP Ventures is this case:
--      the mail exists in the mailbox but not in app.communications, so
--      nothing downstream can see it. Not fixable here.
--
--   d) The party is not typed as an investor. Section 5 shows any party
--      with inbound mail whose type would exclude it.
--
-- Sections 1 to 3 change things; 4 and 5 only report.
-- Replaces fix_20260919b_..., which failed on
--   subquery uses ungrouped column c.from_address from outer query
-- Section 4 now aggregates the domain first, then looks the party up
-- against the grouped value. The editor runs the file in one
-- transaction, so the earlier attempt wrote nothing; this redoes it all.
--
-- Idempotent.
-- ============================================================


-- ------------------------------------------------------------
-- 1) trigger also on relink (UPDATE OF party_id)
-- ------------------------------------------------------------
drop trigger if exists trg_ensure_investor_mail_folder on app.communications;

create trigger trg_ensure_investor_mail_folder
  after insert or update of party_id on app.communications
  for each row
  execute function app.fn_ensure_investor_mail_folder();


-- ------------------------------------------------------------
-- 2) catch-up again, now that relinked rows are in scope
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
-- 3) hide the mailing-test folder: it is not an investor and its 46
--    unread messages would sit permanently at the top of the sidebar
-- ------------------------------------------------------------
update app.mail_folders
   set deleted_at = now()
 where deleted_at is null
   and label = 'MBG Mailing Test';


-- ------------------------------------------------------------
-- 4) REPORT: inbound mail that still has no party, by sender domain
--    These are the real gaps -- each one needs a contact, or a party
--    whose domain_normalized matches, before it can be filed.
-- ------------------------------------------------------------
with orphan as (
  select split_part(lower(c.from_address), '@', 2) as sender_domain,
         c.read_at,
         c.occurred_at
  from app.communications c
  where c.deleted_at is null
    and c.direction = 'inbound'
    and c.party_id is null
    and c.from_address is not null
    and split_part(lower(c.from_address), '@', 2) not in (
          'gmail.com','yahoo.com','hotmail.com','outlook.com','icloud.com',
          'naver.com','daum.net','kakao.com','qq.com','163.com',
          'linkedin.com','google.com','facebookmail.com')
),
agg as (
  select sender_domain,
         count(*)                                as messages,
         count(*) filter (where read_at is null) as unread,
         max(occurred_at)                        as latest
  from orphan
  group by sender_domain
)
select a.sender_domain,
       a.messages,
       a.unread,
       a.latest,
       coalesce(
         (select p.party_name
            from app.parties p
           where p.deleted_at is null
             and lower(p.domain_normalized) = a.sender_domain
           limit 1),
         '(no party with this domain)') as party_exists
from agg a
order by a.unread desc, a.messages desc
limit 40;


-- ------------------------------------------------------------
-- 5) REPORT: parties with inbound mail that are NOT typed investor
--    If a firm you expect under Investors shows up here, its
--    party_type is the reason it has no folder.
-- ------------------------------------------------------------
select p.party_name,
       pt.code as party_type,
       count(*) as inbound
from app.communications c
join app.parties p      on p.id = c.party_id and p.deleted_at is null
join app.party_types pt on pt.id = p.party_type_id
where c.deleted_at is null
  and c.direction = 'inbound'
  and pt.code not in ('investor', 'investors')
group by p.party_name, pt.code
order by inbound desc
limit 30;
