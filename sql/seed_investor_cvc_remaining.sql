-- ============================================================
-- Remaining 3 from CVC doc: BASF Venture Capital, JJDC, Eclipse Ventures
-- Verified 2026-06-15. These likely ALREADY exist in DB (prior batches / enrichment),
-- so this script is a safe idempotent BACKFILL:
--   - INSERT only if no matching party exists (ILIKE, tolerant of name variants)
--   - intro backfilled ONLY where currently null (never overwrites existing intros)
--   - investor_profile / sector focus ensured (NOT EXISTS), organization_id included
--   - priority set high for BASF/Eclipse; JJDC set medium only if currently null
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. dollar-quoted intros.
-- ============================================================

-- (1) INSERT canonical row only when NO matching party exists (variant-tolerant)
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id,
         coalesce((select id from app.entity_types where code = 'fund'),
                  (select id from app.entity_types where code = 'company')) as fund_entity_id
),
firms(party_name, match_pat, country_code, city, intro_ko, intro_en) as (
  values
    ('BASF Venture Capital', 'BASF%Venture%', 'US', 'San Francisco', $ko$세계 최대 화학기업 BASF의 기업형 벤처(BASF Venture Capital GmbH)로, CO2 저감·순환경제·신소재·바이오테크·디지털을 핵심 투자 영역으로 한다(포트폴리오: Lactips 단백질 기반 플라스틱 대체, DePoly 폴리에스터 재활용, Oceanworks 등). 기술·시장 검증 이후 단계에 투자한다. mbg의 펄프 기반 마이크로 충전제 공정 혁신을 글로벌 화학·소재 공급망에 편입시킬 수 있는 강력한 전략 파트너다.$ko$, $en$The corporate venture arm of BASF, the worlds largest chemical company, with core focus areas of CO2 reduction, circular economy, new materials, biotechnology and digital (portfolio includes Lactips protein based plastic alternatives, DePoly polyester recycling and Oceanworks). It invests after technological and market proof of concept. It is a strong strategic partner for bringing the mbg pulp based micro filler process innovation into the global chemical and materials supply chain.$en$),
    ('Johnson & Johnson Innovation - JJDC', '%JJDC%', 'US', NULL, $ko$Johnson & Johnson의 전략적 벤처캐피탈(JJDC, 1973년 설립, 매사추세츠 케임브리지)로 제약·의료기기·헬스케어 전반에 전 단계로 투자하며 J&J의 글로벌 역량(연구·임상·규제·제조)을 적극 지원한다. 인체 친화적 바이오 소재(생리대·화장품 등 Life Science/Femtech) 상용화를 위한 독점 공급·공동 R&D 측면에서 의미가 있다(다만 소비자건강 부문은 2023년 Kenvue로 분사되어 현재 범위는 헬스케어 중심).$ko$, $en$The strategic venture capital arm of Johnson and Johnson (JJDC, founded 1973, Cambridge Massachusetts) that invests across pharmaceuticals, medical devices and healthcare at all stages and actively deploys the global Johnson and Johnson capabilities in discovery, clinical, regulatory and manufacturing. It is meaningful for exclusive supply and joint R and D around human friendly bio materials for life science and femtech applications such as sanitary products and cosmetics, although the consumer health unit was spun off as Kenvue in 2023 and its current scope is healthcare centric.$en$),
    ('Eclipse Ventures', 'Eclipse Ventures%', 'US', 'Palo Alto', $ko$팔로알토 기반의 투자사로 '물리적 세계(Physical World)의 혁신', 즉 하드웨어·제조·공급망 딥테크 기업에 집중 투자한다(VC와 PE의 중간 성격). 텍사스 양산 공장 설립과 산업용 충전제 제조망 스케일업에 필요한 운영·제조 인프라 최적화 노하우가 강점이다.$ko$, $en$A Palo Alto based investor focused on innovation in the physical world, meaning hardware, manufacturing and supply chain deep tech companies, with a profile between venture capital and private equity. Its strength is operational and manufacturing infrastructure optimization, well suited to building a Texas production plant and scaling an industrial filler manufacturing network.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, city, source, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id, i.fund_entity_id, f.country_code, f.city,
       'manual_cvc_2026Q2', f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike f.match_pat
    and p.organization_id = i.org and p.deleted_at is null
);

-- (2) Backfill intro ONLY where currently null (preserves existing intros)
update app.parties p set intro_ko = f.intro_ko, intro_en = f.intro_en, updated_at = now()
from (values
  ('BASF%Venture%', $ko$세계 최대 화학기업 BASF의 기업형 벤처(BASF Venture Capital GmbH)로, CO2 저감·순환경제·신소재·바이오테크·디지털을 핵심 투자 영역으로 한다(포트폴리오: Lactips 단백질 기반 플라스틱 대체, DePoly 폴리에스터 재활용, Oceanworks 등). 기술·시장 검증 이후 단계에 투자한다. mbg의 펄프 기반 마이크로 충전제 공정 혁신을 글로벌 화학·소재 공급망에 편입시킬 수 있는 강력한 전략 파트너다.$ko$, $en$The corporate venture arm of BASF, the worlds largest chemical company, with core focus areas of CO2 reduction, circular economy, new materials, biotechnology and digital (portfolio includes Lactips protein based plastic alternatives, DePoly polyester recycling and Oceanworks). It invests after technological and market proof of concept. It is a strong strategic partner for bringing the mbg pulp based micro filler process innovation into the global chemical and materials supply chain.$en$),
  ('%JJDC%', $ko$Johnson & Johnson의 전략적 벤처캐피탈(JJDC, 1973년 설립, 매사추세츠 케임브리지)로 제약·의료기기·헬스케어 전반에 전 단계로 투자하며 J&J의 글로벌 역량(연구·임상·규제·제조)을 적극 지원한다. 인체 친화적 바이오 소재(생리대·화장품 등 Life Science/Femtech) 상용화를 위한 독점 공급·공동 R&D 측면에서 의미가 있다(다만 소비자건강 부문은 2023년 Kenvue로 분사되어 현재 범위는 헬스케어 중심).$ko$, $en$The strategic venture capital arm of Johnson and Johnson (JJDC, founded 1973, Cambridge Massachusetts) that invests across pharmaceuticals, medical devices and healthcare at all stages and actively deploys the global Johnson and Johnson capabilities in discovery, clinical, regulatory and manufacturing. It is meaningful for exclusive supply and joint R and D around human friendly bio materials for life science and femtech applications such as sanitary products and cosmetics, although the consumer health unit was spun off as Kenvue in 2023 and its current scope is healthcare centric.$en$),
  ('Eclipse Ventures%', $ko$팔로알토 기반의 투자사로 '물리적 세계(Physical World)의 혁신', 즉 하드웨어·제조·공급망 딥테크 기업에 집중 투자한다(VC와 PE의 중간 성격). 텍사스 양산 공장 설립과 산업용 충전제 제조망 스케일업에 필요한 운영·제조 인프라 최적화 노하우가 강점이다.$ko$, $en$A Palo Alto based investor focused on innovation in the physical world, meaning hardware, manufacturing and supply chain deep tech companies, with a profile between venture capital and private equity. Its strength is operational and manufacturing infrastructure optimization, well suited to building a Texas production plant and scaling an industrial filler manufacturing network.$en$)
) as f(match_pat, intro_ko, intro_en)
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike f.match_pat
  and p.deleted_at is null and (p.intro_ko is null or p.intro_en is null);

-- (3) Ensure investor_profile rows
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.deleted_at is null
  and (coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'BASF%Venture%' or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike '%JJDC%' or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Eclipse Ventures%')
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (4) Sector focus links (idempotent; organization_id included)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('BASF%Venture%', 'advanced_materials'),
  ('BASF%Venture%', 'climate'),
  ('BASF%Venture%', 'industrial'),
  ('%JJDC%', 'life_science'),
  ('%JJDC%', 'healthcare'),
  ('%JJDC%', 'consumer'),
  ('Eclipse Ventures%', 'deep_tech'),
  ('Eclipse Ventures%', 'industrial'),
  ('Eclipse Ventures%', 'advanced_materials')
) as m(match_pat, sector_code)
join app.parties p on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike m.match_pat and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where not exists (
  select 1 from app.investor_sector_focus f where f.investor_profile_id = ip.id and f.sector_id = s.id
);

-- (5a) Priority = high for BASF / Eclipse (idempotent)
update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and (coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'BASF%Venture%' or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Eclipse Ventures%');

-- (5b) Priority = medium for JJDC ONLY if currently null (no downgrade)
update app.investor_profile ip set priority = 'medium', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null and ip.priority is null
  and (coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike '%JJDC%');

-- (6) Verification
select p.party_name, p.country_code, (p.intro_ko is not null) as ko, (p.intro_en is not null) as en,
       ip.priority, array_agg(s.label_en order by s.label_en) as sectors
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'BASF%Venture%' or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike '%JJDC%' or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Eclipse Ventures%'
group by p.party_name, p.country_code, p.intro_ko, p.intro_en, ip.priority
order by p.party_name;
