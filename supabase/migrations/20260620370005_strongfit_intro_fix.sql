-- ============================================================
-- 20260620370005_strongfit_intro_fix.sql
-- Completes 20260620370004 (which applied to only BASF + Saint-Gobain
-- due to a paste/file truncation). Fills intro_ko/intro_en + priority='high'
-- for the remaining 6 strong-fit firms. Per-firm statements, idempotent.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.
-- ============================================================

begin;

update app.parties set intro_ko = $ko$소재·화학 산업 전문가들이 운용하는 일본(도쿄) 소재·화학 특화 VC(약 300억 엔/3펀드). 사명 umi는 일본어로 바다를 뜻해 MBG의 해양바이오·탄산칼슘 소재 서사와 결이 맞고, 탄소섬유 재활용·바이오소재 포트폴리오가 직접 접점이다.$ko$,
  intro_en = $en$A Japan (Tokyo) venture firm specialized in materials and chemicals (about 30 billion yen across three funds). Its name umi means ocean in Japanese, aligning with the mbg marine bio and calcium carbonate materials story; its carbon-fiber recycling and biomaterials portfolio is a direct point of contact.$en$
where party_name = 'Universal Materials Incubator' and deleted_at is null;

update app.parties set intro_ko = $ko$파리 기반 라이프사이언스 VC(약 9.5억 유로)로 바이오·헬스·영양뿐 아니라 Blue Economy·양식·마이크로바이옴에 투자한다. MBG의 해양바이오·생체적합 소재 방향과 매우 강하게 일치한다.$ko$,
  intro_en = $en$A Paris-based life sciences VC (about 950 million euros) investing across bio, health and nutrition as well as the Blue Economy, aquaculture and microbiome. It aligns very strongly with the mbg marine bio and biocompatible materials direction.$en$
where party_name = 'Seventure Partners' and deleted_at is null;

update app.parties set intro_ko = $ko$네덜란드(나르덴) 유럽 대표 라이프사이언스 VC(약 50억 유로)로, BioEconomy 펀드를 통해 바이오 기반 소재·환경기술에도 투자한다. MBG의 해양바이오와 생체 기반 친환경 소재 접점이 분명하다.$ko$,
  intro_en = $en$A leading European life sciences VC (Naarden, Netherlands, about 5 billion euros) that also invests in biology-based materials and environmental technologies through its BioEconomy fund. There is a clear point of contact with mbg marine bio and bio-based sustainable materials.$en$
where party_name = 'Forbion' and deleted_at is null;

update app.parties set intro_ko = $ko$벨기에 특수화학사 Syensqo(구 Solvay)의 CVC로 advanced materials·바이오텍·클린에너지에 투자한다. 기능성 충전제·코팅 소재 측면에서 MBG와 기술적 시너지가 크다.$ko$,
  intro_en = $en$The corporate venture arm of Belgian specialty chemicals company Syensqo (formerly Solvay), investing in advanced materials, biotech and clean energy. Strong technical synergy with mbg in functional fillers and coating materials.$en$
where party_name = 'Syensqo Ventures' and deleted_at is null;

update app.parties set intro_ko = $ko$런던 기반 VC로 수소·탄소 가치사슬과 산업 탈탄소 딥테크에 투자하며 소재과학·전기화학에 깊은 전문성을 갖는다. MBG의 하드사이언스 소재 공정혁신과 결이 맞는다.$ko$,
  intro_en = $en$A London-based VC investing in the hydrogen and carbon value chains and industrial decarbonization deep tech, with deep expertise in materials science and electrochemistry. It fits the mbg hard-science materials process innovation.$en$
where party_name = 'AP Ventures' and deleted_at is null;

update app.parties set intro_ko = $ko$베를린 기반 유럽 climate deep tech VC(약 3억 유로)로 소재·산업 탈탄소 분야에 투자한다. MBG의 친환경 충전제·저탄소 제지 소재 서사와 부합한다.$ko$,
  intro_en = $en$A Berlin-based European climate deep tech VC (about 300 million euros) investing in materials and industrial decarbonization. It fits the mbg sustainable filler and low-carbon paper materials thesis.$en$
where party_name = 'World Fund' and deleted_at is null;

update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and p.party_name in ('Universal Materials Incubator','Seventure Partners','Forbion','Syensqo Ventures','AP Ventures','World Fund')
  and ip.priority is distinct from 'high';

commit;
