# Handoff 2026-09-24 — AI Draft 회신 언어 고정

## 문제
- 영문 수신 메일에 AI Draft가 한글로 답장 생성
- 원인: 언어 판단을 모델(OpenAI)에 맡김("auto") → 한글로 쓴 Instructions / 인용된 한글 스레드에 끌려감

## 변경 (코드만, DB 변경 없음)
- `src/lib/actions/email-compose.ts`
  - `detectReplyLanguage()` 신설: 인용 이력(`On ... wrote:`, `>`, `...님이 작성:`, `From:/보낸 사람:`) 제거 후 **새 본문 + 제목**의 한글/영문 비율로 판정
  - 규칙 고정: 한글 메일 → 한글, 그 외 전부 → **영문(기본값)**
  - `payload.language`(UI 선택값) 무시 — 서버에서 결정
  - 프롬프트: "Instructions가 한글이어도 회신 언어는 바뀌지 않음" 명시
  - 안전장치: 생성 결과 언어가 틀리면 1회 재생성
- `src/components/email/compose-email-dialog.tsx`
  - Language 드롭다운 제거 → `Same as original (default English)` 고정 표시

## 테스트
- Vinlav(Venkat) 영문 메일 → AI Draft, Instructions를 한글로 입력 → 영문 회신 확인
- 한글 수신 메일 → 한글 회신 확인

## Mover
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_ai_reply_language_fixed.ps1

## Push
cd C:\dev\mbg-project
git status -sb
git add src/lib/actions/email-compose.ts src/components/email/compose-email-dialog.tsx tools/patches/patch_ai_reply_language_fixed.ps1 docs/handoff
git commit -m "ai draft: fix reply language (EN default, KO only for Korean mail)"
git push origin marinebiogroup

## Fallback — patch inline (PowerShell 창에 그대로 붙여넣기)
```powershell
# ============================================================
# patch_ai_reply_language_fixed.ps1  (2026-09-24)
# AI Draft reply language is FIXED server-side:
#   English mail -> English reply, Korean mail -> Korean reply,
#   anything else / unclear -> English (default).
#  A) src/lib/actions/email-compose.ts
#       - detectReplyLanguage(): Hangul vs Latin ratio on the NEW message
#         (quoted history stripped); payload.language ignored
#       - prompt: user instructions (often Korean) never change language
#       - guard: if draft comes back in the wrong language, retry once
#  B) src/components/email/compose-email-dialog.tsx
#       - Language dropdown removed -> static "Same as original (default English)"
# Idempotent: guarded per hunk. ASCII-only.
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
function NL([string]$s) { return $s.Replace("`r`n", "`n") }
function Apply([string]$rel, [string]$name, [string]$guard, [string]$old, [string]$new) {
  $p = Join-Path $repo $rel
  $t = NL ([System.IO.File]::ReadAllText($p))
  if ($t.Contains($guard)) { Write-Host ("SKIP (already patched): " + $name); return }
  $old = NL $old; $new = NL $new
  $i = $t.IndexOf($old)
  if ($i -lt 0) { throw ("ANCHOR NOT FOUND: " + $name) }
  if ($t.IndexOf($old, $i + 1) -ge 0) { throw ("ANCHOR NOT UNIQUE: " + $name) }
  $t = $t.Substring(0, $i) + $new + $t.Substring($i + $old.Length)
  [System.IO.File]::WriteAllText($p, $t, [System.Text.UTF8Encoding]::new($false))
  Write-Host ("PATCHED: " + $name)
}

# ---------- lang-helpers ----------
$old = @'
export async function generateAIReply(payload: AIReplyPayload)
'@
$new = @'
// ---------------------------------------------
// reply language: fixed rule (English default; Korean only for Korean mail)
// ---------------------------------------------
const HANGUL_RE = /[\uAC00-\uD7A3\u3131-\u318E]/g;
const LATIN_RE = /[A-Za-z]/g;

/** Drop quoted history so an old Korean/English thread below the new message
 *  does not decide the language. */
function stripQuotedHistory(text: string): string {
  const lines = text.replace(/\r\n/g, "\n").split("\n");
  const out: string[] = [];
  for (const line of lines) {
    const t = line.trim();
    if (
      /^On .{3,200}wrote:\s*$/i.test(t) ||
      /^-{2,}\s*(Original Message|Forwarded message)/i.test(t) ||
      /\uB2D8\uC774 \uC791\uC131:\s*$/.test(t) ||           // Korean Gmail quote header
      (out.length > 0 && /^(From|\uBCF4\uB0B8 \uC0AC\uB78C|\uBCF4\uB0B8\uC0AC\uB78C)\s*:/.test(t)) // From: header (EN/KO)
    ) break;
    if (t.startsWith(">")) continue;
    out.push(line);
  }
  return out.join("\n");
}

