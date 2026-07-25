-- ============================================================
-- seed_houston_angel_network.sql
-- Houston Angel Network (HAN) - Series A application track
-- Verified by web research 2026-07-25 against houstonangelnetwork.org
--
-- CONTEXT / WHY THIS IS AN UPDATE, NOT A NEW PARTY
--   HAN already exists in app.parties (seed_form_only_investors.sql,
--   2026-07-09) with preferred_contact_method = web_form, a whitelisted
--   domain (houstonangelnetwork.org) and one contact (Samia Ahsan).
--   The 2026-07-09 note said the 100K SAFE was below the HAN floor.
--   That note is now STALE - the raise is a 3M Series A, and HAN states
--   pre-seed / seed / bridge / Series A are all eligible. This script
--   refreshes the record and opens an application track.
--
-- WHAT IT DOES (idempotent, Supabase SQL Editor safe)
--   1) Campaign "Houston Angel Network (network)" - fixed id ...fb
--   2) Campaign materials checklist - the HAN application playbook
--   3) Refresh the HAN party notes / intro / form URL
--   4) investor_profile + priority + sector focus
--   5) Deal on the investors pipeline at stage backlog
--   6) Tasks pinned to the HAN monthly cycle, target pitch 2026-09-16
--
-- HAN CYCLE (verified 2026-07-25)
--   Apply at least ONE MONTH before the target pitch date
--   Deal Committee review - last week of the month
--   Internal member vote - first Wednesday
--   Pitch meeting     - third Wednesday, none in July or December
--   Pitch format      - 8 minutes plus 5 minutes Q and A, 3 companies only
--   Application fee   - 100 USD, refunds none, outcome not guaranteed
--   NO NDA is signed by HAN or its members during screening
--
-- TARGET CYCLE. July has no pitch meeting and the 2026-08-19 slot needed
--   an application by mid July, so the first realistic slot is
--   2026-09-16 (third Wednesday of September).
--     2026-08-14  application deadline (one month ahead)
--     2026-08-24  deal committee week
--     2026-09-02  internal member vote
--     2026-09-16  pitch meeting
--
-- ASSUMPTION TO ADJUST: value_amount is set to 250000 USD as the tracked
--   HAN allocation inside the 3M round. Change it if the target differs.
--
-- Editor safety: no do-blocks, no temp tables, no semicolons inside string
--   literals, no standalone SQL keywords inside string literals.
--   Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Campaign container (fixed id ...fb - fc / fd / fe / ff taken)
-- ------------------------------------------------------------
insert into app.campaigns
  (id, organization_id, created_by, name, campaign_type, description, status)
values
 ('d0000000-0000-4000-8000-0000000000fb',
  'b25de8f2-1020-482f-9012-183f63883169',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  'Houston Angel Network (network)',
  'network',
  'HAN monthly pitch application track for the Series A. Target pitch date 2026-09-16 (third Wednesday). Application fee 100 USD. HAN takes no equity - members invest individually or via an SPV and the company pays the SPV formation cost. No NDA is signed during screening.',
  'active')
on conflict (id) do nothing;


-- ------------------------------------------------------------
-- 2) HAN application playbook checklist
-- ------------------------------------------------------------
insert into app.campaign_materials
  (campaign_id, section, item_key, label, detail, status, sort_order)
