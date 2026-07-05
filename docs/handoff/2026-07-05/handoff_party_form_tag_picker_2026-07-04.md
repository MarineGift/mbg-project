# Handoff — Party 폼 태그 피커: 기존 태그 제안 + Add 버튼 (2026-07-04)

## 요구사항 → 구현
| 요구 | 구현 |
|---|---|
| 기존 태그가 나와야 함 | `app.interest_tags` 카탈로그(정식 ~40종, sort_order 순)를 서버에서 내려 필터형 제안 드롭다운으로 표시 (코드 + 한글 라벨) |
| 없으면 Add 버튼 | 검색어가 카탈로그에 없으면 `Add "<slug>"` 버튼 표시 → 자유 태그를 칩으로 추가 (소문자·언더스코어 정규화) |
| 입력 UX | 칩 다중선택, Enter=첫 매치 추가, Backspace=마지막 칩 삭제, × 로 개별 삭제 |

## 구조 (기존 패턴 준수)
- **신규** `src/components/parties/tag-multi-select.tsx` — 클라이언트 컴포넌트. 폼 값은 기존과 동일한 **콤마 문자열** 유지 → zod 스키마·서버 액션 무변경
- **신규** `src/lib/queries/interest-tags.ts` — `investor-types.ts` 헬퍼 패턴 미러
- party-form.tsx: 두 Input → TagMultiSelect (watch/setValue 기반, 추가 의존성 없음)
- new/edit page.tsx: 서버에서 옵션 fetch 후 props 전달 (investorTypeOptions와 동일 패턴)
- Industry Tags에도 동일 카탈로그를 제안으로 제공 (industry 전용 어휘 테이블이 아직 없어 공용; D6-5e에 따라 industry 배열은 저장 시 미영속 — T4b FK 매핑 과제와 함께 개선 예정)

## 참고 (알려진 갭)
1. **Add로 만든 새 태그**는 저장 시 레거시 jsonb에 들어가고, 정규화 카탈로그 반영은 `fix_interest_tags_all_in_one.sql` [B] 재실행(멱등)으로 흡수됩니다. 폼 저장→정규화 실시간 동기화는 다음 태스크.
2. TAGS 컬럼(정규화 소스)에 새 태그가 뜨려면 위 재실행이 필요합니다.

## 실행
1. 아래 인라인 패치 실행 (신규 파일 2개 생성 + 3개 파일 11개 앵커 패치, 전부 멱등)
2. `npm run build`
3. finish block

## 인라인 패치

