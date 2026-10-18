# Handoff 2026-10-16 (zzl) — 리투아니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzk_slovakia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzl_lithuania_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` LT 행 |

batch / source: `lithuania_update_20261016` · 메모 표식 `LT check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: Naujasis Kalcitas Menčiai (농업·건설용 분쇄 석회석, 탄산염 94%+, 0~0.2 mm — 제지 규격 없음, C). AB Kalcitas·Akmenės Cementas·Mortar Akmenė 추가 안 함. 제지용 PCC·GCC 없음
- **밀 / 우선순위**: 1 Grigeo Tissue Grigiškės (PM5·PM6, PM7 Toscotec 7만 t 2028 상반기 — split 에만, 그룹 7만→14만 t 은 폴란드 포함) · 2 Grigeo Klaipėda (재생 테스트라이너·골심지, 2024 매출 4,970만 유로)
  - Grigeo Tissue 는 도시 fallback 없음 → Grigiškės 의 Grigeo Hygiene·Packaging 행에 잘못 붙지 않음
  - 배경: Grigeo Hygiene, Grigeo Packaging, DS Smith Packaging Lithuania, Smurfit Westrock Baltic, Stora Enso Packaging
- **시장현황**: LT 행 low, FCC 2,100 ~ 7,000 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzl_lithuania_mills_fillers.sql docs/handoff
git commit -m "data: Lithuania filler + mills + country market row"
git push origin marinebiogroup
```

## 4. 후속
PL 보완 시: Grigeo Niedomice 티슈 공장 (2024 인수) 행 확인
