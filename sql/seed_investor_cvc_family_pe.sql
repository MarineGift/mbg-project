-- ============================================================
-- New investor parties: CVC / Family Office / Growth-PE / Endowment & Sovereign
-- Verified 2026-06-15. Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en use dollar-quoting ($ko$...$ko$) so inner quotes never break.
-- NOTE: BASF Venture Capital, JJDC and Eclipse Ventures already exist in DB -> NOT recreated.
-- ============================================================

-- (1) Insert parties (idempotent). entity per firm: 'fund' / 'organization'.
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id
),
firms(party_name, entity_code, country_code, region, city, website, intro_ko, intro_en) as (
  values
    ('Intel Capital', 'fund', 'US', 'California', 'Santa Clara', 'https://www.intelcapital.com', $ko$인텔의 기업형 벤처(CVC) 부문으로 반도체를 넘어 정밀 제조·첨단 소재·딥테크 생태계 전반에 투자해 온 실리콘밸리의 대표적 CVC다. 공정 수율 향상과 원가 절감형 기술을 선호한다. mbg의 마이크로 충전제 공정 혁신·제조 효율 측면에서 접점이 있다.$ko$, $en$Intel corporate venture arm and one of the most established Silicon Valley CVCs, investing beyond semiconductors across precision manufacturing, advanced materials and the broader deep tech ecosystem, with a preference for yield improving and cost reducing technologies. There is overlap with the mbg micro filler process innovation and manufacturing efficiency.$en$),
    ('Dow Venture Capital', 'fund', 'US', NULL, NULL, 'https://corporate.dow.com/en-us/collaborations/venture-capital.html', $ko$세계적 소재과학 기업 Dow의 기업형 벤처 부문으로, Dow의 사업 성장과 가치를 가속하는 전략적 스타트업에 투자하고 회사 역량·자원을 적극 투입한다. 지속가능 플라스틱 대체재·패키징 혁신과 시너지가 크다. 기존 종이/제지 가치사슬을 혁신하는 mbg 소재와 직접적 전략 적합성이 높다.$ko$, $en$The corporate venture arm of Dow, a global materials science company, making strategic investments in startups that accelerate Dow business growth and actively deploying Dow capabilities and resources. It has strong synergy with sustainable plastic alternatives and packaging innovation, and a high strategic fit with mbg materials that transform the paper and pulp value chain.$en$),
    ('Capricorn Investment Group', 'fund', 'US', 'California', 'Palo Alto', 'https://www.capricornllc.com', $ko$이베이 초대 회장 Jeff Skoll의 자금에서 출발한 팔로알토 멀티 패밀리 오피스 겸 임팩트 투자사로, Technology Impact/Growth 펀드를 통해 기후 솔루션 딥테크에 투자한다. Tesla·QuantumScape 등 하드테크·첨단 소재의 압도적 이력을 보유한다. 플라스틱을 대체하는 탄소·폐기물 저감 사업인 mbg에 매력을 느낄 인내 자본이다.$ko$, $en$A Palo Alto multi family office and impact investor that grew from the capital of Jeff Skoll, eBay first president, investing in deep technology climate solutions through its Technology Impact and Growth funds. It has a strong hard tech and advanced materials track record including Tesla and QuantumScape. As patient capital it is well suited to mbg, a plastic replacing business that cuts carbon and waste.$en$),
    ('Emerson Collective', 'organization', 'US', 'California', 'Palo Alto', 'https://www.emersoncollective.com', $ko$스티브 잡스의 아내 Laurene Powell Jobs가 2011년 설립한 투자·자선 조직(팔로알토)으로, 벤처 투자 부문은 환경·에너지와 기후 딥테크에 집중한다. 플라스틱 대체·환경 임팩트를 핵심으로 하는 mbg와 가치 정렬이 좋다.$ko$, $en$An investment and philanthropy organization founded in 2011 by Laurene Powell Jobs in Palo Alto, whose venture arm focuses on environment, energy and climate deep tech. It is well aligned in values with mbg, whose core is plastic replacement and environmental impact.$en$),
    ('ICONIQ Capital', 'fund', 'US', 'California', 'San Francisco', 'https://www.iconiqcapital.com', $ko$Mark Zuckerberg 등 실리콘밸리 거물들의 자금을 운용하는 멀티 패밀리 오피스(2011)로 약 800억 달러를 운용한다. ICONIQ Growth를 통해 주로 엔터프라이즈 소프트웨어 등 그로스 단계 기술기업에 직접 투자한다(소재 직접 적합도는 제한적). 후기 성장 자본과 강력한 네트워크 측면에서 참고 대상이다.$ko$, $en$A multi family office founded in 2011 managing capital for prominent Silicon Valley leaders including Mark Zuckerberg, with about 80 billion dollars in assets. Through ICONIQ Growth it invests directly in growth stage technology companies, mainly enterprise software (direct materials fit is limited). It is a reference for later stage growth capital and a strong network.$en$),
    ('G2 Venture Partners', 'fund', 'US', 'California', 'Portola Valley', 'https://g2vp.com', $ko$Kleiner Perkins(KPCB)의 클린테크 팀이 독립해 만든 그로스 에쿼티 펀드(포르톨라 밸리)로, 운송·물류·제조·농업·에너지 등 전통 산업을 기술로 지속가능하게 탈바꿈하는 성장기 기업에 투자한다(포트폴리오: Carbon 3D 프린팅 등). 제지·소재 등 전통 산업 가치사슬을 혁신하는 mbg와 정합성이 높다.$ko$, $en$A growth equity fund spun out of the Kleiner Perkins cleantech team (Portola Valley) that invests in growth stage companies making traditional industries such as transportation, logistics, manufacturing, agriculture and energy more sustainable (portfolio includes Carbon 3D printing). It fits well with mbg, which transforms traditional industry value chains such as paper and materials.$en$),
    ('Generation Investment Management', 'fund', 'GB', NULL, 'London', 'https://www.generationim.com', $ko$앨 고어 전 미국 부통령이 공동 설립한 지속가능성 특화 투자사(런던/샌프란시스코)로, 성장기 딥테크·친환경 제조 기업에 장기 자본을 투입한다. 탈탄소·지속가능 소재 관점에서 mbg와 방향성이 맞는다.$ko$, $en$A sustainability focused investment firm co founded by former US Vice President Al Gore (London and San Francisco) that provides long term capital to growth stage deep tech and sustainable manufacturing companies. It aligns with mbg on decarbonization and sustainable materials.$en$),
    ('Temasek', 'fund', 'SG', NULL, 'Singapore', 'https://www.temasek.com.sg', $ko$싱가포르 국부형 투자회사(1974, 포트폴리오 약 2,900억 달러)로, LP이자 직접 투자자로서 생명과학·첨단 소재·소비재 등에 대형 라운드를 주도한다. 화장품·생리대 등 소비재 밸류체인을 아시아·글로벌로 확장할 때 최상급 앵커 투자자가 될 수 있다.$ko$, $en$A Singapore state owned investment company (founded 1974, portfolio about 290 billion dollars) that acts as both an LP and a direct investor and leads large rounds in life sciences, advanced materials and consumer sectors. It can be a top anchor investor when expanding the cosmetics and personal care consumer value chain across Asia and globally.$en$),
    ('GIC', 'fund', 'SG', NULL, 'Singapore', 'https://www.gic.com.sg', $ko$싱가포르 정부의 준비금을 운용하는 국부펀드(1981)로 글로벌 다자산에 투자하며 넷제로 전환을 적극 지원한다. 첨단 소재·생명과학 생태계가 Series B 이상으로 성장할 때 대형 직접 공동투자 파트너가 될 수 있다.$ko$, $en$A sovereign wealth fund (founded 1981) that manages the Singapore government reserves across global multi asset portfolios and actively supports the net zero transition. It can be a large direct co investment partner as advanced materials and life science companies grow beyond Series B.$en$),
    ('UC Investments', 'organization', 'US', 'California', 'Oakland', NULL, $ko$캘리포니아 대학교(UC)의 투자 운용 조직으로 기금·연금 자산을 운용하며, 최근 기후 테크·딥테크 직접 투자 비중을 빠르게 늘리고 있다. 통상 VC 펀드의 LP로 참여하지만 성장 단계에서 직접 공동투자도 한다.$ko$, $en$The investment office of the University of California, managing its endowment and pension assets and rapidly increasing direct allocations to climate tech and deep tech. It usually participates as an LP in venture funds but also co invests directly at growth stages.$en$),
    ('Stanford Management Company (SMC)', 'organization', 'US', 'California', 'Stanford', 'https://www.smc.stanford.edu', $ko$스탠퍼드 대학 기금을 운용하는 조직(SMC)으로 실리콘밸리 딥테크·신소재 생태계의 근간을 이루는 자본이다. 우수한 특허·원천기술을 가진 딥테크 기업이 스탠퍼드 관련 네트워크 펀드와 연결될 경우 간접적 지원 가능성이 있다.$ko$, $en$The organization that manages the Stanford University endowment (SMC), a foundational source of capital for the Silicon Valley deep tech and advanced materials ecosystem. Deep tech companies with strong patents and core technology may gain indirect support when connected to Stanford affiliated network funds.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, website, source, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id,
       coalesce((select id from app.entity_types et where et.code = f.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       f.country_code, f.region, f.city, f.website, 'manual_cvc_2026Q2', f.intro_ko, f.intro_en
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
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Intel Capital', 'Dow Venture Capital', 'Capricorn Investment Group', 'Emerson Collective', 'ICONIQ Capital', 'G2 Venture Partners', 'Generation Investment Management', 'Temasek', 'GIC', 'UC Investments', 'Stanford Management Company (SMC)')
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (3) Sector focus links (includes organization_id - NOT NULL)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('Intel Capital', 'deep_tech'),
  ('Intel Capital', 'advanced_materials'),
  ('Dow Venture Capital', 'advanced_materials'),
  ('Dow Venture Capital', 'industrial'),
  ('Dow Venture Capital', 'climate'),
  ('Capricorn Investment Group', 'climate'),
  ('Capricorn Investment Group', 'advanced_materials'),
  ('Capricorn Investment Group', 'deep_tech'),
  ('Emerson Collective', 'climate'),
  ('Emerson Collective', 'deep_tech'),
  ('ICONIQ Capital', 'enterprise'),
  ('ICONIQ Capital', 'deep_tech'),
  ('G2 Venture Partners', 'climate'),
  ('G2 Venture Partners', 'industrial'),
  ('G2 Venture Partners', 'advanced_materials'),
  ('Generation Investment Management', 'climate'),
  ('Generation Investment Management', 'deep_tech'),
  ('Temasek', 'life_science'),
  ('Temasek', 'advanced_materials'),
  ('Temasek', 'consumer'),
  ('GIC', 'life_science'),
  ('GIC', 'advanced_materials'),
  ('UC Investments', 'climate'),
  ('UC Investments', 'deep_tech'),
  ('Stanford Management Company (SMC)', 'deep_tech'),
  ('Stanford Management Company (SMC)', 'advanced_materials')
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
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Dow Venture Capital', 'Capricorn Investment Group', 'G2 Venture Partners', 'Temasek');

-- (5) Verification
select p.party_name, p.country_code, p.city, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en, ip.priority,
       array_agg(s.label_en order by s.label_en) as sectors
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('Intel Capital', 'Dow Venture Capital', 'Capricorn Investment Group', 'Emerson Collective', 'ICONIQ Capital', 'G2 Venture Partners', 'Generation Investment Management', 'Temasek', 'GIC', 'UC Investments', 'Stanford Management Company (SMC)')
group by p.party_name, p.country_code, p.city, p.website, p.intro_ko, p.intro_en, ip.priority
order by p.party_name;
