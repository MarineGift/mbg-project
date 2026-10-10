-- ============================================================
-- enrich_20261010_mill_emails_b14.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- James Cropper plc - company inboxes on https://jamescropper.com/contact-us/
-- (crawler 2026-10-10). The mail domain is cropper.com.
--   info@cropper.com        primary
--   enquiries@cropper.com   secondary
-- inquiries@cropper.com (spelling variant on the same page) not added.
-- Kruger Products: no address on 9 pages (form only).
-- Mercer International: site blocks scripted access; domain confirmed by
-- PEFC member page and SEC filings - website kept, no e-mail.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid, 2, v.email, v.title_text,
       v.is_primary, false, 'homepage',
       'Shown on https://jamescropper.com/contact-us/ (crawler 2026-10-10)'
from (values
  ('info@cropper.com',      'General inbox',  true),
  ('enquiries@cropper.com', 'Enquiries inbox', false)
) as v(email, title_text, is_primary)
where exists (select 1 from app.parties p where p.id = '7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid and p.deleted_at is null)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = '7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid
      and lower(c.email) = lower(v.email)
      and c.deleted_at is null
  );

select c.email, c.title_text, c.is_primary
from app.contacts c
where c.party_id = '7dce0157-0836-4fb2-aabc-a5f225ed8acc'::uuid
  and c.deleted_at is null and c.email is not null;
