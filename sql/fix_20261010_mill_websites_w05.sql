-- ============================================================
-- fix_20261010_mill_websites_w05.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Website batch 05 - Indonesian group mills (no supplier link):
--   APP Sinar Mas Indonesia (6 mill rows)   app.co.id
--     Indah Kiat Serang, Indah Kiat Tangerang, Tjiwi Kimia, Pindo Deli,
--     Lontar Papyrus, OKI
--   APRIL Group (Riau Andalan Pulp & Paper) aprilasia.com
-- Sites confirmed 2026-10-10 (company pages, press releases, Wikipedia infobox).
-- No published general e-mail found for either group - the crawler is run.
-- Only empty fields are filled. Last statement verifies.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('b9a6f26d-66d8-47fc-99a3-bbf41499a980'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('92a3af50-0b0d-47dc-b75b-a6d79f52ac8b'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('01d1f184-bf99-422a-8187-2744b9f69dd1'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('13340c0e-50bc-4eb5-aa14-807a05a33b73'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('d21e102d-2844-4284-8f0b-7d01c5978b73'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('a78e7ca7-6dfb-4b0c-9b1d-91c3fe182663'::uuid, 'https://www.app.co.id', 'app.co.id'),
  ('335e2930-a639-43c9-b232-7d89697807c8'::uuid, 'https://www.aprilasia.com', 'aprilasia.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.website, p.domain_normalized
from app.parties p
where p.id in ('b9a6f26d-66d8-47fc-99a3-bbf41499a980'::uuid, '92a3af50-0b0d-47dc-b75b-a6d79f52ac8b'::uuid,
               '01d1f184-bf99-422a-8187-2744b9f69dd1'::uuid, '13340c0e-50bc-4eb5-aa14-807a05a33b73'::uuid,
               'd21e102d-2844-4284-8f0b-7d01c5978b73'::uuid, 'a78e7ca7-6dfb-4b0c-9b1d-91c3fe182663'::uuid,
               '335e2930-a639-43c9-b232-7d89697807c8'::uuid)
order by p.party_name;
