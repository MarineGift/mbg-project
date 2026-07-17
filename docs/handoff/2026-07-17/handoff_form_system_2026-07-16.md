# Handoff — 폼 시스템은 이미 있습니다. 필요한 건 데이터입니다 (2026-07-16, 19차)

## 1. investor 폼 시스템을 먼저 읽었습니다 — 그리고 이미 일반화돼 있습니다

`migration_027_contact_method_variants.sql` 헤더 원문:

> Generalizes the application-form machinery from investor-only to **any party that communicates via a web form (mills included)**

**025 → 026 → 027로 이미 완성돼 있습니다:**

| 조각 | 하는 일 |
|---|---|
| `parties.contact_form_url`<br>`parties.preferred_contact_method` | **폼 기반 party 표시.** 배지 로직이 **이 두 컬럼만** 읽습니다 (조인 없음). partial index로 "폼 기반 party 전부 보여줘" 필터가 빠릅니다.<br>*"common attribute of any party → lives on parties itself, NOT on investor_profile / paper_mill_profile"* |
| `application_forms.form_type = 'contact_inquiry'` | **새 테이블이 아니라 form_type.** 025/026 기계 전체를 그대로 재사용 — fields, answer binding, char counts, nda_blocked guard |
| `answer_library.variant` + `target_length` | **answer_key 하나가 short/medium/long 본문을 갖고, 필드의 `max_length`에 맞춰 자동 선택** |
| `application_form_fields.canonical_key` | **각 폼 질문 → 표준 질문 카탈로그 매핑.**<br>*"so hundreds of forms share one answer library"* |
| `application_forms.submission_method` | `email` / `web_form` / `portal` / `email_then_form` + `submit_email` + `attachments[]` + `login_required` |
| `application_form_fields.selector`<br>`selector_type` / `input_kind` | **Playwright 셀렉터 메타데이터** — 폼 자동 입력용 |

> **"수백 개 폼이 answer library 하나를 공유한다" — 그 수백 개가 filler 176곳입니다.**

**스키마는 손댈 게 없습니다.**

### 제가 `migration_028`을 쓸 뻔했습니다

`form_type`에 라이선싱 문의 타입을 추가하려던 참이었습니다. **027이 몇 주 전에 `'contact_inquiry'`로 넣었습니다.**

**오늘 네 번째로 같은 실수(*"내가 모른다 = 없다"*)를 할 뻔했고, 이번엔 읽어서 막았습니다.**

## 2. 🎯 그리고 이게 오늘의 병목을 정확히 칩니다

**filler 176곳 중 컨택이 있는 곳은 4곳입니다. 그런데 거의 전부가 홈페이지에 문의 폼을 갖고 있습니다.**

| | 콜드메일 | 폼 제출 |
|---|---|---|
| 주소가 필요한가 | **필요** (176곳 중 4곳만 있음) | **불필요** |
| DKIM/DMARC/PTR | **전부 문제 상태** | **무관** |
| 성격 | 초대받지 않은 접촉 | **초대된 접촉** |
| 도달 | 스팸함 | **담당자 큐** |

**폼이 곧 컨택 채널입니다.** 그리고 `v_email_do_not_send`가 이미 `application_forms`를 읽습니다 — **폼을 내면 그 party의 콜드메일이 자동 억제됩니다.** 배선이 이미 돼 있습니다.

## 3. `scan_form_system_state_2026-07-16.sql` → `sql\`

**READ-ONLY.** 쓰기 전에 사실을 봅니다 — 오늘 가짜 인물 14명을 막은 그 규칙입니다.

| 블록 | |
|---|---|
| 1 | form_type × party_type × submission_method × status |
| 2 | **answer_library 전체** — 키·variant·disclosure·tags·본문 길이. **filler 키가 충돌하면 안 되고, 진짜 audience-neutral한 건 재사용해야 합니다** |
| 3 | **canonical_key 카탈로그** — 이미 있는 표준 질문과 각 `max_length` 범위 |
| 4 | party_type별 `contact_form_url` 채워진 비율 |
| 5 | **filler 갭 리스트** — 컨택 없고 adverse 아닌 곳. 이 작업의 대상 |
| 6 | **🔴 게이트 점검** — adverse party가 이미 form URL이나 form 행을 갖고 있나 |

## 4. 🔴 이 시스템에 아직 없는 것 — 그리고 오늘이 그걸 증명했습니다

> **웹 폼은 접촉이고, 적대적 상대에게의 접촉은 공개(disclosure)입니다.**

**태경산업은 깨끗한나라와 EP4579034(flexible calcium carbonate)를 공동 출원했습니다.**

**그들의 문의 폼에 FCC 기술 설명을 넣는 건 — 분쟁 상대에게, 그들의 기록으로, 타임스탬프를 찍어, 자발적으로 서면 공개하는 겁니다.**

**콜드메일보다 나쁩니다.** 폼 제출은 의도적이고, 귀속 가능하고, **수신자가 보관합니다.**

### investor 라이브러리는 이 교훈의 절반을 이미 배웠습니다

