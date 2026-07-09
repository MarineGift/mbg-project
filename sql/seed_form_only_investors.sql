-- ============================================================
-- seed_form_only_investors.sql
-- Form-only / portal-only investor targets (verified 2026-07-09)
-- for the 100K SAFE round. Sets parties.preferred_contact_method
-- and parties.contact_form_url (migration_027 columns).
--
-- Verified this session (web research 2026-07-09):
--   SWAN Impact Network      portal (Dealum)  swanimpact.org/entrepreneurs
--   Houston Angel Network    web_form         houstonangelnetwork.org/entrepreneurs
--   Baylor Angel Network     portal (Dealum)  baylorangelnetwork.com apply page
--   Third Derivative (RMI)   web_form         third-derivative.org/startup-application
--   NSF SBIR Seed Fund       web_form         seedfund.nsf.gov/project-pitch
--   Techstars                portal           apply.techstars.com
--   SOSV                     web_form         sosv.com/apply
--
-- Key findings baked in below:
--   * NSF SBIR Project Pitch REOPENED 2026-06-02 (NSF 26-510) after the
--     authorization lapse. Phase I up to 305K non-dilutive. Deep-tech focus.
--   * Third Derivative 2026 cohort is hard-tech / low-carbon materials.
--     Optional 100K convertible note. TRL 4+ required.
--   * Baylor Angel Network writes 25K-250K checks - direct fit for a 100K ask.
--   * Houston Angel Network wants 250K-1.5M raises + 100 USD fee - stretch fit.
--
-- Supabase SQL Editor safe: no do-blocks, no semicolons or standalone
-- SQL keywords inside string literals, dollar-quoted intros. Idempotent.
-- ============================================================


