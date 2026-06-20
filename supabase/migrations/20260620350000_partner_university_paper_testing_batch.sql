-- ============================================================
-- Partner parties: US universities with paper pilot / testing facilities (for FCC filler papermaking trials)
-- party_type = partner (6). Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en dollar-quoted. intro_en is ASCII-only. entity_code 'organization' for all.
-- Verified 2026-06-20: facilities able to run mbg FCC (functional/precipitated CaCO3 filler) in papermaking.
-- No partner_profile satellite -> insert into app.parties only.
-- ============================================================

with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'partner'), 6) as partner_type_id
),
orgs(party_name, entity_code, country_code, region, city, website, intro_ko, intro_en) as (
  values
  ('Western Michigan University (WMU Paper Pilot Plants - Chemical and Paper Engineering)', 'organization', 'US', 'Michigan', 'Kalamazoo', 'https://wmich.edu/pilotplants',
   $ko$미국 4개뿐인 ABET 인증 제지공학 프로그램 중 하나로 24인치 Fourdrinier 파일럿 제지기·고속 코터·재활용 플랜트와 종이 시험 설비를 보유한다. mbg의 FCC 충전제를 초지 공정에 투입해 보류율·회분(ash)·강도·광학특성을 파일럿 규모로 검증할 수 있는 핵심 파트너.$ko$,
   $en$One of only four ABET-accredited paper-engineering programs in the US, with a 24-inch Fourdrinier pilot paper machine, high-speed coater, recycling plant and paper-testing labs. A core partner for piloting mbg FCC filler in the furnish and measuring retention, ash, strength and optical properties.$en$),

  ('University of Maine (Process Development Center - PDC)', 'organization', 'US', 'Maine', 'Orono', 'https://umaine.edu/pdc',
   $ko$40여 년간 펄프·제지 공동연구의 표준이 된 파일럿 플랜트로 파일럿 제지기·코터·6대 리파이너와 회분/기초중량 온라인 모니터링(Honeywell), wet-end 화학 시험 설비를 갖췄다. mbg의 FCC를 wet-end에 투입해 보류·회분·표면 특성을 평가하기에 최적.$ko$,
   $en$A pilot plant that has set the standard for collaborative pulp and paper research for 40+ years, with a pilot paper machine, coater, six pilot refiners, on-line ash/basis-weight monitoring (Honeywell) and wet-end chemistry capability. Ideal for evaluating mbg FCC in the wet end for retention, ash and surface properties.$en$),

  ('North Carolina State University (Department of Forest Biomaterials)', 'organization', 'US', 'North Carolina', 'Raleigh', 'https://cnr.ncsu.edu/forest-biomaterials',
   $ko$50년 이상 미국을 선도해온 제지·바이오소재 학과로 Robertson Pulp & Paper Lab·파일럿 플랜트·분석시험 설비(FBAT)를 보유한다. mbg의 FCC 충전제 초지 적용 및 지력·광학 성능 평가에 적합한 파트너.$ko$,
   $en$A US-leading pulp/paper and biomaterials department for 50+ years, with the Robertson Paper and Pulp Laboratory, pilot plants and analytical/test facilities (FBAT). A fit for applying mbg FCC filler in papermaking and evaluating strength and optical performance.$en$),

  ('Georgia Institute of Technology (Renewable Bioproducts Institute - RBI)', 'organization', 'US', 'Georgia', 'Atlanta', 'https://rbi.gatech.edu',
   $ko$1929년 Institute of Paper Chemistry를 잇는 미국 대표 제지·바이오제품 연구소(IPST 후신)로 제지·포장·티슈 파일럿 설비와 깊은 산학 파트너십을 제공한다. mbg의 FCC 사업화와 고배합 충전 기술 검증에 강력한 파트너.$ko$,
   $en$The leading US paper and bioproducts institute (successor to the 1929 Institute of Paper Chemistry / IPST), offering paper, packaging and tissue pilot capability and deep industry-university partnerships. A powerful partner for validating mbg FCC commercialization and high-loading filler technology.$en$),

  ('University of Wisconsin-Stevens Point (Paper Science and Engineering)', 'organization', 'US', 'Wisconsin', 'Stevens Point', 'https://www.uwsp.edu/programs/degree/paper-science-and-engineering/',
   $ko$위스콘신 유일의 파일럿 제지기 실험실을 운영하는 제지과학공학 프로그램으로 다양한 첨가제·충전제를 넣어 종이 물성을 시험한다. mbg의 FCC 첨가에 따른 종이 물성 변화를 파일럿으로 검증 가능.$ko$,
   $en$A Paper Science and Engineering program operating Wisconsin's only pilot paper-machine laboratory, where additives and fillers are run to test paper properties. Can pilot how adding mbg FCC changes paper properties.$en$),

  ('SUNY College of Environmental Science and Forestry (ESF - Paper Engineering)', 'organization', 'US', 'New York', 'Syracuse', 'https://www.esf.edu',
   $ko$시러큐스 소재 환경과학산림대학(SUNY ESF)의 제지공학 프로그램(미국 최상위권)으로 펄프·제지 파일럿 및 시험 역량을 갖췄다. mbg의 FCC 초지 적용 평가에 적합.$ko$,
   $en$The Paper Engineering program at the SUNY College of Environmental Science and Forestry in Syracuse (top-ranked in the US), with pulp/paper pilot and testing capability. A fit for evaluating mbg FCC in papermaking.$en$),

  ('Auburn University (Alabama Center for Paper and Bioresource Engineering - AC-PABE)', 'organization', 'US', 'Alabama', 'Auburn', 'https://eng.auburn.edu/research/centers/ac-pabe/',
   $ko$1985년 설립 미국 유일의 펄프·제지·바이오자원 공학 센터로 펄프·종이·바이오매스의 화학·물리 평가를 위한 완비된 controlled-condition wet-test 실험실과 시험 서비스센터를 운영한다. mbg의 FCC wet-end 거동·종이 물성 시험에 적합.$ko$,
   $en$The nation's only pulp, paper and bioresource engineering center (founded 1985), running a complete controlled-condition wet-test laboratory and a testing service center for chemical/physical evaluation of pulp, paper and biomass. A fit for testing mbg FCC wet-end behavior and paper properties.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, intro_ko, intro_en)
select i.org, o.party_name, i.partner_type_id,
       coalesce((select id from app.entity_types et where et.code = o.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       o.country_code, o.region, o.city, o.website, 'manual_partner_paper_testing_2026Q2', o.intro_ko, o.intro_en
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
  and p.source = 'manual_partner_paper_testing_2026Q2'
  and p.deleted_at is null
order by p.region, p.party_name;