`20260714170000_scan_nda_sensitive_answers.sql`가 공개 폼에 새는 텍스트를 사냥합니다:

```
'Marinepad'           - KR 특허를 보유한 관계사 이름
'500,000 USD'         - 이연 양수 대가
'executive approval'  - 상대방 딜 단계
'9,000-ton' + payee   - named counterparty를 계약에 연결
```

### 그런데 filler 상대는 investor 상대와 다릅니다

| | investor | **filler supplier** |
|---|---|---|
| 읽는 사람은 | 잠재 **투자자** | **잠재 라이선시 _그리고_ 잠재 침해자** |

**태경이 문자 그대로 둘 다입니다.**

**그래서 filler answer set은 investor보다 "똑같이 엄격"이 아니라 "더 엄격"해야 합니다:**

```
* disclosure_level = public 전용. nda_only 답변은 contact_inquiry 필드에
  절대 바인딩되면 안 됨
* 공정 파라미터·배합·계약 중인 밀 이름 금지
* 로열티 수치·라운드 조건 금지
* 능력과 결과만. 밀에게 무엇을 해주는가는 되고, 어떻게는 안 됨
* 마무리는 명시적 NDA 요청 — 진짜 대화는 웹 폼이 아니라 계약 아래에서
```

**블록 6이 이미 발사 준비된 게 있는지 봅니다.** adverse party에 `contact_form_url`이나 form 행이 있으면 **살아있는 공개 리스크**입니다.

## 5. 다음 단계 — 블록 2·3 결과가 있어야 씁니다

**canonical_key 카탈로그와 answer_library 현황을 봐야 filler 답변을 짤 수 있습니다.** 지금 짜면 키가 충돌하거나, 이미 있는 질문을 중복으로 만들거나, 재사용 가능한 답변을 놓칩니다.

**제가 제안할 filler 문의 폼 canonical 질문** (블록 3 결과와 대조 후 확정):

| canonical_key | 전형적 라벨 | 비고 |
|---|---|---|
| `company_name` | Company / 회사명 | 재사용 가능성 높음 |
| `contact_person` | Name / 담당자 | 〃 |
| `contact_email` | Email | 〃 |
| `country` | Country / 지역 | 〃 |
| `industry_segment` | Industry / Application | 드롭다운 많음 |
| `inquiry_type` | Subject / 문의 유형 | 드롭다운 — **"Partnership" / "R&D" 선택지 존재 여부가 관건** |
| `product_interest` | Product / 관심 제품 | PCC / GCC 선택 |
| **`fcc_one_liner`** | Message (짧은 폼) | **short variant, ~200자** |
| **`fcc_licensing_intro`** | Message (긴 폼) | **medium/long variant, 1000~2000자** |
| `nda_request` | — | 마무리 문단, 모든 variant에 포함 |

**`variant` 시스템이 여기서 값을 합니다** — 어떤 폼은 Message가 200자 제한이고 어떤 건 무제한입니다. `target_length` 대 `max_length`로 자동 선택됩니다.

## 6. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'scan_form_system_state_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'scan_form_system_state_2026-07-16.sql' },
  @{ Pattern = 'handoff_form_system_2026-07-16*.md';     Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_form_system_2026-07-16.md' }
)

foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  no match: " + $m.Pattern); continue }
  Unblock-File -Path $src.FullName
  [System.IO.Directory]::CreateDirectory($m.Dest) | Out-Null
  $target = [System.IO.Path]::Combine($m.Dest, $m.Name)
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ("OK    " + $src.Name + "  ->  " + $target)
}
Write-Host "DONE"
```

**실행: 블록 6을 먼저.** adverse party에 발사 준비된 게 있는지가 가장 급합니다. 그다음 2·3 — 그게 answer set 설계의 입력입니다.

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_form_system_state_2026-07-16.sql docs/handoff/2026-07-16/handoff_form_system_2026-07-16.md
git commit -m "scan: form system state before seeding filler contact_inquiry data - migration 027 already generalized the machinery to any form-based party incl. mills, so no schema work is needed; filler answer set must be stricter than the investor one because a filler supplier is a potential licensee AND a potential infringer"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 7. 왜 이 방향이 오늘의 결론과 맞물리는가

오늘 종일 나온 결론은 **"병목은 데이터가 아니라 컨택"**이었습니다. 176곳 중 4곳.

**폼은 그 4를 176으로 바꿀 수 있는 유일한 채널입니다.** 이메일 주소 없이 도달하고, 발신 도메인 상태와 무관하고, 스팸이 아닙니다.

**그리고 시스템이 이미 그걸 위해 지어져 있었습니다.** 027이 "mills included"라고 명시하고, canonical_key로 "hundreds of forms, one answer library"를 설계해뒀습니다. **investor 49곳용으로 만든 게 아니라 처음부터 이 규모를 겨냥한 구조입니다.**

**남은 건 답변을 쓰는 것 — 그리고 태경·깨끗한나라에는 절대 내지 않는 것입니다.**
