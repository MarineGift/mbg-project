\xef\xbb\xbf# Handoff 2026-10-14 (ab) — 쿠웨이트 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014aa_iraq_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ab_kuwait_mills_fillers.sql` | 필러 2사, 밀 2곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `kuwait_update_20261014` · 메모 표식 `KW check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: KDF (Shuaiba, 시추용 광물 분쇄 롤러밀 3기·합산 25만 t — 제지용 미확인), NICBM 석회공장 (500 t/일, PCC 원료 후보). 쿠웨이트 PCC 제조사 없음
- Mill profile 우선순위: 1 Gulf Paper Manufacturing (포장원지 5만 t + 티슈 1.5만 t, 16.5~20 gsm) · 2 United Paper Industries (탈묵 펄프 — 초지기 확인 필요)
- 참고(있을 때만): Al Wataniya, Al Jothoor (가공업체 가능성 — 원지 공급처 문의)
- 제외: Al Khat, Kuwait Box, Caesar Pack (포장 가공)

## 3. 판단
- 단일 제지사 규모 작음 — 사우디·UAE 충전제 거점에서 공급하는 GCC 권역 통합 모델
- FCC 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ab_kuwait_mills_fillers.sql docs/handoff
git commit -m "data: Kuwait fillers + mills (Gulf Paper, UPI) + intros + plant profiles"
git push origin marinebiogroup
```
