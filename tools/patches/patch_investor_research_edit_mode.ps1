# patch_investor_research_edit_mode.ps1.txt
#
# Rename to .ps1 and run, or paste the body into PowerShell.
#
# What it changes in src/components/parties/investor-analysis-panel.tsx
#   - The research box is now READ-ONLY by default: saved text renders as
#     formatted, scrollable prose instead of a permanently open textarea.
#   - Edit switches to a tall textarea with Save / Cancel.
#   - Delete removes the research note, with a confirm.
#   - Cancel restores the last saved text and clears the dirty flag, so the
#     unsaved-changes warning no longer fires after an abandoned edit.
#
# Idempotent: the guard checks for the editingNotes state hook.

$p = 'C:\dev\mbg-project\src\components\parties\investor-analysis-panel.tsx'
$t = [System.IO.File]::ReadAllText($p) -replace "`r`n", "`n"

if ($t.Contains('editingNotes')) {
  Write-Host 'SKIP already applied'
  exit
}

# ---------- 1) add the edit-mode state next to the existing notes state ----------
$oldState = "  const [savingNotes, setSavingNotes] = useState(false)"
$newState = @"
  const [savingNotes, setSavingNotes] = useState(false)
  const [editingNotes, setEditingNotes] = useState(false)
"@ -replace "`r`n", "`n"

if (-not $t.Contains($oldState)) {
  Write-Host 'WARN state anchor not found - aborting'
  exit
}
$t = $t.Replace($oldState, $newState)

# ---------- 2) replace the header buttons + textarea with read/edit modes ----------
$oldBlock = @"
            {dirty && <span className="text-xs text-amber-600">Unsaved changes</span>}
            <Button size="sm" onClick={handleSaveNotes} disabled={savingNotes || !dirty}>
              {savingNotes ? 'Saving...' : 'Save'}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              className="text-muted-foreground hover:text-red-600"
              onClick={handleClearNotes}
              disabled={savingNotes || (!notes && !savedNotes)}
            >
              Clear
            </Button>
          </div>
        </div>

        <Textarea
          className="mt-3 min-h-[220px] text-sm"
          placeholder={loading ? 'Loading...' : 'What did we find out about this firm?'}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          disabled={loading}
        />
      </section>
"@ -replace "`r`n", "`n"

$newBlock = @"
            {editingNotes && dirty && (
              <span className="text-xs text-amber-600">Unsaved changes</span>
            )}

            {editingNotes ? (
              <>
                <Button
                  size="sm"
                  onClick={async () => {
                    await handleSaveNotes()
                    setEditingNotes(false)
                  }}
                  disabled={savingNotes}
                >
                  {savingNotes ? 'Saving...' : 'Save'}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => {
                    setNotes(savedNotes)
                    setEditingNotes(false)
                  }}
                  disabled={savingNotes}
                >
                  Cancel
                </Button>
              </>
            ) : (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  className="gap-1.5"
                  onClick={() => setEditingNotes(true)}
                  disabled={loading}
                >
                  <Pencil className="h-3.5 w-3.5" />
                  {savedNotes ? 'Edit' : 'Add research'}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  className="gap-1.5 text-muted-foreground hover:text-red-600"
                  onClick={async () => {
                    if (!window.confirm('Delete the research note for this party?')) return
                    await handleClearNotes()
                    setEditingNotes(false)
                  }}
                  disabled={savingNotes || !savedNotes}
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  Delete
                </Button>
              </>
            )}
          </div>
        </div>

        {editingNotes ? (
          <Textarea
            className="mt-3 min-h-[60vh] resize-y text-sm leading-relaxed"
            placeholder={loading ? 'Loading...' : 'What did we find out about this firm?'}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            disabled={loading}
            autoFocus
          />
        ) : savedNotes ? (
          <div className="mt-3 max-h-[70vh] overflow-y-auto whitespace-pre-wrap rounded-md border bg-muted/20 px-4 py-3 text-sm leading-relaxed">
            {savedNotes}
          </div>
        ) : (
          <p className="mt-3 rounded-md border border-dashed px-4 py-8 text-center text-sm text-muted-foreground">
            {loading ? 'Loading...' : 'No research yet. Use Add research to start.'}
          </p>
        )}
      </section>
"@ -replace "`r`n", "`n"

if (-not $t.Contains($oldBlock)) {
  Write-Host 'WARN research block not found - aborting, nothing written'
  exit
}
$t = $t.Replace($oldBlock, $newBlock)

[System.IO.File]::WriteAllText($p, $t)
Write-Host 'OK  investor research: read mode + Edit + Delete'
