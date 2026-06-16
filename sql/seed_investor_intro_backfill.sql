-- ============================================================
-- Backfill investor Introduction (intro_ko / intro_en) for verified firms
-- Family Office + PE/Growth + Endowment/Sovereign (this document, 10 firms).
-- Some firms already existed in DB, so their earlier INSERT was skipped and
-- intro stayed empty (e.g. Emerson Collective). This fills the gaps.
-- SAFE: sets intro ONLY where currently null -> never overwrites good intros.
-- Verified 2026-06-15. Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.
-- dollar-quoted intros so inner quotes never break.
-- ============================================================

update app.parties p
set intro_ko = f.intro_ko, intro_en = f.intro_en, updated_at = now()
from (values
  ('Capricorn%', $ko$이베이 초대 회장 Jeff Skoll의 자금에서 출발한 팔로알토 멀티 패밀리 오피스 겸 임팩트 투자사로, Technology Impact/Growth 펀드를 통해 기후 솔루션 딥테크에 투자한다. Tesla·QuantumScape 등 하드테크·첨단 소재의 압도적 이력을 보유한다. 플라스틱을 대체하는 탄소·폐기물 저감 사업인 mbg에 매력을 느낄 인내 자본이다.$ko$, $en$A Palo Alto multi family office and impact investor that grew from the capital of Jeff Skoll, eBay first president, investing in deep technology climate solutions through its Technology Impact and Growth funds. It has a strong hard tech and advanced materials track record including Tesla and QuantumScape. As patient capital it is well suited to mbg, a plastic replacing business that cuts carbon and waste.$en$),
  ('Emerson Collective%', $ko$스티브 잡스의 아내 Laurene Powell Jobs가 2011년 설립한 투자·자선 조직(팔로알토)으로, 벤처 투자 부문은 환경·에너지와 기후 딥테크에 집중한다. 플라스틱 대체·환경 임팩트를 핵심으로 하는 mbg와 가치 정렬이 좋다.$ko$, $en$An investment and philanthropy organization founded in 2011 by Laurene Powell Jobs in Palo Alto, whose venture arm focuses on environment, energy and climate deep tech. It is well aligned in values with mbg, whose core is plastic replacement and environmental impact.$en$),
  ('ICONIQ%', $ko$Mark Zuckerberg 등 실리콘밸리 거물들의 자금을 운용하는 멀티 패밀리 오피스(2011)로 약 800억 달러를 운용한다. ICONIQ Growth를 통해 주로 엔터프라이즈 소프트웨어 등 그로스 단계 기술기업에 직접 투자한다(소재 직접 적합도는 제한적). 후기 성장 자본과 강력한 네트워크 측면에서 참고 대상이다.$ko$, $en$A multi family office founded in 2011 managing capital for prominent Silicon Valley leaders including Mark Zuckerberg, with about 80 billion dollars in assets. Through ICONIQ Growth it invests directly in growth stage technology companies, mainly enterprise software (direct materials fit is limited). It is a reference for later stage growth capital and a strong network.$en$),
  ('Eclipse Ventures%', $ko$팔로알토 기반의 투자사로 '물리적 세계(Physical World)의 혁신', 즉 하드웨어·제조·공급망 딥테크 기업에 집중 투자한다(VC와 PE의 중간 성격). 텍사스 양산 공장 설립과 산업용 충전제 제조망 스케일업에 필요한 운영·제조 인프라 최적화 노하우가 강점이다.$ko$, $en$A Palo Alto based investor focused on innovation in the physical world, meaning hardware, manufacturing and supply chain deep tech companies, with a profile between venture capital and private equity. Its strength is operational and manufacturing infrastructure optimization, well suited to building a Texas production plant and scaling an industrial filler manufacturing network.$en$),
  ('G2 Venture Partners%', $ko$Kleiner Perkins(KPCB)의 클린테크 팀이 독립해 만든 그로스 에쿼티 펀드(포르톨라 밸리)로, 운송·물류·제조·농업·에너지 등 전통 산업을 기술로 지속가능하게 탈바꿈하는 성장기 기업에 투자한다(포트폴리오: Carbon 3D 프린팅 등). 제지·소재 등 전통 산업 가치사슬을 혁신하는 mbg와 정합성이 높다.$ko$, $en$A growth equity fund spun out of the Kleiner Perkins cleantech team (Portola Valley) that invests in growth stage companies making traditional industries such as transportation, logistics, manufacturing, agriculture and energy more sustainable (portfolio includes Carbon 3D printing). It fits well with mbg, which transforms traditional industry value chains such as paper and materials.$en$),
  ('Generation Investment Management%', $ko$앨 고어 전 미국 부통령이 공동 설립한 지속가능성 특화 투자사(런던/샌프란시스코)로, 성장기 딥테크·친환경 제조 기업에 장기 자본을 투입한다. 탈탄소·지속가능 소재 관점에서 mbg와 방향성이 맞는다.$ko$, $en$A sustainability focused investment firm co founded by former US Vice President Al Gore (London and San Francisco) that provides long term capital to growth stage deep tech and sustainable manufacturing companies. It aligns with mbg on decarbonization and sustainable materials.$en$),
  ('Temasek%', $ko$싱가포르 국부형 투자회사(1974, 포트폴리오 약 2,900억 달러)로, LP이자 직접 투자자로서 생명과학·첨단 소재·소비재 등에 대형 라운드를 주도한다. 화장품·생리대 등 소비재 밸류체인을 아시아·글로벌로 확장할 때 최상급 앵커 투자자가 될 수 있다.$ko$, $en$A Singapore state owned investment company (founded 1974, portfolio about 290 billion dollars) that acts as both an LP and a direct investor and leads large rounds in life sciences, advanced materials and consumer sectors. It can be a top anchor investor when expanding the cosmetics and personal care consumer value chain across Asia and globally.$en$),
  ('GIC', $ko$싱가포르 정부의 준비금을 운용하는 국부펀드(1981)로 글로벌 다자산에 투자하며 넷제로 전환을 적극 지원한다. 첨단 소재·생명과학 생태계가 Series B 이상으로 성장할 때 대형 직접 공동투자 파트너가 될 수 있다.$ko$, $en$A sovereign wealth fund (founded 1981) that manages the Singapore government reserves across global multi asset portfolios and actively supports the net zero transition. It can be a large direct co investment partner as advanced materials and life science companies grow beyond Series B.$en$),
  ('UC Investments%', $ko$캘리포니아 대학교(UC)의 투자 운용 조직으로 기금·연금 자산을 운용하며, 최근 기후 테크·딥테크 직접 투자 비중을 빠르게 늘리고 있다. 통상 VC 펀드의 LP로 참여하지만 성장 단계에서 직접 공동투자도 한다.$ko$, $en$The investment office of the University of California, managing its endowment and pension assets and rapidly increasing direct allocations to climate tech and deep tech. It usually participates as an LP in venture funds but also co invests directly at growth stages.$en$),
  ('Stanford Management Company%', $ko$스탠퍼드 대학 기금을 운용하는 조직(SMC)으로 실리콘밸리 딥테크·신소재 생태계의 근간을 이루는 자본이다. 우수한 특허·원천기술을 가진 딥테크 기업이 스탠퍼드 관련 네트워크 펀드와 연결될 경우 간접적 지원 가능성이 있다.$ko$, $en$The organization that manages the Stanford University endowment (SMC), a foundational source of capital for the Silicon Valley deep tech and advanced materials ecosystem. Deep tech companies with strong patents and core technology may gain indirect support when connected to Stanford affiliated network funds.$en$)
) as f(match_pat, intro_ko, intro_en)
where coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike f.match_pat
  and p.deleted_at is null
  and (p.intro_ko is null or p.intro_en is null);

-- Verification: intro presence for the 10 firms
select coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') as party_name,
       (p.intro_ko is not null) as ko, (p.intro_en is not null) as en
from app.parties p
where p.deleted_at is null and (
  coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Capricorn%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Emerson Collective%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'ICONIQ%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Eclipse Ventures%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'G2 Venture Partners%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Generation Investment Management%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Temasek%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'GIC'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'UC Investments%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Stanford Management Company%'
)
order by party_name;