```powershell
# patch_party_form_tag_picker.ps1
# New Investor form: Industry/Interest Tags become multi-select pickers with
# suggestions from app.interest_tags + an Add button for unknown tags.
# Creates 2 new files, patches party-form.tsx and the new/edit pages.
# Idempotent. Run npm run build afterwards.
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$warn = $false

# ---- new file 1: TagMultiSelect component ----
$f1 = Join-Path $repo 'src\components\parties\tag-multi-select.tsx'
$componentSrc = @'
'use client';

/**
 * components/parties/tag-multi-select.tsx
 *
 * Multi-select tag input with suggestions from the normalized tag catalogue.
 *  - shows existing tags as filterable suggestions (code + label)
 *  - Enter or click adds a tag chip; Backspace removes the last chip
 *  - unknown queries get an explicit `Add "<slug>"` action (free vocabulary,
 *    normalized later by the interest-tags alias/merge pipeline)
 *  - emits the same comma-separated string the form previously stored, so
 *    server actions / zod schema stay untouched.
 */

import { useMemo, useRef, useState } from 'react';
import { X, Plus } from 'lucide-react';

export interface TagOption {
  code: string;
  label: string;
}

interface Props {
  inputId?: string;
  /** comma-separated tag codes (react-hook-form field value) */
  value: string;
  onChange: (next: string) => void;
  suggestions?: TagOption[];
  placeholder?: string;
  disabled?: boolean;
}

function slugify(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

export function TagMultiSelect({
  inputId,
  value,
  onChange,
  suggestions = [],
  placeholder,
  disabled,
}: Props) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);

  const selected = useMemo(
    () => value.split(',').map((s) => s.trim()).filter(Boolean),
    [value],
  );
  const selectedSet = useMemo(
    () => new Set(selected.map((s) => s.toLowerCase())),
    [selected],
  );

  const q = query.trim().toLowerCase();
  const matches = useMemo(() => {
    const pool = suggestions.filter((s) => !selectedSet.has(s.code.toLowerCase()));
    if (!q) return pool.slice(0, 8);
    return pool
      .filter(
        (s) =>
          s.code.toLowerCase().includes(q) || s.label.toLowerCase().includes(q),
      )
      .slice(0, 8);
  }, [suggestions, selectedSet, q]);

  const slug = slugify(q);
  const exactExists =
    q !== '' &&
    (selectedSet.has(slug) ||
      suggestions.some((s) => s.code.toLowerCase() === slug));

  const add = (code: string) => {
    const c = code.trim();
    if (!c || selectedSet.has(c.toLowerCase())) return;
    onChange([...selected, c].join(', '));
    setQuery('');
  };
  const remove = (code: string) => {
    onChange(selected.filter((s) => s !== code).join(', '));
  };

  return (
    <div ref={boxRef} className="relative">
      <div
        className={`flex min-h-9 w-full flex-wrap items-center gap-1 rounded-md border bg-background px-2 py-1 text-sm ${disabled ? 'opacity-50' : ''}`}
      >
        {selected.map((tag) => (
          <span
            key={tag}
            className="inline-flex items-center gap-1 rounded bg-muted px-1.5 py-0.5 text-xs"
          >
            {tag}
            {!disabled && (
              <button
                type="button"
                className="text-muted-foreground hover:text-foreground"
                onClick={() => remove(tag)}
                aria-label={'remove ' + tag}
              >
                <X className="h-3 w-3" />
              </button>
            )}
          </span>
        ))}
        <input
          id={inputId}
          className="min-w-[120px] flex-1 bg-transparent py-0.5 outline-none placeholder:text-muted-foreground"
          value={query}
          placeholder={selected.length === 0 ? placeholder : undefined}
          disabled={disabled}
          autoComplete="off"
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => window.setTimeout(() => setOpen(false), 150)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (q !== '' && matches.length > 0) add(matches[0]!.code);
              else if (q !== '' && slug) add(slug);
            } else if (e.key === 'Backspace' && q === '' && selected.length > 0) {
              remove(selected[selected.length - 1]!);
            }
          }}
        />
      </div>
      {open && !disabled && (q !== '' || matches.length > 0) && (
        <div className="absolute z-30 mt-1 w-full rounded-md border bg-popover p-1 shadow-md">
          {matches.map((s) => (
            <button
              key={s.code}
              type="button"
              className="flex w-full items-center justify-between rounded px-2 py-1.5 text-left text-sm hover:bg-muted"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => add(s.code)}
            >
              <span>{s.code}</span>
              {s.label !== s.code && (
                <span className="ml-2 truncate text-xs text-muted-foreground">
                  {s.label}
                </span>
              )}
            </button>
          ))}
          {q !== '' && slug !== '' && !exactExists && (
            <button
              type="button"
              className="mt-0.5 flex w-full items-center gap-1 rounded px-2 py-1.5 text-left text-sm text-primary hover:bg-muted"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => add(slug)}
            >
              <Plus className="h-3.5 w-3.5" />
              {'Add "' + slug + '"'}
            </button>
          )}
          {matches.length === 0 && q === '' && (
            <div className="px-2 py-1.5 text-xs text-muted-foreground">
              Type to search tags
            </div>
          )}
        </div>
      )}
    </div>
  );
}

'@
if (Test-Path -LiteralPath $f1) { Write-Output 'SKIP new-file tag-multi-select.tsx (exists)' }
else { [System.IO.File]::WriteAllText($f1, $componentSrc, $utf8); Write-Output ('WROTE ' + $f1) }

# ---- new file 2: interest tag options query ----
$f2 = Join-Path $repo 'src\lib\queries\interest-tags.ts'
$helperSrc = @'
/**
 * lib/queries/interest-tags.ts
 *
 * Canonical interest-tag options (app.interest_tags) for the Party form
 * TagMultiSelect. Global lookup, catalogue sort_order, mirrors
 * lib/queries/investor-types.ts.
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { TagOption } from '@/components/parties/tag-multi-select';

export async function fetchInterestTagOptions(): Promise<TagOption[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('interest_tags' as never)
    .select('code, label_en, label_ko, sort_order')
    .order('sort_order' as never, { ascending: true });

  if (error || !data) return [];

  return (
    data as Array<{ code: string; label_en: string | null; label_ko: string | null }>
  )
    .filter((r) => !!r.code)
    .map((r) => ({
      code: r.code,
      label:
        r.label_ko && r.label_ko !== r.code
          ? r.label_ko
          : (r.label_en ?? r.code),
    }));
}

'@
if (Test-Path -LiteralPath $f2) { Write-Output 'SKIP new-file interest-tags.ts (exists)' }
else { [System.IO.File]::WriteAllText($f2, $helperSrc, $utf8); Write-Output ('WROTE ' + $f2) }

# ---- patch party-form.tsx ----
$path = Join-Path $repo 'src\components\parties\party-form.tsx'
$c = [System.IO.File]::ReadAllText($path); $c = $c.Replace("`r`n", "`n")

