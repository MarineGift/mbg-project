-- ============================================================
-- seed_20260918b_investor_contacts_fix.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Replaces seed_20260918_investor_contacts.sql, which failed on
--   email_whitelist_kind_check
-- because it used kind = 'email'. The constraint allows only
--   'domain', 'address', 'regex'
-- so the single-address entry is now kind = 'address'.
--
-- The editor runs the whole file in one transaction, so that one bad
-- statement rolled back the contacts and the domain entries too. Nothing
-- from the previous attempt survived; this file redoes all of it.
--
-- Section 0 is a dry run. If any label shows parties_matched = 0 its
-- contact is skipped silently, and if it shows 2 or more the contact
-- attaches to every match -- read it before trusting section 4.
--
-- Idempotent.
-- ============================================================


-- ------------------------------------------------------------
-- 0) DRY RUN -- how many parties each pattern resolves to
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
-- 1) contacts
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
   'Replied 2026-09-18 through the Greentown warm intro. Challenged whether MBG should be a venture business or a profitable licensing business; happy to continue once that is decided.'),
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
-- 2) corporate domains behind those addresses
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169', d.domain, 'domain',
       'auto: investor contact domain', true
from (values ('foley.com'), ('inquisitive.capital')) as d(domain)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and w.kind = 'domain'
    and lower(w.pattern) = d.domain
);


-- ------------------------------------------------------------
-- 3) the single gmail address -- kind 'address', not 'email'
--    Keeps the free-mail domain closed while letting this sender through.
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169',
       'dcpalter@gmail.com',
       'address',
       'auto: investor contact address (Chemical Angels)',
       true
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and lower(w.pattern) = 'dcpalter@gmail.com'
);


-- ------------------------------------------------------------
-- 4) Verification -- expect three contact rows
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
