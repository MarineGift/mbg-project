# ============================================================
# patch_agent_role_type_align.ps1  (2026-07-06)
# OPTIONAL cleanup: align the AgentRole TS union with the ACTUAL roles in the
# DB. Probe showed the real enum/lookup labels are:
#   classifier, reply_drafter, strategy_advisor, summarizer,
#   extractor, translator, task_decomposer
# The code had `content_extractor` (never a real DB value) and was missing
# `translator`. This corrects the union so a future translator/extractor agent
# typechecks. Purely additive to correctness; does not affect Phase 4 runtime
# (task_decomposer was already correct).
# Idempotent. ASCII-only output.
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
function NL([string]$s) { return $s.Replace("`r`n", "`n") }

$aiPath = Join-Path $repo 'src\types\ai.ts'
$ai = [System.IO.File]::ReadAllText($aiPath).Replace("`r`n", "`n")

if ($ai.Contains("'translator'") -and -not $ai.Contains("'content_extractor'")) {
  Write-Host 'SKIP (already aligned): ai.ts'
} else {
  $old = NL @'
  | 'summarizer' // body summarizer (Haiku)
  | 'content_extractor' // scraping-result normalizer (Haiku)
  | 'task_decomposer'; // goal -> subtasks (Haiku, JSON)
'@
  $new = NL @'
  | 'summarizer' // body summarizer (Haiku)
  | 'extractor' // scraping-result normalizer (Haiku)
  | 'translator' // translator (Haiku)
  | 'task_decomposer'; // goal -> subtasks (Haiku, JSON)
'@
  if (-not $ai.Contains($old)) { throw 'ANCHOR NOT FOUND: AgentRole union (content_extractor block)' }
  $ai = $ai.Replace($old, $new)
  [System.IO.File]::WriteAllText($aiPath, $ai, [System.Text.UTF8Encoding]::new($false))
  Write-Host 'PATCHED: ai.ts (AgentRole aligned: content_extractor -> extractor, +translator)'
}

Write-Host 'DONE. Run npm run build to confirm no callers referenced content_extractor.'
