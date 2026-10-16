# Handoff 2026-10-15 (x) — 자메이카 제지사(초지기 미확인) + 시장현황 행

> 앞 문서: `handoff_20261015w_costarica_fillers.md`
> 파일 알파벳: 2026-10-15 는 x 까지 사용 (y, z 남음). handoff w 의 "다음 20261016a" 는 날짜가 바뀌기 전이라 x 로 이어 씀.

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015x_jamaica_mills.sql` | 밀 1(없을 때, 우선순위 없음) + 배경 9(있을 때만), plant 블록, `app.country_markets` JM 행. 필러 없음 |

batch / source: `jamaica_update_20261015` · 메모 표식 `JM check 2026-10-15`

## 2. 반영
- **밀**: West Indies Pulp & Paper (Freetown, Clarendon) — 과거 티슈 원지 제조, 2004 티슈 사업이 Quality Incorporations VII 로 넘어감, 현재 초지기 가동 미확인 → 우선순위 없음
- **배경(있을 때만, 가공업체)**: Sanmerna (일 12만 롤+, 수입 원지, 킹스턴항 신공장 2028 착공 목표), Quality Incorporations VII, Choi's, HDB, Jiffy, Seven Industries, Jamaica Packaging Industries (구 Corrpak 포함), AMG Packaging & Paper, Sterling Packaging
- **필러 없음**: 붙여 준 보고서는 제지기업 편만 있음. Lydford Mining·Hodges Aggregates & Powders (GCC) 는 충전제 보고서를 받으면 추가
- **시장현황**: JM 행 low, FCC 산정 불가

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015x_jamaica_mills.sql docs/handoff
git commit -m "data: Jamaica mill history + converters + country market row"
git push origin marinebiogroup
```

## 4. 대기: 자메이카 충전제 보고서, 코스타리카 제지기업 보고서. 실행 결과 대기: TH, CA, GT, BZ, NI, CR, JM
