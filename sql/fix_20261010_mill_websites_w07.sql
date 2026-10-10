-- ============================================================
-- fix_20261010_mill_websites_w07.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 07 - Vietnam:
--   Saigon Paper Corporation (My Xuan 1 + 2, Sojitz group since 2018)
--     saigonpaper.com - company site as listed on its own job-board employer
--     profiles. contact@saigonpaper.com appears only on a vendor case-study
--     page, so it is not filed - the crawler checks the company site itself.
-- Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = 'https://www.saigonpaper.com',
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), 'saigonpaper.com'),
    updated_at = now()
where p.id = '05f07dcf-80c0-4a63-811f-c6a51a0565f2'::uuid
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id = '05f07dcf-80c0-4a63-811f-c6a51a0565f2'::uuid;
