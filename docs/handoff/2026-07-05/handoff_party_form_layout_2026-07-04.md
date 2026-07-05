# Handoff — Party 폼 레이아웃 재구성 (2026-07-04)

## 반영 사항
| 요구 | 구현 |
|---|---|
| Name 옆 Legal name, 옆 Status | 한 줄 반응형 행 (1열 → sm:2열 → lg:3열) |
| Website/Email/Source 한 줄 | 동일 반응형 행 |
| Introduction·Notes 상단으로 | Basic information 바로 아래로 이동 (Location 위) |
| Geographic focus 삭제 | 폼·zod·액션·detail 쿼리·프로필 카드·마인드맵 + **DB 컬럼 drop** — 국가 데이터는 parties에 이미 존재 |
| Sector Focus vs Industry Tags | **Industry Tags 삭제** — D6-5e 이후 저장되지 않는 죽은 필드. Sector Focus는 디렉토리 필터·캠페인의 근간(investor_sector_focus)이라 유지 |
| 반응형 | 주요 행 grid-cols-1 / sm:grid-cols-2 / lg:grid-cols-3 |

## ⚠️ 실행 순서 (RPC 때와 반대!)
```
1) 인라인 패치 (5개 파일 19앵커, 순차 검증 완료)
2) npm run build
3) commit + push → Railway 배포 완료 대기
4) 그 다음에 fix_drop_geographic_focus.sql 실행
   (이전 배포 코드가 이 컬럼을 select하므로 먼저 drop하면 상세 페이지 500)
```

## 인라인 패치

```powershell
# patch_party_form_layout.ps1
# Party form restructure (2026-07-04):
#  - Name | Legal name | Status in one responsive row
#  - Website | Email | Source in one responsive row
#  - Introduction + Notes moved to the top (right under Basic information)
#  - Industry Tags field removed (duplicated Sector focus; not persisted D6-5e)
#  - Geographic focus removed end-to-end (form/zod/action/detail/card/mindmap)
#  - responsive grids: grid-cols-1 / sm:2 / lg:3
# ORDER: apply patch -> build -> push -> AFTER deploy run
#        fix_drop_geographic_focus.sql (old code selects the column!)
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$warn = $false


$path = Join-Path $repo 'src\components\parties\party-form.tsx'
$f = [System.IO.File]::ReadAllText($path); $f = $f.Replace("`r`n", "`n")

$old_L7 = @'
          <Separator />

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
        </CardContent>
'@
$new_L7 = @'
        </CardContent>
'@
if ($f.Contains($new_L7)) { Write-Output ('SKIP L7') }
elseif ($f.Contains($old_L7)) { $f = $f.Replace($old_L7, $new_L7); Write-Output ('OK   L7') }
else { Write-Output ('WARN L7: anchor not found'); $warn = $true }

$old_L1 = @'
              {/* Name */}
              <div className="space-y-2 md:col-span-2">
                <Label htmlFor="party-name">{t('name')} *</Label>
'@
$new_L1 = @'
              {/* Name / Legal name / Status -- one responsive row */}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 md:col-span-2">
              <div className="space-y-2">
                <Label htmlFor="party-name">{t('name')} *</Label>
'@
if ($f.Contains($new_L1)) { Write-Output ('SKIP L1') }
elseif ($f.Contains($old_L1)) { $f = $f.Replace($old_L1, $new_L1); Write-Output ('OK   L1') }
else { Write-Output ('WARN L1: anchor not found'); $warn = $true }