values
 ('d0000000-0000-4000-8000-0000000000fb','Eligibility','elig_stage',
  'Confirm stage eligibility',
  'HAN accepts pre-seed, seed, bridge and Series A in equity, debt, or debt with an equity component. The 3M Series A qualifies. The earlier note about a 100K floor is obsolete.',
  'ready',10),
 ('d0000000-0000-4000-8000-0000000000fb','Eligibility','elig_traction',
  'Working prototype plus market validation',
  'HAN requires a completed working prototype and market validation such as a pilot, beta users or revenue. Exceptions are possible depending on the industry. Line up the two paper mill orders and the top filler maker relationship as the validation evidence.',
  'in_progress',20),
 ('d0000000-0000-4000-8000-0000000000fb','Eligibility','elig_committee',
  'Pick the target deal committee',
  'Five committees exist - Energy, Life Sciences, Consumer, Tech, Aerospace. FCC filler for the paper industry maps best to Energy (industrial decarbonization) with Life Sciences as the marine biomaterial fallback. Frame the application so routing is obvious.',
  'not_started',30),
 ('d0000000-0000-4000-8000-0000000000fb','Eligibility','elig_ip_boundary',
  'Set the no-NDA disclosure boundary',
  'HAN and its members sign no confidentiality agreement during screening. Decide in advance what can be said about the FCC patent family and the active proceedings. Keep unpublished claim strategy and the opinion letter analysis out of every written submission.',
  'not_started',40),
 ('d0000000-0000-4000-8000-0000000000fb','Application','app_readiness',
  'Run the HAN readiness scorecard',
  'Free self assessment tool at houston-angel-p8gvnhec.scoreapp.com. Optional but it previews how the deal committee scores the deal.',
  'not_started',110),
 ('d0000000-0000-4000-8000-0000000000fb','Application','app_fee',
  'Pay the 100 USD application fee',
  'Square checkout. The fee does not guarantee a pitch slot or funding. Log the receipt as a fundraising expense.',
  'not_started',120),
 ('d0000000-0000-4000-8000-0000000000fb','Application','app_dealum',
  'Complete the Dealum application',
  'HAN moved applications to Dealum (app.dealum.com). Submit at least one month before the target pitch date. Applying early is explicitly encouraged.',
  'not_started',130),
 ('d0000000-0000-4000-8000-0000000000fb','Pitch Materials','pitch_10slides',
  'Build the HAN 10 slide deck',
  'HAN prescribes the order - Problem, Solution and value proposition, The Magic (IP and secret sauce), Business model, Go to market, Competition, Team, Financials and key metrics, Progress to date, Raise and use of funds. Rebuild it as an 8 minute cut of the Ver3.x deck rather than reusing the full version.',
  'not_started',210),
 ('d0000000-0000-4000-8000-0000000000fb','Pitch Materials','pitch_valuation',
  'Prepare the valuation defence',
  'The 27M pre-money is high for a typical angel network audience. Have the comparable transactions, the royalty margin model and the patent position ready as the answer, and decide whether an SPV allocation with different terms is acceptable.',
  'not_started',220),
 ('d0000000-0000-4000-8000-0000000000fb','Pitch Materials','pitch_qa',
  'Rehearse the 5 minute Q and A',
  'Only 5 minutes of questions. Prepare tight answers on unit economics, mill adoption cycle length, the competitor patent dispute, and use of funds.',
  'not_started',230),
 ('d0000000-0000-4000-8000-0000000000fb','Screening','screen_committee_call',
  'Deal committee reviewer call',
  'If routed forward, a HAN reviewer (member, Managing Director or Venture Associate) books a 30 to 60 minute call. Committee meetings run in the last week of each month.',
  'not_started',310),
 ('d0000000-0000-4000-8000-0000000000fb','Screening','screen_vote',
  'Internal member vote',
  'First Wednesday of the month. Three companies advance to the pitch meeting. Highly competitive - plan a second cycle in case this one does not land.',
  'not_started',320),
 ('d0000000-0000-4000-8000-0000000000fb','Follow-up','follow_signups',
  'Work the post-pitch sign up sheet',
  'Interested members add themselves to a sign up sheet or approach directly. Follow up is entirely the founder responsibility. HAN does not run diligence or negotiate terms.',
  'not_started',410),
 ('d0000000-0000-4000-8000-0000000000fb','Follow-up','follow_spv',
  'Decide the SPV path',
  'Members may invest directly or pool through an SPV. The company pays the SPV formation cost, so budget it before agreeing.',
  'not_started',420),
 ('d0000000-0000-4000-8000-0000000000fb','Ecosystem','eco_rice',
  'Warm path via Rice Alliance and the Ion',
  'Rice Alliance is a listed HAN partner and co-hosts HAN events. A referral through Rice Alliance or Greentown Labs Houston is worth more than a cold application.',
  'not_started',510),
 ('d0000000-0000-4000-8000-0000000000fb','Ecosystem','eco_capital_factory',
  'Cross-reference the Capital Factory relationship',
  'Capital Factory co-sponsors HAN angel bootcamps. The existing Capital Factory campaign (...fd) may produce a member level introduction to a HAN member.',
  'not_started',520)
