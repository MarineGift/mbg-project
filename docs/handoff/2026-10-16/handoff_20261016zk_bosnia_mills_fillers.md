# Handoff 2026-10-16 (zk) — 보스니아 헤르체고비나 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zj_montenegro_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zk_bosnia_mills_fillers.sql` | 필러 2, 밀 3(없을 때), plant 블록, `app.country_markets` BA 행 |

batch / source: `bosnia_update_20261016` · 메모 표식 `BA check 2026-10-16`

## 2. 반영
- **필러 (원료)**: Carmeuse Doboj (석회석 광산 + 석회 공장, 향후 PCC 기반) · TERAKOP Živinice (CaCO3 96%+ 석회석). 추가 안 함: Lukavac Cement, Šahin Kamen. 제지용 PCC·GCC 없음. 인근 공급원 메모: Omya Venčac (세르비아), STARAC (크로아티아)
- **밀**: 1 SHP Celex Banja Luka (티슈 약 4만 t, 신규 일 195 t 초지기 2026-06 허가·10월 1,500만 유로 발표 — 계획분은 split 2번째 줄) · 2 Natron-Hayat Maglaj (일관 펄프·제지, PM1 2025 현대화 5만 t — 전체 종이능력 미공개라 split 에만, 펄프 10만 t 메모) · Violeta Grude (초지기 미확인 — 우선순위 없음)
- **시장현황**: BA 행 medium, FCC 1,200 ~ 2,000 t (SHP Celex 기존 4만 t 기준)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zk_bosnia_mills_fillers.sql docs/handoff
git commit -m "data: Bosnia and Herzegovina fillers + mills + country market row"
git push origin marinebiogroup
```