$old_L2 = @'
                {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
              </div>

              {/* Type / Entity type / Tier */}
'@
$new_L2 = @'
                {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-legal">{t('legalName')}</Label>
                <Input
                  id="party-legal"
                  {...register('legalName')}
                  disabled={isPending}
                  placeholder={t('legalNamePlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-status">Status</Label>
                <Select
                  value={selectedStatus}
                  onValueChange={(v) => setValue('status', v as PartyStatus, { shouldDirty: true })}
                  disabled={isPending}
                >
                  <SelectTrigger id="party-status">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PARTY_STATUSES.map((s) => (
                      <SelectItem key={s} value={s}>
                        {STATUS_LABELS[s]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              </div>

              {/* Type / Entity type / Tier */}
'@
if ($f.Contains($new_L2)) { Write-Output ('SKIP L2') }
elseif ($f.Contains($old_L2)) { $f = $f.Replace($old_L2, $new_L2); Write-Output ('OK   L2') }
else { Write-Output ('WARN L2: anchor not found'); $warn = $true }

$old_L3 = @'
              {/* Legal name */}
              <div className="space-y-2">
                <Label htmlFor="party-legal">{t('legalName')}</Label>
                <Input
                  id="party-legal"
                  {...register('legalName')}
                  disabled={isPending}
                  placeholder={t('legalNamePlaceholder')}
                />
              </div>

              {/* Status */}
              <div className="space-y-2">
                <Label htmlFor="party-status">Status</Label>
                <Select
                  value={selectedStatus}
                  onValueChange={(v) => setValue('status', v as PartyStatus, { shouldDirty: true })}
                  disabled={isPending}
                >
                  <SelectTrigger id="party-status">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PARTY_STATUSES.map((s) => (
                      <SelectItem key={s} value={s}>
                        {STATUS_LABELS[s]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Website */}
              <div className="space-y-2 md:col-span-2">
'@
$new_L3 = @'
              {/* Website / Email / Source -- one responsive row */}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 md:col-span-2">
              {/* Website */}
              <div className="space-y-2">
'@
if ($f.Contains($new_L3)) { Write-Output ('SKIP L3') }
elseif ($f.Contains($old_L3)) { $f = $f.Replace($old_L3, $new_L3); Write-Output ('OK   L3') }
else { Write-Output ('WARN L3: anchor not found'); $warn = $true }

$old_L4 = @'
              {/* Email (org-level / HQ) */}
              <div className="space-y-2 md:col-span-2">
'@
$new_L4 = @'
              {/* Email (org-level / HQ) */}
              <div className="space-y-2">
'@
if ($f.Contains($new_L4)) { Write-Output ('SKIP L4') }
elseif ($f.Contains($old_L4)) { $f = $f.Replace($old_L4, $new_L4); Write-Output ('OK   L4') }
else { Write-Output ('WARN L4: anchor not found'); $warn = $true }

$old_L5 = @'
              {/* Source */}
              <div className="space-y-2 md:col-span-2">
'@
$new_L5 = @'
              {/* Source */}
              <div className="space-y-2">
'@
if ($f.Contains($new_L5)) { Write-Output ('SKIP L5') }
elseif ($f.Contains($old_L5)) { $f = $f.Replace($old_L5, $new_L5); Write-Output ('OK   L5') }
else { Write-Output ('WARN L5: anchor not found'); $warn = $true }

$old_L6 = @'
                  placeholder={t('sourcePlaceholder')}
                />
              </div>
            </div>
          </section>

          <Separator />

          {/* ===================== Location ===================== */}
'@
$new_L6 = @'
                  placeholder={t('sourcePlaceholder')}
                />
              </div>
              </div>
            </div>
          </section>

          <Separator />

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

          <Separator />

          {/* ===================== Location ===================== */}
'@
if ($f.Contains($new_L6)) { Write-Output ('SKIP L6') }
elseif ($f.Contains($old_L6)) { $f = $f.Replace($old_L6, $new_L6); Write-Output ('OK   L6') }
else { Write-Output ('WARN L6: anchor not found'); $warn = $true }

$old_T1 = @'
            <SectionLabel>Tags</SectionLabel>
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="party-industry-tags">{t('industryTags')}</Label>
                <TagMultiSelect
                  inputId="party-industry-tags"
                  value={watch('industryTags') ?? ''}
                  onChange={(v) => setValue('industryTags', v, { shouldDirty: true })}
                  suggestions={industryTagSuggestions}
                  disabled={isPending}
                  placeholder={t('industryTagsPlaceholder')}
                />
                <p className="text-xs text-muted-foreground">{t('industryTagsHint')}</p>
              </div>
              <div className="space-y-2">
'@
$new_T1 = @'
            <SectionLabel>Tags</SectionLabel>
            {/* Industry Tags removed (2026-07-04): duplicated Sector focus and
                was not persisted since D6-5e. */}
            <div className="grid grid-cols-1 gap-y-4">
              <div className="space-y-2">
'@
if ($f.Contains($new_T1)) { Write-Output ('SKIP T1') }
elseif ($f.Contains($old_T1)) { $f = $f.Replace($old_T1, $new_T1); Write-Output ('OK   T1') }
else { Write-Output ('WARN T1: anchor not found'); $warn = $true }

$old_G1 = @'
  sectorFocus: z.string().max(500).optional().or(z.literal('')),
  geographicFocus: z.string().max(500).optional().or(z.literal('')),
'@
$new_G1 = @'
  sectorFocus: z.string().max(500).optional().or(z.literal('')),
'@
if ($f.Contains($new_G1)) { Write-Output ('SKIP G1') }
elseif ($f.Contains($old_G1)) { $f = $f.Replace($old_G1, $new_G1); Write-Output ('OK   G1') }
else { Write-Output ('WARN G1: anchor not found'); $warn = $true }

$old_G2 = @'
          sectorFocus: (existingProfile?.sectorFocus ?? []).join(', '),
          geographicFocus: (existingProfile?.geographicFocus ?? []).join(', '),
'@
$new_G2 = @'
          sectorFocus: (existingProfile?.sectorFocus ?? []).join(', '),
'@
if ($f.Contains($new_G2)) { Write-Output ('SKIP G2') }
elseif ($f.Contains($old_G2)) { $f = $f.Replace($old_G2, $new_G2); Write-Output ('OK   G2') }
else { Write-Output ('WARN G2: anchor not found'); $warn = $true }

$old_G3 = @'
          sectorFocus: '',
          geographicFocus: '',
'@
$new_G3 = @'
          sectorFocus: '',
'@
if ($f.Contains($new_G3)) { Write-Output ('SKIP G3') }
elseif ($f.Contains($old_G3)) { $f = $f.Replace($old_G3, $new_G3); Write-Output ('OK   G3') }
else { Write-Output ('WARN G3: anchor not found'); $warn = $true }

$old_G4 = @'
          sectorFocus: parseTagsInput(values.sectorFocus),
          geographicFocus: parseTagsInput(values.geographicFocus),
'@
$new_G4 = @'
          sectorFocus: parseTagsInput(values.sectorFocus),
'@
if ($f.Contains($new_G4)) { Write-Output ('SKIP G4') }
elseif ($f.Contains($old_G4)) { $f = $f.Replace($old_G4, $new_G4); Write-Output ('OK   G4') }
else { Write-Output ('WARN G4: anchor not found'); $warn = $true }

$old_G5 = @'

                  {/* Geographic focus */}
                  <div className="space-y-2 md:col-span-2">
                    <Label htmlFor="party-geo-focus">Geographic focus</Label>
                    <Input
                      id="party-geo-focus"
                      {...register('geographicFocus')}
                      disabled={isPending}
                      placeholder="US, Global"
                    />
                    <p className="text-xs text-muted-foreground">Comma-separated.</p>
                  </div>

'@
if (-not $f.Contains($old_G5)) { Write-Output ('SKIP/WARN G5: anchor not found (already removed?)') }
else { $f = $f.Replace($old_G5, ''); Write-Output ('OK   G5: removed') }

[System.IO.File]::WriteAllText($path, $f, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\lib\actions\parties.ts'
$a = [System.IO.File]::ReadAllText($path); $a = $a.Replace("`r`n", "`n")

$old_AC1 = @'
  sectorFocus: z.array(z.string().max(64)).max(50),
  geographicFocus: z.array(z.string().max(64)).max(50),
'@
$new_AC1 = @'
  sectorFocus: z.array(z.string().max(64)).max(50),
'@
if ($a.Contains($new_AC1)) { Write-Output ('SKIP AC1') }
elseif ($a.Contains($old_AC1)) { $a = $a.Replace($old_AC1, $new_AC1); Write-Output ('OK   AC1') }
else { Write-Output ('WARN AC1: anchor not found'); $warn = $true }

$old_AC2 = @'
    sector_focus: parsed.data.sectorFocus,
    geographic_focus: parsed.data.geographicFocus,
'@
$new_AC2 = @'
    sector_focus: parsed.data.sectorFocus,
'@
if ($a.Contains($new_AC2)) { Write-Output ('SKIP AC2') }
elseif ($a.Contains($old_AC2)) { $a = $a.Replace($old_AC2, $new_AC2); Write-Output ('OK   AC2') }
else { Write-Output ('WARN AC2: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $a, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\lib\queries\party-detail.ts'
$d = [System.IO.File]::ReadAllText($path); $d = $d.Replace("`r`n", "`n")

$old_PD1 = @'
        'ticket_min_usd, ticket_max_usd, sector_focus, geographic_focus, ' +
'@
$new_PD1 = @'
        'ticket_min_usd, ticket_max_usd, sector_focus, ' +
'@
if ($d.Contains($new_PD1)) { Write-Output ('SKIP PD1') }
elseif ($d.Contains($old_PD1)) { $d = $d.Replace($old_PD1, $new_PD1); Write-Output ('OK   PD1') }
else { Write-Output ('WARN PD1: anchor not found'); $warn = $true }

$old_PD2 = @'
    geographicFocus: arr(r.geographic_focus),
'@
$new_PD2 = @'
    geographicFocus: [],  // column dropped 2026-07-04
'@
if ($d.Contains($new_PD2)) { Write-Output ('SKIP PD2') }
elseif ($d.Contains($old_PD2)) { $d = $d.Replace($old_PD2, $new_PD2); Write-Output ('OK   PD2') }
else { Write-Output ('WARN PD2: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $d, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\components\parties\investor-profile-card.tsx'
$i = [System.IO.File]::ReadAllText($path); $i = $i.Replace("`r`n", "`n")

$old_IC1 = @'
          <Field label="Geographic Focus"><Tags items={profile.geographicFocus} /></Field>

'@
if (-not $i.Contains($old_IC1)) { Write-Output ('SKIP/WARN IC1: anchor not found (already removed?)') }
else { $i = $i.Replace($old_IC1, ''); Write-Output ('OK   IC1: removed') }

[System.IO.File]::WriteAllText($path, $i, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\app\(app)\[partyType]\parties\[id]\mindmap\page.tsx'
$m = [System.IO.File]::ReadAllText($path); $m = $m.Replace("`r`n", "`n")

$old_MM1 = @'
    if ((ip.geographicFocus ?? []).length) investorFocus.push({ label: 'Geography', sub: ip.geographicFocus.join(', ') });

'@
if (-not $m.Contains($old_MM1)) { Write-Output ('SKIP/WARN MM1: anchor not found (already removed?)') }
else { $m = $m.Replace($old_MM1, ''); Write-Output ('OK   MM1: removed') }

[System.IO.File]::WriteAllText($path, $m, $utf8); Write-Output ('WROTE ' + $path)


if ($warn) { Write-Output 'One or more anchors missing - review WARN lines before building.' }
Write-Output 'Next: npm run build -> commit/push -> AFTER deploy, run fix_drop_geographic_focus.sql.'
```

## Finish block

```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/components/parties/party-form.tsx src/lib/actions/parties.ts src/lib/queries/party-detail.ts src/components/parties/investor-profile-card.tsx "src/app/(app)/[partyType]/parties/[id]/mindmap/page.tsx" sql/ tools/ docs/
git commit -m "feat(party-form): responsive layout - name/legal/status + web/email/source rows, intro+notes to top; drop industry-tags field and geographic_focus end-to-end"
git push origin marinebiogroup
```

> 배포 완료 후: Supabase에서 `fix_drop_geographic_focus.sql` 실행 → 컬럼 목록에 geographic_focus 없음 확인.
