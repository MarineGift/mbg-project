-- ============================================================
-- fix_houston_hq_relocation_v2.sql
-- Replaces seed_houston_hq_relocation.sql (2026-07-25)
--
-- WHY V2
--   1) The first version wrote to app.tasks, which has a NOT NULL
--      deal_id. Relocation work has no counterparty deal, so the
--      insert failed with 23502. The correct table is app.todo_items,
--      which needs a board_id and leaves party_id optional.
--      The Supabase editor wraps the script in a transaction, so the
--      earlier sections most likely rolled back too. Everything below
--      is idempotent, so run the whole file regardless.
--
--   2) Wet lab is NOT needed. Near-term work is fundraising, sales and
--      FCC royalty contracts, and the company is pre-funding. That
--      removes half the reason Greentown ranked first, so the
--      workspace logic is rewritten around a single desk.
--
-- REVISED WORKSPACE POSITION
--   Greentown desk-only at about 450 USD per month against Cannon at
--   about 180 to 220 USD. The delta is roughly 3K USD a year. What it
--   buys is acceptance into a climatetech incubator, which reads as a
--   screening signal on the HAN application and to New Climate
--   Ventures and Fathom Fund, plus an Ion District address walkable to
--   Fathom, Chevron Technology Ventures and Ara Partners. For a
--   company whose near-term job is raising, that is worth the delta.
--   The 2021 rate sheet allows a desk without lab space.
--   Greentown selects its members, so the application takes time and
--   the move lands 2026-09-02. Apply to Greentown now, take Cannon
--   month to month as the landing pad, skip the Ion.
--   If cash is tight, Cannon plus public Ion and Greentown events
--   captures much of the network value at lower cost - many Ion events
--   are open to non-members.
--
-- Save as UTF-8 WITHOUT BOM. Supabase SQL Editor safe.
-- ============================================================


-- ------------------------------------------------------------
-- 0) PRE-FLIGHT. Run this alone first.
--    A board must exist for section E to insert anything.
--    If this returns zero rows, stop and say so.
-- ------------------------------------------------------------
select b.id, b.name, b.kind, b.position,
       (select count(*) from app.todo_status_options so where so.board_id = b.id) as status_options
from app.todo_boards b
where b.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
order by b.position;


-- ------------------------------------------------------------
-- A) Campaign
-- ------------------------------------------------------------
insert into app.campaigns
  (id, organization_id, created_by, name, campaign_type, description, status)
values
 ('d0000000-0000-4000-8000-0000000000f9',
  'b25de8f2-1020-482f-9012-183f63883169',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  'Houston HQ Relocation 2026Q3',
  'network',
  'Full relocation to Houston completing 2026-09-02, with Houston as headquarters for US and global business. Near-term focus is fundraising, sales and FCC royalty contracts. Austin is retired as a base.',
  'active')
on conflict (id) do nothing;


-- ------------------------------------------------------------
-- B) Checklist
-- ------------------------------------------------------------
insert into app.campaign_materials
  (campaign_id, section, item_key, label, detail, status, sort_order)
