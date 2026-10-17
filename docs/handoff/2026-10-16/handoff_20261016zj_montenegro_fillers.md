# Handoff 2026-10-16 (zj) — 몬테네그로 원료 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zi_bulgaria_update.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zj_montenegro_fillers.sql` | 필러 2 (석회석 원료), 배경 10 (있을 때만), `app.country_markets` ME 행 (priority none) — 밀 생성 없음 |

batch / source: `montenegro_update_20261016` · 메모 표식 `ME check 2026-10-16`

## 2. 반영
- **필러 (원료만)**: Nimont Bar (Volujica 석회석, 골재 450만 t+ 수출, Bar 항) · Maljat Stone Danilovgrad (석재). 제지용 PCC·GCC 없음. 인근 공급원 메모: Omya Specialty Materials Serbia, STARAC 크로아티아 (White Rock 1~100 μm, 제지 슬러리 명시)
- **밀**: Berane 공장 폐쇄 후 초지기 없음 (UNECE 보고) → 생성 없음
  - 배경(있을 때만): TRING, Montcarton, Oscar Co, PG-PAK, Montekarton, LEGEND, BOY IV, Micromedia, Himpeks, Berane (폐쇄)
  - Femić 는 세르비아 기업이라 제외
- **시장현황**: ME 행 none

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zj_montenegro_fillers.sql docs/handoff
git commit -m "data: Montenegro raw-material fillers + market row (no paper machine)"
git push origin marinebiogroup
```

## 4. 후속 후보 (크로아티아·세르비아 조사 시)
STARAC (HR), Calcit Lika Gospić (HR), Omya Specialty Materials (RS)
