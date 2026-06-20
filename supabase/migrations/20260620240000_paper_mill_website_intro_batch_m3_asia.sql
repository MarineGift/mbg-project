-- 20260620240000_paper_mill_website_intro_batch_m3_asia.sql
-- paper_mill (party_type_id = 2) website + intro - BATCH m3 (ASIA, 41 mills).
-- Supply-link-connected Asian mills with no website. Corporate domains (mill -> parent/group site).
-- 13 left NULL (small/unverified): see comments. NOTE Daehan Pulp -> Kleannara (renamed 2011;
-- NOT the same as Daehan Paper/daehanpaper.com). UTF-8. RUN IN SUPABASE SQL EDITOR.
-- Idempotent: website only where missing/non-URL; intro overwrite ok. Org+type scoped.

-- 1) website (only where currently missing or non-URL; this also overwrites the stray 'B' on Daehan Pulp)
update app.parties p
set website = d.url, updated_at = now()
from (values
  ('1a35b462-79e5-44d0-84df-a7dea4ce1d94'::uuid, 'https://www.rgei.com'),  -- Asia Symbol (Rugao, Nantong)
  ('08e82ea2-eed9-40ed-b279-a8cacc84dc12'::uuid, 'https://www.chenmingpaper.com'),  -- Chenming Paper
  ('000812ab-3fe9-45ad-9773-07f22d0283d1'::uuid, 'https://www.asiapulppaper.com'),  -- Gold East Paper
  ('a6f46744-3238-4057-a7c9-e62403fe968b'::uuid, 'https://www.asiapulppaper.com'),  -- Gold Huasheng Paper (APP)
  ('6f7c12be-0182-4ccd-bced-89c8cc41901d'::uuid, 'https://www.ndpaper.com'),  -- Nine Dragons - Beihai Base (Beihai)
  ('2f403cd1-6e53-48a0-8c1e-3b2c9b3c9844'::uuid, 'https://www.sunpapergroup.com'),  -- Shandong Sun Paper
  ('e4c573e5-5a7a-4025-bce3-58d8bd79a046'::uuid, 'https://www.asiapulppaper.com'),  -- PT Indah Kiat Pulp & Paper
  ('6ad04789-209f-4df1-b185-24a50c60717d'::uuid, 'https://www.andhrapaper.com'),  -- Andhra Paper Limited
  ('4a2112db-b063-42c8-afb0-4126c0c7a38b'::uuid, 'https://www.bilt.com'),  -- BILT Sewa Unit
  ('de740c5b-323c-4a74-9a4a-7212ec9a7dd9'::uuid, 'https://www.bilt.com'),  -- Ballarpur Industries Ltd.
  ('3f29730f-528e-47a3-bd4c-ac82c5dd2d8d'::uuid, 'https://www.jkpaper.com'),  -- JK Paper Limited
  ('f1e0a67a-8cf2-41e0-938c-caaec218a5c7'::uuid, 'https://www.satiagroup.com'),  -- Satia Industries Limited
  ('a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid, 'https://www.seshapaper.com'),  -- Seshasayee Paper & Boards Ltd.
  ('d3d18246-80e7-4f60-9aef-20c22713f75a'::uuid, 'https://www.tnpl.com'),  -- Tamil Nadu Newsprint & Papers Ltd. (TNPL)
  ('3596af41-c22c-420b-b4b4-52f44188afe3'::uuid, 'https://www.westcoastpaper.com'),  -- West Coast Paper Mills Ltd.
  ('570aaa49-61e9-43b0-a1af-644d4403e36e'::uuid, 'https://www.nipponpapergroup.com'),  -- Nippon Paper Industries - Shiraoi Mill (Shiraoi)
  ('da6ee20c-3b4b-4eb5-8fd4-a4c5a7dc0ac6'::uuid, 'https://www.kleannara.co.kr'),  -- Daehan Pulp
  ('913b37b7-dd16-4e50-88ec-3831dc5af687'::uuid, 'https://www.aitkenspence.com'),  -- Aitken Spence Printing
  ('e61f2e0d-cb46-4a00-9feb-9094b77a2a02'::uuid, 'https://www.centurypaper.com.pk'),  -- Century Paper & Board Mills
  ('dedc9cf2-b21d-46ed-b57d-15a21aa5a1da'::uuid, 'https://www.packages.com.pk'),  -- Packages Limited / Bulleh Shah Packaging
  ('cd2af0b1-a9ff-4251-aafd-4395ae3228b4'::uuid, 'https://www.bashundharagroup.com'),  -- Bashundhara Unit-1
  ('843a03f7-f4e5-4925-aece-fa6132acfd6f'::uuid, 'https://www.doubleapaper.com'),  -- Advance Agro
  ('8a99e736-95a1-41da-9d36-09036fb96ebd'::uuid, 'https://www.doubleapaper.com'),  -- Double A
  ('17a84a38-1d0f-4883-ac25-2810181228f8'::uuid, 'https://www.ojiholdings.co.jp'),  -- Oji Paper (Thailand) Ltd.
  ('49f234b1-f442-479c-92a0-edadf3c36964'::uuid, 'https://www.phoenixpulpandpaper.com'),  -- Phoenix Pulp & Paper
  ('1604c865-b437-49d2-a304-30fc9baeb512'::uuid, 'https://www.scgpackaging.com'),  -- SCG Packaging / packaging chain
  ('6994c74f-dd38-459a-ab9a-60c6eee41fc3'::uuid, 'https://www.thaipaper.com')  -- Thai Paper Co., Ltd. (SCG Packaging)
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2
  and (p.website is null or p.website not ilike 'http%');

-- 2) company intro (ko/en) - all 41, incl. the 13 without a website
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('1a35b462-79e5-44d0-84df-a7dea4ce1d94'::uuid,
   '싱가포르 RGE(Royal Golden Eagle) 그룹의 중국 펄프·제지사 Asia Symbol. 표백활엽수펄프(BHKP)와 고급 인쇄용지·아이보리 보드를 산둥(르자오)·광둥에서 생산.',
   'Asia Symbol, the Chinese pulp & paper arm of Singapore''s RGE (Royal Golden Eagle) group, producing BHKP pulp and fine printing/ivory-board papers in Shandong (Rizhao) and Guangdong.'),  -- Asia Symbol (Rugao, Nantong)
  ('08e82ea2-eed9-40ed-b279-a8cacc84dc12'::uuid,
   '중국 최대급 제지기업 Shandong Chenming Paper(상장). 아트지·경량 코팅지·백판지·인쇄용지를 다수 공장에서 생산.',
   'Shandong Chenming Paper, one of China''s largest listed paper makers, producing art, lightweight-coated, white board and printing papers across multiple mills.'),  -- Chenming Paper
  ('000812ab-3fe9-45ad-9773-07f22d0283d1'::uuid,
   'Asia Pulp & Paper(APP, Sinar Mas) 중국 계열의 Gold East Paper(장쑤). 세계 최대급 코팅 인쇄용지 생산거점.',
   'Gold East Paper (Jiangsu), an APP (Asia Pulp & Paper, Sinar Mas) China mill and one of the world''s largest coated graphic-paper sites.'),  -- Gold East Paper
  ('a6f46744-3238-4057-a7c9-e62403fe968b'::uuid,
   'APP(Sinar Mas) 중국 계열의 Gold Huasheng Paper(쑤저우 공업원구). 인쇄·문화용지를 생산.',
   'Gold Huasheng Paper (Suzhou Industrial Park), an APP (Sinar Mas) China mill producing printing and cultural papers.'),  -- Gold Huasheng Paper (APP)
  ('7e7cb097-b8fe-41a9-a0e1-fc810a022cca'::uuid,
   '중국 허난성의 중소 제지사 Henan Jianghe Paper. 공개 정보가 제한적이라 공식 도메인은 미확인.',
   'Henan Jianghe Paper, a small/mid Chinese mill in Henan province; no verified official domain (limited public information).'),  -- Henan Jianghe Paper
  ('31df6baf-98f0-4b8f-89de-7db412312eff'::uuid,
   '중국 광시성 난닝의 중소 제지사 Nanning Jindaxing Paper. 공식 도메인 미확인.',
   'Nanning Jindaxing Paper, a small/mid Chinese mill in Nanning, Guangxi; no verified official domain.'),  -- Nanning Jindaxing Paper
  ('6f7c12be-0182-4ccd-bced-89c8cc41901d'::uuid,
   '중국 최대 골판지/포장원지 기업 Nine Dragons(玖龍, ND Paper)의 광시 베이하이 기지. 재생기반 포장원지를 대량 생산.',
   'The Beihai (Guangxi) base of Nine Dragons (ND Paper), China''s largest containerboard/packaging-paper maker, producing recycled-based packaging papers at scale.'),  -- Nine Dragons - Beihai Base (Beihai)
  ('2f403cd1-6e53-48a0-8c1e-3b2c9b3c9844'::uuid,
   '중국 산둥 Sun Paper 그룹(상장). 문화용지·포장원지·식품용지와 펄프(용해펄프 포함)를 생산하는 글로벌 제지기업.',
   'Shandong Sun Paper (listed), a Chinese global paper group producing cultural, packaging and food-grade papers plus pulp (incl. dissolving pulp).'),  -- Shandong Sun Paper
  ('6939a129-bfa2-4114-be61-529b8e487ec1'::uuid,
   '중국 저장성의 중소 제지/소재사 Zhejiang Zhefeng. 공식 도메인 미확인.',
   'Zhejiang Zhefeng New Materials, a small/mid Chinese paper/materials maker in Zhejiang; no verified official domain.'),  -- Zhejiang Zhefeng New Materials Co.
  ('46cc9ad2-e14f-43c6-a600-1e623c0256be'::uuid,
   '중국 저장성의 중소 제지사 Zhejiang Zhengda Paper. 공식 도메인 미확인.',
   'Zhejiang Zhengda Paper Group, a small/mid Chinese mill in Zhejiang; no verified official domain.'),  -- Zhejiang Zhengda Paper Group
  ('4a8427e1-a1c9-4d11-a045-dee92a50840f'::uuid,
   '중국 허난성 주마뎬(쑤이핑)의 중소 제지사 Zhumadian Baiyun Paper. 공식 도메인 미확인.',
   'Zhumadian Baiyun Paper (Suiping, Zhumadian, Henan), a small/mid Chinese mill; no verified official domain.'),  -- Zhumadian Baiyun Paper Co. (Suiping, Zhumadian)
  ('e4c573e5-5a7a-4025-bce3-58d8bd79a046'::uuid,
   '인도네시아 APP(Sinar Mas)의 핵심 일관공장 PT Indah Kiat. 펄프·인쇄용지·티슈·포장재를 대규모로 생산.',
   'PT Indah Kiat, a flagship integrated mill of Indonesia''s APP (Sinar Mas), producing pulp, printing papers, tissue and packaging at large scale.'),  -- PT Indah Kiat Pulp & Paper
  ('4f416164-129c-40d7-b835-fcfc871e7f8c'::uuid,
   '인도 펀자브 소재 중소 제지사 ABC Paper. 농업부산물 기반 인쇄·필기용지를 생산하나 공식 도메인 미확인.',
   'ABC Paper, a small/mid Indian mill (Punjab) producing agro-based printing/writing papers; no verified official domain.'),  -- ABC Paper Limited
  ('6ad04789-209f-4df1-b185-24a50c60717d'::uuid,
   '인도 안드라프라데시의 Andhra Paper(옛 International Paper APPM, 상장). 인쇄·필기용지와 펄프를 생산.',
   'Andhra Paper (formerly International Paper APPM, listed), an Andhra Pradesh maker of printing/writing papers and pulp.'),  -- Andhra Paper Limited
  ('4a2112db-b063-42c8-afb0-4126c0c7a38b'::uuid,
   '인도 Ballarpur Industries(BILT)의 Sewa 공장. 인쇄·필기용지를 생산하는 BILT 계열 거점.',
   'The Sewa unit of India''s Ballarpur Industries (BILT), a BILT-group site producing printing/writing papers.'),  -- BILT Sewa Unit
  ('de740c5b-323c-4a74-9a4a-7212ec9a7dd9'::uuid,
   '인도의 대형 제지기업 Ballarpur Industries(BILT). 인쇄·필기용지·코팅지를 다수 공장에서 생산해 온 인도 제지 대표사.',
   'Ballarpur Industries (BILT), a major Indian paper company historically producing printing/writing and coated papers across multiple mills.'),  -- Ballarpur Industries Ltd.
  ('9f3719af-21fb-4fb5-b5aa-866416b7231f'::uuid,
   '인도 Aditya Birla 계열(Century Textiles) 산하 Century Pulp & Paper(우타라칸드 랄쿠안). 인쇄·필기용지·티슈·라요셀 펄프를 생산. 도메인은 모기업 통합 중이라 미지정.',
   'Century Pulp & Paper (Lalkuan, Uttarakhand), part of India''s Aditya Birla-linked Century Textiles, producing printing/writing papers, tissue and rayon-grade pulp; domain left unset (parent consolidation).'),  -- Century Pulp & Paper
  ('3f29730f-528e-47a3-bd4c-ac82c5dd2d8d'::uuid,
   '인도 JK Organisation 계열의 대형 제지사 JK Paper(상장). 코팅·무코팅 인쇄용지와 포장보드를 생산하는 인도 선도사.',
   'JK Paper (listed, JK Organisation), a leading Indian maker of coated/uncoated graphic papers and packaging board.'),  -- JK Paper Limited
  ('f1e0a67a-8cf2-41e0-938c-caaec218a5c7'::uuid,
   '인도 펀자브의 Satia Industries(상장). 농업부산물·목재 기반 인쇄·필기용지를 생산하는 중견 제지사.',
   'Satia Industries (listed, Punjab), an Indian mid-cap maker of agro/wood-based printing and writing papers.'),  -- Satia Industries Limited
  ('a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid,
   '인도 타밀나두의 Seshasayee Paper & Boards(SPB, 상장). 인쇄·필기용지를 생산하는 남인도 대표 제지사.',
   'Seshasayee Paper & Boards (SPB, listed, Tamil Nadu), a leading South Indian maker of printing and writing papers.'),  -- Seshasayee Paper & Boards Ltd.
  ('d3d18246-80e7-4f60-9aef-20c22713f75a'::uuid,
   '인도 타밀나두 정부 계열의 TNPL. 바가스(사탕수수 부산물) 기반 인쇄용지·신문용지·포장보드를 생산.',
   'Tamil Nadu Newsprint & Papers (TNPL), a Tamil Nadu state-linked maker of bagasse-based printing, newsprint and packaging board.'),  -- Tamil Nadu Newsprint & Papers Ltd. (TNPL)
  ('3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,
   '인도 카르나타카의 West Coast Paper Mills(상장). 인쇄·필기용지와 포장보드를 생산하는 인도 오래된 제지사.',
   'West Coast Paper Mills (listed, Karnataka), a long-established Indian maker of printing/writing papers and packaging board.'),  -- West Coast Paper Mills Ltd.
  ('570aaa49-61e9-43b0-a1af-644d4403e36e'::uuid,
   '일본 Nippon Paper(일본제지) 그룹의 홋카이도 시라오이 공장. 인쇄·포장용지와 펄프를 생산하는 일본 대표 제지사 거점.',
   'The Shiraoi (Hokkaido) mill of Japan''s Nippon Paper Group, producing printing/packaging papers and pulp.'),  -- Nippon Paper Industries - Shiraoi Mill (Shiraoi)
  ('da6ee20c-3b4b-4eb5-8fd4-a4c5a7dc0ac6'::uuid,
   '한국 대한펄프(1966년 창업)가 2011년 사명을 변경한 깨끗한나라(Kleannara). 위생용지(화장지 등)와 펄프 기반 제지·생활용품을 생산.',
   'Kleannara (the 2011 rename of Korea''s Daehan Pulp, founded 1966), producing tissue/hygiene papers and pulp-based paper and household products.'),  -- Daehan Pulp
  ('913b37b7-dd16-4e50-88ec-3831dc5af687'::uuid,
   '스리랑카 대형 복합기업 Aitken Spence PLC 계열의 인쇄/지물 사업. 상업 인쇄·지류 가공을 담당.',
   'The printing/paper arm of Sri Lanka''s diversified conglomerate Aitken Spence PLC, handling commercial printing and paper converting.'),  -- Aitken Spence Printing
  ('6f1136e6-062d-4fdc-b7e6-738e56af8375'::uuid,
   '말레이시아의 중소 제지사 Asia Honour Paper. 공식 도메인 미확인.',
   'Asia Honour Paper Industries, a small/mid Malaysian mill; no verified official domain.'),  -- Asia Honour Paper Industries (M) Sdn Bhd
  ('292c1b9b-194a-4aef-952c-29a430d1fc6d'::uuid,
   '말레이시아 Genting Sanyen 계열의 판지/포장사 GS Paperboard & Packaging. 재생 골판지 원지를 생산하나 단일 공식 도메인 미확정.',
   'GS Paperboard & Packaging (Genting Sanyen, Malaysia), producing recycled containerboard; no single verified domain assigned.'),  -- GS Paperboard & Packaging Sdn Bhd
  ('18ecb713-8f25-4201-a594-bf54b97307c4'::uuid,
   '말레이시아 상장 포장기업 Muda Holdings 산하 Muda Paper Mills. 재생 골판지 원지·포장재를 생산. 공식 도메인은 추후 확인.',
   'Muda Paper Mills under Malaysia''s listed Muda Holdings, producing recycled containerboard and packaging; domain to be verified.'),  -- Muda Holdings Berhad / Muda Paper Mills
  ('99a0ef69-a3cf-4be0-b9c3-69f2c842a445'::uuid,
   '말레이시아 사바주의 대형 펄프·제지 단지 Sabah Forest Industries(SFI). 운영 변동 이력이 있어 공식 도메인 미확정.',
   'Sabah Forest Industries (SFI), a large pulp & paper complex in Sabah, Malaysia; no verified current domain (ownership/operating changes).'),  -- Sabah Forest Industries
  ('f1e73c29-4f78-4ef6-be27-3146ec7aac00'::uuid,
   '필리핀 Trust International Paper(TIPCO)의 Mabalacat 공장(PM1~3). 재생 포장원지를 생산하나 공식 도메인 미확인.',
   'The Mabalacat mill (PM1-3) of the Philippines'' Trust International Paper (TIPCO), producing recycled packaging papers; no verified official domain.'),  -- TIPCO Mabalacat PM1+PM2+PM3
  ('e61f2e0d-cb46-4a00-9feb-9094b77a2a02'::uuid,
   '파키스탄 Lakson 그룹 계열의 Century Paper & Board Mills(상장). 인쇄·포장보드와 라이너/골심지를 생산.',
   'Century Paper & Board Mills (listed, Lakson Group, Pakistan), producing printing/packaging board and liner/fluting papers.'),  -- Century Paper & Board Mills
  ('dedc9cf2-b21d-46ed-b57d-15a21aa5a1da'::uuid,
   '파키스탄 대표 포장기업 Packages Limited 및 Bulleh Shah Packaging. 종이·판지와 포장재를 생산하는 파키스탄 선도사.',
   'Packages Limited and Bulleh Shah Packaging, Pakistan''s leading packaging maker producing paper, board and packaging.'),  -- Packages Limited / Bulleh Shah Packaging
  ('cd2af0b1-a9ff-4251-aafd-4395ae3228b4'::uuid,
   '방글라데시 Bashundhara 그룹의 제지 사업(Unit-1). 인쇄·필기용지·티슈를 생산하는 방글라데시 대형 제지 거점.',
   'Unit-1 of the paper business of Bangladesh''s Bashundhara Group, a large local maker of printing/writing papers and tissue.'),  -- Bashundhara Unit-1
  ('843a03f7-f4e5-4925-aece-fa6132acfd6f'::uuid,
   '태국 Advance Agro(현 Double A 그룹). 자체 조림목 기반으로 Double A 브랜드 사무용지·인쇄용지를 일관 생산.',
   'Advance Agro (now part of Thailand''s Double A group), an integrated maker of Double A-brand office/printing papers from its own plantations.'),  -- Advance Agro
  ('8a99e736-95a1-41da-9d36-09036fb96ebd'::uuid,
   '태국 Double A(제조사 Advance Agro). 조림목 기반 사무용지·인쇄용지를 생산해 전 세계에 수출하는 대표 카피용지 브랜드.',
   'Thailand''s Double A (made by Advance Agro), producing plantation-based office/printing papers exported worldwide; a leading copy-paper brand.'),  -- Double A
  ('17a84a38-1d0f-4883-ac25-2810181228f8'::uuid,
   '일본 Oji Holdings 그룹의 태국 법인 Oji Paper (Thailand). 포장·산업용지 등 그룹 제품을 동남아 시장에 공급.',
   'Oji Paper (Thailand), the Thai arm of Japan''s Oji Holdings group, supplying packaging/industrial papers into Southeast Asia.'),  -- Oji Paper (Thailand) Ltd.
  ('49f234b1-f442-479c-92a0-edadf3c36964'::uuid,
   '태국 SCGP(SCG Packaging) 계열의 Phoenix Pulp & Paper(콘깬 남퐁). 표백 크라프트펄프 등 펄프·제지를 생산.',
   'Phoenix Pulp & Paper (Nam Phong, Khon Kaen), part of Thailand''s SCGP (SCG Packaging), producing pulp and paper incl. bleached kraft pulp.'),  -- Phoenix Pulp & Paper
  ('1604c865-b437-49d2-a304-30fc9baeb512'::uuid,
   '태국 SCG 그룹의 포장 자회사 SCGP. 아세안 전역에서 섬유기반 포장재·펄프·인쇄용지를 공급하는 역내 최대급 포장기업.',
   'SCGP, the packaging arm of Thailand''s SCG group, a leading ASEAN supplier of fiber-based packaging, pulp and printing papers.'),  -- SCG Packaging / packaging chain
  ('6994c74f-dd38-459a-ab9a-60c6eee41fc3'::uuid,
   '태국 SCGP 계열의 Thai Paper. 라차부리·깐짜나부리·콘깬·사뭇사콘 공장에서 유칼립투스 기반 펄프·제지를 생산.',
   'Thai Paper Co., part of Thailand''s SCGP, producing eucalyptus-based pulp and paper at Ratchaburi, Kanchanaburi, Khon Kaen and Samut Sakhon.'),  -- Thai Paper Co., Ltd. (SCG Packaging)
  ('4dd9d110-dddb-4b68-b4dc-fd48f7a4c63c'::uuid,
   '태국의 제지사 Thai Paper Mill Co.(상기 SCG Thai Paper와 별개). 공식 도메인 미확인.',
   'Thai Paper Mill Co. (distinct from the SCG Thai Paper above); no verified official domain.'),  -- Thai Paper Mill Co., Ltd.
  ('51feec41-284a-485f-8b46-1f57735b5d47'::uuid,
   '베트남의 중소 고급지(fine paper) 공장군을 묶은 항목. 단일 회사가 아니라 공식 도메인은 두지 않음.',
   'A grouping of smaller Vietnamese fine-paper mills; not a single company, so no domain is assigned.')  -- Smaller Vietnam fine-paper mills
) as d(party_id, intro_ko, intro_en)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2;

