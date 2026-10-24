# Handoff 2026-10-16 (zzzu) — 우간다 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzzt_rwanda_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzu_uganda_mills_fillers.sql` | 필러 3, 밀 5(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` UG 행 |

batch / source: `uganda_update_20261016` · 메모 표식 `UG check 2026-10-16`

## 2. 반영
- **필러**: **A-One Investments Njeru** (대리석·방해석 400~2,500 mesh, 백색도 97%+·Ca 93% 회사 발표, 제지 명시 — 후보 1, B) · **Gebal Minerals Jinja** (2015, GC2~GC10, Moroto 원료, African Minerals 인수 — 가드에 AML 포함, 후보 2, B) · Thompson Creek (굵은 분말, C). System Star·Brenntag·Tororo·Hima 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Global Paper Products Mukono (티슈 점보롤 버진 16~21·재생 17~24 gsm, 탈묵) · 2 Modern Laminates Jinja (다층 크라프트·판지, 더블와이어·QCS, KE·RW 수출) · 3 EAPS Njeru (2겹 크라프트·골판지 월 3,600 t (가공)·계란판)
  - 우선순위 없음: Uganda Pulp & Paper Mills (가동 확인), Paper Toils (초지기 확인)
  - 배경: Imperial Tissue (가공), Riley Packaging, Picfare
- **시장현황**: UG 행 low, FCC 산정 보류. Jinja-Njeru 에 GCC 업체와 제지사 인접 → 현지 OEM 시험 모델. 르완다 Mingyang 골심지 수입처

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzu_uganda_mills_fillers.sql docs/handoff
git commit -m "data: Uganda fillers + mills + country market row"
git push origin marinebiogroup
```
