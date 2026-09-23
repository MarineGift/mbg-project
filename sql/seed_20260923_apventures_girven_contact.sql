-- ============================================================
-- seed_20260923_apventures_girven_contact.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Adds Girven (AP Ventures) as a contact on the AP Ventures investor
-- party, and makes sure the apventures.com domain is whitelisted.
-- Party is matched by exact name (case-insensitive), oldest row first,
-- so only ONE party receives the contact.
-- Idempotent: re-running does nothing once the contact exists.
-- The last statement is the verification (the editor shows only it).
-- ============================================================


-- ------------------------------------------------------------
-- 1) contact
-- ------------------------------------------------------------
insert into app.contacts
  (organization_id, party_id, contact_type_id,
   full_name, given_name, family_name, email, title_text,
   is_primary, is_active, source, notes)
select p.organization_id,
       p.id,
       coalesce(
         (select ct.id from app.contact_types ct
           where ct.code in ('primary', 'contact', 'general') limit 1),
         (select min(ct.id) from app.contact_types ct)
       ),
       'Girven', null, 'Girven',
       'girven@apventures.com',
       null,
       not exists (
         select 1 from app.contacts c2
         where c2.party_id = p.id
           and c2.is_primary
           and c2.deleted_at is null
       ),
       true,
       'apventures_meeting_2026',
       $gt$Met 2026-09-22 for about one hour. Showed deep interest in the FCC/HFCC technology and requested materials. Upgraded materials sent 2026-09-23 as promised; more detail to follow once an NDA is signed.$gt$
from (
  select p0.id, p0.organization_id
  from app.parties p0
  where p0.deleted_at is null
    and lower(trim(p0.party_name)) = 'ap ventures'
  order by p0.created_at
  limit 1
) p
where not exists (
  select 1 from app.contacts c
  where c.organization_id = p.organization_id
    and lower(c.email) = 'girven@apventures.com'
    and c.deleted_at is null
);


-- ------------------------------------------------------------
-- 2) domain whitelist (skipped if already present)
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169', 'apventures.com', 'domain',
       'auto: investor contact domain (AP Ventures)', true
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and w.kind = 'domain'
    and lower(w.pattern) = 'apventures.com'
);


-- ------------------------------------------------------------
-- 3) Verification -- expect one row. Zero rows = party not found by name.
-- ------------------------------------------------------------
select p.party_name,
       c.full_name,
       c.email,
       c.is_primary,
       (select count(*) from app.parties px
         where px.deleted_at is null
           and lower(trim(px.party_name)) = 'ap ventures') as parties_named_ap_ventures
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and lower(c.email) = 'girven@apventures.com';
