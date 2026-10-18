# Handoff 2026-10-16 (zzzg) — 에티오피아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzf_djibouti_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzg_ethiopia_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` ET 행 |

batch / source: `ethiopia_update_20261016` · 메모 표식 `ET check 2026-10-16`

## 2. 반영
- **필러**: **Min-Tech Dukem** (천연·코팅 CaCO3, 제지 명시, 4.5 t/h ≈ 이론 3.6만 t — 후보 1, B) · **DH Geda Gelan** (2011~, 미분 CaCO3·돌로마이트 3만 t, 제지 명시 — 후보 2, B) · MIDROC / MBI Awash 7 Kilo (2025-05 코팅 CaCO3 1.8만 t, 플라스틱용 — C) · Plaspia (C). CITCO 브로슈어 제품 추가 안 함, UNIDO 1,500 t PCC 타당성 메모. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Purewood Dukem (티슈 1만 + 크라프트 1.5만 + 판지 7,500 = 3.25만 t, 회사 발표 — split) · 2 EPPSC Wonji (1963, 정부 70%·IFC 30%, 인쇄·필기 약 1만 t — 가드에 "Wonji Pulp and Paper" 포함) · 3 Suzo Gelan (재생 티슈 1만 t+, 회사 주장)
  - 우선순위 없음: Kite Manufacturing (초지기 확인)
  - 배경: Zak Green (Hawassa), Safe Tissue (Akaki Kality)
  - Gelan 의 Suzo·Kite → 소유사 정규식 분리
- **시장현황**: ET 행 low, FCC 1,575 ~ 2,625 t. GCC 업체와 제지사가 Dukem·Gelan 에 붙어 있어 소규모 OEM 시험에 유리, 지부티항 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzg_ethiopia_mills_fillers.sql docs/handoff
git commit -m "data: Ethiopia fillers + mills + country market row"
git push origin marinebiogroup
```
