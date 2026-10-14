\xef\xbb\xbf# Handoff 2026-10-14 (t) — 방글라데시 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014s_myanmar_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014t_bangladesh_mills_fillers.sql` | 필러 4사, 밀 8곳(없을 때), 소개·메모, SMI 링크 1, plant 블록 12 |

batch / source: `bangladesh_update_20261014` · 메모 표식 `BD check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: BBCL (PCC, Sreemangal), Crescent Chemical (PCC·GCC, Gazipur), ASM Chemical (GCC, D50 1.5~6 µm), Unirex (PCC 공장 2027 목표 — 미가동)
- 제외: Uni Lube (공정 미확인), Quality Mineral·NRJ (플라스틱 마스터배치)
- 링크: SMI → Bashundhara Paper Mills (Meghnaghat 위성 PCC, MTI 2007 계약) — active / medium, 기존 SMI 링크 있으면 skip
- Mill profile 우선순위: 1 Bashundhara Multi-Paper (자체 PCC·WGCC) · 2 Meghna (수입 펄프 인쇄 300 t/일·티슈 100 t/일) · 3 Partex Tissue · 4 Lipy (6만 t) · 5 Pearl Paper (4만 t) · 6 Sonali · 7 Akij · 8 Partex Paper
- 참고: Bashundhara Paper Mills, Hakkani, Karnaphuli, Magura Paper
- 시나리오: Meghna 인쇄·필기(9.9만 t 환산), Lipy, Pearl, Sonali

## 3. 판단
- BMPIL 홈페이지의 210만 t 은 사용하지 않음 (초지기별 확인 전)
- 2025~26 업계 침체(가동중단 70~80개 공장 주장) — 신규 FCC 공장보다 기존 PCC·GCC 설비 활용

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014t_bangladesh_mills_fillers.sql docs/handoff
git commit -m "data: Bangladesh fillers + mills + intros + SMI link + plant profiles"
git push origin marinebiogroup
```
