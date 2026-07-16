# Handoff — 경쟁사에게 메일이 갈 뻔했습니다 (2026-07-16, 11차)

## 0. 블록 6 결과 — 41행 전부 제네릭이었습니다

`info@` 38개, `marketing@` 2개, `office@` 2개. `contact_type_id`는 전부 `2`.

**결론 먼저: 이 41개에 사람 이름을 붙이면 안 됩니다.** `full_name`을 `null`로 두는 게 정직합니다 — **실제로 사람이 아니니까요.** 해결은 컨택 쪽이 아니라 **시퀀스 쪽**입니다: 제네릭 주소를 enroll에서 제외해야 합니다. `Dear null`을 보내느니 안 보내는 게 낫습니다.

그런데 이 41행을 보다가 **진짜 버그**가 나왔습니다.

---

## 1. 🚨 Saica에 경쟁사 이메일이 붙어 있습니다

```
Saica Paper El Burgo de Ebro Zaragoza  →  info@burgogroup.com
```

| | |
|---|---|
| **Saica** | Sociedad Anonima Industrias Celulosa Aragonesa. **스페인** 사라고사. **saica.com**. 직원 1만+ |
| **Burgo Group** | **이탈리아** 회사. **burgogroup.com** |
| **El Burgo de Ebro** | 사라고사주의 **인구 2,432명 지자체**. 회사가 아니라 **지명** |

**문자열 매칭이 스페인 지명 "Burgo"를 보고 이탈리아 경쟁사의 받은편지함을 붙였습니다.**

### 이게 왜 심각한가

**시퀀스가 이 행을 enroll했다면, Saica에게 보낼 제안이 Burgo에게 갔습니다.**

컨택이 없는 것보다 나쁩니다. 없으면 아무 일도 안 일어나지만, 이건 **경쟁사에게 우리 접근 방식을 그대로 보여주는** 일입니다.

### 대체 주소를 추측하지 않았습니다

`fix_saica_wrong_contact_2026-07-16.sql`은 **틀린 컨택을 soft-delete하고 이유를 기록만** 합니다.

틀린 이메일을 그럴듯한 추측으로 바꾸면 **문제를 고치는 게 아니라 숨기는 겁니다.** saica.com에서 실제 주소를 찾아 의도적으로 넣으세요. `deleted_at`을 지우면 복구됩니다.

### 덤 — Saica 자체가 중요한 곳이었습니다

확인차 saica.com을 읽다가 알게 된 것:

- **초지기 3대, 합산 연산 131만 톤** (PM8 36만 / PM9 43만 / PM10 52만). Saica 최대 거점입니다
- 그룹 **R&D&I 센터가 바로 이 부지에** 있습니다 (2023년, 4,000㎡)
- **★ Saica는 저평량(grammage reduction)을 회사 정체성으로 내겁니다.** 자사 설명: **MP9는 75 g/m2까지 생산 가능한 세계 최초의 기계**

**평량 저감 = FCC의 펄프 저감 서사와 정확히 같은 축입니다.** 기술 대화의 출발점이 이미 공유돼 있고, 그룹 R&D 센터가 현장에 있습니다. 파일럿 논의에 이보다 좋은 조건이 드뭅니다.

이름이 오염된 채로 방치돼 있던 행이 **알고 보니 유럽 최상위 후보 중 하나**였습니다.

---

## 2. `scan_contact_email_domain_mismatch_2026-07-16.sql` → `sql\`

**READ-ONLY.** 두 가지를 봅니다.

### 문제 1 — 다른 오염이 더 있나

블록 1이 **컨택 이메일 도메인 vs party 웹사이트 도메인**을 대조합니다. 일치해야 정상이고, 어긋나면 정당한 이유(그룹 공용 인박스)이거나 **버그**입니다. 하나가 오염됐으면 더 있을 겁니다.

블록 5는 **문자열 매칭이 건드렸을 만한 다른 이름**들을 거칠게 훑습니다 (`palm`, `crown`, `century`, `progroup`, `jass`, `waraq` — 전부 일반 단어와 겹치는 브랜드입니다).

### 문제 2 — 같은 인박스에 중복 발송

41행을 보면 이렇습니다:

| 이메일 | 붙어 있는 party 수 |
|---|---|
| `info@nordic-paper.com` | **5** |
| `info@burgogroup.com` | **5** (진짜 Burgo 4 + 오염된 Saica 1) |
| `info@sodra.com` | **4** |
| `info@ence.es` | **4** |
| `info@arcticpaper.com` | **3** |

