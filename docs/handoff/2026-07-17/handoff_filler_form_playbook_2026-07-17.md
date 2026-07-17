# Handoff — filler 문의 폼 플레이북 설계 (2026-07-17)

## 0. ⚠️ 먼저: 어제 커밋이 안 됐습니다

**날짜가 바뀌어서** 무버가 handoff를 `docs\handoff\2026-07-17\`로 보냈는데 제 `git add`가 `2026-07-16`을 가리켰습니다 → `fatal: pathspec ... did not match any files` → **아무것도 커밋 안 됨.**

미추적 파일 5개가 남아 있고, **그중 하나는 철회된 파일입니다:**

```powershell
cd C:\dev\mbg-project

# 1) 철회된 파일 삭제 - 커밋된 적 없으므로 그냥 지우면 됩니다
#    "태경비케이 = FCC 1순위, 그룹 단위로 시퀀스" 라고 쓰인 파일입니다.
Remove-Item sql\enrich_taekyung_bk_fcc_fit_2026-07-16.sql -Force

# 2) 나머지 커밋 (경로 수정됨)
git add sql/fix_supply_link_taekyung_enrich_2026-07-16.sql `
        sql/scan_form_system_state_2026-07-16.sql `
        docs/handoff/2026-07-16/handoff_supply_links_2026-07-16.md `
        docs/handoff/2026-07-17/
git status -sb
git commit -m "scan: form system state - migration 027 already generalized the form machinery to any form-based party (mills included), so filler contact_inquiry needs data not schema; fix: supply link brought up to the omya_smi_batch1 convention; retract enrich_taekyung_bk (adverse party - EP4579034 co-filer)"
git push origin marinebiogroup
```

> `enrich_taekyung_bk_fcc_fit`은 **실행하지도, 커밋하지도 마세요.** `fix_taekyung_adverse_party_2026-07-16.sql`이 철회 사유를 전부 기록합니다.

---

## 1. ✅ 게이트는 깨끗합니다

```
Kleannara (깨끗한나라)          type 2   form_url: null   form_rows: 0
Taekyung BK Co. (태경비케이)     type 3   form_url: null   form_rows: 0
Taekyung Industrial (태경산업)   type 3   form_url: null   form_rows: 0
```

**발사 준비된 게 없습니다.**

## 2. 🔴 그런데 깨끗한나라는 제지사입니다 — 그리고 제지사는 97.7%가 컨택을 갖고 있습니다

| type | parties | form_url | **컨택 보유** |
|---|---|---|---|
| 1 investor | 547 | 33 | 165 |
| **2 제지사** | **888** | 15 | **868 (97.7%)** |
| **3 filler** | **242** | **0** | **4 (1.7%)** |

**태경은 사고로 안전했습니다** — filler에 컨택이 없어서. **깨끗한나라에는 그런 사고가 없습니다.**

`scan_kleannara_reach_2026-07-17.sql` **블록 1을 먼저 돌려주세요.** 이메일이 나오면 **분쟁 상대가 97.7% 컨택된 로스터 안에, 시퀀서가 겨누는 방향에 앉아 있는 겁니다.**

### 그리고 플래그를 넣을 자리가 없습니다

`fix_taekyung_adverse_party`는 `filler_supplier_profile.extra_data.adverse_party`에 씁니다. **깨끗한나라는 제지사라 `filler_supplier_profile`이 없습니다.**

**집을 잘못 잡았습니다.** 027이 이미 같은 질문을 해결했고 그 논리가 그대로 적용됩니다:

> `app.parties`: `preferred_contact_method` + `contact_form_url`
> *(**common attribute of any party** → lives on parties itself, **NOT** on investor_profile / paper_mill_profile)*

**적대적 상대 여부도 똑같은 종류입니다. 어떤 party든 적대적일 수 있습니다.** `app.parties`에 있어야 하고, **enroll 단계와 폼 제출 단계가 둘 다 읽어야 합니다.**

블록 4가 `app.parties`에 `extra_data jsonb`가 있는지 봅니다 — **있으면 마이그레이션 없이 끝납니다.** 어제 `migration_028`을 쓸 뻔한 실수를 반복하지 않으려고 먼저 봅니다.

