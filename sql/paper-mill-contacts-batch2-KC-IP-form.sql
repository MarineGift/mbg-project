-- ============================================================
-- Paper Mill 연락처 보강 - Batch 2 (FORM 전용)
-- Kimberly-Clark 33 + International Paper 23 = 56 곳
-- 두 그룹 모두 공식 연락 방식 = 국가선택 폼 + 전화 (공개 B2B inbox 없음).
-- => email 빈칸, title_text='Form 입력', source='form', is_primary=false.
-- 멱등: 해당 party 에 이미 source='form' 연락처 있으면 스킵.
--
-- 제외(별도 처리): Trust International Paper Corp / TIPCO (PH, tipco.com.ph) — 동명 별개사, 독립으로 리서치.
-- LOW 참고(미삽입): info@ipaper.com / info@kcprofessional.com 은 비공식 애그리게이터 출처 → 발송 전 검증.
-- ============================================================

insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       v.given_name, v.family_name, v.full_name, v.title_text,
       v.is_primary, v.is_decision_maker, v.source
from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'d8e4ff6e-d929-4e00-b00b-91842fcf7bcc'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- AR | Kimberly-Clark Argentina
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'7713b28d-79b7-41fe-a79c-ea11a70b6f62'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- AU | Kimberly-Clark Australia
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'ce8a9300-dffd-4196-ac28-f5c3528c8685'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- CO | Kimberly-Clark Colombia
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'592c35f8-5715-4e15-8f3a-4ae06850cde8'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- CR | Kimberly-Clark Costa Rica
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'8a222fde-013d-4164-87e8-b78532af3800'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- CZ | Kimberly-Clark CZ
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'26349278-4469-49e6-9fa3-9d1cd745efeb'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- DO | Kimberly-Clark Dominican
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'8446271e-ba34-469d-8d84-5db879b94d26'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- EC | Kimberly-Clark Ecuador
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'02e15f19-006f-4d4f-97b0-be5a218f400d'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- FR | Kimberly-Clark France
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'f462acdf-7445-4d68-9483-7b1cdb68b14d'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- GB | Kimberly-Clark UK
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'822d0e58-3894-4c2d-aa41-cb697d79d01e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- GT | Kimberly-Clark Guatemala
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'89367dd8-9945-40f0-9607-33a3b463c3bd'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- HN | Kimberly-Clark Honduras
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'045e423e-ff2d-4290-b078-5ca7c7530f0f'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- MX | Kimberly-Clark de México
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'1aade01a-e9ea-4639-a9e4-3adc3caa98c7'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- NG | Kimberly-Clark Nigeria
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'dd74271c-04f1-4166-84bb-ea1ffe5c4b43'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- PA | Kimberly-Clark Panama
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b1e3921d-6e86-436e-9744-4b0f945dade1'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- PE | Kimberly-Clark Peru
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'120a8ede-41c3-4594-868c-e7e5245aaa5d'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- SA | Olayan Kimberly-Clark Saudi
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'84a0c8e9-c6f3-473f-9e35-11e5a4033547'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- SV | Kimberly-Clark El Salvador
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'eb74d1bb-d837-455f-b866-73120cbee979'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- TH | Kimberly-Clark Thailand
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b4ee1503-10cb-44e2-9fed-74bb60f185eb'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Beech Island Mill (Beech Island, SC)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'f6f9f652-f81a-4b12-b8df-c0369c14461c'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Chester Mill (Chester, PA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b7237509-ba2c-45f7-9355-838958ad0f3f'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Corinth Mill, KC Professional (Corinth, MS)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'7310293a-0244-4c98-a429-810ba46d5940'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Experimental / X-Mill (Neenah, WI)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'7ddc6889-0d9a-478c-b6dd-82dbc49132f2'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Jenks Mill (Jenks, OK)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'fda205ad-f716-41ea-b752-43bf55850ce7'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - LaGrange Mill (LaGrange, GA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3a5f1813-5247-40d1-97fc-1ffa97cefff1'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Loudon Mill (Loudon, TN)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'c1aec276-bc81-48dd-a423-9e09d3ea7a6b'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Marinette Mill (Marinette, WI)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'462b72d3-9280-4ca9-9337-43167e9589ad'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Maumelle Facility (Maumelle, AR)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'6c95880a-3a97-4d6e-b2ec-228042504f3c'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Mobile Mill (Mobile, AL)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'9c2de818-9a9f-4bc0-9110-2cdf522c790a'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - New Milford Mill (New Milford, CT)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'ce922fc7-f96c-4270-940d-714e56ef121e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Owensboro Mill (Owensboro, KY)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'688b4e09-b385-4e2a-919a-9eab8c61639a'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | Kimberly-Clark - Paris Mill (Paris, TX)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'47934d00-fe0f-4c1a-9e84-ac3ab3c23991'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- VE | Kimberly-Clark Venezuela
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'68f154a7-0d8f-4b4d-9c8e-db6896a9311e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- ZA | Kimberly-Clark South Africa
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'acecbe72-1a3f-43f9-b9da-3ae37a00b51e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- ES | International Paper Madrid (former Holmen)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'905ef95c-6d5f-4cfb-a4f8-bb04ec4fd80e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- GB | International Paper UK (post-DS Smith)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'023772c0-5d52-400d-95de-c87bb4a934f0'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- IT | International Paper Italia S.r.l.
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b7089b22-3931-4b12-b016-f54a71e250b6'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- MA | CMCP-International Paper
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'e95f5a7e-53df-4964-82f7-ec58fc6d5396'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- MX | International Paper Mexico
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'923e99b3-4a8e-40fa-9a51-ffea031b839a'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- PL | International Paper Poland (Gdańsk)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'46466a09-bfa9-4499-bbc0-32738879ad6e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Bogalusa Mill (Bogalusa, LA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'48c7e382-0740-4100-99b9-dc69a6956959'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Campti Mill (Campti, LA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'764660f3-83f0-4b28-8bf0-e5fe71675baf'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Cantonment Mill (Cantonment, FL)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'e4c4f7ac-0812-44b8-b2bf-c7e4e764b8b0'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Cayuga Mill (Cayuga, IN)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'5f5f034f-de0f-4045-8772-f53ae7a2284e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Cedar Rapids Mill (Cedar Rapids, IA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'a5b5e1c9-77c5-4fec-a0cc-0a8f2a8b13c9'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Henderson Mill (Henderson, KY)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'56609f6e-e66c-4b5d-906d-1946f5444aca'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Mansfield Mill (Mansfield, LA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'03cfa8cf-d689-4bb5-9c61-71419c61acf6'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Maysville Mill (Maysville, KY)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'e915dddd-280e-4e95-9fdf-c68e957b7844'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Orange Mill (Orange, TX)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'a659b5d3-effc-430e-977f-4411a257d95d'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Pine Hill Mill (Pine Hill, AL)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'7b671f5e-2f18-4ec0-8292-7cb622a811e4'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Prattville Mill (Prattville, AL)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'5eacc81c-201d-443f-9e88-8eea91fd09ca'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Rome Mill (Rome, GA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'8df4e4bf-ff13-4b3a-9415-433f910b244e'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Savannah Mill (Savannah, GA)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'54ffc8d8-fc56-462e-b9ec-fe9b1de164a5'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Springfield Mill (Springfield, OR)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'9087c780-658d-4f8e-a222-ae26a205654b'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Valliant Mill (Valliant, OK)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'35d7a837-8d1f-4a5c-ad88-16ed997e2e06'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form'),  -- US | International Paper - Vicksburg Mill (Vicksburg, MS)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'979a84eb-6857-42f5-bbb2-8f080879af36'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form')  -- US | International Paper Company
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text,
       is_primary, is_decision_maker, source)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id and c.source='form' and c.deleted_at is null
);
