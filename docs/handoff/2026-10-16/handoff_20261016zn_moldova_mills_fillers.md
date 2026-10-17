# Handoff 2026-10-16 (zn) — 몰도바 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zm_romania_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zn_moldova_mills_fillers.sql` | 필러 2, 밀 1(없을 때) + 배경 6(있을 때만), plant 블록, `app.country_markets` MD 행 |

batch / source: `moldova_update_20261016` · 메모 표식 `MD check 2026-10-16`

## 2. 반영
- **필러**: CALCAR Beleavinți (석회석 연 약 100만 m³, CaCO3 97~99% — 원료) · LIORMAX Cricova (석회석 필러 월 5천 t+, 2025 현대화 — 가공 파트너). CALCAR 가드는 'calcar'(루마니아어 '석회석')가 다른 나라 이름에 걸리지 않게 사이트명 포함으로 좁힘. 제지용 PCC·GCC 없음
- **밀**: 1 CANDELUX-COM Chișinău (재생 티슈 원지, 몰도바 유일 원지 공정)
  - 배경(있을 때만): MITRA-GRUP (Milta), Combinatul de Articole din Carton, CARTNORD (종이포대 4,500만 개·유통 8천 t), MoldPack, Pergament, MOLDCARTON (청산)
- **시장현황**: MD 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zn_moldova_mills_fillers.sql docs/handoff
git commit -m "data: Moldova fillers + mill + country market row"
git push origin marinebiogroup
```
