-- ============================================================
-- fix_20261010_mill_websites_w12.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Domain check for the 7 sites the w11 crawl could not reach (2026-10-10).
-- Confirmed and filled (sites block scripted access, domains are right):
--   Longchen Paper & Packaging  longchenpaper.com   (Taiwan company registry)
--   YFY Inc.                    yfy.com             (Taiwan company registry)
--   Productos Familia           grupofamilia.com    (Essity subsidiary since 2022)
--   UPPC (Calumpit)             ph.scgpackaging.com (SCGP Philippines page)
-- Renamed: Hadera Paper became Infinya Ltd in February 2022 - the row is
--   renamed so search finds it; no confirmed domain, website left empty.
-- Not filled: Ibema (domain not confirmed; Suzano owns 49 percent),
--   UCIC (not checked).
-- Only empty fields are filled. Idempotent. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('dad54b3d-3f4a-48cc-bd25-3eea7741ed67'::uuid, 'https://www.longchenpaper.com', 'longchenpaper.com'),
  ('9d291bcd-d881-4f57-b784-77e510efb313'::uuid, 'https://www.yfy.com',           'yfy.com'),
  ('7e22ae68-9d4b-4722-8b7d-dd3640adb276'::uuid, 'https://www.grupofamilia.com',  'grupofamilia.com'),
  ('679e3010-dced-4ed1-ba32-bdb1ad4df3c5'::uuid, 'https://ph.scgpackaging.com',   'ph.scgpackaging.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

update app.parties p
set party_name = 'Infinya (formerly Hadera Paper)',
    notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '')
            || 'Hadera Paper took the name Infinya Ltd in February 2022 (checked 2026-10-10)',
    updated_at = now()
where p.deleted_at is null
  and p.id = '0e5c0812-22b9-4c0d-b11b-331215e62c69'::uuid
  and p.party_name = 'Hadera Paper';

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id in ('dad54b3d-3f4a-48cc-bd25-3eea7741ed67'::uuid, '9d291bcd-d881-4f57-b784-77e510efb313'::uuid,
               '7e22ae68-9d4b-4722-8b7d-dd3640adb276'::uuid, '679e3010-dced-4ed1-ba32-bdb1ad4df3c5'::uuid,
               '0e5c0812-22b9-4c0d-b11b-331215e62c69'::uuid)
order by p.party_name;
