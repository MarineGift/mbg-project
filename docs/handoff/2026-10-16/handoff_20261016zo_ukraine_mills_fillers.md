# Handoff 2026-10-16 (zo) — 우크라이나 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zn_moldova_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zo_ukraine_mills_fillers.sql` | 필러 3, 밀 7(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` UA 행 |

batch / source: `ukraine_update_20261016` · 메모 표식 `UA check 2026-10-16` · 모든 메모에 "War risk - 현장 상태·전력·물류 확인" 문구

## 2. 반영
- **필러**: NEOCARB (Renta-Prim) 드니프로 (제지용 GCC 9종 공식 판매, 99%+·백색도 98+ — 후보 1, B) · South Trade (위탁 분쇄) · Ekokarbo (수입·가공)
  - 추가 안 함: Reaktiv Sloviansk·Slavyansk Soda Plant (PCC 과거 이력, 현재 미확인), Vovchoiarivskyi (루한스크 — 점령지역 제재), Brenntag (유통)
- **밀 / 우선순위**: 1 Kyiv CPM Obukhiv (티슈+코팅판지, 2025 매출 80.6억 UAH) · 2 Kokhavynska (재생 티슈, 135 t/일 은 투입량) · 3 VGP Ruta Lutsk (원지 자체 생산 확인 필요) · 4 Zhytomyr Cardboard · 5 Poninka (2020 월 8천 t — 과거) · 6 Lutsk Carton and Paper · Weidmann Malyn (전기절연지 — 우선순위 없음)
  - 배경(있을 때만): Carton and Paper Company (Lviv), Trypil Packaging, Slovianski Shpalery
- **시장현황**: UA 행 medium, FCC 산정 보류 (공장별 생산량 미공개)
- 미결 3번(제재국 캠페인 제외)은 국가 단위라 UA 는 해당 없음 — 점령지역 업체만 개별 제외

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zo_ukraine_mills_fillers.sql docs/handoff
git commit -m "data: Ukraine fillers + mills + country market row"
git push origin marinebiogroup
```
