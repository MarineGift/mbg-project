\xef\xbb\xbf# Handoff 2026-10-14 (m) — 베트남 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014k_malaysia_mills_fillers.md` (+ l: Muda 단일 행 plant 블록)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014m_vietnam_mills_fillers.sql` | 필러 8사, 밀 8곳(없을 때), plant 블록 9 |

batch / source: `vietnam_update_20261014`

## 2. 이미 있음
VSV Group, Global Filler, VINAPACO, Dong Hai Ben Tre

## 3. 추가
- 필러 (없을 때): VMPC (옌바이, 30만 t, 제지용 GCC 사양 공개), YBM (5공장·약 99만~100만 t+), EAMC (응에안 2공장, 20만 t+), Tan Ky (PCC 제품 — 자체 합성 미확인), ACBM, Mien Trung Mineral (7만 t), Nimex, Phu Thanh Dat (PCC). Eco Green 은 플라스틱이라 제외. 연락처는 notes 에만
- 밀 (없을 때 생성): An Hoa, VINAPACO Bai Bang, Saigon Paper, New Toyo Pulppy, Vina Kraft, Cheng Loong, Lee & Man Vietnam, Nine Dragons Vietnam
- Mill profile 우선순위: 1 An Hoa (복사용지 14만 t) · 2 VINAPACO Bai Bang · 3 Saigon Paper (티슈) · 4 New Toyo Pulppy (티슈)
- 참고: Vina Kraft(87만 t), Cheng Loong(약 100만 t), Lee & Man(55만 t), Nine Dragons(43만 t), Dohaco(Giao Long 3 2027)

## 4. 판단
- FCC 시나리오는 An Hoa 만. Bai Bang 은 2026 라인 전환 중(10만 → 18만 t, 일부 포장지)이라 생략
- 보고서의 국가 단위 시나리오(인쇄·필기 29.8만 t, 티슈 41.6만 t)는 DB 에 넣지 않음
- 확인된 밀–필러 공급관계 없음 → 링크 없음 (북부 VMPC·YBM ↔ An Hoa·Bai Bang 은 후보일 뿐)

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014m_vietnam_mills_fillers.sql docs/handoff
git commit -m "data: Vietnam fillers + mills + plant profiles"
git push origin marinebiogroup
```
