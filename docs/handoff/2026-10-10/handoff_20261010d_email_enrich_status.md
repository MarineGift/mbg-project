# Handoff 2026-10-10 (d) — 제지사·필러 공급사 이메일 보강 진행 현황

## 완료 (DB 반영 + push)
| 파일 | 내용 | 결과 |
|---|---|---|
| enrich_20261010_mill_emails_b01 | Kartonsan, Borregaard (수동) | 3행 |
| enrich_20261010_mill_emails_b02 | 크롤러 1차 | 56곳 / 59행 |
| enrich_20261010_mill_emails_b03 | Norske Skog TCS 기술담당 5명 (공장 명시) | Bruck·Skogn·Golbey·Saugbrugs |
| enrich_20261010_mill_emails_b04 | 크롤러 v2 재시도 (Bio Pappel 5, Bracell, Packages 2) | 8곳 / 10행 |
| enrich_20261010_filler_emails_b01 | 필러 공급사 크롤러 (SMI·Omya 제외) | 19곳 / 23행 |
| fix_20261010_domain_normalized_notes | domain_normalized 에 들어간 분석 메모 → notes 이동, 도메인 재생성 | filler 54행 보존, 잔여 0 |

## 도구
- `tools/mill_email_crawl.ps1` v2: 사이트 홈 + contact/imprint 페이지에서 표시된 이메일만 수집. TLS 1.3 허용, curl.exe 폴백, `-RetryFrom <candidates.csv>` 로 FAIL/0건만 재시도. 입력 CSV 는 `company_key`, `website` 컬럼만 있으면 됨 (공급사도 동일하게 사용)
- 워크리스트: `scan_20261010_mill_email_worklist.sql`, `scan_20261010_filler_email_worklist.sql` (READ-ONLY, 단일 statement → CSV)
- 로컬 데이터는 `data\` (커밋 안 함)

## 검토 규칙 (유지)
- 회사 자기 페이지에 표시된 주소만. 데이터브로커·검색 스니펫·패턴 추측 금지
- 유지: 일반/영업/고객서비스/공장·거점 전용 인박스. 제외: IR, 언론, HR, GDPR/KVKK, 컴플라이언스, webmaster, no-reply, 대행사, 자회사·인근 회사 주소
- 개인 주소는 페이지가 역할을 밝힐 때만 (예: Norske Skog TCS). 담당 공장이 명시된 경우에만 해당 공장 행에
- 크롤러 아티팩트(`u003e…`, `nosotros-…`, `us-…`, 오타 도메인) 제거

## 남은 작업
1. 크롤러 FAIL(WAF/지역차단) 중소형사 웹검색 — 제지사: Copamex, Lecta, Ilim, Sun Paper, Leeman, Chenming, Asia Paper, Hongwon / 공급사: Shiraishi, Maruo, Nittetsu, Huanan, gdcaco3, 삼표, Suez Cement, Thiele, hbklgroup
2. 웹사이트 없는 행 — 제지사 344, 공급사 20 (공급사 링크 있는 중국 SMI 밀 7곳, Ledesma, Yueyang 우선)
3. 역할 미표시 개인 주소 (Domtar 13, Nordkalk 45, Trzuskawica 7 등) — 페이지에서 역할 확인 후 선별
4. 데이터 정리: Jiangsu Bohui (APP) 가 bohui.com(Shandong Bohui) 에 잘못 묶임 / PCM 웹사이트 칸 dnb.com / 필러 'Texas Medical Center' 오분류 의심 / Daehan Pulp DNC 누락 여부
5. [결정 대기] Omya·SMI 공장 행 132개 — "licensee - HQ only" 표시로 /marketing 대량발송 제외 제안

## 발송 시 주의
- 그룹 공통 인박스가 여러 행에 붙은 경우(Holmen 6, Fedrigoni 4, Navigator 4, Norske Skog 4, Bio Pappel 5, Mpact 3, ND Paper US 3, Saugbrugs PM4/PM5) — 다른 배치에서 재발송 가능, 미리보기 확인
- DE·AT·KR 은 /marketing 기본 제외
