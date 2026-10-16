# Handoff 2026-10-16 (i) — 페루 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016h_brazil_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016i_peru_mills_fillers.sql` | 필러 6, 밀 10(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` PE 행 |

batch / source: `peru_update_20261016` · 메모 표식 `PE check 2026-10-15`

## 2. 반영
- **필러**: Mineralium Huachipa (Carbomin 325~600 mesh, 제지 명시, 후보 1) · OLAH Group Lurín (자동화 5라인, OEM 후보) · Dogaresa · Abastecedora Andina (Super 1000 mesh) · Molinos Calcáreos Alpamayo · Comando Group (원료)
  - 추가 안 함: Calidra Perú (생석회), ABC Carbon, Procasac, COPROCAL (석회). 제지용 PCC 없음
- **밀 / 우선순위**: 1 Papelera Reyes Callao · 2 Papelera Zárate Puente Piedra (점보롤, 2025 증산 보고 불승인) · 3 Softys Santa Anita·Cañete · 4 Kimberly-Clark Puente Piedra (운영법인 확인) · 5 CARVIMSA Huachipa · 6 Trupal Trujillo (전체 30만 t 이 행에만)·Lima · 7 PANASA Paramonga (에콰도르 PANASA 와 다름) · 8 Papelera del Sur Chincha Baja
  - 배경(있을 때만): Papelera Campoy, Papelera Panamericana, El Chasqui, Schroth, Softys Arequipa (가공)
- **시장현황**: PE 행 medium, FCC 6,000 ~ 10,000 t (2018 티슈 약 20만 t × 3~5% — 과거 자료 기반)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016i_peru_mills_fillers.sql docs/handoff
git commit -m "data: Peru fillers + mills + country market row"
git push origin marinebiogroup
```
