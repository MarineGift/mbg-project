# Handoff 2026-10-15 (u) — 벨리즈 제지사 + 시장현황 행

> 앞 문서: `handoff_20261015t_guatemala_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015u_belize_mills.sql` | 밀 1(없을 때) + 배경 1(있을 때만), plant 블록, `app.country_markets` BZ 행. 필러·링크 없음 |

batch / source: `belize_update_20261015` · 메모 표식 `BZ check 2026-10-15`

## 2. 반영
- **필러 없음**: 제지용 PCC·GCC 공장 없음. Limbe(농업용 석회 2 mm), St. Margaret Village 석회 가마 5곳(연 약 283 t) 추가 안 함. 탄산칼슘 수입 2024 2,499 t (과테말라 85.6%)
- **밀**: 1 Caribbean Paper Mill Company (Orange Walk, 티슈 — 2014년부터 원지 제조, 2026 카리브해 선적 확인). Caribbean Paper Company 와 같은 공장으로 1행. 생산능력 미공개 (과거 폐지 처리 5.5 t/일은 투입량이라 capacity 로 넣지 않음)
  - 배경(있을 때만): Roses Paper Products (가공업체)
  - GraceKennedy Belize·Paper Box Belize 등 유통·가공업체 추가 안 함
- **시장현황**: BZ 행 low, FCC 산정 보류
- 생성기: 필러가 없는 나라도 처리 (필러 섹션 생략)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015u_belize_mills.sql docs/handoff
git commit -m "data: Belize tissue mill + country market row"
git push origin marinebiogroup
```

## 4. 완료 국가 41 (+BZ). 결과 대기: TH(o), CA(s), GT(t), BZ(u)
