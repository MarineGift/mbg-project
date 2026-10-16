# Handoff 2026-10-16 (n) — 온두라스 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016m_panama_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016n_honduras_mills_fillers.sql` | 필러 2, 밀 2(없을 때) + 배경 7(있을 때만), plant 블록, `app.country_markets` HN 행 |

batch / source: `honduras_update_20261016` · 메모 표식 `HN check 2026-10-15`

## 2. 반영
- **필러**: Calidra Honduras INCAL Potrerillos (석회·조립 탄산칼슘, 향후 PCC 기반 — 가드에 사이트명 포함해 멕시코 Calidra 와 분리) · Carbonatos de Honduras Choloma (325 mesh, 10 μm 미만). Brenntag·OregonChem 추가 안 함. 제지용 PCC 없음
- **밀**: 1 PAFISA San Pedro Sula (버진 티슈, Cariñoso) · 2 PACASA San Pedro Sula (재생 종이·판지, 1986~). 생산능력 미공개
  - 배경(있을 때만): Kimberly-Clark Honduras (Villanueva), Corrugados de Sula (Galindo — 그룹 제지공장은 파나마), Astro Cartón (Saica 원지 수입), CANASA, Cartones Sula, PAINSA de Honduras (창고), Alas Doradas (판매법인)
- **시장현황**: HN 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016n_honduras_mills_fillers.sql docs/handoff
git commit -m "data: Honduras fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 중미 남은 나라: 엘살바도르 (Alas Doradas — 니카라과·온두라스 보고서에서 반복 언급)
