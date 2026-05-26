### Subdir: `04_column_rename`

#### `party_type_join_pattern.ts` (10709 bytes)

```typescript
/**
 * party_type → party_type_id (FK) Migration Patterns
 *
 * 출처: handoff §6 #2, §A4 의 매핑 표
 * 작성: Stage 29-c (2026-05-24)
 *
 * 배경:
 *   V1: app.parties.party_type (enum) — "company" | "organization" | "individual" | "fund" | "government"
 *   V2: urm.parties.party_type_id (FK to urm.party_types) — 1..7
 *
 *   urm.party_types lookup:
 *     1 investor
 *     2 paper_mill
 *     3 filler_supplier
 *     4 buyer
 *     5 customer
 *     6 partner
 *     7 government_grant
 *
 * 핵심 변경:
 *   - app enum 값 ('company') 와 urm code ('investor') 가 1:1 매핑 안 됨
 *   - urm 측에서 "어떤 종류의 party 인지" 는 profile 테이블의 존재로 판별
 *   - caller 가 사용한 'company' 분류는 6 가지 sub-type (investor/paper_mill/filler_supplier/buyer/customer/partner) 중 하나로 정밀화됨
 *
 * 이 파일은 caller code 의 수동 변환 패턴을 예시로 제공.
 * 실제 코드 적용 시: audit script A4 결과의 매치 사이트 case-by-case 처리.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database";

type SbUrm = SupabaseClient<Database, "urm">;
type SbApp = SupabaseClient<Database, "app">;

// =============================================================================
// §1. party_types lookup 상수 (한 번만 정의, caller 전역 사용)
// =============================================================================

/**
 * urm.party_types 의 7 코드. id 는 실제 DB row 확인 후 채울 것.
 *
 * 측정 SQL:
 *   SELECT id, code FROM urm.party_types ORDER BY id;
 */
export const PARTY_TYPE = {
  INVESTOR: 1,
  PAPER_MILL: 2,
  FILLER_SUPPLIER: 3,
  BUYER: 4,
  CUSTOMER: 5,
  PARTNER: 6,
  GOVERNMENT_GRANT: 7,
} as const;

export type PartyTypeCode =
  | "investor"
  | "paper_mill"
  | "filler_supplier"
  | "buyer"
  | "customer"
  | "partner"
  | "government_grant";

export const PARTY_TYPE_CODE_TO_ID: Record<PartyTypeCode, number> = {
  investor: PARTY_TYPE.INVESTOR,
  paper_mill: PARTY_TYPE.PAPER_MILL,
  filler_supplier: PARTY_TYPE.FILLER_SUPPLIER,
  buyer: PARTY_TYPE.BUYER,
  customer: PARTY_TYPE.CUSTOMER,
  partner: PARTY_TYPE.PARTNER,
  government_grant: PARTY_TYPE.GOVERNMENT_GRANT,
};

export const PARTY_TYPE_ID_TO_CODE: Record<number, PartyTypeCode> =
  Object.entries(PARTY_TYPE_CODE_TO_ID).reduce<Record<number, PartyTypeCode>>(
    (acc, [code, id]) => {
      acc[id] = code as PartyTypeCode;
      return acc;
    },
    {}
  );

// =============================================================================
// §2. 변환 패턴 (각 V1 → V2)
// =============================================================================

// -----------------------------------------------------------------------------
// 패턴 P1: .eq('party_type', '<enum>') 단일 filter
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .eq('party_type', 'company');

// V2 (urm):
async function p1_filter_by_type(sbUrm: SbUrm) {
  // 1. 단순 변환 (만약 'company' 가 다 investor 라면)
  const { data: investors } = await sbUrm
    .from("parties")
    .select("*")
    .eq("party_type_id", PARTY_TYPE.INVESTOR);

  // 2. 더 정확: profile 테이블 join 으로 "company 가 어느 sub-type 인지" 판별
  //    예) investor 만 추출
  const { data: investorsWithProfile } = await sbUrm
    .from("parties")
    .select("*, investor_profile!inner(*)")
    .order("name");

  // 3. 또는 여러 sub-type 한꺼번에 (만약 'company' 가 6 sub-type 모두 포함이라면)
  const { data: allCorporateParties } = await sbUrm
    .from("parties")
    .select("*")
    .in("party_type_id", [
      PARTY_TYPE.INVESTOR,
      PARTY_TYPE.PAPER_MILL,
      PARTY_TYPE.FILLER_SUPPLIER,
      PARTY_TYPE.BUYER,
      PARTY_TYPE.CUSTOMER,
      PARTY_TYPE.PARTNER,
    ]);

  return { investors, investorsWithProfile, allCorporateParties };
}

// -----------------------------------------------------------------------------
// 패턴 P2: .in('party_type', ['fund', 'individual']) — 매핑 없는 enum
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .in('party_type', ['fund', 'individual']);

// V2 (urm):
//   urm.party_types 에 fund / individual 부재.
//   - fund: ε hard-delete 완료 (0 row)
//   - individual: 모두 soft-deleted (urm 측 0 row)
//   → 이 query 자체가 빈 결과 반환. 코드 제거 후보.
//
//   만약 어쩔 수 없이 carry 해야 한다면 app.* 로 격리:
async function p2_dead_filter(sbApp: SbApp) {
  // Stage 29-d 까지의 app.* carry. soft-deleted 까지 포함 필요한 경우만.
  const { data } = await sbApp
    .from("parties")
    .select("*")
    .in("party_type", ["fund", "individual"]); // app enum (V1 carry)
  // 운영상 0~118 row (모두 soft-deleted)
  return data;
}

// -----------------------------------------------------------------------------
// 패턴 P3: object property 비교 (TS code, runtime check)
// -----------------------------------------------------------------------------

interface PartyV1 {
  party_type: "company" | "organization" | "individual" | "fund" | "government";
}

interface PartyV2 {
  party_type_id: number;
}

// V1:
//   if (party.party_type === 'fund') { ... }

// V2:
function p3_runtime_check_v2(party: PartyV2) {
  const code = PARTY_TYPE_ID_TO_CODE[party.party_type_id];
  if (code === "investor") {
    // investor 처리
  }
  // fund / individual / organization 는 V2 에 없음. 분기 자체 제거 가능.
}

// =============================================================================
// §3. select() 의 join 패턴 (party_types.code 함께 가져오기)
// =============================================================================

// V1:
//   const { data } = await sbApp.from('parties').select('id, name, party_type');
//   // data: { id, name, party_type: 'company' }[]

// V2 (PostgREST 의 nested select):
async function v2_select_with_type_code(sbUrm: SbUrm) {
  const { data } = await sbUrm
    .from("parties")
    .select(`
      id,
      name,
      party_type_id,
      party_type:party_types(code)
    `);
  // data 의 row 형태:
  //   { id, name, party_type_id: 1, party_type: { code: 'investor' } }

  // 만약 caller 가 flat 한 'party_type' 문자열을 원하면 매핑:
  const flat = data?.map((row) => ({
    id: row.id,
    name: row.name,
    party_type_id: row.party_type_id,
    party_type: PARTY_TYPE_ID_TO_CODE[row.party_type_id],
  }));

  return flat;
}

// =============================================================================
// §4. INSERT 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').insert({
//     name: 'Acme',
//     party_type: 'company',
//     module: 'investor',
//     organization_id: ORG_ID,
//   });

// V2 (urm — organization_id 없음, party_type_id 사용):
async function v2_insert(sbUrm: SbUrm) {
  await sbUrm.from("parties").insert({
    name: "Acme",
    party_type_id: PARTY_TYPE.INVESTOR, // 직접 ID
    // organization_id: 없음 (urm 은 single-tenant, handoff §8)
  } as Database["urm"]["Tables"]["parties"]["Insert"]);
}

// =============================================================================
// §5. UPDATE 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').update({ party_type: 'fund' }).eq('id', id);

// V2:
//   urm 에 'fund' 없음. update 자체 제거 또는 다른 sub-type 으로:
async function v2_update_avoid_fund(sbUrm: SbUrm, id: string) {
  // 잘못된 V1 패턴 ('fund' 로 변경) 은 V2 에서 의미 없음.
  // 만약 의도가 "다른 분류로 reclassify" 라면 명확히 6 sub-type 중 하나:
  await sbUrm
    .from("parties")
    .update({ party_type_id: PARTY_TYPE.PARTNER })
    .eq("id", id);
}

// =============================================================================
// §6. RPC 호출에서의 party_type
// =============================================================================

// V1 RPC 시그니처:
//   public.get_parties_by_type(p_party_type text)
//   → 내부에서 WHERE party_type = p_party_type::party_type_enum

// V2 RPC 시그니처 (DB 측 함수 V2 재작성 필요):
//   public.get_parties_by_type(p_party_type_id int)
//   또는
//   public.get_parties_by_type(p_party_type_code text)
//   → 내부에서 JOIN urm.party_types ON code = p_party_type_code

// caller 측:
async function v2_rpc(sbUrm: SbUrm) {
  // 만약 V2 RPC 가 code 받음
  const { data } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_code: "investor",
  } as never); // 타입 확정 후 as never 제거

  // 또는 id 받음
  const { data: data2 } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_id: PARTY_TYPE.INVESTOR,
  } as never);

  return { data, data2 };
}

// =============================================================================
// §7. helper functions (caller 가 자주 쓰는 분류 logic)
// =============================================================================

/** party 가 investor 인지 (urm 기반) */
export async function isInvestor(sbUrm: SbUrm, partyId: string): Promise<boolean> {
  const { data } = await sbUrm
    .from("investor_profile")
    .select("party_id")
    .eq("party_id", partyId)
    .maybeSingle();
  return !!data;
}

/** party 의 sub-type 코드 추출 (profile 테이블 join) */
export async function getPartyTypeCode(
  sbUrm: SbUrm,
  partyId: string
): Promise<PartyTypeCode | null> {
  const { data: party } = await sbUrm
    .from("parties")
    .select("party_type_id")
    .eq("id", partyId)
    .maybeSingle();
  if (!party) return null;
  return PARTY_TYPE_ID_TO_CODE[party.party_type_id] ?? null;
}

/** 사용자에게 표시할 party_type 한국어 라벨 */
export const PARTY_TYPE_DISPLAY_KO: Record<PartyTypeCode, string> = {
  investor: "투자자",
  paper_mill: "제지사",
  filler_supplier: "충전제 공급사",
  buyer: "구매자",
  customer: "고객",
  partner: "파트너",
  government_grant: "정부지원",
};
```

