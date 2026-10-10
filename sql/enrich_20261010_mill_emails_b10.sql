-- ============================================================
-- enrich_20261010_mill_emails_b10.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 10 - crawler results for website batch 05 (2026-10-10):
--   APP Sinar Mas Indonesia   app_callcenter@app.co.id   (app.co.id home page)
--                             on the 6 APP Indonesia mill rows (group inbox)
--   APRIL Group               customer_service@aprilasia.com (contact page)
-- Not used: legal@aprilasia.com.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, v.title_text,
       true, false, 'homepage', v.notes
from (values
  ('b9a6f26d-66d8-47fc-99a3-bbf41499a980'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('92a3af50-0b0d-47dc-b75b-a6d79f52ac8b'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('01d1f184-bf99-422a-8187-2744b9f69dd1'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('13340c0e-50bc-4eb5-aa14-807a05a33b73'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('d21e102d-2844-4284-8f0b-7d01c5978b73'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('a78e7ca7-6dfb-4b0c-9b1d-91c3fe182663'::uuid, 'app_callcenter@app.co.id', 'Group call-center inbox (APP)', 'Shown on https://app.co.id/ (crawler 2026-10-10)'),
  ('335e2930-a639-43c9-b232-7d89697807c8'::uuid, 'customer_service@aprilasia.com', 'Customer service inbox', 'Shown on https://www.aprilasia.com/en/contact-us (crawler 2026-10-10)')
) as v(party_id, email, title_text, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select p.party_name, c.email, c.title_text
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.email in ('app_callcenter@app.co.id', 'customer_service@aprilasia.com')
order by p.party_name;
