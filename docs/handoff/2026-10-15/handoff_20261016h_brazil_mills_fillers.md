# Handoff 2026-10-16 (h) — 브라질 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016g_chile_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016h_brazil_mills_fillers.sql` | 필러 8, 밀 21(없을 때) + 배경 3(있을 때만), plant 블록, 공급 링크 5, `app.country_markets` BR 행 |

batch / source: `brazil_update_20261016` · 메모 표식 `BR check 2026-10-15`

## 2. 반영
- **필러**: Specialty Minerals (Brazil) (위성 PCC 4곳, NewYield LO 2023, 라이선시) · Imerys Brás Cubas (18.5만 t, 습식 68%) · Imerys Cachoeiro de Itapemirim · Imerys Quixeré · Omya do Brasil (라이선시, Multifill·FiberLean 경쟁기술) · Mineração São Judas (제지용 슬러리 90 ISO, 현지 파일럿 후보) · Fillercal · Carbomil. Minerjato 추가 안 함
- **밀 / 우선순위**: 1 Sylvamo Mogi Guaçu·Luiz Antônio·Três Lagoas (LatAm UFS 약 100만 t 은 Mogi Guaçu 행에만) · 2 Suzano Suzano(SP) 55만·Limeira 40만·Mucuri 31만 t · 3 BO Paper Arapoti 15만·Pisa 21만 t · 4 Bracell Lençóis Paulista 24만 t (+12만 계획) · 5 Softys Caieiras (브라질 합계 28만 t 이 행에만), Suzano 티슈 Mogi das Cruzes 13만·Imperatriz 6만·Aracruz 6만 t · 6 Klabin Ortigueira·Monte Alegre · 7 Santher (합계 18만 t) · 8 Smurfit Westrock Três Barras, Irani, CMPC Piraí do Sul
  - 배경(있을 때만): Papirus, Mili, Melhoramentos (Softys Caieiras 가드에서 Melhoramentos 제외)
- **공급 링크**: SMI → Suzano(SP)·Mucuri (active / medium), SMI → Sylvamo Luiz Antônio (historical / medium), Omya → Sylvamo Mogi Guaçu·Três Lagoas (historical / low)
- **시장현황**: BR 행 high, FCC 22,000 ~ 44,000 t (인쇄·필기 220만 t × 10~20% × 10%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016h_brazil_mills_fillers.sql docs/handoff
git commit -m "data: Brazil fillers + mills + supply links + country market row"
git push origin marinebiogroup
```
