# mbg-project — Phase D4 Handoff

**Date**: 2026-05-26
**Branch**: `marinebiogroup` (default branch)
**Last commit**: `b2ff506` (Phase D4: cleanup stale .bak files)
**Tag**: `v5.13-d4-complete`
**Repository**: https://github.com/MarineGift/mbg-project
**Local path**: `C:\dev\mbg-project`
**Current tsc**: **0 errors** ✓
**Current build**: success ✓
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

### D1 → D3 (이전 handoff 참고: HANDOFF_phase-d3-complete.md)

| Phase | tsc | Description |
|---|---|---|
| D1 | 172 | code-side `module` → `party_type` cleanup |
| D2a-D2s-2b | 172 → 0 | TypeScript cascade cleanup (multiple sub-phases) |
| D3-5 | 0 | `app.parties.party_type = 'filler'` → `'filler_supplier'` UPDATE (229 rows) |
| D3-6 | 0 | UI 라벨 변경 (`Module` → `Party type`) |
| D3-8 | 0 | enum 11값 → 5값 (deprecated 6개 제거) |

### D4 (이번 세션, 2026-05-26)

| Phase | 내용 | 결과 | Commit |
|---|---|---|---|
| **D4-a** | `ai.brand_voice.module` / `ai.drafts.module` → `party_type` | DB rename + database.ts 재생성. 활성 코드 참조 0 | `25b198c` (squashed into `1804271`) |
| **PR #1 merge** | `feature/d4a-column-rename` → `marinebiogroup` squash merge | D3 + D4-a 통합 (94 commits → 1) | `1804271` |
| **D4-b** | `/paper_mill/parties` 1067 vs 429 진단 + parties/page.tsx cleanup | 의도된 stub filter 확인. 중복 if + 헤더 주석 정정 | `fbfd140` |
| **D4-c** | 3 dead dedup functions 호출자 grep | 활성 호출자 0 확정, 재작성 불필요 | (no commit, analysis only) |
| **Bonus** | 42 stale .bak files cleanup (src/) | `.bak2` 1개만 git-tracked, 나머지는 .gitignore 됨 | `b2ff506` |

---

## 현재 DB 상태 (D4 종료 후, D3 와 동일)

### `app.party_type` enum (5 values)

```
investor, paper_mill, partner, customer, filler_supplier
```

### 데이터 분포 — 화면 가시성 포함

```
party_type        total   visible_default   hidden_stubs   비고
─────────────────────────────────────────────────────────────────────────
paper_mill        1067    429               638            stub 638개 숨김
filler_supplier   229     226               3
investor          119     119               0
customer          14      14                0
partner           8       8                 0
─────────────────────────────────────────────────────────────────────────
total             1437    796               641
```

Stub 정체: `notes ILIKE 'Auto-created%'` — 두 가지 import source 의 placeholder.
- `Auto-created from supplier_mill_linkages` — supplier-mill 관계에서 company entity 없을 때
- `Auto-created from paper_mills (no legacy companies entry)` — plant-level 데이터에서 legacy 없을 때

화면에서 stub 보고 싶으면 URL 에 `?include_stubs=1`.

### 마이그레이션된 컬럼 (변경 사항)

D4-a 에서 컬럼명 정정:
- `ai.brand_voice.module` → `ai.brand_voice.party_type` (타입은 `app.party_type` 으로 동일)
- `ai.drafts.module` → `ai.drafts.party_type`

기존 12 enum 컬럼 + 5 array 컬럼 (D3 timeline) 은 변경 없음.

---

## D4 에서 확정된 내용 — 향후 referenced

### 1. `/paper_mill/parties` 1067 vs 429 = 의도된 UX

**버그 아님**. `src\app\(app)\[partyType]\parties\page.tsx` L151-153:

```typescript
if (!showStubs) {
  query = query.or('notes.is.null,notes.not.ilike.Auto-created%');
}
```

`showStubs = sp.include_stubs === '1'` → 기본 false → stub 숨김.

향후 UX 개선 옵션 (별도 phase 후보):
- hidden stubs count + "show all" 링크
- stub party 별도 admin 페이지

### 2. 3 dead dedup functions — D3-8 DROP 이 옳은 결정이었음

| 함수 | 활성 .rpc() 호출자 | 활성 SQL 호출자 | database.ts (live) |
|---|---:|---:|---|
| `app.find_similar_parties` | 0 | 0 | 없음 |
| `app.find_similar_persons` | 0 | 0 | 없음 |
| `app.fn_pick_meeting_engagement_kind` | 0 | 0 | 없음 |

모든 mention 은 다음 중 하나로만 잡힘:
- `supabase/migrations/20260520015659_a2_dedup_activity_status.sql` — 함수 **생성** 한 마이그레이션 자체 (historical record, 건드리지 않음)
- `scripts/d3-archive/d3-8c-recovery-diagnostic.sql` — D3-8 DROP 진단용
- `.bak` 파일들 (이미 삭제됨)

