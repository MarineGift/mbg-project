# Handoff 2026-10-16 (zzu) — 나이지리아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzt_egypt_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzu_nigeria_mills_fillers.sql` | 필러 6, 밀 2(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` NG 행 |

batch / source: `nigeria_update_20261016` · 메모 표식 `NG check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **IzeCarb Lampese** (2024-12-06 가동, 2025 생산 7.2만 t, 2026 1분기 50만·2027 100만 t 목표 — 후보 1, B) · Lafarge Africa GCC (2025 출시, CaCO3 92%+ — 시멘트 1,050만 t 은 GCC 아님) · Freedom Group (CALCO·ULTRACAL·KAOLAY 카올린, 제지 명시 — 비코팅 등급 사용) · Bees Industries · NovaCore · NARICT PCC 파일럿 Zaria (3.57 t/일, 제약용 — R&D 연계). AMRL 추가 안 함
- **밀**: 1 Speciality Pulp and Paper (포장 275 t/일 ≈ 9.1만 t + P&W 175 t/일 계획 ≈ 5.8만 t — split) · 2 NIXIN (P&W 월 최대 8천 t — split, 회사 주장)
  - 배경: Iwopin, Nigerian Paper Mill Jebba, Nigerian Newsprint Oku-Iboku (중단된 국영 공장)
- **시장현황**: NG 행 low, FCC 2,880 ~ 7,700 t. 서아프리카 수출 거점 가능성 메모

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzu_nigeria_mills_fillers.sql docs/handoff
git commit -m "data: Nigeria fillers + mills + country market row"
git push origin marinebiogroup
```
