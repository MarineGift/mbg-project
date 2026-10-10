-- ============================================================
-- enrich_20261010_mill_emails_b03.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 03 - Norske Skog Technical Customer Service (TCS) people.
-- Source page: norskeskog.com/sales-and-support/technical-customer-service
-- The page names the mill each person serves, so each is attached to that
-- mill only:
--   Bruck (AT)      Boris Voegeler          (publication + packaging paper)
--   Skogn (NO)      Havar Fjerdingen, Magni Ranes
--   Golbey (FR)     Stephan Simeray          matched by party name
--   Saugbrugs (NO)  Ole Anders Jansen        matched by party name
-- Sales-office TCS staff (France, Deutschland, UK) are not attached - those
-- rows are sales offices, not mills.
-- Boyer (AU) and Norske Skog Finland have no TCS entry on the page.
-- Not primary - the group inbox info@norskeskog.com stays the primary.
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- 1) Mills from the worklist, by id
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email,
       v.given_name, v.family_name, v.given_name || ' ' || v.family_name, v.title_text,
       false, false, 'homepage',
       'Listed on norskeskog.com technical customer service page (2026-10-10)'
from (values
  ('b07fec64-e144-4a6a-ba45-6fdf821b02eb'::uuid, 'boris.voegeler@norskeskog.com',
   'Boris', $n$Vögeler$n$, 'Technical Customer Service - publication and packaging paper'),
  ('4c89e9cd-66d1-45d8-9ea2-6abfb038f421'::uuid, 'havar.fjerdingen@norskeskog.com',
   $n$Håvar$n$, 'Fjerdingen', 'Technical Customer Service - publication paper'),
  ('4c89e9cd-66d1-45d8-9ea2-6abfb038f421'::uuid, 'magni.ranes@norskeskog.com',
   'Magni', 'Ranes', 'Technical Customer Service - publication paper')
) as v(party_id, email, given_name, family_name, title_text)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

-- 2) Mills that already had an email, matched by name (skipped if no match)
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 2, v.email,
       v.given_name, v.family_name, v.given_name || ' ' || v.family_name, v.title_text,
       false, false, 'homepage',
       'Listed on norskeskog.com technical customer service page (2026-10-10)'
from (values
  ('norske skog golbey%', 'stephan.simeray@norskeskog.com',
   'Stephan', 'Simeray', 'Technical Customer Service - publication paper'),
  ('norske skog saugbrugs%', 'ole-anders.jansen@norskeskog.com',
   'Ole Anders', 'Jansen', 'Technical Customer Service - publication paper')
) as v(name_pat, email, given_name, family_name, title_text)
join app.parties p
  on p.deleted_at is null
 and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
 and lower(p.party_name) like v.name_pat
join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
where not exists (
  select 1 from app.contacts c
  where c.party_id = p.id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

-- 3) Verify - every Norske Skog mill and its e-mail contacts
select p.party_name, p.country_code, c.email, c.full_name, c.title_text, c.is_primary
from app.parties p
join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
left join app.contacts c
  on c.party_id = p.id and c.deleted_at is null and nullif(btrim(c.email), '') is not null
where p.deleted_at is null
  and p.party_name ilike 'norske skog%'
order by p.party_name, c.is_primary desc nulls last, c.email;