$old_F1 = @'
import { Separator } from '@/components/ui/separator';
'@
$new_F1 = @'
import { Separator } from '@/components/ui/separator';
import { TagMultiSelect, type TagOption } from '@/components/parties/tag-multi-select';
'@
if ($c.Contains($new_F1)) { Write-Output ('SKIP F1') }
elseif ($c.Contains($old_F1)) { $c = $c.Replace($old_F1, $new_F1); Write-Output ('OK   F1') }
else { Write-Output ('WARN F1: anchor not found'); $warn = $true }

$old_F2 = @'
  /** app.investor_types options for the "Investor type" select */
  investorTypeOptions?: InvestorTypeOption[];
}
'@
$new_F2 = @'
  /** app.investor_types options for the "Investor type" select */
  investorTypeOptions?: InvestorTypeOption[];
  /** canonical tag options for the Industry Tags multi-select */
  industryTagSuggestions?: TagOption[];
  /** canonical tag options for the Interest Tags multi-select */
  interestTagSuggestions?: TagOption[];
}
'@
if ($c.Contains($new_F2)) { Write-Output ('SKIP F2') }
elseif ($c.Contains($old_F2)) { $c = $c.Replace($old_F2, $new_F2); Write-Output ('OK   F2') }
else { Write-Output ('WARN F2: anchor not found'); $warn = $true }

