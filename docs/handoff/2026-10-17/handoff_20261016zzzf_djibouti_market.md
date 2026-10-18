# Handoff 2026-10-16 (zzzf) — 지부티 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261016zzze_eritrea_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzf_djibouti_market.sql` | 배경 6 (있을 때만), `app.country_markets` DJ 행 (priority none) — 행 생성 없음 |

batch / source: `djibouti_update_20261016` · 메모 표식 `DJ check 2026-10-16`

## 2. 반영
- 펄프·종이·판지 생산 없음 (FAO 2019), 제지용 PCC·GCC 없음 (USGS: 시멘트·석회석·점토·소금·골재)
- 배경 (있을 때만): Imprimerie Nationale de Djibouti, NDJED / DJED (과거 수입 롤 재단·노트), Spectrum Imprimerie, Weprint.dj (Flexy SARL), Multi Services Olympiques, AMC Papeterie
- 시장현황: DJ none. 2023 수입 비도공지 약 770 t·크라프트 약 424 t. CaCO3 수입 약 1.8천 t 중 약 1.2천 t 에티오피아 재수출 → 에티오피아 제지사 공급 물류 거점 (지부티·도랄레항)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzf_djibouti_market.sql docs/handoff
git commit -m "data: Djibouti market row (no paper machine)"
git push origin marinebiogroup
```
