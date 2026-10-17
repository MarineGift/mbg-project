# Handoff 2026-10-16 (zzd) — 룩셈부르크 시장현황 행 (초지기·충전제 없음) + 벨기에 시드 보완

> 앞 문서: `handoff_20261016zzc_belgium_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzd_luxembourg_market.sql` | 배경 1 (COREX, 있을 때만), `app.country_markets` LU 행 (priority none) — 행 생성 없음 |
| `sql/seed_20261016zzc_belgium_mills_fillers.sql` | **다시 생성** — Burgo Ardennes 2023 생산능력 추가 (아직 실행 전이면 이걸로 교체, 실행했어도 재실행 안전) |

batch / source: `luxembourg_update_20261016` · 메모 표식 `LU check 2026-10-16`

## 2. 반영
- **LU**: 초지기 없음 (NACE 17 약 8곳, 대부분 가공 — 과거 공장 Manternach·Mühlenbach·Echternach·Diekirch 없음). 제지용 PCC·GCC 없음
  - 배경: COREX Luxembourg Niederkorn (지관·코어, 1988~, 2002 연 1.65만 t)
  - Garda Group: 2026-04 Lecta 구조조정 후 생긴 룩셈부르크 지주사, 이탈리아 Cartiere del Garda 소유 → IT 행 메모 대상 (LU 시드는 국가 범위 밖이라 IT 행을 건드리지 않음 — 시장현황에만 기록)
  - 시장현황: LU none, BE·DE·FR 권역으로 관리
- **BE 보완**: Burgo Ardennes Virton — 2023 표백 화학펄프 약 38.5만 t, 우드프리 코팅지 약 37.5만 t → capacity 37.5만 t (펄프는 미합산), 제품을 coated woodfree 로 정정

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzd_luxembourg_market.sql sql/seed_20261016zzc_belgium_mills_fillers.sql docs/handoff
git commit -m "data: Luxembourg market row; Belgium Burgo Ardennes capacity"
git push origin marinebiogroup
```

## 4. 후속
IT Cartiere del Garda 행에 "Garda Group (Luxembourg holding, 2026-04)" 소유 정보 추가 — 다음 IT 보완 시
