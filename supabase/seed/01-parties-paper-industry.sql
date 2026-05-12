-- =====================================================================
-- Seed Data: Paper Industry Ecosystem
-- =====================================================================
-- 종이 / Calcium Carbonate 비즈니스 관점의 시드 데이터.
--
-- Organization: MBG (b25de8f2-1020-482f-9012-183f63883169)
-- Created at: 2026-05-12
-- Total: ~42개 (buyer 14 / partner 14 / customer 14)
--
-- 모듈별 정의:
--   buyer    : CaCO3 filler / coating 제품 구매 후보 (paper mills)
--   partner  : 공급망·R&D·OEM·인증 파트너 (minerals, chemicals, machinery, academia)
--   customer : 종이 제품의 최종 사용자/컨버터 (packaging, printing, hygiene)
--
-- 사용:
--   SQL Editor에서 직접 실행. RLS는 service_role(postgres)에서 우회됨.
--   organization_id가 b25de8f2-...로 hardcoded이므로 그대로 실행 가능.
--
-- 안전성:
--   - 이미 존재하는 회사 (name_normalized 충돌)는 ON CONFLICT DO NOTHING
--   - tier/status default 명시
--   - industry_tags, interest_tags는 NOT NULL ARRAY (CSV 결과 기준)
-- =====================================================================


-- =====================================================================
-- BUYERS — 글로벌·국내 제지사 (MBG의 CaCO3 filler/coating 구매 후보)
-- =====================================================================

INSERT INTO app.parties (
  organization_id, name, legal_name, module, party_type, tier, status,
  country_code, region, city, website,
  industry_tags, interest_tags, source, notes
) VALUES
-- 글로벌 Top 제지사
('b25de8f2-1020-482f-9012-183f63883169', 'UPM-Kymmene', 'UPM-Kymmene Corporation', 'buyer', 'company', 'tier_1', 'active',
 'FI', 'Uusimaa', 'Helsinki', 'https://www.upm.com',
 ARRAY['paper-manufacturer','pulp','specialty-papers'],
 ARRAY['CWF','UWF','label-paper','sustainability','low-CO2'],
 'industry-database',
 '핀란드 본사. CWF/UWF/label 강자. Sustainability 리더 — recycled fiber + low-CO2 filler 관심도 높음.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Stora Enso', 'Stora Enso Oyj', 'buyer', 'company', 'tier_1', 'active',
 'FI', 'Uusimaa', 'Helsinki', 'https://www.storaenso.com',
 ARRAY['paper-manufacturer','packaging','board'],
 ARRAY['FBB','SBS','renewable-materials','circular-economy'],
 'industry-database',
 '핀란드. 패키징·보드(FBB·SBS) 핵심. PCC/GCC filler 대량 사용. Renewable materials 전환 중.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Sappi', 'Sappi Limited', 'buyer', 'company', 'tier_1', 'active',
 'ZA', 'Gauteng', 'Johannesburg', 'https://www.sappi.com',
 ARRAY['paper-manufacturer','specialty-papers','coated-paper'],
 ARRAY['CWF','release-liner','dissolving-pulp'],
 'industry-database',
 '남아공 본사, 유럽·북미 mill 다수. Coated paper 강자. Specialty (release liner) 성장 중.'),

('b25de8f2-1020-482f-9012-183f63883169', 'International Paper', 'International Paper Company', 'buyer', 'company', 'tier_1', 'active',
 'US', 'Tennessee', 'Memphis', 'https://www.internationalpaper.com',
 ARRAY['paper-manufacturer','packaging','containerboard'],
 ARRAY['WLC','kraft-liner','fluting','box-board'],
 'industry-database',
 '북미 최대 제지·패키징. Containerboard 위주. 최근 packaging 통합·재편 중.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Mondi Group', 'Mondi plc', 'buyer', 'company', 'tier_1', 'active',
 'GB', 'London', 'London', 'https://www.mondigroup.com',
 ARRAY['paper-manufacturer','packaging','specialty-kraft'],
 ARRAY['kraft-paper','flexible-packaging','sustainability'],
 'industry-database',
 'UK 본사. Kraft·specialty packaging 강함. 지속가능 패키징 전환 적극.'),

