# Handoff 2026-10-16 (za) — 조지아(공화국) 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016z_armenia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016za_georgia_mills_fillers.sql` | 필러 2, 밀 3(없을 때) + 배경 8(있을 때만), plant 블록, `app.country_markets` GE 행 |

batch / source: `georgia_update_20261016` · 메모 표식 `GE check 2026-10-16`

## 2. 반영
- **필러**: Geo-Filler (Rustavi 3만 t·Kutaisi 6.5만 t, 5~170 μm — 후보 1) · GMM (방해석·석회석 원료, 위탁가공). 제지용 PCC 없음
- **밀**: 1 Green Paper Natakhtari (재생 테스트라이너·골심지, 명목 2.5만 t, 화이트탑 개발) · 2 Neoprint Tserovani (명목 7,200 t, 실제 3,000 t 이하 2023 — Green Paper 와 전화번호 공유) · Georgian Paper Mill Tbilisi (2023 원지 중단 — 우선순위 없음)
  - 배경(있을 때만): Georgian Cardboard, Georgian Paper Production, Simetra, Kriala, Fabrica 1900, Royal Paper, Greenpack, GeoPaper
- **시장현황**: GE 행 low, FCC 322 ~ 966 t
- 미국 조지아주 아님 (국가코드 GE)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016za_georgia_mills_fillers.sql docs/handoff
git commit -m "data: Georgia fillers + mills + country market row"
git push origin marinebiogroup
```
