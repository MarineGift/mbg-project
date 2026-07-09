# ============================================================
# patch_contact_method_ui.ps1
# Adds preferred_contact_method / contact_form_url UI wiring:
#   1. src/types/party-detail.ts            (PartyDetail fields)
#   2. src/lib/queries/party-detail.ts      (select + RawPartyRow + mapping)
#   3. src/components/parties/party-header.tsx      (badge)
#   4. src/components/parties/party-info-card.tsx   (fields)
#   5. src/app/(app)/[partyType]/parties/[id]/page.tsx  (application panel)
#   6. src/app/(app)/[partyType]/parties/page.tsx       (list badge)
#   7. src/components/parties/party-form.tsx + src/lib/actions/parties.ts (edit)
# Idempotent: every patch is guarded. ASCII output only.
# Run: powershell -ExecutionPolicy Bypass -File patch_contact_method_ui.ps1
# ============================================================

$repo = "C:\dev\mbg-project"
if (-not (Test-Path $repo)) { Write-Host "FAIL  repo not found: $repo"; exit 1 }

function Patch-File {
  param([string]$Rel, [string]$Guard, [object[]]$Pairs)
  $path = Join-Path $repo $Rel
  if (-not (Test-Path $path)) { Write-Host "MISS  $Rel"; return }
  $t = [System.IO.File]::ReadAllText($path)
  $t = $t -replace "`r`n", "`n"
  if ($t.Contains($Guard)) { Write-Host "SKIP  $Rel (already patched)"; return }
  $ok = $true
  foreach ($p in $Pairs) {
    if (-not $t.Contains($p.Old)) { Write-Host "WARN  $Rel anchor not found: $($p.Name)"; $ok = $false }
  }
  if (-not $ok) { Write-Host "FAIL  $Rel (anchors changed, patch manually)"; return }
  foreach ($p in $Pairs) { $t = $t.Replace($p.Old, $p.New) }
  [System.IO.File]::WriteAllText($path, $t)
  Write-Host "OK    $Rel"
}

# ------------------------------------------------------------
# 1. types/party-detail.ts
# ------------------------------------------------------------
$old1 = @'
  /** Organization-level contact: HQ email and street address (single line). */
  email: string | null;
  streetAddress: string | null;
'@
$new1 = @'
  /** Organization-level contact: HQ email and street address (single line). */
  email: string | null;
  streetAddress: string | null;
  /** How this party prefers to be contacted (migration_027). */
  preferredContactMethod: string | null;
  contactFormUrl: string | null;
'@
Patch-File "src\types\party-detail.ts" "preferredContactMethod" @(
  @{ Name="detail-iface"; Old=$old1; New=$new1 }
)

# ------------------------------------------------------------
# 2. lib/queries/party-detail.ts
# ------------------------------------------------------------
$q_selOld = "intro_ko, intro_en, created_at, updated_at',"
$q_selNew = "intro_ko, intro_en, preferred_contact_method, contact_form_url, created_at, updated_at',"
$q_rawOld = @'
  email: string | null;
  street_address: string | null;
  created_at: string;
'@
$q_rawNew = @'
  email: string | null;
  street_address: string | null;
  preferred_contact_method: string | null;
  contact_form_url: string | null;
  created_at: string;
'@
$q_mapOld = "    streetAddress: p.street_address,"
$q_mapNew = @'
    streetAddress: p.street_address,
    preferredContactMethod: p.preferred_contact_method,
    contactFormUrl: p.contact_form_url,
'@
Patch-File "src\lib\queries\party-detail.ts" "preferred_contact_method" @(
  @{ Name="select"; Old=$q_selOld; New=$q_selNew },
  @{ Name="raw-iface"; Old=$q_rawOld; New=$q_rawNew },
  @{ Name="mapping"; Old=$q_mapOld; New=$q_mapNew }
)

# ------------------------------------------------------------
# 3. components/parties/party-header.tsx
# ------------------------------------------------------------
$h_impOld = "import { PartyTypeBadge } from '@/components/common/party-type-badge';"
$h_impNew = @'
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { ContactMethodBadge } from '@/components/common/contact-method-badge';
'@
$h_bdgOld = @'
          {party.status}
        </span>
        <Button asChild variant="outline" size="sm" className="ml-auto">
'@
$h_bdgNew = @'
          {party.status}
        </span>
        <ContactMethodBadge
          method={party.preferredContactMethod}
          formUrl={party.contactFormUrl}
          size="sm"
        />
        <Button asChild variant="outline" size="sm" className="ml-auto">
