# Handoff 2026-10-16 (zzp) — 덴마크 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzo_belarus_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzp_denmark_mills_fillers.sql` | 필러 2, 밀 2(없을 때) + 배경 8(있을 때만), plant 블록, `app.country_markets` DK 행 |

batch / source: `denmark_update_20261016` · 메모 표식 `DK check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (C)**: Dankalk Aggersund (DLG 56%·Omya 44%, Betocarb·Lime Filler — 제지 등급 없음, Omya 그룹 경로 메모) · Faxe Kalk (Lhoist, Faxe 원료 연 약 300만 t — 제지용 아님). 제지용 PCC·GCC 없음
- **밀**: 1 Sonoco Skjern (100% 재생 Greyboard·Greyliner·Blueliner·URB, 2022 인수 — 그룹 180만 t 은 공장 단독 아님) · 2 Hartmann Tønder (몰드펄프 계란 포장, 약 350명)
  - 배경: Smurfit Westrock Danmark, DS Smith Denmark, VPK Randers, Schur Pack, ABENA, Elopak (배리어 코팅 협력 아이디어), Dalum (2012 폐쇄), Grenaa (2006 폐쇄)
- **시장현황**: DK 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzp_denmark_mills_fillers.sql docs/handoff
git commit -m "data: Denmark fillers + mills + country market row"
git push origin marinebiogroup
```
