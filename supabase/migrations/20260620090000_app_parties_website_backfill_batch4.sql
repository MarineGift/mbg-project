-- 20260620090000_app_parties_website_backfill_batch4.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 4 (page-2 Tier B)
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Scope : page-2 (country_code >= 'M') real independent companies.
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : each URL verified against the company's own live site (2026-06-20).
--
-- NOTE: 'Imerys USA' (39aeaeff-6c76-41c6-8ccd-d004bc9d5102) intentionally NOT
--       filled here - no distinct US domain (only global imerys.com), kept NULL
--       for consistency with Imerys China/India (page-1). Apply a parent-domain
--       policy separately if desired.

update app.parties set website = v.url, updated_at = now()
from (values
  ('2c5f4cba-426a-46b5-8e9a-9ba27ee27639', 'https://www.trzuskawica.pl'),  -- Trzuskawica S.A. (CRH) - Poland lime
  ('dc5e760b-0bc9-4a49-8dc9-bec5b269328d', 'https://www.carmeusena.com')   -- Carmeuse USA (Carmeuse North America)
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 2 rows, both with website populated)
select id, party_name, website
from app.parties
where id in (
  '2c5f4cba-426a-46b5-8e9a-9ba27ee27639',
  'dc5e760b-0bc9-4a49-8dc9-bec5b269328d'
)
order by party_name;
