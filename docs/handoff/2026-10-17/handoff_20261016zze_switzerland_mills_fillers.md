# Handoff 2026-10-16 (zze) — 스위스 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzd_luxembourg_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zze_switzerland_mills_fillers.sql` | 필러 2, 밀 7(없을 때), plant 블록, `app.country_markets` CH 행 |

batch / source: `switzerland_update_20261016` · 메모 표식 `CH check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Omya (Schweiz) AG Oftringen 본사** (1884, 약 9,000명·50개국, R&D Oftringen·Egerkingen, 2023 중국·인니 7개 공장 100만 t 계획 — 라이선시 B. 가드는 스위스 이름 또는 접미어 없는 "Omya / Omya AG / Omya Group" 행만) · Kalkfabrik Netstal (생석회 9만 t, PCC 원료). PERFECO (시험 연구소) 추가 안 함
  - Omya 본사 접촉 시 NDA·Background IP 조항 정리 후 공정 상세 공개 (Multifill·FiberLean 경쟁) 메모
- **밀 / 우선순위**: 1 Perlen Papier (신문·LWC 2대, 특수지·성형섬유, 2026-03 Pulpex 종이병 파트너십) · 2 Swiss Quality Paper Balsthal (2.5만 t, 자체 R&D — 파일럿 파트너) · 3 Tela / Cartaseta (티슈 약 1.9만 t — 생산량 기준) · 4 Model Weinfelden (19만 t) · 5 Model Niedergösgen (24만 t)
  - 우선순위 없음: Papierfabrik Netstal (필터지), Landqart (보안용지 1만 t+)
- **시장현황**: CH 행 medium, FCC 2,207 ~ 23,707 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zze_switzerland_mills_fillers.sql docs/handoff
git commit -m "data: Switzerland fillers + mills + country market row"
git push origin marinebiogroup
```
