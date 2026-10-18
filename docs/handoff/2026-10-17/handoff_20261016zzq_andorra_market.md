# Handoff 2026-10-16 (zzq) — 안도라 시장현황 행 (초지기·충전제 없음)

> 앞 문서: `handoff_20261016zzp_denmark_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzq_andorra_market.sql` | `app.country_markets` AD 행 (priority none) + 검증 select + 이름 충돌 점검 select — 행 생성 없음 |

batch / source: `andorra_update_20261016` · 메모 표식 `AD check 2026-10-16`

## 2. 반영
- 초지기·제지용 PCC·GCC 공장 없음. 인쇄·그래픽 약 21곳, 문구 유통, 포장 디자인만
- 종이제품 수입: HS 482390 2024 약 103만 달러·240 t (스페인·중국·오스트리아·독일·프랑스)
- **이름 충돌**: DS Smith "Andorra" 는 스페인 Teruel 주 Andorra 시 골판지 공장 → ES 행이어야 함. 마지막 select 가 `country_code = 'AD'` 이거나 이름·도시에 "andorra" 가 들어간 모든 행을 보여줌 → AD 로 잘못 들어간 행이 있으면 ES 로 수정
- 시장현황: AD none, ES·FR 행으로 커버

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzq_andorra_market.sql docs/handoff
git commit -m "data: Andorra market row (no paper machine)"
git push origin marinebiogroup
```