#### `rename_codemod.ps1` (11060 bytes)

```powershell
# Stage 29-c Column Rename Codemod (PowerShell)
#
# 사용법:
#   .\rename_codemod.ps1 -ProjectRoot . -DryRun         # 미리보기만
#   .\rename_codemod.ps1 -ProjectRoot . -Apply          # 실제 적용
#   .\rename_codemod.ps1 -ProjectRoot . -Apply -Confirm # 각 매치 별로 y/n 물음
#
# 주의:
#   1. -DryRun 으로 먼저 검토 필수
#   2. git working tree clean 상태에서 실행 (revert 용이)
#   3. party_type → party_type_id 는 단순 rename 안 됨. 별도 처리 (party_type_join_pattern.ts)

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Confirm,
    [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts"),
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

if (-not $DryRun -and -not $Apply) {
    Write-Host "ERROR: -DryRun 또는 -Apply 중 하나 필수" -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Column Rename Codemod ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
Write-Host "Project root: $projectRootFull"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 매핑 정의
# 각 entry: { Pattern, Replacement, Description, Scope }
#   Scope: "app" | "urm" | "both" | "code" — caller 호출 컨텍스트 힌트
# ─────────────────────────────────────────────────────────────────────────

$renames = @(
    # === A3 의 V1 caller bug (실재 컬럼명 불일치) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])org_id(?![a-zA-Z0-9_])'
        Replacement = 'organization_id'
        Description = 'org_id → organization_id (app.* 모든 테이블)'
        Scope       = "both"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])body_text(?![a-zA-Z0-9_])'
        Replacement = 'body_plain'
        Description = 'body_text → body_plain (app.communications)'
        Scope       = "app"
    },
    @{
        Pattern     = "(?<![a-zA-Z0-9_])'country'(?![a-zA-Z0-9_])"
        Replacement = "'country_code'"
        Description = "'country' literal → 'country_code' (app.parties)"
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])"country"(?![a-zA-Z0-9_])'
        Replacement = '"country_code"'
        Description = '"country" literal → "country_code" (app.parties)'
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])\.country(?![a-zA-Z0-9_])'
        Replacement = '.country_code'
        Description = '.country accessor → .country_code'
        Scope       = "both"
    },

    # === A3 의 stage_position (urm.stages 의 실재 컬럼은 sort_order) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])stage_position(?![a-zA-Z0-9_])'
        Replacement = 'sort_order'
        Description = 'stage_position → sort_order (urm.stages)'
        Scope       = "urm"
    },

    # === Stage 29-b δ 의 9 deprecated profile 테이블 reference (caller 가 .from() 에 쓰면 실패) ===
    # 이건 단순 rename 이 아니라 "코드 제거 또는 다른 logic 으로 대체" 가 정답.
    # 여기선 검색만 (실제 적용 안 함). audit script 의 A6 와 중복되므로 skip.

    # === handoff §A5 의 module_data 이전 패턴 ===
    # caller 가 .module_data._app_* 접근하는 경우 그대로 두기 (V2 jsonb 보존 logic)
    # 이건 자동 변환 대상 아님.

    # === V1 의 portfolio_company_id (FK) 를 V2 의 module_data._app_portfolio_company_id 로 ===
    # 이것도 단순 rename 어려움 — caller 측 query 패턴 자체가 달라짐.
    # 별도 manual review 후보.
)

# ─────────────────────────────────────────────────────────────────────────
# 파일 list
# ─────────────────────────────────────────────────────────────────────────

$excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"

$allFiles = Get-ChildItem -Path $projectRootFull -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
        $_.FullName -notmatch "[\\/]($excludeRegex)$"
    }

Write-Host "Scanning $($allFiles.Count) files" -ForegroundColor Gray
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 실행
# ─────────────────────────────────────────────────────────────────────────

$grandTotalMatches = 0
$grandTotalFilesChanged = 0
$logEntries = @()

foreach ($rename in $renames) {
    Write-Host "[$($rename.Description)] (scope: $($rename.Scope))" -ForegroundColor Yellow
    Write-Host "  Pattern: $($rename.Pattern)" -ForegroundColor Gray
    Write-Host "  Replace: $($rename.Replacement)" -ForegroundColor Gray

    $patternMatchCount = 0
    $patternFilesChangedCount = 0

    foreach ($file in $allFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        } catch {
            continue
        }
        if (-not $content) { continue }

        $matches = [regex]::Matches($content, $rename.Pattern)
        if ($matches.Count -eq 0) { continue }

        $patternMatchCount += $matches.Count
        $patternFilesChangedCount += 1

        $relPath = $file.FullName.Replace($projectRootFull, "").TrimStart("\", "/")

        Write-Host "  -> $relPath ($($matches.Count) matches)" -ForegroundColor Cyan
        # 매치 라인 sample (앞 3개)
        $lines = $content -split "`n"
        $matchedLineNumbers = @()
        $cursor = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineStart = $cursor
            $lineEnd = $cursor + $lines[$i].Length
            foreach ($m in $matches) {
                if ($m.Index -ge $lineStart -and $m.Index -lt $lineEnd) {
                    $matchedLineNumbers += $i + 1
                }
            }
            $cursor = $lineEnd + 1  # +1 for newline
        }
        $matchedLineNumbers = $matchedLineNumbers | Select-Object -Unique | Sort-Object
        $sampleLines = $matchedLineNumbers | Select-Object -First 3
        foreach ($ln in $sampleLines) {
            $lineContent = $lines[$ln - 1].Trim()
            if ($lineContent.Length -gt 100) { $lineContent = $lineContent.Substring(0, 97) + "..." }
            Write-Host "     L$ln`: $lineContent" -ForegroundColor DarkGray
        }
        if ($matchedLineNumbers.Count -gt 3) {
            Write-Host "     ... ($($matchedLineNumbers.Count - 3) more)" -ForegroundColor DarkGray
        }

        $logEntries += [PSCustomObject]@{
            File         = $relPath
            Pattern      = $rename.Description
            Matches      = $matches.Count
            LineNumbers  = ($matchedLineNumbers -join ", ")
        }

        # 적용
        if ($Apply) {
            $proceed = $true
            if ($Confirm) {
                $answer = Read-Host "  Apply to $relPath? (y/N)"
                if ($answer -notmatch '^[Yy]') { $proceed = $false }
            }
            if ($proceed) {
                $newContent = [regex]::Replace($content, $rename.Pattern, $rename.Replacement)
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Host "     ✓ Applied" -ForegroundColor Green
            } else {
                Write-Host "     - Skipped" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "  ## Sub-total: $patternMatchCount matches in $patternFilesChangedCount files" -ForegroundColor White
    Write-Host ""

    $grandTotalMatches += $patternMatchCount
    $grandTotalFilesChanged += $patternFilesChangedCount
}

# ─────────────────────────────────────────────────────────────────────────
# 결과
# ─────────────────────────────────────────────────────────────────────────

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total matches  : $grandTotalMatches"
Write-Host "Files affected : $grandTotalFilesChanged"
Write-Host ""

# 로그 저장
$logFile = Join-Path -Path $projectRootFull -ChildPath "stage29c_rename_log.csv"
$logEntries | Export-Csv -Path $logFile -NoTypeInformation -Encoding UTF8
Write-Host "Log: $logFile"
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN — 실제 변경 없음. -Apply 로 재실행 시 적용." -ForegroundColor Yellow
}
if ($Apply) {
    Write-Host "APPLIED — git diff 로 변경 검토 + 빌드 확인 후 commit." -ForegroundColor Green
    Write-Host "  git diff > stage29c_rename.patch"
    Write-Host "  npm run build"
    Write-Host "  npx tsc --noEmit"
}

