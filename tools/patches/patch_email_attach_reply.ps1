# patch_email_attach_reply.ps1 (2026-07-06)
# Fix 1: server-action body limit 1MB -> 30MB (multi/large attachments) + 25MB total guard
# Fix 2: per-message reply targeting (In-Reply-To = chosen message) + References chain
# Idempotent: marker-guarded. ASCII-only output. Normalizes CRLF->LF before matching.
$repo = 'C:\dev\mbg-project'
$failed = 0
function Apply-Patch([string]$rel, [string]$old, [string]$new, [string]$marker) {
  $p = Join-Path $script:repo $rel
  if (-not (Test-Path $p)) { Write-Host ('MISSING: ' + $rel); $script:failed++; return }
  $t = [System.IO.File]::ReadAllText($p)
  $t = $t -replace "`r`n", "`n"
  $old = $old -replace "`r`n", "`n"
  $new = $new -replace "`r`n", "`n"
  $marker = $marker -replace "`r`n", "`n"
  if ($t.Contains($marker)) { Write-Host ('SKIP (already patched): ' + $rel + ' :: ' + $marker); return }
  if (-not $t.Contains($old)) { Write-Host ('NO MATCH: ' + $rel + ' :: ' + $marker); $script:failed++; return }
  $t = $t.Replace($old, $new)
  [System.IO.File]::WriteAllText($p, $t)
  Write-Host ('PATCHED: ' + $rel + ' :: ' + $marker)
}

