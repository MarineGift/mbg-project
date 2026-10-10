-- ============================================================
-- enrich_20261010_mill_emails_b11.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 11 - Turkey, crawler results for website batch 06 (2026-10-10):
--   Viking Kagit   info@viking.com.tr (home page, primary)
--   Lila Kagit     info@lilakagit.com (contact page, primary)
--                  jumborollsales@lilakagit.com (parent-roll sales - the mill side)
-- Not used: export-team / export inboxes for finished consumer goods, HR,
-- corporate communications, consumer hotline, yarn export, IR, and
-- info@ybp.com.tr (Yasar group company, not Viking).
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from (values
  ('f4b8a163-7bca-43d8-a4a1-05eb77a21feb'::uuid, 'info@viking.com.tr', 'General inbox', true,
   'Shown on https://www.viking.com.tr/tr (crawler 2026-10-10)'),
  ('41dff19b-a087-4cbe-bccc-97bf5341cc3e'::uuid, 'info@lilakagit.com', 'General inbox', true,
   'Shown on https://lilakagit.com/iletisim/ (crawler 2026-10-10)'),
  ('41dff19b-a087-4cbe-bccc-97bf5341cc3e'::uuid, 'jumborollsales@lilakagit.com', 'Parent-roll sales inbox', false,
   'Shown on https://lilakagit.com/iletisim/ (crawler 2026-10-10)')
) as v(party_id, email, title_text, is_primary, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select p.party_name, c.email, c.title_text, c.is_primary
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.party_id in ('f4b8a163-7bca-43d8-a4a1-05eb77a21feb'::uuid, '41dff19b-a087-4cbe-bccc-97bf5341cc3e'::uuid)
  and c.email is not null
order by p.party_name, c.is_primary desc;
