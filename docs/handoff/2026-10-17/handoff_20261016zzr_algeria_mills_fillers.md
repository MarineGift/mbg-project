# Handoff 2026-10-16 (zzr) — 알제리 제지사·충전제 + 시장현황 행 (아프리카 첫 국가)

> 앞 문서: `handoff_20261016zzq_andorra_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzr_algeria_mills_fillers.sql` | 필러 5, 밀 6(없을 때) + 배경 1(있을 때만), plant 블록, `app.country_markets` DZ 행 |

batch / source: `algeria_update_20261016` · 메모 표식 `DZ check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **ENOF (SONAREM) Oggaz** (2023-09 준공 설계 10만 t, 제지 용도 명시, Mellal 7만 t — 후보 1, B) · BEXCAR Constantine (Bexcarb 10N: D50 6.7 μm·2 μm 이하 22%·L* 96.6 — 제지용으론 굵음, 기술 파트너, C) · Golden Poudre Sétif · Baslimane Chaux Berriane (석회, PCC 원료) · Frères DIB El Khroub. Vita Plast·Brenntag (유통) 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Africaine Paper Mills Rouïba (티슈 점보롤, 3만 t 라인 계획 — split) · 2 Warak / Faderco Sétif (티슈 3만 t+) · 3 Tonic Industrie Bou Ismaïl (티슈·라이너·MG, 가동률 확인) · 4 Wafa Doux Aïn Oussera (신규, 2025-04 착공) · 5 Général Emballage (가공 26만 t 은 원지 아님, Naâma 35만 t 원지공장 계획 — split)
  - 우선순위 없음: GIPEC (초지기 확인 필요)
  - 배경: Maghreb Emballage
- **시장현황**: DZ 행 medium, FCC 900 ~ 13,500 t (계획 포함)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzr_algeria_mills_fillers.sql docs/handoff
git commit -m "data: Algeria fillers + mills + country market row"
git push origin marinebiogroup
```
