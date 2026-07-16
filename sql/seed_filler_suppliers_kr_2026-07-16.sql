-- ============================================================
-- seed_filler_suppliers_kr_2026-07-16.sql
-- GAP FIX: South Korea (KR) filler suppliers were entirely absent from
-- app.parties where party_type_id = 3. The repo has KR paper mills
-- (Hansol, Moorim, Yuhan-Kimberly) but zero KR filler suppliers.
--
-- Adds the 4 KR CaCO3 producers that matter for the FCC royalty push:
--   1. Omya Korea Inc.          - Omya KR subsidiary, 5 plants, 1.2M t+
--   2. Taekyung Industry Co.    - KOSPI, GCC slurry paper-materials division
--   3. Taekyung BK Co., Ltd.    - KOSPI, PCC + on-site plant at Hansol Janghang
--   4. GMC Co., Ltd. (Korea)    - SME, Samcheok mine + Jincheon/Ulsan GCC
--
-- Source tag: filler_gap_kr_2026Q3. paper_mill = 2, filler_supplier = 3.
-- IDEMPOTENT: NOT EXISTS on lower(party_name) + party_type_id = 3 + live.
-- No BEGIN / no DO blocks / no semicolons inside strings (SQL Editor parser).
-- Evidence rule: merchant -> C, satellite -> B.
-- ============================================================

