# Handoff 2026-10-16 (zza) — 아일랜드 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zz_context_plant_fix.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zza_ireland_fillers.sql` | 필러 1, 배경 8 (있을 때만), `app.country_markets` IE 행 (priority none) — 밀 생성 없음. 수정된 생성기 사용 (배경 행은 기존 plant 키 유지) |

batch / source: `ireland_update_20261016` · 메모 표식 `IE check 2026-10-16`

## 2. 반영
- **필러**: McGraths Limestone Cong (CongCal 10m: CaCO3 98.5%, Fe2O3 0.03%, D50 약 2 μm, 2007 고사양 분쇄·분급 설비 — 후보 1, C). Roadstone·Grolime 회원사 (농업용) 추가 안 함. 제지용 PCC 없음
- **밀**: 마지막 제지공장 Smurfit Clonskeagh 2005 폐쇄 → 생성 없음
  - 배경(있을 때만): Smurfit Westrock 아일랜드 공장들 (글로벌 본사 더블린, 제지공장 57곳·약 830만 t), VPK Limerick, Saica Pack Ashbourne·Dublin, CavanBox, Aldar Tissues, Dawn Paper, Corrugated Containers Ireland, Pakform
- **시장현황**: IE 행 none — Smurfit Westrock 본사·Saica·VPK 유럽 공장으로 가는 창구로 기록

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zza_ireland_fillers.sql docs/handoff
git commit -m "data: Ireland filler + market row (no paper machine)"
git push origin marinebiogroup
```
