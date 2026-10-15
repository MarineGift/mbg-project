\xef\xbb\xbf# Handoff 2026-10-14 (ae) — 스리랑카 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014ad_oman_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ae_srilanka_mills_fillers.sql` | 필러 5사, 밀 4곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `srilanka_update_20261014` · 메모 표식 `LK check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: LANMIC (초미립 GCC W-CARB, 연구소 3곳·수출), Quality Chemicals (PCC·GCC 제조공정 소개 — 현장 확인 필요), Unitum (UNICAL), Promark (원료·분쇄), Lanka Phosphate PCC 공장 **제안**(2026-01, 3만~5만 t — 미결정)
- Mill profile 우선순위: 1 National Paper Valaichchenai (인쇄·필기, 2025년 1~9월 2,066 t) · 2 Nalaka Tissue (일본산 티슈기 15 t/일) · 3 Nithya (Horana, 재생 골판지원지) · 4 KSPA Embilipitiya (PPP, 재생 라이너)

## 3. 판단
- 물량 작음 (4개 공장 전부 채택 가정해도 FCC 약 1,850 t·$2.8만/년) — 인쇄용지·티슈 **기술 실증 시장**
- Horana 에 Nithya·Nalaka 집중 → GCC 사(LANMIC)와 순차 시험 동선
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ae_srilanka_mills_fillers.sql docs/handoff
git commit -m "data: Sri Lanka fillers (LANMIC) + mills + intros + plant profiles"
git push origin marinebiogroup
```
