# Handoff 2026-10-16 (zzzs) — 부룬디 충전제·제지사 + 시장현황 행

> 앞 문서: `handoff_20261016zzzr_drc_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzs_burundi_mills_fillers.sql` | 필러 1, 밀 1(없을 때, 우선순위 없음) + 배경 6(있을 때만), plant 블록, `app.country_markets` BI 행 (priority none) |

batch / source: `burundi_update_20261016` · 메모 표식 `BI check 2026-10-16`

## 2. 반영
- **필러 (C)**: BUCECO (시멘트 2019 약 7.5만 t, Rusizi 탄산염 약 200만 t — 과거 조사). OBM (광업 관리기관) 메모. 2023 CaCO3 수입 약 400 t (UAE·탄자니아·케냐·요르단·튀르키예). 제지용 PCC·GCC 없음
- **밀**: BUMAC Bujumbura (2013, 복사·오프셋·아트지 — 초지기인지 수입 롤 재단인지 확인)
  - 배경: PACOBU (Ngagara, 노트 일 1만 권+), INTER PACK (Maramvya, 2024-10 개장, 약 300억 BIF), EPG (종이봉투), Imprimerie MEX, Hope Design, Itrapack
- **시장현황**: BI none. HS 48 수입 2023 약 1,809만 달러

## 3. 후속
- 르완다(RW) 보고서 대기: Mingyang Paper (골심지), Bonus Industries (종이봉투) 메모

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzs_burundi_mills_fillers.sql docs/handoff
git commit -m "data: Burundi filler + mill + market row"
git push origin marinebiogroup
```