-- ---------- 1) PARTIES ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select v.* from (values
  (3::smallint,1::smallint,'Omya Korea Inc.','KR','서울특별시','서울','https://www.omya.com/kr-ko','active','filler_gap_kr_2026Q3',
   'Korean subsidiary of Omya (CH), operating since 1990. HQ in Mapo-gu, Seoul. Five plants at Gunsan, Andong, Hambaek, Onsan and Jecheon - 3 dry and 2 slurry calcium carbonate lines with combined capacity above 1.2 million tons, supported by 5 owned mines. Largest paper-filler CaCO3 supplier in Korea and the No.1 FCC licensing target in this market. Source: omya.com KR pages, 2026-07.',
   'b25de8f2-1020-482f-9012-183f63883169'::uuid),

  (3::smallint,1::smallint,'Taekyung Industry Co., Ltd.','KR','서울특별시','서울','http://www.taekyung.co.kr','active','filler_gap_kr_2026Q3',
   'KOSPI-listed flagship of Taekyung Group (founded 1982-02-15). Ferroalloy is the main business, with a paper-materials division producing GCC and PCC. Supplies ultra-fine wet GCC slurries (TK-45F/50F60, TK-65F/75F60, OTM-55C) as filler and coating pigment to art paper, white board, newsprint and containerboard mills, and runs 3 regional sites for backup supply. Chairman Kim Hae-ryun. Source: taekyung.co.kr business pages + 2023 annual filing, 2026-07.',
   'b25de8f2-1020-482f-9012-183f63883169'::uuid),

  (3::smallint,1::smallint,'Taekyung BK Co., Ltd.','KR','충청북도','단양','http://www.taekyungbk.co.kr','active','filler_gap_kr_2026Q3',
   'KOSPI-listed Taekyung Group affiliate, formerly Baekkwang Mineral Products (renamed 2021). Korea largest lime producer at roughly 1.28 million t/yr quicklime from Danyang plants 1 and 2, plus PCC. Built a 50 kt/yr PCC plant at Danyang in 2002 and absorbed Korea Fimatec (a Sumitomo Osaka Cement and Fimatec joint venture) on 2000-07-01, adding ultra-fine GCC for paper and paint pigment. Operates an on-site PCC plant at the Hansol Paper Janghang mill. Owns the Yeongcheon, Baekkwang, Hwaam, Samyuk and Bangnim limestone mines. Highest-value FCC target in KR because it already runs the satellite model. Source: taekyungbk.co.kr + group annual filing, 2026-07.',
   'b25de8f2-1020-482f-9012-183f63883169'::uuid),

  (3::smallint,1::smallint,'GMC Co., Ltd. (Korea)','KR',NULL,NULL,NULL,'active','filler_gap_kr_2026Q3',
   'Korean name 지엠씨. Founded 2007, CEO Lee Sang-hoon. Limestone mining plus GCC manufacture for the paper industry. Samcheok site holds the limestone reserve, with paper-grade GCC plants at Jincheon and Ulsan supplying ultra-fine calcium carbonate slurry. Annual revenue roughly KRW 26 billion (KBIZ, 2022). Korean SME - smallest of the 4 KR targets but a pure-play paper GCC producer. English legal name and website need verification. Source: KBIZ release, 2026-07.',
   'b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
where not exists (
  select 1 from app.parties p
  where lower(p.party_name) = lower(v.party_name)
    and p.party_type_id = 3
    and p.deleted_at is null
);

-- ---------- 2) BILINGUAL INTROS (intro_en is ASCII-only) ----------
update app.parties p
set intro_ko = d.ko, intro_en = d.en, updated_at = now()
from (values
  ('Omya Korea Inc.',
   '스위스 Omya의 한국 법인으로 1990년부터 가동 중이며, 군산·안동·함백·온산·제천 5개 공장(건식 3, 슬러리 2)에서 연 120만 톤 이상의 탄산칼슘을 생산한다. 자체 광산 5곳을 보유한 국내 최대 제지용 필러 공급사로, FCC 로열티 라이선싱의 한국 시장 1순위 타깃이다.',
   'Korean arm of Omya of Switzerland, running since 1990 with five plants at Gunsan, Andong, Hambaek, Onsan and Jecheon - three dry and two slurry lines above 1.2 million tons of calcium carbonate a year, backed by five owned mines. The largest paper-filler supplier in Korea and the top FCC royalty licensing target in this market.'),

  ('Taekyung Industry Co., Ltd.',
   '태경그룹 주력사(KOSPI 상장, 1982년 설립)로 합금철과 함께 제지소재 사업부에서 GCC·PCC를 생산한다. 아트지·백판지·신문용지·골판지용 초미립 중탄 슬러리(TK-45F/50F60 등)를 메이저 제지사에 공급하며, 펄프 사용을 줄이는 고충진 슬러리를 자체 개발해 왔다는 점에서 FCC 가치 제안과 결이 정확히 맞는다.',
   'KOSPI-listed flagship of Taekyung Group (founded 1982). Ferroalloy plus a paper-materials division making GCC and PCC. Supplies ultra-fine wet GCC slurries such as TK-45F/50F60 as filler and coating pigment to major art paper, white board, newsprint and containerboard mills. It already markets high-fill slurries aimed at cutting pulp use, which lines up directly with the FCC value proposition.'),

  ('Taekyung BK Co., Ltd.',
   '구 백광소재(2021년 사명 변경, KOSPI 상장). 단양 1·2공장에서 연 128만 톤 규모의 생석회를 생산하는 국내 최대 석회 기업이며 경질탄산칼슘(PCC)도 만든다. 2000년 한국화이마테크(스미토모오사카시멘트·Fimatec 합작사)를 흡수합병해 제지·페인트용 초미립 중탄 라인을 확보했고, 한솔제지 장항공장에 On-Site PCC 플랜트를 운영한다. 이미 satellite 모델을 실행 중이라는 점에서 한국 내 FCC 라이선싱 적합도가 가장 높다.',
   'Formerly Baekkwang Mineral Products, renamed 2021, KOSPI-listed Taekyung Group affiliate. Korea largest lime producer at about 1.28 million t/yr of quicklime from its two Danyang plants, and a PCC maker. It absorbed Korea Fimatec, a Sumitomo Osaka Cement and Fimatec joint venture, in 2000, gaining an ultra-fine GCC line for paper and paint, and runs an on-site PCC plant at the Hansol Paper Janghang mill. Because it already operates the satellite model, it is the strongest FCC licensing fit in Korea.'),

  ('GMC Co., Ltd. (Korea)',
   '2007년 설립된 제지용 GCC 전문 중소기업으로, 삼척 석회석 광산과 진천·울산 두 곳의 GCC 공장에서 초정밀 탄산칼슘 슬러리를 공급한다. 연매출 약 260억 원(2022년 기준) 규모로 4개 타깃 중 가장 작지만, 제지용 GCC 순수 사업자라 의사결정이 빠르고 파일럿 파트너로 적합할 수 있다.',
   'A Korean SME founded in 2007 focused on paper-grade GCC. It holds a limestone reserve at Samcheok and runs GCC plants at Jincheon and Ulsan supplying ultra-fine calcium carbonate slurry. Revenue is roughly KRW 26 billion as of 2022 - the smallest of the four Korean targets, but a pure-play paper GCC producer, which can mean faster decisions and a good pilot partner profile.')
) as d(name, ko, en)
where p.party_name = d.name
  and p.party_type_id = 3
  and p.deleted_at is null
  and p.intro_ko is null;

-- ---------- 3) FILLER SUPPLIER PROFILES ----------
insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GCC/PCC producer',
  'Korea GCC/PCC merchant leader (Omya subsidiary)', 'merchant', 'C',
  'CaCO3 (GCC/PCC)', 'industry-research',
  'Five KR plants, 1.2M t+ combined capacity, 5 owned mines. Parent Omya is already tracked at group level.',
  '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Omya Korea Inc.' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GCC/PCC producer',
  'KR merchant GCC slurry supplier to major paper mills', 'merchant', 'C',
  'CaCO3 (GCC/PCC)', 'industry-research',
  'Paper-materials division of Taekyung Group. Markets high-fill GCC slurries positioned on pulp reduction - direct thematic overlap with FCC.',
  '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Taekyung Industry Co., Ltd.' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PCC/GCC producer',
  'KR lime leader running an on-site PCC satellite', 'satellite', 'B',
  'On-site PCC plant supplied to the Hansol Paper Janghang mill, disclosed in the company annual filing. Danyang PCC plant since 2002 at 50 kt/yr.',
  'CaCO3 (PCC/GCC)', 'industry-research',
  'Formerly Baekkwang Mineral Products. Absorbed Korea Fimatec in 2000 for ultra-fine GCC. Already operates the satellite model, so the FCC licensing conversation starts one step ahead.',
  '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Taekyung BK Co., Ltd.' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GCC producer',
  'KR pure-play paper GCC SME', 'merchant', 'C',
  'CaCO3 (GCC)', 'industry-research',
  'Samcheok limestone reserve, GCC plants at Jincheon and Ulsan. Revenue about KRW 26bn (2022). Small enough to move fast - candidate pilot partner.',
  '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'GMC Co., Ltd. (Korea)' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 4) VERIFY (run separately) ----------
-- select p.party_name, p.country_code, p.city, fp.supply_model, fp.evidence_level,
--        (p.intro_ko is not null) as has_ko, (p.intro_en is not null) as has_en
-- from app.parties p
-- left join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.source = 'filler_gap_kr_2026Q3' and p.party_type_id = 3 and p.deleted_at is null
-- order by p.party_name;
-- expect 4 rows, all country_code = KR, 1 satellite/B + 3 merchant/C

-- select count(*) from app.parties
-- where party_type_id = 3 and country_code = 'KR' and deleted_at is null;
-- expect 4 (was 0)

-- ---------- 5) ROLLBACK ----------
-- delete from app.filler_supplier_profile fp
-- using app.parties p
-- where fp.party_id = p.id and p.source = 'filler_gap_kr_2026Q3' and p.party_type_id = 3;
-- delete from app.parties where source = 'filler_gap_kr_2026Q3' and party_type_id = 3;
