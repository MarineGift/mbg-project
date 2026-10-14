\xef\xbb\xbf# Handoff 2026-10-14 (r) — UAE 제지공장·필러 + 회사소개 입력 규칙

> 앞 문서: `handoff_20261014q_saudi_mills_fillers.md` (실행·푸시 완료)

## 0. 새 규칙 (YunYoung, 2026-10-14)
**회사소개 정보는 Introduction(intro_ko / intro_en) 또는 Memo(notes)에 입력한다.**
- 신규 행: intro_ko·intro_en 에 1~2문장 회사소개, notes 에 추가 상세(설비·연락처·주의사항)
- 기존 행: intro 가 비어 있을 때만 채움 (기존 소개는 덮어쓰지 않음), notes 에는 `UAE check 2026-10-14` 표식으로 1회만 추가
- 공장 데이터(생산능력·필러·우선순위·접근)는 계속 Mill profile 카드(extra_data.plant)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014r_uae_mills_fillers.sql` | 필러 6사, 밀 9곳(없을 때), 소개·메모, 링크 1, plant 블록 11 |

batch / source: `uae_update_20261014`

## 2. 반영
- 필러: Omya (UAE) — Ittihad 공장 내 현장 PCC(소유·운영 주체 미공개), GMI (아지만 PCC 1.5만 t), ECCF, Gulf Lime, Apex Chemical (푸자이라 GCC 2단계 20만 t, 2025-05-07 개장), Wasit Group
- 링크: Omya (UAE) → Ittihad Paper Mill (active / medium)
- Mill profile 우선순위: 1 Ittihad (32.5만 t, 시나리오) · 2 Crown · 3 ADNPM · 4 Star 티슈 · 5 Al Nakheel (Fine) · 6 Queenex · 7 Star KEZAD 포장원지 (2026-05 개장) · 8 Union Paper Mills · 9 Gulf Paper Dubai · 10 Arabian Kraft — 참고: Al Dhafra

## 3. 후속 제안
오늘 앞서 입력한 9개국 신규 행은 회사소개가 notes 에만 있고 intro 는 비어 있음 → 필요 시 intro 백필 파일 별도 작성

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014r_uae_mills_fillers.sql docs/handoff
git commit -m "data: UAE fillers + mills + intros + plant profiles"
git push origin marinebiogroup
```
