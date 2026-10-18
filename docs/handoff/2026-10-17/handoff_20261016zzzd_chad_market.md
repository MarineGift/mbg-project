# Handoff 2026-10-16 (zzzd) — 차드 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zzzc_niger_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzd_chad_market.sql` | 필러 1, 배경 3 (있을 때만), `app.country_markets` TD 행 (priority none) — 밀 생성 없음 |

batch / source: `chad_update_20261016` · 메모 표식 `TD check 2026-10-16`

## 2. 반영
- **필러 (C)**: CIM-Tchad Baoré (2026-03-06 CIMAF 70%·정부 30% 로 구 SONACIM 자산 인수, 석회석 광산·시멘트 약 20만 t, 2007 석회석 약 700만 t — 제지 품질 미검증). CIMAF Tchad Lamadji (분쇄 50만 t) 추가 안 함. CaCO3 수입 2024 약 246 t. 제지용 PCC·GCC 없음
  - SONACIM 과 CIM-Tchad 는 같은 자산 → 한 행 (가드에 sonacim·baoré 포함)
- **밀**: 초지기 없음. 배경: ASHIA PACK (포장), IDT, Bouchra Printing (인쇄)
- **시장현황**: TD 행 none. 종이·판지 수입 2024 약 588 t (FAO). Douala–N'Djamena 회랑 → 카메룬·나이지리아 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzd_chad_market.sql docs/handoff
git commit -m "data: Chad filler + market row (no paper machine)"
git push origin marinebiogroup
```
