# Handoff 2026-10-10 (f) — handoff (e) 이후 추가분

> (e) `handoff_20261010e_email_enrich_final.md` 를 먼저 읽고, 이 문서는 그 뒤에 일어난 변경만 담습니다.

## 1. 추가된 데이터 작업

| 파일 | 내용 | 결과 |
|---|---|---|
| fix_20261010_mill_websites_w09 | James Cropper, Kruger, Mercer | 3 행 |
| enrich_20261010_mill_emails_b14 | James Cropper info@ / enquiries@cropper.com | 2 행 |
| scan_20261010_pulp_only_mills | 펄프 전용 후보 조회 (READ-ONLY) | 85 행 검토 |
| fix_20261010_tag_pulp_only_mills | interest_tags 에 'MBG Pulp Only' | 23 곳 |
| fix_20261010_host_mill_cleanup | Sartell→Clearwater 잘못된 링크 삭제, Omya→Billerud Escanaba confidence high, 우루과이 3 + Lenzing 태그 | 태그 누계 27 |
| fix_20261010_archive_arjowiggins_kutahya | Arjowiggins (그룹 해체) archived + DNC, Hamburger Kütahya (미건설) archived | 2 행 |
| enrich_20261010_mill_emails_b15 | 유럽·일본 18 웹사이트 + 10 인박스, SCA Östrand 태그 | 태그 누계 28 |
| enrich_20261010_mill_emails_b16 | TW/IL/BR/AR/KE 8 웹사이트 + 6 인박스 | |
| fix_20261010_mill_websites_w12 | Longchen, YFY, Familia, UPPC 웹사이트, Hadera → "Infinya (formerly Hadera Paper)" | |

## 2. 코드 변경
- `src/lib/queries/marketing-segment.ts` (565d354, patch_20261010_marketing_skip_pulp_only.ps1): 세그먼트가 **archived 행**과 **interest_tags 에 'MBG Pulp Only'** 가 있는 행을 건너뜀. 디렉토리 MBG category 줄에 "Pulp Only" 칩이 자동 표시.
- `tools/mill_email_crawl.ps1` v3 (21e3c70): 연락처·impressum 링크 우선, 베트남어 lienhe.

## 3. 새 규칙
- **Pulp Only 태그** = 종이를 만들지 않는 시장펄프·용해펄프·CTMP 공장. DNC 가 아니라 대량발송 제외용. 통합 펄프+제지 공장(Suzano, Klabin, Double A, Navigator Setúbal, Mondi Štětí, Ilim, Segezha, SCA 그룹 등)은 태그 안 함.
- **크롤 먼저, DB 나중**: 도메인을 기억으로 추정한 배치는 크롤러로 접속·회사 일치를 확인한 뒤에만 website 를 넣는다. FAIL 사이트는 검색으로 도메인을 확인한 경우만 입력.
- 크롤 입력 CSV 는 실행 블록 안에서 `WriteAllLines` 로 생성 (다운로드 불필요).
- SQL 문자열 리터럴 안에 from / select 등 키워드 금지 — notes 문구도 해당 (w12 에서 한 번 걸림).

## 4. Omya · SMI 호스트 밀 문서
- Claude Doc: https://claude.ai/code/artifact/c7a9674d-0e4e-47da-b8d7-39d5241bb975
- 100 곳: SMI 위성 active 45, Omya active 15, Omya potential 39, SMI historical 9 (중복 7)
- 중복 7곳 공개자료 확인: Double A = SMI 확정, Billerud Escanaba = Omya 확정, Kwidzyn·Spring Grove·IP·Phoenix = 협의 확인 필요, Clearwater = 라이선시 근거 없음 → MBG 직접

## 5. 확인된 회사 변동 (URM 반영 완료)
- Arjowiggins: 프랑스 2019 청산, 영국 2022.9 법정관리, Guarro Casas(2022.10)·Quzhou(2023.12) → Fedrigoni
- Hamburger Kütahya: 2017 발표, 미건설 (EUWID 2024.4: 2025 전 진행 없음)
- Kotkamills → MM (mm.group), Hadera Paper → Infinya (2022.2), Productos Familia → Essity 자회사, UPPC → SCGP

## 6. 남은 작업
1. /marketing 발송 대상 미리보기 — `scan_20261010_marketing_preview.sql` (이 세션 마지막에 작성)
2. 협의 확인 4곳 (Kwidzyn, Spring Grove, IP, Phoenix) — 라이선시 협의 후 링크 갱신
3. 웹사이트 미확인: Ibema, UCIC, Infinya 도메인, Ranheim / Rengo / Marusumi / Daio (봇 차단)
4. MM Follacell — CTMP 펄프 공장 가능성, 확인 후 Pulp Only 태그
5. 무사이트 밀 약 230 행 — 대부분 중동·남아시아·아프리카 중소 밀, 성공률 낮음

## 7. 커밋 (e 이후)
c5cbf80 w09 · 674a5d4 b14 · eee1016 pulp scan · 565d354 marketing skip + tag 23 · 9b0b7aa host cleanup · d4afbd5 Arjowiggins/Kütahya · 6809611 b15 · c75c530 b16 · 707de1a w12
