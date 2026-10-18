# Handoff 2026-10-16 (zzn) — 에스토니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzm_latvia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzn_estonia_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` EE 행 |

batch / source: `estonia_update_20261016` · 메모 표식 `EE check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: Nordkalk Estonia Rakke (2025-02 허가 필러 15만·석회 10만 t 상한 — 제지용 아님, Vasalemma CaCO3 95.6~97.4%, C). 가드 에스토니아 한정 → FI·SE·PL Nordkalk 행과 분리. Heidelberg Materials Kunda 추가 안 함. 제지용 PCC·GCC 없음
- **밀**: 1 Räpina Paberivabrik (회수지 100% 판지 180~540 gsm, 2025 매출 1,662만 유로 — 파일럿 후보) · 2 Horizon Kehra (미표백 색크라프트, Tolaram, 2025 매출 3,497만 유로)
  - 배경: Estonian Cell Kunda (BCTMP 공칭 17만·2025 12.77만 t, Heinzel — AT 연결), DS Smith Estonia, Stora Enso Packaging, Nefab, Kohila (과거)
- **시장현황**: EE 행 low, FCC 산정 보류

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzn_estonia_mills_fillers.sql docs/handoff
git commit -m "data: Estonia filler + mills + country market row"
git push origin marinebiogroup
```
