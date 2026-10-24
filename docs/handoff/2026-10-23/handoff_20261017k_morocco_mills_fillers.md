# Handoff 2026-10-17 (k) — 모로코 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261017j_senegal_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017k_morocco_mills_fillers.sql` | 필러 5, 밀 4(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` MA 행 |

batch / source: `morocco_update_20261017` · 메모 표식 `MA check 2026-10-17` · 국가코드 `MA`

## 2. 반영
- **필러**: **Omya Maroc** Bouskoura (탄산칼슘 제조, 자본 3,000만 MAD — Omya 라이선시 그룹, Multifill·FiberLean 경쟁, NDA·IP 먼저 — 후보 1, B) · Broychim Casablanca (1982, 독립 분쇄 — 후보 2) · Carbonate Chaouia Ben Ahmed (미분화 2라인 38 μm 미만) · SIGMAROC (석회, PCC 원료) · Minerallum. 제지용 PCC 공장 미확인
- **밀 / 우선순위**: 1 Med Paper Tanger (상장, Papelera de Tétouan + Safripac 통합, 초지기 2기 이론 약 4.5만 t, 2026-09-30 상반기 공시) · 2 SIPAT Meknès (티슈 PM1·PM2 약 1.6만 t, 2024 ABB QCS·2025 AMACO) · 3 CMCP–International Paper Kénitra (재생 골판지원지 — 생산능력 미공개, IP 그룹)
  - 우선순위 없음: GPC Papier et Carton (Ynna, 포장재 9만 → 16만 t 목표 — split, 초지기 확인)
  - 배경: Le Carton, Mondi Morocco, COMPLIPACK, Safapac, Brior, Sanipak, Safripac (Med Paper 로 통합)
- **시장현황**: MA 행 low, FCC 2,410 ~ 7,550 t. 세네갈·모리타니 최대 종이 공급국 → 서아프리카 공급원

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017k_morocco_mills_fillers.sql docs/handoff
git commit -m "data: Morocco fillers + mills + country market row"
git push origin marinebiogroup
```
