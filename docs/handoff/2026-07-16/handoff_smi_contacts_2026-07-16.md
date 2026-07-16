# Handoff — SMI 컨택 3명의 정체 (2026-07-16, 9차)

## 0. 먼저 두 가지 정리

**① 스크린샷의 `syntax error at end of input`은 제 탓입니다.** 제가 보여드린 `insert into app.contacts (...)` 블록은 **컬럼명을 보여주려고 인용한 것**이었지 실행용이 아니었습니다. 코드 블록으로 감싸서 실행하시게 만들었습니다.

**② 패치 `file not found`** — `scan_us_smi_mti_structure_2026-07-16.sql`이 **아직 리포에 없습니다.** 브라우저 다운로드에서 SQL 에디터로 바로 붙여넣으신 것 같습니다. 패치는 리포 파일을 고치는 거라 대상이 없었습니다. move-downloads를 먼저 돌리시면 됩니다 (아래 4번).

**③ Thiele 확인 완료** ✅ — `mineral_class = kaolin`, `fcc_fit = no`, `market_role`도 반영됐습니다.

---

## 1. 🎯 블록 3의 결과 — 이게 오늘 US에서 가장 큰 겁니다

`Specialty Minerals (HQ)`의 컨택 3명은 **이름도 직함도 없는 맨 이메일**이었습니다:

| email | full_name | title_text | source |
|---|---|---|---|
| sharad.mathur@mineralstech.com | null | null | inbound_backfill_2026Q2 |
| ken.mueller@mineralstech.com | null | null | inbound_backfill_2026Q2 |
| raina.wickkiser@mineralstech.com | null | null | inbound_backfill_2026Q2 |

**아무도 이들이 누군지 몰랐으니 아무도 쓸 수 없었습니다.** 그래서 찾아봤습니다.

### Sharad Mathur — 파이프라인 전체에서 FCC와 가장 가까운 사람

> **Director, Research and New Product and Business Development, Paper and Packaging**
> — Minerals Technologies Inc.

MTI 인베스터 데이에서 그가 발표한 주제:

> **crystal engineering** — MTI 고유 공정으로 **입자 크기·분포·형상(shape)**을 제어해 목표 입자를 만든다. 이런 응용에는 **석회석에서 유래한 중질탄산칼슘(GCC)** 같은 광물이 쓰인다. 소비재·헬스케어·자동차·건설, 그리고 **제지·포장** 시장에 적용된다.

**이게 FCC 대화입니다.** 인커번트가, 공개적으로, 기록에 남겨서 하고 있는.

- **제지·포장의 신제품 + 사업개발을 책임지는 자리**입니다
- FCC가 밀어내야 할 바로 그 회사에서
- 탄산칼슘 입자 형상 제어가 그의 공개 발표 주제입니다

`is_primary = true`, `is_decision_maker = true`로 설정했습니다.

> **⚠️ 접촉 전 확인 필수**: 2019년 1월 보도자료에 **Dr Sharad Mathur가 Applied Minerals CTO로 선임**됐다는 기록이 있고 ResearchGate도 아직 거기로 표시합니다. theorg·ZoomInfo·MTI 인베스터 데이 트랜스크립트는 셋 다 MTI 제지 담당으로 표시합니다. **같은 사람이 옮겨다닌 건지 동명이인인지 불명확합니다.** LinkedIn으로 현 소속을 확인하고 접촉하세요. notes에 미확인으로 기록했지 단정하지 않았습니다.

### Raina Wickkiser

**Inside Sales & Systems Manager** (2014년 2월~, 이전 Sales & Marketing Analyst). 영업 실무 담당이라 **라이선싱 대화 상대는 아닙니다.** 라우팅·물류 창구로 유효합니다.

### Ken Mueller

**공개 정보 없음.** 이메일 로컬파트에서 이름만 유추했고 **직함·부서는 비워뒀습니다** — 추측해서 채우지 않았습니다.

---

## 2. 4행 문제가 부분적으로 풀렸습니다

이 3명은 **`9f161ff5` Specialty Minerals (HQ)**에 붙어 있습니다. 병합을 어떻게 결정하든 **`9f161ff5`가 keeper입니다** — 4행 중 유일하게 뭔가 붙어 있는 행입니다.

나머지 3행(`5ba57cb3` MTI / `cd3dbf9e` SMI Inc. / `fa423be1` Regional HQ)은 접을 수 있지만, **블록 1·2 결과가 있어야 병합 파일을 씁니다.** 아직 안 받았습니다.

