-- ============================================================
-- Partner parties (batch 2): US universities with paper pilot / testing facilities (for FCC papermaking trials)
-- party_type = partner (6). Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en dollar-quoted. intro_en ASCII-only. entity_code 'organization'.
-- Verified 2026-06-20 as CURRENTLY operating. (Univ. of Minnesota excluded: no verified current paper pilot/test facility.)
-- Same source tag as batch 1 so both group together. No partner_profile satellite.
-- ============================================================

with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'partner'), 6) as partner_type_id
),
orgs(party_name, entity_code, country_code, region, city, website, intro_ko, intro_en) as (
  values
  ('University of Washington (Wollenberg Paper and Bioresource Science Laboratory - SEFS)', 'organization', 'US', 'Washington', 'Seattle', 'https://sites.uw.edu/pbsc',
   $ko$워싱턴대 환경산림과학대(SEFS) 소속 Wollenberg Paper & Bioresource Science Lab(약 4,000 sq ft 파일럿)로 12인치 N&W 제지기·몰디드펄프·리파이너·wet-end 화학 랩·TAPPI 시험실을 갖추고 기업·스타트업 대상 유료 시험/파일럿($200/hr)을 제공한다. mbg의 FCC를 초지·wet-end에 투입해 물성·보류를 검증하기에 적합.$ko$,
   $en$The Wollenberg Paper and Bioresource Science Laboratory (~4,000 sq ft pilot) in UW's School of Environmental and Forest Sciences, with a 12-inch N&W paper machine, molded-pulp unit, refiner, wet-end chemistry lab and TAPPI testing lab, offering fee-based testing/pilot work (about $200/hr) to companies and startups. A fit for piloting mbg FCC in the furnish/wet end and validating properties and retention.$en$),

  ('Miami University (Chemical, Paper and Biomedical Engineering - Pilot Paper Machine)', 'organization', 'US', 'Ohio', 'Oxford', 'https://miamioh.edu/cec/departments/chemical-paper-biomedical-engineering/',
   $ko$마이애미대(오하이오) 화학·제지·생의공학과(CPB)로 12인치 Fourdrinier 파일럿 제지기·종이 시험실·기업 협업용 Contract Research Lab을 운영한다(과거 10% CaCO3 배합 파일럿 트라이얼 실적). mbg의 FCC 충전제 초지 적용·강도 평가에 직접 적합.$ko$,
   $en$Miami University's (Ohio) Department of Chemical, Paper, and Biomedical Engineering (CPB), running a 12-inch Fourdrinier pilot paper machine, a paper testing lab and a Contract Research Lab for company projects (with a documented history of pilot trials at 10% CaCO3 loading). Directly suited to applying mbg FCC filler in papermaking and evaluating strength.$en$)
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

-- Verification (all paper-testing university partners, both batches)
select p.party_name, p.region, p.city, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = coalesce((select id from app.party_types where code = 'partner'), 6)
  and p.source = 'manual_partner_paper_testing_2026Q2'
  and p.deleted_at is null
order by p.region, p.party_name;
