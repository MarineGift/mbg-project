# Handoff 2026-10-16 (zt) — 영국 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zs_france_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zt_uk_mills_fillers.sql` | 필러 4, 밀 10(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` GB 행 |

batch / source: `uk_update_20261016` · 메모 표식 `GB check 2026-10-16` · 국가코드 GB

## 2. 반영
- **필러**: Omya UK Melton (라이선시, FiberLean = FCC 최근접 경쟁기술, B) · SMI Lifford 버밍엄 (SEC 공시 Merchant PCC, MBG 티슈 트랙 파트너 메모, B) · European Calcium Carbonates Westwood Beverley (구 Imerys 백악 GCC·슬러리 — Imerys 2024 매각으로 현 소유주 확인) · Longcliffe (고순도 GCC). Sibelco·Ben Bennett·CEMEX·LKAB 추가 안 함
- **밀 / 우선순위**: 1 Sofidel UK (Hamilton·Baglan·Lancaster) · 2 Essity Prudhoe (2026-04 재생섬유 10만 t 시설) · 3 James Cropper · 4 Holmen Workington (Incada FBB) · 5 Northwood · 6 DS Smith Kemsley · 7 Saica Partington · 8 Shotton Mill (Eren — 라이너 75만 + 티슈 6.7만 t **계획**, split 에만, Modern Karton 과 같은 그룹)
  - 우선순위 없음: WEPA Bridgend, Kimberly-Clark Barrow
  - 배경: **Smurfit Westrock Birmingham SSK (2026-07-27 생산 중단, 약 20만 t)**, Palm Paper, Portals, Mondi
- **시장현황**: GB 행 high (2024 329만 t), FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zt_uk_mills_fillers.sql docs/handoff
git commit -m "data: UK fillers + mills + country market row"
git push origin marinebiogroup
```
