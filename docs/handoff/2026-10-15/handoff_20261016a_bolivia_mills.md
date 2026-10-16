# Handoff 2026-10-16 (a) — 볼리비아 제지사 + 시장현황 행

> 앞 문서: `docs/handoff/2026-10-15/handoff_20261015z_guyana_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016a_bolivia_mills.sql` | 밀 4(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` BO 행. 필러 없음 |

batch / source: `bolivia_update_20261016` · 메모 표식 `BO check 2026-10-15`

## 2. 반영
- **밀 / 우선순위**: 1 PAPELBOL Villa Tunari (국영, 재생 인쇄·복사·크라프트, 2024 1만 t+ 전망, 탄산칼슘 75 t 구매 공고 2026-09) · 2 COPELME Cochabamba (Grupo Mendoza, PM3·PM4, 점유율 34%) · 3 Papelera Vinto (버진 펄프, 34%) · 4 KUPEL / Empacar Santa Cruz (2024 재가동, Finesse, 16%)
  - 배경(있을 때만): Kimberly Bolivia (현지 생산 중단·자산 Empacar 매각 보도), La Papelera (주로 가공), Paper King, Papelex, Novopel Tissue, Riverijos, Indamika
- **FCC Base**: PAPELBOL 1만 t × 5% = 500 t (티슈 3사는 톤수 미공개)
- **필러 없음**: 충전제 보고서 미제공 — MAPRIN·LUVEBOL 은 보고서 받으면 추가
- **시장현황**: BO 행 medium, FCC 300 ~ 500 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016a_bolivia_mills.sql docs/handoff
git commit -m "data: Bolivia mills + country market row"
git push origin marinebiogroup
```

## 4. 충전제 보고서 대기: JM, BO. 제지기업 보고서 대기: CR
