-- ============================================================
-- Investor expansion -- Wave 4 US Philanthropic / Catalytic Capital (8 firms)
-- Generated 2026-07-04. Run in Supabase SQL Editor (UTF-8).
-- Save WITHOUT BOM. Idempotent (same pattern as waves 2-3).
-- Category note: foundations & foundation-linked investors. Several are
-- grant-first (Bezos Earth Fund) or PRI/mission-investment vehicles.
-- -> Recommend a SEPARATE outreach track (grants/PRI applications, warm
--    intros), NOT the cold email sequence used for VCs.
-- Related entities ALREADY in DB (do not re-add):
--   - Breakthrough Energy Ventures (Bill Gates)  -> wave 3 US
--   - Azolla Ventures (Prime Coalition affiliated)
--   - S2G Ventures (Builders Vision / Walton family)
-- Email addresses intentionally NOT set -> separate enrichment batch.
-- ============================================================

-- (1) INSERT canonical row only when NO matching party exists
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id,
         coalesce((select id from app.entity_types where code = 'fund'),
                  (select id from app.entity_types where code = 'company')) as fund_entity_id
),
firms(party_name, match_pat, country_code, region, city, intro_ko, intro_en) as (
  values
    ('Schmidt Marine Technology Partners', 'Schmidt Marine%', 'US', 'California', 'San Francisco',
     $ko$에릭 슈미트 가문(Schmidt Family Foundation) 산하의 해양기술 전문 지원 조직으로, 해양 건강 문제를 푸는 초기 기술 기업에 그랜트와 투자를 병행 지원한다. mbg의 해양 유래 바이오소재는 핵심 미션과 정확히 부합하며, 재단 계열 중 정합도가 가장 높다.$ko$,
     $en$An ocean technology program of the Schmidt Family Foundation, supporting early stage companies solving ocean health problems with a mix of grants and investments. mbg marine derived biomaterials fit squarely within its core mission, making it the highest fit foundation linked funder.$en$),
    ('Pivotal Ventures', 'Pivotal Ventures%', 'US', 'Washington', 'Seattle',
     $ko$멜린다 프렌치 게이츠가 설립한 투자·인큐베이션 회사로, 여성 건강·펨테크를 포함한 사회 발전 분야에 지분 투자한다. mbg의 인체 친화 바이오소재 생리대 등 Life Science/펨테크 응용과 직접 맞닿아, Advanced Materials보다 Life Science 캠페인 트랙으로 접근하는 것이 적합하다.$ko$,
     $en$An investment and incubation company founded by Melinda French Gates, making equity investments in social progress areas including womens health and femtech. It maps directly to mbg life science and femtech applications such as human friendly biomaterial sanitary products, and is best approached through the Life Science campaign track rather than Advanced Materials.$en$),
    ('Grantham Foundation', 'Grantham Foundation%', 'US', 'Massachusetts', 'Boston',
     $ko$투자가 제레미 그랜섬의 환경 보호 재단으로, 'Neglected Climate Opportunities' 전략을 통해 주류 VC가 놓치는 기후 기술에 직접 지분 투자한다. 탄소집약 소재를 대체하는 mbg 바이오 필러는 이 전략의 전형적 대상이다.$ko$,
     $en$The environmental foundation of investor Jeremy Grantham, making direct equity investments in overlooked climate technologies through its Neglected Climate Opportunities strategy. mbg bio fillers displacing carbon intensive materials are a typical target for this strategy.$en$),
    ('Gates Foundation Strategic Investment Fund', 'Gates Foundation%', 'US', 'Washington', 'Seattle',
     $ko$게이츠 재단의 전략투자 부문으로, 재단 미션(글로벌 헬스·위생·개발)에 부합하는 기업에 PRI(프로그램 연계 투자) 방식의 지분·대출 투자를 한다. mbg의 경우 소재 자체보다 위생용품(생리대 등) 접근성·여성 위생 각도의 Life Science 스토리로 접근해야 하며, 일반 VC 콜드 아웃리치와는 다른 트랙이 필요하다.$ko$,
     $en$The strategic investment arm of the Gates Foundation, making program related equity and debt investments in companies aligned with the foundation mission in global health, sanitation and development. For mbg the entry point is the life science story of sanitary product access and womens hygiene rather than materials, and it requires a different track from VC cold outreach.$en$),
    ('Emerson Collective', 'Emerson Collective%', 'US', 'California', 'Palo Alto',
     $ko$로렌 파월 잡스가 설립한 임팩트 투자·자선 조직으로, 기후·환경 분야에 지분 투자와 그랜트를 병행한다. mbg의 지속가능 소재는 기후 포트폴리오와 접점이 있다.$ko$,
     $en$An impact investment and philanthropy organization founded by Laurene Powell Jobs, combining equity investments and grants in climate and environment. mbg sustainable materials connect with its climate portfolio.$en$),
    ('Autodesk Foundation', 'Autodesk Foundation%', 'US', 'California', 'San Francisco',
     $ko$Autodesk의 재단으로, 지속가능 제조·건축·소재 분야 초기 기업에 그랜트와 임팩트 지분 투자를 병행한다. 설계·제조 소프트웨어 생태계와 연결되며, mbg의 지속가능 소재 제조 스케일업과 접점이 있다.$ko$,
     $en$The foundation of Autodesk, combining grants and impact equity investments in early stage companies across sustainable manufacturing, construction and materials. It connects to the design and manufacturing software ecosystem and touches the mbg sustainable materials manufacturing scale up.$en$),
    ('Prime Coalition', 'Prime Coalition%', 'US', 'Massachusetts', 'Cambridge',
     $ko$자선 자본을 기후 기술 촉매 투자로 전환하는 비영리 투자기관으로, Azolla Ventures(이미 DB 등재) 등의 비히클을 통해 온실가스 감축 잠재력이 큰 초기 기업에 투자한다. 직접 접촉보다 Azolla 트랙과 연계해 관리하는 것이 효율적이다.$ko$,
     $en$A nonprofit investor channeling philanthropic capital into catalytic climate investments, backing early stage companies with large emissions reduction potential through vehicles such as Azolla Ventures, which is already in the database. It is most efficiently managed in connection with the Azolla track rather than separate direct contact.$en$),
    ('Bezos Earth Fund', 'Bezos Earth Fund%', 'US', 'Washington DC', 'Washington',
     $ko$제프 베이조스가 100억 달러를 약정한 기후·자연 분야 자선 펀드로, 지분 투자가 아닌 그랜트 중심이다. 직접 투자 유치 대상은 아니지만, 해양·자연 기반 솔루션 그랜트 프로그램이 mbg의 실증·연구 자금원이 될 수 있다.$ko$,
     $en$A philanthropic fund with a 10 billion dollar commitment from Jeff Bezos for climate and nature, operating primarily through grants rather than equity. It is not an equity target, but its ocean and nature based solution grant programs can be a source of demonstration and research funding for mbg.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, source, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id, i.fund_entity_id, f.country_code, f.region, f.city,
       'web_research_2026Q3_phil', f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike f.match_pat
    and p.organization_id = i.org and p.deleted_at is null
);

-- (2) Ensure investor_profile rows
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.deleted_at is null
  and p.source = 'web_research_2026Q3_phil'
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- (3) Sector focus links (idempotent; organization_id included)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('Schmidt Marine%',      'climate'),
  ('Schmidt Marine%',      'advanced_materials'),
  ('Pivotal Ventures%',    'life_science'),
  ('Pivotal Ventures%',    'consumer'),
  ('Grantham Foundation%', 'climate'),
  ('Grantham Foundation%', 'advanced_materials'),
  ('Gates Foundation%',    'life_science'),
  ('Gates Foundation%',    'healthcare'),
  ('Emerson Collective%',  'climate'),
  ('Autodesk Foundation%', 'climate'),
  ('Autodesk Foundation%', 'industrial'),
  ('Prime Coalition%',     'climate'),
  ('Bezos Earth Fund%',    'climate')
) as m(match_pat, sector_code)
join app.parties p on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike m.match_pat
  and p.deleted_at is null and p.source = 'web_research_2026Q3_phil'
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where not exists (
  select 1 from app.investor_sector_focus f
  where f.investor_profile_id = ip.id and f.sector_id = s.id
);