---

## 3. 📋 filler 문의 폼 플레이북 — 설계

### 3-1. 현황

- **`contact_inquiry` 폼: 0개.** 027이 만든 기계가 **한 번도 안 쓰였습니다**
- 전체 폼 13개 — 전부 investor(type 1)와 type 6
- **filler 242곳 중 `contact_form_url`이 채워진 곳: 0**
- canonical_key **74개** — 전부 investor 지향. **미매핑 필드 70개**
- answer_library **79개** — `investor` 태그 **54개(68%)**

**`licensing` / `filler` 태그 네임스페이스는 비어 있습니다.**

### 3-2. 재사용 가능한 기존 키 — 4개뿐

| canonical_key | 비고 |
|---|---|
| `company_legal_name` | short, 80자 |
| `brand_name` | short, 80자 |
| `company_one_liner` | **7개 폼이 이미 사용 중**, 200~300자 |
| `employee_count` | |

`capital_seeking` · `valuation_cap` · `use_of_funds` · `burn_rate` · `cap_table` · `exit_strategy` · `prior_investors` — **investor 전용. filler 폼에 쓰면 안 됩니다.**

### 3-3. 제안하는 canonical_key — filler 문의 폼

충전제 제조사 홈페이지 문의 폼의 전형적 구조입니다. **블록 3 결과(74개 키 전체)와 대조해 충돌을 확인한 뒤 확정합니다.**

**A. 신원 — 대부분 재사용 또는 신규 단순 필드**

| canonical_key | 전형적 라벨 | field_type | 비고 |
|---|---|---|---|
| `company_legal_name` | Company / 회사명 | text | ♻️ 재사용 |
| `contact_person_name` | Name / 담당자명 | text | 신규 |
| `contact_email` | Email | text | 신규 |
| `contact_phone` | Phone / 전화 | text | 신규, 선택 |
| `contact_country` | Country / 국가 | dropdown | 신규 |
| `contact_job_title` | Job title / 직책 | text | 신규 |

**B. 분류 — 드롭다운. 여기가 관건입니다**

| canonical_key | 전형적 라벨 | 비고 |
|---|---|---|
| `inquiry_type` | Subject / 문의 유형 | **드롭다운에 "Partnership" / "R&D" / "Technology" 선택지가 있는지가 결정적.** 없고 "Sales"만 있으면 그 폼은 영업 큐로 갑니다 — **폼 자체를 쓰면 안 되는 신호** |
| `industry_segment` | Industry / Application | Paper / Pulp & Paper 선택 |
| `product_interest` | Product | PCC / GCC / Specialty |

**C. 본문 — 진짜 콘텐츠. variant 시스템이 여기서 값을 합니다**

| canonical_key | variant | target_length | 용도 |
|---|---|---|---|
| `fcc_one_liner` | `short` | **~200** | Message 필드가 짧은 폼 |
| `fcc_licensing_intro` | `medium` | **~900** | 표준 문의 폼 |
| `fcc_licensing_intro` | `long` | **~2000** | 제한 없는 폼. **`long` variant의 첫 사용처** |
| `nda_request_close` | `short` | ~150 | **모든 본문의 마무리 문단** |

> **`answer_library.variant` + `target_length`가 필드의 `max_length`에 맞춰 자동 선택합니다.** 이게 027이 만들어 둔 값어치고, 여기서 처음 제대로 쓰입니다.

### 3-4. 🔴 공개 규율 — investor보다 엄격해야 합니다

| | investor | **filler supplier** |
|---|---|---|
| 읽는 사람 | 잠재 **투자자** | **잠재 라이선시 _그리고_ 잠재 침해자** |

**태경이 문자 그대로 둘 다입니다.** 그리고 폼 제출은 **의도적·귀속 가능·수신자 보관**입니다.

**filler answer set 규칙:**

