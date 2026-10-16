# Handoff 2026-10-16 (g) — 칠레 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016f_argentina_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016g_chile_mills_fillers.sql` | 필러 3, 밀 10(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` CL 행 |

batch / source: `chile_update_20261016` · 메모 표식 `CL check 2026-10-15`

## 2. 반영
- **필러**: Calidra Chile Noviciado (GCC Fillpack·PCC Opacifill 제지 공급 명시 — PCC 는 아르헨티나 공장 생산 가능성, FCC 라이선스 후보 1) · Carbonatos SGI (Nogales, 월 6,000 t 계획) · IM Minerals (La Serena)
  - 추가 안 함: Top Química, Barahona (CALPREC), CCI (유통), Omya (칠레 공장 미확인)
- **밀 / 우선순위**: 1 FPC Tissue Coronel (NTT, 버진 펄프) · 2 Softys Talagante (Softys 칠레 합계 24.5만 t 을 이 행에만) · 3 Softys Puente Alto · 4 CMPC Boxboard Maule (Maule+Valdivia 52만 t 을 이 행에만) · 5 CMPC Boxboard Valdivia · 6 FPC Papeles Coronel · 7 Coipsa CPP San Pedro de la Paz, Papelera Dos Mostazal (사이트 매핑 확인 필요), CMPC Papeles Cordillera Puente Alto (25.2만 t, Smurfit Westrock 매각 계약 2026-09 승인 대기) · CMPC Laja (sack kraft 7만 t, 우선순위 없음)
  - 배경(있을 때만): CMPC Santa Fe·Pacífico (펄프), Arauco (펄프), Corrupac (상자)
- **시장현황**: CL 행 high, FCC 3,725 ~ 7,450 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016g_chile_mills_fillers.sql docs/handoff
git commit -m "data: Chile fillers + mills + country market row"
git push origin marinebiogroup
```
