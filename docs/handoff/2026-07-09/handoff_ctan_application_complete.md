# Handoff — CTAN/Dealum 지원서 완료 + 다음 세션: Party 지원서 템플릿 UI

**작성일** 2026-07-09 · **레포** MarineGift/mbg-project · **브랜치** marinebiogroup
**최근 커밋** `58aee2f` feat(applications): CTAN Dealum 9-step application seed

---

## 1. 이번 세션에서 완료한 것

### 1-1. CTAN/Dealum 9스텝 지원서 전체 시드

실제 폼 URL: `https://app.dealum.com/#/company/application/new/72264/cmwl94en1rop0rvg8k9x44vzlcw2hgrf`
(ctan.com/entrepreneurs 는 랜딩 페이지일 뿐. 포털 로그인 필요)

| Step | seq | 상태 |
|---|---|---|
| 1 Overview | 101–119 | 시드 완료, 파일/날짜 필드는 공란 |
| 2 Team | 201–213 | 시드 완료, 전화·LinkedIn·CEO 창업연수 공란 |
| 3 Problem | 301 | ok |
| 4 Solution | 401 | ok |
| 5 Market | 501–504 | ok |
| 6 Business Model | 601–604 | ok |
| 7 Finance | 701–721 | 14개 ok, 7개 창업자 입력 대기 |
| 8 Strategy | 801–806 | ok |
| 9 Other | 901–904 | 901 ok, 903·904 대기 |

**커밋된 SQL 14개** (`sql/`)
- `seed_ctan_overview_fields.sql`, `seed_ctan_team_fields.sql`, `seed_ctan_problem.sql`,
  `seed_ctan_solution.sql`, `seed_ctan_market.sql`, `seed_ctan_business_model.sql`,
  `seed_ctan_finance.sql`, `seed_ctan_strategy.sql`, `seed_ctan_other_and_overview.sql`
- `fix_ctan_ip_disclosure.sql` → `_v2` → `_v3` (IP 공시 단계적 정정 이력)
- `fix_ctan_round_100k.sql` ← **최종 권위본**
- `fix_ctan_cleanup_and_oneliner.sql` (유령 필드 seq 1–8 삭제 + 104 바인딩)

실행 순서: seed 9개 → v1 → v2 → v3 → 100k → cleanup. 전부 멱등.

### 1-2. 라운드 구조 재설계 ($1M priced → $100K SAFE)

| 항목 | 값 |
|---|---|
| Instrument | post-money SAFE |
| Capital seeking | **$100,000** (라운드 전체) |
| Valuation cap | $10,000,000 |
| Discount | 20% |
| MFN | 있음 |
| Pre/post money | N/A (SAFE) |
| Already raised | $0 |
| Use of funds | 전액 미국 국립 제지연구소 티슈 검증 ($85K 랩·샘플·분석, $15K 출장·기술지원) |

$500K 특허 이전 대가는 **이번 자금이 아님** — 계약상 투자 유치 후 1년 내 지급.

### 1-3. IP 소유 현황 (정직한 공시로 3차 수정)

- **MBG Inc. 보유 특허 자산: US 19/396,332 단 1건.** 대가 미지급, 1년 내 지급 조건.
- 등록특허 5건(KR) + KR 10-2887327 + PCT + KR 출원 = **전부 Marinepad 명의**
- 한국 특허는 한국에서만 유효 → 9,000톤(한국 공급)의 로열티를 뒷받침하는 특허를 미국 법인이 소유하지 않음
- 글로벌 충전제사와의 **NDA는 MBG Inc.가 체결**, MBG를 로열티 수취인으로 지정, Marinepad를 가족회사로 기재
- 9,000톤 라이선스 계약: **대표자 승인 완료, 문서화 진행 중(미체결)**
- 충남대 → Marinepad 100% 이전 완료. 자비 연구. 국가 R&D 자금 미개입. 대학·발명자 잔여권리 없음

문구 정정: "royalties accruing automatically" → "royalty terms have executive approval, definitive agreement being documented"

