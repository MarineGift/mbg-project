# Handoff 2026-10-16 (zzzw, 재생성) — 중앙아프리카공화국 시장현황 행 보완

> 앞 문서: `handoff_20261016zzzy_eq_guinea_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzw_car_market.sql` | **다시 생성** — 두 번째 CAR 보고서 반영. 배경 7 → 12, 시장현황 요약 갱신 (아직 실행 전이면 교체, 실행했어도 재실행 안전) |

## 2. 추가 반영
- 배경 5곳 추가: Printstech Centrafrique (2022-09-07 개소, DRC Printstech 계열), Emadeu Trade Corporation (2015, Avenue des Martyrs), Watatu SARL (오프셋·문구), Bonprix.cf (온라인 복사용지·문구), Société M Nour (사무용품 유통)
- 시장현황 요약에 HS 4818 위생용지 수입 약 1,341 t (2024) 추가 — 완제품 수입, 현지 티슈 원지 생산 아님
- 기존 그대로: 제재 메모, 필러·밀 생성 없음, CF none

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzw_car_market.sql docs/handoff
git commit -m "data: CAR market row - more converter rows"
git push origin marinebiogroup
```