-- verify
select
  count(*) filter (where website ilike 'http%') as with_url,
  count(*) filter (where intro_ko is not null and intro_ko <> '') as with_intro
from app.parties where id in (
  '1a35b462-79e5-44d0-84df-a7dea4ce1d94','08e82ea2-eed9-40ed-b279-a8cacc84dc12','000812ab-3fe9-45ad-9773-07f22d0283d1','a6f46744-3238-4057-a7c9-e62403fe968b','7e7cb097-b8fe-41a9-a0e1-fc810a022cca','31df6baf-98f0-4b8f-89de-7db412312eff','6f7c12be-0182-4ccd-bced-89c8cc41901d','2f403cd1-6e53-48a0-8c1e-3b2c9b3c9844','6939a129-bfa2-4114-be61-529b8e487ec1','46cc9ad2-e14f-43c6-a600-1e623c0256be','4a8427e1-a1c9-4d11-a045-dee92a50840f','e4c573e5-5a7a-4025-bce3-58d8bd79a046','4f416164-129c-40d7-b835-fcfc871e7f8c','6ad04789-209f-4df1-b185-24a50c60717d','4a2112db-b063-42c8-afb0-4126c0c7a38b','de740c5b-323c-4a74-9a4a-7212ec9a7dd9','9f3719af-21fb-4fb5-b5aa-866416b7231f','3f29730f-528e-47a3-bd4c-ac82c5dd2d8d','f1e0a67a-8cf2-41e0-938c-caaec218a5c7','a7721ae3-e761-4b31-a6aa-d7b7610df205','d3d18246-80e7-4f60-9aef-20c22713f75a','3596af41-c22c-420b-b4b4-52f44188afe3','570aaa49-61e9-43b0-a1af-644d4403e36e','da6ee20c-3b4b-4eb5-8fd4-a4c5a7dc0ac6','913b37b7-dd16-4e50-88ec-3831dc5af687','6f1136e6-062d-4fdc-b7e6-738e56af8375','292c1b9b-194a-4aef-952c-29a430d1fc6d','18ecb713-8f25-4201-a594-bf54b97307c4','99a0ef69-a3cf-4be0-b9c3-69f2c842a445','f1e73c29-4f78-4ef6-be27-3146ec7aac00','e61f2e0d-cb46-4a00-9feb-9094b77a2a02','dedc9cf2-b21d-46ed-b57d-15a21aa5a1da','cd2af0b1-a9ff-4251-aafd-4395ae3228b4','843a03f7-f4e5-4925-aece-fa6132acfd6f','8a99e736-95a1-41da-9d36-09036fb96ebd','17a84a38-1d0f-4883-ac25-2810181228f8','49f234b1-f442-479c-92a0-edadf3c36964','1604c865-b437-49d2-a304-30fc9baeb512','6994c74f-dd38-459a-ab9a-60c6eee41fc3','4dd9d110-dddb-4b68-b4dc-fd48f7a4c63c','51feec41-284a-485f-8b46-1f57735b5d47'
);
