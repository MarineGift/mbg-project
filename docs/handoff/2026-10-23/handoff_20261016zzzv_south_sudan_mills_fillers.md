# Handoff 2026-10-16 (zzzv) — 남수단 충전제·제지사 + 시장현황 행

> 앞 문서: `handoff_20261016zzzu_uganda_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzv_south_sudan_mills_fillers.sql` | 필러 1, 밀 2(없을 때, 우선순위 없음) + 배경 2(있을 때만), plant 블록, `app.country_markets` SS 행 (priority none) |

batch / source: `south_sudan_update_20261016` · 메모 표식 `SS check 2026-10-16` · 국가코드 `SS`

## 2. 반영
- 모든 메모 끝에 `Screen against UN and US South Sudan sanctions lists.`
- **필러 (C)**: Upper Nile Cement Kapoeta (시멘트 48만 t 주장 — 독립 검증 없음). 2024 중국산 GCC-11·PCC-12, 우간다산·코팅 CaCO3 소량 수입 메모. 제지용 PCC·GCC 없음
- **밀 (초지기 검증 필요)**: Gentle Hubs Juba (버진펄프 티슈, 웹에 펄프 준비·시트 형성 공정 — 1순위 확인 대상) · PAL Investment Juba (2022, 티슈·점보롤·종이컵 — 웹 수치 미검증)
  - 배경: Carnak, Ezgiamin (수입업체)
- **시장현황**: SS none. HS 48 상위 5개국 약 1,184만 달러 (2024, 케냐·우간다 중심) → 우간다·케냐 제지사 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzv_south_sudan_mills_fillers.sql docs/handoff
git commit -m "data: South Sudan filler + mills + market row"
git push origin marinebiogroup
```
