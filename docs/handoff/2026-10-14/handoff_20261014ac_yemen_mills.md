\xef\xbb\xbf# Handoff 2026-10-14 (ac) — 예멘 제지기업 (기록 전용, 낮은 우선순위)

> 앞 문서: `handoff_20261014ab_kuwait_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ac_yemen_mills.sql` | 밀 4곳(없을 때), 소개·메모, plant 블록 4 — 필러 없음 |

batch / source: `yemen_update_20261014` · 메모 표식 `YE check 2026-10-14`

## 2. 반영
- 제지용 PCC·GCC 제조사 없음 → 필러 행 추가 안 함 (예멘 수입량 2023 13,425 t, 요르단 69% — 요르단 공급사는 요르단 행)
- 밀: 1 NCSPI (HSA, 타이즈 — 티슈 가공, 초지 여부 확인) · 2 Al-Ganad (타이즈 — 노트는 구매 원지, 티슈 원지 확인) · 참고: National Company for Paper Products (사나), National Carton (HSA)
- **제재 주의**: 사나·타이즈 일부를 통제하는 Ansar Allah(후티)는 미국 지정 단체 — 모든 approach 에 `OFAC SDN 스크리닝 선행` 기록

## 3. 판단
- 확인된 초지기 없음, 분쟁 리스크 — 로열티 전망에 반영하지 않음
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ac_yemen_mills.sql docs/handoff
git commit -m "data: Yemen mills (record only, OFAC screening note)"
git push origin marinebiogroup
```
