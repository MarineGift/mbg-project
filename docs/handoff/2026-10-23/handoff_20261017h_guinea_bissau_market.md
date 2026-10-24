# Handoff 2026-10-17 (h) — 기니비사우 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261017g_guinea_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017h_guinea_bissau_market.sql` | 배경 7 (있을 때만), `app.country_markets` GW 행 (priority none) — 행 생성 없음 |

batch / source: `guinea_bissau_update_20261017` · 메모 표식 `GW check 2026-10-17` · 국가코드 `GW`

## 2. 반영
- 제지용 PCC·GCC 없음, 초지기 없음
- 배경: Sankofa Works (Softy — 구매 점보롤 재권취, 계획 자본 FCFA 3,280만), INACEP (1978 국영 인쇄), Kamatchol, Bcassama, Mille Impressão, Copytop, Central Gráfica (나머지 인쇄업체 360v2·INNOVA·Alvalade·Nô Gráfica 는 요약에만)
- IndexBox 의 펄프 273 t 추정치는 공장명 없음 → 메모만
- 시장현황: GW none — 세네갈과 묶어 관리

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017h_guinea_bissau_market.sql docs/handoff
git commit -m "data: Guinea-Bissau market row"
git push origin marinebiogroup
```
