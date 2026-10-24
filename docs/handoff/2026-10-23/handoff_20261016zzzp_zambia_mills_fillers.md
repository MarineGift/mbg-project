# Handoff 2026-10-16 (zzzp) — 잠비아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzo_angola_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzp_zambia_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 13(있을 때만), plant 블록, `app.country_markets` ZM 행 |

batch / source: `zambia_update_20261016` · 메모 표식 `ZM check 2026-10-16`

## 2. 반영
- **필러 (C)**: Calcite Ltd Lusaka (미분·코팅 CaCO3, 제지 용도 — 후보 1) · Handyman's Lime Masaiti (Carmeuse 2017~, Maerz PFR 생석회 600 t/일 — PCC 원료·그룹 연계, 가드에 국가 한정) · Limestone Resources (구 Ndola Lime, 생석회 500 t/일, 2026-05-28 ZCCM-IH·Wonderful Group 합작 Ndola Lime (2026) USD 3,000만) · Changzhou Zambia (파쇄 3,000 t/일·석회 600 t/일). Clean Lime 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Book Hut Lusaka (2021-06 Scan Machineries 턴키, 더블와이어 2,600 mm, 70~250 gsm 라이너·골심지·화이트탑 — 생산량 미공개) · 2 Zambezi Paper Mills Ndola (1981~, 재생 티슈·필기용지·라이너, 과거 티슈 10 t/일)
  - 우선순위 없음 (초지기 확인): Zambia Huiyu Chibombo, Falcom Paper Mills Kanakantapa (폐지 수입 기록)
  - 배경 13: Sobi, Yasha, PurePly, IMCO & BISCO, Fairy, Cloud 9, Premium Pure, Unity Packages, ICZ, Boxpack, Devsai, Nisco / Best Pack, 구 Nampak Zambia (DLPG)
- **시장현황**: ZM 행 low, FCC 산정 보류. 종이 관련 수입 약 1.4억 달러 (2021)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzp_zambia_mills_fillers.sql docs/handoff
git commit -m "data: Zambia fillers + mills + country market row"
git push origin marinebiogroup
```