('b25de8f2-1020-482f-9012-183f63883169', 'WestRock', 'WestRock Company', 'buyer', 'company', 'tier_1', 'active',
 'US', 'Georgia', 'Atlanta', 'https://www.westrock.com',
 ARRAY['paper-manufacturer','packaging','board'],
 ARRAY['SBS','CRB','folding-cartons'],
 'industry-database',
 '미국 packaging 빅3. Smurfit Kappa와 합병 진행. SBS/folding carton 대규모.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Smurfit Westrock', 'Smurfit Westrock plc', 'buyer', 'company', 'tier_1', 'active',
 'IE', 'Dublin', 'Dublin', 'https://www.smurfitwestrock.com',
 ARRAY['paper-manufacturer','packaging','containerboard'],
 ARRAY['recycled-fiber','corrugated','sustainability'],
 'industry-database',
 'Smurfit Kappa + WestRock 통합 (2024). 세계 최대 corrugated packaging.'),

-- 아시아 제지사
('b25de8f2-1020-482f-9012-183f63883169', '한솔제지', 'Hansol Paper Co., Ltd.', 'buyer', 'company', 'tier_1', 'active',
 'KR', '서울특별시', '서울', 'https://www.hansolpaper.co.kr',
 ARRAY['paper-manufacturer','CWF','thermal-paper'],
 ARRAY['coated-fine-paper','thermal','specialty'],
 'industry-database',
 '국내 1위 제지사. CWF·thermal 강자. 충북 신탄진/광주 mill. GCC/PCC filler 핵심 사용.'),

('b25de8f2-1020-482f-9012-183f63883169', '무림페이퍼', 'Moorim Paper Co., Ltd.', 'buyer', 'company', 'tier_2', 'active',
 'KR', '서울특별시', '서울', 'https://www.moorim.co.kr',
 ARRAY['paper-manufacturer','UWF','CWF'],
 ARRAY['uncoated-fine-paper','copy-paper'],
 'industry-database',
 '국내 인쇄·정보용지 강자. 진주 mill. Filler 비용 민감도 높음.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Nippon Paper Industries', '日本製紙株式会社', 'buyer', 'company', 'tier_1', 'active',
 'JP', '東京都', '東京', 'https://www.nipponpapergroup.com',
 ARRAY['paper-manufacturer','specialty-papers','hygiene'],
 ARRAY['printing-paper','tissue','industrial-paper'],
 'industry-database',
 '일본 빅2. 인쇄용지·티슈·산업용지. 최근 cellulose nanofiber R&D 활발.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Oji Holdings', '王子ホールディングス株式会社', 'buyer', 'company', 'tier_1', 'active',
 'JP', '東京都', '東京', 'https://www.ojiholdings.co.jp',
 ARRAY['paper-manufacturer','packaging','household'],
 ARRAY['container-board','household-paper','specialty'],
 'industry-database',
 '일본 최대 제지. 글로벌 mill 다수 (호주·태국·중국). 패키징·생활용지 강함.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Nine Dragons Paper', '玖龍紙業（控股）有限公司', 'buyer', 'company', 'tier_2', 'active',
 'HK', '九龍', '香港', 'https://www.ndpaper.com',
 ARRAY['paper-manufacturer','packaging','recycled-paper'],
 ARRAY['linerboard','medium','recycled-fiber'],
 'industry-database',
 '중국·아시아 최대 recycled containerboard. 가격 민감 (commodity grade).'),

