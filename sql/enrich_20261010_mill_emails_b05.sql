-- ============================================================
-- enrich_20261010_mill_emails_b05.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 05 - web research on Missing-email mills that are linked to a filler
-- supplier. Only addresses the company itself publishes (letterhead on its
-- stock-exchange filings, or its official disclosure-platform profile).
--   Emami Paper Mills (Balasore)   balasore@ unit inbox + emamipaper@ HQ inbox
--   Orient Paper & Industries      info@opil.in (letterhead, Dec 2024 filing)
--   Alkim Kagit                    info@alkimkagit.com.tr (KAP company profile)
-- Searched, nothing usable: Century Pulp & Paper, ABC Paper, MEPPCO (Egypt),
--   Muda Paper Mills - only data-broker pages, not used.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email,
       null, null, null, v.title_text,
       v.is_primary, false, v.source, v.notes
from (values
  ('9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid, 'balasore@emamipaper.com', 'Mill inbox (Balasore unit)', true, 'press',
   'Balasore unit address on Emami Paper letterhead, results filing hosted on emamipaper.com (2021)'),
  ('9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid, 'emamipaper@emamipaper.com', 'HQ inbox (Kolkata)', false, 'press',
   'Registered office address on Emami Paper letterhead, results filing hosted on emamipaper.com (2021)'),
  ('cce0b453-be0d-4ff0-84f9-124277fe5af7'::uuid, 'info@opil.in', 'General inbox', true, 'press',
   'Company letterhead on NSE disclosure filing, December 2024'),
  ('897b7cdb-d073-4fb1-88d5-f4670c8c701a'::uuid, 'info@alkimkagit.com.tr', 'General inbox', true, 'registry',
   'Company e-mail on its KAP (Public Disclosure Platform) profile, checked 2026-10-10')
) as v(party_id, email, title_text, is_primary, source, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select p.party_name, c.email, c.title_text, c.is_primary
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.email is not null
  and c.party_id in ('9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid,
                     'cce0b453-be0d-4ff0-84f9-124277fe5af7'::uuid,
                     '897b7cdb-d073-4fb1-88d5-f4670c8c701a'::uuid)
order by p.party_name, c.is_primary desc;
