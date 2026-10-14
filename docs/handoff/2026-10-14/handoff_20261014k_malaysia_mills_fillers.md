\xef\xbb\xbf# Handoff 2026-10-14 (k) — 말레이시아 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014i_indonesia_mills_fillers.md` (+ j: Pura·Adiprima 추가 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014k_malaysia_mills_fillers.sql` | Sipitang 링크 historical 전환, 필러 6사, 밀 6곳(없을 때), plant 블록 10 |

batch / source: `malaysia_update_20261014`

## 2. 반영
- **SMI → Sabah Forest Industries Sipitang: active → historical** (active_until 2019-01-01). 확인: 2019 주 총리 "공장 가동 중단·설비 대부분 고철", 법정관리, 2025 부지 회수
- 필러 (없을 때): MRC Industries (Perak, 습식 분쇄 3라인), Schaefer Kalk (Malaysia) (Kuala Ketil — PCC 공장 확인), Omya (Malaysia) (Shah Alam — 제지 전용 공장 미확인), Imerys Minerals Malaysia, RCI Lime (Gopeng), Jayatrade (Seremban). Lon Dah 은 플라스틱 마스터배치라 제외
- Zantat 메모 추가: Ipoh GCC 32만 t, KL 분산액 6만 t(주로 라텍스 장갑), PCC 분말은 수입 — 자체 PCC 합성 아님
- 밀 (없을 때 생성): NTPM, Kimberly-Clark Kluang, GS Paperboard Banting, Lee & Man Malaysia, Nine Dragons Malaysia, Fudak
- Mill profile 우선순위: 1 NTPM (티슈, MBG 15 gsm·FCC 5% 시험 비교) · 2 Kimberly-Clark Kluang · 3 GS Paperboard (PM2 White Top 5.5만 t) · 4 Muda Kajang · 5 Lee & Man · 6 Nine Dragons
- 참고: Muda Tasek, Fudak(자체 초지 여부 확인), Pascorp(2025-08-15 조업중단), SFI(가동중단)

## 3. 보고서 대비 판단
- 포장지 대형사(Lee & Man 140만 t, Nine Dragons 90만 t)는 전체 능력을 FCC 물량으로 보지 않음 — 시나리오 없음
- FCC 시나리오는 GS PM2 White Top (5.5만 t)만
- 보고서의 기업별 가상 물량(5천~1만 t)은 DB 에 넣지 않음
- 확인된 밀–필러 공급관계가 없어 신규 링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014k_malaysia_mills_fillers.sql docs/handoff
git commit -m "data: Malaysia fillers + mills + plant profiles, SFI link historical"
git push origin marinebiogroup
```