---

## 3. `enrich_smi_contacts_2026-07-16.sql` → `sql\`

`app.contacts` uuid 타깃 UPDATE 3건. **INSERT 없음.**

컬럼명은 **제 MLC 파일에서 가져왔습니다** — 13명이 성공적으로 들어간 그 파일입니다. `title_text`(≠`title`), `is_decision_maker`(≠`decision_maker`). 스캔 파일에선 이걸 확인 안 하고 지어내서 42703이 났습니다.

---

## 4. 이동 · 실행 · 마무리

**scan 파일도 아직 리포에 없으니 같이 옮깁니다.**

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'enrich_smi_contacts_2026-07-16*.sql';        Dest = (Join-Path $repo 'sql'); Name = 'enrich_smi_contacts_2026-07-16.sql' },
  @{ Pattern = 'scan_us_smi_mti_structure_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'scan_us_smi_mti_structure_2026-07-16.sql' },
  @{ Pattern = 'enrich_thiele_kaolin_2026-07-16*.sql';       Dest = (Join-Path $repo 'sql'); Name = 'enrich_thiele_kaolin_2026-07-16.sql' },
  @{ Pattern = 'handoff_smi_contacts_2026-07-16*.md';        Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_smi_contacts_2026-07-16.md' },
  @{ Pattern = 'handoff_us_tier1_2026-07-16*.md';            Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_us_tier1_2026-07-16.md' }
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

**스캔 파일 컬럼명 패치** (리포에 들어간 뒤에 실행):

```powershell
$ErrorActionPreference = 'Stop'
$f = 'C:\dev\mbg-project\sql\scan_us_smi_mti_structure_2026-07-16.sql'
if (-not (Test-Path $f)) { Write-Host "SKIP  file not in repo yet - run move-downloads first"; return }

$t = [System.IO.File]::ReadAllText($f) -replace "`r`n", "`n"
$old = "select c.id, c.full_name, c.title, c.email, c.phone_e164, c.decision_maker"
$new = "select c.id, c.full_name, c.title_text, c.department, c.email,`n       c.phone_e164, c.is_primary, c.is_decision_maker, c.source"

if ($t.Contains($new))     { Write-Host "SKIP  already patched" }
elseif ($t.Contains($old)) {
  [System.IO.File]::WriteAllText($f, $t.Replace($old, $new), (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "OK    patched: title -> title_text, decision_maker -> is_decision_maker"
} else { Write-Host "WARN  target not found - check manually" }
```

**실행**

1. `enrich_smi_contacts` 전체 실행 → 검증 쿼리로 3명 이름·직함 확인, Sharad Mathur가 primary/decision_maker인지
2. **`scan_us_smi_mti_structure` 블록 1과 2를 따로따로** 실행 → **결과 보내주세요.** 병합 파일에 필요합니다
   - 블록 1: 4행 나란히 비교
   - 블록 2: FK 부착 현황 (contacts/deals/comms/deal_parties/supply_links/engagements)

> 에디터는 파일 중간에 에러가 나면 **전체를 중단하고 마지막 문 결과만** 보여줍니다. 그래서 지난번 블록 1·2 결과가 화면에 안 나왔습니다. **블록 단위로 따로 실행**해 주세요.

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/handoff/2026-07-16/
git commit -m "enrich: name+title the 3 bare SMI contacts (Sharad Mathur = MTI Director New Product/BD Paper & Packaging, crystal engineering = FCC adjacent); fix scan contacts column names"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 이게 시사하는 것

`inbound_backfill_2026Q2`로 들어온 **맨 이메일**들이 다른 party에도 있을 겁니다. 이름·직함이 없으면 **CRM에 있어도 없는 것과 같습니다.**

한 번 스캔해 볼 가치가 있습니다:

```sql
select p.party_name, p.party_type_id, count(*) as bare_contacts
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and c.full_name is null and c.email is not null
group by 1, 2
order by count(*) desc;
```

Sharad Mathur가 3개월 넘게 이름 없이 앉아 있었습니다. 같은 처지가 더 있을 겁니다.

## 6. 아직 안 받은 것

- **`scan_us_smi_mti_structure` 블록 1·2** — 병합 파일의 전제
- **일본 `has_ko` 5행 확인** — 다음에 안 주시면 그냥 강제 덮어쓰기 파일을 만들겠습니다
