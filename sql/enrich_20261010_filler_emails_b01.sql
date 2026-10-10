-- ============================================================
-- enrich_20261010_filler_emails_b01.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Filler supplier batch 01. SMI and Omya rows are licensees and not in scope.
-- 23 rows / 19 parties. Addresses collected by tools/mill_email_crawl.ps1
-- on each company's own site and reviewed by hand.
-- Dropped: personal addresses with no stated role (Nordkalk 45, Trzuskawica 7,
--   Gulshan 3, Yamuna 1), HR, IR, compliance, data-protection, media,
--   Maaden (event and IR addresses only), Graymont (regional sales inboxes only,
--   region of the party row unknown), Sibelco (no Sibelco sales inbox),
--   Lhoist Polska (page shows Czech and Portuguese inboxes only).
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
  ('33d5aa0b-2cf8-4b73-842f-873f2a85312d'::uuid, 'info@nordkalk.com', 'General inbox', true, 'Shown on https://www.nordkalk.com/contact-us/ (crawler 2026-10-10)'),
  ('e575dd34-d48e-4742-a44b-e5d24920dc2f'::uuid, 'info@imifabi.com', 'General inbox', true, 'Shown on https://www.imifabi.com/ (crawler 2026-10-10)'),
  ('a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, 'atencionaclientes@calidra.com', 'Customer service inbox', true, 'Shown on https://www.calidra.com/es/ (crawler 2026-10-10)'),
  ('a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, 'clientes_industria@calidra.com.mx', 'Industrial customers inbox', false, 'Shown on https://www.calidra.com/es/casc/ (crawler 2026-10-10)'),
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, 'info@nigtas.com', 'General inbox', true, 'Shown on https://www.nigtas.com/ (crawler 2026-10-10)'),
  ('ee2a64c7-09ca-43ec-b81e-e04748450533'::uuid, 'info@lhoist.com', 'General inbox', true, 'Shown on https://www.lhoist.com/en/about-us/map-locator (crawler 2026-10-10)'),
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, 'info@anadolumikronize.com.tr', 'General inbox', true, 'Shown on https://anadolumikronize.com.tr/tr/iletisim (crawler 2026-10-10)'),
  ('53a7435e-5761-449d-a6ea-fe1628cc0b50'::uuid, 'info@ashapura.com', 'General inbox', true, 'Shown on https://ashapura.com/ (crawler 2026-10-10)'),
  ('34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'::uuid, 'info@ashapura.com', 'Group inbox (Ashapura)', true, 'Shown on https://ashapura.com/ (crawler 2026-10-10)'),
  ('bf9bb9b7-de2a-4c08-885d-d6692ab2c7c5'::uuid, 'calcinor@calcinor.com', 'General inbox', true, 'Shown on https://www.calcinor.com/en/contact-calcinor (crawler 2026-10-10)'),
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid, 'sales@gulshanindia.com', 'Sales inbox', true, 'Shown on http://www.gulshanindia.com/enquiry.html (crawler 2026-10-10)'),
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid, 'indussales@gulshanindia.com', 'Industrial sales inbox', false, 'Shown on http://www.gulshanindia.com/enquiry.html (crawler 2026-10-10)'),
  ('ce77920a-b7f2-45d9-bf6c-82a99a8112e7'::uuid, 'hubermaterials@huber.com', 'General inbox', true, 'Shown on https://www.hubermaterials.com/contact-us/ (crawler 2026-10-10)'),
  ('b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'::uuid, 'kunalcalcium1997@gmail.com', 'General inbox (gmail, shown on own site)', true, 'Shown on https://www.kunalcalcium.com/ (crawler 2026-10-10)'),
  ('256947a4-9f3b-42ee-96be-743ad72cbd2a'::uuid, 'sales@nanocaco3.com', 'Sales inbox', true, 'Shown on http://nanocaco3.com/ (crawler 2026-10-10)'),
  ('ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid, 'sales@zantat.com.my', 'Sales inbox', true, 'Shown on https://zantat.com.my/contact.php (crawler 2026-10-10)'),
  ('75a0d40b-8a7e-40a9-9e20-023df4cbf81c'::uuid, 'contactus@ppc.co.za', 'General inbox', true, 'Shown on https://ppc.co.za/ (crawler 2026-10-10)'),
  ('f26ebc78-777d-4e59-aaa3-152532ac40a1'::uuid, 'info@shikharmicrons.com', 'General inbox', true, 'Shown on https://www.shikharmicrons.com/ (crawler 2026-10-10)'),
  ('2c5f4cba-426a-46b5-8e9a-9ba27ee27639'::uuid, 'bok@trzuskawica.pl', 'Customer service inbox', true, 'Shown on https://www.trzuskawica.pl/kontakt/ (crawler 2026-10-10)'),
  ('2c5f4cba-426a-46b5-8e9a-9ba27ee27639'::uuid, 'info@trzuskawica.pl', 'General inbox', false, 'Shown on https://www.trzuskawica.pl/ (crawler 2026-10-10)'),
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, 'info@mikrons.com.tr', 'General inbox', true, 'Shown on https://mikrons.com.tr/ (crawler 2026-10-10)'),
  ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid, 'info@wolkem.com', 'General inbox', true, 'Shown on https://wolkem.com/contactus.html (crawler 2026-10-10)'),
  ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid, 'intnlmktg@wolkem.com', 'International marketing inbox', false, 'Shown on https://wolkem.com/contactus.html (crawler 2026-10-10)')
) as v(party_id, email, title_text, is_primary, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select count(distinct c.party_id) as parties_with_email_now,
       count(*) as email_rows
from app.contacts c
where c.deleted_at is null
  and nullif(btrim(c.email), '') is not null
  and c.party_id in ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid, '256947a4-9f3b-42ee-96be-743ad72cbd2a'::uuid, '2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, '2c5f4cba-426a-46b5-8e9a-9ba27ee27639'::uuid, '33d5aa0b-2cf8-4b73-842f-873f2a85312d'::uuid, '34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'::uuid, '38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, '53a7435e-5761-449d-a6ea-fe1628cc0b50'::uuid, '6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid, '75a0d40b-8a7e-40a9-9e20-023df4cbf81c'::uuid, '85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, 'a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, 'b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'::uuid, 'bf9bb9b7-de2a-4c08-885d-d6692ab2c7c5'::uuid, 'ce77920a-b7f2-45d9-bf6c-82a99a8112e7'::uuid, 'e575dd34-d48e-4742-a44b-e5d24920dc2f'::uuid, 'ee2a64c7-09ca-43ec-b81e-e04748450533'::uuid, 'f26ebc78-777d-4e59-aaa3-152532ac40a1'::uuid, 'ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid);
