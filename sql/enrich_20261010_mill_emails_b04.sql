-- ============================================================
-- enrich_20261010_mill_emails_b04.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Paper mill batch 04 - retry crawl (crawler v2).
-- 10 rows / 8 parties. Addresses collected by tools/mill_email_crawl.ps1
-- on each company's own site and reviewed by hand.
-- Dropped: contacto@bioppael.com (typo on the site), Clearwater (IR only),
--   Bracell press agency, Packages share desk / careers / whistleblowing / FAMCO.
-- Idempotent: an address already on the party is skipped.
-- Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email,
       null, null, null, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from (values
  ('1eec3bdc-a16b-4846-9edb-18e4247e1431'::uuid, 'contacto@biopappel.com', 'General inbox', true, 'Shown on https://biopappel.com/ (crawler 2026-10-10)'),
  ('0da21f57-e4cb-4360-af23-22f1d1690623'::uuid, 'contacto@biopappel.com', 'General inbox', true, 'Shown on https://biopappel.com/ (crawler 2026-10-10)'),
  ('9a619bd5-7a76-4d81-8e26-08c9b36cf80c'::uuid, 'contacto@biopappel.com', 'General inbox', true, 'Shown on https://biopappel.com/ (crawler 2026-10-10)'),
  ('3c7d129f-5e27-48a2-a6b8-65ee11c33e21'::uuid, 'contacto@biopappel.com', 'General inbox', true, 'Shown on https://biopappel.com/ (crawler 2026-10-10)'),
  ('b7582406-58c5-415a-8c24-fce6fea97365'::uuid, 'contacto@biopappel.com', 'General inbox', true, 'Shown on https://biopappel.com/ (crawler 2026-10-10)'),
  ('c5068a5d-d973-4ca6-adf9-57a25585f296'::uuid, 'sac@bracell.com', 'Customer service inbox', true, 'Shown on https://www.bracell.com/ (crawler 2026-10-10)'),
  ('c5068a5d-d973-4ca6-adf9-57a25585f296'::uuid, 'faleconoscosp@bracell.com', 'Contact inbox (Sao Paulo)', false, 'Shown on https://www.bracell.com/contato/ (crawler 2026-10-10)'),
  ('dedc9cf2-b21d-46ed-b57d-15a21aa5a1da'::uuid, 'info@packages.com.pk', 'General inbox', true, 'Shown on https://www.packages.com.pk/ (crawler 2026-10-10)'),
  ('dedc9cf2-b21d-46ed-b57d-15a21aa5a1da'::uuid, 'sales@packages.com.pk', 'Sales inbox', false, 'Shown on https://www.packages.com.pk/contact-us/ (crawler 2026-10-10)'),
  ('8eab1187-d1a4-4f5c-9203-eb3a2bfa2d95'::uuid, 'info@packages.com.pk', 'Group inbox (Packages)', true, 'Shown on https://www.packages.com.pk/ (crawler 2026-10-10)')
) as v(party_id, email, title_text, is_primary, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select count(distinct c.party_id) as parties_with_email_now,
       count(*) as email_rows
from app.contacts c
where c.deleted_at is null
  and nullif(btrim(c.email), '') is not null
  and c.party_id in ('0da21f57-e4cb-4360-af23-22f1d1690623'::uuid, '1eec3bdc-a16b-4846-9edb-18e4247e1431'::uuid, '3c7d129f-5e27-48a2-a6b8-65ee11c33e21'::uuid, '8eab1187-d1a4-4f5c-9203-eb3a2bfa2d95'::uuid, '9a619bd5-7a76-4d81-8e26-08c9b36cf80c'::uuid, 'b7582406-58c5-415a-8c24-fce6fea97365'::uuid, 'c5068a5d-d973-4ca6-adf9-57a25585f296'::uuid, 'dedc9cf2-b21d-46ed-b57d-15a21aa5a1da'::uuid);
