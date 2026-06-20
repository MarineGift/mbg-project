-- 20260620060000_app_parties_website_backfill_batch1.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 1
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Scope : 7 verified independent CaCO3 / lime producers taken from the
--         page-1 (country_code < 'M') NULL-website dump.
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.
-- Source : each URL verified against the company's own live site (2026-06-20).

update app.parties set website = v.url, updated_at = now()
from (values
  -- Japan
  ('844b4120-2db9-4f39-a191-0700c67b48e6', 'https://www.bihokufunka.co.jp'),  -- Bihoku Funka Kogyo
  ('1be485ad-2edd-494d-9f4d-c5caa2a333b1', 'https://www.maruo-cal.co.jp'),     -- Maruo Calcium
  ('8395314e-f6a8-4191-9795-5c26f5cb54f7', 'https://www.okutama.co.jp'),       -- Okutama Kogyo
  ('e00f4fd0-1c82-42d7-b535-965b2ed2c998', 'https://www.shiraishi.co.jp'),     -- Shiraishi Calcium (Shiraishi Group)
  ('6cb04800-9a18-4ec1-b7ba-bb7882e6581b', 'https://www.shiraishi.co.jp'),     -- Shiraishi Kogyo Kaisha (Shiraishi Group)
  -- Korea
  ('3d121300-0eab-49b9-baf3-89f592baca78', 'http://www.taekyungbk.co.kr'),     -- Taekyung BK (ex-Baekkwang Materials)
  ('313a4d86-0055-49a1-aca0-6a760ee0b7e2', 'http://www.taekyungind.co.kr')     -- Taekyung Industrial
) as v(party_id, url)
where parties.id = v.party_id::uuid
  and parties.website is null
  and parties.party_type_id = 3
  and parties.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (expect 7 rows, all with website populated)
select id, party_name, website
from app.parties
where id in (
  '844b4120-2db9-4f39-a191-0700c67b48e6', '1be485ad-2edd-494d-9f4d-c5caa2a333b1',
  '8395314e-f6a8-4191-9795-5c26f5cb54f7', 'e00f4fd0-1c82-42d7-b535-965b2ed2c998',
  '6cb04800-9a18-4ec1-b7ba-bb7882e6581b', '3d121300-0eab-49b9-baf3-89f592baca78',
  '313a4d86-0055-49a1-aca0-6a760ee0b7e2'
)
order by party_name;
