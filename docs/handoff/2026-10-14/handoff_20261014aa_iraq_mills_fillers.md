\xef\xbb\xbf# Handoff 2026-10-14 (aa) — 이라크 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014z_jordan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014aa_iraq_mills_fillers.sql` | 필러 4사, 밀 4곳(없을 때), 소개·메모, plant 블록 5 |

batch / source: `iraq_update_20261014` · 메모 표식 `IQ check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: White Shield (Kayaci, 다르반디칸 — GCC·PCC 주장, PCC 설비 미확인), Noor Al Shams (칼라르, 제지 용도 명시), Al Azm (바그다드, 투자 파트너형), Basmat Al-Haram (홈페이지 구축 중)
- 이란·튀르키예·중국 수출업체는 이라크 행으로 추가하지 않음
- Mill profile 우선순위: 1 Al Sindyan (티슈 65 t/일, ACACIA 와 동일 공장 가능성 — 중복 집계 금지) · 2 Al Shumookh (포장원지 500 t/일 계획 + 티슈 70 t/일 프로젝트, 시운전 준비 단계)
- 참고: Basra·Maysan 국영공장 (재건 대상), Narjis (있을 때만)

## 3. 판단
- 단일 중형 티슈공장 로열티는 작음 (Al Sindyan 5% 가정 시 약 1,040 t·$15,600/년) — 다수 티슈공장 또는 대형 라인 필요
- FCC 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014aa_iraq_mills_fillers.sql docs/handoff
git commit -m "data: Iraq fillers + mills (Al Sindyan, Al Shumookh) + intros + plant profiles"
git push origin marinebiogroup
```
