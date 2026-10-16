# Handoff 2026-10-16 (c) — 우루과이 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016b_paraguay_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016c_uruguay_mills_fillers.sql` | 필러 3, 밀 3(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` UY 행 |

batch / source: `uruguay_update_20261016` · 메모 표식 `UY check 2026-10-15`

## 2. 반영
- **필러**: CYCUSA (Minas·Montevideo, 미분화 탄산칼슘·석회, 광상 CaCO3 95.8%, FCC 생산 후보 1) · DARSA (#10~#635 분쇄) · Compañía Oriental de Minerales (원료)
  - 추가 안 함: Calera Carapé (석회 가마), Omya (현지 공장 미확인), Droguería Uruguayana (재판매)
- **밀 / 우선순위**: 1 Softys Uruguay (IPUSA) Pando (2011 티슈기 2.27만 t — 사이트 전체 아님) · 2 Amberplan Montevideo (1단계 1.2만 t 계획, 최종 4.8만 t) · 3 PAMER Mercedes (재생 골심지, 능력 미공개)
  - 배경(있을 때만): UPM Fray Bentos·Paso de los Toros, Montes del Plata (펄프 전용 — 제지사 생산능력 합계에 넣지 않으려고 새로 만들지 않음), FANAPEL (2017 폐쇄)
- **FCC Base 5%**: Softys 1,135 t · Amberplan 600 t
- **시장현황**: UY 행 medium, FCC 1,735 ~ 3,535 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016c_uruguay_mills_fillers.sql docs/handoff
git commit -m "data: Uruguay fillers + mills + country market row"
git push origin marinebiogroup
```
