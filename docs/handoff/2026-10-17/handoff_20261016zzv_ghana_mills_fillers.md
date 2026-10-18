# Handoff 2026-10-16 (zzv) — 가나 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzu_nigeria_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzv_ghana_mills_fillers.sql` | 필러 3, 밀 1(없을 때) + 배경 6(있을 때만), plant 블록, `app.country_markets` GH 행 (priority none) |

batch / source: `ghana_update_20261016` · 메모 표식 `GH check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (C)**: Alkaboat Plus Accra (현지 GCC, 제지 명시 — 샘플 시험 필요) · Carmeuse Ghana Takoradi (1995 소석회, 2020 1.3만 t — PCC 원료) · Ghani ChemWorld (PCC 공급 — 99.34%·중앙 5.0 μm·L* 95.55, 제조사 불명). Ghacem 추가 안 함. 제지용 PCC·GCC 공장 없음, 이집트·나이지리아 수입 가능
- **밀**: 1 Akosombo Paper Mill (재생 티슈 점보롤 약 10 t/일 ≈ 4천 t, UNIDO 2023 — 가나 유일 확인 초지기, 가동 여부 확인, TGRG Pulp 연계)
  - 배경 (가공): Belpak (2만~2.5만 t 가공), Delta Paper Mill Tema, FON, Fine Print, Prak, Jay Kay (펄프·제지 후방통합 계획)
- **시장현황**: GH 행 none, FCC 40 ~ 200 t — 기술 실증·서아프리카 영업 거점

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzv_ghana_mills_fillers.sql docs/handoff
git commit -m "data: Ghana fillers + mill + country market row"
git push origin marinebiogroup
```
