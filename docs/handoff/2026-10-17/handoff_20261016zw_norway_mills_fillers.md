# Handoff 2026-10-16 (zw) — 노르웨이 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zv_finland_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zw_norway_mills_fillers.sql` | 필러 2, 밀 6(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` NO 행 |

batch / source: `norway_update_20261016` · 메모 표식 `NO check 2026-10-16`

## 2. 반영
- **필러**: **Omya Hustadmarmor** Elnesvågen (유럽 제지용 GCC 슬러리 허브, 2007 연 300만 t+, 탱커 공급, 2025 매출 약 13억 NOK — 라이선시, B) · Brønnøy Kalk Velfjord (Norsk Mineral, 대리석 원광 연 200만 t — Omya 생산량과 합산 금지). 노르웨이 제지용 PCC 없음
- **밀 / 우선순위**: 1 **Norske Skog Saugbrugs** Halden (SC — 2026-10-07 PM6 재건 결정, 라이너 30만 또는 SC 23만 t, 계획분은 split 에만 · 설계 단계 제안 시점) · 2 Hellefoss (고벌크 서적용지 5만 t — 벌크 손실 주의) · 3 Norske Skog Skogn (PM1 NOR Book 14만 t, 2026-04 전환) · 4 Vajda-Papir Drammen (티슈, 그룹 14.5만 t 은 헝가리 포함) · 5 Ranheim · 6 Nordic Paper Greåker (내유지 4.4만 t)
  - 배경(있을 때만): FollaCell, Vafos, Rygene-Smith, Borregaard (펄프 전용)
- **시장현황**: NO 행 medium, FCC 23,200 ~ 46,400 t (보고서 시나리오, PM6 미가동 포함)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zw_norway_mills_fillers.sql docs/handoff
git commit -m "data: Norway fillers + mills + country market row"
git push origin marinebiogroup
```
