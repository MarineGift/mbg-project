# Handoff 2026-10-16 (zzb) — 네덜란드 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zza_ireland_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzb_netherlands_mills_fillers.sql` | 필러 2, 밀 8(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` NL 행 |

batch / source: `netherlands_update_20261016` · 메모 표식 `NL check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: Omya Moerdijk (상업 PCC 1999 약 10만 t — 과거, C) · Sibelco Maastricht (산업용 탄산칼슘, 제지 미확인). 인근 공급원 메모: SMI Walsum (DE 행)
- **밀 / 우선순위**: 1 Sappi Maastricht (코팅 우드프리·판지 26만 t — 동일 회분 GCC 대비 시험, DE Alfeld 와 연계) · 2 Essity Cuijk · 3 WEPA Swalmen · 4 Schut Papier Heelsum (대체 섬유 특수지 — 해양섬유 공동개발) · 5 Papierfabriek Doetinchem · 6 Smurfit Westrock Roermond (2022 67만 t) · 7 Solidus
  - 우선순위 없음: Smurfit Westrock Parenco Renkum
  - 배경 (파산·폐쇄): Crown Van Gelder (2023-01 파산), Folding Boxboard Eerbeek (2026-06 파산 → 2026-08 폐쇄), Coldenhove (2026-05 파산), De Hoop Eerbeek, Sappi Nijmegen
- **시장현황**: NL 행 medium, FCC 7,800 ~ 13,000 t (Sappi Maastricht 기준). NL-BE-DE 를 한 권역으로 보는 전략 메모

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzb_netherlands_mills_fillers.sql docs/handoff
git commit -m "data: Netherlands fillers + mills + country market row"
git push origin marinebiogroup
```
