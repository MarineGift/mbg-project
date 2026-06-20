-- 20260620110000_app_parties_website_backfill_batch5b.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 5b (long tail final sweep, Policy A)
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Policy A: fill ONLY rows with a verified own official domain; leave the rest NULL.
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : each URL verified against the company's own live site (2026-06-20).

update app.parties set website = v.url, updated_at = now()
from (values
  ('2c7759a6-3b7a-4312-af03-5d498e2f4544', 'https://www.huananm.com'),       -- Guangxi Huana New Material (nano-PCC/GCC for papermaking)
  ('7be68e77-1c7c-4dc3-afd7-c92df46b3481', 'http://www.yzqunxin.com'),       -- Jiangsu Qunxin Powder Technology (ultrafine GCC; NEEQ 834008)
  ('aaf7bd3c-e640-4047-a8da-93cecaa7e48a', 'https://www.mumalmicrons.in'),   -- Mumal Microns Pvt. Ltd. (Udaipur GCC/calcite)
  ('f26ebc78-777d-4e59-aaa3-152532ac40a1', 'https://www.shikharmicrons.com'),-- Shikhar Microns (Alwar GCC/calcite)
  ('b6514b8d-e09d-47f2-b241-7183f27d806e', 'https://www.yamunacalcium.com')  -- Yamuna Calcium (PCC/GCC for paper)
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 5 rows, all with website populated)
select id, party_name, website
from app.parties
where id in (
  '2c7759a6-3b7a-4312-af03-5d498e2f4544', '7be68e77-1c7c-4dc3-afd7-c92df46b3481',
  'aaf7bd3c-e640-4047-a8da-93cecaa7e48a', 'f26ebc78-777d-4e59-aaa3-152532ac40a1',
  'b6514b8d-e09d-47f2-b241-7183f27d806e'
)
order by party_name;
