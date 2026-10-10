-- ============================================================
-- enrich_20261010_mill_emails_b02.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 02 - addresses collected by tools/mill_email_crawl.ps1 from each
-- company's own site, then reviewed by hand. 59 rows / 56 mills.
-- Rules applied in review:
--   kept     general, sales, customer-service and mill/base-specific inboxes
--   dropped  IR, media/press, HR/careers, GDPR/KVKK, compliance, webmaster,
--            no-reply, agency and data-protection addresses
--   dropped  personal addresses whose role the page does not state
--   ND Paper base inboxes only where the suffix plainly names the base
--   (tj, cq, ls, qz, sy, tc). Beihai, Hebei, Hubei, Malaysia left for later
-- Idempotent: an address already on the party is skipped.
-- Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email,
       null, null, null, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from (values
  ('913b37b7-dd16-4e50-88ec-3831dc5af687'::uuid, 'info@aitkenspence.lk', 'General inbox', true, 'Shown on https://aitkenspence.com/ (crawler 2026-10-10)'),
  ('8b3cd061-aac9-4f47-a4f9-e85422fda422'::uuid, 'info.paper@bgc-bd.com', 'General inbox', true, 'Shown on https://www.bashundharapapermills.com/ (crawler 2026-10-10)'),
  ('8b3cd061-aac9-4f47-a4f9-e85422fda422'::uuid, 'cs.bpml@bgc-bd.com', 'Customer service inbox', false, 'Shown on https://www.bashundharapapermills.com/contact (crawler 2026-10-10)'),
  ('32c4c745-dd70-4312-85d2-a80fda4cd857'::uuid, 'contactus@billerud.com', 'General inbox', true, 'Shown on https://www.billerud.com/contact (crawler 2026-10-10)'),
  ('2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid, 'contactus@billerud.com', 'General inbox', true, 'Shown on https://www.billerud.com/contact (crawler 2026-10-10)'),
  ('20542502-5c71-406c-993f-3b357bf0c672'::uuid, 'info@canfor.com', 'General inbox', true, 'Shown on https://www.canfor.com/contact (crawler 2026-10-10)'),
  ('2a3eb144-6dda-40cd-af1d-f6b948ea6018'::uuid, 'contact@cascades.com', 'General inbox', true, 'Shown on https://www.cascades.com/en/contact-us (crawler 2026-10-10)'),
  ('17b713d9-28fd-49d0-a3c5-6766f736beb7'::uuid, 'tervakoski@delfortgroup.com', 'Mill inbox (Tervakoski)', true, 'Shown on https://delfortgroup.com/ (crawler 2026-10-10)'),
  ('37040d42-b0a4-4d3f-90e5-c3415d3c9cbb'::uuid, 'faleconosco@eldoradobrasil.com.br', 'General inbox', true, 'Shown on https://www.eldoradobrasil.com.br/pb/ (crawler 2026-10-10)'),
  ('4137629a-a890-4856-b795-4cd129f52925'::uuid, 'info@fedrigoni.com', 'General inbox', true, 'Shown on https://fedrigoni.com/contatti/ (crawler 2026-10-10)'),
  ('c81a71bd-6191-4f8a-a12b-83f3a12fd0da'::uuid, 'info@fedrigoni.com', 'General inbox', true, 'Shown on https://fedrigoni.com/contatti/ (crawler 2026-10-10)'),
  ('d3ced3a7-4612-4a8f-ae6f-2586d6142e61'::uuid, 'info@fedrigoni.com', 'General inbox', true, 'Shown on https://fedrigoni.com/contatti/ (crawler 2026-10-10)'),
  ('d9fefd12-d516-43d0-9d00-ad6653c9f23f'::uuid, 'info@fedrigoni.com', 'General inbox', true, 'Shown on https://fedrigoni.com/contatti/ (crawler 2026-10-10)'),
  ('759be160-8313-4df0-9448-1e51b4486c05'::uuid, 'mail@fabriano.com', 'General inbox (Fabriano)', true, 'Shown on https://fedrigoni.com/contatti/ (crawler 2026-10-10)'),
  ('82ebf0bf-372b-4b2a-b13c-bd4c2f7dec08'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('a365bdcf-2097-447f-8244-24f0c9242c0d'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('9dfc2a7a-30a6-4782-a5e7-b71d2d812267'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('d3e5e182-cb96-4fec-bb05-815b1fad0be7'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('1531840c-bfc2-49d3-932a-c2b0c49cc492'::uuid, 'info@holmen.com', 'General inbox', true, 'Shown on https://www.holmen.com/ (crawler 2026-10-10)'),
  ('7c847abc-fa34-4d45-8f7b-b713ee7dc7fb'::uuid, 'info@kipaskagit.com.tr', 'General inbox', true, 'Shown on https://kipaskagit.com.tr/tr-TR/iletisim (crawler 2026-10-10)'),
  ('a8ff9f12-61fb-4481-8c3d-89c3c45efb26'::uuid, 'office@lenzing.com', 'General inbox', true, 'Shown on https://www.lenzing.com/ (crawler 2026-10-10)'),
  ('88ca497f-c47c-403d-81db-136286e77e8c'::uuid, 'myc@miquelycostas.com', 'General inbox', true, 'Shown on https://miquelycostas.com/ (crawler 2026-10-10)'),
  ('cd039913-b0c9-4deb-a128-eb6f94457b00'::uuid, 'kwidzyn@mm.group', 'Mill inbox (Kwidzyn)', true, 'Shown on https://mm.group/locations/ (crawler 2026-10-10)'),
  ('b647f87e-4b85-4ee9-bc3d-c32ccac6747c'::uuid, 'modernkarton@modernkarton.com.tr', 'General inbox', true, 'Shown on https://modernkarton.com.tr/ (crawler 2026-10-10)'),
  ('b647f87e-4b85-4ee9-bc3d-c32ccac6747c'::uuid, 'mksatis@modernkarton.com.tr', 'Sales inbox', false, 'Shown on https://modernkarton.com.tr/sayfa/iletisim-12 (crawler 2026-10-10)'),
  ('8d19cb27-3128-4796-96e1-499aab16415d'::uuid, 'contacto@montesdelplata.com.uy', 'General inbox', true, 'Shown on https://montesdelplata.com.uy/ (crawler 2026-10-10)'),
  ('b267715c-95f4-49b3-abfb-26de334e2cbb'::uuid, 'info@mpact.co.za', 'General inbox', true, 'Shown on https://www.mpact.co.za/ (crawler 2026-10-10)'),
  ('7a1e58d0-1373-4ec6-bc94-b952b70132bd'::uuid, 'info@mpact.co.za', 'General inbox', true, 'Shown on https://www.mpact.co.za/ (crawler 2026-10-10)'),
  ('344a7714-a3f5-44a0-92c2-b4f3d582d93e'::uuid, 'info@mpact.co.za', 'General inbox', true, 'Shown on https://www.mpact.co.za/ (crawler 2026-10-10)'),
  ('8132970c-468e-4077-8a9d-65bf0946db9e'::uuid, 'info_group@ndpaper.com', 'Group inbox', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('5584302b-72db-412b-a565-df8e94201e4d'::uuid, 'info_group@ndpaper.com', 'Group inbox', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('5dd0b290-6433-4645-aa25-d9b7d289de28'::uuid, 'info_tj@ndpaper.com', 'Base inbox (Tianjin)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('f6187cca-50a8-47d7-92bf-599815ce810c'::uuid, 'info_cq@ndpaper.com', 'Base inbox (Chongqing)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('90db44cf-b80e-41b3-a572-89b388256482'::uuid, 'info_ls@ndpaper.com', 'Base inbox (Leshan)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('8e336456-8975-45db-ac4f-46c56965dce2'::uuid, 'info_qz@ndpaper.com', 'Base inbox (Quanzhou)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('f83a0118-5eba-4a5a-92b1-7be8569a06d3'::uuid, 'info_sy@ndpaper.com', 'Base inbox (Shenyang)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('b367fff5-e352-4f3b-936e-c9c0a30247aa'::uuid, 'info_tc@ndpaper.com', 'Base inbox (Taicang)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('8663d702-15c1-43b2-92b0-7bd1c51c82f0'::uuid, 'chengyang@ndpaper.com.vn', 'Mill inbox (Cheng Yang)', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('55f04c50-e660-4fb3-a7b5-301f19823813'::uuid, 'customerservice@us.ndpaper.com', 'Customer service inbox', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('e9cec2dc-b308-4eb0-bc45-1dee717445cb'::uuid, 'customerservice@us.ndpaper.com', 'Customer service inbox', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('8588c86b-35c7-4a40-aa3f-5c1c943d82d0'::uuid, 'customerservice@us.ndpaper.com', 'Customer service inbox', true, 'Shown on https://ndpaper.com/en/contact/contact.php (crawler 2026-10-10)'),
  ('b07fec64-e144-4a6a-ba45-6fdf821b02eb'::uuid, 'info@norskeskog.com', 'General inbox', true, 'Shown on https://www.norskeskog.com/ (crawler 2026-10-10)'),
  ('3bd842e8-93f9-4718-a287-006e225f6cff'::uuid, 'info@norskeskog.com', 'General inbox', true, 'Shown on https://www.norskeskog.com/ (crawler 2026-10-10)'),
  ('60c6b496-a5c1-4a3d-b473-213fbd6ee144'::uuid, 'info@norskeskog.com', 'General inbox', true, 'Shown on https://www.norskeskog.com/ (crawler 2026-10-10)'),
  ('4c89e9cd-66d1-45d8-9ea2-6abfb038f421'::uuid, 'info@norskeskog.com', 'General inbox', true, 'Shown on https://www.norskeskog.com/ (crawler 2026-10-10)'),
  ('088103d9-7408-4619-89b1-444c3d758254'::uuid, 'paper@palm.de', 'Paper division inbox', true, 'Shown on https://www.palm.de/kontakt.html (crawler 2026-10-10)'),
  ('de87ce0d-f021-4849-bfd5-a072ef5cc27e'::uuid, 'sales@porthawkesburypaper.com', 'Sales inbox', true, 'Shown on https://www.porthawkesburypaper.com/legal-information.html (crawler 2026-10-10)'),
  ('de87ce0d-f021-4849-bfd5-a072ef5cc27e'::uuid, 'customerservice@porthawkesburypaper.com', 'Customer service inbox', false, 'Shown on https://www.porthawkesburypaper.com/contacts.html (crawler 2026-10-10)'),
  ('86b571f4-420b-48de-a714-30026ee4c4d1'::uuid, 'comercial.paper@saica.com', 'Paper sales inbox', true, 'Shown on https://www.saica.com/es/contacto/ (crawler 2026-10-10)'),
  ('335a80bc-648d-4e78-908e-0a4487a7b287'::uuid, 'comercial.paper@saica.com', 'Paper sales inbox', true, 'Shown on https://www.saica.com/es/contacto/ (crawler 2026-10-10)'),
  ('4c43d397-607c-4fe4-84ec-74206d740345'::uuid, 'tl@thallimited.com', 'General inbox', true, 'Shown on https://thallimited.com/contact-us (crawler 2026-10-10)'),
  ('bba55e7f-41ad-4ed0-bfd2-bbad0d6b74bf'::uuid, 'sales@thenavigatorcompany.com', 'Sales inbox', true, 'Shown on https://thenavigatorcompany.com/institucional/a-empresa-no-mundo/ (crawler 2026-10-10)'),
  ('a336b16b-27d4-4153-ba11-c1bd8c594d81'::uuid, 'sales@thenavigatorcompany.com', 'Sales inbox', true, 'Shown on https://thenavigatorcompany.com/institucional/a-empresa-no-mundo/ (crawler 2026-10-10)'),
  ('590025b8-d703-4c70-82bc-a0df8c700392'::uuid, 'sales@thenavigatorcompany.com', 'Sales inbox', true, 'Shown on https://thenavigatorcompany.com/institucional/a-empresa-no-mundo/ (crawler 2026-10-10)'),
  ('de6e3565-151f-45c7-b3c5-fd7137ee37d7'::uuid, 'sales@thenavigatorcompany.com', 'Sales inbox', true, 'Shown on https://thenavigatorcompany.com/institucional/a-empresa-no-mundo/ (crawler 2026-10-10)'),
  ('eb10193f-4b97-4257-8bf9-f97b1dac30a4'::uuid, 'sales@thuananpaper.com', 'Sales inbox', true, 'Shown on https://thuananpaper.com/ (crawler 2026-10-10)'),
  ('3e3b5378-486e-4e0a-a3aa-6993ab0c64e2'::uuid, 'marketing@visy.com.au', 'Marketing inbox', true, 'Shown on https://www.visy.com/ (crawler 2026-10-10)'),
  ('e213808a-12fc-4cbf-898c-355a31133a3d'::uuid, 'info.france@wepa.eu', 'General inbox (France)', true, 'Shown on https://www.wepa.eu/de/kontakt (crawler 2026-10-10)')
) as v(party_id, email, title_text, is_primary, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select count(distinct c.party_id) as mills_with_email_now,
       count(*) as email_rows
from app.contacts c
where c.deleted_at is null
  and nullif(btrim(c.email), '') is not null
  and c.party_id in ('088103d9-7408-4619-89b1-444c3d758254'::uuid, '1531840c-bfc2-49d3-932a-c2b0c49cc492'::uuid, '17b713d9-28fd-49d0-a3c5-6766f736beb7'::uuid, '20542502-5c71-406c-993f-3b357bf0c672'::uuid, '2a3eb144-6dda-40cd-af1d-f6b948ea6018'::uuid, '2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid, '32c4c745-dd70-4312-85d2-a80fda4cd857'::uuid, '335a80bc-648d-4e78-908e-0a4487a7b287'::uuid, '344a7714-a3f5-44a0-92c2-b4f3d582d93e'::uuid, '37040d42-b0a4-4d3f-90e5-c3415d3c9cbb'::uuid, '3bd842e8-93f9-4718-a287-006e225f6cff'::uuid, '3e3b5378-486e-4e0a-a3aa-6993ab0c64e2'::uuid, '4137629a-a890-4856-b795-4cd129f52925'::uuid, '4c43d397-607c-4fe4-84ec-74206d740345'::uuid, '4c89e9cd-66d1-45d8-9ea2-6abfb038f421'::uuid, '5584302b-72db-412b-a565-df8e94201e4d'::uuid, '55f04c50-e660-4fb3-a7b5-301f19823813'::uuid, '590025b8-d703-4c70-82bc-a0df8c700392'::uuid, '5dd0b290-6433-4645-aa25-d9b7d289de28'::uuid, '60c6b496-a5c1-4a3d-b473-213fbd6ee144'::uuid, '759be160-8313-4df0-9448-1e51b4486c05'::uuid, '7a1e58d0-1373-4ec6-bc94-b952b70132bd'::uuid, '7c847abc-fa34-4d45-8f7b-b713ee7dc7fb'::uuid, '8132970c-468e-4077-8a9d-65bf0946db9e'::uuid, '82ebf0bf-372b-4b2a-b13c-bd4c2f7dec08'::uuid, '8588c86b-35c7-4a40-aa3f-5c1c943d82d0'::uuid, '8663d702-15c1-43b2-92b0-7bd1c51c82f0'::uuid, '86b571f4-420b-48de-a714-30026ee4c4d1'::uuid, '88ca497f-c47c-403d-81db-136286e77e8c'::uuid, '8b3cd061-aac9-4f47-a4f9-e85422fda422'::uuid, '8d19cb27-3128-4796-96e1-499aab16415d'::uuid, '8e336456-8975-45db-ac4f-46c56965dce2'::uuid, '90db44cf-b80e-41b3-a572-89b388256482'::uuid, '913b37b7-dd16-4e50-88ec-3831dc5af687'::uuid, '9dfc2a7a-30a6-4782-a5e7-b71d2d812267'::uuid, 'a336b16b-27d4-4153-ba11-c1bd8c594d81'::uuid, 'a365bdcf-2097-447f-8244-24f0c9242c0d'::uuid, 'a8ff9f12-61fb-4481-8c3d-89c3c45efb26'::uuid, 'b07fec64-e144-4a6a-ba45-6fdf821b02eb'::uuid, 'b267715c-95f4-49b3-abfb-26de334e2cbb'::uuid, 'b367fff5-e352-4f3b-936e-c9c0a30247aa'::uuid, 'b647f87e-4b85-4ee9-bc3d-c32ccac6747c'::uuid, 'bba55e7f-41ad-4ed0-bfd2-bbad0d6b74bf'::uuid, 'c81a71bd-6191-4f8a-a12b-83f3a12fd0da'::uuid, 'cd039913-b0c9-4deb-a128-eb6f94457b00'::uuid, 'd3ced3a7-4612-4a8f-ae6f-2586d6142e61'::uuid, 'd3e5e182-cb96-4fec-bb05-815b1fad0be7'::uuid, 'd98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'd9fefd12-d516-43d0-9d00-ad6653c9f23f'::uuid, 'de6e3565-151f-45c7-b3c5-fd7137ee37d7'::uuid, 'de87ce0d-f021-4849-bfd5-a072ef5cc27e'::uuid, 'e213808a-12fc-4cbf-898c-355a31133a3d'::uuid, 'e9cec2dc-b308-4eb0-bc45-1dee717445cb'::uuid, 'eb10193f-4b97-4257-8bf9-f97b1dac30a4'::uuid, 'f6187cca-50a8-47d7-92bf-599815ce810c'::uuid, 'f83a0118-5eba-4a5a-92b1-7be8569a06d3'::uuid);
