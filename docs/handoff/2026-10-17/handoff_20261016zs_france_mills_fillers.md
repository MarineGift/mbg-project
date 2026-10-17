# Handoff 2026-10-16 (zs) — 프랑스 제지사·충전제·위성 PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zr_portugal_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zs_france_mills_fillers.sql` | 필러 2, 밀 13(없을 때) + 배경 22(있을 때만), plant 블록, 링크 1, `app.country_markets` FR 행 |

batch / source: `france_update_20261016` · 메모 표식 `FR check 2026-10-16`

## 2. 반영
- **필러**: Omya SAS Omey (약 8개 사업장·340명, 라이선시, B) · Specialty Minerals France (MTI 2022 공시 위성 PCC: Saillat-sur-Vienne·Quimperlé — B, satellite, **MBG 티슈 트랙 파트너(NDA)** 메모)
  - **Imerys 제지용 광물사업 2024-07 Flacks Group 매각** (24개 공장, 2023 매출 3.7억 유로, 1.5억 유로) → 시장현황에 기록, Flacks 운영사 후속 조사 필요. Lhoist·Carmeuse 추가 안 함
- **밀 / 우선순위**: 1 Sylvamo Saillat (통합 UWF, 같은 도시에 SMI 위성) · 2 Clairefontaine Étival · 3 Essity Kunheim (R&D 거점) · 4 Lucart Laval-sur-Vologne · 5 WEPA Bousbecque · 6 Sofidel Frouard · 7 Mandeure · 8 Papeteries des Vosges · 9 ICT France Pannes · 10 Ahlstrom France
  - 우선순위 없음: Norske Skog Golbey (PM1 골판지원지 전환), Condat (Lecta, 축소·상태 확인), Kimberly-Clark Villey
  - 배경 22곳 (Essity Gien·Hondouville·Le Theil, Canson, Everbal, Zuber Rieder, Vizille, Gascogne, 티슈 4, 골판지원지 10)
  - 같은 도시: Laval-sur-Vologne (Lucart·Papeteries des Vosges), Bousbecque (WEPA·Ahlstrom) → 소유사 정규식 분리
- **링크**: SMI France → Sylvamo Saillat (active·medium, 2022 공시 — 2026 상태 확인)
- **시장현황**: FR 행 high, FCC 산정 보류 (공장별 생산량 미공개)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zs_france_mills_fillers.sql docs/handoff
git commit -m "data: France fillers + mills + SMI Saillat link + country market row"
git push origin marinebiogroup
```
