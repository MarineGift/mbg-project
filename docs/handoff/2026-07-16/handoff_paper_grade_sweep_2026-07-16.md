# Handoff — paper-grade 재검증 스윕 (2026-07-16, 5차)

## 0. 먼저 — 이 스캔이 못 하는 일

**"근거가 마케팅 페이지뿐인 행"을 SQL로 골라낼 수 없습니다.** 제가 제안해놓고 막상 짜려니 막혔습니다.

이유: **provenance가 애초에 기록돼 있지 않습니다.**

- `filler_supplier_profile.notes`에 `Paper-grade: YES`라고만 적혀 있고 **근거 URL이 없습니다**
- **확인 일자가 없습니다**
- `industry_source`는 `industry-research` / `v11.4` 같은 뭉뚱그린 값이라 판별에 못 씁니다

즉 지금 데이터로는 **"YES인데 근거가 마케팅"과 "YES인데 근거가 공시"를 구분할 수 없습니다.** 전부 똑같이 `Paper-grade: YES`입니다.

그래서 이 스캔은 **재검증 우선순위**로 대신 뽑습니다 — `주장 강도 × 랭킹 영향도 × 아직 재확인 안 됨`. 현재 데이터에서 가능한 최선의 프록시입니다. 근본 해결책은 §6에 따로 적었습니다.

## 1. `scan_filler_paper_grade_reverify_2026-07-16.sql` → `sql\`

**READ-ONLY입니다.** INSERT/UPDATE/DELETE 하나도 없습니다. 블록 6개를 **따로따로** 실행하세요.

| 블록 | 내용 |
|---|---|
| 1 | **요약** — 티어별 행 수. 문제 규모 파악 |
| 2 | **⭐ Tier 1 워크리스트** — `Paper-grade: YES` + `evidence A/B` + 아직 재확인 안 됨. **여기부터** |
| 3 | Tier 2 — YES인데 evidence가 A/B가 아닌 것 |
| 4 | **한 번도 평가 안 된 행** — 일본 top 5가 숨어 있던 바로 그 구멍 |
| 5 | **비공식 판단 텍스트** — `[ex-website-note 2026-06-20]` 태그. ⭐표시 붙은 의견들 |
| 6 | **도메인 기준 중복 탐지** — 이름이 아니라 host로 |

### 왜 Tier 1이 먼저인가

**MLC와 Zantat이 정확히 거기 있었습니다.** 둘 다 `evidence B` + 강한 제지 주장이었고, 둘 다 틀렸습니다.

주의할 점 하나: **`evidence_level='C'`가 더 위험할 거라 생각했는데 아니었습니다.** 실제로 틀린 두 건은 모두 **B**였습니다. 문제는 근거의 *등급*이 아니라 *출처*입니다. C는 애초에 "추정"이라고 인정하고 있어서 오히려 정직합니다. **B가 위험한 이유는 "확인했다"고 주장하면서 실은 마케팅 페이지를 봤기 때문**입니다.

그래서 정렬을 `satellite/onsite` → `evidence_level` 순으로 걸었습니다. satellite 주장이 틀리면 랭킹이 가장 크게 흔들립니다.

### 블록 4를 꼭 보셔야 하는 이유

奧多摩·白石×2·丸尾·備北 — **일본 제지 PCC 최상위 이름 5개가 한 달간 여기 있었습니다.** batch1에서 website만 받고 이후 모든 enrich 배치에서 누락. 아무 에러 없이 조용히요.

같은 처지의 행이 다른 나라에도 있을 겁니다. **랭킹에 안 올라온 게 아니라 애초에 평가된 적이 없는 행**이라 가장 놓치기 쉽습니다.

### 블록 5 — ⭐는 근거가 아닙니다

batch14가 website 컬럼에 잘못 들어가 있던 평가 텍스트를 구조해서 `[ex-website-note 2026-06-20]` 태그로 옮겨놨습니다. 그런데 그 내용이:

> `⭐ 미국 자국 PCC 시장의 두 번째 사업자 (MTI 다음)` ← **MLC. 이게 틀린 그 문장입니다.**
> `⭐⭐⭐ 터키 자국 calcite #1 by quarry scale`
> `Potential local supplier candidate only` ← **Calrock. 이것도 틀렸습니다.**

**출처 없는 의견입니다.** 5번 블록으로 전수 확인하세요.

### 블록 6 — 중복은 제가 낸 사고입니다

`Omya Korea Inc.`가 중복으로 들어간 건 가드가 **party_name 완전일치**였기 때문입니다. `Omya (Korea)`와 안 부딪혔습니다.

