-- 20260620250000_paper_mill_website_intro_batch_m4_americas_other.sql
-- paper_mill (party_type_id = 2) website + intro - BATCH m4 (FINAL: Americas, Turkey,
-- Africa, Oceania - 37 mills). Corporate domains (mill -> parent/group site).
-- 7 left NULL (small/defunct/composite): Egypt x3, Consolidated Papers, Phoenix Paper LLC,
-- Alkim Kagit, Hamburger/Prinzhorn. NOTE Verso -> Billerud (acquired 2022). UTF-8.
-- RUN IN SUPABASE SQL EDITOR. Idempotent; org+type scoped. This completes the 116 connected mills.

-- 1) website (only where currently missing or non-URL)
update app.parties p
set website = d.url, updated_at = now()
from (values
  ('4ba39dee-769b-41d8-a494-f35e4f467ffd'::uuid, 'https://www.celulosaargentina.com'),  -- Celulosa Argentina
  ('cad65661-81a3-4aa3-bace-cb0a264729f6'::uuid, 'https://www.smurfitwestrock.com'),  -- Smurfit Westrock Argentina
  ('68c6ce53-d036-4a78-af8b-60eda8571916'::uuid, 'https://www.opalanz.com'),  -- Opal
  ('3e3b5378-486e-4e0a-a3aa-6993ab0c64e2'::uuid, 'https://www.visy.com.au'),  -- Visy
  ('30923c37-257f-44cb-a889-fbd99f2f518b'::uuid, 'https://www.suzano.com'),  -- Suzano Papel e Celulose
  ('de87ce0d-f021-4849-bfd5-a072ef5cc27e'::uuid, 'https://www.porthawkesburypaper.com'),  -- Port Hawkesbury Paper
  ('c72eb789-b4b4-41b2-9b10-b1507d6fcccf'::uuid, 'https://www.arauco.com'),  -- Arauco multi-mill
  ('a04d9916-532f-4d04-8628-f3e9e9ce8862'::uuid, 'https://www.cmpc.com'),  -- CMPC multi-mill
  ('6776fcce-9f10-46e5-84a3-9b58bdffe53e'::uuid, 'https://www.smurfitwestrock.com'),  -- Smurfit Westrock Cali
  ('d6b20d5a-ed29-4fd0-a51f-904184f7797a'::uuid, 'https://www.dssmith.com'),  -- CMCP Casablanca + Agadir
  ('8b3c16da-1aee-459d-87d3-e15c474197e5'::uuid, 'https://www.dssmith.com'),  -- CMCP Kenitra
  ('72a4417f-65cb-4245-859c-78ffb713641b'::uuid, 'https://www.hayat.com'),  -- Hayat Nigeria
  ('7c847abc-fa34-4d45-8f7b-b713ee7dc7fb'::uuid, 'https://www.kipaskagit.com.tr'),  -- Kahramanmaraş Kağıt (Kipaş)
  ('2b7d3ee1-8977-42d1-a83a-31b3b668e742'::uuid, 'https://www.kartonsan.com.tr'),  -- Kartonsan
  ('b647f87e-4b85-4ee9-bc3d-c32ccac6747c'::uuid, 'https://www.modernkarton.com.tr'),  -- Modern Karton
  ('c014ea7a-e5da-4cc6-b11d-9aac2215f836'::uuid, 'https://www.clearwaterpaper.com'),  -- Clearwater Paper
  ('406131aa-a4f4-442b-bd90-eb7a1569c4bf'::uuid, 'https://www.graphicpkg.com'),  -- Graphic Packaging International
  ('55f04c50-e660-4fb3-a7b5-301f19823813'::uuid, 'https://www.ndpaper.com'),  -- ND Paper
  ('e9cec2dc-b308-4eb0-bc45-1dee717445cb'::uuid, 'https://www.ndpaper.com'),  -- ND Paper Biron (ex-Catalyst/Wausau; Nine Dragons subsidiary 2018)
  ('8588c86b-35c7-4a40-aa3f-5c1c943d82d0'::uuid, 'https://www.ndpaper.com'),  -- ND Paper Rumford (ex-Catalyst/NewPage; Nine Dragons subsidiary 2018)
  ('720c91b7-35ca-43cc-a274-be4244bbe8e2'::uuid, 'https://www.pixelle.com'),  -- Pixelle Androscoggin (Jay, ME) [closed 2023]
  ('33e531bf-e378-4f2b-80be-6eb8a8cb5d8f'::uuid, 'https://www.pixelle.com'),  -- Pixelle Specialty Solutions (Chillicothe, OH) [closed 2025]
  ('6053a88d-c44f-41d7-8e62-d72dc160e105'::uuid, 'https://www.pixelle.com'),  -- Pixelle Specialty Solutions (Spring Grove, PA)
  ('da71948a-39aa-4b3d-913a-7b8e44275167'::uuid, 'https://www.sylvamo.com'),  -- Sylvamo
  ('79fb76ed-cd21-45a8-9301-4d68aaffde0f'::uuid, 'https://www.sylvamo.com'),  -- Sylvamo - Ticonderoga Mill (Ticonderoga, NY)
  ('e4c96a5f-0853-4415-aba0-5e69025d3c96'::uuid, 'https://www.billerud.com'),  -- Verso Paper
  ('8d19cb27-3128-4796-96e1-499aab16415d'::uuid, 'https://www.montesdelplata.com.uy'),  -- Montes del Plata
  ('3c893407-beb5-492c-aa7f-384f16666bd2'::uuid, 'https://www.upm.com'),  -- UPM Fray Bentos
  ('d226ea8b-a601-4e92-8815-6ad3e6104a73'::uuid, 'https://www.upm.com'),  -- UPM Paso de Los Toros
  ('b2319789-8124-4406-a285-dc8dc498c159'::uuid, 'https://www.mpact.co.za')  -- Mpact + Neopak
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2
  and (p.website is null or p.website not ilike 'http%');

-- 2) company intro (ko/en) - all 37, incl. the 7 without a website
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('4ba39dee-769b-41d8-a494-f35e4f467ffd'::uuid,
   '아르헨티나의 대표 펄프·제지사 Celulosa Argentina. 인쇄·필기용지와 포장지를 생산하는 남미 거점.',
   'Celulosa Argentina, a leading Argentine pulp & paper maker producing printing/writing and packaging papers.'),  -- Celulosa Argentina
  ('cad65661-81a3-4aa3-bace-cb0a264729f6'::uuid,
   'Smurfit Westrock의 아르헨티나 거점. 재생 골판지 원지·포장재를 생산.',
   'Smurfit Westrock''s Argentine operations, producing recycled containerboard and packaging.'),  -- Smurfit Westrock Argentina
  ('68c6ce53-d036-4a78-af8b-60eda8571916'::uuid,
   '호주·뉴질랜드 최대급 제지·포장사 Opal(옛 Australian Paper, Nippon Paper 소유). Maryvale 공장에서 크라프트라이너·플루팅·인쇄용지를 생산.',
   'Opal (ex-Australian Paper, Nippon Paper-owned), one of ANZ''s largest paper/packaging makers; its Maryvale mill produces kraftliner, fluting and graphic papers.'),  -- Opal
  ('3e3b5378-486e-4e0a-a3aa-6993ab0c64e2'::uuid,
   '호주 Visy. 재생 골판지 원지·포장재를 대규모로 생산하는 호주 최대 사기업 포장사.',
   'Australia''s Visy, a major privately held packaging company producing recycled containerboard and packaging at scale.'),  -- Visy
  ('30923c37-257f-44cb-a889-fbd99f2f518b'::uuid,
   '브라질 Suzano. 세계 최대 표백 유칼립투스 펄프(BEKP) 생산사이자 인쇄·티슈용지를 생산하는 글로벌 기업.',
   'Brazil''s Suzano, the world''s largest bleached eucalyptus (BEKP) pulp producer, also making printing and tissue papers.'),  -- Suzano Papel e Celulose
  ('de87ce0d-f021-4849-bfd5-a072ef5cc27e'::uuid,
   '캐나다 노바스코샤의 Port Hawkesbury Paper. 초경량 코팅지(SC)·인쇄용지를 생산하는 북미 거점.',
   'Port Hawkesbury Paper in Nova Scotia, Canada, producing supercalendered (SC) and graphic papers for North America.'),  -- Port Hawkesbury Paper
  ('c72eb789-b4b4-41b2-9b10-b1507d6fcccf'::uuid,
   '칠레 Arauco. 시장펄프·목재패널과 제지를 생산하는 남미 최대급 임산·펄프 기업.',
   'Chile''s Arauco, one of South America''s largest forestry/pulp companies, producing market pulp, wood panels and paper.'),  -- Arauco multi-mill
  ('a04d9916-532f-4d04-8628-f3e9e9ce8862'::uuid,
   '칠레 CMPC. 펄프·티슈·포장지·인쇄용지를 생산하는 중남미 대표 제지그룹.',
   'Chile''s CMPC, a leading Latin American paper group producing pulp, tissue, packaging and graphic papers.'),  -- CMPC multi-mill
  ('6776fcce-9f10-46e5-84a3-9b58bdffe53e'::uuid,
   'Smurfit Westrock의 콜롬비아 칼리 거점. 골판지 원지·포장재를 생산.',
   'Smurfit Westrock''s Cali (Colombia) operations, producing containerboard and packaging.'),  -- Smurfit Westrock Cali
  ('64afbd9f-e347-4b6b-9aa9-4be061cb66be'::uuid,
   '이집트의 제지사 MEPPCO(Middle East Paper). 포장·산업용지를 생산하나 공식 도메인 미확인.',
   'MEPPCO (Middle East Paper Company), an Egyptian maker of packaging/industrial papers; no verified official domain.'),  -- MEPPCO
  ('8a046c90-47a3-4d23-aa64-cb95c091385f'::uuid,
   '이집트 국영계 제지사 Misr Edfu·Rakta(사탕수수 바가스 기반). 인쇄·포장용지를 생산하나 공식 도메인 미확인.',
   'Egypt''s state-linked Misr Edfu and Rakta mills (bagasse-based), producing printing/packaging papers; no verified official domain.'),  -- Misr Edfu + Rakta
  ('3fc1680b-267e-4068-828b-7f8eb5b7dda2'::uuid,
   '이집트 Qena의 제지사 QPIC. 공식 도메인 미확인.',
   'Quena Paper Industry Company (QPIC), an Egyptian mill in Qena; no verified official domain.'),  -- Quena Paper Industry Company (QPIC)
  ('d6b20d5a-ed29-4fd0-a51f-904184f7797a'::uuid,
   '모로코 CMCP(DS Smith 모로코, Compagnie Marocaine des Cartons et des Papiers)의 카사블랑카·아가디르 거점. 재생 골판지 원지·포장재를 생산.',
   'CMCP (DS Smith Morocco) Casablanca and Agadir sites, producing recycled containerboard and packaging.'),  -- CMCP Casablanca + Agadir
  ('8b3c16da-1aee-459d-87d3-e15c474197e5'::uuid,
   '모로코 CMCP(DS Smith 모로코)의 케니트라 공장. 재생 골판지 원지를 생산.',
   'CMCP (DS Smith Morocco) Kenitra mill, producing recycled containerboard.'),  -- CMCP Kenitra
  ('72a4417f-65cb-4245-859c-78ffb713641b'::uuid,
   '터키 Hayat 그룹의 나이지리아 거점. 티슈·위생용지를 생산해 서아프리카 시장에 공급.',
   'The Nigerian operations of Turkey''s Hayat group, producing tissue/hygiene papers for the West African market.'),  -- Hayat Nigeria
  ('897b7cdb-d073-4fb1-88d5-f4670c8c701a'::uuid,
   '터키 Alkim 계열의 제지사 Alkim Kağıt. 인쇄·산업용지를 생산하나 단일 공식 도메인 미확정.',
   'Alkim Kağıt, a Turkish paper maker in the Alkim group, producing printing/industrial papers; no single verified domain assigned.'),  -- Alkim Kağıt
  ('cc593de4-7457-474b-a855-7938aacfda45'::uuid,
   '오스트리아 Prinzhorn 그룹의 터키 Hamburger(Kütahya) 골판지 원지 거점. 재생 포장원지를 생산. 복합 명칭이라 단일 도메인 미지정.',
   'The Turkish Hamburger (Kütahya) containerboard site of Austria''s Prinzhorn group, producing recycled packaging papers; composite name, no single domain assigned.'),  -- Hamburger Kütahya / Prinzhorn Turkey
  ('7c847abc-fa34-4d45-8f7b-b713ee7dc7fb'::uuid,
   '터키 Kipaş Holding 계열의 Kipaş Kağıt(카흐라만마라쉬). 100% 재생 폐지 기반으로 테스트라이너·플루팅 골판지 원지를 대량 생산.',
   'Kipaş Kağıt (Kahramanmaraş), part of Turkey''s Kipaş Holding, producing testliner/fluting containerboard at scale from 100% recycled waste paper.'),  -- Kahramanmaraş Kağıt (Kipaş)
  ('2b7d3ee1-8977-42d1-a83a-31b3b668e742'::uuid,
   '터키의 상장 판지 제조사 Kartonsan. 코팅 폴딩박스보드(GD/GT) 등 판지를 생산.',
   'Kartonsan, a listed Turkish cartonboard maker producing coated folding boxboard (GD/GT) grades.'),  -- Kartonsan
  ('b647f87e-4b85-4ee9-bc3d-c32ccac6747c'::uuid,
   '터키 Eren Holding 계열의 Modern Karton. 재생 골판지 원지(테스트라이너·플루팅)를 대규모로 생산.',
   'Modern Karton, part of Turkey''s Eren Holding, producing recycled containerboard (testliner/fluting) at scale.'),  -- Modern Karton
  ('c014ea7a-e5da-4cc6-b11d-9aac2215f836'::uuid,
   '미국 Clearwater Paper. 표백 판지(SBS)와 티슈를 생산하는 북미 제지사.',
   'US-based Clearwater Paper, producing bleached paperboard (SBS) and tissue for North America.'),  -- Clearwater Paper
  ('471e45e3-b982-4704-a436-49867c91aa93'::uuid,
   '미국 위스콘신의 옛 Consolidated Papers. 2000년 Stora Enso에 인수된 뒤 자산이 분할·정리되어 단독 공식 도메인 부재.',
   'The former Consolidated Papers (Wisconsin, USA); acquired by Stora Enso in 2000 and since broken up, so no standalone official domain.'),  -- Consolidated Papers
  ('406131aa-a4f4-442b-bd90-eb7a1569c4bf'::uuid,
   '미국 Graphic Packaging International. 코팅 재생판지(CRB·CUK) 등 소비재 포장용 판지를 생산하는 글로벌 기업.',
   'Graphic Packaging International (USA), a global maker of coated recycled/unbleached kraft board (CRB/CUK) for consumer packaging.'),  -- Graphic Packaging International
  ('55f04c50-e660-4fb3-a7b5-301f19823813'::uuid,
   '중국 Nine Dragons(ND Paper)의 미국 자회사. 펄프·포장원지·인쇄용지를 북미에서 생산.',
   'ND Paper, the US arm of China''s Nine Dragons, producing pulp, packaging and graphic papers in North America.'),  -- ND Paper
  ('e9cec2dc-b308-4eb0-bc45-1dee717445cb'::uuid,
   'ND Paper의 위스콘신 Biron 공장(옛 Catalyst/Wausau, 2018년 Nine Dragons 인수). 코팅·인쇄용지와 펄프를 생산.',
   'ND Paper''s Biron (Wisconsin) mill (ex-Catalyst/Wausau, acquired by Nine Dragons in 2018), producing coated/graphic papers and pulp.'),  -- ND Paper Biron (ex-Catalyst/Wausau; Nine Dragons subsidiary 2018)
  ('8588c86b-35c7-4a40-aa3f-5c1c943d82d0'::uuid,
   'ND Paper의 메인주 Rumford 공장(옛 Catalyst/NewPage, 2018년 Nine Dragons 인수). 코팅지·펄프를 생산.',
   'ND Paper''s Rumford (Maine) mill (ex-Catalyst/NewPage, acquired by Nine Dragons in 2018), producing coated papers and pulp.'),  -- ND Paper Rumford (ex-Catalyst/NewPage; Nine Dragons subsidiary 2018)
  ('1bb3361c-f55d-4aad-8b08-9104133beaca'::uuid,
   '미국 켄터키 Wickliffe의 Phoenix Paper(중국계 소유). 인쇄·포장용지를 생산하나 단일 공식 도메인 미확정.',
   'Phoenix Paper (Wickliffe, Kentucky, USA; Chinese-owned), producing printing/packaging papers; no single verified domain assigned.'),  -- Phoenix Paper LLC
  ('720c91b7-35ca-43cc-a274-be4244bbe8e2'::uuid,
   '미국 특수지 1위 Pixelle Specialty Solutions의 Androscoggin(메인주 Jay) 공장. 특수지 생산 거점이었으나 2023년 폐쇄.',
   'Pixelle Specialty Solutions'' Androscoggin mill (Jay, Maine); a specialty-paper site that closed in 2023.'),  -- Pixelle Androscoggin (Jay, ME) [closed 2023]
  ('33e531bf-e378-4f2b-80be-6eb8a8cb5d8f'::uuid,
   'Pixelle Specialty Solutions의 오하이오 Chillicothe 공장. 특수지를 생산했으나 2025년 폐쇄.',
   'Pixelle Specialty Solutions'' Chillicothe (Ohio) mill, a specialty-paper site that closed in 2025.'),  -- Pixelle Specialty Solutions (Chillicothe, OH) [closed 2025]
  ('6053a88d-c44f-41d7-8e62-d72dc160e105'::uuid,
   '미국 특수지 1위 Pixelle Specialty Solutions의 펜실베이니아 Spring Grove 공장. 특수·인쇄용지를 생산.',
   'Pixelle Specialty Solutions'' Spring Grove (Pennsylvania) mill, producing specialty and printing papers; Pixelle is the largest US specialty-paper maker.'),  -- Pixelle Specialty Solutions (Spring Grove, PA)
  ('da71948a-39aa-4b3d-913a-7b8e44275167'::uuid,
   '글로벌 무코팅 인쇄용지(uncoated freesheet) 전문기업 Sylvamo(2021년 IP에서 분사). 사무·인쇄용지를 미주·유럽·중남미에서 생산.',
   'Sylvamo (spun off from International Paper in 2021), a global uncoated-freesheet specialist producing office/printing papers across the Americas and Europe.'),  -- Sylvamo
  ('79fb76ed-cd21-45a8-9301-4d68aaffde0f'::uuid,
   'Sylvamo의 뉴욕주 Ticonderoga 공장. 무코팅 인쇄·사무용지를 생산하는 미국 거점.',
   'Sylvamo''s Ticonderoga (New York) mill, a US site producing uncoated printing/office papers.'),  -- Sylvamo - Ticonderoga Mill (Ticonderoga, NY)
  ('e4c96a5f-0853-4415-aba0-5e69025d3c96'::uuid,
   '미국 코팅지 기업이던 Verso. 2022년 스웨덴 Billerud에 인수되어 현재 Billerud 북미 사업(Escanaba 등)으로 운영.',
   'Verso, a former US coated-paper company, acquired by Sweden''s Billerud in 2022 and now run as Billerud''s North American operations (Escanaba, etc.).'),  -- Verso Paper
  ('8d19cb27-3128-4796-96e1-499aab16415d'::uuid,
   '우루과이 Montes del Plata(Arauco·Stora Enso 합작). 표백 유칼립투스 시장펄프를 대규모로 생산.',
   'Montes del Plata in Uruguay (an Arauco/Stora Enso JV), producing bleached eucalyptus market pulp at large scale.'),  -- Montes del Plata
  ('3c893407-beb5-492c-aa7f-384f16666bd2'::uuid,
   '핀란드 UPM의 우루과이 Fray Bentos 펄프공장. 표백 유칼립투스 시장펄프를 생산.',
   'UPM''s Fray Bentos pulp mill in Uruguay, producing bleached eucalyptus market pulp.'),  -- UPM Fray Bentos
  ('d226ea8b-a601-4e92-8815-6ad3e6104a73'::uuid,
   'UPM의 우루과이 Paso de los Toros 대형 펄프공장(2023년 가동). 표백 유칼립투스 시장펄프를 생산.',
   'UPM''s large Paso de los Toros pulp mill in Uruguay (started up 2023), producing bleached eucalyptus market pulp.'),  -- UPM Paso de Los Toros
  ('b2319789-8124-4406-a285-dc8dc498c159'::uuid,
   '남아공 상장 포장기업 Mpact 주도 거점(Neopak 연계). 재생 골판지 원지·포장재를 생산하는 남아공 최대급 제지사.',
   'A South African cluster led by listed Mpact (with Neopak), producing recycled containerboard and packaging; among South Africa''s largest paper makers.')  -- Mpact + Neopak
) as d(party_id, intro_ko, intro_en)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2;

