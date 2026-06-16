-- ============================================================
-- New investor parties: Austin-based firms (verified 2026-06-15)
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en use dollar-quoting ($ko$...$ko$) so inner quotes never break.
-- 8VC and S3 Ventures already exist in DB and are intentionally NOT recreated here.
-- ============================================================

-- (1) Insert parties (idempotent). entity per firm: 'fund' / 'organization'.
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id
),
firms(party_name, entity_code, website, intro_ko, intro_en) as (
  values
    ('Mithril Capital', 'fund', 'https://www.mithril.com', $ko$페이팔/팰런티어 공동창업자 피터 틸과 Ajay Royan이 2012년 설립한 장기 성장투자 펀드로, 2019년 본사를 오스틴으로 이전했다. 섹터 불문하고 기술로 '오랫동안 변화가 없던 산업'을 근본 혁신하는 기업을 큰 확신으로 스케일업한다. mbg의 펄프 기반 제지 레거시 산업을 원가절감 충전제로 혁신하는 딥테크·하드사이언스 해자와 결이 맞는다.$ko$, $en$A long term growth investment firm founded in 2012 by Peter Thiel and Ajay Royan, relocated to Austin in 2019. It backs, with high conviction and a sector agnostic focus, teams that use technology to transform industries long overdue for change. This fits the mbg deep tech and hard science moat that reinvents the legacy pulp based paper industry with cost saving functional filler.$en$),
    ('True Wealth Ventures', 'fund', 'https://truewealthvc.com', $ko$오스틴 기반의 시드 단계 펀드(Sara Brand·Kerry Rupp)로, '환경 건강'과 '인체 건강'을 측정 가능하게 개선하는 기업에 투자하며 창업·경영진에 여성이 포함된 회사에 집중한다(AUM 약 6천만 달러, 포트폴리오에 켈프 생산사 Atlantic Sea Farms 등). 미세플라스틱 대체 친환경 소재를 화장품·생리대 등 소비재에 적용하는 mbg의 방향성과 매우 강하게 일치한다.$ko$, $en$An Austin based seed stage fund led by Sara Brand and Kerry Rupp that invests in companies measurably improving environmental or human health, focused on teams with a woman in a founding or executive role (about 60 million dollars in assets; portfolio includes kelp producer Atlantic Sea Farms). It aligns very strongly with mbg, which applies plastic replacing sustainable materials to consumer products such as cosmetics and sanitary pads.$en$),
    ('Next Coast Ventures', 'fund', 'https://www.nextcoastventures.com', $ko$오스틴 기반 벤처사(2016 설립, AUM 약 2.65억 달러)로 비연안(next coast) 시장의 고성장 스타트업을 하이퍼그로스로 끌어올리는 데 집중하며 창업자 운영 지원이 강점이다. mbg의 로열티 기반 고마진 플랫폼과 자체 D2C 브랜드를 결합한 하이브리드 모델 스케일업에 적합한 파트너다.$ko$, $en$An Austin based venture firm (founded 2016, about 265 million dollars in assets) focused on driving high growth startups in non coastal markets into hypergrowth, with strong founder operating support. It is a fit for scaling the mbg hybrid model of a high margin royalty platform plus its own direct to consumer brands.$en$),
    ('ATX Venture Partners', 'fund', NULL, $ko$오스틴 기반 초기 단계 벤처사(2014 설립)로 B2B 소프트웨어·프론티어 테크·마켓플레이스와 공급망/제조 분야에 투자하며 텍사스 내 네트워크가 강하다. mbg의 B2B 공급망 혁신과 텍사스 제조 인프라 연계 측면에서 접점이 있다.$ko$, $en$An Austin based early stage venture firm (founded 2014) investing across B2B software, frontier tech and marketplaces as well as supply chain and manufacturing, with a strong Texas network. There is overlap with mbg on B2B supply chain innovation and Texas manufacturing connections.$en$),
    ('Central Texas Angel Network (CTAN)', 'organization', NULL, $ko$미국에서 가장 활발한 엔젤 투자 네트워크 중 하나(오스틴 기반, 200여 개 이상 포트폴리오)로 텍사스 스타트업에 초기 자본·멘토십을 제공한다. 텍사스 에너지·제조·화학 분야 전직 경영진이 다수 포진해, 브릿지 라운드나 대형 VC 이전 단계에서 주정부·공장 부지 네트워크 연결에 유용한 로컬 우군이다.$ko$, $en$One of the most active angel networks in the United States (Austin based, more than 200 portfolio companies), providing early capital and mentorship to Texas startups. With many former executives from Texas energy, manufacturing and chemicals, it is a useful local ally for bridge rounds and for connecting to state government and factory site networks ahead of larger venture rounds.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id,
       coalesce((select id from app.entity_types et where et.code = f.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       'US', 'Texas', 'Austin', f.website, 'manual_austin_2026Q2', f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = f.party_name
    and p.organization_id = i.org and p.deleted_at is null
);

-- (2) Ensure investor_profile rows (priority defaults to 'medium')
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.party_type_id = coalesce((select id from app.party_types where code = 'investor'), 1)
  and p.deleted_at is null
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Mithril Capital', 'True Wealth Ventures', 'Next Coast Ventures', 'ATX Venture Partners', 'Central Texas Angel Network (CTAN)')
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (3) Sector focus links (includes organization_id - NOT NULL)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('Mithril Capital', 'deep_tech'),
  ('Mithril Capital', 'advanced_materials'),
  ('True Wealth Ventures', 'climate'),
  ('True Wealth Ventures', 'consumer'),
  ('Next Coast Ventures', 'consumer'),
  ('ATX Venture Partners', 'deep_tech'),
  ('ATX Venture Partners', 'industrial'),
  ('Central Texas Angel Network (CTAN)', 'advanced_materials'),
  ('Central Texas Angel Network (CTAN)', 'industrial')
) as m(party_name, sector_code)
join app.parties p on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = m.party_name and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where not exists (
  select 1 from app.investor_sector_focus f where f.investor_profile_id = ip.id and f.sector_id = s.id
);

-- (4) Priority = high for strongest-fit (others stay medium)
update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Mithril Capital', 'True Wealth Ventures');

-- (5) Verification
select p.party_name, p.city, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en, ip.priority,
       array_agg(s.label_en order by s.label_en) as sectors
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Mithril Capital', 'True Wealth Ventures', 'Next Coast Ventures', 'ATX Venture Partners', 'Central Texas Angel Network (CTAN)')
group by p.party_name, p.city, p.website, p.intro_ko, p.intro_en, ip.priority
order by p.party_name;
