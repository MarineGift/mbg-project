# patch_ai_compose_instructions.ps1 (2026-07-06)
# Adds an instruction textarea to the AI Draft tab so a NEW email can be
# AI-generated from a prompt, and lets reply mode take optional instructions.
# Two files: email-compose.ts (server action generateAIEmail + instructions)
#            compose-email-dialog.tsx (UI + handler).
# Idempotent, marker-guarded, CRLF-normalized, ASCII-only output.
$repo = 'C:\dev\mbg-project'
$failed = 0
function Apply([string]$rel,[string]$old,[string]$new,[string]$marker){
  $p = Join-Path $script:repo $rel
  if(-not(Test-Path $p)){Write-Host('MISSING: '+$rel);$script:failed++;return}
  $t=[System.IO.File]::ReadAllText($p) -replace "`r`n","`n"
  $old=$old -replace "`r`n","`n"; $new=$new -replace "`r`n","`n"; $marker=$marker -replace "`r`n","`n"
  if($t.Contains($marker)){Write-Host('SKIP (already): '+$rel+' :: '+$marker.Substring(0,[Math]::Min(40,$marker.Length)));return}
  if(-not $t.Contains($old)){Write-Host('NO MATCH: '+$rel+' :: '+$marker.Substring(0,[Math]::Min(40,$marker.Length)));$script:failed++;return}
  [System.IO.File]::WriteAllText($p,$t.Replace($old,$new))
  Write-Host('PATCHED: '+$rel)
}

$o1=@'
export interface AIReplyPayload {
  communicationId: string;
  partyId: string;
  contactId?: string | null;
  tone?: "professional" | "friendly" | "concise";
  /** Reply language: "auto" mirrors the language of the original email. */
  language?: "auto" | "en" | "ko";
}
'@
$n1=@'
export interface AIReplyPayload {
  communicationId: string;
  partyId: string;
  contactId?: string | null;
  tone?: "professional" | "friendly" | "concise";
  /** Reply language: "auto" mirrors the language of the original email. */
  language?: "auto" | "en" | "ko";
  /** Optional free-text guidance from the user: what the reply should say/do. */
  instructions?: string;
}

/** New-email (no original message) AI draft request. */
export interface AIComposePayload {
  partyId?: string | null;
  contactId?: string | null;
  /** Recipient email, used as a hint when no contact record is linked. */
  toAddress?: string | null;
  subject?: string | null;
  tone?: "professional" | "friendly" | "concise";
  /** "auto" writes in the language of the instructions; else forces en/ko. */
  language?: "auto" | "en" | "ko";
  /** Required: what the email should say / accomplish. */
  instructions: string;
}
'@
Apply 'src/lib/actions/email-compose.ts' $o1 $n1 'instructions?: string;'

$o2=@'
  const userPrompt = `Original email:
From: ${comm.from_address}
Subject: ${comm.subject}
Body:
${originalBody}

${contactName ? `Recipient name: ${contactName}` : ""}

Write a plain text reply draft for this email. Do not use any HTML tags.`;
'@
$n2=@'
  const instructionBlock = payload.instructions?.trim()
    ? `\n\nWhat this reply must accomplish (follow these instructions closely):\n${payload.instructions.trim()}`
    : "";

  const userPrompt = `Original email:
From: ${comm.from_address}
Subject: ${comm.subject}
Body:
${originalBody}

${contactName ? `Recipient name: ${contactName}` : ""}${instructionBlock}

Write a plain text reply draft for this email. Do not use any HTML tags.`;
'@
Apply 'src/lib/actions/email-compose.ts' $o2 $n2 'instructionBlock'

# append generateAIEmail if absent
$ec3=@'

