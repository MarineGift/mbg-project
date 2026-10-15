\xef\xbb\xbf# Handoff 2026-10-14 (ah) — 뉴질랜드 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014ag_nepal_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ah_newzealand_mills_fillers.sql` | 필러 2사, 밀 2곳(없을 때), 소개·메모, plant 블록 5 |

batch / source: `newzealand_update_20261014` · 메모 표식 `NZ check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Omya New Zealand (Te Kuiti — 건식·습식 GCC, 2018년 10만 t 초과), Graymont NZ (석회석·석회 원료). 뉴질랜드 제지용 PCC 공장 없음. Sibelco(현지 공장 미확인)·소형 석회 업체 제외
- Mill profile 우선순위: 1 Whakatāne Mill (FBB 15만 t) · 2 Essity Kawerau (티슈 5.5만 t, 뉴질랜드 유일 티슈 원지)
- 참고(있을 때만, 제외 표시): Oji Kinleith (PM6 2025-06 정지, 펄프만), Oji Penrose (2024-12 폐쇄), Norske Skog Tasman (2021 폐쇄)
- Pan Pac·Oji Tasman (펄프 전용) 추가 안 함

## 3. 판단
- 뉴질랜드 원지 기반 대부분 폐쇄 — 남은 FCC 대상 약 20.5만 t (Whakatāne + Essity)
- Oji 는 그룹 차원(일본·말레이시아) 접근, Opal 은 호주 공장 대상
- Omya Multifill 은 FCC 와 목적 중복 — 파트너이자 경쟁자
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ah_newzealand_mills_fillers.sql docs/handoff
git commit -m "data: New Zealand fillers (Omya Te Kuiti) + mills (Whakatane, Essity) + intros + plant profiles"
git push origin marinebiogroup
```
