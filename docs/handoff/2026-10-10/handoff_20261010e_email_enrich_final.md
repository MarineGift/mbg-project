# Handoff 2026-10-10 (e) — Party 이메일 보강 세션 종료 정리

> 이 문서가 오늘 작업의 최종본입니다. (c)·(d) handoff 는 중간 기록.

## 1. 결과 요약

| 항목 | 결과 |
|---|---|
| 제지사 이메일 | 약 115곳 추가 — enrich_20261010_mill_emails_b01 ~ b13 |
| 제지사 웹사이트 | 약 45행 추가 — fix_20261010_mill_websites_w01, w04 ~ w08 (+ b06, b08, b12 안에 포함) |
| 필러 공급사 이메일 | 19곳 추가 — enrich_20261010_filler_emails_b01 |
| 데이터 정리 | fix_20261010_domain_normalized_notes (분석 메모 54건 → notes, 도메인 복구) |
| 폐업 archived | fix_20261010_archive_defunct_mills (PICOP, Kemi, Consolidated Papers, NewPage) + w01 (Sabah Forest Industries) — status=archived, do_not_contact=true |
| 화면 | /[partyType]/parties — Email 컬럼 + `?email=has|missing|form` 필터 (investor / paper_mill / filler_supplier) — commit a723d3a |
| 도구 | tools/mill_email_crawl.ps1 v3 — commit 21e3c70 |

배포 직후 화면 기준(작업 전): Paper Mills Has 183 / Missing 705 (Form only 687).

## 2. 도구 — tools/mill_email_crawl.ps1 (v3)
- 사이트 홈 + 같은 사이트 내 링크를 열어 **페이지에 표시된 이메일만** 수집 (Cloudflare 난독화 해제, JSON escape 정리)
- v2: TLS 고정 해제(1.3 허용), Invoke-WebRequest 실패 시 curl.exe 폴백, `-RetryFrom <candidates.csv>` (UNREACHABLE / NO EMAIL 만 재시도)
- v3: 연락처·impressum 계열 링크를 먼저 엶 (MaxPagesPerSite 8 에 걸려 연락처가 빠지던 문제), 베트남어 `lienhe`
- 입력 CSV 는 `company_key,rows_in_key,website` 만 있으면 됨 → 실행 블록 안에서 WriteAllText 로 생성 (다운로드 불필요)
- 출력: `Downloads\mill_email_candidates_<yyyyMMdd_HHmm>.csv` → 검토 후 배치 SQL
- 한계: WAF/지역차단 사이트는 FAIL (Copamex, Hokuetsu, Yueyang, Asia Honour, KC, Sappi, Stora Enso, Nippon, Oji 등). JS 로 주소를 그리는 사이트는 0건
- 크롤러 0건이어도 주요 대상은 연락처 페이지를 직접 열어 확인 (VINAPACO 가 그 예)

## 3. 검토 규칙 (유지)
- **회사 자신이 공개한 주소만**: 회사 페이지, 회사 공시 레터헤드(BSE/NSE), 회사 연차보고서, 공시플랫폼 회사 프로필(KAP). 데이터브로커(ContactOut, Wiza, Prospeo, Datanyze 등)·업체 디렉토리·장비업체 사례 페이지·검색 스니펫·패턴 추측 금지
- 넣는 것: 일반 / 영업 / 고객서비스 / 공장·거점 전용 인박스, 페이지가 역할을 밝힌 개인(예: Norske Skog TCS)
- 빼는 것: IR, 언론, HR·채용, GDPR/KVKK/개인정보, 컴플라이언스·법무, webmaster, no-reply, 대행사, 자회사·계열사·인근 회사 주소, 판매대리점(depot), 소비재 마케팅
- 그룹 공통 인박스는 같은 도메인 행에만. 매핑이 불확실하면 사용자 브라우저 확인 후 입력 (Muda 사례)
- source 값: homepage / press (공시·연차보고서) / registry (KAP)
- 모든 SQL: 멱등(not exists 가드), 마지막 문장은 검증 select, 문자열 안에 SQL 키워드·세미콜론 금지