-- verify (this batch)
select
  count(*) filter (where website ilike 'http%') as with_url,
  count(*) filter (where intro_ko is not null and intro_ko <> '') as with_intro
from app.parties where id in (
  '4ba39dee-769b-41d8-a494-f35e4f467ffd','cad65661-81a3-4aa3-bace-cb0a264729f6','68c6ce53-d036-4a78-af8b-60eda8571916','3e3b5378-486e-4e0a-a3aa-6993ab0c64e2','30923c37-257f-44cb-a889-fbd99f2f518b','de87ce0d-f021-4849-bfd5-a072ef5cc27e','c72eb789-b4b4-41b2-9b10-b1507d6fcccf','a04d9916-532f-4d04-8628-f3e9e9ce8862','6776fcce-9f10-46e5-84a3-9b58bdffe53e','64afbd9f-e347-4b6b-9aa9-4be061cb66be','8a046c90-47a3-4d23-aa64-cb95c091385f','3fc1680b-267e-4068-828b-7f8eb5b7dda2','d6b20d5a-ed29-4fd0-a51f-904184f7797a','8b3c16da-1aee-459d-87d3-e15c474197e5','72a4417f-65cb-4245-859c-78ffb713641b','897b7cdb-d073-4fb1-88d5-f4670c8c701a','cc593de4-7457-474b-a855-7938aacfda45','7c847abc-fa34-4d45-8f7b-b713ee7dc7fb','2b7d3ee1-8977-42d1-a83a-31b3b668e742','b647f87e-4b85-4ee9-bc3d-c32ccac6747c','c014ea7a-e5da-4cc6-b11d-9aac2215f836','471e45e3-b982-4704-a436-49867c91aa93','406131aa-a4f4-442b-bd90-eb7a1569c4bf','55f04c50-e660-4fb3-a7b5-301f19823813','e9cec2dc-b308-4eb0-bc45-1dee717445cb','8588c86b-35c7-4a40-aa3f-5c1c943d82d0','1bb3361c-f55d-4aad-8b08-9104133beaca','720c91b7-35ca-43cc-a274-be4244bbe8e2','33e531bf-e378-4f2b-80be-6eb8a8cb5d8f','6053a88d-c44f-41d7-8e62-d72dc160e105','da71948a-39aa-4b3d-913a-7b8e44275167','79fb76ed-cd21-45a8-9301-4d68aaffde0f','e4c96a5f-0853-4415-aba0-5e69025d3c96','8d19cb27-3128-4796-96e1-499aab16415d','3c893407-beb5-492c-aa7f-384f16666bd2','d226ea8b-a601-4e92-8815-6ad3e6104a73','b2319789-8124-4406-a285-dc8dc498c159'
);

-- verify (overall connected mills remaining without website; expect = sectors 3 + all NULLs accumulated)
select count(distinct p.id) as connected_mill_no_website
from app.parties p join app.party_supply_links sl on sl.mill_party_id = p.id
where p.party_type_id = 2 and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (p.website is null or p.website not ilike 'http%') and sl.deleted_at is null;
