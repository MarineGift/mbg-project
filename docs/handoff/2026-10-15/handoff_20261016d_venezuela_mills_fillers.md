# Handoff 2026-10-16 (d) — 베네수엘라 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016c_uruguay_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016d_venezuela_mills_fillers.sql` | 필러 6, 밀 5(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` VE 행 |

batch / source: `venezuela_update_20261016` · 메모 표식 `VE check 2026-10-15`

## 2. 반영
- **필러**: RIASCA (635 mesh, 후보 1) · ESVENCA (MTW-138 2대, 일 32~40 t, 후보 2) · VE-CA-FO (Villa de Cura) · Minerales Yaracal · MICRA (가동 미확인) · EXIN (조립, 원료)
  - 추가 안 함: SUPRACAL·Maxical (석회), Corporación Venezolana de Agregados·Venza (유통). 제지용 PCC·Omya 거점 없음
- **밀 / 우선순위**: 1 MANPA Maracay (과거 인쇄·포장 12만 t + 티슈 5만 t) · 2 PAVECA Guacara (과거 7대 9.4만 t, 활동 확인) · 3 Cartonal Valencia · 3 Mocarpel San Felipe (구 Smurfit, 2024-11 정부 관리) · 4 Cacique Maracay (구 Kimberly-Clark, 과거 3만 t)
  - 생산능력은 모두 과거 수치 → `capacity_split` 에만 (탭 합계에 과거 값이 들어감을 유의)
  - 배경(있을 때만): 구 Smurfit 그룹 행, Vencartón, INVEPAL, PULPACA (미완공), Cartoenvases, Unión Gráfica, Corrugadora Maracay
- **시장현황**: VE 행 low, FCC 산정 보류. risks 에 "접촉·계약 전 미국 제재 확인" 명시 → 미결 3번(제재국 캠페인 제외) 결정 때 VE 포함 여부 검토

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016d_venezuela_mills_fillers.sql docs/handoff
git commit -m "data: Venezuela fillers + mills + country market row"
git push origin marinebiogroup
```
