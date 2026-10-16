# Handoff 2026-10-15 (v) — 니카라과 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261015u_belize_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015v_nicaragua_mills_fillers.sql` | 필러 1, 밀 1(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` NI 행. 링크 없음 |

batch / source: `nicaragua_update_20261015` · 메모 표식 `NI check 2026-10-15`

## 2. 반영
- **필러**: Calcios de Nicaragua (해양 화석 탄산칼슘, 최소 60 μm — 원료 공급원만). Brenntag Nicaragua (유통), Carbotico (코스타리카 소재) 추가 안 함. 제지용 PCC·GCC 공장 없음
- **밀**: 1 Innova Industrias Tipitapa (재생 티슈, 과거 15 t/일 → 4,950 t/년 계산값). Base 5% = 248 t
  - 배경(있을 때만): Empaques Santo Domingo (COMECA), Envanic, Astro Carton / Astro Empaques, Industrias Gráficas Mercurio, Ecocentro — 가공업체
  - Kimberly-Clark Nicaragua 는 유통만. Alas Doradas (Grupo Coen, 6.5만 t) 는 엘살바도르 — 엘살바도르 보고서 때 추가
- **시장현황**: NI 행 low, FCC 149 ~ 248 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015v_nicaragua_mills_fillers.sql docs/handoff
git commit -m "data: Nicaragua filler + tissue mill + country market row"
git push origin marinebiogroup
```

## 4. 완료 국가 42 (+NI). 결과 대기: TH(o), CA(s), GT(t), BZ(u), NI(v)
