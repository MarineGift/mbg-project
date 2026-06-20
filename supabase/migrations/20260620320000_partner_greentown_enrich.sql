-- ============================================================
-- Enrich existing partner row: Greentown Labs (already party_type=6, intros present)
-- Fills only the NULL fields (website, country/region/city, source). Intros untouched.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent (coalesce fills nulls only).
-- Target row id confirmed 2026-06-20: be0ab5ca-4538-4a65-827a-af3f94cd11f6
-- ============================================================

update app.parties
set website      = coalesce(website, 'https://greentownlabs.com'),
    country_code = coalesce(country_code, 'US'),
    region       = coalesce(region, 'Massachusetts'),
    city         = coalesce(city, 'Somerville'),
    source       = coalesce(source, 'manual_partner_funding_2026Q2'),
    updated_at   = now()
where id = 'be0ab5ca-4538-4a65-827a-af3f94cd11f6'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and party_type_id = coalesce((select id from app.party_types where code = 'partner'), 6)
  and deleted_at is null;

-- Verification
select party_name, party_type_id, source, country_code, region, city,
       website, (intro_ko is not null) as ko, (intro_en is not null) as en
from app.parties
where id = 'be0ab5ca-4538-4a65-827a-af3f94cd11f6';
