# Handoff 2026-10-17 (c) — 부르키나파소 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261017b_togo_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017c_burkina_market.sql` | 필러 2(없을 때), 배경 6(있을 때만), `app.country_markets` BF 행 (priority none) — 밀 생성 없음 |

batch / source: `burkina_update_20261017` · 메모 표식 `BF check 2026-10-17` · 국가코드 `BF`

## 2. 반영
- **필러 (C)**: SOFANEC Bobo-Dioulasso (돌로마이트 파쇄·선별 — Mg 높음, CaCO3 확인) · Carrières et Mines du Burkina (Dandé 4·5 돌로마이트질 석회석 허가). AF'Gri-culture (판매상), CIMAF Burkina (분쇄 2곳 100만 t), Bobo Diamond Cement, Fluent Burkina (코트디부아르 수출 계획 100만 t) 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 초지기 없음. 배경: SONACEB (판지·포장), Faso Sachets, Kabre Bassirou (D&B 분류만), Impricolor, SOGECOP, Prodiconseil (아비장·로메·테마항 경유 공급)
- **시장현황**: BF none. HS 48 수입 2024 약 6,002만 달러 (코트디부아르·중국·가나), 골심지 HS 480810 약 1.4천 t

## 3. 후속 (베냉 제지 보고서 시)
- WAPACK Industries (베냉 Sèmè-Podji, 골판지·종이봉투 연 1.8만 t 발표, 부르키나 공급) 배경 행 반영

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017c_burkina_market.sql docs/handoff
git commit -m "data: Burkina Faso fillers + market row (no paper machine)"
git push origin marinebiogroup
```
