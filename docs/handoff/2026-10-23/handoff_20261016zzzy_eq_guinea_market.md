# Handoff 2026-10-16 (zzzy) — 적도기니 제지사 + 시장현황 행

> 앞 문서: `handoff_20261016zzzx_gabon_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzy_eq_guinea_market.sql` | 밀 1(없을 때, 우선순위 없음) + 배경 5(있을 때만), plant 블록, `app.country_markets` GQ 행 (priority none) |

batch / source: `eq_guinea_update_20261016` · 메모 표식 `GQ check 2026-10-16` · 국가코드 `GQ`

## 2. 반영
- 제지용 PCC·GCC 없음 (USGS — 비연료 광업 미미) → 필러 없음
- **밀**: Evita Office Line (Grupo Evita, Bata Ntobo — 2021-03-11 BDEAC 17억 FCFA, A4 80 gsm 재단·포장 시간당 5박스, 공책·봉투, 2022 CEMAC 원산지 인정 — 재단 라인으로 보임, 원지 출처 확인)
  - 배경: WAC Services, Ocean Print, Imprenta Carioca, Imprenta Papelería Litoral, Tecnobioko
- **시장현황**: GQ none. HS 48 주로 중국·스페인·튀르키예·인도 (2024). Grupo Evita 의 CEMAC 유통망을 접촉 경로로 메모

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzy_eq_guinea_market.sql docs/handoff
git commit -m "data: Equatorial Guinea mill + market row"
git push origin marinebiogroup
```
