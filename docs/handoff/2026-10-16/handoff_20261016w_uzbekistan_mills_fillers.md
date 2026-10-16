# Handoff 2026-10-16 (w) — 우즈베키스탄 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016v_tajikistan_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016w_uzbekistan_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 8(있을 때만), plant 블록, `app.country_markets` UZ 행 |

batch / source: `uzbekistan_update_20261016` · 메모 표식 `UZ check 2026-10-16`

## 2. 반영
- **필러**: CEMIX FE Sazagon (LASSELSBERGER, GCC 1001 D50 1.0 μm·Ry 92.5, Sedigraph 품질관리 — 후보 1, B 등급) · DAVR-STROY (2~10 μm, 제지 명시) · KITOB MARMAR ZAVOD Shahrisabz · NAYMAN MEL Andijan
  - 추가 안 함: MIKRO GRAND, Nurmix, MASTER (생산 미확인), Global Optimals (PCC 재판매), Calpet (PCC 사용). 제지용 PCC 없음
- **밀 / 우선순위**: 1 Tashkent Paper Factory (중앙은행 산하, 필기용지 — 보안용지는 시험 대상 아님) · 2 Angren Karton / Angren Pack (10만 t, 화이트탑 라이너 우선) · 3 Perfect Paper Group Chinaz · Uzbek China Paper (볏짚, 가동 미확인 — 우선순위 없음)
  - 배경(있을 때만): Huanrong Paper (Urgut 5억 달러 프로젝트, 미완공), Global KOMSCO Daewoo, Daewoo Pack, Pulp and Paper LLC, Premium Alliance, Ravshan Yodik, Profpack, Ahangaran Hygienic Pro
- **시장현황**: UZ 행 medium, FCC 3,000 ~ 5,000 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016w_uzbekistan_mills_fillers.sql docs/handoff
git commit -m "data: Uzbekistan fillers + mills + country market row"
git push origin marinebiogroup
```
