# Handoff 2026-10-17 (g) — 기니 충전제 + 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261017f_sierra_leone_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017g_guinea_market.sql` | 필러 1(없을 때), 배경 9(있을 때만), `app.country_markets` GN 행 (priority none) — 밀 생성 없음 |

batch / source: `guinea_update_20261017` · 메모 표식 `GN check 2026-10-17` · 국가코드 `GN` (적도기니 GQ 와 구분)

## 2. 반영
- **필러 (C)**: Diamond Cement Guinea (2014 Souguéta Wondé Fily·Amaraya 석회석 허가 보도 — 현재 상태·품질 미확인, 가드 국가 한정). CIMAF Guinée (분쇄 150만 t)·GI Ciments (140만 t)·LafargeHolcim Guinée 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 초지기 없음. 배경 — 가공: Papel Industries (2024, 3겹 미용티슈), ACC (Ali Chehab), SODEFA, SOGEPAC, EGEPAC / 신규 프로젝트: Guinée Industrie Plus (Kagbélén, 2026-05-08 환경평가 범위 검토 — 초지기 포함 여부 확인이 설계단계 접점), Globale Invest Co (Coyah 포장, 2025-05-15 승인, 266.7억 GNF), EGUIFAB (Forécariah), Barry Kadiatou (Matoto)
- **시장현황**: GN none

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017g_guinea_market.sql docs/handoff
git commit -m "data: Guinea filler + market row (no paper machine)"
git push origin marinebiogroup
```
