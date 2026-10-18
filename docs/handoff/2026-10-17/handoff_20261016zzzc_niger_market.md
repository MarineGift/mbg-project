# Handoff 2026-10-16 (zzzc) — 니제르 시장현황 행 + 말리 시드 보완

> 앞 문서: `handoff_20261016zzzb_mali_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzc_niger_market.sql` | 필러 1(없을 때), `app.country_markets` NE 행 (priority none) — 밀 행 없음 |
| `sql/seed_20261016zzzb_mali_mills_fillers.sql` | **다시 생성** — 두 번째 말리 제지사 보고서 반영 (아직 실행 전이면 교체, 실행했어도 재실행 안전) |

## 2. 니제르 (NE)
- 받은 두 번째 보고서가 말리 제지사 보고서 (재작성본) → 니제르 제지사 정보 없음, 밀 행 생성 안 함
- **필러 (C)**: Malbaza Cement (시멘트 65만 t, Karni-Ouest CaCO3 72~83.5% — 제지용 순도 미달). Mango Ciment (약 4,500 t/일), Dangote Mining Niger·SOCINIC·CITEC (과거 광업권) 추가 안 함. Ader Doutchi 석회석대 메모. 제지용 PCC·GCC 없음 → 나이지리아 GCC (IzeCarb 등) 경유
- 시장현황: NE none

## 3. 말리 (ML) 보완
- 배경 3곳 추가: TransFopam (A3·A4 80 gsm 가공·노트), SNFC (노트, 2017 두 회사 약 35명·시간당 9천~1만 권), Barkana (인쇄)
- SCS Malienne de Cartonnerie 메모에 2016 연락처·당시 대표 추가
- 시장현황 요약·sections 갱신

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzc_niger_market.sql sql/seed_20261016zzzb_mali_mills_fillers.sql docs/handoff
git commit -m "data: Niger market row; Mali converter rows"
git push origin marinebiogroup
```

## 5. 후속
니제르 제지기업 보고서 필요
