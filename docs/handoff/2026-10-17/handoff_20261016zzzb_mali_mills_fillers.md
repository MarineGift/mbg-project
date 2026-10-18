# Handoff 2026-10-16 (zzzb) — 말리 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzza_mauritania_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzb_mali_mills_fillers.sql` | 필러 1, 밀 2(없을 때, 우선순위 없음) + 배경 4(있을 때만), plant 블록, `app.country_markets` ML 행 (priority none) |

batch / source: `mali_update_20261016` · 메모 표식 `ML check 2026-10-16`

## 2. 반영
- **필러 (C)**: Diamond Cement Mali (클링커 약 100만 t, 석회석 약 6,700만 t — 시멘트용, 품질 미검증). CIMAF·CMM·Carrières et Chaux·SECDO 추가 안 함. 제지용 PCC·GCC 없음
- **밀 (우선순위 없음, 초지기 확인 필요)**: SAP Mali Sotuba (Dahdah 그룹 "종이공장") · SCS Malienne de Cartonnerie Kamalé (2019~ 골판지·시멘트 포대, 계획 2만 t 은 가공 — split, Diamond Cement 포대 공급)
  - 배경: SOCEM, Graphique Industrie, Emball'Print, CMP (유통)
- **시장현황**: ML 행 none. HS 48 수입 2024 약 4,263만 달러 (코트디부아르·가나 54%) — 내륙국, 연안국 제지사 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzb_mali_mills_fillers.sql docs/handoff
git commit -m "data: Mali filler + mills + country market row"
git push origin marinebiogroup
```
