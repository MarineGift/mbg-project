\xef\xbb\xbf# Handoff 2026-10-15 (a) — 동티모르: URM 반영 없음 (기록 전용)

> 앞 문서: `handoff_20261014ai_png_mills_fillers.md`

## 1. 결정
동티모르 보고서(2026-10)는 **SQL 없이 기록만** 남긴다.

| 항목 | 조사 결과 | URM 처리 |
|---|---|---|
| 제지용 PCC·GCC 제조사 | 없음 | 행 추가 안 함 |
| TL Cement (Baucau, Bucoli 석회석) | 시멘트 프로젝트, 2026년에도 발표 단계 | 추가 안 함 — 제지 충전제와 무관 |
| 제지공장 (원지 생산) | 없음 | 행 추가 안 함 |
| 인쇄·가공업체 (Planet Printing, Gráfica Nacional, MAX ADS, QUES KEV, INTL) | 원지 구매자 | 추가 안 함 — FCC 사용자 아님 |
| 재활용 (Caltech, Circul-R) | 폐지 수거, 제지 안 함 | 추가 안 함 |

## 2. 판단
- 2024 HS 48 수입 약 $15.7M, 인도네시아·중국 약 95% — FCC 기회는 동티모르로 종이를 수출하는 **인도네시아 제지공장** 쪽 (이미 URM 에 인도네시아 밀 등록됨)
- 우선순위: 낮음 — 대형 제지공장 또는 충전제 공장 신설 발표 시 재검토

## 3. 커밋 (이 문서만)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git add docs/handoff
git commit -m "docs: Timor-Leste research - no URM rows (no mills, no paper fillers)"
git push origin marinebiogroup
```
