-- ============================================================
-- Investor Introduction seed -- Advanced Materials sector
-- Generated 2026-06-15. Run in Supabase SQL Editor (UTF-8).
-- Save WITHOUT BOM. Idempotent (UPDATE only). Self-resolving name join.
-- Source: investor homepages + web research (verified). intro_en is ASCII-only.
-- Note: 'Chevron Technology Ventures' already had an intro and is intentionally excluded.
-- ============================================================

-- (1) Fill intro_ko / intro_en
update app.parties p
set intro_ko = d.ko, intro_en = d.en
from (values
  ('3M Ventures', '3M의 기업형 벤처 투자 부문으로, 접착·코팅·필름·부직포 등 3M의 소재 플랫폼과 연결되는 advanced materials 스타트업에 투자한다. mbg의 해양 바이오소재 기능성 필러는 종이·포장·코팅용 첨가제로서 3M 소재 사업과 응용 접점이 크다.', '3M corporate venture arm, investing in advanced materials startups that connect to 3M platforms such as adhesives, coatings, films and nonwovens. mbg marine biomaterial fillers map well to 3M interests in coatings and paper or packaging additives.'),
  ('ARCH Venture Partners', '대학·국립연구소 발 deep science 및 바이오 원천기술 회사를 초기부터 키우는 대표적 벤처사다. mbg의 해양 바이오소재 플랫폼처럼 과학 기반 advanced materials 기회와 결이 맞는다.', 'A leading venture firm building deep science and biotech companies spun out of universities and national labs from inception. mbg as a science based marine biomaterials platform fits its appetite for breakthrough advanced materials.'),
  ('Amazon Climate Pledge Fund', '아마존의 지속가능 기술 투자 펀드로, 탄소중립과 순환경제(포장재 포함) 분야에 투자한다. mbg의 바이오 기반 필러·지속가능 포장 소재는 펀드의 탈탄소·포장 혁신 테마와 연결된다.', 'Amazon sustainability fund investing in decarbonization and circular economy areas including packaging. mbg bio based fillers and sustainable packaging materials align with its decarbonization and packaging innovation themes.'),
  ('Anzu Partners', '약 10억 달러 규모의 산업기술·소재과학 deep tech 전문 투자사로, 기술 전문 인력이 대부분의 라운드를 리드한다. mbg의 해양 유래 advanced materials는 Anzu의 소재과학·산업기술 핵심 테제에 정확히 부합한다.', 'A deep tech firm with about 1 billion dollars in assets focused on industrial technology and materials science, leading most of the rounds it joins. mbg marine derived advanced materials sit squarely within its materials science and industrial thesis.'),
  ('Applied Ventures', 'Applied Materials의 벤처 투자 부문으로, 소재·공정·제조 장비 영역의 초기 기업에 투자한다. mbg의 소재 원천기술과 제조 스케일업 측면에서 전략적 접점이 있다.', 'The venture arm of Applied Materials, investing in early stage companies across materials, process and manufacturing equipment. There are strategic touchpoints with mbg core materials technology and manufacturing scale up.'),
  ('Ara Partners', '산업 탈탄소화에 집중하는 사모·성장 투자사로, 화학·소재·제조 분야의 저탄소 전환을 지원한다. mbg의 바이오 기반 소재는 화석 원료 대체라는 Ara의 산업 탈탄소 테마와 맞는다.', 'A private equity and growth firm focused on industrial decarbonization across chemicals, materials and manufacturing. mbg bio based materials match its theme of replacing fossil derived inputs.'),
  ('At One Ventures', '자연과 인간 번영의 양립을 목표로 하는 deep tech 투자사로, 자원 효율·소재 혁신 기업에 투자한다. mbg의 해양 바이오소재는 환경 부하를 낮추는 nature-positive 소재로서 At One의 테제에 부합한다.', 'A deep tech firm aiming to make humanity a net positive to nature, backing resource efficiency and materials innovation. mbg marine biomaterials are a nature positive material that matches the At One thesis.'),
  ('Azolla Ventures', '촉매적 기후 임팩트 자본을 운용하는 초기 투자사(Prime Coalition 연계)로, 온실가스 감축 잠재력이 큰 기술에 투자한다. mbg의 바이오 기반 소재가 탄소집약 소재를 대체하는 점에서 임팩트 적합성이 있다.', 'An early stage climate fund deploying catalytic impact capital, backing technologies with large emissions reduction potential. mbg bio based materials can displace carbon intensive materials, giving a clear impact fit.'),
  ('BASF Venture Capital', '세계 최대 화학기업 BASF의 CVC로, 화학·소재·지속가능 솔루션 분야 스타트업에 전략 투자한다. BASF는 제지용 화학·분산제·기능성 첨가제의 글로벌 강자이므로, mbg의 종이·포장용 바이오 필러와 가치사슬 시너지가 매우 크다.', 'The corporate venture arm of BASF, the worlds largest chemical company, making strategic investments in chemicals, materials and sustainability. BASF is a global leader in paper chemicals, dispersions and functional additives, so there is strong value chain synergy with mbg paper and packaging bio fillers.'),
  ('Breakout Ventures', '과학 기반(생물·화학·소재) 초기 창업을 전문으로 하는 시드 단계 투자사다. mbg의 해양 바이오소재 원천기술은 Breakout이 선호하는 science-driven advanced materials 기회와 맞는다.', 'A seed stage firm specializing in science driven founders across biology, chemistry and materials. mbg marine biomaterials technology fits the science driven advanced materials opportunities Breakout favors.'),
  ('Cavallo Ventures', '농업·식품·산업 유통 대기업 Wilbur-Ellis의 CVC로, 농업·식품·특수소재 분야에 투자한다. mbg의 바이오소재·천연 유래 기능성 원료는 Cavallo의 특수소재·지속가능 농식품 관심과 접점이 있다.', 'The corporate venture arm of Wilbur-Ellis, investing across agriculture, food and specialty materials. mbg biomaterials and naturally derived functional ingredients connect with Cavallo interest in specialty materials and sustainable agrifood.'),
  ('Circulate Capital', '플라스틱 순환경제와 해양 플라스틱 저감에 집중하는 임팩트 투자사로 싱가포르 기반이며 아시아·신흥시장 중심이다. mbg의 바이오 기반·재활용 가능 포장 소재는 Circulate의 핵심 테제와 직접 맞닿아 있다.', 'A Singapore based impact investor focused on the circular economy for plastics and on reducing ocean plastic, active across Asia and high growth markets. mbg bio based and recyclable packaging materials sit directly within the Circulate thesis.'),
  ('Closed Loop Partners', '순환경제 전문 투자사로 재활용·포장·소재·리커머스 분야에 투자하며 대형 소비재·포장 기업과 협업한다. mbg의 지속가능 포장·바이오 필러는 Closed Loop의 포장·소재 순환 테마에 정확히 부합한다.', 'A circular economy investment firm covering recycling, packaging, materials and recommerce, working closely with major consumer and packaging companies. mbg sustainable packaging and bio fillers match the Closed Loop packaging and materials themes.'),
  ('Creative Ventures', '기후·헬스·산업의 구조적 문제를 deep tech로 푸는 초기 투자사(오클랜드)로, advanced materials부터 로보틱스·바이오까지 폭넓게 투자한다. mbg의 소재 원천기술은 Creative의 deep tech 범주와 맞는다.', 'An early stage deep tech firm in Oakland tackling structural problems in climate, health and industry, spanning advanced materials, robotics and biology. mbg core materials technology fits the Creative deep tech scope.'),
  ('Diamond Edge Ventures', '미쓰비시케미칼그룹의 미국 CVC로, advanced materials·그린소재·바이오매스·특수화학 스타트업에 투자하고 그룹 사업과 공동개발한다. mbg의 해양 바이오소재·지속가능 필러는 그룹의 그린소재 전략과 강한 시너지가 있다.', 'The US corporate venture arm of Mitsubishi Chemical Group, investing in advanced materials, green materials, biomass and specialty chemicals and co developing with group businesses. mbg marine biomaterials and sustainable fillers have strong synergy with the group green materials strategy.'),
  ('Emerald Technology Ventures', '산업 혁신·청정기술 전문의 글로벌 벤처사(스위스)로, 에너지·소재·물·포장 분야에 투자한다. mbg의 지속가능 소재·포장 응용은 Emerald의 산업·포장 테제와 부합한다.', 'A Swiss global venture firm specializing in industrial innovation and clean technology across energy, materials, water and packaging. mbg sustainable materials and packaging applications align with the Emerald industrial and packaging thesis.'),
  ('Emergent Technologies', '대학·연구기관 IP를 사업화해 회사로 키우는 기술 상용화 투자사로 생명과학·소재 등 다분야를 다룬다. mbg의 과학 기반 소재 플랫폼과 상용화 측면에서 접점이 있다.', 'A technology commercialization firm that builds companies from university and research IP across life sciences and materials. There are commercialization touchpoints with the mbg science based materials platform.'),
  ('First Bight Ventures', '합성생물학·바이오제조에 특화된 초기 전용 펀드(휴스턴)로, 화학·소재·소비재 등 산업 바이오 응용에 투자하고 파일럿 생산 인프라까지 지원한다. mbg의 해양 바이오소재 생산·스케일업과 직접적으로 부합한다.', 'A Houston based early stage fund dedicated to synthetic biology and biomanufacturing across chemicals, materials and consumer goods, supporting portfolio companies with pilot production infrastructure. It maps directly to mbg marine biomaterials production and scale up.'),
  ('Flagship Pioneering', '바이오 플랫폼 기업을 직접 창업·육성하는 벤처 크리에이션 기관(모더나 산실)으로 생명과학·바이오 중심이다. mbg의 바이오소재 플랫폼은 Flagship의 바이오 우선 테제와 인접한다.', 'A venture creation institution that founds and builds bioplatform companies, known for originating Moderna, centered on life sciences and biology. The mbg biomaterials platform is adjacent to the Flagship biology first thesis.'),
  ('G2 Venture Partners', '기존 산업의 지속가능 전환(decarbonization)을 돕는 기술에 투자하는 성장 단계 벤처사다. mbg의 바이오 기반 소재는 소재·제조 산업의 친환경 전환 테마와 맞는다.', 'A growth stage venture firm backing technologies that drive the sustainable transformation of established industries. mbg bio based materials fit its theme of decarbonizing materials and manufacturing.'),
  ('GM Ventures', '제너럴모터스의 CVC로 모빌리티·소재·제조 분야 전략 투자에 집중한다. mbg의 advanced materials는 경량·지속가능 소재 측면에서 일부 접점이 있다.', 'The corporate venture arm of General Motors, focused on mobility, materials and manufacturing. mbg advanced materials have some touchpoints in lightweight and sustainable materials.'),
  ('In-Q-Tel', '미국 정보·국가안보 커뮤니티를 위한 전략 투자기관으로 첨단 소재를 포함한 dual-use 딥테크에 투자한다. mbg의 소재 원천기술과는 응용 접점이 제한적이지만 advanced materials 일반 관심과는 닿는다.', 'A strategic investor for the US national security community that backs dual use deep tech including advanced materials. Application overlap with mbg is limited, though it connects to general advanced materials interest.'),
  ('KdT Ventures', '분자과학(생물·화학)에 뿌리를 둔 회사를 초기부터 키우는 deep tech 투자사로 바이오제조·소재·헬스를 아우른다. mbg의 해양 바이오소재 원천기술과 강하게 부합한다.', 'A deep tech firm building companies rooted in molecular sciences across biology and chemistry, spanning biomanufacturing, materials and health. It aligns strongly with mbg marine biomaterials technology.'),
  ('Lowercarbon Capital', '탄소 감축·제거에 집중하는 대형 기후 테크 투자사다. mbg의 바이오 기반 소재가 탄소집약 소재를 대체하는 점에서 기후 임팩트 접점이 있다.', 'A large climate tech firm focused on cutting and removing carbon. mbg bio based materials that displace carbon intensive materials offer a climate impact connection.'),
  ('Lux Capital Management LLC', '과학·공학 기반의 deep tech에 폭넓게 투자하는 대표 벤처사(뉴욕·실리콘밸리)로 소재·바이오·하드테크를 포함한다. mbg의 과학 기반 advanced materials는 Lux의 관심 영역과 맞닿는다.', 'A leading venture firm investing broadly in science and engineering driven deep tech including materials, biology and hardtech, based in New York and Silicon Valley. mbg science based advanced materials fall within the Lux scope.'),
  ('Material Impact Partners', '소재과학만을 핵심 전략으로 삼아 실험실 기술을 제품·회사로 키우는 보스턴 기반 전문 투자사다(바이오소재 포트폴리오 보유). mbg의 해양 바이오소재 원천기술과 가장 직접적으로 부합하는 투자사 중 하나다.', 'A Boston based firm that focuses exclusively on materials science, building companies from lab breakthroughs and holding biomaterials investments. It is among the most directly aligned investors for mbg marine biomaterials technology.'),
  ('Microsoft Climate Innovation Fund', '마이크로소프트의 기후 투자 펀드로 탄소 감축·제거, 지속가능 소재·포장에 투자한다. mbg의 바이오 기반 소재·포장은 펀드의 지속가능 소재 테마와 연결된다.', 'The Microsoft climate fund investing in carbon reduction and removal and in sustainable materials and packaging. mbg bio based materials and packaging connect with its sustainable materials theme.'),
  ('Mitsui Global Investment', '일본 종합상사 미쓰이물산의 벤처 투자 부문으로 소재·화학·헬스 등 폭넓게 투자하며 글로벌 사업망과 연결한다. mbg의 소재 사업화·아시아 유통 측면에서 전략적 가치가 있다.', 'The venture arm of the Japanese trading house Mitsui, investing broadly across materials, chemicals and health with access to a global business network. It offers strategic value for mbg commercialization and Asian distribution.'),
  ('P&G Ventures', 'P&G의 신사업 벤처 플랫폼으로 소비재 신소재·지속가능 성분 분야 초기 기업과 협업한다. mbg의 화장품·퍼스널케어용 바이오 기능성 원료는 P&G의 소비재 응용과 직접 맞닿는다.', 'The new business venture platform of P&G, partnering with early stage companies on new consumer materials and sustainable ingredients. mbg bio functional ingredients for cosmetics and personal care map directly to P&G consumer applications.'),
  ('Pangaea Ventures', '2000년 설립된 advanced materials 전문 1세대 벤처사로 소재·화학·생물 기반 하드테크에 투자하며 글로벌 소재·화학 대기업과 전략 관계를 맺는다. mbg의 해양 바이오소재와 정합도가 가장 높은 투자사 중 하나다.', 'Founded in 2000, a pioneer advanced materials venture firm investing in hardtech across materials, chemistry and biology, with strategic ties to major global materials and chemical companies. It is among the highest fit investors for mbg marine biomaterials.'),
  ('PepsiCo Greenhouse Accelerator', '펩시코의 액셀러레이터 프로그램으로 지속가능 포장·성분·공급망 혁신 초기 기업을 육성한다. mbg의 지속가능 포장·바이오 필러는 프로그램의 포장 혁신 테마와 접점이 있다.', 'A PepsiCo accelerator program supporting early stage companies in sustainable packaging, ingredients and supply chain innovation. mbg sustainable packaging and bio fillers connect with its packaging innovation theme.'),
  ('Phoenix Venture Partners', '소재과학 혁신을 개념검증에서 상용화까지 끌어내는 데 특화된 advanced materials 전문 벤처사(샌마테오)다. mbg의 해양 바이오소재 원천기술·제조 상용화와 강하게 부합한다.', 'A San Mateo based venture firm specialized in taking materials science innovations from proof of concept through to commercialization. It aligns strongly with mbg marine biomaterials technology and manufacturing commercialization.'),
  ('Piva Capital', '산업·에너지 전환 분야의 deep tech에 투자하는 벤처사다. mbg의 바이오 기반 소재는 산업 탈탄소·소재 전환 테마와 접점이 있다.', 'A venture firm investing in deep tech across the industrial and energy transition. mbg bio based materials connect with its industrial decarbonization and materials transition themes.'),
  ('Playground Global', '딥테크·하드웨어·소재·제조 자동화에 투자하는 벤처사(팔로알토)로 기술 난도가 높은 회사를 선호한다. mbg의 advanced materials 원천기술과 일부 접점이 있다.', 'A Palo Alto venture firm investing in deep tech, hardware, materials and manufacturing automation, favoring technically hard companies. There are touchpoints with mbg advanced materials technology.'),
  ('Prime Movers Lab', '물리·공학 기반의 breakthrough 과학 스타트업에 투자하는 벤처사로 에너지·소재·바이오·제조를 아우른다. mbg의 과학 기반 advanced materials는 Prime Movers의 테제에 부합한다.', 'A venture firm backing breakthrough scientific startups grounded in physics and engineering, spanning energy, materials, biology and manufacturing. mbg science based advanced materials fit the Prime Movers thesis.'),
  ('Regeneration.VC', '순환경제·재생 소재와 소비재에 투자하는 초기 벤처사다. mbg의 바이오 기반 필러·지속가능 포장·소비재 응용은 Regeneration의 순환·소재 테제에 정확히 부합한다.', 'An early stage venture firm investing in circular and regenerative materials and consumer products. mbg bio based fillers, sustainable packaging and consumer applications match the Regeneration circular materials thesis.'),
  ('S2G Ventures', '식품·농업·해양·에너지의 지속가능 전환에 투자하는 멀티스테이지 벤처사로 별도 Oceans(블루 이코노미) 전략을 통해 해조류·해양 건강 등에 투자한다. mbg의 해양 유래 소재는 S2G의 해양·지속가능 소재 테제와 직접 맞닿는다.', 'A multistage venture firm investing in the sustainable transition of food, agriculture, oceans and energy, with a dedicated Oceans blue economy strategy covering algae, seaweed and ocean health. mbg marine derived materials connect directly with the S2G oceans and sustainable materials thesis.'),
  ('SOSV', 'HAX(하드웨어)와 IndieBio(생명공학)를 운영하는 글로벌 deep tech 시드 투자사로 바이오소재 스타트업을 다수 지원해 왔다. mbg의 해양 바이오소재 원천기술·스케일업과 강하게 부합한다.', 'A global deep tech seed investor running HAX for hardware and IndieBio for biology, with a track record backing biomaterials startups. It aligns strongly with mbg marine biomaterials technology and scale up.'),
  ('Safar Partners', '대학(MIT·로체스터 등) 발 deep tech를 초기부터 키우는 벤처사로 소재·에너지·바이오를 다룬다. mbg의 과학 기반 소재 플랫폼과 접점이 있다.', 'A venture firm building deep tech from universities such as MIT and Rochester across materials, energy and biology. There are touchpoints with the mbg science based materials platform.'),
  ('Saint-Gobain NOVA', '글로벌 소재·건축자재 기업 Saint-Gobain의 외부 혁신·CVC 조직으로 advanced materials·지속가능 소재 스타트업과 협업한다. mbg의 기능성 필러·바이오소재는 그룹의 소재 사업과 응용 접점이 크다.', 'The external innovation and corporate venture organization of Saint-Gobain, a global materials and building products company, partnering with advanced and sustainable materials startups. mbg functional fillers and biomaterials have meaningful application overlap with the group materials businesses.'),
  ('Scout Ventures', '대학·국방 연구실 발 dual-use 딥테크에 투자하는 초기 벤처사다. mbg의 advanced materials와는 일반적 딥테크 관심 수준에서 접점이 있다.', 'An early stage venture firm investing in dual use deep tech out of university and defense labs. The connection to mbg advanced materials is at the level of general deep tech interest.'),
  ('Sumitomo Corp Equity Asia / Presidio', '스미토모상사 계열의 벤처 투자 활동으로 소재·산업·기술 분야에 투자하며 글로벌 사업망과 연결한다. mbg의 소재 사업화·아시아 유통 측면에서 전략적 가치가 있다.', 'Venture investment activity affiliated with the Sumitomo trading house, investing across materials, industrial and technology with global business reach. It offers strategic value for mbg commercialization and Asian distribution.'),
  ('Supply Change Capital', '식품·소비재의 지속가능·문화 트렌드에 투자하는 초기 벤처사다. mbg의 천연 유래 기능성 원료·지속가능 소재는 식품·소비재 응용 측면에서 접점이 있다.', 'An early stage venture firm investing in sustainability and cultural shifts in food and consumer goods. mbg naturally derived functional ingredients and sustainable materials connect on the food and consumer application side.'),
  ('Suzano Ventures', '세계 최대 시판 펄프 생산사 Suzano의 글로벌 CVC로 유칼립투스 바이오소재·지속가능 포장·임업기술·탄소제거에 투자하며 펄프·제지 가치사슬과 직접 연결된다. mbg의 종이·포장용 바이오 필러와 가장 직접적으로 맞닿는 투자사다.', 'The global corporate venture arm of Suzano, the worlds largest market pulp producer, investing in eucalyptus biomaterials, sustainable packaging, forestry technology and carbon removal, with direct links to the pulp and paper value chain. It is the most directly aligned investor for mbg paper and packaging bio fillers.'),
  ('The Coca-Cola Company Ventures', '코카콜라의 벤처·혁신 활동으로 지속가능 포장·성분·공급망 분야에 관심을 둔다. mbg의 지속가능 포장 소재는 포장 혁신 테마와 접점이 있다.', 'The venture and innovation activity of The Coca-Cola Company, with interest in sustainable packaging, ingredients and supply chain. mbg sustainable packaging materials connect with its packaging innovation theme.'),
  ('The Engine Ventures', 'MIT에서 출범한 tough tech 전문 벤처사로 소재·제조·바이오 등 난제 해결형 과학기업을 인내자본으로 키운다. mbg의 해양 바이오소재·제조 스케일업과 부합한다.', 'A tough tech venture firm born out of MIT, using patient capital to build hard science companies across materials, manufacturing and biology. It aligns with mbg marine biomaterials and manufacturing scale up.'),
  ('Toyota Ventures', '토요타의 벤처 펀드로 모빌리티와 함께 기후·소재·에너지 초기 기업에 투자한다. mbg의 지속가능 advanced materials와 일부 접점이 있다.', 'The Toyota venture fund investing in early stage companies across mobility as well as climate, materials and energy. There are some touchpoints with mbg sustainable advanced materials.'),
  ('Unilever Ventures', '유니레버의 벤처 투자 부문으로 뷰티·퍼스널케어·디지털 커머스 초기 브랜드·기술에 투자한다. mbg의 화장품·퍼스널케어용 해양 바이오 기능성 원료는 Unilever의 핵심 응용과 직접 맞닿는다.', 'The venture arm of Unilever, investing in early stage beauty, personal care and digital commerce brands and technologies. mbg marine bio functional ingredients for cosmetics and personal care map directly to core Unilever applications.'),
  ('Voyager Ventures', '북미·유럽의 기후 기술 초기 투자사로 탈탄소·산업 전환 분야에 투자한다. mbg의 바이오 기반 소재는 탄소집약 소재 대체라는 기후 테마와 접점이 있다.', 'An early stage climate tech investor across North America and Europe focused on decarbonization and industrial transition. mbg bio based materials connect with the theme of replacing carbon intensive materials.'),
  ('Walmart Strategic Capital', '월마트의 전략 투자 부문으로 리테일·공급망·지속가능성 분야에 투자한다. mbg의 지속가능 포장·소재는 리테일 공급망의 지속가능성 테마와 접점이 있다.', 'The strategic investment arm of Walmart investing in retail, supply chain and sustainability. mbg sustainable packaging and materials connect with the retail supply chain sustainability theme.')
) as d(nm, ko, en)
where coalesce(
  to_jsonb(p)->>'name', to_jsonb(p)->>'party_name', to_jsonb(p)->>'legal_name',
  to_jsonb(p)->>'display_name', to_jsonb(p)->>'company_name', to_jsonb(p)->>'entity_name'
) = d.nm
  and p.party_type_id = 1
  and p.deleted_at is null;