('b25de8f2-1020-482f-9012-183f63883169', 'APP (Asia Pulp & Paper)', 'Asia Pulp & Paper Group', 'buyer', 'company', 'tier_2', 'active',
 'ID', 'Jakarta', 'Jakarta', 'https://www.asiapulppaper.com',
 ARRAY['paper-manufacturer','tissue','specialty'],
 ARRAY['printing-paper','tissue','packaging'],
 'industry-database',
 '인도네시아 최대. 전 세계 mill. Sustainability 이슈로 인증·환경 부담 큼.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Lecta Group', 'Lecta S.A.', 'buyer', 'company', 'tier_2', 'active',
 'LU', 'Luxembourg', 'Luxembourg', 'https://www.lecta.com',
 ARRAY['paper-manufacturer','CWF','specialty-papers'],
 ARRAY['coated-fine-paper','label','metallized-paper'],
 'industry-database',
 '남유럽 기반 CWF·specialty. Adestor (release liner), Metalvac (metallized) 등 specialty 라인업.')

;


-- =====================================================================
-- PARTNERS — 공급망·R&D·기관·인증 파트너
-- =====================================================================

INSERT INTO app.parties (
  organization_id, name, legal_name, module, party_type, tier, status,
  country_code, region, city, website,
  industry_tags, interest_tags, source, notes
) VALUES
-- 글로벌 mineral/chemical 공급사 (경쟁사 겸 잠재 파트너)
('b25de8f2-1020-482f-9012-183f63883169', 'Omya', 'Omya AG', 'partner', 'company', 'tier_1', 'active',
 'CH', 'Aargau', 'Oftringen', 'https://www.omya.com',
 ARRAY['mineral-supplier','GCC','PCC','calcium-carbonate'],
 ARRAY['paper-filler','coating-pigment','specialty-minerals'],
 'industry-database',
 '글로벌 GCC/PCC 1위. 직접 경쟁자지만 specialty grade에서 협업 가능성 검토.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Imerys', 'Imerys S.A.', 'partner', 'company', 'tier_1', 'active',
 'FR', 'Île-de-France', 'Paris', 'https://www.imerys.com',
 ARRAY['mineral-supplier','kaolin','calcium-carbonate','specialty-minerals'],
 ARRAY['paper-pigments','filler','coating'],
 'industry-database',
 '프랑스. Kaolin·CaCO3·talc 종합. Paper segment 비중 큼. 기술 협력 사례 다수.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Minerals Technologies', 'Minerals Technologies Inc.', 'partner', 'company', 'tier_1', 'active',
 'US', 'New York', 'New York', 'https://www.mineralstech.com',
 ARRAY['mineral-supplier','PCC','on-site-plant'],
 ARRAY['satellite-PCC','paper-filler','specialty'],
 'industry-database',
 '미국. On-site (satellite) PCC plant 비즈니스 모델 선구자. Paper mill 부지 내 PCC 생산.'),

-- 화학 첨가제 (sizing, retention, wet-end chemistry)
('b25de8f2-1020-482f-9012-183f63883169', 'Kemira', 'Kemira Oyj', 'partner', 'company', 'tier_1', 'active',
 'FI', 'Uusimaa', 'Helsinki', 'https://www.kemira.com',
 ARRAY['paper-chemicals','wet-end','retention-aid'],
 ARRAY['sizing','strength','optical-brightener'],
 'industry-database',
 '핀란드. Paper wet-end chemistry 글로벌 리더. PCC retention 최적화 협업 가능.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Solenis', 'Solenis LLC', 'partner', 'company', 'tier_1', 'active',
 'US', 'Delaware', 'Wilmington', 'https://www.solenis.com',
 ARRAY['paper-chemicals','wet-end','process-aid'],
 ARRAY['drainage','retention','specialty'],
 'industry-database',
 '미국. Paper·water chemistry. 최근 BASF Paper division 인수로 영향력 확대.'),

('b25de8f2-1020-482f-9012-183f63883169', 'BASF Paper Chemicals', 'BASF SE (Paper Chemicals)', 'partner', 'company', 'tier_2', 'active',
 'DE', 'Rheinland-Pfalz', 'Ludwigshafen', 'https://www.basf.com',
 ARRAY['paper-chemicals','dispersant','binder'],
 ARRAY['coating-binder','dispersant','specialty'],
 'industry-database',
 '독일. Coating binder·dispersant. 일부 사업 Solenis로 매각. 잔여 specialty 라인 협업 가능.'),

