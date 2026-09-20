# patch_inbox_delete_block_v2.ps1.txt
#
# Rename to .ps1 and run, or paste the body into PowerShell.
#
# Replaces the earlier auto-deciding version. The Inbox selection bar now
# offers three explicit actions:
#
#   Delete                  delete the messages only
#   Delete + block domain   delete, and block every sender domain
#                           (newsletters: news@, no-reply@, info@ all stop)
#   Delete + block address  delete, and block only those exact addresses
#                           (one unwanted person, colleagues unaffected)
#
# The confirm dialog lists the exact patterns that will be written, so the
# scope is visible before committing. Free-mail domains (gmail, naver,
# outlook...) are refused for a domain block and reported, since blocking
# them would cut off every other sender on that host.
#
# Entries land in app.email_blocklist via the existing addBlocklistEntry
# action and can be reviewed or lifted in Settings, Email blocklist.
#
# Seven edits in one pass. If any anchor is missing the script exits
# before writing, so the file is never left half-patched.
#
# Idempotent: guarded on handleBulkDeleteAndBlock.

$p = 'C:\dev\mbg-project\src\components\inbox\inbox-table.tsx'
$t = [System.IO.File]::ReadAllText($p) -replace "`r`n", "`n"

if ($t.Contains('handleBulkDeleteAndBlock')) { Write-Host 'SKIP already applied'; exit }

# ---------- 1) import the blocklist action ----------
$oldImp = "import { InboxDeleteButton } from './inbox-delete-button';"
if (-not $t.Contains($oldImp)) { Write-Host 'WARN import anchor not found'; exit }
$t = $t.Replace(
  $oldImp,
  "import { InboxDeleteButton } from './inbox-delete-button';`nimport { addBlocklistEntry } from '@/lib/actions/email-blocklist';")

# ---------- 2) icons ----------
$oldIcon = "  Trash2,"
if (-not $t.Contains($oldIcon)) { Write-Host 'WARN icon anchor not found'; exit }
$t = $t.Replace($oldIcon, "  Trash2,`n  Ban,`n  Globe,")

# ---------- 3) state ----------
$oldState = "  const [bulkDialogOpen, setBulkDialogOpen] = useState(false);"
if (-not $t.Contains($oldState)) { Write-Host 'WARN state anchor not found'; exit }
$t = $t.Replace(
  $oldState,
  "  const [bulkDialogOpen, setBulkDialogOpen] = useState(false);`n  const [blockKind, setBlockKind] = useState<'domain' | 'address' | null>(null);")