### 1-4. 산출물

- `Marinebio_IR_Ver2_1_100K_SAFE.pdf` (2.9MB, Dealum 25MB 제한 통과) / `.pptx` (27.7MB, 업로드 불가)
  - 18p "The Ask: $100K on a capped SAFE", 19p "Why a $10M cap" (= 0.45× Year-3 로열티)
  - **발표자 노트도 교체** (원본에 "1 million dollars, for 5 percent" 잔존했음)
- `Marinebio_Cap_Table_2026-07-09.xlsx` / `.csv` — Heo 51% / Seo 34% / 미발행 15%
- `Marinebio_Exclusive_License_Term_Sheet_DRAFT.md` — Marinepad → MBG Inc. 전용실시권 텀시트

> 🔒 Cap table과 텀시트는 **레포에 커밋 금지**. 주주 실명·계열사 채무 포함, 레포는 public.

---

## 2. 남은 작업 (마감 2026-07-26, D-17)

### 2-1. 지원서 공란 19개

| 구분 | 필드 |
|---|---|
| 재무 실측 | 701 마감월, 702 12개월 매출(미입금이면 0), 704 번레이트, 705 지난달 지출/수입, 706 현금, 709 사전출자 |
| 파일 | 102 로고, 117 덱 PDF, 119 이미지, 721 cap table, 903 추가자료 |
| 창업자 정보 | 108 등록일, 201 전화, 202 LinkedIn, 205 팀원초대, 212 CEO 창업연수, 904 유입경로 |
| 선택 | 118 비디오 |

### 2-2. 법률·계약

1. **전용실시권 체결 + KIPO 설정등록** (목표 7/20) — 한국 특허법상 등록해야 효력 발생
2. **기존 $500K 양도계약서 검토** — 조건부 이전인지 단순 채무인지
3. **USPTO Assignment Search** — US 19/396,332 양도 등록 여부 (무료, 즉시)
4. **$500K 산정 근거** 가치평가서
5. Korea NET 인증서(2023-0010) 명의자 확인

완료 시 지원서 901/804/714의 "being documented" → "executed and registered" SQL 패치 요청.

### 2-3. 덱 22p

"This round funds FCC... the Series-A upside the seed also secures" — $100K를 seed라 부르기 무리. 표현 조정 검토.

---

## 3. 다음 세션 작업: Party 지원서 · 연락방식 템플릿 UI

### 배경

투자자·제지사 수백 곳의 지원서·문의 폼은 사실상 **15~20개 표준 질문의 변형**입니다.
canonical_key로 매핑하고 answer_library를 공유하면, 새 폼을 만날 때마다 답변을 다시 쓰지 않아도 됩니다.

### 이미 적용된 스키마 (migration_026 / 027)

```
app.parties
  preferred_contact_method  -- email | web_form | portal | phone | other
  contact_form_url          -- 폼 URL (partial index 있음)

app.application_forms
  submission_method         -- email | web_form | portal | email_then_form
  submit_email, attachments, login_required, form_type
  form_type 에 'contact_inquiry' 추가됨 (mill 문의 폼이 같은 기계 재사용)

app.application_form_fields
  canonical_key             -- answer_library 조인 키
  selector, selector_type, input_kind

app.answer_library
  variant                   -- short | medium | long
  target_length
  UNIQUE (org, answer_key, variant)
```

검증됨: CTAN → `portal`, Venture For ClimateTech → `web_form`

### 만들 것

1. **Party 상세/목록에 연락방식 배지**
   - `preferred_contact_method` 를 뱃지로 표시 (email / web_form / portal)
   - `web_form`·`portal` 이면 폼 아이콘 + `contact_form_url` 링크

2. **Party에서 지원서 작성 drawer**
   - 폼이 연결된 party → "Open application" 버튼
   - `application_forms` 없으면 **템플릿에서 생성**: form_type 선택 →
     표준 canonical_key 세트로 `application_form_fields` 자동 생성
   - 각 필드에 `answer_library` 에서 canonical_key + 적절한 variant 자동 바인딩
   - `target_length` / `max_length` 비교해서 variant 자동 선택 (short/medium/long)

