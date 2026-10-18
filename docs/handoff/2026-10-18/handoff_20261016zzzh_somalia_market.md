# Handoff 2026-10-16 (zzzh) — 소말리아 충전제 + 시장현황 행 (초지기 미확인)

> 앞 문서: `handoff_20261016zzzg_ethiopia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzh_somalia_market.sql` | 필러 2(없을 때), 배경 4(있을 때만), `app.country_markets` SO 행 (priority none) — 밀 생성 없음 |

batch / source: `somalia_update_20261016` · 메모 표식 `SO check 2026-10-16`

## 2. 반영
- 모든 메모 끝에 `Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.`
- **필러 (C)**: Red Sea Cement Berbera (과거 약 20만 t, 2019 비가동 — 원료·유휴 부지 후보) · Berbera Marble and Granite (대리석 — GCC 원료 후보, 품질 미검증). 제지용 PCC·GCC 없음
- **밀**: 초지기 미확인 → 생성 없음. 배경 (가공): Nadiif Paper Mills (티슈, HS 4803 원지 롤 수입), AADCO Hargeisa (복사용지·공책, 에티오피아·지부티 판매), Noor Industrials (Alpha Plus 냅킨), Sompack (상자)
- **시장현황**: SO none. Berbera 항·경제특구 (2023) → 에티오피아 회랑, 장기 GCC·물류 후보

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzh_somalia_market.sql docs/handoff
git commit -m "data: Somalia fillers + market row (no paper machine)"
git push origin marinebiogroup
```