```
① disclosure_level = 'public' 전용.
   nda_only 답변은 contact_inquiry 필드에 절대 바인딩 금지.
   (79개 중 nda 태그 7개 존재 — 이것들이 새면 안 됩니다)

② 로열티 수치 금지.
   $15/ton은 라이선싱 조건입니다. 협상 전에 잠재 라이선시에게
   공개하면 협상 자체를 잃습니다.

③ 공정 파라미터·배합·수율 금지. 능력과 결과만.
   "밀에게 무엇을 해주는가"는 되고 "어떻게"는 안 됩니다.

④ 계약 중인 밀 이름 금지.
   investor 라이브러리가 이미 배운 교훈:
   'Marinepad' / '500,000 USD' / 'executive approval' / '9,000-ton'+payee

⑤ 관계사·특허 보유 구조 금지.
   EP4579034 분쟁 중에 IP 소유 구조를 경쟁사 폼에 적는 건
   그쪽 대리인에게 지도를 주는 겁니다.

⑥ 마무리는 명시적 NDA 요청.
   진짜 대화는 웹 폼이 아니라 계약 아래에서.
```

**`nda_request_close`가 선택이 아니라 필수인 이유입니다.** 폼은 문을 여는 도구지 설명하는 도구가 아닙니다.

### 3-5. 🚧 제출 전 게이트

```
skip  adverse_party = DO NOT CONTACT        ← 태경 ×2, 깨끗한나라
skip  party_name ~ ' - '                    ← 공장·사이트
skip  fcc_fit.verdict in ('no','adverse')   ← Thiele
skip  market_role ~ 'theoretical|no direct presence|holding company'
skip  inquiry_type 드롭다운에 기술/제휴 선택지 없음  ← 영업 큐로 감
```

**`v_email_do_not_send`는 이 게이트가 될 수 없습니다** — 이벤트 기반이라 한 번도 접촉 안 한 상대는 들어 있지 않습니다. **어제 확인한 그대로입니다.**

---

## 4. 다음 단계

**제가 답변 본문을 쓰기 전에 필요한 것 — 순서대로:**

1. **`scan_kleannara_reach` 블록 1·4** ← 가장 급합니다. 블록 4가 플래그 집을 정합니다
2. **canonical_key 74개 전체 목록** — 제안한 키와 충돌하는지. 어제 `migration_028` 실수를 반복하지 않으려면 필요합니다
3. **`nda` 태그 7개 + `ip` 태그 8개 본문** — 무엇이 이미 nda_only로 분류돼 있는지 알아야 ①번 규칙을 지킵니다

**2·3번은 한 줄씩입니다:**

```sql
select canonical_key, count(*) from app.application_form_fields
where canonical_key is not null group by 1 order by 1;
```

```sql
select answer_key, variant, disclosure_level, tags, title, left(body_en, 120) as en_head
from app.answer_library
where tags && ARRAY['nda','ip','royalty','patent']
order by answer_key, variant;
```

**그다음 `seed_filler_form_answers_2026-07-17.sql`을 씁니다.**

---

## 5. 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'scan_kleannara_reach_2026-07-17*.sql';       Dest = (Join-Path $repo 'sql'); Name = 'scan_kleannara_reach_2026-07-17.sql' },
  @{ Pattern = 'handoff_filler_form_playbook_2026-07-17*.md'; Dest = (Join-Path $repo 'docs\handoff\2026-07-17'); Name = 'handoff_filler_form_playbook_2026-07-17.md' }
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

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 6. 왜 이 방향이 맞는가

**filler 242곳 중 컨택은 4곳(1.7%)입니다. 그런데 거의 전부가 문의 폼을 갖고 있습니다.**

| | 콜드메일 | **폼 제출** |
|---|---|---|
| 주소 | **필요 — 4곳뿐** | **불필요** |
| DKIM/DMARC/PTR | **전부 문제** | **무관** |
| 성격 | 초대받지 않음 | **초대됨** |

**그리고 027이 처음부터 이걸 겨눴습니다** — *"any party that communicates via a web form (mills included)"*, *"hundreds of forms share one answer library"*. **investor 49곳용 구조가 아니었습니다. 기계는 지어져 있고 놀고 있습니다.**

**남은 건 답변을 쓰는 것 — 그리고 태경·깨끗한나라에는 절대 내지 않는 것입니다.**
