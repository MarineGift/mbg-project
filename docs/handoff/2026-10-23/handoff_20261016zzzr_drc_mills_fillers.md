# Handoff 2026-10-16 (zzzr) — 콩고민주공화국 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzq_malawi_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzr_drc_mills_fillers.sql` | 필러 3, 밀 3(없을 때, 우선순위 없음) + 배경 6(있을 때만), plant 블록, `app.country_markets` CD 행 (priority none) |

batch / source: `drc_update_20261016` · 메모 표식 `CD check 2026-10-16` · 국가코드 `CD`

## 2. 반영
- 모든 메모 끝에 `Screen against UN and US DR Congo sanctions lists.`
- **필러 (C)**: JDE DRC Lubumbashi (석회석 분말 75 μm, 5,400 t/일 주장 — 제지용보다 매우 굵음) · Datong SARL (98% 초과 주장, 자체 설비 미확인, 잠비아 번호) · GCK Kakontwe (2011, 구 Gécamines 석회석·석회·시멘트). ABICOM (유통)·PPC Barnet (시멘트 125만 t) 추가 안 함. 제지용 PCC·GCC 없음
- **밀 (초지기 확인 필요)**: All Pack Industries Kingabwa (재생 크라프트·골판지·화장지 생산 주장) · LANI Services Lubumbashi (티슈, D&B 매출 추정 약 623만 달러) · Nduw's Family Kolwezi (100% 재생 티슈, 2025-02 장관 방문)
  - 배경: APPI, BOPETO, cPack (Congo Store), WRITE SARL Goma, EBENEZER (Maluku 계획, 월 15만 t 주장 — 미검증), MPC·Instaprint·Lubum Link (D&B 업종 분류)
- **시장현황**: CD none. 2019 생산 약 3천 t·수입 약 1.3만 t (FAO). 2026-05 서부 티슈 수입 제한 연장 → 현지 원지 투자 유인

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzr_drc_mills_fillers.sql docs/handoff
git commit -m "data: DR Congo fillers + mills + market row"
git push origin marinebiogroup
```
