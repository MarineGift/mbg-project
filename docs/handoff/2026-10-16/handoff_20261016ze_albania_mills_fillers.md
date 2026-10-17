# Handoff 2026-10-16 (ze) — 알바니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zd_greece_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016ze_albania_mills_fillers.sql` | 필러 1, 밀 3(없을 때) + 배경 6(있을 때만), plant 블록, `app.country_markets` AL 행 |

batch / source: `albania_update_20261016` · 메모 표식 `AL check 2026-10-16`

## 2. 반영
- **필러**: Berdica Cement Shkodër (산업용 탄산칼슘 15~100 μm, 자체 공장 미확인). 추가 안 함: REY PLASTICA (수입), ALBANERA, Colacem Albania, Shijaku. 인근 제지용 GCC 후보 (메모만): Calcit (슬로베니아·크로아티아 Gospić), Omya Italy, Aydın (튀르키예 — TR 행 있음)
- **밀**: 1 Edipack Porto Romano (재생 골심지·테스트라이너, 자체 원지 라인) · 2 GERIS Xhafzotaj (셀룰로오스 티슈, 월 600 t 은 제품 기준이라 capacity 미입력) · Elisabet Korçë (초지기 미확인 — 우선순위 없음)
  - 배경(있을 때만): So Cart, Eurokartoni, Alba Box, Unieuro, Kartonteks, Novopack
- **시장현황**: AL 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016ze_albania_mills_fillers.sql docs/handoff
git commit -m "data: Albania filler + mills + country market row"
git push origin marinebiogroup
```

## 4. 후속 후보
Calcit Group (SI/HR) — 유럽 제지용 GCC 약 20%, 매출 80% 제지. 슬로베니아·크로아티아 조사 시 필러로 추가
