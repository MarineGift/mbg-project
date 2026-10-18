# Handoff 2026-10-16 (zzy) — 케냐 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzx_sudan_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzy_kenya_mills_fillers.sql` | 필러 4, 밀 8(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` KE 행 |

batch / source: `kenya_update_20261016` · 메모 표식 `KE check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Mineral Enterprises (MELWIT) Athi River** (1991~, Kajiado 원료, 알칼리 초지·티슈용 GCC 명시, KAOMEL 카올린 — 동아프리카 후보 1, B) · Kiki's Nairobi (초미세 D50 1.2~2.0 μm·ISO 97 웹 표시 — 자체 설비 검증, C) · Dalit (GCC·PCC 공급) · Sanvil. Innova·Karanwal (인도) 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Chandaria (1964, 재생 티슈 일관) · 2 Kenturian Kisaju (18~19 gsm 재생 점보롤, 우간다 수출) · 3 Kim-Fay (Tatu City 신규 재생 티슈 공장 약 KSh 25억 — 가동 확인) · 4 Transafrica · 5 Rai Paper Webuye (구 Pan African, 2025 KSh 30억 재투자 — 과거 11만 t 은 현재 아님) · 6 EAPM Thika (라이너) · 7 Mega Paper Nakuru (3.6만 t)
  - 우선순위 없음: Fortuna
  - 배경: Cots Paper and Board, Jubilee Tissue
  - 나이로비 공장 다수 → 소유사 정규식 분리
- **시장현황**: KE 행 low, FCC 산정 보류. MEL GCC + 티슈 공장 → 우간다·탄자니아 확대

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzy_kenya_mills_fillers.sql docs/handoff
git commit -m "data: Kenya fillers + mills + country market row"
git push origin marinebiogroup
```