**시퀀스가 Södra 4개 밀을 전부 enroll하면, `info@sodra.com` 한 곳에 거의 똑같은 콜드메일이 4통 갑니다.** 같은 시간대에.

**이건 교과서적인 스팸 패턴입니다.** 그리고 이 프로젝트는 이미 **DKIM 없음 / DMARC p=none / PTR 불일치** 상태입니다. 스팸으로 보일 여유가 **전혀 없습니다.**

블록 3이 실제 위험을 봅니다 — **라이브 시퀀스에 enroll된 party 중** 인박스를 공유하는 것들. 여기서 행이 나오면 **지금 발송이 임박한 상태**입니다.

> 블록 3은 `app.email_sequence_enrollments`에 `party_id`가 있다고 가정합니다. 없으면 에러 나는데, **마지막 블록이라 1·2는 이미 돌았습니다.** 스키마 알려주시면 다시 짜겠습니다.

### 블록 4 — Omya

filler 행의 이메일 전수. **`Omya (HQ)`와 `Omya (Korea)`가 이름 없이 앉아 있습니다.** Omya Korea는 공정위 의결로 확정된 **KR 1순위 타깃**입니다.

---

## 3. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_saica_wrong_contact_2026-07-16*.sql';              Dest = (Join-Path $repo 'sql'); Name = 'fix_saica_wrong_contact_2026-07-16.sql' },
  @{ Pattern = 'scan_contact_email_domain_mismatch_2026-07-16*.sql';   Dest = (Join-Path $repo 'sql'); Name = 'scan_contact_email_domain_mismatch_2026-07-16.sql' },
  @{ Pattern = 'handoff_saica_contamination_2026-07-16*.md';           Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_saica_contamination_2026-07-16.md' }
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

**실행 순서**

1. `fix_saica_wrong_contact` **블록 0 (pre-flight)** 먼저 → `info@burgogroup.com` 1행 확인. **다르면 멈추세요**
2. 블록 1~3 실행 → 검증으로 `website = saica.com`, `live_contacts = 0` 확인
3. `scan_contact_email_domain_mismatch` **블록 1과 3을 먼저** — 1은 다른 오염, 3은 발송 임박 위험
4. 블록 2·4·5

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_saica_wrong_contact_2026-07-16.sql sql/scan_contact_email_domain_mismatch_2026-07-16.sql docs/handoff/2026-07-16/handoff_saica_contamination_2026-07-16.md
git commit -m "fix: Saica mill carried info@burgogroup.com (Italian competitor) via a string match on the Spanish place name El Burgo de Ebro - contact soft-deleted, no replacement guessed, mill enriched (1.31Mt/yr, grammage-reduction leader = FCC-adjacent); scan: email/website domain mismatch + shared-inbox send risk"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 4. 제네릭 인박스 처리 — 제 권고

**41행에 이름을 붙이지 마세요.** 대신 시퀀스가 제외하게 하는 게 맞습니다.

메모리상 `v_email_do_not_send`가 `get_due_enrollments()`에 이미 물려 있습니다. 제네릭 주소 조건을 거기 얹는 게 자연스러워 보입니다:

```sql
-- 개념만 - 실제 뷰 정의를 보고 짜야 합니다
split_part(email,'@',1) ~ '^(info|sales|contact|office|marketing|...)$'
```

**뷰 정의를 보내주시면 패치를 만들겠습니다.** 지금 추측으로 건드리지 않겠습니다 — 발송 로직이라 틀리면 조용히 안 나가거나 잘못 나갑니다.

## 5. 오늘 여섯 번째 유형입니다

| 유형 | 사례 | 조용히 실패? |
|---|---|---|
| 낡은 마케팅 | MLC, Zantat, 白石 | ✅ |
| 관련성 혼동 | Thiele | ✅ |
| 구조적 중복 | SMI/MTI, Omya Korea, Taekyung ×2 | ✅ |
| 평가 누락 | JP top 5 | ✅ |
| 접근 불가 | 이름 없는 컨택 100+ | ✅ |
| **잘못된 연결** | **Saica → Burgo** | ✅ |

**여섯 개 다 에러를 안 냅니다.** 그래서 몇 달을 갑니다. 그리고 여섯 번째는 앞의 다섯과 달리 **능동적으로 해롭습니다** — 나머지는 기회를 놓치는 것이고, 이건 경쟁사에게 정보를 주는 겁니다.

## 6. 아직 안 받은 것

1. **`scan_us_smi_mti_structure` 블록 1·2** — 4행 병합의 전제
2. **`scan_bare_contacts` 블록 4·5** — Omya Korea 이메일 + 이름 유도 미리보기
3. **일본 `has_ko` 5행**
