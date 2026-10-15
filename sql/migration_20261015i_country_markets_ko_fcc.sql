-- ============================================================
-- migration_20261015i_country_markets_ko_fcc.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Market tab support for app.country_markets.
-- 1) New columns (if missing): headline_ko, summary_ko, sections_ko jsonb,
--    fcc_potential_low_t, fcc_potential_high_t numeric, fcc_potential_basis_ko.
-- 2) Fill headline_ko and the report-based FCC supply range (t/yr) with its
--    basis for 35 countries. Ranges are planning scenarios, not orders.
--    Mill counts, filler counts, capacity totals and the mill-scenario FCC sum
--    are NOT stored - the Market tab computes them live of app.parties and
--    the mill profiles.
-- 3) Verify.
-- Re-running is safe.
-- ============================================================

alter table app.country_markets add column if not exists headline_ko text;
alter table app.country_markets add column if not exists summary_ko text;
alter table app.country_markets add column if not exists sections_ko jsonb;
alter table app.country_markets add column if not exists fcc_potential_low_t numeric;
alter table app.country_markets add column if not exists fcc_potential_high_t numeric;
alter table app.country_markets add column if not exists fcc_potential_basis_ko text;

update app.country_markets cm
set headline_ko            = v.headline_ko,
    fcc_potential_low_t    = v.lo,
    fcc_potential_high_t   = v.hi,
    fcc_potential_basis_ko = v.basis_ko,
    updated_at             = now()
