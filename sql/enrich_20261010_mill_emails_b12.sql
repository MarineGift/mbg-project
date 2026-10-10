-- ============================================================
-- enrich_20261010_mill_emails_b12.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 12 - Vietnam:
--   Saigon Paper Corporation   contact@saigonpaper.com
--     shown on the saigonpaper.com home page (crawler 2026-10-10)
--   DOHACO (Dong Hai Ben Tre)  donghai@dohacobentre.com + website
--     company e-mail and site in its own annual reports 2022 and 2024
--     (an old yahoo address in the 2017 report is not used)
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set website = 'https://www.dohacobentre.com.vn',
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), 'dohacobentre.com.vn'),
    updated_at = now()
where p.id = '8adfe40f-e4dc-4302-a0b7-81f082c3066b'::uuid
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, 'General inbox',
       true, false, v.source, v.notes
from (values
  ('05f07dcf-80c0-4a63-811f-c6a51a0565f2'::uuid, 'contact@saigonpaper.com', 'homepage',
   'Shown on https://saigonpaper.com/ (crawler 2026-10-10)'),
  ('8adfe40f-e4dc-4302-a0b7-81f082c3066b'::uuid, 'donghai@dohacobentre.com', 'press',
   'Company e-mail in DOHACO annual reports 2022 and 2024')
) as v(party_id, email, source, notes)
where exists (select 1 from app.parties p where p.id = v.party_id and p.deleted_at is null)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = v.party_id
      and lower(c.email) = lower(v.email)
      and c.deleted_at is null
  );

select p.party_name, p.website, c.email
from app.parties p
left join app.contacts c
  on c.party_id = p.id and c.deleted_at is null and nullif(btrim(c.email), '') is not null
where p.id in ('05f07dcf-80c0-4a63-811f-c6a51a0565f2'::uuid, '8adfe40f-e4dc-4302-a0b7-81f082c3066b'::uuid)
order by p.party_name;
