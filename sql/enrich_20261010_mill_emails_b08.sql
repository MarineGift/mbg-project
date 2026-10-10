-- ============================================================
-- enrich_20261010_mill_emails_b08.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 08 - Missing-email mills with no supplier link (outreach track).
-- 1) Websites (only empty fields filled):
--      Packaging Corporation of America + 10 mills   packagingcorp.com
--      N R Agarwal Industries                       nrail.com
--      Star Paper Mills                             starpapers.com
--      Andhra Paper - Kadiyam unit                  andhrapaper.com
-- 2) E-mails printed on the company letterhead of its own stock-exchange
--    filings (BSE / NSE):
--      N R Agarwal       admin@nrail.com
--      Star Paper Mills  star.sre@starpapers.com   (Saharanpur mill letterhead)
--      Andhra Paper      info@andhrapaper.com      (Rajahmundry + Kadiyam rows)
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('8dad6d59-9f75-41d7-94f7-c81b7849287d'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('95b9effe-f74b-4c56-979d-ea92b1e5f86f'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('91158a54-1f1b-439b-8edb-8c59d1e9e075'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('041b70fe-545b-45c9-a927-fbf1ff256f84'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('b27f0a15-a57f-45b1-bf25-ddfd345cc883'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('5c0ec360-6af0-4d73-842c-2351489af735'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('6fe5db18-ed0b-4d64-8ec9-cd45696ea245'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('212e1e58-9362-4c0b-ba17-ce6820cfeaac'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('96ed8f81-2b08-4ba2-b0d5-8bb8e9d153cd'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('1a4beaeb-4f90-4ae5-b5af-9b0869ee7b93'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('5e6a10a2-1d7b-4ee4-9752-bf2d107602d6'::uuid, 'https://www.packagingcorp.com', 'packagingcorp.com'),
  ('d1fd5cd2-f97f-422b-ad02-3dbe6ca00d88'::uuid, 'https://www.nrail.com', 'nrail.com'),
  ('970b9e9c-248c-4075-acf8-9880403aeb31'::uuid, 'https://www.starpapers.com', 'starpapers.com'),
  ('1ba05550-ad2e-40b1-a09f-8805b8775caa'::uuid, 'https://www.andhrapaper.com', 'andhrapaper.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, v.title_text,
       true, false, 'press', v.notes
from (values
  ('d1fd5cd2-f97f-422b-ad02-3dbe6ca00d88'::uuid, 'admin@nrail.com', 'General inbox', 'Company letterhead on BSE disclosure filing, September 2023'),
  ('970b9e9c-248c-4075-acf8-9880403aeb31'::uuid, 'star.sre@starpapers.com', 'Mill inbox (Saharanpur)', 'Saharanpur mill letterhead on NSE/BSE disclosure filings, 2023-2026'),
  ('6ad04789-209f-4df1-b185-24a50c60717d'::uuid, 'info@andhrapaper.com', 'General inbox', 'Company letterhead on BSE disclosure filings, 2023-2024'),
  ('1ba05550-ad2e-40b1-a09f-8805b8775caa'::uuid, 'info@andhrapaper.com', 'Group inbox (Andhra Paper)', 'Company letterhead on BSE disclosure filings, 2023-2024')
) as v(party_id, email, title_text, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select p.party_name, p.website, c.email
from app.parties p
left join app.contacts c
  on c.party_id = p.id and c.deleted_at is null and nullif(btrim(c.email), '') is not null
where p.id in ('041b70fe-545b-45c9-a927-fbf1ff256f84'::uuid, '1a4beaeb-4f90-4ae5-b5af-9b0869ee7b93'::uuid, '1ba05550-ad2e-40b1-a09f-8805b8775caa'::uuid, '212e1e58-9362-4c0b-ba17-ce6820cfeaac'::uuid, '5c0ec360-6af0-4d73-842c-2351489af735'::uuid, '5e6a10a2-1d7b-4ee4-9752-bf2d107602d6'::uuid, '6ad04789-209f-4df1-b185-24a50c60717d'::uuid, '6fe5db18-ed0b-4d64-8ec9-cd45696ea245'::uuid, '8dad6d59-9f75-41d7-94f7-c81b7849287d'::uuid, '91158a54-1f1b-439b-8edb-8c59d1e9e075'::uuid, '95b9effe-f74b-4c56-979d-ea92b1e5f86f'::uuid, '96ed8f81-2b08-4ba2-b0d5-8bb8e9d153cd'::uuid, '970b9e9c-248c-4075-acf8-9880403aeb31'::uuid, 'b27f0a15-a57f-45b1-bf25-ddfd345cc883'::uuid, 'd1fd5cd2-f97f-422b-ad02-3dbe6ca00d88'::uuid)
order by p.party_name;
