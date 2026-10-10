-- ============================================================
-- enrich_20261010_mill_emails_b09.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- PT Suparma Tbk - info@ptsuparmatbk.com, shown on the ptsuparmatbk.com home
-- page (crawler 2026-10-10). Also on the contact page but not used: Jakarta,
-- Bandung and Bali sales depots, and the consumer-products marketing inbox.
-- Fajar Surya Wisesa: no address on 9 pages crawled (form only).
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '8899cba0-f6e3-4ad3-8e60-13ef34a09a23'::uuid, 2,
       'info@ptsuparmatbk.com', 'General inbox', true, false, 'homepage',
       'Shown on https://www.ptsuparmatbk.com/ (crawler 2026-10-10)'
where not exists (
  select 1 from app.contacts c
  where c.party_id = '8899cba0-f6e3-4ad3-8e60-13ef34a09a23'::uuid
    and lower(c.email) = 'info@ptsuparmatbk.com'
    and c.deleted_at is null
);

select c.email, c.title_text, c.is_primary
from app.contacts c
where c.party_id = '8899cba0-f6e3-4ad3-8e60-13ef34a09a23'::uuid
  and c.deleted_at is null and c.email is not null;
