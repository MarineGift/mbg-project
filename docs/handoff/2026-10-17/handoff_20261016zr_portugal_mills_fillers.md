# Handoff 2026-10-16 (zr) — 포르투갈 제지사·충전제·위성 PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zq_spain_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zr_portugal_mills_fillers.sql` | 필러 5, 밀 8(없을 때) + 배경 6(있을 때만), plant 블록, **공급 링크 2 (active)**, `app.country_markets` PT 행 |

batch / source: `portugal_update_20261016` · 메모 표식 `PT check 2026-10-16`

## 2. 반영
- **필러**: SMI Figueira da Foz (위성 PCC, 1995·2000, 제지공장 CO2·부산물 활용 — B, supply_model satellite) · Omya Setúbal (위성 PCC, 라이선시 — B, satellite) · Omya Mineral Portuguesa Perulheira (Salmon·Omya 합작 GCC 10만 t) · Microlime · Calcidrata (PCC 용 석회). LDM/BIOCAL (농업용 88%), Lhoist 추가 안 함
  - **SMI 는 MBG 티슈 트랙 파트너(NDA)** → Figueira 3자 시험은 그 관계를 통해 제안하도록 메모
- **밀 / 우선순위**: 1 Navigator Figueira da Foz (UWF 80만 t + 펄프 57만 t) · 2 Navigator Setúbal (77.5만 t) · 3 Fortissue (3.5만 t 버진) · 4 Fapajal · 5 Renova · 6 Prado · 7 Paper Prime · DS Smith Viana (44만 t, 우선순위 없음)
  - 배경(있을 때만): Navigator Cacia·Ródão, Coreboard, Ponte Redonda, Altri (Celbi·Biotek·Caima 펄프)
- **링크**: SMI → Navigator Figueira (active, 1995~) · Omya Setúbal → Navigator Setúbal (active)
- **시장현황**: PT 행 high, FCC 78,750 ~ 157,500 t (UWF 157.5만 t × 5~10%, 보고서 시나리오)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zr_portugal_mills_fillers.sql docs/handoff
git commit -m "data: Portugal fillers + mills + satellite PCC links + country market row"
git push origin marinebiogroup
```
