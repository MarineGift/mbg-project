# Handoff 2026-10-16 (zzs) — 튀니지 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzr_algeria_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzs_tunisia_mills_fillers.sql` | 필러 5, 밀 2(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` TN 행 |

batch / source: `tunisia_update_20261016` · 메모 표식 `TN check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **SOFAP Sfax** (1981, Gabès 채석장, 제지 용도 명시, 25만~35만 t, 아프리카 수출 — 후보 1, B) · **HERMESS Feriana** (3FN: 99.92%·평균 4 μm·2 μm 이하 30%·L 97 — B, STICC 와 전화번호 같음 → 관계 확인) · STPM Sidi Bouzid (Perle 3~15) · MBS Gabès (0~2 μm 표기 확인 필요) · SOCHEM (플라스틱용). 제지용 PCC 없음
- **밀**: 1 Azur Papier Zriba (SAH/Lilas, PM1 80 t/일 + PM2 115 t/일, 2024 생산 약 5.5만 t, 2022 수출 53%, 3호기 8만 t 계획 — split, Metsä Fibre 펄프) · 2 SOTIPAPIER Belli (PM2 크라프트 5만 + PM3 골심지·라이너 3만 = 8만 t)
  - 배경: SAH / Lilas (가공·판매), Cartonnerie Tunisienne, SITPEC, Yamama
- **시장현황**: TN 행 low, FCC 1,650 ~ 3,550 t. 알제리·모로코까지 공급하는 북아프리카 FCC 거점 후보로 기록

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzs_tunisia_mills_fillers.sql docs/handoff
git commit -m "data: Tunisia fillers + mills + country market row"
git push origin marinebiogroup
```
