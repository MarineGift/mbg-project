-- ============================================================
-- SEED: CA/NY deep-tech + life-science VCs -- Wave 8 (2026-07-04)
-- Genuinely-new firms only (checked against the 530-row investor list).
-- Idempotent: name/domain dedup guard skips anything already present.
-- source: web_research_2026Q3_ca_ny. Sector focus stored as normalized CODES
-- (comma-separated) so the new sync RPC can build investor_sector_focus links.
-- Editor-safe: pure statements, no do-blocks, no temp tables.
-- ============================================================

-- (1) insert missing firms
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id,
   country_code, city, region, website, source, intro_ko, intro_en)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  c.party_name,
  (select id from app.party_types where code='investor'),
  coalesce((select id from app.entity_types where code='fund'),
           (select id from app.entity_types where code='company'),
           (select min(id) from app.entity_types)),
  c.country_code, c.city, c.region,
  'https://www.'||c.domain, 'web_research_2026Q3_ca_ny',
  c.intro_ko, c.intro_en
from (values
  -- ----- Deep tech / infrastructure -----
  ('Point72 Ventures','p72.vc','US','New York','New York',
   '뉴욕 기반 딥테크·AI·디펜스·핀테크 초기~성장 투자사. 시드부터 IPO까지 100개+ 투자. mbg의 딥테크/첨단소재 파이프라인에 잠재적 관심.',
   'NYC-based early-to-growth investor in deep tech, AI, defense and fintech - 100+ investments seed to IPO. Potential fit for mbg deep-tech / advanced-materials pipeline.'),
  ('True Ventures','trueventures.com','US','San Francisco','California',
   '실리콘밸리 초기(시드/시리즈A) 전문. 딥테크·하드웨어·소비자 전반. 창업자 네트워크 중심 지원. 하드테크 소재 스타트업에 접점.',
   'Silicon Valley early-stage (seed/Series A) specialist across deep tech, hardware and consumer - founder-network driven. Touchpoint for hard-tech materials startups.'),
  ('645 Ventures','645ventures.com','US','New York','New York',
   '뉴욕 시드~시리즈A. 엔터프라이즈 SaaS·인프라 소프트웨어·소비자 기술. 독자 소프트웨어 플랫폼으로 성장 단계까지 스케일 지원.',
   'NYC seed-to-Series-A in enterprise SaaS, infrastructure software and consumer tech - scales companies to growth via a proprietary software platform.'),
  ('Great Oaks Venture Capital','greatoaksvc.com','US','New York','New York',
   '뉴욕 활발한 시드 투자사(Stripe·Casper·BuzzFeed). 초기 체크를 빠르게 쓰며 zero-to-one 단계 지원.',
   'Active NYC seed investor (Stripe, Casper, BuzzFeed) - writes early checks and supports the zero-to-one phase.'),
  ('Contour Venture Partners','contourventures.com','US','New York','New York',
   '뉴욕 시드 단계 전문. IT·SaaS(소비자/엔터프라이즈)·B2B·금융서비스. 창업팀과 강한 유대.',
   'NYC seed-stage specialist in IT, SaaS (consumer + enterprise), B2B and financial-services startups - close founder relationships.'),
  ('Primary Venture Partners','primary.vc','US','New York','New York',
   '뉴욕 시드 전문. 엔터프라이즈·소비자. 포트폴리오 지원팀(Primary Expert Network)으로 초기 스케일 지원.',
   'NYC seed specialist across enterprise and consumer - heavy post-investment support via the Primary Expert Network.'),
  ('Base10 Partners','base10.vc','US','San Francisco','California',
   '샌프란시스코 기반. 실물경제 자동화(Real Economy) 초기 투자. Notion·Figma·Stripe 백. 산업/자동화 접점.',
   'San Francisco firm backing early-stage automation of the Real Economy (Notion, Figma, Stripe) - industrial/automation touchpoints.'),
  -- ----- Life science / biotech -----
  ('LifeSci Venture Partners','lifescivp.com','US','New York','New York',
   '뉴욕 생명과학·헬스케어 초기~후기 투자사. 바이오텍 IPO 경로 안내에 강점(Erasca·Caribou Biosciences 상장).',
   'NYC life-science / healthcare early-to-late investor - strong at guiding biotech to IPO (Erasca, Caribou Biosciences).'),
  ('LifeX Ventures','lifexventures.com','US','New York','New York',
   '뉴욕 초기 생명과학 전문. 바이오텍·제약·의료기기·진단·디지털헬스. AI/소프트웨어로 상용화 가속.',
   'NYC early-stage life-science specialist across biotech, pharma, medical devices, diagnostics and digital health - accelerates commercialization with AI/software.'),
  ('Sands Capital Ventures','sandscapital.com','US','San Francisco','California',
   '바이오텍+소프트웨어/데이터 결합 스타트업에 강점. 시드부터 post-IPO까지. 데이터 기반 생명과학 접점.',
   'Backs biotech startups with a software/data component - invests seed through post-IPO. Fit for data-driven life-science plays.'),
  ('SR One','srone.com','US','Redwood City','California',
   '레드우드시티+런던 트랜스애틀랜틱 바이오텍 VC. back-and-build 방식으로 혁신 과학을 신약으로 전환.',
   'Redwood City + London transatlantic biotech VC - a back-and-build approach translating innovative science into medicines.'),
  ('Novo Holdings','novoholdings.dk','US','San Francisco','California',
   'Novo Nordisk Foundation 투자부문(덴마크 본사, SF·보스턴·싱가포르 거점). 전 단계 바이오텍·헬스케어. 장기 자본.',
   'Investment arm of the Novo Nordisk Foundation (Denmark HQ - SF, Boston, Singapore presence) - all-stage biotech/healthcare with long-term capital.')
) as c(party_name, domain, country_code, city, region, intro_ko, intro_en)
where not exists (
  select 1 from app.parties p
  where p.organization_id='b25de8f2-1020-482f-9012-183f63883169'::uuid
    and p.deleted_at is null
    and (
      regexp_replace(lower(btrim(p.party_name)),
        '\s*(,?\s*(inc|llc|l\.?p\.?|ltd|limited|co|corp|corporation|company|ventures?|capital|partners?|management|group|holdings?|fund[s]?)\.?)+\s*$','','g')
      = regexp_replace(lower(btrim(c.party_name)),
        '\s*(,?\s*(inc|llc|l\.?p\.?|ltd|limited|co|corp|corporation|company|ventures?|capital|partners?|management|group|holdings?|fund[s]?)\.?)+\s*$','','g')
      or lower(regexp_replace(regexp_replace(coalesce(p.website,''),'^https?://(www\.)?','',''),'/.*$','')) = lower(c.domain)
    )
);