on conflict (campaign_id, item_key) do nothing;


-- ------------------------------------------------------------
-- 3) Refresh the existing HAN party record
--    (overwrites the stale 100K floor note)
-- ------------------------------------------------------------
update app.parties p
set contact_form_url = 'https://www.houstonangelnetwork.org/entrepreneurs',
    preferred_contact_method = 'web_form',
    city    = 'Houston',
    region  = 'Texas',
    country_code = 'US',
    website = 'https://www.houstonangelnetwork.org',
    notes   = 'Verified 2026-07-25. Monthly cycle - apply one month ahead, deal committee last week, member vote first Wednesday, pitch third Wednesday, no meetings in July or December. 8 minute pitch plus 5 minute Q and A, only 3 companies per meeting. Application fee 100 USD via Square, then apply on Dealum. Committees - Energy, Life Sciences, Consumer, Tech, Aerospace. HAN takes no equity and runs no diligence. NO NDA during screening. Leadership - Eric Alfuth (Chair), Mitra Miller (Vice President), Samia Ahsan (Managing Director). Address 1801 Main Street Suite 1300 Box 12, Houston TX 77002.',
    intro_ko = $ko$텍사스에서 가장 오래되고 활발한 엔젤 네트워크(2001년 설립, 회원 100명 이상, 400건 이상 딜에 1억 달러 이상 투자). 에너지·라이프사이언스·소비재·테크·항공우주 5개 딜커미티 구조이며, 에너지 산업 출신 경영진이 다수라 산업 탈탄소 서사가 잘 통한다. HAN 자체는 지분을 갖지 않고 회원이 개별 또는 SPV로 투자한다(SPV 설립비는 회사 부담). 월간 사이클 - 목표 피치일 1개월 전 지원, 말주 딜커미티 리뷰, 첫째 수요일 내부 투표, 셋째 수요일 피치(7월·12월 제외), 회당 3개사만 선정. 지원비 100달러. 2026-07-09에 기록한 '10만 달러 SAFE는 하한 미달' 판단은 폐기 - 현재 Series A는 지원 자격에 해당한다. 다만 27M 프리머니는 엔젤 오디언스 기준으로 높은 편이라 밸류에이션 방어 논리가 핵심이다. 스크리닝 단계에서 NDA를 체결하지 않으므로 FCC 특허 계쟁 관련 비공개 자료는 제출물에서 제외해야 한다.$ko$,
    intro_en = $en$The oldest and most active angel network in Texas (established 2001, 100 plus members, more than 100M USD deployed across 400 plus deals). Five deal committees cover Energy, Life Sciences, Consumer, Tech and Aerospace, and the membership is heavy with energy industry operators, so an industrial decarbonization narrative lands well. HAN itself holds no equity - members invest individually or pool through an SPV, and the company pays any SPV formation cost. Monthly cycle - apply one month before the target pitch, deal committee review in the last week, internal member vote on the first Wednesday, pitch meeting on the third Wednesday, none in July or December, only three companies per meeting. Application fee is 100 USD. The 2026-07-09 assessment that the 100K SAFE sat below the HAN floor is retired - the current Series A is eligible. The 27M pre-money is high for an angel audience, so the valuation defence is the critical piece. HAN signs no NDA during screening, so material on the FCC patent proceedings must stay out of every submission.$en$,
    updated_at = now()
where p.party_name = 'Houston Angel Network'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- 4a) investor_profile row (idempotent)
-- ------------------------------------------------------------
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.party_name = 'Houston Angel Network'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);


-- ------------------------------------------------------------
-- 4b) Priority = medium. HAN will not lead a 3M Series A - the value
--     is local credibility, SPV participation and Houston ecosystem
--     access, so it stays a supporting channel, not a lead source.
-- ------------------------------------------------------------
update app.investor_profile ip
set priority = 'medium', updated_at = now()
from app.parties p
where p.id = ip.party_id
  and p.party_name = 'Houston Angel Network'
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- 4c) Sector focus
-- ------------------------------------------------------------
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('advanced_materials'),
  ('industrial'),
  ('deep_tech')
) as m(sector_code)
cross join app.parties p
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where p.party_name = 'Houston Angel Network'
  and p.deleted_at is null
  and not exists (
    select 1 from app.investor_sector_focus f
    where f.investor_profile_id = ip.id and f.sector_id = s.id
  );


