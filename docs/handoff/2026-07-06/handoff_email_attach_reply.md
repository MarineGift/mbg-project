# Handoff — 메일 발송 2건 수정: 다중/대용량 첨부 + 메시지별 Reply (2026-07-06)

## 근본 원인 진단
### 문제 1 — "첨부가 한 개만 발송되는 것 같다"
UI(파일 input `multiple`)와 발송 코어(`send-outbound.ts`의 attachments 배열)는 **원래 다중 첨부를 지원**합니다. 진짜 원인은 업로드가 **Next.js Server Action**(`uploadAttachment`)을 경유하는데, **Server Action의 기본 body 한도가 1MB**라는 것. `next.config.mjs`에 `bodySizeLimit` 설정이 없어서:
- 1MB 초과 파일(덱 PDF 등) → 업로드 실패
- 여러 개 선택 시 작은 파일만 성공 → "한 개만 되는" 체감

### 문제 2 — 스레드 중간 메일에 회신 불가
`communication-detail-view.tsx`의 reply 대상이 `replyTarget = 최신 inbound 메시지` **하드코딩**. 스레드 전체에 Reply 버튼이 하나뿐이라 개별 메시지 지정 불가. 추가로 `email-compose.ts`가 References를 `[replyToMessageId]` 하나로만 보내 RFC 5322 체인이 끊겼음 (inbound 파서는 references를 이미 DB에 저장 중 — 쓰기만 하면 되는 상태였음).

## 수정 내역 (4파일 · 14 hunks)
| 파일 | 변경 |
|---|---|
| `next.config.mjs` | `experimental.serverActions.bodySizeLimit: '30mb'` (파일당 25MB 한도 + FormData 오버헤드 여유) |
| `compose-email-dialog.tsx` | ① 첨부 **합계 25MB 가드**(SMTP 릴레이 한도) ② `replyToReferences` prop 수신 → payload 전달 |
| `communication-detail-view.tsx` | ① 각 메시지 카드(펼침 상태)에 **"Reply to this message"** 버튼(Message-ID 있는 메시지) ② 선택 메시지가 reply 대상이 되고 기본값은 기존대로 최신 inbound ③ 다이얼로그 `key={replyTarget.id}`로 대상 전환 시 초기화 ④ 닫으면 선택 리셋 ⑤ 대상 메시지의 references 전달 |
| `email-compose.ts` | References = **원본 체인 + 원본 Message-ID** (중복 제거) → Gmail/Outlook이 정확한 위치에 스레딩 |

동작: 스레드에서 아무 메시지나 펼치면 우측 상단에 "Reply to this message" → 그 메일의 From이 수신자, Re: 제목, **In-Reply-To가 그 메시지**로 발송됩니다. 하단의 기존 Reply 버튼은 종전대로 최신 inbound 대상.

## 적용 순서
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_email_attach_reply.ps1
```
기대 출력: `PATCHED: ...` 14줄 + `ALL PATCHES APPLIED OK`. (재실행 시 `SKIP (already patched)` — idempotent. `NO MATCH`가 하나라도 나오면 커밋하지 말고 회신.)

## 검증 (로컬)
```powershell
cd C:\dev\mbg-project
npm run build   # 타입 에러 없어야 함
```
수동 테스트: ① 3~5MB PDF 2개 + 이미지 1개 첨부 발송 → 3개 모두 도착 ② 26MB 합계 시도 → 토스트 차단 ③ Pangaea 스레드에서 **중간 메시지** 펼침 → Reply to this message → 발송 후 Gmail에서 해당 메시지 아래에 스레딩되는지 확인.

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git status -sb
git add next.config.mjs src/components/inbox/communication-detail-view.tsx src/components/email/compose-email-dialog.tsx src/lib/actions/email-compose.ts tools/patches/patch_email_attach_reply.ps1 "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_email_attach_reply.md"
git commit -m "fix(email): server-action 30mb body limit + 25mb total guard; per-message reply with RFC references chain"
git push origin marinebiogroup
```
⚠ `next.config.mjs` 변경은 **Railway 재배포가 있어야 반영**됩니다 — push가 곧 배포입니다.

## 인라인 patch (fallback — .ps1이 no-op일 때 콘솔에 통째로 붙여넣기)
```powershell
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
```

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='patch_email_attach_reply*.ps1';  d='C:\dev\mbg-project\tools\patches\patch_email_attach_reply.ps1'},
  @{f='handoff_email_attach_reply*.md'; d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_email_attach_reply.md')}
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path $dl -Filter $m.f -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName -ErrorAction SilentlyContinue
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($m.d)) | Out-Null
    [System.IO.File]::Copy($src.FullName, $m.d, $true); Remove-Item $src.FullName -Force
    Write-Host ("MOVED: " + $src.Name)
  } else { Write-Host ("SKIP (not found): " + $m.f) }
}
```

## 남은 것
- Pangaea 이메일 발송이 아직이면: 이 패치 배포를 기다릴 필요 없음 — one-pager PDF 1개(74KB)는 현재 시스템으로도 발송 가능
- 대기: 9c-2/9d 커밋, Humba LinkedIn 주소
