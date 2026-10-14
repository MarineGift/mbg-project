\xef\xbb\xbf# Handoff 2026-10-14 (s) — 미얀마 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014r_uae_mills_fillers.md` (실행·푸시 완료, 회사소개 규칙 적용 시작)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014s_myanmar_mills_fillers.sql` | 필러 1사, 밀 9곳(없을 때), 소개·메모, plant 블록 9 |

batch / source: `myanmar_update_20261014` · 메모 표식 `MM check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Crown Calcium Carbonate (양곤 East Dagon, MIA 2026~2028 집행위원 명단) — 폐업 표시 디렉터리 있음, 가동 여부 확인 필요
- 제외: Empire Chemicals·Ziwaka(유통), Ochnology(석회석 조달), SBM 미얀마 분쇄설비 고객(회사명 미공개, 스테아르산 코팅 플라스틱용). Omya·MTI·Artemyn 미얀마 공장 미확인
- Mill profile 우선순위: 1 New Century (재생 포장원지 월 5,000 t) · 2 YDE (50 t 신규 라인 설치 중) · 3 Star Flower 티슈 · 4 KKN Tissue · 5 Yeni Paper Mill · 6 Nilar Pulp & Paper (R&D 파트너) · 7 Thabaung (재가동 확인 시)
- 참고: Special Manufacturing, Tissue World (점보롤 수입 가공 — FCC 고객 아님)

## 3. 판단
- 미얀마는 2차 시장 — FCC 시나리오·링크 없음
- 접촉 창구: MPPIA (+95 1 296845, info@mppia2019.com) — 가동 제지사·초지기·충전제 공급사 명단 요청

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014s_myanmar_mills_fillers.sql docs/handoff
git commit -m "data: Myanmar filler + mills + intros + plant profiles"
git push origin marinebiogroup
```
