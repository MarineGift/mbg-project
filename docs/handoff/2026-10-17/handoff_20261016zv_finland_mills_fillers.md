# Handoff 2026-10-16 (zv) — 핀란드 제지사·충전제·위성 PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zu_sweden_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zv_finland_mills_fillers.sql` | 필러 5, 밀 13(없을 때) + 배경 8(있을 때만), plant 블록, 링크 3, `app.country_markets` FI 행 |

batch / source: `finland_update_20261016` · 메모 표식 `FI check 2026-10-16`

## 2. 반영
- **필러**: Suomen Karbonaatti Lappeenranta (Nordkalk 자회사, 습식 GCC·부유선별 — B) · Nordkalk Finland (PCC 용 생석회 QL — 원료) · **SMI Nordic** Äänekoski (1993, Metsä Fibre CO2)·Tervakoski (위성 PCC, 2025 매출 1,000만 유로·18명 — B, 파트너 메모) · **SCHAEFER KALK Finland** Kuusankoski (현장 PCC, 독립 — 라이선스 후보, B) · Omya Finland (Förby·PCC 과거 이력, C)
  - Nordkalk 가드를 핀란드 한정으로 → SE Köping 행·Suomen Karbonaatti 와 겹치지 않음 (교차검사에서 발견해 이름 순서 조정)
- **밀 / 우선순위**: 1 UPM Kymi · 2 UPM Jämsänkoski · 3 Metsä Board Kyro · 4 Metsä Board Äänekoski · 5 Simpele · 6 Stora Enso Imatra · 7 Metsä Tissue Mänttä (재생섬유 종료·1대 폐쇄) · 8 MM Kotkamills · 9 delfort Tervakoski · 10 Pankaboard
  - 우선순위 없음: Jujo Thermal, UPM Rauma, UPM Tervasaari
  - 배경: UPM Kaukas (2025-10 제지 종료), Metsä Board Tako (2025-06 종료), Kemi, Stora Enso Oulu·Varkaus·Heinola·Anjala, Mondi
- **링크 (active·medium, 호스트 확인 필요)**: SMI → Metsä Board Äänekoski (1993~) · SMI → delfort Tervakoski · SCHAEFER KALK → UPM Kymi
- **시장현황**: FI 행 high, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zv_finland_mills_fillers.sql docs/handoff
git commit -m "data: Finland fillers + mills + satellite PCC links + country market row"
git push origin marinebiogroup
```