-- ------------------------------------------------------------
-- 5) Deal on the investors pipeline, stage backlog
--    (moves to cold_outreach automatically once the application
--     is recorded as submitted)
-- ------------------------------------------------------------
insert into app.deals
  (party_id, pipeline_id, current_stage_id, campaign_id, deal_name, description,
   status, value_amount, value_currency, priority, source, extra_data,
   organization_id, expected_close_date, stage_entered_at, created_at, updated_at)
select p.id,
       (select pl.id from app.pipelines pl
         where pl.code = 'investors'
           and pl.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid),
       (select s.id from app.stages s
          join app.pipelines pl on pl.id = s.pipeline_id
         where pl.code = 'investors'
           and pl.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
           and s.code = 'backlog'),
       'd0000000-0000-4000-8000-0000000000fb'::uuid,
       'Houston Angel Network - Sep 2026 pitch cycle',
       'HAN monthly pitch application for the Series A. Target pitch 2026-09-16. Application deadline 2026-08-14. Tracked allocation 250K USD inside the 3M round - adjust once member appetite is known.',
       'open', 250000, 'USD', 'medium', 'han_research_2026-07-25',
       '{"src":"han_research_2026-07-25","channel":"web_form","target_pitch":"2026-09-16","fee_usd":100,"nda":"none"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       date '2026-10-31', now(), now(), now()
from app.parties p
where p.party_name = 'Houston Angel Network'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and not exists (
    select 1 from app.deals d
    where d.party_id = p.id
      and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
      and d.deleted_at is null
  );


-- ------------------------------------------------------------
-- 6) Tasks pinned to the HAN cycle (all times America/Chicago)
-- ------------------------------------------------------------
insert into app.tasks
  (deal_id, title, description, status, priority, due_at, extra_data, organization_id)
select d.id, v.title, v.description, 'pending', v.priority,
       v.due_at::timestamptz,
       '{"src":"han_research_2026-07-25"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.deals d
