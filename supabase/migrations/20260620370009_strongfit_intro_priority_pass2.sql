-- ============================================================
-- 20260620370009_strongfit_intro_priority_pass2.sql
-- Strong-fit intro_ko/intro_en + priority='high', PASS 2.
-- Firms (already in DB from batch2/3): Aramco Ventures, Climentum Capital,
-- Cycle Capital, Real Tech Holdings, KAUST Innovation Ventures.
-- Per-firm UPDATEs (avoids multi-row dollar-quote paste truncation). Idempotent.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.
-- ============================================================

begin;

update app.parties set intro_ko = $ko$사우디 아람코의 CVC(약 75억 달러/6펀드)로 deep tech·에너지전환·기후·첨단산업·소재에 글로벌 투자한다. MBG의 탄산칼슘 공정혁신·산업 소재·친환경 제지 서사와 산업 스케일 측면에서 강하게 부합한다.$ko$,
  intro_en = $en$The corporate venture arm of Saudi Aramco (about 7.5 billion dollars across six funds), investing globally in deep tech, energy transition, climate, advanced industrials and materials. It fits the mbg calcium carbonate process innovation, industrial materials and sustainable paper thesis at industrial scale.$en$
where party_name = 'Aramco Ventures' and deleted_at is null;

update app.parties set intro_ko = $ko$코펜하겐 기반 북유럽·DACH climate hardtech VC(Article 9)로 산업 탈탄소·소재·제조에 투자하며 LP에 BASF Venture Capital이 있다. MBG의 친환경 충전제·저탄소 제지 공정과 결이 맞는다.$ko$,
  intro_en = $en$A Copenhagen-based Nordic and DACH climate hardtech VC (Article 9) investing in industrial decarbonization, materials and manufacturing, with BASF Venture Capital among its LPs. It fits the mbg sustainable filler and low-carbon paper process.$en$
where party_name = 'Climentum Capital' and deleted_at is null;

update app.parties set intro_ko = $ko$몬트리올 기반 캐나다 대표 cleantech VC로 산업·소재·순환경제에 투자한다. MBG의 친환경 소재·탄산칼슘 충전제 서사와 부합한다.$ko$,
  intro_en = $en$A Montreal-based leading Canadian cleantech VC investing in industrial, materials and the circular economy. It fits the mbg sustainable materials and calcium carbonate filler thesis.$en$
where party_name = 'Cycle Capital' and deleted_at is null;

update app.parties set intro_ko = $ko$도쿄 기반 딥테크 VC로 환경·사회 임팩트 하드테크('real tech')에 집중 투자한다. 해양·소재·환경 기술 포트폴리오가 MBG 해양바이오·친환경 소재와 직접 접점이다.$ko$,
  intro_en = $en$A Tokyo-based deep tech VC concentrating on environmental and social impact hard tech (real tech). Its ocean, materials and environmental technology portfolio is a direct point of contact with mbg marine bio and sustainable materials.$en$
where party_name = 'Real Tech Holdings' and deleted_at is null;

update app.parties set intro_ko = $ko$사우디 KAUST(과학기술대학)의 벤처 투자조직으로 deep-science·소재·바이오 spinout에 시드~초기 단계 투자한다. MBG의 하드사이언스 소재·해양바이오 연구접점과 결이 맞는다.$ko$,
  intro_en = $en$The venture investment arm of KAUST (the Saudi science and technology university), making seed to early-stage investments in deep-science, materials and bio spinouts. It fits the mbg hard-science materials and marine bio research interface.$en$
where party_name = 'KAUST Innovation Ventures' and deleted_at is null;

update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and p.party_name in ('Aramco Ventures','Climentum Capital','Cycle Capital','Real Tech Holdings','KAUST Innovation Ventures')
  and ip.priority is distinct from 'high';

commit;

-- Verify:
-- select party_name, (intro_ko is not null) ko, (intro_en is not null) en
-- from app.parties
-- where party_name in ('Aramco Ventures','Climentum Capital','Cycle Capital','Real Tech Holdings','KAUST Innovation Ventures');
