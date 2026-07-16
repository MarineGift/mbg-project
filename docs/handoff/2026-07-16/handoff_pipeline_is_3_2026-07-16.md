# Handoff — 파이프라인은 151이 아니라 3입니다 (2026-07-16, 16차)

## 세 가지 다 진행했습니다. 하나는 제 제안을 철회합니다.

---

## 1. 🔴 숫자

| | live FCC Licensing deals |
|---|---|
| **연락할 사람이 있다** | **3** |
| **연락할 사람이 없다** | **148** |

**148개 구성:**

| | 수 |
|---|---|
| Omya 국가법인 | 40 |
| SMI 국가법인 | 43 |
| **SMI 공장·사이트** | **65** |

그리고 그 안에:

- **`Specialty Minerals (Korea)`** — DB가 스스로 기록한 값: **"No direct presence"**
- **`Specialty Minerals (Malaysia)`** — DB 기록: **"Theoretical only; no Malaysia commercial entity"**
- **`Specialty Minerals (Global - PCC)`** — 회사가 아니라 **추상 개념**

> **이 데이터베이스가 스스로 "존재하지 않는다"고 적어둔 법인에 FCC 라이선싱 딜이 열려 있습니다.**

### 그리고 연락 가능한 3개마저

`Omya (HQ)` · `Omya (Korea)` · `Specialty Minerals (HQ)` — **이 셋의 컨택 5명 전부 오늘 아침까지 이름이 없었습니다.**

Edgar Habich · Jaehoon Cho · Sharad Mathur · Raina Wickkiser · Ken Mueller — **오늘 이름을 붙였습니다.**

**오늘 아침 기준으로 연락 가능한 파이프라인은 사실상 0이었습니다.**

### 더 이상한 것

**Mississippi Lime은 컨택이 13명인데 딜이 하나도 없습니다.** enrollment가 Omya와 SMI 두 계열만 훑고 멈췄습니다. 오늘 조사한 태경비케이(satellite, evidence B)·태경산업·GMC·Zantat·奥多摩(일본 제지 PCC 9할)·丸尾·Imerys USA·Huber — **딜 151개 중에 하나도 없습니다.**

### 프레이밍

> **148개는 딜이 아닙니다. 파이프라인 옷을 입은 타깃 리스트입니다.**

컨택 0, 생성 후 활동 0, `value_amount` null인 행은 **대시보드 숫자를 올리는 행**입니다.

**148개를 제가 지우지 않았습니다.** 이건 당신 파이프라인에 대한 사업 판단이고 제가 내릴 게 아닙니다. `scan_fcc_campaign_triage`가 결정을 싸게 만들도록 버킷으로 나눕니다:

| 버킷 | |
|---|---|
| **A_KEEP** | 연락 가능 — 진짜 딜 |
| **B_RETIRE** | **DB가 존재하지 않는다고 적은 법인** |
| **C_RETIRE** | 공장·사이트 행 — 라이선싱 상대가 될 수 없음 |
| **D_RETIRE** | 추상 (`Global - PCC`) |
| **E_DECIDE** | **진짜 국가법인인데 아직 연락할 사람이 없음** ← 여기가 진짜 백로그. `Omya (USA)`(evidence A)가 여기 있습니다 |

**E가 핵심 질문입니다: 연락할 사람이 없는 타깃이 "딜"이어야 합니까, 아니면 그냥 "타깃"입니까?**

---

## 2. ✅ `fa423be1` 판단 — 유지합니다. 병합 안 합니다

**블록 5가 아무도 답 안 해도 결론을 냈습니다.** 148개의 이름 규칙이 완벽하게 규칙적입니다:

```
Specialty Minerals (<Country>)            43행   국가법인
Specialty Minerals (<Country> - <Site>)   65행   공장·사무소
```

**`Specialty Minerals (USA - Regional HQ)`는 두 번째 패턴에 정확히 맞습니다.** `SMI (Japan)`과 `SMI FMT (Japan - Shiraoi)`를 나눈 것과 같은 방식으로 정리된 **사이트 행**입니다.

**108행에 걸쳐 일관된 컨벤션입니다.** 병합했으면 **이름이 비슷해 보인다는 이유로 잘 작동하는 모델을 깨뜨릴 뻔했습니다.**

조심한 게 옳았습니다.

### 그리고 규칙을 뽑아냈습니다

**중복과 형제를 구별하는 법** — keeper의 notes에 적어뒀습니다:

| | |
|---|---|
| **형제** | 두 이름 규칙 중 하나를 지킴. 아무리 비슷해 보여도 정당 |
| **중복** | **둘 다 안 지킴** + `source = filler_gap_*` → gap 파일이 못 보는 베이스 행 위에 얹은 것 |

- `Specialty Minerals Inc.` → 둘 다 실패 + gap → **제거** ✅
- `Specialty Minerals (USA - Regional HQ)` → 통과 → **유지** ✅
- `Omya Korea Inc.` vs `Omya (Korea)` → 같은 테스트로 잡힙니다

---

## 3. ❌ `v_email_do_not_send` — 제 제안을 철회합니다