# party_type 특수 케이스 안내
Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "특수 케이스: party_type → party_type_id" -ForegroundColor DarkYellow
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "이 codemod 는 party_type 자동 변경 안 함 (단순 rename 으로 해결 안 되는 FK 매핑)."
Write-Host "별도 manual review: party_type_join_pattern.ts 참조."
Write-Host "audit script 의 A4 결과 사용해서 호출 사이트 list 만들고 case-by-case 처리."
```

#### `RENAME_TABLE.md` (7009 bytes)

```markdown
# Stage 29-c Column Rename Table

handoff §A4 + §6 + 본 chat 의 V1 database.ts 검증 결과 통합.

---

## §1. 자동 변환 가능 (rename_codemod.ps1 처리)

### 1-1. V1 caller bug (DB 컬럼명 불일치)

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 | 영향 |
|---|---|---|---|
| `org_id` | `organization_id` | app.* 다수 (email_whitelist, communications, parties 등) | runtime fail |
| `body_text` | `body_plain` | app.communications | runtime fail |
| `'country'` literal | `'country_code'` | app.parties | runtime fail |
| `.country` accessor | `.country_code` | app.parties (객체 속성) | runtime fail |
| `email_whitelist.value` | `email_whitelist.pattern` | app.email_whitelist | runtime fail |

