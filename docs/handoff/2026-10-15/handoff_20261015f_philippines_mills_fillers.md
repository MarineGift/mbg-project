\xef\xbb\xbf# Handoff 2026-10-15 (f) — 필리핀 제지공장·필러 업데이트

> 앞 문서: `handoff_20261015e_australia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015f_philippines_mills_fillers.sql` | 필러 5사, 밀 5곳(없을 때), 소개·메모, plant 블록 6 |

batch / source: `philippines_update_20261015` · 메모 표식 `PH check 2026-10-15`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Omya Mineral Philippines (2010, 코팅·비코팅 GCC 현지 제조 — 영업 Omya Chemical Merchants), Philstone (Novaliches, BOI 국내 충전제사), Kingstone (불라칸, 제지 용도 명시), South Pacific Chemical (경질 PCC 표기 — 합성 여부 미확인), Busilak (제지용 LPCC 표기 — 합성 미확인). Alad·HT Mining·유통사 제외
- Mill profile 우선순위: 1 Bataan 2020 (인쇄·티슈·포장, 10만 t+) · 2 Quanta Paper (티슈, 초지기 5대) · 3 TIPCO (탈묵 재생 인쇄·신문) · 4 Fifth Discipline (400 t/일, 백색 재생지) · 5 UPPC (SCGP, 45만 t 골판지원지)
- 참고(있을 때만): Multi Ply
- BOI 인쇄용지 밀 (Alliance, Hansson, Rural, Vanson, Fedco) 은 보고서에 상세 없음 → 미추가, 후속 조사 후보
- 확인 안 된 웹사이트(South Pacific) 비워 둠

## 3. 판단
- 필리핀 165만 t 중 포장 132만 t — 인쇄 25만 t·티슈 5만 t 가 FCC 직접 대상
- 2023 가동률 56% (수입 경쟁) — 원가절감 수요 존재
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015f_philippines_mills_fillers.sql docs/handoff
git commit -m "data: Philippines fillers (Omya PH) + mills (Bataan 2020, Quanta, TIPCO, UPPC) + intros + plant profiles"
git push origin marinebiogroup
```
