\xef\xbb\xbf# Handoff 2026-10-14 — 미국 필러 공급사 누락분 + 호스트 제지공장 링크

> 직전 handoff: `docs/handoff/2026-10-10/handoff_20261010f_after_e.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014_us_filler_mill_links.sql` | 필러 2사 + SMI 위성공장 8행 + 호스트 밀 최대 5행 + 공급 링크 10쌍. 멱등, 마지막 문장 = 검증 select |

source / batch 태그: `us_filler_gap_20261014`

## 2. 대조 결과 (보고서 vs URM)
- **이미 있음 (손대지 않음)**: Minerals Technologies, Specialty Minerals (HQ / USA Regional HQ), Omya (USA), Mississippi Lime, Imerys, Artemyn, Lhoist (HQ), Carmeuse, Huber
- **신규 필러사**: Columbia River Carbonates (Woodland WA, Omya+Bleeck 합작, 제지용 GCC), GLC Minerals (Green Bay WI, 제지 비중 낮음)
- **SMI 미국 위성공장** — MTI FY2024 10-K (2025-02-21 제출) Item 2 기준 11곳. 기존 행: Ticonderoga, Wickliffe, Chillicothe(2025 폐쇄, historical). 없을 때만 추가: Selma AL, Ashdown AR, Quinnesec MI, Cloquet MN, International Falls MN, Eastover SC, Longview WA, Superior WI

## 3. 링크 (SMI 공장 → 호스트 밀)
| 공장 | 호스트 밀 | 상태 |
|---|---|---|
| Selma AL | IP Riverdale | active / medium |
| Ashdown AR | Domtar Ashdown | active / high |
| Wickliffe KY | Phoenix Paper | active / high (기존이면 skip) |
| Quinnesec MI | Billerud Quinnesec | active / high |
| Cloquet MN | Sappi Cloquet | active / high |
| International Falls MN | Boise Paper (PCA) | active / high |
| Ticonderoga NY | Sylvamo Ticonderoga | active / high (기존이면 skip) |
| Eastover SC | Sylvamo Eastover | active / high |
| Longview WA | Nippon Dynawave | active / medium — WA Ecology: 공장 폐수를 Dynawave 가 처리. 구 10-K 는 Weyerhaeuser → NORPAC |
| Superior WI | Duluth 밀 (현 Sofidel 티슈) | **historical** 2011-04 ~ 2020-07, 최대 70,000 t/yr |

- 신규 밀 행은 같은 도시의 미국 밀 행이 없을 때만 생성 (IP Riverdale, Billerud Quinnesec, Boise International Falls, Nippon Dynawave Longview, Sofidel Duluth)
- Columbia River Carbonates·GLC 는 공개된 공장별 고객이 없어 **링크 없음** (추정 금지)

## 4. 실행 후 확인
- 검증 결과의 `status` 열: `added now` / `already there`
- link 가 10행보다 적으면 해당 도시의 밀 행 이름이 패턴과 다른 것 → 이름으로 행을 찾아 개별 문장으로 처리 (패턴 넓히기 금지)

## 5. 참고 / 남은 일
- Sofidel Duluth (재생 티슈): SMI 티슈 관심과 연결되는 사례 — 협의 자료에 활용 가능
- Superior WI 공장은 FY2024 10-K 에 아직 등재 — 현재 고객 미공개, 확인 필요
- Omya 미국 개별 공장 주소·고객은 공개자료로 미확정 (보고서와 동일) — 이번 배치에서 제외

## 6. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014_us_filler_mill_links.sql docs/handoff
git commit -m "data: US filler gaps (CRC, GLC, SMI satellites) + host mill links"
git push origin marinebiogroup
```