3. **"Copy next" 순차 복사 모드**
   - 폼 화면과 나란히 놓고 필드 순서대로 복사 → `is_copied` 토글
   - 이미 `application_field_answers.is_copied` 컬럼 존재

4. **표준 canonical_key 세트 정의**
   - 현재 확보된 키: `problem`, `solution`, `market_customers`, `market_size_musd`, `uvp`,
     `competitors`, `business_model`, `customer_acquisition`, `cost_structure`, `growth_barriers`,
     `traction`, `go_to_market`, `milestones`, `risks_mitigations`, `exit_strategy`,
     `likely_acquirers`, `ip_portfolio`, `valuation_rationale`, `deal_terms`, `use_of_funds`,
     `capital_seeking`, `valuation_cap`, `discount_rate`, `company_one_liner`,
     `team_management`, `advisory_board`, `founder_experience` 등
   - 중복 키 통합 필요: `SELECT answer_key, variant FROM app.answer_library ORDER BY 1,2;` 확인

### 관련 파일

- `src/app/(app)/applications/page.tsx`, `list-client.tsx`, `[formId]/page.tsx`, `library/`
- `src/app/api/applications/*` (5개)
- 폐기됨: `src/scripts/fill-application.ts`, `inspect-form.ts` (Playwright 자동입력 — CTAN/Dealum이 봇 차단, 사용 중단)

---

## 4. 파일 이동 (mover)

라우터:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"
```

라우터가 못 잡을 때 인라인 폴백:
```powershell
$dl   = Join-Path $env:USERPROFILE "Downloads"
$dest = "C:\dev\mbg-project\docs\handoff\2026-07-09"
[System.IO.Directory]::CreateDirectory($dest) | Out-Null
$f = Get-ChildItem -Path $dl -Filter "handoff_ctan_application_complete*.md" -File -ErrorAction SilentlyContinue |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $f) { Write-Host "MISS  handoff_ctan_application_complete.md" }
else {
  Unblock-File -Path $f.FullName -ErrorAction SilentlyContinue
  [System.IO.File]::Copy($f.FullName, (Join-Path $dest "handoff_ctan_application_complete.md"), $true)
  Remove-Item $f.FullName -Force
  Write-Host "OK    handoff_ctan_application_complete.md"
}
```

## 5. 커밋 · 배포

```powershell
cd C:\dev\mbg-project
git status -sb
git add docs/handoff/
git commit -m "docs(handoff): CTAN application complete, next session party form templates"
git push origin marinebiogroup
```

> `git push` 가 Railway 자동 배포를 트리거합니다. 푸시해야 웹에 반영됩니다.
> `git add` 에 존재하지 않는 패턴이 섞이면 명령 전체가 중단되니 `git add docs/handoff/` 처럼 디렉터리로 지정하세요.

---

## 6. 반복되는 실무 주의사항

- **Supabase SQL Editor 파서**: 문자열 리터럴 안에 `;`, `'`, 그리고 독립 SQL 키워드(`into` `from` `where` `join` `select`) 금지.
  실제로 `"designed into a mill"` 의 `into` 가 `INSERT INTO` 로 오인되어 `42P01: relation "a" does not exist` 발생 → `"specified at a mill"` 로 수정.
- **파일은 반드시 다운로드 후 라우터 실행.** 채팅에서 SQL만 복사하면 `0 file(s) moved` → `git add` pathspec 에러.
- 🔒 **파트너 실명(Omya / Specialty Minerals / 무림 / TPIL)은 대면 NDA에서만.** 웹폼·이메일·공개자료 금지.
  단 806(인수 후보)에 **시장 참여자로 명명하는 것은 안전** (덱 9p·28~29p 공개내용). 802의 "under NDA" 익명 표기와 절대 연결하지 말 것.
- 재무 수치·법률 자문은 지어내지 않는다. 창업자 실측값이 없으면 필드를 `empty` 로 남긴다.
