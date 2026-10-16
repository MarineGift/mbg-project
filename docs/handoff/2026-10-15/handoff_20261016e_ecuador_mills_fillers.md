# Handoff 2026-10-16 (e) — 에콰도르 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016d_venezuela_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016e_ecuador_mills_fillers.sql` | 필러 5, 밀 4(없을 때) + 배경 10(있을 때만), plant 블록, `app.country_markets` EC 행 |

batch / source: `ecuador_update_20261016` · 메모 표식 `EC check 2026-10-15`

## 2. 반영
- **필러**: Omya Ecuador / LACEC Ascázubi (1982~, 제지·티슈·판지 공급 명시, 라이선시) · La Colina / INDUCOLINA (CaCO3 98%, 제지 명시, 현지 후보 1) · Morrocal · INDAMI (초미립) · ACTEK Riobamba (원료). PCC 공장 없음
- **밀 / 우선순위**: 1 Familia Sancela (Essity) Lasso (PM2 7,920 + PM5 17,170 t, 약 2017) · 2 Cartopel Cuenca 제지공장 (능력 미공개) · 3 Papelera Nacional (PANASA) 16.5만 t · 4 Surpapelcorp Durán 14만 t (MIGA 2020)
  - 배경(있을 때만): INPAECSA / Essity Babahoyo (2026-08 가동 중단·설비 반출), Softys·Kimberly-Clark (가공), Grupasa, INCARPALM, Procarsa, Industria Cartonera Ecuatoriana, Papelesa, Zaimella, Absoreforma
  - Essity 가드는 `lasso` 로 한정 — Babahoyo 행과 섞이지 않게
- **FCC Base**: PANASA 3,960 t · Surpapelcorp 3,360 t (80% × 3%) · Essity Lasso 753 t (3%)
- **시장현황**: EC 행 medium, FCC 2,440 ~ 8,073 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016e_ecuador_mills_fillers.sql docs/handoff
git commit -m "data: Ecuador fillers + mills + country market row"
git push origin marinebiogroup
```
