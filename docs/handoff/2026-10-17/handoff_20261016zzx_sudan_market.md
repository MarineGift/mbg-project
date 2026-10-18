# Handoff 2026-10-16 (zzx) — 수단 충전제 + 시장현황 행 (내전 보류)

> 앞 문서: `handoff_20261016zzw_libya_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzx_sudan_market.sql` | 필러 2(없을 때), `app.country_markets` SD 행 (priority none) — 밀 행 없음 |

batch / source: `sudan_update_20261016` · 메모 표식 `SD check 2026-10-16`

## 2. 반영 — 내전 보류
- 모든 메모 끝에 `WAR RISK: civil war since 2023 (...), screen US and EU Sudan conflict sanctions before any contact.`
- **필러 (C)**: Sudan Chemical (탄산칼슘·대리석 칩 공급 — 제품 페이지에 인도 제조사·+91 → 현지 제조사 아님, 유통) · Nile Cement Rabak (Carawan, Al-Jabalian 석회석 약 2.5억 t — 장기 원료). 정부 투자목록 20 t/일 탄산칼슘 사업 (미건설) 메모. 제지용 PCC·GCC 없음
- **밀**: 이번에 받은 두 보고서가 모두 충전제 보고서 (같은 내용 반복) → 제지사 정보 없음, 밀 행 생성 안 함
- **시장현황**: SD 행 none. 이집트 GCC·이집트 제지사 (QPIC 수단 수출) 경유로 메모

## 3. 후속
- 수단 제지기업 보고서 필요
- **EG 보완**: Arab Company for Calcium Carbonate (2003~, 코팅·비코팅 GCC, 공장 2곳) 필러 행 추가 · Alfacarb 공장 위치 (10th of Ramadan vs Minya) 확인

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzx_sudan_market.sql docs/handoff
git commit -m "data: Sudan fillers + market row (war hold)"
git push origin marinebiogroup
```
