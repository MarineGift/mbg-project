-- 20260620070000_app_parties_website_backfill_batch2.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 2
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Scope : 9 verified independent producers (Tier B) from the page-1 dump.
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : each URL verified against the company's own live site (2026-06-20).

update app.parties set website = v.url, updated_at = now()
from (values
  -- Japan
  ('92f57c52-4570-4464-b212-fbc52240e34a', 'https://www.nittetsukou.co.jp'),  -- Nittetsu Mining (TSE 1515)
  ('21d35d02-debe-4575-8018-dcef7468c02c', 'http://www.fmt.co.jp'),           -- Fimatec
  ('f24bb73a-2cc9-4727-a54d-1f6e0ee318c9', 'https://www.nittofunka.co.jp'),   -- Nitto Funka Kogyo
  ('ba067815-e964-49f7-ba15-f80a3560aa58', 'https://www.toyodenka.co.jp'),    -- Toyo Denka Kogyo
  -- Korea
  ('d8f19e97-734e-416e-98c5-6ac53c59e030', 'https://www.hanil.com'),          -- Hanil Cement / Hanil Hyundai Cement (group)
  ('3fb6423e-b5e3-46c6-8c8a-bea3502b59cb', 'http://www.sungshincement.co.kr'),-- Sungshin Cement (KRX A004980)
  -- India
  ('feab20d4-08cb-423f-814f-7f29ed665244', 'https://www.20microns.com'),      -- 20 Microns Limited
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2', 'https://www.gulshanindia.com'),   -- Gulshan Polyols Ltd. (BSE/NSE)
  ('22f4f49d-91d8-488f-9165-fa55659b0763', 'https://www.wolkem.com')          -- Wolkem India Ltd.
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 9 rows, all with website populated)
select id, party_name, website
from app.parties
where id in (
  '92f57c52-4570-4464-b212-fbc52240e34a', '21d35d02-debe-4575-8018-dcef7468c02c',
  'f24bb73a-2cc9-4727-a54d-1f6e0ee318c9', 'ba067815-e964-49f7-ba15-f80a3560aa58',
  'd8f19e97-734e-416e-98c5-6ac53c59e030', '3fb6423e-b5e3-46c6-8c8a-bea3502b59cb',
  'feab20d4-08cb-423f-814f-7f29ed665244', '6ce2f30c-4c98-4886-8922-62ffd57f62b2',
  '22f4f49d-91d8-488f-9165-fa55659b0763'
)
order by party_name;
