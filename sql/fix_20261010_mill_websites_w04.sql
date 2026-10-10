-- ============================================================
-- fix_20261010_mill_websites_w04.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 04 - Indonesia (no supplier link, outreach track):
--   PT Fajar Surya Wisesa Tbk   fajarpaper.com      (now an SCGP subsidiary)
--   PT Suparma Tbk              ptsuparmatbk.com
-- Sites confirmed from the IDX issuer profiles and company pages, 2026-10-10.
-- The only e-mails those profiles list are ir@ and corp.sec@ (investor /
-- corporate-secretary inboxes) - not used. The crawler is run on the sites.
-- Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('27e7ef83-0dad-443b-b63f-1bd7bbc36c60'::uuid, 'https://www.fajarpaper.com',   'fajarpaper.com'),
  ('8899cba0-f6e3-4ad3-8e60-13ef34a09a23'::uuid, 'https://www.ptsuparmatbk.com', 'ptsuparmatbk.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id in ('27e7ef83-0dad-443b-b63f-1bd7bbc36c60'::uuid, '8899cba0-f6e3-4ad3-8e60-13ef34a09a23'::uuid);