$old1 = @'
  experimental: {

'@
$new1 = @'
  experimental: {
    // Server Actions default body limit is 1 MB, which silently capped email
    // attachment uploads at ~1 MB per file. Raise to cover the 25 MB/file cap.
    serverActions: { bodySizeLimit: '30mb' },

'@
Apply-Patch 'next.config.mjs' $old1 $new1 'bodySizeLimit'

$old2 = @'
  function openReply(tab: 'direct' | 'template' | 'ai') {
    setInitialTab(tab);
    setDialogOpen(true);
  }
'@
$new2 = @'
  const [replyTargetId, setReplyTargetId] = useState<string | null>(null);
  function openReply(tab: 'direct' | 'template' | 'ai', msgId?: string) {
    setReplyTargetId(msgId ?? null);
    setInitialTab(tab);
    setDialogOpen(true);
  }
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old2 $new2 'replyTargetId'

$old3 = @'
  const replyTarget = [...thread].reverse().find((m) => m.direction === 'inbound') ?? null;
'@
$new3 = @'
  const latestInbound = [...thread].reverse().find((m) => m.direction === 'inbound') ?? null;
  const selectedTarget = replyTargetId ? (thread.find((m) => m.id === replyTargetId) ?? null) : null;
  // Per-message reply: an explicitly chosen message wins; default stays the latest inbound.
  const replyTarget = selectedTarget ?? latestInbound;
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old3 $new3 'selectedTarget'

$old4 = @'
          openStatus={openStatuses?.[msg.id]}
          timeZone={timeZone}
        />
'@
$new4 = @'
          openStatus={openStatuses?.[msg.id]}
          timeZone={timeZone}
          onReply={msg.messageId ? () => openReply('direct', msg.id) : undefined}
        />
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old4 $new4 'onReply={msg.messageId'

$old5 = @'
        <ComposeEmailDialog
          open={dialogOpen}
          onOpenChange={setDialogOpen}
'@
$new5 = @'
        <ComposeEmailDialog
          key={replyTarget.id}
          open={dialogOpen}
          onOpenChange={(o) => { setDialogOpen(o); if (!o) setReplyTargetId(null); }}
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old5 $new5 'key={replyTarget.id}'

$old6 = @'
          replyToMessageId={replyTarget.messageId ?? undefined}
          threadId={replyTarget.threadId ?? undefined}
'@
$new6 = @'
          replyToMessageId={replyTarget.messageId ?? undefined}
          replyToReferences={replyTarget.references ?? undefined}
          threadId={replyTarget.threadId ?? undefined}
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old6 $new6 'replyToReferences={replyTarget.references'

$old7 = @'
interface ThreadMessageCardProps {
  msg: CommunicationDetail;
  expanded: boolean;
  onToggle: () => void;
  openStatus?: { firstOpenedAt: string | null; openCount: number };
  timeZone?: string;
}
'@
$new7 = @'
interface ThreadMessageCardProps {
  msg: CommunicationDetail;
  expanded: boolean;
  onToggle: () => void;
  openStatus?: { firstOpenedAt: string | null; openCount: number };
  timeZone?: string;
  /** Present when this specific message can be replied to (has a Message-ID). */
  onReply?: () => void;
}
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old7 $new7 'onReply?: () => void;'

$old8 = @'
function ThreadMessageCard({ msg, expanded, onToggle, openStatus, timeZone }: ThreadMessageCardProps) {
'@
$new8 = @'
function ThreadMessageCard({ msg, expanded, onToggle, openStatus, timeZone, onReply }: ThreadMessageCardProps) {
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old8 $new8 'onReply }: ThreadMessageCardProps'

$old9 = @'
      {expanded && (
        <CardContent className="space-y-3 pt-0">
          {/* Metadata grid */}
'@
$new9 = @'
      {expanded && (
        <CardContent className="space-y-3 pt-0">
          {onReply && (
            <div className="flex justify-end">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-7 text-xs"
                onClick={(e) => { e.stopPropagation(); onReply(); }}
              >
                <Send className="h-3 w-3 mr-1" />
                Reply to this message
              </Button>
            </div>
          )}
          {/* Metadata grid */}
'@
Apply-Patch 'src/components/inbox/communication-detail-view.tsx' $old9 $new9 'Reply to this message'

$old10 = @'
  replyToMessageId?: string;
'@
$new10 = @'
  replyToMessageId?: string;
  /** RFC 5322 References chain of the message being replied to (threading). */
  replyToReferences?: string[];
'@
Apply-Patch 'src/components/email/compose-email-dialog.tsx' $old10 $new10 'replyToReferences?: string[];'

$old11 = @'
        replyToMessageId: props.replyToMessageId,
        threadId: props.threadId,
'@
$new11 = @'
        replyToMessageId: props.replyToMessageId,
        replyToReferences: props.replyToReferences,
        threadId: props.threadId,
'@
Apply-Patch 'src/components/email/compose-email-dialog.tsx' $old11 $new11 'replyToReferences: props.replyToReferences,'

$old12 = @'
    const files = Array.from(e.target.files ?? []);
    if (!files.length) return;

'@
$new12 = @'
    const files = Array.from(e.target.files ?? []);
    if (!files.length) return;

    // Total-size guard: most SMTP relays reject messages over ~25 MB combined.
    const MAX_TOTAL_BYTES = 25 * 1024 * 1024;
    const currentTotal = attachments.reduce((s, a) => s + a.file.size, 0);
    const incomingTotal = files.reduce((s, f) => s + f.size, 0);
    if (currentTotal + incomingTotal > MAX_TOTAL_BYTES) {
      toast.error("Attachments exceed the 25 MB total limit per email.");
      e.target.value = "";
      return;
    }

'@
Apply-Patch 'src/components/email/compose-email-dialog.tsx' $old12 $new12 'MAX_TOTAL_BYTES'

$old13 = @'
  replyToMessageId?: string;       // reply mode
'@
$new13 = @'
  replyToMessageId?: string;       // reply mode
  /** References chain of the replied-to message; the send core appends replyToMessageId. */
  replyToReferences?: string[];
'@
Apply-Patch 'src/lib/actions/email-compose.ts' $old13 $new13 'replyToReferences?: string[];'

$old14 = @'
    references:
      payload.mode === "reply" && payload.replyToMessageId
        ? [payload.replyToMessageId]
        : undefined,
'@
$new14 = @'
    references:
      payload.mode === "reply" && payload.replyToMessageId
        ? [
            ...(payload.replyToReferences ?? []).filter(
              (r) => r && r !== payload.replyToMessageId,
            ),
            payload.replyToMessageId,
          ]
        : undefined,
'@
Apply-Patch 'src/lib/actions/email-compose.ts' $old14 $new14 'payload.replyToReferences ?? []'

if ($failed -gt 0) { Write-Host ('DONE WITH ' + $failed + ' FAILURE(S) - do not commit, report back.') }
else { Write-Host 'ALL PATCHES APPLIED OK' }
