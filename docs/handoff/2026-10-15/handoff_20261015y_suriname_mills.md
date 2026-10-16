# Handoff 2026-10-15 (y) — 수리남 제지사(초지기 미확인) + 시장현황 행

> 앞 문서: `handoff_20261015x_jamaica_mills.md` · 2026-10-15 알파벳은 z 하나 남음

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015y_suriname_mills.sql` | 밀 1(없을 때, 우선순위 없음) + 배경 6(있을 때만), plant 블록, `app.country_markets` SR 행. 필러 없음 |

batch / source: `suriname_update_20261015` · 메모 표식 `SR check 2026-10-15`

## 2. 반영
- **밀**: Yeung Papier Fabriek (Wanica) — D&B 펄프·종이·판지 공장 분류 유일, 초지기·지종 미확인 → 우선순위 없음
- **배경(있을 때만)**: Shen Long (Snow-Kleen, 2018 월 4만 팩·점유율 약 60%, 2024 점보 원지 수입 확인 → 가공업체), Devnan, Clear Packaging & Recycling, Q-Pack, C W K Plastic, Wanda / Wang Da Paper
- **필러 없음**: 충전제 보고서 미제공, 제지용 PCC·GCC 업체 없음
- **시장현황**: SR 행 low — 2024 티슈 원지 수입 1,934 t (중국 83.6%), 위생용지 완제품 3,735 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015y_suriname_mills.sql docs/handoff
git commit -m "data: Suriname listed mill + converters + country market row"
git push origin marinebiogroup
```