values
 ('d0000000-0000-4000-8000-0000000000f9','Workspace','ws_wetlab',
  'Wet lab requirement - RESOLVED, not needed',
  'Decision recorded 2026-07-25. No wet lab is required at this stage. Near-term work is fundraising, sales and FCC royalty contracts, so the workspace question reduces to a single desk. This closes the earlier blocking question about Greentown Houston wet lab capacity. Revisit only when absorbent production planning starts.',
  'complete',10),
 ('d0000000-0000-4000-8000-0000000000f9','Workspace','ws_greentown',
  'Apply to Greentown Houston as a desk-only member',
  'About 450 USD per desk per month on the 2021 sheet, which allows a desk without taking lab space - CONFIRM current pricing. The value here is not the furniture. Greentown selects its members, so acceptance is a screening signal that carries onto the HAN application and across conversations with New Climate Ventures and Fathom Fund. The address also sits in the Ion District, walkable to Fathom, Chevron Technology Ventures and Ara Partners. Selection takes time and the move lands 2026-09-02, so apply early.',
  'not_started',20),
 ('d0000000-0000-4000-8000-0000000000f9','Workspace','ws_cannon',
  'The Cannon month to month - landing pad',
  'About 180 USD per month Downtown and 220 USD West Houston as of 2024 - CONFIRM. Pay and go with no selection process, six locations, 24 hour access, parking and a business mailing address. Take this month to month so the move is not blocked while the Greentown application runs. If cash is tight this can also stand alone, paired with public Ion and Greentown events, many of which are open to non-members.',
  'not_started',30),
 ('d0000000-0000-4000-8000-0000000000f9','Workspace','ws_ion',
  'The Ion - skip for now',
  'Premium pricing under Industrious for a building the Greentown membership already puts within walking distance. A desk here only pays off once a target firm has agreed to meet. Not part of the current plan.',
  'complete',40),
 ('d0000000-0000-4000-8000-0000000000f9','HQ and Records','hq_han_wording',
  'Restate the company as Houston based on the HAN application',
  'The HAN materials currently say Texas based. Change to Houston based as of September 2, 2026. For a Houston angel network this is a gain, not a caveat - by the 2026-09-16 pitch date the company is local. Apply the same change to the deck, the Dealum application and every outbound template.',
  'not_started',110),
 ('d0000000-0000-4000-8000-0000000000f9','HQ and Records','hq_address',
  'Houston address of record and entity details',
  'Registered address, mailing address, bank and filing records move to Houston. Austin is retired as a base and should not appear in any investor facing material.',
  'not_started',120),
 ('d0000000-0000-4000-8000-0000000000f9','Cosmetics Regulatory','cos_foreign_reg',
  'Korean facility FDA registration plus US agent',
  'Cosmetics are manufactured in Korea and sold in the US, so MoCRA attaches as a FOREIGN facility obligation rather than domestic manufacturing. The Korean facility registers with FDA and designates a US agent. Registration renews every two years, updates are due within 60 days of a change. Enforcement has run since 2024-07-01 and a gap makes product misbranded or adulterated, which risks border holds. US cosmetic GMP facility obligations do not attach to the company at this stage.',
  'not_started',210),
 ('d0000000-0000-4000-8000-0000000000f9','Cosmetics Regulatory','cos_resp_person',
  'Determine the responsible person and file product listings',
  'The responsible person is the manufacturer, packer or distributor whose name appears on the product label. If the US entity is on the label it carries the listing obligation. Facility registration uses Form 5066, product listing uses Form 5067 with an FEI and a full ingredient list updated annually. Submissions go through Cosmetics Direct.',
  'not_started',220),
 ('d0000000-0000-4000-8000-0000000000f9','Cosmetics Regulatory','cos_small_biz',
  'Check the small business exemption',
  'Section 612 of the FD and C Act exempts certain small businesses out of registration and listing. Early revenue may qualify but specific product categories are carved out. Confirm with regulatory counsel rather than assuming - the downside of assuming wrongly is a border hold.',
  'not_started',230),
 ('d0000000-0000-4000-8000-0000000000f9','Cosmetics Regulatory','cos_safety_sub',
  'Safety substantiation and adverse event reporting',
  'Distinct to registration and listing. The responsible person must hold adequate safety substantiation records and report serious adverse events. Cosmetic GMP regulations were still not final as of January 2026, so the draft comment period will be the opportunity to shape them - worth monitoring given a novel marine derived ingredient.',
  'not_started',240),
 ('d0000000-0000-4000-8000-0000000000f9','Future Production','fp_site_scan',
  'Site scan of the Houston and Galveston chemical corridor',
  'Target for future marine biomaterial absorbent production. Scan the Houston Ship Channel, Bayport, Texas City and Galveston County complexes. Decide early between tolling with an existing operator and an owned facility - the two paths have very different capital profiles and very different regulatory footprints.',
  'not_started',310),
 ('d0000000-0000-4000-8000-0000000000f9','Future Production','fp_510k_prep',
  'Keep the 510(k) question answerable, do not answer it yet',
  'Sanitary pad production is deferred, so this is not urgent and a regulatory opinion today would be early and expensive. The exemption at 21 CFR 884.5435 depends on materials having an established safety profile, meaning a history of safe use for similar intended uses plus physical and chemical characterization. A novel marine biomaterial absorbent is unlikely to clear that on its own. The action now is to accumulate material characterization data in a form a regulatory attorney can assess later.',
  'not_started',320),
 ('d0000000-0000-4000-8000-0000000000f9','Logistics','log_port',
  'Port of Houston import lane for Korean raw material',
  'Relocation puts the company beside the port. Marine biomaterial feedstock shipped out of Korea no longer routes through another metro first. Quantify the landed cost and lead time difference - it strengthens both the FCC unit economics and the future absorbent plan.',
  'not_started',410)
on conflict (campaign_id, item_key) do nothing;

-- Force the three revised workspace items to the final wording even if
-- an earlier run already inserted the previous text.
update app.campaign_materials
set label = 'Wet lab requirement - RESOLVED, not needed',
    detail = 'Decision recorded 2026-07-25. No wet lab is required at this stage. Near-term work is fundraising, sales and FCC royalty contracts, so the workspace question reduces to a single desk. This closes the earlier blocking question about Greentown Houston wet lab capacity. Revisit only when absorbent production planning starts.',
    status = 'complete', updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000f9' and item_key = 'ws_wetlab';

