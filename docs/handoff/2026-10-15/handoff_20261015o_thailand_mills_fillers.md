# Handoff 2026-10-15 (o) — 태국 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261015n_mx_followup.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015o_thailand_mills_fillers.sql` | 필러 5, 밀 7(없을 때) + 배경 3(있을 때만), plant 블록, 공급 링크 2, `app.country_markets` TH 행 |

batch / source: `thailand_update_20261015` · 메모 표식 `TH check 2026-10-15`
생성기: 멕시코와 같은 가드(이름 정규식 또는 도시 + 소유사 정규식). 검증 결과에 `other mill` 로 기존 TH 밀(매칭 안 된 행) 목록도 나옴.

## 2. 반영
- **필러**: Specialty Minerals (Thailand) (Double A Tha Toom 위성 PCC 2기 7만+8만 t, Phoenix Nam Phong 5만~7만 t — 2007~2013 발표치, 라이선시) · Surint Omya (라이선시) · F.M.T. (Fimatec 계열 WGCC, Sing Buri) · QMIN (Lopburi 건식 GCC 18만 t) · MCS Mining
  - 제외: Thai Poly Chemicals, Dusit Chemicals (공장 미확인) — MCS 메모에 기록
  - F.M.T. 가드는 `thai` 포함 이름만 — 일본·인니 Fimatec 행과 섞이지 않게
- **밀 / 우선순위**: 1 Double A (74.5만 t, 제지 4기) · 2 BJC Cellox (7.5만 t, ANDRITZ 2021) · 3 RiverPRO (100 t/일) · 4 Kimberly-Clark Thailand (Arbex 편입 여부 확인) · 5 Thai Paper (SCGP, 종이 57.2만 t) · 6 United Paper (26.4만 t) · Phoenix (펄프, 우선순위 없음)
  - 배경(있을 때만): Siam Kraft, Thai Cane Paper, Thai Paper Mill
- **FCC Base**: Double A 5% 37,250 t · BJC 3% 2,250 t · RiverPRO 3% 990 t · United Paper 5% 13,200 t
- **공급 링크**: SMI → Double A (active / medium), SMI → Phoenix (historical / medium)
- **시장현황**: TH 행 high, FCC 40,490~53,690 t
- 웹사이트는 doubleapaper.com 만 입력

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015o_thailand_mills_fillers.sql docs/handoff
git commit -m "data: Thailand fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 완료 국가 38 (+TH)
