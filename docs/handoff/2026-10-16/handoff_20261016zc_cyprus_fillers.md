# Handoff 2026-10-16 (zc) — 키프로스 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zb_turkiye_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zc_cyprus_fillers.sql` | 필러 2 (원료), 배경 11 (있을 때만), `app.country_markets` CY 행 (priority none) — 밀 생성 없음 |

batch / source: `cyprus_update_20261016` · 메모 표식 `CY check 2026-10-16`

## 2. 반영
- **필러 (원료만)**: Peletico Strovolos (사료용 FILLER K, 150 μm) · Latomia Latouros Dali (석회석 채석·골재, 계열 Elmeni). 추가 안 함: Chr. Peppos, Avraam Pittakis, Vassiliko Cement, Neochrom. 제지용 PCC·GCC 없음
- **밀**: 초지기 확인 없음 → 생성 없음
  - 배경(있을 때만): Nikyr, Harco (티슈 가공), P&S Carton (현지 상자 약 60%, 2026 지분 51% 매각 발표), Unipakcyprus (INDEVCO), AMS Box, Caterways, Emes, G. P. Braspaper (종이·펄프 무역), 북키프로스 Atensa·Cyprus Printing Global·Abatay
- **시장현황**: CY 행 none — 직접 수요 없음, INDEVCO 제지공장·Braspaper 공급처로 가는 창구로 기록

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zc_cyprus_fillers.sql docs/handoff
git commit -m "data: Cyprus raw-material fillers + country market row (no paper machine)"
git push origin marinebiogroup
```
