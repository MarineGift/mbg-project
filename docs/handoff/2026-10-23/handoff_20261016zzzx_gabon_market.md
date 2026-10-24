# Handoff 2026-10-16 (zzzx) — 가봉 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zzzw_car_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzx_gabon_market.sql` | 필러 2(없을 때), 배경 3(있을 때만), `app.country_markets` GA 행 (priority none) — 밀 생성 없음 |

batch / source: `gabon_update_20261016` · 메모 표식 `GA check 2026-10-16`

## 2. 반영
- **필러 (C)**: CIMAF Gabon Méba (석회석 허가 약 9.20 km², 2024-02-24 만료 — 갱신 확인) · CIMGABON Ntoum (약 1.99 km², 1979~2054). CIMAF 가드는 국가 한정 (ML·MR·TD 에도 CIMAF 언급). Kéri (Mouila) 는 백운석 메모. 제지용 PCC·GCC 없음, Omya·MTI·Imerys·Sibelco 공장 없음
- **밀**: 초지기 없음. 배경: SATOGA (Oloumi, 티슈 가공 — 코트디부아르산 종이 수입 기록), Cartonnerie du Gabon (Nkok 특구 2023, FOBERD 그룹, 25명), PROPACK Gabon
- **시장현황**: GA none. HS 48 공급 주로 중국·프랑스·튀니지·튀르키예·모로코 (2024)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzx_gabon_market.sql docs/handoff
git commit -m "data: Gabon fillers + market row (no paper machine)"
git push origin marinebiogroup
```