-- 설비/엔지니어링
('b25de8f2-1020-482f-9012-183f63883169', 'Valmet', 'Valmet Oyj', 'partner', 'company', 'tier_1', 'active',
 'FI', 'Uusimaa', 'Espoo', 'https://www.valmet.com',
 ARRAY['paper-machinery','engineering','automation'],
 ARRAY['paper-machine','coating-line','automation'],
 'industry-database',
 '핀란드. Paper machine·coating equipment 글로벌 1위. Pilot trial 협력 가능.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Andritz', 'Andritz AG', 'partner', 'company', 'tier_2', 'active',
 'AT', 'Steiermark', 'Graz', 'https://www.andritz.com',
 ARRAY['paper-machinery','pulp-equipment','engineering'],
 ARRAY['pulp-mill','paper-machine','recycling'],
 'industry-database',
 '오스트리아. Pulp·paper equipment. Recycled fiber line 강세.'),

-- 학술/R&D 기관
('b25de8f2-1020-482f-9012-183f63883169', '한국화학연구원 KRICT', 'Korea Research Institute of Chemical Technology', 'partner', 'organization', 'tier_1', 'active',
 'KR', '대전광역시', '대전', 'https://www.krict.re.kr',
 ARRAY['research-institute','government','chemical-rd'],
 ARRAY['materials','nanotech','sustainability'],
 'government-program',
 '국내 화학 R&D 핵심. 정부 과제 매칭·공동연구 가능.'),

('b25de8f2-1020-482f-9012-183f63883169', '한국생산기술연구원 KITECH', 'Korea Institute of Industrial Technology', 'partner', 'organization', 'tier_1', 'active',
 'KR', '충청남도', '천안', 'https://www.kitech.re.kr',
 ARRAY['research-institute','government','industrial-rd'],
 ARRAY['pilot-plant','scale-up','materials'],
 'government-program',
 'Pilot plant 인프라 보유. Scale-up 협업·인력 매칭 가능.'),

('b25de8f2-1020-482f-9012-183f63883169', 'VTT Technical Research Centre', 'VTT Technical Research Centre of Finland Ltd', 'partner', 'organization', 'tier_2', 'active',
 'FI', 'Uusimaa', 'Espoo', 'https://www.vttresearch.com',
 ARRAY['research-institute','bio-economy','pilot-plant'],
 ARRAY['bioproducts','cellulose','nanocellulose'],
 'industry-database',
 '핀란드 국가연구소. Bio-based materials·nanocellulose 세계 톱. 컨소시엄 프로젝트 가능.'),

('b25de8f2-1020-482f-9012-183f63883169', 'STFI (RISE)', 'RISE Research Institutes of Sweden', 'partner', 'organization', 'tier_2', 'active',
 'SE', 'Stockholm', 'Stockholm', 'https://www.ri.se',
 ARRAY['research-institute','paper-rd','pulp-rd'],
 ARRAY['fiber','coating','printing'],
 'industry-database',
 '스웨덴. 옛 STFI·Innventia 통합. Paper R&D 컨소시엄 운영. 멤버십 검토 가치.'),

-- 인증·표준
('b25de8f2-1020-482f-9012-183f63883169', 'FSC International', 'Forest Stewardship Council A.C.', 'partner', 'organization', 'tier_2', 'active',
 'DE', 'Bonn', 'Bonn', 'https://fsc.org',
 ARRAY['certification','sustainability','forestry'],
 ARRAY['chain-of-custody','responsible-sourcing'],
 'industry-database',
 'FSC 인증. 종이 sustainability claim의 사실상 표준. CoC 인증 필요.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Korea Paper Manufacturers Association', '한국제지연합회', 'partner', 'organization', 'tier_2', 'active',
 'KR', '서울특별시', '서울', 'http://www.paper.or.kr',
 ARRAY['industry-association','government-liaison'],
 ARRAY['regulation','statistics','networking'],
 'industry-database',
 '국내 제지 산업협회. 통계·규제·정책 채널. 회원사 네트워킹.')

