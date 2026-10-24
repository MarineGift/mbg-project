# Handoff 2026-10-16 (zzzz) — 카메룬 충전제·제지사 + 시장현황 행

> 앞 문서: `handoff_20261016zzzw_car_market_v2.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzz_cameroon_mills_fillers.sql` | 필러 1, 밀 1(없을 때, 우선순위 없음) + 배경 8(있을 때만), plant 블록, `app.country_markets` CM 행 (priority none) |

batch / source: `cameroon_update_20261016` · 메모 표식 `CM check 2026-10-16`

## 2. 반영
- **필러 (C)**: CIMENCAM (Figuil 석회석 명목 27.5만 t, USGS 2019). 2026 Douala 분지 연구 CaCO3 약 99% 층 (Mungo River, Mbalangi, Ediki) 메모. CIMAF·Dangote (시멘트), ASCOM SARL·SPIEX·AFOMA-CM (탄산칼슘 상사) 추가 안 함. 튀니지 MBS 카메룬 수출 메모. 제지용 PCC·GCC 없음
- **밀**: SITRACEL (1978, Yaoundé·Douala, 티슈·노트·복사용지, 장비 28대 — 티슈 초지기인지 점보롤 가공인지 확인)
  - 배경: SITA Industry (SITRACEL 그룹), SOCARTO (크라프트 포대 1~6겹), **SAMCO Paper** (Ombe 재단, CAR·TD·GQ 판매 — CF 보고서 후속 반영 완료), Moore Paragon, SAFCA, Printpak, PIC, CELLUCAM (Edéa 펄프 1980~1986 청산)
- **시장현황**: CM none. 2023 HS 480560 약 7.6천 t, HS 4818 약 5천 t 수입. Douala = CEMAC 종이 유통 거점

## 3. 파일 접미사
- 이번이 `zzzz`. 다음 배치는 날짜를 바꿔 `seed_20261017a_...` 부터 시작 권장 (이름순 정렬 유지, 접미사 단순화)

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzz_cameroon_mills_fillers.sql docs/handoff
git commit -m "data: Cameroon filler + mill + market row"
git push origin marinebiogroup
```