-- (2) Promote high-relevance investors to priority = high
update app.investor_profile ip
set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id
  and p.party_type_id = 1
  and p.deleted_at is null
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in (
    '3M Ventures',
    'Anzu Partners',
    'At One Ventures',
    'BASF Venture Capital',
    'Breakout Ventures',
    'Circulate Capital',
    'Closed Loop Partners',
    'Diamond Edge Ventures',
    'Emerald Technology Ventures',
    'First Bight Ventures',
    'KdT Ventures',
    'Material Impact Partners',
    'P&G Ventures',
    'Pangaea Ventures',
    'Phoenix Venture Partners',
    'Prime Movers Lab',
    'Regeneration.VC',
    'S2G Ventures',
    'SOSV',
    'Saint-Gobain NOVA',
    'Suzano Ventures',
    'The Engine Ventures',
    'Unilever Ventures'
  );

-- (3) Verification
select priority, count(*) from app.investor_profile group by priority order by 2 desc;

select s.label_en as sector, p.party_name,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en, ip.priority
from app.parties p
join app.investor_profile ip       on ip.party_id = p.id
join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
join app.sectors s                 on s.id = isf.sector_id
where s.label_en = 'Advanced Materials' and p.party_type_id = 1 and p.deleted_at is null
order by ip.priority, p.party_name;
