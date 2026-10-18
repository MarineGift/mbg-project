# Handoff 2026-10-16 (zzw) — 리비아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzv_ghana_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzw_libya_mills_fillers.sql` | 필러 4, 밀 2(없을 때, 우선순위 없음) + 배경 10(있을 때만), plant 블록, `app.country_markets` LY 행 (priority none) |

batch / source: `libya_update_20261016` · 메모 표식 `LY check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- 모든 메모 끝에 `Screen counterparties against UN and US Libya sanctions lists.` (전면 제재국은 아님 — 지정 인물·기관 대상)
- **필러 (C)**: Osol Elnomow 트리폴리 (분쇄 CaCO3, 제지 명시 — 후보 1. 2026-05 Epic Powder 익명 고객 초미분 GCC 라인 시운전 메모 → mineral@epic-powder.com 에 고객명 문의) · Alhilal First 미스라타 (플라스틱용) · Al-Mokawelon (광물 개발) · Valley Mining (동부 GCC 공장 계획). Elwaseet (유통) 추가 안 함. 제지용 PCC 없음
- **밀 (우선순위 없음, 초지기 확인 필요)**: National Paper & Cardboard Factory 트리폴리 · Al-Jesr Al-Feddi Tajoura (재생 티슈 100%)
  - 배경 10: 티슈 가공 (Al-Emtiaz, Azhar Al-Rabie, Al-Sandiyan, Al-Warrak), 골판지 (Al-Nahda, Al-Badr, Tamina, Misrata Paper, Al-Jawda), Al-Tahdi (복사용지 — 재단 여부 확인)
- **200 t/일 재생 제지공장 계획** (약 6.6만 t, 4만 m², 2025-06 목표) — 가동 근거 없음, 회사명 미상 → 시장현황에만 기록
- **시장현황**: LY 행 none. 리비아 티슈는 튀니지 Azur Papier / SAH 경유가 더 직접적

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzw_libya_mills_fillers.sql docs/handoff
git commit -m "data: Libya fillers + mills + country market row"
git push origin marinebiogroup
```
