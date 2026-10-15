\xef\xbb\xbf# Handoff 2026-10-14 (u) — 파키스탄 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014t_bangladesh_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014u_pakistan_mills_fillers.sql` | 필러 7사, 밀 5곳(없을 때), 소개·메모, 링크 3, plant 블록 7 |

batch / source: `pakistan_update_20261014` · 메모 표식 `PK check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: **OmyaPack** (Omya 50 : Packages 50, Kasur 2018 — 2025 매출 PKR 26억), Asian Chemicals (PCC, 1981), Shaheen Grinding Mills (GCC 17만 t, 액상 분산), Shaheen Carbonates, Asian Polymer, Omar Group, Salamat
- 제외: Crown Mining, Prime Carbonate, Tycoon (제지 연결 미확인)
- 링크: Shaheen Carbonates → Empire / Fazal Paper Mills (active / medium — 회사가 고객 명시), **OmyaPack → Bulleh Shah (potential / medium — 같은 그룹, 공급량 미공개)**
- Mill profile 우선순위: 1 Bulleh Shah (설치 36만 t, 2025 생산 266,076 t) · 2 Premier (2.5만 t) · 3 Century (28만 t 판지) · 4 Flying Board (1.8만 t) · 5 Rose Petal 티슈 — 참고: Fazal, Empire
- 시나리오: Premier, Flying Board

## 3. 판단
- Bulleh Shah 240,000 t(1차 보고서)는 PACRA 2026-09 의 360,000 t / 266,076 t 로 대체
- OmyaPack: Omya 와의 FCC IP 경계 명확히 — Omya 는 이미 로열티 라이선시

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014u_pakistan_mills_fillers.sql docs/handoff
git commit -m "data: Pakistan fillers (OmyaPack) + mills + intros + links + plant profiles"
git push origin marinebiogroup
```