→ 모두 단순 string replace. `rename_codemod.ps1` 가 처리.

⚠️ **`email_whitelist.value` 케이스**: codemod 가 자동 처리 안 함 (너무 일반적 단어 `value`). audit script A3 에 명시적 패턴 미포함. 별도 grep:
```powershell
Select-String -Path src -Recurse -Include *.ts,*.tsx -Pattern "email_whitelist.*value|value.*email_whitelist"
```
매치된 site case-by-case manual review.

### 1-2. urm.stages 의 정렬 컬럼

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 |
|---|---|---|
| `stage_position` | `sort_order` | urm.stages |

→ 단순 rename. (단 `app.pipeline_stages` 의 컬럼명도 이미 `sort_order` 임 — V1 에서도 stage_position 은 caller bug)

---

## §2. 수동 처리 필요 (codemod 안 함)

### 2-1. party_type → party_type_id (FK)

**가장 영향 큰 변경**. 단순 rename 으로 해결 안 됨.

| V1 패턴 | V2 (urm) 변환 |
|---|---|
| `.eq('party_type', 'company')` | `.eq('party_type_id', <FK_UUID>)` + 별도 JOIN 또는 lookup table mapping |
| `.in('party_type', ['fund', 'individual'])` | (urm 에 fund/individual 없음, hard-delete 완료) → 코드 제거 또는 다른 조건 |
| `party_type === 'paper_mill'` | `party_type_id === <PAPER_MILL_ID>` 또는 `party_type_code === 'paper_mill'` (JOIN 후 alias) |
| `select('party_type')` | `select('party_type:party_types(code)')` (PostgREST JOIN), 또는 raw id 만 |
| INSERT/UPDATE 의 `party_type: 'company'` | `party_type_id: <ID>` |

