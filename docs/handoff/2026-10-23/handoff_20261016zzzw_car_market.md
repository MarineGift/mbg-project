# Handoff 2026-10-16 (zzzw) — 중앙아프리카공화국 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261016zzzv_south_sudan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzw_car_market.sql` | 배경 7 (있을 때만), `app.country_markets` CF 행 (priority none) — 행 생성 없음 |

batch / source: `car_update_20261016` · 메모 표식 `CF check 2026-10-16` · 국가코드 `CF`

## 2. 반영
- 메모 끝에 `Screen against UN and US Central African Republic sanctions lists.`
- 제지용 PCC·GCC 없음, 초지기 없음
- 배경 (방기): Papeterie Akram GR. Skaiki, Papeterie Papyrus, Dauphin Royal, Imprimerie Centrafricaine, IPC, IPM, Vopijus
- 시장현황: CF none. HS 48 수입 2024 약 644만 달러 (말리·코트디부아르·카메룬·중국·프랑스)

## 3. 후속 (카메룬 CM 보고서 시)
- SAMCO Paper (Limbe, 1992, Ombe 재단공장 — CAR·차드·적도기니 고객) 배경 행 반영

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzw_car_market.sql docs/handoff
git commit -m "data: Central African Republic market row"
git push origin marinebiogroup
```