'@
Patch-File "src\components\parties\party-header.tsx" "ContactMethodBadge" @(
  @{ Name="import"; Old=$h_impOld; New=$h_impNew },
  @{ Name="badge"; Old=$h_bdgOld; New=$h_bdgNew }
)

# ------------------------------------------------------------
# 4. components/parties/party-info-card.tsx
# ------------------------------------------------------------
$c_impOld = "import { PartyTypeBadge } from '@/components/common/party-type-badge';"
$c_impNew = @'
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { ContactMethodBadge } from '@/components/common/contact-method-badge';
'@
$c_fldOld = '          <Field label="Source">{party.source || DASH}</Field>'
$c_fldNew = @'
          <Field label="Contact method">
            {party.preferredContactMethod ? (
              <ContactMethodBadge
                method={party.preferredContactMethod}
                formUrl={party.contactFormUrl}
              />
            ) : (
              DASH
            )}
          </Field>
          <Field label="Form URL">
            {party.contactFormUrl ? (
              <a
                href={party.contactFormUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline break-all"
              >
                {party.contactFormUrl}
              </a>
            ) : (
              DASH
            )}
          </Field>
          <Field label="Source">{party.source || DASH}</Field>
'@
Patch-File "src\components\parties\party-info-card.tsx" "ContactMethodBadge" @(
  @{ Name="import"; Old=$c_impOld; New=$c_impNew },
  @{ Name="fields"; Old=$c_fldOld; New=$c_fldNew }
)

# ------------------------------------------------------------
# 5. [partyType]/parties/[id]/page.tsx  (application panel)
# ------------------------------------------------------------
$d_impOld = "import { PartyInfoCard } from '@/components/parties/party-info-card';"
$d_impNew = @'
import { PartyInfoCard } from '@/components/parties/party-info-card';
import { PartyApplicationPanel } from '@/components/parties/party-application-panel';
'@
$d_pnlOld = "                <PartyInfoCard party={full.party} contacts={full.contacts} />"
$d_pnlNew = @'
                <PartyInfoCard party={full.party} contacts={full.contacts} />
                <PartyApplicationPanel
                  partyId={full.party.id}
                  partyType={full.party.partyType}
                  contactMethod={full.party.preferredContactMethod}
                  contactFormUrl={full.party.contactFormUrl}
                />
'@
Patch-File "src\app\(app)\[partyType]\parties\[id]\page.tsx" "PartyApplicationPanel" @(
  @{ Name="import"; Old=$d_impOld; New=$d_impNew },
  @{ Name="panel"; Old=$d_pnlOld; New=$d_pnlNew }
)

# ------------------------------------------------------------
# 6. [partyType]/parties/page.tsx  (directory list badge)
# ------------------------------------------------------------
$l_impOld = "import { AccountScoreBadge } from '@/components/common/account-score-badge';"
$l_impNew = @'
import { AccountScoreBadge } from '@/components/common/account-score-badge';
import { ContactMethodBadge } from '@/components/common/contact-method-badge';
'@
$l_ifcOld = "  interest_tags: string[] | null; website: string | null; created_at: string;"
$l_ifcNew = @'
  interest_tags: string[] | null; website: string | null; created_at: string;
  preferred_contact_method: string | null; contact_form_url: string | null;
'@
$l_selOld = "'id, party_name, status, country_code, city, region, website, interest_tags, created_at, entity_type_id',"
$l_selNew = "'id, party_name, status, country_code, city, region, website, interest_tags, created_at, entity_type_id, preferred_contact_method, contact_form_url',"
$l_bdgOld = @'
                          {p.party_name}
                        </Link>
'@
$l_bdgNew = @'
                          {p.party_name}
                        </Link>
                        {p.preferred_contact_method && (
                          <ContactMethodBadge
                            method={p.preferred_contact_method}
                            formUrl={p.contact_form_url}
                            size="sm"
                            className="mt-1"
                          />
                        )}
'@
Patch-File "src\app\(app)\[partyType]\parties\page.tsx" "ContactMethodBadge" @(
  @{ Name="import"; Old=$l_impOld; New=$l_impNew },
  @{ Name="row-iface"; Old=$l_ifcOld; New=$l_ifcNew },
  @{ Name="select"; Old=$l_selOld; New=$l_selNew },
  @{ Name="badge"; Old=$l_bdgOld; New=$l_bdgNew }
)

# ------------------------------------------------------------
# 7a. components/parties/party-form.tsx (edit form)
# ------------------------------------------------------------
$f_schOld = "  source: z.string().max(120).optional().or(z.literal('')),"
$f_schNew = @'
  source: z.string().max(120).optional().or(z.literal('')),
  preferredContactMethod: z
    .enum(['email', 'web_form', 'portal', 'phone', 'other'])
    .optional()
    .or(z.literal('')),
  contactFormUrl: z
    .string()
    .max(500)
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^https?:\/\/.+/.test(s), 'Must start with http:// or https://'),
'@
$f_defEOld = "          source: existing.source ?? '',"
$f_defENew = @'
          source: existing.source ?? '',
          preferredContactMethod: (existing.preferredContactMethod ??
            '') as FormValues['preferredContactMethod'],
          contactFormUrl: existing.contactFormUrl ?? '',
