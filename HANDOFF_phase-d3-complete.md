# mbg-project — Phase D3 Handoff

**Date**: 2026-05-26
**Branch**: `feature/stage23-urm-cleanup`
**Last commit**: `fe7d6d6` (Phase D3 enum cleanup + UI label modernization)
**Repository**: https://github.com/MarineGift/mbg-project
**Local path**: `C:\dev\mbg-project`
**Current tsc**: **0 errors** ✓
**Supabase project_id**: `ogenmrgxwhpbfepeldqx`

---

## Session restart — First commands

```powershell
cd C:\dev\mbg-project

# Pull latest
git pull --rebase

# Verify state
git log --oneline -10

# Set exec policy (every new PS session)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Verify tsc baseline (should be 0)
(npx tsc --noEmit 2>&1 | Select-String 'error TS').Count
```

---

## Completed phases — Full timeline

### Pre-D3 (이전 handoff 까지)

| Phase | tsc | Description |
|---|---|---|
| D1 | 172 | code-side `module` → `party_type` cleanup |
| D2a-D2o | 172 → 69 | TypeScript cascade cleanup |
| D2p | 69 → 62 | `.schema('app' as never)` cast removal |
| D2q | 62 → 52 | sequence-processor.ts 6 pattern fixes |
| D2r | 52 → 29 | Bulk fix top 10 files |
| D2s-1 | 29 → 15 | destructure rename + JSX prop rename |
| (D2s-2 등) | 15 → 0 | 모든 잔여 tsc 에러 해소 |

### D3 (이번 세션, 2026-05-26)

| Phase | 내용 | 결과 |
|---|---|---|
| **D3-5** | `app.parties.party_type = 'filler'` → `'filler_supplier'` 데이터 UPDATE | 229 rows updated, `/filler_supplier/parties` 226건 표시 ✓ |
| **D3-6** | UI 라벨 변경 (`Module` → `Party type`, `All modules` → `All`) | 3 파일 5 사이트, tsc 0 유지 |
| **D3-8** | enum 11값 → 5값 (deprecated 6개 제거) | 단일 트랜잭션 마이그레이션 + 14 VIEW 정상 |
| **TS 타입 재생성** | Supabase Management API → `database.ts` 424KB/13,062줄 | app, ai, urm, public 스키마 포함 |

**Commit**: `fe7d6d6 — Phase D3: enum cleanup (filler→filler_supplier, drop 6 deprecated values), UI label modernization`

---

## 현재 DB 상태 (D3 종료 후)

### `app.party_type` enum (5 values)

```
investor, paper_mill, partner, customer, filler_supplier
```

(이전 11값 중 deprecated 6개 제거: `filler`, `crowdfunding`, `product_launch`, `sales`, `government_grant`, `buyer`)

### 데이터 분포

```
app.parties:
  customer        : 14
  filler_supplier : 229
  investor        : 119
  paper_mill      : 1067
  partner         : 8
  total           : 1437

ai.brand_voice (18 deprecated rows 삭제됨):
  customer    : 6
  investor    : 6
  paper_mill  : 6
  partner     : 6
  total       : 24
```

### 마이그레이션된 컬럼 (12개 enum + 5개 array)

**Enum 컬럼**:
- ai.brand_voice.module
- ai.drafts.module
- app.communications.party_type
- app.consultations.party_type
- app.custom_field_definitions.party_type
- app.engagements.party_type
- app.industry_collections.primary_party_type
- app.parties.party_type
- app.person_firm_history.party_type
- app.pipelines.party_type
- app.response_strategies.party_type
- app.tasks.party_type

**Array 컬럼**:
- app.organizations.allowed_modules
- app.teams.focus_modules
- app.template_categories.applicable_modules
- ai.agents.applicable_modules
- ai.auto_send_rules.allowed_modules

### VIEW 14개 정상 (8 재생성 + 6 보너스)

```
v_engagement_events           v_investor_subtype_options
v_engagement_participants     v_investor_with_partners
v_filler_suppliers            v_paper_mills
v_firm_alumni                 v_partner_seniority_options
v_firm_engagement_summary     v_party_dedup_candidates
v_investor_outreach_list      v_person_career_history
                              v_person_dedup_candidates
                              v_person_engagement_participation
```

---

## D3 에서 발견되어 deferred 된 작업 (D4 후보)

### 🔴 1. 사전 버그 함수 3개 재작성

D3-8 에서 DROP 한 함수들 — 원본에 사전 버그 있었음:

