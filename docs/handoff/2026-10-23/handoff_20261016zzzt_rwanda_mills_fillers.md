# Handoff 2026-10-16 (zzzt) — 르완다 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzs_burundi_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzt_rwanda_mills_fillers.sql` | 필러 2, 밀 2(없을 때) + 배경 9(있을 때만), plant 블록, `app.country_markets` RW 행 |

batch / source: `rwanda_update_20261016` · 메모 표식 `RW check 2026-10-16`

## 2. 반영
- **필러 (C)**: ALICOMEC 서부주 (파쇄·분말·미분 석회석, 생석회·소석회 — 현지 GCC 시험 후보 1) · CIMERWA Bugarama (시멘트 약 60만 t, Mashyuza 트래버틴·규암 — Prime Cement 도 CIMERWA 자산 표기). Kigali Cement·Anjia 추가 안 함. 제지용 PCC·GCC 없음
- **밀 / 우선순위**: 1 Kigali Mingyang Paper (120 gsm 골심지 우간다 수출, 초지기 펠트·성형망 수입 기록 — 생산능력 미공개) · 2 Roba Industries Bugesera (폐지 재활용 화장지, 2026-03-11 폐지 조달 공고)
  - 배경 9: SUPA (Safari Center), Salama, Star Overseas, ALVYO (SAFI), Basil, V-Plus, Jabbar, Bonus (A4 — 초지 여부 확인), Nyungwe Paper
- **시장현황**: RW 행 low, FCC 산정 보류. 부룬디 보고서의 Mingyang·Bonus 메모 반영 완료

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzt_rwanda_mills_fillers.sql docs/handoff
git commit -m "data: Rwanda fillers + mills + country market row"
git push origin marinebiogroup
```
