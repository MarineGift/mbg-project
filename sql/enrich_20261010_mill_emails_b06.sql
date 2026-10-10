-- ============================================================
-- enrich_20261010_mill_emails_b06.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- 1) Shanying International group inbox sy@shanyingintl.com (shown on the
--    shanyingintl.com home page, crawler 2026-10-10) on the group row and its
--    4 base rows. wu@ on the same page is a personal address with no stated
--    role - not used.
-- 2) Website batch 02 - official sites for two supplier-linked mills:
--      Asia Honour Paper Industries   asiahonourpaper.com
--      Muda Holdings / Muda Paper     muda.com.my
--    Only empty website / domain fields are filled.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, 'sy@shanyingintl.com',
       null, null, null, 'Group inbox (Shanying)',
       true, false, 'homepage', 'Shown on https://www.shanyingintl.com/ (crawler 2026-10-10)'
from (values
  ('8e7e1fc0-3bf1-476c-92b4-d3d20dbb423c'::uuid),
  ('24dd8a21-9a5b-478d-b108-9734f02e427c'::uuid),
  ('7832c9b3-6694-4473-8ee5-cea7b1967ac8'::uuid),
  ('ab259746-82f0-437d-af7b-15587927236e'::uuid),
  ('d2c71cdf-9636-4851-9e16-05e07264e162'::uuid)
) as v(party_id)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = 'sy@shanyingintl.com'
    and c.deleted_at is null
);

update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('6f1136e6-062d-4fdc-b7e6-738e56af8375'::uuid, 'https://www.asiahonourpaper.com', 'asiahonourpaper.com'),
  ('18ecb713-8f25-4201-a594-bf54b97307c4'::uuid, 'https://www.muda.com.my',         'muda.com.my')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, c.email
from app.parties p
left join app.contacts c
  on c.party_id = p.id and c.deleted_at is null and c.email is not null
where p.id in ('8e7e1fc0-3bf1-476c-92b4-d3d20dbb423c'::uuid, '24dd8a21-9a5b-478d-b108-9734f02e427c'::uuid,
               '7832c9b3-6694-4473-8ee5-cea7b1967ac8'::uuid, 'ab259746-82f0-437d-af7b-15587927236e'::uuid,
               'd2c71cdf-9636-4851-9e16-05e07264e162'::uuid, '6f1136e6-062d-4fdc-b7e6-738e56af8375'::uuid,
               '18ecb713-8f25-4201-a594-bf54b97307c4'::uuid)
order by p.party_name;
