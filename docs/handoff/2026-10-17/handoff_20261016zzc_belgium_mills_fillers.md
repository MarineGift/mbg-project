# Handoff 2026-10-16 (zzc) — 벨기에 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzb_netherlands_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzc_belgium_mills_fillers.sql` | 필러 5, 밀 6(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` BE 행 |

batch / source: `belgium_update_20261016` · 메모 표식 `BE check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (전부 C, 가드 벨기에 한정)**: SMI Hermalle-sous-Huy (상업 PCC, 2001 Huber 인수 — 과거, 파트너 메모) · Imerys Lixhe (Carrara 대리석 제지용 GCC — 과거, 2024 Flacks 매각 후 소유주 확인) · Carmeuse Belgium (Seilles·Aisemont·Moha 석회) · Sibelco (벨기에 본사, NL Maastricht 행과 분리) · Calcaires de la Sambre
- **밀 / 우선순위**: 1 Essity Stembert (2대, 약 7.5만 t) · 2 Sofidel Duffel (TAD) · 3 Burgo Ardennes Virton (2025 매출 3.79억 유로 — 지종 확인, IT Burgo 연계) · 4 Stora Enso Langerbrugge (재생 신문·SC — SC 유지 여부 확인) · 5 VPK Oudegem (50만 t) · 6 Ahlstrom Malmedy (벽지용 부직포)
  - 배경: Sappi Lanaken (코팅 53만 t, 2023-12 종이 생산 종료·2024 자산 매각), Cartonnages de Gondardennes
- **시장현황**: BE 행 medium, FCC 2,250 ~ 28,750 t (하한 Essity 3%, 상한 보고서 시나리오)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzc_belgium_mills_fillers.sql docs/handoff
git commit -m "data: Belgium fillers + mills + country market row"
git push origin marinebiogroup
```
