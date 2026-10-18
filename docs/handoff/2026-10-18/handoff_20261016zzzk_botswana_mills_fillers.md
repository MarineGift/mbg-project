# Handoff 2026-10-16 (zzzk) — 보츠와나 충전제·제지사 + 시장현황 행

> 앞 문서: `handoff_20261016zzzj_mozambique_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzzk_botswana_mills_fillers.sql` | 필러 2, 밀 1(없을 때, 우선순위 없음) + 배경 9(있을 때만), plant 블록, `app.country_markets` BW 행 (priority none) |

batch / source: `botswana_update_20261016` · 메모 표식 `BW check 2026-10-16`

## 2. 반영
- **필러 (C)**: PPC Botswana (Naka-la-Phala 석회석) · Matsiloje Portland Cement (2016 3.6만 t, KCL Technologies 석회석 메모). **ILCCMCo 는 요르단 Aqaba 기업** → 추가 안 함 (보고서 정정 반영). Idwala Carbonates (ZA) 보츠와나 선적 79건 메모. 제지용 PCC·GCC 없음
- **밀**: Pulp and Paper Industries (Strides for Success, Mogoditshane — 폐지 월 약 2천 t 수거 (생산량 아님), 2023-09 출범, 초지기 확인)
  - 배경 (가공): Genpack, Jewel Paper, Fu Qiang, Calm Tissue (점보롤 가공), Slae, Enviro Drive, Jubilation, Xuuxoo, Holly Fern
- **시장현황**: BW none — 남아공-보츠와나-짐바브웨 공급권역

## 3. 후속
- 요르단(JO) 보완 시: ILCCMCo (Rocks Group, Aqaba — GCC·PCC·석회) 필러 행 추가 검토

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzzk_botswana_mills_fillers.sql docs/handoff
git commit -m "data: Botswana fillers + mill + market row"
git push origin marinebiogroup
```
