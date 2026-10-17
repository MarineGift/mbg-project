# Handoff 2026-10-16 (zd) — 그리스 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zc_cyprus_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zd_greece_mills_fillers.sql` | 필러 6, 밀 5(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` GR 행 |

batch / source: `greece_update_20261016` · 메모 표식 `GR check 2026-10-16`

## 2. 반영
- **필러**: IOKAL Kefalonia·Mandra·Kavala (미분 45만 t, 제지 충전·코팅 명시 — 독립 라이선스·OEM 후보 1, B) · Omya Hellas Sindos (라이선시, B) · Industrial Minerals Greece Nea Karvali (제지 중심 수출, Imerys·Vougiouklis 설립 — 현재 지분 미확인, B) · Microfill Corinth (13만 t) · Dionyssomarble · Powder Ltd. Granule·KarboKal 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 Intertrade Hellas Oinofyta (14만 t+, 2026-02 Toscotec PM2) · 2 MAXI Katerini (7.5만 t) · 3 MEL Thessaloniki (재생 코팅판지 12만 t) · 4 ELITE Patras · 5 UNIPAKHELLAS Pelasgia (INDEVCO — Unipakcyprus 와 같은 그룹)
  - 배경(있을 때만): DS Smith Hellas, Dunapack Hellas
- **시장현황**: GR 행 medium, FCC 3,350 ~ 6,700 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zd_greece_mills_fillers.sql docs/handoff
git commit -m "data: Greece fillers + mills + country market row"
git push origin marinebiogroup
```
