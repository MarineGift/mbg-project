# Handoff 2026-10-16 (y) — 아제르바이잔 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016x_turkmenistan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016y_azerbaijan_mills_fillers.sql` | 필러 3, 밀 2(없을 때) + 배경 3(있을 때만), plant 블록, `app.country_markets` AZ 행 |

batch / source: `azerbaijan_update_20261016` · 메모 표식 `AZ check 2026-10-16`

## 2. 반영
- **필러**: Azeka BM Sumgait (GCC 3.6만 t 계획, 가동 미확인 — 후보 1) · Caltech Agdam (미분화·코팅 방해석 — 코팅품은 플라스틱용) · Fortis Group Khirdalan (calcite powder, 탄산염 97.5%, 제지 명시). 제지용 PCC 없음
- **밀**: 1 Azersun Paper and Cardboard Plant Sumgayit (2014, 폐지 투입 5만 t — 생산능력 아님, capacity 미입력) · 2 Azersun Tissue Paper Factory Sumgayit (Sun·Aura·Papi, 구 Caucasus Paper Industry, 자체 초지기 확인 필요)
  - 같은 단지라 가드를 이름·소유사 정규식으로 분리
  - 배경(있을 때만): Baku Cardboard and Box (2026-01, 5,500만 m²), Fabriora (2026-09, 위생제품), Azersun Khirdalan Cardboard
- **시장현황**: AZ 행 low, FCC 500 ~ 1,500 t (가정치)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016y_azerbaijan_mills_fillers.sql docs/handoff
git commit -m "data: Azerbaijan fillers + mills + country market row"
git push origin marinebiogroup
```
