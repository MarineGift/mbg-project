\xef\xbb\xbf# Handoff 2026-10-14 (v) — 아프가니스탄 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014u_pakistan_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014v_afghanistan_mills_fillers.sql` | 필러 1사, 밀 4곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `afghanistan_update_20261014` · 메모 표식 `AF check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Afghan Morvarid Stone Mining (헤라트 대리석 미분말 — 제지용 등급 미확인). PCC 제조사 없음
- 제외: Natural Stone·Sahil Marble·Mezan Sultani (석재만), Zia Sahak (유통)
- Mill profile 우선순위: 1 Baheer Group (자체 제지공장, 2022 연 5.5만 t 발표) · 2 Paktia Paper · 3 Rahim Gardizi (재단·포장 가능성 — 초지 여부 확인)
- 참고: Wazirson (PaperOne 원지 롤 수입 가공 — FCC 고객 아님, UAE 유통망)

## 3. 판단
- 장기 시장 — FCC 시나리오·링크 없음
- 수입 원지 재단업체의 A4 물량은 FCC 수요에 포함하지 않음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014v_afghanistan_mills_fillers.sql docs/handoff
git commit -m "data: Afghanistan filler + mills + intros + plant profiles"
git push origin marinebiogroup
```
