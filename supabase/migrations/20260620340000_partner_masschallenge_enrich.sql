-- ============================================================
-- Enrich existing partner row: MassChallenge (already party_type=6, intros present)
-- Fills only NULL fields (website, country/region/city, source). Intros untouched.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent (coalesce fills nulls only).
-- Target row id confirmed 2026-06-20: a2b16c18-302c-49c0-87e6-9e2e235d134a
-- ============================================================

update app.parties
set website      = coalesce(website, 'https://masschallenge.org'),
    country_code = coalesce(country_code, 'US'),
    region       = coalesce(region, 'Massachusetts'),
    city         = coalesce(city, 'Boston'),
    source       = coalesce(source, 'manual_partner_accelerators_2026Q2'),
    updated_at   = now()
where id = 'a2b16c18-302c-49c0-87e6-9e2e235d134a'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and party_type_id = coalesce((select id from app.party_types where code = 'partner'), 6)
  and deleted_at is null;

-- Verification
select party_name, party_type_id, source, country_code, region, city,
       website, (intro_ko is not null) as ko, (intro_en is not null) as en
from app.parties
where id = 'a2b16c18-302c-49c0-87e6-9e2e235d134a';