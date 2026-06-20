-- 20260620100000_app_parties_website_backfill_batch5.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 5 (long tail, Policy A)
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Policy A: fill ONLY rows with a verified own official domain; leave the rest NULL.
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : each URL verified against the company's own live site (2026-06-20).

update app.parties set website = v.url, updated_at = now()
from (values
  ('c9d842e8-00ba-4c75-8363-8cbcca9a4c48', 'http://www.sampyocement.co.kr'), -- Tongyang Cement (renamed -> Sampyo Cement, KOSDAQ A038500)
  ('7d7a6790-086c-472f-8675-5a35a8bdefbd', 'http://www.hbklgroup.cn'),       -- Hubei Kailong Chemical Group (SZSE 002783; nano CaCO3)
  ('256947a4-9f3b-42ee-96be-743ad72cbd2a', 'http://www.nanocaco3.com'),      -- Fujian Sanmu Nano Calcium Carbonate
  ('b8abccc4-f5c0-4c77-b1de-cfe1d79797cf', 'https://www.kunalcalcium.com')   -- Kunal Calcium Limited (PCC)
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 4 rows, all with website populated)
select id, party_name, website
from app.parties
where id in (
  'c9d842e8-00ba-4c75-8363-8cbcca9a4c48', '7d7a6790-086c-472f-8675-5a35a8bdefbd',
  '256947a4-9f3b-42ee-96be-743ad72cbd2a', 'b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'
)
order by party_name;
