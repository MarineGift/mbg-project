# Handoff 2026-10-17 (e) — 라이베리아 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261017d_cote_divoire_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017e_liberia_market.sql` | 배경 5 (있을 때만), `app.country_markets` LR 행 (priority none) — 행 생성 없음 |

batch / source: `liberia_update_20261017` · 메모 표식 `LR check 2026-10-17`

## 2. 반영
- 제지용 PCC·GCC 없음 — CEMENCO (1968, 분쇄 65 t/h)·Fouta Cement (50만 t+) 는 수입 클링커 시멘트 분쇄라 원료 후보도 아님 → 배경 행으로만
- 초지기 없음. 배경: National Toiletries (Paynesville — HS 4803 티슈 원지 롤 수입, 가공 가능성 높음), Doito Soft (Congo Town, 버진펄프 티슈·점보롤 — 초지기 미확인), Liberia Paper Products and Carton Factory (상자, 크라프트라이너 수입)
- 과거 UNIPAC·VAANG-AHN (1985 UNIDO) 메모만, 행 없음
- 시장현황: LR none. HS 48 수입 2024 약 1,197만 달러, HS 4818 약 2천 t (화장지 421 t). 가나 Delta Paper Mill 판매

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017e_liberia_market.sql docs/handoff
git commit -m "data: Liberia market row (no paper machine)"
git push origin marinebiogroup
```
