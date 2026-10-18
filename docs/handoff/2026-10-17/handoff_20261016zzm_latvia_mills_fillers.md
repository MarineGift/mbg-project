# Handoff 2026-10-16 (zzm) — 라트비아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzl_lithuania_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzm_latvia_mills_fillers.sql` | 필러 2, 밀 3(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` LV 행 (priority none) |

batch / source: `latvia_update_20261016` · 메모 표식 `LV check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (C)**: SCHWENK Latvija Brocēni (Kūmas 채석장, 농업용 — 96.5% 는 순도 아닌 중화능) · Saulkalne S (건설용 석회석 필러). Brenntag Latvia (유통) 추가 안 함. 제지용 PCC·GCC 없음 — 가장 가까운 제지용 GCC 는 핀란드 Suomen Karbonaatti
- **밀**: 1 Līgatne Paper Mill (면섬유 미술·특수지, 천연섬유 R&D) · 2 V.L.T. Valmiera (몰드펄프 계란판, 폐지 최대 4,500 t) · EKOPAPĪRS Lēdmane (NACE 17.12 등록, 설비 미확인 — 우선순위 없음)
  - 배경: Stora Enso Riga, VG Kvadra Pak, Liepājas Papīrs, Smurfit Westrock Baltic (Jelgava), DS Smith Latvia, GOFRAPRO, Asta Pro
- **시장현황**: LV 행 none (NACE 17 131곳·1.537억 유로 중 종이·판지 제조 6곳·560만 유로), FCC 산정 없음

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzm_latvia_mills_fillers.sql docs/handoff
git commit -m "data: Latvia fillers + mills + country market row"
git push origin marinebiogroup
```