-- (4a) Priority = high (direct marine / femtech / climate-materials equity fit)
update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and p.source = 'web_research_2026Q3_phil'
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in (
    'Schmidt Marine Technology Partners',
    'Pivotal Ventures',
    'Grantham Foundation'
  );

-- (4b) Priority = medium for the rest of this wave (only if currently null)
update app.investor_profile ip set priority = 'medium', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null and ip.priority is null
  and p.source = 'web_research_2026Q3_phil';

-- (5) OPTIONAL: website backfill, guarded (runs only if column exists)
do $web$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'app' and table_name = 'parties' and column_name = 'website'
  ) then
    update app.parties p set website = w.url, updated_at = now()
    from (values
      ('Schmidt Marine%',      'https://www.schmidtmarine.org'),
      ('Pivotal Ventures%',    'https://www.pivotalventures.org'),
      ('Grantham Foundation%', 'https://www.granthamfoundation.org'),
      ('Gates Foundation%',    'https://www.gatesfoundation.org'),
      ('Emerson Collective%',  'https://www.emersoncollective.com'),
      ('Autodesk Foundation%', 'https://www.autodesk.org'),
      ('Prime Coalition%',     'https://www.primecoalition.org'),
      ('Bezos Earth Fund%',    'https://www.bezosearthfund.org')
    ) as w(match_pat, url)
    where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike w.match_pat
      and p.deleted_at is null and p.source = 'web_research_2026Q3_phil'
      and (p.website is null or btrim(p.website) = '');
  end if;
end
$web$;

-- (6) Verification
select p.party_name, p.region, p.city,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en,
       ip.priority, array_agg(distinct s.label_en order by s.label_en) as sectors
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where p.source = 'web_research_2026Q3_phil' and p.deleted_at is null
group by p.party_name, p.region, p.city, p.intro_ko, p.intro_en, ip.priority
order by ip.priority, p.party_name;

-- Expected: 8 rows (3 high / 5 medium), all with ko+en intros.