| 함수 | 사전 버그 |
|---|---|
| `app.find_similar_parties(text, text, party_kind, party_type, uuid, real, integer)` | 본문에서 존재하지 않는 `p.module` 컬럼 참조 |
| `app.find_similar_persons(text, text, party_type, uuid, real, integer)` | `'individual'::app.party_type` 잘못된 캐스트 (individual 은 party_kind 값) |
| `app.fn_pick_meeting_engagement_kind(uuid, party_type, party_kind)` | engagement_type_registry 와 party_type 컬럼 매핑 검증 필요 |

**수정 방향**: `p.module` → `p.party_type`, 'individual' 관련 캐스트를 party_kind 로 변경, 시그니처도 새 enum 5값에 맞게.

### 🟡 2. Paper Mills 화면 데이터 차이

```
DB app.parties (party_type='paper_mill', deleted_at IS NULL) = 1067
화면 /paper_mill/parties                                      = 429
```

화면이 추가 필터링 중. 가능성:
- `[Sector] ...` 이름 보면 sector 레벨만 표시
- party_level 또는 parent_party_id 필터
- 비즈니스 로직 — 깨진 게 아닐 가능성 높음

→ 별도 진단 후 결정. 만약 의도된 동작이면 그대로 두기.

### 🟡 3. `module` 컬럼명 정리

`ai.brand_voice.module`, `ai.drafts.module` 의 데이터 타입은 `app.party_type` 이지만 **컬럼명에 module 잔존**.

사용자가 D3 작업 중 "Module 필요 없다" 명시. DB 컬럼 rename 필요:

```sql
ALTER TABLE ai.brand_voice RENAME COLUMN module TO party_type;
ALTER TABLE ai.drafts      RENAME COLUMN module TO party_type;
```

→ 코드측 참조도 같이 grep + replace. tsc 회귀 가능성 있음 (database.ts 재생성 필요).

### 🟢 4. urm.* 스키마 마이그레이션 (Phase 7-b 계속)

사용자 메모리: urm 스키마로 점진적 마이그레이션 진행 중. D3-8a 진단에서 urm 의 parallel 구조 확인됨:
- urm.parties, urm.contacts, urm.deals, urm.deal_checklists, urm.stages, urm.pipelines, urm.tasks, urm.engagements

→ 사용자 결정 필요한 큰 작업.

### 🟢 5. PR 리뷰 + main 머지

`feature/stage23-urm-cleanup` 브랜치를 main 으로 머지 (별 이슈 없으면 즉시 가능).

---

## 사용자 환경 + 워크플로우 (영구 메모리 등록됨)

### PowerShell 스크립트 패턴

**필수 표준**:
- 콘솔 출력: **영어 ASCII only** (Windows PowerShell 5.x 의 CP949 인코딩 이슈 회피)
- 한글 텍스트: `.md` 보고서 파일에만 + **UTF-8 BOM** 으로 저장
- Downloads 자동 감지: `Downloads` 와 `다운로드` 둘 다 시도

**템플릿 헤더**:
```powershell
param([switch]$Apply)

$scriptName = 'd?-?-?.ps1'
$downloadsCandidates = @(
    (Join-Path $env:USERPROFILE "Downloads\$scriptName"),
    (Join-Path $env:USERPROFILE "다운로드\$scriptName")
)
foreach ($cand in $downloadsCandidates) {
    if (Test-Path -LiteralPath $cand) {
        Move-Item -LiteralPath $cand -Destination . -Force
        break
    }
}
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Unblock-File -LiteralPath ".\$scriptName" -ErrorAction SilentlyContinue
Set-Location -LiteralPath 'C:\dev\mbg-project'
```

### SQL 마이그레이션 패턴 (중요)

**❌ 단계별 실행 금지** — 트랜잭션 깨져서 half-migrated 상태 위험

**✅ 통째로 BEGIN..COMMIT 한 번에 실행** — 실패 시 자동 ROLLBACK

**필수 안전 장치**:
1. 단일 트랜잭션
2. PRE-CHECK (영향 범위 NOTICE 출력)
3. POST-CHECK with RAISE EXCEPTION (검증 실패 시 ROLLBACK)
4. 의존성 전수 조사 (BASE TABLE 컬럼 + array 컬럼 + VIEW + 함수 + DEFAULT)

### Set-PatchAll 안전 템플릿

```powershell
function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray; return
    }
    $c = [System.IO.File]::ReadAllText($Path)
    $count = ([regex]::Matches($c, [regex]::Escape($A))).Count
    if ($count -eq 0) { Write-Host ("  [SKIP] " + $Desc) -ForegroundColor DarkYellow; return }
    Write-Host ("  [OK x" + $count + "] " + $Desc) -ForegroundColor Green
    if ($Apply) {
        $new = $c.Replace($A, $R)
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($Path, $new, $utf8Bom)
    }
}
```

### Dry-run + Apply 패턴

모든 코드 패치 스크립트는 두 모드 지원:
- 기본 (인자 없음): DRY-RUN — 매치 위치만 출력
- `-Apply`: 실제 변경 + `.bak-*` 백업 + tsc 회귀 검증

