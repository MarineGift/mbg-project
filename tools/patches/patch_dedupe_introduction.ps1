# patch_dedupe_introduction.ps1
# Diagnose & fix duplicate Introduction / Notes sections in party-form.tsx.
# The layout patch was meant to move Introduction+Notes to the top and delete
# the originals at the bottom; if its L7 delete-anchor missed, both copies
# remain. This collapses any duplicates to a single top copy. Idempotent.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$path = 'C:\dev\mbg-project\src\components\parties\party-form.tsx'
$c = [System.IO.File]::ReadAllText($path); $c = $c.Replace("`r`n", "`n")

$introCount = ([regex]::Matches($c, '<SectionLabel>Introduction</SectionLabel>')).Count
$notesCount = ([regex]::Matches($c, "<SectionLabel>\{t\('notes'\)\}</SectionLabel>")).Count
Write-Output ('BEFORE: Introduction=' + $introCount + '  Notes=' + $notesCount)

if ($introCount -le 1 -and $notesCount -le 1) {
  Write-Output 'No duplicates in the file on disk. The live site is likely serving an OLD deploy.'
  Write-Output 'ACTION: confirm Railway deployed the latest commit, then hard-refresh (Ctrl+F5).'
  return
}

# Remove the SECOND Introduction..Notes block (the original bottom one), keeping
# the first (top) copy. We match a full Introduction section immediately
# followed by a Separator + Notes section, and delete the trailing duplicate.
$block = @'
          {/* ===================== Introduction ===================== */}
          <section className="space-y-4">
            <SectionLabel>Introduction</SectionLabel>
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="party-intro-ko">{t('introKo')}</Label>
                <Textarea
                  id="party-intro-ko"
                  {...register('introKo')}
                  disabled={isPending}
                  rows={6}
                  placeholder={t('introKoPlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-intro-en">{t('introEn')}</Label>
                <Textarea
                  id="party-intro-en"
                  {...register('introEn')}
                  disabled={isPending}
                  rows={6}
                  placeholder={t('introEnPlaceholder')}
                />
              </div>
              <p className="text-xs text-muted-foreground md:col-span-2">{t('introHint')}</p>
            </div>
          </section>

          <Separator />

          {/* ===================== Notes ===================== */}
          <section className="space-y-2">
            <SectionLabel>{t('notes')}</SectionLabel>
            <Textarea id="party-notes" {...register('notes')} disabled={isPending} rows={5} />
          </section>
'@

$idx = $c.IndexOf($block)
if ($idx -lt 0) {
  Write-Output 'WARN: canonical block not found verbatim; no automatic change made.'
  Write-Output 'Send the current party-form.tsx Introduction area for a targeted fix.'
  return
}
$idx2 = $c.IndexOf($block, $idx + $block.Length)
if ($idx2 -lt 0) {
  Write-Output 'Only one canonical block present; nothing to dedupe here.'
  return
}
# delete the second occurrence (plus a preceding Separator if present)
$sep = "          <Separator />`n`n"
$before = $c.Substring(0, $idx2)
$after  = $c.Substring($idx2 + $block.Length)
if ($before.EndsWith($sep)) { $before = $before.Substring(0, $before.Length - $sep.Length) }
$c = $before + $after

$introAfter = ([regex]::Matches($c, '<SectionLabel>Introduction</SectionLabel>')).Count
$notesAfter = ([regex]::Matches($c, "<SectionLabel>\{t\('notes'\)\}</SectionLabel>")).Count
Write-Output ('AFTER:  Introduction=' + $introAfter + '  Notes=' + $notesAfter)
[System.IO.File]::WriteAllText($path, $c, $utf8)
Write-Output ('WROTE ' + $path)
Write-Output 'Next: npm run build, then commit + push.'
