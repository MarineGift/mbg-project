# Handoff 2026-10-16 (s) — 카자흐스탄 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016r_mongolia_mills.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016s_kazakhstan_mills_fillers.sql` | 필러 5, 밀 7(없을 때) + 배경 9(있을 때만), plant 블록, `app.country_markets` KZ 행 |

batch / source: `kazakhstan_update_20261016` · 메모 표식 `KZ check 2026-10-16` · 제지기업 보고서 3개 버전 중 최신(교차확인본) 기준

## 2. 반영
- **필러**: Asia Micron Tekeli (대리석 1~500 μm, 후보 1) · TasUn MARMAR Tekeli (2~14 μm, 제지 명시) · Kazhimtehsnab Semey (GCC + 소석회, PCC 기반 후보) · Aktau Minerals (백악 신규, 10~12 t/h, 2026 가동 추진) · Global Chemicals Company (시추용). MicroCalcit·Mountain Mineral 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Karina Paper (Baotuo SF12-1100 2019, PAPIRONE 과 같은 주소 — PAPIRONE 은 배경으로만, 중복 집계 안 함) · 2 Alatau Kagazy (일 60 t → 19,800 t 계산값) · 3 Lucrum Star Aktobe (3,335 t) · 4 NUR KAGAZY Panfilovo (4만 t) · 5 KZ Recycling Abay (구 Kagazy Recycling, 6만 t, 같은 공장 1행) · 6 Inter Multi Service (5.04만 t 목표) · 7 Sever-Kombinat Kostanay (1.7만 t 계획)
  - 배경(있을 때만): PAPIRONE, BumProm, Goldman Astana, LisBum.KZ, Eco Pack Astana, Pavlodar Cardboard-Ruberoid, Gofrotara, Amcor, Karaganda PPC
- **시장현황**: KZ 행 medium, FCC 8,677 ~ 17,354 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016s_kazakhstan_mills_fillers.sql docs/handoff
git commit -m "data: Kazakhstan fillers + mills + country market row"
git push origin marinebiogroup
```
