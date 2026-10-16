# Handoff 2026-10-15 (w) — 코스타리카 충전제 + 시장현황 행 (제지사 보고서 대기)

> 앞 문서: `handoff_20261015v_nicaragua_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015w_costarica_fillers.sql` | 필러 4 (없을 때), `app.country_markets` CR 행. 제지사 없음 — 검증 결과에 기존 CR 밀 목록 표시 |

batch / source: `costarica_update_20261015` · 메모 표식 `CR check 2026-10-15`

## 2. 반영
- **필러**: Grupo Sur Química El Níspero (GCC 325, CaCO3 약 97.87%, 공동생산 후보 1) · PRODECAL Cartago (후보 2) · CCC / Cales CR (제지 명시) · Carbotico Abangares (원료)
  - 추가 안 함: Sun Products Internacional (자체 공장 미확인), Pochteca·Brenntag (유통). PCC 공장·Omya·SMI 거점 없음
- **시장현황**: CR 행 low (임시), FCC 산정 보류 — 제지사 시드에서 갱신
- 생성기: 제지사가 없는 파일도 처리

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015w_costarica_fillers.sql docs/handoff
git commit -m "data: Costa Rica fillers + country market row"
git push origin marinebiogroup
```

## 4. 다음: 코스타리카 제지기업 보고서 → seed_20261016a (2026-10-15 는 w 까지 사용)
