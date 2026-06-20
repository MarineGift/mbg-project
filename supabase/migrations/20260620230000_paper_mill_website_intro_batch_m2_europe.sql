-- 20260620230000_paper_mill_website_intro_batch_m2_europe.sql
-- paper_mill (party_type_id = 2) website + intro - BATCH m2 (EUROPE, 38 mills).
-- Supply-link-connected EU mills with no website. Corporate domains (mill -> parent site).
-- 3 left NULL (no reliable domain): Arjowiggins (liquidated 2019), Palm+WEPA+Koehler
-- (3-way composite), Svetogorsk (Russian-owned post-2022). UTF-8. RUN IN SUPABASE SQL EDITOR.
-- Idempotent: website only where missing/non-URL; intro overwrite ok (was empty). Org+type scoped.

-- 1) website (only where currently missing or non-URL)
update app.parties p
set website = d.url, updated_at = now()
from (values
  ('5ea98772-4478-4393-bef4-e19510694e84'::uuid, 'https://www.arcticpaper.com'),  -- Arctic Paper Kostrzyn
  ('c2f04477-d7fe-42a3-bf50-68171bee1897'::uuid, 'https://www.borregaard.com'),  -- Borregaard AS
  ('5d8ce5a9-5fa3-4be6-a92f-e2349e4a46c8'::uuid, 'https://www.burgo.com'),  -- Burgo 10 plants
  ('8ad7e4c4-d61d-4d12-9454-2ed605637fe7'::uuid, 'https://www.clairefontaine.com'),  -- Clairefontaine (Everbal)
  ('17b713d9-28fd-49d0-a3c5-6766f736beb7'::uuid, 'https://www.delfortgroup.com'),  -- Delfort Tervakoski
  ('d5e11913-f69d-4feb-bac2-4140025034b3'::uuid, 'https://www.dssmith.com'),  -- DS Smith + Smurfit Westrock
  ('f0cb97c6-ff60-486b-a4bd-0377216ae212'::uuid, 'https://www.dssmith.com'),  -- DS Smith Kemsley Mill
  ('5fc29c27-cb4f-4808-926e-9f9f602227f6'::uuid, 'https://www.fedrigoni.com'),  -- Fedrigoni 6 mills
  ('11ac1caf-00fe-4927-b809-41869d8267a4'::uuid, 'https://www.groupe-gascogne.com'),  -- Gascogne + Fibre Excellence + IP Celimo
  ('a8ff9f12-61fb-4481-8c3d-89c3c45efb26'::uuid, 'https://www.lenzing.com'),  -- Lenzing Group
  ('a6c40f65-0c31-4125-be68-6ec4f5c26163'::uuid, 'https://www.lucartgroup.com'),  -- Lucart + RDM + ICT
  ('f1dd192e-832b-401e-84b1-a32f600100f4'::uuid, 'https://www.metsaboard.com'),  -- Metsä Board Äänekoski
  ('1fa8627a-4bea-4186-9198-41669d58c8ac'::uuid, 'https://www.metsafibre.com'),  -- Metsä Fibre Kemi + Äänekoski
  ('3cda8b96-cfd0-4df8-9536-26ff4629106e'::uuid, 'https://www.miquelycostas.com'),  -- Miquel y Costas + Torraspapel + Sniace
  ('cd039913-b0c9-4deb-a128-eb6f94457b00'::uuid, 'https://www.mm.group'),  -- MM Kwidzyn
  ('332395ac-93ba-41f4-9958-f74238f90f7f'::uuid, 'https://www.nordic-paper.com'),  -- Nordic Paper + MM Follacell + VPK + Ranheim
  ('f87785f2-ab6d-4188-805b-969e986b8cec'::uuid, 'https://www.norskeskog.com'),  -- Norske Skog Bruck + Smurfit Kappa Nettingsdorfer
  ('ba901a6c-1225-4af7-b0bf-584089c549fb'::uuid, 'https://www.norskeskog.com'),  -- Norske Skog Skogn + Saugbrugs
  ('01cdc040-438d-4d52-b1ec-026c8823f96c'::uuid, 'https://www.heinzel.com'),  -- Pöls + Laakirchen
  ('8ac2eecd-d317-4acc-ab13-712a3653f3ed'::uuid, 'https://www.saica.com'),  -- Saica + IP Madrid
  ('7815159f-7af9-4670-949f-f39dbcaa3aa5'::uuid, 'https://www.sappi.com'),  -- Sappi Stockstadt
  ('74c90754-78df-4c47-82bd-67a889e22798'::uuid, 'https://www.sca.com'),  -- SCA Munksund + Obbola
  ('b309c12b-daec-4603-8a6a-bdde1a68305f'::uuid, 'https://www.smurfitwestrock.com'),  -- Smurfit Kappa Cellulose de Pin + Smurfit Kappa containerboard
  ('09eff7c5-6074-4de9-99c4-7f05891b7f64'::uuid, 'https://www.smurfitwestrock.com'),  -- Smurfit Westrock + DS Smith Slovakia
  ('c6bab47a-30f0-4c5a-ad1d-605ac507bd72'::uuid, 'https://www.sofidel.com'),  -- Sofidel Italy + USA
  ('7af94eca-d0b9-4b20-a802-5cec7de9c3db'::uuid, 'https://www.sonaearauco.com'),  -- Sonae Arauco + Gescartao + Gomà-Camps
  ('e707def3-a4e5-4363-8a1a-e5ac302f9d2d'::uuid, 'https://www.storaenso.com'),  -- Stora Enso Imatra (Kaukopää + Tainionkoski)
  ('79ec3cf1-ae64-4d9f-9b67-072ea508bbfd'::uuid, 'https://www.storaenso.com'),  -- Stora Enso Oulu + Imatra + Enocell
  ('574bbeb1-4878-4fbf-9556-87c93bde591f'::uuid, 'https://www.storaenso.com'),  -- Stora Enso Skutskär + Norrsundet + Fors
  ('1dd27154-7f00-4f85-aa94-dddc30a785df'::uuid, 'https://www.storaenso.com'),  -- Stora Enso Veitsiluoto Kemi (closed 2021)
  ('cf9d368a-3488-4a06-bde3-8f88bb2faf3f'::uuid, 'https://www.sylvamo.com'),  -- Sylvamo - Nymolla Mill (Nymolla)
  ('e0457d0e-8072-47c6-8663-a18892ce40bc'::uuid, 'https://www.sylvamo.com'),  -- Sylvamo Saillat-sur-Vienne
  ('5f63ed6c-edc6-4467-a053-b4b9f8c7f2cd'::uuid, 'https://www.upm.com'),  -- UPM Kaukas Lappeenranta
  ('1ee35f22-f97b-45ed-8980-1c349f40dc71'::uuid, 'https://www.upm.com'),  -- UPM Kymi (Kuusankoski)
  ('bc76f030-fa9f-477f-8571-2c1c3917f6c1'::uuid, 'https://www.upm.com')  -- UPM multi-mill
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2
  and (p.website is null or p.website not ilike 'http%');

-- 2) company intro (ko/en) - all 38, incl. the 3 without a website
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('5ea98772-4478-4393-bef4-e19510694e84'::uuid,
   '스웨덴 상장 Arctic Paper 그룹의 폴란드 Kostrzyn 공장. 고품질 무코팅 인쇄용지(book/offset)를 생산하는 그룹의 핵심 거점.',
   'The Kostrzyn (Poland) mill of Sweden-listed Arctic Paper, a key site producing high-quality uncoated graphic (book/offset) papers.'),  -- Arctic Paper Kostrzyn
  ('ddf55a91-53c8-4263-8b92-c3dc58335c81'::uuid,
   '프랑스의 유서 깊은 특수지·고급지 제조 브랜드(Arjowiggins). 2019년 모기업 파산 후 자산이 분할·정리되어 단일 그룹 도메인은 부재.',
   'A historic French specialty/fine-paper brand (Arjowiggins); after the 2019 parent insolvency its assets were broken up, so no single group domain exists.'),  -- Arjowiggins
  ('c2f04477-d7fe-42a3-bf50-68171bee1897'::uuid,
   '노르웨이의 바이오리파이너리 기업. 목재에서 특수셀룰로스·리그닌·바닐린 등을 생산하며 제지용 특수셀룰로스도 공급.',
   'A Norwegian biorefinery producing specialty cellulose, lignin and vanillin from wood, including specialty cellulose for paper applications.'),  -- Borregaard AS
  ('5d8ce5a9-5fa3-4be6-a92f-e2349e4a46c8'::uuid,
   '이탈리아 최대 제지그룹 Burgo. 코팅·무코팅 인쇄용지와 특수지를 다수 공장에서 생산하는 남유럽 대표 제지사.',
   'Italy''s largest paper group, Burgo, producing coated/uncoated graphic and specialty papers across multiple mills; a leading Southern European maker.'),  -- Burgo 10 plants
  ('8ad7e4c4-d61d-4d12-9454-2ed605637fe7'::uuid,
   '프랑스 Exacompta Clairefontaine 계열의 종합 제지·문구사. Everbal 등 자사 공장에서 인쇄·필기용지를 생산.',
   'Part of France''s Exacompta Clairefontaine, a paper-and-stationery maker producing printing/writing papers at sites including Everbal.'),  -- Clairefontaine (Everbal)
  ('17b713d9-28fd-49d0-a3c5-6766f736beb7'::uuid,
   '오스트리아 delfort 그룹의 핀란드 Tervakoski 공장. 박엽지·담배용지·라벨/플렉시블 특수지 등 경량 특수지를 생산.',
   'The Tervakoski (Finland) mill of Austria''s delfort group, producing lightweight specialty papers such as thin printing, cigarette and label/flexible papers.'),  -- Delfort Tervakoski
  ('d5e11913-f69d-4feb-bac2-4140025034b3'::uuid,
   'DS Smith(현 International Paper 계열)와 Smurfit Westrock가 연계된 독일 거점. 골판지 원지 등 재생기반 포장지를 생산.',
   'A German site associated with DS Smith (now part of International Paper) and Smurfit Westrock, producing recycled-based packaging papers such as containerboard.'),  -- DS Smith + Smurfit Westrock
  ('f0cb97c6-ff60-486b-a4bd-0377216ae212'::uuid,
   '영국 Kent주 Kemsley에 위치한 DS Smith의 대형 재생 골판지 원지 공장. 유럽 최대급 재생제지 거점 중 하나.',
   'DS Smith''s large recycled containerboard mill at Kemsley, Kent (UK); one of Europe''s biggest recycled-paper sites.'),  -- DS Smith Kemsley Mill
  ('5fc29c27-cb4f-4808-926e-9f9f602227f6'::uuid,
   '이탈리아 Fedrigoni 그룹. 고급 특수지·프리미엄 라벨·보안용지를 여러 공장에서 생산하는 특수지 선도사.',
   'Italy''s Fedrigoni group, a specialty-paper leader producing premium specialty, label and security papers across several mills.'),  -- Fedrigoni 6 mills
  ('11ac1caf-00fe-4927-b809-41869d8267a4'::uuid,
   '프랑스 Gascogne 그룹 주도의 거점(Fibre Excellence·IP Celimo 연계). 크라프트지·포장지와 펄프를 생산.',
   'A French cluster led by Groupe Gascogne (linked with Fibre Excellence and IP Celimo), producing kraft/packaging papers and pulp.'),  -- Gascogne + Fibre Excellence + IP Celimo
  ('a8ff9f12-61fb-4481-8c3d-89c3c45efb26'::uuid,
   '오스트리아 Lenzing. 목재펄프 기반 셀룰로스 섬유(비스코스/리오셀)와 용해펄프를 생산하는 글로벌 기업.',
   'Austria''s Lenzing, a global producer of wood-pulp-based cellulosic fibres (viscose/lyocell) and dissolving pulp.'),  -- Lenzing Group
  ('a6c40f65-0c31-4125-be68-6ec4f5c26163'::uuid,
   '이탈리아 Lucart 그룹 주도(RDM·ICT 연계). 티슈·재생 위생지와 판지를 생산하는 남유럽 거점.',
   'A Southern European cluster led by Italy''s Lucart Group (with RDM and ICT), producing tissue, recycled hygiene papers and board.'),  -- Lucart + RDM + ICT
  ('f1dd192e-832b-401e-84b1-a32f600100f4'::uuid,
   '핀란드 Metsä Group 계열 Metsä Board의 Äänekoski 거점. 신선목섬유 폴딩박스보드(FBB)·화이트라이너를 생산.',
   'Metsä Board (Metsä Group, Finland) at Äänekoski, producing fresh-fibre folding boxboard (FBB) and white kraftliner.'),  -- Metsä Board Äänekoski
  ('1fa8627a-4bea-4186-9198-41669d58c8ac'::uuid,
   '핀란드 Metsä Group의 펄프 자회사 Metsä Fibre. Kemi·Äänekoski 바이오제품공장에서 표백 크라프트펄프를 생산.',
   'Metsä Fibre, the pulp arm of Finland''s Metsä Group, producing bleached kraft pulp at its Kemi and Äänekoski bioproduct mills.'),  -- Metsä Fibre Kemi + Äänekoski
  ('3cda8b96-cfd0-4df8-9536-26ff4629106e'::uuid,
   '스페인 Miquel y Costas 주도 거점(Torraspapel·Sniace 연계). 박엽지·담배용지 등 경량 특수지를 생산.',
   'A Spanish cluster led by Miquel y Costas (with Torraspapel and Sniace), producing lightweight specialty papers including thin and cigarette papers.'),  -- Miquel y Costas + Torraspapel + Sniace
  ('cd039913-b0c9-4deb-a128-eb6f94457b00'::uuid,
   '오스트리아 Mayr-Melnhof(MM) 그룹의 폴란드 Kwidzyn 일관공장(2021년 IP에서 인수). 신선목섬유 판지(FBB)·무코팅 인쇄용지·크라프트지·펄프를 생산.',
   'Mayr-Melnhof (MM) Group''s integrated Kwidzyn mill in Poland (acquired from IP in 2021), producing virgin-fibre cartonboard (FBB), uncoated fine paper, kraft paper and pulp.'),  -- MM Kwidzyn
  ('332395ac-93ba-41f4-9958-f74238f90f7f'::uuid,
   '스웨덴·노르웨이 Nordic Paper 주도 거점(MM Follacell·VPK·Ranheim 연계). 크라프트지·내유성지(greaseproof)를 생산.',
   'A Nordic cluster led by Nordic Paper (Sweden/Norway, with MM Follacell, VPK and Ranheim), producing kraft and greaseproof papers.'),  -- Nordic Paper + MM Follacell + VPK + Ranheim
  ('f87785f2-ab6d-4188-805b-969e986b8cec'::uuid,
   '노르웨이 Norske Skog의 오스트리아 Bruck 공장(Smurfit Kappa Nettingsdorfer 연계). 출판용지에서 재생 포장지·에너지로 전환 중인 거점.',
   'Norske Skog''s Bruck mill in Austria (linked with Smurfit Kappa Nettingsdorfer), a site transitioning from publication paper toward recycled packaging and energy.'),  -- Norske Skog Bruck + Smurfit Kappa Nettingsdorfer
  ('ba901a6c-1225-4af7-b0bf-584089c549fb'::uuid,
   '노르웨이 Norske Skog의 Skogn·Saugbrugs 공장. 신문용지·잡지용지(SC)와 함께 재생 포장원지로 사업을 확장 중.',
   'Norske Skog''s Skogn and Saugbrugs mills in Norway, making newsprint and magazine (SC) papers while expanding into recycled packaging grades.'),  -- Norske Skog Skogn + Saugbrugs
  ('7ffdfb30-8505-4f13-bd6e-d7b865bcf24f'::uuid,
   '독일 제지 3사(Papierfabrik Palm·WEPA·Koehler)를 묶은 복합 항목. 각각 포장원지·위생용지·특수지로 사업이 달라 단일 대표 도메인은 두지 않음.',
   'A composite of three German makers (Papierfabrik Palm, WEPA, Koehler) spanning packaging, hygiene and specialty papers respectively; no single representative domain is assigned.'),  -- Palm + WEPA + Koehler
  ('01cdc040-438d-4d52-b1ec-026c8823f96c'::uuid,
   '오스트리아 Heinzel 그룹의 Pöls(표백 크라프트펄프·크라프트지)·Laakirchen(재생 골판지 원지) 공장.',
   'The Pöls (bleached kraft pulp and kraft paper) and Laakirchen (recycled containerboard) mills of Austria''s Heinzel Group.'),  -- Pöls + Laakirchen
  ('8ac2eecd-d317-4acc-ab13-712a3653f3ed'::uuid,
   '스페인 Saica 그룹 주도 거점(IP Madrid 연계). 재생 골판지 원지와 포장 솔루션을 생산하는 유럽 대형 재생제지사.',
   'A cluster led by Spain''s Saica Group (with IP Madrid), a major European recycled-paper maker producing containerboard and packaging.'),  -- Saica + IP Madrid
  ('7815159f-7af9-4670-949f-f39dbcaa3aa5'::uuid,
   '남아공 본사 글로벌 제지사 Sappi의 독일 Stockstadt 공장. 코팅 인쇄용지·특수지와 펄프를 생산.',
   'The Stockstadt (Germany) mill of South Africa-headquartered global paper maker Sappi, producing coated graphic/specialty papers and pulp.'),  -- Sappi Stockstadt
  ('74c90754-78df-4c47-82bd-67a889e22798'::uuid,
   '스웨덴 SCA의 Munksund·Obbola 공장. 신선목섬유 크라프트라이너(골판지 표층지)를 생산하는 유럽 대형 거점.',
   'SCA''s Munksund and Obbola mills in Sweden, large European sites producing fresh-fibre kraftliner for corrugated packaging.'),  -- SCA Munksund + Obbola
  ('b309c12b-daec-4603-8a6a-bdde1a68305f'::uuid,
   'Smurfit Westrock(2024년 Smurfit Kappa+WestRock 합병)의 프랑스 거점(Cellulose du Pin 등). 크라프트펄프·골판지 원지를 생산.',
   'A French site of Smurfit Westrock (the 2024 Smurfit Kappa + WestRock merger), incl. Cellulose du Pin, producing kraft pulp and containerboard.'),  -- Smurfit Kappa Cellulose de Pin + Smurfit Kappa containerboard
  ('09eff7c5-6074-4de9-99c4-7f05891b7f64'::uuid,
   'Smurfit Westrock의 슬로바키아 거점(DS Smith 연계). 재생/신선섬유 골판지 원지와 포장지를 생산.',
   'A Slovak site of Smurfit Westrock (linked with DS Smith), producing recycled/virgin containerboard and packaging papers.'),  -- Smurfit Westrock + DS Smith Slovakia
  ('c6bab47a-30f0-4c5a-ad1d-605ac507bd72'::uuid,
   '이탈리아 Sofidel 그룹(브랜드 Regina). 티슈·위생용지를 이탈리아·미국 등에서 생산하는 세계 2위급 티슈 제조사.',
   'Italy''s Sofidel group (Regina brand), one of the world''s largest tissue makers, producing tissue/hygiene papers in Italy, the USA and beyond.'),  -- Sofidel Italy + USA
  ('7af94eca-d0b9-4b20-a802-5cec7de9c3db'::uuid,
   '포르투갈 Sonae Arauco 주도 거점(Gescartão·Gomà-Camps 연계). 목재기반 패널과 함께 포장원지·티슈가 연계된 이베리아 거점.',
   'An Iberian cluster led by Portugal''s Sonae Arauco (with Gescartão and Gomà-Camps), spanning wood-based panels alongside packaging and tissue papers.'),  -- Sonae Arauco + Gescartao + Gomà-Camps
  ('e707def3-a4e5-4363-8a1a-e5ac302f9d2d'::uuid,
   '핀란드 Stora Enso의 Imatra 공장군(Kaukopää·Tainionkoski). 식품·액체용 판지(carton board)와 크라프트지를 생산.',
   'Stora Enso''s Imatra mills in Finland (Kaukopää and Tainionkoski), producing food/liquid carton board and kraft papers.'),  -- Stora Enso Imatra (Kaukopää + Tainionkoski)
  ('79ec3cf1-ae64-4d9f-9b67-072ea508bbfd'::uuid,
   '핀란드 Stora Enso의 Oulu(포장용지로 전환)·Imatra·Enocell(펄프) 거점. 신선목섬유 포장재·판지·펄프를 생산.',
   'Stora Enso''s Oulu (converted to packaging), Imatra and Enocell (pulp) sites in Finland, producing fresh-fibre packaging, board and pulp.'),  -- Stora Enso Oulu + Imatra + Enocell
  ('574bbeb1-4878-4fbf-9556-87c93bde591f'::uuid,
   '스웨덴 Stora Enso의 Skutskär(펄프)·Fors(판지) 등 거점. 표백 크라프트펄프와 식품용 판지를 생산.',
   'Stora Enso''s Swedish sites incl. Skutskär (pulp) and Fors (board), producing bleached kraft pulp and food-grade carton board.'),  -- Stora Enso Skutskär + Norrsundet + Fors
  ('1dd27154-7f00-4f85-aa94-dddc30a785df'::uuid,
   '핀란드 Stora Enso의 옛 Veitsiluoto(Kemi) 공장. 인쇄용지 생산 거점이었으나 2021년 폐쇄됨.',
   'Stora Enso''s former Veitsiluoto mill at Kemi, Finland; a graphic-paper site that was closed in 2021.'),  -- Stora Enso Veitsiluoto Kemi (closed 2021)
  ('64f722c7-82ea-4de9-8044-be0a3cf19b71'::uuid,
   '러시아 Svetogorsk 펄프·제지공장. 옛 International Paper/Sylvamo 소유였으나 2022년 이후 러시아 측에 매각되어 신뢰할 공식 도메인이 부재.',
   'The Svetogorsk pulp & paper mill in Russia; formerly owned by International Paper/Sylvamo but sold to Russian ownership after 2022, with no reliable official domain.'),  -- Svetogorsk PPM
  ('cf9d368a-3488-4a06-bde3-8f88bb2faf3f'::uuid,
   '글로벌 무코팅 인쇄용지사 Sylvamo(IP에서 2021년 분사)의 스웨덴 Nymölla 공장. 무코팅 인쇄용지와 펄프를 생산.',
   'The Nymölla (Sweden) mill of Sylvamo (spun off from International Paper in 2021), producing uncoated freesheet papers and pulp.'),  -- Sylvamo - Nymolla Mill (Nymolla)
  ('e0457d0e-8072-47c6-8663-a18892ce40bc'::uuid,
   'Sylvamo의 프랑스 Saillat-sur-Vienne 공장. 사무용·인쇄용 무코팅지를 생산하는 서유럽 거점.',
   'Sylvamo''s Saillat-sur-Vienne mill in France, a Western European site producing office and printing uncoated freesheet papers.'),  -- Sylvamo Saillat-sur-Vienne
  ('5f63ed6c-edc6-4467-a053-b4b9f8c7f2cd'::uuid,
   '핀란드 UPM의 Lappeenranta Kaukas 일관단지. 펄프·인쇄용지와 바이오리파이너리(목질 디젤)를 함께 운영.',
   'UPM''s integrated Kaukas complex at Lappeenranta, Finland, combining pulp, graphic papers and a wood-based biorefinery (renewable diesel).'),  -- UPM Kaukas Lappeenranta
  ('1ee35f22-f97b-45ed-8980-1c349f40dc71'::uuid,
   '핀란드 UPM의 Kymi(Kuusankoski) 일관공장. 표백 크라프트펄프와 무코팅·코팅 인쇄용지를 생산.',
   'UPM''s integrated Kymi mill at Kuusankoski, Finland, producing bleached kraft pulp and uncoated/coated graphic papers.'),  -- UPM Kymi (Kuusankoski)
  ('bc76f030-fa9f-477f-8571-2c1c3917f6c1'::uuid,
   '핀란드 본사 글로벌 제지·바이오 기업 UPM의 다수 공장. 인쇄용지·특수라벨지·펄프·바이오연료를 생산.',
   'Multiple mills of UPM, the Finland-headquartered global paper-and-bio company producing graphic papers, specialty/label papers, pulp and biofuels.')  -- UPM multi-mill
) as d(party_id, intro_ko, intro_en)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2;