## 4. 국가별 경험치
- **인도 상장사**: BSE/NSE 공시 레터헤드에 대표 이메일 → 성공률 높음 (Emami, Orient, N R Agarwal, Star, Andhra)
- **튀르키예 상장사**: KAP 프로필에 회사 이메일 또는 웹사이트 → 크롤러로 영업 인박스 (Alkim, Viking, Lila)
- **인도네시아 상장사**: 거래소 프로필은 IR·corp.sec 만 → 사이트 크롤링 필요 (Suparma OK, Fajar 폼 전용)
- **베트남 상장사**: 연차보고서에 대표 이메일 (DOHACO) / 국영사는 연락처 페이지 직접 확인 (VINAPACO)
- **중국 지방·국영 중소 밀**: 공식 사이트·이메일 대부분 없음 → 라이선시 경로
- **대형 그룹**(KC, IP, Smurfit Westrock, Sappi, Stora Enso, Mondi, Suzano, Essity, GP, PCA, Sylvamo, Metsä 등): 폼 전용 확정 — 페이지에 나오는 주소는 언론·IR 뿐

## 5. 발송 시 주의
- 그룹 공통 인박스가 여러 행에 붙은 경우: Holmen 6, APP Indonesia 6, Bio Pappel 5, Shanying 5, Fedrigoni 4, Navigator 4, Norske Skog 4, Mpact 3, ND Paper US 3, Saugbrugs AS/PM4/PM5 — 한 배치 안에서는 dedup, 다른 배치에서는 재발송 가능 → /marketing 미리보기 확인
- DE·AT·KR 은 /marketing 기본 제외
- Omya·SMI 공급 밀은 대량발송보다 라이선시 본사 협의 경로 우선

## 6. 남은 작업 (우선순위)
1. **라이선시 호스트 밀 목록** — `sql/scan_20261010_licensee_host_mills.sql` (READ-ONLY) 실행 → CSV → Omya·SMI 본사 협의 자료로 정리 (약 70곳). 아직 실행 결과 미수령
2. **웹사이트 없는 비링크 밀** — 약 300행. 영어권(캐나다·영국: Kruger, Irving, Mercer, Sustana, James Cropper)·인도·튀르키예·베트남 상장사 우선, 중국·중동 중소 밀은 후순위
3. **폼 전용 대형 그룹** — LinkedIn(Sales Navigator / Apollo)으로 공장장·기술이사 조사 (Claude 는 LinkedIn 로그인 불가)
4. **필러 공급사** — 웹사이트 없는 20행, 일본 FAIL 사이트(Shiraishi, Maruo, Nittetsu), Imerys·Carmeuse (폼 전용 추정)

## 7. 결정 대기
- **Arjowiggins (FR, Boulogne-Billancourt)**: 아르슈 공장은 2011 Munksjö(현 Ahlstrom) 매각, 현 Arjowiggins 는 영국 Aberdeen 본사(Stoneywood·Chartham·Guarro Casas·Quzhou). ① 행을 영국 현 회사로 수정 + SMI Arches 링크를 Ahlstrom 으로 이동, 또는 ② 프랑스 행 archived + 영국 행 신규
- **Hamburger Kütahya**: 2017 발표 신규 공장 — 가동 여부 확인 필요. 운영 확인된 튀르키예 공장은 Çorlu·Denizli
- **Daehan Pulp**: Kleannara 계열인데 DNC 가 빠져 있는지 확인
- **Jiangsu Bohui (APP, Dafeng)**: bohui.com(Shandong Bohui)에 잘못 묶여 있음
- **PCM (Mexico)**: website 칸에 dnb.com
- **필러 'Texas Medical Center'**: 오분류 의심

## 8. 커밋 기록 (marinebiogroup)
7f1d049 worklist scan + crawler + b01 · 9a0beb1 b02 · e537a84 b03 + crawler v2 · 8bb1512 domain_normalized fix · 6652f2c filler b01 + mill b04 · dd5450c handoff (d) · a723d3a Email 컬럼 · e35b9bf b05 · c4b9d95 archive + w01 · 5797f15 b06 · 9691c0f b07 · 14cd2c8 licensee scan + b08 · 6343828 w04 · 97fc4a7 b09 · c59b3ea w05 · 129b224 b10 · 1ae3d5b w06 · 260e6d6 b11 · 168fe62 w07 · ef2e9f4 b12 · cd5472f w08 · 416859d b13 · 21e3c70 crawler v3
