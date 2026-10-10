-- ============================================================
-- fix_20261010_mill_websites_w06.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 06 - Turkey (no supplier link, outreach track):
--   Viking Kagit ve Seluloz (Aliaga, Yasar Holding)   viking.com.tr
--     web address on its Borsa Istanbul issuer profile
--   Lila Kagit (Ergene / Erzurum)                     lilakagit.com
--     domain of the company e-mail in its KAP interim activity report
-- Both listed e-mails are investor-relations inboxes - not used. The crawler
-- is run on the sites. Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('f4b8a163-7bca-43d8-a4a1-05eb77a21feb'::uuid, 'https://www.viking.com.tr', 'viking.com.tr'),
  ('41dff19b-a087-4cbe-bccc-97bf5341cc3e'::uuid, 'https://www.lilakagit.com', 'lilakagit.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id in ('f4b8a163-7bca-43d8-a4a1-05eb77a21feb'::uuid, '41dff19b-a087-4cbe-bccc-97bf5341cc3e'::uuid);
