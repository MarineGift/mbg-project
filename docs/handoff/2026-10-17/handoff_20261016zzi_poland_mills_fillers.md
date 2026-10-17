# Handoff 2026-10-16 (zzi) — 폴란드 제지사·충전제·위성 PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zzh_croatia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzi_poland_mills_fillers.sql` | 필러 4, 밀 9(없을 때) + 배경 3(있을 때만), plant 블록, 링크 1, `app.country_markets` PL 행 |

batch / source: `poland_update_20261016` · 메모 표식 `PL check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: SMI Poland Kwidzyn (위성 PCC 1990년대 중반~, 과거 약 5만 t, SEC 공시 — B satellite, 파트너 메모) · Omya Poland 바르샤바 (영업, 공장 미확인 — C) · Nordkalk Poland (Wolica·Ostrówka·Sławno 석회석 — 제지용 GCC 는 핀란드) · Lhoist Bukowa. Qemetica (구 CIECH, 2005 PCC 2만 t — 현재 제품군에 없음), WKG·EGM·Labtar·Czatkowice 추가 안 함
- **밀 / 우선순위**: 1 MM Kwidzyn (구 IP, 66만 t, NBSK 8만 t 미합산 — IP Kwidzyn 별도 행 금지) · 2 Arctic Paper Kostrzyn (UWF 28.5만 t, SE 공장과 그룹 시험) · 3 Velvet CARE Klucze (TM9 후 21만 t+, Sulęcin 건설 중) · 4 ICT Poland Kostrzyn (21만 t) · 5 Sofidel Ciechanów (9만 t, NTT) · 6 Metsä Tissue Krapkowice (5.9만 t) · 7 WEPA Piechowice · 8 Mondi Świecie
  - 우선순위 없음: Stora Enso Ostrołęka
  - 배경: Głuchołazy, Schumacher Myszków, DS Smith Poland
  - Kostrzyn 에 Arctic Paper·ICT → 소유사 정규식 분리
- **링크**: SMI Poland → MM Kwidzyn (active·medium, MM 인수 후 상태 확인)
- **시장현황**: PL 행 high, FCC 23,625 ~ 40,695 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzi_poland_mills_fillers.sql docs/handoff
git commit -m "data: Poland fillers + mills + SMI Kwidzyn link + country market row"
git push origin marinebiogroup
```
