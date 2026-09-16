-- ===========================================================================
--  migration_20260915j_backfill_party_links.sql
--  URM - attach unlinked mail to its party, using the folder pins
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  WHY
--    The party-type badge in the inbox (the green "Partners" chip) is driven by
--    app.communications.party_id -> parties -> party_types.code. A message with
--    party_id null shows no badge, which is why mail from Greentown people like
--    Natalie has none while the Greentown Labs Houston row does.
--
--    party_id is set once, at ingest, by matchSenderToContactAndParty: contact
--    email, then party email, then sender domain. Mail that arrived BEFORE the
--    contact or the party existed was never linked, and nothing re-links it
--    afterwards.
--
--  WHAT THIS DOES
--    Uses the mail folders as the source of truth: for every party folder
--    (is_group = false, so it has a party), any unlinked message whose sender
--    matches that folder's pinned domains or exact addresses gets that party.
--
--    Group folders are skipped - they have no party by design (Government,
--    Omya, SMI are containers, not counterparties).
--
--    Only rows with party_id IS NULL are touched. An existing link is never
--    overwritten.
--
--  IDEMPOTENT: safe to re-run. Re-run it after adding a new domain or address
--  pin to pick up that sender's back catalogue.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- VERIFY 1 (before) - what is about to change, grouped by sender domain
-- ---------------------------------------------------------------------------
select coalesce(f.label, p.party_name)                as folder,
       split_part(lower(c.from_address), '@', 2)      as sender_domain,
       count(*)                                       as will_link
from app.communications c
join app.mail_folders f
  on f.deleted_at is null
 and f.is_group = false
 and f.party_id is not null
 and f.organization_id = c.organization_id
 and (
   exists (select 1 from unnest(f.match_domains) d
            where lower(c.from_address) like '%@' || d)
   or lower(c.from_address) = any (select lower(a) from unnest(f.match_addresses) a)
 )
left join app.parties p on p.id = f.party_id
where c.deleted_at is null
  and c.party_id is null
group by folder, sender_domain
order by will_link desc;

-- ---------------------------------------------------------------------------
-- THE BACKFILL
-- ---------------------------------------------------------------------------
update app.communications c
   set party_id = f.party_id,
       updated_at = now()
  from app.mail_folders f
 where c.deleted_at is null
   and c.party_id is null
   and f.deleted_at is null
   and f.is_group = false
   and f.party_id is not null
   and f.organization_id = c.organization_id
   and (
     exists (select 1 from unnest(f.match_domains) d
              where lower(c.from_address) like '%@' || d)
     or lower(c.from_address) = any (select lower(a) from unnest(f.match_addresses) a)
   );

-- ---------------------------------------------------------------------------
-- VERIFY 2 (after) - nothing should be left for the pinned senders
-- ---------------------------------------------------------------------------
select split_part(lower(c.from_address), '@', 2) as sender_domain,
       count(*)                                  as still_unlinked
from app.communications c
join app.mail_folders f
  on f.deleted_at is null
 and f.is_group = false
 and f.party_id is not null
 and f.organization_id = c.organization_id
 and exists (select 1 from unnest(f.match_domains) d
              where lower(c.from_address) like '%@' || d)
where c.deleted_at is null
  and c.party_id is null
group by sender_domain;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - Greentown senders and whether each is linked now. Every row
-- should show a party; those that do not have no folder pin covering them.
-- ---------------------------------------------------------------------------
select lower(c.from_address)                          as sender,
       count(*)                                       as messages,
       count(*) filter (where c.party_id is not null) as linked,
       max(p.party_name)                              as party
from app.communications c
left join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and lower(c.from_address) like '%greentown%'
group by sender
order by messages desc;

-- ---------------------------------------------------------------------------
-- VERIFY 4 - the biggest unlinked senders left in the whole mailbox. Anything
-- here with real volume deserves either a contact record or a folder pin.
-- ---------------------------------------------------------------------------
select split_part(lower(from_address), '@', 2) as sender_domain,
       count(*)                                as unlinked_messages
from app.communications
where deleted_at is null
  and party_id is null
  and direction = 'inbound'
group by sender_domain
having count(*) >= 3
order by unlinked_messages desc
limit 40;