### TS 타입 재생성 — Management API 방식

Supabase CLI 가 설치 안 됐을 때:

```powershell
$token = Read-Host -Prompt "Paste Supabase Personal Access Token (sbp_...)"
$token = $token.Trim()

$projectId = 'ogenmrgxwhpbfepeldqx'
$url = "https://api.supabase.com/v1/projects/$projectId/types/typescript?included_schemas=public,app,ai,urm,industry,ingest"

$resp = Invoke-RestMethod -Uri $url `
    -Headers @{ Authorization = "Bearer $token" } -Method GET

$body = if ($resp.types) { $resp.types } else { $resp }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) 'src\types\database.ts'),
    $body, $utf8NoBom
)
```

⚠ `included_schemas` 파라미터 필수 — 없으면 public 만 반환 (~18KB)

### Personal Access Token 생성

```
https://supabase.com/dashboard/account/tokens
```

→ Generate new token → 즉시 복사 (한 번만 보임)

### Cast semantics (D2 에서 학습)

| Scenario | Correct cast |
|---|---|
| Value to expected type param | `value as never` |
| Function reference for callable | `(func as any)` — NOT `(func as never)` |
| Object literal with excess properties | `{...} as never` |
| Result type conversion | `value as unknown as TargetType` |

### File line endings

대부분 LF. CRLF 파일 목록은 이전 핸드오프 참고. PowerShell 에서 감지:
```powershell
$bytes = [System.IO.File]::ReadAllBytes($file)
$hasCRLF = $false
for ($i = 0; $i -lt [Math]::Min($bytes.Length, 5000); $i++) {
    if ($bytes[$i] -eq 13 -and $i+1 -lt $bytes.Length -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
}
```

### LiteralPath for `()` `[]` paths (Next.js group routes)

```powershell
# Use -LiteralPath for paths with parens/brackets
Test-Path -LiteralPath 'src\app\(app)\[partyType]\parties\page.tsx'
```

### Git autocrlf 경고

Windows core.autocrlf=true 의 정상 동작. 무시 가능.

---

## scripts/d3-archive/ 보관 파일

D3 작업 중 만든 SQL/PS1 스크립트들 (참고용):

```
d3-4-enum-diagnostic.sql            — enum 의존성 진단
d3-5-migrate-filler-supplier-v2.sql — filler → filler_supplier UPDATE
d3-6-dryrun-report.md               — Module 라벨 grep 결과
d3-6-inline.ps1                     — Module → Party type 패치
d3-8-migrate-enum-cleanup.sql       — enum 6값 제거 마이그레이션 (실패한 v1)
d3-8c-recovery-diagnostic.sql       — half-migrated 복구 진단
d3-filler-grep-report.md            — 'filler' 문자열 grep 보고서
d3-grep-filler.ps1                  — grep 스크립트
```

D3-8e (최종 성공한 복구 마이그레이션) 가 archive 에 없음. 필요 시 commit 히스토리에서 복원 가능.

---

## 다음 phase 작업 시 우선순위 제안

1. **PR 머지** (5분) — 별 이슈 없으면 즉시
2. **D4-a: ai.brand_voice / ai.drafts 컬럼 rename** (30분) — `module` → `party_type`. TS 타입 재생성 필요
3. **D4-b: Paper Mills 화면 차이 진단** (30분) — 코드 한 군데 확인
4. **D4-c: 3 함수 재작성** (1-2시간) — 본문 버그 수정 + 새 enum 5값 시그니처
5. **D5: urm.* 마이그레이션 본격 진행** (multiple sessions) — 사용자 결정 후

---

## End-state goal

D3 종료 후 안정 상태. tsc=0 유지. DB 일관성 확보. UI 모듈 라벨 통일.

다음 큰 목표: **urm.* 스키마로 완전 이전** (사용자 메모리의 "Phase 7-b plant-level data restructuring" 연장선).

---

## User preferences (unchanged)

- **Language**: Korean responses preferred
- **Environment**: PowerShell on Windows, downloads to `%USERPROFILE%\Downloads` or `%USERPROFILE%\다운로드`
- **PowerShell console output**: English ASCII only
- **Korean text**: in .md report files only, UTF-8 BOM
- **Naming**: snake_case for DB cols, camelCase for TS props
- **Style**: prefers self-contained SQL/scripts, downloadable patches with sequential problem-solving
- **Workflow**: ALWAYS include `Move-Item` from Downloads/다운로드 step + `Unblock-File`
- **Execution**: Set-ExecutionPolicy bypass each new session
- **SQL migration**: 통째로 실행 (단계별 금지), 단일 트랜잭션 + POST-CHECK 안전망
