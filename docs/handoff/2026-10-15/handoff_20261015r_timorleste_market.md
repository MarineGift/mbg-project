# Handoff 2026-10-15 (r) — 동티모르 시장현황 행 채움

> 앞 문서: `handoff_20261015q_country_combobox_all.md`

- `sql/seed_20261015r_timorleste_market.sql` — `app.country_markets` TL 행 upsert (영문·한글 요약, sections: fillers / mills / strategy / risks / next_steps / key_numbers)
- priority 는 기존 값 유지 (없으면 none = 대상 없음). FCC 물량 null (초지기 없음)
- 제지사·충전제사 행은 여전히 만들지 않음 — 인쇄·가공(Planet Printing, Gráfica Nacional 등), 재활용(Caltech, Circul-R), TL Cement 제외
- 확인: /markets/TL, 제지사 목록 국가 콤보박스에서 Timor-Leste 선택 → 시장현황 버튼

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015r_timorleste_market.sql docs/handoff
git commit -m "data: Timor-Leste country market row (no mills, no paper fillers)"
git push origin marinebiogroup
```
