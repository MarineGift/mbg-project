-- ============================================================
-- seed_20260918_investor_contacts.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Why
--   The whitelist decides whether inbound mail is ACCEPTED. The party a
--   message attaches to is resolved from app.contacts -- exact address
--   first, then contacts.email LIKE '%@domain'. parties.website is never
--   consulted. Every greentown party currently has zero contacts, so mail
--   from them lands with party_id NULL and never reaches the party's
--   Communications tab.
--
--   This seeds the three contacts whose addresses are already known from
--   replies received on 2026-09-18. Once these exist, their threads attach
--   automatically from the next message on.
--
-- Note on Chemical Angels: the address is a gmail one, which the domain
-- whitelist deliberately skips. The exact-address match handles it, which
-- is why the contact row matters more here than the whitelist.
--
-- Section 0 is a dry run. Read it before trusting the inserts: if a party
-- name does not resolve, its contact is silently skipped.
--
-- Idempotent: guarded on the email address.
-- ============================================================


-- ------------------------------------------------------------
-- 0) DRY RUN -- confirm each party name resolves to exactly one row
-- ------------------------------------------------------------
select v.label,
       count(p.id) as parties_matched,
       coalesce(string_agg(p.party_name, ' | '), '(none)') as matched_names
from (values
  ('Chemical Angels',    '%chemical angels%'),
  ('Foley',              '%foley%'),
  ('Inquisitive Capital','%inquisitive%')
) as v(label, pattern)
left join app.parties p
       on p.deleted_at is null
      and p.party_name ilike v.pattern
group by v.label
order by v.label;


-- ------------------------------------------------------------
-- 1) the contacts
--    contact_type_id is resolved from app.contact_types, falling back to
--    the lowest id so the insert cannot fail on a missing code.
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
       v.full_name, v.given_name, v.family_name, v.email, v.title_text,
       true, true,
       'greentown_warm_intro_2026',
       v.notes
from (values
  ('%chemical angels%',
   'DC Palter', 'DC', 'Palter',
   'dcpalter@gmail.com',
   null,
   'Replied 2026-09-18 through the Greentown warm intro. Challenged whether MBG should be a venture business or a profitable licensing business; said he is happy to continue once that is decided.'),
  ('%foley%',
   'James C. De Vellis', 'James', 'De Vellis',
   'JDeVellis@foley.com',
   'Foley & Lardner LLP / Foley Ventures',
   'Introduced by Will McCallum at Greentown on 2026-09-18. Proposed a call the week of Sept 28 and asked MBG to pick a time.'),
  ('%inquisitive%',
   'Stan Sakai', 'Stan', 'Sakai',
   'stanley.sakai@inquisitive.capital',
   null,
   'Introduced by Will McCallum at Greentown on 2026-09-15, replied 2026-09-18. Offered Thursday or Friday next week between 1 and 3.')
) as v(pattern, full_name, given_name, family_name, email, title_text, notes)
join app.parties p
  on p.deleted_at is null
 and p.party_name ilike v.pattern
where not exists (
  select 1 from app.contacts c
  where c.organization_id = p.organization_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);


-- ------------------------------------------------------------
-- 2) whitelist the two corporate domains behind those addresses
--    (gmail is skipped on purpose -- exact address match covers it)
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select distinct p.organization_id, d.domain, 'domain',
       'auto: investor contact domain', true
from app.parties p
cross join lateral (values ('foley.com'), ('inquisitive.capital')) as d(domain)
where p.deleted_at is null
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and not exists (
    select 1 from app.email_whitelist w
    where w.organization_id = p.organization_id
      and w.kind = 'domain'
      and lower(w.pattern) = d.domain
  );


-- ------------------------------------------------------------
-- 3) whitelist the exact gmail address for Chemical Angels
--    kind 'email' so the free-mail domain is not opened up wholesale
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169',
       'dcpalter@gmail.com',
       'email',
       'auto: investor contact address (Chemical Angels)',
       true
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and lower(w.pattern) = 'dcpalter@gmail.com'
);


-- ------------------------------------------------------------
-- 4) Verification
-- ------------------------------------------------------------
select p.party_name,
       c.full_name,
       c.email,
       c.is_primary
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.source = 'greentown_warm_intro_2026'
order by p.party_name;
