-- ============================================================
-- fix_20261010_mill_websites_w08.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 08 - Vietnam:
--   Bai Bang Paper (VINAPACO, Phu Tho)   vinapaco.com.vn
-- The addresses vp.bb@ / bapaco@vinapaco.com.vn appear only in a business
-- directory, so they are not filed here - the crawler checks the company site.
-- Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = 'https://www.vinapaco.com.vn',
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), 'vinapaco.com.vn'),
    updated_at = now()
where p.id = '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id = '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid;