update app.campaign_materials
set label = 'Apply to Greentown Houston as a desk-only member',
    detail = 'About 450 USD per desk per month on the 2021 sheet, which allows a desk without taking lab space - CONFIRM current pricing. The value is the selection, not the furniture. Greentown chooses its members, so acceptance is a screening signal that carries onto the HAN application and across conversations with New Climate Ventures and Fathom Fund. The address also sits in the Ion District, walkable to Fathom, Chevron Technology Ventures and Ara Partners. Selection takes time and the move lands 2026-09-02, so apply early.',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000f9' and item_key = 'ws_greentown';

update app.campaign_materials
set label = 'The Ion - skip for now',
    detail = 'Premium pricing under Industrious for a building the Greentown membership already puts within walking distance. A desk here only pays off once a target firm has agreed to meet. Not part of the current plan.',
    status = 'complete', updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000f9' and item_key = 'ws_ion';


-- ------------------------------------------------------------
-- C) Workspace parties
-- ------------------------------------------------------------
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'partner'),
                  (select id from app.party_types where code = 'investor'), 1) as partner_type_id
),
firms(party_name, entity_code, city, website, notes, intro_ko, intro_en) as (
  values
  ('The Cannon', 'organization', 'Houston', 'https://www.thecannon.com',
   'HOU-T2 | Startup focused coworking operator with six Houston area locations reaching between West Houston and The Woodlands, plus Galveston. Three membership tiers with 24 hour access, parking and a business mailing address. Reported flexible tier pricing about 180 USD per month Downtown and 220 USD West Houston as of 2024 - CONFIRM. Runs Cannon Connect, a platform linking investors, founders and service providers, and the Founders Club program. Reciprocal day passes with Esperson Flex. NOTE - Esperson Flex is run by Cameron Management, whose chief executive Dougal Cameron shares a name with the recorded contact at Golden Section. No selection process, so it is the immediate landing pad while the Greentown application runs.',
   $ko$휴스턴 서부부터 The Woodlands, 갤버스턴까지 6개 지점을 운영하는 스타트업 중심 코워킹 사업자. 3단계 멤버십에 24시간 출입·주차·비즈니스 주소가 포함되고, 2024년 기준 유연 멤버십이 Downtown 월 180달러, West Houston 월 220달러 수준으로 보고됐다(현재가 확인 필요). Cannon Connect 플랫폼과 Founders Club 을 운영하며 Esperson Flex 와 상호 데이패스를 제공한다. 선발 절차가 없어 즉시 입주 가능하다는 점이 핵심이며, Greentown 심사가 진행되는 동안의 착지점으로 삼는다. 에너지·기후 투자자 밀도는 Ion District 에 못 미친다.$ko$,
   $en$A startup focused coworking operator with six Houston area locations stretching between West Houston and The Woodlands, plus Galveston. Three membership tiers include 24 hour access, parking and a business mailing address, with flexible tier pricing reported around 180 USD monthly Downtown and 220 USD in West Houston as of 2024 - confirm current rates. It runs Cannon Connect and the Founders Club program and offers reciprocal day passes with Esperson Flex. The key point is that it has no selection process, so it works as the immediate landing pad while the Greentown application runs. Energy and climate investor density is well below the Ion District.$en$),

  ('Industrious', 'company', 'Houston', 'https://www.industriousoffice.com',
   'HOU-T2 | Premium flexible workspace operator. Selected by Rice Real Estate Co. in January 2025 to run the 86,000 square foot coworking community inside the Ion, replacing WeWork owned Common Desk. Second Houston location at 1301 McKinney Street. IMPORTANT - a workspace operator, not a startup program. Membership buys building access and presence, not curated investor introductions. Much online material still names Common Desk at the Ion and is out of date. Not part of the current plan.',
   $ko$프리미엄 유연 오피스 사업자. 2025년 1월 Rice Real Estate Co. 가 Ion 내 86,000 sqft 코워킹 공간의 운영사로 선정했으며 WeWork 소유였던 Common Desk 를 대체했다. 휴스턴 두 번째 지점은 1301 McKinney Street. 주의할 점은 워크스페이스 운영사이지 스타트업 프로그램 주체가 아니라는 것이다 - 멤버십은 건물 접근성을 살 뿐 큐레이션된 투자자 소개가 딸려오지 않는다. 온라인 자료 다수가 아직 Common Desk 로 표기해 최신이 아니다. 현재 계획에서는 제외.$ko$,
   $en$A premium flexible workspace operator selected by Rice Real Estate Co. in January 2025 to run the 86,000 square foot coworking community inside the Ion, replacing WeWork owned Common Desk. Its second Houston location sits at 1301 McKinney Street. The caveat is that this is a workspace operator rather than a startup program - membership buys building access and presence, not curated investor introductions. Much material online still names Common Desk at the Ion and is out of date. Not part of the current plan.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, notes, intro_ko, intro_en)
select i.org, f.party_name, i.partner_type_id,
       coalesce((select id from app.entity_types et where et.code = f.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       'US', 'Texas', f.city, f.website, 'houston_workspace_2026-07-25', f.notes, f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where p.party_name = f.party_name
    and p.organization_id = i.org
    and p.deleted_at is null
);


-- ------------------------------------------------------------
-- D) Ion and Greentown records
-- ------------------------------------------------------------
update app.parties p
set website = 'https://iondistrict.com',
    notes = 'HOU-T2 | 4201 Main Street, Midtown. A 1939 Sears building converted by Rice Management Company and opened in 2021, now a 266,000 square foot Class AA office and innovation hub at the centre of the 16 acre Ion District. LEED Gold, WiredScore Platinum, WELL Silver. Owned by Rice Real Estate Co. Holds coworking and offices, incubators and accelerators, classrooms, a prototyping lab, an investor studio and restaurants, with a TED style Forum Stairs space hosting hundreds of startup events a year. Coworking is 86,000 square feet run by Industrious since January 2025, replacing WeWork owned Common Desk - most online listings are stale on this. TENANTS THAT MATTER - Fathom Fund (T1 rank 2), Chevron Technology Ventures, Ara Partners, Activate, plus Occidental Petroleum, Microsoft, Carbon Clean and Liongard. Highest investor density per square foot in Houston. Greentown Labs Houston sits in the same district and is walkable, so a Greentown membership captures the proximity without paying for Ion space. Many Ion events are open to non-members.',
    updated_at = now()
where p.party_name = 'The Ion Houston'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;

update app.parties p
set website = 'https://greentownlabs.com/houston/',
    notes = 'HOU-T2 WORKSPACE RANK1 | 4200 San Jacinto Street, inside the 16 acre Ion District, opened spring 2021 on a former Fiesta grocery site. Roughly 30,000 to 40,000 square feet of prototyping lab, office and community space, including more than 5,000 square feet of open concept prototyping lab plus a machine shop, electronics lab, tool shop, 3D printers and an outdoor test area. 2021 Houston rates were 450 USD per desk per month plus 4.00 USD per square foot per month for prototyping space, and a desk may be taken without lab space - CONFIRM current pricing. An INCUBATOR, not an accelerator, with no time limit on residency. Around 19 startups in the Houston hub as of Q1 2025, running the ACCEL cohort with Browning the Green Space. CEO Georgina Campbell Flatter, Head of Houston Lawson Gow. Partnerships include Energy Tech Nexus and an Industrial Center of Excellence with Nominal. WET LAB QUESTION CLOSED 2026-07-25 - no wet lab is needed at this stage. Ranked first on a DESK-ONLY basis - Greentown selects its members, so acceptance is a screening signal usable on the HAN application and with New Climate Ventures and Fathom Fund, and the address is walkable to the Ion tenants. Selection takes time, so apply well ahead of the 2026-09-02 move.',
    updated_at = now()
where p.party_name = 'Greentown Labs Houston'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- E) Todos on the first available board.
--    Status is resolved to the first non-done option on that board.
--    Nothing inserts if no board exists - check section 0 first.
-- ------------------------------------------------------------
insert into app.todo_items
  (organization_id, board_id, title, description, status, priority, due_date, party_id, position, custom)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       b.id, v.title, v.description,
       coalesce((select so.key from app.todo_status_options so
                  where so.board_id = b.id and so.is_done = false
                  order by so.position limit 1), 'todo'),
       v.priority, v.due_date::date,
       (select p.id from app.parties p
         where p.party_name = v.party_name
           and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
           and p.deleted_at is null limit 1),
       v.pos,
       '{"src":"houston_hq_relocation_2026-07-25"}'::jsonb