-- (1) Insert parties (idempotent)
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id
),
firms(party_name, entity_code, country_code, region, city, website, notes, intro_ko, intro_en) as (
  values
    ('SWAN Impact Network', 'organization', 'US', 'Texas', 'Austin',
     'https://swanimpact.org',
     'Applications via Dealum portal. First review the funding criteria doc on the entrepreneurs page. C-Corp preferred. Quarterly funding cycles.',
     $ko$오스틴 기반 임팩트 엔젤 네트워크(2016 설립, 59건 투자). 환경·헬스·교육 분야의 측정 가능한 임팩트 기업에 투자한다. 지원은 Dealum 포털 경유. mbg의 미세플라스틱 대체·저탄소 충전제 기술은 환경 임팩트 요건에 정면으로 부합하며, 오스틴 로컬이라는 점도 강점.$ko$,
     $en$Austin based impact angel network (founded 2016, 59 investments) backing companies with measurable environmental or health impact. Applications go through a Dealum portal. The mbg microplastic replacing low carbon filler technology squarely fits their environmental impact criteria, and the Austin home base is an added advantage.$en$),
    ('Houston Angel Network', 'organization', 'US', 'Texas', 'Houston',
     'https://www.houstonangelnetwork.org',
     'Application fee 100 USD. Preferred raise 250K to 1.5M - the 100K SAFE is below their floor, consider applying once the round target grows or a lead emerges. Monthly pitch meetings, apply one month ahead.',
     $ko$텍사스 최대·최고(最古) 엔젤 네트워크(2001 설립, 400개사 1억 달러 이상 투자). 에너지·라이프사이언스·소비재·테크 딜커미티 구조. 지원비 100달러, 선호 라운드 규모 25만~150만 달러라서 현재 10만 달러 SAFE는 하한 미달 - 라운드 확대 또는 리드 확보 시점에 지원 권장. 텍사스 소재 요건은 이미 충족.$ko$,
     $en$The largest and oldest angel network in Texas (founded 2001, 100M plus deployed across 400 companies). Deal committees cover energy, life sciences, consumer and tech. A 100 USD application fee applies and the preferred raise size is 250K to 1.5M, so the current 100K SAFE sits below their floor - best to apply once the round grows or a lead emerges. The Texas base requirement is already met.$en$),
    ('Baylor Angel Network', 'organization', 'US', 'Texas', 'Waco',
     'https://www.baylorangelnetwork.com',
     'Applications via Dealum. Typical checks 25K to 250K - direct fit for a 100K ask. Quarterly cycles with a 5 week review. Intro call with BAN staff required before screening.',
     $ko$베일러대 한카머 경영대 산하 엔젤 네트워크(6천만 달러 이상, 100개사 투자). 학생 애널리스트가 스크리닝에 참여하는 독특한 구조. 티켓 사이즈 2.5만~25만 달러로 10만 달러 조달과 정확히 맞는 체급. 분기별 사이클, Dealum 포털 지원, 스크리닝 전 스태프와 인트로 콜 필수.$ko$,
     $en$Angel network under the Baylor Hankamer School of Business (60M plus invested, 100 plus companies) with a distinctive student analyst screening model. Typical checks of 25K to 250K make it exactly the right weight class for a 100K raise. Quarterly cycles, Dealum portal applications, and an intro call with staff is required before screening.$en$),
    ('Third Derivative', 'organization', 'US', 'Colorado', 'Boulder',
     'https://www.third-derivative.org',
     'RMI global climate tech accelerator. 18 month virtual program, optional 100K convertible note, no exclusivity. Requires TRL 4 working prototype and two full time employees. 2026 cohort emphasis: hard tech, low carbon materials, heavy industry.',
     $ko$RMI 산하 글로벌 기후테크 액셀러레이터(포트폴리오 286개사, 누적 37억 달러 후속 조달). 18개월 원격 프로그램, 선택형 10만 달러 컨버터블 노트, 배타조항 없음. 2026 코호트가 하드테크·저탄소 소재·중공업 탈탄소에 집중 - 저탄소 충전제로 제지산업 탄소를 줄이는 mbg와 정면 일치. TRL 4 프로토타입과 상근 2인 요건 확인 필요.$ko$,
     $en$Global climate tech accelerator under RMI (286 portfolio companies, 3.7B plus raised post acceptance). An 18 month virtual program with an optional 100K convertible note and no exclusivity. The 2026 cohort emphasizes hard tech, low carbon materials and heavy industry decarbonization - a direct match for mbg cutting paper industry carbon with low carbon filler. Verify the TRL 4 prototype and two full time employee requirements.$en$),
    ('NSF SBIR Americas Seed Fund', 'government', 'US', 'Virginia', 'Alexandria',
     'https://seedfund.nsf.gov',
     'Project Pitch submissions REOPENED 2026-06-02 (solicitation NSF 26-510, deep tech). Phase I up to 305K non-dilutive. Full proposal deadlines 2026-11-04 and 2027-03-04. Pitch is a short web form: 4 sections, 3500 chars each. Eligibility: at least 50 percent ownership by US citizens or permanent residents - VERIFY cap table eligibility before investing effort.',
     $ko$미국 국립과학재단의 비희석 시드 프로그램. 2025년 승인 만료로 중단됐던 Project Pitch 접수가 2026-06-02 재개(NSF 26-510, 딥테크 중심). Phase I 최대 30.5만 달러 - 티슈 검증 랩 테스트 자금과 용도가 정확히 겹친다. Pitch는 섹션당 3,500자 웹폼 4개로, 이번에 만드는 canonical 답변 시스템과 궁합이 좋다. 단, 미국 시민·영주권자 지분 50% 이상 요건이 있어 캡테이블 적격성 사전 확인 필수.$ko$,
     $en$The non-dilutive seed program of the US National Science Foundation. Project Pitch intake, paused during the 2025 authorization lapse, REOPENED on 2026-06-02 under solicitation NSF 26-510 with a deep tech focus. Phase I funds up to 305K - the same use of funds as the tissue validation lab work. The pitch is a short web form of four sections at 3500 characters each, a natural fit for the canonical answer system. Note the eligibility rule requiring at least 50 percent ownership by US citizens or permanent residents - verify cap table eligibility first.$en$),
    ('Techstars', 'organization', 'US', 'New York', 'New York',
     'https://www.techstars.com',
     'Applications via apply.techstars.com portal (account required). Standard deal: 20K for 5 percent plus optional 100K convertible note. Program specific deadlines - check the sustainability and Alabama EnergyTech style programs for materials fit.',
     $ko$글로벌 최상위 액셀러레이터 네트워크. apply.techstars.com 포털로 프로그램별 지원(계정 필요). 표준 딜은 2만 달러+선택형 10만 달러 노트. 소재·지속가능성 계열 프로그램 위주로 선별 지원 권장.$ko$,
     $en$A top global accelerator network. Program specific applications go through the apply.techstars.com portal (account required). The standard deal is 20K plus an optional 100K convertible note. Target the sustainability and materials adjacent programs.$en$),
    ('SOSV', 'fund', 'US', 'New Jersey', 'Princeton',
     'https://sosv.com',
     'Deep tech VC running HAX (hard tech, Newark NJ) and IndieBio (bio, SF and NY). Single application form covers all programs. Pre-seed checks up to 500K plus lab and engineering facilities.',
     $ko$하드테크(HAX)·바이오(IndieBio) 프로그램을 운영하는 딥테크 VC(운용자산 15억 달러 이상). 단일 웹폼으로 전 프로그램 지원. 프리시드 최대 50만 달러+랩·엔지니어링 시설 제공. 해양 바이오소재·CaCO3 충전제 양쪽 모두 HAX와 IndieBio 접점이 있다.$ko$,
     $en$A deep tech VC (1.5B plus AUM) running HAX for hard tech in Newark and IndieBio for bio in SF and NY. One web form covers every program. Pre-seed checks up to 500K plus lab and engineering facilities. Both the marine biomaterial and the CaCO3 filler angles have HAX and IndieBio touchpoints.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, notes, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id,
       coalesce((select id from app.entity_types et where et.code = f.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       f.country_code, f.region, f.city, f.website, 'form_only_research_2026-07-09', f.notes, f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where p.party_name = f.party_name
    and p.organization_id = i.org and p.deleted_at is null
);

-- (2) Set contact method + form URL (idempotent overwrite for these 7 names)
update app.parties p
set preferred_contact_method = m.method,
    contact_form_url         = m.form_url,
    updated_at               = now()
from (values
  ('SWAN Impact Network',          'portal',   'https://swanimpact.org/entrepreneurs'),
  ('Houston Angel Network',        'web_form', 'https://www.houstonangelnetwork.org/entrepreneurs'),
  ('Baylor Angel Network',         'portal',   'https://www.baylorangelnetwork.com/entrepreneurs/apply-for-funding/'),
  ('Third Derivative',             'web_form', 'https://www.third-derivative.org/startup-application'),
  ('NSF SBIR Americas Seed Fund',  'web_form', 'https://seedfund.nsf.gov/project-pitch/'),
  ('Techstars',                    'portal',   'https://apply.techstars.com'),
  ('SOSV',                         'web_form', 'https://sosv.com/apply')
) as m(party_name, method, form_url)
where p.party_name = m.party_name
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;

-- (3) Ensure investor_profile rows
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and p.party_name in ('SWAN Impact Network','Houston Angel Network','Baylor Angel Network','Third Derivative','NSF SBIR Americas Seed Fund','Techstars','SOSV')
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (4) Verify
select p.party_name, p.preferred_contact_method, p.contact_form_url
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.preferred_contact_method is not null
  and p.deleted_at is null
order by p.party_name;
