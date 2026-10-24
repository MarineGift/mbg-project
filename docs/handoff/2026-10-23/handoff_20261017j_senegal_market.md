# Handoff 2026-10-17 (j) — 세네갈 충전제 + 시장현황 행 (초지기 미확인)

> 앞 문서: `handoff_20261017i_gambia_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017j_senegal_market.sql` | 필러 2(없을 때), 배경 10(있을 때만), `app.country_markets` SN 행 (priority none) — 밀 생성 없음 |

batch / source: `senegal_update_20261017` · 메모 표식 `SN check 2026-10-17` · 국가코드 `SN`

## 2. 반영
- **필러 (C)**: Les Sablières du Sahel (Tassette — GCC Standard 90~95%·0~100 μm, Micronisé 95~98%·2~40 μm, 제지 등급 없음 — 세네갈 유일 GCC 제조 확인, 후보 1) · SOCOCIM (Vicat, Bandia 석회석 — Pout-Bandia 일부층 CaCO3 약 96.6%). Ciments du Sahel·Dangote 추가 안 함. 제지용 PCC 없음
- **밀**: 초지기 미확인. 배경 10: La Rochette Dakar (골판지 2018 점유 80%, BOBST — 초지기 아님), SIPS, MSP (DISTINGO), TRANSPAPS (티슈 — 초지기 확인 1순위), RUFSAC (크라프트 포대), SEIS, Mondial Paper (원지 재단 약 4.5천 t — 해외 제지사 추적 경로), SIPEXS, Polykrome, Klingele Senegal (가드 국가 한정)
- **시장현황**: SN none. HS 48 수입 2024 약 1.398억 달러 (모로코·스페인·중국·독일·스웨덴). 감비아·기니비사우 공급국

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017j_senegal_market.sql docs/handoff
git commit -m "data: Senegal fillers + market row"
git push origin marinebiogroup
```
