# Handoff 2026-10-16 (zzzn) — 나미비아 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261016zzzm_zimbabwe_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzn_namibia_market.sql` | 필러 3(없을 때), 배경 8(있을 때만), `app.country_markets` NA 행 (priority none) — 밀 생성 없음 |

batch / source: `namibia_update_20261016` · 메모 표식 `NA check 2026-10-16`

## 2. 반영
- **필러 (C)**: Ohorongo Cement Otavi (시멘트 100만 t+, 자체 석회석) · Whale Rock / Cheetah (Farm Cleveland, 1.39억 t·CaO 50.59% ≈ CaCO3 90% — 평균은 제지 순도 미달) · Peralin (대리석 칩·분말 — GCC 원료 후보). 2025 경쟁위원회가 Whale Rock 의 Ohorongo 모회사 인수 금지 → 별개 그룹. NMDC (백운석)·Karibib 대리석 채석장 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 가동 초지기 없음. 배경: Soft Cloud (Gobabis, 화장지·A4 — 초지기 미확인), JJ Nam / NamSoft (남아공 점보롤 가공), Biocol, SoftKiss, Mpact Corrugated Namibia (Walvis Bay·Windhoek 가공 — 그룹 제지공장은 ZA), Guan's Packaging, Namibia Pulp Paper (2016 재생 티슈 공장 계획 — 건설 미확인), Bliss Tissue
- **시장현황**: NA none. HS 48 수입 2024 1.349억 달러, 86% 남아공 → ZA Mpact·티슈 원지 제지사 경유

## 3. 국가코드 주의
나미비아 ISO 코드는 **`NA`** — CSV·엑셀·일부 파서에서 NULL/결측으로 읽힐 수 있음. SQL 에는 문자열 `'NA'` 로 들어가 문제없지만, `app.countries` 에 `NA` 행이 있는지, 내보내기·가져오기 화면에서 빈 값으로 바뀌지 않는지 확인

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzn_namibia_market.sql docs/handoff
git commit -m "data: Namibia fillers + market row (no paper machine)"
git push origin marinebiogroup
```
