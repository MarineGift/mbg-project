-- ============================================================
-- 20260620370012_strongfit_intro_priority_pass3.sql
-- Strong-fit intro_ko/intro_en + priority='high', PASS 3 (batch5 materials/climate fits).
-- Firms (added in batch5 / 370007): SABIC Ventures, POSCO Venture Capital,
-- Shell Ventures, Planet First Partners. Per-firm UPDATEs. Idempotent.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.
-- ============================================================

begin;

update app.parties set intro_ko = $ko$사우디 SABIC(시테르드 NL 운영)의 CVC로 functional polymers·첨단소재·복합재, 대체에너지, 그리고 조류(algae)·CO2 기반 대체 원료에 투자한다. MBG의 탄산칼슘 기능성 충전제·친환경 소재 공정과 가장 직접적으로 맞닿는 전략적 파트너 후보다.$ko$,
  intro_en = $en$The CVC of Saudi SABIC (operating from Sittard, Netherlands), investing in functional polymers, advanced materials and composites, alternative energy, and algae- and CO2-based alternative feedstocks. It is one of the most directly relevant strategic partners for mbg calcium carbonate functional fillers and sustainable materials processing.$en$
where party_name = 'SABIC Ventures' and deleted_at is null;

update app.parties set intro_ko = $ko$한국 POSCO의 CVC(서울, KRW 600억 규모)로 첨단 탄소소재·이차전지/에너지 소재·로보틱스·나노기술·딥테크에 투자한다. MBG의 산업 소재·탄산칼슘 공정혁신과 강하게 부합하며, 한국 내 소재 산업 네트워크 접점이 크다.$ko$,
  intro_en = $en$The CVC of Korea's POSCO (Seoul, about KRW 60 billion), investing in advanced carbon materials, battery/energy materials, robotics, nanotechnology and deep tech. It aligns strongly with mbg industrial materials and calcium carbonate process innovation, with valuable access to Korea's materials-industry network.$en$
where party_name = 'POSCO Venture Capital' and deleted_at is null;

update app.parties set intro_ko = $ko$런던 기반 Article 9 지속가능 성장투자 플랫폼(de Mévius 가문 기반)으로 에너지전환·그린시티·산업·소재 분야 스케일업에 투자한다. MBG의 친환경 소재·저탄소 제지 서사와 결이 맞으며 유럽·북미 확장 파트너로 적합하다.$ko$,
  intro_en = $en$A London-based Article 9 sustainable growth-investment platform (rooted in the de Mevius family) backing scale-ups in energy transition, green cities, industrials and materials. It fits the mbg sustainable materials and low-carbon paper thesis and suits European and North American expansion.$en$
where party_name = 'Planet First Partners' and deleted_at is null;

update app.parties set intro_ko = $ko$Shell의 CVC(헤이그 NL)로 에너지전환·저탄소·산업 분야에 글로벌 투자한다. MBG의 산업 스케일 친환경 소재·공정 탈탄소 측면에서 접점이 있는 에너지 메이저 파트너 후보다.$ko$,
  intro_en = $en$The CVC of Shell (The Hague, Netherlands), investing globally in energy transition, low-carbon and industrial themes. An energy-major partner candidate with touchpoints to mbg industrial-scale sustainable materials and process decarbonization.$en$
where party_name = 'Shell Ventures' and deleted_at is null;

update app.investor_profile ip set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id and p.deleted_at is null
  and p.party_name in ('SABIC Ventures','POSCO Venture Capital','Planet First Partners','Shell Ventures')
  and ip.priority is distinct from 'high';

commit;

-- Verify:
-- select party_name, (intro_ko is not null) ko, (intro_en is not null) en, ip.priority
-- from app.parties p join app.investor_profile ip on ip.party_id=p.id
-- where party_name in ('SABIC Ventures','POSCO Venture Capital','Planet First Partners','Shell Ventures');