결론: **재작성 불필요**. 호출자 0인 dead code 였음. 향후 만약 dedup 기능이 필요해지면 새 함수 (5값 enum + party_kind 정확 분리) 로 처음부터 작성.

### 3. 파일 헤더 주석 정정 패턴

D3 에서 `[module]` → `[partyType]` route rename 했지만 일부 파일 헤더 주석에 옛 경로가 남아있던 케이스 발견. parties/page.tsx 외에도 비슷한 잔재 있을 가능성:

```powershell
# 향후 정리 시 grep 패턴
Get-ChildItem -Recurse -LiteralPath 'src' -Include *.ts,*.tsx -ErrorAction SilentlyContinue |
  Select-String -Pattern '\[module\]/parties/' -ErrorAction SilentlyContinue
```

D5 작업 중 발견되면 같이 정리.

---

## D5 후보 (next phase) — urm.* 마이그레이션

### 현황

사용자 메모리: urm 스키마로 점진적 마이그레이션 진행 중. D3-8a 진단에서 urm 의 parallel 구조 확인됨:
- `urm.parties`, `urm.contacts`, `urm.deals`, `urm.deal_checklists`, `urm.stages`, `urm.pipelines`, `urm.tasks`, `urm.engagements`

stage29c 디렉토리에 plumbing artifacts 존재:
- `stage29c/01_caller_audit/` — TS 코드의 app.* 호출 audit
- `stage29c/02_type_regeneration/REGEN_TYPES.md` + `urm_schema_typescript_stub.ts`
- `stage29c/03_sbclient_cutover/` — Supabase client cutover 패턴
- `stage29c/04_column_rename/` — codemod 스크립트
- `stage29c/05_urm_verification_sql/` — 검증 SQL 5개
- `stage29c/06_app_residual_cleanup/` — app.* 잔재 audit
- `stage29c/07_completion/completion_criteria.md`
- `stage29c/STAGE_29C_PLAYBOOK.md` — 전체 playbook
- `stage29c/INDEX.md`

→ **D5 시작 첫 단계**: `stage29c/INDEX.md` + `STAGE_29C_PLAYBOOK.md` 읽어서 어디까지 진행됐는지 파악.

### 사전 결정 필요 항목

1. **urm 스키마 design 확정됐는가?** — stage29c/02 의 stub 으로 충분한지, 추가 컬럼 필요한지
2. **app.* vs urm.* 분담 전략** — 영구 공존 vs urm 가 app 완전 대체?
3. **데이터 이전 전략** — 한 번에 dump+load vs 점진적 이중쓰기 vs 모듈별 단계 cutover
4. **마이그레이션 timing** — 한 세션에 트랜잭션 통째로 vs 모듈별 분할
5. **롤백 전략** — DB 스냅샷? 이중쓰기 windows? read-only fallback?

### D5 작전 (개략)

```
D5-0: stage29c 산출물 audit + 현재 진행 상태 정확히 파악
D5-1: urm 스키마 final DDL 확정 + 문서화
D5-2: urm 테이블 최종 생성 (이미 일부 존재) + 누락 컬럼 추가
D5-3: app.* → urm.* 데이터 마이그레이션 SQL (단일 트랜잭션)
D5-4: TS 타입 재생성 (urm 포함 — 이미 database.ts 에 urm schema 포함됨, 확인 필요)
D5-5: 코드 cutover (모듈별 점진, .rpc/.from 호출 변경)
D5-6: app.* deprecation 안내 + grace period
D5-7: app.* 제거 마이그레이션

→ 각 단계가 D3 한 사이클 정도 분량. 최소 3-5 세션 예상.
```

---

## 사용자 환경 + 워크플로우 (D3 동일, 변경 없음)

### PowerShell 스크립트 패턴

**필수 표준**:
- 콘솔 출력: **영어 ASCII only** (Windows PowerShell 5.x 의 CP949 인코딩 이슈 회피)
- 한글 텍스트: `.md` 보고서 파일에만 + **UTF-8 BOM** 으로 저장
- Downloads 자동 감지: `Downloads` 와 `다운로드` 둘 다 시도

### SQL 마이그레이션 패턴

**❌ 단계별 실행 금지** — 트랜잭션 깨져서 half-migrated 상태 위험

**✅ 통째로 BEGIN..COMMIT 한 번에 실행** — 실패 시 자동 ROLLBACK

