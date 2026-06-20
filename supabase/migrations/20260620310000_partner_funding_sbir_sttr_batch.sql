-- ============================================================
-- Partner parties: US SBIR/STTR agencies + commercialization / funding support orgs
-- party_type = partner (6). Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en use dollar-quoting ($ko$...$ko$ / $en$...$en$). intro_en is ASCII-only.
-- entity_code: 'organization' for agencies & nonprofits, 'company' for for-profit consultancy.
-- Verified 2026-06-20: 11 SBIR participating agencies (5 also STTR: DoD/HHS/DOE/NASA/NSF),
-- coordinated by SBA (America's Seed Fund). DoD now uses secondary title "Department of War" (war.gov).
-- No partner_profile satellite table exists -> insert into app.parties only.
-- ============================================================

with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'partner'), 6) as partner_type_id
),
orgs(party_name, entity_code, country_code, region, city, website, intro_ko, intro_en) as (
  values
  -- ---------- SBIR/STTR coordinator ----------
  ('U.S. Small Business Administration (SBIR/STTR - America''s Seed Fund)', 'organization', 'US', 'DC', 'Washington', 'https://www.sbir.gov',
   $ko$SBIR/STTR(America's Seed Fund)를 총괄 조정하는 연방 기관으로, 11개 참여 부처의 비희석성(non-dilutive) R&D 자금 프로그램을 한곳에서 안내한다. mbg가 미국 정부 R&D 자금 트랙에 진입하는 출발점이자 부처별 솔리시테이션을 탐색하는 허브.$ko$,
   $en$The federal agency that coordinates SBIR/STTR (America's Seed Fund), the single front door to non-dilutive R&D funding across 11 participating agencies. It is mbg's entry point into the US federal R&D funding track and the hub for browsing each agency's solicitations.$en$),

  -- ---------- 5 agencies that do BOTH SBIR and STTR ----------
  ('U.S. National Science Foundation (NSF SBIR/STTR)', 'organization', 'US', 'Virginia', 'Alexandria', 'https://seedfund.nsf.gov',
   $ko$전 분야 과학·공학 혁신에 SBIR/STTR(America's Seed Fund at NSF)를 지원하며 1단계 다수가 첫 신청 스타트업에 돌아간다. mbg의 탄산칼슘 충전제·친환경 소재 딥테크 R&D에 가장 폭넓게 적합한 비희석성 자금원.$ko$,
   $en$Funds broad science and engineering innovation through SBIR/STTR (America's Seed Fund at NSF), with most Phase I awards going to first-time applicants. The most broadly applicable non-dilutive source for mbg deep-tech R&D in calcium carbonate filler and sustainable materials.$en$),

  ('U.S. Department of Energy (DOE SBIR/STTR)', 'organization', 'US', 'DC', 'Washington', 'https://science.osti.gov/sbir',
   $ko$에너지·소재·바이오에너지·환경 R&D에 SBIR/STTR을 지원하고 2단계 수혜자에 사업화 지원(TABA)을 제공한다. mbg의 저에너지 충전제 공정·바이오기반 소재와 결이 맞는 자금 트랙.$ko$,
   $en$Funds SBIR/STTR across energy, materials, bioenergy and environmental R&D, with commercialization assistance (TABA) for Phase II awardees. A funding track aligned with mbg low-energy filler processing and bio-based materials.$en$),

  ('U.S. National Aeronautics and Space Administration (NASA SBIR/STTR)', 'organization', 'US', 'DC', 'Washington', 'https://sbir.nasa.gov',
   $ko$항공우주 임무를 위한 첨단소재·제조·센싱 기술에 SBIR/STTR을 지원한다. mbg의 경량·고기능 미네랄 소재 기술이 우주·항공 소재 토픽과 접점을 가질 수 있다.$ko$,
   $en$Funds SBIR/STTR for advanced materials, manufacturing and sensing technologies serving aerospace missions. mbg lightweight high-function mineral materials may map to aerospace materials topics.$en$),

  ('U.S. Department of Health and Human Services (NIH SBIR/STTR)', 'organization', 'US', 'Maryland', 'Bethesda', 'https://sbir.nih.gov',
   $ko$생명과학·바이오소재·헬스 기술에 SBIR/STTR을 지원하는 미국 최대 비희석성 헬스 R&D 자금원. mbg의 해양바이오·생체적합 소재 및 위생용 소비재 라인과 접점.$ko$,
   $en$The largest US non-dilutive health R&D funder, supporting SBIR/STTR in life science, biomaterials and health technologies. Relevant to mbg marine-bio and biocompatible materials and to sanitary consumer product lines.$en$),

  ('U.S. Department of Defense / Department of War (DoD SBIR/STTR)', 'organization', 'US', 'Virginia', 'Arlington', 'https://www.war.gov',
   $ko$연방 SBIR/STTR 예산의 절반 이상을 차지하는 최대 부처로 첨단소재·국방 제조 토픽이 많다(2025년 2차 명칭 'Department of War' 병행, 법적 명칭은 Department of Defense 유지). mbg의 고기능 미네랄 소재가 국방 소재 토픽과 접점 가능.$ko$,
   $en$The largest SBIR/STTR funder (over half the federal budget), with many advanced-materials and defense-manufacturing topics. As of 2025 it also uses the secondary title "Department of War" (legal name remains Department of Defense). mbg high-function mineral materials may match defense materials topics.$en$),

  -- ---------- SBIR-only agencies (highest MBG fit first) ----------
  ('U.S. Department of Agriculture (USDA SBIR - NIFA)', 'organization', 'US', 'DC', 'Washington', 'https://www.nifa.usda.gov',
   $ko$식품·농업·천연자원·바이오기반 제품·양식(aquaculture)·바이오연료 분야에 SBIR을 지원한다(NIFA 운영). mbg의 해양바이오 원료·바이오기반 충전제·친환경 포장 소재에 직접적으로 부합하는 핵심 자금원.$ko$,
   $en$Funds SBIR (administered by NIFA) in food, agriculture, natural resources, bio-based products, aquaculture and biofuels. A core funder directly aligned with mbg marine-bio feedstocks, bio-based filler and sustainable packaging materials.$en$),

  ('U.S. National Oceanic and Atmospheric Administration (NOAA SBIR)', 'organization', 'US', 'Maryland', 'Silver Spring', 'https://techpartnerships.noaa.gov',
   $ko$해양·대기·수산 관련 기술에 SBIR을 지원하는 상무부 산하 기관. mbg의 해양바이오 소재와 가장 직접적으로 관련된 부처 중 하나.$ko$,
   $en$A Commerce Department agency funding SBIR for ocean, atmospheric and fisheries technologies. One of the most directly relevant agencies for mbg marine-bio materials.$en$),

  ('U.S. National Institute of Standards and Technology (NIST SBIR)', 'organization', 'US', 'Maryland', 'Gaithersburg', 'https://www.nist.gov',
   $ko$측정과학·첨단소재·첨단제조 기술에 SBIR을 지원하는 상무부 산하 표준기관. 소재 표준·시험과 제조 확장(MEP)과의 연계가 mbg 충전제·제지 소재 사업화에 유용.$ko$,
   $en$A Commerce Department standards agency funding SBIR in measurement science, advanced materials and advanced manufacturing. Its materials standards/testing and manufacturing scale-up (MEP) links are useful for mbg filler and paper-materials commercialization.$en$),

  ('U.S. Environmental Protection Agency (EPA SBIR)', 'organization', 'US', 'DC', 'Washington', 'https://www.epa.gov/sbir',
   $ko$환경·지속가능성 기술에 SBIR을 지원하는 연방 환경청. mbg의 친환경·미세플라스틱 대체 소재 및 저탄소 공정 서사와 강하게 부합.$ko$,
   $en$The federal environmental agency funding SBIR for environmental and sustainability technologies. A strong fit with the mbg eco-friendly, plastic-replacement and low-carbon process narrative.$en$),

  ('U.S. Department of Homeland Security (DHS SBIR)', 'organization', 'US', 'DC', 'Washington', 'https://www.dhs.gov',
   $ko$국토안보 임무 관련 기술에 SBIR을 지원한다. mbg와의 직접 적합도는 낮으나 소재·센싱 토픽에서 부수적 접점 가능.$ko$,
   $en$Funds SBIR for homeland-security mission technologies. Lower direct fit for mbg, with possible incidental overlap in materials and sensing topics.$en$),

  ('U.S. Department of Transportation (DOT SBIR)', 'organization', 'US', 'DC', 'Washington', 'https://www.transportation.gov',
   $ko$교통 인프라·안전·이동성 기술에 SBIR을 지원한다. mbg와 직접 적합도는 낮음(참고용 등록).$ko$,
   $en$Funds SBIR for transportation infrastructure, safety and mobility technologies. Lower direct fit for mbg (registered for completeness).$en$),

  ('U.S. Department of Education (ED SBIR - IES)', 'organization', 'US', 'DC', 'Washington', 'https://www.ed.gov',
   $ko$교육기술 제품에 SBIR을 지원한다(IES 운영). mbg와 직접 적합도는 낮음(참고용 등록).$ko$,
   $en$Funds SBIR for education-technology products (administered by IES). Lower direct fit for mbg (registered for completeness).$en$),

  -- ---------- Government commercialization / funding support ----------
  ('NIST Manufacturing Extension Partnership (MEP)', 'organization', 'US', 'Maryland', 'Gaithersburg', 'https://www.nist.gov/mep',
   $ko$50개 주 + 푸에르토리코에 센터를 둔 공공-민간 파트너십으로 중소 제조기업의 성장·공정개선·사업화를 지원한다. mbg 충전제·제지 소재의 제조 확장과 미국 내 생산 파트너 연결에 유용.$ko$,
   $en$A public-private partnership with centers in all 50 states and Puerto Rico that helps small and mid-size manufacturers grow, improve processes and commercialize. Useful for mbg manufacturing scale-up of filler/paper materials and for connecting US production partners.$en$),

  ('Manufacturing USA', 'organization', 'US', 'Maryland', 'Gaithersburg', 'https://www.manufacturingusa.com',
   $ko$첨단제조 기술 R&D를 주도하는 연방 후원 연구소 네트워크(다수 institute). 소재·복합재·바이오제조 institute가 mbg 소재 사업화·시범생산과 접점.$ko$,
   $en$A network of federally sponsored institutes leading advanced-manufacturing R&D. Its materials, composites and biomanufacturing institutes connect to mbg materials commercialization and pilot production.$en$),

  ('Federal Laboratory Consortium for Technology Transfer (FLC)', 'organization', 'US', 'DC', 'Washington', 'https://www.federallabs.org',
   $ko$250개 이상의 연방 연구소 기술이전을 연결하는 법정 네트워크(주관 NIST). mbg가 연방 연구소의 소재·공정 기술을 라이선싱·협업으로 활용할 수 있는 창구.$ko$,
   $en$The chartered network (hosted by NIST) linking technology transfer across 250+ federal laboratories. A channel for mbg to license or partner on federal-lab materials and process technologies.$en$),

  ('U.S. Economic Development Administration (EDA)', 'organization', 'US', 'DC', 'Washington', 'https://www.eda.gov',
   $ko$지역 경제개발·혁신 자금을 지원하는 상무부 산하 기관으로 Build to Scale 등 사업화·스케일업 보조금을 운영한다. mbg의 미국 내 생산 거점·지역 파트너 구축에 활용 가능.$ko$,
   $en$A Commerce Department agency funding regional economic development and innovation, including Build to Scale commercialization/scale-up grants. Usable for building mbg US production footprint and regional partners.$en$),

  -- ---------- Private / nonprofit commercialization & funding support ----------
  ('Larta Institute', 'organization', 'US', 'California', 'Los Angeles', 'https://www.larta.org',
   $ko$DOE·NOAA·USDA 등의 SBIR/STTR 사업화 가속(TABA) 위탁 운영기관으로 25년 이상 비희석성 자금·시장진입을 지원해왔다. mbg가 USDA/NOAA/DOE 트랙에 진입할 경우 직접적인 사업화 파트너.$ko$,
   $en$The contracted operator of SBIR/STTR commercialization accelerator (TABA) programs for DOE, NOAA, USDA and others, with 25+ years supporting non-dilutive funding and market entry. A direct commercialization partner if mbg enters the USDA/NOAA/DOE tracks.$en$),

  ('VentureWell', 'organization', 'US', 'Massachusetts', 'Hadley', 'https://venturewell.org',
   $ko$대학·초기 혁신가에 보조금과 가속 프로그램을 제공하는 비영리로, NSF·EDA와 협력하며 해양경제(Ocean Enterprise)·기후테크 가속기를 운영한다. mbg의 해양바이오·친환경 소재 초기 사업화와 강하게 부합.$ko$,
   $en$A nonprofit providing grants and accelerators to academic and early-stage innovators, partnering with NSF and EDA and running ocean-economy and climatetech accelerators. Strong fit for mbg early-stage commercialization in marine-bio and sustainable materials.$en$),

  ('BBC Entrepreneurial Training & Consulting (BBCetc)', 'company', 'US', 'Michigan', 'Ann Arbor', 'https://bbcetc.com',
   $ko$SBIR/STTR 제안서 작성·사업화 계획 수립을 전문으로 하는 컨설팅사. mbg가 연방 R&D 자금 신청 성공률을 높이는 데 활용 가능한 실무 파트너.$ko$,
   $en$A consultancy specializing in SBIR/STTR proposal development and commercialization planning. A hands-on partner mbg can use to raise its federal R&D application success rate.$en$),

  ('Greentown Labs', 'organization', 'US', 'Massachusetts', 'Somerville', 'https://greentownlabs.com',
   $ko$보스턴·휴스턴(텍사스)에 거점을 둔 북미 최대급 기후테크 인큐베이터로 시설·투자자·기업 파트너 네트워크를 제공한다. mbg의 친환경 소재 사업화와 텍사스 거점 확장에 유용.$ko$,
   $en$One of North America's largest climatetech incubators, based in Boston with a Houston, Texas hub, offering facilities and an investor/corporate partner network. Useful for mbg sustainable-materials commercialization and Texas-based expansion.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, intro_ko, intro_en)
select i.org, o.party_name, i.partner_type_id,
       coalesce((select id from app.entity_types et where et.code = o.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       o.country_code, o.region, o.city, o.website, 'manual_partner_funding_2026Q2', o.intro_ko, o.intro_en
from orgs o cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = o.party_name
    and p.organization_id = i.org and p.deleted_at is null
);

-- Verification: inserted/existing funding partners with intro coverage
select p.party_name, p.city, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = coalesce((select id from app.party_types where code = 'partner'), 6)
  and p.source = 'manual_partner_funding_2026Q2'
  and p.deleted_at is null
order by p.party_name;
