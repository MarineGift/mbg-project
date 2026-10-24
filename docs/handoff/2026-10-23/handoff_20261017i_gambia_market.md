# Handoff 2026-10-17 (i) — 감비아 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261017h_guinea_bissau_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017i_gambia_market.sql` | 배경 4 (있을 때만), `app.country_markets` GM 행 (priority none) — 행 생성 없음 |

batch / source: `gambia_update_20261017` · 메모 표식 `GM check 2026-10-17` · 국가코드 `GM`

## 2. 반영
- 제지용 PCC·GCC 없음 (지질국: 대규모 석회석 매장 미확인), 초지기 없음
- 배경: Gampaper Industry (2016, Kanifing — 수입 원지 종이봉투, 11~50명), Annaf Group, Abacous Group (포장재 유통), Harch Cement (2028 반줄 50만 t 계획 — 미검증)
- 시장현황: GM none. HS 48 수입 2024 약 790만 달러 (영국·모로코·중국·세네갈), CaCO3 수입 2023 565 t (인도·이집트·베트남) — 세네갈과 묶어 관리

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017i_gambia_market.sql docs/handoff
git commit -m "data: The Gambia market row"
git push origin marinebiogroup
```