-- (2) investor_profile for each new firm (priority per firm)
insert into app.investor_profile (organization_id, party_id, priority)
select p.organization_id, p.id,
  case
    when p.party_name in ('Point72 Ventures','True Ventures','Novo Holdings') then 'high'
    else 'medium'
  end
from app.parties p
where p.source='web_research_2026Q3_ca_ny' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- (3) set legacy sector_focus text[] (normalized CODES) per firm, then sync.
-- Deep tech / infra group:
update app.investor_profile ip set sector_focus = array['deep_tech','industrial']
from app.parties p
where p.id=ip.party_id and p.source='web_research_2026Q3_ca_ny'
  and p.party_name in ('Point72 Ventures','True Ventures','645 Ventures',
                       'Great Oaks Venture Capital','Contour Venture Partners',
                       'Primary Venture Partners','Base10 Partners');
-- Life science group:
update app.investor_profile ip set sector_focus = array['life_science']
from app.parties p
where p.id=ip.party_id and p.source='web_research_2026Q3_ca_ny'
  and p.party_name in ('LifeSci Venture Partners','LifeX Ventures',
                       'Sands Capital Ventures','SR One','Novo Holdings');

-- (4) interest_tags (legacy jsonb) mirrors the sectors + a region tag
update app.parties p
set interest_tags = to_jsonb(
  case
    when p.party_name in ('LifeSci Venture Partners','LifeX Ventures','Sands Capital Ventures','SR One','Novo Holdings')
      then array['life_science']
    else array['deep_tech','industrial']
  end),
  updated_at=now()
where p.source='web_research_2026Q3_ca_ny' and p.deleted_at is null;

-- (5) sync normalized layers (sector + interest tags) for each new firm
select app.sync_party_sector_focus(p.id, ip.sector_focus)
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
where p.source='web_research_2026Q3_ca_ny' and p.deleted_at is null;

select app.sync_party_interest_tags(p.id)
from app.parties p
where p.source='web_research_2026Q3_ca_ny' and p.deleted_at is null;

-- (6) VERIFY
select p.party_name, p.city, p.region, ip.priority, ip.sector_focus, p.interest_tags
from app.parties p
left join app.investor_profile ip on ip.party_id=p.id
where p.source='web_research_2026Q3_ca_ny' and p.deleted_at is null
order by p.party_name;