# ---------- 4) handler + pattern helper ----------
$oldFn = @"
  function handleBulkDelete() {
"@ -replace "`r`n", "`n"

$newFn = @"
  // Blocking one of these by domain would cut off every other sender on
  // the same host, so a domain block is refused for them.
  const FREE_MAIL = new Set([
    'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com',
    'naver.com', 'daum.net', 'kakao.com', 'qq.com', '163.com', 'hanmail.net',
  ]);

  // What would actually be written, for the chosen scope.
  function blockPatterns(kind: 'domain' | 'address'): {
    patterns: string[];
    refused: string[];
  } {
    const patterns = new Set<string>();
    const refused = new Set<string>();
    for (const r of rows) {
      if (!selected.has(r.id)) continue;
      const addr = (r.fromAddress ?? '').trim().toLowerCase();
      if (!addr.includes('@')) continue;
      if (kind === 'address') {
        patterns.add(addr);
        continue;
      }
      const domain = addr.split('@')[1] ?? '';
      if (!domain) continue;
      if (FREE_MAIL.has(domain)) refused.add(domain);
      else patterns.add(domain);
    }
    return { patterns: Array.from(patterns).sort(), refused: Array.from(refused).sort() };
  }

  function handleBulkDeleteAndBlock() {
    if (!blockKind) return;
    const kind = blockKind;
    const ids = Array.from(selected);
    const { patterns } = blockPatterns(kind);

    startTransition(async () => {
      let blocked = 0;
      const already: string[] = [];
      const failed: string[] = [];
      for (const pattern of patterns) {
        const res = await addBlocklistEntry(pattern, kind, 'Blocked from Inbox');
        if (res.ok) blocked += 1;
        else if (/already/i.test(res.error ?? '')) already.push(pattern);
        else failed.push(pattern);
      }

      const { deleted, errors } = await deleteCommunicationsBulk(ids);
      if (deleted > 0) toast.success(`${deleted} message${deleted > 1 ? 's' : ''} deleted`);
      if (errors.length > 0) toast.error(`${errors.length} failed to delete`);
      if (blocked > 0) toast.success(`${blocked} ${kind}${blocked > 1 ? 's' : ''} blocked`);
      if (already.length > 0) toast.info(`Already blocked: ${already.join(', ')}`);
      if (failed.length > 0) toast.error(`Could not block: ${failed.join(', ')}`);

      setSelected(new Set());
      setBlockKind(null);
      router.refresh();
    });
  }

  function handleBulkDelete() {
"@ -replace "`r`n", "`n"

if (-not $t.Contains($oldFn)) { Write-Host 'WARN handler anchor not found'; exit }
$t = $t.Replace($oldFn, $newFn)

# ---------- 5) the two block buttons ----------
$oldBtn = @"
            <Trash2 className="h-3.5 w-3.5" />
            Delete Selected
          </Button>
"@ -replace "`r`n", "`n"

$newBtn = @"
            <Trash2 className="h-3.5 w-3.5" />
            Delete Selected
          </Button>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5"
            onClick={() => setBlockKind('domain')}
            disabled={isPending}
            title="Delete these messages and block the whole sending domain"
          >
            <Globe className="h-3.5 w-3.5" />
            Delete + block domain
          </Button>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5"
            onClick={() => setBlockKind('address')}
            disabled={isPending}
            title="Delete these messages and block only these exact addresses"
          >
            <Ban className="h-3.5 w-3.5" />
            Delete + block address
          </Button>
"@ -replace "`r`n", "`n"

if (-not $t.Contains($oldBtn)) { Write-Host 'WARN button anchor not found'; exit }
$t = $t.Replace($oldBtn, $newBtn)

# ---------- 6) confirm dialog listing the exact patterns ----------
$oldDlg = @"
      <Dialog open={bulkDialogOpen} onOpenChange={setBulkDialogOpen}>
"@ -replace "`r`n", "`n"

$newDlg = @"
      <Dialog open={blockKind !== null} onOpenChange={(o) => { if (!o) setBlockKind(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Ban className="h-5 w-5 text-destructive" />
              Delete and block by {blockKind === 'domain' ? 'domain' : 'address'}?
            </DialogTitle>
            <DialogDescription asChild>
              <div>
                <span className="block text-sm">
                  Deletes <strong>{selected.size}</strong> message{selected.size > 1 ? 's' : ''} and
                  blocks {blockKind === 'domain'
                    ? 'everything from these domains'
                    : 'these exact addresses only'}:
                </span>
                {blockKind && (
                  <span className="mt-2 block max-h-40 overflow-y-auto rounded-md border bg-muted/30 px-3 py-2 font-mono text-xs">
                    {blockPatterns(blockKind).patterns.length > 0
                      ? blockPatterns(blockKind).patterns.join('\n')
                      : 'nothing to block'}
                  </span>
                )}
                {blockKind === 'domain' && blockPatterns('domain').refused.length > 0 && (
                  <span className="mt-2 block text-sm text-amber-600">
                    Skipped (free mail, blocking the domain would cut off everyone
                    else on it): {blockPatterns('domain').refused.join(', ')}.
                    Use block by address for those.
                  </span>
                )}
                <span className="mt-2 block text-sm text-muted-foreground">
                  Reviewable in Settings, Email blocklist.
                </span>
                <span className="mt-2 block text-sm font-medium text-destructive">
                  The deletion cannot be undone.
                </span>
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBlockKind(null)} disabled={isPending}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleBulkDeleteAndBlock} disabled={isPending}>
              {isPending ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" />Working…</>
              ) : (
                `Delete and block`
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={bulkDialogOpen} onOpenChange={setBulkDialogOpen}>
"@ -replace "`r`n", "`n"

if (-not $t.Contains($oldDlg)) { Write-Host 'WARN dialog anchor not found'; exit }
$t = $t.Replace($oldDlg, $newDlg)

[System.IO.File]::WriteAllText($p, $t)
Write-Host 'OK  inbox: Delete, Delete + block domain, Delete + block address'