'@
$f_defNOld = "          source: '',"
$f_defNNew = @'
          source: '',
          preferredContactMethod: '',
          contactFormUrl: '',
'@
$f_payOld = "        source: values.source || null,"
$f_payNew = @'
        source: values.source || null,
        preferredContactMethod: values.preferredContactMethod || null,
        contactFormUrl: values.contactFormUrl || null,
'@
$f_uiOld = @'
              {/* Source */}
              <div className="space-y-2">
                <Label htmlFor="party-source">{t('source')}</Label>
                <Input
                  id="party-source"
                  {...register('source')}
                  disabled={isPending}
                  placeholder={t('sourcePlaceholder')}
                />
              </div>
'@
$f_uiNew = @'
              {/* Source */}
              <div className="space-y-2">
                <Label htmlFor="party-source">{t('source')}</Label>
                <Input
                  id="party-source"
                  {...register('source')}
                  disabled={isPending}
                  placeholder={t('sourcePlaceholder')}
                />
              </div>

              {/* Contact method (migration_027) */}
              <div className="space-y-2">
                <Label htmlFor="party-contact-method">Contact method</Label>
                <select
                  id="party-contact-method"
                  {...register('preferredContactMethod')}
                  disabled={isPending}
                  className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm"
                >
                  <option value="">- unknown -</option>
                  <option value="email">Email</option>
                  <option value="web_form">Web form</option>
                  <option value="portal">Portal (login required)</option>
                  <option value="phone">Phone</option>
                  <option value="other">Other</option>
                </select>
              </div>

              {/* Application / contact form URL (required for web_form and portal) */}
              <div className="space-y-2">
                <Label htmlFor="party-contact-form-url">Form URL</Label>
                <Input
                  id="party-contact-form-url"
                  {...register('contactFormUrl')}
                  disabled={isPending}
                  placeholder="https://..."
                />
                {errors.contactFormUrl && (
                  <p className="text-xs text-destructive">
                    {errors.contactFormUrl.message}
                  </p>
                )}
              </div>
'@
Patch-File "src\components\parties\party-form.tsx" "preferredContactMethod" @(
  @{ Name="schema"; Old=$f_schOld; New=$f_schNew },
  @{ Name="defaults-existing"; Old=$f_defEOld; New=$f_defENew },
  @{ Name="defaults-new"; Old=$f_defNOld; New=$f_defNNew },
  @{ Name="payload"; Old=$f_payOld; New=$f_payNew },
  @{ Name="ui"; Old=$f_uiOld; New=$f_uiNew }
)

# ------------------------------------------------------------
# 7b. lib/actions/parties.ts (server action schema + rows)
#     NOTE: the source: line appears in BOTH create and update rows;
#     string.Replace patches both at once (intended).
# ------------------------------------------------------------
$a_schOld = "  source: z.string().max(120).optional().nullable(),"
$a_schNew = @'
  source: z.string().max(120).optional().nullable(),
  preferredContactMethod: z
    .enum(['email', 'web_form', 'portal', 'phone', 'other'])
    .optional()
    .nullable(),
  contactFormUrl: z.string().url().max(500).optional().nullable(),
'@
$a_rowOld = "    source: parsed.data.source?.trim() || null,"
$a_rowNew = @'
    source: parsed.data.source?.trim() || null,
    preferred_contact_method: parsed.data.preferredContactMethod || null,
    contact_form_url: parsed.data.contactFormUrl || null,
'@
Patch-File "src\lib\actions\parties.ts" "preferredContactMethod" @(
  @{ Name="schema"; Old=$a_schOld; New=$a_schNew },
  @{ Name="rows"; Old=$a_rowOld; New=$a_rowNew }
)

Write-Host ""
Write-Host "DONE. Next: npx tsc --noEmit (or npm run build) to verify."
