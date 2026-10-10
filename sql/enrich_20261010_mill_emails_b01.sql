-- ============================================================
-- enrich_20261010_mill_emails_b01.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 01 of the paper mill e-mail enrichment.
-- Only addresses printed on the company's own pages or its own publications.
--   Kartonsan      kartonsan.com.tr/en/contact   general + purchasing inbox
--   Borregaard AS  Borregaard annual report       group general inbox
-- Checked, nothing usable yet:
--   Modern Karton  e-mail on site is Cloudflare-obfuscated - picked up by the crawler
-- Idempotent: an address already on the party is skipped.
-- Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       null, null, null, v.title_text,
       v.is_primary, false, v.source, v.notes
from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, '2b7d3ee1-8977-42d1-a83a-31b3b668e742'::uuid, 2,
   'kartonsan@kartonsan.com.tr', 'General inbox', true, 'homepage',
   'Listed as general correspondence on kartonsan.com.tr/en/contact (2026-10-10)'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, '2b7d3ee1-8977-42d1-a83a-31b3b668e742'::uuid, 2,
   'satinalma@kartonsan.com.tr', 'Purchasing inbox', false, 'homepage',
   'Listed as purchasing matters on kartonsan.com.tr/en/contact (2026-10-10)'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'c2f04477-d7fe-42a3-bf50-68171bee1897'::uuid, 2,
   'borregaard@borregaard.com', 'General inbox', true, 'press',
   'Printed in the Borregaard ASA annual report contact block (checked 2026-10-10)')
) as v(organization_id, party_id, contact_type_id, email, title_text, is_primary, source, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id
    and lower(c.email) = lower(v.email)
    and c.deleted_at is null
);

select p.party_name, c.email, c.title_text, c.is_primary, c.source
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.party_id in ('2b7d3ee1-8977-42d1-a83a-31b3b668e742'::uuid,
                     'c2f04477-d7fe-42a3-bf50-68171bee1897'::uuid)
  and c.email is not null
order by p.party_name, c.is_primary desc;