/** Korean only when Hangul clearly dominates; everything else is English. */
function scoreLanguage(text: string): "en" | "ko" {
  const clean = text.replace(/https?:\/\/\S+|\S+@\S+/g, " ");
  const hangul = (clean.match(HANGUL_RE) ?? []).length;
  if (hangul === 0) return "en";
  const latin = (clean.match(LATIN_RE) ?? []).length;
  // one Hangul syllable ~ 2-3 Latin letters of content
  return hangul * 2.5 >= latin ? "ko" : "en";
}

function detectReplyLanguage(subject: string, body: string): "en" | "ko" {
  const main = stripQuotedHistory(body);
  const basis = main.trim().length >= 20 ? main : body;
  return scoreLanguage(`${subject ?? ""}\n${basis}`);
}

export async function generateAIReply(payload: AIReplyPayload)
'@
Apply 'src\lib\actions\email-compose.ts' 'lang-helpers' 'detectReplyLanguage(subject' $old $new

# ---------- lang-rule ----------
$old = @'
  const language = payload.language ?? "auto";
  const languageInstruction =
    language === "en"
      ? "Write the entire reply in English."
      : language === "ko"
        ? "Write the entire reply in Korean."
        : "LANGUAGE: Detect the language of the original email below and write the ENTIRE reply in that same language. If the original email is in English, the reply MUST be in English. Do not default to Korean and do not translate.";
'@ + "`n"
$new = @'
  // Language is FIXED by rule, not by the model or the UI:
  // English mail -> English reply, Korean mail -> Korean reply, default English.
  // (payload.language is ignored on purpose.)
  const language = detectReplyLanguage(comm.subject ?? "", originalBody);
  const languageName = language === "ko" ? "Korean" : "English";
  const languageInstruction =
    `LANGUAGE (mandatory): Write the ENTIRE reply in ${languageName}. ` +
    `The user's instructions may be written in Korean or another language - they are internal guidance only and must NOT change the reply language. ` +
    `Never mix languages and never translate the recipient's name.`;
'@ + "`n"
Apply 'src\lib\actions\email-compose.ts' 'lang-rule' 'detectReplyLanguage(comm.subject' $old $new

# ---------- lang-retry ----------
$old = @'
    const draft = await generateReply({
      system: systemPrompt,
      user: userPrompt,
      maxTokens: 1000,
    });
'@ + "`n"
$new = @'
    let draft = await generateReply({
      system: systemPrompt,
      user: userPrompt,
      maxTokens: 1000,
    });

    // Guard: if the model still answered in the wrong language, retry once.
    if (draft.trim() && scoreLanguage(draft) !== language) {
      draft = await generateReply({
        system: `${systemPrompt}\n- CRITICAL: Your previous draft was in the wrong language. Output ${languageName} ONLY.`,
        user: userPrompt,
        maxTokens: 1000,
      });
    }
'@ + "`n"
Apply 'src\lib\actions\email-compose.ts' 'lang-retry' 'wrong language. Output' $old $new

# ---------- lang-doc ----------
$old = @'
  /** Reply language: "auto" mirrors the language of the original email. */
'@
$new = @'
  /** Ignored: reply language is fixed server-side (English default, Korean only for Korean mail). */
'@
Apply 'src\lib\actions\email-compose.ts' 'lang-doc' 'Ignored: reply language is fixed' $old $new

# ---------- ui-select ----------
$old = @'
                <select
                  id="ai-language"
                  value={aiLanguage}
                  onChange={(e) =>
                    setAiLanguage(e.target.value as "auto" | "en" | "ko")
                  }
                  className="h-7 px-2 text-xs rounded border border-input bg-background"
                >
                  <option value="auto">{isReplyMode ? "Auto (match original)" : "Auto (match instructions)"}</option>
                  <option value="en">English</option>
                  <option value="ko">Korean</option>
                </select>
'@ + "`n"
$new = @'
                <span id="ai-language" className="text-xs text-muted-foreground">
                  {isReplyMode ? "Same as original (default English)" : "English"}
                </span>
'@ + "`n"
Apply 'src\components\email\compose-email-dialog.tsx' 'ui-select' 'Same as original (default English)' $old $new

# ---------- ui-state ----------
$old = @'
  const [aiLanguage, setAiLanguage] = useState<"auto" | "en" | "ko">("auto");
'@
$new = @'
  const [aiLanguage] = useState<"auto" | "en" | "ko">("auto"); // fixed: server decides reply language
'@
Apply 'src\components\email\compose-email-dialog.tsx' 'ui-state' 'fixed: server decides reply language' $old $new

Write-Host "DONE: AI reply language fixed (EN default, KO only for Korean mail)."

```
