# Handoff 2026-10-16 (zzzi) — 탄자니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzh_somalia_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzi_tanzania_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 6(있을 때만), plant 블록, `app.country_markets` TZ 행 |

batch / source: `tanzania_update_20261016` · 메모 표식 `TZ check 2026-10-16`

## 2. 반영
- **필러**: **Neelkanth Chemicals Tanga** (방해석·백운석 GCC·코팅 CaCO3, 2026 우간다 수출, USD 800만 설비 — 후보 1, B) · Neelkanth Lime (석회, PCC 원료) · ABM (농업용 석회석 분말 200~400 mesh) · Alpha Lime (금광용 석회). Abouraya·Innova 추가 안 함, UNIDO 3천 t PCC 계획 (미건설) 메모. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Tanpack Tissues Dar es Salaam (Chandaria 그룹 — 티슈·MG 초지기, 재생 원료, 케냐 Chandaria 와 그룹 시험) · 2 Mufindi Paper Mills Mgololo (Rai 그룹 — 일관 펄프·색크라프트·크라프트라이너, 2012 약 14만 t (과거치), 2026-07 TBS 인증 — 케냐 Rai Paper Webuye 와 같은 그룹) · 3 Fortune Paper Kibaha (재생 골심지·라이너 약 4.8만 t)
  - 우선순위 없음: Kibo Paper (과거 1만 t, 가동 확인)
  - 배경: Kibo Match, Twiga, 369 Industries, Tanzania Printing Services, Maxons, Pee Pee (PP 포대 — 종이 아님)
- **시장현황**: TZ 행 low, FCC 3,948 ~ 6,580 t (Mufindi + Fortune × 가동 70% × 3~5%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzi_tanzania_mills_fillers.sql docs/handoff
git commit -m "data: Tanzania fillers + mills + country market row"
git push origin marinebiogroup
```
