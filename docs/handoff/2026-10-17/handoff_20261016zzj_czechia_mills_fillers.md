# Handoff 2026-10-16 (zzj) — 체코 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzi_poland_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzj_czechia_mills_fillers.sql` | 필러 6, 밀 7(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` CZ 행 |

batch / source: `czechia_update_20261016` · 메모 표식 `CZ check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (전부 C)**: Omya Czechia Lipová-lázně (영업·기술지원, 현지 생산 미확인, 라이선시) · LB Cemix Kotouč Štramberk (분쇄 석회석, 제지 공급 명시 — 현지 파트너 후보) · Lhoist Čertovy schody (체코 최대 석회) · Carmeuse Mokrá · Vápenka Vitošov (SigmaRoc) · Vápenka Vitoul (미분 석회석 40 μm). Hasit 추가 안 함. 체코 제지용 PCC 위성공장 미확인
- **밀 / 우선순위**: 1 Mondi Štětí White Paper (PS7 백색지 — 지종 확인) · 2 OP papírna Olšany (delfort, 3대, 박엽·담배지 — AT Traun·FI Tervakoski 와 그룹 시험) · 3 KRPA PAPER Hostinné (내유·배리어) · 4 Mondi Štětí 본 공장 (크라프트, 6대, PM10 21만 t 은 split 에만) · 5 Huhtamaki (몰드펄프) · 6 EMBA · 7 Morava Paper (Smurfit Westrock)
  - Štětí 의 Mondi 두 행: 크라프트 가드 `^(?!.*white).*mondi.*štětí` + 도시 fallback 없음 → White Paper 행과 분리
  - 배경: Lenzing Biocel Paskov (용해펄프), JIP Papírny Větřní (2025-09-30 PM4·PM6 종료)
- **시장현황**: CZ 행 medium, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzj_czechia_mills_fillers.sql docs/handoff
git commit -m "data: Czechia fillers + mills + country market row"
git push origin marinebiogroup
```
