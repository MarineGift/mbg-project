\xef\xbb\xbf# Handoff 2026-10-14 (ad) — 오만 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014ac_yemen_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ad_oman_mills_fillers.sql` | 필러 5사, 밀 2곳(없을 때), 소개·메모, plant 블록 3 |

batch / source: `oman_update_20261014` · 메모 표식 `OM check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: IMC (Northern Minerals, 소하르 GCC 12만 t), GMMC (살랄라, 제지 용도 명시), SAC (시추용, 광물 합산 30만 t), ALTAIF (6,000 t/일 GCC 계획 — 미가동), Al Jood (저실리카 석회석 원료). 오만 PCC 공장 없음, Global Chemicals(유통) 제외
- Mill profile 우선순위: 1 Keryas (재생 골판지원지 18만 t, 2022 생산 약 10만 t) · 2 Oman Royal Paper (100 t/일) — 참고: CARMA (가공, 있을 때만)
- 살랄라 자유무역지대 신규 티슈시설(2026-02 상업가동)은 운영사 미확인 → 행 없음, CARMA 메모에 기록

## 3. 판단
- 오만 원지는 재생 포장용지 중심 — 섬유 절감·강도 유지 시험 대상
- 소하르: IMC(GCC) ↔ Keryas 같은 산업단지 — 현지 FCC 생산 조합 후보 (카드 approach)
- 오만 GCC 사는 UAE·사우디 수출 거점 후보

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ad_oman_mills_fillers.sql docs/handoff
git commit -m "data: Oman fillers (IMC) + mills (Keryas) + intros + plant profiles"
git push origin marinebiogroup
```
