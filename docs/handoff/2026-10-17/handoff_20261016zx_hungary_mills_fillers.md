# Handoff 2026-10-16 (zx) — 헝가리 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zw_norway_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zx_hungary_mills_fillers.sql` | 필러 2, 밀 2(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` HU 행 |

batch / source: `hungary_update_20261016` · 메모 표식 `HU check 2026-10-16`

## 2. 반영
- **필러**: Omya Hungária Eger (2025 매출 132억 HUF·62명 — Szolnok 위성 PCC 1999 약 4만 t 이력, 현재 상태 확인, B satellite) · Carbonát Kft. Döbrönte (98~99% 석회석 분말). MTI·Imerys·Carmeuse 추가 안 함
- **밀 / 우선순위**: 1 Vajda-Papír Dunaföldvár (티슈 원지 11.5만 t = 3.5만 + 8만, 2026 가공 3만 t 증설은 미합산, 노르웨이 Drammen 계열) · 2 Hamburger Hungária Dunaújváros (재생 라이너 70만 t = PM3 21만 + PM7 49만, 터키 Hamburger 와 같은 Prinzhorn)
  - 배경(있을 때만): Sofidel Hungary (Lábatlan 가공), Magyar Piszke, Duna Papír, Dunafin, Szolnok 공장 (구 Neusiedler/Mondi)
  - Szolnok 공장 링크는 현재 가동 확인 전이라 미생성
- **시장현황**: HU 행 medium, FCC 3,450 ~ 5,750 t (Vajda 기준)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zx_hungary_mills_fillers.sql docs/handoff
git commit -m "data: Hungary fillers + mills + country market row"
git push origin marinebiogroup
```
