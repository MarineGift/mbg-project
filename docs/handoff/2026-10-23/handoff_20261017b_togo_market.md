# Handoff 2026-10-17 (b) — 토고 충전제 + 시장현황 행 (초지기 미확인)

> 앞 문서: `handoff_20261017a_benin_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017b_togo_market.sql` | 필러 3(없을 때), 배경 6(있을 때만), `app.country_markets` TG 행 (priority none) — 밀 생성 없음 |

batch / source: `togo_update_20261017` · 메모 표식 `TG check 2026-10-17`

## 2. 반영
- **필러 (C)**: Scantogo Mines (Heidelberg, Tabligbo — 클링커 150만 t, 원료밀 410 t/h 는 제지용 아님) · WACEM (Diamond Cement 그룹, 120만 t) · POMAR (Pagala 대리석 — 장기 GCC 원료). Cimtogo·Diamond Cement Togo 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 초지기 미확인. 배경: FACAM STAIRWAY (Baguida 2023, 티슈·위생 — 베냉·부르키나파소 판매), SOTOPA (AURA, 구매 원지), IMEP SA (Aného, 상자 2.5만 개/h·라벨 100만 개/h), CivicBag, SAFA PAK (2021 등록), Papeterie Rame-Store (2018 등록)
- **시장현황**: TG none — 가나·베냉과 한 권역. 가나 Delta Paper Mill 이 토고 판매 명시

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017b_togo_market.sql docs/handoff
git commit -m "data: Togo fillers + market row (no paper machine)"
git push origin marinebiogroup
```
