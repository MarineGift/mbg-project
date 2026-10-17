# Handoff 2026-10-16 (zm) — 루마니아 충전제 + 임시 시장현황 행

> 앞 문서: `handoff_20261016zl_serbia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zm_romania_fillers.sql` | 필러 3 (없을 때), `app.country_markets` RO 행 (임시 medium) — 검증 결과에 기존 RO 밀 목록 표시 |

batch / source: `romania_fillers_20261016` · 메모 표식 `RO check 2026-10-16`

## 2. 반영
- **필러**: Omya Calcita Voislova (대리석 GCC, 2025 매출 1.57억 RON·71명, 라이선시, B) · Carmeuse Romania Brașov (Câmpulung·Deva·Fieni·Pojoga 석회 — PCC 원료 파트너) · Tempo Invest Murfatlar (독립 탄산칼슘, OEM 후보). 루마니아 제지용 PCC 공장 미확인
- **제지사**: 붙여넣은 제지기업 편이 세르비아 보고서(두 번째 버전)라 루마니아 밀은 없음 → **루마니아 제지기업 보고서 재요청**
- 세르비아 2번째 버전의 추가 정보(Smurfit Beograd SEC 13.2만 t, Drenik 완제품 70%·점보롤 30%, Mondi Šabac·DS Smith Kruševac·Kartonval·Piramida 72 가공업체)는 zl 시드에 이미 핵심 반영 — 별도 시드 없음
- **시장현황**: RO 행 medium (임시)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zm_romania_fillers.sql docs/handoff
git commit -m "data: Romania fillers + provisional market row"
git push origin marinebiogroup
```
