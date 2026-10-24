# Handoff 2026-10-16 (zzzq) — 말라위 충전제 + 시장현황 행 (초지기 미확인)

> 앞 문서: `handoff_20261016zzzp_zambia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzq_malawi_market.sql` | 필러 2(없을 때), 배경 6(있을 때만), `app.country_markets` MW 행 (priority none) — 밀 생성 없음 |

batch / source: `malawi_update_20261016` · 메모 표식 `MW check 2026-10-16`

## 2. 반영
- **필러 (C)**: Shayona Cement Kasungu (1994, 시멘트 1,600 t/일 — 자체 석회석) · Cement Products Njeleza (Mangochi, MWEITI). Bwanje·Kulimba·OG Quarry (과거 광업권) 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 초지기 미확인 → 생성 없음. 배경: Zamm Investments (Cool Touch — virgin·100% 재생 티슈, 초지기 확인 필요), Andrex Industries Blantyre (티슈·노트), Unicare (Silky), DLPG Malawi (구 Nampak Malawi — 잠비아 판지로 음료 카톤 가공), Kris Offset (상자·난좌), Capital Printing Press
- **시장현황**: MW none. HS 48 수입 2024 약 7,661만 달러 (남아공·이탈리아·인도·짐바브웨·잠비아)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzq_malawi_market.sql docs/handoff
git commit -m "data: Malawi fillers + market row (no paper machine)"
git push origin marinebiogroup
```
