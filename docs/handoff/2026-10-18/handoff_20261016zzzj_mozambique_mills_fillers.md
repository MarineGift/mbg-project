# Handoff 2026-10-16 (zzzj) — 모잠비크 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzi_tanzania_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzj_mozambique_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` MZ 행 (priority none) |

batch / source: `mozambique_update_20261016` · 메모 표식 `MZ check 2026-10-16`

## 2. 반영
- **필러 (C)**: Cimentos de Moçambique (Salamanga 석회석 → Matola — 제지 품질 미검증). Dugongo (5천 t/일), CINAC, Cimentos da Beira (80만 t), Austral Cimentos Sofala (Heidelberg, 원료 수입) 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 1 INCEP (골심지 초지기 1,900 mm, 월 500 t ≈ 6천 t — split, 초지기 위치 Nampula/Nacala/Maputo 확인) · Ecopac Matola (제지공장 등록, 초지기 확인 — 우선순위 없음)
  - 배경: Portucel Moçambique (Navigator — 목재칩 100만·펄프 150만 t 계획, 2032~34·보류, 펄프는 충전제 시장 아님 — PT Navigator 행과 그룹 연결), Paper Tech, CarPack, Mozambique Packaging, AMAL, Mozindia, Right Choice
- **시장현황**: MZ 행 none, FCC 60 ~ 300 t. 남아공 경유

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzj_mozambique_mills_fillers.sql docs/handoff
git commit -m "data: Mozambique filler + mills + country market row"
git push origin marinebiogroup
```
