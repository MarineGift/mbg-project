\xef\xbb\xbf# Handoff 2026-10-14 (d) — 일본 제지공장 plant 프로필

> 앞 문서: `handoff_20261014c_us_mill_plant_profiles.md` (Mill profile 카드 배포 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/fix_20261014d_jp_mill_plant_profiles.sql` | 일본 밀 16곳 `paper_mill_profile.extra_data.plant` — 기존 JP 밀 행에만 기록, 새 행 생성 없음 |

## 2. 우선순위 (outreach priority)
1 Hokuetsu Niigata · 2 Nippon Paper Ishinomaki · 3 Oji Kasugai · 4 Oji Yonago · 5 Daio Mishima · 6 Mitsubishi Hachinohe · 7 Nippon Paper Shiraoi
참고용(우선순위 없음): Oji Tomioka·Tomakomai, Nippon Paper Iwakuni·Otake·Iwanuma·Yatsushiro, Hokuetsu Kishu, Daio Kani, Chuetsu Takaoka

## 3. 확인한 사실 / 보고서만의 내용
- 확인: Shiraoi PM8(6.4만 t) 2025-09 정지, Yatsushiro N2(23.2만 t 신문용지) 2025-06 정지·2027 가정지 계획, Oji Tomakomai PM9(8.3만 t) 2025-03 정지, Mitsubishi Takasago 초지기 2025-12 정지
- 보고서만(confirm 표시): Tomakomai N-4 2026-03, Otake PM1 2026-06, Hokuetsu FY2024 수출 29만 t
- FCC 시나리오는 Ishinomaki(약 85만 t, 전량 인쇄·정보용지)만. Mishima(약 210만 t)는 판지·티슈 포함이라 시나리오 생략
- Shiraoi: Specialty Minerals FMT 밀 내부 PCC (기존 링크) — PM8 정지 후 가동 여부 확인 필요

## 4. 실행 후
- 검증 결과에 `MISSING` 이 있으면 그 밀 행이 DB 에 없음 → 결과 공유 후 개별 추가

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/fix_20261014d_jp_mill_plant_profiles.sql docs/handoff
git commit -m "data: Japan mill plant profiles (Hokuetsu, Nippon Paper, Oji, Daio, Mitsubishi)"
git push origin marinebiogroup
```
