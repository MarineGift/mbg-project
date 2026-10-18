# Handoff 2026-10-16 (zzt) — 이집트 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzs_tunisia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzt_egypt_mills_fillers.sql` | 필러 6, 밀 7(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` EG 행 |

batch / source: `egypt_update_20261016` · 메모 표식 `EG check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러 (Minya GCC 클러스터)**: **ACCM** (ASCOM, El-Metahra, 제지 충전·코팅 명시, Hosokawa Alpine, 2020 40만 t 목표 — 후보 1, B) · ACMA (3~200 μm, 99.5%·백색도 99% 회사 발표, 제지 명시 — 후보 2) · Alfacarb (1955~, 99.6%) · Minya Carbonate (Abo Kastour) · HERBOCAL (0.7 μm~) · El Sayaad Stone (월 1만 t, 8~50 μm). Rihan Trade·Innova 추가 안 함. 제지용 PCC 없음
- **밀 / 우선순위**: 1 QPIC Qus (바가스 인쇄·복사 12만 t) · 2 Hayat Egypt Ain Sokhna (티슈 7만 t, 2017 발표 — TR Hayat 그룹) · 3 Al Zeina 10th of Ramadan (티슈 3.2만 t) · 4 Misr Edfu (바가스 UWF 6만 t, 가동·소유 확인) · 5 Fine Hygienic (1990 첫 공장) · 6 Uniboard Sadat City (듀플렉스) · 7 Bardi (컨테이너보드)
  - 10th of Ramadan 의 Al Zeina·Bardi → 소유사 정규식 분리
  - 배경: Rakta (청산 중, 2026-09-30 공시), National Paper, Interpac (MM 이집트, 초지기 3대 — 상세 수집)
- **시장현황**: EG 행 medium, FCC 8,460 ~ 14,100 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzt_egypt_mills_fillers.sql docs/handoff
git commit -m "data: Egypt fillers + mills + country market row"
git push origin marinebiogroup
```
