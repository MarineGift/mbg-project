-- ============================================================
-- fix_20261010_mill_websites_w01.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 01 - official sites for Missing-email mills that had no
-- website (supplier-linked mills first). With a website the crawler
-- (tools/mill_email_crawl.ps1) can collect the published addresses.
-- Sites confirmed 2026-10-10 from the company's own pages, stock-exchange
-- profiles or its own filings:
--   Shanying International + 4 bases   shanyingintl.com
--   Yueyang Forest & Paper             yypaper.com
--   Century Pulp & Paper               centurypaperindia.com
--   Hokuetsu Corporation               hokuetsucorp.com
--   Emami Paper Mills                  emamipaper.in (letterhead website)
--   Orient Paper & Industries          orientpaper.in
--   Alkim Kagit                        alkimkagit.com.tr
-- Also archives Sabah Forest Industries (in receivership since 2021, mill
-- not operating) - status archived + do_not_contact, nothing deleted.
-- Only empty website / domain fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('8e7e1fc0-3bf1-476c-92b4-d3d20dbb423c'::uuid, 'https://www.shanyingintl.com', 'shanyingintl.com'),
  ('24dd8a21-9a5b-478d-b108-9734f02e427c'::uuid, 'https://www.shanyingintl.com', 'shanyingintl.com'),
  ('7832c9b3-6694-4473-8ee5-cea7b1967ac8'::uuid, 'https://www.shanyingintl.com', 'shanyingintl.com'),
  ('ab259746-82f0-437d-af7b-15587927236e'::uuid, 'https://www.shanyingintl.com', 'shanyingintl.com'),
  ('d2c71cdf-9636-4851-9e16-05e07264e162'::uuid, 'https://www.shanyingintl.com', 'shanyingintl.com'),
  ('a1a8ac1b-c0bb-49fc-91d2-f230e8b388b4'::uuid, 'http://www.yypaper.com',       'yypaper.com'),
  ('9f3719af-21fb-4fb5-b5aa-866416b7231f'::uuid, 'https://www.centurypaperindia.com', 'centurypaperindia.com'),
  ('917824a0-3f42-4817-a155-099fbbe26af8'::uuid, 'https://www.hokuetsucorp.com', 'hokuetsucorp.com'),
  ('9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid, 'https://www.emamipaper.in',    'emamipaper.in'),
  ('cce0b453-be0d-4ff0-84f9-124277fe5af7'::uuid, 'https://www.orientpaper.in',   'orientpaper.in'),
  ('897b7cdb-d073-4fb1-88d5-f4670c8c701a'::uuid, 'https://www.alkimkagit.com.tr', 'alkimkagit.com.tr')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

update app.parties p
set status = 'archived',
    do_not_contact = true,
    do_not_contact_reason = coalesce(p.do_not_contact_reason, 'Defunct - company or mill no longer operating'),
    do_not_contact_set_at = coalesce(p.do_not_contact_set_at, now()),
    updated_at = now()
where p.deleted_at is null
  and p.id = '99a0ef69-a3cf-4be0-b9c3-69f2c842a445'::uuid
  and (p.status is distinct from 'archived' or p.do_not_contact is distinct from true);

select p.party_name, p.website, p.domain_normalized, p.status, p.do_not_contact
from app.parties p
where p.id in ('8e7e1fc0-3bf1-476c-92b4-d3d20dbb423c'::uuid, '24dd8a21-9a5b-478d-b108-9734f02e427c'::uuid,
               '7832c9b3-6694-4473-8ee5-cea7b1967ac8'::uuid, 'ab259746-82f0-437d-af7b-15587927236e'::uuid,
               'd2c71cdf-9636-4851-9e16-05e07264e162'::uuid, 'a1a8ac1b-c0bb-49fc-91d2-f230e8b388b4'::uuid,
               '9f3719af-21fb-4fb5-b5aa-866416b7231f'::uuid, '917824a0-3f42-4817-a155-099fbbe26af8'::uuid,
               '9fba39fa-55cb-48fb-b85c-a8425629c10e'::uuid, 'cce0b453-be0d-4ff0-84f9-124277fe5af7'::uuid,
               '897b7cdb-d073-4fb1-88d5-f4670c8c701a'::uuid, '99a0ef69-a3cf-4be0-b9c3-69f2c842a445'::uuid)
order by p.party_name;