$old_F3 = @'
  investorTypeOptions = [],
}: Props) {
'@
$new_F3 = @'
  investorTypeOptions = [],
  industryTagSuggestions = [],
  interestTagSuggestions = [],
}: Props) {
'@
if ($c.Contains($new_F3)) { Write-Output ('SKIP F3') }
elseif ($c.Contains($old_F3)) { $c = $c.Replace($old_F3, $new_F3); Write-Output ('OK   F3') }
else { Write-Output ('WARN F3: anchor not found'); $warn = $true }

$old_F4 = @'
                <Input
                  id="party-industry-tags"
                  {...register('industryTags')}
                  disabled={isPending}
                  placeholder={t('industryTagsPlaceholder')}
                />
'@
$new_F4 = @'
                <TagMultiSelect
                  inputId="party-industry-tags"
                  value={watch('industryTags') ?? ''}
                  onChange={(v) => setValue('industryTags', v, { shouldDirty: true })}
                  suggestions={industryTagSuggestions}
                  disabled={isPending}
                  placeholder={t('industryTagsPlaceholder')}
                />
'@
if ($c.Contains($new_F4)) { Write-Output ('SKIP F4') }
elseif ($c.Contains($old_F4)) { $c = $c.Replace($old_F4, $new_F4); Write-Output ('OK   F4') }
else { Write-Output ('WARN F4: anchor not found'); $warn = $true }

$old_F5 = @'
                <Input
                  id="party-interest-tags"
                  {...register('interestTags')}
                  disabled={isPending}
                  placeholder={t('interestTagsPlaceholder')}
                />
'@
$new_F5 = @'
                <TagMultiSelect
                  inputId="party-interest-tags"
                  value={watch('interestTags') ?? ''}
                  onChange={(v) => setValue('interestTags', v, { shouldDirty: true })}
                  suggestions={interestTagSuggestions}
                  disabled={isPending}
                  placeholder={t('interestTagsPlaceholder')}
                />
'@
if ($c.Contains($new_F5)) { Write-Output ('SKIP F5') }
elseif ($c.Contains($old_F5)) { $c = $c.Replace($old_F5, $new_F5); Write-Output ('OK   F5') }
else { Write-Output ('WARN F5: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $c, $utf8); Write-Output ('WROTE ' + $path)

# ---- patch new/page.tsx ----
$path = Join-Path $repo 'src\app\(app)\[partyType]\parties\new\page.tsx'
$n = [System.IO.File]::ReadAllText($path); $n = $n.Replace("`r`n", "`n")

$old_N1 = @'
import { fetchInvestorTypeOptions } from '@/lib/queries/investor-types';
'@
$new_N1 = @'
import { fetchInvestorTypeOptions } from '@/lib/queries/investor-types';
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
'@
if ($n.Contains($new_N1)) { Write-Output ('SKIP N1') }
elseif ($n.Contains($old_N1)) { $n = $n.Replace($old_N1, $new_N1); Write-Output ('OK   N1') }
else { Write-Output ('WARN N1: anchor not found'); $warn = $true }

$old_N2 = @'
  const investorTypeOptions =
    module === 'investor' ? await fetchInvestorTypeOptions() : [];
'@
$new_N2 = @'
  const investorTypeOptions =
    module === 'investor' ? await fetchInvestorTypeOptions() : [];
  const interestTagSuggestions = await fetchInterestTagOptions();
'@
if ($n.Contains($new_N2)) { Write-Output ('SKIP N2') }
elseif ($n.Contains($old_N2)) { $n = $n.Replace($old_N2, $new_N2); Write-Output ('OK   N2') }
else { Write-Output ('WARN N2: anchor not found'); $warn = $true }

$old_N3 = @'
        investorTypeOptions={investorTypeOptions}
      />
'@
$new_N3 = @'
        investorTypeOptions={investorTypeOptions}
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
      />
'@
if ($n.Contains($new_N3)) { Write-Output ('SKIP N3') }
elseif ($n.Contains($old_N3)) { $n = $n.Replace($old_N3, $new_N3); Write-Output ('OK   N3') }
else { Write-Output ('WARN N3: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $n, $utf8); Write-Output ('WROTE ' + $path)

# ---- patch edit/page.tsx ----
$path = Join-Path $repo 'src\app\(app)\[partyType]\parties\[id]\edit\page.tsx'
$e = [System.IO.File]::ReadAllText($path); $e = $e.Replace("`r`n", "`n")

$old_E1 = @'
import { fetchInvestorTypeOptions } from '@/lib/queries/investor-types';
'@
$new_E1 = @'
import { fetchInvestorTypeOptions } from '@/lib/queries/investor-types';
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
'@
if ($e.Contains($new_E1)) { Write-Output ('SKIP E1') }
elseif ($e.Contains($old_E1)) { $e = $e.Replace($old_E1, $new_E1); Write-Output ('OK   E1') }
else { Write-Output ('WARN E1: anchor not found'); $warn = $true }

$old_E2 = @'
  const investorTypeOptions =
    full.party.partyType === 'investor' ? await fetchInvestorTypeOptions() : [];
'@
$new_E2 = @'
  const investorTypeOptions =
    full.party.partyType === 'investor' ? await fetchInvestorTypeOptions() : [];
  const interestTagSuggestions = await fetchInterestTagOptions();
'@
if ($e.Contains($new_E2)) { Write-Output ('SKIP E2') }
elseif ($e.Contains($old_E2)) { $e = $e.Replace($old_E2, $new_E2); Write-Output ('OK   E2') }
else { Write-Output ('WARN E2: anchor not found'); $warn = $true }

$old_E3 = @'
        investorTypeOptions={investorTypeOptions}
      />
'@
$new_E3 = @'
        investorTypeOptions={investorTypeOptions}
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
      />
'@
if ($e.Contains($new_E3)) { Write-Output ('SKIP E3') }
elseif ($e.Contains($old_E3)) { $e = $e.Replace($old_E3, $new_E3); Write-Output ('OK   E3') }
else { Write-Output ('WARN E3: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $e, $utf8); Write-Output ('WROTE ' + $path)

if ($warn) { Write-Output 'One or more anchors missing - review WARN lines before building.' }
Write-Output 'Next: npm run build, then commit + push.'
```

## Finish block

```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/components/parties/tag-multi-select.tsx src/lib/queries/interest-tags.ts src/components/parties/party-form.tsx "src/app/(app)/[partyType]/parties/new/page.tsx" "src/app/(app)/[partyType]/parties/[id]/edit/page.tsx" tools/ docs/
git commit -m "feat(party-form): tag multi-select with catalogue suggestions + add-new; interest tag options query"
git push origin marinebiogroup
```

> push = Railway 자동 배포. 배포 후 /investor/parties/new 에서 Interest Tags 클릭 → 제안 목록/Add 버튼 확인.
