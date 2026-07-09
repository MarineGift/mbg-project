# handoff_application_forms.md

**작업**: 투자처 홈페이지가 "웹 폼 지원" 방식일 때, URM에서 질문·답변을 관리하고 붙여넣기까지 지원하는 기능
**날짜**: 2026-07-09
**브랜치**: `marinebiogroup`
**딜리버러블**: `migration_025_application_forms.sql`, `seed_answer_library.sql`, 이 문서

---

## 1. 왜 필요한가

브릿지 라운드 타깃(CTAN, Austin Hardtech, Venture For ClimateTech, MassChallenge)이 **전부 웹 폼으로만 지원**을 받는다. 이메일 피치가 안 통한다.

실무 문제 4가지:

| 문제 | 결과 |
|---|---|
| 폼마다 질문이 다름 | 매번 처음부터 다시 씀 |
| 같은 답변을 반복 작성 | 버전이 갈라지고 문구가 흔들림 |
| 글자수 제한(300자, 1000자…) | 붙여넣고 나서 잘림 |
| 어디에 뭘 냈는지 추적 안 됨 | 마감 놓침, 중복 지원 |

**그리고 우리만의 제약 하나** — Omya·SMI·무림·TPIL 실명은 **대면에서만** 공개 가능하다. 웹 폼에 붙여넣는 텍스트에 절대 들어가면 안 된다. 이걸 사람의 기억에 맡기지 않고 **스키마 레벨에서 막는 것**이 이번 설계의 핵심이다.

> ⚠️ 자동 제출은 하지 않는다. 제3자 사이트의 폼을 대신 submit하는 것은 스코프 밖이다.
> 이 기능은 **"폼 작성 어시스턴트"** — 질문을 저장하고, 답변을 준비하고, 글자수를 세고, 필드별로 복사 버튼을 준다.

---

## 2. 스키마 (4 테이블 + 1 뷰)

```
app.application_forms          (ENTITY)  ← created_by O
   └─ app.application_form_fields        (CHILD DETAIL) ← created_by X
         └─ app.application_field_answers (LINK)        ← created_by X
                └─ app.answer_library     (ENTITY)      ← created_by O
```

### 테이블별 역할

| 테이블 | 역할 | created_by |
|---|---|---|
| `application_forms` | 지원 프로그램 1건 = 1행. `party_id`로 기존 investor/partner에 연결. URL·마감일·상태·결과 | ✅ |
| `application_form_fields` | 그 폼의 질문들 (순서, 라벨, 타입, **max_length**) | ❌ 자식 상세 |
| `answer_library` | **재사용 답변 라이브러리** (EN/KO 병기, `disclosure_level`) | ✅ |
| `application_field_answers` | 질문 ↔ 답변 바인딩 + 실제 제출 텍스트 + 파생 `char_count` | ❌ 링크 |

**SaaS 규칙 준수**: 전 테이블 `organization_id` + RLS org-scoping. `created_by uuid default auth.uid()`는 **엔티티 테이블에만** (링크·상세 테이블 제외).

### 🔒 핵심 설계: `disclosure_level`

`answer_library.disclosure_level`:
- `public` — 제3자 웹 폼에 붙여넣어도 안전
- `nda_only` — **대면 전용.** UI가 복사를 거부하고 경고를 띄운다

시드에 `partner_names` 답변을 `nda_only`로 넣어뒀다 (Omya / Specialty Minerals / 무림 / TPIL). 나머지 12개는 전부 익명화된 `public` 답변이다 — "a global top-3 filler producer", "a national paper lab" 등.

### 뷰 `app.v_application_field_status`

UI가 바로 렌더할 수 있게 필드별 상태를 계산해 준다:

| `field_state` | 의미 |
|---|---|
| `empty` | 답변 미작성 |
| `over_limit` | `char_count > max_length` → 붙여넣으면 잘림 |
| `nda_blocked` | **NDA 답변이 바인딩됨 → 복사 금지** |
| `ok` | 제출 준비 완료 |