cross join (values
  ('Run the HAN readiness scorecard and pay the 100 USD fee',
   '무료 readiness 도구(houston-angel-p8gvnhec.scoreapp.com)로 자가진단 후 Square 결제. 결제해도 피치 기회나 투자는 보장되지 않는다. 영수증은 조달 비용으로 기록.',
   'high', '2026-08-03 09:00:00-05'),
  ('Fix the no-NDA disclosure boundary for the FCC patent material',
   'HAN과 회원은 스크리닝 단계에서 NDA를 체결하지 않는다. Kleannara 대응 논리, 의견서 분석, 미공개 클레임 전략은 제출물과 구두 답변 모두에서 제외. 공개 가능한 범위를 1페이지 메모로 확정하고 피치덱에 반영.',
   'high', '2026-08-07 09:00:00-05'),
  ('Choose the target deal committee and frame the application for it',
   'Energy / Life Sciences / Consumer / Tech / Aerospace 중 라우팅 대상 결정. 제지 산업 탈탄소 서사면 Energy, 해양 바이오소재 서사면 Life Sciences. 지원서 첫 문단에서 위원회가 자명하게 갈리도록 작성.',
   'high', '2026-08-07 09:00:00-05'),
  ('Build the 8 minute HAN cut of the deck in the prescribed 10 slide order',
   'HAN 지정 순서 - Problem / Solution and value proposition / The Magic (IP) / Business model / Go to market / Competition / Team / Financials and key metrics / Progress to date / Raise and use of funds. Ver3.x 전체판 재사용 금지, 8분 전용 축약본으로 별도 제작.',
   'high', '2026-08-12 09:00:00-05'),
  ('Prepare the 27M pre-money valuation defence',
   '엔젤 오디언스 기준 27M 프리머니는 높은 편이다. 비교 거래 사례, 로열티 마진 모델, 특허 포지션을 방어 논리로 정리하고, SPV 배정에 별도 조건을 허용할지 사전에 결정.',
   'high', '2026-08-12 09:00:00-05'),
  ('Submit the Dealum application (one month before the target pitch)',
   '목표 피치일 2026-09-16 기준 최소 한 달 전 제출. HAN은 조기 지원을 권장한다. 제출 후 app.application_forms 상태를 submitted 로 기록하면 딜이 cold_outreach 로 이동한다.',
   'urgent', '2026-08-14 09:00:00-05'),
  ('Prep for the deal committee reviewer call',
   '딜커미티는 매월 마지막 주에 열린다. 통과 시 HAN 리뷰어(회원, Managing Director 또는 Venture Associate)가 30~60분 콜을 잡는다. 리뷰어 배경 조사와 예상 질문 리스트를 미리 준비.',
   'high', '2026-08-24 09:00:00-05'),
  ('Check the internal member vote outcome',
   '첫째 수요일 내부 투표에서 3개사만 피치에 진출한다. 결과를 확인하고, 미선정 시 10월 사이클(투표 2026-10-07, 피치 2026-10-21) 재지원 여부를 즉시 결정.',
   'high', '2026-09-02 09:00:00-05'),
  ('HAN pitch meeting - 8 minutes plus 5 minutes Q and A',
   '셋째 수요일 피치. 8분 발표 + 5분 질의응답. 유닛 이코노믹스, 제지사 도입 사이클 길이, 경쟁사 특허 분쟁, 자금 사용 계획 4개 질문에 대한 압축 답변을 준비.',
   'urgent', '2026-09-16 09:00:00-05'),
  ('Work the post-pitch sign up sheet within 24 hours',
   '관심 회원은 사인업 시트에 이름을 적거나 직접 접근한다. 이후 팔로업은 전적으로 창업자 책임이며 HAN은 실사나 텀시트 협상에 관여하지 않는다. 24시간 내 개별 이메일 발송, URM 딜로 각각 등록.',
   'urgent', '2026-09-17 09:00:00-05'),
  ('Explore a warm path through Rice Alliance, the Ion or Capital Factory',
   'Rice Alliance는 HAN 공식 파트너이고 Capital Factory는 HAN 엔젤 부트캠프를 공동 후원한다. 콜드 지원보다 회원 레벨 소개가 통과율이 높다. 기존 Capital Factory 캠페인(...fd) 인맥에서 HAN 회원 접점을 찾아본다.',
   'medium', '2026-08-10 09:00:00-05')
) as v(title, description, priority, due_at)
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and d.deleted_at is null
  and not exists (
    select 1 from app.tasks t
    where t.deal_id = d.id and t.title = v.title and t.deleted_at is null
  );


-- ============================================================
-- VERIFY (read-only, run after the seed)
-- ============================================================

-- V1: campaign + checklist (expect 1 campaign, 16 items)
select 'campaign' as kind, name as detail
from app.campaigns where id = 'd0000000-0000-4000-8000-0000000000fb'
union all
select 'checklist items', count(*)::text
from app.campaign_materials where campaign_id = 'd0000000-0000-4000-8000-0000000000fb';

-- V2: party refresh (notes should mention 2026-07-25, not the 100K floor)
select p.party_name, p.city, p.preferred_contact_method, p.contact_form_url,
       ip.priority, left(p.notes, 80) as notes_head
from app.parties p
left join app.investor_profile ip on ip.party_id = p.id
where p.party_name = 'Houston Angel Network' and p.deleted_at is null;

-- V3: deal + tasks (expect 1 deal at backlog, 11 pending tasks)
select d.deal_name, s.code as stage, d.status, d.value_amount, d.value_currency,
       d.expected_close_date,
       (select count(*) from app.tasks t where t.deal_id = d.id and t.deleted_at is null) as task_count
from app.deals d
join app.stages s on s.id = d.current_stage_id
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null;

-- V4: task schedule
select t.due_at, t.priority, t.title
from app.tasks t
join app.deals d on d.id = t.deal_id
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and t.deleted_at is null
order by t.due_at;
