\xef\xbb\xbf# Handoff 2026-10-14 (y) — 이스라엘 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014x_lebanon_mills_fillers.md` (+ Lebanese Calcium Carbonate 가드 수정)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014y_israel_mills_fillers.sql` | 필러 3사, 밀 5곳(없을 때), 소개·메모, 과거 링크 2, plant 블록 5 |

batch / source: `israel_update_20261014` · 메모 표식 `IL check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Omya Shefaya (2005 Hadera PCC 계약·이스라엘 PCC 공장), Specialty Minerals Israel (1996~2006-04, 이력 보존용), Negev Industrial Minerals (석회석·석회 원료). A. Shitzer(유통) 제외
- **과거 링크 → Infinya(Hadera)**: SMI Israel 1996-01 ~ 2006-04 (MTI 10-K), Omya Shefaya 2005-09 ~ 2020-12 (Hadera SEC, 2019 인쇄용지 철수) — 둘 다 historical / high
- Mill profile 우선순위: 1 Shaniv (티슈 3.5만 t+) · 2 Panda (Sano, 재생 티슈) · 3 Kimberly-Clark Israel · 4 Infinya (재생 골판지원지 32만 t) — 참고: Snir (Sano)

## 3. 판단
- 이스라엘의 PCC 수요는 Hadera 인쇄용지와 함께 사라짐 — 현재는 티슈·재생 골판지 시장
- Omya 는 Multifill·FiberLean 보유 — 파트너이자 경쟁자 (메모에 기록)
- FCC 시나리오 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014y_israel_mills_fillers.sql docs/handoff
git commit -m "data: Israel fillers + mills + historical PCC links + intros + plant profiles"
git push origin marinebiogroup
```
