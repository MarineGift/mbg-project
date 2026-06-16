-- ============================================================
-- New investor parties: large PE funds (verified 2026-06-15)
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. Idempotent.
-- intro_ko/intro_en use dollar-quoting ($ko$...$ko$) so inner quotes never break.
-- ============================================================

-- (1) Insert the 4 parties (idempotent: skip if same name already exists in this org)
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types  where code = 'investor'), 1) as investor_type_id,
         coalesce((select id from app.entity_types where code = 'fund'),
                  (select id from app.entity_types where code = 'company')) as fund_entity_id
),
firms(party_name, country_code, website, intro_ko, intro_en) as (
  values
    ('TPG Rise Climate', 'US', 'https://www.tpg.com/platforms/impact/rise-climate', $ko$TPG의 기후 전용 PE 전략(임팩트 플랫폼 TPG Rise 산하)으로, 1호 펀드를 약 73억 달러에 마감했고 'clean electrons / clean molecules and materials / 탄소 저감'을 핵심 테마로 한다. 탄소·폐기물을 실질적으로 줄이는 지속가능 소재·양산 기업에 대규모 자본을 집행하며, 28개 글로벌 기업이 참여한 연합 LP 네트워크를 통해 대형 고객 연결이 가능하다. mbg의 펄프·플라스틱 사용량 저감 원천기술의 양산 스케일업과 탈탄소 효과에 정합한다.$ko$, $en$TPG dedicated climate private equity strategy under the TPG Rise impact platform; its first fund closed at about 7.3 billion dollars with core themes of clean electrons, clean molecules and materials, and carbon reduction. It deploys large scale capital into sustainable materials and scale up manufacturers that measurably cut carbon and waste, and its coalition of 28 global corporate LPs can connect portfolio companies to major customers. This aligns with mbg core technology that reduces pulp and plastic use and with its decarbonization impact.$en$),
    ('KKR Global Impact Fund', 'US', 'https://www.kkr.com/invest/global-impact', $ko$KKR이 약 13억 달러 규모로 운용하는 임팩트 PE로, UN SDGs에 기여하는 상업적 솔루션에 투자한다. 이탈리아 CMC Machinery(3D 온디맨드 포장으로 종이 박스와 완충재 사용을 크게 줄이는 기술)에 투자한 이력이 있어, 펄프·플라스틱·필러 저감이라는 mbg의 가치제안과 정확히 일치한다. 텍사스 대규모 양산(CapEx)과 글로벌 제지사 공급망 확장 시 KKR의 운영 효율화·글로벌 스케일업 플레이북이 강점이다.$ko$, $en$An impact private equity fund of about 1.3 billion dollars run by KKR, investing in commercial solutions that advance the UN SDGs. It backed CMC Machinery in Italy, whose 3D on demand packaging sharply reduces both box and void filler use, which matches the mbg value proposition of cutting pulp, plastic and filler. Its operational improvement and global scale up playbook fits mbg plans for large scale Texas manufacturing and expansion into global paper supply chains.$en$),
    ('L Catterton', 'US', 'https://www.lcatterton.com', $ko$LVMH·Groupe Arnault와 연계된(약 40% 지분) 세계 최대 소비재 전문 PE로 운용자산 약 340~400억 달러 규모이며 뷰티·퍼스널케어·식음료·패션 등에 투자한다(뷰티 사례: Kiko Milano). mbg 신소재 기반 화장품·생리대 완제품(OEM)이 갖춰지면 L Catterton의 글로벌 뷰티/소비재 밸류체인을 통해 북미 프리미엄 시장 진입·스케일업이 가능하다.$ko$, $en$The worlds largest consumer focused private equity firm, tied to LVMH and Groupe Arnault who together own about 40 percent, with roughly 34 to 40 billion dollars in assets across beauty and personal care, food and beverage, fashion and more (beauty example: Kiko Milano). Once mbg has finished cosmetic and personal care products, the L Catterton global consumer value chain can drive entry and scale up in the North American premium market.$en$),
    ('Sycamore Partners', 'US', 'https://www.sycamorepartners.com', $ko$약 100억 달러 이상을 운용하는 뉴욕 기반 소비재·리테일·유통 전문 PE로, 운영 개선과 카브아웃·턴어라운드를 통해 브랜드 가치를 높인다(포트폴리오: Staples, Talbots, Hot Topic, Walgreens Boots Alliance 등). mbg 완제품이 미국 시장에서 초기 매출 궤도에 오르면 전국 오프라인 유통·물류 확장 단계의 재무 스폰서로 적합하다.$ko$, $en$A New York based private equity firm with over 10 billion dollars focused on consumer, retail and distribution, raising brand value through operational improvement, carve outs and turnarounds (portfolio includes Staples, Talbots, Hot Topic and Walgreens Boots Alliance). Once mbg finished products reach early sales traction in the US, it is a suitable financial sponsor for the national retail distribution and logistics expansion stage.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, website, source, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id, i.fund_entity_id, f.country_code, f.website,
       'manual_pe_2026Q2', f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = f.party_name
    and p.organization_id = i.org and p.deleted_at is null
);

-- (2) Ensure an investor_profile row exists for each (priority defaults to 'medium')
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.party_type_id = coalesce((select id from app.party_types where code = 'investor'), 1)
  and p.deleted_at is null
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in
      ('TPG Rise Climate', 'KKR Global Impact Fund', 'L Catterton', 'Sycamore Partners')
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (3) Sector focus links (includes organization_id - NOT NULL)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('TPG Rise Climate', 'advanced_materials'),
  ('TPG Rise Climate', 'climate'),
  ('TPG Rise Climate', 'industrial'),
  ('KKR Global Impact Fund', 'advanced_materials'),
  ('KKR Global Impact Fund', 'climate'),
  ('KKR Global Impact Fund', 'industrial'),
  ('L Catterton', 'consumer'),
  ('Sycamore Partners', 'consumer')
) as m(party_name, sector_code)
join app.parties p on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') = m.party_name and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where not exists (
  select 1 from app.investor_sector_focus f where f.investor_profile_id = ip.id and f.sector_id = s.id
);

-- (4) Priority = high for the strongest-fit funds (Sycamore stays medium)
update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in ('TPG Rise Climate', 'KKR Global Impact Fund', 'L Catterton');

-- (5) Verification
select p.party_name, p.country_code, p.website is not null as has_web,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en, ip.priority,
       array_agg(s.label_en order by s.label_en) as sectors
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in
      ('TPG Rise Climate', 'KKR Global Impact Fund', 'L Catterton', 'Sycamore Partners')
group by p.party_name, p.country_code, p.website, p.intro_ko, p.intro_en, ip.priority
order by p.party_name;