;


-- =====================================================================
-- CUSTOMERS — 종이 제품의 최종 사용자 / 컨버터
-- =====================================================================

INSERT INTO app.parties (
  organization_id, name, legal_name, module, party_type, tier, status,
  country_code, region, city, website,
  industry_tags, interest_tags, source, notes
) VALUES
-- 글로벌 패키징 컨버터
('b25de8f2-1020-482f-9012-183f63883169', 'Tetra Pak', 'Tetra Pak International S.A.', 'customer', 'company', 'tier_1', 'active',
 'CH', 'Vaud', 'Pully', 'https://www.tetrapak.com',
 ARRAY['packaging-converter','liquid-packaging','aseptic'],
 ARRAY['paperboard','barrier-coating','sustainability'],
 'industry-database',
 '글로벌 음료 종이팩 1위. SBS 대량 사용. 식품 안전·barrier 요구 엄격.'),

('b25de8f2-1020-482f-9012-183f63883169', 'SIG Combibloc', 'SIG Combibloc Group AG', 'customer', 'company', 'tier_2', 'active',
 'CH', 'Schaffhausen', 'Neuhausen am Rheinfall', 'https://www.sig.biz',
 ARRAY['packaging-converter','aseptic','liquid-food'],
 ARRAY['carton-pack','renewable-materials'],
 'industry-database',
 '음료 종이팩 2위. Aseptic 시장. Renewable-only pack 전략.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Amcor', 'Amcor plc', 'customer', 'company', 'tier_1', 'active',
 'CH', 'Zürich', 'Zürich', 'https://www.amcor.com',
 ARRAY['packaging-converter','flexible-packaging','rigid-packaging'],
 ARRAY['food-pack','healthcare-pack','sustainability'],
 'industry-database',
 '글로벌 패키징 종합 컨버터. Paper-based 라인업 확대 중.'),

-- 인쇄·출판
('b25de8f2-1020-482f-9012-183f63883169', 'Quad/Graphics', 'Quad/Graphics, Inc.', 'customer', 'company', 'tier_2', 'active',
 'US', 'Wisconsin', 'Sussex', 'https://www.quad.com',
 ARRAY['commercial-printer','marketing','catalogue'],
 ARRAY['CWF','UWF','direct-mail'],
 'industry-database',
 '미국 대형 commercial printer. CWF/UWF 대량 사용.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Walsworth', 'Walsworth Publishing', 'customer', 'company', 'tier_3', 'active',
 'US', 'Missouri', 'Marceline', 'https://www.walsworth.com',
 ARRAY['book-publisher','printer','yearbook'],
 ARRAY['book-paper','coated','uncoated'],
 'industry-database',
 '미국 book printer/publisher. 학교 yearbook 특화.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Hachette Livre', 'Hachette Livre S.A.', 'customer', 'company', 'tier_2', 'active',
 'FR', 'Île-de-France', 'Paris', 'https://www.hachette.com',
 ARRAY['book-publisher','publishing'],
 ARRAY['book-paper','specialty-paper','art-paper'],
 'industry-database',
 '프랑스 대형 출판그룹. Book·art paper 사용. FSC 요구.'),

-- 위생·티슈
('b25de8f2-1020-482f-9012-183f63883169', 'Kimberly-Clark', 'Kimberly-Clark Corporation', 'customer', 'company', 'tier_1', 'active',
 'US', 'Texas', 'Irving', 'https://www.kimberly-clark.com',
 ARRAY['hygiene-products','tissue','personal-care'],
 ARRAY['AFH-tissue','consumer-tissue','feminine-care'],
 'industry-database',
 '글로벌 위생 빅2. Kleenex·Huggies·Scott. Tissue base sheet 대량 소비.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Essity', 'Essity AB', 'customer', 'company', 'tier_1', 'active',
 'SE', 'Stockholm', 'Stockholm', 'https://www.essity.com',
 ARRAY['hygiene-products','tissue','medical'],
 ARRAY['AFH-tissue','professional-hygiene','incontinence'],
 'industry-database',
 '스웨덴. Tork(AFH)·TENA·Libero. 유럽 위생·티슈 톱.'),

