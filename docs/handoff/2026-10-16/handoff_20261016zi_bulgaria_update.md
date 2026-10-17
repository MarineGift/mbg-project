# Handoff 2026-10-16 (zi) — 불가리아 2차 보고서 반영 (zg 위에 실행)

> 앞 문서: `handoff_20261016zh_kosovo_fillers.md` · 선행: `seed_20261016zg_bulgaria_mills_fillers.sql`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zi_bulgaria_update.sql` | 필러 4 추가(없을 때), 밀 3 plant 블록 갱신 + 메모 1줄, 배경 4, BG 시장현황 갱신 |

메모 표식 `BG check 2026-10-16b` (zg 의 `BG check 2026-10-16` 과 달라 새 줄로 1회 추가) · source `bulgaria_update_20261016b`

## 2. 변경
- **Belovo Paper Mill**: Finansi.bg 기준 청산 절차 중(2026-10-15) → **우선순위 제거**, 5.8만 t 은 과거 수치로 메모
- **GFF Nikopol**: 우선순위 3 → **1**, 평량별 규격·시험안(15 gsm 버진, FCC 3·5·7%) 메모
- **Kostenets HHI**: 2 유지, 같은 부지에 법인 3개(Kostenets Paper Mill AD, Kostenets Paper AD, Kostenets-HHI AD) — PM1~PM3 운영 법인 확인 필요
- **필러 추가**: Zlatna Panega Cement (TITAN 미분 석회석, 2017 보고서 제지 명시) · SMA Mineral Burgas Var (석회) · Ognyanovo K (석회) · Skalni Materiali (원료). Kaolin EAD 상세(Quarzwerke 2013~, Senovo 본사, Dimitrovgrad 석회석)는 Skalni 메모에 기록
- **배경 추가**: Lipo-Hart, Tri-Wall Bulgaria (2026-01 신규 골판지 공장 착공, 3천만 유로+), EMA, Kostenets Paper Mill AD
- **시장현황**: BG headline·summary 갱신, FCC 670 ~ 3,350 t (GFF + Kostenets PM3, Belovo 제외)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zi_bulgaria_update.sql docs/handoff
git commit -m "data: Bulgaria update - Belovo in liquidation, GFF lead, lime fillers"
git push origin marinebiogroup
```