from (select id from app.todo_boards
       where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
       order by position limit 1) b
cross join (values
  ('Apply to Greentown Houston as a desk-only member',
   '웻랩 불필요 확정에 따라 데스크 단독으로 신청. 2021년 요율 기준 데스크 월 450달러이며 랩 공간 없이 데스크만 받을 수 있다(현재가 확인 필요). 핵심 가치는 책상이 아니라 선발 자체다 - 기후테크 인큐베이터 심사 통과가 HAN 지원서와 New Climate Ventures·Fathom Fund 대화에서 신호로 작동한다. 주소도 Ion District 안이라 Fathom·Chevron Technology Ventures·Ara Partners 까지 도보다. 심사에 시간이 걸리므로 9/2 이전 대비해 조기 신청.',
   'high', '2026-07-31', 'Greentown Labs Houston', 10),
  ('Take The Cannon month to month as the landing pad',
   'Greentown 심사가 진행되는 동안의 즉시 착지점. 선발 절차가 없어 바로 입주 가능하다. Downtown 과 West Houston 요금·데이패스 조건 비교하고 월단위 계약으로 묶이지 않게 할 것. 현금이 빠듯하면 Cannon 단독 + Ion·Greentown 공개 행사 참석 조합도 실질적 대안이다.',
   'medium', '2026-08-05', 'The Cannon', 20),
  ('Restate the company as Houston based across all materials',
   'HAN 지원서·피치덱·Dealum 제출·아웃바운드 템플릿의 "Texas based" 를 "Houston based as of September 2, 2026" 으로 변경. 휴스턴 엔젤 네트워크 상대로는 가점이며 9/16 피치 시점에는 이미 로컬 기업이다. 오스틴은 투자자 대면 자료에서 전부 삭제.',
   'high', '2026-08-07', '', 30),
  ('Check the Korean cosmetics facility FDA registration and US agent',
   '화장품은 한국 생산·미국 판매 구조이므로 MoCRA 가 해외 시설 등록 의무로 적용된다. 미국 내 제조 시설 요건이 아니다. 한국 제조 시설의 FDA 등록 여부와 미국 대리인 지정 여부를 확인하고 미등록이면 착수. 2년마다 갱신, 변경 시 60일 내 갱신. 2024-07-01 부터 집행 중이며 미비 시 통관 보류 위험.',
   'high', '2026-08-17', '', 40),
  ('Fix the responsible person and plan the product listings',
   '제품 라벨에 이름이 올라가는 주체가 responsible person 이고 리스팅 의무를 진다. 미국 판매 법인이 라벨에 오르는지 먼저 확정. 시설 등록 Form 5066, 제품 리스팅 Form 5067(FEI·전성분, 연 1회 갱신), 제출은 Cosmetics Direct. FD&C Act 612조 소기업 면제 해당 여부도 규제 자문으로 확인 - 품목별 예외가 있어 가정은 위험하다.',
   'high', '2026-08-24', '', 50),
  ('Move the address of record and retire Austin',
   '등기 주소·우편 주소·은행·신고 기록을 휴스턴으로 이전. 오스틴은 운영 거점에서 제외하고 대외 자료에서 삭제한다.',
   'high', '2026-08-28', '', 60),
  ('Start the Houston and Galveston chemical corridor site scan',
   '향후 해양 바이오소재 흡수체 생산 부지 조사. Houston Ship Channel, Bayport, Texas City, Galveston County 를 훑고 기존 사업자 토링 방식과 자체 설비 방식을 조기 비교 - 자본 소요와 규제 부담이 완전히 다르다. 한국발 원료의 휴스턴항 직수입 리드타임·착지원가도 함께 산출해 FCC 유닛 이코노믹스에 반영.',
   'medium', '2026-09-30', '', 70)
) as v(title, description, priority, due_date, party_name, pos)
where not exists (
  select 1 from app.todo_items ti
  where ti.title = v.title
    and ti.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and ti.archived_at is null
);


-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: campaign and checklist (expect 1 campaign, 13 items)
select 'campaign' as kind, name as detail
from app.campaigns where id = 'd0000000-0000-4000-8000-0000000000f9'
union all
select 'checklist items', count(*)::text
from app.campaign_materials where campaign_id = 'd0000000-0000-4000-8000-0000000000f9';

-- V2: the two workspace parties
select p.party_name, p.website, left(p.notes, 40) as notes_head
from app.parties p
where p.source = 'houston_workspace_2026-07-25' and p.deleted_at is null
order by p.party_name;

-- V3: todos (expect 7, 07-31 through 09-30)
select ti.due_date, ti.priority, ti.status, ti.title
from app.todo_items ti
where ti.custom->>'src' = 'houston_hq_relocation_2026-07-25'
  and ti.archived_at is null
order by ti.due_date;

-- V4: roster now 40
select left(p.notes, 7) as tier, count(*) as parties
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.notes like 'HOU-%' and p.deleted_at is null
group by left(p.notes, 7)
order by tier;
