# Handoff 2026-10-16 (b) — 파라과이 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016a_bolivia_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016b_paraguay_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 10(있을 때만), plant 블록, `app.country_markets` PY 행 |

batch / source: `paraguay_update_20261016` · 메모 표식 `PY check 2026-10-15`

## 2. 반영
- **필러**: Calmax (Concepción San Lázaro, 농업용 석회석 — 원료만)
  - 추가 안 함: Grupo Ferreira / FOZ QUÍMICA (PCC·분쇄 탄산칼슘 수입·유통), Pyatra Minerals (공장 위치 미확인), OregonChem, Inovaquimica (유통), Concret-Mix (석회). PCC 공장·Omya·SMI 거점 없음
- **밀**: 1 Kartotec Villeta (Grupo Yaguareté, PM 2대, 재생 테스트라이너·골심지·석고보드 원지 9.5만 t, 2026-09 신규 초지기 10만~13만 t 계획) · Trans River Internacional (티슈 점보롤 프로젝트, 가동 미확인 → 우선순위 없음)
  - 배경(있을 때만): Cartones Yaguareté, Venezia, CARFAL, A&Z, CPI Paraguay, Envaco, Corrugadora Paraguaya, PACSA, ADS, Paracel (펄프 프로젝트 180만 t)
- **FCC Base**: Kartotec 9.5만 t × 5% = 4,750 t (capacity 는 기존 9.5만 t, 신규 계획은 capacity_split 2번째 줄 — 탭 합계에는 기존만 반영)
- **시장현황**: PY 행 medium, FCC 4,750 ~ 11,250 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016b_paraguay_mills_fillers.sql docs/handoff
git commit -m "data: Paraguay filler + mills + country market row"
git push origin marinebiogroup
```