리포에서 찾아 읽었습니다. **제가 틀렸습니다.**

뷰 자체 헤더:

> `app.v_email_do_not_send` is a **COLD-OUTREACH suppression list**, not a global one.

입력이 전부 **이벤트**입니다:
- `app.email_send_outcomes` — `bounce_hard`, `unsubscribe_request`, `reply_positive`, `reply_neutral`, `rejected_*`, `next_action = suppress`, `resend_later` 쿨다운
- `app.application_forms` — `submitted` / `decided`

키는 `email_lower` + `party_id`, 컬럼에 `is_follow_up` / `blocks_direct`, **`organization_id`는 일부러 없습니다** (다운스트림에 org 필터 걸면 42703).

**이 뷰가 답하는 질문은 "누가 이미 반응했으니 콜드메일을 그만 보낼 것인가"입니다.**

- 제네릭 인박스 → **이벤트 없음**
- 인박스 공유하는 중복 party → **이벤트 없음**
- 컨택 없는 법인 → **이벤트 없음**

**억제 목록에 들어갈 게 아닙니다.** 억지로 붙이면 뷰의 의미가 깨집니다.

### 진짜 자리는 enroll입니다

**151개 딜이 결함의 위치를 알려줍니다.**

`entity_enrollment`가 보이는 Omya·SMI 행 전부에 딜을 찍었습니다 — 국가 껍데기, 공장 65개, DB가 없다고 한 법인 3개.

**발송 시점에 뭘 해도 이건 못 고칩니다. 나쁜 행들은 발송까지 가지도 않습니다 — 컨택이 없으니까요. 숫자만 부풀립니다.**

필요한 건 **enroll 전 가드**입니다:

```
* party_name에 ' - ' 있으면 skip           (공장·사이트)
* market_role이 theoretical/absent이면 skip
* live contact 0이면 skip, 또는 딜 파이프라인이 아니라 TARGET 리스트로
* 생성 전에 website host + country로 중복 제거
```

**마지막 하나가 제 Omya Korea 중복, 태경 2개, Specialty Minerals Inc.를 한 번에 막았을 겁니다.**

**`entity_enrollment` 소스를 보내주시면 추측 대신 읽고 쓰겠습니다.** 리포에서 `src/lib` 아래 grep 해보시면 나올 겁니다.

---

## 4. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'scan_fcc_campaign_triage_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'scan_fcc_campaign_triage_2026-07-16.sql' },
  @{ Pattern = 'fix_smi_regional_hq_keep_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'fix_smi_regional_hq_keep_2026-07-16.sql' },
  @{ Pattern = 'handoff_pipeline_is_3_2026-07-16*.md';      Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_pipeline_is_3_2026-07-16.md' }
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

**실행**

1. `fix_smi_regional_hq_keep` 전체 (2개 문) — 판단 기록
2. `scan_fcc_campaign_triage` **블록 1** → 버킷별 숫자. **여기서 148을 어떻게 쪼갤지 결정됩니다**
3. 블록 2·3·4 → **블록 4가 아플 겁니다** (딜 151개에 오늘 조사한 회사가 하나도 없음)
4. 버킷 결정 주시면 retire 파일을 쓰겠습니다

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_fcc_campaign_triage_2026-07-16.sql sql/fix_smi_regional_hq_keep_2026-07-16.sql docs/handoff/2026-07-16/handoff_pipeline_is_3_2026-07-16.md
git commit -m "scan: FCC campaign is 3 reachable deals vs 148 with nobody to call (incl. entities the DB itself records as non-existent); decide: keep SMI Regional HQ - roster naming convention holds across 108 rows; withdraw the v_email_do_not_send proposal - it is an event-based suppression list, the defect is at enrolment"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 하루가 여기로 수렴합니다

아침에 제가 **"KR filler 0건"**이라고 잘못 말했습니다. 그게 seed를 낳고, seed가 중복 3개를 낳았습니다.

그리고 하루 종일 발견한 게 전부 같은 한 줄로 모입니다:

> **데이터 오류는 데이터에 머물지 않습니다. 자동화가 그걸 먹고 숫자와 행동으로 바꿉니다.**

```
중복 행         → entity_enrollment → 유령 딜 → 파이프라인 숫자 151
공장 행 65개    → entity_enrollment → 유령 딜
"존재 안 함" 3개 → entity_enrollment → 유령 딜
잘못된 연결      → (Saica)          → 경쟁사가 우리 제안을 읽음
이름 없는 컨택   → 시퀀스 개인화 불가 → CRM에 있으나 사업엔 없음
```

**그리고 다섯 개 전부 에러를 안 냅니다.**

## 6. 남은 것

1. **버킷 결정** — 148개를 어디까지 retire할지
2. **`entity_enrollment` 소스** — enroll 전 가드를 쓰려면 필요합니다
3. **컨택 확보** — 오늘의 진짜 결론입니다. 데이터는 종일 고쳤는데, **filler 타깃 대부분에 연락할 사람이 없습니다.** Omya (USA)는 evidence A인데 컨택 0입니다