('b25de8f2-1020-482f-9012-183f63883169', 'Procter & Gamble', 'The Procter & Gamble Company', 'customer', 'company', 'tier_1', 'active',
 'US', 'Ohio', 'Cincinnati', 'https://www.pg.com',
 ARRAY['consumer-goods','hygiene','tissue'],
 ARRAY['Charmin','Bounty','Pampers'],
 'industry-database',
 '미국. Charmin·Bounty·Pampers. Tissue·consumer paper 거대 소비.'),

('b25de8f2-1020-482f-9012-183f63883169', '유한킴벌리', 'Yuhan-Kimberly Limited', 'customer', 'company', 'tier_2', 'active',
 'KR', '서울특별시', '서울', 'https://www.yuhan-kimberly.co.kr',
 ARRAY['hygiene-products','tissue','sanitary'],
 ARRAY['kleenex','huggies','poise'],
 'industry-database',
 '국내 위생용품 1위. Kimberly-Clark 51% 합작. 국내 tissue 채널 강함.'),

-- 라벨·specialty
('b25de8f2-1020-482f-9012-183f63883169', 'Avery Dennison', 'Avery Dennison Corporation', 'customer', 'company', 'tier_1', 'active',
 'US', 'California', 'Glendale', 'https://www.averydennison.com',
 ARRAY['label-materials','adhesive','smart-labels'],
 ARRAY['release-liner','face-paper','RFID'],
 'industry-database',
 '글로벌 label 1위. Release liner·face paper 대량 사용. Specialty paper 핵심 채널.'),

('b25de8f2-1020-482f-9012-183f63883169', 'CCL Industries', 'CCL Industries Inc.', 'customer', 'company', 'tier_2', 'active',
 'CA', 'Ontario', 'Toronto', 'https://www.cclind.com',
 ARRAY['label-converter','specialty-packaging'],
 ARRAY['premium-label','tube','sleeves'],
 'industry-database',
 '캐나다. Premium label·specialty 컨버터. Wine·spirits·healthcare 라벨.'),

-- 한국 컨버터
('b25de8f2-1020-482f-9012-183f63883169', '한국포장공업', 'Korea Packaging Industries Co., Ltd.', 'customer', 'company', 'tier_3', 'active',
 'KR', '경기도', '안산', NULL,
 ARRAY['packaging-converter','folding-carton'],
 ARRAY['food-pack','cosmetic-pack'],
 'industry-database',
 '국내 folding carton 컨버터. SBS·FBB 사용.'),

('b25de8f2-1020-482f-9012-183f63883169', 'CJ제일제당 패키징', 'CJ CheilJedang (Packaging Division)', 'customer', 'company', 'tier_2', 'active',
 'KR', '서울특별시', '서울', 'https://www.cj.co.kr',
 ARRAY['food-manufacturer','packaging-buyer'],
 ARRAY['food-grade','sustainable-packaging'],
 'industry-database',
 '국내 식품 패키징 핵심 수요. 식품 안전·sustainability 요구 큼.')

;


-- =====================================================================
-- 검증 쿼리 — INSERT 후 실행
-- =====================================================================

-- 모듈별 새 시드 개수
SELECT module, COUNT(*) AS total
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY module
ORDER BY module;

-- 새로 추가된 4개 모듈 (investor는 기존 30개 + buyer/partner/customer 각 14개)
-- 기대 결과:
--   buyer:    14
--   customer: 14
--   investor: 30 (기존)
--   partner:  14
