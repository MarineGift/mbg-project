# Handoff 2026-10-16 (r) — 몽골 제지사 + 시장현황 행

> 앞 문서: `handoff_20261016o_sv_jm_bo_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016r_mongolia_mills.sql` | 밀 3(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` MN 행. 필러 없음 |

batch / source: `mongolia_update_20261016` · 메모 표식 `MN check 2026-10-16`

## 2. 반영
- **충전제 보고서 로딩 실패** — Khutul 탄산칼슘 신규 투자 프로젝트만 언급됨 → 필러 행 없음, 보고서 재요청 필요
- **밀**: 1 Eco Tsaas 울란바토르 (재생 갈색 포장원지 일 30 t → 9,000 t 계산값) · 2 Urin Trade (러시아산 펄프 티슈 일 6 t → 1,800 t 계산값, 원지 자체 제조 확인 필요) · Sain Tsaas (폐지 20~25 t/일 처리, 가동 미확인 — 우선순위 없음)
  - 배경(있을 때만): Khugjil Trade (Ariun), Eco Pack Mongolia, Finpack, Selenge Press
- **시장현황**: MN 행 low, FCC 270 ~ 450 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016r_mongolia_mills.sql docs/handoff
git commit -m "data: Mongolia mills + country market row"
git push origin marinebiogroup
```