// ─────────────────────────────────────────────
// AI compose for a BRAND-NEW email (no original message to reply to).
// ─────────────────────────────────────────────
export async function generateAIEmail(payload: AIComposePayload): Promise<{
  success: boolean;
  draft?: string;
  subject?: string;
  error?: string;
}> {
  const instructions = payload.instructions?.trim();
  if (!instructions) {
    return { success: false, error: "Please describe what the email should say." };
  }

  const supabase = await createSupabaseServerClient();

  let contactName = "";
  if (payload.contactId) {
    const { data: c } = await supabase
      .schema("app").from("contacts" as never)
      .select("given_name, family_name")
      .eq("id", payload.contactId)
      .single();
    if (c) contactName = [c.given_name, c.family_name].filter(Boolean).join(" ");
  }

  let partyName = "";
  if (payload.partyId) {
    const { data: pr } = await supabase
      .schema("app").from("parties" as never)
      .select("party_name")
      .eq("id", payload.partyId)
      .single();
    if (pr) partyName = pr.party_name ?? "";
  }

  const tone = payload.tone ?? "professional";
  const language = payload.language ?? "auto";
  const languageInstruction =
    language === "en"
      ? "Write the entire email in English."
      : language === "ko"
        ? "Write the entire email in Korean."
        : "LANGUAGE: Write the email in the same language as the instructions above. If the instructions are in English, write in English; if in Korean, write in Korean. Do not translate.";

  const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  const systemPrompt = `You are a B2B sales email professional drafting a NEW outbound email.
Write a ${tone === "professional" ? "professional and courteous" : tone === "friendly" ? "warm and friendly" : "concise and clear"} email based on the user's instructions.
- If a recipient name is provided, open with a proper salutation; otherwise use a neutral greeting.
- Write in PLAIN TEXT only. Do NOT use HTML tags.
- Separate paragraphs with empty lines (double newline).
- Do NOT include any closing salutation or sign-off and do NOT write the sender's name, title, or company at the end. End immediately after the last body paragraph; the signature is appended automatically.
- On the VERY FIRST line, output a subject line prefixed exactly with "SUBJECT: " and nothing else, then a blank line, then the body. Keep the subject under 78 characters.
- ${languageInstruction}`;

  const contextLines = [
    contactName ? `Recipient name: ${contactName}` : "",
    partyName ? `Recipient organization: ${partyName}` : "",
    payload.toAddress ? `Recipient email: ${payload.toAddress}` : "",
    payload.subject?.trim() ? `Draft subject the user already typed (improve or keep): ${payload.subject.trim()}` : "",
  ].filter(Boolean).join("\n");

  const userPrompt = `${contextLines ? contextLines + "\n\n" : ""}Instructions for the email:\n${instructions}\n\nWrite the email now. Remember: first line "SUBJECT: ...", blank line, then plain-text body, no sign-off.`;

  try {
    const response = await anthropic.messages.create({
      model: process.env.ANTHROPIC_MODEL_SONNET ?? "claude-sonnet-4-6",
      max_tokens: 1200,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });

    let text = response.content
      .filter((b) => b.type === "text")
      .map((b) => (b as { type: "text"; text: string }).text)
      .join("");

    let subject: string | undefined;
    const m = text.match(/^\s*SUBJECT:\s*(.+?)\s*(?:\n|$)/i);
    if (m) {
      subject = m[1].trim();
      text = text.slice(m[0].length);
    }

    const signOffPattern =
      /\n[ \t]*(?:best regards|best wishes|best|kind regards|warm regards|regards|sincerely|respectfully|cheers)[,.!]?[ \t]*(?:\n[^\n]{0,80}){0,4}\s*$/i;
    const cleanedDraft = text.replace(signOffPattern, "").trim();

    return { success: true, draft: cleanedDraft, subject };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
}

'@
$ecp = Join-Path $repo 'src/lib/actions/email-compose.ts'
$ect = [System.IO.File]::ReadAllText($ecp) -replace "`r`n","`n"
if($ect.Contains('export async function generateAIEmail')){Write-Host 'SKIP (already): generateAIEmail'}
else{[System.IO.File]::WriteAllText($ecp, ($ect.TrimEnd()+"`n"+($ec3 -replace "`r`n","`n"))); Write-Host 'PATCHED: email-compose.ts (generateAIEmail appended)'}

$o4=@'
  generateAIReply,

'@
$n4=@'
  generateAIReply,
  generateAIEmail,

'@
Apply 'src/components/email/compose-email-dialog.tsx' $o4 $n4 'generateAIEmail,'

$o5=@'
  const [generatingAI, setGeneratingAI] = useState(false);

'@
$n5=@'
  const [generatingAI, setGeneratingAI] = useState(false);
  const [aiInstruction, setAiInstruction] = useState("");

'@
Apply 'src/components/email/compose-email-dialog.tsx' $o5 $n5 'aiInstruction, setAiInstruction'

$o6=@'
        tone: aiTone,
        language: aiLanguage,
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        toast.success("AI draft generated.");
'@
$n6=@'
        tone: aiTone,
        language: aiLanguage,
        instructions: aiInstruction,
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        toast.success("AI draft generated.");
'@
Apply 'src/components/email/compose-email-dialog.tsx' $o6 $n6 'instructions: aiInstruction,'

$o7=@'
      } else {
        toast.error(result.error ?? "AI generation failed.");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  //
'@
$n7=@'
      } else {
        toast.error(result.error ?? "AI generation failed.");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  // AI generate for a brand-new email (instructions-driven, no original).
  async function handleGenerateAIEmail() {
    if (!aiInstruction.trim()) {
      toast.error("Describe what the email should say first.");
      return;
    }
    setGeneratingAI(true);
    try {
      const result = await generateAIEmail({
        partyId: props.partyId ?? null,
        contactId: selectedContactId ?? props.contactId ?? null,
        toAddress: to || effectiveTo || null,
        subject: subject || null,
        tone: aiTone,
        language: aiLanguage,
        instructions: aiInstruction,
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        if (result.subject && !subject.trim()) setSubject(result.subject);
        toast.success("AI draft generated.");
      } else {
        toast.error(result.error ?? "AI generation failed.");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  //
'@
Apply 'src/components/email/compose-email-dialog.tsx' $o7 $n7 'handleGenerateAIEmail'

$o8=@'
          {activeTab === "ai" && (
            <div className="space-y-2 rounded-md border bg-violet-50/50 p-3">
              {isReplyMode ? (
                <>
                  <div className="flex items-center justify-between gap-2">
                    <Label htmlFor="ai-tone" className="text-xs">
                      Tone
                    </Label>
                    <select
                      id="ai-tone"
                      value={aiTone}
                      onChange={(e) =>
                        setAiTone(
                          e.target.value as "professional" | "friendly" | "concise",
                        )
                      }
                      className="h-7 px-2 text-xs rounded border border-input bg-background"
                    >
                      <option value="professional">Professional</option>
                      <option value="friendly">Friendly</option>
                      <option value="concise">Concise</option>
                    </select>
                  </div>
                  <div className="flex items-center justify-between gap-2">
                    <Label htmlFor="ai-language" className="text-xs">
                      Language
                    </Label>
                    <select
                      id="ai-language"
                      value={aiLanguage}
                      onChange={(e) =>
                        setAiLanguage(e.target.value as "auto" | "en" | "ko")
                      }
                      className="h-7 px-2 text-xs rounded border border-input bg-background"
                    >
                      <option value="auto">Auto (match original)</option>
                      <option value="en">English</option>
                      <option value="ko">Korean</option>
                    </select>
                  </div>
                  <Button
                    type="button"
                    size="sm"
                    onClick={handleGenerateAI}
                    disabled={generatingAI}
                    className="w-full bg-violet-600 hover:bg-violet-700 text-white"
                  >
                    {generatingAI ? (
                      <>
                        <Loader2 className="h-3.5 w-3.5 mr-1.5 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Sparkles className="h-3.5 w-3.5 mr-1.5" />
                        Generate AI reply
                      </>
                    )}
                  </Button>
                </>
              ) : (
                <div className="text-xs text-muted-foreground flex items-start gap-1.5">
                  <Info className="h-3.5 w-3.5 mt-0.5 shrink-0" />
                  <span>
                    AI Draft is available when replying to an inbound message.
                    Open the inbox or party timeline and click <strong>Reply</strong> on an existing email.
                  </span>
                </div>
              )}
            </div>
          )}


'@
$n8=@'
          {activeTab === "ai" && (
            <div className="space-y-2 rounded-md border bg-violet-50/50 p-3">
              <div className="space-y-1">
                <Label htmlFor="ai-instruction" className="text-xs">
                  {isReplyMode ? "What should this reply say? (optional)" : "What should this email say?"}
                </Label>
                <textarea
                  id="ai-instruction"
                  value={aiInstruction}
                  onChange={(e) => setAiInstruction(e.target.value)}
                  rows={4}
                  placeholder={
                    isReplyMode
                      ? "e.g. Thank them, confirm Wednesday 9:30 works, ask them to send the deck template."
                      : "e.g. Intro to Pangaea: FCC paper filler, 9,000 t confirmed demand, raising a $1M SAFE bridge, ask for a 30-min call next week."
                  }
                  className="w-full rounded border border-input bg-background px-2 py-1.5 text-sm resize-y"
                />
                <p className="text-[11px] text-muted-foreground">
                  {isReplyMode
                    ? "Leave blank to auto-draft from the original message, or add specifics to steer the reply."
                    : "Describe the goal, key facts, and the ask. The AI writes the draft; your signature is added at send."}
                </p>
              </div>
              <div className="flex items-center justify-between gap-2">
                <Label htmlFor="ai-tone" className="text-xs">
                  Tone
                </Label>
                <select
                  id="ai-tone"
                  value={aiTone}
                  onChange={(e) =>
                    setAiTone(
                      e.target.value as "professional" | "friendly" | "concise",
                    )
                  }
                  className="h-7 px-2 text-xs rounded border border-input bg-background"
                >
                  <option value="professional">Professional</option>
                  <option value="friendly">Friendly</option>
                  <option value="concise">Concise</option>
                </select>
              </div>
              <div className="flex items-center justify-between gap-2">
                <Label htmlFor="ai-language" className="text-xs">
                  Language
                </Label>
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
              </div>
              <Button
                type="button"
                size="sm"
                onClick={isReplyMode ? handleGenerateAI : handleGenerateAIEmail}
                disabled={generatingAI || (!isReplyMode && !aiInstruction.trim())}
                className="w-full bg-violet-600 hover:bg-violet-700 text-white"
              >
                {generatingAI ? (
                  <>
                    <Loader2 className="h-3.5 w-3.5 mr-1.5 animate-spin" />
                    Generating...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-3.5 w-3.5 mr-1.5" />
                    {isReplyMode ? "Generate AI reply" : "Generate AI email"}
                  </>
                )}
              </Button>
            </div>
          )}


'@
Apply 'src/components/email/compose-email-dialog.tsx' $o8 $n8 'ai-instruction'

if($failed -gt 0){Write-Host ('DONE WITH '+$failed+' FAILURE(S) - do not commit.')}else{Write-Host 'ALL PATCHES APPLIED OK'}
