\xef\xbb\xbf# Handoff 2026-10-15 (h) — 시리아 제지공장·필러 + 시장현황 행

> 앞 문서: `handoff_20261015g_country_markets.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015h_syria_mills_fillers.sql` | 필러 4사, 밀 7곳(없을 때), 소개·메모, plant 블록 8, **`app.country_markets` SY 행** |

batch / source: `syria_update_20261015` · 메모 표식 `SY check 2026-10-15`

## 2. 제재
- 미국 시리아 제재 프로그램 종료(2025-06-30 행정명령), Caesar Act 폐지(2025-12-18)
- 단, 아사드 정권 관련(PAARSS)·테러 관련 SDN 지정은 유지 → 모든 approach 에 `OFAC SDN 스크리닝 선행` 기록. 이란처럼 전면 보류는 아님

## 3. 반영
- 필러: Al-Siraj (Adra, 독일 IVA 라인, 제지 공급 명시 — PCC 설비 미확인), SCI (Adra, 처리·비처리 미분화), Phoenician Stone, Al-Thiqa Bil-Amal. Adra 명부 등록 업체들 제외. 시리아 제지용 PCC 공장 없음
- 밀: 1 Mediterranean Paper Mills (Jableh 티슈 40 t/일) · 2 Dinatex (PM3 2.8만 t) · 3 Lanatex (PM2 1.7만 t) · 4 Oriental Paper (PM1 9천 t) — 2~4 는 과거 명목치, 동일 그룹 가능성 · 5 ARAPEPCO (알레포 재생 포장) · 6 Asian Paper Industries (3.9만 t) · 7 United Paper Industry (자유무역지대) — 참고: Saffoury
- Deir ez-Zor 국영 공장 (피해·복구 검토) 추가 안 함
- **시장현황**: SY 행 upsert (priority low) — 이제부터 국가 보고서마다 시장현황 행을 같은 파일에 포함

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015h_syria_mills_fillers.sql docs/handoff
git commit -m "data: Syria fillers + mills + country market row"
git push origin marinebiogroup
```
