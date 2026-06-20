-- ============================================================
-- 20260620370004_strongfit_intro_priority.sql
-- Strongest MBG-fit investors: fill intro_ko/intro_en (fill-empty only)
-- and set investor_profile.priority='high'. Idempotent.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.
-- intro_ko/intro_en use dollar-quoting ($ko$...$ko$ / $en$...$en$).
-- Targets span batch-1/2 firms + the two pre-existing CVCs (BASF, Saint-Gobain).
-- ============================================================

begin;

-- ---------- (1) intro_ko / intro_en on parties (fill only where null; no clobber) ----------
update app.parties p set
  intro_ko = v.intro_ko,
  intro_en = v.intro_en
from (values
  ('BASF Venture Capital',
   $ko$BASF 그룹의 CVC(독일 루트비히스하펜)로 화학·신소재·지속가능성 분야 글로벌 스타트업과 펀드에 투자한다. MBG의 탄산칼슘 충전제 공정혁신과 친환경 제지 소재 서사에 가장 직접적으로 부합하는 전략적 파트너다.$ko$,
   $en$The corporate venture arm of BASF Group (Ludwigshafen, Germany), investing globally in chemistry, new materials and sustainability startups and funds. It is the most direct strategic fit for the mbg calcium carbonate filler process innovation and sustainable paper materials thesis.$en$),
  ('Saint-Gobain NOVA',
   $ko$360년 역사의 글로벌 소재기업 Saint-Gobain의 CVC(프랑스 쿠르브부아)로 소재·건축·지속가능성 초기 투자에 집중한다. 코팅·미네랄·친환경 건자재 접점에서 MBG의 기능성 충전제 소재와 협업 여지가 크다.$ko$,
   $en$The corporate venture arm of Saint-Gobain (Courbevoie, France), a 360-year-old global materials company, focused on early-stage materials, construction and sustainability. There is strong room for collaboration with mbg functional filler materials across coatings, minerals and sustainable building materials.$en$),
  ('Universal Materials Incubator',
   $ko$소재·화학 산업 전문가들이 운용하는 일본(도쿄) 소재·화학 특화 VC(약 300억 엔/3펀드). 사명 'umi'는 일본어로 '바다'를 뜻해 MBG의 해양바이오·탄산칼슘 소재 서사와 결이 맞고, 탄소섬유 재활용·바이오소재 포트폴리오가 직접적 접점이다.$ko$,
   $en$A Japan (Tokyo) venture firm specialized in materials and chemicals, run by industry professionals (about 30 billion yen across three funds). Its name umi means ocean in Japanese, aligning with the mbg marine bio and calcium carbonate materials story, and its carbon-fiber recycling and biomaterials portfolio is a direct point of contact.$en$),
  ('Seventure Partners',
   $ko$파리 기반 라이프사이언스 VC(약 9.5억 유로)로 바이오·헬스·영양뿐 아니라 Blue Economy·양식·마이크로바이옴에 투자한다. MBG의 해양바이오·생체적합 소재 방향과 매우 강하게 일치한다.$ko$,
   $en$A Paris-based life sciences VC (about 950 million euros) investing across bio, health and nutrition as well as the Blue Economy, aquaculture and microbiome. It aligns very strongly with the mbg marine bio and biocompatible materials direction.$en$),
  ('Forbion',
   $ko$네덜란드(나르덴) 유럽 대표 라이프사이언스 VC(약 50억 유로)로, BioEconomy 펀드를 통해 바이오 기반 소재·환경기술에도 투자한다. MBG의 해양바이오와 생체 기반 친환경 소재 접점이 분명하다.$ko$,
   $en$A leading European life sciences VC (Naarden, Netherlands, about 5 billion euros) that also invests in biology-based materials and environmental technologies through its BioEconomy fund. There is a clear point of contact with mbg marine bio and bio-based sustainable materials.$en$),
  ('Syensqo Ventures',
   $ko$벨기에 특수화학사 Syensqo(舊 Solvay)의 CVC로 advanced materials·바이오텍·클린에너지에 투자한다. 기능성 충전제·코팅 소재 측면에서 MBG와 기술적 시너지가 크다.$ko$,
   $en$The corporate venture arm of Belgian specialty chemicals company Syensqo (formerly Solvay), investing in advanced materials, biotech and clean energy. It offers strong technical synergy with mbg in functional fillers and coating materials.$en$),
  ('AP Ventures',
   $ko$런던 기반 VC로 수소·탄소 가치사슬과 산업 탈탄소 딥테크에 투자하며 소재과학·전기화학에 깊은 전문성을 갖는다. MBG의 하드사이언스 소재 공정혁신과 결이 맞는다.$ko$,
   $en$A London-based VC investing in the hydrogen and carbon value chains and industrial decarbonization deep tech, with deep expertise in materials science and electrochemistry. It fits the mbg hard-science materials process innovation.$en$),
  ('World Fund',
   $ko$베를린 기반 유럽 climate deep tech VC(약 3억 유로)로 소재·산업 탈탄소 분야에 투자한다. MBG의 친환경 충전제·저탄소 제지 소재 서사와 부합한다.$ko$,
   $en$A Berlin-based European climate deep tech VC (about 300 million euros) investing in materials and industrial decarbonization. It fits the mbg sustainable filler and low-carbon paper materials thesis.$en$)
) as v(party_name, intro_ko, intro_en)
where p.party_name = v.party_name
  and p.deleted_at is null
  and (p.intro_ko is null or p.intro_en is null);

-- ---------- (2) priority = 'high' on investor_profile (strongest-fit) ----------
update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and p.party_name in (
    'BASF Venture Capital','Saint-Gobain NOVA','Universal Materials Incubator',
    'Seventure Partners','Forbion','Syensqo Ventures','AP Ventures','World Fund'
  )
  and ip.priority is distinct from 'high';

commit;

-- Verify:
--   select p.party_name, (p.intro_ko is not null) ko, (p.intro_en is not null) en, ip.priority
--   from app.parties p join app.investor_profile ip on ip.party_id = p.id
--   where p.party_name in ('BASF Venture Capital','Saint-Gobain NOVA','Universal Materials Incubator',
--     'Seventure Partners','Forbion','Syensqo Ventures','AP Ventures','World Fund')
--   order by p.party_name;
-- ============================================================
