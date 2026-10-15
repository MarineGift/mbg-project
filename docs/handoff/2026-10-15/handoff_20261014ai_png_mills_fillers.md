\xef\xbb\xbf# Handoff 2026-10-14 (ai) — 파푸아뉴기니 제지기업·석회석 업체 (낮은 우선순위)

> 앞 문서: `handoff_20261014ah_newzealand_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ai_png_mills_fillers.sql` | 필러 2사, 밀 4곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `png_update_20261014` · 메모 표식 `PG check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Bayawaha Limestone (모로베, CaCO3 99.8% — 사료·광산용, 제지용 미검증), Pacific Lime and Cement (구 Mayur, Central Lime Project 생석회 600 t/일 × 2, 2027 상반기 첫 생산 목표). PNG 제지용 PCC·GCC 공장 없음
- 밀: 1 KK Kingston (라에, 과거 PNG 최대 종이공장 — 현재 초지기 가동 확인) · 2 Star Mountain Paper · 3 Niugini Paper · 참고: Amalpack (골판지 가공)
- Lae Packaging Industries 는 플라스틱 봉투 업체 → 제외
- 확인 안 된 웹사이트(Pacific Lime) 비워 둠

## 3. 판단
- PNG 는 종이 수입 의존 — FCC 대상은 PNG 로 원지를 수출하는 인도네시아·말레이시아·중국 제지사
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ai_png_mills_fillers.sql docs/handoff
git commit -m "data: PNG limestone fillers + tissue mills (KK Kingston) - low priority"
git push origin marinebiogroup
```