**필수 안전 장치**:
1. 단일 트랜잭션
2. PRE-CHECK (영향 범위 NOTICE 출력)
3. POST-CHECK with RAISE EXCEPTION (검증 실패 시 ROLLBACK)
4. 의존성 전수 조사 (BASE TABLE 컬럼 + array 컬럼 + VIEW + 함수 + DEFAULT + INDEX + RLS + TRIGGER)

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
        $bak = $Path + '.bak-d?-' + (Get-Date -Format 'yyyyMMddHHmmss')
        Copy-Item -LiteralPath $Path -Destination $bak -Force
        $new = $c.Replace($A, $R)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Path, $new, $utf8NoBom)
    }
}
```

⚠ **CRLF-aware**: D4-b 작업 중 발견된 교훈 — `parties/page.tsx` 같은 파일은 CRLF 라인 엔딩. here-string 으로 매칭 시 `` `r`n `` 명시 필요. 매치 실패하면 line ending 의심.

⚠ **`.bak` 파일 정리**: D4 phase 마무리에서 일괄 정리. 작업 끝나면 매번 정리하는 게 grep noise 줄임. `.gitignore` 가 대부분 잡지만 `.bak2`, `.20260525_*.bak` 같은 변종은 안 잡힐 수 있음.

### TS 타입 재생성 — Management API 방식

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
Write-Host ("database.ts size: " + (Get-Item 'src\types\database.ts').Length + " bytes")
```

기대 크기: ~424KB (public + app + ai + urm + industry + ingest schemas 포함). 18KB 면 `included_schemas` 파라미터 누락 의심.

### Cast semantics (D2 에서 학습)

| Scenario | Correct cast |
|---|---|
| Value to expected type param | `value as never` |
| Function reference for callable | `(func as any)` — NOT `(func as never)` |
| Object literal with excess properties | `{...} as never` |
| Result type conversion | `value as unknown as TargetType` |

### Git workflow 패턴 (D3/D4 에서 학습)

- Default branch: **`marinebiogroup`** (NOT `main` or `master`)
- 머지: GitHub UI 의 **Squash and merge** 권장 (D2 의 미세 commit 들 정리)
- PR base 선택 시: dropdown 에서 `marinebiogroup` 직접 선택
- Compare URL 패턴: `https://github.com/MarineGift/mbg-project/compare/marinebiogroup...feature/xxx?expand=1`

⚠ **`git push --delete` 주의**: 머지 안 된 상태에서 원격 브랜치 삭제하면 작업물 사라질 수 있음. 항상 머지 확인 후 삭제.

---

## D4 작업 중 발견된 잔재 (D5 시작 전 정리 후보)

### A. `.env.local.bak` (루트, 5974 bytes, 2026-05-24)

시크릿 가능성. **자동 삭제 금지**. 필요 여부 사용자 확인 후 결정.

### B. `[module]` 잔재 grep (D4-b 와 같은 패턴)

```powershell
Get-ChildItem -Recurse -LiteralPath 'src' -Include *.ts,*.tsx -ErrorAction SilentlyContinue |
  Select-String -Pattern '\[module\]' -ErrorAction SilentlyContinue
```

→ 0건이면 OK. 발견되면 D5 작업 중 같이 정리.

### C. 활성 코드의 `module` 단어 잔재 (변수명, prop 명 등)

D3 에서 cascade 정리됐지만 일부 잔재 있을 가능성. D5 cutover 시 발견되면 함께 정리.

---

## End-state goal

**현재**: D4 phase 안정 종료. tsc=0. build 성공. DB + 코드 일관성 확보. UI 라벨 통일.

**다음**: D5 — **urm.* 스키마로 완전 이전** (사용자 메모리의 "Phase 7-b plant-level data restructuring" 연장선).

D5 시작 시 첫 단계:
1. `stage29c/INDEX.md` + `stage29c/STAGE_29C_PLAYBOOK.md` 읽기
2. 현재 urm.* 스키마 상태 진단 (어디까지 만들어졌는지)
3. 사전 결정 5항목 (위 D5 후보 섹션 참조) 결정
4. D5-0 부터 순차 진행

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
- **Git**: default branch `marinebiogroup`, GitHub UI squash merge 선호

---

## Git refs (current)

```
b2ff506  (HEAD -> marinebiogroup, tag: v5.13-d4-complete, origin/marinebiogroup, origin/HEAD)
         Phase D4: cleanup stale .bak files
fbfd140  Phase D4-b: cleanup parties/page.tsx
1804271  (tag: v5.12-party-type-cleanup)
         Phase D3 + D4-a: enum cleanup + ai column rename (#1)
f649879  (tag: v5.11-party-system-db-enrichment)
         v5.11: Phase 7-b party system + industry DB enrichment
```

**Tags**:
- `v5.11-party-system-db-enrichment` — pre-D3 baseline
- `v5.12-party-type-cleanup` — D3 + D4-a 완료
- `v5.13-d4-complete` — D4 phase 완전 종료 (현재)
