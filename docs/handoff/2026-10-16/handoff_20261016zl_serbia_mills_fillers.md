# Handoff 2026-10-16 (zl) — 세르비아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zk_bosnia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zl_serbia_mills_fillers.sql` | 필러 5, 밀 3(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` RS 행 |

batch / source: `serbia_update_20261016` · 메모 표식 `RS check 2026-10-16`

## 2. 반영
- **필러**: Beaz Plus Aranđelovac (5 μm 등급 D50 1.7, 제지 명시 — 후보 1, B) · ABM International Palić·Kučevo (6만 + 20만 t, Ducalcit 1 D50 1.8~2.2 — 대량 위탁생산 후보, B) · DNV-Micron Raška · Novkal Aranđelovac (3.5만 t) · **Omya Venčac / Omya Specialty Materials** Aranđelovac (라이선시, 몬테네그로·보스니아 보고서에서 공급 연락처로 반복 등장, B). Nutra (유통) 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Drenik ND 베오그라드 (티슈 3라인, 그룹 11만 t — 헝가리 Szolnok 포함이라 split 에만) · 2 Umka (재생 코팅 백판지 22만 t) · 3 Smurfit Westrock Beograd (구 Fabrika Hartije, 재생 라이너 12만 t)
  - 배경(있을 때만): Veropapir, Swiss Papier, Inter-Papir, Litopapir, Intertron, Papircoop, Avala Ada
- **시장현황**: RS 행 medium, FCC 9,000 ~ 18,000 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zl_serbia_mills_fillers.sql docs/handoff
git commit -m "data: Serbia fillers + mills + country market row"
git push origin marinebiogroup
```
