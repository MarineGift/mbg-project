# Handoff 2026-10-16 (v) — 타지키스탄 제지사 + 시장현황 행

> 앞 문서: `handoff_20261016u_russia_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016v_tajikistan_mills.sql` | 밀 3(없을 때, 우선순위 없음) + 배경 6(있을 때만), plant 블록, `app.country_markets` TJ 행. 필러 없음 |

batch / source: `tajikistan_update_20261016` · 메모 표식 `TJ check 2026-10-16`

## 2. 반영
- **충전제 보고서 내용 없음** ("Searched 24 websites" 만 표시) — Karon-Calcite·Marmar Stone (GCC 원료) 이름만 언급 → 필러 행 없음, 재요청 필요
- **밀 (초지기 미확인 → 우선순위 없음)**: Kogazi Tojik Khujand (종이·판지 공장 등재, 폐지 재활용) · Kogazi Sugd · Durakhshon Buston (티슈 월 50 t 원료, 색지 월 20 t)
  - Kogazi Tojik 가드의 소유사 정규식을 좁혀 Kogazi Sugd 행과 섞이지 않게 함
  - 배경(있을 때만): Quttii Tojik (상자, 15 t/일 원료, 2026-03 2단계), Cekhi Kartonbarori Isfara, ALFA PET, Afzaliyat Grupp, Forsiyon, Borkhaltai Sugd
- **시장현황**: TJ 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016v_tajikistan_mills.sql docs/handoff
git commit -m "data: Tajikistan listed mills + country market row"
git push origin marinebiogroup
```
