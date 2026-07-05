# Handoff — Sector focus를 Interest Tags 옆으로 이동 (2026-07-04)

## 변경
- Tags 섹션을 2열 그리드로 (md:grid-cols-2): **왼쪽 Interest Tags | 오른쪽 Sector focus**
- Investor profile 섹션의 기존 Sector focus 블록 제거 (중복 방지)
- Sector focus는 투자자에게만 표시 (`isInvestor` 가드) — 다른 party 타입에는 investor_profile이 없으므로
- 반응형: 모바일 1열 → md 이상 2열

## 참고 (선행 확인됨)
- geographic_focus 컬럼 drop 검증 완료 (CSV #54: sector_focus만 남음)

## 실행
1. 아래 인라인 패치 → npm run build → finish block

## 인라인 패치

```powershell
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
```

## Finish block

```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/components/parties/party-form.tsx tools/ docs/
git commit -m "feat(party-form): move Sector focus beside Interest Tags (2-col Tags section, investor-only)"
git push origin marinebiogroup
```
