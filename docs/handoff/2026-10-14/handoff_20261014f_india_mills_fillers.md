\xef\xbb\xbf# Handoff 2026-10-14 (f) — 인도 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014d_jp_mill_plant_profiles.md` (+ e: Hachinohe·Kishu 추가 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014f_india_mills_fillers.sql` | 인도 밀 8곳 확인/추가, Fimakem·Omya (India) 추가, 링크 4, plant 블록 7 |

batch / source: `india_update_20261014`

## 2. 이미 있어서 건드리지 않은 것
SMI → JK Rayagada(4.6만 t)·BILT Sewa(1.5만 t)·Century Lalkuan(4.5만 t)·Andhra Rajahmundry(NewYield)·Satia(4.2만 t), Gulshan → Orient Amlai·ITC Tribeni, Gulshan·Wolkem·20 Microns 필러 행

## 3. 추가
- 밀 (없을 때만): JK Rayagada, Satia, Century Lalkuan, Andhra Rajahmundry, Trident Barnala, West Coast Dandeli, TNPL Kagithapuram, Silvertone Muzaffarnagar
- 필러: Fimakem India (Wolkem + Fimatec JV, 위성 WGCC), Omya (India) (2004년부터 건식·슬러리 공장, 위치 미공개)
- 링크
  - Gulshan → Trident Barnala: potential, 22,000 t/yr 계획 (2026-03 계약, FY2027-28 매출 시작)
  - Gulshan → Silvertone: active / high (2013, Gulshan 자사 페이지)
  - Fimakem → ITC Bhadrachalam, JK Rayagada: active / medium (Wolkem 이 사이트 명시, 현재 가동 확인 필요)
- Mill profile 우선순위: 1 JK Rayagada · 2 Satia · 3 Century Lalkuan (2026-08-01 ITC 이전) · 4 Andhra · 5 Trident · 6 West Coast · 7 TNPL
- FCC 시나리오는 인쇄·필기용지 밀만 (JK, Satia, Andhra, Trident, West Coast). Century·TNPL 은 판지·티슈 포함이라 생략

## 4. 보고서 대비 판단
- 보고서의 "기존 PCC 능력 × 25% 전환" 방식 대신, 다른 국가와 같은 종이 생산능력 기준 시나리오 사용 (카드에서 자동 계산)
- Gulshan 185,000 t (과거·전 제품 합산), MTI 2026-01 인도 증설(공장명 미공개)은 수치로 넣지 않음

## 5. 실행 후
검증 결과 `MISSING` 이나 엉뚱한 밀 이름(예: JK 다른 공장)이 보이면 공유 → 개별 수정

## 6. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014f_india_mills_fillers.sql docs/handoff
git commit -m "data: India mills + Fimakem/Omya India + links + plant profiles"
git push origin marinebiogroup
```
