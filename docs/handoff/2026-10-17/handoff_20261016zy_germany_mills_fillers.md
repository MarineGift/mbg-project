# Handoff 2026-10-16 (zy) — 독일 제지사·충전제·PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zx_hungary_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zy_germany_mills_fillers.sql` | 필러 6, 밀 10(없을 때) + 배경 16(있을 때만), plant 블록, 링크 2, `app.country_markets` DE 행 |

batch / source: `germany_update_20261016` · 메모 표식 `DE check 2026-10-16`

## 2. 반영
- **필러**: **SCHAEFER KALK** Hahnstätten (본사 Diez, 현장 PCC Neidenfels·Kehl, PRECARB 100~800, 그룹 PCC 약 44.2만 t, 담당자 공개 — 후보 1, B satellite. 가드 독일 한정 → FI Kuusankoski 행과 분리) · **ALPHA CALCIT** 쾰른 (CALCICELL 제지용 GCC — B) · Omya Germany (라이선시, B) · SMI Germany (Schongau 위성 5만~7만·Walsum 상업 12.5만~14만 t, 2005 — C, 파트너 메모) · sh minerals · Lhoist/Rheinkalk (석회). Calcit (슬로베니아, UPM 독일 공장 공급 2017) 는 SI 조사 때 추가
- **밀 / 우선순위**: 1 Koehler Oberkirch · 2 UPM Nordland Dörpen (PM3 2024 말 종료) · 3 Felix Schoeller Osnabrück (12만 t) · 4 LEIPA Schwedt · 5 Sappi Alfeld · 6 Essity Mannheim (짚 섬유, 2026-02 EU PROTEUS 해조류 흡수재 — 해양섬유 FCC 접점) · 7 WEPA Müschede · 8 Progroup
  - 우선순위 없음: Koehler Kehl, UPM Schongau (링크용)
  - 배경 16곳: UPM Hürth (2024-08 종료)·Ettringen (2025 말 종료)·Augsburg/Plattling, Felix Schoeller 기타 (Penig 2025-06 폐쇄), Koehler 기타, Sappi Ehingen, Essity·WEPA 기타, Palm, Hamburger, Schoellershammer, Drewsen, Hahnemühle, Mitsubishi HiTec, Feldmuehle, Norske Skog Bruckmühl
  - Koehler Oberkirch 가드가 Kehl 에 같이 걸려 수정 (교차검사)
- **링크**: SCHAEFER KALK → Koehler Kehl (active·medium, 호스트 확인) · SMI → UPM Schongau (historical)
- **시장현황**: DE 행 high (2025 1,870만 t, 공장 128), FCC 15,000 ~ 30,000 t (보고서 시나리오)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zy_germany_mills_fillers.sql docs/handoff
git commit -m "data: Germany fillers + mills + PCC links + country market row"
git push origin marinebiogroup
```

## 4. 파일 접미사
다음은 zz, 그 다음부터 zza, zzb ... (이름순 정렬 유지)
