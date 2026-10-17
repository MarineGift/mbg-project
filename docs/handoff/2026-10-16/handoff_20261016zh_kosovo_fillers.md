# Handoff 2026-10-16 (zh) — 코소보 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zg_bulgaria_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zh_kosovo_fillers.sql` | app.countries XK 행 추가(없을 때), 필러 1, 배경 12(있을 때만), `app.country_markets` XK 행 (priority none) — 밀 생성 없음 |

batch / source: `kosovo_update_20261016` · 메모 표식 `XK check 2026-10-16`

## 2. 반영
- **국가코드 XK**: ISO 3166-1 정식 코드가 아니어서 fix_20261015q 의 249개 목록에 없음 → 시드 0번에서 `app.countries (code, name_en)` 에 ('XK','Kosovo') 추가. country_markets 에는 FK 없음 (정규식 `^[A-Z]{2}$` 만)
- **필러**: Alba Lime Factory Hani i Elezit (2025 Maerz PFR 석회로 — 석회만, 향후 PCC 라인 후보). 추가 안 함: TITAN Sharrcem, New Kosova Lime, Green Power, Fox Marble. 제지용 PCC·GCC 없음
- **밀**: 초지기 확인 없음 → 생성 없음
  - 배경(있을 때만): Top Soft Papers, M-Group, KOHA, Mare Group (티슈 가공), ORTO Paper, LB Group, Papperlapapp, DG PACK (이탈리아·그리스·튀르키예 원지), Hilzna Plus, Nord Ecopack, Nori Group, DAKU P S (펄프·제지 업종 등록, 직원 1명)
- **시장현황**: XK 행 none

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zh_kosovo_fillers.sql docs/handoff
git commit -m "data: Kosovo country row + lime filler + market row (no paper machine)"
git push origin marinebiogroup
```
