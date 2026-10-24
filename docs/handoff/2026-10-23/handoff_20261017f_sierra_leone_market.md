# Handoff 2026-10-17 (f) — 시에라리온 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261017e_liberia_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017f_sierra_leone_market.sql` | 필러 1(없을 때), 배경 4(있을 때만), `app.country_markets` SL 행 (priority none) — 밀 생성 없음 |

batch / source: `sierra_leone_update_20261017` · 메모 표식 `SL check 2026-10-17` · 국가코드 `SL`

## 2. 반영
- **필러 (C)**: Kalmax Resources Freetown (석회석·광물 채굴·수출 주장 — 과거 UNIDO 의 석회석 부족 평가와 상충, 광구·순도·생산 검증 필요). 조개껍데기 석회 (비공식, 건설용) 메모. CaCO3 수입 2018 2,745 t, 2023 주로 튀니지·이집트. 제지용 PCC·GCC 없음
- **밀**: 초지기 없음. 배경: Develop Manufacturing (Devmanco — 웹에 레바논 그룹 주소 혼재), Flora Tissue (2024, Devmanco 계열), Saltucks Investment (복사용지·티슈 생산 계획 — 설계 단계 접점), Dorlbee Group (인쇄)
- **시장현황**: SL none. 2023 티슈 점보롤 36 t 구매 문의 → 수입 원지 가공 모델

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017f_sierra_leone_market.sql docs/handoff
git commit -m "data: Sierra Leone filler + market row (no paper machine)"
git push origin marinebiogroup
```
