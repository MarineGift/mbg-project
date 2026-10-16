# Handoff 2026-10-15 (z) — 가이아나 시장현황 행 (초지기 없음)

> 앞 문서: `handoff_20261015y_suriname_mills.md` · 2026-10-15 알파벳 소진 → 다음은 20261016a

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015z_guyana_market.sql` | 새 행 없음. 배경 5곳(있을 때만 메모·plant 메모), `app.country_markets` GY 행 |

batch / source: `guyana_update_20261015` · 메모 표식 `GY check 2026-10-15`

## 2. 반영
- **초지기 없음**: Caribbean Container Inc. 재생 라이너·골심지 공장 2003~2017 가동, 2021 영구 폐쇄 → 현재 수입 원지 상자 가공
- **배경(있을 때만)**: CCI, Nova High Technology (2023 티슈, 2025 Made in Guyana, 초지기 미확인), Cuddles Touch, NPN Enterprise, Fullworks Packaging
- Jacana Paper Company 는 트리니다드토바고 업체 — 가이아나에서 제외
- **필러 없음** (충전제 보고서 미제공)
- **시장현황**: GY 행 priority none, FCC 산정 불가
- 생성기: 새 밀이 하나도 없는 파일도 처리

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015z_guyana_market.sql docs/handoff
git commit -m "data: Guyana country market row (no paper machine)"
git push origin marinebiogroup
```

## 4. 실행 결과 대기: TH(o), CA(s), GT(t), BZ(u), NI(v), CR(w), JM(x), SR(y), GY(z)
