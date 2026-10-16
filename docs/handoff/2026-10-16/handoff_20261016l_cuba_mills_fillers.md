# Handoff 2026-10-16 (l) — 쿠바 제지사·충전제 + 시장현황 행 (보류: 미국 금수)

> 앞 문서: `handoff_20261016k_dominican_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016l_cuba_mills_fillers.sql` | 필러 3, 밀 4(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` CU 행 (priority **on_hold**) |

batch / source: `cuba_update_20261016` · 메모 표식 `CU check 2026-10-15` · 모든 메모에 "US embargo (OFAC CACR) - 제재 검토 전 거래 불가" 문구

## 2. 반영
- **필러**: EMO Roberto Coco Peredo (San José de las Lajas, 미세 3만 + 조립 6만 t 설비, CARCAL 98%·2~5 μm, 광업 허가에 제지 용도) · Geominera del Centro · Geominera de Pinar del Río (원료). PCC 없음
- **밀**: 1 PROSA Cárdenas (티슈, 2023 재가동) · 2 Damují Abreus (재생 판지, 일 15~17 t → 4,800 t 계산값) · Pulpa Cuba Trinidad (과거 2.4만 t, 2020 중단 — 우선순위 없음) · Papeles Finos Jatibonico (6만 t 계획 — 우선순위 없음)
  - 배경(있을 때만): Cartones y Cartulinas, Tejas Infinitas, Jatimol, Compacto Caribe
- **시장현황**: CU 행 on_hold, FCC 산정 안 함
- **미결 3번과 연결**: 제재국 캠페인 제외 패치 대상에 CU 포함 필요 (IR, CU, 필요 시 VE·SY 등)
- 생성기: 행 형식(12칸·create 플래그) 검사 추가

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016l_cuba_mills_fillers.sql docs/handoff
git commit -m "data: Cuba fillers + mills + country market row (on hold, sanctions)"
git push origin marinebiogroup
```
