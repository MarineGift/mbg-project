# Handoff 2026-10-16 (zzzo) — 앙골라 충전제 + 시장현황 행 (원지공장 미확인)

> 앞 문서: `handoff_20261016zzzn_namibia_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzo_angola_market.sql` | 필러 3(없을 때), 배경 10(있을 때만), `app.country_markets` AO 행 (priority none) — 밀 생성 없음 |

batch / source: `angola_update_20261016` · 메모 표식 `AO check 2026-10-16`

## 2. 반영
- **필러 (C)**: Terrafort (Grupo Cimenfort, Lobito, 2024~ 석회석 가공 설치 140만 t — 후보 1, 항만 연계) · Calcários da Huíla (2007, 사료·농업용 탄산칼슘·소석회, 일 420 → 90~150 t 로 감소 — 여유 설비) · ESA Malanje (2025-12-10 착공 발표, 농업용 분쇄공장 — 계획). 제지용 PCC·GCC 없음, Omya·Imerys 공장 없음
- **밀**: 원지공장 미확인 → 생성 없음
  - 배경 (가공): **Saluna** (Viana, 현지 원지 생산 도입 계획 명시 — 유일한 설계단계 접점), SIPA (원지 조달처에 포르투갈 Navigator — PT 행 연계), Joia FEF (10 ha·라인 10개·250명 — 초지기 10대 아님), MIPER, Miatop (Fofinho), Heran, Cartaplast (Catumbela), FSF Global / We1, Pacote Certo, Embalagem do Sol
- **시장현황**: AO none. HS 48 수입 2024 약 1.072억 달러 (포르투갈·중국·이탈리아·인도)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzo_angola_market.sql docs/handoff
git commit -m "data: Angola fillers + market row (no base-paper mill)"
git push origin marinebiogroup
```
