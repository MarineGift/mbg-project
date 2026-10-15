\xef\xbb\xbf# Handoff 2026-10-14 (x) — 레바논 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014w_iran_mills_fillers.md` (실행·푸시 완료, 제재국 마케팅 제외 패치는 결정 대기)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014x_lebanon_mills_fillers.sql` | 필러 2사, 밀 5곳(없을 때), 소개·메모, plant 블록 5 |

batch / source: `lebanon_update_20261014` · 메모 표식 `LB check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Lebanese Calcium Carbonate S.A.L. (Amchit), Microfillers (Al Koura). PCC 공장 없음 ('PCC' 라는 회사는 레미콘)
- 제외: Roky Plast(플라스틱), 유통업체, 요르단 공급사(별도 국가)
- Mill profile 우선순위: 1 Unipak Tissue Mill (INDEVCO, PM1 2.2만 t) · 2 MIMOSA (티슈 1.5만 t) · 3 SICOMO (재생 판지 2.5만 t) · 4 Solicar · 5 SIPCO
- 가공업체(UNIPAK 박스, Sanita, Perla, Gemayel)는 추가하지 않음

## 3. 판단
- INDEVCO Paper Making 을 레바논·이집트(Interstate)·그리스(UNIPAKHELLAS) 진입점으로 — 카드 approach 에 기록
- Unipak 과거 3만~3.2만 t 는 PM2(2012 이집트 이전) 포함 수치 → 2.2만 t 사용
- 티슈·재생 판지 → FCC 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014x_lebanon_mills_fillers.sql docs/handoff
git commit -m "data: Lebanon fillers + mills (INDEVCO Unipak) + intros + plant profiles"
git push origin marinebiogroup
```