**도메인으로 묶었으면 잡혔습니다** (`omya.com/kr-ko` vs `omya.com`). 6번 블록이 그겁니다. **앞으로 filler에 INSERT하기 전엔 이걸 먼저 돌리는 걸 규칙으로** 하시는 게 좋겠습니다.

정상 중복도 같이 나올 겁니다(Omya 계열 14행이 전부 omya.com, SMI 공장 20여 행이 전부 mineralstech.com). 그건 무시하시면 됩니다 — 봐야 할 건 **같은 host + 같은 country_code인데 이름만 다른 쌍**입니다.

---

## 2. §6 구조적 해결 — 마이그레이션 없이 가능합니다

`app.filler_supplier_profile.extra_data`가 이미 `jsonb NOT NULL DEFAULT '{}'`입니다. **컬럼 추가 없이** provenance를 넣을 수 있습니다:

```json
{"paper_grade": {
   "claim": "yes",
   "source_url": "https://www.mlc.com/contact-us/",
   "source_type": "transactional",
   "checked_at": "2026-07-16"
}}
```

`source_type`: `marketing` | `disclosure` | `transactional` | `third_party`

**이 필드 하나가 세 건 다 잡았을 겁니다.** `source_type = marketing`에만 기대는 주장이 정확히 그 위험군입니다. 채워지면 이 스캔 전체가 정직한 쿼리 한 줄로 줄어듭니다:

```sql
select party_name from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id
where f.extra_data #>> '{paper_grade,source_type}' = 'marketing'
   or f.extra_data #>> '{paper_grade,checked_at}' < '2026-01-01';
```

**전 행 백필은 비현실적입니다.** 제안: **Tier 1을 재확인할 때마다 그 행만 채우기.** 별도 프로젝트가 아니라 작업하면서 커버리지가 자라게. 다음 배치부터 제가 이 형식으로 넣겠습니다.

---

## 3. 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'scan_filler_paper_grade_reverify_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'scan_filler_paper_grade_reverify_2026-07-16.sql' },
  @{ Pattern = 'handoff_paper_grade_sweep_2026-07-16*.md';         Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_paper_grade_sweep_2026-07-16.md' }
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

## 4. 실행

1. **블록 1**부터 — 규모 확인.
2. **블록 2 (Tier 1) 결과를 CSV로 export해서 보내주세요.** 그게 실제 재검증 작업 리스트입니다.
3. 여유 되시면 **블록 4·5·6**도 함께. 4는 숨은 행, 6은 중복 사고 재발 방지.
4. 받으면 Tier 1 위에서부터 홈페이지 현행 공시 기준으로 재확인하고, `extra_data` provenance까지 채운 `fix_` 파일을 드리겠습니다.

**그리고 지난번 부탁 하나 아직입니다**: 일본 파일 검증 쿼리의 `has_ko`가 5행 모두 `true`인지 확인해 주세요. false가 있으면 MLC와 같은 null 가드 버그입니다.

## 5. 마무리 (commit + push)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_filler_paper_grade_reverify_2026-07-16.sql docs/handoff/2026-07-16/handoff_paper_grade_sweep_2026-07-16.md
git commit -m "scan: filler paper-grade re-verification triage (read-only) + domain-based dupe detector + extra_data provenance proposal"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 6. 예상되는 것 — 미리 말씀드립니다

블록 2가 **꽤 긴 리스트**를 뱉을 겁니다. 파이프라인 export에서 본 것만 해도 `Omya (USA)`(evidence A, "Merchant + onsite/satellite"), `Specialty Minerals (HQ)`(evidence A, "Leading global satellite PCC operator"), `Imerys USA`(B), `IMI Fabi`(B), SMI 온사이트 공장 다수가 조건에 걸립니다.

**전부 다 재확인하는 건 현실적이지 않습니다.** 제 제안은:

1. **satellite 주장 행 먼저** — 틀리면 랭킹이 가장 크게 흔들립니다. 정렬을 그렇게 걸어놨습니다.
2. **SMI 공장 행은 개별 재확인 대상이 아닙니다** — 담당자도 없고 계약 주체도 아닙니다. `Specialty Minerals (HQ)` 한 행만 제대로 보면 됩니다. 공장 행은 satellite 근거 데이터로 두세요.
3. **Omya 계열도 마찬가지** — `Omya (USA)`, `Omya (Korea)` 등 국가 법인이 실제 상대이고, 그중 evidence A인 `Omya (USA)`가 1순위입니다.

이렇게 걸러내면 실제 재확인 대상은 **10~15행 수준**으로 줄어들 겁니다. 그 정도면 한 배치에 끝납니다.
