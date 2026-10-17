# Handoff 2026-10-16 (z) — 아르메니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016y_azerbaijan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016z_armenia_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` AM 행 |

batch / source: `armenia_update_20261016` · 메모 표식 `AM check 2026-10-16`

## 2. 반영
- **필러**: GALIK Ararat (석회석·석회, 원료). 추가 안 함: Araratcement·Hrazdan Cement (시멘트), Karmend Chemicals (수입), Arosha Powder (이란 — 제재, 조달원 아님). 제지용 PCC·GCC 없음
- **밀**: 1 Grand Master Masis (재생 종이·판지 + 위생용 티슈, Grand Holding) · 2 Gofroline Marmarashen (자체 롤 원지·판지·골판지). 생산량 미공개
  - 배경(있을 때만): Tukhtard-Tara, Kradan, Cleanland, Softex, Unigroup, TOOP, BA LI Harutyunyan
- **시장현황**: AM 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016z_armenia_mills_fillers.sql docs/handoff
git commit -m "data: Armenia filler + mills + country market row"
git push origin marinebiogroup
```

## 4. 다음 파일 접미사
2026-10-16 은 a~z 를 모두 썼으므로 다음 시드는 `seed_20261016za_...` 부터 사용
