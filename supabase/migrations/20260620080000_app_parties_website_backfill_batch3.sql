-- 20260620080000_app_parties_website_backfill_batch3.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 3
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Scope : Ashapura Group rows (page-1 long tail). Both rows are Ashapura
--         Group divisions; ashapura.com is the single official group site
--         (it hosts the White Performance Minerals section directly).
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : ashapura.com verified as the live official group site (2026-06-20).

update app.parties set website = v.url, updated_at = now()
from (values
  ('53a7435e-5761-449d-a6ea-fe1628cc0b50', 'https://www.ashapura.com'),  -- Ashapura Group / Ashapura Microns
  ('34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d', 'https://www.ashapura.com')   -- Ashapura Kaolin / White Performance Minerals
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 2 rows, both with website populated)
select id, party_name, website
from app.parties
where id in (
  '53a7435e-5761-449d-a6ea-fe1628cc0b50',
  '34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'
)
order by party_name;
