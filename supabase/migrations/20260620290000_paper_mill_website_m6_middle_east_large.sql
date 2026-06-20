-- 20260620290000_paper_mill_website_m6_middle_east_large.sql
-- NON-CONNECTED paper_mill (party_type_id = 2) website backfill - m6 (Middle East / South Asia large cos).
-- Long-tail follow-up: verified domains for the LARGE companies in SA + BD only.
-- Verified this pass: MEPCO(mepco.biz, Tadawul 1202), WARAQ(waraq.com), NAPCO(napconational.com),
--   Obeikan(obeikan.com.sa), Bashundhara(bashundharapapermills.com, from m5), Olayan K-C(kimberly-clark.com).
-- NOT included (domain unverified -> stay NULL): Saudi Paper Group/SPM, Juthor, Al-Madar, UCIC,
--   Al-Faris, Al-Faisaliah, Al Suwaidi, Yanbu Shuaiba; all Iran (IR) mills (sanctions/no reliable domain);
--   BD state/suspended mills (Karnaphuli, Khulna, North Bengal, etc.).
-- website-only. UTF-8. RUN IN SUPABASE SQL EDITOR. Idempotent. Org+type scoped.

update app.parties p
set website = d.url, updated_at = now()
from (values
  ('c6b384bb-a4c0-45a0-9271-45a0e251ed8b'::uuid, 'https://www.bashundharapapermills.com'),  -- [BD] Bashundhara
  ('8b3cd061-aac9-4f47-a4f9-e85422fda422'::uuid, 'https://www.bashundharapapermills.com'),  -- [BD] Bashundhara Paper Mills PLC (BPMPLC)
  ('888ee933-0b69-47c3-8a90-89091b6ed796'::uuid, 'https://www.bashundharapapermills.com'),  -- [BD] Bashundhara tissue
  ('824c36ba-e755-4ef3-a8b7-421c44134794'::uuid, 'https://www.bashundharapapermills.com'),  -- [BD] Bashundhara tissue line
  ('1e97b46e-ea89-4c14-bede-aa38e8910505'::uuid, 'https://www.bashundharapapermills.com'),  -- [BD] Bashundhara Unit-2 newsprint
  ('121d4953-67e5-4128-9322-0458c0deb720'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO
  ('353b9687-3f0b-48f2-82c0-e7cf7d5504e6'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO (Middle East Paper Company)
  ('370db0a7-b688-4bdd-a839-e12bbb5202c8'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO + WARAQ
  ('01045f98-42db-48fe-ad53-5a2e64276c7e'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO Jeddah PM1
  ('1a9264f8-fa7e-400f-99f4-e97167be356e'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO Jeddah PM2
  ('7d5345fc-50da-47c1-8d2c-a6da6074d83c'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO Jeddah PM3
  ('33a50b2b-f5b1-4a6c-90ae-41d3b23b291c'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO Jeddah PM4 (Tissue)
  ('dde2f23f-94c2-4571-a760-085d173c2b67'::uuid, 'https://www.mepco.biz'),  -- [SA] MEPCO Jeddah PM5 (2027)
  ('7ab0af91-2463-4900-b178-7edef758698a'::uuid, 'https://www.napconational.com'),  -- [SA] NAPCO Consumer Products
  ('a0d3100f-6f93-460d-8058-ca87e7df7477'::uuid, 'https://www.napconational.com'),  -- [SA] NAPCO Dammam
  ('1804bf51-a160-43b3-be5c-50825651db64'::uuid, 'https://www.obeikan.com.sa'),  -- [SA] Obeikan Paper Industries
  ('07590e94-b275-4c46-a231-64621fd37fce'::uuid, 'https://www.obeikan.com.sa'),  -- [SA] Obeikan Paper Industries Riyadh
  ('120a8ede-41c3-4594-868c-e7e5245aaa5d'::uuid, 'https://www.kimberly-clark.com'),  -- [SA] Olayan Kimberly-Clark Saudi
  ('98d131c1-2495-45d2-8344-e11b9540f03c'::uuid, 'https://www.waraq.com'),  -- [SA] WARAQ
  ('8bf8be06-9ac6-4753-8f56-fa878b16e213'::uuid, 'https://www.waraq.com'),  -- [SA] WARAQ Dammam PM-I
  ('64502ca8-c497-4232-88eb-db7fbada5263'::uuid, 'https://www.waraq.com'),  -- [SA] WARAQ Dammam PM-II
  ('d7d7a259-d036-48c5-a40e-6e7fb5c87450'::uuid, 'https://www.waraq.com')  -- [SA] WARAQ expansion (target 500k t/y)
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2
  and (p.website is null or p.website not ilike 'http%');

-- verify
select count(*) filter (where website ilike 'http%') as with_url, count(*) as total
from app.parties where id in (
  'c6b384bb-a4c0-45a0-9271-45a0e251ed8b','8b3cd061-aac9-4f47-a4f9-e85422fda422','888ee933-0b69-47c3-8a90-89091b6ed796','824c36ba-e755-4ef3-a8b7-421c44134794','1e97b46e-ea89-4c14-bede-aa38e8910505','121d4953-67e5-4128-9322-0458c0deb720','353b9687-3f0b-48f2-82c0-e7cf7d5504e6','370db0a7-b688-4bdd-a839-e12bbb5202c8','01045f98-42db-48fe-ad53-5a2e64276c7e','1a9264f8-fa7e-400f-99f4-e97167be356e','7d5345fc-50da-47c1-8d2c-a6da6074d83c','33a50b2b-f5b1-4a6c-90ae-41d3b23b291c','dde2f23f-94c2-4571-a760-085d173c2b67','7ab0af91-2463-4900-b178-7edef758698a','a0d3100f-6f93-460d-8058-ca87e7df7477','1804bf51-a160-43b3-be5c-50825651db64','07590e94-b275-4c46-a231-64621fd37fce','120a8ede-41c3-4594-868c-e7e5245aaa5d','98d131c1-2495-45d2-8344-e11b9540f03c','8bf8be06-9ac6-4753-8f56-fa878b16e213','64502ca8-c497-4232-88eb-db7fbada5263','d7d7a259-d036-48c5-a40e-6e7fb5c87450'
);
