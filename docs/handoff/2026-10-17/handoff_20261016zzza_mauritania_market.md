# Handoff 2026-10-16 (zzza) — 모리타니 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zzz_south_africa_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzza_mauritania_market.sql` | 필러 1, 배경 7 (있을 때만), `app.country_markets` MR 행 (priority none) — 밀 생성 없음 |

batch / source: `mauritania_update_20261016` · 메모 표식 `MR check 2026-10-16`

## 2. 반영
- **필러 (C)**: Carmeuse Mauritania 누악쇼트 (생석회 수입·수화석회 10 t/h — PCC 플랜트 아님). 시멘트 업체 (Ciment de Mauritanie, MAFCI 40만 t, CIMAF, Cinord, Mauricim) 추가 안 함. 제지용 PCC·GCC 없음. CaCO3 수입 2024 약 1.29만 t·254만 달러 (이집트·튀르키예·모로코·튀니지)
- **밀**: 초지기 없음
  - 배경 (가공): Klingele / Mauripack (누악쇼트 2015·누아디부 2011), SPIE (수산물 상자 연 400만 개), SMPCO (2025), SIPE Carton, SOMACAR, MAURISAC, Mauritano Chinoise de Carton
- **시장현황**: MR 행 none. HS 48 수입 2024 약 4,187만 달러 (스페인·모로코·튀르키예·중국) → 원지 공급 제지사·Klingele 그룹 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzza_mauritania_market.sql docs/handoff
git commit -m "data: Mauritania filler + market row (no paper machine)"
git push origin marinebiogroup
```
