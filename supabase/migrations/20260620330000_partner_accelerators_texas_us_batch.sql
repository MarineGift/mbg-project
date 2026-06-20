-- ============================================================
-- Partner parties: Texas + US startup accelerator / incubator support organizations
-- party_type = partner (6). Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en dollar-quoted ($ko$.../$en$...). intro_en is ASCII-only.
-- entity_code 'organization' for all (university units / nonprofits / accelerator networks).
-- Verified 2026-06-20. No partner_profile satellite -> insert into app.parties only.
-- ============================================================

with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'partner'), 6) as partner_type_id
),
orgs(party_name, entity_code, country_code, region, city, website, intro_ko, intro_en) as (
  values
  -- ---------- Texas ----------
  ('Austin Technology Incubator (ATI) - UT Austin', 'organization', 'US', 'Texas', 'Austin', 'https://ati.utexas.edu',
   $ko$UT Austin 부설 1989년 설립 미국 최장수 딥테크 인큐베이터로 순환경제·에너지·물·농식품테크 전문 인큐베이터를 운영한다. mbg의 친환경 충전제·순환경제·물 분야 사업화와 오스틴 현지 네트워크에 직접 부합.$ko$,
   $en$The deep-tech incubator of UT Austin (founded 1989, the longest-running US incubator), with specialized Circular Economy, Energy, Water and Food/Agtech tracks. Directly fits mbg sustainable-filler, circular-economy and water commercialization and the Austin local network.$en$),

  ('Texas A&M Engineering Experiment Station Clean Energy Incubator (TEES-CEI)', 'organization', 'US', 'Texas', 'College Station', 'https://tees.tamu.edu/research/facilities/clean-energy-incubator.html',
   $ko$Texas A&M 공학연구청(TEES) 산하 클린에너지 인큐베이터로 클린테크 창업 교육·가속·기술지원과 소재·제조 연구시설(RELLIS) 접근을 제공한다. mbg의 소재·제조 사업화와 텍사스 기반 확장에 적합.$ko$,
   $en$The Clean Energy Incubator of the Texas A&M Engineering Experiment Station (TEES), offering cleantech education, acceleration, technical support and access to materials/manufacturing facilities (RELLIS). Fits mbg materials/manufacturing commercialization and Texas-based scale-up.$en$),

  ('Texas State University Center for Innovation and Entrepreneurship (TXST New Ventures / STAR Park)', 'organization', 'US', 'Texas', 'San Marcos', 'https://innovation.txst.edu',
   $ko$Texas State University 혁신창업센터로 무지분(equity-free) New Ventures 액셀러레이터와 STAR Park 연구단지·소재응용연구센터(MARC)·고속 프로토타이핑 랩을 운영한다. mbg의 소재 시제품화·초기 사업화에 유용.$ko$,
   $en$The Center for Innovation and Entrepreneurship at Texas State University, running an equity-free New Ventures accelerator plus STAR Park, the Materials Application Research Center (MARC) and a rapid-prototyping lab. Useful for mbg materials prototyping and early commercialization.$en$),

  ('UTSA SBDC Technology Commercialization Center (Texas FAST / StartUp Texas SBIR)', 'organization', 'US', 'Texas', 'San Antonio', 'https://tcc.txsbdc.org',
   $ko$UTSA 중소기업개발센터 기술사업화센터로 텍사스 FAST 파트너십과 StartUp Texas SBIR/STTR 액셀러레이터를 운영하며 제안서·예산·사업화 전략을 지원한다. 앞서 입력한 SBIR 연방기관 트랙 진입을 직접 돕는 텍사스 거점.$ko$,
   $en$The Technology Commercialization Center of the UTSA SBDC, operating the Texas FAST Partnership and the StartUp Texas SBIR/STTR accelerator with proposal, budget and commercialization support. A Texas hub that directly supports entering the federal SBIR tracks listed earlier.$en$),

  ('Rice Alliance for Technology and Entrepreneurship', 'organization', 'US', 'Texas', 'Houston', 'https://alliance.rice.edu',
   $ko$Rice University의 기술사업화·창업 이니셔티브로 휴스턴 Ion District에서 에너지·순환경제 스타트업을 가속하고 투자자 네트워크를 연결한다. mbg의 친환경 소재 사업화와 휴스턴 거점 확장에 적합.$ko$,
   $en$Rice University's technology-commercialization and entrepreneurship initiative, accelerating energy and circular-economy startups in Houston's Ion District and connecting investor networks. Fits mbg sustainable-materials commercialization and Houston expansion.$en$),

  -- ---------- US-wide ----------
  ('Activate (Activate Global)', 'organization', 'US', 'California', 'Berkeley', 'https://activate.org',
   $ko$과학자 창업가를 위한 2년 하드테크 펠로십(2015 DOE Cyclotron Road 기반 설립, 휴스턴 포함 5개 거점)으로 제조·화학·에너지·농업 탈탄소 기술을 지원한다. NSF·NIST 등과 협력하는 mbg 딥테크 소재 사업화에 강한 적합.$ko$,
   $en$A two-year hardtech fellowship for entrepreneurial scientists (founded 2015 alongside DOE's Cyclotron Road; five sites including Houston) supporting manufacturing, chemicals, energy and agriculture decarbonization technologies. With NSF/NIST partnerships, a strong fit for mbg deep-tech materials commercialization.$en$),

  ('Techstars', 'organization', 'US', 'Colorado', 'Boulder', 'https://www.techstars.com',
   $ko$전 세계 다수 거점을 둔 글로벌 액셀러레이터 네트워크로 자금·멘토십·투자자 네트워크를 제공한다. mbg의 초기 스케일업·미국 시장 진입 옵션.$ko$,
   $en$A global accelerator network with many locations worldwide, providing funding, mentorship and investor networks. An option for mbg early scale-up and US market entry.$en$),

  ('MassChallenge', 'organization', 'US', 'Massachusetts', 'Boston', 'https://masschallenge.org',
   $ko$무지분(zero-equity) 액셀러레이터로 다양한 산업 챌린지 프로그램과 대기업 파트너 연결을 제공한다. mbg의 무지분 가속·기업 파트너십 옵션.$ko$,
   $en$A zero-equity accelerator offering varied industry challenge programs and corporate-partner connections. An option for mbg equity-free acceleration and corporate partnerships.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, intro_ko, intro_en)
select i.org, o.party_name, i.partner_type_id,
       coalesce((select id from app.entity_types et where et.code = o.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       o.country_code, o.region, o.city, o.website, 'manual_partner_accelerators_2026Q2', o.intro_ko, o.intro_en
from orgs o cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = o.party_name
    and p.organization_id = i.org and p.deleted_at is null
);

-- Verification
select p.party_name, p.region, p.city, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = coalesce((select id from app.party_types where code = 'partner'), 6)
  and p.source = 'manual_partner_accelerators_2026Q2'
  and p.deleted_at is null
order by p.region, p.party_name;
