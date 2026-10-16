# Handoff 2026-10-16 (o, p, q) — 엘살바도르 + 자메이카·볼리비아 충전제 보완

> 앞 문서: `handoff_20261016n_honduras_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016o_elsalvador_mills_fillers.sql` | 필러 1 (Fábrica Bonanza), 밀 1 (Alas Doradas), SV 시장현황 행 |
| `sql/seed_20261016p_jamaica_fillers.sql` | 필러 3 (Lydford, Hodges, Chemical Lime), JM 시장현황 행 갱신 |
| `sql/seed_20261016q_bolivia_fillers.sql` | 필러 4 (MAPRIN, LUVEBOL, Estuquera Cayara, CALCO), BO 시장현황 행 갱신 |

## 2. 반영
- **엘살바도르 (SV)**: Fábrica Bonanza (Mejicanos, 생산 확인 필요) · Alas Doradas San Juan Opico (Grupo Coen 약 6.5만 t, Valmet DCT100HS, 재생 티슈·크라프트 — 우선순위 1). Pochteca·Brenntag·Química Industrial (유통) 추가 안 함. SV 행 medium, FCC 1,950~3,250 t. **제지기업 보고서 미입력**
- **자메이카 (JM)**: Lydford Mining St. Ann (고순도 GCC 미국 수출, 카리브 FCC 생산 후보 1) · Hodges (400 mesh, 카리브 9개국 수출) · Chemical Lime (원료). CEMEX·Caribbean Cement·Caribbean Mining·Limecore 추가 안 함. 2023 whiting +24.5만 t
- **볼리비아 (BO)**: MAPRIN Santiváñez (400~2500 mesh, 제지 명시, 후보 1 — PAPELBOL 재단시설과 같은 단지) · LUVEBOL CARBOCAL (97~99%) · Estuquera Cayara (백색 대리석) · CALCO Parotani (석회, PCC 원료 후보). Oxametal 추가 안 함. PAPELBOL 입찰 상세(2026-09-15, 75 t, Bs 2.50/kg, 11-03 납품) 시장현황에 추가
- 코스타리카 충전제 보고서는 중복 — seed_20261015w 로 처리 완료

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016o_elsalvador_mills_fillers.sql sql/seed_20261016p_jamaica_fillers.sql sql/seed_20261016q_bolivia_fillers.sql docs/handoff
git commit -m "data: El Salvador + Jamaica and Bolivia filler reports"
git push origin marinebiogroup
```

## 4. 남은 보고서: 코스타리카 제지기업, 엘살바도르 제지기업
