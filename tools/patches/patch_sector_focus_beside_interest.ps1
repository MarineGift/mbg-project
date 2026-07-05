# patch_sector_focus_beside_interest.ps1
# Move Sector focus into the Tags section, beside Interest Tags (2-col grid).
# Removes the old Sector focus block from Investor profile. Idempotent.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$warn = $false
$path = 'C:\dev\mbg-project\src\components\parties\party-form.tsx'
$c = [System.IO.File]::ReadAllText($path); $c = $c.Replace("`r`n", "`n")

$old_S1 = @'
            <div className="grid grid-cols-1 gap-y-4">
              <div className="space-y-2">
                <Label htmlFor="party-interest-tags">{t('interestTags')}</Label>
                <TagMultiSelect
                  inputId="party-interest-tags"
                  value={watch('interestTags') ?? ''}
                  onChange={(v) => setValue('interestTags', v, { shouldDirty: true })}
                  suggestions={interestTagSuggestions}
                  disabled={isPending}
                  placeholder={t('interestTagsPlaceholder')}
                />
                <p className="text-xs text-muted-foreground">{t('interestTagsHint')}</p>
              </div>
'@
$new_S1 = @'
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="party-interest-tags">{t('interestTags')}</Label>
                <TagMultiSelect
                  inputId="party-interest-tags"
                  value={watch('interestTags') ?? ''}
                  onChange={(v) => setValue('interestTags', v, { shouldDirty: true })}
                  suggestions={interestTagSuggestions}
                  disabled={isPending}
                  placeholder={t('interestTagsPlaceholder')}
                />
                <p className="text-xs text-muted-foreground">{t('interestTagsHint')}</p>
              </div>
              {isInvestor && (
                <div className="space-y-2">
                  <Label htmlFor="party-sector-focus">Sector focus</Label>
                  <Input
                    id="party-sector-focus"
                    {...register('sectorFocus')}
                    disabled={isPending}
                    placeholder="materials, industrial, healthcare, sustainability"
                  />
                  <p className="text-xs text-muted-foreground">Comma-separated.</p>
                </div>
              )}
'@
if ($c.Contains($new_S1)) { Write-Output 'SKIP S1' }
elseif ($c.Contains($old_S1)) { $c = $c.Replace($old_S1, $new_S1); Write-Output 'OK   S1' }
else { Write-Output 'WARN S1: anchor not found'; $warn = $true }

$old_S2 = @'

                  {/* Sector focus */}
                  <div className="space-y-2 md:col-span-2">
                    <Label htmlFor="party-sector-focus">Sector focus</Label>
                    <Input
                      id="party-sector-focus"
                      {...register('sectorFocus')}
                      disabled={isPending}
                      placeholder="materials, industrial, healthcare, sustainability"
                    />
                    <p className="text-xs text-muted-foreground">Comma-separated.</p>
                  </div>

'@
if ($c.Contains($old_S2)) { $c = $c.Replace($old_S2, "`n"); Write-Output 'OK   S2: removed' }
else { Write-Output 'SKIP/WARN S2: anchor not found (already moved?)' }

[System.IO.File]::WriteAllText($path, $c, $utf8); Write-Output ('WROTE ' + $path)
if ($warn) { Write-Output 'Anchor missing - review before build.' }
Write-Output 'Next: npm run build, then commit + push.'
