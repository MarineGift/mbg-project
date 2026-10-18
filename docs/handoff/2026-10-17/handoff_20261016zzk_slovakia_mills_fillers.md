# Handoff 2026-10-16 (zzk) — 슬로바키아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzj_czechia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzk_slovakia_mills_fillers.sql` | 필러 4, 밀 4(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` SK 행 |

batch / source: `slovakia_update_20261016` · 메모 표식 `SK check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Specialty Minerals Slovakia** (2019~2020 PCC 증설 설계 발주처 — 실제 PCC 설비 운영, 위치·호스트 미확인, B satellite, 파트너 메모) · Omya Slovakia 브라티슬라바 (영업, C) · Carmeuse Slovakia Košice (Slavec 등, PCC 담당 부서 — PCC 석회 공급) · Calmit Slovakia (Tisovec·Žírany·Margecany, AT Bad Ischl 과 같은 그룹). EUROTALC 추가 안 함
- **밀 / 우선순위**: 1 Mondi SCP Ružomberok (5대, UWF 58만 + 컨테이너보드 31만 + 크라프트 6.7만 = 95.7만 t, 판매 펄프 10만 t 미합산) · 2 Metsä Tissue Žilina (2대, 약 8.1만 t) · 3 SHP Harmanec (재생 티슈, 2026-01 TL2 가공라인 — 원지 아님) · 4 SHP Slavošovce (냅킨, 버진 펄프)
  - SHP 두 공장 합 약 6만 t 은 Harmanec split 에만 기록
  - 배경: Essity Gemerská Hôrka (위생용품, 초지기 아님), BUKOCEL (2025 파산)
- **링크 없음**: SMI 슬로바키아 PCC 의 호스트가 Mondi SCP 로 확인되면 다음 보완 시 링크 추가
- **시장현황**: SK 행 high, FCC 10,980 ~ 54,900 t (보고서 1~5%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzk_slovakia_mills_fillers.sql docs/handoff
git commit -m "data: Slovakia fillers + mills + country market row"
git push origin marinebiogroup
```
