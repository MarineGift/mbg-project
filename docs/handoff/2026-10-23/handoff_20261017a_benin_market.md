# Handoff 2026-10-17 (a) — 베냉 시장현황 행 + 카메룬 시드 보완

> 앞 문서: `handoff_20261016zzzz_cameroon_mills_fillers.md`
> **새 접두사 시작**: `seed_20261017a_...` (이름순으로 `20261016zzzz` 뒤)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017a_benin_market.sql` | 필러 2(없을 때), `app.country_markets` BJ 행 (priority none) — 밀 행 없음 |
| `sql/seed_20261016zzzz_cameroon_mills_fillers.sql` | **다시 생성** — 두 번째 카메룬 제지사 보고서 반영, 배경 8 → 13 |

## 2. 베냉 (BJ)
- 받은 자료 중 제지사 부분이 카메룬 보고서 → 베냉 제지사 정보 없음
- **필러 (C)**: SCB-Lafarge Onigbolo (매장 9,000만 t+, 1,924 ha, 시멘트 약 60만 t — 점토층 협재, 원료 후보 1) · NOCIBE Massé (시멘트 약 150만 t). CALCIM SA·CIMBENIN·SCB Cotonou 추가 안 함. 제지용 PCC·GCC 없음
- 시장현황: BJ none — 나이지리아·토고와 묶어 관리

## 3. 카메룬 (CM) 보완
- 배경 추가: PLASTICAM (1961, Bassa — 골판지·플라스틱, 공장 2), SATI SARL (골판지), Greystone Manufacturing (Odza — PaperOne 유통, 창고 2,500 m², 연 2만 t 생산 계획), TIOF Hygienic and Paper Industry, Le Menn Paper Converting (Limbe)
- SITA Industry 메모에 2018 SITRACEL 흡수합병 추가, SAFCA (Fotso 그룹) 메모
- 시장현황 요약에 FAO 2002 생산능력 약 5천 t (과거치) 추가

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017a_benin_market.sql sql/seed_20261016zzzz_cameroon_mills_fillers.sql docs/handoff
git commit -m "data: Benin market row; Cameroon converter rows"
git push origin marinebiogroup
```

## 5. 후속
- 베냉 제지기업 보고서 필요