---

## 3. 실행 순서

### STEP 0 — RLS 패턴 확인 (중요, 먼저 실행)

마이그레이션의 RLS 정책은 `(auth.jwt() ->> 'organization_id')::uuid` 패턴을 가정한다. **기존 `app.parties`와 다르면 4개 정책을 고쳐야 한다.**

```sql
SELECT tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'app' AND tablename = 'parties';
```

결과의 `qual` 표현식이 마이그레이션 §5와 다르면 → 마이그레이션 파일의 `USING` / `WITH CHECK`를 그 표현식으로 교체 후 실행.

### STEP 1 — 마이그레이션

Supabase SQL Editor에서 `migration_025_application_forms.sql` 실행.
⚠️ 마이그레이션 번호 충돌 확인: `024`가 최신이면 `025`가 맞다. 이미 `025`가 있으면 파일명과 헤더를 `026`으로 바꿀 것.

### STEP 2 — 시드

`seed_answer_library.sql` 실행. 멱등(`ON CONFLICT ... DO UPDATE`)이라 재실행 안전.

기대 결과: 13개 답변 (public 12 + nda_only 1), CTAN 폼 1건 + 질문 8개, Venture For ClimateTech 폼 1건.

### STEP 3 — 검증

```sql
SELECT party_name, label, max_length, field_state, char_count
FROM app.v_application_field_status
ORDER BY party_name, seq;
```

---

## 4. 다음 세션 UI 스펙 (아직 미구현)

**라우트**: `app/(app)/applications/page.tsx` (목록) + `app/(app)/applications/[formId]/page.tsx` (작성)

### 목록 페이지
- 카드/테이블: 프로그램명, 폼 URL(새 탭), 마감일 D-day, 상태 배지, 완성도(`ok` 필드 / 전체 필드)
- 마감 임박순 정렬. `deadline` 지났고 `status != 'submitted'` → 빨강

### 작성 페이지 (핵심)
필드마다 한 행:

```
[3] Describe your solution                    (required, max 1000)
┌──────────────────────────────────────────────────────────┐
│ FCC grows calcium carbonate in-situ on a cellulose ...    │
└──────────────────────────────────────────────────────────┘
 [답변 라이브러리에서 선택 ▾]        412 / 1000        [복사]
```

구현 포인트:
1. **답변 라이브러리 드롭다운** — 선택 시 `final_text`에 `body_en` 주입. 이후 자유 편집 가능(라이브러리 원본은 안 바뀜).
2. **글자수 카운터** — `max_length` 초과 시 빨강 + 복사 버튼 비활성화.
3. **복사 버튼** — `navigator.clipboard.writeText()`. 성공 시 `is_copied = true` 업데이트 → 진행 상황 추적.
4. 🔒 **NDA 가드** — 바인딩된 답변의 `disclosure_level = 'nda_only'`면 복사 버튼을 **잠그고** 경고: *"This answer contains partner names under NDA. Disclose in person only."*
5. **폼 URL 새 탭 버튼** — 옆에 띄워두고 필드별로 복사→붙여넣기.
6. **Submit 처리** — "Mark as submitted" 버튼 → `status='submitted'`, `submitted_at=now()`.

### 답변 라이브러리 관리 페이지
`app/(app)/applications/library/page.tsx` — CRUD, EN/KO 토글, `disclosure_level` 스위치(빨강 경고), 태그 필터.

### API
- `GET /api/applications` · `GET /api/applications/[formId]` (뷰 조회)
- `PATCH /api/applications/[formId]/fields/[fieldId]` (final_text, answer_id, is_copied)
- `POST /api/applications/[formId]/submit`
- `GET|POST|PATCH /api/answer-library`

RLS가 org 스코핑을 처리하므로 API는 세션의 org만 신뢰하면 된다.

