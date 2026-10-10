-- ============================================================
-- enrich_20261010_mill_emails_b13.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bai Bang Paper (VINAPACO) - bapaco@vinapaco.com.vn, the Northern sales
-- department at Phu Ninh, Phu Tho (the Bai Bang mill site), listed on
-- https://vinapaco.com.vn/lien-he/ (opened 2026-10-10). The Da Nang and
-- Ho Chi Minh City sales-branch inboxes on the same page are not used.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid, 2,
       'bapaco@vinapaco.com.vn', 'Sales department inbox (Phu Ninh mill)', true, false, 'homepage',
       'Listed on https://vinapaco.com.vn/lien-he/ for the Northern sales department, Phu Ninh (opened 2026-10-10)'
where exists (select 1 from app.parties p where p.id = '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid and p.deleted_at is null)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid
      and lower(c.email) = 'bapaco@vinapaco.com.vn'
      and c.deleted_at is null
  );

select p.party_name, c.email, c.title_text
from app.contacts c
join app.parties p on p.id = c.party_id
where c.party_id = '8c6ab930-6419-44ab-ba80-fc43552b245a'::uuid
  and c.deleted_at is null and c.email is not null;
