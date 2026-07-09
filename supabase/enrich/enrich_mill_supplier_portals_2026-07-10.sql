-- enrich_mill_supplier_portals_2026-07-10.sql
-- Consolidated record: mill supplier/vendor contact channel sweep (15 companies)
-- Applied to DB on 2026-07-10 via Supabase editor. Idempotent - safe to re-run.
-- organization_id: b25de8f2-1020-482f-9012-183f63883169
-- Result: 9 portal + 6 web_form. Party names below are exact DB names (verified).
-- HQ parties inserted during sweep: Kimberly-Clark Corporation, Nippon Paper Industries Co., Ltd.

-- HQ inserts (template: type ids copied via International Paper Company row)
INSERT INTO app.parties (party_name, party_type_id, entity_type_id, organization_id, country_code, region, city, website, source)
SELECT 'Kimberly-Clark Corporation', p.party_type_id, p.entity_type_id, p.organization_id, 'US', 'TX', 'Irving', 'https://www.kimberly-clark.com', 'manual'
FROM app.parties p
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name = 'International Paper Company' AND p.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM app.parties x WHERE x.organization_id = p.organization_id AND lower(trim(x.party_name)) = 'kimberly-clark corporation' AND x.deleted_at IS NULL)
LIMIT 1;

INSERT INTO app.parties (party_name, party_type_id, entity_type_id, organization_id, country_code, city, website, source)
SELECT 'Nippon Paper Industries Co., Ltd.', p.party_type_id, p.entity_type_id, p.organization_id, 'JP', 'Tokyo', 'https://www.nipponpapergroup.com', 'manual'
FROM app.parties p
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name = 'International Paper Company' AND p.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM app.parties x WHERE x.organization_id = p.organization_id AND lower(trim(x.party_name)) = 'nippon paper industries co., ltd.' AND x.deleted_at IS NULL)
LIMIT 1;

-- PORTAL (9): procurement systems (Ariba / JAGGAER / Supplier.io / dedicated portals)
UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://internationalpaper.supplierone.co/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'International Paper Company';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://www.gp.com/georgia-pacific-supplier-portal'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Georgia-Pacific';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://pgsupplier.com/become-a-supplier/send-your-profile/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Procter & Gamble (USA)';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://www.sappi.com/en-us/supplier-portal'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Sappi (North America)';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://www.upm.com/about-us/for-suppliers/become-a-supplier/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'UPM';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://storaenso.bravosolution.com/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Stora Enso Oyj';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://portaldofornecedor.suzano.com.br/en/become-a-supplier'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Suzano Papel e Celulose';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://sustainable-procurement.sofidel.com/en/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Sofidel Group';

UPDATE app.parties SET preferred_contact_method = 'portal', contact_form_url = 'https://www.essity.com/company/for-suppliers/how-to-become-a-supplier-to-essity/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Essity';

-- WEB_FORM (6): self-hosted supplier or inquiry forms
UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.smurfitwestrock.com/about/supplier-resources'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Smurfit Westrock plc';

UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.kimberly-clark.com/en-us/suppliers/supplier-engagement'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Kimberly-Clark Corporation';

UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.mondigroup.com/about-mondi/our-suppliers/supplier-application-form/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Mondi (HQ)';

UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.domtar.com/contact-us/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Domtar';

UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.ojiholdings.co.jp/en/contact/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Oji Holdings Corporation';

UPDATE app.parties SET preferred_contact_method = 'web_form', contact_form_url = 'https://www.nipponpapergroup.com/english/inquire/'
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' AND deleted_at IS NULL AND party_name = 'Nippon Paper Industries Co., Ltd.';

-- Verification: expect 15 rows (9 portal + 6 web_form)
SELECT party_name, preferred_contact_method, contact_form_url
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL AND preferred_contact_method IN ('portal', 'web_form') AND party_type_id = 2
ORDER BY preferred_contact_method, party_name;