-- ============================================================
-- fix_20261010_mill_websites_w09.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 09 - UK / Canada (no supplier link):
--   James Cropper plc (Burneside)   jamescropper.com
--     website on Wikipedia infobox and its own annual report 2023
--   Kruger Products LP              krugerproducts.ca
--   Mercer International            mercerint.com
--     well-known corporate domains - to be confirmed by the crawler run
--     (only kept if the crawl reaches the site; see the notes in the reply)
-- Personal addresses on the UK charity register (James Cropper staff) are
-- not used. Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid, 'https://www.jamescropper.com', 'jamescropper.com'),
  ('5044479c-3b33-42e0-9898-4a86646e50f5'::uuid, 'https://www.krugerproducts.ca', 'krugerproducts.ca'),
  ('7e4dde04-533d-4130-be3e-4cfdc1019ba8'::uuid, 'https://www.mercerint.com', 'mercerint.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id in ('7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid, '5044479c-3b33-42e0-9898-4a86646e50f5'::uuid,
               '7e4dde04-533d-4130-be3e-4cfdc1019ba8'::uuid)
order by p.party_name;