from (values
  ('US', $cm$SMI 위성 PCC·Omya 현장 PCC 가 집중된 대형 인쇄용지 시장$cm$, null::numeric, null::numeric, $cm$밀별 FCC 시나리오 합계 참조 (보고서 국가 총량 없음)$cm$),
  ('JP', $cm$대형 일관공장 중심 성숙 시장 — 주요 밀이 자체 PCC 보유$cm$, null::numeric, null::numeric, $cm$밀별 시나리오 참조$cm$),
  ('IN', $cm$인쇄용지 성장 시장 — SMI·Gulshan·Fimakem 공급 링크 확인$cm$, null::numeric, null::numeric, $cm$밀별 시나리오 참조$cm$),
  ('CN', $cm$최대 시장 — SMI 위성·자체 PCC, Omya 증설$cm$, null::numeric, null::numeric, $cm$밀별 시나리오 참조$cm$),
  ('ID', $cm$APP·APRIL 양대 그룹 — Indah Kiat 에 SMI 합작 PCC$cm$, null::numeric, null::numeric, $cm$밀별 시나리오 참조$cm$),
  ('MY', $cm$티슈·판지 중심 — 현지 GCC, Schaefer Kalk PCC$cm$, null::numeric, null::numeric, $cm$밀별 시나리오 참조$cm$),
  ('VN', $cm$GCC 수출 기지 + 중형 인쇄·티슈 밀$cm$, null::numeric, null::numeric, $cm$An Hoa 시나리오 참조$cm$),
  ('KR', $cm$진행 중 — Moorim 연 9,000t FCC 상업 프로그램 (Omya 생산)$cm$, 9000::numeric, 9000::numeric, $cm$Moorim 상업 프로그램 목표 (확정 로열티 아님)$cm$),
  ('TW', $cm$현지 PCC·GCC 제조사, 인쇄용지 대상은 중화펄프$cm$, null::numeric, null::numeric, $cm$공장별 생산능력 미공개$cm$),
  ('SA', $cm$티슈·듀플렉스 판지 — 제지용 PCC 공장 없음$cm$, 7500::numeric, 23500::numeric, $cm$Saudi Paper·Juthor 티슈 3~5% + Obeikan 판지 3~5% (전량 적용 가정)$cm$),
  ('AE', $cm$Ittihad 제지공장 + Omya 현장 PCC — 걸프 실증 거점$cm$, 16250::numeric, 48750::numeric, $cm$Ittihad 32.5만 t × FCC 5~15% (가동 100% 가정)$cm$),
  ('MM', $cm$2차 시장 — 재생 포장지·소형 티슈$cm$, 3000::numeric, 3000::numeric, $cm$New Century 연 6만 t × 5% 예시$cm$),
  ('BD', $cm$Bashundhara 자체 PCC·WGCC — 수입펄프 밀 원가절감 수요$cm$, 27985::numeric, 27985::numeric, $cm$6개 밀 인쇄·티슈 10% (330일 가동 가정)$cm$),
  ('PK', $cm$OmyaPack 합작이 Bulleh Shah 옆에 — Omya 와 IP 경계 필요$cm$, 21571::numeric, 23400::numeric, $cm$Bulleh Shah·Century·Premier·Flying 일부 품목 적용 가정$cm$),
  ('AF', $cm$장기 시장 — 실제 제지공장 1곳, 제지용 충전제 없음$cm$, 3850::numeric, 3850::numeric, $cm$Baheer 5.5만 t × 가동 70% × 10%$cm$),
  ('IR', $cm$보류 — 미국 제재. 기록 전용$cm$, 25050::numeric, 49600::numeric, $cm$8개 밀 인쇄 10~20%·티슈 5~10% (제재로 사업 불가)$cm$),
  ('LB', $cm$티슈·재생 판지 — INDEVCO 가 지역 진입점$cm$, 1530::numeric, 3100::numeric, $cm$Unipak·MIMOSA·SICOMO 5% (침투 30~100%)$cm$),
  ('IL', $cm$Hadera 인쇄용지 철수로 PCC 수요 종료 — 티슈·골판지원지$cm$, 4250::numeric, 19500::numeric, $cm$Shaniv 3~10% + Infinya 1~5%$cm$),
  ('JO', $cm$GCC 수출 기지 — Sanabel·Fine 티슈$cm$, 3930::numeric, 13100::numeric, $cm$티슈 3개 설비 13.1만 t × 3~10%$cm$),
  ('IQ', $cm$신규 라인·국영공장 재건 — 현재 소규모$cm$, 1040::numeric, 1040::numeric, $cm$Al Sindyan 65 t/일 × 320일 × 5%$cm$),
  ('KW', $cm$실질 제지공장 1곳 — Gulf Paper$cm$, 600::numeric, 3250::numeric, $cm$티슈 5% ~ 티슈 5% + 포장 5%$cm$),
  ('YE', $cm$기록 전용 — 접촉 전 OFAC 스크리닝$cm$, null::numeric, null::numeric, $cm$확인된 초지기 없음$cm$),
  ('OM', $cm$재생 골판지원지 + GCC 수출 기지$cm$, 1620::numeric, 1620::numeric, $cm$Keryas 18만 t × 적용 30% × 3%$cm$),
  ('LK', $cm$인쇄용지·티슈 실증 시장$cm$, 1848::numeric, 1848::numeric, $cm$4개 밀 전량 채택 가정$cm$),
  ('BT', $cm$석회석 원료지 역할만$cm$, 495::numeric, 1650::numeric, $cm$Eco-Tech 50 t/일 × 3~10%$cm$),
  ('NP', $cm$수입 대체 중인 소형 인쇄용지 밀 — NPPI 자체 PCC$cm$, 3375::numeric, 6750::numeric, $cm$4개 밀 인쇄용지 5~10%$cm$),
  ('NZ', $cm$대부분 폐쇄 — Whakatāne 판지·Essity 티슈만 남음$cm$, 6150::numeric, 30750::numeric, $cm$Whakatāne + Essity 20.5만 t × 3~15%$cm$),
  ('PG', $cm$수입 의존 — 수출국 제지사 추적$cm$, null::numeric, null::numeric, $cm$초지기 확인 안 됨$cm$),
  ('TL', $cm$제지공장·충전제 제조사 없음$cm$, null::numeric, null::numeric, $cm$대상 없음$cm$),
  ('BN', $cm$소형 재생 티슈 밀 1곳$cm$, 30::numeric, 135::numeric, $cm$EnEvo 600~900 t × 5~15%$cm$),
  ('KH', $cm$가공업체 중심 — 12만 t 프로젝트 1건$cm$, 1200::numeric, 6000::numeric, $cm$Rongwei 12만 t × 1~5% (가동 미확인)$cm$),
  ('LA', $cm$Sun Paper Laos 포장용지 80만 t — Sun Paper 그룹 단위 접근$cm$, 10000::numeric, 10000::numeric, $cm$80만 t × 적용 25% × 5%$cm$),
  ('AU', $cm$Boyer 복사용지·티슈가 직접 대상$cm$, 5200::numeric, 26000::numeric, $cm$Boyer 26만 t × 2~10%$cm$),
  ('PH', $cm$수입 압박 속 인쇄·티슈 밀$cm$, 16000::numeric, 49000::numeric, $cm$Bataan·Quanta·TIPCO·Fifth Discipline·기타 인쇄 밀 가정 물량$cm$),
  ('SY', $cm$알레포 재생 포장 회복, 티슈 밀은 과거 명목치 — OFAC SDN 스크리닝$cm$, 3360::numeric, 3360::numeric, $cm$티슈 4개 설비 6.72만 t × 5%$cm$)
) as v(country_code, headline_ko, lo, hi, basis_ko)
where cm.country_code = v.country_code
  and cm.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;

notify pgrst, 'reload schema';

select cm.country_code, cm.country_name, cm.priority, cm.headline_ko,
       cm.fcc_potential_low_t, cm.fcc_potential_high_t
from app.country_markets cm
where cm.deleted_at is null
order by case cm.priority when 'high' then 1 when 'medium' then 2 when 'low' then 3 when 'on_hold' then 4 else 5 end,
         cm.country_code;
