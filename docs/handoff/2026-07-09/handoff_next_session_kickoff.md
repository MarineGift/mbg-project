# 🚀 킥오프 브리프 — Investor 지원서 자동 입력 (다음 세션용)

> **새 세션 첫 메시지로 이 파일을 통째로 붙여넣으세요.**
> 이전 세션의 컨텍스트 없이도 바로 작업을 이어갈 수 있게 정리했습니다.

---

## 0. 프로젝트 컨텍스트 (30초 요약)

- **레포**: `MarineGift/mbg-project`, 브랜치 `marinebiogroup`, 로컬 `C:\dev\mbg-project`
- **스택**: Next.js 14 / TypeScript / Supabase, Railway 자동배포 (`git push` = 배포)
- **파일 경로 규칙 (라우터가 진실)**: SQL → `sql\`, 핸드오프 → `docs\handoff\<YYYY-MM-DD>\`
  - 이동은 항상 `powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"`
- **org_id**: `b25de8f2-1020-482f-9012-183f63883169`

### 배경
Marinebio Group(FCC 제지용 충전제)이 브릿지 $100K를 조달 중. 타깃 엔젤·액셀러레이터
(CTAN, Austin Hardtech, Venture For ClimateTech, MassChallenge)가 **웹 폼으로만 지원**을 받는다.
매번 같은 답변을 손으로 붙여넣는 노동을 없애는 게 이번 작업의 목적.

### 🔒 절대 규칙 (이게 이 기능의 존재 이유)
파트너 실명(**Omya / Specialty Minerals / 무림제지 / TPIL**)은 **대면에서만** 공개 가능.
웹 폼·이메일·공개 자료에 절대 들어가면 안 된다. 스키마의 `disclosure_level='nda_only'`가 이 가드다.

---

## 1. 이미 완료된 것 (migration 025, DB 반영 + 커밋 완료)

```
app.application_forms          (ENTITY, created_by O)
 └ app.application_form_fields  (자식상세, created_by X)
    └ app.application_field_answers (링크, created_by X)
       └ app.answer_library      (ENTITY, created_by O)
app.v_application_field_status   (뷰: empty / over_limit / nda_blocked / ok)
```

- `answer_library` 13개 시드 완료 (public 12 + nda_only 1)
- CTAN 폼 1건 + 질문 8개, Venture For ClimateTech 폼 1건 등록
- 파일: `sql/migration_025_application_forms.sql`, `sql/seed_answer_library.sql`

### ⚠️ 알려진 함정
1. `created_by uuid NOT NULL DEFAULT auth.uid()` → **SQL Editor는 postgres 역할이라 auth.uid()가 NULL**.
   시드는 `COALESCE(auth.uid(), (SELECT id FROM auth.users ORDER BY created_at LIMIT 1))`로 해결.
2. Supabase SQL Editor 파서: 문자열 리터럴 안에 **세미콜론·아포스트로피·독립 SQL 키워드**(`into`,`from`,`select`…) 금지.
3. `field_type`의 드롭다운 값은 `'select'`가 아니라 **`'dropdown'`**.

---

## 2. 이번 세션에 할 일

### (A) 마이그레이션 026 — 제출 방식 + 셀렉터

`app.application_forms`에 추가:
| 컬럼 | 타입 | 설명 |
|---|---|---|
| `submission_method` | text NOT NULL default 'web_form' | `email` / `web_form` / `portal` / `email_then_form` |
| `submit_email` | text | email 방식일 때 수신처 |
| `attachments` | text[] | 첨부 파일명·URL 목록 |
| `login_required` | boolean default false | 계정 로그인 필요 여부 |

`app.application_form_fields`에 추가:
| 컬럼 | 타입 | 설명 |
|---|---|---|
| `selector` | text | Playwright용 CSS 셀렉터 (예: `#company_description`) |
| `selector_type` | text default 'css' | `css` / `xpath` / `label` / `placeholder` |
| `input_kind` | text default 'fill' | `fill` / `check` / `select_option` / `upload` |

CHECK 제약 추가. RLS는 기존 테이블 상속(정책 이미 존재).
자식상세 테이블이므로 `created_by` 추가 금지.

### (B) UI — `/applications`

**목록** `app/(app)/applications/page.tsx`
- 프로그램명, 제출방식 배지(📧 email / 🌐 form), 마감 D-day, 진행률(`ok` 필드 / 전체)
- 마감 임박순. 지났는데 미제출이면 빨강

