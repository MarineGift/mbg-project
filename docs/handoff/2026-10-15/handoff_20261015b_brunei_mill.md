\xef\xbb\xbf# Handoff 2026-10-15 (b) — 브루나이 재생 티슈 밀 1곳 (낮은 우선순위)

> 앞 문서: `handoff_20261015a_timorleste_no_rows.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015b_brunei_mill.sql` | 밀 1곳(없을 때), 소개·메모, plant 블록 1 — 필러 없음 |

batch / source: `brunei_update_20261015` · 메모 표식 `BN check 2026-10-15`

## 2. 반영
- 제지용 PCC·GCC 제조사 없음 → 필러 행 없음
- Heidelberg Materials Butra 는 시멘트 (제품명 "PCC 52.5N" = Portland Composite Cement — 탄산칼슘 아님) → 추가 안 함
- 밀: EnEvo (투퉁, 회수 사무용지 재생펄프로 화장지 직접 초조, 2020 약 2 t/일)
- 수입·가공업체 (Muji Paper, AFIA, Sagaria, Wan Sing, Brunei Press) 추가 안 함

## 3. 판단
- EnEvo 는 재생섬유 티슈 실증 후보 — 로열티는 15% 가정에도 연 $2,100 미만
- 브루나이 수입 종이의 79%는 말레이시아·중국 — 사라왁 Hai Ming Paper Mills 확인 가치 (EnEvo 메모에 기록)

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015b_brunei_mill.sql docs/handoff
git commit -m "data: Brunei EnEvo recycled tissue mill (low priority)"
git push origin marinebiogroup
```
