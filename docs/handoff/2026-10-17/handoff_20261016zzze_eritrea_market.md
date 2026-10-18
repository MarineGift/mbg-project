# Handoff 2026-10-16 (zzze) — 에리트레아 시장현황 행 (가동 초지기 없음)

> 앞 문서: `handoff_20261016zzzd_chad_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzze_eritrea_market.sql` | 배경 5 (있을 때만), `app.country_markets` ER 행 (priority none) — 행 생성 없음 |

batch / source: `eritrea_update_20261016` · 메모 표식 `ER check 2026-10-16`

## 2. 반영
- 메모 끝에 `Screen US sanctions on Eritrean state entities (PFDJ, defence) before any contact.`
- 제지용 PCC·GCC 없음, 가동 초지기 없음
- 배경 (있을 때만): AMAP (과거 포장지, 1946 연 약 150 t), Cartiera Fratelli Perrone (1941, 월 약 25 t), M. Villani (1950 갈색 포장지), Gejeret Corrugated Boxes (Nakfa Corporation), Sabur Printing Press
- 시장현황: ER none — 장기 관찰, 에티오피아·이집트 우선

## 3. 후속 (EG 보완 목록에 추가)
- **Mohamed Mahmoud Paper & Packaging** (이집트, 연 25만 t+ 종이 — 회사 소개) → EG 밀 행 추가
- Arab Company for Calcium Carbonate (EG 필러), Alfacarb 위치 확인 (이전 메모)
- 에티오피아 (Wonji Pulp and Paper 등) 보고서 대기

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzze_eritrea_market.sql docs/handoff
git commit -m "data: Eritrea market row (no running paper machine)"
git push origin marinebiogroup
```