-- verify
select
  count(*) filter (where website ilike 'http%') as with_url,
  count(*) filter (where intro_ko is not null and intro_ko <> '') as with_intro
from app.parties
where id in (
  '5ea98772-4478-4393-bef4-e19510694e84','ddf55a91-53c8-4263-8b92-c3dc58335c81','c2f04477-d7fe-42a3-bf50-68171bee1897','5d8ce5a9-5fa3-4be6-a92f-e2349e4a46c8','8ad7e4c4-d61d-4d12-9454-2ed605637fe7','17b713d9-28fd-49d0-a3c5-6766f736beb7','d5e11913-f69d-4feb-bac2-4140025034b3','f0cb97c6-ff60-486b-a4bd-0377216ae212','5fc29c27-cb4f-4808-926e-9f9f602227f6','11ac1caf-00fe-4927-b809-41869d8267a4','a8ff9f12-61fb-4481-8c3d-89c3c45efb26','a6c40f65-0c31-4125-be68-6ec4f5c26163','f1dd192e-832b-401e-84b1-a32f600100f4','1fa8627a-4bea-4186-9198-41669d58c8ac','3cda8b96-cfd0-4df8-9536-26ff4629106e','cd039913-b0c9-4deb-a128-eb6f94457b00','332395ac-93ba-41f4-9958-f74238f90f7f','f87785f2-ab6d-4188-805b-969e986b8cec','ba901a6c-1225-4af7-b0bf-584089c549fb','7ffdfb30-8505-4f13-bd6e-d7b865bcf24f','01cdc040-438d-4d52-b1ec-026c8823f96c','8ac2eecd-d317-4acc-ab13-712a3653f3ed','7815159f-7af9-4670-949f-f39dbcaa3aa5','74c90754-78df-4c47-82bd-67a889e22798','b309c12b-daec-4603-8a6a-bdde1a68305f','09eff7c5-6074-4de9-99c4-7f05891b7f64','c6bab47a-30f0-4c5a-ad1d-605ac507bd72','7af94eca-d0b9-4b20-a802-5cec7de9c3db','e707def3-a4e5-4363-8a1a-e5ac302f9d2d','79ec3cf1-ae64-4d9f-9b67-072ea508bbfd','574bbeb1-4878-4fbf-9556-87c93bde591f','1dd27154-7f00-4f85-aa94-dddc30a785df','64f722c7-82ea-4de9-8044-be0a3cf19b71','cf9d368a-3488-4a06-bde3-8f88bb2faf3f','e0457d0e-8072-47c6-8663-a18892ce40bc','5f63ed6c-edc6-4467-a053-b4b9f8c7f2cd','1ee35f22-f97b-45ed-8980-1c349f40dc71','bc76f030-fa9f-477f-8571-2c1c3917f6c1'
);