---

## 5. 파일 이동 (① 자동 라우터)

```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"
```

파일명 접두사(`migration_`, `seed_`, `handoff_`)를 보고 알아서 배치한다.

---

## 6. 파일 이동 (② 인라인 폴백 — 터미널에 그대로 붙여넣기)

> 라우터가 없거나 목적지가 다르면 아래 블록을 사용. `$Dest` 경로는 실제 레포 구조에 맞게 한 번만 확인할 것.

```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'

$Files = @(
  @{ Base='migration_025_application_forms'; Ext='.sql'; Dest=(Join-Path $Repo 'supabase\migrations'); Final='migration_025_application_forms.sql' },
  @{ Base='seed_answer_library';             Ext='.sql'; Dest=(Join-Path $Repo 'supabase\seeds');      Final='seed_answer_library.sql' },
  @{ Base='handoff_application_forms';       Ext='.md';  Dest=(Join-Path $Repo 'docs\handoffs');       Final='handoff_application_forms.md' }
)

foreach ($f in $Files) {
  $pattern = $f.Base + '*' + $f.Ext
  $src = Get-ChildItem -Path $Dl -Filter $pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  not found: " + $pattern); continue }

  Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
  [System.IO.Directory]::CreateDirectory($f.Dest) | Out-Null
  $target = Join-Path $f.Dest $f.Final
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item $src.FullName -Force
  Write-Host ("MOVED " + $src.Name + " -> " + $target)
}
Write-Host "Done."
```

---

## 7. 마무리 (커밋 + 배포)

```powershell
cd C:\dev\mbg-project
git status -sb

git add supabase/migrations/migration_025_application_forms.sql
git add supabase/seeds/seed_answer_library.sql
git add docs/handoffs/handoff_application_forms.md

git commit -m "feat(applications): web-form application tracker with NDA-safe answer library

- app.application_forms / application_form_fields / answer_library / application_field_answers
- disclosure_level guard blocks NDA-only text from being copied into third-party forms
- v_application_field_status view computes empty / over_limit / nda_blocked / ok
- seed 13 reusable answers (EN + KO), CTAN and Venture For ClimateTech forms"

git push origin marinebiogroup
```

> **`git push`가 곧 배포다.** Railway가 `marinebiogroup` 브랜치를 감지해 `urm.marinebiogroup.com`에 자동 반영한다. 푸시하지 않으면 웹에 아무것도 올라가지 않는다.

---

## 8. 체크리스트

- [ ] STEP 0: `pg_policies`로 RLS 패턴 확인 → 필요 시 마이그레이션 §5 수정
- [ ] 마이그레이션 번호 `025` 충돌 여부 확인
- [ ] `migration_025_application_forms.sql` 실행 → 4개 테이블 생성 확인
- [ ] `seed_answer_library.sql` 실행 → 13개 답변 확인
- [ ] `v_application_field_status` 조회로 CTAN 8개 필드 확인
- [ ] 파일 이동 (§5 또는 §6)
- [ ] `git status -sb` → commit → `git push origin marinebiogroup`
- [ ] 다음 세션: §4 UI 구현

---

## 9. 남은 논점

1. **`max_length` 확인** — CTAN 폼의 실제 글자수 제한은 추정값이다. 실제 폼을 열어 확인하고 `application_form_fields.max_length`를 갱신할 것.
2. **Austin Hardtech / MassChallenge 폼** — 아직 미등록. 폼 URL과 질문 목록을 확보하면 같은 패턴으로 INSERT.
3. **답변 버전 관리** — 지금은 라이브러리 1행 = 1답변. 프로그램별 변형이 많아지면 `answer_variants` 테이블을 나중에 고려.
4. **파일 업로드 필드** — `field_type='file'`은 스키마만 있고 저장은 미구현. 덱 PDF 링크는 `final_text`에 URL로 넣어 대응.