상세 패턴: `party_type_join_pattern.ts`.

### 2-2. urm.parties.party_type enum (app) → urm.party_types code (urm)

**enum 매핑** (handoff §6 #5 + §4 의 app.parties.party_type enum 5값):

| app enum 값 | urm.party_types.code | 처리 |
|---|---|---|
| `company` | (없음) | profile 테이블 (investor / paper_mill / filler_supplier / buyer / customer / partner) join 으로 결정 |
| `individual` | (없음) | urm.parties 에 0 row (모두 soft-deleted, Stage 29-d 시 drop) |
| `fund` | (없음) | urm.parties 에 0 row (ε hard-delete) |
| `organization` | (없음) | 동상 |
| `government` | `government_grant` | 직접 매핑 |

→ caller logic 이 `party_type === 'fund'` 같은 비교를 하면 → 거의 dead code. 검토 후 제거.

→ `party_type === 'company'` 가장 흔함. urm 측에선 **profile 테이블 존재로 판별**. 예:
```typescript
// V1
const isInvestor = party.party_type === 'company' && /* ... */;

// V2 (urm)
const isInvestor = party.party_type_id === PARTY_TYPE.INVESTOR;
// 또는
const isInvestor = !!(await sbUrm
  .from('investor_profile')
  .select('id')
  .eq('party_id', party.id)
  .maybeSingle()).data;
```

### 2-3. portfolio_company_id (V1) → V2 module_data 보존

handoff §8: `portfolio_company_id (app.ipc)` → drop → `module_data._app_portfolio_company_id` (V2 jsonb)

| V1 (caller) | V2 (urm.investor_portfolio_companies) |
|---|---|
| `.select('portfolio_company_id')` | `.select('module_data')` + `data.module_data._app_portfolio_company_id` |
| `.eq('portfolio_company_id', id)` | 신규 컬럼 `portfolio_company_party_id` 또는 `portfolio_company_name_normalized` 사용 |
| INSERT `{ portfolio_company_id: ... }` | 별도 신설 컬럼 또는 module_data 에 직접 |

→ caller code 의 의도에 따라 다름. case-by-case.

### 2-4. parent_party_id / party_level (3-tier hierarchy)

**Stage 29-b handoff §8: "3-tier hierarchy DROP. parent_party_id, party_level carry 안 함".**

urm.parties 에는 이 컬럼 없음. V1 caller 가 사용한다면:
- (a) 코드 제거 (가장 흔함)
- (b) app.parties carry 영역으로 격리 (Stage 29-d 시 drop)

audit script A8 결과로 site list 확보 후 검토.

---

## §3. 코드 안 건드리는 케이스

### 3-1. module_data._app_* 접근

V1 의 일부 컬럼이 urm 측에서 `module_data` jsonb 의 `_app_*` prefix 키로 보존됨. caller 가 직접 접근하면 그대로 동작.

예: `_app_is_decision_maker`, `_app_module`, `_app_source`, `_app_product_grade`, `_app_organization_id`, `_app_portfolio_company_id`

→ codemod 처리 안 함. (caller 의 의도된 정상 패턴)

### 3-2. 외부 API response 의 필드명

caller code 에 `body_text`, `org_id` 등이 있을 때 외부 API response 파싱 컨텍스트면 정상 — DB call 아님.

→ rename_codemod.ps1 은 false positive 발생 가능. -DryRun + 수동 검토 필수.

대표 false positive 패턴:
- LinkedIn API: `country` (ISO 코드)
- Gmail API: `body` 내부 sub-field
- Slack API: `text` (body_text 아님)

검토 시 line context 확인. import 또는 함수 호출 컨텍스트로 판별.

---

## §4. 적용 순서

1. **dry run 으로 매치 site list 확보**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -DryRun | Tee-Object stage29c_rename_dryrun.log
   ```

2. **stage29c_rename_log.csv 검토**. false positive 식별.

3. **자동 적용 (확신되는 패턴부터)**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -Apply
   ```

4. **빌드 + tsc 확인**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

5. **수동 처리 항목 (§2) 별도 작업**:
   - audit script A4 결과의 party_type 호출 사이트 → `party_type_join_pattern.ts` 패턴 적용
   - audit script A7 결과의 portfolio_companies → V2 패턴
   - audit script A8 결과의 parent_party_id → 제거 또는 격리

6. **다시 빌드 + tsc**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

7. **git diff 검토 + commit**:
   ```powershell
   git diff --stat
   git diff > stage29c_rename.patch
   ```

---

## §5. 통계 추정 (audit script A3 결과로 정확화)

| 카테고리 | 예상 매치 수 (typical project) | 자동 처리 |
|---|---:|---|
| org_id | 5–20 | ✅ |
| body_text | 1–5 | ✅ |
| 'country' literal | 1–3 | ✅ |
| .country accessor | 1–10 | ✅ |
| stage_position | 0–5 | ✅ |
| party_type (직접) | 10–50 | ❌ 수동 |
| portfolio_companies (V1) | 1–10 | ❌ 수동 |
| parent_party_id / party_level | 0–5 | ❌ 수동 |

총 자동 처리 추정: 10–40 매치. 수동 처리 추정: 10–60 매치.
```

