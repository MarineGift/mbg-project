# Handoff 2026-10-16 (zzzl) — 마다가스카르 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzk_botswana_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzl_madagascar_mills_fillers.sql` | 필러 3, 밀 2(없을 때) + 배경 8(있을 때만), plant 블록, `app.country_markets` MG 행 (priority none) |

batch / source: `madagascar_update_20261016` · 메모 표식 `MG check 2026-10-16`

## 2. 반영
- **필러 (C)**: Chaux Roca (대리석 분쇄 CaCO3 95.5%, Fe2O3 0.3% — 농업용, 현지 파트너 후보) · Soalara Calcaire (Cassius Mining, Toliara 남 28 km, CaO 56.01%·Fe2O3 0.07% — 탐사 단계, 장기 수출형 GCC 원료) · Agro Industrie / Ocean Trade (99%·5 μm 판매, 원산지 미상 — 샘플원). SCB·MBS (TN 행) 추가 안 함, Belobaka 채석장 2026-01 중단 메모. 제지용 PCC 없음
- **밀**: 1 SPAH (Sipromad, 2012~ 재생 티슈 일관 — 폐지 1,200 t+, 약 1,800만 롤) · 2 PAPMAD (1963, 과거 9천~1만 t — 가동 확인)
  - 같은 Ambohimanambola → 소유사 정규식 분리
  - 배경: GPM SA (사례 문서 — 실재 확인), SEMBA, NEWPACK, MHPC, Cellupack (Softy), EPIC, EUROPLI, Eco-Pulp
- **시장현황**: MG 행 none, FCC 산정 안 함

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzl_madagascar_mills_fillers.sql docs/handoff
git commit -m "data: Madagascar fillers + mills + market row"
git push origin marinebiogroup
```
