# Handoff 2026-10-16 (zg) — 불가리아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zf_northmacedonia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zg_bulgaria_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` BG 행 |

batch / source: `bulgaria_update_20261016` · 메모 표식 `BG check 2026-10-16`

## 2. 반영
- **필러**: Calcit JSC Asenovgrad (실제 PCC 제조, 98.5%·10 μm 이하 97%·아라고나이트, SDS 에 제지 명시 — 입도 굵음, 후보 1, B. 가드에 사이트명 포함 → 슬로베니아 Calcit Group 과 분리) · Kaolin EAD Ignatievo (탄산염 + 제지용 카올린 담당자 공개) · Bulterra S (대리석 GCC, 제지 명시) · Omya Bulgaria (영업소, 라이선시). Heidelberg Devnya·Carboplast 추가 안 함
- **밀 / 우선순위**: 1 Belovo (Belana, 초지기 4대, 5.8만 t) · 2 Kostenets HHI (PM1 플루팅 8천 + PM2 MG 1.5만/티슈 9천 + PM3 티슈 2.7만 t — capacity 5만 t 는 상한 합, FCC 는 PM3 비중 54% 만) · 3 GFF Nikopol (PM1·PM2 각 2만 t) · 4 Nova Knizhna Fabrika (재생 플루팅)
  - 배경(있을 때만): Mondi Stambolijski (2024 화재 후 폐쇄), Svilocell (펄프 15만 t, 중단), Dunapack-Rodina, Velpa 91, Vitavel
- **시장현황**: BG 행 medium, FCC 1,250 ~ 6,250 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zg_bulgaria_mills_fillers.sql docs/handoff
git commit -m "data: Bulgaria fillers + mills + country market row"
git push origin marinebiogroup
```
