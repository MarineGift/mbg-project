#!/usr/bin/env bash
# Stage 29-c Caller Code Audit Script (Bash / WSL / Linux fallback)
# 사용법:
#   ./audit.sh <project-root> [output-file]
#
# 의존: ripgrep (rg). 없으면: grep -rE fallback.

set -euo pipefail

PROJECT_ROOT="${1:?Usage: $0 <project-root> [output-file]}"
OUT_FILE="${2:-./stage29c_audit_report.md}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

EXCLUDE_DIRS=("node_modules" ".next" "dist" "build" ".git" "coverage" "outputs" "stage29c")
INCLUDE_EXTS=("ts" "tsx" "js" "jsx" "mts" "cts")

if command -v rg >/dev/null 2>&1; then
    USE_RG=1
else
    USE_RG=0
    echo "Warning: ripgrep (rg) not found, using grep fallback (slower)" >&2
fi

rg_exclude_args=()
for d in "${EXCLUDE_DIRS[@]}"; do
    rg_exclude_args+=("--glob" "!**/$d/**")
done

rg_include_args=()
for e in "${INCLUDE_EXTS[@]}"; do
    rg_include_args+=("--glob" "*.$e")
done

find_pattern() {
    local pat="$1"
    if [[ $USE_RG -eq 1 ]]; then
        rg --line-number --no-heading "${rg_exclude_args[@]}" "${rg_include_args[@]}" -e "$pat" "$PROJECT_ROOT" 2>/dev/null || true
    else
        local exclude_args=()
        for d in "${EXCLUDE_DIRS[@]}"; do
            exclude_args+=("--exclude-dir=$d")
        done
        local include_args=()
        for e in "${INCLUDE_EXTS[@]}"; do
            include_args+=("--include=*.$e")
        done
        grep -rEn "${exclude_args[@]}" "${include_args[@]}" "$pat" "$PROJECT_ROOT" 2>/dev/null || true
    fi
}

# --- audit definitions
declare -a AUDIT_NAMES=(
    "A1. SbClient factory 정의"
    "A2. schema-prefixed .from() 호출"
    "A3. 잘못된 컬럼 reference (V1 bug)"
    "A4. party_type 직접 enum 비교"
    "A5. RPC 호출"
    "A6. 9 deprecated profile 테이블 reference"
    "A7. portfolio_companies (V1) reference"
    "A8. parent_party_id / party_level reference"
    "A9. urm 신규 테이블 references"
    "A10. fund / organization party_type 사용"
)

declare -a AUDIT_DESCS=(
    "SupabaseClient<Database, 'app'> 등 generic schema 정의 site"
    ".from('app.*') 또는 .from('urm.*') 패턴"
    "DB 에 실재하지 않는 컬럼 이름. caller 의 hard-coded bug"
    "urm 에서 party_type_id (FK) 로 바뀐 패턴"
    "Supabase RPC 호출. V1→V2 함수 매핑 검토"
    "Stage 29-b δ 에서 DROP 된 테이블"
    "Stage 29-b δ Port-1 에서 DROP"
    "3-tier hierarchy DROP 결정. carry 안 함"
    "이미 urm 으로 일부 이전된 코드"
    "Stage 29-b ε 에서 hard-delete"
)

declare -a AUDIT_PATTERNS=(
    "SupabaseClient<Database|createClient<Database|createServerClient<Database|createBrowserClient<Database"
    "\.from\(['\"]app\.|\.from\(['\"]urm\.|\.schema\(['\"]app['\"]\)|\.schema\(['\"]urm['\"]\)"
    "\\borg_id\\b|\\bbody_text\\b|['\"]country['\"]|\.country[[:space:]]*[=,)]|stage_position"
    "\.eq\(['\"]party_type['\"]|party_type[[:space:]]*===|party_type:[[:space:]]*['\"]|PartyType\.|party_type[[:space:]]*[=:][[:space:]]*['\"]"
    "\.rpc\(['\"][a-zA-Z_]+|supabase\.rpc"
    "buyer_profile|buyer_partner_profile|customer_profile|govt_grant_profile|govt_grant_contact_profile|partner_profile|partner_audits|partner_capabilities|filler_supplier_contact_profile"
    "\\bportfolio_companies\\b|v_portfolio_with_investors"
    "parent_party_id|\\bparty_level\\b"
    "contacts_history|party_supply_links|plant_supply_links|deal_checklists|deal_stage_history|engagement_attendees|engagement_documents|party_types"
    "['\"]fund['\"]|['\"]organization['\"]"
)

declare -a AUDIT_CRITICAL=(1 1 1 1 0 1 1 0 0 0)

# --- run
mkdir -p "$(dirname "$OUT_FILE")"

{
    echo "# Stage 29-c Caller Audit Report"
    echo ""
    echo "**Project root**: \`$PROJECT_ROOT\`"
    echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "---"
    echo ""
} > "$OUT_FILE"

# summary placeholder
{
    echo "## §0. Summary"
    echo ""
    echo "| Crit | Audit | Matches |"
    echo "|---|---|---:|"
} >> "$OUT_FILE.summary"

{
    echo "---"
    echo ""
} >> "$OUT_FILE.summary"

# detail body
detail_file="$OUT_FILE.details"
: > "$detail_file"

for i in "${!AUDIT_NAMES[@]}"; do
    name="${AUDIT_NAMES[$i]}"
    desc="${AUDIT_DESCS[$i]}"
    pat="${AUDIT_PATTERNS[$i]}"
    crit="${AUDIT_CRITICAL[$i]}"
    
    echo "[$name] $desc" >&2
    matches="$(find_pattern "$pat" || true)"
    count=$(echo -n "$matches" | grep -c "" || true)
    if [[ -z "$matches" ]]; then count=0; fi
    
    mark="ℹ️"
    if [[ $crit -eq 1 ]]; then mark="⚠️"; fi
    
    echo "| $mark | $name | $count |" >> "$OUT_FILE.summary.tmp"
    
    {
        echo "## $name"
        echo ""
        echo "**Description**: $desc"
        echo "**Pattern**: \`$pat\`"
        echo "**Match count**: **$count**"
        echo ""
        
        if [[ $count -eq 0 ]]; then
            echo "(매치 없음)"
        else
            echo "| File | Line | Content |"
            echo "|---|---:|---|"
            echo "$matches" | while IFS=: read -r file line content; do
                rel="${file#$PROJECT_ROOT/}"
                content="$(echo "$content" | sed 's/|/\\|/g' | head -c 120)"
                echo "| \`$rel\` | $line | \`$content\` |"
            done
        fi
        echo ""
    } >> "$detail_file"
    
    if [[ $count -eq 0 ]]; then
        echo "  -> 0 matches"
    else
        echo "  -> $count matches"
    fi
done

# 조립: header + summary + detail
{
    head -n 6 "$OUT_FILE"
    echo "## §0. Summary"
    echo ""
    echo "| Crit | Audit | Matches |"
    echo "|---|---|---:|"
    [[ -f "$OUT_FILE.summary.tmp" ]] && cat "$OUT_FILE.summary.tmp"
    echo ""
    echo "---"
    echo ""
    cat "$detail_file"
} > "$OUT_FILE.new"

mv "$OUT_FILE.new" "$OUT_FILE"
rm -f "$OUT_FILE.summary" "$OUT_FILE.summary.tmp" "$OUT_FILE.details"

echo ""
echo "=== Done ==="
echo "Report: $OUT_FILE"
