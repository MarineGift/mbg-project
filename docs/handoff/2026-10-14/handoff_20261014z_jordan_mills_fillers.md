\xef\xbb\xbf# Handoff 2026-10-14 (z) — 요르단 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014y_israel_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014z_jordan_mills_fillers.sql` | 필러 6사, 밀 3곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `jordan_update_20261014` · 메모 표식 `JO check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Manaseer Carbonate (Qatrana, 35만 t+), GCCI (25만 t, 제지 충전·코팅 명시), Jordan Minerals (제지용 초미분 JM1SFN·JM2SFN), Jordan Carbonate (2006 Omya 합작 이력), Petra Calcium Carbonate, ILCCMCo (PCC 주장 — 상업 가동 미확인). Global Polymer 제외
- Mill profile 우선순위: 1 Sanabel Al Ataa (신규 티슈 PM1 2.1만 t + PM2 2.6만 t, 2026-10 가동) · 2 Al Snobar (Fine, 5.4만 t) · 3 Al Keena (Fine, 3만 t)
- 참고: Jordan Paper & Cardboard (2024-08 청산 개시 — 제외 표시)
- 미추가: NIC (2003 청산), Al Hourani·Perfect Printing (가공업체)

## 3. 판단
- 요르단 GCC 사의 사업 기회는 내수보다 사우디·UAE·이라크 수출 — 제지사와의 공급관계는 미확인 → 링크 없음
- Fine Hygienic 은 Al Nakheel(UAE)과 함께 그룹 단위 접근
- Jordan Carbonate: Omya 와의 기존 기술계약 제한 여부 확인

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014z_jordan_mills_fillers.sql docs/handoff
git commit -m "data: Jordan fillers + tissue mills (Sanabel, Fine) + intros + plant profiles"
git push origin marinebiogroup
```
