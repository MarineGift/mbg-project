# Handoff 2026-10-15 (t) — 과테말라 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261015s_canada_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015t_guatemala_mills_fillers.sql` | 필러 6, 밀 3(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` GT 행. 공급 링크 없음 |

batch / source: `guatemala_update_20261015` · 메모 표식 `GT check 2026-10-15`

## 2. 반영
- **필러**: GUAMINSA · Proservi (둘 다 제지 명시, 파트너 후보) · PROMISA · Mineral Resources de Guatemala (Villa Nueva, 전 광물 3만 t) · Tercerón · EXGUAMISA (원료)
  - 제지용 PCC 공장·Omya·SMI 거점 없음. Calera San Miguel (석회), Minerales y Agregados (Holcim) 추가 안 함
- **밀 / 우선순위**: 1 GrandBay PAINSA Río Hondo 티슈 13만 t (PM7 2023) · 2 Papelera del Pacífico Retalhuleu (재생 크라프트·판지, 능력 미공개) · 3 COPACASA Escuintla (SigmaQ, 1.6만 short t)
  - 배경(있을 때만): Kimberly-Clark Guatemala, CARTOGUA, Empresas Galindo — 가공업체, 초지기 미확인
- **FCC Base** (보고서 80% × 5%): GrandBay 5,200 t · COPACASA 580 t
- **시장현황**: GT 행 medium, FCC 3,468 ~ 5,780 t
- 웹사이트는 모두 비움 (미확인)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015t_guatemala_mills_fillers.sql docs/handoff
git commit -m "data: Guatemala fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 완료 국가 40 (+GT). 결과 대기: TH(o), CA(s), GT(t)
