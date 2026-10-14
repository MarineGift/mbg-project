\xef\xbb\xbf# Handoff 2026-10-14 (b) — Omya 미국 공장 + Artemyn 메모

> 앞 문서: `handoff_20261014_us_filler_mill_links.md` (SMI 위성공장 8 + 링크 8, 실행 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014b_omya_us_plants.sql` | Omya 미국 공장 7행 + 프로필 + Domtar Hawesville 밀(없을 때) + 링크 3 + Artemyn 메모. 멱등, 마지막 = 검증 select |

source / batch: `us_omya_plants_20261014`

## 2. 반영 내용
- **Omya PCC (제지공장 현장형)** — "Omya PCC USA" 가 Domtar 밀 주소에 등록됨
  - Hawesville KY (58 Wescor Rd = Domtar Hawesville 주소) → active / medium
  - Johnsonburg PA (499 Glen Ave, 2007 설립) → active / medium
  - Kingsport TN (100 Clinchfield St = Domtar Kingsport 주소) → **historical** (Domtar 가 2020년 UFS 종료, 재생 라이너보드로 전환)
- **Omya GCC** — Florence VT (Verpol·East 공장, VT DEC 허가), Sylacauga AL, Lucerne Valley CA (MDAQMD 허가 2025-10 갱신), Superior AZ (도시명 보고서 기준, 확인 필요). 고객 미공개 → 링크 없음
- **Artemyn** — 2024-07 출범 시 23개 사업장·약 1,000명·2023 매출 약 4억 달러, 미국 법인 Artemyn USA, LLC (구 Americarb, Inc.). 미국 공장 목록은 미공개 → 메모만 추가

## 3. 반영하지 않은 보고서 내용 (이유)
- Eastover·Ticonderoga 고객 = IP, Longview = NORPAC: URM 에 최신 운영사(Sylvamo, Nippon Dynawave) 반영됨
- Chillicothe "FCC 높음": 2025 폐쇄 — historical 유지
- Wickliffe 35,000 t/yr: 기존 링크에 이미 있음
- $15/톤 로열티 시나리오: 분석값, DB 데이터 아님

## 4. 실행 후 확인
- `group link` 행: 기존 `Omya (USA)` 그룹 행이 같은 밀에 이미 연결돼 있으면 표시됨 → 공장 행 링크와 중복이면 그룹 링크 정리 여부 결정
- link 3행 미만이면 해당 도시 밀 행 이름이 다름 → 개별 처리

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014b_omya_us_plants.sql docs/handoff
git commit -m "data: Omya US plants (PCC at Domtar mills, GCC sites) + Artemyn note"
git push origin marinebiogroup
```