**작성** `app/(app)/applications/[formId]/page.tsx`
필드 한 줄당:
```
[3] Describe your solution              (required · max 1000)
┌────────────────────────────────────────────────────┐
│ FCC grows calcium carbonate in-situ on a ...        │
└────────────────────────────────────────────────────┘
 [라이브러리 ▾]   412 / 1000   [복사]
```
- 라이브러리 드롭다운 → `final_text`에 `body_en` 주입 (원본 불변)
- `char_count > max_length` → 빨강 + 복사 비활성
- 🔒 `disclosure_level='nda_only'` → **복사 버튼 잠금** + 경고 토스트
  *"This answer contains partner names under NDA. Disclose in person only."*
- 복사 성공 시 `is_copied = true`
- "Mark as submitted" → `status='submitted'`, `submitted_at=now()`

**라이브러리 CRUD** `app/(app)/applications/library/page.tsx`
EN/KO 토글, `disclosure_level` 스위치(빨강 경고), 태그 필터

**API**
- `GET /api/applications`, `GET /api/applications/[formId]` (뷰 조회)
- `PATCH /api/applications/[formId]/fields/[fieldId]`
- `POST /api/applications/[formId]/submit`
- `GET|POST|PATCH /api/answer-library`

RLS가 org 스코핑을 처리하므로 API는 세션 org만 신뢰.

### (C) Playwright 반자동 입력 — `scripts/fill-application.ts`

**설계 원칙 (중요)**
- ✅ 브라우저 열기 → 필드 자동 채우기 → **열어둔 채 정지**
- ❌ **자동 제출 금지.** 사람이 눈으로 검토하고 직접 Submit 클릭
- 이유: ① 다수 폼의 약관이 자동 제출 금지 ② CAPTCHA·로그인·업로드는 어차피 사람 필요
  ③ `nda_only` 유출을 사람 눈이 마지막으로 걸러야 함

**동작**
```bash
npm run apply:fill -- --form <formId>
```
1. Supabase에서 `v_application_field_status` 조회
2. **가드 1**: `field_state='nda_blocked'`가 하나라도 있으면 **즉시 중단**하고 해당 필드 출력
3. **가드 2**: `over_limit` 있으면 경고 후 확인 프롬프트
4. `chromium.launch({ headless: false })` → `form_url` 이동
5. `login_required`면 사람이 로그인할 때까지 대기 (`page.pause()`)
6. 필드별로 `selector`/`input_kind`에 따라 `fill()` / `check()` / `selectOption()`
7. `page.pause()` — Playwright Inspector가 열리고 브라우저는 유지됨. 사람이 검토 후 제출.
8. 종료 후 `is_copied=true` 일괄 업데이트

**셀렉터 수집 헬퍼** `scripts/inspect-form.ts`
- `codegen` 대신, 폼 URL을 열어 `input/textarea/select`를 스캔하고
  `{ label, name, id, css }` 목록을 JSON으로 뱉음 → `application_form_fields.selector`에 채워넣기

**의존성**: `npm i -D playwright` + `npx playwright install chromium`
**주의**: 이 스크립트는 로컬 실행 전용. CI/서버에서 돌리지 말 것 (자격증명·NDA 데이터).

---

## 3. 산출물 & 마무리

**파일명 규칙 준수**
- `migration_026_submission_method.sql`
- `handoff_form_autofill.md`
- (선택) `seed_ctan_selectors.sql`

**마무리 블록**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"

cd C:\dev\mbg-project
git status -sb
git add sql/migration_026_submission_method.sql
git add docs/handoff/<날짜>/handoff_form_autofill.md
git add app/ scripts/ package.json
git commit -m "feat(applications): submission method, selectors, and Playwright semi-auto fill"
git push origin marinebiogroup
```
> `git push` = Railway 자동배포. 푸시해야 웹에 반영됨.

---

## 4. 열린 질문 (세션 시작 시 확인)

1. CTAN 폼의 **실제 글자수 제한**은 추정값이다 — 실제 폼을 열어 확인 필요
2. CTAN 폼이 **로그인 필요**한가? 계정을 먼저 만들어야 하나?
3. Austin Hardtech / MassChallenge의 폼 URL과 질문 목록은 아직 미수집
4. 첨부 파일(덱 PDF, 1페이저) 업로드 필드가 있는가? → `input_kind='upload'` 처리 필요

---

## 5. 첫 메시지 예시

> 위 브리프대로 진행하자. 먼저 마이그레이션 026(submission_method + selector 컬럼)부터 만들고,
> 그다음 Playwright 스크립트, 마지막에 UI 순서로 가자.
> CTAN 폼 URL은 https://www.ctan.com/entrepreneurs/ 이고, 아직 열어보지 않았다.
