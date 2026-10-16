# Handoff 2026-10-16 (k) — 도미니카공화국 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016j_colombia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016k_dominican_mills_fillers.sql` | 필러 5, 밀 2(없을 때) + 배경 13(있을 때만), plant 블록, `app.country_markets` DO 행 |

batch / source: `dominican_update_20261016` · 메모 표식 `DO check 2026-10-15` · 제지기업 보고서는 4개 버전 중 최신(Toscotec PM2 확인본) 기준

## 2. 반영
- **필러**: Industrias GAT Haina (2.5 μm 초미세, 원석 99%+, 후보 1 — PNCC 는 PCC 로 보지 않음) · DOCALSA El Pomier (20~100 μm) · INREGOSA Santiago (325 mesh) · Industrias Dominca · Belfond Barahona (고순도 석회석 → 미국 INCOA Theodore, AL)
  - 추가 안 함: GEOTEK (석회 프로젝트), INCOA (미국 공장 — 필요 시 US 로)
- **밀**: 1 César Iglesias Santo Domingo (PM1 약 1.5만 t, Toscotec PM2 AHEAD 1.8 3만 t+ 2026 목표 — capacity 는 PM1, PM2 는 split 2번째 줄) · 2 Industria del Papel Sido La Guáyiga (재활용 크라프트·티슈, 6,480 t 은 기간 불명이라 미사용)
  - 배경(있을 때만): INPADOM, INPACA (초지기 미확인), Industrias Nigua, Grupo Formosa, AG Supply, Velvety, Kimberly-Clark, Familia (가공), Cartones del Caribe, HUED, UPI, Pico Duarte, Smurfit Westrock (골판지 가공)
- **시장현황**: DO 행 medium, FCC 1,350 ~ 2,250 t (PM1+PM2 × 3~5%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016k_dominican_mills_fillers.sql docs/handoff
git commit -m "data: Dominican Republic fillers + mills + country market row"
git push origin marinebiogroup
```
