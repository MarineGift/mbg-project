# Handoff 2026-10-16 (zzh) — 크로아티아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzg_austria_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzh_croatia_mills_fillers.sql` | 필러 3, 밀 2(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` HR 행 |

batch / source: `croatia_update_20261016` · 메모 표식 `HR check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Calcit Lika Gospić** (Calcit 그룹 GCC 공장 2012, 자체 채석장·철도, 2025 Thiele Kaolin 유통 협력 — 라이선스는 Calcit 본사(SI 행) 경유, B) · **STARAC** Siverić (White Rock 1~100 μm, 제지 슬러리 명시, 표기 35만 t — 범위 불명확, 현지 파일럿 파트너, B) · InterCal Croatia (Sirač·Ličko Lešće 석회). 가드 크로아티아 한정 → SI Calcit·InterCal 행과 분리 확인. 제지용 PCC 없음 (Omya Hydrocarb 슬러리 수입)
- **밀**: 1 DS Smith Belišće (PM2 12.5만 + PM3 9만 = 21.5만 t, 2025-01 International Paper 편입) · Violeta Sveti Ivan Zelina (티슈제품, 2025 매출 8,785만 유로 — 초지기 미확인, 우선순위 없음, BA Grude 와 같은 그룹)
  - 배경: Drvenjača (RMP 펄프 4.5만 t), Valica, Jaška (골판지 가공 3.5만 t), PAN Zagreb (파산)
- **시장현황**: HR 행 low, FCC 2,150 ~ 6,450 t (Belišće × 1~3%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzh_croatia_mills_fillers.sql docs/handoff
git commit -m "data: Croatia fillers + mills + country market row"
git push origin marinebiogroup
```
