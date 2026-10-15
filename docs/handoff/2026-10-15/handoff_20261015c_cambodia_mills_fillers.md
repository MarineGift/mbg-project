\xef\xbb\xbf# Handoff 2026-10-15 (c) — 캄보디아 제지공장·필러 (낮은 우선순위)

> 앞 문서: `handoff_20261015b_brunei_mill.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015c_cambodia_mills_fillers.sql` | 필러 1사, 밀 3곳(없을 때), 소개·메모, plant 블록 4 |

batch / source: `cambodia_update_20261015` · 메모 표식 `KH check 2026-10-15`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: KPTT-Investment (프놈펜, 산업용 석회석 분말 — 제지용 미확인). 캄보디아 제지용 PCC·GCC 공장 없음. Brenntag(유통)·시멘트사 제외
- 밀: 1 Rongwei Industrial (연 12만 t 포장용지 프로젝트, 2025-05 Yunda 설비계약 — 가동 미확인, 위치 미공개) · 2 Sary Paper (시아누크빌 티슈) · 3 Dynith (프놈펜 미용티슈) — 2·3 은 자체 초지 여부 확인
- 참고(있을 때만): CAM Paper Industries
- Oji/Harta 골판지 공장 3곳·Rongxing 은 가공업체 → 추가 안 함
- 확인 안 된 웹사이트(Sary) 비워 둠

## 3. 판단
- 2024 HS 48 수입 $738M (중국 52%, 베트남 26%) — 실제 FCC 기회는 캄보디아로 수출하는 베트남·태국 원지 공장 (예: Thuận An Paper)
- Oji 는 그룹 차원 접근 (동남아 원지 공장)
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015c_cambodia_mills_fillers.sql docs/handoff
git commit -m "data: Cambodia filler + mills (Rongwei, Sary, Dynith) - low priority"
git push origin marinebiogroup
```
